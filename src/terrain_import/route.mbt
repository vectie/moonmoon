///|
/// Find a minimum-cost four-neighbor route through known metric cell centers.
/// Cost is horizontal distance plus uphill_weight times positive elevation rise.
/// The grade cap is an absolute adjacent-center grade, not a 3x3 surface slope.
/// Equal-cost choices are deterministic in source row-major order.
pub fn route_bundle(
  source_bundle : String,
  start_row : Int,
  start_col : Int,
  goal_row : Int,
  goal_col : Int,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Json raise ImportError {
  let source = reopen_bundle(source_bundle)
  let grid = route_grid(source, max_grade_deg, uphill_weight)
  grid.cell_center(start_row, start_col) |> ignore
  grid.cell_center(goal_row, goal_col) |> ignore
  let start = start_row * grid.cols + start_col
  let goal = goal_row * grid.cols + goal_col
  need(grid.values[start] is Some(_), "Start cell has NODATA elevation")
  need(grid.values[goal] is Some(_), "Goal cell has NODATA elevation")
  let path = route_path(grid, start, goal, max_grade_deg, uphill_weight)
  route_result(source, grid, path, start, goal, max_grade_deg, uphill_weight)
}

///|
fn route_grid(
  source : Json,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> AsciiGrid raise ImportError {
  need(
    json_text(source, "horizontal_unit") == "m",
    "Routing requires declared metre cells; reproject degree grids separately",
  )
  need(
    finite(max_grade_deg) && max_grade_deg >= 0.0 && max_grade_deg < 90.0,
    "Maximum route grade must be finite, at least 0 and less than 90 degrees",
  )
  need(
    finite(uphill_weight) && uphill_weight >= 0.0,
    "Uphill weight must be finite and nonnegative",
  )
  bundle_grid(source)
}

///|
// Callers validate bounds and known endpoint elevations before searching.
fn route_path(
  grid : AsciiGrid,
  start : Int,
  goal : Int,
  max_grade_deg : Double,
  uphill_weight : Double,
) -> Array[Int] raise ImportError {
  let count = grid.values.length()
  let costs : Array[Double?] = Array::make(count, None)
  let previous = Array::make(count, -1)
  let visited = Array::make(count, false)
  costs[start] = Some(0.0)
  let mut reached = false
  // Bounded to 4096 cells by the importer. A dense Dijkstra selection avoids
  // introducing a dependency and gives explicit, stable tie behavior.
  for _ in 0..<count {
    let mut selected = -1
    let mut best = 0.0
    for index, cost in costs {
      if !visited[index] &&
        cost is Some(value) &&
        (selected < 0 || value < best) {
        selected = index
        best = value
      }
    }
    if selected < 0 {
      break
    }
    visited[selected] = true
    if selected == goal {
      reached = true
      break
    }
    let row = selected / grid.cols
    let col = selected % grid.cols
    let elevation = grid.values[selected].unwrap()
    for (dr, dc) in [(-1, 0), (0, -1), (0, 1), (1, 0)] {
      let r = row + dr
      let c = col + dc
      if r < 0 || c < 0 || r >= grid.rows || c >= grid.cols {
        continue
      }
      let next = r * grid.cols + c
      if visited[next] {
        continue
      }
      guard grid.values[next] is Some(z) else { continue }
      let rise = z - elevation
      let gradient = rise / grid.cell_size
      need(
        finite(rise) && finite(gradient),
        "Route elevation difference or grade overflows; rescale the source",
      )
      let grade = @math.atan(gradient.abs()) * 180.0 / @math.PI
      if grade > max_grade_deg {
        continue
      }
      let candidate = best + grid.cell_size + uphill_weight * rise.max(0.0)
      need(
        finite(candidate),
        "Route cost overflows; reduce the uphill weight or rescale the source",
      )
      if costs[next].map(old => candidate < old).unwrap_or(true) {
        costs[next] = Some(candidate)
        previous[next] = selected
      }
    }
  }
  let reversed : Array[Int] = []
  if reached {
    let mut at = goal
    while at != start {
      reversed.push(at)
      at = previous[at]
    }
    reversed.push(start)
  }
  Array::makei(reversed.length(), i => reversed[reversed.length() - i - 1])
}
