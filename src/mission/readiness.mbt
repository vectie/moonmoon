///|
pub(all) enum MissionReadinessCheckKind {
  TerrainReadiness
  CorridorReadiness
  IlluminationReadiness
  EnergyReadiness
  MoonBookReviewReadiness
  RobotSimulationReadiness
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionReadinessCheck {
  check_id : String
  kind : MissionReadinessCheckKind
  label : String
  decision : TraverseDecision
  evidence_path : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionSimulationReadiness {
  readiness_id : String
  route_id : String
  decision : TraverseDecision
  robot_simulation_status : String
  checks : Array[MissionReadinessCheck]
  blocking_checks : Array[String]
  review_checks : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn mission_readiness_check_kind_label(
  kind : MissionReadinessCheckKind,
) -> String {
  match kind {
    TerrainReadiness => "terrain"
    CorridorReadiness => "corridor"
    IlluminationReadiness => "illumination"
    EnergyReadiness => "energy"
    MoonBookReviewReadiness => "moonbook-review"
    RobotSimulationReadiness => "robot-simulation"
  }
}

///|
pub fn mission_simulation_readiness_label(
  readiness : MissionSimulationReadiness,
) -> String {
  traverse_decision_label(readiness.decision)
}

///|
pub fn readiness_check(
  check_id : String,
  kind : MissionReadinessCheckKind,
  label : String,
  decision : TraverseDecision,
  evidence_path : String,
  reason : String,
) -> MissionReadinessCheck {
  { check_id, kind, label, decision, evidence_path, reason }
}

///|
fn combine_readiness_decision(
  left : TraverseDecision,
  right : TraverseDecision,
) -> TraverseDecision {
  if left == Block || right == Block {
    Block
  } else if left == Review || right == Review {
    Review
  } else {
    Allow
  }
}

///|
fn readiness_decision(
  checks : Array[MissionReadinessCheck],
) -> TraverseDecision {
  let mut decision = Allow
  for check in checks {
    decision = combine_readiness_decision(decision, check.decision)
  }
  decision
}

///|
fn check_ids_with_decision(
  checks : Array[MissionReadinessCheck],
  decision : TraverseDecision,
) -> Array[String] {
  let ids : Array[String] = []
  for check in checks {
    if check.decision == decision {
      ids.push(check.check_id)
    }
  }
  ids
}

///|
fn robot_simulation_status(decision : TraverseDecision) -> String {
  match decision {
    Allow => "simulation-ready"
    Review => "simulation-needs-review"
    Block => "simulation-blocked"
  }
}

///|
fn robot_simulation_check(decision : TraverseDecision) -> MissionReadinessCheck {
  readiness_check(
    "robot-simulation",
    RobotSimulationReadiness,
    "Robot simulation gate",
    decision,
    "output/moonrobo/first_trusted_square_handoffs.json",
    match decision {
      Allow => "MoonRobo simulation may consume the selected-route packet"
      Review =>
        "MoonRobo simulation needs operator review before the packet can be consumed"
      Block =>
        "MoonRobo simulation stays blocked until mission readiness checks clear"
    },
  )
}

///|
fn simulation_next_action(decision : TraverseDecision) -> String {
  match decision {
    Allow =>
      "selected route may advance to MoonRobo simulation; hardware remains outside MoonMoon authority"
    Review =>
      "resolve review checks before MoonRobo simulation consumes the selected-route packet"
    Block =>
      "keep MoonRobo simulation blocked until terrain, corridor, illumination, energy, and MoonBook review checks clear"
  }
}

///|
pub fn simulation_readiness(
  readiness_id : String,
  route_id : String,
  base_checks : Array[MissionReadinessCheck],
) -> MissionSimulationReadiness {
  let base_decision = readiness_decision(base_checks)
  let checks = base_checks
  checks.push(robot_simulation_check(base_decision))
  let decision = readiness_decision(checks)
  {
    readiness_id,
    route_id,
    decision,
    robot_simulation_status: robot_simulation_status(decision),
    checks,
    blocking_checks: check_ids_with_decision(checks, Block),
    review_checks: check_ids_with_decision(checks, Review),
    next_action: simulation_next_action(decision),
  }
}
