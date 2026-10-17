///|
priv struct Pds3Declaration {
  grid : XyzSpecification
  datum : String
  uncertainty : String
}

///|
fn pds3_declaration(text : String) -> Pds3Declaration raise ImportError {
  need(
    text.length() <= 16384,
    "PDS3 grid declaration exceeds 16 KiB character limit",
  )
  let tokens = pds3_declaration_tokens(text)
  for key in ["rows", "cols"] {
    guard tokens.get(key) is Some(token) else {
      raise InvalidRaster("Missing PDS3 grid field " + key)
    }
    pds3_exact_integer(token, 4096, "PDS3 " + key) |> ignore
  }
  let spec = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid PDS3 grid declaration JSON")
  }
  guard spec is Object(fields) else {
    raise InvalidRaster("PDS3 declaration must be an object")
  }
  let common = [
    "tile_id", "coordinate_frame", "horizontal_unit", "source_note", "rows", "cols",
    "origin_x", "origin_y", "cell_size",
  ]
  let own = [
    "contract_id", "vertical_quantity", "vertical_datum", "uncertainty_note", "row_order",
    "column_order",
  ]
  for key, _ in fields {
    need(
      common.contains(key) || own.contains(key),
      "Unsupported PDS3 declaration field " + key,
    )
  }
  need(
    json_text(spec, "contract_id") == "moonmoon.pds3-grid.v1",
    "Unsupported PDS3 grid declaration",
  )
  need(
    json_text(spec, "vertical_quantity") == "elevation",
    "PDS3 scaled quantity must explicitly be elevation, not radius or reflectance; no datum conversion is performed",
  )
  need(
    json_text(spec, "row_order") == "top-to-bottom" &&
    json_text(spec, "column_order") == "left-to-right",
    "PDS3 profile requires explicitly declared top-to-bottom rows and left-to-right columns",
  )
  let datum = json_text(spec, "vertical_datum")
  let uncertainty = json_text(spec, "uncertainty_note")
  for
    (name, value) in [
      ("vertical_datum", datum),
      ("uncertainty_note", uncertainty),
    ] {
    need(
      !value.trim().is_empty() && value.length() <= 2000,
      "Declare PDS3 " + name + " in 1 to 2000 characters",
    )
  }
  let grid_fields : Map[String, Json] = Map([])
  grid_fields["contract_id"] = "moonmoon.xyz-grid.v1".to_json()
  for key in common {
    guard fields.get(key) is Some(value) else {
      raise InvalidRaster("Missing PDS3 grid field " + key)
    }
    grid_fields[key] = value
  }
  let grid = xyz_specification(grid_fields.to_json().stringify())
  for
    (origin, size, axis) in [
      (grid.origin_x, grid.cols, "X"),
      (grid.origin_y, grid.rows, "Y"),
    ] {
    let mut previous = origin
    for index in 1..<size {
      let next = origin + index.to_double() * grid.cell_size
      need(
        finite(next) && next > previous,
        "PDS3 " + axis + " centers collapse at the declared origin and spacing",
      )
      previous = next
    }
  }
  { grid, datum, uncertainty, }
}

///|
fn pds3_samples(
  image : Bytes,
  label : Pds3Image,
) -> (Array[Double?], String) raise ImportError {
  need(
    image.length() == label.rows * label.cols * 2,
    "PDS3 IMG byte length differs from declared unpadded 16-bit raster",
  )
  let values : Array[Double?] = []
  let lines = ["row,col,raw_signed_dn,elevation_m,coverage"]
  for index in 0..<(label.rows * label.cols) {
    let a = image[index * 2].to_int()
    let b = image[index * 2 + 1].to_int()
    let word = if label.little_endian { b * 256 + a } else { a * 256 + b }
    let dn = if word >= 32768 { word - 65536 } else { word }
    let coverage = if label.missing == Some(dn) {
      "missing-constant"
    } else if label.invalid == Some(dn) {
      "invalid-constant"
    } else {
      "known"
    }
    let elevation = if coverage == "known" {
      let scaled = dn.to_double() * label.scale
      need(
        finite(scaled) && !(dn != 0 && scaled == 0.0),
        "PDS3 scale multiplication overflows or underflows",
      )
      let value = scaled + label.offset
      need(finite(value), "PDS3 scale plus offset overflows")
      Some(value)
    } else {
      None
    }
    values.push(elevation)
    lines.push(
      "\{index / label.cols},\{index % label.cols},\{dn},\{csv_number(elevation)},\{coverage}",
    )
  }
  (values, lines.join("\n") + "\n")
}

///|
fn pds3_grid(
  image : Bytes,
  label : Pds3Image,
  declaration : Pds3Declaration,
) -> (AsciiGrid, String) raise ImportError {
  let spec = declaration.grid
  need(
    spec.rows == label.rows && spec.cols == label.cols,
    "PDS3 IMAGE dimensions differ from the supplied grid declaration",
  )
  let (values, samples) = pds3_samples(image, label)
  (
    {
      rows: spec.rows,
      cols: spec.cols,
      origin_x: spec.origin_x,
      origin_y: spec.origin_y,
      origin_kind: "center",
      cell_size: spec.cell_size,
      nodata_value: -9999.0,
      nodata_declared: false,
      values,
    },
    samples,
  )
}

///|
fn pds3_image_from_hex(text : String) -> Bytes raise ImportError {
  need(
    text.length() <= 16384 && text.length() % 2 == 0,
    "Invalid PDS3 retained image hex length",
  )
  fn digit(c : UInt16) -> Int raise ImportError {
    if c >= 48 && c <= 57 {
      c.to_int() - 48
    } else if c >= 97 && c <= 102 {
      c.to_int() - 87
    } else {
      raise InvalidRaster(
        "PDS3 retained image requires lowercase hexadecimal bytes",
      )
    }
  }
  Bytes::makei(text.length() / 2, i => {
    (digit(text[i * 2]) * 16 + digit(text[i * 2 + 1])).to_byte()
  })
}

///|
/// Decode a bounded detached PDS3 signed-16-bit IMAGE using an explicit regular
/// grid declaration. Scale and offset are literal: output = DN * scale + offset.
/// Missing and invalid constants are tested before scaling. The caller declares
/// that scaled values are elevations in metres and names the datum; no radius
/// subtraction, map projection, interpolation or dataset qualification occurs.
/// Retained label, exact image bytes and declaration are replayed by reopen_bundle.
pub fn import_pds3_bundle(
  label_text : String,
  image : Bytes,
  image_name : String,
  specification_text : String,
) -> Json raise ImportError {
  let label = pds3_label(label_text, image_name)
  let declaration = pds3_declaration(specification_text)
  let spec = declaration.grid
  let (grid, samples_csv) = pds3_grid(image, label, declaration)
  let bundle = grid_bundle(
    grid,
    label_text,
    spec.tile_id,
    spec.coordinate_frame,
    spec.horizontal_unit,
    spec.source_note,
  )
  guard bundle is Object(fields) else {
    raise InvalidRaster("Invalid internal PDS3 bundle")
  }
  let image_digest = "sha256:" +
    @crypto.bytes_to_hex_string(@crypto.sha256(image))
  let inputs : Json = {
    "label_digest": digest(label_text),
    "image_digest": image_digest,
    "image_name": image_name,
    "grid_specification_digest": digest(specification_text),
  }
  let sample_type = if label.little_endian {
    "LSB_INTEGER"
  } else {
    "MSB_INTEGER"
  }
  fields["contract_id"] = "moonmoon.terrain-pds3-import.v1".to_json()
  fields["format"] = "pds3-detached-signed16-image".to_json()
  fields["source_digest"] = digest(inputs.stringify()).to_json()
  fields["source_inputs"] = inputs
  fields["image_name"] = image_name.to_json()
  fields["image_hex"] = @crypto.bytes_to_hex_string(image).to_json()
  fields["image_byte_count"] = image.length().to_json()
  fields["grid_specification_text"] = specification_text.to_json()
  fields["nodata_value"] = Json::null()
  fields["sample_type"] = sample_type.to_json()
  fields["scaling_factor"] = label.scale.to_json()
  fields["offset"] = label.offset.to_json()
  fields["missing_constant"] = label.missing.to_json()
  fields["invalid_constant"] = label.invalid.to_json()
  fields["vertical_quantity"] = "elevation".to_json()
  fields["vertical_datum"] = declaration.datum.to_json()
  fields["uncertainty_note"] = declaration.uncertainty.to_json()
  fields["decoded_samples_csv"] = samples_csv.to_json()
  fields["decoded_samples_digest"] = digest(samples_csv).to_json()
  fields["import_report_markdown"] = ("# PDS3 elevation import\n\n" +
  "Local, caller-declared digital study inputs. No terrain truth or physical readiness established.\n\n" +
  "- Raster: \{label.rows} rows by \{label.cols} columns, top-to-bottom and left-to-right\n" +
  "- Decoding: \{sample_type}, signed 16-bit, no padding\n" +
  "- Elevation metres = raw signed DN * \{label.scale} + \{label.offset}\n" +
  "- Frame (caller declaration): \{spec.coordinate_frame}\n" +
  "- Lower-left cell center: (\{spec.origin_x}, \{spec.origin_y}); square spacing \{spec.cell_size} \{spec.horizontal_unit}\n" +
  "- Vertical datum (caller declaration): \{declaration.datum}\n" +
  "- Uncertainty (caller declaration): \{declaration.uncertainty}\n" +
  "- Source, terms and limitations: \{spec.source_note}\n" +
  "- Input identity: \{digest(inputs.stringify())}\n\n" +
  "See decoded-samples.csv for raw codes and converted elevations. Missing and invalid codes remain unknown and are omitted from terrain.csv. Other signed codes are values; no missing code is guessed. Label extrema are retained text only, not trusted statistics.\n\n" +
  "The supplied grid controls coordinates. No map projection, georeferencing inference, vertical datum conversion, radius subtraction or interpolation is performed. Degree grids cannot use metre-only analyses. Floating-point scaling uses ordinary rounding; invalid intermediate arithmetic is refused.\n\n" +
  "Retain terrain-import.json to replay all three inputs. Subsequent edits are declarations and retain this original. This profile is not a general PDS3 validator or external lunar dataset qualification.\n").to_json()
  fields["limitations"] = [
    "Unverified caller-supplied source, grid, datum and uncertainty; no external dataset qualification.",
    "Only a bounded, detached, unpadded, one-band signed-16-bit IMAGE profile is supported. Unsupported label layouts are refused.",
    "Scaled quantity is explicitly declared elevation in metres. No radius subtraction, vertical conversion, projection or interpolation.",
    "Missing and invalid constants are checked in raw signed values before scaling; absent codes are not inferred.",
    "No mission acceptance, physical readiness or navigation authority.",
  ].to_json()
  bundle
}
