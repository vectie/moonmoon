///|
pub(all) struct RobotPrecondition {
  precondition_id : String
  label : String
  decision : @mission.TraverseDecision
  evidence_path : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonroboExecutionState {
  SimulationReady
  SimulationNeedsReview
  SimulationBlocked
  ReplayReady
  ReplayNeedsReview
  HardwareDenied
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonroboExecutionEnvelope {
  simulation_state : MoonroboExecutionState
  replay_state : MoonroboExecutionState
  hardware_state : MoonroboExecutionState
  authority : String
  simulation_packet_path : String
  replay_source_path : String
  hardware_denial_reason : String
  blocking_preconditions : Array[String]
  review_preconditions : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonroboTaskHandoff {
  handoff_id : String
  site_id : @core.SiteId
  route_id : String
  task_kind : String
  target_body : String
  decision : @mission.TraverseDecision
  execution : MoonroboExecutionEnvelope
  preconditions : Array[RobotPrecondition]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn precondition_status_label(precondition : RobotPrecondition) -> String {
  @mission.traverse_decision_label(precondition.decision)
}

///|
pub fn handoff_status_label(handoff : MoonroboTaskHandoff) -> String {
  @mission.traverse_decision_label(handoff.decision)
}

///|
pub fn execution_state_label(state : MoonroboExecutionState) -> String {
  match state {
    SimulationReady => "simulation-ready"
    SimulationNeedsReview => "simulation-needs-review"
    SimulationBlocked => "simulation-blocked"
    ReplayReady => "replay-ready"
    ReplayNeedsReview => "replay-needs-review"
    HardwareDenied => "hardware-denied"
  }
}

///|
fn combine_decision(
  left : @mission.TraverseDecision,
  right : @mission.TraverseDecision,
) -> @mission.TraverseDecision {
  if left == @mission.TraverseDecision::Block ||
    right == @mission.TraverseDecision::Block {
    @mission.TraverseDecision::Block
  } else if left == @mission.TraverseDecision::Review ||
    right == @mission.TraverseDecision::Review {
    @mission.TraverseDecision::Review
  } else {
    @mission.TraverseDecision::Allow
  }
}

///|
fn blocking_precondition_ids(
  preconditions : Array[RobotPrecondition],
) -> Array[String] {
  let ids : Array[String] = []
  for precondition in preconditions {
    if precondition.decision == @mission.TraverseDecision::Block {
      ids.push(precondition.precondition_id)
    }
  }
  ids
}

///|
fn review_precondition_ids(
  preconditions : Array[RobotPrecondition],
) -> Array[String] {
  let ids : Array[String] = []
  for precondition in preconditions {
    if precondition.decision == @mission.TraverseDecision::Review {
      ids.push(precondition.precondition_id)
    }
  }
  ids
}

///|
fn simulation_state(
  decision : @mission.TraverseDecision,
) -> MoonroboExecutionState {
  match decision {
    Allow => SimulationReady
    Review => SimulationNeedsReview
    Block => SimulationBlocked
  }
}

///|
fn replay_state(decision : @mission.TraverseDecision) -> MoonroboExecutionState {
  match decision {
    Allow => ReplayReady
    Review => ReplayNeedsReview
    Block => ReplayNeedsReview
  }
}

///|
fn execution_envelope(
  route : @mission.RouteCandidate,
  decision : @mission.TraverseDecision,
  preconditions : Array[RobotPrecondition],
) -> MoonroboExecutionEnvelope {
  let blocking = blocking_precondition_ids(preconditions)
  let review = review_precondition_ids(preconditions)
  {
    simulation_state: simulation_state(decision),
    replay_state: replay_state(decision),
    hardware_state: HardwareDenied,
    authority: "moonmoon-safety-gate-only",
    simulation_packet_path: "output/moonrobo/first_trusted_square_handoffs.json#\{route.route_id}",
    replay_source_path: "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/handoffs.json",
    hardware_denial_reason: "MoonMoon never emits hardware commands; \{blocking.length()} blocking and \{review.length()} review preconditions must clear before any external execution authority can be requested.",
    blocking_preconditions: blocking,
    review_preconditions: review,
  }
}

///|
fn route_precondition(route : @mission.RouteCandidate) -> RobotPrecondition {
  {
    precondition_id: "route-\{route.route_id}",
    label: "Route terrain gate",
    decision: route.decision,
    evidence_path: "mission/first-trusted-square/routes/\{route.route_id}.json",
    reason: route.next_action,
  }
}

///|
fn illumination_precondition(
  route : @mission.RouteCandidate,
) -> RobotPrecondition {
  {
    precondition_id: "illumination-\{route.route_id}",
    label: "Illumination and thermal gate",
    decision: route.illumination.decision,
    evidence_path: "mission/first-trusted-square/routes/\{route.route_id}.illumination.json",
    reason: route.illumination.next_action,
  }
}

///|
fn energy_precondition(dossier : @site.SiteDossier) -> RobotPrecondition {
  {
    precondition_id: "energy-window",
    label: "Rover energy window gate",
    decision: dossier.energy.decision,
    evidence_path: "mission/first-trusted-square/energy-window.json",
    reason: dossier.energy.next_action,
  }
}

///|
fn power_window_precondition(dossier : @site.SiteDossier) -> RobotPrecondition {
  let evidence = dossier.power_window_evidence
  let decision = if evidence.has_time_window_ephemeris &&
    evidence.source_status == "ready" {
    @mission.TraverseDecision::Allow
  } else {
    @mission.TraverseDecision::Block
  }
  {
    precondition_id: "power-window-evidence",
    label: "Power-window source evidence gate",
    decision,
    evidence_path: "mission/first-trusted-square/power-window-evidence.json",
    reason: "power-window evidence \{evidence.evidence_id} has source status \{evidence.source_status}",
  }
}

///|
fn corridor_precondition(dossier : @site.SiteDossier) -> RobotPrecondition {
  let best = dossier.corridor_scan[0]
  {
    precondition_id: "corridor-scan-best-window",
    label: "Measured corridor search gate",
    decision: best.decision,
    evidence_path: "mission/first-trusted-square/corridor-scan.json",
    reason: best.note,
  }
}

///|
fn handoff_decision(
  preconditions : Array[RobotPrecondition],
) -> @mission.TraverseDecision {
  let mut decision = @mission.TraverseDecision::Allow
  for precondition in preconditions {
    decision = combine_decision(decision, precondition.decision)
  }
  decision
}

///|
fn handoff_next_action(decision : @mission.TraverseDecision) -> String {
  match decision {
    Allow =>
      "Moonrobo simulation may consume this packet; hardware remains denied until an external execution authority is issued"
    Review =>
      "operator must review Moonmoon preconditions before simulation; replay remains review-only and hardware is denied"
    Block =>
      "Moonrobo must not simulate this route; replay is review-only and hardware is denied until blocking Moonmoon preconditions are cleared"
  }
}

///|
pub fn route_handoff(
  dossier : @site.SiteDossier,
  route : @mission.RouteCandidate,
) -> MoonroboTaskHandoff {
  let preconditions = [
    route_precondition(route),
    illumination_precondition(route),
    power_window_precondition(dossier),
    energy_precondition(dossier),
    corridor_precondition(dossier),
  ]
  let decision = handoff_decision(preconditions)
  {
    handoff_id: "moonrobo/\{dossier.site.site_id}/\{route.route_id}/simulation-preconditions",
    site_id: dossier.site.site_id,
    route_id: route.route_id,
    task_kind: "route-simulation-precondition",
    target_body: dossier.site.body,
    decision,
    execution: execution_envelope(route, decision, preconditions),
    preconditions,
    next_action: handoff_next_action(decision),
  }
}

///|
pub fn from_site_dossier(
  dossier : @site.SiteDossier,
) -> Array[MoonroboTaskHandoff] {
  let handoffs : Array[MoonroboTaskHandoff] = []
  for route in dossier.route_candidates {
    handoffs.push(route_handoff(dossier, route))
  }
  handoffs
}

///|
pub fn first_trusted_square_handoffs() -> Array[MoonroboTaskHandoff] {
  from_site_dossier(@site.first_trusted_square_dossier())
}

///|
pub fn first_trusted_square_primary_handoff() -> MoonroboTaskHandoff {
  let dossier = @site.first_trusted_square_dossier()
  let selected_route_id = dossier.corridor_scan[0].selected_route_id
  let handoffs = from_site_dossier(dossier)
  for handoff in handoffs {
    if handoff.route_id == selected_route_id {
      return handoff
    }
  }
  handoffs[0]
}

///|
pub fn render_markdown(handoffs : Array[MoonroboTaskHandoff]) -> String {
  let mut text = "# Moonrobo Simulation Preconditions\n\n"
  for handoff in handoffs {
    text += "- \{handoff.handoff_id}\n"
    text += "  - route: \{handoff.route_id}\n"
    text += "  - decision: \{handoff_status_label(handoff)}\n"
    text += "  - task: \{handoff.task_kind}\n"
    text += "  - simulation: \{execution_state_label(handoff.execution.simulation_state)}\n"
    text += "  - replay: \{execution_state_label(handoff.execution.replay_state)}\n"
    text += "  - hardware: \{execution_state_label(handoff.execution.hardware_state)}\n"
    text += "  - authority: \{handoff.execution.authority}\n"
    text += "  - hardware denial: \{handoff.execution.hardware_denial_reason}\n"
    text += "  - next action: \{handoff.next_action}\n"
    text += "  - preconditions:\n"
    for precondition in handoff.preconditions {
      text += "    - \{precondition.precondition_id}: \{precondition_status_label(precondition)} - \{precondition.reason}\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_markdown() -> String {
  render_markdown(first_trusted_square_handoffs())
}

///|
pub fn render_json(handoffs : Array[MoonroboTaskHandoff]) -> Json {
  handoffs.to_json()
}

///|
pub fn first_trusted_square_json() -> Json {
  render_json(first_trusted_square_handoffs())
}
