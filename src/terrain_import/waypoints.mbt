///|
fn waypoint_cells(
  csv : String,
  grid : AsciiGrid,
) -> Array[Int] raise ImportError {
  need(csv.length() <= 16384, "Waypoint CSV exceeds 16384 characters")
  let lines = csv.split("\n").collect()
  need(
    !lines.is_empty() && lines[0].trim() == "row,col",
    "Waypoint CSV must start with row,col (zero-based source grid coordinates)",
  )
  let cells : Array[Int] = []
  for line_index in 1..<lines.length() {
    let line = lines[line_index].trim()
    if line.is_empty() {
      continue
    }
    let parts = line.split(",").collect()
    need(
      parts.length() == 2,
      "Waypoint CSV line \{line_index + 1}: expected row,col",
    )
    let row = @string.parse_int(parts[0].trim()) catch {
      _ =>
        raise InvalidRaster(
          "Waypoint CSV line \{line_index + 1}: row must be an integer",
        )
    }
    let col = @string.parse_int(parts[1].trim()) catch {
      _ =>
        raise InvalidRaster(
          "Waypoint CSV line \{line_index + 1}: column must be an integer",
        )
    }
    need(
      row >= 0 && row < grid.rows && col >= 0 && col < grid.cols,
      "Waypoint \{cells.length()} on CSV line \{line_index + 1} is outside the source grid",
    )
    cells.push(row * grid.cols + col)
    need(
      cells.length() <= 32,
      "Waypoint routing supports at most 32 ordered stops",
    )
  }
  need(
    cells.length() >= 2,
    "Waypoint routing requires at least two ordered stops",
  )
  cells
}

///|
fn route_field(value : Json, name : String) -> Json raise ImportError {
  guard value is Object(fields) && fields.get(name) is Some(field) else {
    raise InvalidRaster("Missing internal route field " + name)
  }
  field
}

///|
fn route_csv_metric(summary : Json, name : String) -> String raise ImportError {
  if summary is Null {
    ""
  } else {
    route_field(summary, name).stringify()
  }
}

///|
/// Route every adjacent pair of 2–32 explicitly ordered row,col CSV stops.
/// Later feasible legs stay independent after the first failure. Only the
/// connected prefix is concatenated, and incomplete routes have null totals.
pub fn route_waypoints_bundle(
  source_bundle : String,
  waypoints_csv : String,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = route_grid(source, max_grade_deg, uphill_weight)
  route_waypoints_from_grid(
    source, grid, waypoints_csv, max_grade_deg, uphill_weight,
  )
}

///|
fn route_waypoints_from_grid(
  source : Json,
  grid : AsciiGrid,
  waypoints_csv : String,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let stops = waypoint_cells(waypoints_csv, grid)
  let legs : Array[Json] = []
  let connected : Array[Int] = []
  let arrivals : Array[Int?] = Array::make(stops.length(), None)
  let lines = [
    "leg,from_stop,to_stop,start_row,start_col,goal_row,goal_col,status,in_connected_path,cell_count,horizontal_distance_m,ascent_m,descent_m,objective_cost_m",
  ]
  let descriptions : Array[String] = []
  let mut connected_open = true
  let mut first_failed : Int? = None
  for leg in 0..<(stops.length() - 1) {
    let start = stops[leg]
    let goal = stops[leg + 1]
    let start_known = grid.values[start] is Some(_)
    let goal_known = grid.values[goal] is Some(_)
    let path = if start_known && goal_known {
      route_path(grid, start, goal, max_grade_deg, uphill_weight)
    } else {
      []
    }
    let found = !path.is_empty()
    let status = if !start_known && !goal_known {
      "unknown-endpoints"
    } else if !start_known {
      "unknown-start"
    } else if !goal_known {
      "unknown-goal"
    } else if found {
      "candidate-found"
    } else {
      "no-path"
    }
    // Reuse the existing route accounting, not a second cost/grade model.
    let trace = route_result(
      source, grid, path, start, goal, max_grade_deg, uphill_weight,
    )
    let summary = route_field(trace, "summary")
    let included = connected_open && found
    let mut start_step : Int? = None
    let mut end_step : Int? = None
    if included {
      if connected.is_empty() {
        connected.push(start)
      }
      start_step = Some(connected.length() - 1)
      arrivals[leg] = start_step
      for step in 1..<path.length() {
        connected.push(path[step])
      }
      end_step = Some(connected.length() - 1)
      arrivals[leg + 1] = end_step
    }
    if !found {
      if first_failed is None {
        first_failed = Some(leg)
      }
      connected_open = false
    }
    let cells = path.map(index => {
      ({ "row": index / grid.cols, "col": index % grid.cols } : Json)
    })
    legs.push({
      "leg": leg,
      "from_stop": leg,
      "to_stop": leg + 1,
      "status": status,
      "in_connected_path": included,
      "connected_start_step": match start_step {
        Some(n) => n.to_json()
        None => Json::null()
      },
      "connected_end_step": match end_step {
        Some(n) => n.to_json()
        None => Json::null()
      },
      "summary": summary,
      "path_cells": cells,
    })
    let cell_count = route_csv_metric(summary, "cell_count")
    let distance = route_csv_metric(summary, "horizontal_distance_m")
    let ascent = route_csv_metric(summary, "ascent_m")
    let descent = route_csv_metric(summary, "descent_m")
    let cost = route_csv_metric(summary, "objective_cost_m")
    lines.push(
      "\{leg},\{leg},\{leg + 1},\{start / grid.cols},\{start % grid.cols},\{goal / grid.cols},\{goal % grid.cols},\{status},\{included},\{cell_count},\{distance},\{ascent},\{descent},\{cost}",
    )
    descriptions.push(
      "- Leg \{leg}: stop \{leg} (\{start / grid.cols},\{start % grid.cols}) to stop \{leg + 1} (\{goal / grid.cols},\{goal % grid.cols}): \{status}; included in connected path: \{included}.",
    )
  }
  let complete = first_failed is None
  let status = if complete { "complete-candidate" } else { "incomplete-route" }
  // The trace ends at the actual prefix endpoint, never at a disconnected stop.
  let prefix_goal = if connected.is_empty() {
    stops[0]
  } else {
    connected[connected.length() - 1]
  }
  let trace = route_result(
    source,
    grid,
    connected,
    stops[0],
    prefix_goal,
    max_grade_deg,
    uphill_weight,
  )
  let connected_summary = route_field(trace, "summary")
  let stop_records = stops.mapi((stop, index) => {
    (
      {
        "stop": stop,
        "row": index / grid.cols,
        "col": index % grid.cols,
        "elevation_m": nullable(grid.values[index]),
        "connected_path_step": match arrivals[stop] {
          Some(n) => n.to_json()
          None => Json::null()
        },
      } : Json)
  })
  let leg_csv = lines.join("\n") + "\n"
  let scope = if complete { "complete-route" } else { "connected-prefix-only" }
  let report = [
      "# Ordered terrain waypoints: \{status}",
      if complete {
        "Every leg has a candidate. complete-route.csv and complete-cells.txt contain the complete ordered route. Junction cells occur once; later revisits remain."
      } else {
        "INCOMPLETE ROUTE. Whole-route totals are unavailable (summary is null). incomplete-prefix-route.csv and incomplete-prefix-cells.txt contain ONLY the successful connected prefix before the first failed leg, possibly empty. Later successful legs are independent alternatives in the leg results; they are never joined across a gap."
      },
      "Source: " +
      json_text(source, "source_digest") +
      ". Declared frame: " +
      json_text(source, "coordinate_frame") +
      ". Stop and leg indexes are zero-based; rows increase down in the source grid.",
      "## Ordered leg outcomes\n" + descriptions.join("\n"),
      "## Method\nThe input order is mandatory: each adjacent pair uses the existing deterministic four-neighbor Dijkstra search. NODATA is excluded; unknown endpoints have explicit leg outcomes. Absolute adjacent-center grade cap: \{max_grade_deg} degrees. Cost = horizontal distance + \{uphill_weight} times positive elevation rise. All legs are attempted independently; no stop reordering, waypoint optimization or gap interpolation. Repeated stops make valid zero-length legs.",
      "## Files\nwaypoint-legs.csv has one outcome and totals per leg, with blank totals for failed legs. terrain-waypoint-route.json binds the exact input CSV, validated source, stops, per-leg cell paths, connected path and output digests. The complete-route.csv or incomplete-prefix-route.csv file uses the existing rich route columns, with cumulative values for its stated scope only. Retain the report and JSON alongside the CSV files.",
      "## Limits\nExploratory digital grid candidates only. Metre grids and at most 4096 cells, 2–32 stops. Source declarations are unverified. Adjacent-center grade is not surface slope or a subcell maximum. No physical readiness, energy, clearance, footprint, dynamics, mission acceptance or hardware authority. No new terrain or reprojection. A path may border unknown cells. Floating-point runtime differences remain possible.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-waypoint-route.v1",
    "method": "ordered-legs-dijkstra-four-neighbor-center-grade-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "waypoints_csv": waypoints_csv,
    "waypoints_csv_digest": digest(waypoints_csv),
    "parameters": {
      "max_grade_deg": max_grade_deg,
      "uphill_weight": uphill_weight,
    },
    "stops": stop_records,
    "legs": legs,
    "status": status,
    "route_complete": complete,
    "first_failed_leg": match first_failed {
      Some(n) => n.to_json()
      None => Json::null()
    },
    "summary": if complete {
      connected_summary
    } else {
      Json::null()
    },
    "connected_path_scope": scope,
    "connected_summary": connected_summary,
    "connected_path": route_field(trace, "path"),
    "connected_route_csv": route_field(trace, "route_csv"),
    "connected_route_csv_digest": route_field(trace, "route_csv_digest"),
    "connected_cells_text": route_field(trace, "path_cells_text"),
    "connected_cells_digest": route_field(trace, "path_cells_digest"),
    "legs_csv": leg_csv,
    "legs_csv_digest": digest(leg_csv),
    "report_markdown": report,
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid internal waypoint result")
  }
  fields["route_digest"] = identity.to_json()
  result
}
