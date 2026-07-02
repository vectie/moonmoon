///|
fn root_path(name : String) -> String {
  "target/site-catalog-tests/\{name}"
}

///|
test "site catalog adapter projects evidence from materialized catalog root" {
  let root = root_path("catalog-evidence")
  ignore(
    @lunar_catalog.ingest_first_trusted_square_catalog(root, 400L).unwrap(),
  )
  let evidence = @site_catalog.first_trusted_square_catalog_evidence_from_root(
    root,
  ).unwrap()
  assert_eq(evidence.length(), 4)
  assert_eq(evidence[0].artifact.artifact_kind, "source")
  assert_eq(
    evidence[0].artifact.manifest_path,
    root + "/sources/source-lro-lola-gdr-south-pole-v1.json",
  )
  assert_eq(
    evidence[0].source_url,
    "https://pds-geosciences.wustl.edu/missions/lro/lola.htm",
  )
  assert_eq(evidence[2].artifact.artifact_kind, "dataset")
  assert_eq(
    evidence[2].artifact.manifest_path,
    root + "/datasets/lro-lola-first-trusted-square-dem-v1.json",
  )
  assert_true(evidence[2].artifact.status == @data_core.DataStatus::Verified)
  assert_eq(evidence[2].ref_uris.length(), 1)
  let validation = @site_catalog.first_trusted_square_catalog_validation_from_root(
    root,
  ).unwrap()
  assert_eq(validation.artifact.artifact_id, "validation-400")
  assert_true(
    validation.validation_status == @data_core.ValidationStatus::Warning,
  )
  assert_true(!validation.ready)
  assert_eq(validation.blocker_count, 0)
  assert_true(validation.warning_count > 0)
}

///|
test "site dossier can replace static catalog claims from data root" {
  let root = root_path("dossier")
  ignore(
    @lunar_catalog.ingest_first_trusted_square_catalog(root, 500L).unwrap(),
  )
  let dossier = @site_catalog.first_trusted_square_dossier_from_catalog_root(
    root,
  ).unwrap()
  assert_eq(dossier.site.site_id, "first-trusted-square")
  assert_eq(dossier.catalog_evidence.length(), 4)
  assert_eq(dossier.catalog_validation.artifact.artifact_id, "validation-500")
  assert_true(
    dossier.catalog_validation.validation_status ==
    @data_core.ValidationStatus::Warning,
  )
  assert_true(!dossier.catalog_validation.ready)
  assert_true(dossier.catalog_validation.warning_count > 0)
  assert_true(
    dossier.catalog_evidence[2].artifact.manifest_path.has_prefix(root),
  )
  assert_eq(dossier.datasets.length(), 6)
  assert_eq(dossier.route_candidates.length(), 6)
}
