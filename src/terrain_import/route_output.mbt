///|
fn route_result(
  source : Json,
  grid : AsciiGrid,
  path : Array[Int],
  start : Int,
  goal : Int,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let points : Array[Json] = []
  let csv_lines = [
    "step,row,col,x_m,y_m,elevation_m,distance_m,rise_m,grade_deg,cumulative_ascent_m,cumulative_descent_m,cumulative_cost_m",
  ]
  let path_lines : Array[String] = []
  let mut ascent = 0.0
  let mut descent = 0.0
  let mut distance = 0.0
  let mut surface_distance = 0.0
  let mut peak_grade = 0.0
  for step, index in path {
    let row = index / grid.cols
    let col = index % grid.cols
    let (x, y) = grid.cell_center(row, col)
    let z = grid.values[index].unwrap()
    let mut rise : Double? = None
    let mut grade : Double? = None
    if step > 0 {
      let dz = z - grid.values[path[step - 1]].unwrap()
      let angle = @math.atan(dz / grid.cell_size) * 180.0 / @math.PI
      rise = Some(dz)
      grade = Some(angle)
      distance += grid.cell_size
      surface_distance += @math.hypot(grid.cell_size, dz)
      ascent += dz.max(0.0)
      descent += (-dz).max(0.0)
      peak_grade = peak_grade.max(angle.abs())
    }
    let cost = distance + uphill_weight * ascent
    need(
      finite(distance) &&
      finite(surface_distance) &&
      finite(ascent) &&
      finite(descent) &&
      finite(cost),
      "Route totals overflow; rescale the source or cost",
    )
    points.push({
      "step": step,
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "elevation_m": z,
      "distance_m": distance,
      "rise_m": nullable(rise),
      "grade_deg": nullable(grade),
      "cumulative_ascent_m": ascent,
      "cumulative_descent_m": descent,
      "cumulative_cost_m": cost,
    })
    csv_lines.push(
      "\{step},\{row},\{col},\{x},\{y},\{z},\{distance},\{csv_number(rise)},\{csv_number(grade)},\{ascent},\{descent},\{cost}",
    )
    path_lines.push("\{row},\{col}")
  }
  let found = !path.is_empty()
  let status = if found { "candidate-found" } else { "no-path" }
  let csv = csv_lines.join("\n") + "\n"
  let path_text = if found { path_lines.join("\n") + "\n" } else { "" }
  let svg = route_svg(grid, path, start, goal)
  let tile = json_text(source, "tile_id")
  let frame = json_text(source, "coordinate_frame")
  let source_digest = json_text(source, "source_digest")
  let cost = distance + uphill_weight * ascent
  let route_summary = if found {
    "Candidate contains \{path.length()} cells: \{distance} m horizontal distance, \{surface_distance} m piecewise 3D distance, \{ascent} m ascent, \{descent} m descent. Maximum absolute adjacent grade \{peak_grade} degrees. Objective cost \{cost} metre-equivalent units."
  } else {
    "No route connects these endpoints in the known-cell four-neighbor graph under this grade cap. This does not establish that no real-world route exists. Inspect coverage, endpoints and assumptions before trying another candidate. No route totals are reported."
  }
  let report = [
      "# Local terrain route: \{tile}",
      "Result: \{status}. Source: \{source_digest}. Declared frame: \{frame}. Elevations and horizontal spacing are declared metres.",
      "Start: row \{start / grid.cols}, column \{start % grid.cols}. Goal: row \{goal / grid.cols}, column \{goal % grid.cols}.",
      "## Candidate",
      route_summary,
      "## Method and assumptions",
      "Dijkstra minimum-cost routing on four-neighbor cell centers; no diagonals. NODATA cells are excluded. Absolute adjacent-center grade must be at most \{max_grade_deg} degrees. Edge cost = horizontal cell spacing + \{uphill_weight} times positive elevation rise. Weight is a dimensionless preference, not a physical energy model. Ties select the first row-major minimum and retain the first equal-cost predecessor. Reversing endpoints can change the route because ascent cost is directional.",
      "## Files",
      "route.csv contains every ordered center, signed segment grade and cumulative totals. path-cells.txt has row,column pairs without a header for manual reuse where supported. route.svg plots the raster and candidate. terrain-route.json retains source, parameters, results and exact output digests. Save the whole output directory.",
      "## Limits",
      "Exploratory digital grid candidate only. The grade between neighboring centers is not the 3x3 surface slope or subcell maximum. Missing cells are never filled. A path can border unknown terrain. No clearance, footprint, cross-slope, roughness, illumination, energy, dynamics, mission acceptance or physical readiness is evaluated. The route is optimal only for this declared discrete graph and objective. Source declarations are unverified. No interpolation or reprojection. Existing frozen mission inputs remain unchanged.",
    ].join("\n\n") +
    "\n"
  let summary : Json = if found {
    {
      "cell_count": path.length(),
      "horizontal_distance_m": distance,
      "piecewise_3d_distance_m": surface_distance,
      "ascent_m": ascent,
      "descent_m": descent,
      "max_absolute_grade_deg": peak_grade,
      "objective_cost_m": cost,
    }
  } else {
    Json::null()
  }
  let result : Json = {
    "contract_id": "moonmoon.terrain-route.v1",
    "method": "dijkstra-four-neighbor-center-grade-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "parameters": {
      "start_row": start / grid.cols,
      "start_col": start % grid.cols,
      "goal_row": goal / grid.cols,
      "goal_col": goal % grid.cols,
      "max_grade_deg": max_grade_deg,
      "uphill_weight": uphill_weight,
    },
    "status": status,
    "summary": summary,
    "path": points,
    "route_csv": csv,
    "route_csv_digest": digest(csv),
    "path_cells_text": path_text,
    "path_cells_digest": digest(path_text),
    "route_svg": svg,
    "route_svg_digest": digest(svg),
    "report_markdown": report,
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid internal route result")
  }
  fields["route_digest"] = identity.to_json()
  result
}

///|
fn route_svg(
  grid : AsciiGrid,
  path : Array[Int],
  start : Int,
  goal : Int,
) -> String {
  let size = (720.0 / grid.cols.to_double()).min(560.0 / grid.rows.to_double())
  let left = (860.0 - grid.cols.to_double() * size) / 2.0
  let top = 80.0
  let mut low = 0.0
  let mut high = 0.0
  let mut seen = false
  for value in grid.values {
    if value is Some(z) {
      if !seen {
        low = z
        high = z
        seen = true
      }
      low = low.min(z)
      high = high.max(z)
    }
  }
  let lines = [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"860\" height=\"740\" viewBox=\"0 0 860 740\" role=\"img\" aria-labelledby=\"title description\">",
    "<title id=\"title\">Imported terrain candidate route</title>", "<desc id=\"description\">Cell-center four-neighbor route. Rows increase down and columns right. Gray crossed cells are unknown. This is an exploratory grid path, not mission or physical readiness.</desc>",
    "<rect width=\"860\" height=\"740\" fill=\"#111827\"/>", "<g font-family=\"sans-serif\" fill=\"#f9fafb\"><text x=\"28\" y=\"30\" font-size=\"22\">Imported terrain candidate route</text><text x=\"28\" y=\"55\" font-size=\"14\">Rows increase down; columns right. Cell centers, no geographic orientation inferred.</text></g>",
  ]
  for index, value in grid.values {
    let x = left + (index % grid.cols).to_double() * size
    let y = top + (index / grid.cols).to_double() * size
    let color = match value {
      None => "#64748b"
      Some(z) => {
        // Scale before subtraction, so finite extreme elevations cannot overflow.
        let scale = low.abs().max(high.abs()).max(1.0)
        let span = high / scale - low / scale
        let fraction = if span == 0.0 {
          0.5
        } else {
          (z / scale - low / scale) / span
        }
        let hue = 220.0 - fraction * 190.0
        "hsl(\{hue},65%,50%)"
      }
    }
    lines.push(
      "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{size}\" height=\"\{size}\" fill=\"\{color}\" stroke=\"#111827\" stroke-width=\"0.4\"><title>row \{index / grid.cols}, col \{index % grid.cols}: \{csv_number(value)} m</title></rect>",
    )
    if value is None {
      lines.push(
        "<path d=\"M \{x} \{y} l \{size} \{size} M \{x + size} \{y} l \{-size} \{size}\" stroke=\"#334155\" stroke-width=\"1\"/>",
      )
    }
  }
  let points = path
    .map(index => {
      let x = left + ((index % grid.cols).to_double() + 0.5) * size
      let y = top + ((index / grid.cols).to_double() + 0.5) * size
      "\{x},\{y}"
    })
    .join(" ")
  if !path.is_empty() {
    lines.push(
      "<polyline points=\"\{points}\" fill=\"none\" stroke=\"#111827\" stroke-width=\"6\"/><polyline points=\"\{points}\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"3\"/>",
    )
  }
  for
    (index, color, label) in [
      (start, "#34d399", "Start"),
      (goal, "#f472b6", "Goal"),
    ] {
    let x = left + ((index % grid.cols).to_double() + 0.5) * size
    let y = top + ((index / grid.cols).to_double() + 0.5) * size
    let radius = (size * 0.25).min(9.0).max(2.0)
    lines.push(
      "<circle cx=\"\{x}\" cy=\"\{y}\" r=\"\{radius}\" fill=\"\{color}\" stroke=\"#111827\" stroke-width=\"2\"><title>\{label}: row \{index / grid.cols}, col \{index % grid.cols}</title></circle>",
    )
  }
  let caption = if path.is_empty() {
    "No path under these assumptions. See the report."
  } else {
    "White: candidate path. Green: start. Pink: goal. See route.csv for exact steps."
  }
  lines.push(
    "<g font-family=\"sans-serif\" fill=\"#f9fafb\" font-size=\"14\"><text x=\"28\" y=\"670\">\{caption}</text><text x=\"28\" y=\"695\">Elevation color: blue (\{low} m) to orange (\{high} m); gray crossed cells: NODATA.</text><text x=\"28\" y=\"720\">Exploratory grid candidate. No clearance, energy, rover suitability or physical readiness.</text></g></svg>",
  )
  lines.join("\n") + "\n"
}
