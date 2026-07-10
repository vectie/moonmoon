///|
test "first trusted square projects lunar records into generic data contracts" {
  let sources = @lunar_data.first_trusted_square_lunar_sources()
  assert_eq(sources.length(), 2)
  assert_eq(sources[0].source_id, "source-lro-lola-gdr-south-pole-v1")
  assert_eq(sources[0].source_refs.length(), 2)
  assert_eq(sources[1].source_refs[0].byte_count, 1191L)
  let datasets = @lunar_data.first_trusted_square_lunar_datasets()
  assert_eq(datasets.length(), 2)
  assert_eq(datasets[0].source_ids[0], sources[0].source_id)
  assert_eq(datasets[0].data_refs[0].byte_count, 636L)
  assert_eq(
    @data_core.data_payload_uri_relative_path(datasets[0].data_refs[0].uri).unwrap(),
    "sources/lro_lola/first_trusted_square_dem.csv",
  )
  assert_true(datasets[1].status == @data_core.DataStatus::Curated)
}

///|
test "lunar product keeps domain details outside data_core projection" {
  let selection = @lunar_data.first_trusted_square_lola_product_selection()
  assert_eq(selection.coverage.body, "Moon")
  assert_eq(selection.coordinate_frame.projection, "Polar Stereographic")
  assert_eq(selection.coverage.resolution_m, 20.0)
  assert_eq(selection.lines, 7584)
  assert_eq(selection.samples, 7584)
  let extraction = @lunar_data.first_trusted_square_lola_extraction_candidate()
  assert_eq(extraction.rows, 4)
  assert_eq(extraction.cols, 4)
  assert_eq(extraction.source_row_start, 3972)
  assert_eq(extraction.source_col_start, 3790)
}

///|
test "lunar records json round trip" {
  let tile = @lunar_data.first_trusted_square_tile_manifest()
  let decoded : @lunar_data.LunarTileManifest = @json.from_json(tile.to_json())
  assert_true(decoded == tile)
  assert_eq(decoded.terrain_dataset_id, "lro-lola-first-trusted-square-dem-v1")
  assert_eq(
    decoded.ephemeris_dataset_id,
    "naif-lunar-first-trusted-square-power-window-v1",
  )
}

///|
test "lunar data owns acquisition plans and route windows" {
  let plans = @lunar_data.first_trusted_square_lunar_acquisition_plans()
  assert_eq(plans.length(), 2)
  assert_eq(plans[0].source_metadata_bytes, 5672L)
  assert_eq(plans[0].steps.length(), 5)
  assert_eq(plans[1].source_metadata_bytes, 45745465L)
  let routes = @lunar_data.first_trusted_square_route_lola_extraction_candidates()
  assert_eq(routes.length(), 5)
  assert_eq(routes[0].tile_id, "first-trusted-square-west-contour-lola")
  assert_eq(routes[4].source_row_start, 3960)
  assert_eq(routes[4].source_col_start, 3806)
  let records = @lunar_data.first_trusted_square_route_lola_terrain_dataset_records()
  assert_eq(records.length(), 5)
  assert_eq(
    records[4].inline_fingerprint,
    "inline-grid-v1:tile=first-trusted-square-northeast-stepout-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=341.536:last=305.726",
  )
}
