///|
pub(all) struct MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_action_receipt_id : String
  source_action_id : String
  source_fresh_evidence_task_id : String
  source_plan_id : String
  source_review_transition_id : String
  source_review_decision : MoonClawCloseoutActionReviewDecision
  reviewer_id : String
  reviewed_at_utc : String
  source_receipt_count : Int
  source_receipt_ids : Array[String]
  source_receipt_id : String
  source_work_item_id : String
  source_action_state : MoonClawRemediationMarginFreshEvidenceActionReceiptState
  result_state : MoonClawRemediationMarginReviewedWorkItemReceiptState
  work_item_result : MoonClawRemediationMarginReviewedWorkItemResult
  execution_mode : String
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
fn regenerated_reviewed_work_item_result(
  action_receipt : MoonClawRemediationMarginFreshEvidenceActionReceipt,
) -> MoonClawRemediationMarginReviewedWorkItemResult {
  let action = action_receipt.action_result
  {
    work_item_id: action.source_work_item_id,
    rank: action.rank,
    margin_id: action.margin_id,
    refresh_id: action.refresh_id,
    blocker_domain: action.blocker_domain,
    disposition: action.disposition,
    required_evidence: action.required_evidence,
    target_artifact_path: action.target_artifact_path,
    command: action.command,
    acceptance_check: action.acceptance_check,
    status: action.result_status,
    evidence_path: action.evidence_path,
    current_state: "regenerated reviewed work item receipt consumed fresh-evidence action receipt \{action_receipt.receipt.receipt_id}; reviewed work item remains pending until the named evidence check passes",
    next_action: action.next_action,
  }
}

///|
fn regenerated_reviewed_work_item_paths_present(
  result : MoonClawRemediationMarginReviewedWorkItemResult,
) -> Bool {
  result.required_evidence != "" &&
  result.target_artifact_path != "" &&
  result.evidence_path != "" &&
  result.command != "" &&
  result.acceptance_check != ""
}

///|
fn regenerated_reviewed_work_item_receipt(
  action_receipt : MoonClawRemediationMarginFreshEvidenceActionReceipt,
) -> MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt {
  let result = regenerated_reviewed_work_item_result(action_receipt)
  let result_state = match result.status {
    ReviewedWorkItemFreshEvidenceReady => ReviewedWorkItemsReady
    ReviewedWorkItemPendingFreshEvidence => ReviewedWorkItemsCarriedForward
  }
  let action = action_receipt.action_result
  let checks = [
    validation(
      "source-action-receipt-accepted",
      action_receipt.receipt.status == Accepted &&
      action_receipt.action_state == FreshEvidenceActionsRecorded,
      "regenerated receipt consumes accepted fresh-evidence action receipt \{action_receipt.receipt.receipt_id}",
    ),
    validation(
      "source-receipt-provenance-preserved",
      action_receipt.source_receipt_ids.contains(
        action_receipt.source_receipt_id,
      ) &&
      action_receipt.source_review_decision == Accept,
      "source reviewed work item receipt \{action_receipt.source_receipt_id} and accepted review \{action_receipt.source_review_transition_id} remain attached",
    ),
    validation(
      "source-action-accounting-complete",
      action.source_receipt_id == action_receipt.source_receipt_id &&
      action.source_work_item_id == action_receipt.source_work_item_id &&
      action.margin_id != "" &&
      action.refresh_id != "",
      "fresh-evidence action \{action.action_id} maps back to reviewed work item \{action.source_work_item_id}",
    ),
    validation(
      "execution-mode-preserved",
      action.execution_mode == "operator-escalation" ||
      action.execution_mode == "bounded-regeneration" ||
      action.execution_mode == "manual-freeze-verification",
      "regenerated receipt preserves execution mode \{action.execution_mode}",
    ),
    validation(
      "result-paths-present",
      regenerated_reviewed_work_item_paths_present(result),
      "regenerated reviewed work item result carries required evidence, target, command, check, and evidence paths",
    ),
    validation(
      "no-automatic-refresh-loop",
      !action_receipt.automatic_refresh_loop_allowed,
      "regenerated receipt does not open an automatic refresh loop",
    ),
    validation(
      "simulation-consumption-blocked",
      !action_receipt.may_consume_simulation &&
      action_receipt.simulation_state ==
      @moonrobo.MoonroboExecutionState::SimulationBlocked,
      "simulation remains \{@moonrobo.execution_state_label(action_receipt.simulation_state)} with may-consume=\{action_receipt.may_consume_simulation}",
    ),
    validation(
      "hardware-denial-preserved",
      action_receipt.hardware_denied &&
      !action_receipt.hardware_authority_change &&
      action_receipt.hardware_state ==
      @moonrobo.MoonroboExecutionState::HardwareDenied,
      "hardware remains \{@moonrobo.execution_state_label(action_receipt.hardware_state)} under \{action_receipt.hardware_authority}",
    ),
    validation(
      "reviewed-work-item-still-pending",
      result.status == ReviewedWorkItemPendingFreshEvidence,
      "regenerated receipt keeps \{action.margin_id} pending until \{action.acceptance_check} passes",
    ),
  ]
  {
    receipt: {
      receipt_id: "\{action.source_work_item_id}/regenerated-receipt",
      proposal_id: action_receipt.source_task_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json",
        "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json",
        action.evidence_path,
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: action_receipt.site_id,
    route_id: action_receipt.route_id,
    source_action_receipt_id: action_receipt.receipt.receipt_id,
    source_action_id: action.action_id,
    source_fresh_evidence_task_id: action_receipt.source_task_id,
    source_plan_id: action_receipt.source_plan_id,
    source_review_transition_id: action_receipt.source_review_transition_id,
    source_review_decision: action_receipt.source_review_decision,
    reviewer_id: action_receipt.reviewer_id,
    reviewed_at_utc: action_receipt.reviewed_at_utc,
    source_receipt_count: action_receipt.source_receipt_count,
    source_receipt_ids: action_receipt.source_receipt_ids,
    source_receipt_id: action_receipt.source_receipt_id,
    source_work_item_id: action_receipt.source_work_item_id,
    source_action_state: action_receipt.action_state,
    result_state,
    work_item_result: result,
    execution_mode: action.execution_mode,
    validation_checks: checks,
    may_consume_simulation: action_receipt.may_consume_simulation,
    simulation_state: action_receipt.simulation_state,
    automatic_refresh_loop_allowed: action_receipt.automatic_refresh_loop_allowed,
    hardware_state: action_receipt.hardware_state,
    hardware_authority: action_receipt.hardware_authority,
    hardware_authority_change: action_receipt.hardware_authority_change,
    hardware_denied: action_receipt.hardware_denied,
    next_action: "Keep \{action.margin_id} pending fresh evidence until \{action.acceptance_check} passes, then only downstream MoonRobo simulation review may consume a later ready receipt.",
  }
}

///|
pub fn remediation_margin_regenerated_reviewed_work_item_receipts_from_action_receipts(
  action_receipts : Array[MoonClawRemediationMarginFreshEvidenceActionReceipt],
) -> Array[MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt] {
  let receipts : Array[
    MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt,
  ] = []
  for action_receipt in action_receipts {
    if action_receipt.receipt.status == Accepted &&
      action_receipt.source_review_decision == Accept &&
      !action_receipt.may_consume_simulation &&
      !action_receipt.automatic_refresh_loop_allowed &&
      !action_receipt.hardware_authority_change &&
      action_receipt.hardware_denied {
      receipts.push(regenerated_reviewed_work_item_receipt(action_receipt))
    }
  }
  receipts
}

///|
pub fn first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts() -> Array[
  MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt,
] {
  remediation_margin_regenerated_reviewed_work_item_receipts_from_action_receipts(
    first_trusted_square_remediation_margin_fresh_evidence_action_receipts(),
  )
}

///|
pub fn render_remediation_margin_regenerated_reviewed_work_item_receipts_markdown(
  receipts : Array[MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Regenerated Reviewed Work Item Receipts\n\n"
  for receipt_index, receipt in receipts {
    let result = receipt.work_item_result
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - source action receipt: \{receipt.source_action_receipt_id}\n"
    text += "  - source action: \{receipt.source_action_id}\n"
    text += "  - source fresh evidence task: \{receipt.source_fresh_evidence_task_id}\n"
    text += "  - source receipt: \{receipt.source_receipt_id}\n"
    text += "  - source work item: \{receipt.source_work_item_id}\n"
    text += "  - source plan: \{receipt.source_plan_id}\n"
    text += "  - review transition: \{receipt.source_review_transition_id}\n"
    text += "  - review decision: \{closeout_action_review_decision_label(receipt.source_review_decision)}\n"
    text += "  - action state: \{remediation_margin_fresh_evidence_action_receipt_state_label(receipt.source_action_state)}\n"
    text += "  - result state: \{remediation_margin_reviewed_work_item_receipt_state_label(receipt.result_state)}\n"
    text += "  - execution mode: \{receipt.execution_mode}\n"
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
    text += "  - work item result:\n"
    text += "    - \{result.rank}. \{result.refresh_id}: \{result.margin_id} - \{remediation_margin_reviewed_work_item_result_status_label(result.status)}\n"
    text += "      - blocker domain: \{result.blocker_domain}\n"
    text += "      - disposition: \{@moonrobo.remediation_margin_cycle_disposition_label(result.disposition)}\n"
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
pub fn first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts_markdown() -> String {
  render_remediation_margin_regenerated_reviewed_work_item_receipts_markdown(
    first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts(),
  )
}

///|
pub fn render_remediation_margin_regenerated_reviewed_work_item_receipts_json(
  receipts : Array[MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts_json() -> Json {
  render_remediation_margin_regenerated_reviewed_work_item_receipts_json(
    first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts(),
  )
}
