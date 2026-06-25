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
  mission_readiness : @mission.MissionSimulationReadiness
  clearance_plan : @mission.MissionClearancePlan
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
  readiness : @mission.MissionSimulationReadiness,
) -> MoonroboExecutionEnvelope {
  let blocking = readiness.blocking_checks
  let review = readiness.review_checks
  {
    simulation_state: simulation_state(readiness.decision),
    replay_state: replay_state(readiness.decision),
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
fn terrain_decision(
  route : @mission.RouteCandidate,
) -> @mission.TraverseDecision {
  route.terrain_remediation.decision
}

///|
fn terrain_reason(route : @mission.RouteCandidate) -> String {
  let terrain = route.terrain_remediation
  "route terrain remediation reports grade \{terrain.max_neighbor_grade}, roughness \{terrain.roughness_m} m, blocking edges \{terrain.blocking_edge_count}/\{terrain.edge_count}: \{terrain.next_action}"
}

///|
fn terrain_evidence_path(route : @mission.RouteCandidate) -> String {
  if route.terrain_remediation.output_path != "" {
    route.terrain_remediation.output_path
  } else {
    "mission/first-trusted-square/routes/\{route.route_id}.json"
  }
}

///|
fn energy_remediation(
  dossier : @site.SiteDossier,
  route : @mission.RouteCandidate,
) -> @mission.EnergyRemediationEvidence {
  @mission.energy_remediation_for_selected_route(
    dossier.energy,
    route.route_id,
    terrain_evidence_path(route),
    if route.illumination.local_horizon.output_path != "" {
      route.illumination.local_horizon.output_path
    } else {
      "mission/first-trusted-square/routes/\{route.route_id}.illumination.json"
    },
    "output/mission/first_trusted_square_energy_remediation.json",
  )
}

///|
fn moonbook_review_decision(
  route : @mission.RouteCandidate,
) -> @mission.TraverseDecision {
  if route.decision == @mission.TraverseDecision::Allow &&
    route.illumination.decision == @mission.TraverseDecision::Allow {
    @mission.TraverseDecision::Review
  } else {
    @mission.TraverseDecision::Block
  }
}

///|
fn moonbook_review_reason(route : @mission.RouteCandidate) -> String {
  if route.decision == @mission.TraverseDecision::Allow &&
    route.illumination.decision == @mission.TraverseDecision::Allow {
    "MoonBook review must accept the selected route, energy window, and handoff before simulation"
  } else {
    "MoonBook review remains blocked because selected route \{route.route_id} still has route or illumination blockers"
  }
}

///|
fn readiness_checks(
  dossier : @site.SiteDossier,
  route : @mission.RouteCandidate,
) -> Array[@mission.MissionReadinessCheck] {
  let best = dossier.corridor_scan[0]
  let illumination_evidence_path = if route.illumination.local_horizon.output_path !=
    "" {
    route.illumination.local_horizon.output_path
  } else {
    "mission/first-trusted-square/routes/\{route.route_id}.illumination.json"
  }
  let energy = energy_remediation(dossier, route)
  [
    @mission.readiness_check(
      "terrain-\{route.route_id}",
      @mission.MissionReadinessCheckKind::TerrainReadiness,
      "Selected-route terrain gate",
      terrain_decision(route),
      terrain_evidence_path(route),
      terrain_reason(route),
    ),
    @mission.readiness_check(
      "corridor-scan-best-window",
      @mission.MissionReadinessCheckKind::CorridorReadiness,
      "Measured corridor search gate",
      best.decision,
      "mission/first-trusted-square/corridor-scan.json",
      best.note,
    ),
    @mission.readiness_check(
      "illumination-\{route.route_id}",
      @mission.MissionReadinessCheckKind::IlluminationReadiness,
      "Illumination and thermal gate",
      route.illumination.decision,
      illumination_evidence_path,
      route.illumination.next_action,
    ),
    @mission.readiness_check(
      "energy-window",
      @mission.MissionReadinessCheckKind::EnergyReadiness,
      "Rover energy window gate",
      energy.decision,
      energy.output_path,
      "energy remediation reports bounded selected-route margin \{energy.bounded_margin_wh} Wh and margin gap \{energy.margin_gap_wh} Wh from power-window evidence \{energy.power_window_evidence_id}: \{energy.next_action}",
    ),
    @mission.readiness_check(
      "moonbook-review",
      @mission.MissionReadinessCheckKind::MoonBookReviewReadiness,
      "MoonBook accepted-review gate",
      moonbook_review_decision(route),
      "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      moonbook_review_reason(route),
    ),
  ]
}

///|
fn mission_readiness(
  dossier : @site.SiteDossier,
  route : @mission.RouteCandidate,
) -> @mission.MissionSimulationReadiness {
  @mission.simulation_readiness(
    "mission/\{dossier.site.site_id}/\{route.route_id}/simulation-readiness",
    route.route_id,
    readiness_checks(dossier, route),
  )
}

///|
fn precondition_from_check(
  check : @mission.MissionReadinessCheck,
) -> RobotPrecondition {
  {
    precondition_id: check.check_id,
    label: check.label,
    decision: check.decision,
    evidence_path: check.evidence_path,
    reason: check.reason,
  }
}

///|
fn preconditions_from_readiness(
  readiness : @mission.MissionSimulationReadiness,
) -> Array[RobotPrecondition] {
  let preconditions : Array[RobotPrecondition] = []
  for check in readiness.checks {
    preconditions.push(precondition_from_check(check))
  }
  preconditions
}

///|
pub fn route_handoff(
  dossier : @site.SiteDossier,
  route : @mission.RouteCandidate,
) -> MoonroboTaskHandoff {
  route_handoff_with_clearance_transitions(dossier, route, [])
}

///|
pub fn route_handoff_with_clearance_transitions(
  dossier : @site.SiteDossier,
  route : @mission.RouteCandidate,
  clearance_transitions : Array[@mission.MissionClearanceTransition],
) -> MoonroboTaskHandoff {
  let readiness = mission_readiness(dossier, route)
  let clearance_plan = @mission.selected_route_clearance_plan_with_transitions(
    "mission/\{dossier.site.site_id}/\{route.route_id}/selected-route-clearance",
    route,
    dossier.energy,
    readiness,
    clearance_transitions,
  )
  let preconditions = preconditions_from_readiness(readiness)
  let decision = readiness.decision
  {
    handoff_id: "moonrobo/\{dossier.site.site_id}/\{route.route_id}/simulation-preconditions",
    site_id: dossier.site.site_id,
    route_id: route.route_id,
    task_kind: "route-simulation-precondition",
    target_body: dossier.site.body,
    decision,
    mission_readiness: readiness,
    clearance_plan,
    execution: execution_envelope(route, readiness),
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
    text += "  - mission readiness: \{@mission.mission_simulation_readiness_label(handoff.mission_readiness)}\n"
    text += "  - robot simulation status: \{handoff.mission_readiness.robot_simulation_status}\n"
    text += "  - clearance plan: \{@mission.traverse_decision_label(handoff.clearance_plan.decision)}\n"
    text += "  - authority: \{handoff.execution.authority}\n"
    text += "  - hardware denial: \{handoff.execution.hardware_denial_reason}\n"
    text += "  - next action: \{handoff.next_action}\n"
    text += "  - selected-route clearance actions:\n"
    for item in handoff.clearance_plan.items {
      text += "    - \{item.clearance_id} (\{@mission.mission_clearance_kind_label(item.kind)}): \{@mission.mission_clearance_status_label(item.status)} - \{item.clearance_action}\n"
    }
    text += "  - mission readiness checks:\n"
    for check in handoff.mission_readiness.checks {
      text += "    - \{check.check_id} (\{@mission.mission_readiness_check_kind_label(check.kind)}): \{@mission.traverse_decision_label(check.decision)} - \{check.reason}\n"
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
