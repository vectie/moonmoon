///|
test "first trusted square exports Moonrobo simulation preconditions" {
  let handoffs = @moonrobo.first_trusted_square_handoffs()
  assert_eq(handoffs.length(), 6)
  assert_eq(handoffs[0].route_id, "direct-lola-window")
  assert_true(handoffs[0].decision == @mission.TraverseDecision::Block)
  assert_eq(handoffs[0].mission_readiness.route_id, "direct-lola-window")
  assert_eq(
    handoffs[0].mission_readiness.robot_simulation_status,
    "simulation-blocked",
  )
  assert_eq(handoffs[0].mission_readiness.checks.length(), 6)
  assert_eq(handoffs[0].preconditions.length(), 6)
  assert_eq(
    handoffs[0].preconditions[0].precondition_id,
    "terrain-direct-lola-window",
  )
  assert_eq(
    handoffs[0].preconditions[1].precondition_id,
    "corridor-scan-best-window",
  )
  assert_eq(
    handoffs[0].preconditions[2].precondition_id,
    "illumination-direct-lola-window",
  )
  assert_eq(handoffs[0].preconditions[3].precondition_id, "energy-window")
  assert_eq(handoffs[0].preconditions[4].precondition_id, "moonbook-review")
  assert_eq(handoffs[0].preconditions[5].precondition_id, "robot-simulation")
  assert_eq(@moonrobo.handoff_status_label(handoffs[0]), "block")
  assert_true(handoffs[0].next_action.contains("must not simulate"))
  assert_true(
    handoffs[0].execution.simulation_state
    is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(
    handoffs[0].execution.replay_state
    is @moonrobo.MoonroboExecutionState::ReplayNeedsReview,
  )
  assert_true(
    handoffs[0].execution.hardware_state
    is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(handoffs[0].execution.authority, "moonmoon-safety-gate-only")
  assert_true(handoffs[0].execution.blocking_preconditions.length() >= 3)
}

///|
test "first trusted square primary Moonrobo handoff follows promoted best corridor window" {
  let handoff = @moonrobo.first_trusted_square_primary_handoff()
  assert_eq(handoff.route_id, "northeast-stepout")
  assert_true(handoff.decision == @mission.TraverseDecision::Block)
  assert_eq(handoff.site_id, "first-trusted-square")
  assert_eq(handoff.target_body, "Moon")
  assert_eq(
    handoff.mission_readiness.readiness_id,
    "mission/first-trusted-square/northeast-stepout/simulation-readiness",
  )
  assert_eq(
    handoff.clearance_plan.plan_id,
    "mission/first-trusted-square/northeast-stepout/selected-route-clearance",
  )
  assert_eq(handoff.mission_readiness.checks.length(), 6)
  assert_eq(handoff.clearance_plan.items.length(), 4)
  assert_eq(handoff.clearance_plan.blocking_items.length(), 4)
  assert_true(
    handoff.clearance_plan.blocking_items.contains(
      "clear-terrain-grade-northeast-stepout",
    ),
  )
  assert_true(
    handoff.clearance_plan.blocking_items.contains(
      "clear-illumination-confidence-northeast-stepout",
    ),
  )
  assert_true(
    handoff.clearance_plan.blocking_items.contains("clear-energy-margin"),
  )
  assert_true(
    handoff.clearance_plan.blocking_items.contains(
      "clear-moonbook-review-northeast-stepout",
    ),
  )
  assert_true(
    handoff.preconditions.any(fn(precondition) {
      precondition.precondition_id == "terrain-northeast-stepout" &&
      precondition.decision == @mission.TraverseDecision::Block
    }),
  )
  assert_true(
    handoff.preconditions.any(fn(precondition) {
      precondition.precondition_id == "energy-window" &&
      precondition.decision == @mission.TraverseDecision::Block &&
      precondition.evidence_path ==
      "output/mission/first_trusted_square_energy_remediation.json" &&
      precondition.reason.contains("bounded selected-route margin")
    }),
  )
  assert_true(
    handoff.preconditions.any(fn(precondition) {
      precondition.precondition_id == "corridor-scan-best-window" &&
      precondition.reason.contains("northeast-stepout")
    }),
  )
  assert_true(
    handoff.preconditions.any(fn(precondition) {
      precondition.precondition_id == "moonbook-review" &&
      precondition.decision == @mission.TraverseDecision::Block &&
      precondition.evidence_path.contains("review_transitions.json")
    }),
  )
  assert_true(
    handoff.execution.blocking_preconditions.contains("energy-window"),
  )
  assert_true(
    handoff.execution.blocking_preconditions.contains(
      "terrain-northeast-stepout",
    ),
  )
  assert_true(
    handoff.execution.blocking_preconditions.contains("moonbook-review"),
  )
  assert_true(
    handoff.execution.blocking_preconditions.contains("robot-simulation"),
  )
  assert_true(
    handoff.execution.hardware_denial_reason.contains("hardware commands"),
  )
}

///|
test "Moonrobo handoff can consume selected-route clearance transitions" {
  let dossier = @site.first_trusted_square_dossier()
  let route = dossier.route_candidates[5]
  let handoff = @moonrobo.route_handoff_with_clearance_transitions(
    dossier,
    route,
    [
      @mission.clearance_transition(
        "operator-clear-terrain-grade-northeast-stepout-accept",
        "clear-terrain-grade-northeast-stepout",
        @mission.MissionClearanceReviewDecision::ClearanceAccept,
        "operator/moonbook-policy-v2",
        "2026-06-25T00:00:00Z",
        "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#terrain",
        "terrain route fixture accepted for simulation rehearsal",
      ),
    ],
  )
  assert_eq(handoff.clearance_plan.accepted_items.length(), 1)
  assert_true(
    handoff.clearance_plan.accepted_items.contains(
      "clear-terrain-grade-northeast-stepout",
    ),
  )
  assert_true(
    handoff.clearance_plan.items[0].status
    is @mission.MissionClearanceStatus::AcceptedEvidence,
  )
  assert_true(
    handoff.clearance_plan.items[0].accepted_evidence_id.contains("terrain"),
  )
  assert_true(handoff.decision == @mission.TraverseDecision::Block)
}

///|
test "Moonrobo simulation review packet joins clearance margins and hardware denial" {
  let dossier = @site.first_trusted_square_dossier()
  let route = dossier.route_candidates[5]
  let handoff = @moonrobo.route_handoff_with_clearance_transitions(
    dossier,
    route,
    [
      @mission.clearance_transition(
        "operator-clear-terrain-grade-northeast-stepout-accept",
        "clear-terrain-grade-northeast-stepout",
        @mission.MissionClearanceReviewDecision::ClearanceAccept,
        "operator/rabbita-clearance-review",
        "2026-06-25T00:00:00Z",
        "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#clear-terrain-grade-northeast-stepout",
        "terrain remediation evidence accepted for simulation review",
      ),
      @mission.clearance_transition(
        "operator-clear-illumination-confidence-northeast-stepout-accept",
        "clear-illumination-confidence-northeast-stepout",
        @mission.MissionClearanceReviewDecision::ClearanceAccept,
        "operator/rabbita-clearance-review",
        "2026-06-25T00:00:00Z",
        "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#clear-illumination-confidence-northeast-stepout",
        "local horizon evidence accepted for simulation review",
      ),
      @mission.clearance_transition(
        "operator-clear-energy-margin-accept",
        "clear-energy-margin",
        @mission.MissionClearanceReviewDecision::ClearanceAccept,
        "operator/rabbita-clearance-review",
        "2026-06-25T00:00:00Z",
        "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#clear-energy-margin",
        "energy remediation evidence accepted for simulation review",
      ),
      @mission.clearance_transition(
        "operator-clear-moonbook-review-northeast-stepout-accept",
        "clear-moonbook-review-northeast-stepout",
        @mission.MissionClearanceReviewDecision::ClearanceAccept,
        "operator/rabbita-clearance-review",
        "2026-06-25T00:00:00Z",
        "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#clear-moonbook-review-northeast-stepout",
        "MoonBook clearance evidence accepted for simulation review",
      ),
    ],
  )
  let packet = @moonrobo.simulation_review_packet(
    handoff, "data/fixtures/rabbita_clearance_transitions_accept.json",
  )
  assert_eq(
    packet.packet_id,
    "moonrobo-simulation-review-packet/first-trusted-square/northeast-stepout",
  )
  assert_true(packet.clearance_allows_simulation_review)
  assert_eq(packet.accepted_clearance_transitions.length(), 4)
  assert_eq(packet.remediation_margins.length(), 3)
  assert_true(packet.hardware_denied)
  assert_true(
    packet.hardware_state is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_true(
    packet.remaining_non_margin_blockers.any(fn(blocker) {
      blocker.check_id == "robot-simulation"
    }),
  )
  assert_true(
    packet.remediation_margins.any(fn(margin) {
      margin.check_id == "terrain-northeast-stepout" &&
      margin.margin_summary.contains("grade") &&
      margin.margin_summary.contains("roughness") &&
      margin.clearance_status ==
      @mission.MissionClearanceStatus::AcceptedEvidence
    }),
  )
  assert_true(
    packet.remediation_margins.any(fn(margin) {
      margin.check_id == "illumination-northeast-stepout" &&
      margin.evidence_path.contains("horizon")
    }),
  )
  assert_true(
    packet.remediation_margins.any(fn(margin) {
      margin.check_id == "energy-window" &&
      margin.margin_summary.contains("bounded selected-route margin") &&
      margin.margin_summary.contains("margin gap")
    }),
  )
  assert_true(
    packet.hardware_denial_invariants.contains(
      "hardware_state must remain HardwareDenied",
    ),
  )
  let markdown = @moonrobo.render_simulation_review_packet_markdown(packet)
  assert_true(
    markdown.contains("MoonRobo Selected-Route Simulation Review Packet"),
  )
  assert_true(markdown.contains("Accepted Clearance Transitions"))
  assert_true(markdown.contains("Remediation Margins"))
  assert_true(markdown.contains("Hardware Denial Invariants"))
  let json = @moonrobo.simulation_review_packet_json(packet).stringify(indent=2)
  assert_true(json.contains("\"hardware_denied\": true"))
  assert_true(json.contains("\"remediation_margins\""))
  assert_true(json.contains("\"accepted_clearance_transitions\""))
  let decision = @moonrobo.simulation_review_closeout_decision(packet)
  assert_eq(
    decision.decision_id,
    "moonrobo-simulation-review-decision/first-trusted-square/northeast-stepout",
  )
  assert_true(!decision.may_consume_simulation_packet)
  assert_true(
    decision.decision
    is @moonrobo.SimulationReviewDecisionStatus::SimulationBlocked,
  )
  assert_eq(decision.blocking_margin_count, 3)
  assert_eq(decision.accepted_clearance_transition_count, 4)
  assert_eq(decision.original_non_margin_blocker_count, 3)
  assert_eq(decision.closed_non_margin_blocker_count, 2)
  assert_eq(decision.remaining_non_margin_blocker_count, 1)
  assert_true(
    decision.blocking_margin_checks.contains("terrain-northeast-stepout"),
  )
  assert_true(
    decision.closed_non_margin_blockers.contains("corridor-scan-best-window"),
  )
  assert_true(decision.closed_non_margin_blockers.contains("moonbook-review"))
  assert_true(
    decision.remaining_non_margin_blockers.contains("robot-simulation"),
  )
  assert_true(decision.hardware_denied)
  assert_eq(decision.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(decision.reason.contains("3 remediation margins"))
  assert_true(decision.reason.contains("1 active non-margin blockers"))
  assert_true(
    decision.reason.contains("2 stale non-margin blockers are closed"),
  )
  assert_true(decision.reason.contains("hardware authority remains"))
  assert_true(decision.next_action.contains("do not let MoonRobo consume"))
  let decision_markdown = @moonrobo.render_simulation_review_decision_markdown(
    decision,
  )
  assert_true(decision_markdown.contains("Simulation Review Decision"))
  assert_true(decision_markdown.contains("Hardware Denial Invariants"))
  let decision_json = @moonrobo.simulation_review_decision_json(decision).stringify(
    indent=2,
  )
  assert_true(
    decision_json.contains("\"may_consume_simulation_packet\": false"),
  )
  assert_true(decision_json.contains("\"decision\": \"SimulationBlocked\""))
}

///|
test "Moonrobo execution state labels distinguish simulation replay and hardware" {
  assert_eq(
    @moonrobo.execution_state_label(
      @moonrobo.MoonroboExecutionState::SimulationReady,
    ),
    "simulation-ready",
  )
  assert_eq(
    @moonrobo.execution_state_label(
      @moonrobo.MoonroboExecutionState::ReplayReady,
    ),
    "replay-ready",
  )
  assert_eq(
    @moonrobo.execution_state_label(
      @moonrobo.MoonroboExecutionState::HardwareDenied,
    ),
    "hardware-denied",
  )
}

///|
test "Moonrobo remediation margin modeling consumes receipt contract" {
  let pass = @moonrobo.first_trusted_square_remediation_margin_modeling_pass()
  assert_eq(
    pass.modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass",
  )
  assert_eq(
    pass.source_receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt",
  )
  assert_eq(
    pass.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/task",
  )
  assert_eq(pass.source_remediation_state, "OpenMarginsCarriedForward")
  assert_eq(pass.route_id, "northeast-stepout")
  assert_true(
    pass.state
    is @moonrobo.RemediationMarginModelingState::AllMarginsStillBlocking,
  )
  assert_eq(pass.active_margin_count, 3)
  assert_eq(pass.cleared_margin_count, 0)
  assert_eq(pass.still_blocking_margin_count, 3)
  assert_true(
    pass.hardware_state is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(pass.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(pass.hardware_denied)
  assert_eq(pass.margin_results.length(), 3)
  assert_true(
    pass.margin_results.all(fn(result) {
      result.result_status ==
      @moonrobo.RemediationMarginModelingResultStatus::MarginStillBlocking &&
      !result.cleared
    }),
  )
  assert_true(
    pass.margin_results.any(fn(result) {
      result.margin_id == "terrain-northeast-stepout" &&
      result.modeling_command.contains(
        "check_selected_route_terrain_remediation.py",
      ) &&
      result.modeling_evidence_path.contains("terrain_remediation")
    }),
  )
  assert_true(
    pass.margin_results.any(fn(result) {
      result.margin_id == "illumination-northeast-stepout" &&
      result.modeling_command.contains("check_selected_route_horizon_model.py") &&
      result.modeling_evidence_path.contains("horizon")
    }),
  )
  assert_true(
    pass.margin_results.any(fn(result) {
      result.margin_id == "energy-window" &&
      result.modeling_command.contains("check_energy_margin_remediation.py") &&
      result.modeling_evidence_path.contains("energy_remediation")
    }),
  )
  assert_true(
    pass.next_action.contains("carry the terrain, local-horizon, and energy"),
  )
  let markdown = @moonrobo.first_trusted_square_remediation_margin_modeling_markdown()
  assert_true(markdown.contains("MoonRobo Remediation Margin Modeling Passes"))
  assert_true(markdown.contains("AllMarginsStillBlocking"))
  assert_true(markdown.contains("terrain-northeast-stepout"))
  assert_true(markdown.contains("moonmoon-safety-gate-only"))
  let json = @moonrobo.first_trusted_square_remediation_margin_modeling_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains("\"source_remediation_state\": \"OpenMarginsCarriedForward\""),
  )
  assert_true(json.contains("\"MarginStillBlocking\""))
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "Moonrobo remediation margin projection blocks simulation consumption" {
  let projection = @moonrobo.first_trusted_square_remediation_margin_projection()
  assert_eq(
    projection.projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/projection",
  )
  assert_eq(
    projection.source_modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass",
  )
  assert_eq(
    projection.source_modeling_path,
    "output/moonrobo/first_trusted_square_remediation_margin_modeling.json",
  )
  assert_true(
    projection.source_modeling_state
    is @moonrobo.RemediationMarginModelingState::AllMarginsStillBlocking,
  )
  assert_true(!projection.may_consume_simulation)
  assert_true(
    projection.projection_status
    is @moonrobo.RemediationMarginProjectionStatus::NoConsumeSimulationBlocked,
  )
  assert_true(
    projection.simulation_state
    is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_eq(projection.active_margin_count, 3)
  assert_eq(projection.cleared_margin_count, 0)
  assert_eq(projection.still_blocking_margin_count, 3)
  assert_eq(projection.blocking_margin_ids.length(), 3)
  assert_true(
    projection.blocking_margin_ids.contains("terrain-northeast-stepout"),
  )
  assert_true(
    projection.blocking_margin_ids.contains("illumination-northeast-stepout"),
  )
  assert_true(projection.blocking_margin_ids.contains("energy-window"))
  assert_eq(projection.consumed_margin_result_ids.length(), 3)
  assert_true(
    projection.hardware_state
    is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(projection.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(projection.hardware_denied)
  assert_true(projection.reason.contains("no-consume projection"))
  assert_true(projection.next_action.contains("do not let MoonRobo consume"))
  let markdown = @moonrobo.first_trusted_square_remediation_margin_projection_markdown()
  assert_true(
    markdown.contains("MoonRobo Remediation Margin Clearance Projection"),
  )
  assert_true(markdown.contains("NoConsumeSimulationBlocked"))
  assert_true(markdown.contains("AllMarginsStillBlocking"))
  assert_true(markdown.contains("simulation-blocked"))
  let json = @moonrobo.first_trusted_square_remediation_margin_projection_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(
    json.contains("\"projection_status\": \"NoConsumeSimulationBlocked\""),
  )
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "Moonrobo remediation margin refresh modeling consumes refresh receipt contract" {
  let pass = @moonrobo.first_trusted_square_remediation_margin_refresh_modeling_pass()
  assert_eq(
    pass.modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass",
  )
  assert_eq(
    pass.source_receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt",
  )
  assert_eq(
    pass.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task",
  )
  assert_eq(
    pass.source_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/projection",
  )
  assert_eq(pass.source_refresh_state, "RefreshesCarriedForward")
  assert_eq(pass.route_id, "northeast-stepout")
  assert_true(
    pass.state
    is @moonrobo.RemediationMarginRefreshModelingState::AllRefreshesStillBlocking,
  )
  assert_eq(pass.refresh_action_count, 3)
  assert_eq(pass.refreshed_count, 0)
  assert_eq(pass.still_blocking_count, 3)
  assert_true(!pass.may_consume_simulation)
  assert_true(
    pass.simulation_state is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(
    pass.hardware_state is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(pass.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(pass.hardware_denied)
  assert_eq(pass.refresh_results.length(), 3)
  assert_true(
    pass.refresh_results.all(fn(result) {
      result.result_status ==
      @moonrobo.RemediationMarginRefreshModelingResultStatus::RefreshStillBlocking &&
      !result.refreshed
    }),
  )
  assert_true(
    pass.refresh_results.any(fn(result) {
      result.rank == 1 &&
      result.margin_id == "terrain-northeast-stepout" &&
      result.refresh_id == "refresh-terrain-northeast-stepout" &&
      result.modeling_command.contains(
        "check_selected_route_terrain_remediation.py",
      )
    }),
  )
  assert_true(
    pass.refresh_results.any(fn(result) {
      result.rank == 2 &&
      result.margin_id == "illumination-northeast-stepout" &&
      result.modeling_command.contains("check_selected_route_horizon_model.py")
    }),
  )
  assert_true(
    pass.refresh_results.any(fn(result) {
      result.rank == 3 &&
      result.margin_id == "energy-window" &&
      result.modeling_command.contains("check_energy_margin_remediation.py")
    }),
  )
  assert_true(pass.next_action.contains("do not let MoonRobo consume"))
  let markdown = @moonrobo.first_trusted_square_remediation_margin_refresh_modeling_markdown()
  assert_true(
    markdown.contains("MoonRobo Remediation Margin Refresh Modeling Passes"),
  )
  assert_true(markdown.contains("AllRefreshesStillBlocking"))
  assert_true(markdown.contains("RefreshesCarriedForward"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("simulation-blocked"))
  assert_true(markdown.contains("terrain-northeast-stepout"))
  assert_true(markdown.contains("moonmoon-safety-gate-only"))
  let json = @moonrobo.first_trusted_square_remediation_margin_refresh_modeling_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains("\"source_refresh_state\": \"RefreshesCarriedForward\""),
  )
  assert_true(json.contains("\"result_status\": \"RefreshStillBlocking\""))
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"simulation_state\": \"SimulationBlocked\""))
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "Moonrobo remediation margin refresh projection blocks simulation consumption" {
  let projection = @moonrobo.first_trusted_square_remediation_margin_refresh_projection()
  assert_eq(
    projection.projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
  )
  assert_eq(
    projection.source_modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass",
  )
  assert_eq(
    projection.source_modeling_path,
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json",
  )
  assert_true(
    projection.source_modeling_state
    is @moonrobo.RemediationMarginRefreshModelingState::AllRefreshesStillBlocking,
  )
  assert_eq(
    projection.source_receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt",
  )
  assert_eq(
    projection.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task",
  )
  assert_eq(
    projection.source_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/projection",
  )
  assert_true(!projection.may_consume_simulation)
  assert_true(
    projection.projection_status
    is @moonrobo.RemediationMarginRefreshProjectionStatus::NoConsumeRefreshSimulationBlocked,
  )
  assert_true(
    projection.simulation_state
    is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_eq(projection.refresh_action_count, 3)
  assert_eq(projection.refreshed_count, 0)
  assert_eq(projection.still_blocking_count, 3)
  assert_eq(projection.consumed_refresh_result_ids.length(), 3)
  assert_true(
    projection.consumed_refresh_result_ids.contains(
      "refresh-terrain-northeast-stepout",
    ),
  )
  assert_true(
    projection.blocking_refresh_ids.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(projection.blocking_refresh_ids.contains("refresh-energy-window"))
  assert_true(
    projection.blocking_margin_ids.contains("terrain-northeast-stepout"),
  )
  assert_true(
    projection.blocking_margin_ids.contains("illumination-northeast-stepout"),
  )
  assert_true(projection.blocking_margin_ids.contains("energy-window"))
  assert_true(
    projection.hardware_state
    is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(projection.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(projection.hardware_denied)
  assert_true(projection.reason.contains("no-consume refresh projection"))
  assert_true(projection.reason.contains("AllRefreshesStillBlocking"))
  assert_true(projection.next_action.contains("do not let MoonRobo consume"))
  let markdown = @moonrobo.first_trusted_square_remediation_margin_refresh_projection_markdown()
  assert_true(
    markdown.contains("MoonRobo Remediation Margin Refresh Projection"),
  )
  assert_true(markdown.contains("NoConsumeRefreshSimulationBlocked"))
  assert_true(markdown.contains("AllRefreshesStillBlocking"))
  assert_true(markdown.contains("simulation-blocked"))
  assert_true(markdown.contains("refresh-terrain-northeast-stepout"))
  let json = @moonrobo.first_trusted_square_remediation_margin_refresh_projection_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(
    json.contains(
      "\"projection_status\": \"NoConsumeRefreshSimulationBlocked\"",
    ),
  )
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "Moonrobo remediation margin refresh follow-up modeling consumes follow-up receipt contract" {
  let pass = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_modeling_pass()
  assert_eq(
    pass.modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-modeling-pass",
  )
  assert_eq(
    pass.source_receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt",
  )
  assert_eq(
    pass.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
  )
  assert_eq(
    pass.source_refresh_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
  )
  assert_eq(
    pass.source_modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass",
  )
  assert_eq(pass.source_modeling_state, "AllRefreshesStillBlocking")
  assert_eq(pass.source_projection_status, "NoConsumeRefreshSimulationBlocked")
  assert_eq(pass.source_followup_state, "FollowupRefreshesCarriedForward")
  assert_true(
    pass.state
    is @moonrobo.RemediationMarginRefreshFollowupModelingState::AllFollowupRefreshesStillBlocking,
  )
  assert_eq(pass.followup_action_count, 3)
  assert_eq(pass.refreshed_count, 0)
  assert_eq(pass.still_blocking_count, 3)
  assert_true(!pass.may_consume_simulation)
  assert_true(
    pass.simulation_state is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(
    pass.hardware_state is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(pass.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(pass.hardware_denied)
  assert_eq(pass.followup_results.length(), 3)
  assert_true(
    pass.followup_results.all(fn(result) {
      result.result_status ==
      @moonrobo.RemediationMarginRefreshFollowupModelingResultStatus::FollowupRefreshStillBlocking &&
      !result.refreshed
    }),
  )
  assert_true(
    pass.followup_results.any(fn(result) {
      result.rank == 1 &&
      result.margin_id == "terrain-northeast-stepout" &&
      result.refresh_id == "refresh-terrain-northeast-stepout" &&
      result.modeling_command.contains(
        "check_selected_route_terrain_remediation.py",
      )
    }),
  )
  assert_true(
    pass.followup_results.any(fn(result) {
      result.rank == 2 &&
      result.margin_id == "illumination-northeast-stepout" &&
      result.modeling_command.contains("check_selected_route_horizon_model.py")
    }),
  )
  assert_true(
    pass.followup_results.any(fn(result) {
      result.rank == 3 &&
      result.margin_id == "energy-window" &&
      result.modeling_command.contains("check_energy_margin_remediation.py")
    }),
  )
  assert_true(pass.next_action.contains("do not let MoonRobo consume"))
  let markdown = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_modeling_markdown()
  assert_true(
    markdown.contains(
      "MoonRobo Remediation Margin Refresh Follow-Up Modeling Passes",
    ),
  )
  assert_true(markdown.contains("AllFollowupRefreshesStillBlocking"))
  assert_true(markdown.contains("FollowupRefreshesCarriedForward"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("simulation-blocked"))
  assert_true(markdown.contains("FollowupRefreshStillBlocking"))
  assert_true(markdown.contains("terrain-northeast-stepout"))
  assert_true(markdown.contains("moonmoon-safety-gate-only"))
  let json = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_modeling_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"source_followup_state\": \"FollowupRefreshesCarriedForward\"",
    ),
  )
  assert_true(
    json.contains("\"result_status\": \"FollowupRefreshStillBlocking\""),
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"simulation_state\": \"SimulationBlocked\""))
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "Moonrobo remediation margin refresh follow-up projection blocks simulation consumption" {
  let projection = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_projection()
  assert_eq(
    projection.projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection",
  )
  assert_eq(
    projection.source_modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-modeling-pass",
  )
  assert_eq(
    projection.source_modeling_path,
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json",
  )
  assert_true(
    projection.source_modeling_state
    is @moonrobo.RemediationMarginRefreshFollowupModelingState::AllFollowupRefreshesStillBlocking,
  )
  assert_eq(
    projection.source_receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt",
  )
  assert_eq(
    projection.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
  )
  assert_eq(
    projection.source_refresh_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
  )
  assert_eq(projection.source_followup_state, "FollowupRefreshesCarriedForward")
  assert_true(!projection.may_consume_simulation)
  assert_true(
    projection.projection_status
    is @moonrobo.RemediationMarginRefreshFollowupProjectionStatus::NoConsumeFollowupRefreshSimulationBlocked,
  )
  assert_true(
    projection.simulation_state
    is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_eq(projection.followup_action_count, 3)
  assert_eq(projection.refreshed_count, 0)
  assert_eq(projection.still_blocking_count, 3)
  assert_eq(projection.consumed_followup_result_ids.length(), 3)
  assert_true(
    projection.consumed_followup_result_ids.contains(
      "refresh-terrain-northeast-stepout",
    ),
  )
  assert_true(
    projection.blocking_refresh_ids.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(projection.blocking_refresh_ids.contains("refresh-energy-window"))
  assert_true(
    projection.blocking_margin_ids.contains("terrain-northeast-stepout"),
  )
  assert_true(
    projection.blocking_margin_ids.contains("illumination-northeast-stepout"),
  )
  assert_true(projection.blocking_margin_ids.contains("energy-window"))
  assert_true(
    projection.hardware_state
    is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(projection.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(projection.hardware_denied)
  assert_true(
    projection.reason.contains("no-consume follow-up refresh projection"),
  )
  assert_true(projection.reason.contains("AllFollowupRefreshesStillBlocking"))
  assert_true(projection.next_action.contains("do not let MoonRobo consume"))
  let markdown = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_projection_markdown()
  assert_true(
    markdown.contains(
      "MoonRobo Remediation Margin Refresh Follow-Up Projection",
    ),
  )
  assert_true(markdown.contains("NoConsumeFollowupRefreshSimulationBlocked"))
  assert_true(markdown.contains("AllFollowupRefreshesStillBlocking"))
  assert_true(markdown.contains("simulation-blocked"))
  assert_true(markdown.contains("refresh-terrain-northeast-stepout"))
  let json = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_projection_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(
    json.contains(
      "\"projection_status\": \"NoConsumeFollowupRefreshSimulationBlocked\"",
    ),
  )
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "Moonrobo remediation margin cycle closeout policy stops automatic follow-up loops" {
  let policy = @moonrobo.first_trusted_square_remediation_margin_cycle_closeout_policy()
  assert_eq(
    policy.policy_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy",
  )
  assert_eq(policy.route_id, "northeast-stepout")
  assert_eq(
    policy.source_refresh_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
  )
  assert_true(
    policy.source_refresh_projection_status
    is @moonrobo.RemediationMarginRefreshProjectionStatus::NoConsumeRefreshSimulationBlocked,
  )
  assert_eq(
    policy.source_refresh_projection_path,
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
  )
  assert_eq(
    policy.source_followup_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection",
  )
  assert_true(
    policy.source_followup_projection_status
    is @moonrobo.RemediationMarginRefreshFollowupProjectionStatus::NoConsumeFollowupRefreshSimulationBlocked,
  )
  assert_eq(
    policy.source_followup_projection_path,
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
  )
  assert_true(!policy.may_consume_simulation)
  assert_true(
    policy.simulation_state
    is @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(
    policy.closeout_status
    is @moonrobo.RemediationMarginCycleCloseoutStatus::NoConsumeCycleClosedForPolicy,
  )
  assert_eq(policy.refresh_cycle_count, 2)
  assert_eq(policy.blocker_count, 3)
  assert_true(
    policy.blocking_refresh_ids.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    policy.blocking_refresh_ids.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(policy.blocking_refresh_ids.contains("refresh-energy-window"))
  assert_true(policy.blocking_margin_ids.contains("terrain-northeast-stepout"))
  assert_true(
    policy.blocking_margin_ids.contains("illumination-northeast-stepout"),
  )
  assert_true(policy.blocking_margin_ids.contains("energy-window"))
  assert_eq(policy.dispositions.length(), 3)
  assert_true(
    policy.dispositions.any(fn(item) {
      item.margin_id == "terrain-northeast-stepout" &&
      item.blocker_domain == "terrain" &&
      item.disposition
      is @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision
    }),
  )
  assert_true(
    policy.dispositions.any(fn(item) {
      item.margin_id == "illumination-northeast-stepout" &&
      item.blocker_domain == "local-horizon" &&
      item.disposition
      is @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence
    }),
  )
  assert_true(
    policy.dispositions.any(fn(item) {
      item.margin_id == "energy-window" &&
      item.blocker_domain == "energy" &&
      item.disposition
      is @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence
    }),
  )
  assert_true(
    policy.hardware_state is @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(policy.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(policy.hardware_denied)
  assert_true(policy.reason.contains("terrain/horizon/energy blockers"))
  assert_true(policy.next_action.contains("retry/escalate/freeze dispositions"))
  let markdown = @moonrobo.first_trusted_square_remediation_margin_cycle_closeout_policy_markdown()
  assert_true(
    markdown.contains("MoonRobo Remediation Margin Cycle Closeout Policy"),
  )
  assert_true(markdown.contains("NoConsumeCycleClosedForPolicy"))
  assert_true(markdown.contains("NoConsumeRefreshSimulationBlocked"))
  assert_true(markdown.contains("NoConsumeFollowupRefreshSimulationBlocked"))
  assert_true(markdown.contains("EscalateToOperatorDecision"))
  assert_true(markdown.contains("RetryWithNewEvidence"))
  assert_true(markdown.contains("FreezeUntilNewSourceEvidence"))
  let json = @moonrobo.first_trusted_square_remediation_margin_cycle_closeout_policy_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"simulation_state\": \"SimulationBlocked\""))
  assert_true(
    json.contains("\"closeout_status\": \"NoConsumeCycleClosedForPolicy\""),
  )
  assert_true(json.contains("\"hardware_denied\": true"))
}

///|
test "first trusted square Moonrobo renderers expose blocked handoff evidence" {
  let markdown = @moonrobo.first_trusted_square_markdown()
  assert_true(markdown.contains("Moonrobo Simulation Preconditions"))
  assert_true(markdown.contains("southwest-bypass"))
  assert_true(markdown.contains("northeast-stepout"))
  assert_true(markdown.contains("power-window evidence"))
  assert_true(markdown.contains("energy-window"))
  assert_true(markdown.contains("bounded selected-route margin"))
  assert_true(markdown.contains("mission readiness"))
  assert_true(markdown.contains("clearance plan"))
  assert_true(markdown.contains("selected-route clearance actions"))
  assert_true(markdown.contains("clear-terrain-grade-northeast-stepout"))
  assert_true(markdown.contains("clear-energy-margin"))
  assert_true(markdown.contains("moonbook-review"))
  assert_true(markdown.contains("robot-simulation"))
  assert_true(markdown.contains("must not simulate"))
  assert_true(markdown.contains("simulation-blocked"))
  assert_true(markdown.contains("replay-needs-review"))
  assert_true(markdown.contains("hardware-denied"))
  let json = @moonrobo.first_trusted_square_json().stringify(indent=2)
  assert_true(json.contains("\"task_kind\": \"route-simulation-precondition\""))
  assert_true(json.contains("\"route_id\": \"southwest-bypass\""))
  assert_true(json.contains("\"route_id\": \"northeast-stepout\""))
  assert_true(json.contains("power-window evidence"))
  assert_true(json.contains("first_trusted_square_energy_remediation.json"))
  assert_true(json.contains("\"mission_readiness\""))
  assert_true(
    json.contains("\"robot_simulation_status\": \"simulation-blocked\""),
  )
  assert_true(json.contains("\"clearance_plan\""))
  assert_true(json.contains("\"clearance_id\": \"clear-energy-margin\""))
  assert_true(json.contains("\"status\": \"ActionRequired\""))
  assert_true(json.contains("\"kind\": \"MoonBookReviewReadiness\""))
  assert_true(json.contains("\"check_id\": \"moonbook-review\""))
  assert_true(json.contains("\"precondition_id\": \"energy-window\""))
  assert_true(json.contains("\"simulation_state\": \"SimulationBlocked\""))
  assert_true(json.contains("\"replay_state\": \"ReplayNeedsReview\""))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
  assert_true(json.contains("\"authority\": \"moonmoon-safety-gate-only\""))
  assert_true(json.contains("\"Block\""))
}
