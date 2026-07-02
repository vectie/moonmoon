///|
pub(all) enum HazardClass {
  Clear
  Caution
  Blocked
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainGrid {
  tile_id : String
  rows : Int
  cols : Int
  cell_size_m : Double
  source_manifest : @dataset.DatasetManifest
  cells : Array[@core.TerrainCell]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainMetrics {
  min_elevation_m : Double
  max_elevation_m : Double
  elevation_range_m : Double
  max_neighbor_grade : Double
  roughness_m : Double
  hazard_class : HazardClass
  hazard_reason : String
  provenance : @core.Provenance
  uncertainty : @core.Uncertainty
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum TerrainFixtureValidationStatus {
  Verified
  FingerprintMismatch
  MissingFingerprint
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainFixtureValidation {
  dataset_id : @core.DatasetId
  expected_fingerprint : String
  actual_fingerprint : String
  status : TerrainFixtureValidationStatus
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn hazard_label(hazard : HazardClass) -> String {
  match hazard {
    Clear => "clear"
    Caution => "caution"
    Blocked => "blocked"
  }
}

///|
pub fn terrain_fixture_validation_status_label(
  status : TerrainFixtureValidationStatus,
) -> String {
  match status {
    Verified => "verified"
    FingerprintMismatch => "fingerprint-mismatch"
    MissingFingerprint => "missing-fingerprint"
  }
}

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn cell_at(grid : TerrainGrid, row : Int, col : Int) -> @core.TerrainCell? {
  if row < 0 || col < 0 || row >= grid.rows || col >= grid.cols {
    None
  } else {
    grid.cells.get(row * grid.cols + col)
  }
}

///|
fn first_cell(grid : TerrainGrid) -> @core.TerrainCell {
  grid.cells.get(0).unwrap()
}

///|
fn elevation_range(grid : TerrainGrid) -> (Double, Double) {
  let first = first_cell(grid)
  let mut min_value = first.elevation_m
  let mut max_value = first.elevation_m
  for cell in grid.cells {
    if cell.elevation_m < min_value {
      min_value = cell.elevation_m
    }
    if cell.elevation_m > max_value {
      max_value = cell.elevation_m
    }
  }
  (min_value, max_value)
}

///|
fn neighbor_pairs(grid : TerrainGrid) -> Array[(Double, Double)] {
  let pairs : Array[(Double, Double)] = []
  for row in 0..<grid.rows {
    for col in 0..<grid.cols {
      let cell = cell_at(grid, row, col).unwrap()
      match cell_at(grid, row, col + 1) {
        Some(east) => pairs.push((cell.elevation_m, east.elevation_m))
        None => ()
      }
      match cell_at(grid, row + 1, col) {
        Some(south) => pairs.push((cell.elevation_m, south.elevation_m))
        None => ()
      }
    }
  }
  pairs
}

///|
fn classify_hazard(
  max_grade : Double,
  roughness_m : Double,
) -> (HazardClass, String) {
  if max_grade >= 0.35 || roughness_m >= 2.5 {
    (Blocked, "neighbor grade or roughness exceeds early rover traverse limits")
  } else if max_grade >= 0.18 || roughness_m >= 1.2 {
    (Caution, "terrain needs operator review before traverse planning")
  } else {
    (Clear, "terrain is smooth enough for the first trusted-square fixture")
  }
}

///|
pub fn analyze(grid : TerrainGrid) -> TerrainMetrics {
  let (min_elevation_m, max_elevation_m) = elevation_range(grid)
  let pairs = neighbor_pairs(grid)
  let mut max_delta = 0.0
  let mut total_delta = 0.0
  for pair in pairs {
    let delta = abs_double(pair.0 - pair.1)
    total_delta += delta
    if delta > max_delta {
      max_delta = delta
    }
  }
  let roughness_m = if pairs.is_empty() {
    0.0
  } else {
    total_delta / pairs.length().to_double()
  }
  let max_neighbor_grade = if grid.cell_size_m <= 0.0 {
    0.0
  } else {
    max_delta / grid.cell_size_m
  }
  let (hazard_class, hazard_reason) = classify_hazard(
    max_neighbor_grade, roughness_m,
  )
  let first = first_cell(grid)
  {
    min_elevation_m,
    max_elevation_m,
    elevation_range_m: max_elevation_m - min_elevation_m,
    max_neighbor_grade,
    roughness_m,
    hazard_class,
    hazard_reason,
    provenance: @core.derived_provenance(
      first.provenance,
      "moonmoon/src/terrain.analyze",
      "terrain-metrics.v1",
    ),
    uncertainty: @core.uncertainty(
      first.uncertainty.confidence * 0.92,
      "Derived from a tiny fixture; useful for software proof, not mission certification.",
    ),
  }
}

///|
pub fn grid_fingerprint(grid : TerrainGrid) -> String {
  let first = first_cell(grid)
  let last = grid.cells.get(grid.cells.length() - 1).unwrap()
  "inline-grid-v1:tile=\{grid.tile_id}:rows=\{grid.rows}:cols=\{grid.cols}:cell-size-m=\{grid.cell_size_m}:cells=\{grid.cells.length()}:first=\{first.elevation_m}:last=\{last.elevation_m}"
}

///|
pub fn validate_grid_source(grid : TerrainGrid) -> TerrainFixtureValidation {
  let expected_fingerprint = grid.source_manifest.checksum
  let actual_fingerprint = grid_fingerprint(grid)
  let status = if expected_fingerprint == "" || actual_fingerprint == "" {
    MissingFingerprint
  } else if expected_fingerprint == actual_fingerprint {
    Verified
  } else {
    FingerprintMismatch
  }
  {
    dataset_id: grid.source_manifest.dataset_id,
    expected_fingerprint,
    actual_fingerprint,
    status,
    note: match status {
      Verified => "terrain fixture fingerprint matches manifest"
      FingerprintMismatch => "terrain fixture fingerprint differs from manifest"
      MissingFingerprint =>
        "terrain fixture manifest or generated grid fingerprint is missing"
    },
  }
}

///|
pub fn render_grid_markdown(grid : TerrainGrid) -> String {
  let metrics = analyze(grid)
  let manifest = grid.source_manifest
  let validation = validate_grid_source(grid)
  let mut text = "# Terrain Fixture: \{grid.tile_id}\n\n"
  text += "## Source\n\n"
  text += "- dataset: \{manifest.dataset_id}\n"
  text += "- title: \{manifest.title}\n"
  text += "- trust: \{@dataset.trust_label(manifest.trust)}\n"
  text += "- claim: \{@core.claim_kind_label(manifest.claim_kind)}\n"
  text += "- resolution: \{manifest.resolution_m} m\n"
  text += "- source path: \{manifest.source_path}\n"
  text += "- source sha256: \{manifest.source_sha256}\n"
  text += "- extractor: \{manifest.extractor}\n"
  text += "- checksum kind: \{@dataset.checksum_kind_label(manifest.checksum_kind)}\n"
  text += "- checksum: \{manifest.checksum}\n\n"
  text += "## Terrain Fixture Validation\n\n"
  text += "- status: \{terrain_fixture_validation_status_label(validation.status)}\n"
  text += "- actual: \{validation.actual_fingerprint}\n"
  text += "- note: \{validation.note}\n\n"
  text += "## Grid\n\n"
  text += "- rows: \{grid.rows}\n"
  text += "- cols: \{grid.cols}\n"
  text += "- cell size: \{grid.cell_size_m} m\n"
  text += "- cells: \{grid.cells.length()}\n\n"
  text += "## Derived Metrics\n\n"
  text += "- elevation range: \{metrics.elevation_range_m} m (\{metrics.min_elevation_m} to \{metrics.max_elevation_m})\n"
  text += "- max neighbor grade: \{metrics.max_neighbor_grade}\n"
  text += "- roughness: \{metrics.roughness_m} m\n"
  text += "- hazard: \{hazard_label(metrics.hazard_class)} - \{metrics.hazard_reason}\n"
  text
}

///|
pub fn first_trusted_square_fixture_markdown() -> String {
  render_grid_markdown(first_trusted_square_grid())
}

///|
pub fn render_grid_json(grid : TerrainGrid) -> Json {
  grid.to_json()
}

///|
pub fn first_trusted_square_fixture_json() -> Json {
  render_grid_json(first_trusted_square_grid())
}
