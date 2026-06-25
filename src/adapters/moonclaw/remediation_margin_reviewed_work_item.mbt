///|
pub(all) struct MoonClawRemediationMarginReviewedWorkItem {
  work_item_id : String
  plan_id : String
  site_id : @core.SiteId
  route_id : String
  rank : Int
  state : MoonClawReceiptStatus
  margin_id : String
  refresh_id : String
  blocker_domain : String
  disposition : @moonrobo.RemediationMarginCycleDisposition
  required_evidence : String
  target_artifact_path : String
  command : String
  acceptance_check : String
  source_review_transition_id : String
  source_review_decision : MoonClawCloseoutActionReviewDecision
  reviewer_id : String
  reviewed_at_utc : String
  may_consume_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  automatic_refresh_loop_allowed : Bool
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn reviewed_work_item(
  plan : MoonClawRemediationMarginReviewedActionPlan,
  action : MoonClawRemediationMarginCloseoutAction,
) -> MoonClawRemediationMarginReviewedWorkItem {
  {
    work_item_id: "\{plan.plan_id}/work-item-\{action.rank}-\{action.margin_id}",
    plan_id: plan.plan_id,
    site_id: plan.site_id,
    route_id: plan.route_id,
    rank: action.rank,
    state: Accepted,
    margin_id: action.margin_id,
    refresh_id: action.refresh_id,
    blocker_domain: action.blocker_domain,
    disposition: action.disposition,
    required_evidence: action.required_evidence,
    target_artifact_path: action.target_artifact_path,
    command: action.command,
    acceptance_check: action.acceptance_check,
    source_review_transition_id: plan.source_review_transition_id,
    source_review_decision: plan.source_review_decision,
    reviewer_id: plan.reviewer_id,
    reviewed_at_utc: plan.reviewed_at_utc,
    may_consume_simulation: plan.may_consume_simulation,
    simulation_state: plan.simulation_state,
    automatic_refresh_loop_allowed: plan.automatic_refresh_loop_allowed,
    hardware_state: plan.hardware_state,
    hardware_authority: plan.hardware_authority,
    hardware_authority_change: plan.hardware_authority_change,
    hardware_denied: plan.hardware_denied,
    safety_gate: "Execute this reviewed work item only as part of the accepted remediation-margin action plan; do not start an automatic refresh loop, consume simulation, or change MoonRobo hardware authority.",
    next_action: "Run or schedule \{action.command} and verify \{action.acceptance_check} before any downstream MoonRobo simulation review.",
  }
}

///|
pub fn remediation_margin_reviewed_work_items_from_plans(
  plans : Array[MoonClawRemediationMarginReviewedActionPlan],
) -> Array[MoonClawRemediationMarginReviewedWorkItem] {
  let items : Array[MoonClawRemediationMarginReviewedWorkItem] = []
  for plan in plans {
    if plan.state == Accepted &&
      !plan.may_consume_simulation &&
      !plan.automatic_refresh_loop_allowed &&
      !plan.hardware_authority_change &&
      plan.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied {
      for action in plan.actions {
        items.push(reviewed_work_item(plan, action))
      }
    }
  }
  items
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_work_items() -> Array[
  MoonClawRemediationMarginReviewedWorkItem,
] {
  remediation_margin_reviewed_work_items_from_plans(
    first_trusted_square_remediation_margin_reviewed_action_plans(),
  )
}

///|
pub fn render_remediation_margin_reviewed_work_items_markdown(
  items : Array[MoonClawRemediationMarginReviewedWorkItem],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Reviewed Work Items\n\n"
  for item_index, item in items {
    text += "- \{item.work_item_id}\n"
    text += "  - state: \{receipt_status_label(item.state)}\n"
    text += "  - plan: \{item.plan_id}\n"
    text += "  - route: \{item.route_id}\n"
    text += "  - rank: \{item.rank}\n"
    text += "  - margin: \{item.margin_id}\n"
    text += "  - refresh: \{item.refresh_id}\n"
    text += "  - blocker domain: \{item.blocker_domain}\n"
    text += "  - disposition: \{@moonrobo.remediation_margin_cycle_disposition_label(item.disposition)}\n"
    text += "  - required evidence: \{item.required_evidence}\n"
    text += "  - target: \{item.target_artifact_path}\n"
    text += "  - command: \{item.command}\n"
    text += "  - check: \{item.acceptance_check}\n"
    text += "  - review transition: \{item.source_review_transition_id}\n"
    text += "  - review decision: \{closeout_action_review_decision_label(item.source_review_decision)}\n"
    text += "  - reviewer: \{item.reviewer_id}\n"
    text += "  - reviewed at: \{item.reviewed_at_utc}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(item.simulation_state)}\n"
    text += "  - may consume simulation: \{item.may_consume_simulation}\n"
    text += "  - automatic refresh loop allowed: \{item.automatic_refresh_loop_allowed}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(item.hardware_state)}\n"
    text += "  - hardware authority: \{item.hardware_authority}\n"
    text += "  - hardware authority change: \{item.hardware_authority_change}\n"
    text += "  - safety gate: \{item.safety_gate}\n"
    text += "  - next action: \{item.next_action}"
    if item_index + 1 < items.length() {
      text += "\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_work_items_markdown() -> String {
  render_remediation_margin_reviewed_work_items_markdown(
    first_trusted_square_remediation_margin_reviewed_work_items(),
  )
}

///|
pub fn render_remediation_margin_reviewed_work_items_json(
  items : Array[MoonClawRemediationMarginReviewedWorkItem],
) -> Json {
  items.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_work_items_json() -> Json {
  render_remediation_margin_reviewed_work_items_json(
    first_trusted_square_remediation_margin_reviewed_work_items(),
  )
}
