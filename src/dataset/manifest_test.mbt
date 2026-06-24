///|
test "first trusted square manifest marks LOLA evidence clearly" {
  let manifest = @dataset.first_trusted_square_manifest()
  assert_eq(manifest.dataset_id, "lro-lola-first-trusted-square-dem-v1")
  assert_true(manifest.claim_kind == @core.ClaimKind::Measured)
  assert_true(manifest.trust == @dataset.DatasetTrust::Authoritative)
  assert_eq(@dataset.trust_label(manifest.trust), "authoritative")
  assert_eq(
    manifest.source_path,
    "data/sources/lro_lola/first_trusted_square_dem.csv",
  )
  assert_eq(
    manifest.source_sha256,
    "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
  )
  assert_true(manifest.extractor.contains("extract_lola_trusted_square.py"))
  assert_eq(
    @dataset.checksum_kind_label(manifest.checksum_kind),
    "inline-fixture-fingerprint",
  )
  assert_eq(
    @dataset.review_status_label(manifest.review_status),
    "accepted-for-software-proof",
  )
  let provenance = @dataset.to_provenance(manifest)
  assert_eq(provenance.dataset_id, manifest.dataset_id)
  assert_true(provenance.claim_kind == @core.ClaimKind::Measured)
  let validation = @dataset.verify_checksum(manifest, manifest.checksum)
  assert_true(validation.status == @dataset.DatasetValidationStatus::Verified)
  assert_eq(@dataset.validation_status_label(validation.status), "verified")
  let mismatch = @dataset.verify_checksum(manifest, "wrong")
  assert_true(
    mismatch.status == @dataset.DatasetValidationStatus::ChecksumMismatch,
  )
}

///|
test "first trusted square declares an authoritative LOLA upgrade candidate" {
  let candidate = @dataset.first_trusted_square_lola_candidate()
  assert_eq(
    candidate.candidate_id,
    "candidate-lro-lola-sldem-first-trusted-square",
  )
  assert_eq(candidate.instrument, "LOLA")
  assert_true(candidate.product_family.contains("SLDEM"))
  assert_eq(
    candidate.official_source_url,
    "https://pds-geosciences.wustl.edu/missions/lro/lola.htm",
  )
  assert_eq(candidate.access_url, "https://ode.rsl.wustl.edu/moon/")
  assert_eq(
    @dataset.source_candidate_status_label(candidate),
    "accepted-for-software-proof",
  )
  assert_eq(@dataset.first_trusted_square_source_candidates().length(), 1)
}

///|
test "first trusted square has a concrete LOLA acquisition plan" {
  let plan = @dataset.first_trusted_square_lola_acquisition_plan()
  assert_eq(plan.plan_id, "acquire-lro-lola-gdr-south-pole-20m-v1")
  assert_eq(plan.product_family_id, "lro-lola-gdr-south-pole-selection")
  assert_true(plan.source_family_url.contains("data/lola_gdr/"))
  assert_true(plan.source_metadata_url.has_suffix("catalog/gdr_ds.cat"))
  assert_eq(
    plan.source_metadata_sha256,
    "f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8",
  )
  assert_eq(plan.source_metadata_bytes, 5672)
  assert_eq(plan.discovery_url, "https://ode.rsl.wustl.edu/moon/")
  assert_eq(
    plan.extracted_fixture_path,
    "data/sources/lro_lola/first_trusted_square_dem.csv and adjacent route-window CSVs",
  )
  assert_eq(@dataset.acquisition_plan_progress_label(plan), "recorded:5-steps")
  assert_eq(
    @dataset.first_trusted_square_source_acquisition_plans().length(),
    1,
  )
}

///|
test "first trusted square selects a concrete LOLA product label" {
  let selection = @dataset.first_trusted_square_lola_product_selection()
  assert_eq(selection.selection_id, "select-ldem-875s-20m-float-v1")
  assert_eq(selection.product_id, "ldem_875s_20m_float")
  assert_true(selection.product_lid.contains("ldem_875s_20m_float"))
  assert_true(selection.image_url.has_suffix("ldem_875s_20m_float.img"))
  assert_true(selection.label_url.has_suffix("ldem_875s_20m_float.xml"))
  assert_eq(
    selection.local_label_path,
    "data/sources/lro_lola/ldem_875s_20m_float.xml",
  )
  assert_eq(
    selection.label_sha256,
    "10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53",
  )
  assert_eq(selection.label_bytes, 11629)
  assert_eq(selection.image_bytes, 230068224)
  assert_eq(selection.projection, "Polar Stereographic")
  assert_eq(selection.resolution_m, 20.0)
  assert_eq(selection.south_deg, -90.0)
  assert_eq(selection.north_deg, -87.5)
  assert_eq(selection.lines, 7584)
  assert_eq(selection.samples, 7584)
  assert_eq(selection.data_type, "IEEE754LSBSingle")
  assert_eq(selection.unit, "KILOMETER")
  assert_eq(selection.value_offset_km, 1737.4)
  assert_eq(
    @dataset.product_selection_status_label(selection),
    "accepted-for-software-proof",
  )
  assert_eq(
    @dataset.first_trusted_square_source_product_selections().length(),
    1,
  )
}

///|
test "first trusted square tracks LOLA extraction candidates" {
  let extraction = @dataset.first_trusted_square_lola_extraction_candidate()
  assert_eq(
    extraction.extraction_id,
    "extract-ldem-875s-20m-first-trusted-square-v1",
  )
  assert_eq(extraction.selection_id, "select-ldem-875s-20m-float-v1")
  assert_eq(extraction.generated_by, "scripts/extract_lola_trusted_square.py")
  assert_eq(
    extraction.output_path,
    "data/sources/lro_lola/first_trusted_square_dem.csv",
  )
  assert_eq(
    extraction.output_sha256,
    "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
  )
  assert_eq(extraction.output_bytes, 636)
  assert_eq(extraction.tile_id, "first-trusted-square-lola")
  assert_eq(extraction.source_row_start, 3972)
  assert_eq(extraction.source_col_start, 3790)
  assert_eq(extraction.rows, 4)
  assert_eq(extraction.cols, 4)
  assert_eq(extraction.cell_size_m, 20.0)
  assert_true(extraction.claim_kind == @core.ClaimKind::Measured)
  assert_eq(
    @dataset.extraction_candidate_status_label(extraction),
    "accepted-for-software-proof",
  )
  assert_eq(
    @dataset.first_trusted_square_source_extraction_candidates().length(),
    3,
  )
  let west = @dataset.first_trusted_square_west_contour_lola_extraction_candidate()
  assert_eq(west.tile_id, "first-trusted-square-west-contour-lola")
  assert_eq(west.source_row_start, 3972)
  assert_eq(west.source_col_start, 3786)
  assert_eq(
    west.output_sha256,
    "1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6",
  )
  assert_eq(west.output_bytes, 844)
  let north = @dataset.first_trusted_square_north_rim_lola_extraction_candidate()
  assert_eq(north.tile_id, "first-trusted-square-north-rim-lola")
  assert_eq(north.source_row_start, 3968)
  assert_eq(north.source_col_start, 3790)
  assert_eq(
    north.output_sha256,
    "40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28",
  )
  assert_eq(north.output_bytes, 796)
  let route_manifests = @dataset.first_trusted_square_route_manifests()
  assert_eq(route_manifests.length(), 2)
  assert_eq(
    route_manifests[0].dataset_id,
    "lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    route_manifests[1].dataset_id,
    "lro-lola-first-trusted-square-north-rim-dem-v1",
  )
}
