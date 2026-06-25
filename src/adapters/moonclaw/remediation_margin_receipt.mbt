///|
pub(all) enum MoonClawRemediationMarginResultStatus {
  Cleared
  StillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawRemediationMarginState {
  AllMarginsCleared
  OpenMarginsCarriedForward
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginResult {
  margin_id : String
  source_artifact_path : String
  status : MoonClawRemediationMarginResultStatus
  current_state : String
  evidence_path : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  route_id : String
  source_task_id : String
  remediation_state : MoonClawRemediationMarginState
  active_margin_count : Int
  cleared_margin_count : Int
  still_blocking_margin_count : Int
  margin_results : Array[MoonClawRemediationMarginResult]
  validation_checks : Array[MoonClawReceiptValidation]
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_result_status_label(
  status : MoonClawRemediationMarginResultStatus,
) -> String {
  match status {
    Cleared => "Cleared"
    StillBlocking => "StillBlocking"
  }
}

///|
pub fn remediation_margin_state_label(
  state : MoonClawRemediationMarginState,
) -> String {
  match state {
    AllMarginsCleared => "AllMarginsCleared"
    OpenMarginsCarriedForward => "OpenMarginsCarriedForward"
  }
}

///|
fn remediation_margin_result(
  artifact : MoonClawTaskArtifact,
) -> MoonClawRemediationMarginResult {
  {
    margin_id: artifact.artifact_id,
    source_artifact_path: artifact.path,
    status: if artifact.ready {
      Cleared
    } else {
      StillBlocking
    },
    current_state: artifact.current_state,
    evidence_path: artifact.path,
    next_action: artifact.blocking_reason,
  }
}

///|
fn cleared_margin_count(
  results : Array[MoonClawRemediationMarginResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.status == Cleared {
      count = count + 1
    }
  }
  count
}

///|
fn still_blocking_margin_count(
  results : Array[MoonClawRemediationMarginResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.status == StillBlocking {
      count = count + 1
    }
  }
  count
}

///|
fn margin_accounting_complete(
  task : MoonClawRemediationMarginTask,
  results : Array[MoonClawRemediationMarginResult],
) -> Bool {
  if results.length() != task.active_margin_count {
    return false
  }
  for margin_id in task.active_margin_ids {
    if !results.any(fn(result) { result.margin_id == margin_id }) {
      return false
    }
  }
  true
}

///|
fn all_result_paths_present(
  results : Array[MoonClawRemediationMarginResult],
) -> Bool {
  results.all(fn(result) {
    result.evidence_path != "" && result.source_artifact_path != ""
  })
}

///|
pub fn remediation_margin_receipt(
  task : MoonClawRemediationMarginTask,
) -> MoonClawRemediationMarginReceipt {
  let results = task.artifacts.map(remediation_margin_result)
  let cleared = cleared_margin_count(results)
  let still_blocking = still_blocking_margin_count(results)
  let checks = [
    validation(
      "source-task-present",
      task.task_id == "moonclaw/first-trusted-square/remediation-margin-v1/task",
      "receipt consumes \{task.task_id}",
    ),
    validation(
      "margin-accounting-complete",
      margin_accounting_complete(task, results),
      "\{results.length()} receipt margin results account for \{task.active_margin_count} active remediation margins",
    ),
    validation(
      "result-paths-present",
      all_result_paths_present(results),
      "every margin result carries a source artifact path and evidence path",
    ),
    validation(
      "hardware-denial-preserved",
      task.hardware_denied &&
      task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
      "hardware remains \{@moonrobo.execution_state_label(task.hardware_state)} under \{task.hardware_authority}",
    ),
    validation(
      "still-blocking-margins-carried-forward",
      still_blocking == task.active_margin_count && cleared == 0,
      "all current remediation margins are carried forward until regenerated evidence clears them",
    ),
  ]
  {
    receipt: {
      receipt_id: "moonclaw/\{task.site_id}/remediation-margin-v1/current-receipt",
      proposal_id: task.proposal_id,
      status: Accepted,
      accepted_outputs: [
        "output/moonclaw/first_trusted_square_remediation_margin_task.json", "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        "output/mission/first_trusted_square_northeast_stepout_horizon.json", "output/mission/first_trusted_square_energy_remediation.json",
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: task.site_id,
    route_id: task.route_id,
    source_task_id: task.task_id,
    remediation_state: if still_blocking > 0 {
      OpenMarginsCarriedForward
    } else {
      AllMarginsCleared
    },
    active_margin_count: results.length(),
    cleared_margin_count: cleared,
    still_blocking_margin_count: still_blocking,
    margin_results: results,
    validation_checks: checks,
    hardware_state: task.hardware_state,
    hardware_authority: task.hardware_authority,
    hardware_denied: task.hardware_denied,
    next_action: if still_blocking > 0 {
      "Regenerate terrain, local-horizon, and energy remediation evidence, then re-run the MoonRobo blocker reduction and this receipt check before simulation readiness can change."
    } else {
      "Re-run MoonRobo simulation readiness with all remediation margins cleared while hardware authority remains denied."
    },
  }
}

///|
pub fn first_trusted_square_remediation_margin_receipt() -> MoonClawRemediationMarginReceipt {
  remediation_margin_receipt(first_trusted_square_remediation_margin_task())
}

///|
pub fn first_trusted_square_remediation_margin_receipts() -> Array[
  MoonClawRemediationMarginReceipt,
] {
  [first_trusted_square_remediation_margin_receipt()]
}

///|
pub fn render_remediation_margin_receipts_markdown(
  receipts : Array[MoonClawRemediationMarginReceipt],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Receipts\n\n"
  for receipt in receipts {
    text += "- receipt: \{receipt.receipt.receipt_id}\n"
    text += "  - proposal: \{receipt.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(receipt.receipt.status)}\n"
    text += "  - route: \{receipt.route_id}\n"
    text += "  - source task: \{receipt.source_task_id}\n"
    text += "  - state: \{remediation_margin_state_label(receipt.remediation_state)}\n"
    text += "  - active margins: \{receipt.active_margin_count}\n"
    text += "  - cleared margins: \{receipt.cleared_margin_count}\n"
    text += "  - still blocking margins: \{receipt.still_blocking_margin_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(receipt.hardware_state)}\n"
    text += "  - hardware authority: \{receipt.hardware_authority}\n"
    text += "  - next action: \{receipt.next_action}\n"
    text += "  - validation:\n"
    for check in receipt.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - margin results:\n"
    for index, result in receipt.margin_results {
      text += "    - \{result.margin_id}: \{remediation_margin_result_status_label(result.status)}\n"
      text += "      - evidence: \{result.evidence_path}\n"
      text += "      - current: \{result.current_state}\n"
      text += "      - next action: \{result.next_action}"
      if index + 1 < receipt.margin_results.length() {
        text += "\n"
      }
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_receipts_markdown() -> String {
  render_remediation_margin_receipts_markdown(
    first_trusted_square_remediation_margin_receipts(),
  )
}

///|
pub fn render_remediation_margin_receipts_json(
  receipts : Array[MoonClawRemediationMarginReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_receipts_json() -> Json {
  render_remediation_margin_receipts_json(
    first_trusted_square_remediation_margin_receipts(),
  )
}
