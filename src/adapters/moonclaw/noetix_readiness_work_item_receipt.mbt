///|
pub(all) enum MoonClawNoetixReadinessWorkItemResultStatus {
  NoetixReadinessWorkItemFreshEvidenceReady
  NoetixReadinessWorkItemPendingEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawNoetixReadinessWorkItemReceiptState {
  NoetixReadinessWorkItemsReady
  NoetixReadinessWorkItemsCarriedForward
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawNoetixReadinessWorkItemResult {
  work_item_id : String
  rank : Int
  robot_id : String
  blocker_domain : String
  blocker_count : Int
  blocker_ids : Array[String]
  required_evidence : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  status : MoonClawNoetixReadinessWorkItemResultStatus
  evidence_path : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawNoetixReadinessWorkItemReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  robot_id : String
  source_work_item_id : String
  source_decision_id : String
  source_task_id : String
  source_work_item_state : MoonClawReceiptStatus
  may_consume_simulation : Bool
  may_consume_moonrobo_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  result_state : MoonClawNoetixReadinessWorkItemReceiptState
  work_item_result : MoonClawNoetixReadinessWorkItemResult
  validation_checks : Array[MoonClawReceiptValidation]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn noetix_readiness_work_item_result_status_label(
  status : MoonClawNoetixReadinessWorkItemResultStatus,
) -> String {
  match status {
    NoetixReadinessWorkItemFreshEvidenceReady =>
      "NoetixReadinessWorkItemFreshEvidenceReady"
    NoetixReadinessWorkItemPendingEvidence =>
      "NoetixReadinessWorkItemPendingEvidence"
  }
}

///|
pub fn noetix_readiness_work_item_receipt_state_label(
  state : MoonClawNoetixReadinessWorkItemReceiptState,
) -> String {
  match state {
    NoetixReadinessWorkItemsReady => "NoetixReadinessWorkItemsReady"
    NoetixReadinessWorkItemsCarriedForward =>
      "NoetixReadinessWorkItemsCarriedForward"
  }
}

///|
fn noetix_readiness_work_item_result(
  item : MoonClawNoetixReadinessWorkItem,
) -> MoonClawNoetixReadinessWorkItemResult {
  {
    work_item_id: item.work_item_id,
    rank: item.rank,
    robot_id: item.robot_id,
    blocker_domain: item.blocker_domain,
    blocker_count: item.blocker_count,
    blocker_ids: item.blocker_ids,
    required_evidence: item.required_evidence,
    target_artifact_path: item.target_artifact_path,
    command: item.command,
    acceptance_check: item.acceptance_check,
    status: NoetixReadinessWorkItemPendingEvidence,
    evidence_path: item.target_artifact_path,
    current_state: "Noetix readiness work item is carried forward as pending evidence before any downstream MoonRobo simulation consumption.",
    next_action: item.next_action,
  }
}

///|
fn noetix_readiness_result_paths_present(
  result : MoonClawNoetixReadinessWorkItemResult,
) -> Bool {
  result.required_evidence != "" &&
  result.target_artifact_path != "" &&
  result.evidence_path != "" &&
  result.command != "" &&
  result.acceptance_check != ""
}

///|
fn noetix_readiness_work_item_receipt(
  decision : NoetixSimulationReadinessDecision,
  item : MoonClawNoetixReadinessWorkItem,
) -> MoonClawNoetixReadinessWorkItemReceipt {
  let result = noetix_readiness_work_item_result(item)
  let result_state = match result.status {
    NoetixReadinessWorkItemFreshEvidenceReady => NoetixReadinessWorkItemsReady
    NoetixReadinessWorkItemPendingEvidence =>
      NoetixReadinessWorkItemsCarriedForward
  }
  let checks = [
    validation(
      "source-work-item-needs-review",
      item.state == NeedsReview &&
      item.decision_id == decision.decision_id &&
      item.source_task_id == decision.source_task_id,
      "receipt carries pending Noetix work item \{item.work_item_id} from decision \{decision.decision_id}",
    ),
    validation(
      "blocker-accounting-preserved",
      item.blocker_count == item.blocker_ids.length() && item.blocker_count > 0,
      "work item \{item.blocker_domain} preserves \{item.blocker_count} named blockers",
    ),
    validation(
      "result-paths-present",
      noetix_readiness_result_paths_present(result),
      "Noetix readiness result carries required evidence, target, command, check, and evidence paths",
    ),
    validation(
      "readiness-decision-blocked",
      decision.decision == NoetixSimulationBlocked &&
      !decision.may_consume_moonrobo_simulation,
      "source decision remains blocked for MoonRobo simulation consumption",
    ),
    validation(
      "simulation-consumption-blocked",
      !item.may_consume_moonrobo_simulation,
      "MoonRobo simulation consumption remains false for \{item.blocker_domain}",
    ),
    validation(
      "hardware-denial-preserved",
      item.hardware_denied &&
      item.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied &&
      item.hardware_authority == "moonmoon-safety-gate-only",
      "hardware remains \{@moonrobo.execution_state_label(item.hardware_state)} under \{item.hardware_authority}",
    ),
    validation(
      "fresh-evidence-still-pending",
      result.status == NoetixReadinessWorkItemPendingEvidence,
      "Noetix readiness work item remains pending until \{item.acceptance_check} passes",
    ),
  ]
  {
    receipt: {
      receipt_id: "\{item.work_item_id}/receipt",
      proposal_id: item.source_task_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_noetix_readiness_work_items.json",
        "output/moonclaw/first_trusted_square_noetix_readiness_work_item_receipts.json",
        item.target_artifact_path,
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: item.site_id,
    robot_id: item.robot_id,
    source_work_item_id: item.work_item_id,
    source_decision_id: item.decision_id,
    source_task_id: item.source_task_id,
    source_work_item_state: item.state,
    may_consume_simulation: false,
    may_consume_moonrobo_simulation: item.may_consume_moonrobo_simulation,
    simulation_state: @moonrobo.MoonroboExecutionState::SimulationBlocked,
    result_state,
    work_item_result: result,
    validation_checks: checks,
    hardware_state: item.hardware_state,
    hardware_authority: item.hardware_authority,
    hardware_authority_change: false,
    hardware_denied: item.hardware_denied,
    next_action: "Attach fresh Noetix evidence via \{item.command}, verify \{item.acceptance_check}, regenerate readiness work item receipts, and keep hardware denied.",
  }
}

///|
pub fn noetix_readiness_work_item_receipts_from_decision(
  decision : NoetixSimulationReadinessDecision,
  items : Array[MoonClawNoetixReadinessWorkItem],
) -> Array[MoonClawNoetixReadinessWorkItemReceipt] {
  let receipts : Array[MoonClawNoetixReadinessWorkItemReceipt] = []
  if decision.decision == NoetixSimulationBlocked &&
    !decision.may_consume_moonrobo_simulation &&
    decision.hardware_denied {
    for item in items {
      if item.decision_id == decision.decision_id &&
        item.state == NeedsReview &&
        item.hardware_denied &&
        !item.may_consume_moonrobo_simulation {
        receipts.push(noetix_readiness_work_item_receipt(decision, item))
      }
    }
  }
  receipts
}

///|
pub fn first_trusted_square_noetix_readiness_work_item_receipts() -> Array[
  MoonClawNoetixReadinessWorkItemReceipt,
] {
  let decision = first_trusted_square_noetix_simulation_readiness_decision()
  noetix_readiness_work_item_receipts_from_decision(
    decision,
    noetix_readiness_work_items_from_decision(decision),
  )
}

///|
pub fn render_noetix_readiness_work_item_receipts_markdown(
  receipts : Array[MoonClawNoetixReadinessWorkItemReceipt],
) -> String {
  let mut text = "# MoonClaw Noetix Readiness Work Item Receipts\n\n"
  for receipt_index, receipt in receipts {
    let result = receipt.work_item_result
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - source work item: \{receipt.source_work_item_id}\n"
    text += "  - source decision: \{receipt.source_decision_id}\n"
    text += "  - source task: \{receipt.source_task_id}\n"
    text += "  - source work item state: \{receipt_status_label(receipt.source_work_item_state)}\n"
    text += "  - robot: \{receipt.robot_id}\n"
    text += "  - result state: \{noetix_readiness_work_item_receipt_state_label(receipt.result_state)}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(receipt.simulation_state)}\n"
    text += "  - may consume simulation: \{receipt.may_consume_simulation}\n"
    text += "  - may consume MoonRobo simulation: \{receipt.may_consume_moonrobo_simulation}\n"
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
    text += "    - \{result.rank}. \{result.blocker_domain}: \{noetix_readiness_work_item_result_status_label(result.status)}\n"
    text += "      - blockers: \{result.blocker_count}\n"
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
pub fn first_trusted_square_noetix_readiness_work_item_receipts_markdown() -> String {
  render_noetix_readiness_work_item_receipts_markdown(
    first_trusted_square_noetix_readiness_work_item_receipts(),
  )
}

///|
pub fn render_noetix_readiness_work_item_receipts_json(
  receipts : Array[MoonClawNoetixReadinessWorkItemReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_noetix_readiness_work_item_receipts_json() -> Json {
  render_noetix_readiness_work_item_receipts_json(
    first_trusted_square_noetix_readiness_work_item_receipts(),
  )
}
