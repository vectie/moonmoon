///|
fn coordinate_waypoint_index(
  value : Double,
  origin : Double,
  spacing : Double,
  size : Int,
  label : String,
) -> Int raise ImportError {
  let offset = (value - origin) / spacing
  need(finite(offset), "Waypoint coordinate offset overflows for " + label)
  let nearest = @math.round(offset)
  need(
    nearest >= 0.0 && nearest < size.to_double(),
    "Waypoint coordinate outside the source grid for " + label,
  )
  need(
    (offset - nearest).abs() <= 0.0000001,
    "Waypoint coordinate is not a source cell center for " + label,
  )
  nearest.to_int()
}

///|
// ASCII sources can describe spacings below the origin's numeric precision.
// Coordinate intake must not silently choose among indistinguishable centers.
fn coordinate_waypoint_geometry(grid : AsciiGrid) -> Unit raise ImportError {
  let (origin_x, origin_y) = grid.cell_center(grid.rows - 1, 0)
  let mut previous_x = origin_x
  for col in 1..<grid.cols {
    let (x, _) = grid.cell_center(grid.rows - 1, col)
    need(x > previous_x, "Source x cell centers are not distinguishable")
    need(
      coordinate_waypoint_index(
        x,
        origin_x,
        grid.cell_size,
        grid.cols,
        "source x",
      ) ==
      col,
      "Source x cell centers cannot be represented within coordinate tolerance",
    )
    previous_x = x
  }
  let mut previous_y = origin_y
  for upward in 1..<grid.rows {
    let (_, y) = grid.cell_center(grid.rows - 1 - upward, 0)
    need(y > previous_y, "Source y cell centers are not distinguishable")
    need(
      coordinate_waypoint_index(
        y,
        origin_y,
        grid.cell_size,
        grid.rows,
        "source y",
      ) ==
      upward,
      "Source y cell centers cannot be represented within coordinate tolerance",
    )
    previous_y = y
  }
}

///|
/// Connect 2–32 ordered x,y CSV stops in the source's declared metre frame.
/// Coordinates must match source cell centers within 1e-7 cell units per axis.
/// Retains original coordinates, their exact mapping, and the ordinary ordered
/// route outcome. No reprojection, arbitrary-point snapping or interpolation.
pub fn route_coordinate_waypoints_bundle(
  source_bundle : String,
  coordinates_csv : String,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = route_grid(source, max_grade_deg, uphill_weight)
  coordinate_waypoint_geometry(grid)
  need(
    coordinates_csv.length() <= 16384,
    "Coordinate waypoint CSV exceeds 16384 characters",
  )
  let lines = coordinates_csv.split("\n").collect()
  need(
    !lines.is_empty() && lines[0].trim() == "x,y",
    "Coordinate waypoint CSV must start with x,y in the source's declared metre frame",
  )
  let (origin_x, origin_y) = grid.cell_center(grid.rows - 1, 0)
  let normalized = ["row,col"]
  let mapping = ["stop,input_x,input_y,row,col,center_x,center_y"]
  let records : Array[Json] = []
  for line_index in 1..<lines.length() {
    let line = lines[line_index].trim()
    if line.is_empty() {
      continue
    }
    need(
      records.length() < 32,
      "Waypoint routing supports at most 32 ordered stops",
    )
    let parts = line.split(",").collect()
    let label = "CSV line \{line_index + 1}"
    need(parts.length() == 2, "Coordinate waypoint " + label + ": expected x,y")
    let x = number(parts[0].trim().to_owned(), label + " x")
    let y = number(parts[1].trim().to_owned(), label + " y")
    let col = coordinate_waypoint_index(
      x,
      origin_x,
      grid.cell_size,
      grid.cols,
      label + " x",
    )
    let row = grid.rows -
      1 -
      coordinate_waypoint_index(
        y,
        origin_y,
        grid.cell_size,
        grid.rows,
        label + " y",
      )
    let (center_x, center_y) = grid.cell_center(row, col)
    let stop = records.length()
    normalized.push("\{row},\{col}")
    mapping.push("\{stop},\{x},\{y},\{row},\{col},\{center_x},\{center_y}")
    records.push({
      "stop": stop,
      "input_x": x,
      "input_y": y,
      "row": row,
      "col": col,
      "center_x": center_x,
      "center_y": center_y,
    })
  }
  need(
    records.length() >= 2,
    "Waypoint routing requires at least two ordered stops",
  )
  let normalized_csv = normalized.join("\n") + "\n"
  let mapping_csv = mapping.join("\n") + "\n"
  let result = route_waypoints_from_grid(
    source, grid, normalized_csv, max_grade_deg, uphill_weight,
  )
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid internal coordinate waypoint result")
  }
  let report = json_text(result, "report_markdown") +
    "\n## Coordinate input\nInput x,y values use the source's declared metre frame. Each axis must be within 1e-7 cell units of a source cell center. coordinates.csv retains the exact original input; coordinate-mapping.csv records every input and selected center. waypoints.csv is the equivalent row,col input for the existing route command. No arbitrary-point snapping, reprojection or interpolation. The coordinate frame is caller-declared and not independently verified.\n"
  fields["contract_id"] = "moonmoon.terrain-coordinate-waypoint-route.v1".to_json()
  fields["coordinate_waypoints_csv"] = coordinates_csv.to_json()
  fields["coordinate_waypoints_csv_digest"] = digest(coordinates_csv).to_json()
  fields["coordinate_mapping_csv"] = mapping_csv.to_json()
  fields["coordinate_mapping_csv_digest"] = digest(mapping_csv).to_json()
  fields["coordinate_stops"] = records.to_json()
  fields["coordinate_tolerance_cells"] = 0.0000001.to_json()
  fields["coordinate_frame"] = json_text(source, "coordinate_frame").to_json()
  fields["horizontal_unit"] = "m".to_json()
  fields["report_markdown"] = report.to_json()
  fields.remove("route_digest")
  let identity = digest(result.stringify())
  fields["route_digest"] = identity.to_json()
  result
}
