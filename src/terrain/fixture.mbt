///|
fn build_grid(
  source_manifest : TerrainSourceManifest,
  tile_id : String,
  rows : Int,
  cols : Int,
  elevations : Array[Array[Double]],
) -> TerrainGrid {
  let provenance = terrain_source_provenance(source_manifest)
  let uncertainty = @core.uncertainty(
    0.82, "LOLA GDR byte-range extraction accepted for MoonMoon software proof; not mission certification.",
  )
  let cells : Array[@core.TerrainCell] = []
  for row in 0..<rows {
    for col in 0..<cols {
      cells.push({
        tile_id: "trusted-square-r\{row}-c\{col}",
        row,
        col,
        elevation_m: elevations[row][col],
        provenance,
        uncertainty,
      })
    }
  }
  {
    tile_id,
    rows,
    cols,
    cell_size_m: source_manifest.resolution_m,
    source_manifest,
    cells,
  }
}

///|
pub fn first_trusted_square_grid() -> TerrainGrid {
  build_grid(
    first_trusted_square_source_manifest(),
    generated_first_trusted_square_tile_id(),
    generated_first_trusted_square_rows(),
    generated_first_trusted_square_cols(),
    generated_first_trusted_square_elevations(),
  )
}

///|
pub fn first_trusted_square_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_grid())
}

///|
pub fn first_trusted_square_west_contour_grid() -> TerrainGrid {
  build_grid(
    first_trusted_square_west_contour_source_manifest(),
    generated_first_trusted_square_west_contour_tile_id(),
    generated_first_trusted_square_west_contour_rows(),
    generated_first_trusted_square_west_contour_cols(),
    generated_first_trusted_square_west_contour_elevations(),
  )
}

///|
pub fn first_trusted_square_west_contour_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_west_contour_grid())
}

///|
pub fn first_trusted_square_north_rim_grid() -> TerrainGrid {
  build_grid(
    first_trusted_square_north_rim_source_manifest(),
    generated_first_trusted_square_north_rim_tile_id(),
    generated_first_trusted_square_north_rim_rows(),
    generated_first_trusted_square_north_rim_cols(),
    generated_first_trusted_square_north_rim_elevations(),
  )
}

///|
pub fn first_trusted_square_north_rim_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_north_rim_grid())
}

///|
pub fn first_trusted_square_southwest_bypass_grid() -> TerrainGrid {
  build_grid(
    first_trusted_square_southwest_bypass_source_manifest(),
    generated_first_trusted_square_southwest_bypass_tile_id(),
    generated_first_trusted_square_southwest_bypass_rows(),
    generated_first_trusted_square_southwest_bypass_cols(),
    generated_first_trusted_square_southwest_bypass_elevations(),
  )
}

///|
pub fn first_trusted_square_southwest_bypass_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_southwest_bypass_grid())
}

///|
pub fn first_trusted_square_south_stepout_grid() -> TerrainGrid {
  build_grid(
    first_trusted_square_south_stepout_source_manifest(),
    generated_first_trusted_square_south_stepout_tile_id(),
    generated_first_trusted_square_south_stepout_rows(),
    generated_first_trusted_square_south_stepout_cols(),
    generated_first_trusted_square_south_stepout_elevations(),
  )
}

///|
pub fn first_trusted_square_south_stepout_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_south_stepout_grid())
}

///|
pub fn first_trusted_square_northeast_stepout_grid() -> TerrainGrid {
  build_grid(
    first_trusted_square_northeast_stepout_source_manifest(),
    generated_first_trusted_square_northeast_stepout_tile_id(),
    generated_first_trusted_square_northeast_stepout_rows(),
    generated_first_trusted_square_northeast_stepout_cols(),
    generated_first_trusted_square_northeast_stepout_elevations(),
  )
}

///|
pub fn first_trusted_square_northeast_stepout_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_northeast_stepout_grid())
}

///|
pub fn first_trusted_square_route_grids() -> Array[TerrainGrid] {
  [
    first_trusted_square_west_contour_grid(),
    first_trusted_square_north_rim_grid(),
    first_trusted_square_southwest_bypass_grid(),
    first_trusted_square_south_stepout_grid(),
    first_trusted_square_northeast_stepout_grid(),
  ]
}
