///|
priv struct XyzSpecification {
  tile_id : String
  coordinate_frame : String
  horizontal_unit : String
  source_note : String
  rows : Int
  cols : Int
  origin_x : Double
  origin_y : Double
  cell_size : Double
}

///|
fn xyz_specification(text : String) -> XyzSpecification raise ImportError {
  need(
    text.length() <= 16384,
    "XYZ grid declaration exceeds 16 KiB character limit",
  )
  let specification = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid XYZ grid declaration JSON")
  }
  guard specification is Object(fields) else {
    raise InvalidRaster("XYZ grid declaration must be an object")
  }
  let keys = [
    "contract_id", "tile_id", "coordinate_frame", "horizontal_unit", "source_note",
    "rows", "cols", "origin_x", "origin_y", "cell_size",
  ]
  for key, _ in fields {
    need(keys.contains(key), "Unsupported XYZ grid declaration field " + key)
  }
  need(
    json_text(specification, "contract_id") == "moonmoon.xyz-grid.v1",
    "Unsupported XYZ grid declaration",
  )
  fn numeric(name : String) -> Double raise ImportError {
    guard fields.get(name) is Some(Number(value, ..)) else {
      raise InvalidRaster("Missing numeric XYZ grid field " + name)
    }
    need(finite(value), "Nonfinite XYZ grid field " + name)
    value
  }
  fn size(name : String) -> Int raise ImportError {
    let value = numeric(name)
    need(
      value >= 1.0 && value <= 4096.0 && @math.floor(value) == value,
      "XYZ " + name + " must be an integer between 1 and 4096",
    )
    value.to_int()
  }
  let rows = size("rows")
  let cols = size("cols")
  need(rows * cols <= 4096, "XYZ grid supports at most 4096 cells")
  let origin_x = numeric("origin_x")
  let origin_y = numeric("origin_y")
  let cell_size = numeric("cell_size")
  need(cell_size > 0.0, "XYZ cell_size must be positive")
  let max_x = origin_x + (cols - 1).to_double() * cell_size
  let max_y = origin_y + (rows - 1).to_double() * cell_size
  need(finite(max_x) && finite(max_y), "XYZ grid coordinate extent overflows")
  need(
    (
      cols == 1 ||
      (origin_x + cell_size > origin_x && max_x - cell_size < max_x)
    ) &&
    (
      rows == 1 ||
      (origin_y + cell_size > origin_y && max_y - cell_size < max_y)
    ),
    "XYZ grid spacing is not representable at the declared origin",
  )
  {
    tile_id: json_text(specification, "tile_id"),
    coordinate_frame: json_text(specification, "coordinate_frame"),
    horizontal_unit: json_text(specification, "horizontal_unit"),
    source_note: json_text(specification, "source_note"),
    rows,
    cols,
    origin_x,
    origin_y,
    cell_size,
  }
}

///|
fn xyz_index(
  coordinate : Double,
  origin : Double,
  spacing : Double,
  size : Int,
  label : String,
) -> Int raise ImportError {
  let offset = (coordinate - origin) / spacing
  need(finite(offset), "XYZ coordinate offset overflows for " + label)
  let nearest = @math.round(offset)
  need(
    nearest >= 0.0 && nearest < size.to_double(),
    "XYZ coordinate outside declared grid for " + label,
  )
  need(
    (offset - nearest).abs() <= 0.0000001,
    "XYZ coordinate is not a declared cell center for " + label,
  )
  nearest.to_int()
}

///|
fn xyz_grid(
  text : String,
  spec : XyzSpecification,
) -> AsciiGrid raise ImportError {
  need(text.length() <= 1048576, "XYZ CSV exceeds 1 MiB character limit")
  let lines = text.split("\n").collect()
  need(
    !lines.is_empty() && lines[0].trim() == "x,y,elevation_m",
    "XYZ CSV requires the exact x,y,elevation_m header",
  )
  let values : Array[Double?] = Array::make(spec.rows * spec.cols, None)
  let occupied = Array::make(spec.rows * spec.cols, false)
  let mut records = 0
  for line_number in 1..<lines.length() {
    let line = lines[line_number].trim()
    if line.is_empty() {
      continue
    }
    records += 1
    need(records <= 4096, "XYZ CSV supports at most 4096 point records")
    let fields = line.split(",").map(v => v.trim().to_owned()).collect()
    need(
      fields.length() == 3,
      "XYZ CSV line " +
      (line_number + 1).to_string() +
      " needs three numeric fields",
    )
    let label = "CSV line " + (line_number + 1).to_string()
    let x = number(fields[0], label + " x")
    let y = number(fields[1], label + " y")
    let elevation = number(fields[2], label + " elevation_m")
    let col = xyz_index(
      x,
      spec.origin_x,
      spec.cell_size,
      spec.cols,
      label + " x",
    )
    let row = spec.rows -
      1 -
      xyz_index(y, spec.origin_y, spec.cell_size, spec.rows, label + " y")
    let index = row * spec.cols + col
    need(
      !occupied[index],
      "Duplicate XYZ cell at " +
      label +
      "; choose one observation before import",
    )
    occupied[index] = true
    values[index] = Some(elevation)
  }
  {
    rows: spec.rows,
    cols: spec.cols,
    origin_x: spec.origin_x,
    origin_y: spec.origin_y,
    origin_kind: "center",
    cell_size: spec.cell_size,
    // CSV has no numeric missing-value sentinel. The exported field is null.
    nodata_value: -9999.0,
    nodata_declared: false,
    values,
  }
}

///|
/// Import grid-aligned x,y,elevation_m observations in arbitrary row order.
/// The declaration fixes extent and lower-left cell center. Missing rows in the
/// CSV stay unknown; all finite elevations, including -9999, are observations.
/// Coordinates must be within 1e-7 cell units of a declared center. No
/// interpolation, CRS inference, vertical conversion or duplicate aggregation.
pub fn import_xyz_bundle(
  text : String,
  specification_text : String,
) -> Json raise ImportError {
  let spec = xyz_specification(specification_text)
  let grid = xyz_grid(text, spec)
  let bundle = grid_bundle(
    grid,
    text,
    spec.tile_id,
    spec.coordinate_frame,
    spec.horizontal_unit,
    spec.source_note,
  )
  guard bundle is Object(fields) else {
    raise InvalidRaster("Invalid internal XYZ bundle")
  }
  fields["contract_id"] = "moonmoon.terrain-xyz-import.v1".to_json()
  fields["format"] = "xyz-csv-regular-grid".to_json()
  fields["nodata_value"] = Json::null()
  fields["grid_specification_text"] = specification_text.to_json()
  fields["grid_specification_digest"] = digest(specification_text).to_json()
  fields["coordinate_tolerance_cells"] = 0.0000001.to_json()
  fields["limitations"] = [
    "User-supplied source, grid declaration and coordinate frame are unverified.",
    "Elevation values must already be metres; no vertical conversion is performed.",
    "Absent CSV cells are unknown and omitted from terrain CSV; no numeric missing-value sentinel is used.",
    "Input order is ignored; coordinates map to declared centers within 1e-7 cell units. Duplicate cells are rejected.",
    "No reprojection, interpolation, mission acceptance or physical authority.",
  ].to_json()
  bundle
}

///|
// Only called after reopen_bundle has recomputed and verified the full bundle.
fn bundle_grid(source : Json) -> AsciiGrid raise ImportError {
  if json_text(source, "contract_id") == "moonmoon.terrain-revision.v1" {
    revision_grid(source)
  } else if json_text(source, "contract_id") == "moonmoon.terrain-mosaic.v1" {
    mosaic_grid(source)
  } else if json_text(source, "contract_id") == "moonmoon.terrain-xyz-import.v1" {
    xyz_grid(
      json_text(source, "source_text"),
      xyz_specification(json_text(source, "grid_specification_text")),
    )
  } else if json_text(source, "contract_id") ==
    "moonmoon.terrain-pds3-import.v1" {
    let label = pds3_label(
      json_text(source, "source_text"),
      json_text(source, "image_name"),
    )
    let declaration = pds3_declaration(
      json_text(source, "grid_specification_text"),
    )
    let (grid, _) = pds3_grid(
      pds3_image_from_hex(json_text(source, "image_hex")),
      label,
      declaration,
    )
    grid
  } else {
    parse_ascii_grid(json_text(source, "source_text"))
  }
}
