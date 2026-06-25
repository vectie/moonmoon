///|
pub(all) enum MoonClawRemediationMarginRefreshResultStatus {
  RefreshedEvidenceReady
  RefreshStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawRemediationMarginRefreshState {
  AllRefreshesReady
  RefreshesCarriedForward
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginRefreshResult {
  rank : Int
  margin_id : String
  refresh_id : String
  source_projection_path : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  status : MoonClawRemediationMarginRefreshResultStatus
  evidence_path : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginRefreshReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_task_id : String
  source_projection_id : String
  refresh_state : MoonClawRemediationMarginRefreshState
  ranked_margin_ids : Array[String]
  refresh_action_count : Int
  refreshed_count : Int
  still_blocking_count : Int
  refresh_results : Array[MoonClawRemediationMarginRefreshResult]
  validation_checks : Array[MoonClawReceiptValidation]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_refresh_result_status_label(
  status : MoonClawRemediationMarginRefreshResultStatus,
) -> String {
  match status {
    RefreshedEvidenceReady => "RefreshedEvidenceReady"
    RefreshStillBlocking => "RefreshStillBlocking"
  }
}

///|
pub fn remediation_margin_refresh_state_label(
  state : MoonClawRemediationMarginRefreshState,
) -> String {
  match state {
    AllRefreshesReady => "AllRefreshesReady"
    RefreshesCarriedForward => "RefreshesCarriedForward"
  }
}

///|
fn remediation_margin_refresh_result(
  action : MoonClawRemediationMarginRefreshAction,
) -> MoonClawRemediationMarginRefreshResult {
  {
    rank: action.rank,
    margin_id: action.margin_id,
    refresh_id: action.refresh_id,
    source_projection_path: action.source_projection_path,
    target_artifact_path: action.target_artifact_path,
    command: action.command,
    acceptance_check: action.acceptance_check,
    status: RefreshStillBlocking,
    evidence_path: action.target_artifact_path,
    current_state: "refresh requested; refreshed evidence has not yet cleared this remediation margin",
    next_action: action.reason,
  }
}

///|
fn refreshed_result_count(
  results : Array[MoonClawRemediationMarginRefreshResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.status == RefreshedEvidenceReady {
      count = count + 1
    }
  }
  count
}

///|
fn still_blocking_refresh_count(
  results : Array[MoonClawRemediationMarginRefreshResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.status == RefreshStillBlocking {
      count = count + 1
    }
  }
  count
}

///|
fn refresh_accounting_complete(
  task : MoonClawRemediationMarginRefreshTask,
  results : Array[MoonClawRemediationMarginRefreshResult],
) -> Bool {
  if results.length() != task.refresh_actions.length() {
    return false
  }
  if task.ranked_margin_ids.length() != task.refresh_actions.length() {
    return false
  }
  for action in task.refresh_actions {
    if !results.any(fn(result) {
        result.margin_id == action.margin_id &&
        result.refresh_id == action.refresh_id &&
        result.rank == action.rank
      }) {
      return false
    }
  }
  true
}

///|
fn all_refresh_result_paths_present(
  results : Array[MoonClawRemediationMarginRefreshResult],
) -> Bool {
  results.all(fn(result) {
    result.source_projection_path != "" &&
    result.target_artifact_path != "" &&
    result.evidence_path != "" &&
    result.command != "" &&
    result.acceptance_check != ""
  })
}

///|
pub fn remediation_margin_refresh_receipt(
  task : MoonClawRemediationMarginRefreshTask,
) -> MoonClawRemediationMarginRefreshReceipt {
  let results = task.refresh_actions.map(remediation_margin_refresh_result)
  let refreshed = refreshed_result_count(results)
  let still_blocking = still_blocking_refresh_count(results)
  let checks = [
    validation(
      "source-task-present",
      task.task_id ==
      "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task",
      "receipt consumes \{task.task_id}",
    ),
    validation(
      "projection-source-present",
      task.source_projection_id ==
      "moonrobo/first-trusted-square/remediation-margin-v1/projection" &&
      task.source_projection_status ==
      @moonrobo.RemediationMarginProjectionStatus::NoConsumeSimulationBlocked &&
      !task.may_consume_simulation,
      "source projection \{task.source_projection_id} remains \{@moonrobo.remediation_margin_projection_status_label(task.source_projection_status)} with may-consume=\{task.may_consume_simulation}",
    ),
    validation(
      "ranked-refresh-accounting-complete",
      refresh_accounting_complete(task, results),
      "\{results.length()} receipt refresh results account for \{task.refresh_actions.length()} ranked actions",
    ),
    validation(
      "result-paths-present",
      all_refresh_result_paths_present(results),
      "every refresh result carries projection, target, command, check, and evidence paths",
    ),
    validation(
      "hardware-denial-preserved",
      task.hardware_denied &&
      task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
      "hardware remains \{@moonrobo.execution_state_label(task.hardware_state)} under \{task.hardware_authority}",
    ),
    validation(
      "refreshes-carried-forward",
      still_blocking == task.refresh_actions.length() && refreshed == 0,
      "all current refresh actions are carried forward until refreshed evidence clears them",
    ),
  ]
  {
    receipt: {
      receipt_id: "moonclaw/\{task.site_id}/remediation-margin-v1/refresh-receipt",
      proposal_id: task.source_projection_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json",
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json",
        task.source_projection_path,
        "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        "output/mission/first_trusted_square_energy_remediation.json",
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: task.site_id,
    route_id: task.route_id,
    source_task_id: task.task_id,
    source_projection_id: task.source_projection_id,
    refresh_state: if still_blocking > 0 {
      RefreshesCarriedForward
    } else {
      AllRefreshesReady
    },
    ranked_margin_ids: task.ranked_margin_ids,
    refresh_action_count: results.length(),
    refreshed_count: refreshed,
    still_blocking_count: still_blocking,
    refresh_results: results,
    validation_checks: checks,
    hardware_state: task.hardware_state,
    hardware_authority: task.hardware_authority,
    hardware_denied: task.hardware_denied,
    next_action: if still_blocking > 0 {
      "Execute the ranked terrain, local-horizon, and energy refresh commands, rebuild the dossier, and re-run the MoonRobo remediation-margin projection before simulation consumption can change."
    } else {
      "Re-run MoonRobo remediation-margin modeling with refreshed evidence while hardware authority remains denied."
    },
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_receipt() -> MoonClawRemediationMarginRefreshReceipt {
  remediation_margin_refresh_receipt(
    first_trusted_square_remediation_margin_refresh_task(),
  )
}

///|
pub fn first_trusted_square_remediation_margin_refresh_receipts() -> Array[
  MoonClawRemediationMarginRefreshReceipt,
] {
  [first_trusted_square_remediation_margin_refresh_receipt()]
}

///|
pub fn render_remediation_margin_refresh_receipts_markdown(
  receipts : Array[MoonClawRemediationMarginRefreshReceipt],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Refresh Receipts\n\n"
  for receipt in receipts {
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - route: \{receipt.route_id}\n"
    text += "  - source task: \{receipt.source_task_id}\n"
    text += "  - source projection: \{receipt.source_projection_id}\n"
    text += "  - state: \{remediation_margin_refresh_state_label(receipt.refresh_state)}\n"
    text += "  - refresh actions: \{receipt.refresh_action_count}\n"
    text += "  - refreshed: \{receipt.refreshed_count}\n"
    text += "  - still blocking: \{receipt.still_blocking_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(receipt.hardware_state)}\n"
    text += "  - hardware authority: \{receipt.hardware_authority}\n"
    text += "  - next action: \{receipt.next_action}\n"
    text += "  - ranked margins:\n"
    for margin_id in receipt.ranked_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - validation:\n"
    for check in receipt.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - refresh results:\n"
    for index, result in receipt.refresh_results {
      text += "    - \{result.rank}. \{result.refresh_id}: \{result.margin_id} - \{remediation_margin_refresh_result_status_label(result.status)}\n"
      text += "      - target: \{result.target_artifact_path}\n"
      text += "      - evidence: \{result.evidence_path}\n"
      text += "      - command: \{result.command}\n"
      text += "      - check: \{result.acceptance_check}\n"
      text += "      - current: \{result.current_state}\n"
      text += "      - next action: \{result.next_action}"
      if index + 1 < receipt.refresh_results.length() {
        text += "\n"
      }
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_refresh_receipts_markdown() -> String {
  render_remediation_margin_refresh_receipts_markdown(
    first_trusted_square_remediation_margin_refresh_receipts(),
  )
}

///|
pub fn render_remediation_margin_refresh_receipts_json(
  receipts : Array[MoonClawRemediationMarginRefreshReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_receipts_json() -> Json {
  render_remediation_margin_refresh_receipts_json(
    first_trusted_square_remediation_margin_refresh_receipts(),
  )
}
