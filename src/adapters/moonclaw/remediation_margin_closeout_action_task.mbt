///|
pub(all) struct MoonClawRemediationMarginCloseoutAction {
  rank : Int
  action_id : String
  margin_id : String
  refresh_id : String
  blocker_domain : String
  disposition : @moonrobo.RemediationMarginCycleDisposition
  required_evidence : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginCloseoutActionTask {
  task_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  source_policy_id : String
  source_policy_path : String
  source_closeout_status : @moonrobo.RemediationMarginCycleCloseoutStatus
  source_refresh_projection_id : String
  source_refresh_projection_status : @moonrobo.RemediationMarginRefreshProjectionStatus
  source_followup_projection_id : String
  source_followup_projection_status : @moonrobo.RemediationMarginRefreshFollowupProjectionStatus
  may_consume_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  refresh_cycle_count : Int
  blocker_count : Int
  blocking_refresh_ids : Array[String]
  blocking_margin_ids : Array[String]
  closeout_actions : Array[MoonClawRemediationMarginCloseoutAction]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn closeout_policy_path() -> String {
  "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
}

///|
fn closeout_action_target(blocker_domain : String) -> String {
  if blocker_domain == "terrain" {
    "operator/rabbita-remediation-margin-cycle-closeout#terrain-escalation"
  } else if blocker_domain == "local-horizon" {
    "output/mission/first_trusted_square_northeast_stepout_horizon.json"
  } else {
    "operator/rabbita-remediation-margin-cycle-closeout#energy-freeze"
  }
}

///|
fn closeout_action_command(
  item : @moonrobo.RemediationMarginCycleCloseoutItem,
) -> String {
  match item.disposition {
    @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision =>
      "manual: review DEM slope/roughness evidence for \{item.margin_id} before any terrain refresh is retried"
    @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence =>
      "python3 scripts/generate_selected_route_horizon.py --check"
    @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence =>
      "manual: keep \{item.margin_id} frozen until new power-window source evidence or rover energy profile is attached"
  }
}

///|
fn closeout_action_check(
  item : @moonrobo.RemediationMarginCycleCloseoutItem,
) -> String {
  match item.disposition {
    @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision =>
      "python3 scripts/check_selected_route_terrain_remediation.py"
    @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence =>
      "python3 scripts/check_selected_route_horizon_model.py"
    @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence =>
      "python3 scripts/check_energy_margin_remediation.py"
  }
}

///|
fn closeout_action_id(
  item : @moonrobo.RemediationMarginCycleCloseoutItem,
) -> String {
  "\{item.blocker_domain}-\{@moonrobo.remediation_margin_cycle_disposition_label(item.disposition)}"
}

///|
fn closeout_action(
  rank : Int,
  item : @moonrobo.RemediationMarginCycleCloseoutItem,
) -> MoonClawRemediationMarginCloseoutAction {
  {
    rank,
    action_id: closeout_action_id(item),
    margin_id: item.margin_id,
    refresh_id: item.refresh_id,
    blocker_domain: item.blocker_domain,
    disposition: item.disposition,
    required_evidence: item.required_evidence,
    target_artifact_path: closeout_action_target(item.blocker_domain),
    command: closeout_action_command(item),
    acceptance_check: closeout_action_check(item),
    reason: item.reason,
  }
}

///|
fn closeout_actions(
  policy : @moonrobo.RemediationMarginCycleCloseoutPolicy,
) -> Array[MoonClawRemediationMarginCloseoutAction] {
  let actions : Array[MoonClawRemediationMarginCloseoutAction] = []
  for index, item in policy.dispositions {
    actions.push(closeout_action(index + 1, item))
  }
  actions
}

///|
pub fn first_trusted_square_remediation_margin_closeout_action_task() -> MoonClawRemediationMarginCloseoutActionTask {
  let policy = @moonrobo.first_trusted_square_remediation_margin_cycle_closeout_policy()
  let actions = closeout_actions(policy)
  {
    task_id: "moonclaw/\{policy.site_id}/remediation-margin-v1/closeout-action-task",
    site_id: policy.site_id,
    route_id: policy.route_id,
    priority: Critical,
    state: NeedsReview,
    source_policy_id: policy.policy_id,
    source_policy_path: closeout_policy_path(),
    source_closeout_status: policy.closeout_status,
    source_refresh_projection_id: policy.source_refresh_projection_id,
    source_refresh_projection_status: policy.source_refresh_projection_status,
    source_followup_projection_id: policy.source_followup_projection_id,
    source_followup_projection_status: policy.source_followup_projection_status,
    may_consume_simulation: policy.may_consume_simulation,
    simulation_state: policy.simulation_state,
    refresh_cycle_count: policy.refresh_cycle_count,
    blocker_count: policy.blocker_count,
    blocking_refresh_ids: policy.blocking_refresh_ids,
    blocking_margin_ids: policy.blocking_margin_ids,
    closeout_actions: actions,
    hardware_state: policy.hardware_state,
    hardware_authority: policy.hardware_authority,
    hardware_denied: policy.hardware_denied,
    acceptance_criteria: [
      criterion(
        "closeout-policy-consumed", "Task source id, closeout status, refresh-cycle count, blocker ids, and no-consume simulation state match the durable MoonRobo closeout policy.",
      ),
      criterion(
        "one-action-per-disposition", "Task carries exactly one operator-reviewable action for each terrain/horizon/energy retry, escalate, or freeze disposition.",
      ),
      criterion(
        "hardware-denial-preserved", "Hardware state remains HardwareDenied under moonmoon-safety-gate-only while the closeout action task is under review.",
      ),
    ],
    safety_gate: "This task may schedule only the explicit retry, escalation, and freeze actions from the closeout policy; it must not emit another automatic follow-up refresh loop or authorize MoonRobo simulation consumption.",
    next_action: "Review the terrain escalation, horizon retry-with-new-evidence, and energy freeze actions in one operator pass before any new MoonClaw remediation task is emitted.",
  }
}

///|
pub fn first_trusted_square_remediation_margin_closeout_action_tasks() -> Array[
  MoonClawRemediationMarginCloseoutActionTask,
] {
  [first_trusted_square_remediation_margin_closeout_action_task()]
}

///|
pub fn render_remediation_margin_closeout_action_tasks_markdown(
  tasks : Array[MoonClawRemediationMarginCloseoutActionTask],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Closeout Action Tasks\n\n"
  for task_index, task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - route: \{task.route_id}\n"
    text += "  - source policy: \{task.source_policy_id}\n"
    text += "  - source policy path: \{task.source_policy_path}\n"
    text += "  - closeout status: \{@moonrobo.remediation_margin_cycle_closeout_status_label(task.source_closeout_status)}\n"
    text += "  - source refresh projection: \{task.source_refresh_projection_id}\n"
    text += "  - source refresh projection status: \{@moonrobo.remediation_margin_refresh_projection_status_label(task.source_refresh_projection_status)}\n"
    text += "  - source follow-up projection: \{task.source_followup_projection_id}\n"
    text += "  - source follow-up projection status: \{@moonrobo.remediation_margin_refresh_followup_projection_status_label(task.source_followup_projection_status)}\n"
    text += "  - refresh cycles: \{task.refresh_cycle_count}\n"
    text += "  - blockers: \{task.blocker_count}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(task.simulation_state)}\n"
    text += "  - may consume simulation: \{task.may_consume_simulation}\n"
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
    text += "  - closeout actions:\n"
    for action in task.closeout_actions {
      text += "    - \{action.rank}. \{action.action_id}: \{action.margin_id} / \{action.refresh_id}\n"
      text += "      - disposition: \{@moonrobo.remediation_margin_cycle_disposition_label(action.disposition)}\n"
      text += "      - required evidence: \{action.required_evidence}\n"
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
pub fn first_trusted_square_remediation_margin_closeout_action_tasks_markdown() -> String {
  render_remediation_margin_closeout_action_tasks_markdown(
    first_trusted_square_remediation_margin_closeout_action_tasks(),
  )
}

///|
pub fn render_remediation_margin_closeout_action_tasks_json(
  tasks : Array[MoonClawRemediationMarginCloseoutActionTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_closeout_action_tasks_json() -> Json {
  render_remediation_margin_closeout_action_tasks_json(
    first_trusted_square_remediation_margin_closeout_action_tasks(),
  )
}
