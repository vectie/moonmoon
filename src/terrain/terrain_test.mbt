///|
test "first trusted square fixture derives deterministic terrain metrics" {
  let grid = @terrain.first_trusted_square_grid()
  assert_eq(grid.rows, 4)
  assert_eq(grid.cols, 4)
  assert_eq(grid.cells.length(), 16)
  assert_eq(
    grid.source_manifest.dataset_id,
    "lro-lola-first-trusted-square-dem-v1",
  )
  assert_true(
    grid.source_manifest.trust == @dataset.DatasetTrust::Authoritative,
  )
  let validation = @terrain.validate_grid_source(grid)
  assert_true(
    validation.status == @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_eq(validation.actual_fingerprint, @terrain.grid_fingerprint(grid))
  let metrics = @terrain.analyze(grid)
  assert_eq(metrics.min_elevation_m.to_string(), "441.521")
  assert_eq(metrics.max_elevation_m.to_string(), "499.693")
  assert_eq(metrics.elevation_range_m.to_string(), "58.17199999999997")
  assert_true(metrics.hazard_class == Blocked)
  assert_eq(@terrain.hazard_label(metrics.hazard_class), "blocked")
  assert_true(metrics.max_neighbor_grade > 1.0)
  assert_true(metrics.roughness_m > 9.0)
  assert_true(metrics.provenance.claim_kind == Derived)
  assert_eq(metrics.provenance.dataset_id, grid.source_manifest.dataset_id)
}

///|
test "first trusted square adjacent route windows derive measured terrain metrics" {
  let route_grids = @terrain.first_trusted_square_route_grids()
  assert_eq(route_grids.length(), 5)
  assert_eq(route_grids[0].tile_id, "first-trusted-square-west-contour-lola")
  assert_eq(route_grids[1].tile_id, "first-trusted-square-north-rim-lola")
  assert_eq(
    route_grids[2].tile_id,
    "first-trusted-square-southwest-bypass-lola",
  )
  assert_eq(route_grids[3].tile_id, "first-trusted-square-south-stepout-lola")
  assert_eq(
    route_grids[4].tile_id,
    "first-trusted-square-northeast-stepout-lola",
  )
  for grid in route_grids {
    let validation = @terrain.validate_grid_source(grid)
    assert_true(
      validation.status == @terrain.TerrainFixtureValidationStatus::Verified,
    )
    let metrics = @terrain.analyze(grid)
    assert_true(metrics.hazard_class == Blocked)
    assert_true(metrics.max_neighbor_grade > 0.5)
    assert_true(metrics.roughness_m > 5.0)
    assert_true(metrics.provenance.claim_kind == Derived)
  }
  let west = @terrain.first_trusted_square_west_contour_metrics()
  assert_eq(west.min_elevation_m.to_string(), "492.629")
  assert_eq(west.max_elevation_m.to_string(), "544.454")
  let north = @terrain.first_trusted_square_north_rim_metrics()
  assert_eq(north.min_elevation_m.to_string(), "460.176")
  assert_eq(north.max_elevation_m.to_string(), "506.517")
  let southwest = @terrain.first_trusted_square_southwest_bypass_metrics()
  assert_eq(southwest.min_elevation_m.to_string(), "505.456")
  assert_eq(southwest.max_elevation_m.to_string(), "548.224")
  assert_true(southwest.max_neighbor_grade < west.max_neighbor_grade)
  let south = @terrain.first_trusted_square_south_stepout_metrics()
  assert_eq(south.min_elevation_m.to_string(), "409.003")
  assert_eq(south.max_elevation_m.to_string(), "453.571")
  let northeast = @terrain.first_trusted_square_northeast_stepout_metrics()
  assert_eq(northeast.min_elevation_m.to_string(), "305.726")
  assert_eq(northeast.max_elevation_m.to_string(), "341.536")
  assert_true(northeast.max_neighbor_grade < south.max_neighbor_grade)
}

///|
test "first trusted square fixture renders terrain evidence markdown" {
  let text = @terrain.first_trusted_square_fixture_markdown()
  assert_true(text.contains("# Terrain Fixture: first-trusted-square-lola"))
  assert_true(text.contains("trust: authoritative"))
  assert_true(text.contains("claim: measured"))
  assert_true(
    text.contains(
      "source path: data/sources/lro_lola/first_trusted_square_dem.csv",
    ),
  )
  assert_true(
    text.contains(
      "source sha256: 7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
    ),
  )
  assert_true(text.contains("status: verified"))
  assert_true(text.contains("## Derived Metrics"))
  let json = @terrain.first_trusted_square_fixture_json().stringify(indent=2)
  assert_true(json.contains("\"source_manifest\""))
  assert_true(json.contains("\"claim_kind\": \"Measured\""))
}
