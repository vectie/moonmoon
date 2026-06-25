///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn clamp_int(value : Int, min_value : Int, max_value : Int) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn terrain_cell_at(
  grid : @terrain.TerrainGrid,
  row : Int,
  col : Int,
) -> @core.TerrainCell? {
  if row < 0 || col < 0 || row >= grid.rows || col >= grid.cols {
    None
  } else {
    grid.cells.get(row * grid.cols + col)
  }
}

///|
fn selected_cell(
  grid : @terrain.TerrainGrid,
  row : Int,
  col : Int,
) -> @core.TerrainCell {
  let bounded_row = clamp_int(row, 0, grid.rows - 1)
  let bounded_col = clamp_int(col, 0, grid.cols - 1)
  terrain_cell_at(grid, bounded_row, bounded_col).unwrap()
}

///|
fn cell_metric_pair(
  grid : @terrain.TerrainGrid,
  cell : @core.TerrainCell,
) -> (Double, Double) {
  let mut max_delta = 0.0
  let mut total_delta = 0.0
  let mut neighbor_count = 0
  match terrain_cell_at(grid, cell.row - 1, cell.col) {
    Some(neighbor) => {
      let delta = abs_double(cell.elevation_m - neighbor.elevation_m)
      total_delta += delta
      neighbor_count += 1
      if delta > max_delta {
        max_delta = delta
      }
    }
    None => ()
  }
  match terrain_cell_at(grid, cell.row + 1, cell.col) {
    Some(neighbor) => {
      let delta = abs_double(cell.elevation_m - neighbor.elevation_m)
      total_delta += delta
      neighbor_count += 1
      if delta > max_delta {
        max_delta = delta
      }
    }
    None => ()
  }
  match terrain_cell_at(grid, cell.row, cell.col - 1) {
    Some(neighbor) => {
      let delta = abs_double(cell.elevation_m - neighbor.elevation_m)
      total_delta += delta
      neighbor_count += 1
      if delta > max_delta {
        max_delta = delta
      }
    }
    None => ()
  }
  match terrain_cell_at(grid, cell.row, cell.col + 1) {
    Some(neighbor) => {
      let delta = abs_double(cell.elevation_m - neighbor.elevation_m)
      total_delta += delta
      neighbor_count += 1
      if delta > max_delta {
        max_delta = delta
      }
    }
    None => ()
  }
  let slope_grade = if grid.cell_size_m <= 0.0 {
    0.0
  } else {
    max_delta / grid.cell_size_m
  }
  let roughness_m = if neighbor_count == 0 {
    0.0
  } else {
    total_delta / neighbor_count.to_double()
  }
  (slope_grade, roughness_m)
}

///|
fn cell_hazard(slope_grade : Double, roughness_m : Double) -> String {
  if slope_grade >= 0.35 || roughness_m >= 2.5 {
    "blocked"
  } else if slope_grade >= 0.18 || roughness_m >= 1.2 {
    "caution"
  } else {
    "clear"
  }
}

///|
fn default_selected_cell(grid : @terrain.TerrainGrid) -> @core.TerrainCell {
  let mut selected = grid.cells.get(0).unwrap()
  let mut selected_risk = 0.0
  for cell in grid.cells {
    let metric = cell_metric_pair(grid, cell)
    let risk = metric.0 * 10.0 + metric.1
    if risk > selected_risk {
      selected = cell
      selected_risk = risk
    }
  }
  selected
}

///|
fn cell_id(grid : @terrain.TerrainGrid, row : Int, col : Int) -> String {
  "\{grid.tile_id}/r\{row}-c\{col}"
}
