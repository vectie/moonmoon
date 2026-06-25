///|
pub(all) enum MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceiptState {
  RegeneratedFreshEvidenceActionsRecorded
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRegeneratedReceiptReadinessFreshEvidenceActionResult {
  rank : Int
  action_id : String
  source_readiness_gate_id : String
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
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_task_id : String
  source_readiness_gate_id : String
  source_readiness_state : @moonrobo.RemediationMarginRegeneratedReceiptReadinessState
  source_receipt_bundle_path : String
  source_workspace_entry_path : String
  source_receipt_count : Int
  pending_receipt_count : Int
  ready_receipt_count : Int
  source_receipt_ids : Array[String]
  source_action_receipt_ids : Array[String]
  source_receipt_id : String
  source_action_receipt_id : String
  action_state : MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceiptState
  action_result : MoonClawRegeneratedReceiptReadinessFreshEvidenceActionResult
  validation_checks : Array[MoonClawReceiptValidation]
  may_consume_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn regenerated_readiness_fresh_evidence_action_receipt_state_label(
  state : MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceiptState,
) -> String {
  match state {
    RegeneratedFreshEvidenceActionsRecorded =>
      "RegeneratedFreshEvidenceActionsRecorded"
  }
}

///|
fn regenerated_readiness_fresh_evidence_action_result(
  task : MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
  action : MoonClawRegeneratedReceiptReadinessFreshEvidenceAction,
) -> MoonClawRegeneratedReceiptReadinessFreshEvidenceActionResult {
  {
    rank: action.rank,
    action_id: action.action_id,
    source_readiness_gate_id: task.source_readiness_gate_id,
    source_receipt_id: action.source_receipt_id,
    source_action_receipt_id: action.source_action_receipt_id,
    margin_id: action.margin_id,
    refresh_id: action.refresh_id,
    blocker_domain: action.blocker_domain,
    execution_mode: action.execution_mode,
    required_evidence: action.required_evidence,
    target_artifact_path: action.target_artifact_path,
    evidence_path: action.evidence_path,
    command: action.command,
    acceptance_check: action.acceptance_check,
    current_state: "regenerated readiness fresh-evidence action recorded; regenerated receipt remains pending until the named evidence check passes and readiness is recomputed",
    next_action: action.next_action,
  }
}

///|
fn regenerated_readiness_action_paths_present(
  result : MoonClawRegeneratedReceiptReadinessFreshEvidenceActionResult,
) -> Bool {
  result.required_evidence != "" &&
  result.target_artifact_path != "" &&
  result.evidence_path != "" &&
  result.command != "" &&
  result.acceptance_check != "" &&
  result.execution_mode != ""
}

///|
fn regenerated_readiness_action_belongs_to_task(
  task : MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
  action : MoonClawRegeneratedReceiptReadinessFreshEvidenceAction,
) -> Bool {
  task.fresh_evidence_actions.any(fn(candidate) {
    candidate.action_id == action.action_id &&
    candidate.source_receipt_id == action.source_receipt_id &&
    candidate.source_action_receipt_id == action.source_action_receipt_id &&
    candidate.margin_id == action.margin_id &&
    candidate.refresh_id == action.refresh_id &&
    candidate.rank == action.rank
  })
}

///|
fn regenerated_readiness_fresh_evidence_action_receipt(
  task : MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
  action : MoonClawRegeneratedReceiptReadinessFreshEvidenceAction,
) -> MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt {
  let result = regenerated_readiness_fresh_evidence_action_result(task, action)
  let checks = [
    validation(
      "source-task-accepted",
      task.state == Accepted &&
      task.source_readiness_state ==
      @moonrobo.RemediationMarginRegeneratedReceiptReadinessState::RegeneratedReceiptsPendingFreshEvidence,
      "receipt consumes accepted regenerated readiness fresh-evidence task \{task.task_id}",
    ),
    validation(
      "source-readiness-gate-preserved",
      task.source_readiness_gate_id == result.source_readiness_gate_id &&
      task.source_readiness_gate_id != "",
      "source readiness gate \{task.source_readiness_gate_id} remains attached",
    ),
    validation(
      "source-receipt-provenance-preserved",
      task.source_receipt_ids.contains(action.source_receipt_id) &&
      task.source_action_receipt_ids.contains(action.source_action_receipt_id),
      "action \{action.action_id} preserves regenerated receipt \{action.source_receipt_id} and source action receipt \{action.source_action_receipt_id}",
    ),
    validation(
      "action-accounting-complete",
      regenerated_readiness_action_belongs_to_task(task, action),
      "action \{action.action_id} is one of the regenerated readiness terrain/horizon/energy fresh-evidence actions",
    ),
    validation(
      "execution-mode-recorded",
      action.execution_mode == "operator-escalation" ||
      action.execution_mode == "bounded-regeneration" ||
      action.execution_mode == "manual-freeze-verification",
      "action \{action.action_id} records execution mode \{action.execution_mode}",
    ),
    validation(
      "result-paths-present",
      regenerated_readiness_action_paths_present(result),
      "action result carries required evidence, target, command, check, evidence path, and execution mode",
    ),
    validation(
      "no-automatic-refresh-loop",
      !task.automatic_refresh_loop_allowed,
      "regenerated readiness action receipt does not open an automatic refresh loop",
    ),
    validation(
      "simulation-consumption-blocked",
      !task.may_consume_simulation &&
      task.simulation_state ==
      @moonrobo.MoonroboExecutionState::SimulationBlocked,
      "simulation remains \{@moonrobo.execution_state_label(task.simulation_state)} with may-consume=\{task.may_consume_simulation}",
    ),
    validation(
      "hardware-denial-preserved",
      task.hardware_denied &&
      !task.hardware_authority_change &&
      task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
      "hardware remains \{@moonrobo.execution_state_label(task.hardware_state)} under \{task.hardware_authority}",
    ),
    validation(
      "regenerated-receipt-still-pending",
      task.pending_receipt_count > 0 && task.ready_receipt_count == 0,
      "action \{action.action_id} records evidence work without marking regenerated receipts ready",
    ),
  ]
  {
    receipt: {
      receipt_id: "\{task.task_id}/action-\{action.rank}-\{action.margin_id}/receipt",
      proposal_id: task.task_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json",
        "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json",
        action.evidence_path,
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: task.site_id,
    route_id: task.route_id,
    source_task_id: task.task_id,
    source_readiness_gate_id: task.source_readiness_gate_id,
    source_readiness_state: task.source_readiness_state,
    source_receipt_bundle_path: task.source_receipt_bundle_path,
    source_workspace_entry_path: task.source_workspace_entry_path,
    source_receipt_count: task.source_receipt_count,
    pending_receipt_count: task.pending_receipt_count,
    ready_receipt_count: task.ready_receipt_count,
    source_receipt_ids: task.source_receipt_ids,
    source_action_receipt_ids: task.source_action_receipt_ids,
    source_receipt_id: action.source_receipt_id,
    source_action_receipt_id: action.source_action_receipt_id,
    action_state: RegeneratedFreshEvidenceActionsRecorded,
    action_result: result,
    validation_checks: checks,
    may_consume_simulation: task.may_consume_simulation,
    simulation_state: task.simulation_state,
    automatic_refresh_loop_allowed: task.automatic_refresh_loop_allowed,
    hardware_state: task.hardware_state,
    hardware_authority: task.hardware_authority,
    hardware_authority_change: task.hardware_authority_change,
    hardware_denied: task.hardware_denied,
    next_action: "Keep \{action.margin_id} pending fresh evidence until \{action.acceptance_check} passes, then recompute regenerated receipt readiness before MoonRobo simulation review resumes.",
  }
}

///|
pub fn regenerated_receipt_readiness_fresh_evidence_action_receipts_from_task(
  task : MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
) -> Array[MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt] {
  let receipts : Array[
    MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt,
  ] = []
  if task.state == Accepted &&
    task.source_readiness_state ==
    @moonrobo.RemediationMarginRegeneratedReceiptReadinessState::RegeneratedReceiptsPendingFreshEvidence &&
    !task.may_consume_simulation &&
    !task.automatic_refresh_loop_allowed &&
    !task.hardware_authority_change &&
    task.hardware_denied {
    for action in task.fresh_evidence_actions {
      receipts.push(
        regenerated_readiness_fresh_evidence_action_receipt(task, action),
      )
    }
  }
  receipts
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts() -> Array[
  MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt,
] {
  let tasks = first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks()
  if tasks.length() == 0 {
    []
  } else {
    regenerated_receipt_readiness_fresh_evidence_action_receipts_from_task(
      tasks[0],
    )
  }
}

///|
pub fn render_regenerated_receipt_readiness_fresh_evidence_action_receipts_markdown(
  receipts : Array[
    MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt,
  ],
) -> String {
  let mut text = "# MoonClaw Regenerated Receipt Readiness Fresh Evidence Action Receipts\n\n"
  for receipt_index, receipt in receipts {
    let result = receipt.action_result
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - source task: \{receipt.source_task_id}\n"
    text += "  - source readiness gate: \{receipt.source_readiness_gate_id}\n"
    text += "  - source readiness state: \{@moonrobo.remediation_margin_regenerated_receipt_readiness_state_label(receipt.source_readiness_state)}\n"
    text += "  - source receipt: \{receipt.source_receipt_id}\n"
    text += "  - source action receipt: \{receipt.source_action_receipt_id}\n"
    text += "  - action state: \{regenerated_readiness_fresh_evidence_action_receipt_state_label(receipt.action_state)}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(receipt.simulation_state)}\n"
    text += "  - may consume simulation: \{receipt.may_consume_simulation}\n"
    text += "  - automatic refresh loop allowed: \{receipt.automatic_refresh_loop_allowed}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(receipt.hardware_state)}\n"
    text += "  - hardware authority: \{receipt.hardware_authority}\n"
    text += "  - hardware authority change: \{receipt.hardware_authority_change}\n"
    text += "  - next action: \{receipt.next_action}\n"
    text += "  - validation:\n"
    for check in receipt.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - action result:\n"
    text += "    - \{result.rank}. \{result.action_id}: \{result.margin_id} / \{result.refresh_id}\n"
    text += "      - source readiness gate: \{result.source_readiness_gate_id}\n"
    text += "      - source receipt: \{result.source_receipt_id}\n"
    text += "      - source action receipt: \{result.source_action_receipt_id}\n"
    text += "      - blocker domain: \{result.blocker_domain}\n"
    text += "      - execution mode: \{result.execution_mode}\n"
    text += "      - required evidence: \{result.required_evidence}\n"
    text += "      - target: \{result.target_artifact_path}\n"
    text += "      - evidence: \{result.evidence_path}\n"
    text += "      - command: \{result.command}\n"
    text += "      - check: \{result.acceptance_check}\n"
    text += "      - current: \{result.current_state}"
    if receipt_index + 1 < receipts.length() {
      text += "\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts_markdown() -> String {
  render_regenerated_receipt_readiness_fresh_evidence_action_receipts_markdown(
    first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts(),
  )
}

///|
pub fn render_regenerated_receipt_readiness_fresh_evidence_action_receipts_json(
  receipts : Array[
    MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipt,
  ],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts_json() -> Json {
  render_regenerated_receipt_readiness_fresh_evidence_action_receipts_json(
    first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts(),
  )
}
