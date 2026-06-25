///|
pub(all) enum MoonClawCloseoutActionReviewDecision {
  Accept
  RequestEvidence
  Defer
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawCloseoutActionReviewEvidenceRef {
  ref_id : String
  entry_id : String
  path : String
  immutable_uri : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginCloseoutActionReview {
  transition_id : String
  item_id : String
  entry_id : String
  previous_status : MoonClawReceiptStatus
  decision : MoonClawCloseoutActionReviewDecision
  resulting_status : MoonClawReceiptStatus
  reviewer_id : String
  reviewer_role : String
  timestamp_policy : String
  recorded_at_utc : String
  append_only : Bool
  hardware_authority_change : Bool
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  source_evidence_refs : Array[MoonClawCloseoutActionReviewEvidenceRef]
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRemediationMarginReviewedActionPlan {
  plan_id : String
  site_id : @core.SiteId
  route_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  source_task_id : String
  source_review_transition_id : String
  source_review_item_id : String
  source_review_decision : MoonClawCloseoutActionReviewDecision
  reviewer_id : String
  reviewed_at_utc : String
  source_evidence_refs : Array[MoonClawCloseoutActionReviewEvidenceRef]
  may_consume_simulation : Bool
  simulation_state : @moonrobo.MoonroboExecutionState
  refresh_cycle_count : Int
  blocker_count : Int
  blocking_refresh_ids : Array[String]
  blocking_margin_ids : Array[String]
  actions : Array[MoonClawRemediationMarginCloseoutAction]
  automatic_refresh_loop_allowed : Bool
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_authority_change : Bool
  hardware_denied : Bool
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn closeout_action_review_entry_id() -> String {
  "moonclaw/first-trusted-square/remediation-margin-closeout-action-task"
}

///|
fn closeout_action_review_item_id() -> String {
  "moonclaw-remediation-margin-closeout-action-review"
}

///|
pub fn first_trusted_square_closeout_action_review_accept() -> MoonClawRemediationMarginCloseoutActionReview {
  {
    transition_id: "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
    item_id: closeout_action_review_item_id(),
    entry_id: closeout_action_review_entry_id(),
    previous_status: NeedsReview,
    decision: Accept,
    resulting_status: Accepted,
    reviewer_id: "operator/rabbita-closeout-action-review",
    reviewer_role: "moonclaw-closeout-action-review",
    timestamp_policy: "operator-browser-export",
    recorded_at_utc: "2026-06-25T00:00:00Z",
    append_only: true,
    hardware_authority_change: false,
    hardware_state: @moonrobo.MoonroboExecutionState::HardwareDenied,
    hardware_authority: "moonmoon-safety-gate-only",
    source_evidence_refs: [
      {
        ref_id: closeout_action_review_item_id(),
        entry_id: closeout_action_review_entry_id(),
        path: "moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json",
        immutable_uri: "moonbook://moonmoon/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json#moonclaw-remediation-margin-closeout-action-review",
      },
    ],
    rationale: "Rabbita accept decision for moonclaw-remediation-margin-closeout-action-review: terrain escalation, horizon retry-with-new-evidence, and energy freeze actions are operator-reviewed; hardware remains denied",
  }
}

///|
fn review_allows_action_plan(
  review : MoonClawRemediationMarginCloseoutActionReview,
) -> Bool {
  review.item_id == closeout_action_review_item_id() &&
  review.entry_id == closeout_action_review_entry_id() &&
  review.previous_status == NeedsReview &&
  review.decision == Accept &&
  review.resulting_status == Accepted &&
  review.append_only &&
  !review.hardware_authority_change &&
  review.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied &&
  review.hardware_authority == "moonmoon-safety-gate-only"
}

///|
pub fn remediation_margin_reviewed_action_plans_from_review(
  review : MoonClawRemediationMarginCloseoutActionReview,
) -> Array[MoonClawRemediationMarginReviewedActionPlan] {
  if !review_allows_action_plan(review) {
    []
  } else {
    let task = first_trusted_square_remediation_margin_closeout_action_task()
    [
      {
        plan_id: "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan",
        site_id: task.site_id,
        route_id: task.route_id,
        priority: task.priority,
        state: Accepted,
        source_task_id: task.task_id,
        source_review_transition_id: review.transition_id,
        source_review_item_id: review.item_id,
        source_review_decision: review.decision,
        reviewer_id: review.reviewer_id,
        reviewed_at_utc: review.recorded_at_utc,
        source_evidence_refs: review.source_evidence_refs,
        may_consume_simulation: task.may_consume_simulation,
        simulation_state: task.simulation_state,
        refresh_cycle_count: task.refresh_cycle_count,
        blocker_count: task.blocker_count,
        blocking_refresh_ids: task.blocking_refresh_ids,
        blocking_margin_ids: task.blocking_margin_ids,
        actions: task.closeout_actions,
        automatic_refresh_loop_allowed: false,
        hardware_state: task.hardware_state,
        hardware_authority: task.hardware_authority,
        hardware_authority_change: review.hardware_authority_change,
        hardware_denied: task.hardware_denied,
        acceptance_criteria: [
          criterion(
            "accepted-review-required", "Plan is emitted only from an append-only Accept transition for the closeout action task.",
          ),
          criterion(
            "bounded-closeout-actions", "Plan carries terrain escalation, horizon retry-with-new-evidence, and energy freeze actions without opening another automatic refresh loop.",
          ),
          criterion(
            "hardware-denial-preserved", "Hardware state remains HardwareDenied under moonmoon-safety-gate-only with no hardware authority change.",
          ),
        ],
        safety_gate: "Execute only the reviewed closeout actions; do not start an automatic refresh loop, consume simulation, or change MoonRobo hardware authority.",
        next_action: "Schedule the terrain escalation, horizon retry-with-new-evidence, and energy freeze as bounded reviewed work items with fresh evidence attached before any downstream MoonRobo simulation review.",
      },
    ]
  }
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_action_plans() -> Array[
  MoonClawRemediationMarginReviewedActionPlan,
] {
  remediation_margin_reviewed_action_plans_from_review(
    first_trusted_square_closeout_action_review_accept(),
  )
}

///|
pub fn closeout_action_review_decision_label(
  decision : MoonClawCloseoutActionReviewDecision,
) -> String {
  match decision {
    Accept => "Accept"
    RequestEvidence => "RequestEvidence"
    Defer => "Defer"
  }
}

///|
pub fn render_remediation_margin_reviewed_action_plans_markdown(
  plans : Array[MoonClawRemediationMarginReviewedActionPlan],
) -> String {
  let mut text = "# MoonClaw Remediation Margin Reviewed Action Plans\n\n"
  for plan_index, plan in plans {
    text += "- \{plan.plan_id}\n"
    text += "  - priority: \{priority_label(plan.priority)}\n"
    text += "  - state: \{receipt_status_label(plan.state)}\n"
    text += "  - route: \{plan.route_id}\n"
    text += "  - source task: \{plan.source_task_id}\n"
    text += "  - review transition: \{plan.source_review_transition_id}\n"
    text += "  - review decision: \{closeout_action_review_decision_label(plan.source_review_decision)}\n"
    text += "  - reviewer: \{plan.reviewer_id}\n"
    text += "  - reviewed at: \{plan.reviewed_at_utc}\n"
    text += "  - refresh cycles: \{plan.refresh_cycle_count}\n"
    text += "  - blockers: \{plan.blocker_count}\n"
    text += "  - simulation state: \{@moonrobo.execution_state_label(plan.simulation_state)}\n"
    text += "  - may consume simulation: \{plan.may_consume_simulation}\n"
    text += "  - automatic refresh loop allowed: \{plan.automatic_refresh_loop_allowed}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(plan.hardware_state)}\n"
    text += "  - hardware authority: \{plan.hardware_authority}\n"
    text += "  - hardware authority change: \{plan.hardware_authority_change}\n"
    text += "  - safety gate: \{plan.safety_gate}\n"
    text += "  - next action: \{plan.next_action}\n"
    text += "  - source evidence:\n"
    for evidence_ref in plan.source_evidence_refs {
      text += "    - \{evidence_ref.ref_id}: \{evidence_ref.immutable_uri}\n"
    }
    text += "  - actions:\n"
    for action in plan.actions {
      text += "    - \{action.rank}. \{action.action_id}: \{action.margin_id} / \{action.refresh_id}\n"
      text += "      - disposition: \{@moonrobo.remediation_margin_cycle_disposition_label(action.disposition)}\n"
      text += "      - required evidence: \{action.required_evidence}\n"
      text += "      - target: \{action.target_artifact_path}\n"
      text += "      - command: \{action.command}\n"
      text += "      - check: \{action.acceptance_check}\n"
    }
    text += "  - acceptance:\n"
    for acceptance_index, acceptance in plan.acceptance_criteria {
      text += "    - \{acceptance.criterion_id}: \{acceptance.description}"
      if acceptance_index + 1 < plan.acceptance_criteria.length() ||
        plan_index + 1 < plans.length() {
        text += "\n"
      }
    }
  }
  text
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_action_plans_markdown() -> String {
  render_remediation_margin_reviewed_action_plans_markdown(
    first_trusted_square_remediation_margin_reviewed_action_plans(),
  )
}

///|
pub fn render_remediation_margin_reviewed_action_plans_json(
  plans : Array[MoonClawRemediationMarginReviewedActionPlan],
) -> Json {
  plans.to_json()
}

///|
pub fn first_trusted_square_remediation_margin_reviewed_action_plans_json() -> Json {
  render_remediation_margin_reviewed_action_plans_json(
    first_trusted_square_remediation_margin_reviewed_action_plans(),
  )
}
