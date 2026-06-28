///|
pub(all) struct MoonClawNoetixReadinessWorkItem {
  work_item_id : String
  decision_id : String
  source_task_id : String
  site_id : @core.SiteId
  robot_id : String
  rank : Int
  state : MoonClawReceiptStatus
  blocker_domain : String
  blocker_count : Int
  blocker_ids : Array[String]
  required_evidence : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  may_consume_moonrobo_simulation : Bool
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn noetix_readiness_work_item(
  decision : NoetixSimulationReadinessDecision,
  rank : Int,
  blocker_domain : String,
  blocker_count : Int,
  blocker_ids : Array[String],
  required_evidence : String,
  target_artifact_path : String,
  command : String,
  acceptance_check : String,
  next_action : String,
) -> MoonClawNoetixReadinessWorkItem {
  {
    work_item_id: "\{decision.decision_id}/work-item-\{rank}-\{blocker_domain}",
    decision_id: decision.decision_id,
    source_task_id: decision.source_task_id,
    site_id: decision.site_id,
    robot_id: decision.robot_id,
    rank,
    state: NeedsReview,
    blocker_domain,
    blocker_count,
    blocker_ids,
    required_evidence,
    target_artifact_path,
    command,
    acceptance_check,
    may_consume_moonrobo_simulation: false,
    hardware_state: decision.hardware_state,
    hardware_authority: decision.hardware_authority,
    hardware_denied: decision.hardware_denied,
    safety_gate: "Noetix readiness work items may only replace simulation-review blockers; they must not issue hardware authority or consume MoonRobo simulation until the readiness decision becomes consumable.",
    next_action,
  }
}

///|
pub fn noetix_readiness_work_items_from_decision(
  decision : NoetixSimulationReadinessDecision,
) -> Array[MoonClawNoetixReadinessWorkItem] {
  let items : Array[MoonClawNoetixReadinessWorkItem] = []
  if decision.metadata_blocker_count > 0 {
    items.push(
      noetix_readiness_work_item(
        decision,
        1,
        "source-metadata",
        decision.metadata_blocker_count,
        decision.metadata_blocker_ids,
        "authoritative collision and inertial metadata for every Noetix source link",
        "output/moonrobo/first_trusted_square_noetix_source_model.json",
        "moon run cmd/main -- moonrobo noetix model json",
        "python3 scripts/check_moonrobo_noetix_source_model.py output/moonrobo/first_trusted_square_noetix_source_model.json && python3 scripts/check_moonrobo_noetix_source_sync.py output/moonrobo/first_trusted_square_noetix_source_model.json output/moonrobo/first_trusted_square_noetix_walk_command.json",
        "Replace missing source collision/inertial metadata, regenerate the Noetix source-model audit, and keep hardware denied.",
      ),
    )
  }
  if decision.physical_model_blocker_count > 0 {
    items.push(
      noetix_readiness_work_item(
        decision,
        2,
        "physical-model",
        decision.physical_model_blocker_count,
        decision.physical_model_blocker_ids,
        "authoritative mass, center-of-mass, inertia, collision, sole, servo, damping, stiffness, and friction inputs for every Noetix physical_model_gaps entry",
        "output/moonrobo/first_trusted_square_noetix_stability.json",
        "moon run cmd/main -- moonrobo noetix stability json",
        "python3 scripts/check_moonrobo_noetix_stability.py output/moonrobo/first_trusted_square_noetix_stability.json && python3 scripts/check_moonrobo_noetix_inertial_collision.py output/moonrobo/first_trusted_square_noetix_inertial_collision.json",
        "Replace each Noetix physical_model_gaps entry with Moonrobo model data, regenerate stability and inertial/collision evidence, and keep hardware denied.",
      ),
    )
  }
  if decision.joint_control_world_replay_blocker_count > 0 {
    items.push(
      noetix_readiness_work_item(
        decision,
        3,
        "world-replay",
        decision.joint_control_world_replay_blocker_count,
        decision.joint_control_world_replay_blockers,
        "Moonphys world replay review with envelope, support, and dynamic-support blockers cleared",
        "output/moonrobo/first_trusted_square_noetix_control.json",
        "moon run cmd/main -- moonrobo noetix control json",
        "python3 scripts/check_moonrobo_noetix_control.py output/moonrobo/first_trusted_square_noetix_control.json",
        "Improve motor-driven Moonphys world replay evidence until the named replay blockers clear, then regenerate MoonClaw review artifacts.",
      ),
    )
  }
  if decision.blocked_artifact_count > 0 {
    items.push(
      noetix_readiness_work_item(
        decision,
        4,
        "review-artifacts",
        decision.blocked_artifact_count,
        decision.blocked_artifacts,
        "ready remaining Noetix review artifacts after static-support, dynamic-stability, and joint-control replay checks have cleared",
        "output/moonclaw/first_trusted_square_noetix_review_task.json",
        "moon run cmd/main -- moonclaw noetix review task json",
        "python3 scripts/check_moonclaw_noetix_review_task.py output/moonclaw/first_trusted_square_noetix_review_task.json",
        "Resolve review-only Noetix artifacts, regenerate the review task and readiness decision, and keep hardware denied.",
      ),
    )
  }
  items
}

///|
pub fn first_trusted_square_noetix_readiness_work_items() -> Array[
  MoonClawNoetixReadinessWorkItem,
] {
  noetix_readiness_work_items_from_decision(
    first_trusted_square_noetix_simulation_readiness_decision(),
  )
}

///|
pub fn render_noetix_readiness_work_items_markdown(
  items : Array[MoonClawNoetixReadinessWorkItem],
) -> String {
  let mut text = "# MoonClaw Noetix Readiness Work Items\n\n"
  for item_index, item in items {
    text += "- \{item.work_item_id}\n"
    text += "  - state: \{receipt_status_label(item.state)}\n"
    text += "  - decision: \{item.decision_id}\n"
    text += "  - site: \{item.site_id}\n"
    text += "  - robot: \{item.robot_id}\n"
    text += "  - rank: \{item.rank}\n"
    text += "  - blocker domain: \{item.blocker_domain}\n"
    text += "  - blockers: \{item.blocker_count}\n"
    text += "  - blocker ids:\n"
    for blocker in item.blocker_ids {
      text += "    - \{blocker}\n"
    }
    text += "  - required evidence: \{item.required_evidence}\n"
    text += "  - target: \{item.target_artifact_path}\n"
    text += "  - command: \{item.command}\n"
    text += "  - check: \{item.acceptance_check}\n"
    text += "  - may consume MoonRobo simulation: \{item.may_consume_moonrobo_simulation}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(item.hardware_state)}\n"
    text += "  - hardware authority: \{item.hardware_authority}\n"
    text += "  - safety gate: \{item.safety_gate}\n"
    text += "  - next action: \{item.next_action}\n"
    if item_index + 1 < items.length() {
      text += "\n"
    }
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_readiness_work_items_markdown() -> String {
  render_noetix_readiness_work_items_markdown(
    first_trusted_square_noetix_readiness_work_items(),
  )
}

///|
pub fn render_noetix_readiness_work_items_json(
  items : Array[MoonClawNoetixReadinessWorkItem],
) -> Json {
  items.to_json()
}

///|
pub fn first_trusted_square_noetix_readiness_work_items_json() -> Json {
  render_noetix_readiness_work_items_json(
    first_trusted_square_noetix_readiness_work_items(),
  )
}
