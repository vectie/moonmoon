///|
fn viewport_geometry(grid : @terrain.TerrainGrid) -> ViewportGeometry {
  let tile_width_px = 88
  let tile_height_px = 56
  {
    rows: grid.rows,
    cols: grid.cols,
    cell_size_m: grid.cell_size_m,
    tile_width_px,
    tile_height_px,
    viewport_width_px: grid.cols * tile_width_px,
    viewport_height_px: grid.rows * tile_height_px,
  }
}

///|
fn terrain_cell_views(
  grid : @terrain.TerrainGrid,
  metrics : @terrain.TerrainMetrics,
  energy : @mission.EnergyAssessment,
  selected : @core.TerrainCell,
) -> Array[TerrainCellView] {
  let viewport = viewport_geometry(grid)
  let cells : Array[TerrainCellView] = []
  for cell in grid.cells {
    let metric = cell_metric_pair(grid, cell)
    let slope_grade = metric.0
    let roughness_m = metric.1
    let hazard = cell_hazard(slope_grade, roughness_m)
    cells.push({
      cell_id: cell_id(grid, cell.row, cell.col),
      row: cell.row,
      col: cell.col,
      x_px: cell.col * viewport.tile_width_px,
      y_px: cell.row * viewport.tile_height_px,
      elevation_m: cell.elevation_m,
      slope_grade,
      roughness_m,
      hazard,
      selected: cell.row == selected.row && cell.col == selected.col,
      confidence: cell.uncertainty.confidence,
      source_dataset_id: grid.source_manifest.dataset_id,
      layer_values: cell_layer_values(
        cell, slope_grade, roughness_m, hazard, metrics, energy,
      ),
    })
  }
  cells
}
