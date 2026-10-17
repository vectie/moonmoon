///|
/// Preserve raw source bytes as UTF-8 text, provenance supplied by the user,
/// coordinate semantics, exact samples and sparse terrain CSV in one local bundle.
pub fn import_bundle(
  text : String,
  tile_id : String,
  coordinate_frame : String,
  horizontal_unit : String,
  source_note : String,
) -> Json raise ImportError {
  let grid = parse_ascii_grid(text)
  grid_bundle(
    grid, text, tile_id, coordinate_frame, horizontal_unit, source_note,
  )
}

///|
fn grid_bundle(
  grid : AsciiGrid,
  text : String,
  tile_id : String,
  coordinate_frame : String,
  horizontal_unit : String,
  source_note : String,
) -> Json raise ImportError {
  need(
    !coordinate_frame.trim().is_empty() && coordinate_frame.length() <= 500,
    "Name the source coordinate frame (up to 500 characters)",
  )
  need(
    horizontal_unit == "m" || horizontal_unit == "degrees",
    "Horizontal units must be m or degrees",
  )
  need(
    !source_note.trim().is_empty() && source_note.length() <= 2000,
    "Record the source, license and limitations (up to 2000 characters)",
  )
  let csv = grid.terrain_csv(tile_id)
  let samples : Array[Json] = []
  let mut count = 0
  let mut min : Double? = None
  let mut max : Double? = None
  for index, value in grid.values {
    let row = index / grid.cols
    let col = index % grid.cols
    let (x, y) = grid.cell_center(row, col)
    if value is Some(elevation) {
      count += 1
      min = Some(min.map(v => v.min(elevation)).unwrap_or(elevation))
      max = Some(max.map(v => v.max(elevation)).unwrap_or(elevation))
    }
    samples.push({
      "row": row,
      "col": col,
      "x": x,
      "y": y,
      "elevation_m": match value {
        Some(v) => v.to_json()
        None => Json::null()
      },
    })
  }
  {
    "contract_id": "moonmoon.terrain-import.v1",
    "format": "esri-ascii-grid",
    "tile_id": tile_id,
    "coordinate_frame": coordinate_frame,
    "horizontal_unit": horizontal_unit,
    "elevation_unit": "m",
    "row_order": "top-to-bottom",
    "coordinate_kind": "cell-center",
    "rows": grid.rows,
    "cols": grid.cols,
    "origin_x": grid.origin_x,
    "origin_y": grid.origin_y,
    "origin_kind": grid.origin_kind,
    "cell_size": grid.cell_size,
    "nodata_value": grid.nodata_value,
    "nodata_declared": grid.nodata_declared,
    "sample_count": count,
    "nodata_count": grid.values.length() - count,
    "minimum_elevation_m": match min {
      Some(v) => v.to_json()
      None => Json::null()
    },
    "maximum_elevation_m": match max {
      Some(v) => v.to_json()
      None => Json::null()
    },
    "source_note": source_note,
    "source_text": text,
    "source_digest": "sha256:" +
    @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text))),
    "terrain_csv": csv,
    "terrain_csv_digest": "sha256:" +
    @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(csv))),
    "samples": samples,
    "review_required": true,
    "physical_readiness": false,
    "limitations": [
      "User-supplied source and coordinate frame are unverified.", "Elevation values must already be metres; no vertical conversion is performed.",
      "NODATA is unknown coverage and is omitted from terrain CSV.", "No reprojection, interpolation, mission acceptance or physical authority.",
    ],
  }
}

///|
/// Browser boundary: typed MoonBit parser errors become a recoverable UI result.
pub fn import_json(
  text : String,
  tile_id : String,
  coordinate_frame : String,
  horizontal_unit : String,
  source_note : String,
) -> String {
  try {
    let bundle = import_bundle(
      text, tile_id, coordinate_frame, horizontal_unit, source_note,
    )
    ({ "ok": true, "bundle": bundle } : Json).stringify()
  } catch {
    InvalidRaster(message) =>
      ({ "ok": false, "error": message } : Json).stringify()
  }
}

///|
/// Recompute every exported field and digest from the retained source before
/// reopening. JSON formatting and key order are irrelevant; changed data is not.
pub fn reopen_bundle(text : String) -> Json raise ImportError {
  need(text.length() <= 4194304, "Terrain bundle exceeds 4 MiB character limit")
  let saved = @json.parse(text) catch {
    _ => raise InvalidRaster("Invalid terrain bundle JSON")
  }
  guard saved is Object(fields) else {
    raise InvalidRaster("Terrain bundle must be an object")
  }
  fn field(name : String) -> String raise ImportError {
    guard fields.get(name) is Some(String(value)) else {
      raise InvalidRaster("Missing text field " + name)
    }
    value
  }
  let current = match field("contract_id") {
    "moonmoon.terrain-import.v1" =>
      import_bundle(
        field("source_text"),
        field("tile_id"),
        field("coordinate_frame"),
        field("horizontal_unit"),
        field("source_note"),
      )
    "moonmoon.terrain-xyz-import.v1" =>
      import_xyz_bundle(field("source_text"), field("grid_specification_text"))
    "moonmoon.terrain-pds3-import.v1" =>
      import_pds3_bundle(
        field("source_text"),
        pds3_image_from_hex(field("image_hex")),
        field("image_name"),
        field("grid_specification_text"),
      )
    "moonmoon.terrain-revision.v1" => reopen_revision(saved)
    "moonmoon.terrain-mosaic.v1" => reopen_mosaic(saved)
    _ => raise InvalidRaster("Unsupported terrain source bundle")
  }
  need(
    saved == current,
    "Source bundle differs from its recomputed terrain data or digests",
  )
  current
}

///|
pub fn reopen_json(text : String) -> String {
  try {
    let bundle = reopen_bundle(text)
    ({ "ok": true, "bundle": bundle } : Json).stringify()
  } catch {
    InvalidRaster(message) =>
      ({ "ok": false, "error": message } : Json).stringify()
  }
}
