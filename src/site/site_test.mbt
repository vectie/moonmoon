///|
test "first trusted square dossier renders the first Moonmoon evidence surface" {
  let dossier = @site.first_trusted_square_dossier()
  assert_eq(dossier.site.site_id, "first-trusted-square")
  assert_eq(dossier.datasets.length(), 1)
  assert_eq(
    dossier.datasets[0].dataset_id,
    "lro-lola-first-trusted-square-dem-v1",
  )
  assert_eq(dossier.validations.length(), 1)
  assert_true(
    dossier.validations[0].status == @dataset.DatasetValidationStatus::Verified,
  )
  assert_eq(dossier.source_candidates.length(), 1)
  assert_eq(dossier.source_candidates[0].instrument, "LOLA")
  assert_eq(dossier.source_acquisition_plans.length(), 1)
  assert_eq(
    dossier.source_acquisition_plans[0].product_family_id,
    "lro-lola-gdr-south-pole-selection",
  )
  assert_eq(dossier.source_product_selections.length(), 1)
  assert_eq(
    dossier.source_product_selections[0].product_id,
    "ldem_875s_20m_float",
  )
  assert_eq(dossier.source_extraction_candidates.length(), 1)
  assert_eq(
    dossier.source_extraction_candidates[0].tile_id,
    "first-trusted-square-lola",
  )
  assert_true(dossier.terrain.hazard_class == @terrain.HazardClass::Blocked)
  assert_true(dossier.traverse.decision == @mission.TraverseDecision::Block)
  assert_eq(dossier.blockers.length(), 2)
  let markdown = @site.render_markdown(dossier)
  assert_true(markdown.contains("# First Trusted Square"))
  assert_true(markdown.contains("## Source Datasets"))
  assert_true(markdown.contains("authoritative"))
  assert_true(markdown.contains("source sha256"))
  assert_true(markdown.contains("## Source Upgrade Candidates"))
  assert_true(
    markdown.contains("https://pds-geosciences.wustl.edu/missions/lro/lola.htm"),
  )
  assert_true(markdown.contains("## Source Acquisition Plans"))
  assert_true(markdown.contains("lro-lola-gdr-south-pole-selection"))
  assert_true(markdown.contains("source metadata sha256"))
  assert_true(markdown.contains("active software-proof fixture"))
  assert_true(markdown.contains("## Source Product Selections"))
  assert_true(markdown.contains("ldem_875s_20m_float"))
  assert_true(markdown.contains("Polar Stereographic"))
  assert_true(markdown.contains("230068224"))
  assert_true(markdown.contains("## Source Extraction Candidates"))
  assert_true(markdown.contains("first-trusted-square-lola"))
  assert_true(
    markdown.contains(
      "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
    ),
  )
  assert_true(markdown.contains("## Source Validation"))
  assert_true(markdown.contains("verified"))
  assert_true(markdown.contains("## Traverse Readiness"))
  assert_true(
    markdown.contains("provenance: lro-lola-first-trusted-square-dem-v1"),
  )
  assert_true(markdown.contains("terrain exceeds early traverse limits"))
}

///|
test "first trusted square dossier exports machine-readable evidence" {
  let text = @site.first_trusted_square_json().stringify(indent=2)
  assert_true(text.contains("\"site_id\": \"first-trusted-square\""))
  assert_true(text.contains("\"datasets\""))
  assert_true(text.contains("\"source_path\""))
  assert_true(text.contains("\"source_sha256\""))
  assert_true(text.contains("\"validations\""))
  assert_true(text.contains("\"source_candidates\""))
  assert_true(text.contains("\"source_acquisition_plans\""))
  assert_true(text.contains("\"source_product_selections\""))
  assert_true(text.contains("\"source_extraction_candidates\""))
  assert_true(
    text.contains(
      "\"product_family_id\": \"lro-lola-gdr-south-pole-selection\"",
    ),
  )
  assert_true(text.contains("\"source_metadata_bytes\": 5672"))
  assert_true(text.contains("\"product_id\": \"ldem_875s_20m_float\""))
  assert_true(text.contains("\"label_bytes\": 11629"))
  assert_true(text.contains("\"tile_id\": \"first-trusted-square-lola\""))
  assert_true(text.contains("\"output_bytes\": 636"))
  assert_true(text.contains("\"instrument\": \"LOLA\""))
  assert_true(text.contains("\"status\": \"Verified\""))
  assert_true(text.contains("\"trust\": \"Authoritative\""))
  assert_true(text.contains("\"profile_id\": \"conservative-lunar-rover-v1\""))
  assert_true(text.contains("\"Block\""))
}
