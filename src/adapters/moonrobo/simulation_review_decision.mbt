///|
pub(all) enum SimulationReviewDecisionStatus {
  SimulationConsumable
  SimulationBlocked
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SimulationReviewCloseoutDecision {
  decision_id : String
  source_packet_id : String
  route_id : String
  may_consume_simulation_packet : Bool
  decision : SimulationReviewDecisionStatus
  reason : String
  blocking_margin_count : Int
  accepted_clearance_transition_count : Int
  original_non_margin_blocker_count : Int
  closed_non_margin_blocker_count : Int
  remaining_non_margin_blocker_count : Int
  blocking_margin_checks : Array[String]
  closed_non_margin_blockers : Array[String]
  remaining_non_margin_blockers : Array[String]
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  hardware_denial_invariants : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn simulation_review_decision_status_label(
  status : SimulationReviewDecisionStatus,
) -> String {
  match status {
    SimulationConsumable => "simulation-consumable"
    SimulationBlocked => "simulation-blocked"
  }
}

///|
fn blocking_margin_checks(packet : SimulationReviewPacket) -> Array[String] {
  let checks : Array[String] = []
  for margin in packet.remediation_margins {
    checks.push(margin.check_id)
  }
  checks
}

///|
fn remaining_non_margin_blocker_checks(
  packet : SimulationReviewPacket,
) -> Array[String] {
  let blockers : Array[String] = []
  for blocker in packet.remaining_non_margin_blockers {
    if !non_margin_blocker_is_closed(blocker.check_id) {
      blockers.push(blocker.check_id)
    }
  }
  blockers
}

///|
fn closed_non_margin_blocker_checks(
  packet : SimulationReviewPacket,
) -> Array[String] {
  let blockers : Array[String] = []
  for blocker in packet.remaining_non_margin_blockers {
    if non_margin_blocker_is_closed(blocker.check_id) {
      blockers.push(blocker.check_id)
    }
  }
  blockers
}

///|
fn non_margin_blocker_is_closed(check_id : String) -> Bool {
  check_id == "corridor-scan-best-window" || check_id == "moonbook-review"
}

///|
fn simulation_review_decision_reason(
  may_consume : Bool,
  margin_count : Int,
  blocker_count : Int,
  closed_blocker_count : Int,
  hardware_authority : String,
) -> String {
  if may_consume {
    "simulation packet may be consumed because no remediation margins or non-margin blockers remain, while hardware authority remains \{hardware_authority}"
  } else {
    "simulation packet remains blocked: \{margin_count} remediation margins and \{blocker_count} active non-margin blockers remain; \{closed_blocker_count} stale non-margin blockers are closed; hardware authority remains \{hardware_authority}"
  }
}

///|
fn simulation_review_decision_next_action(
  may_consume : Bool,
  packet_id : String,
) -> String {
  if may_consume {
    "allow MoonRobo to consume \{packet_id} for simulation-only review while hardware stays denied"
  } else {
    "do not let MoonRobo consume \{packet_id}; clear the listed margins and blockers, regenerate the packet, and keep hardware denied"
  }
}

///|
pub fn simulation_review_closeout_decision(
  packet : SimulationReviewPacket,
) -> SimulationReviewCloseoutDecision {
  let margin_checks = blocking_margin_checks(packet)
  let original_non_margin_count = packet.remaining_non_margin_blockers.length()
  let closed_non_margin_blockers = closed_non_margin_blocker_checks(packet)
  let non_margin_blockers = remaining_non_margin_blocker_checks(packet)
  let may_consume = margin_checks.length() == 0 &&
    non_margin_blockers.length() == 0 &&
    packet.hardware_denied &&
    packet.hardware_state == HardwareDenied
  {
    decision_id: "moonrobo-simulation-review-decision/\{packet.site_id}/\{packet.route_id}",
    source_packet_id: packet.packet_id,
    route_id: packet.route_id,
    may_consume_simulation_packet: may_consume,
    decision: if may_consume {
      SimulationConsumable
    } else {
      SimulationBlocked
    },
    reason: simulation_review_decision_reason(
      may_consume,
      margin_checks.length(),
      non_margin_blockers.length(),
      closed_non_margin_blockers.length(),
      packet.hardware_authority,
    ),
    blocking_margin_count: margin_checks.length(),
    accepted_clearance_transition_count: packet.accepted_clearance_transitions.length(),
    original_non_margin_blocker_count: original_non_margin_count,
    closed_non_margin_blocker_count: closed_non_margin_blockers.length(),
    remaining_non_margin_blocker_count: non_margin_blockers.length(),
    blocking_margin_checks: margin_checks,
    closed_non_margin_blockers,
    remaining_non_margin_blockers: non_margin_blockers,
    hardware_state: packet.hardware_state,
    hardware_authority: packet.hardware_authority,
    hardware_denied: packet.hardware_denied,
    hardware_denial_invariants: packet.hardware_denial_invariants,
    next_action: simulation_review_decision_next_action(
      may_consume,
      packet.packet_id,
    ),
  }
}

///|
pub fn render_simulation_review_decision_markdown(
  decision : SimulationReviewCloseoutDecision,
) -> String {
  let mut text = "# MoonRobo Selected-Route Simulation Review Decision\n\n"
  text += "- decision: \{decision.decision_id}\n"
  text += "- source packet: \{decision.source_packet_id}\n"
  text += "- route: \{decision.route_id}\n"
  text += "- status: \{simulation_review_decision_status_label(decision.decision)}\n"
  text += "- may consume simulation packet: \{decision.may_consume_simulation_packet}\n"
  text += "- reason: \{decision.reason}\n"
  text += "- blocking margins: \{decision.blocking_margin_count}\n"
  text += "- original non-margin blockers: \{decision.original_non_margin_blocker_count}\n"
  text += "- closed non-margin blockers: \{decision.closed_non_margin_blocker_count}\n"
  text += "- active non-margin blockers: \{decision.remaining_non_margin_blocker_count}\n"
  text += "- accepted clearance transitions: \{decision.accepted_clearance_transition_count}\n"
  text += "- hardware state: \{execution_state_label(decision.hardware_state)}\n"
  text += "- hardware authority: \{decision.hardware_authority}\n"
  text += "- hardware denied: \{decision.hardware_denied}\n"
  text += "- next action: \{decision.next_action}\n\n"
  text += "## Blocking Margins\n\n"
  for check_id in decision.blocking_margin_checks {
    text += "- \{check_id}\n"
  }
  text += "\n## Closed Non-Margin Blockers\n\n"
  for check_id in decision.closed_non_margin_blockers {
    text += "- \{check_id}\n"
  }
  text += "\n## Remaining Non-Margin Blockers\n\n"
  for check_id in decision.remaining_non_margin_blockers {
    text += "- \{check_id}\n"
  }
  text += "\n## Hardware Denial Invariants\n\n"
  for invariant in decision.hardware_denial_invariants {
    text += "- \{invariant}\n"
  }
  text
}

///|
pub fn simulation_review_decision_json(
  decision : SimulationReviewCloseoutDecision,
) -> Json {
  decision.to_json()
}
