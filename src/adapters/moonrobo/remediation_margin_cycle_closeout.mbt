///|
pub(all) enum RemediationMarginCycleCloseoutStatus {
  NoConsumeCycleClosedForPolicy
  CycleReadyForSimulationReview
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum RemediationMarginCycleDisposition {
  RetryWithNewEvidence
  EscalateToOperatorDecision
  FreezeUntilNewSourceEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginCycleCloseoutItem {
  margin_id : String
  refresh_id : String
  blocker_domain : String
  attempt_count : Int
  disposition : RemediationMarginCycleDisposition
  required_evidence : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RemediationMarginCycleCloseoutPolicy {
  policy_id : String
  site_id : @core.SiteId
  route_id : String
  source_refresh_projection_id : String
  source_refresh_projection_status : RemediationMarginRefreshProjectionStatus
  source_refresh_projection_path : String
  source_followup_projection_id : String
  source_followup_projection_status : RemediationMarginRefreshFollowupProjectionStatus
  source_followup_projection_path : String
  may_consume_simulation : Bool
  simulation_state : MoonroboExecutionState
  closeout_status : RemediationMarginCycleCloseoutStatus
  refresh_cycle_count : Int
  blocker_count : Int
  blocking_refresh_ids : Array[String]
  blocking_margin_ids : Array[String]
  dispositions : Array[RemediationMarginCycleCloseoutItem]
  hardware_state : MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  reason : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn remediation_margin_cycle_closeout_status_label(
  status : RemediationMarginCycleCloseoutStatus,
) -> String {
  match status {
    NoConsumeCycleClosedForPolicy => "NoConsumeCycleClosedForPolicy"
    CycleReadyForSimulationReview => "CycleReadyForSimulationReview"
  }
}

///|
pub fn remediation_margin_cycle_disposition_label(
  disposition : RemediationMarginCycleDisposition,
) -> String {
  match disposition {
    RetryWithNewEvidence => "RetryWithNewEvidence"
    EscalateToOperatorDecision => "EscalateToOperatorDecision"
    FreezeUntilNewSourceEvidence => "FreezeUntilNewSourceEvidence"
  }
}

///|
fn cycle_blocker_domain(margin_id : String) -> String {
  if margin_id.contains("terrain") {
    "terrain"
  } else if margin_id.contains("illumination") {
    "local-horizon"
  } else {
    "energy"
  }
}

///|
fn cycle_disposition(margin_id : String) -> RemediationMarginCycleDisposition {
  if margin_id.contains("terrain") {
    EscalateToOperatorDecision
  } else if margin_id.contains("illumination") {
    RetryWithNewEvidence
  } else {
    FreezeUntilNewSourceEvidence
  }
}

///|
fn cycle_required_evidence(margin_id : String) -> String {
  if margin_id.contains("terrain") {
    "operator-reviewed DEM slope and roughness evidence before another terrain refresh"
  } else if margin_id.contains("illumination") {
    "new local-horizon or ephemeris evidence before retrying the horizon refresh"
  } else {
    "new power-window source evidence or rover energy profile before unfreezing energy"
  }
}

///|
fn cycle_item_reason(
  margin_id : String,
  refresh_id : String,
  disposition : RemediationMarginCycleDisposition,
) -> String {
  "\{cycle_blocker_domain(margin_id)} blocker \{margin_id} remains tied to \{refresh_id} after the first refresh and follow-up refresh projections; disposition \{remediation_margin_cycle_disposition_label(disposition)} prevents an unbounded refresh loop"
}

///|
fn cycle_closeout_items(
  projection : RemediationMarginRefreshFollowupProjection,
) -> Array[RemediationMarginCycleCloseoutItem] {
  let items : Array[RemediationMarginCycleCloseoutItem] = []
  for i in 0..<projection.blocking_margin_ids.length() {
    let margin_id = projection.blocking_margin_ids[i]
    let refresh_id = projection.blocking_refresh_ids[i]
    let disposition = cycle_disposition(margin_id)
    items.push({
      margin_id,
      refresh_id,
      blocker_domain: cycle_blocker_domain(margin_id),
      attempt_count: 2,
      disposition,
      required_evidence: cycle_required_evidence(margin_id),
      reason: cycle_item_reason(margin_id, refresh_id, disposition),
    })
  }
  items
}

///|
fn cycle_closeout_reason(
  policy_status : RemediationMarginCycleCloseoutStatus,
  refresh_projection : RemediationMarginRefreshProjection,
  followup_projection : RemediationMarginRefreshFollowupProjection,
) -> String {
  match policy_status {
    CycleReadyForSimulationReview =>
      "remediation-margin refresh cycle is ready for simulation review because first and follow-up projections allow simulation consumption while hardware authority remains \{followup_projection.hardware_authority}"
    NoConsumeCycleClosedForPolicy =>
      "no-consume remediation-margin refresh cycle closed for policy: first projection \{remediation_margin_refresh_projection_status_label(refresh_projection.projection_status)} and follow-up projection \{remediation_margin_refresh_followup_projection_status_label(followup_projection.projection_status)} still leave \{followup_projection.still_blocking_count} terrain/horizon/energy blockers; hardware authority remains \{followup_projection.hardware_authority}"
  }
}

///|
fn cycle_closeout_next_action(
  policy_status : RemediationMarginCycleCloseoutStatus,
) -> String {
  match policy_status {
    CycleReadyForSimulationReview =>
      "route the accepted refresh cycle into simulation review while preserving HardwareDenied authority"
    NoConsumeCycleClosedForPolicy =>
      "stop issuing automatic remediation-margin follow-up refreshes; apply the retry/escalate/freeze dispositions before any new MoonClaw task is emitted"
  }
}

///|
pub fn remediation_margin_cycle_closeout_policy(
  refresh_projection : RemediationMarginRefreshProjection,
  refresh_projection_path : String,
  followup_projection : RemediationMarginRefreshFollowupProjection,
  followup_projection_path : String,
) -> RemediationMarginCycleCloseoutPolicy {
  let may_consume = refresh_projection.may_consume_simulation &&
    followup_projection.may_consume_simulation
  let status = if may_consume {
    CycleReadyForSimulationReview
  } else {
    NoConsumeCycleClosedForPolicy
  }
  {
    policy_id: "moonrobo/\{followup_projection.site_id}/remediation-margin-v1/cycle-closeout-policy",
    site_id: followup_projection.site_id,
    route_id: followup_projection.route_id,
    source_refresh_projection_id: refresh_projection.projection_id,
    source_refresh_projection_status: refresh_projection.projection_status,
    source_refresh_projection_path: refresh_projection_path,
    source_followup_projection_id: followup_projection.projection_id,
    source_followup_projection_status: followup_projection.projection_status,
    source_followup_projection_path: followup_projection_path,
    may_consume_simulation: may_consume,
    simulation_state: if may_consume {
      SimulationNeedsReview
    } else {
      SimulationBlocked
    },
    closeout_status: status,
    refresh_cycle_count: 2,
    blocker_count: followup_projection.still_blocking_count,
    blocking_refresh_ids: followup_projection.blocking_refresh_ids,
    blocking_margin_ids: followup_projection.blocking_margin_ids,
    dispositions: cycle_closeout_items(followup_projection),
    hardware_state: followup_projection.hardware_state,
    hardware_authority: followup_projection.hardware_authority,
    hardware_denied: followup_projection.hardware_denied,
    reason: cycle_closeout_reason(
      status, refresh_projection, followup_projection,
    ),
    next_action: cycle_closeout_next_action(status),
  }
}

///|
pub fn first_trusted_square_remediation_margin_cycle_closeout_policy() -> RemediationMarginCycleCloseoutPolicy {
  remediation_margin_cycle_closeout_policy(
    first_trusted_square_remediation_margin_refresh_projection(),
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
    first_trusted_square_remediation_margin_refresh_followup_projection(),
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
  )
}

///|
pub fn render_remediation_margin_cycle_closeout_policy_markdown(
  policy : RemediationMarginCycleCloseoutPolicy,
) -> String {
  let mut text = "# MoonRobo Remediation Margin Cycle Closeout Policy\n\n"
  text += "- policy: \{policy.policy_id}\n"
  text += "- route: \{policy.route_id}\n"
  text += "- status: \{remediation_margin_cycle_closeout_status_label(policy.closeout_status)}\n"
  text += "- source refresh projection: \{policy.source_refresh_projection_id}\n"
  text += "- source refresh projection status: \{remediation_margin_refresh_projection_status_label(policy.source_refresh_projection_status)}\n"
  text += "- source refresh projection path: \{policy.source_refresh_projection_path}\n"
  text += "- source follow-up projection: \{policy.source_followup_projection_id}\n"
  text += "- source follow-up projection status: \{remediation_margin_refresh_followup_projection_status_label(policy.source_followup_projection_status)}\n"
  text += "- source follow-up projection path: \{policy.source_followup_projection_path}\n"
  text += "- refresh cycles: \{policy.refresh_cycle_count}\n"
  text += "- blocker count: \{policy.blocker_count}\n"
  text += "- may consume simulation: \{policy.may_consume_simulation}\n"
  text += "- simulation state: \{execution_state_label(policy.simulation_state)}\n"
  text += "- hardware state: \{execution_state_label(policy.hardware_state)}\n"
  text += "- hardware authority: \{policy.hardware_authority}\n"
  text += "- hardware denied: \{policy.hardware_denied}\n"
  text += "- reason: \{policy.reason}\n"
  text += "- next action: \{policy.next_action}\n\n"
  text += "## Dispositions\n\n"
  for item in policy.dispositions {
    text += "- \{item.blocker_domain}: \{item.margin_id} / \{item.refresh_id} after \{item.attempt_count} attempts -> \{remediation_margin_cycle_disposition_label(item.disposition)}; required evidence: \{item.required_evidence}\n"
  }
  text += "\n## Blocking Refreshes\n\n"
  for refresh_id in policy.blocking_refresh_ids {
    text += "- \{refresh_id}\n"
  }
  text += "\n## Blocking Margins\n\n"
  for margin_id in policy.blocking_margin_ids {
    text += "- \{margin_id}\n"
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_cycle_closeout_policy_markdown() -> String {
  render_remediation_margin_cycle_closeout_policy_markdown(
    first_trusted_square_remediation_margin_cycle_closeout_policy(),
  )
}

///|
pub fn remediation_margin_cycle_closeout_policy_json(
  policy : RemediationMarginCycleCloseoutPolicy,
) -> Json {
  policy.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_cycle_closeout_policy_json() -> Json {
  remediation_margin_cycle_closeout_policy_json(
    first_trusted_square_remediation_margin_cycle_closeout_policy(),
  )
}
