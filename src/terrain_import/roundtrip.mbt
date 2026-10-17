///|
/// Explore destinations whose minimum outbound plus return objective cost fits
/// a combined budget. This is a digital grid study, never an energy allowance.
pub fn roundtrip_bundle(
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
    "Round-trip budget must be finite and nonnegative",
  )
  let outbound = route_search(grid, start, None, max_grade_deg, uphill_weight)
  let returning = route_search(
    grid,
    start,
    None,
    max_grade_deg,
    uphill_weight,
    reverse_edges=true,
  )
  let totals : Array[Double?] = []
  let cells : Array[Json] = []
  let csv = [
    "row,col,status,outbound_cost_m_equivalent,return_cost_m_equivalent,combined_cost_m_equivalent,remaining_budget_m_equivalent",
  ]
  let mut within = 0
  let mut over = 0
  let mut disconnected = 0
  let mut unknown = 0
  for i, elevation in grid.values {
    let total = match (outbound.costs[i], returning.costs[i]) {
      (Some(a), Some(b)) => {
        need(finite(a + b), "Combined round-trip cost overflows")
        Some(a + b)
      }
      _ => None
    }
    totals.push(total)
    let status = reachability_status(elevation, total, budget_m_equivalent)
    match status {
      "within-budget" => within += 1
      "over-budget" => over += 1
      "unknown" => unknown += 1
      _ => disconnected += 1
    }
    let remaining = total.map(value => budget_m_equivalent - value)
    let row = i / grid.cols
    let col = i % grid.cols
    let (x, y) = grid.cell_center(row, col)
    cells.push({
      "row": row,
      "col": col,
      "x_m": x,
      "y_m": y,
      "elevation_m": nullable(elevation),
      "status": status,
      "outbound_cost_m_equivalent": nullable(outbound.costs[i]),
      "return_cost_m_equivalent": nullable(returning.costs[i]),
      "combined_cost_m_equivalent": nullable(total),
      "remaining_budget_m_equivalent": nullable(remaining),
    })
    csv.push(
      "\{row},\{col},\{status},\{csv_number(outbound.costs[i])},\{csv_number(returning.costs[i])},\{csv_number(total)},\{csv_number(remaining)}",
    )
  }
  let csv_text = csv.join("\n") + "\n"
  let svg = reachability_svg(grid, totals, start, budget_m_equivalent).replace(
    old="one-way",
    new="round-trip",
  )
  let report = [
      "# Round-trip destination exploration",
      "Start: row \{start_row}, col \{start_col}. Combined outbound + return budget: \{budget_m_equivalent} metre-equivalent units. Grade cap: \{max_grade_deg} degrees; uphill preference: \{uphill_weight}.",
      "\{within} within budget including start; \{over} connected but over budget; \{disconnected} known cells not connected in this model; \{unknown} unknown cells.",
      "Open reachability.svg and reachability-cells.csv, then select a within-budget row/column with the round-trip CLI. The saved terrain-roundtrip.json retains the exact terrain and assumptions. Selection emits separate outbound and return route contracts and ordered path files for existing assess-path, assess-corridor and energy-path tools. Recompute into a new directory to change assumptions or terrain.",
      "Two all-destination Dijkstra searches use the same four-neighbor known-cell graph: forward edge costs for outbound travel, reversed edge costs for return travel. Each directed edge costs cell spacing plus uphill preference times positive rise in that travel direction. The combined budget boundary is inclusive. Costs beyond the boundary distinguish over-budget from disconnected cells. Ties settle row-major cells and retain the first equal-cost predecessor. Return paths may retrace outbound paths; different geometry is not promised.",
      "Unknown cells are excluded, never filled. The grade cap is absolute adjacent-center grade, not a physical robot limit. No diagonals, interpolation, reprojection, subcell obstacle or clearance model. Floating-point costs are estimates. Source frame, units and provenance remain declarations. Not connected means no route in this model, not real-world impossibility.",
      "Combined objective cost is not battery, time or energy. Assess both ordered legs separately with explicit assumptions. Two independently sufficient energy results do not establish combined battery adequacy or a reserve. Negative energy remains a blocker. No mission acceptance, physical readiness or device action.",
    ].join("\n\n") +
    "\n"
  let result : Json = {
    "contract_id": "moonmoon.terrain-roundtrip.v1",
    "method": "forward-and-reverse-dijkstra-four-neighbor-v1",
    "source_bundle": source,
    "source_bundle_digest": digest(source.stringify()),
    "parameters": {
      "start_row": start_row,
      "start_col": start_col,
      "max_grade_deg": max_grade_deg,
      "uphill_weight": uphill_weight,
      "budget_m_equivalent": budget_m_equivalent,
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
  guard result is Object(fields) else {
    raise InvalidRaster("Invalid round-trip output")
  }
  fields["roundtrip_digest"] = digest(result.stringify()).to_json()
  need(
    result.stringify(indent=2).length() + 1 <= 8388608,
    "Round-trip bundle exceeds 8 MiB",
  )
  result
}

///|
/// Select both exact directed legs from a recomputed saved round-trip study.
/// Each route remains independently reusable by existing path assessment tools.
pub fn roundtrip_path_bundle(
  exploration_text : String,
  goal_row : Int,
  goal_col : Int,
) -> Json raise ImportError {
  need(exploration_text.length() <= 8388608, "Round-trip bundle exceeds 8 MiB")
  let saved = @json.parse(exploration_text) catch {
    _ => raise InvalidRaster("Invalid round-trip JSON")
  }
  guard saved is Object(fields) &&
    fields.get("source_bundle") is Some(source) &&
    fields.get("parameters") is Some(Object(parameters)) else {
    raise InvalidRaster("Round-trip study needs retained source and parameters")
  }
  fn value(key : String) -> Double raise ImportError {
    guard parameters.get(key) is Some(Number(v, ..)) else {
      raise InvalidRaster("Missing numeric round-trip parameter " + key)
    }
    need(finite(v), "Round-trip parameters must be finite")
    v
  }
  fn index(key : String) -> Int raise ImportError {
    let v = value(key)
    need(
      v >= 0.0 && v < 4096.0 && v == v.floor(),
      "Invalid round-trip start index",
    )
    v.to_int()
  }
  let sr = index("start_row")
  let sc = index("start_col")
  let grade = value("max_grade_deg")
  let weight = value("uphill_weight")
  let budget = value("budget_m_equivalent")
  let expected = roundtrip_bundle(
    source.stringify(),
    sr,
    sc,
    grade,
    weight,
    budget,
  )
  need(
    saved == expected,
    "Saved round-trip differs from source, assumptions or results; explore again",
  )
  let grid = route_grid(source, grade, weight)
  grid.cell_center(goal_row, goal_col) |> ignore
  let start = sr * grid.cols + sc
  let goal = goal_row * grid.cols + goal_col
  need(
    grid.values[goal] is Some(_),
    "Selected destination has unknown elevation",
  )
  let outbound = route_search(grid, start, Some(goal), grade, weight)
  let returning = route_search(
    grid,
    start,
    Some(goal),
    grade,
    weight,
    reverse_edges=true,
  )
  guard outbound.costs[goal] is Some(a) && returning.costs[goal] is Some(b) else {
    raise InvalidRaster("Selected destination is not connected in this model")
  }
  need(
    finite(a + b) && a + b <= budget,
    "Selected destination exceeds combined round-trip budget",
  )
  let reverse_path = returning.path(start, goal)
  let return_path = Array::makei(reverse_path.length(), i => {
    reverse_path[reverse_path.length() - i - 1]
  })
  {
    "contract_id": "moonmoon.terrain-roundtrip-path.v1",
    "roundtrip_digest": json_text(expected, "roundtrip_digest"),
    "budget_m_equivalent": budget,
    "outbound_cost_m_equivalent": a,
    "return_cost_m_equivalent": b,
    "combined_cost_m_equivalent": a + b,
    "outbound_route": route_result(
      source,
      grid,
      outbound.path(start, goal),
      start,
      goal,
      grade,
      weight,
    ),
    "return_route": route_result(
      source, grid, return_path, goal, start, grade, weight,
    ),
    "review_required": true,
    "physical_readiness": false,
  }
}
