///|
pub(all) enum RemediationMarginModelingResultStatus {
  MarginCleared
  MarginStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum RemediationMarginModelingState {
  AllMarginsCleared
  SomeMarginsCleared
  AllMarginsStillBlocking
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginModelingInput {
  margin_id : String
  source_artifact_path : String
  receipt_status : String
  current_state : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginModelingResult {
  margin_id : String
  source_artifact_path : String
  receipt_status : String
  current_state : String
  modeling_evidence_path : String
  modeling_command : String
  result_status : RemediationMarginModelingResultStatus
  cleared : Bool
  result_rationale : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginModelingPass {
  modeling_pass_id : String
  site_id : @core.SiteId
  route_id : String
  source_receipt_id : String
  source_receipt_path : String
  source_task_id : String
  source_remediation_state : String
  state : RemediationMarginModelingState
  active_margin_count : Int
  cleared_margin_count : Int
  still_blocking_margin_count : Int
  margin_results : Array[RemediationMarginModelingResult]
  commands_evaluated : Array[String]
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_modeling_result_status_label(
  status : RemediationMarginModelingResultStatus,
) -> String {
  match status {
    MarginCleared => "MarginCleared"
    MarginStillBlocking => "MarginStillBlocking"
  }
}

///|
pub fn remediation_margin_modeling_state_label(
  state : RemediationMarginModelingState,
) -> String {
  match state {
    AllMarginsCleared => "AllMarginsCleared"
    SomeMarginsCleared => "SomeMarginsCleared"
    AllMarginsStillBlocking => "AllMarginsStillBlocking"
  }
}

///|
fn remediation_margin_modeling_command(margin_id : String) -> String {
  if margin_id == "terrain-northeast-stepout" {
    "python3 scripts/check_selected_route_terrain_remediation.py"
  } else if margin_id == "illumination-northeast-stepout" {
    "python3 scripts/check_selected_route_horizon_model.py"
  } else if margin_id == "energy-window" {
    "python3 scripts/check_energy_margin_remediation.py"
  } else {
    "python3 scripts/check_moonrobo_remediation_margin_modeling.py"
  }
}

///|
fn remediation_margin_modeling_rationale(margin_id : String) -> String {
  if margin_id == "terrain-northeast-stepout" {
    "terrain grade and roughness evidence still carries the selected-route terrain margin"
  } else if margin_id == "illumination-northeast-stepout" {
    "local horizon evidence still carries the terrain-shadow illumination margin"
  } else if margin_id == "energy-window" {
    "bounded selected-route demand evidence still carries the negative energy margin"
  } else {
    "receipt margin has no clearing model attached, so MoonRobo carries it forward"
  }
}

///|
fn remediation_margin_modeling_result(
  input : RemediationMarginModelingInput,
) -> RemediationMarginModelingResult {
  {
    margin_id: input.margin_id,
    source_artifact_path: input.source_artifact_path,
    receipt_status: input.receipt_status,
    current_state: input.current_state,
    modeling_evidence_path: input.source_artifact_path,
    modeling_command: remediation_margin_modeling_command(input.margin_id),
    result_status: MarginStillBlocking,
    cleared: false,
    result_rationale: remediation_margin_modeling_rationale(input.margin_id),
    next_action: input.next_action,
  }
}

///|
fn cleared_modeling_margin_count(
  results : Array[RemediationMarginModelingResult],
) -> Int {
  let mut count = 0
  for result in results {
    if result.cleared {
      count = count + 1
    }
  }
  count
}

///|
fn remediation_margin_modeling_state(
  cleared_count : Int,
  total_count : Int,
) -> RemediationMarginModelingState {
  if cleared_count == total_count {
    AllMarginsCleared
  } else if cleared_count == 0 {
    AllMarginsStillBlocking
  } else {
    SomeMarginsCleared
  }
}

///|
fn remediation_margin_modeling_next_action(
  state : RemediationMarginModelingState,
) -> String {
  match state {
    AllMarginsCleared =>
      "regenerate MoonRobo simulation review packets from cleared remediation-margin evidence while hardware authority remains denied"
    _ =>
      "carry the terrain, local-horizon, and energy margins forward; regenerate their evidence before MoonRobo simulation consumption can change"
  }
}

///|
pub fn remediation_margin_modeling_pass(
  site_id : @core.SiteId,
  route_id : String,
  source_receipt_id : String,
  source_receipt_path : String,
  source_task_id : String,
  source_remediation_state : String,
  margin_inputs : Array[RemediationMarginModelingInput],
  hardware_state : MoonroboExecutionState,
  hardware_authority : String,
  hardware_denied : Bool,
) -> RemediationMarginModelingPass {
  let results = margin_inputs.map(remediation_margin_modeling_result)
  let cleared_count = cleared_modeling_margin_count(results)
  let state = remediation_margin_modeling_state(cleared_count, results.length())
  {
    modeling_pass_id: "moonrobo/\{site_id}/remediation-margin-v1/modeling-pass",
    site_id,
    route_id,
    source_receipt_id,
    source_receipt_path,
    source_task_id,
    source_remediation_state,
    state,
    active_margin_count: results.length(),
    cleared_margin_count: cleared_count,
    still_blocking_margin_count: results.length() - cleared_count,
    margin_results: results,
    commands_evaluated: results.map(fn(result) { result.modeling_command }),
    hardware_state,
    hardware_authority,
    hardware_denied,
    next_action: remediation_margin_modeling_next_action(state),
  }
}

///|
pub fn first_trusted_square_remediation_margin_modeling_pass() -> RemediationMarginModelingPass {
  remediation_margin_modeling_pass(
    "first-trusted-square",
    "northeast-stepout",
    "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt",
    "output/moonclaw/first_trusted_square_remediation_margin_receipt.json",
    "moonclaw/first-trusted-square/remediation-margin-v1/task",
    "OpenMarginsCarriedForward",
    [
      {
        margin_id: "terrain-northeast-stepout",
        source_artifact_path: "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
        receipt_status: "StillBlocking",
        current_state: "grade margin 0.16395, roughness margin 3.45975 m, blocking edges 11/24",
        next_action: "collect a wider smoother selected-route corridor or keep northeast-stepout out of MoonRobo simulation",
      },
      {
        margin_id: "illumination-northeast-stepout",
        source_artifact_path: "output/mission/first_trusted_square_northeast_stepout_horizon.json",
        receipt_status: "StillBlocking",
        current_state: "terrain-shadow margin 26.356833 deg, max horizon 26.487251 deg, max sun altitude 0.130418 deg",
        next_action: "collect wider local horizon and terrain-shadow evidence before route simulation",
      },
      {
        margin_id: "energy-window",
        source_artifact_path: "output/mission/first_trusted_square_energy_remediation.json",
        receipt_status: "StillBlocking",
        current_state: "bounded margin -855.061927 Wh, margin gap 1105.061927 Wh, available 234.938073 Wh",
        next_action: "reduce reserve or dark-survival demand, increase verified power-window energy, or keep northeast-stepout out of MoonRobo simulation",
      },
    ],
    HardwareDenied,
    "moonmoon-safety-gate-only",
    true,
  )
}

///|
pub fn first_trusted_square_remediation_margin_modeling_passes() -> Array[
  RemediationMarginModelingPass,
] {
  [first_trusted_square_remediation_margin_modeling_pass()]
}

///|
pub fn render_remediation_margin_modeling_markdown(
  passes : Array[RemediationMarginModelingPass],
) -> String {
  let mut text = "# MoonRobo Remediation Margin Modeling Passes\n\n"
  for pass_index, pass in passes {
    text += "- pass: \{pass.modeling_pass_id}\n"
    text += "  - route: \{pass.route_id}\n"
    text += "  - source receipt: \{pass.source_receipt_id}\n"
    text += "  - source task: \{pass.source_task_id}\n"
    text += "  - source state: \{pass.source_remediation_state}\n"
    text += "  - state: \{remediation_margin_modeling_state_label(pass.state)}\n"
    text += "  - active margins: \{pass.active_margin_count}\n"
    text += "  - cleared margins: \{pass.cleared_margin_count}\n"
    text += "  - still blocking margins: \{pass.still_blocking_margin_count}\n"
    text += "  - hardware state: \{execution_state_label(pass.hardware_state)}\n"
    text += "  - hardware authority: \{pass.hardware_authority}\n"
    text += "  - next action: \{pass.next_action}\n"
    text += "  - margin results:\n"
    for result_index, result in pass.margin_results {
      text += "    - \{result.margin_id}: \{remediation_margin_modeling_result_status_label(result.result_status)}\n"
      text += "      - command: \{result.modeling_command}\n"
      text += "      - evidence: \{result.modeling_evidence_path}\n"
      text += "      - rationale: \{result.result_rationale}"
      if result_index + 1 < pass.margin_results.length() {
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
pub fn first_trusted_square_remediation_margin_modeling_markdown() -> String {
  render_remediation_margin_modeling_markdown(
    first_trusted_square_remediation_margin_modeling_passes(),
  )
}

///|
pub fn render_remediation_margin_modeling_json(
  passes : Array[RemediationMarginModelingPass],
) -> Json {
  passes.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_modeling_json() -> Json {
  render_remediation_margin_modeling_json(
    first_trusted_square_remediation_margin_modeling_passes(),
  )
}
