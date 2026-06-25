///|
pub(all) enum MoonClawRemediationMarginReviewedWorkItemResultStatus {
  ReviewedWorkItemFreshEvidenceReady
  ReviewedWorkItemPendingFreshEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawRemediationMarginReviewedWorkItemReceiptState {
  ReviewedWorkItemsReady
  ReviewedWorkItemsCarriedForward
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginReviewedWorkItemResult {
  work_item_id : String
  rank : Int
  margin_id : String
  refresh_id : String
  blocker_domain : String
  disposition : @moonrobo.RemediationMarginCycleDisposition
  required_evidence : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  status : MoonClawRemediationMarginReviewedWorkItemResultStatus
  evidence_path : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginReviewedWorkItemReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_work_item_id : String
  source_plan_id : String
  source_review_transition_id : String
  source_review_decision : MoonClawCloseoutActionReviewDecision
  reviewer_id : String
  reviewed_at_utc : String
  source_evidence_refs : Array[MoonClawCloseoutActionReviewEvidenceRef]
  source_work_item_state : MoonClawReceiptStatus
  may_consume_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  result_state : MoonClawRemediationMarginReviewedWorkItemReceiptState
  work_item_result : MoonClawRemediationMarginReviewedWorkItemResult
  validation_checks : Array[MoonClawReceiptValidation]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_reviewed_work_item_result_status_label(
  status : MoonClawRemediationMarginReviewedWorkItemResultStatus,
) -> String {
  match status {
    ReviewedWorkItemFreshEvidenceReady => "ReviewedWorkItemFreshEvidenceReady"
    ReviewedWorkItemPendingFreshEvidence =>
      "ReviewedWorkItemPendingFreshEvidence"
  }
}

///|
pub fn remediation_margin_reviewed_work_item_receipt_state_label(
  state : MoonClawRemediationMarginReviewedWorkItemReceiptState,
) -> String {
  match state {
    ReviewedWorkItemsReady => "ReviewedWorkItemsReady"
    ReviewedWorkItemsCarriedForward => "ReviewedWorkItemsCarriedForward"
  }
}

///|
fn reviewed_work_item_result(
  item : MoonClawRemediationMarginReviewedWorkItem,
) -> MoonClawRemediationMarginReviewedWorkItemResult {
  {
    work_item_id: item.work_item_id,
    rank: item.rank,
    margin_id: item.margin_id,
    refresh_id: item.refresh_id,
    blocker_domain: item.blocker_domain,
    disposition: item.disposition,
    required_evidence: item.required_evidence,
    target_artifact_path: item.target_artifact_path,
    command: item.command,
    acceptance_check: item.acceptance_check,
    status: ReviewedWorkItemPendingFreshEvidence,
    evidence_path: item.target_artifact_path,
    current_state: "accepted reviewed work item is pending fresh evidence before any downstream MoonRobo simulation review",
    next_action: item.next_action,
  }
}

///|
fn reviewed_work_item_paths_present(
  result : MoonClawRemediationMarginReviewedWorkItemResult,
) -> Bool {
  result.required_evidence != "" &&
  result.target_artifact_path != "" &&
  result.evidence_path != "" &&
  result.command != "" &&
  result.acceptance_check != ""
}

///|
fn reviewed_work_item_receipt(
  plan : MoonClawRemediationMarginReviewedActionPlan,
  item : MoonClawRemediationMarginReviewedWorkItem,
) -> MoonClawRemediationMarginReviewedWorkItemReceipt {
  let result = reviewed_work_item_result(item)
  let result_state = match result.status {
    ReviewedWorkItemFreshEvidenceReady => ReviewedWorkItemsReady
    ReviewedWorkItemPendingFreshEvidence => ReviewedWorkItemsCarriedForward
  }
  let checks = [
    validation(
      "source-work-item-accepted",
      item.state == Accepted &&
      item.plan_id == plan.plan_id &&
      item.source_review_transition_id == plan.source_review_transition_id &&
      item.source_review_decision == Accept,
      "receipt consumes accepted reviewed work item \{item.work_item_id} from plan \{plan.plan_id}",
    ),
    validation(
      "review-provenance-preserved",
      plan.state == Accepted &&
      plan.source_review_decision == Accept &&
      plan.source_review_transition_id ==
      "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
      "accepted review \{plan.source_review_transition_id} remains the source of authority",
    ),
    validation(
      "work-item-accounting-complete",
      plan.actions.any(fn(action) {
        action.rank == item.rank &&
        action.margin_id == item.margin_id &&
        action.refresh_id == item.refresh_id
      }),
      "work item \{item.margin_id} / \{item.refresh_id} is accounted for by the accepted reviewed action plan",
    ),
    validation(
      "result-paths-present",
      reviewed_work_item_paths_present(result),
      "reviewed work item result carries required evidence, target, command, check, and evidence paths",
    ),
    validation(
      "no-automatic-refresh-loop",
      !item.automatic_refresh_loop_allowed,
      "reviewed work item does not open an automatic refresh loop",
    ),
    validation(
      "simulation-consumption-blocked",
      !item.may_consume_simulation &&
      item.simulation_state ==
      @moonrobo.MoonroboExecutionState::SimulationBlocked,
      "simulation remains \{@moonrobo.execution_state_label(item.simulation_state)} with may-consume=\{item.may_consume_simulation}",
    ),
    validation(
      "hardware-denial-preserved",
      item.hardware_denied &&
      !item.hardware_authority_change &&
      item.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
      "hardware remains \{@moonrobo.execution_state_label(item.hardware_state)} under \{item.hardware_authority}",
    ),
    validation(
      "fresh-evidence-still-pending",
      result.status == ReviewedWorkItemPendingFreshEvidence,
      "reviewed work item remains pending until fresh evidence satisfies \{item.acceptance_check}",
    ),
  ]
  {
    receipt: {
      receipt_id: "\{item.work_item_id}/receipt",
      proposal_id: item.plan_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json",
        "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json",
        item.target_artifact_path,
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: item.site_id,
    route_id: item.route_id,
    source_work_item_id: item.work_item_id,
    source_plan_id: item.plan_id,
    source_review_transition_id: item.source_review_transition_id,
    source_review_decision: item.source_review_decision,
    reviewer_id: item.reviewer_id,
    reviewed_at_utc: item.reviewed_at_utc,
    source_evidence_refs: plan.source_evidence_refs,
    source_work_item_state: item.state,
    may_consume_simulation: item.may_consume_simulation,
    simulation_state: item.simulation_state,
    automatic_refresh_loop_allowed: item.automatic_refresh_loop_allowed,
    result_state,
    work_item_result: result,
    validation_checks: checks,
    hardware_state: item.hardware_state,
    hardware_authority: item.hardware_authority,
    hardware_authority_change: item.hardware_authority_change,
    hardware_denied: item.hardware_denied,
    next_action: "Attach fresh evidence for \{item.margin_id} via \{item.command}, verify \{item.acceptance_check}, then regenerate the reviewed work item receipts before downstream MoonRobo simulation review.",
  }
}

///|
pub fn remediation_margin_reviewed_work_item_receipts_from_plan(
  plan : MoonClawRemediationMarginReviewedActionPlan,
  items : Array[MoonClawRemediationMarginReviewedWorkItem],
) -> Array[MoonClawRemediationMarginReviewedWorkItemReceipt] {
  let receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt] = []
  if plan.state == Accepted &&
    plan.source_review_decision == Accept &&
    !plan.may_consume_simulation &&
    !plan.automatic_refresh_loop_allowed &&
    !plan.hardware_authority_change &&
    plan.hardware_denied {
    for item in items {
      if item.plan_id == plan.plan_id {
        receipts.push(reviewed_work_item_receipt(plan, item))
      }
    }
  }
  receipts
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_work_item_receipts() -> Array[
  MoonClawRemediationMarginReviewedWorkItemReceipt,
] {
  let plans = first_trusted_square_remediation_margin_reviewed_action_plans()
  if plans.length() == 0 {
    []
  } else {
    remediation_margin_reviewed_work_item_receipts_from_plan(
      plans[0],
      first_trusted_square_remediation_margin_reviewed_work_items(),
    )
  }
}

///|
pub fn render_remediation_margin_reviewed_work_item_receipts_markdown(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Reviewed Work Item Receipts\n\n"
  for receipt_index, receipt in receipts {
    let result = receipt.work_item_result
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - source work item: \{receipt.source_work_item_id}\n"
    text += "  - source plan: \{receipt.source_plan_id}\n"
    text += "  - review transition: \{receipt.source_review_transition_id}\n"
    text += "  - review decision: \{closeout_action_review_decision_label(receipt.source_review_decision)}\n"
    text += "  - reviewer: \{receipt.reviewer_id}\n"
    text += "  - reviewed at: \{receipt.reviewed_at_utc}\n"
    text += "  - route: \{receipt.route_id}\n"
    text += "  - result state: \{remediation_margin_reviewed_work_item_receipt_state_label(receipt.result_state)}\n"
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
pub fn first_trusted_square_remediation_margin_reviewed_work_item_receipts_markdown() -> String {
  render_remediation_margin_reviewed_work_item_receipts_markdown(
    first_trusted_square_remediation_margin_reviewed_work_item_receipts(),
  )
}

///|
pub fn render_remediation_margin_reviewed_work_item_receipts_json(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_work_item_receipts_json() -> Json {
  render_remediation_margin_reviewed_work_item_receipts_json(
    first_trusted_square_remediation_margin_reviewed_work_item_receipts(),
  )
}
