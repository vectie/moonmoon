///|
pub(all) enum MissionClearanceKind {
  TerrainGradeClearance
  IlluminationConfidenceClearance
  EnergyMarginClearance
  MoonBookReviewClearance
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MissionClearanceStatus {
  AcceptedEvidence
  RejectedEvidence
  NeedsEvidence
  ActionRequired
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MissionClearanceReviewDecision {
  ClearanceAccept
  ClearanceReject
  ClearanceRequestEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionClearanceTransition {
  transition_id : String
  clearance_id : String
  decision : MissionClearanceReviewDecision
  reviewer_id : String
  recorded_at_utc : String
  evidence_ref : String
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionClearanceItem {
  clearance_id : String
  kind : MissionClearanceKind
  label : String
  decision : TraverseDecision
  status : MissionClearanceStatus
  source_check_id : String
  evidence_path : String
  observed : String
  required : String
  clearance_action : String
  accepted_evidence_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionClearancePlan {
  plan_id : String
  route_id : String
  decision : TraverseDecision
  items : Array[MissionClearanceItem]
  blocking_items : Array[String]
  review_items : Array[String]
  accepted_items : Array[String]
  rejected_items : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn mission_clearance_kind_label(kind : MissionClearanceKind) -> String {
  match kind {
    TerrainGradeClearance => "terrain-grade"
    IlluminationConfidenceClearance => "illumination-confidence"
    EnergyMarginClearance => "energy-margin"
    MoonBookReviewClearance => "moonbook-review"
  }
}

///|
pub fn mission_clearance_status_label(
  status : MissionClearanceStatus,
) -> String {
  match status {
    AcceptedEvidence => "accepted-evidence"
    RejectedEvidence => "rejected-evidence"
    NeedsEvidence => "needs-evidence"
    ActionRequired => "action-required"
  }
}

///|
pub fn mission_clearance_review_decision_label(
  decision : MissionClearanceReviewDecision,
) -> String {
  match decision {
    ClearanceAccept => "accept"
    ClearanceReject => "reject"
    ClearanceRequestEvidence => "request-evidence"
  }
}

///|
pub fn clearance_transition(
  transition_id : String,
  clearance_id : String,
  decision : MissionClearanceReviewDecision,
  reviewer_id : String,
  recorded_at_utc : String,
  evidence_ref : String,
  rationale : String,
) -> MissionClearanceTransition {
  {
    transition_id,
    clearance_id,
    decision,
    reviewer_id,
    recorded_at_utc,
    evidence_ref,
    rationale,
  }
}

///|
fn initial_clearance_status(
  decision : TraverseDecision,
) -> MissionClearanceStatus {
  match decision {
    Allow => AcceptedEvidence
    Review | Block => ActionRequired
  }
}

///|
fn accepted_evidence_id(
  decision : TraverseDecision,
  evidence_path : String,
) -> String {
  match decision {
    Allow => evidence_path
    Review | Block => ""
  }
}

///|
fn clearance_item(
  clearance_id : String,
  kind : MissionClearanceKind,
  label : String,
  decision : TraverseDecision,
  source_check_id : String,
  evidence_path : String,
  observed : String,
  required : String,
  clearance_action : String,
) -> MissionClearanceItem {
  {
    clearance_id,
    kind,
    label,
    decision,
    status: initial_clearance_status(decision),
    source_check_id,
    evidence_path,
    observed,
    required,
    clearance_action,
    accepted_evidence_id: accepted_evidence_id(decision, evidence_path),
  }
}

///|
fn clearance_transition_for(
  transitions : Array[MissionClearanceTransition],
  clearance_id : String,
) -> MissionClearanceTransition? {
  for transition in transitions {
    if transition.clearance_id == clearance_id {
      return Some(transition)
    }
  }
  None
}

///|
fn transition_decision(
  decision : MissionClearanceReviewDecision,
) -> TraverseDecision {
  match decision {
    ClearanceAccept => Allow
    ClearanceReject | ClearanceRequestEvidence => Block
  }
}

///|
fn transition_status(
  decision : MissionClearanceReviewDecision,
) -> MissionClearanceStatus {
  match decision {
    ClearanceAccept => AcceptedEvidence
    ClearanceReject => RejectedEvidence
    ClearanceRequestEvidence => NeedsEvidence
  }
}

///|
fn transition_evidence_id(transition : MissionClearanceTransition) -> String {
  match transition.decision {
    ClearanceAccept => transition.evidence_ref
    ClearanceReject | ClearanceRequestEvidence => ""
  }
}

///|
fn transition_clearance_action(
  item : MissionClearanceItem,
  transition : MissionClearanceTransition,
) -> String {
  let decision = mission_clearance_review_decision_label(transition.decision)
  "\{decision} by \{transition.reviewer_id} at \{transition.recorded_at_utc}: \{transition.rationale}; prior action was \{item.clearance_action}"
}

///|
fn apply_clearance_transition(
  item : MissionClearanceItem,
  transition : MissionClearanceTransition,
) -> MissionClearanceItem {
  {
    clearance_id: item.clearance_id,
    kind: item.kind,
    label: item.label,
    decision: transition_decision(transition.decision),
    status: transition_status(transition.decision),
    source_check_id: item.source_check_id,
    evidence_path: item.evidence_path,
    observed: item.observed,
    required: item.required,
    clearance_action: transition_clearance_action(item, transition),
    accepted_evidence_id: transition_evidence_id(transition),
  }
}

///|
fn apply_clearance_transitions(
  items : Array[MissionClearanceItem],
  transitions : Array[MissionClearanceTransition],
) -> Array[MissionClearanceItem] {
  let reviewed : Array[MissionClearanceItem] = []
  for item in items {
    match clearance_transition_for(transitions, item.clearance_id) {
      Some(transition) =>
        reviewed.push(apply_clearance_transition(item, transition))
      None => reviewed.push(item)
    }
  }
  reviewed
}

///|
fn combine_clearance_decision(
  left : TraverseDecision,
  right : TraverseDecision,
) -> TraverseDecision {
  match (left, right) {
    (Block, _) | (_, Block) => Block
    (Review, _) | (_, Review) => Review
    (Allow, Allow) => Allow
  }
}

///|
fn clearance_decision(items : Array[MissionClearanceItem]) -> TraverseDecision {
  let mut decision = TraverseDecision::Allow
  for item in items {
    decision = combine_clearance_decision(decision, item.decision)
  }
  decision
}

///|
fn clearance_ids_with_decision(
  items : Array[MissionClearanceItem],
  decision : TraverseDecision,
) -> Array[String] {
  let ids : Array[String] = []
  for item in items {
    if item.decision == decision {
      ids.push(item.clearance_id)
    }
  }
  ids
}

///|
fn accepted_clearance_ids(items : Array[MissionClearanceItem]) -> Array[String] {
  let ids : Array[String] = []
  for item in items {
    if item.status == MissionClearanceStatus::AcceptedEvidence {
      ids.push(item.clearance_id)
    }
  }
  ids
}

///|
fn rejected_clearance_ids(items : Array[MissionClearanceItem]) -> Array[String] {
  let ids : Array[String] = []
  for item in items {
    if item.status == MissionClearanceStatus::RejectedEvidence {
      ids.push(item.clearance_id)
    }
  }
  ids
}

///|
fn readiness_check_for(
  readiness : MissionSimulationReadiness,
  check_id : String,
) -> MissionReadinessCheck? {
  for check in readiness.checks {
    if check.check_id == check_id {
      return Some(check)
    }
  }
  None
}

///|
fn check_decision(
  readiness : MissionSimulationReadiness,
  check_id : String,
  fallback : TraverseDecision,
) -> TraverseDecision {
  match readiness_check_for(readiness, check_id) {
    Some(check) => check.decision
    None => fallback
  }
}

///|
fn check_evidence_path(
  readiness : MissionSimulationReadiness,
  check_id : String,
  fallback : String,
) -> String {
  match readiness_check_for(readiness, check_id) {
    Some(check) => check.evidence_path
    None => fallback
  }
}

///|
fn terrain_clearance_item(
  route : RouteCandidate,
  readiness : MissionSimulationReadiness,
) -> MissionClearanceItem {
  let profile = conservative_rover_profile()
  let check_id = "terrain-\{route.route_id}"
  clearance_item(
    "clear-terrain-grade-\{route.route_id}",
    TerrainGradeClearance,
    "Selected route grade and roughness clearance",
    check_decision(readiness, check_id, route.decision),
    check_id,
    check_evidence_path(
      readiness,
      check_id,
      route.terrain_remediation.output_path,
    ),
    "grade \{route.terrain_remediation.max_neighbor_grade}, roughness \{route.terrain_remediation.roughness_m} m, blocking edges \{route.terrain_remediation.blocking_edge_count}/\{route.terrain_remediation.edge_count}, route confidence \{route.terrain_remediation.confidence}",
    "grade < \{profile.max_grade}, roughness < \{profile.max_roughness_m} m, blocking edges 0, confidence >= \{profile.min_confidence}",
    "accept a smoother measured route fixture or keep \{route.route_id} out of simulation until terrain remediation clears the rover profile",
  )
}

///|
fn illumination_clearance_item(
  route : RouteCandidate,
  readiness : MissionSimulationReadiness,
) -> MissionClearanceItem {
  let check_id = "illumination-\{route.route_id}"
  clearance_item(
    "clear-illumination-confidence-\{route.route_id}",
    IlluminationConfidenceClearance,
    "Selected route illumination confidence clearance",
    check_decision(readiness, check_id, route.illumination.decision),
    check_id,
    check_evidence_path(
      readiness,
      check_id,
      route.illumination.local_horizon.output_path,
    ),
    "illumination confidence \{route.illumination.confidence}, relief-shadow risk \{route.illumination.relief_shadow_risk}, terrain-shadow margin \{route.illumination.terrain_shadow_margin_deg} deg",
    "confidence >= \{route.illumination.constraint.min_confidence}, relief-shadow risk < \{route.illumination.constraint.max_relief_shadow_risk}, terrain-shadow margin <= 0 deg",
    "accept local-horizon and terrain-shadow evidence for \{route.route_id} before any MoonRobo simulation packet is consumable",
  )
}

///|
fn energy_clearance_item(
  energy : EnergyAssessment,
  readiness : MissionSimulationReadiness,
) -> MissionClearanceItem {
  let check_id = "energy-window"
  clearance_item(
    "clear-energy-margin",
    EnergyMarginClearance,
    "Rover energy margin clearance",
    check_decision(readiness, check_id, energy.decision),
    check_id,
    check_evidence_path(
      readiness,
      check_id,
      energy.budget.power_window_source_path,
    ),
    "energy margin \{energy.margin_wh} Wh, available \{energy.available_energy_wh} Wh, required \{energy.required_energy_wh} Wh",
    "margin >= \{energy.budget.min_energy_margin_wh} Wh with accepted power, drive, comms, and thermal assumptions",
    "accept an energy budget with non-negative conservative margin or reduce route/survival demand before simulation",
  )
}

///|
fn moonbook_clearance_item(
  route : RouteCandidate,
  readiness : MissionSimulationReadiness,
) -> MissionClearanceItem {
  let check_id = "moonbook-review"
  let decision = check_decision(readiness, check_id, TraverseDecision::Block)
  clearance_item(
    "clear-moonbook-review-\{route.route_id}",
    MoonBookReviewClearance,
    "MoonBook accepted review clearance",
    decision,
    check_id,
    check_evidence_path(
      readiness, check_id, "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
    ),
    "MoonBook review status is \{traverse_decision_label(decision)} for selected route \{route.route_id}",
    "accepted review transitions cover terrain, illumination, energy, and MoonRobo handoff evidence",
    "record accepted MoonBook review transitions for the selected route evidence bundle before simulation",
  )
}

///|
fn clearance_next_action(decision : TraverseDecision) -> String {
  match decision {
    Allow =>
      "selected-route blockers are cleared; simulation packet can advance to MoonRobo review"
    Review =>
      "resolve review clearance items before MoonRobo consumes the selected-route simulation packet"
    Block =>
      "clear required terrain grade, illumination confidence, energy margin, and MoonBook review actions before simulation"
  }
}

///|
pub fn selected_route_clearance_plan(
  plan_id : String,
  route : RouteCandidate,
  energy : EnergyAssessment,
  readiness : MissionSimulationReadiness,
) -> MissionClearancePlan {
  selected_route_clearance_plan_with_transitions(
    plan_id,
    route,
    energy,
    readiness,
    [],
  )
}

///|
pub fn selected_route_clearance_plan_with_transitions(
  plan_id : String,
  route : RouteCandidate,
  energy : EnergyAssessment,
  readiness : MissionSimulationReadiness,
  transitions : Array[MissionClearanceTransition],
) -> MissionClearancePlan {
  let base_items = [
    terrain_clearance_item(route, readiness),
    illumination_clearance_item(route, readiness),
    energy_clearance_item(energy, readiness),
    moonbook_clearance_item(route, readiness),
  ]
  let items = apply_clearance_transitions(base_items, transitions)
  let decision = clearance_decision(items)
  {
    plan_id,
    route_id: route.route_id,
    decision,
    items,
    blocking_items: clearance_ids_with_decision(items, Block),
    review_items: clearance_ids_with_decision(items, Review),
    accepted_items: accepted_clearance_ids(items),
    rejected_items: rejected_clearance_ids(items),
    next_action: clearance_next_action(decision),
  }
}
