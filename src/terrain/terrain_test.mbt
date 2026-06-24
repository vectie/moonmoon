///|
test "first trusted square fixture derives deterministic terrain metrics" {
  let grid = @terrain.first_trusted_square_grid()
  assert_eq(grid.rows, 4)
  assert_eq(grid.cols, 4)
  assert_eq(grid.cells.length(), 16)
  assert_eq(
    grid.source_manifest.dataset_id,
    "fixture-first-trusted-square-dem-v1",
  )
  assert_true(
    grid.source_manifest.trust == @dataset.DatasetTrust::CuratedFixture,
  )
  let validation = @terrain.validate_grid_source(grid)
  assert_true(validation.status == @dataset.DatasetValidationStatus::Verified)
  assert_eq(validation.actual_checksum, @terrain.grid_fingerprint(grid))
  let metrics = @terrain.analyze(grid)
  assert_eq(metrics.min_elevation_m.to_string(), "-0.3")
  assert_eq(metrics.max_elevation_m.to_string(), "5.4")
  assert_eq(metrics.elevation_range_m.to_string(), "5.7")
  assert_true(metrics.hazard_class == Caution)
  assert_eq(@terrain.hazard_label(metrics.hazard_class), "caution")
  assert_true(metrics.max_neighbor_grade > 0.15)
  assert_true(metrics.roughness_m > 0.9)
  assert_true(metrics.provenance.claim_kind == Derived)
  assert_eq(metrics.provenance.dataset_id, grid.source_manifest.dataset_id)
}

///|
test "first trusted square fixture renders terrain evidence markdown" {
  let text = @terrain.first_trusted_square_fixture_markdown()
  assert_true(text.contains("# Terrain Fixture: first-trusted-square"))
  assert_true(text.contains("trust: curated-fixture"))
  assert_true(text.contains("claim: simulated"))
  assert_true(
    text.contains("source path: data/fixtures/first_trusted_square_dem.csv"),
  )
  assert_true(
    text.contains(
      "source sha256: 45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7",
    ),
  )
  assert_true(text.contains("status: verified"))
  assert_true(text.contains("## Derived Metrics"))
  let json = @terrain.first_trusted_square_fixture_json().stringify(indent=2)
  assert_true(json.contains("\"source_manifest\""))
  assert_true(json.contains("\"claim_kind\": \"Simulated\""))
}
