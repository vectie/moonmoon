///|
test "first trusted square dossier renders the first MoonMoon evidence surface" {
  let dossier = @site.first_trusted_square_dossier()
  assert_eq(dossier.site.site_id, "first-trusted-square")
  assert_eq(dossier.datasets.length(), 6)
  assert_eq(
    dossier.datasets[0].dataset_id,
    "lro-lola-first-trusted-square-dem-v1",
  )
  assert_eq(
    dossier.datasets[1].dataset_id,
    "lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    dossier.datasets[2].dataset_id,
    "lro-lola-first-trusted-square-north-rim-dem-v1",
  )
  assert_eq(
    dossier.datasets[3].dataset_id,
    "lro-lola-first-trusted-square-southwest-bypass-dem-v1",
  )
  assert_eq(
    dossier.datasets[4].dataset_id,
    "lro-lola-first-trusted-square-south-stepout-dem-v1",
  )
  assert_eq(
    dossier.datasets[5].dataset_id,
    "lro-lola-first-trusted-square-northeast-stepout-dem-v1",
  )
  assert_eq(dossier.validations.length(), 6)
  assert_true(
    dossier.validations[0].status ==
    @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_true(
    dossier.validations[1].status ==
    @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_true(
    dossier.validations[2].status ==
    @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_true(
    dossier.validations[3].status ==
    @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_true(
    dossier.validations[4].status ==
    @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_true(
    dossier.validations[5].status ==
    @terrain.TerrainFixtureValidationStatus::Verified,
  )
  assert_eq(dossier.catalog_evidence.length(), 4)
  assert_eq(dossier.catalog_evidence[0].artifact.artifact_kind, "source")
  assert_eq(
    dossier.catalog_evidence[0].artifact.artifact_id,
    "source-lro-lola-gdr-south-pole-v1",
  )
  assert_eq(
    dossier.catalog_evidence[0].authority,
    "NASA PDS Geosciences / LRO LOLA",
  )
  assert_eq(dossier.catalog_evidence[2].artifact.artifact_kind, "dataset")
  assert_eq(
    dossier.catalog_evidence[2].artifact.artifact_id,
    "lro-lola-first-trusted-square-dem-v1",
  )
  assert_eq(
    dossier.catalog_evidence[2].artifact.manifest_path,
    "datasets/lro-lola-first-trusted-square-dem-v1.json",
  )
  assert_eq(dossier.catalog_evidence[2].ref_uris.length(), 1)
  assert_eq(
    dossier.catalog_validation.artifact.artifact_kind,
    "validation-report",
  )
  assert_eq(dossier.catalog_validation.artifact.artifact_id, "")
  assert_true(!dossier.catalog_validation.ready)
  assert_eq(dossier.source_candidates.length(), 2)
  assert_eq(dossier.source_candidates[0].instrument, "LOLA")
  assert_eq(dossier.source_candidates[1].instrument, "SPICE kernels")
  assert_eq(dossier.source_acquisition_plans.length(), 2)
  assert_eq(
    dossier.source_acquisition_plans[0].product_family_id,
    "lro-lola-gdr-south-pole-selection",
  )
  assert_eq(
    dossier.source_acquisition_plans[1].product_family_id,
    "lunar-solar-ephemeris-power-window",
  )
  assert_eq(dossier.source_product_selections.length(), 1)
  assert_eq(
    dossier.source_product_selections[0].product_id,
    "ldem_875s_20m_float",
  )
  assert_eq(dossier.source_extraction_candidates.length(), 6)
  assert_eq(
    dossier.source_extraction_candidates[0].tile_id,
    "first-trusted-square-lola",
  )
  assert_eq(
    dossier.source_extraction_candidates[1].tile_id,
    "first-trusted-square-west-contour-lola",
  )
  assert_eq(
    dossier.source_extraction_candidates[2].tile_id,
    "first-trusted-square-north-rim-lola",
  )
  assert_eq(
    dossier.source_extraction_candidates[3].tile_id,
    "first-trusted-square-southwest-bypass-lola",
  )
  assert_eq(
    dossier.source_extraction_candidates[4].tile_id,
    "first-trusted-square-south-stepout-lola",
  )
  assert_eq(
    dossier.source_extraction_candidates[5].tile_id,
    "first-trusted-square-northeast-stepout-lola",
  )
  assert_true(dossier.terrain.hazard_class == @terrain.HazardClass::Blocked)
  assert_true(dossier.traverse.decision == @mission.TraverseDecision::Block)
  assert_eq(dossier.corridor_scan.length(), 81)
  assert_eq(dossier.corridor_scan[0].window_id, "r-12-c+16")
  assert_eq(dossier.corridor_scan[0].selected_route_id, "northeast-stepout")
  assert_true(
    dossier.corridor_scan[0].decision == @mission.TraverseDecision::Block,
  )
  assert_eq(dossier.route_candidates.length(), 6)
  assert_eq(dossier.route_candidates[0].route_id, "direct-lola-window")
  assert_eq(dossier.route_candidates[1].route_id, "west-contour-detour")
  assert_true(
    dossier.route_candidates[1].decision == @mission.TraverseDecision::Block,
  )
  assert_eq(dossier.route_candidates[3].route_id, "southwest-bypass")
  assert_true(
    dossier.route_candidates[3].expected_max_grade <
    dossier.route_candidates[1].expected_max_grade,
  )
  assert_eq(dossier.route_candidates[5].route_id, "northeast-stepout")
  assert_true(dossier.energy.decision == @mission.TraverseDecision::Block)
  assert_eq(
    dossier.power_window_evidence.evidence_id,
    "first-trusted-square-power-window-computed-v2",
  )
  assert_eq(dossier.power_window_evidence.source_status, "ready")
  assert_eq(dossier.power_window_evidence.available_energy_wh, 0.0)
  assert_eq(dossier.energy.route_count, 6)
  assert_eq(dossier.energy.blocked_route_count, 6)
  assert_eq(dossier.clearance_plan.route_id, "northeast-stepout")
  assert_true(
    dossier.clearance_plan.decision == @mission.TraverseDecision::Block,
  )
  assert_eq(dossier.clearance_plan.items.length(), 4)
  assert_eq(dossier.clearance_plan.blocking_items.length(), 4)
  assert_eq(
    dossier.clearance_plan.items[0].clearance_id,
    "clear-terrain-grade-northeast-stepout",
  )
  assert_eq(
    dossier.clearance_plan.items[1].clearance_id,
    "clear-illumination-confidence-northeast-stepout",
  )
  assert_eq(dossier.clearance_plan.items[2].clearance_id, "clear-energy-margin")
  assert_eq(
    dossier.clearance_plan.items[3].clearance_id,
    "clear-operator-review-northeast-stepout",
  )
  assert_true(dossier.clearance_plan.next_action.contains("terrain grade"))
  assert_eq(dossier.blockers.length(), 4)
  assert_true(
    dossier.blockers.any(fn(blocker) {
      blocker.contains("terrain-visible hours")
    }),
  )
  assert_true(
    dossier.blockers.any(fn(blocker) { blocker.contains("energy margin") }),
  )
  assert_true(!dossier.next_questions[0].contains("Attach time-windowed"))
  let markdown = @site.render_markdown(dossier)
  assert_true(markdown.contains("# First Trusted Square"))
  assert_true(markdown.contains("## Source Datasets"))
  assert_true(markdown.contains("authoritative"))
  assert_true(markdown.contains("source sha256"))
  assert_true(markdown.contains("## Catalog Evidence"))
  assert_true(markdown.contains("source: source-lro-lola-gdr-south-pole-v1"))
  assert_true(
    markdown.contains("dataset: lro-lola-first-trusted-square-dem-v1"),
  )
  assert_true(
    markdown.contains(
      "manifest: datasets/lro-lola-first-trusted-square-dem-v1.json",
    ),
  )
  assert_true(markdown.contains("## Catalog Validation"))
  assert_true(markdown.contains("catalog validation has not been read"))
  assert_true(markdown.contains("## Source Upgrade Candidates"))
  assert_true(
    markdown.contains("https://pds-geosciences.wustl.edu/missions/lro/lola.htm"),
  )
  assert_true(markdown.contains("SPICE kernels"))
  assert_true(markdown.contains("needs-human-review"))
  assert_true(markdown.contains("## Source Acquisition Plans"))
  assert_true(markdown.contains("lro-lola-gdr-south-pole-selection"))
  assert_true(markdown.contains("lunar-solar-ephemeris-power-window"))
  assert_true(markdown.contains("source metadata sha256"))
  assert_true(markdown.contains("active software-proof fixtures"))
  assert_true(
    markdown.contains("mission-window selection and rover power assumptions"),
  )
  assert_true(markdown.contains("## Source Product Selections"))
  assert_true(markdown.contains("ldem_875s_20m_float"))
  assert_true(markdown.contains("Polar Stereographic"))
  assert_true(markdown.contains("230068224"))
  assert_true(markdown.contains("## Source Extraction Candidates"))
  assert_true(markdown.contains("first-trusted-square-lola"))
  assert_true(markdown.contains("first-trusted-square-west-contour-lola"))
  assert_true(markdown.contains("first-trusted-square-north-rim-lola"))
  assert_true(markdown.contains("first-trusted-square-southwest-bypass-lola"))
  assert_true(markdown.contains("first-trusted-square-south-stepout-lola"))
  assert_true(markdown.contains("first-trusted-square-northeast-stepout-lola"))
  assert_true(
    markdown.contains(
      "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
    ),
  )
  assert_true(markdown.contains("## Terrain Fixture Validation"))
  assert_true(markdown.contains("verified"))
  assert_true(markdown.contains("## Traverse Readiness"))
  assert_true(markdown.contains("## Corridor Scan"))
  assert_true(markdown.contains("first-trusted-square-9x9-corridor-scan-v2"))
  assert_true(markdown.contains("r-12-c+16"))
  assert_true(markdown.contains("selected route: northeast-stepout"))
  assert_true(markdown.contains("## Energy Window"))
  assert_true(markdown.contains("## Power Window Evidence"))
  assert_true(markdown.contains("source status: ready"))
  assert_true(markdown.contains("source bytes: 45745465"))
  assert_true(markdown.contains("naif0012.tls"))
  assert_true(markdown.contains("de440s.bsp"))
  assert_true(markdown.contains("moon_de440_250416.tf"))
  assert_true(markdown.contains("south-pole-power-window-v2"))
  assert_true(markdown.contains("has time-windowed ephemeris: true"))
  assert_true(markdown.contains("conservative-south-pole-energy-v1"))
  assert_true(
    markdown.contains("first-trusted-square-power-window-computed-v2"),
  )
  assert_true(markdown.contains("power-window source status: ready"))
  assert_true(markdown.contains("verified available energy: 0"))
  assert_true(markdown.contains("## Mission Window Search"))
  assert_true(
    markdown.contains(
      "recommended window: 2026-11-08T00:00:00Z -> 2026-11-22T00:00:00Z",
    ),
  )
  assert_true(markdown.contains("terrain-visible sunlight: 336 h"))
  assert_true(markdown.contains("clears illumination constraint: true"))
  assert_true(markdown.contains("## Route Candidates"))
  assert_true(markdown.contains("west-contour-detour"))
  assert_true(markdown.contains("north-rim-stepout"))
  assert_true(markdown.contains("southwest-bypass"))
  assert_true(markdown.contains("south-stepout"))
  assert_true(markdown.contains("northeast-stepout"))
  assert_true(markdown.contains("evidence dataset"))
  assert_true(markdown.contains("west-adjacent LOLA window is measured"))
  assert_true(markdown.contains("illumination decision: block"))
  assert_true(markdown.contains("illumination risk"))
  assert_true(markdown.contains("local relief shadow proxy exceeds"))
  assert_true(markdown.contains("## Selected Route Clearance"))
  assert_true(markdown.contains("clear-terrain-grade-northeast-stepout"))
  assert_true(
    markdown.contains("clear-illumination-confidence-northeast-stepout"),
  )
  assert_true(markdown.contains("clear-energy-margin"))
  assert_true(markdown.contains("clear-operator-review-northeast-stepout"))
  assert_true(markdown.contains("operator-review-transitions.json"))
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
  assert_true(text.contains("\"catalog_validation\""))
  assert_true(text.contains("\"clearance_plan\""))
  assert_true(text.contains("\"route_id\": \"northeast-stepout\""))
  assert_true(
    text.contains("\"clearance_id\": \"clear-terrain-grade-northeast-stepout\""),
  )
  assert_true(text.contains("\"clearance_id\": \"clear-energy-margin\""))
  assert_true(text.contains("\"catalog validation has not been read"))
  assert_true(
    text.contains(
      "\"product_family_id\": \"lro-lola-gdr-south-pole-selection\"",
    ),
  )
  assert_true(
    text.contains(
      "\"product_family_id\": \"lunar-solar-ephemeris-power-window\"",
    ),
  )
  assert_true(text.contains("\"instrument\": \"SPICE kernels\""))
  assert_true(text.contains("\"source_metadata_bytes\": \"5672\""))
  assert_true(text.contains("\"product_id\": \"ldem_875s_20m_float\""))
  assert_true(text.contains("\"label_bytes\": \"11629\""))
  assert_true(text.contains("\"tile_id\": \"first-trusted-square-lola\""))
  assert_true(
    text.contains("\"tile_id\": \"first-trusted-square-west-contour-lola\""),
  )
  assert_true(
    text.contains("\"tile_id\": \"first-trusted-square-north-rim-lola\""),
  )
  assert_true(
    text.contains("\"tile_id\": \"first-trusted-square-southwest-bypass-lola\""),
  )
  assert_true(
    text.contains("\"tile_id\": \"first-trusted-square-south-stepout-lola\""),
  )
  assert_true(
    text.contains(
      "\"tile_id\": \"first-trusted-square-northeast-stepout-lola\"",
    ),
  )
  assert_true(text.contains("\"output_bytes\": \"636\""))
  assert_true(text.contains("\"output_bytes\": \"844\""))
  assert_true(text.contains("\"output_bytes\": \"796\""))
  assert_true(text.contains("\"output_bytes\": \"908\""))
  assert_true(text.contains("\"output_bytes\": \"860\""))
  assert_true(text.contains("\"output_bytes\": \"924\""))
  assert_true(text.contains("\"instrument\": \"LOLA\""))
  assert_true(text.contains("\"status\": \"Verified\""))
  assert_true(text.contains("\"trust\": \"Authoritative\""))
  assert_true(text.contains("\"profile_id\": \"conservative-lunar-rover-v1\""))
  assert_true(text.contains("\"corridor_scan\""))
  assert_true(
    text.contains("\"scan_id\": \"first-trusted-square-9x9-corridor-scan-v2\""),
  )
  assert_true(text.contains("\"window_id\": \"r-12-c+16\""))
  assert_true(text.contains("\"energy\""))
  assert_true(text.contains("\"power_window_evidence\""))
  assert_true(text.contains("\"window_search_evidence\""))
  assert_true(
    text.contains(
      "\"evidence_id\": \"first-trusted-square-mission-window-search-v1\"",
    ),
  )
  assert_true(text.contains("\"time_start_utc\": \"2026-11-08T00:00:00Z\""))
  assert_true(text.contains("\"file_id\": \"de440s.bsp\""))
  assert_true(text.contains("\"file_id\": \"moon_de440_250416.tf\""))
  assert_true(
    text.contains("\"budget_id\": \"conservative-south-pole-energy-v1\""),
  )
  assert_true(text.contains("\"available_energy_wh\": 0"))
  assert_true(text.contains("\"power_window_source_status\": \"ready\""))
  assert_true(
    text.contains(
      "\"power_window_evidence_id\": \"first-trusted-square-power-window-computed-v2\"",
    ),
  )
  assert_true(text.contains("\"route_candidates\""))
  assert_true(text.contains("\"route_id\": \"west-contour-detour\""))
  assert_true(text.contains("\"route_id\": \"southwest-bypass\""))
  assert_true(text.contains("\"route_id\": \"northeast-stepout\""))
  assert_true(text.contains("\"evidence_dataset_id\""))
  assert_true(text.contains("\"illumination\""))
  assert_true(
    text.contains("\"constraint_id\": \"conservative-south-pole-power-v1\""),
  )
  assert_true(text.contains("\"relief_shadow_risk\""))
  assert_true(text.contains("\"Block\""))
}
