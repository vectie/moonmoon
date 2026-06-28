///|
pub(all) enum NoetixSimulationReadinessDecisionStatus {
  NoetixSimulationConsumable
  NoetixSimulationBlocked
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSimulationReadinessDecision {
  decision_id : String
  source_task_id : String
  site_id : @core.SiteId
  robot_id : String
  may_consume_moonrobo_simulation : Bool
  decision : NoetixSimulationReadinessDecisionStatus
  reason : String
  ready_artifact_count : Int
  blocked_artifact_count : Int
  metadata_blocker_count : Int
  metadata_blocker_ids : Array[String]
  source_metadata_ready : Bool
  source_metadata_inventory : @moonphys.ModelMetadataInventory
  physical_model_ready : Bool
  physical_model_readiness : @moonphys.PhysicalModelReadiness
  physical_model_blocker_count : Int
  physical_model_blocker_ids : Array[String]
  static_support_stable_frame_count : Int
  static_support_review_frame_count : Int
  dynamic_stability_capture_stable_frame_count : Int
  dynamic_stability_review_frame_count : Int
  joint_control_review_frame_count : Int
  joint_control_world_support_review_frame_count : Int
  joint_control_world_capture_review_frame_count : Int
  joint_control_max_support_recovery_shift_m : Double
  joint_control_worst_capture_support_margin_m : Double
  joint_control_max_capture_recovery_shift_m : Double
  joint_control_world_replay_blocker_count : Int
  joint_control_world_replay_blockers : Array[String]
  inertial_collision_review_frame_count : Int
  ready_artifacts : Array[String]
  blocked_artifacts : Array[String]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  hardware_denial_invariants : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn noetix_simulation_readiness_decision_status_label(
  status : NoetixSimulationReadinessDecisionStatus,
) -> String {
  match status {
    NoetixSimulationConsumable => "noetix-simulation-consumable"
    NoetixSimulationBlocked => "noetix-simulation-blocked"
  }
}

///|
fn noetix_ready_artifacts(task : MoonClawNoetixReviewTask) -> Array[String] {
  let artifacts : Array[String] = []
  for artifact in task.artifacts {
    if artifact.ready {
      artifacts.push(artifact.artifact_id)
    }
  }
  artifacts
}

///|
fn noetix_blocked_artifacts(task : MoonClawNoetixReviewTask) -> Array[String] {
  let artifacts : Array[String] = []
  for artifact in task.artifacts {
    if !artifact.ready {
      artifacts.push(artifact.artifact_id)
    }
  }
  artifacts
}

///|
fn noetix_hardware_denial_invariants() -> Array[String] {
  [
    "hardware_state must remain HardwareDenied", "hardware_authority must remain moonmoon-safety-gate-only",
    "Noetix review decision must never issue hardware authority", "MoonRobo simulation consumption requires all review artifacts ready, source metadata inventory ready, and physical model readiness clear",
  ]
}

///|
fn noetix_readiness_reason(
  may_consume : Bool,
  blocked_count : Int,
  metadata_blocker_count : Int,
  metadata_status : String,
  physical_blocker_count : Int,
  physical_status : String,
  hardware_authority : String,
) -> String {
  if may_consume {
    "Noetix simulation evidence may be consumed by MoonRobo review because all artifacts are ready, source metadata status is \{metadata_status}, physical model status is \{physical_status}, and hardware authority remains \{hardware_authority}"
  } else {
    "Noetix simulation remains blocked for MoonRobo consumption: \{blocked_count} review artifacts are blocked, \{metadata_blocker_count} source metadata blockers remain with status \{metadata_status}, and \{physical_blocker_count} physical model blockers remain with status \{physical_status}; hardware authority remains \{hardware_authority}"
  }
}

///|
fn noetix_readiness_next_action(
  may_consume : Bool,
  blocked_artifact_count : Int,
  metadata_blocker_count : Int,
  physical_blocker_count : Int,
) -> String {
  if may_consume {
    "route Noetix evidence to MoonRobo simulation-only consumption while keeping hardware denied"
  } else if blocked_artifact_count == 0 &&
    metadata_blocker_count > 0 &&
    physical_blocker_count > 0 {
    "keep Noetix evidence in MoonClaw review; all review artifacts are ready, so replace authoritative source metadata and physical model metadata, regenerate the decision, and keep hardware denied"
  } else if blocked_artifact_count == 0 && metadata_blocker_count > 0 {
    "keep Noetix evidence in MoonClaw review; all review artifacts are ready, so replace authoritative source metadata, regenerate the decision, and keep hardware denied"
  } else if blocked_artifact_count == 0 && physical_blocker_count > 0 {
    "keep Noetix evidence in MoonClaw review; all review artifacts are ready, so replace authoritative physical model metadata, regenerate the decision, and keep hardware denied"
  } else {
    "keep Noetix evidence in MoonClaw review; clear \{blocked_artifact_count} blocked review artifacts, replace source and physical model metadata, regenerate the decision, and keep hardware denied"
  }
}

///|
pub fn noetix_simulation_readiness_decision(
  task : MoonClawNoetixReviewTask,
) -> NoetixSimulationReadinessDecision {
  let ready_artifacts = noetix_ready_artifacts(task)
  let blocked_artifacts = noetix_blocked_artifacts(task)
  let metadata_inventory = task.source_model_metadata_inventory
  let metadata_blockers = metadata_inventory.blocker_count
  let physical_readiness = task.physical_model_readiness
  let may_consume = blocked_artifacts.length() == 0 &&
    metadata_inventory.ready &&
    physical_readiness.ready &&
    task.hardware_denied &&
    task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied
  {
    decision_id: "moonclaw/\{task.site_id}/noetix-simulation-readiness-decision",
    source_task_id: task.task_id,
    site_id: task.site_id,
    robot_id: task.robot_id,
    may_consume_moonrobo_simulation: may_consume,
    decision: if may_consume {
      NoetixSimulationConsumable
    } else {
      NoetixSimulationBlocked
    },
    reason: noetix_readiness_reason(
      may_consume,
      blocked_artifacts.length(),
      metadata_blockers,
      metadata_inventory.status,
      physical_readiness.blocker_count,
      physical_readiness.status,
      task.hardware_authority,
    ),
    ready_artifact_count: ready_artifacts.length(),
    blocked_artifact_count: blocked_artifacts.length(),
    metadata_blocker_count: metadata_blockers,
    metadata_blocker_ids: metadata_inventory.blocker_ids,
    source_metadata_ready: metadata_inventory.ready,
    source_metadata_inventory: metadata_inventory,
    physical_model_ready: physical_readiness.ready,
    physical_model_readiness: physical_readiness,
    physical_model_blocker_count: physical_readiness.blocker_count,
    physical_model_blocker_ids: physical_readiness.blocker_ids,
    static_support_stable_frame_count: task.static_support_stable_frame_count,
    static_support_review_frame_count: task.static_support_review_frame_count,
    dynamic_stability_capture_stable_frame_count: task.dynamic_stability_capture_stable_frame_count,
    dynamic_stability_review_frame_count: task.dynamic_stability_review_frame_count,
    joint_control_review_frame_count: task.joint_control_review_frame_count,
    joint_control_world_support_review_frame_count: task.joint_control_world_support_review_frame_count,
    joint_control_world_capture_review_frame_count: task.joint_control_world_capture_review_frame_count,
    joint_control_max_support_recovery_shift_m: task.joint_control_max_support_recovery_shift_m,
    joint_control_worst_capture_support_margin_m: task.joint_control_worst_capture_support_margin_m,
    joint_control_max_capture_recovery_shift_m: task.joint_control_max_capture_recovery_shift_m,
    joint_control_world_replay_blocker_count: task.joint_control_world_replay_blocker_count,
    joint_control_world_replay_blockers: task.joint_control_world_replay_blockers,
    inertial_collision_review_frame_count: task.inertial_collision_review_frame_count,
    ready_artifacts,
    blocked_artifacts,
    hardware_state: task.hardware_state,
    hardware_authority: task.hardware_authority,
    hardware_denied: task.hardware_denied,
    hardware_denial_invariants: noetix_hardware_denial_invariants(),
    next_action: noetix_readiness_next_action(
      may_consume,
      blocked_artifacts.length(),
      metadata_blockers,
      physical_readiness.blocker_count,
    ),
  }
}

///|
pub fn first_trusted_square_noetix_simulation_readiness_decision() -> NoetixSimulationReadinessDecision {
  noetix_simulation_readiness_decision(
    first_trusted_square_noetix_review_task(),
  )
}

///|
pub fn first_trusted_square_noetix_simulation_readiness_decision_json() -> Json {
  first_trusted_square_noetix_simulation_readiness_decision().to_json()
}

///|
pub fn render_noetix_simulation_readiness_decision_markdown(
  decision : NoetixSimulationReadinessDecision,
) -> String {
  let mut text = "# MoonClaw Noetix Simulation Readiness Decision\n\n"
  text += "- decision: \{decision.decision_id}\n"
  text += "- source task: \{decision.source_task_id}\n"
  text += "- site: \{decision.site_id}\n"
  text += "- robot: \{decision.robot_id}\n"
  text += "- status: \{noetix_simulation_readiness_decision_status_label(decision.decision)}\n"
  text += "- may consume MoonRobo simulation: \{decision.may_consume_moonrobo_simulation}\n"
  text += "- reason: \{decision.reason}\n"
  text += "- ready artifacts: \{decision.ready_artifact_count}\n"
  text += "- blocked artifacts: \{decision.blocked_artifact_count}\n"
  text += "- source metadata blockers: \{decision.metadata_blocker_count}\n"
  text += "- source metadata blocker ids:\n"
  for blocker in decision.metadata_blocker_ids {
    text += "  - \{blocker}\n"
  }
  text += "- source metadata ready: \{decision.source_metadata_ready}\n"
  text += "- source metadata inventory: \{decision.source_metadata_inventory.status}\n"
  text += "- physical model ready: \{decision.physical_model_ready}\n"
  text += "- physical model blockers: \{decision.physical_model_blocker_count}\n"
  text += "- physical model blocker ids:\n"
  for blocker in decision.physical_model_blocker_ids {
    text += "  - \{blocker}\n"
  }
  text += "- static-support stable frames: \{decision.static_support_stable_frame_count}\n"
  text += "- static-support review frames: \{decision.static_support_review_frame_count}\n"
  text += "- dynamic-stability capture-stable frames: \{decision.dynamic_stability_capture_stable_frame_count}\n"
  text += "- dynamic-stability review frames: \{decision.dynamic_stability_review_frame_count}\n"
  text += "- joint-control review frames: \{decision.joint_control_review_frame_count}\n"
  text += "- joint-control world-support review frames: \{decision.joint_control_world_support_review_frame_count}\n"
  text += "- joint-control world-capture review frames: \{decision.joint_control_world_capture_review_frame_count}\n"
  text += "- joint-control max support recovery shift: \{decision.joint_control_max_support_recovery_shift_m} m\n"
  text += "- joint-control worst capture support margin: \{decision.joint_control_worst_capture_support_margin_m} m\n"
  text += "- joint-control max capture recovery shift: \{decision.joint_control_max_capture_recovery_shift_m} m\n"
  text += "- joint-control world replay blockers: \{decision.joint_control_world_replay_blocker_count}\n"
  text += "- joint-control world replay blocker ids:\n"
  for blocker in decision.joint_control_world_replay_blockers {
    text += "  - \{blocker}\n"
  }
  text += "- inertial-collision review frames: \{decision.inertial_collision_review_frame_count}\n"
  text += "- hardware state: \{@moonrobo.execution_state_label(decision.hardware_state)}\n"
  text += "- hardware authority: \{decision.hardware_authority}\n"
  text += "- hardware denied: \{decision.hardware_denied}\n"
  text += "- next action: \{decision.next_action}\n\n"
  text += "## Blocked Artifacts\n\n"
  for artifact_id in decision.blocked_artifacts {
    text += "- \{artifact_id}\n"
  }
  text += "\n## Ready Artifacts\n\n"
  for artifact_id in decision.ready_artifacts {
    text += "- \{artifact_id}\n"
  }
  text += "\n## Hardware Denial Invariants\n\n"
  for invariant in decision.hardware_denial_invariants {
    text += "- \{invariant}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_simulation_readiness_decision_markdown() -> String {
  render_noetix_simulation_readiness_decision_markdown(
    first_trusted_square_noetix_simulation_readiness_decision(),
  )
}
