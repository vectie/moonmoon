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
