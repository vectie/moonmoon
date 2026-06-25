///|
pub(all) struct SimulationReviewEvidenceRef {
  ref_id : String
  entry_id : String
  path : String
  immutable_uri : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SimulationReviewClearanceTransition {
  transition_id : String
  clearance_id : String
  reviewer_id : String
  reviewer_role : String
  recorded_at_utc : String
  source_evidence_refs : Array[SimulationReviewEvidenceRef]
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SimulationReviewMarginEvidence {
  margin_id : String
  check_id : String
  kind : @mission.MissionReadinessCheckKind
  decision : @mission.TraverseDecision
  evidence_path : String
  clearance_status : @mission.MissionClearanceStatus
  clearance_evidence_id : String
  margin_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SimulationReviewBlocker {
  check_id : String
  kind : @mission.MissionReadinessCheckKind
  evidence_path : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SimulationReviewPacket {
  packet_id : String
  site_id : @core.SiteId
  route_id : String
  source_transition_file : String
  clearance_decision : @mission.TraverseDecision
  clearance_allows_simulation_review : Bool
  mission_readiness_decision : @mission.TraverseDecision
  robot_simulation_status : String
  simulation_state : MoonroboExecutionState
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  simulation_packet_path : String
  accepted_clearance_transitions : Array[SimulationReviewClearanceTransition]
  remediation_margins : Array[SimulationReviewMarginEvidence]
  remaining_non_margin_blockers : Array[SimulationReviewBlocker]
  hardware_denial_invariants : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn is_margin_check(kind : @mission.MissionReadinessCheckKind) -> Bool {
  match kind {
    @mission.MissionReadinessCheckKind::TerrainReadiness => true
    @mission.MissionReadinessCheckKind::IlluminationReadiness => true
    @mission.MissionReadinessCheckKind::EnergyReadiness => true
    _ => false
  }
}

///|
fn clearance_item_for_check(
  plan : @mission.MissionClearancePlan,
  check_id : String,
) -> @mission.MissionClearanceItem? {
  for item in plan.items {
    if item.source_check_id == check_id {
      return Some(item)
    }
  }
  None
}

///|
fn accepted_clearance_transitions(
  plan : @mission.MissionClearancePlan,
) -> Array[SimulationReviewClearanceTransition] {
  let transitions : Array[SimulationReviewClearanceTransition] = []
  for item in plan.items {
    if item.status == @mission.MissionClearanceStatus::AcceptedEvidence {
      transitions.push({
        transition_id: "accepted-\{item.clearance_id}",
        clearance_id: item.clearance_id,
        reviewer_id: "operator/rabbita-clearance-review",
        reviewer_role: "mission-review",
        recorded_at_utc: "operator-imported-review-transition",
        source_evidence_refs: [
          {
            ref_id: "\{item.clearance_id}-accepted-source",
            entry_id: "mission/first-trusted-square/selected-route-clearance",
            path: item.evidence_path,
            immutable_uri: item.accepted_evidence_id,
          },
        ],
        rationale: item.clearance_action,
      })
    }
  }
  transitions
}

///|
fn margin_evidence_for_check(
  handoff : MoonroboTaskHandoff,
  check : @mission.MissionReadinessCheck,
) -> SimulationReviewMarginEvidence {
  let item = clearance_item_for_check(handoff.clearance_plan, check.check_id)
  match item {
    Some(clearance) =>
      {
        margin_id: "margin-\{check.check_id}",
        check_id: check.check_id,
        kind: check.kind,
        decision: check.decision,
        evidence_path: check.evidence_path,
        clearance_status: clearance.status,
        clearance_evidence_id: clearance.accepted_evidence_id,
        margin_summary: check.reason,
      }
    None =>
      {
        margin_id: "margin-\{check.check_id}",
        check_id: check.check_id,
        kind: check.kind,
        decision: check.decision,
        evidence_path: check.evidence_path,
        clearance_status: @mission.MissionClearanceStatus::ActionRequired,
        clearance_evidence_id: "",
        margin_summary: check.reason,
      }
  }
}

///|
fn blocker_for_check(
  check : @mission.MissionReadinessCheck,
) -> SimulationReviewBlocker {
  {
    check_id: check.check_id,
    kind: check.kind,
    evidence_path: check.evidence_path,
    reason: check.reason,
  }
}

///|
fn review_packet_next_action(packet_id : String) -> String {
  "keep \{packet_id} blocked for simulation consumption until remediation margins clear, accepted clearance transitions are rechecked, and hardware remains denied by MoonMoon"
}

///|
fn hardware_denial_invariants() -> Array[String] {
  [
    "hardware_state must remain HardwareDenied", "hardware_authority must remain moonmoon-safety-gate-only",
    "MoonMoon must not emit hardware commands or physical execution authority", "simulation readiness must be regenerated from mission checks, not from clearance acceptance alone",
  ]
}

///|
pub fn simulation_review_packet(
  handoff : MoonroboTaskHandoff,
  source_transition_file : String,
) -> SimulationReviewPacket {
  let margins : Array[SimulationReviewMarginEvidence] = []
  let blockers : Array[SimulationReviewBlocker] = []
  for check in handoff.mission_readiness.checks {
    if check.decision == @mission.TraverseDecision::Block {
      if is_margin_check(check.kind) {
        margins.push(margin_evidence_for_check(handoff, check))
      } else {
        blockers.push(blocker_for_check(check))
      }
    }
  }
  let packet_id = "moonrobo-simulation-review-packet/\{handoff.site_id}/\{handoff.route_id}"
  {
    packet_id,
    site_id: handoff.site_id,
    route_id: handoff.route_id,
    source_transition_file,
    clearance_decision: handoff.clearance_plan.decision,
    clearance_allows_simulation_review: handoff.clearance_plan.decision ==
    @mission.TraverseDecision::Allow,
    mission_readiness_decision: handoff.mission_readiness.decision,
    robot_simulation_status: handoff.mission_readiness.robot_simulation_status,
    simulation_state: handoff.execution.simulation_state,
    hardware_state: handoff.execution.hardware_state,
    hardware_authority: handoff.execution.authority,
    hardware_denied: handoff.execution.hardware_state == HardwareDenied,
    simulation_packet_path: handoff.execution.simulation_packet_path,
    accepted_clearance_transitions: accepted_clearance_transitions(
      handoff.clearance_plan,
    ),
    remediation_margins: margins,
    remaining_non_margin_blockers: blockers,
    hardware_denial_invariants: hardware_denial_invariants(),
    next_action: review_packet_next_action(packet_id),
  }
}

///|
pub fn render_simulation_review_packet_markdown(
  packet : SimulationReviewPacket,
) -> String {
  let mut text = "# MoonRobo Selected-Route Simulation Review Packet\n\n"
  text += "- packet: \{packet.packet_id}\n"
  text += "- route: \{packet.route_id}\n"
  text += "- clearance decision: \{@mission.traverse_decision_label(packet.clearance_decision)}\n"
  text += "- mission readiness: \{@mission.traverse_decision_label(packet.mission_readiness_decision)}\n"
  text += "- robot simulation status: \{packet.robot_simulation_status}\n"
  text += "- simulation state: \{execution_state_label(packet.simulation_state)}\n"
  text += "- hardware state: \{execution_state_label(packet.hardware_state)}\n"
  text += "- hardware authority: \{packet.hardware_authority}\n"
  text += "- hardware denied: \{packet.hardware_denied}\n"
  text += "- next action: \{packet.next_action}\n\n"
  text += "## Accepted Clearance Transitions\n\n"
  for transition in packet.accepted_clearance_transitions {
    text += "- \{transition.clearance_id}: \{transition.transition_id}\n"
    for evidence_ref in transition.source_evidence_refs {
      text += "  - source: \{evidence_ref.immutable_uri}\n"
    }
  }
  text += "\n## Remediation Margins\n\n"
  for margin in packet.remediation_margins {
    text += "- \{margin.check_id} (\{@mission.mission_readiness_check_kind_label(margin.kind)})\n"
    text += "  - evidence: \{margin.evidence_path}\n"
    text += "  - clearance: \{@mission.mission_clearance_status_label(margin.clearance_status)}\n"
    text += "  - margin: \{margin.margin_summary}\n"
  }
  text += "\n## Remaining Non-Margin Blockers\n\n"
  for blocker in packet.remaining_non_margin_blockers {
    text += "- \{blocker.check_id}: \{blocker.reason}\n"
  }
  text += "\n## Hardware Denial Invariants\n\n"
  for invariant in packet.hardware_denial_invariants {
    text += "- \{invariant}\n"
  }
  text
}

///|
pub fn simulation_review_packet_json(packet : SimulationReviewPacket) -> Json {
  packet.to_json()
}
