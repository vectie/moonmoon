///|
pub(all) struct MoonClawRemediationMarginRefreshFollowupAction {
  rank : Int
  margin_id : String
  refresh_id : String
  source_refresh_projection_path : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginRefreshFollowupTask {
  task_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  source_refresh_projection_id : String
  source_refresh_projection_path : String
  source_modeling_pass_id : String
  source_modeling_state : @moonrobo.RemediationMarginRefreshModelingState
  source_projection_status : @moonrobo.RemediationMarginRefreshProjectionStatus
  source_simulation_state : @moonrobo.MoonroboExecutionState
  may_consume_simulation : Bool
  blocking_refresh_count : Int
  blocking_refresh_ids : Array[String]
  blocking_margin_ids : Array[String]
  followup_actions : Array[MoonClawRemediationMarginRefreshFollowupAction]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn source_refresh_projection_path() -> String {
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
}

///|
fn followup_terrain_action(
  projection : @moonrobo.RemediationMarginRefreshProjection,
) -> MoonClawRemediationMarginRefreshFollowupAction {
  {
    rank: 1,
    margin_id: "terrain-northeast-stepout",
    refresh_id: "refresh-terrain-northeast-stepout",
    source_refresh_projection_path: source_refresh_projection_path(),
    target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
    command: "python3 scripts/generate_selected_route_terrain_remediation.py --check",
    acceptance_check: "python3 scripts/check_selected_route_terrain_remediation.py",
    reason: "Re-run the terrain refresh first because \{projection.projection_id} still blocks simulation consumption on selected-route grade, roughness, and blocking-edge evidence.",
  }
}

///|
fn followup_horizon_action(
  projection : @moonrobo.RemediationMarginRefreshProjection,
) -> MoonClawRemediationMarginRefreshFollowupAction {
  {
    rank: 2,
    margin_id: "illumination-northeast-stepout",
    refresh_id: "refresh-illumination-northeast-stepout",
    source_refresh_projection_path: source_refresh_projection_path(),
    target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
    command: "python3 scripts/generate_selected_route_horizon.py --check",
    acceptance_check: "python3 scripts/check_selected_route_horizon_model.py",
    reason: "Re-run the local-horizon refresh after terrain so illumination evidence remains tied to bounded terrain-shadow geometry for \{projection.route_id}.",
  }
}

///|
fn followup_energy_action(
  projection : @moonrobo.RemediationMarginRefreshProjection,
) -> MoonClawRemediationMarginRefreshFollowupAction {
  {
    rank: 3,
    margin_id: "energy-window",
    refresh_id: "refresh-energy-window",
    source_refresh_projection_path: source_refresh_projection_path(),
    target_artifact_path: "output/mission/first_trusted_square_energy_remediation.json",
    command: "python3 scripts/check_energy_margin_remediation.py",
    acceptance_check: "python3 scripts/check_energy_margin_remediation.py",
    reason: "Re-run bounded energy refresh last because demand and reserve evidence should consume the refreshed terrain and local-horizon constraints for \{projection.route_id}.",
  }
}

///|
fn ranked_followup_actions(
  projection : @moonrobo.RemediationMarginRefreshProjection,
) -> Array[MoonClawRemediationMarginRefreshFollowupAction] {
  let actions : Array[MoonClawRemediationMarginRefreshFollowupAction] = []
  if projection.blocking_refresh_ids.contains(
      "refresh-terrain-northeast-stepout",
    ) {
    actions.push(followup_terrain_action(projection))
  }
  if projection.blocking_refresh_ids.contains(
      "refresh-illumination-northeast-stepout",
    ) {
    actions.push(followup_horizon_action(projection))
  }
  if projection.blocking_refresh_ids.contains("refresh-energy-window") {
    actions.push(followup_energy_action(projection))
  }
  actions
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_task() -> MoonClawRemediationMarginRefreshFollowupTask {
  let projection = @moonrobo.first_trusted_square_remediation_margin_refresh_projection()
  let actions = ranked_followup_actions(projection)
  {
    task_id: "moonclaw/\{projection.site_id}/remediation-margin-v1/refresh-followup-task",
    site_id: projection.site_id,
    route_id: projection.route_id,
    priority: Critical,
    state: Accepted,
    source_refresh_projection_id: projection.projection_id,
    source_refresh_projection_path: source_refresh_projection_path(),
    source_modeling_pass_id: projection.source_modeling_pass_id,
    source_modeling_state: projection.source_modeling_state,
    source_projection_status: projection.projection_status,
    source_simulation_state: projection.simulation_state,
    may_consume_simulation: projection.may_consume_simulation,
    blocking_refresh_count: projection.blocking_refresh_ids.length(),
    blocking_refresh_ids: projection.blocking_refresh_ids,
    blocking_margin_ids: projection.blocking_margin_ids,
    followup_actions: actions,
    hardware_state: projection.hardware_state,
    hardware_authority: projection.hardware_authority,
    hardware_denied: projection.hardware_denied,
    acceptance_criteria: [
      criterion(
        "refresh-projection-consumed", "Follow-up task source id, status, blocking refresh ids, and no-consume simulation state match the durable MoonRobo refresh projection.",
      ),
      criterion(
        "visible-before-dispatch", "Follow-up task is emitted only after the refresh projection is materialized in MoonBook and surfaced in Rabbita.",
      ),
      criterion(
        "hardware-denial-preserved", "Hardware state remains HardwareDenied under moonmoon-safety-gate-only while follow-up refresh work is open.",
      ),
    ],
    safety_gate: "This follow-up may only refresh terrain, local-horizon, and energy evidence named by the no-consume refresh projection; it must not authorize MoonRobo simulation consumption or hardware execution.",
    next_action: "Execute the follow-up terrain, local-horizon, and energy refresh commands, rebuild the dossier, then regenerate refresh receipt, refresh modeling, and refresh projection evidence before simulation consumption can change.",
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_tasks() -> Array[
  MoonClawRemediationMarginRefreshFollowupTask,
] {
  [first_trusted_square_remediation_margin_refresh_followup_task()]
}

///|
pub fn render_remediation_margin_refresh_followup_tasks_markdown(
  tasks : Array[MoonClawRemediationMarginRefreshFollowupTask],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Refresh Follow-Up Tasks\n\n"
  for task_index, task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - route: \{task.route_id}\n"
    text += "  - source refresh projection: \{task.source_refresh_projection_id}\n"
    text += "  - source refresh projection path: \{task.source_refresh_projection_path}\n"
    text += "  - source modeling pass: \{task.source_modeling_pass_id}\n"
    text += "  - source modeling state: \{@moonrobo.remediation_margin_refresh_modeling_state_label(task.source_modeling_state)}\n"
    text += "  - projection status: \{@moonrobo.remediation_margin_refresh_projection_status_label(task.source_projection_status)}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(task.source_simulation_state)}\n"
    text += "  - may consume simulation: \{task.may_consume_simulation}\n"
    text += "  - blocking refreshes: \{task.blocking_refresh_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - blocking refresh ids:\n"
    for refresh_id in task.blocking_refresh_ids {
      text += "    - \{refresh_id}\n"
    }
    text += "  - blocking margin ids:\n"
    for margin_id in task.blocking_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - follow-up actions:\n"
    for action in task.followup_actions {
      text += "    - \{action.rank}. \{action.refresh_id}: \{action.margin_id}\n"
      text += "      - target: \{action.target_artifact_path}\n"
      text += "      - command: \{action.command}\n"
      text += "      - check: \{action.acceptance_check}\n"
      text += "      - reason: \{action.reason}\n"
    }
    text += "  - acceptance:\n"
    for acceptance_index, acceptance in task.acceptance_criteria {
      text += "    - \{acceptance.criterion_id}: \{acceptance.description}"
      if acceptance_index + 1 < task.acceptance_criteria.length() ||
        task_index + 1 < tasks.length() {
        text += "\n"
      }
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_tasks_markdown() -> String {
  render_remediation_margin_refresh_followup_tasks_markdown(
    first_trusted_square_remediation_margin_refresh_followup_tasks(),
  )
}

///|
pub fn render_remediation_margin_refresh_followup_tasks_json(
  tasks : Array[MoonClawRemediationMarginRefreshFollowupTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_tasks_json() -> Json {
  render_remediation_margin_refresh_followup_tasks_json(
    first_trusted_square_remediation_margin_refresh_followup_tasks(),
  )
}
