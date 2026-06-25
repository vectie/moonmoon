///|
pub(all) enum RemediationMarginRegeneratedReceiptReadinessState {
  RegeneratedReceiptsReady
  RegeneratedReceiptsPendingFreshEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRegeneratedReceiptInput {
  receipt_id : String
  source_action_receipt_id : String
  source_receipt_id : String
  source_work_item_id : String
  margin_id : String
  refresh_id : String
  execution_mode : String
  result_status : String
  evidence_path : String
  acceptance_check : String
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RegeneratedReceiptReadinessValidation {
  validation_id : String
  passed : Bool
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRegeneratedReceiptReadinessGate {
  readiness_gate_id : String
  site_id : @core.SiteId
  route_id : String
  source_receipt_bundle_path : String
  source_workspace_entry_path : String
  source_receipt_count : Int
  ready_receipt_count : Int
  pending_receipt_count : Int
  pending_margin_ids : Array[String]
  pending_refresh_ids : Array[String]
  source_receipt_ids : Array[String]
  source_action_receipt_ids : Array[String]
  execution_modes : Array[String]
  readiness_state : RemediationMarginRegeneratedReceiptReadinessState
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  validation_checks : Array[RegeneratedReceiptReadinessValidation]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_regenerated_receipt_readiness_state_label(
  state : RemediationMarginRegeneratedReceiptReadinessState,
) -> String {
  match state {
    RegeneratedReceiptsReady => "RegeneratedReceiptsReady"
    RegeneratedReceiptsPendingFreshEvidence =>
      "RegeneratedReceiptsPendingFreshEvidence"
  }
}

///|
fn regenerated_receipt_readiness_validation(
  validation_id : String,
  passed : Bool,
  note : String,
) -> RegeneratedReceiptReadinessValidation {
  { validation_id, passed, note }
}

///|
fn pending_regenerated_receipts(
  receipts : Array[RemediationMarginRegeneratedReceiptInput],
) -> Array[RemediationMarginRegeneratedReceiptInput] {
  receipts.filter(fn(receipt) {
    receipt.result_status == "ReviewedWorkItemPendingFreshEvidence"
  })
}

///|
fn ready_regenerated_receipt_count(
  receipts : Array[RemediationMarginRegeneratedReceiptInput],
) -> Int {
  let mut count = 0
  for receipt in receipts {
    if receipt.result_status != "ReviewedWorkItemPendingFreshEvidence" {
      count = count + 1
    }
  }
  count
}

///|
fn expected_regenerated_receipt_execution_mode(
  receipt : RemediationMarginRegeneratedReceiptInput,
) -> Bool {
  (
    receipt.margin_id == "terrain-northeast-stepout" &&
    receipt.execution_mode == "operator-escalation"
  ) ||
  (
    receipt.margin_id == "illumination-northeast-stepout" &&
    receipt.execution_mode == "bounded-regeneration"
  ) ||
  (
    receipt.margin_id == "energy-window" &&
    receipt.execution_mode == "manual-freeze-verification"
  )
}

///|
fn regenerated_receipt_readiness_state(
  pending_count : Int,
) -> RemediationMarginRegeneratedReceiptReadinessState {
  if pending_count == 0 {
    RegeneratedReceiptsReady
  } else {
    RegeneratedReceiptsPendingFreshEvidence
  }
}

///|
fn regenerated_receipt_readiness_next_action(
  state : RemediationMarginRegeneratedReceiptReadinessState,
) -> String {
  match state {
    RegeneratedReceiptsReady =>
      "route a later ready regenerated receipt bundle into MoonRobo simulation review while HardwareDenied authority remains unchanged"
    RegeneratedReceiptsPendingFreshEvidence =>
      "keep regenerated terrain, local-horizon, and energy receipts pending fresh evidence; do not let MoonRobo consume simulation inputs until a later ready bundle passes its checks"
  }
}

///|
pub fn remediation_margin_regenerated_receipt_readiness_gate(
  site_id : @core.SiteId,
  route_id : String,
  source_receipt_bundle_path : String,
  source_workspace_entry_path : String,
  receipts : Array[RemediationMarginRegeneratedReceiptInput],
) -> RemediationMarginRegeneratedReceiptReadinessGate {
  let pending_receipts = pending_regenerated_receipts(receipts)
  let pending_count = pending_receipts.length()
  let ready_count = ready_regenerated_receipt_count(receipts)
  let state = regenerated_receipt_readiness_state(pending_count)
  let validation_checks = [
    regenerated_receipt_readiness_validation(
      "regenerated-receipts-present",
      receipts.length() > 0,
      "readiness gate consumed \{receipts.length()} regenerated reviewed work item receipts from \{source_receipt_bundle_path}",
    ),
    regenerated_receipt_readiness_validation(
      "all-receipts-pending-fresh-evidence",
      receipts.length() > 0 && pending_count == receipts.length(),
      "\{pending_count}/\{receipts.length()} regenerated receipts remain pending fresh evidence",
    ),
    regenerated_receipt_readiness_validation(
      "source-action-provenance-present",
      receipts.all(fn(receipt) {
        receipt.source_action_receipt_id != "" &&
        receipt.source_receipt_id != "" &&
        receipt.source_work_item_id != ""
      }),
      "every regenerated receipt carries source action receipt, source receipt, and work item provenance",
    ),
    regenerated_receipt_readiness_validation(
      "execution-modes-preserved",
      receipts.all(expected_regenerated_receipt_execution_mode),
      "terrain/horizon/energy execution modes remain operator-escalation, bounded-regeneration, and manual-freeze-verification",
    ),
    regenerated_receipt_readiness_validation(
      "no-automatic-refresh-loop",
      receipts.all(fn(receipt) { !receipt.automatic_refresh_loop_allowed }),
      "regenerated readiness does not open an automatic refresh loop",
    ),
    regenerated_receipt_readiness_validation(
      "simulation-consumption-blocked",
      receipts.all(fn(receipt) {
        !receipt.may_consume_simulation &&
        receipt.simulation_state == SimulationBlocked
      }),
      "regenerated receipts remain no-consume with simulation blocked",
    ),
    regenerated_receipt_readiness_validation(
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
    readiness_gate_id: "moonrobo/\{site_id}/remediation-margin-v1/regenerated-receipt-readiness",
    site_id,
    route_id,
    source_receipt_bundle_path,
    source_workspace_entry_path,
    source_receipt_count: receipts.length(),
    ready_receipt_count: ready_count,
    pending_receipt_count: pending_count,
    pending_margin_ids: pending_receipts.map(fn(receipt) { receipt.margin_id }),
    pending_refresh_ids: pending_receipts.map(fn(receipt) { receipt.refresh_id }),
    source_receipt_ids: receipts.map(fn(receipt) { receipt.source_receipt_id }),
    source_action_receipt_ids: receipts.map(fn(receipt) {
      receipt.source_action_receipt_id
    }),
    execution_modes: receipts.map(fn(receipt) { receipt.execution_mode }),
    readiness_state: state,
    may_consume_simulation: false,
    simulation_state: SimulationBlocked,
    automatic_refresh_loop_allowed: false,
    hardware_state: HardwareDenied,
    hardware_authority: "moonmoon-safety-gate-only",
    hardware_denied: true,
    validation_checks,
    next_action: regenerated_receipt_readiness_next_action(state),
  }
}

///|
pub fn first_trusted_square_remediation_margin_regenerated_receipt_readiness_gate() -> RemediationMarginRegeneratedReceiptReadinessGate {
  remediation_margin_regenerated_receipt_readiness_gate(
    "first-trusted-square",
    "northeast-stepout",
    "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json",
    "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json",
    [
      {
        receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout/regenerated-receipt",
        source_action_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task/action-1-terrain-northeast-stepout/receipt",
        source_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout/receipt",
        source_work_item_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout",
        margin_id: "terrain-northeast-stepout",
        refresh_id: "refresh-terrain-northeast-stepout",
        execution_mode: "operator-escalation",
        result_status: "ReviewedWorkItemPendingFreshEvidence",
        evidence_path: "operator/rabbita-remediation-margin-cycle-closeout#terrain-escalation",
        acceptance_check: "python3 scripts/check_selected_route_terrain_remediation.py",
        may_consume_simulation: false,
        simulation_state: SimulationBlocked,
        automatic_refresh_loop_allowed: false,
        hardware_state: HardwareDenied,
        hardware_authority: "moonmoon-safety-gate-only",
        hardware_authority_change: false,
        hardware_denied: true,
        next_action: "Keep terrain-northeast-stepout pending fresh evidence until python3 scripts/check_selected_route_terrain_remediation.py passes.",
      },
      {
        receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-2-illumination-northeast-stepout/regenerated-receipt",
        source_action_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task/action-2-illumination-northeast-stepout/receipt",
        source_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-2-illumination-northeast-stepout/receipt",
        source_work_item_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-2-illumination-northeast-stepout",
        margin_id: "illumination-northeast-stepout",
        refresh_id: "refresh-illumination-northeast-stepout",
        execution_mode: "bounded-regeneration",
        result_status: "ReviewedWorkItemPendingFreshEvidence",
        evidence_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        acceptance_check: "python3 scripts/check_selected_route_horizon_model.py",
        may_consume_simulation: false,
        simulation_state: SimulationBlocked,
        automatic_refresh_loop_allowed: false,
        hardware_state: HardwareDenied,
        hardware_authority: "moonmoon-safety-gate-only",
        hardware_authority_change: false,
        hardware_denied: true,
        next_action: "Keep illumination-northeast-stepout pending fresh evidence until python3 scripts/check_selected_route_horizon_model.py passes.",
      },
      {
        receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-3-energy-window/regenerated-receipt",
        source_action_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task/action-3-energy-window/receipt",
        source_receipt_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-3-energy-window/receipt",
        source_work_item_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-3-energy-window",
        margin_id: "energy-window",
        refresh_id: "refresh-energy-window",
        execution_mode: "manual-freeze-verification",
        result_status: "ReviewedWorkItemPendingFreshEvidence",
        evidence_path: "operator/rabbita-remediation-margin-cycle-closeout#energy-freeze",
        acceptance_check: "python3 scripts/check_energy_margin_remediation.py",
        may_consume_simulation: false,
        simulation_state: SimulationBlocked,
        automatic_refresh_loop_allowed: false,
        hardware_state: HardwareDenied,
        hardware_authority: "moonmoon-safety-gate-only",
        hardware_authority_change: false,
        hardware_denied: true,
        next_action: "Keep energy-window pending fresh evidence until python3 scripts/check_energy_margin_remediation.py passes.",
      },
    ],
  )
}

///|
pub fn render_remediation_margin_regenerated_receipt_readiness_markdown(
  gate : RemediationMarginRegeneratedReceiptReadinessGate,
) -> String {
  let mut text = "# MoonRobo Remediation Margin Regenerated Receipt Readiness\n\n"
  text += "- gate: \{gate.readiness_gate_id}\n"
  text += "- route: \{gate.route_id}\n"
  text += "- source receipts: \{gate.source_receipt_bundle_path}\n"
  text += "- source workspace entry: \{gate.source_workspace_entry_path}\n"
  text += "- readiness: \{remediation_margin_regenerated_receipt_readiness_state_label(gate.readiness_state)}\n"
  text += "- source receipt count: \{gate.source_receipt_count}\n"
  text += "- ready receipt count: \{gate.ready_receipt_count}\n"
  text += "- pending receipt count: \{gate.pending_receipt_count}\n"
  text += "- may consume simulation: \{gate.may_consume_simulation}\n"
  text += "- simulation state: \{execution_state_label(gate.simulation_state)}\n"
  text += "- automatic refresh loop allowed: \{gate.automatic_refresh_loop_allowed}\n"
  text += "- hardware state: \{execution_state_label(gate.hardware_state)}\n"
  text += "- hardware authority: \{gate.hardware_authority}\n"
  text += "- pending margins:\n"
  for index, margin_id in gate.pending_margin_ids {
    text += "  - \{margin_id}: \{gate.pending_refresh_ids[index]} via \{gate.execution_modes[index]}\n"
  }
  text += "- source action receipts:\n"
  for source_action_receipt_id in gate.source_action_receipt_ids {
    text += "  - \{source_action_receipt_id}\n"
  }
  text += "- validation:\n"
  for check in gate.validation_checks {
    let status = if check.passed { "pass" } else { "fail" }
    text += "  - \{check.validation_id}: \{status} - \{check.note}\n"
  }
  text += "- next action: \{gate.next_action}"
  text
}

///|
pub fn first_trusted_square_remediation_margin_regenerated_receipt_readiness_markdown() -> String {
  render_remediation_margin_regenerated_receipt_readiness_markdown(
    first_trusted_square_remediation_margin_regenerated_receipt_readiness_gate(),
  )
}

///|
pub fn render_remediation_margin_regenerated_receipt_readiness_json(
  gate : RemediationMarginRegeneratedReceiptReadinessGate,
) -> Json {
  gate.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_regenerated_receipt_readiness_json() -> Json {
  render_remediation_margin_regenerated_receipt_readiness_json(
    first_trusted_square_remediation_margin_regenerated_receipt_readiness_gate(),
  )
}
