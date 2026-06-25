///|
pub(all) struct MoonClawRegeneratedReceiptReadinessFreshEvidenceAction {
  rank : Int
  action_id : String
  source_receipt_id : String
  source_action_receipt_id : String
  margin_id : String
  refresh_id : String
  blocker_domain : String
  execution_mode : String
  required_evidence : String
  target_artifact_path : String
  evidence_path : String
  command : String
  acceptance_check : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRegeneratedReceiptReadinessFreshEvidenceTask {
  task_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  source_readiness_gate_id : String
  source_readiness_state : @moonrobo.RemediationMarginRegeneratedReceiptReadinessState
  source_receipt_bundle_path : String
  source_workspace_entry_path : String
  source_receipt_count : Int
  pending_receipt_count : Int
  ready_receipt_count : Int
  pending_margin_ids : Array[String]
  pending_refresh_ids : Array[String]
  source_receipt_ids : Array[String]
  source_action_receipt_ids : Array[String]
  fresh_evidence_actions : Array[
    MoonClawRegeneratedReceiptReadinessFreshEvidenceAction,
  ]
  may_consume_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn regenerated_readiness_blocker_domain(margin_id : String) -> String {
  if margin_id == "illumination-northeast-stepout" {
    "local-horizon"
  } else if margin_id == "energy-window" {
    "energy"
  } else {
    "terrain"
  }
}

///|
fn regenerated_readiness_required_evidence(margin_id : String) -> String {
  if margin_id == "illumination-northeast-stepout" {
    "fresh local-horizon model for the northeast stepout"
  } else if margin_id == "energy-window" {
    "operator freeze verification for the selected energy window"
  } else {
    "operator terrain escalation evidence for the northeast stepout"
  }
}

///|
fn regenerated_readiness_target_artifact_path(margin_id : String) -> String {
  if margin_id == "illumination-northeast-stepout" {
    "output/mission/first_trusted_square_northeast_stepout_horizon.json"
  } else if margin_id == "energy-window" {
    "operator/rabbita-regenerated-receipt-readiness#energy-freeze"
  } else {
    "operator/rabbita-regenerated-receipt-readiness#terrain-escalation"
  }
}

///|
fn regenerated_readiness_acceptance_check(margin_id : String) -> String {
  if margin_id == "illumination-northeast-stepout" {
    "python3 scripts/check_selected_route_horizon_model.py"
  } else if margin_id == "energy-window" {
    "python3 scripts/check_energy_margin_remediation.py"
  } else {
    "python3 scripts/check_selected_route_terrain_remediation.py"
  }
}

///|
fn regenerated_readiness_command(
  margin_id : String,
  execution_mode : String,
) -> String {
  if execution_mode == "bounded-regeneration" {
    "regenerate bounded fresh evidence for \{margin_id} and rerun its acceptance check"
  } else if execution_mode == "manual-freeze-verification" {
    "record manual freeze verification for \{margin_id} without opening simulation consumption"
  } else {
    "escalate \{margin_id} to the operator with source action receipt provenance attached"
  }
}

///|
fn regenerated_readiness_action(
  gate : @moonrobo.RemediationMarginRegeneratedReceiptReadinessGate,
  index : Int,
  margin_id : String,
) -> MoonClawRegeneratedReceiptReadinessFreshEvidenceAction {
  let refresh_id = gate.pending_refresh_ids[index]
  let execution_mode = gate.execution_modes[index]
  let source_receipt_id = gate.source_receipt_ids[index]
  let source_action_receipt_id = gate.source_action_receipt_ids[index]
  let acceptance_check = regenerated_readiness_acceptance_check(margin_id)
  {
    rank: index + 1,
    action_id: "regenerated-readiness-fresh-evidence-\{margin_id}",
    source_receipt_id,
    source_action_receipt_id,
    margin_id,
    refresh_id,
    blocker_domain: regenerated_readiness_blocker_domain(margin_id),
    execution_mode,
    required_evidence: regenerated_readiness_required_evidence(margin_id),
    target_artifact_path: regenerated_readiness_target_artifact_path(margin_id),
    evidence_path: regenerated_readiness_target_artifact_path(margin_id),
    command: regenerated_readiness_command(margin_id, execution_mode),
    acceptance_check,
    next_action: "Keep \{margin_id} pending until \{acceptance_check} passes, then regenerate the receipt readiness gate before MoonRobo simulation review.",
  }
}

///|
fn regenerated_readiness_actions(
  gate : @moonrobo.RemediationMarginRegeneratedReceiptReadinessGate,
) -> Array[MoonClawRegeneratedReceiptReadinessFreshEvidenceAction] {
  let actions : Array[MoonClawRegeneratedReceiptReadinessFreshEvidenceAction] = []
  for index, margin_id in gate.pending_margin_ids {
    actions.push(regenerated_readiness_action(gate, index, margin_id))
  }
  actions
}

///|
pub fn regenerated_receipt_readiness_fresh_evidence_tasks_from_gate(
  gate : @moonrobo.RemediationMarginRegeneratedReceiptReadinessGate,
) -> Array[MoonClawRegeneratedReceiptReadinessFreshEvidenceTask] {
  if gate.readiness_state !=
    @moonrobo.RemediationMarginRegeneratedReceiptReadinessState::RegeneratedReceiptsPendingFreshEvidence ||
    gate.pending_receipt_count == 0 ||
    gate.may_consume_simulation ||
    gate.automatic_refresh_loop_allowed ||
    !gate.hardware_denied {
    []
  } else {
    [
      {
        task_id: "moonclaw/\{gate.site_id}/regenerated-receipt-readiness-v1/fresh-evidence-task",
        site_id: gate.site_id,
        route_id: gate.route_id,
        priority: Critical,
        state: Accepted,
        source_readiness_gate_id: gate.readiness_gate_id,
        source_readiness_state: gate.readiness_state,
        source_receipt_bundle_path: gate.source_receipt_bundle_path,
        source_workspace_entry_path: gate.source_workspace_entry_path,
        source_receipt_count: gate.source_receipt_count,
        pending_receipt_count: gate.pending_receipt_count,
        ready_receipt_count: gate.ready_receipt_count,
        pending_margin_ids: gate.pending_margin_ids,
        pending_refresh_ids: gate.pending_refresh_ids,
        source_receipt_ids: gate.source_receipt_ids,
        source_action_receipt_ids: gate.source_action_receipt_ids,
        fresh_evidence_actions: regenerated_readiness_actions(gate),
        may_consume_simulation: false,
        simulation_state: gate.simulation_state,
        automatic_refresh_loop_allowed: false,
        hardware_state: gate.hardware_state,
        hardware_authority: gate.hardware_authority,
        hardware_authority_change: false,
        hardware_denied: gate.hardware_denied,
        acceptance_criteria: [
          criterion(
            "readiness-gate-pending", "Task is emitted only from a regenerated receipt readiness gate with pending fresh-evidence receipts.",
          ),
          criterion(
            "one-action-per-pending-receipt", "Task carries one explicit terrain, horizon, or energy fresh-evidence action for each pending regenerated receipt.",
          ),
          criterion(
            "source-action-provenance-preserved", "Every fresh-evidence action preserves the source regenerated receipt id and source action receipt id.",
          ),
          criterion(
            "no-refresh-loop-or-simulation", "Task keeps automatic refresh loops closed and MoonRobo simulation consumption blocked.",
          ),
          criterion(
            "hardware-denial-preserved", "Hardware remains HardwareDenied under moonmoon-safety-gate-only with no hardware authority change.",
          ),
        ],
        safety_gate: "Execute only the named fresh-evidence actions from the regenerated readiness gate; do not start an automatic refresh loop, consume simulation, or change MoonRobo hardware authority.",
        next_action: "Run the regenerated terrain escalation, local-horizon bounded regeneration, and energy freeze verification actions, then regenerate readiness before any MoonRobo simulation review resumes.",
      },
    ]
  }
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks() -> Array[
  MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
] {
  regenerated_receipt_readiness_fresh_evidence_tasks_from_gate(
    @moonrobo.first_trusted_square_remediation_margin_regenerated_receipt_readiness_gate(),
  )
}

///|
pub fn render_regenerated_receipt_readiness_fresh_evidence_tasks_markdown(
  tasks : Array[MoonClawRegeneratedReceiptReadinessFreshEvidenceTask],
) -> String {
  let mut text = "# MoonClaw Regenerated Receipt Readiness Fresh Evidence Tasks\n\n"
  for task_index, task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - route: \{task.route_id}\n"
    text += "  - source readiness gate: \{task.source_readiness_gate_id}\n"
    text += "  - source readiness state: \{@moonrobo.remediation_margin_regenerated_receipt_readiness_state_label(task.source_readiness_state)}\n"
    text += "  - source receipts: \{task.source_receipt_count}\n"
    text += "  - pending receipts: \{task.pending_receipt_count}\n"
    text += "  - ready receipts: \{task.ready_receipt_count}\n"
    text += "  - source receipt bundle: \{task.source_receipt_bundle_path}\n"
    text += "  - source workspace entry: \{task.source_workspace_entry_path}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(task.simulation_state)}\n"
    text += "  - may consume simulation: \{task.may_consume_simulation}\n"
    text += "  - automatic refresh loop allowed: \{task.automatic_refresh_loop_allowed}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - hardware authority change: \{task.hardware_authority_change}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - pending margin ids:\n"
    for margin_id in task.pending_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - source action receipts:\n"
    for source_action_receipt_id in task.source_action_receipt_ids {
      text += "    - \{source_action_receipt_id}\n"
    }
    text += "  - fresh evidence actions:\n"
    for action in task.fresh_evidence_actions {
      text += "    - \{action.rank}. \{action.action_id}: \{action.margin_id} / \{action.refresh_id}\n"
      text += "      - source receipt: \{action.source_receipt_id}\n"
      text += "      - source action receipt: \{action.source_action_receipt_id}\n"
      text += "      - blocker domain: \{action.blocker_domain}\n"
      text += "      - execution mode: \{action.execution_mode}\n"
      text += "      - required evidence: \{action.required_evidence}\n"
      text += "      - target: \{action.target_artifact_path}\n"
      text += "      - command: \{action.command}\n"
      text += "      - check: \{action.acceptance_check}\n"
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
pub fn first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks_markdown() -> String {
  render_regenerated_receipt_readiness_fresh_evidence_tasks_markdown(
    first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks(),
  )
}

///|
pub fn render_regenerated_receipt_readiness_fresh_evidence_tasks_json(
  tasks : Array[MoonClawRegeneratedReceiptReadinessFreshEvidenceTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks_json() -> Json {
  render_regenerated_receipt_readiness_fresh_evidence_tasks_json(
    first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks(),
  )
}
