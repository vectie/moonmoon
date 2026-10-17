///|
/// Explore every destination in the declared four-neighbor terrain graph.
/// Budget is one-way metre-equivalent cost: distance + uphill_weight * ascent.
/// Unknown cells are excluded, never interpreted as traversable or impassable.
///
/// ```mbt check
/// test "explore a two-cell budget" {
///   let source = @terrain_import.import_bundle(
///     "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0", "example", "Synthetic local frame",
///     "m", "Synthetic only",
///   )
///   let study = @terrain_import.reachability_bundle(
///     source.stringify(),
///     0,
///     0,
///     0.0,
///     0.0,
///     10.0,
///   )
///   guard study is Object(fields) else { fail("Expected study") }
///   assert_eq(fields.get("physical_readiness"), Some(false.to_json()))
/// }
/// ```
pub fn reachability_bundle(
  source_bundle : String,
  start_row : Int,
  start_col : Int,
  max_grade_deg : Double,
  uphill_weight : Double,
  budget_m_equivalent : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = route_grid(source, max_grade_deg, uphill_weight)
  grid.cell_center(start_row, start_col) |> ignore
  let start = start_row * grid.cols + start_col
  need(grid.values[start] is Some(_), "Start cell has NODATA elevation")
  need(
    finite(budget_m_equivalent) && budget_m_equivalent >= 0.0,
    "Reachability budget must be finite and nonnegative",
  )
  let search = route_search(grid, start, None, max_grade_deg, uphill_weight)
  reachability_result(
    source, grid, search, start, max_grade_deg, uphill_weight, budget_m_equivalent,
  )
}

///|
fn reachability_status(
  elevation : Double?,
  cost : Double?,
  budget : Double,
) -> String {
  match (elevation, cost) {
    (None, _) => "unknown"
    (Some(_), None) => "not-connected-in-model"
    (Some(_), Some(value)) =>
      if value <= budget {
        "within-budget"
      } else {
        "over-budget"
      }
  }
}

///|
fn reachability_result(
  source : Json,
  grid : AsciiGrid,
  search : RouteSearch,
  start : Int,
  grade : Double,
  weight : Double,
  budget : Double,
) -> Json raise ImportError {
  let cells : Array[Json] = []
  let csv = [
    "row,col,x_m,y_m,elevation_m,status,minimum_cost_m_equivalent,remaining_budget_m_equivalent,predecessor_row,predecessor_col",
  ]
  let mut within = 0
  let mut over = 0
  let mut disconnected = 0
  let mut unknown = 0
  for index, elevation in grid.values {
    let row = index / grid.cols
    let col = index % grid.cols
    let (x, y) = grid.cell_center(row, col)
    let cost = search.costs[index]
    let status = reachability_status(elevation, cost, budget)
    match status {
      "within-budget" => within += 1
      "over-budget" => over += 1
      "unknown" => unknown += 1
      _ => disconnected += 1
    }
    let remaining = cost.map(value => budget - value)
    let previous = search.previous[index]
    let predecessor : Json = if previous < 0 {
      Json::null()
    } else {
      { "row": previous / grid.cols, "col": previous % grid.cols }
    }
    cells.push({
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "elevation_m": nullable(elevation),
      "status": status,
      "minimum_cost_m_equivalent": nullable(cost),
      "remaining_budget_m_equivalent": nullable(remaining),
      "predecessor": predecessor,
    })
    let previous_csv = if previous < 0 {
      ","
    } else {
      "\{previous / grid.cols},\{previous % grid.cols}"
    }
    csv.push(
      "\{row},\{col},\{x},\{y},\{csv_number(elevation)},\{status},\{csv_number(cost)},\{csv_number(remaining)},\{previous_csv}",
    )
  }
  let csv_text = csv.join("\n") + "\n"
  let svg = reachability_svg(grid, search.costs, start, budget)
  let tile = json_text(source, "tile_id")
  let frame = json_text(source, "coordinate_frame")
  let source_digest = json_text(source, "source_digest")
  let report = [
      "# Terrain destination exploration: \{tile}",
      "Start: row \{start / grid.cols}, col \{start % grid.cols}. Budget: \{budget} one-way metre-equivalent cost. Grade cap: \{grade} degrees; uphill preference: \{weight} (dimensionless).",
      "## Where can this graph take me?",
      "\{within} cells within budget (including the start), \{over} connected but over budget, \{disconnected} known cells not connected under this grade cap, \{unknown} unknown cells. These are cell-center destinations, not an area or physical traversability estimate.",
      "Open reachability.svg, then inspect reachability-cells.csv to choose a row/column. Use reach-path with the saved terrain-reachability.json to extract a within-budget candidate. Its path-cells.txt can be assessed by the existing corridor and energy-path commands. Change budget, grade or uphill preference by running reach again into a new directory; the original exploration stays intact.",
      "## Model",
      "One all-destination Dijkstra search uses the same four-neighbor known-cell graph as route. Each edge costs cell spacing + \{weight} times positive elevation rise. Ties select row-major cells and retain the first equal-cost predecessor. The budget boundary is inclusive. Costs are calculated beyond the budget too, so an over-budget destination is distinct from one not connected in this model. No diagonals or interpolation across NODATA. Numeric costs are floating-point estimates with no measurement-accuracy guarantee.",
      "## Source and limits",
      "Source: \{source_digest}. Declared frame: \{frame}. Full verified source bundle and assumptions are retained in terrain-reachability.json. Horizontal and elevation units must be declared metres; no reprojection or verification of source declarations is performed.",
      "Unknown cells have no cost. Not-connected-in-model means no path in this known-cell graph under the grade cap; it does not establish that no real route exists. A candidate can border unknown terrain. Coverage, subcell obstacles, footprint, clearance, cross-slope, roughness, energy, illumination and dynamics need separate assessment. This is ONE-WAY objective cost, not distance unless the uphill preference is zero, and never travel time, battery range or energy. No return allowance is reserved. No mission acceptance or physical readiness.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-reachability.v1",
    "method": "dijkstra-four-neighbor-all-destinations-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "parameters": {
      "start_row": start / grid.cols,
      "start_col": start % grid.cols,
      "max_grade_deg": grade,
      "uphill_weight": weight,
      "budget_m_equivalent": budget,
    },
    "summary": {
      "within_budget_cells": within,
      "over_budget_cells": over,
      "not_connected_cells": disconnected,
      "unknown_cells": unknown,
      "within_count_includes_start": true,
    },
    "cells": cells,
    "cells_csv": csv_text,
    "cells_csv_digest": digest(csv_text),
    "reachability_svg": svg,
    "reachability_svg_digest": digest(svg),
    "report_markdown": report,
    "report_digest": digest(report),
    "review_required": true,
    "physical_readiness": false,
  }
  let identity = digest(result.stringify())
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid reachability output")
  }
  fields["reachability_digest"] = identity.to_json()
  need(
    result.stringify(indent=2).length() + 1 <= 8388608,
    "Reachability bundle exceeds 8 MiB",
  )
  result
}

///|
/// Reopen a saved exploration and select an in-budget destination. Returns the
/// existing route contract plus the exact exploration identity and objective.
/// Over-budget, unknown and disconnected destinations are refused, not rerouted
/// with changed assumptions. The retained source is recomputed before selection.
///
/// ```mbt check
/// test "select a destination from retained exploration" {
///   let source = @terrain_import.import_bundle(
///     "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0", "example", "Synthetic local frame",
///     "m", "Synthetic only",
///   )
///   let study = @terrain_import.reachability_bundle(
///     source.stringify(),
///     0,
///     0,
///     0.0,
///     0.0,
///     10.0,
///   )
///   let selection = @terrain_import.reachability_path_bundle(
///     study.stringify(),
///     0,
///     1,
///   )
///   guard selection is Object(fields) else { fail("Expected selection") }
///   assert_eq(fields.get("minimum_cost_m_equivalent"), Some(10.0.to_json()))
/// }
/// ```
pub fn reachability_path_bundle(
  exploration_text : String,
  goal_row : Int,
  goal_col : Int,
) -> Json raise ImportError {
  need(
    exploration_text.length() <= 8388608,
    "Reachability bundle exceeds 8 MiB",
  )
  let saved = @json.parse(exploration_text) catch {
    _ => raise InvalidRaster("Invalid reachability JSON")
  }
  guard saved is Object(fields) &&
    fields.get("source_bundle") is Some(source) &&
    fields.get("parameters") is Some(Object(parameters)) else {
    raise InvalidRaster("Reachability needs its retained source and parameters")
  }
  fn value(key : String) -> Double raise ImportError {
    guard parameters.get(key) is Some(Number(value, ..)) else {
      raise InvalidRaster("Missing numeric reachability parameter " + key)
    }
    need(finite(value), "Reachability parameters must be finite")
    value
  }
  fn index(key : String) -> Int raise ImportError {
    let v = value(key)
    need(
      v >= 0.0 && v < 4096.0 && v == v.floor(),
      "Invalid reachability start index",
    )
    v.to_int()
  }
  let start_row = index("start_row")
  let start_col = index("start_col")
  let grade = value("max_grade_deg")
  let weight = value("uphill_weight")
  let budget = value("budget_m_equivalent")
  let expected = reachability_bundle(
    source.stringify(),
    start_row,
    start_col,
    grade,
    weight,
    budget,
  )
  need(
    saved == expected,
    "Saved reachability differs from its source, assumptions or results; run reach again to revise it",
  )
  let grid = route_grid(source, grade, weight)
  grid.cell_center(goal_row, goal_col) |> ignore
  let goal = goal_row * grid.cols + goal_col
  need(
    grid.values[goal] is Some(_),
    "Selected destination has unknown elevation",
  )
  let start = start_row * grid.cols + start_col
  let search = route_search(grid, start, Some(goal), grade, weight)
  guard search.costs[goal] is Some(cost) else {
    raise InvalidRaster("Selected destination is not connected in this model")
  }
  need(cost <= budget, "Selected destination exceeds this exploration's budget")
  let route = route_result(
    source,
    grid,
    search.path(start, goal),
    start,
    goal,
    grade,
    weight,
  )
  {
    "contract_id": "moonmoon.terrain-reachable-path.v1",
    "reachability_digest": json_text(expected, "reachability_digest"),
    "budget_m_equivalent": budget,
    "minimum_cost_m_equivalent": cost,
    "route": route,
    "review_required": true,
    "physical_readiness": false,
  }
}
