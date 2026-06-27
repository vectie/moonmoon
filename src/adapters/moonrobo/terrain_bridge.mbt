///|
pub fn terrain_grid_heightfield(
  grid : @terrain.TerrainGrid,
) -> @moonphys.Heightfield {
  @moonphys.heightfield(
    grid.tile_id,
    grid.rows,
    grid.cols,
    grid.cell_size_m,
    grid.cells.map(fn(cell) { cell.elevation_m }),
  )
}

///|
pub fn first_trusted_square_noetix_heightfield() -> @moonphys.Heightfield {
  terrain_grid_heightfield(
    @terrain.first_trusted_square_northeast_stepout_grid(),
  )
}
