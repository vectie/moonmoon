///|
test "first trusted square dossier renders the first Moonmoon evidence surface" {
  let dossier = @site.first_trusted_square_dossier()
  assert_eq(dossier.site.site_id, "first-trusted-square")
  assert_eq(dossier.datasets.length(), 1)
  assert_eq(
    dossier.datasets[0].dataset_id,
    "fixture-first-trusted-square-dem-v1",
  )
  assert_eq(dossier.validations.length(), 1)
  assert_true(
    dossier.validations[0].status == @dataset.DatasetValidationStatus::Verified,
  )
  assert_true(dossier.terrain.hazard_class == @terrain.HazardClass::Caution)
  assert_true(dossier.traverse.decision == @mission.TraverseDecision::Review)
  assert_eq(dossier.blockers.length(), 2)
  let markdown = @site.render_markdown(dossier)
  assert_true(markdown.contains("# First Trusted Square"))
  assert_true(markdown.contains("## Source Datasets"))
  assert_true(markdown.contains("curated-fixture"))
  assert_true(markdown.contains("source sha256"))
  assert_true(markdown.contains("## Source Validation"))
  assert_true(markdown.contains("verified"))
  assert_true(markdown.contains("## Traverse Readiness"))
  assert_true(
    markdown.contains("provenance: fixture-first-trusted-square-dem-v1"),
  )
  assert_true(markdown.contains("needs operator review"))
}

///|
test "first trusted square dossier exports machine-readable evidence" {
  let text = @site.first_trusted_square_json().stringify(indent=2)
  assert_true(text.contains("\"site_id\": \"first-trusted-square\""))
  assert_true(text.contains("\"datasets\""))
  assert_true(text.contains("\"source_path\""))
  assert_true(text.contains("\"source_sha256\""))
  assert_true(text.contains("\"validations\""))
  assert_true(text.contains("\"status\": \"Verified\""))
  assert_true(text.contains("\"trust\": \"CuratedFixture\""))
  assert_true(text.contains("\"profile_id\": \"conservative-lunar-rover-v1\""))
  assert_true(text.contains("\"Review\""))
}
