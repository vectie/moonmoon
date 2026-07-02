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
  assert_true(manifest.extractor.contains("MoonBit source extraction"))
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
}

///|
test "first trusted square route manifests stay terrain fixture scoped" {
  let route_manifests = @dataset.first_trusted_square_route_manifests()
  assert_eq(route_manifests.length(), 5)
  assert_eq(
    route_manifests[0].dataset_id,
    "lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    route_manifests[1].dataset_id,
    "lro-lola-first-trusted-square-north-rim-dem-v1",
  )
  assert_eq(
    route_manifests[2].dataset_id,
    "lro-lola-first-trusted-square-southwest-bypass-dem-v1",
  )
  assert_eq(
    route_manifests[3].dataset_id,
    "lro-lola-first-trusted-square-south-stepout-dem-v1",
  )
  assert_eq(
    route_manifests[4].dataset_id,
    "lro-lola-first-trusted-square-northeast-stepout-dem-v1",
  )
  assert_eq(
    route_manifests[4].source_sha256,
    "b04648fc553a9c55effd9b6900039cc722b05de8b284dae353c9eba660c18b4c",
  )
}
