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
  assert_eq(decision.remaining_non_margin_blocker_count, 3)
  assert_true(
    decision.blocking_margin_checks.contains("terrain-northeast-stepout"),
  )
  assert_true(
    decision.remaining_non_margin_blockers.contains("robot-simulation"),
  )
  assert_true(decision.hardware_denied)
  assert_eq(decision.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(decision.reason.contains("3 remediation margins"))
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
