///|
pub(all) enum RegeneratedReceiptReadinessActionReceiptCloseoutState {
  RegeneratedReceiptsReadyAfterActionReceipts
  RegeneratedReceiptsStillPendingFreshEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RegeneratedReceiptReadinessActionReceiptInput {
  receipt_id : String
  source_task_id : String
  source_readiness_gate_id : String
  source_readiness_state : RemediationMarginRegeneratedReceiptReadinessState
  source_receipt_id : String
  source_action_receipt_id : String
  margin_id : String
  refresh_id : String
  blocker_domain : String
  execution_mode : String
  action_state : String
  current_state : String
  evidence_path : String
  acceptance_check : String
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RegeneratedReceiptReadinessActionReceiptCloseoutValidation {
  validation_id : String
  passed : Bool
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RegeneratedReceiptReadinessActionReceiptCloseout {
  closeout_id : String
  site_id : @core.SiteId
  route_id : String
  source_action_receipt_bundle_path : String
  source_workspace_entry_path : String
  source_readiness_gate_id : String
  source_readiness_state : RemediationMarginRegeneratedReceiptReadinessState
  source_task_id : String
  source_action_receipt_count : Int
  source_receipt_count : Int
  ready_receipt_count : Int
  pending_receipt_count : Int
  source_receipt_ids : Array[String]
  source_action_receipt_ids : Array[String]
  margin_ids : Array[String]
  refresh_ids : Array[String]
  execution_modes : Array[String]
  closeout_state : RegeneratedReceiptReadinessActionReceiptCloseoutState
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  validation_checks : Array[
    RegeneratedReceiptReadinessActionReceiptCloseoutValidation,
  ]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn regenerated_receipt_readiness_action_receipt_closeout_state_label(
  state : RegeneratedReceiptReadinessActionReceiptCloseoutState,
) -> String {
  match state {
    RegeneratedReceiptsReadyAfterActionReceipts =>
      "RegeneratedReceiptsReadyAfterActionReceipts"
    RegeneratedReceiptsStillPendingFreshEvidence =>
      "RegeneratedReceiptsStillPendingFreshEvidence"
  }
}

///|
fn action_receipt_closeout_validation(
  validation_id : String,
  passed : Bool,
  note : String,
) -> RegeneratedReceiptReadinessActionReceiptCloseoutValidation {
  { validation_id, passed, note }
}

///|
fn action_receipt_expected_execution_mode(
  receipt : RegeneratedReceiptReadinessActionReceiptInput,
) -> Bool {
  (
    receipt.margin_id == "terrain-northeast-stepout" &&
    receipt.blocker_domain == "terrain" &&
    receipt.execution_mode == "operator-escalation"
  ) ||
  (
    receipt.margin_id == "illumination-northeast-stepout" &&
    receipt.blocker_domain == "local-horizon" &&
    receipt.execution_mode == "bounded-regeneration"
  ) ||
  (
    receipt.margin_id == "energy-window" &&
    receipt.blocker_domain == "energy" &&
    receipt.execution_mode == "manual-freeze-verification"
  )
}

///|
fn action_receipt_remains_pending(
  receipt : RegeneratedReceiptReadinessActionReceiptInput,
) -> Bool {
  receipt.action_state == "RegeneratedFreshEvidenceActionsRecorded" &&
  receipt.current_state.contains("remains pending") &&
  receipt.current_state.contains("readiness is recomputed")
}

///|
fn action_receipt_closeout_state(
  pending_count : Int,
) -> RegeneratedReceiptReadinessActionReceiptCloseoutState {
  if pending_count == 0 {
    RegeneratedReceiptsReadyAfterActionReceipts
  } else {
    RegeneratedReceiptsStillPendingFreshEvidence
  }
}

///|
fn action_receipt_closeout_next_action(
  state : RegeneratedReceiptReadinessActionReceiptCloseoutState,
) -> String {
  match state {
    RegeneratedReceiptsReadyAfterActionReceipts =>
      "route the regenerated receipt bundle into simulation review while preserving HardwareDenied authority"
    RegeneratedReceiptsStillPendingFreshEvidence =>
      "keep regenerated terrain, local-horizon, and energy receipts pending fresh evidence; do not consume simulation until later evidence checks mark every regenerated receipt ready"
  }
}

///|
pub fn regenerated_receipt_readiness_action_receipt_closeout(
  site_id : @core.SiteId,
  route_id : String,
  source_action_receipt_bundle_path : String,
  source_workspace_entry_path : String,
  receipts : Array[RegeneratedReceiptReadinessActionReceiptInput],
) -> RegeneratedReceiptReadinessActionReceiptCloseout {
  let pending_count = receipts.filter(action_receipt_remains_pending).length()
  let ready_count = receipts.length() - pending_count
  let state = action_receipt_closeout_state(pending_count)
  let readiness_gate_id = if receipts.length() == 0 {
    ""
  } else {
    receipts[0].source_readiness_gate_id
  }
  let task_id = if receipts.length() == 0 {
    ""
  } else {
    receipts[0].source_task_id
  }
  let readiness_state = if receipts.length() == 0 {
    RemediationMarginRegeneratedReceiptReadinessState::RegeneratedReceiptsPendingFreshEvidence
  } else {
    receipts[0].source_readiness_state
  }
  let validation_checks = [
    action_receipt_closeout_validation(
      "action-receipts-present",
      receipts.length() > 0,
      "closeout consumed \{receipts.length()} regenerated readiness fresh-evidence action receipts from \{source_action_receipt_bundle_path}",
    ),
    action_receipt_closeout_validation(
      "source-readiness-gate-preserved",
      receipts.length() > 0 &&
      receipts.all(fn(receipt) {
        receipt.source_readiness_gate_id == readiness_gate_id &&
        receipt.source_readiness_state ==
        RemediationMarginRegeneratedReceiptReadinessState::RegeneratedReceiptsPendingFreshEvidence
      }),
      "all action receipts preserve source readiness gate \{readiness_gate_id}",
    ),
    action_receipt_closeout_validation(
      "source-action-provenance-present",
      receipts.all(fn(receipt) {
        receipt.source_task_id == task_id &&
        receipt.source_receipt_id != "" &&
        receipt.source_action_receipt_id != ""
      }),
      "every action receipt carries source task, regenerated receipt, and source action receipt provenance",
    ),
    action_receipt_closeout_validation(
      "execution-modes-preserved",
      receipts.all(action_receipt_expected_execution_mode),
      "terrain/horizon/energy execution modes remain operator-escalation, bounded-regeneration, and manual-freeze-verification",
    ),
    action_receipt_closeout_validation(
      "fresh-evidence-still-pending",
      receipts.length() > 0 && pending_count == receipts.length(),
      "\{pending_count}/\{receipts.length()} regenerated receipts remain pending after action receipt accounting",
    ),
    action_receipt_closeout_validation(
      "no-automatic-refresh-loop",
      receipts.all(fn(receipt) { !receipt.automatic_refresh_loop_allowed }),
      "action receipt closeout does not open an automatic refresh loop",
    ),
    action_receipt_closeout_validation(
      "simulation-consumption-blocked",
      receipts.all(fn(receipt) {
        !receipt.may_consume_simulation &&
        receipt.simulation_state == SimulationBlocked
      }),
      "action receipts remain no-consume with simulation blocked",
    ),
    action_receipt_closeout_validation(
      "hardware-denial-preserved",
      receipts.all(fn(receipt) {
        receipt.hardware_denied &&
        !receipt.hardware_authority_change &&
        receipt.hardware_state == HardwareDenied &&
        receipt.hardware_authority == "moonmoon-safety-gate-only"
      }),
      "hardware remains denied under moonmoon-safety-gate-only",
    ),
  ]
  {
    closeout_id: "moonrobo/\{site_id}/regenerated-receipt-readiness-v1/action-receipt-closeout",
    site_id,
    route_id,
    source_action_receipt_bundle_path,
    source_workspace_entry_path,
    source_readiness_gate_id: readiness_gate_id,
    source_readiness_state: readiness_state,
    source_task_id: task_id,
    source_action_receipt_count: receipts.length(),
    source_receipt_count: receipts.length(),
    ready_receipt_count: ready_count,
    pending_receipt_count: pending_count,
    source_receipt_ids: receipts.map(fn(receipt) { receipt.source_receipt_id }),
    source_action_receipt_ids: receipts.map(fn(receipt) {
      receipt.source_action_receipt_id
    }),
    margin_ids: receipts.map(fn(receipt) { receipt.margin_id }),
    refresh_ids: receipts.map(fn(receipt) { receipt.refresh_id }),
    execution_modes: receipts.map(fn(receipt) { receipt.execution_mode }),
    closeout_state: state,
    may_consume_simulation: false,
    simulation_state: SimulationBlocked,
    automatic_refresh_loop_allowed: false,
    hardware_state: HardwareDenied,
    hardware_authority: "moonmoon-safety-gate-only",
    hardware_denied: true,
    validation_checks,
    next_action: action_receipt_closeout_next_action(state),
  }
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout() -> RegeneratedReceiptReadinessActionReceiptCloseout {
  regenerated_receipt_readiness_action_receipt_closeout(
    "first-trusted-square",
    "northeast-stepout",
    "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json",
    "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-action-receipts.json",
    [
      {
        receipt_id: "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task/action-1-terrain-northeast-stepout/receipt",
        source_task_id: "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task",
        source_readiness_gate_id: "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness",
        source_readiness_state: RegeneratedReceiptsPendingFreshEvidence,
        source_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout/receipt",
        source_action_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task/action-1-terrain-northeast-stepout/receipt",
        margin_id: "terrain-northeast-stepout",
        refresh_id: "refresh-terrain-northeast-stepout",
        blocker_domain: "terrain",
        execution_mode: "operator-escalation",
        action_state: "RegeneratedFreshEvidenceActionsRecorded",
        current_state: "regenerated readiness fresh-evidence action recorded; regenerated receipt remains pending until the named evidence check passes and readiness is recomputed",
        evidence_path: "operator/rabbita-remediation-margin-cycle-closeout#terrain-escalation",
        acceptance_check: "python3 scripts/check_selected_route_terrain_remediation.py",
        may_consume_simulation: false,
        simulation_state: SimulationBlocked,
        automatic_refresh_loop_allowed: false,
        hardware_state: HardwareDenied,
        hardware_authority: "moonmoon-safety-gate-only",
        hardware_authority_change: false,
        hardware_denied: true,
      },
      {
        receipt_id: "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task/action-2-illumination-northeast-stepout/receipt",
        source_task_id: "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task",
        source_readiness_gate_id: "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness",
        source_readiness_state: RegeneratedReceiptsPendingFreshEvidence,
        source_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-2-illumination-northeast-stepout/receipt",
        source_action_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task/action-2-illumination-northeast-stepout/receipt",
        margin_id: "illumination-northeast-stepout",
        refresh_id: "refresh-illumination-northeast-stepout",
        blocker_domain: "local-horizon",
        execution_mode: "bounded-regeneration",
        action_state: "RegeneratedFreshEvidenceActionsRecorded",
        current_state: "regenerated readiness fresh-evidence action recorded; regenerated receipt remains pending until the named evidence check passes and readiness is recomputed",
        evidence_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        acceptance_check: "python3 scripts/check_selected_route_horizon_model.py",
        may_consume_simulation: false,
        simulation_state: SimulationBlocked,
        automatic_refresh_loop_allowed: false,
        hardware_state: HardwareDenied,
        hardware_authority: "moonmoon-safety-gate-only",
        hardware_authority_change: false,
        hardware_denied: true,
      },
      {
        receipt_id: "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task/action-3-energy-window/receipt",
        source_task_id: "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task",
        source_readiness_gate_id: "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness",
        source_readiness_state: RegeneratedReceiptsPendingFreshEvidence,
        source_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-3-energy-window/receipt",
        source_action_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task/action-3-energy-window/receipt",
        margin_id: "energy-window",
        refresh_id: "refresh-energy-window",
        blocker_domain: "energy",
        execution_mode: "manual-freeze-verification",
        action_state: "RegeneratedFreshEvidenceActionsRecorded",
        current_state: "regenerated readiness fresh-evidence action recorded; regenerated receipt remains pending until the named evidence check passes and readiness is recomputed",
        evidence_path: "operator/rabbita-remediation-margin-cycle-closeout#energy-freeze",
        acceptance_check: "python3 scripts/check_energy_margin_remediation.py",
        may_consume_simulation: false,
        simulation_state: SimulationBlocked,
        automatic_refresh_loop_allowed: false,
        hardware_state: HardwareDenied,
        hardware_authority: "moonmoon-safety-gate-only",
        hardware_authority_change: false,
        hardware_denied: true,
      },
    ],
  )
}

///|
pub fn render_regenerated_receipt_readiness_action_receipt_closeout_markdown(
  closeout : RegeneratedReceiptReadinessActionReceiptCloseout,
) -> String {
  let mut text = "# MoonRobo Regenerated Receipt Readiness Action Receipt Closeout\n\n"
  text += "- closeout: \{closeout.closeout_id}\n"
  text += "- route: \{closeout.route_id}\n"
  text += "- source action receipts: \{closeout.source_action_receipt_bundle_path}\n"
  text += "- source workspace entry: \{closeout.source_workspace_entry_path}\n"
  text += "- source readiness gate: \{closeout.source_readiness_gate_id}\n"
  text += "- source readiness state: \{remediation_margin_regenerated_receipt_readiness_state_label(closeout.source_readiness_state)}\n"
  text += "- source task: \{closeout.source_task_id}\n"
  text += "- closeout state: \{regenerated_receipt_readiness_action_receipt_closeout_state_label(closeout.closeout_state)}\n"
  text += "- source action receipt count: \{closeout.source_action_receipt_count}\n"
  text += "- source receipt count: \{closeout.source_receipt_count}\n"
  text += "- ready receipt count: \{closeout.ready_receipt_count}\n"
  text += "- pending receipt count: \{closeout.pending_receipt_count}\n"
  text += "- may consume simulation: \{closeout.may_consume_simulation}\n"
  text += "- simulation state: \{execution_state_label(closeout.simulation_state)}\n"
  text += "- automatic refresh loop allowed: \{closeout.automatic_refresh_loop_allowed}\n"
  text += "- hardware state: \{execution_state_label(closeout.hardware_state)}\n"
  text += "- hardware authority: \{closeout.hardware_authority}\n"
  text += "- hardware denied: \{closeout.hardware_denied}\n"
  text += "- margins:\n"
  for index, margin_id in closeout.margin_ids {
    text += "  - \{margin_id}: \{closeout.refresh_ids[index]} via \{closeout.execution_modes[index]}\n"
  }
  text += "- source receipts:\n"
  for receipt_id in closeout.source_receipt_ids {
    text += "  - \{receipt_id}\n"
  }
  text += "- source action receipts:\n"
  for receipt_id in closeout.source_action_receipt_ids {
    text += "  - \{receipt_id}\n"
  }
  text += "- validation:\n"
  for check in closeout.validation_checks {
    let status = if check.passed { "pass" } else { "fail" }
    text += "  - \{check.validation_id}: \{status} - \{check.note}\n"
  }
  text += "- next action: \{closeout.next_action}"
  text
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout_markdown() -> String {
  render_regenerated_receipt_readiness_action_receipt_closeout_markdown(
    first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout(),
  )
}

///|
pub fn render_regenerated_receipt_readiness_action_receipt_closeout_json(
  closeout : RegeneratedReceiptReadinessActionReceiptCloseout,
) -> Json {
  closeout.to_json()
}

///|
pub fn first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout_json() -> Json {
  render_regenerated_receipt_readiness_action_receipt_closeout_json(
    first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout(),
  )
}
