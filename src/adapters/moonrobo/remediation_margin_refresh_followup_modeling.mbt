///|
pub(all) enum RemediationMarginRefreshFollowupModelingResultStatus {
  FollowupRefreshEvidenceAccepted
  FollowupRefreshStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum RemediationMarginRefreshFollowupModelingState {
  AllFollowupRefreshesAccepted
  SomeFollowupRefreshesAccepted
  AllFollowupRefreshesStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshFollowupModelingInput {
  rank : Int
  margin_id : String
  refresh_id : String
  receipt_status : String
  source_refresh_projection_path : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  evidence_path : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshFollowupModelingResult {
  rank : Int
  margin_id : String
  refresh_id : String
  receipt_status : String
  source_refresh_projection_path : String
  target_artifact_path : String
  evidence_path : String
  modeling_command : String
  result_status : RemediationMarginRefreshFollowupModelingResultStatus
  refreshed : Bool
  result_rationale : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshFollowupModelingPass {
  modeling_pass_id : String
  site_id : @core.SiteId
  route_id : String
  source_receipt_id : String
  source_receipt_path : String
  source_task_id : String
  source_refresh_projection_id : String
  source_modeling_pass_id : String
  source_modeling_state : String
  source_projection_status : String
  source_followup_state : String
  state : RemediationMarginRefreshFollowupModelingState
  followup_action_count : Int
  refreshed_count : Int
  still_blocking_count : Int
  followup_results : Array[RemediationMarginRefreshFollowupModelingResult]
  commands_evaluated : Array[String]
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_refresh_followup_modeling_result_status_label(
  status : RemediationMarginRefreshFollowupModelingResultStatus,
) -> String {
  match status {
    FollowupRefreshEvidenceAccepted => "FollowupRefreshEvidenceAccepted"
    FollowupRefreshStillBlocking => "FollowupRefreshStillBlocking"
  }
}

///|
pub fn remediation_margin_refresh_followup_modeling_state_label(
  state : RemediationMarginRefreshFollowupModelingState,
) -> String {
  match state {
    AllFollowupRefreshesAccepted => "AllFollowupRefreshesAccepted"
    SomeFollowupRefreshesAccepted => "SomeFollowupRefreshesAccepted"
    AllFollowupRefreshesStillBlocking => "AllFollowupRefreshesStillBlocking"
  }
}

///|
fn remediation_margin_refresh_followup_modeling_rationale(
  margin_id : String,
) -> String {
  if margin_id == "terrain-northeast-stepout" {
    "terrain follow-up refresh remains carried forward because selected-route grade, roughness, and blocking-edge evidence still do not clear simulation consumption"
  } else if margin_id == "illumination-northeast-stepout" {
    "local-horizon follow-up refresh remains carried forward because terrain-shadow illumination confidence still does not clear simulation consumption"
  } else if margin_id == "energy-window" {
    "energy follow-up refresh remains carried forward because the bounded route energy margin remains negative"
  } else {
    "follow-up receipt result has no accepted model, so MoonRobo carries it forward"
  }
}

///|
fn remediation_margin_refresh_followup_modeling_result(
  input : RemediationMarginRefreshFollowupModelingInput,
) -> RemediationMarginRefreshFollowupModelingResult {
  {
    rank: input.rank,
    margin_id: input.margin_id,
    refresh_id: input.refresh_id,
    receipt_status: input.receipt_status,
    source_refresh_projection_path: input.source_refresh_projection_path,
    target_artifact_path: input.target_artifact_path,
    evidence_path: input.evidence_path,
    modeling_command: input.acceptance_check,
    result_status: FollowupRefreshStillBlocking,
    refreshed: false,
    result_rationale: remediation_margin_refresh_followup_modeling_rationale(
      input.margin_id,
    ),
    next_action: input.next_action,
  }
}

///|
fn accepted_followup_refresh_count(
  results : Array[RemediationMarginRefreshFollowupModelingResult],
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
fn remediation_margin_refresh_followup_modeling_state(
  refreshed_count : Int,
  total_count : Int,
) -> RemediationMarginRefreshFollowupModelingState {
  if refreshed_count == total_count {
    AllFollowupRefreshesAccepted
  } else if refreshed_count == 0 {
    AllFollowupRefreshesStillBlocking
  } else {
    SomeFollowupRefreshesAccepted
  }
}

///|
fn remediation_margin_refresh_followup_modeling_next_action(
  state : RemediationMarginRefreshFollowupModelingState,
) -> String {
  match state {
    AllFollowupRefreshesAccepted =>
      "regenerate the no-consume refresh projection from accepted follow-up evidence while hardware authority remains denied"
    _ =>
      "carry the terrain, local-horizon, and energy follow-up refreshes forward; do not let MoonRobo consume simulation inputs until refreshed evidence clears the projection-derived blockers"
  }
}

///|
pub fn remediation_margin_refresh_followup_modeling_pass(
  site_id : @core.SiteId,
  route_id : String,
  source_receipt_id : String,
  source_receipt_path : String,
  source_task_id : String,
  source_refresh_projection_id : String,
  source_modeling_pass_id : String,
  source_modeling_state : String,
  source_projection_status : String,
  source_followup_state : String,
  followup_inputs : Array[RemediationMarginRefreshFollowupModelingInput],
  hardware_state : MoonroboExecutionState,
  hardware_authority : String,
  hardware_denied : Bool,
) -> RemediationMarginRefreshFollowupModelingPass {
  let results = followup_inputs.map(
    remediation_margin_refresh_followup_modeling_result,
  )
  let refreshed_count = accepted_followup_refresh_count(results)
  let state = remediation_margin_refresh_followup_modeling_state(
    refreshed_count,
    results.length(),
  )
  {
    modeling_pass_id: "moonrobo/\{site_id}/remediation-margin-v1/refresh-followup-modeling-pass",
    site_id,
    route_id,
    source_receipt_id,
    source_receipt_path,
    source_task_id,
    source_refresh_projection_id,
    source_modeling_pass_id,
    source_modeling_state,
    source_projection_status,
    source_followup_state,
    state,
    followup_action_count: results.length(),
    refreshed_count,
    still_blocking_count: results.length() - refreshed_count,
    followup_results: results,
    commands_evaluated: results.map(fn(result) { result.modeling_command }),
    may_consume_simulation: false,
    simulation_state: SimulationBlocked,
    hardware_state,
    hardware_authority,
    hardware_denied,
    next_action: remediation_margin_refresh_followup_modeling_next_action(state),
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_modeling_pass() -> RemediationMarginRefreshFollowupModelingPass {
  remediation_margin_refresh_followup_modeling_pass(
    "first-trusted-square",
    "northeast-stepout",
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt",
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json",
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass",
    "AllRefreshesStillBlocking",
    "NoConsumeRefreshSimulationBlocked",
    "FollowupRefreshesCarriedForward",
    [
      {
        rank: 1,
        margin_id: "terrain-northeast-stepout",
        refresh_id: "refresh-terrain-northeast-stepout",
        receipt_status: "FollowupRefreshStillBlocking",
        source_refresh_projection_path: "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
        target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        command: "python3 scripts/generate_selected_route_terrain_remediation.py --check",
        acceptance_check: "python3 scripts/check_selected_route_terrain_remediation.py",
        evidence_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        current_state: "follow-up refresh requested; refreshed evidence has not yet cleared this projection-derived blocker",
        next_action: "Re-run the terrain refresh first because moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection still blocks simulation consumption on selected-route grade, roughness, and blocking-edge evidence.",
      },
      {
        rank: 2,
        margin_id: "illumination-northeast-stepout",
        refresh_id: "refresh-illumination-northeast-stepout",
        receipt_status: "FollowupRefreshStillBlocking",
        source_refresh_projection_path: "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
        target_artifact_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        command: "python3 scripts/generate_selected_route_horizon.py --check",
        acceptance_check: "python3 scripts/check_selected_route_horizon_model.py",
        evidence_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        current_state: "follow-up refresh requested; refreshed evidence has not yet cleared this projection-derived blocker",
        next_action: "Re-run the local-horizon refresh after terrain so illumination evidence remains tied to bounded terrain-shadow geometry for northeast-stepout.",
      },
      {
        rank: 3,
        margin_id: "energy-window",
        refresh_id: "refresh-energy-window",
        receipt_status: "FollowupRefreshStillBlocking",
        source_refresh_projection_path: "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
        target_artifact_path: "output/mission/first_trusted_square_energy_remediation.json",
        command: "python3 scripts/check_energy_margin_remediation.py",
        acceptance_check: "python3 scripts/check_energy_margin_remediation.py",
        evidence_path: "output/mission/first_trusted_square_energy_remediation.json",
        current_state: "follow-up refresh requested; refreshed evidence has not yet cleared this projection-derived blocker",
        next_action: "Re-run bounded energy refresh last because demand and reserve evidence should consume the refreshed terrain and local-horizon constraints for northeast-stepout.",
      },
    ],
    HardwareDenied,
    "moonmoon-safety-gate-only",
    true,
  )
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_modeling_passes() -> Array[
  RemediationMarginRefreshFollowupModelingPass,
] {
  [first_trusted_square_remediation_margin_refresh_followup_modeling_pass()]
}

///|
pub fn render_remediation_margin_refresh_followup_modeling_markdown(
  passes : Array[RemediationMarginRefreshFollowupModelingPass],
) -> String {
  let mut text = "# MoonRobo Remediation Margin Refresh Follow-Up Modeling Passes\n\n"
  for pass_index, pass in passes {
    text += "- pass: \{pass.modeling_pass_id}\n"
    text += "  - route: \{pass.route_id}\n"
    text += "  - source receipt: \{pass.source_receipt_id}\n"
    text += "  - source task: \{pass.source_task_id}\n"
    text += "  - source refresh projection: \{pass.source_refresh_projection_id}\n"
    text += "  - source modeling pass: \{pass.source_modeling_pass_id}\n"
    text += "  - source modeling state: \{pass.source_modeling_state}\n"
    text += "  - source projection status: \{pass.source_projection_status}\n"
    text += "  - source follow-up state: \{pass.source_followup_state}\n"
    text += "  - state: \{remediation_margin_refresh_followup_modeling_state_label(pass.state)}\n"
    text += "  - follow-up actions: \{pass.followup_action_count}\n"
    text += "  - refreshed: \{pass.refreshed_count}\n"
    text += "  - still blocking: \{pass.still_blocking_count}\n"
    text += "  - may consume simulation: \{pass.may_consume_simulation}\n"
    text += "  - simulation state: \{execution_state_label(pass.simulation_state)}\n"
    text += "  - hardware state: \{execution_state_label(pass.hardware_state)}\n"
    text += "  - hardware authority: \{pass.hardware_authority}\n"
    text += "  - next action: \{pass.next_action}\n"
    text += "  - follow-up results:\n"
    for result_index, result in pass.followup_results {
      text += "    - \{result.rank}. \{result.refresh_id}: \{result.margin_id} - \{remediation_margin_refresh_followup_modeling_result_status_label(result.result_status)}\n"
      text += "      - command: \{result.modeling_command}\n"
      text += "      - evidence: \{result.evidence_path}\n"
      text += "      - target: \{result.target_artifact_path}\n"
      text += "      - rationale: \{result.result_rationale}"
      if result_index + 1 < pass.followup_results.length() {
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
pub fn first_trusted_square_remediation_margin_refresh_followup_modeling_markdown() -> String {
  render_remediation_margin_refresh_followup_modeling_markdown(
    first_trusted_square_remediation_margin_refresh_followup_modeling_passes(),
  )
}

///|
pub fn render_remediation_margin_refresh_followup_modeling_json(
  passes : Array[RemediationMarginRefreshFollowupModelingPass],
) -> Json {
  passes.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_followup_modeling_json() -> Json {
  render_remediation_margin_refresh_followup_modeling_json(
    first_trusted_square_remediation_margin_refresh_followup_modeling_passes(),
  )
}
