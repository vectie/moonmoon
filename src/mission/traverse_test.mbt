///|
test "first trusted square traverse score blocks measured rough terrain" {
  let score = @mission.first_trusted_square_traverse_score()
  assert_true(score.decision == Block)
  assert_eq(score.profile.profile_id, "conservative-lunar-rover-v1")
  assert_true(score.score <= 20)
  assert_true(score.reasons.any(fn(reason) { reason.contains("hard limit") }))
  assert_eq(@mission.traverse_decision_label(score.decision), "block")
}

///|
test "first trusted square route candidates use measured adjacent windows" {
  let routes = @mission.first_trusted_square_route_candidates()
  assert_eq(routes.length(), 6)
  assert_eq(routes[0].route_id, "direct-lola-window")
  assert_true(routes[0].decision == Block)
  assert_true(routes[0].reasons.any(fn(reason) { reason.contains("blocked") }))
  assert_eq(routes[1].route_id, "west-contour-detour")
  assert_true(routes[1].decision == Block)
  assert_eq(
    routes[1].evidence_dataset_id,
    "lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    routes[1].evidence_source_path,
    "data/sources/lro_lola/first_trusted_square_west_contour_dem.csv",
  )
  assert_true(routes[1].expected_max_grade > 0.7)
  assert_eq(@mission.route_candidate_status_label(routes[1]), "block")
  assert_true(routes[1].illumination.decision == Block)
  assert_true(routes[1].illumination.relief_shadow_risk > 0.3)
  assert_true(
    routes[1].illumination.reasons.any(fn(reason) {
      reason.contains("local relief shadow")
    }),
  )
  assert_eq(
    @mission.illumination_decision_label(routes[1].illumination),
    "block",
  )
  assert_eq(routes[2].route_id, "north-rim-stepout")
  assert_true(routes[2].decision == Block)
  assert_eq(routes[2].evidence_tile_id, "first-trusted-square-north-rim-lola")
  assert_true(routes[2].next_action.contains("illumination"))
  assert_eq(routes[3].route_id, "southwest-bypass")
  assert_true(routes[3].decision == Block)
  assert_eq(
    routes[3].evidence_dataset_id,
    "lro-lola-first-trusted-square-southwest-bypass-dem-v1",
  )
  assert_true(routes[3].expected_max_grade < routes[1].expected_max_grade)
  assert_true(
    routes[3].reasons.any(fn(reason) { reason.contains("lower risk") }),
  )
  assert_eq(routes[4].route_id, "south-stepout")
  assert_true(routes[4].decision == Block)
  assert_eq(
    routes[4].evidence_tile_id,
    "first-trusted-square-south-stepout-lola",
  )
  assert_eq(routes[5].route_id, "northeast-stepout")
  assert_true(routes[5].decision == Block)
  assert_eq(
    routes[5].evidence_tile_id,
    "first-trusted-square-northeast-stepout-lola",
  )
  assert_true(routes[5].expected_max_grade < routes[4].expected_max_grade)
}

///|
test "first trusted square corridor scan ranks measured route windows" {
  let windows = @mission.first_trusted_square_corridor_scan()
  assert_eq(windows.length(), 81)
  let best = @mission.first_trusted_square_best_corridor_window()
  assert_eq(best.scan_id, "first-trusted-square-9x9-corridor-scan-v2")
  assert_eq(best.window_id, "r-12-c+16")
  assert_eq(best.rank, 1)
  assert_eq(best.row_offset, -12)
  assert_eq(best.col_offset, 16)
  assert_eq(best.selected_route_id, "northeast-stepout")
  assert_true(best.decision == Block)
  assert_true(best.max_neighbor_grade < 0.52)
  assert_true(best.roughness_m < 6.0)
  assert_eq(@mission.corridor_scan_window_status_label(best), "block")
  assert_eq(windows[80].window_id, "r+0-c+0")
  assert_eq(windows[80].selected_route_id, "direct-lola-window")
}

///|
test "first trusted square illumination gate uses computed time window evidence" {
  let evidence = @mission.first_trusted_square_power_window_evidence()
  assert_eq(
    evidence.evidence_id,
    "first-trusted-square-power-window-computed-v1",
  )
  assert_eq(evidence.source_status, "ready")
  assert_eq(
    evidence.local_source_path,
    "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
  )
  assert_true(evidence.has_time_window_ephemeris)
  assert_eq(evidence.source_files.length(), 5)
  assert_eq(evidence.source_files[0].file_id, "naif0012.tls")
  assert_eq(evidence.source_files[0].status, "ready")
  assert_eq(evidence.source_files[1].file_id, "de440s.bsp")
  assert_eq(evidence.source_files[2].file_id, "pck00011.tpc")
  assert_eq(evidence.source_files[3].file_id, "moon_pa_de440_200625.bpc")
  assert_eq(evidence.source_files[4].file_id, "moon_de440_250416.tf")
  for source_file in evidence.source_files {
    assert_true(source_file.sha256.length() == 64)
    assert_true(source_file.bytes > 0)
    assert_eq(source_file.status, "ready")
  }
  assert_eq(evidence.source_bytes, 45745465)
  assert_eq(
    evidence.source_sha256,
    "d1a84599750c76ae4b93afec9ae2e6a002e5a0fba9c6704ca8cd32a530eacf59",
  )
  assert_eq(evidence.computation.method_id, "south-pole-power-window-v1")
  assert_eq(evidence.computation.status, "computed")
  assert_eq(evidence.time_start_utc, "2026-06-25T00:00:00Z")
  assert_eq(evidence.time_end_utc, "2026-07-09T00:00:00Z")
  assert_eq(evidence.sunlit_hours, 323.0)
  assert_eq(evidence.dark_hours, 13.0)
  assert_true(evidence.available_energy_wh > 230.0)
  assert_true(evidence.available_energy_wh < 240.0)
  let assessment = @mission.assess_illumination(
    @terrain.first_trusted_square_grid(),
    @mission.conservative_illumination_constraint(),
  )
  assert_true(assessment.decision == Block)
  assert_eq(
    assessment.constraint.constraint_id,
    "conservative-south-pole-power-v1",
  )
  assert_eq(
    assessment.constraint.power_window_evidence_id,
    evidence.evidence_id,
  )
  assert_eq(assessment.constraint.power_window_source_status, "ready")
  assert_true(assessment.relief_shadow_risk > 0.3)
  assert_true(assessment.confidence < 0.5)
  assert_true(
    assessment.reasons.any(fn(reason) { reason.contains("local relief shadow") }),
  )
  assert_true(assessment.next_action.contains("local horizon"))
}

///|
test "first trusted square energy window blocks insufficient computed power" {
  let assessment = @mission.first_trusted_square_energy_assessment()
  assert_true(assessment.decision == Block)
  assert_eq(assessment.budget.budget_id, "conservative-south-pole-energy-v1")
  assert_eq(
    assessment.budget.power_window_evidence_id,
    "first-trusted-square-power-window-computed-v1",
  )
  assert_eq(assessment.budget.power_window_source_status, "ready")
  assert_eq(
    assessment.budget.power_window_source_path,
    "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
  )
  assert_eq(assessment.route_count, 6)
  assert_eq(assessment.blocked_route_count, 6)
  assert_eq(assessment.budget.assumed_dark_survival_hours, 13.0)
  assert_true(assessment.required_energy_wh > 1200.0)
  assert_true(assessment.available_energy_wh > 230.0)
  assert_true(assessment.available_energy_wh < 240.0)
  assert_true(assessment.margin_wh < 0.0)
  assert_true(
    assessment.reasons.any(fn(reason) {
      reason.contains("energy demand exceeds")
    }),
  )
  assert_true(
    assessment.reasons.any(fn(reason) {
      reason.contains("route candidates remain blocked")
    }),
  )
  assert_eq(@mission.energy_decision_label(assessment), "block")
  assert_true(assessment.next_action.contains("revise rover power model"))
}

///|
test "mission simulation readiness aggregates named gates" {
  let route = @mission.first_trusted_square_route_candidates()[5]
  let corridor = @mission.first_trusted_square_best_corridor_window()
  let energy = @mission.first_trusted_square_energy_assessment()
  let checks = [
    @mission.readiness_check(
      "terrain-\{route.route_id}",
      @mission.MissionReadinessCheckKind::TerrainReadiness,
      "Selected-route terrain gate",
      route.decision,
      route.evidence_source_path,
      route.next_action,
    ),
    @mission.readiness_check(
      "corridor-scan-best-window",
      @mission.MissionReadinessCheckKind::CorridorReadiness,
      "Measured corridor search gate",
      corridor.decision,
      "mission/first-trusted-square/corridor-scan.json",
      corridor.note,
    ),
    @mission.readiness_check(
      "illumination-\{route.route_id}",
      @mission.MissionReadinessCheckKind::IlluminationReadiness,
      "Illumination and thermal gate",
      route.illumination.decision,
      route.illumination.constraint.power_window_source_path,
      route.illumination.next_action,
    ),
    @mission.readiness_check(
      "energy-window",
      @mission.MissionReadinessCheckKind::EnergyReadiness,
      "Rover energy window gate",
      energy.decision,
      energy.budget.power_window_source_path,
      energy.next_action,
    ),
    @mission.readiness_check(
      "moonbook-review",
      @mission.MissionReadinessCheckKind::MoonBookReviewReadiness,
      "MoonBook accepted-review gate",
      @mission.TraverseDecision::Block,
      "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      "MoonBook review has unresolved blockers",
    ),
  ]
  let readiness = @mission.simulation_readiness(
    "mission/first-trusted-square/northeast-stepout/simulation-readiness",
    route.route_id,
    checks,
  )
  assert_true(readiness.decision == @mission.TraverseDecision::Block)
  assert_eq(readiness.route_id, "northeast-stepout")
  assert_eq(readiness.checks.length(), 6)
  assert_eq(readiness.checks[0].check_id, "terrain-northeast-stepout")
  assert_eq(readiness.checks[1].check_id, "corridor-scan-best-window")
  assert_eq(readiness.checks[2].check_id, "illumination-northeast-stepout")
  assert_eq(readiness.checks[3].check_id, "energy-window")
  assert_eq(readiness.checks[4].check_id, "moonbook-review")
  assert_eq(readiness.checks[5].check_id, "robot-simulation")
  assert_eq(readiness.robot_simulation_status, "simulation-blocked")
  assert_true(readiness.blocking_checks.contains("moonbook-review"))
  assert_true(readiness.blocking_checks.contains("robot-simulation"))
  assert_eq(
    @mission.mission_readiness_check_kind_label(
      @mission.MissionReadinessCheckKind::MoonBookReviewReadiness,
    ),
    "moonbook-review",
  )
  assert_eq(@mission.mission_simulation_readiness_label(readiness), "block")
}

///|
test "selected route clearance plan names blocker actions" {
  let route = @mission.first_trusted_square_route_candidates()[5]
  let energy = @mission.first_trusted_square_energy_assessment()
  let readiness = @mission.simulation_readiness(
    "mission/first-trusted-square/northeast-stepout/simulation-readiness",
    route.route_id,
    [
      @mission.readiness_check(
        "terrain-\{route.route_id}",
        @mission.MissionReadinessCheckKind::TerrainReadiness,
        "Selected-route terrain gate",
        @mission.TraverseDecision::Block,
        route.evidence_source_path,
        route.next_action,
      ),
      @mission.readiness_check(
        "illumination-\{route.route_id}",
        @mission.MissionReadinessCheckKind::IlluminationReadiness,
        "Illumination and thermal gate",
        @mission.TraverseDecision::Block,
        route.illumination.constraint.power_window_source_path,
        route.illumination.next_action,
      ),
      @mission.readiness_check(
        "energy-window",
        @mission.MissionReadinessCheckKind::EnergyReadiness,
        "Rover energy window gate",
        @mission.TraverseDecision::Block,
        energy.budget.power_window_source_path,
        energy.next_action,
      ),
      @mission.readiness_check(
        "moonbook-review",
        @mission.MissionReadinessCheckKind::MoonBookReviewReadiness,
        "MoonBook accepted-review gate",
        @mission.TraverseDecision::Block,
        "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
        "MoonBook review has unresolved blockers",
      ),
    ],
  )
  let plan = @mission.selected_route_clearance_plan(
    "mission/first-trusted-square/northeast-stepout/selected-route-clearance", route,
    energy, readiness,
  )
  assert_eq(plan.route_id, "northeast-stepout")
  assert_true(plan.decision == @mission.TraverseDecision::Block)
  assert_eq(plan.items.length(), 4)
  assert_eq(plan.blocking_items.length(), 4)
  assert_eq(plan.accepted_items.length(), 0)
  assert_eq(plan.items[0].clearance_id, "clear-terrain-grade-northeast-stepout")
  assert_true(
    plan.items[0].kind is @mission.MissionClearanceKind::TerrainGradeClearance,
  )
  assert_true(
    plan.items[0].status is @mission.MissionClearanceStatus::ActionRequired,
  )
  assert_true(plan.items[0].observed.contains("grade"))
  assert_true(plan.items[0].required.contains("roughness"))
  assert_true(
    plan.items[0].clearance_action.contains("smoother measured route"),
  )
  assert_eq(
    plan.items[1].clearance_id,
    "clear-illumination-confidence-northeast-stepout",
  )
  assert_true(plan.items[1].observed.contains("illumination confidence"))
  assert_true(plan.items[1].required.contains("relief-shadow"))
  assert_eq(plan.items[2].clearance_id, "clear-energy-margin")
  assert_true(plan.items[2].observed.contains("energy margin"))
  assert_true(plan.items[2].required.contains("accepted power"))
  assert_eq(
    plan.items[3].clearance_id,
    "clear-moonbook-review-northeast-stepout",
  )
  assert_true(plan.items[3].evidence_path.contains("review_transitions.json"))
  assert_true(plan.items[3].clearance_action.contains("accepted MoonBook"))
  assert_true(
    plan.blocking_items.contains("clear-terrain-grade-northeast-stepout"),
  )
  assert_true(plan.blocking_items.contains("clear-energy-margin"))
  assert_eq(
    @mission.mission_clearance_kind_label(
      @mission.MissionClearanceKind::EnergyMarginClearance,
    ),
    "energy-margin",
  )
  assert_eq(
    @mission.mission_clearance_status_label(
      @mission.MissionClearanceStatus::ActionRequired,
    ),
    "action-required",
  )
}
