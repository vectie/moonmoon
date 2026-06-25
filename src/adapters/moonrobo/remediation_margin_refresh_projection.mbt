///|
pub(all) enum RemediationMarginRefreshProjectionStatus {
  RefreshSimulationConsumeAllowed
  NoConsumeRefreshSimulationBlocked
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginRefreshProjection {
  projection_id : String
  site_id : @core.SiteId
  route_id : String
  source_modeling_pass_id : String
  source_modeling_path : String
  source_modeling_state : RemediationMarginRefreshModelingState
  source_receipt_id : String
  source_task_id : String
  source_projection_id : String
  may_consume_simulation : Bool
  projection_status : RemediationMarginRefreshProjectionStatus
  simulation_state : MoonroboExecutionState
  refresh_action_count : Int
  refreshed_count : Int
  still_blocking_count : Int
  consumed_refresh_result_ids : Array[String]
  blocking_refresh_ids : Array[String]
  blocking_margin_ids : Array[String]
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  reason : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_refresh_projection_status_label(
  status : RemediationMarginRefreshProjectionStatus,
) -> String {
  match status {
    RefreshSimulationConsumeAllowed => "RefreshSimulationConsumeAllowed"
    NoConsumeRefreshSimulationBlocked => "NoConsumeRefreshSimulationBlocked"
  }
}

///|
fn consumed_refresh_result_ids(
  pass : RemediationMarginRefreshModelingPass,
) -> Array[String] {
  pass.refresh_results.map(fn(result) { result.refresh_id })
}

///|
fn blocking_refresh_ids(
  pass : RemediationMarginRefreshModelingPass,
) -> Array[String] {
  let ids : Array[String] = []
  for result in pass.refresh_results {
    if !result.refreshed {
      ids.push(result.refresh_id)
    }
  }
  ids
}

///|
fn refresh_projection_blocking_margin_ids(
  pass : RemediationMarginRefreshModelingPass,
) -> Array[String] {
  let ids : Array[String] = []
  for result in pass.refresh_results {
    if !result.refreshed {
      ids.push(result.margin_id)
    }
  }
  ids
}

///|
fn refresh_projection_reason(
  may_consume : Bool,
  pass : RemediationMarginRefreshModelingPass,
) -> String {
  if may_consume {
    "refresh simulation-consume projection: all remediation-margin refreshes cleared by \{pass.modeling_pass_id}; hardware authority remains \{pass.hardware_authority}"
  } else {
    "no-consume refresh projection: \{pass.still_blocking_count} remediation-margin refreshes still block simulation consumption from \{remediation_margin_refresh_modeling_state_label(pass.state)}; hardware authority remains \{pass.hardware_authority}"
  }
}

///|
fn refresh_projection_next_action(
  may_consume : Bool,
  pass : RemediationMarginRefreshModelingPass,
) -> String {
  if may_consume {
    "regenerate simulation review evidence from accepted terrain, local-horizon, and energy refreshes while preserving HardwareDenied authority"
  } else {
    "do not let MoonRobo consume refreshed simulation evidence for \{pass.route_id}; regenerate terrain, local-horizon, and energy refresh evidence before changing simulation state"
  }
}

///|
pub fn remediation_margin_refresh_projection(
  pass : RemediationMarginRefreshModelingPass,
  source_modeling_path : String,
) -> RemediationMarginRefreshProjection {
  let refresh_blockers = blocking_refresh_ids(pass)
  let may_consume = refresh_blockers.length() == 0 &&
    pass.refreshed_count == pass.refresh_action_count &&
    pass.hardware_denied &&
    pass.hardware_state == HardwareDenied
  {
    projection_id: "moonrobo/\{pass.site_id}/remediation-margin-v1/refresh-projection",
    site_id: pass.site_id,
    route_id: pass.route_id,
    source_modeling_pass_id: pass.modeling_pass_id,
    source_modeling_path,
    source_modeling_state: pass.state,
    source_receipt_id: pass.source_receipt_id,
    source_task_id: pass.source_task_id,
    source_projection_id: pass.source_projection_id,
    may_consume_simulation: may_consume,
    projection_status: if may_consume {
      RefreshSimulationConsumeAllowed
    } else {
      NoConsumeRefreshSimulationBlocked
    },
    simulation_state: if may_consume {
      SimulationNeedsReview
    } else {
      SimulationBlocked
    },
    refresh_action_count: pass.refresh_action_count,
    refreshed_count: pass.refreshed_count,
    still_blocking_count: pass.still_blocking_count,
    consumed_refresh_result_ids: consumed_refresh_result_ids(pass),
    blocking_refresh_ids: refresh_blockers,
    blocking_margin_ids: refresh_projection_blocking_margin_ids(pass),
    hardware_state: pass.hardware_state,
    hardware_authority: pass.hardware_authority,
    hardware_denied: pass.hardware_denied,
    reason: refresh_projection_reason(may_consume, pass),
    next_action: refresh_projection_next_action(may_consume, pass),
  }
}

///|
pub fn first_trusted_square_remediation_margin_refresh_projection() -> RemediationMarginRefreshProjection {
  remediation_margin_refresh_projection(
    first_trusted_square_remediation_margin_refresh_modeling_pass(),
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json",
  )
}

///|
pub fn render_remediation_margin_refresh_projection_markdown(
  projection : RemediationMarginRefreshProjection,
) -> String {
  let mut text = "# MoonRobo Remediation Margin Refresh Projection\n\n"
  text += "- projection: \{projection.projection_id}\n"
  text += "- route: \{projection.route_id}\n"
  text += "- source modeling pass: \{projection.source_modeling_pass_id}\n"
  text += "- source modeling path: \{projection.source_modeling_path}\n"
  text += "- source modeling state: \{remediation_margin_refresh_modeling_state_label(projection.source_modeling_state)}\n"
  text += "- source receipt: \{projection.source_receipt_id}\n"
  text += "- source task: \{projection.source_task_id}\n"
  text += "- source projection: \{projection.source_projection_id}\n"
  text += "- status: \{remediation_margin_refresh_projection_status_label(projection.projection_status)}\n"
  text += "- may consume simulation: \{projection.may_consume_simulation}\n"
  text += "- simulation state: \{execution_state_label(projection.simulation_state)}\n"
  text += "- refresh actions: \{projection.refresh_action_count}\n"
  text += "- refreshed: \{projection.refreshed_count}\n"
  text += "- still blocking: \{projection.still_blocking_count}\n"
  text += "- hardware state: \{execution_state_label(projection.hardware_state)}\n"
  text += "- hardware authority: \{projection.hardware_authority}\n"
  text += "- hardware denied: \{projection.hardware_denied}\n"
  text += "- reason: \{projection.reason}\n"
  text += "- next action: \{projection.next_action}\n\n"
  text += "## Consumed Refresh Results\n\n"
  for refresh_id in projection.consumed_refresh_result_ids {
    text += "- \{refresh_id}\n"
  }
  text += "\n## Blocking Refreshes\n\n"
  for refresh_id in projection.blocking_refresh_ids {
    text += "- \{refresh_id}\n"
  }
  text += "\n## Blocking Margins\n\n"
  for margin_id in projection.blocking_margin_ids {
    text += "- \{margin_id}\n"
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_refresh_projection_markdown() -> String {
  render_remediation_margin_refresh_projection_markdown(
    first_trusted_square_remediation_margin_refresh_projection(),
  )
}

///|
pub fn remediation_margin_refresh_projection_json(
  projection : RemediationMarginRefreshProjection,
) -> Json {
  projection.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_refresh_projection_json() -> Json {
  remediation_margin_refresh_projection_json(
    first_trusted_square_remediation_margin_refresh_projection(),
  )
}
