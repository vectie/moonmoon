///|
pub(all) enum MoonClawRemediationMarginFreshEvidenceActionReceiptState {
  FreshEvidenceActionsRecorded
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginFreshEvidenceActionResult {
  rank : Int
  action_id : String
  source_receipt_id : String
  source_work_item_id : String
  margin_id : String
  refresh_id : String
  blocker_domain : String
  disposition : @moonrobo.RemediationMarginCycleDisposition
  result_status : MoonClawRemediationMarginReviewedWorkItemResultStatus
  required_evidence : String
  target_artifact_path : String
  evidence_path : String
  command : String
  acceptance_check : String
  execution_mode : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginFreshEvidenceActionReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_task_id : String
  source_plan_id : String
  source_review_transition_id : String
  source_review_decision : MoonClawCloseoutActionReviewDecision
  reviewer_id : String
  reviewed_at_utc : String
  source_receipt_count : Int
  source_receipt_ids : Array[String]
  source_receipt_id : String
  source_work_item_id : String
  action_state : MoonClawRemediationMarginFreshEvidenceActionReceiptState
  action_result : MoonClawRemediationMarginFreshEvidenceActionResult
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
pub fn remediation_margin_fresh_evidence_action_receipt_state_label(
  state : MoonClawRemediationMarginFreshEvidenceActionReceiptState,
) -> String {
  match state {
    FreshEvidenceActionsRecorded => "FreshEvidenceActionsRecorded"
  }
}

///|
fn fresh_evidence_action_result(
  action : MoonClawRemediationMarginReviewedFreshEvidenceAction,
) -> MoonClawRemediationMarginFreshEvidenceActionResult {
  {
    rank: action.rank,
    action_id: action.action_id,
    source_receipt_id: action.source_receipt_id,
    source_work_item_id: action.source_work_item_id,
    margin_id: action.margin_id,
    refresh_id: action.refresh_id,
    blocker_domain: action.blocker_domain,
    disposition: action.disposition,
    result_status: action.result_status,
    required_evidence: action.required_evidence,
    target_artifact_path: action.target_artifact_path,
    evidence_path: action.evidence_path,
    command: action.command,
    acceptance_check: action.acceptance_check,
    execution_mode: action.execution_mode,
    current_state: "fresh-evidence action recorded; reviewed work item remains pending until the named evidence check passes",
    next_action: action.next_action,
  }
}

///|
fn fresh_evidence_action_paths_present(
  result : MoonClawRemediationMarginFreshEvidenceActionResult,
) -> Bool {
  result.required_evidence != "" &&
  result.target_artifact_path != "" &&
  result.evidence_path != "" &&
  result.command != "" &&
  result.acceptance_check != "" &&
  result.execution_mode != ""
}

///|
fn action_belongs_to_task(
  task : MoonClawRemediationMarginReviewedFreshEvidenceTask,
  action : MoonClawRemediationMarginReviewedFreshEvidenceAction,
) -> Bool {
  task.fresh_evidence_actions.any(fn(candidate) {
    candidate.action_id == action.action_id &&
    candidate.source_receipt_id == action.source_receipt_id &&
    candidate.margin_id == action.margin_id &&
    candidate.refresh_id == action.refresh_id &&
    candidate.rank == action.rank
  })
}

///|
fn fresh_evidence_action_receipt(
  task : MoonClawRemediationMarginReviewedFreshEvidenceTask,
  action : MoonClawRemediationMarginReviewedFreshEvidenceAction,
) -> MoonClawRemediationMarginFreshEvidenceActionReceipt {
  let result = fresh_evidence_action_result(action)
  let checks = [
    validation(
      "source-task-accepted",
      task.state == Accepted &&
      task.task_id ==
      "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task",
      "receipt consumes accepted fresh-evidence task \{task.task_id}",
    ),
    validation(
      "source-receipt-provenance-preserved",
      task.source_receipt_ids.contains(action.source_receipt_id) &&
      task.source_review_decision == Accept,
      "action \{action.action_id} preserves source receipt \{action.source_receipt_id} and accepted review \{task.source_review_transition_id}",
    ),
    validation(
      "action-accounting-complete",
      action_belongs_to_task(task, action),
      "action \{action.action_id} is one of the task's terrain/horizon/energy fresh-evidence actions",
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
      fresh_evidence_action_paths_present(result),
      "action result carries required evidence, target, command, check, evidence path, and execution mode",
    ),
    validation(
      "no-automatic-refresh-loop",
      !task.automatic_refresh_loop_allowed,
      "fresh-evidence action receipt does not open an automatic refresh loop",
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
      "reviewed-work-item-still-pending",
      action.result_status == ReviewedWorkItemPendingFreshEvidence,
      "action \{action.action_id} records evidence work without marking the reviewed work item ready",
    ),
  ]
  {
    receipt: {
      receipt_id: "\{task.task_id}/action-\{action.rank}-\{action.margin_id}/receipt",
      proposal_id: task.task_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json",
        "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json",
        action.evidence_path,
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: task.site_id,
    route_id: task.route_id,
    source_task_id: task.task_id,
    source_plan_id: task.source_plan_id,
    source_review_transition_id: task.source_review_transition_id,
    source_review_decision: task.source_review_decision,
    reviewer_id: task.reviewer_id,
    reviewed_at_utc: task.reviewed_at_utc,
    source_receipt_count: task.source_receipt_count,
    source_receipt_ids: task.source_receipt_ids,
    source_receipt_id: action.source_receipt_id,
    source_work_item_id: action.source_work_item_id,
    action_state: FreshEvidenceActionsRecorded,
    action_result: result,
    validation_checks: checks,
    may_consume_simulation: task.may_consume_simulation,
    simulation_state: task.simulation_state,
    automatic_refresh_loop_allowed: task.automatic_refresh_loop_allowed,
    hardware_state: task.hardware_state,
    hardware_authority: task.hardware_authority,
    hardware_authority_change: task.hardware_authority_change,
    hardware_denied: task.hardware_denied,
    next_action: "Keep \{action.margin_id} pending fresh evidence until \{action.acceptance_check} passes, then regenerate reviewed work item receipts before downstream MoonRobo simulation review.",
  }
}

///|
pub fn remediation_margin_fresh_evidence_action_receipts_from_task(
  task : MoonClawRemediationMarginReviewedFreshEvidenceTask,
) -> Array[MoonClawRemediationMarginFreshEvidenceActionReceipt] {
  let receipts : Array[MoonClawRemediationMarginFreshEvidenceActionReceipt] = []
  if task.state == Accepted &&
    task.source_review_decision == Accept &&
    !task.may_consume_simulation &&
    !task.automatic_refresh_loop_allowed &&
    !task.hardware_authority_change &&
    task.hardware_denied {
    for action in task.fresh_evidence_actions {
      receipts.push(fresh_evidence_action_receipt(task, action))
    }
  }
  receipts
}

///|
pub fn first_trusted_square_remediation_margin_fresh_evidence_action_receipts() -> Array[
  MoonClawRemediationMarginFreshEvidenceActionReceipt,
] {
  let tasks = first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks()
  if tasks.length() == 0 {
    []
  } else {
    remediation_margin_fresh_evidence_action_receipts_from_task(tasks[0])
  }
}

///|
pub fn render_remediation_margin_fresh_evidence_action_receipts_markdown(
  receipts : Array[MoonClawRemediationMarginFreshEvidenceActionReceipt],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Fresh Evidence Action Receipts\n\n"
  for receipt_index, receipt in receipts {
    let result = receipt.action_result
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - source task: \{receipt.source_task_id}\n"
    text += "  - source receipt: \{receipt.source_receipt_id}\n"
    text += "  - source work item: \{receipt.source_work_item_id}\n"
    text += "  - source plan: \{receipt.source_plan_id}\n"
    text += "  - review transition: \{receipt.source_review_transition_id}\n"
    text += "  - review decision: \{closeout_action_review_decision_label(receipt.source_review_decision)}\n"
    text += "  - action state: \{remediation_margin_fresh_evidence_action_receipt_state_label(receipt.action_state)}\n"
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
    text += "      - blocker domain: \{result.blocker_domain}\n"
    text += "      - disposition: \{@moonrobo.remediation_margin_cycle_disposition_label(result.disposition)}\n"
    text += "      - result status: \{remediation_margin_reviewed_work_item_result_status_label(result.result_status)}\n"
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
pub fn first_trusted_square_remediation_margin_fresh_evidence_action_receipts_markdown() -> String {
  render_remediation_margin_fresh_evidence_action_receipts_markdown(
    first_trusted_square_remediation_margin_fresh_evidence_action_receipts(),
  )
}

///|
pub fn render_remediation_margin_fresh_evidence_action_receipts_json(
  receipts : Array[MoonClawRemediationMarginFreshEvidenceActionReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_fresh_evidence_action_receipts_json() -> Json {
  render_remediation_margin_fresh_evidence_action_receipts_json(
    first_trusted_square_remediation_margin_fresh_evidence_action_receipts(),
  )
}
