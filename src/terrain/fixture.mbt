///|
pub fn first_trusted_square_grid() -> TerrainGrid {
  let source_manifest = @dataset.first_trusted_square_manifest()
  let provenance = @dataset.to_provenance(source_manifest)
  let uncertainty = @core.uncertainty(
    0.72, "Synthetic DEM fixture shaped from lunar south-pole planning assumptions.",
  )
  let elevations = [
    [0.0, 0.8, 1.6, 2.1],
    [0.5, 1.2, 2.4, 3.2],
    [0.2, 1.4, 3.0, 4.7],
    [-0.3, 0.9, 2.8, 5.4],
  ]
  let cells : Array[@core.TerrainCell] = []
  for row in 0..<4 {
    for col in 0..<4 {
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
    tile_id: "first-trusted-square",
    rows: 4,
    cols: 4,
    cell_size_m: 10.0,
    source_manifest,
    cells,
  }
}

///|
pub fn first_trusted_square_metrics() -> TerrainMetrics {
  analyze(first_trusted_square_grid())
}
