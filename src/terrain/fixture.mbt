///|
pub fn first_trusted_square_grid() -> TerrainGrid {
  let source_manifest = @dataset.first_trusted_square_manifest()
  let provenance = @dataset.to_provenance(source_manifest)
  let uncertainty = @core.uncertainty(
    0.72, "Synthetic DEM fixture shaped from lunar south-pole planning assumptions.",
  )
  let rows = generated_first_trusted_square_rows()
  let cols = generated_first_trusted_square_cols()
  let elevations = generated_first_trusted_square_elevations()
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
    tile_id: generated_first_trusted_square_tile_id(),
    rows,
    cols,
    cell_size_m: 10.0,
    source_manifest,
    cells,
  }
}

///|
pub fn first_trusted_square_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_grid())
}
