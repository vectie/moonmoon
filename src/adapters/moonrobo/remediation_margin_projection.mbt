///|
pub(all) enum RemediationMarginProjectionStatus {
  SimulationConsumeAllowed
  NoConsumeSimulationBlocked
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginProjection {
  projection_id : String
  site_id : @core.SiteId
  route_id : String
  source_modeling_pass_id : String
  source_modeling_path : String
  source_modeling_state : RemediationMarginModelingState
  source_receipt_id : String
  source_task_id : String
  may_consume_simulation : Bool
  projection_status : RemediationMarginProjectionStatus
  simulation_state : MoonroboExecutionState
  active_margin_count : Int
  cleared_margin_count : Int
  still_blocking_margin_count : Int
  consumed_margin_result_ids : Array[String]
  blocking_margin_ids : Array[String]
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  reason : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_projection_status_label(
  status : RemediationMarginProjectionStatus,
) -> String {
  match status {
    SimulationConsumeAllowed => "SimulationConsumeAllowed"
    NoConsumeSimulationBlocked => "NoConsumeSimulationBlocked"
  }
}

///|
fn blocking_margin_ids(pass : RemediationMarginModelingPass) -> Array[String] {
  let ids : Array[String] = []
  for result in pass.margin_results {
    if !result.cleared {
      ids.push(result.margin_id)
    }
  }
  ids
}

///|
fn consumed_margin_result_ids(
  pass : RemediationMarginModelingPass,
) -> Array[String] {
  pass.margin_results.map(fn(result) { result.margin_id })
}

///|
fn projection_reason(
  may_consume : Bool,
  pass : RemediationMarginModelingPass,
) -> String {
  if may_consume {
    "simulation-consume projection: all remediation margins cleared by \{pass.modeling_pass_id}; hardware authority remains \{pass.hardware_authority}"
  } else {
    "no-consume projection: \{pass.still_blocking_margin_count} remediation margins still block simulation consumption from \{remediation_margin_modeling_state_label(pass.state)}; hardware authority remains \{pass.hardware_authority}"
  }
}

///|
fn projection_next_action(
  may_consume : Bool,
  pass : RemediationMarginModelingPass,
) -> String {
  if may_consume {
    "regenerate the simulation review packet from cleared remediation-margin evidence while preserving HardwareDenied authority"
  } else {
    "do not let MoonRobo consume simulation for \{pass.route_id}; regenerate terrain, local-horizon, and energy evidence before changing simulation state"
  }
}

///|
pub fn remediation_margin_projection(
  pass : RemediationMarginModelingPass,
  source_modeling_path : String,
) -> RemediationMarginProjection {
  let blockers = blocking_margin_ids(pass)
  let may_consume = blockers.length() == 0 &&
    pass.cleared_margin_count == pass.active_margin_count &&
    pass.hardware_denied &&
    pass.hardware_state == HardwareDenied
  {
    projection_id: "moonrobo/\{pass.site_id}/remediation-margin-v1/projection",
    site_id: pass.site_id,
    route_id: pass.route_id,
    source_modeling_pass_id: pass.modeling_pass_id,
    source_modeling_path,
    source_modeling_state: pass.state,
    source_receipt_id: pass.source_receipt_id,
    source_task_id: pass.source_task_id,
    may_consume_simulation: may_consume,
    projection_status: if may_consume {
      SimulationConsumeAllowed
    } else {
      NoConsumeSimulationBlocked
    },
    simulation_state: if may_consume {
      SimulationNeedsReview
    } else {
      SimulationBlocked
    },
    active_margin_count: pass.active_margin_count,
    cleared_margin_count: pass.cleared_margin_count,
    still_blocking_margin_count: pass.still_blocking_margin_count,
    consumed_margin_result_ids: consumed_margin_result_ids(pass),
    blocking_margin_ids: blockers,
    hardware_state: pass.hardware_state,
    hardware_authority: pass.hardware_authority,
    hardware_denied: pass.hardware_denied,
    reason: projection_reason(may_consume, pass),
    next_action: projection_next_action(may_consume, pass),
  }
}

///|
pub fn first_trusted_square_remediation_margin_projection() -> RemediationMarginProjection {
  remediation_margin_projection(
    first_trusted_square_remediation_margin_modeling_pass(),
    "output/moonrobo/first_trusted_square_remediation_margin_modeling.json",
  )
}

///|
pub fn render_remediation_margin_projection_markdown(
  projection : RemediationMarginProjection,
) -> String {
  let mut text = "# MoonRobo Remediation Margin Clearance Projection\n\n"
  text += "- projection: \{projection.projection_id}\n"
  text += "- route: \{projection.route_id}\n"
  text += "- source modeling pass: \{projection.source_modeling_pass_id}\n"
  text += "- source modeling path: \{projection.source_modeling_path}\n"
  text += "- source modeling state: \{remediation_margin_modeling_state_label(projection.source_modeling_state)}\n"
  text += "- status: \{remediation_margin_projection_status_label(projection.projection_status)}\n"
  text += "- may consume simulation: \{projection.may_consume_simulation}\n"
  text += "- simulation state: \{execution_state_label(projection.simulation_state)}\n"
  text += "- active margins: \{projection.active_margin_count}\n"
  text += "- cleared margins: \{projection.cleared_margin_count}\n"
  text += "- still blocking margins: \{projection.still_blocking_margin_count}\n"
  text += "- hardware state: \{execution_state_label(projection.hardware_state)}\n"
  text += "- hardware authority: \{projection.hardware_authority}\n"
  text += "- hardware denied: \{projection.hardware_denied}\n"
  text += "- reason: \{projection.reason}\n"
  text += "- next action: \{projection.next_action}\n\n"
  text += "## Consumed Margin Results\n\n"
  for margin_id in projection.consumed_margin_result_ids {
    text += "- \{margin_id}\n"
  }
  text += "\n## Blocking Margins\n\n"
  for margin_id in projection.blocking_margin_ids {
    text += "- \{margin_id}\n"
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_projection_markdown() -> String {
  render_remediation_margin_projection_markdown(
    first_trusted_square_remediation_margin_projection(),
  )
}

///|
pub fn remediation_margin_projection_json(
  projection : RemediationMarginProjection,
) -> Json {
  projection.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_projection_json() -> Json {
  remediation_margin_projection_json(
    first_trusted_square_remediation_margin_projection(),
  )
}
