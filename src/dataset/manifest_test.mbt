///|
test "first trusted square manifest marks fixture evidence clearly" {
  let manifest = @dataset.first_trusted_square_manifest()
  assert_eq(manifest.dataset_id, "fixture-first-trusted-square-dem-v1")
  assert_true(manifest.claim_kind == @core.ClaimKind::Simulated)
  assert_true(manifest.trust == @dataset.DatasetTrust::CuratedFixture)
  assert_eq(@dataset.trust_label(manifest.trust), "curated-fixture")
  assert_eq(manifest.source_path, "data/fixtures/first_trusted_square_dem.csv")
  assert_eq(
    manifest.source_sha256,
    "45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7",
  )
  assert_eq(
    manifest.extractor,
    "scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
  )
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
  assert_true(provenance.claim_kind == @core.ClaimKind::Simulated)
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
    "needs-source-upgrade",
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
    "data/sources/lro_lola/first_trusted_square_dem.csv",
  )
  assert_eq(@dataset.acquisition_plan_progress_label(plan), "planned:5-steps")
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
    "needs-human-review",
  )
  assert_eq(
    @dataset.first_trusted_square_source_product_selections().length(),
    1,
  )
}
