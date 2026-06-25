///|
pub(all) enum MoonClawRemediationMarginRefreshFollowupResultStatus {
  FollowupRefreshedEvidenceReady
  FollowupRefreshStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawRemediationMarginRefreshFollowupState {
  FollowupRefreshesReady
  FollowupRefreshesCarriedForward
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginRefreshFollowupResult {
  rank : Int
  margin_id : String
  refresh_id : String
  source_refresh_projection_path : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  status : MoonClawRemediationMarginRefreshFollowupResultStatus
  evidence_path : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginRefreshFollowupReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_task_id : String
  source_refresh_projection_id : String
  source_modeling_pass_id : String
  source_modeling_state : @moonrobo.RemediationMarginRefreshModelingState
  source_projection_status : @moonrobo.RemediationMarginRefreshProjectionStatus
  source_simulation_state : @moonrobo.MoonroboExecutionState
  may_consume_simulation : Bool
  refresh_state : MoonClawRemediationMarginRefreshFollowupState
  blocking_refresh_ids : Array[String]
  blocking_margin_ids : Array[String]
  followup_action_count : Int
  refreshed_count : Int
  still_blocking_count : Int
  followup_results : Array[MoonClawRemediationMarginRefreshFollowupResult]
  validation_checks : Array[MoonClawReceiptValidation]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_refresh_followup_result_status_label(
  status : MoonClawRemediationMarginRefreshFollowupResultStatus,
) -> String {
  match status {
    FollowupRefreshedEvidenceReady => "FollowupRefreshedEvidenceReady"
    FollowupRefreshStillBlocking => "FollowupRefreshStillBlocking"
  }
}

///|
pub fn remediation_margin_refresh_followup_state_label(
  state : MoonClawRemediationMarginRefreshFollowupState,
) -> String {
  match state {
    FollowupRefreshesReady => "FollowupRefreshesReady"
    FollowupRefreshesCarriedForward => "FollowupRefreshesCarriedForward"
  }
}

///|
fn remediation_margin_refresh_followup_result(
  action : MoonClawRemediationMarginRefreshFollowupAction,
) -> MoonClawRemediationMarginRefreshFollowupResult {
  {
    rank: action.rank,
    margin_id: action.margin_id,
    refresh_id: action.refresh_id,
    source_refresh_projection_path: action.source_refresh_projection_path,
    target_artifact_path: action.target_artifact_path,
    command: action.command,
    acceptance_check: action.acceptance_check,
    status: FollowupRefreshStillBlocking,
    evidence_path: action.target_artifact_path,
    current_state: "follow-up refresh requested; refreshed evidence has not yet cleared this projection-derived blocker",
    next_action: action.reason,
  }
}

///|
fn refreshed_followup_result_count(
  results : Array[MoonClawRemediationMarginRefreshFollowupResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.status == FollowupRefreshedEvidenceReady {
      count = count + 1
    }
  }
  count
}

///|
fn still_blocking_followup_result_count(
  results : Array[MoonClawRemediationMarginRefreshFollowupResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.status == FollowupRefreshStillBlocking {
      count = count + 1
    }
  }
  count
}

///|
fn followup_refresh_accounting_complete(
  task : MoonClawRemediationMarginRefreshFollowupTask,
  results : Array[MoonClawRemediationMarginRefreshFollowupResult],
) -> Bool {
  if results.length() != task.followup_actions.length() {
    return false
  }
  if task.blocking_refresh_ids.length() != task.followup_actions.length() {
    return false
  }
  for action in task.followup_actions {
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
fn all_followup_result_paths_present(
  results : Array[MoonClawRemediationMarginRefreshFollowupResult],
) -> Bool {
  results.all(fn(result) {
    result.source_refresh_projection_path != "" &&
    result.target_artifact_path != "" &&
    result.evidence_path != "" &&
    result.command != "" &&
    result.acceptance_check != ""
  })
}

///|
pub fn remediation_margin_refresh_followup_receipt(
  task : MoonClawRemediationMarginRefreshFollowupTask,
) -> MoonClawRemediationMarginRefreshFollowupReceipt {
  let results = task.followup_actions.map(
    remediation_margin_refresh_followup_result,
  )
  let refreshed = refreshed_followup_result_count(results)
  let still_blocking = still_blocking_followup_result_count(results)
  let checks = [
    validation(
      "source-task-present",
      task.task_id ==
      "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
      "receipt consumes \{task.task_id}",
    ),
    validation(
      "refresh-projection-source-present",
      task.source_refresh_projection_id ==
      "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection" &&
      task.source_projection_status ==
      @moonrobo.RemediationMarginRefreshProjectionStatus::NoConsumeRefreshSimulationBlocked &&
      task.source_modeling_state ==
      @moonrobo.RemediationMarginRefreshModelingState::AllRefreshesStillBlocking &&
      !task.may_consume_simulation,
      "source refresh projection \{task.source_refresh_projection_id} remains \{@moonrobo.remediation_margin_refresh_projection_status_label(task.source_projection_status)} from \{@moonrobo.remediation_margin_refresh_modeling_state_label(task.source_modeling_state)} with may-consume=\{task.may_consume_simulation}",
    ),
    validation(
      "followup-refresh-accounting-complete",
      followup_refresh_accounting_complete(task, results),
      "\{results.length()} receipt follow-up results account for \{task.followup_actions.length()} ranked actions",
    ),
    validation(
      "result-paths-present",
      all_followup_result_paths_present(results),
      "every follow-up result carries projection, target, command, check, and evidence paths",
    ),
    validation(
      "hardware-denial-preserved",
      task.hardware_denied &&
      task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
      "hardware remains \{@moonrobo.execution_state_label(task.hardware_state)} under \{task.hardware_authority}",
    ),
    validation(
      "followup-refreshes-carried-forward",
      still_blocking == task.followup_actions.length() && refreshed == 0,
      "all current follow-up refresh actions are carried forward until refreshed evidence clears them",
    ),
  ]
  {
    receipt: {
      receipt_id: "moonclaw/\{task.site_id}/remediation-margin-v1/refresh-followup-receipt",
      proposal_id: task.source_refresh_projection_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json",
        "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json",
        task.source_refresh_projection_path,
        "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        "output/mission/first_trusted_square_energy_remediation.json",
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: task.site_id,
    route_id: task.route_id,
    source_task_id: task.task_id,
    source_refresh_projection_id: task.source_refresh_projection_id,
    source_modeling_pass_id: task.source_modeling_pass_id,
    source_modeling_state: task.source_modeling_state,
    source_projection_status: task.source_projection_status,
    source_simulation_state: task.source_simulation_state,
    may_consume_simulation: task.may_consume_simulation,
    refresh_state: if still_blocking > 0 {
      FollowupRefreshesCarriedForward
    } else {
      FollowupRefreshesReady
    },
    blocking_refresh_ids: task.blocking_refresh_ids,
    blocking_margin_ids: task.blocking_margin_ids,
    followup_action_count: results.length(),
    refreshed_count: refreshed,
    still_blocking_count: still_blocking,
    followup_results: results,
    validation_checks: checks,
    hardware_state: task.hardware_state,
    hardware_authority: task.hardware_authority,
    hardware_denied: task.hardware_denied,
    next_action: if still_blocking > 0 {
      "Execute the follow-up terrain, local-horizon, and energy refresh commands, rebuild the dossier, then regenerate refresh modeling and refresh projection evidence before simulation consumption can change."
    } else {
      "Re-run MoonRobo refresh modeling with follow-up refreshed evidence while hardware authority remains denied."
    },
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_receipt() -> MoonClawRemediationMarginRefreshFollowupReceipt {
  remediation_margin_refresh_followup_receipt(
    first_trusted_square_remediation_margin_refresh_followup_task(),
  )
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_receipts() -> Array[
  MoonClawRemediationMarginRefreshFollowupReceipt,
] {
  [first_trusted_square_remediation_margin_refresh_followup_receipt()]
}

///|
pub fn render_remediation_margin_refresh_followup_receipts_markdown(
  receipts : Array[MoonClawRemediationMarginRefreshFollowupReceipt],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Refresh Follow-Up Receipts\n\n"
  for receipt in receipts {
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - route: \{receipt.route_id}\n"
    text += "  - source task: \{receipt.source_task_id}\n"
    text += "  - source refresh projection: \{receipt.source_refresh_projection_id}\n"
    text += "  - source modeling pass: \{receipt.source_modeling_pass_id}\n"
    text += "  - source modeling state: \{@moonrobo.remediation_margin_refresh_modeling_state_label(receipt.source_modeling_state)}\n"
    text += "  - projection status: \{@moonrobo.remediation_margin_refresh_projection_status_label(receipt.source_projection_status)}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(receipt.source_simulation_state)}\n"
    text += "  - may consume simulation: \{receipt.may_consume_simulation}\n"
    text += "  - state: \{remediation_margin_refresh_followup_state_label(receipt.refresh_state)}\n"
    text += "  - follow-up actions: \{receipt.followup_action_count}\n"
    text += "  - refreshed: \{receipt.refreshed_count}\n"
    text += "  - still blocking: \{receipt.still_blocking_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(receipt.hardware_state)}\n"
    text += "  - hardware authority: \{receipt.hardware_authority}\n"
    text += "  - next action: \{receipt.next_action}\n"
    text += "  - blocking refresh ids:\n"
    for refresh_id in receipt.blocking_refresh_ids {
      text += "    - \{refresh_id}\n"
    }
    text += "  - blocking margin ids:\n"
    for margin_id in receipt.blocking_margin_ids {
      text += "    - \{margin_id}\n"
    }
    text += "  - validation:\n"
    for check in receipt.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - follow-up results:\n"
    for index, result in receipt.followup_results {
      text += "    - \{result.rank}. \{result.refresh_id}: \{result.margin_id} - \{remediation_margin_refresh_followup_result_status_label(result.status)}\n"
      text += "      - target: \{result.target_artifact_path}\n"
      text += "      - evidence: \{result.evidence_path}\n"
      text += "      - command: \{result.command}\n"
      text += "      - check: \{result.acceptance_check}\n"
      text += "      - current: \{result.current_state}\n"
      text += "      - next action: \{result.next_action}"
      if index + 1 < receipt.followup_results.length() {
        text += "\n"
      }
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_receipts_markdown() -> String {
  render_remediation_margin_refresh_followup_receipts_markdown(
    first_trusted_square_remediation_margin_refresh_followup_receipts(),
  )
}

///|
pub fn render_remediation_margin_refresh_followup_receipts_json(
  receipts : Array[MoonClawRemediationMarginRefreshFollowupReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_receipts_json() -> Json {
  render_remediation_margin_refresh_followup_receipts_json(
    first_trusted_square_remediation_margin_refresh_followup_receipts(),
  )
}
