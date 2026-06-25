///|
pub(all) struct MoonClawRemediationMarginReviewedFreshEvidenceAction {
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
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginReviewedFreshEvidenceTask {
  task_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  source_plan_id : String
  source_review_transition_id : String
  source_review_decision : MoonClawCloseoutActionReviewDecision
  reviewer_id : String
  reviewed_at_utc : String
  source_receipt_count : Int
  source_receipt_ids : Array[String]
  pending_receipt_count : Int
  pending_margin_ids : Array[String]
  pending_refresh_ids : Array[String]
  fresh_evidence_actions : Array[
    MoonClawRemediationMarginReviewedFreshEvidenceAction,
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
fn fresh_evidence_action_id(
  result : MoonClawRemediationMarginReviewedWorkItemResult,
) -> String {
  "\{result.blocker_domain}-fresh-evidence-\{result.refresh_id}"
}

///|
fn fresh_evidence_execution_mode(
  result : MoonClawRemediationMarginReviewedWorkItemResult,
) -> String {
  match result.disposition {
    @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision =>
      "operator-escalation"
    @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence =>
      "bounded-regeneration"
    @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence =>
      "manual-freeze-verification"
  }
}

///|
fn fresh_evidence_action(
  receipt : MoonClawRemediationMarginReviewedWorkItemReceipt,
) -> MoonClawRemediationMarginReviewedFreshEvidenceAction {
  let result = receipt.work_item_result
  {
    rank: result.rank,
    action_id: fresh_evidence_action_id(result),
    source_receipt_id: receipt.receipt.receipt_id,
    source_work_item_id: receipt.source_work_item_id,
    margin_id: result.margin_id,
    refresh_id: result.refresh_id,
    blocker_domain: result.blocker_domain,
    disposition: result.disposition,
    result_status: result.status,
    required_evidence: result.required_evidence,
    target_artifact_path: result.target_artifact_path,
    evidence_path: result.evidence_path,
    command: result.command,
    acceptance_check: result.acceptance_check,
    execution_mode: fresh_evidence_execution_mode(result),
    next_action: receipt.next_action,
  }
}

///|
fn pending_reviewed_work_item_receipts(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Array[MoonClawRemediationMarginReviewedWorkItemReceipt] {
  let pending : Array[MoonClawRemediationMarginReviewedWorkItemReceipt] = []
  for receipt in receipts {
    if receipt.receipt.status == Accepted &&
      receipt.result_state == ReviewedWorkItemsCarriedForward &&
      receipt.work_item_result.status == ReviewedWorkItemPendingFreshEvidence &&
      !receipt.may_consume_simulation &&
      !receipt.automatic_refresh_loop_allowed &&
      !receipt.hardware_authority_change &&
      receipt.hardware_denied {
      pending.push(receipt)
    }
  }
  pending
}

///|
fn receipt_ids(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Array[String] {
  receipts.map(fn(receipt) { receipt.receipt.receipt_id })
}

///|
fn pending_margin_ids(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Array[String] {
  receipts.map(fn(receipt) { receipt.work_item_result.margin_id })
}

///|
fn pending_refresh_ids(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Array[String] {
  receipts.map(fn(receipt) { receipt.work_item_result.refresh_id })
}

///|
fn fresh_evidence_actions(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Array[MoonClawRemediationMarginReviewedFreshEvidenceAction] {
  receipts.map(fresh_evidence_action)
}

///|
pub fn remediation_margin_reviewed_fresh_evidence_task_from_receipts(
  receipts : Array[MoonClawRemediationMarginReviewedWorkItemReceipt],
) -> Array[MoonClawRemediationMarginReviewedFreshEvidenceTask] {
  let pending = pending_reviewed_work_item_receipts(receipts)
  if pending.length() == 0 {
    []
  } else {
    let first = pending[0]
    [
      {
        task_id: "moonclaw/\{first.site_id}/remediation-margin-v1/reviewed-fresh-evidence-task",
        site_id: first.site_id,
        route_id: first.route_id,
        priority: Critical,
        state: Accepted,
        source_plan_id: first.source_plan_id,
        source_review_transition_id: first.source_review_transition_id,
        source_review_decision: first.source_review_decision,
        reviewer_id: first.reviewer_id,
        reviewed_at_utc: first.reviewed_at_utc,
        source_receipt_count: receipts.length(),
        source_receipt_ids: receipt_ids(pending),
        pending_receipt_count: pending.length(),
        pending_margin_ids: pending_margin_ids(pending),
        pending_refresh_ids: pending_refresh_ids(pending),
        fresh_evidence_actions: fresh_evidence_actions(pending),
        may_consume_simulation: false,
        simulation_state: first.simulation_state,
        automatic_refresh_loop_allowed: false,
        hardware_state: first.hardware_state,
        hardware_authority: first.hardware_authority,
        hardware_authority_change: false,
        hardware_denied: first.hardware_denied,
        acceptance_criteria: [
          criterion(
            "pending-receipts-consumed", "Task consumes only accepted reviewed work item receipts that are still pending fresh evidence.",
          ),
          criterion(
            "one-action-per-pending-receipt", "Task carries exactly one fresh-evidence action for each pending terrain, horizon, and energy work item receipt.",
          ),
          criterion(
            "review-provenance-preserved", "Accepted closeout action review provenance remains attached to every fresh-evidence action.",
          ),
          criterion(
            "no-refresh-loop-or-simulation", "Task does not open an automatic refresh loop or allow MoonRobo simulation consumption.",
          ),
          criterion(
            "hardware-denial-preserved", "Hardware state remains HardwareDenied under moonmoon-safety-gate-only with no hardware authority change.",
          ),
        ],
        safety_gate: "Execute only the fresh-evidence actions named by the accepted reviewed work item receipts; do not start an automatic refresh loop, consume simulation, or change MoonRobo hardware authority.",
        next_action: "Run the terrain escalation, local-horizon retry-with-new-evidence, and energy freeze verification actions, rebuild the dossier, then regenerate reviewed work item receipts before any downstream MoonRobo simulation review.",
      },
    ]
  }
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks() -> Array[
  MoonClawRemediationMarginReviewedFreshEvidenceTask,
] {
  remediation_margin_reviewed_fresh_evidence_task_from_receipts(
    first_trusted_square_remediation_margin_reviewed_work_item_receipts(),
  )
}

///|
pub fn render_remediation_margin_reviewed_fresh_evidence_tasks_markdown(
  tasks : Array[MoonClawRemediationMarginReviewedFreshEvidenceTask],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Reviewed Fresh Evidence Tasks\n\n"
  for task_index, task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - route: \{task.route_id}\n"
    text += "  - source plan: \{task.source_plan_id}\n"
    text += "  - review transition: \{task.source_review_transition_id}\n"
    text += "  - review decision: \{closeout_action_review_decision_label(task.source_review_decision)}\n"
    text += "  - reviewer: \{task.reviewer_id}\n"
    text += "  - reviewed at: \{task.reviewed_at_utc}\n"
    text += "  - source receipts: \{task.source_receipt_count}\n"
    text += "  - pending receipts: \{task.pending_receipt_count}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(task.simulation_state)}\n"
    text += "  - may consume simulation: \{task.may_consume_simulation}\n"
    text += "  - automatic refresh loop allowed: \{task.automatic_refresh_loop_allowed}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - hardware authority change: \{task.hardware_authority_change}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - source receipt ids:\n"
    for receipt_id in task.source_receipt_ids {
      text += "    - \{receipt_id}\n"
    }
    text += "  - pending margin ids:\n"
    for margin_id in task.pending_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - pending refresh ids:\n"
    for refresh_id in task.pending_refresh_ids {
      text += "    - \{refresh_id}\n"
    }
    text += "  - fresh evidence actions:\n"
    for action in task.fresh_evidence_actions {
      text += "    - \{action.rank}. \{action.action_id}: \{action.margin_id} / \{action.refresh_id}\n"
      text += "      - source receipt: \{action.source_receipt_id}\n"
      text += "      - source work item: \{action.source_work_item_id}\n"
      text += "      - blocker domain: \{action.blocker_domain}\n"
      text += "      - disposition: \{@moonrobo.remediation_margin_cycle_disposition_label(action.disposition)}\n"
      text += "      - result status: \{remediation_margin_reviewed_work_item_result_status_label(action.result_status)}\n"
      text += "      - execution mode: \{action.execution_mode}\n"
      text += "      - required evidence: \{action.required_evidence}\n"
      text += "      - target: \{action.target_artifact_path}\n"
      text += "      - evidence: \{action.evidence_path}\n"
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
pub fn first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks_markdown() -> String {
  render_remediation_margin_reviewed_fresh_evidence_tasks_markdown(
    first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks(),
  )
}

///|
pub fn render_remediation_margin_reviewed_fresh_evidence_tasks_json(
  tasks : Array[MoonClawRemediationMarginReviewedFreshEvidenceTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks_json() -> Json {
  render_remediation_margin_reviewed_fresh_evidence_tasks_json(
    first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks(),
  )
}
