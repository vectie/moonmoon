///|
pub(all) struct MoonClawRemediationMarginRefreshAction {
  rank : Int
  margin_id : String
  refresh_id : String
  source_projection_path : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginRefreshTask {
  task_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  source_projection_id : String
  source_projection_path : String
  source_modeling_pass_id : String
  source_projection_status : @moonrobo.RemediationMarginProjectionStatus
  source_simulation_state : @moonrobo.MoonroboExecutionState
  may_consume_simulation : Bool
  blocking_margin_count : Int
  ranked_margin_ids : Array[String]
  refresh_actions : Array[MoonClawRemediationMarginRefreshAction]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn source_projection_path() -> String {
  "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
}

///|
fn terrain_refresh_action(
  projection : @moonrobo.RemediationMarginProjection,
) -> MoonClawRemediationMarginRefreshAction {
  {
    rank: 1,
    margin_id: "terrain-northeast-stepout",
    refresh_id: "refresh-terrain-northeast-stepout",
    source_projection_path: source_projection_path(),
    target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
    command: "python3 scripts/generate_selected_route_terrain_remediation.py --check",
    acceptance_check: "python3 scripts/check_selected_route_terrain_remediation.py",
    reason: "Refresh selected-route terrain evidence first because grade, roughness, and blocking-edge margins feed every downstream route-consume decision for \{projection.route_id}.",
  }
}

///|
fn horizon_refresh_action(
  projection : @moonrobo.RemediationMarginProjection,
) -> MoonClawRemediationMarginRefreshAction {
  {
    rank: 2,
    margin_id: "illumination-northeast-stepout",
    refresh_id: "refresh-illumination-northeast-stepout",
    source_projection_path: source_projection_path(),
    target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
    command: "python3 scripts/generate_selected_route_horizon.py --check",
    acceptance_check: "python3 scripts/check_selected_route_horizon_model.py",
    reason: "Refresh local-horizon evidence for \{projection.route_id} after terrain so illumination keeps using bounded terrain-shadow geometry before simulation consumption changes.",
  }
}

///|
fn energy_refresh_action(
  projection : @moonrobo.RemediationMarginProjection,
) -> MoonClawRemediationMarginRefreshAction {
  {
    rank: 3,
    margin_id: "energy-window",
    refresh_id: "refresh-energy-window",
    source_projection_path: source_projection_path(),
    target_artifact_path: "output/mission/first_trusted_square_energy_remediation.json",
    command: "python3 scripts/check_energy_margin_remediation.py",
    acceptance_check: "python3 scripts/check_energy_margin_remediation.py",
    reason: "Refresh bounded energy evidence for \{projection.route_id} after terrain and horizon because route demand and sunlit-window margins depend on those constraints.",
  }
}

///|
fn ranked_refresh_actions(
  projection : @moonrobo.RemediationMarginProjection,
) -> Array[MoonClawRemediationMarginRefreshAction] {
  let actions : Array[MoonClawRemediationMarginRefreshAction] = []
  if projection.blocking_margin_ids.contains("terrain-northeast-stepout") {
    actions.push(terrain_refresh_action(projection))
  }
  if projection.blocking_margin_ids.contains("illumination-northeast-stepout") {
    actions.push(horizon_refresh_action(projection))
  }
  if projection.blocking_margin_ids.contains("energy-window") {
    actions.push(energy_refresh_action(projection))
  }
  actions
}

///|
pub fn first_trusted_square_remediation_margin_refresh_task() -> MoonClawRemediationMarginRefreshTask {
  let projection = @moonrobo.first_trusted_square_remediation_margin_projection()
  let actions = ranked_refresh_actions(projection)
  let ranked_margin_ids = actions.map(fn(action) { action.margin_id })
  {
    task_id: "moonclaw/\{projection.site_id}/remediation-margin-v1/refresh-task",
    site_id: projection.site_id,
    route_id: projection.route_id,
    priority: Critical,
    state: Accepted,
    source_projection_id: projection.projection_id,
    source_projection_path: source_projection_path(),
    source_modeling_pass_id: projection.source_modeling_pass_id,
    source_projection_status: projection.projection_status,
    source_simulation_state: projection.simulation_state,
    may_consume_simulation: projection.may_consume_simulation,
    blocking_margin_count: projection.blocking_margin_ids.length(),
    ranked_margin_ids,
    refresh_actions: actions,
    hardware_state: projection.hardware_state,
    hardware_authority: projection.hardware_authority,
    hardware_denied: projection.hardware_denied,
    acceptance_criteria: [
      criterion(
        "projection-consumed", "Refresh task source projection id, status, simulation state, and no-consume flag match the MoonRobo remediation-margin projection.",
      ),
      criterion(
        "ranked-refresh-actions", "Refresh actions are ranked terrain, local-horizon, then energy so downstream evidence is regenerated in dependency order.",
      ),
      criterion(
        "hardware-denial-preserved", "Hardware state remains HardwareDenied under moonmoon-safety-gate-only while refresh evidence is open.",
      ),
    ],
    safety_gate: "This task may refresh evidence only; it must not authorize MoonRobo simulation consumption or hardware execution while the source projection is NoConsumeSimulationBlocked.",
    next_action: "Run the ranked terrain, local-horizon, and energy refresh commands, rebuild the dossier, then regenerate the MoonRobo remediation-margin projection before considering simulation consumption.",
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_tasks() -> Array[
  MoonClawRemediationMarginRefreshTask,
] {
  [first_trusted_square_remediation_margin_refresh_task()]
}

///|
pub fn render_remediation_margin_refresh_tasks_markdown(
  tasks : Array[MoonClawRemediationMarginRefreshTask],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Refresh Tasks\n\n"
  for task_index, task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - route: \{task.route_id}\n"
    text += "  - source projection: \{task.source_projection_id}\n"
    text += "  - source projection path: \{task.source_projection_path}\n"
    text += "  - projection status: \{@moonrobo.remediation_margin_projection_status_label(task.source_projection_status)}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(task.source_simulation_state)}\n"
    text += "  - may consume simulation: \{task.may_consume_simulation}\n"
    text += "  - blocking margins: \{task.blocking_margin_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - ranked margins:\n"
    for margin_id in task.ranked_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - refresh actions:\n"
    for action in task.refresh_actions {
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
pub fn first_trusted_square_remediation_margin_refresh_tasks_markdown() -> String {
  render_remediation_margin_refresh_tasks_markdown(
    first_trusted_square_remediation_margin_refresh_tasks(),
  )
}

///|
pub fn render_remediation_margin_refresh_tasks_json(
  tasks : Array[MoonClawRemediationMarginRefreshTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_tasks_json() -> Json {
  render_remediation_margin_refresh_tasks_json(
    first_trusted_square_remediation_margin_refresh_tasks(),
  )
}
