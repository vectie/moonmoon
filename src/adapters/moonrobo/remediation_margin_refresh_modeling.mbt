///|
pub(all) enum RemediationMarginRefreshModelingResultStatus {
  RefreshEvidenceAccepted
  RefreshStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum RemediationMarginRefreshModelingState {
  AllRefreshesAccepted
  SomeRefreshesAccepted
  AllRefreshesStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshModelingInput {
  rank : Int
  margin_id : String
  refresh_id : String
  receipt_status : String
  source_projection_path : String
  target_artifact_path : String
  evidence_path : String
  acceptance_check : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshModelingResult {
  rank : Int
  margin_id : String
  refresh_id : String
  receipt_status : String
  source_projection_path : String
  target_artifact_path : String
  evidence_path : String
  modeling_command : String
  result_status : RemediationMarginRefreshModelingResultStatus
  refreshed : Bool
  result_rationale : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshModelingPass {
  modeling_pass_id : String
  site_id : @core.SiteId
  route_id : String
  source_receipt_id : String
  source_receipt_path : String
  source_task_id : String
  source_projection_id : String
  source_refresh_state : String
  state : RemediationMarginRefreshModelingState
  refresh_action_count : Int
  refreshed_count : Int
  still_blocking_count : Int
  refresh_results : Array[RemediationMarginRefreshModelingResult]
  commands_evaluated : Array[String]
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_refresh_modeling_result_status_label(
  status : RemediationMarginRefreshModelingResultStatus,
) -> String {
  match status {
    RefreshEvidenceAccepted => "RefreshEvidenceAccepted"
    RefreshStillBlocking => "RefreshStillBlocking"
  }
}

///|
pub fn remediation_margin_refresh_modeling_state_label(
  state : RemediationMarginRefreshModelingState,
) -> String {
  match state {
    AllRefreshesAccepted => "AllRefreshesAccepted"
    SomeRefreshesAccepted => "SomeRefreshesAccepted"
    AllRefreshesStillBlocking => "AllRefreshesStillBlocking"
  }
}

///|
fn remediation_margin_refresh_modeling_rationale(margin_id : String) -> String {
  if margin_id == "terrain-northeast-stepout" {
    "terrain refresh evidence is still carried forward because selected-route grade, roughness, and edge margins remain open"
  } else if margin_id == "illumination-northeast-stepout" {
    "local-horizon refresh evidence is still carried forward because terrain-shadow illumination confidence remains open"
  } else if margin_id == "energy-window" {
    "energy refresh evidence is still carried forward because the bounded route energy margin remains negative"
  } else {
    "refresh receipt result has no accepted model, so MoonRobo carries it forward"
  }
}

///|
fn remediation_margin_refresh_modeling_result(
  input : RemediationMarginRefreshModelingInput,
) -> RemediationMarginRefreshModelingResult {
  {
    rank: input.rank,
    margin_id: input.margin_id,
    refresh_id: input.refresh_id,
    receipt_status: input.receipt_status,
    source_projection_path: input.source_projection_path,
    target_artifact_path: input.target_artifact_path,
    evidence_path: input.evidence_path,
    modeling_command: input.acceptance_check,
    result_status: RefreshStillBlocking,
    refreshed: false,
    result_rationale: remediation_margin_refresh_modeling_rationale(
      input.margin_id,
    ),
    next_action: input.next_action,
  }
}

///|
fn accepted_refresh_count(
  results : Array[RemediationMarginRefreshModelingResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.refreshed {
      count = count + 1
    }
  }
  count
}

///|
fn remediation_margin_refresh_modeling_state(
  refreshed_count : Int,
  total_count : Int,
) -> RemediationMarginRefreshModelingState {
  if refreshed_count == total_count {
    AllRefreshesAccepted
  } else if refreshed_count == 0 {
    AllRefreshesStillBlocking
  } else {
    SomeRefreshesAccepted
  }
}

///|
fn remediation_margin_refresh_modeling_next_action(
  state : RemediationMarginRefreshModelingState,
) -> String {
  match state {
    AllRefreshesAccepted =>
      "regenerate the remediation-margin projection from accepted refresh evidence while hardware authority remains denied"
    _ =>
      "carry the terrain, local-horizon, and energy refreshes forward; do not let MoonRobo consume simulation inputs until refreshed evidence clears the margins"
  }
}

///|
pub fn remediation_margin_refresh_modeling_pass(
  site_id : @core.SiteId,
  route_id : String,
  source_receipt_id : String,
  source_receipt_path : String,
  source_task_id : String,
  source_projection_id : String,
  source_refresh_state : String,
  refresh_inputs : Array[RemediationMarginRefreshModelingInput],
  hardware_state : MoonroboExecutionState,
  hardware_authority : String,
  hardware_denied : Bool,
) -> RemediationMarginRefreshModelingPass {
  let results = refresh_inputs.map(remediation_margin_refresh_modeling_result)
  let refreshed_count = accepted_refresh_count(results)
  let state = remediation_margin_refresh_modeling_state(
    refreshed_count,
    results.length(),
  )
  {
    modeling_pass_id: "moonrobo/\{site_id}/remediation-margin-v1/refresh-modeling-pass",
    site_id,
    route_id,
    source_receipt_id,
    source_receipt_path,
    source_task_id,
    source_projection_id,
    source_refresh_state,
    state,
    refresh_action_count: results.length(),
    refreshed_count,
    still_blocking_count: results.length() - refreshed_count,
    refresh_results: results,
    commands_evaluated: results.map(fn(result) { result.modeling_command }),
    may_consume_simulation: false,
    simulation_state: SimulationBlocked,
    hardware_state,
    hardware_authority,
    hardware_denied,
    next_action: remediation_margin_refresh_modeling_next_action(state),
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_modeling_pass() -> RemediationMarginRefreshModelingPass {
  remediation_margin_refresh_modeling_pass(
    "first-trusted-square",
    "northeast-stepout",
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt",
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json",
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task",
    "moonrobo/first-trusted-square/remediation-margin-v1/projection",
    "RefreshesCarriedForward",
    [
      {
        rank: 1,
        margin_id: "terrain-northeast-stepout",
        refresh_id: "refresh-terrain-northeast-stepout",
        receipt_status: "RefreshStillBlocking",
        source_projection_path: "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
        target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        evidence_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        acceptance_check: "python3 scripts/check_selected_route_terrain_remediation.py",
        current_state: "refresh requested; refreshed evidence has not yet cleared this remediation margin",
        next_action: "Refresh selected-route terrain evidence first because grade, roughness, and blocking-edge margins feed every downstream route-consume decision for northeast-stepout.",
      },
      {
        rank: 2,
        margin_id: "illumination-northeast-stepout",
        refresh_id: "refresh-illumination-northeast-stepout",
        receipt_status: "RefreshStillBlocking",
        source_projection_path: "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
        target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        evidence_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        acceptance_check: "python3 scripts/check_selected_route_horizon_model.py",
        current_state: "refresh requested; refreshed evidence has not yet cleared this remediation margin",
        next_action: "Refresh local-horizon evidence for northeast-stepout after terrain so illumination keeps using bounded terrain-shadow geometry before simulation consumption changes.",
      },
      {
        rank: 3,
        margin_id: "energy-window",
        refresh_id: "refresh-energy-window",
        receipt_status: "RefreshStillBlocking",
        source_projection_path: "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
        target_artifact_path: "output/mission/first_trusted_square_energy_remediation.json",
        evidence_path: "output/mission/first_trusted_square_energy_remediation.json",
        acceptance_check: "python3 scripts/check_energy_margin_remediation.py",
        current_state: "refresh requested; refreshed evidence has not yet cleared this remediation margin",
        next_action: "Refresh bounded energy evidence for northeast-stepout after terrain and horizon because route demand and sunlit-window margins depend on those constraints.",
      },
    ],
    HardwareDenied,
    "moonmoon-safety-gate-only",
    true,
  )
}

///|
pub fn first_trusted_square_remediation_margin_refresh_modeling_passes() -> Array[
  RemediationMarginRefreshModelingPass,
] {
  [first_trusted_square_remediation_margin_refresh_modeling_pass()]
}

///|
pub fn render_remediation_margin_refresh_modeling_markdown(
  passes : Array[RemediationMarginRefreshModelingPass],
) -> String {
  let mut text = "# MoonRobo Remediation Margin Refresh Modeling Passes\n\n"
  for pass_index, pass in passes {
    text += "- pass: \{pass.modeling_pass_id}\n"
    text += "  - route: \{pass.route_id}\n"
    text += "  - source receipt: \{pass.source_receipt_id}\n"
    text += "  - source task: \{pass.source_task_id}\n"
    text += "  - source projection: \{pass.source_projection_id}\n"
    text += "  - source state: \{pass.source_refresh_state}\n"
    text += "  - state: \{remediation_margin_refresh_modeling_state_label(pass.state)}\n"
    text += "  - refresh actions: \{pass.refresh_action_count}\n"
    text += "  - refreshed: \{pass.refreshed_count}\n"
    text += "  - still blocking: \{pass.still_blocking_count}\n"
    text += "  - may consume simulation: \{pass.may_consume_simulation}\n"
    text += "  - simulation state: \{execution_state_label(pass.simulation_state)}\n"
    text += "  - hardware state: \{execution_state_label(pass.hardware_state)}\n"
    text += "  - hardware authority: \{pass.hardware_authority}\n"
    text += "  - next action: \{pass.next_action}\n"
    text += "  - refresh results:\n"
    for result_index, result in pass.refresh_results {
      text += "    - \{result.rank}. \{result.refresh_id}: \{result.margin_id} - \{remediation_margin_refresh_modeling_result_status_label(result.result_status)}\n"
      text += "      - command: \{result.modeling_command}\n"
      text += "      - evidence: \{result.evidence_path}\n"
      text += "      - target: \{result.target_artifact_path}\n"
      text += "      - rationale: \{result.result_rationale}"
      if result_index + 1 < pass.refresh_results.length() {
        text += "\n"
      }
    }
    if pass_index + 1 < passes.length() {
      text += "\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_refresh_modeling_markdown() -> String {
  render_remediation_margin_refresh_modeling_markdown(
    first_trusted_square_remediation_margin_refresh_modeling_passes(),
  )
}

///|
pub fn render_remediation_margin_refresh_modeling_json(
  passes : Array[RemediationMarginRefreshModelingPass],
) -> Json {
  passes.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_modeling_json() -> Json {
  render_remediation_margin_refresh_modeling_json(
    first_trusted_square_remediation_margin_refresh_modeling_passes(),
  )
}
