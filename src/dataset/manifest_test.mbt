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
  assert_eq(plan.product_id, "ldem_875s_20m_float")
  assert_true(plan.source_product_url.contains("lola_gdr/polar/float_img"))
  assert_true(plan.source_label_url.has_suffix(".xml"))
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
