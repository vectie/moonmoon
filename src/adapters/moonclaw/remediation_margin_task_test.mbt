///|
test "first trusted square remediation margin task preserves active blockers" {
  let task = @moonclaw.first_trusted_square_remediation_margin_task()
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/task",
  )
  assert_eq(task.route_id, "northeast-stepout")
  assert_true(task.priority == @moonclaw.MoonClawJobPriority::Critical)
  assert_true(task.state == @moonclaw.MoonClawReceiptStatus::Accepted)
  assert_eq(task.active_margin_count, 3)
  assert_true(task.active_margin_ids.contains("terrain-northeast-stepout"))
  assert_true(task.active_margin_ids.contains("illumination-northeast-stepout"))
  assert_true(task.active_margin_ids.contains("energy-window"))
  assert_true(
    task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(task.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(task.hardware_denied)
  assert_eq(task.artifacts.length(), 3)
  assert_eq(@moonclaw.remediation_margin_task_blocked_artifact_count(task), 3)
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "terrain-northeast-stepout" &&
      !artifact.ready &&
      artifact.current_state.contains("grade margin")
    }),
  )
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "illumination-northeast-stepout" &&
      !artifact.ready &&
      artifact.current_state.contains("terrain-shadow margin")
    }),
  )
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "energy-window" &&
      !artifact.ready &&
      artifact.current_state.contains("margin gap")
    }),
  )
  assert_true(
    task.commands.contains(
      "python3 scripts/check_moonclaw_remediation_margin_task.py",
    ),
  )
}

///|
test "MoonClaw remediation margin task renderers expose margin commands" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_tasks_markdown()
  assert_true(markdown.contains("MoonClaw Remediation Margin Tasks"))
  assert_true(markdown.contains("terrain-northeast-stepout"))
  assert_true(markdown.contains("illumination-northeast-stepout"))
  assert_true(markdown.contains("energy-window"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  assert_true(markdown.contains("ready: false"))
  let json = @moonclaw.first_trusted_square_remediation_margin_tasks_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"active_margin_count\": 3"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
  assert_true(
    json.contains("\"hardware_authority\": \"moonmoon-safety-gate-only\""),
  )
  assert_true(json.contains("\"ready\": false"))
}

///|
test "first trusted square remediation margin receipt carries open margins forward" {
  let receipt = @moonclaw.first_trusted_square_remediation_margin_receipt()
  assert_eq(
    receipt.receipt.receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt",
  )
  assert_eq(
    receipt.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/task",
  )
  assert_eq(receipt.route_id, "northeast-stepout")
  assert_true(
    receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::Accepted,
  )
  assert_true(
    receipt.remediation_state ==
    @moonclaw.MoonClawRemediationMarginState::OpenMarginsCarriedForward,
  )
  assert_eq(receipt.active_margin_count, 3)
  assert_eq(receipt.cleared_margin_count, 0)
  assert_eq(receipt.still_blocking_margin_count, 3)
  assert_true(
    receipt.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(receipt.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(receipt.hardware_denied)
  assert_eq(receipt.margin_results.length(), 3)
  assert_true(
    receipt.margin_results.all(fn(result) {
      result.status ==
      @moonclaw.MoonClawRemediationMarginResultStatus::StillBlocking &&
      result.evidence_path != ""
    }),
  )
  assert_true(
    receipt.margin_results.any(fn(result) {
      result.margin_id == "terrain-northeast-stepout" &&
      result.current_state.contains("grade margin")
    }),
  )
  assert_true(
    receipt.margin_results.any(fn(result) {
      result.margin_id == "illumination-northeast-stepout" &&
      result.current_state.contains("terrain-shadow margin")
    }),
  )
  assert_true(
    receipt.margin_results.any(fn(result) {
      result.margin_id == "energy-window" &&
      result.current_state.contains("margin gap")
    }),
  )
  assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("hardware-denial-preserved: pass")
    }),
  )
}

///|
test "MoonClaw remediation margin receipt renderers expose state and authority" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_receipts_markdown()
  assert_true(markdown.contains("MoonClaw Remediation Margin Receipts"))
  assert_true(markdown.contains("OpenMarginsCarriedForward"))
  assert_true(markdown.contains("still blocking margins: 3"))
  assert_true(markdown.contains("terrain-northeast-stepout: StillBlocking"))
  assert_true(
    markdown.contains("illumination-northeast-stepout: StillBlocking"),
  )
  assert_true(markdown.contains("energy-window: StillBlocking"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  let json = @moonclaw.first_trusted_square_remediation_margin_receipts_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains("\"remediation_state\": \"OpenMarginsCarriedForward\""),
  )
  assert_true(json.contains("\"still_blocking_margin_count\": 3"))
  assert_true(json.contains("\"status\": \"StillBlocking\""))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}

///|
test "first trusted square remediation margin refresh task consumes projection" {
  let task = @moonclaw.first_trusted_square_remediation_margin_refresh_task()
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task",
  )
  assert_eq(
    task.source_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/projection",
  )
  assert_eq(
    task.source_projection_path,
    "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
  )
  assert_eq(
    task.source_modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass",
  )
  assert_true(
    task.source_projection_status ==
    @moonrobo.RemediationMarginProjectionStatus::NoConsumeSimulationBlocked,
  )
  assert_true(
    task.source_simulation_state ==
    @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(!task.may_consume_simulation)
  assert_eq(task.blocking_margin_count, 3)
  assert_eq(task.refresh_actions.length(), 3)
  assert_eq(task.ranked_margin_ids[0], "terrain-northeast-stepout")
  assert_eq(task.ranked_margin_ids[1], "illumination-northeast-stepout")
  assert_eq(task.ranked_margin_ids[2], "energy-window")
  assert_eq(task.refresh_actions[0].rank, 1)
  assert_eq(task.refresh_actions[1].rank, 2)
  assert_eq(task.refresh_actions[2].rank, 3)
  assert_true(
    task.refresh_actions[0].command.contains(
      "generate_selected_route_terrain_remediation.py --check",
    ),
  )
  assert_true(
    task.refresh_actions[1].acceptance_check.contains(
      "check_selected_route_horizon_model.py",
    ),
  )
  assert_true(
    task.refresh_actions[2].target_artifact_path.contains(
      "first_trusted_square_energy_remediation.json",
    ),
  )
  assert_true(
    task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(task.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(task.hardware_denied)
}

///|
test "MoonClaw remediation margin refresh renderers expose no-consume task" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_refresh_tasks_markdown()
  assert_true(markdown.contains("MoonClaw Remediation Margin Refresh Tasks"))
  assert_true(markdown.contains("NoConsumeSimulationBlocked"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("terrain-northeast-stepout"))
  assert_true(markdown.contains("illumination-northeast-stepout"))
  assert_true(markdown.contains("energy-window"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  let json = @moonclaw.first_trusted_square_remediation_margin_refresh_tasks_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"task_id\": \"moonclaw/first-trusted-square/remediation-margin-v1/refresh-task\"",
    ),
  )
  assert_true(
    json.contains(
      "\"source_projection_status\": \"NoConsumeSimulationBlocked\"",
    ),
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}

///|
test "first trusted square remediation margin refresh follow-up consumes refresh projection" {
  let task = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_task()
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
  )
  assert_eq(
    task.source_refresh_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
  )
  assert_eq(
    task.source_refresh_projection_path,
    "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
  )
  assert_eq(
    task.source_modeling_pass_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass",
  )
  assert_true(
    task.source_modeling_state ==
    @moonrobo.RemediationMarginRefreshModelingState::AllRefreshesStillBlocking,
  )
  assert_true(
    task.source_projection_status ==
    @moonrobo.RemediationMarginRefreshProjectionStatus::NoConsumeRefreshSimulationBlocked,
  )
  assert_true(
    task.source_simulation_state ==
    @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(!task.may_consume_simulation)
  assert_eq(task.blocking_refresh_count, 3)
  assert_eq(task.blocking_refresh_ids[0], "refresh-terrain-northeast-stepout")
  assert_eq(
    task.blocking_refresh_ids[1],
    "refresh-illumination-northeast-stepout",
  )
  assert_eq(task.blocking_refresh_ids[2], "refresh-energy-window")
  assert_eq(task.blocking_margin_ids[0], "terrain-northeast-stepout")
  assert_eq(task.blocking_margin_ids[1], "illumination-northeast-stepout")
  assert_eq(task.blocking_margin_ids[2], "energy-window")
  assert_eq(task.followup_actions.length(), 3)
  assert_eq(task.followup_actions[0].rank, 1)
  assert_eq(task.followup_actions[1].rank, 2)
  assert_eq(task.followup_actions[2].rank, 3)
  assert_true(
    task.followup_actions[0].refresh_id == "refresh-terrain-northeast-stepout",
  )
  assert_true(
    task.followup_actions[1].acceptance_check.contains(
      "check_selected_route_horizon_model.py",
    ),
  )
  assert_true(
    task.followup_actions[2].target_artifact_path.contains(
      "first_trusted_square_energy_remediation.json",
    ),
  )
  assert_true(
    task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(task.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(task.hardware_denied)
}

///|
test "MoonClaw remediation margin refresh follow-up renderers expose no-consume projection" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_tasks_markdown()
  assert_true(
    markdown.contains("MoonClaw Remediation Margin Refresh Follow-Up Tasks"),
  )
  assert_true(markdown.contains("NoConsumeRefreshSimulationBlocked"))
  assert_true(markdown.contains("AllRefreshesStillBlocking"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("refresh-terrain-northeast-stepout"))
  assert_true(markdown.contains("refresh-illumination-northeast-stepout"))
  assert_true(markdown.contains("refresh-energy-window"))
  assert_true(markdown.contains("terrain-northeast-stepout"))
  assert_true(markdown.contains("illumination-northeast-stepout"))
  assert_true(markdown.contains("energy-window"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  let json = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_tasks_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"task_id\": \"moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task\"",
    ),
  )
  assert_true(
    json.contains(
      "\"source_projection_status\": \"NoConsumeRefreshSimulationBlocked\"",
    ),
  )
  assert_true(
    json.contains("\"source_modeling_state\": \"AllRefreshesStillBlocking\""),
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}

///|
test "first trusted square remediation margin closeout action task consumes policy" {
  let task = @moonclaw.first_trusted_square_remediation_margin_closeout_action_task()
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task",
  )
  assert_eq(
    task.source_policy_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy",
  )
  assert_eq(
    task.source_policy_path,
    "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json",
  )
  assert_true(
    task.source_closeout_status ==
    @moonrobo.RemediationMarginCycleCloseoutStatus::NoConsumeCycleClosedForPolicy,
  )
  assert_true(
    task.source_refresh_projection_status ==
    @moonrobo.RemediationMarginRefreshProjectionStatus::NoConsumeRefreshSimulationBlocked,
  )
  assert_true(
    task.source_followup_projection_status ==
    @moonrobo.RemediationMarginRefreshFollowupProjectionStatus::NoConsumeFollowupRefreshSimulationBlocked,
  )
  assert_true(task.state == @moonclaw.MoonClawReceiptStatus::NeedsReview)
  assert_true(!task.may_consume_simulation)
  assert_true(
    task.simulation_state == @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_eq(task.refresh_cycle_count, 2)
  assert_eq(task.blocker_count, 3)
  assert_eq(task.blocking_refresh_ids[0], "refresh-terrain-northeast-stepout")
  assert_eq(
    task.blocking_refresh_ids[1],
    "refresh-illumination-northeast-stepout",
  )
  assert_eq(task.blocking_refresh_ids[2], "refresh-energy-window")
  assert_eq(task.blocking_margin_ids[0], "terrain-northeast-stepout")
  assert_eq(task.blocking_margin_ids[1], "illumination-northeast-stepout")
  assert_eq(task.blocking_margin_ids[2], "energy-window")
  assert_eq(task.closeout_actions.length(), 3)
  assert_true(
    task.closeout_actions[0].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision,
  )
  assert_true(task.closeout_actions[0].command.contains("manual: review DEM"))
  assert_true(
    task.closeout_actions[1].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence,
  )
  assert_true(
    task.closeout_actions[1].command.contains(
      "generate_selected_route_horizon.py --check",
    ),
  )
  assert_true(
    task.closeout_actions[2].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence,
  )
  assert_true(
    task.closeout_actions[2].command.contains(
      "manual: keep energy-window frozen",
    ),
  )
  assert_true(
    task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(task.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(task.hardware_denied)
}

///|
test "MoonClaw remediation margin closeout action renderers expose bounded actions" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_closeout_action_tasks_markdown()
  assert_true(
    markdown.contains("MoonClaw Remediation Margin Closeout Action Tasks"),
  )
  assert_true(markdown.contains("NoConsumeCycleClosedForPolicy"))
  assert_true(markdown.contains("NoConsumeRefreshSimulationBlocked"))
  assert_true(markdown.contains("NoConsumeFollowupRefreshSimulationBlocked"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("needs-review"))
  assert_true(markdown.contains("EscalateToOperatorDecision"))
  assert_true(markdown.contains("RetryWithNewEvidence"))
  assert_true(markdown.contains("FreezeUntilNewSourceEvidence"))
  assert_true(markdown.contains("manual: review DEM"))
  assert_true(markdown.contains("generate_selected_route_horizon.py --check"))
  assert_true(markdown.contains("manual: keep energy-window frozen"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  let json = @moonclaw.first_trusted_square_remediation_margin_closeout_action_tasks_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"task_id\": \"moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task\"",
    ),
  )
  assert_true(
    json.contains(
      "\"source_closeout_status\": \"NoConsumeCycleClosedForPolicy\"",
    ),
  )
  assert_true(json.contains("\"state\": \"NeedsReview\""))
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}

///|
test "first trusted square reviewed action plan requires accepted closeout review" {
  let review = @moonclaw.first_trusted_square_closeout_action_review_accept()
  let plans = @moonclaw.remediation_margin_reviewed_action_plans_from_review(
    review,
  )
  assert_eq(plans.length(), 1)
  let plan = plans[0]
  assert_eq(
    plan.plan_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan",
  )
  assert_eq(
    plan.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task",
  )
  assert_eq(
    plan.source_review_transition_id,
    "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
  )
  assert_true(
    plan.source_review_decision ==
    @moonclaw.MoonClawCloseoutActionReviewDecision::Accept,
  )
  assert_true(plan.state == @moonclaw.MoonClawReceiptStatus::Accepted)
  assert_true(!plan.may_consume_simulation)
  assert_true(
    plan.simulation_state == @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_eq(plan.refresh_cycle_count, 2)
  assert_eq(plan.blocker_count, 3)
  assert_eq(plan.actions.length(), 3)
  assert_true(
    plan.actions[0].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision,
  )
  assert_true(
    plan.actions[1].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence,
  )
  assert_true(
    plan.actions[2].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence,
  )
  assert_true(!plan.automatic_refresh_loop_allowed)
  assert_true(
    plan.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(plan.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(!plan.hardware_authority_change)
  assert_true(plan.hardware_denied)

  let request_evidence_review : @moonclaw.MoonClawRemediationMarginCloseoutActionReview = {
    transition_id: "rabbita-moonclaw-remediation-margin-closeout-action-review-request-evidence",
    item_id: review.item_id,
    entry_id: review.entry_id,
    previous_status: review.previous_status,
    decision: @moonclaw.MoonClawCloseoutActionReviewDecision::RequestEvidence,
    resulting_status: @moonclaw.MoonClawReceiptStatus::NeedsReview,
    reviewer_id: review.reviewer_id,
    reviewer_role: review.reviewer_role,
    timestamp_policy: review.timestamp_policy,
    recorded_at_utc: review.recorded_at_utc,
    append_only: review.append_only,
    hardware_authority_change: review.hardware_authority_change,
    hardware_state: review.hardware_state,
    hardware_authority: review.hardware_authority,
    source_evidence_refs: review.source_evidence_refs,
    rationale: "request more evidence before action planning",
  }
  assert_eq(
    @moonclaw.remediation_margin_reviewed_action_plans_from_review(
      request_evidence_review,
    ).length(),
    0,
  )
}

///|
test "MoonClaw reviewed remediation margin action plan renderers expose accepted reviewed work" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_reviewed_action_plans_markdown()
  assert_true(
    markdown.contains("MoonClaw Remediation Margin Reviewed Action Plans"),
  )
  assert_true(markdown.contains("reviewed-action-plan"))
  assert_true(markdown.contains("review decision: Accept"))
  assert_true(markdown.contains("accepted"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("automatic refresh loop allowed: false"))
  assert_true(markdown.contains("hardware-denied"))
  assert_true(markdown.contains("hardware authority change: false"))
  assert_true(markdown.contains("EscalateToOperatorDecision"))
  assert_true(markdown.contains("RetryWithNewEvidence"))
  assert_true(markdown.contains("FreezeUntilNewSourceEvidence"))
  assert_true(markdown.contains("manual: review DEM"))
  assert_true(markdown.contains("generate_selected_route_horizon.py --check"))
  assert_true(markdown.contains("manual: keep energy-window frozen"))
  assert_true(markdown.contains("accepted-review-required"))
  let json = @moonclaw.first_trusted_square_remediation_margin_reviewed_action_plans_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"plan_id\": \"moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan\"",
    ),
  )
  assert_true(json.contains("\"source_review_decision\": \"Accept\""))
  assert_true(json.contains("\"state\": \"Accepted\""))
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"automatic_refresh_loop_allowed\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
  assert_true(json.contains("\"hardware_authority_change\": false"))
}

///|
test "first trusted square reviewed work items split accepted action plan" {
  let items = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_items()
  assert_eq(items.length(), 3)
  assert_eq(items[0].rank, 1)
  assert_eq(items[0].margin_id, "terrain-northeast-stepout")
  assert_true(
    items[0].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision,
  )
  assert_true(items[0].command.contains("manual: review DEM"))
  assert_eq(items[1].rank, 2)
  assert_eq(items[1].margin_id, "illumination-northeast-stepout")
  assert_true(
    items[1].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::RetryWithNewEvidence,
  )
  assert_true(
    items[1].command.contains("generate_selected_route_horizon.py --check"),
  )
  assert_eq(items[2].rank, 3)
  assert_eq(items[2].margin_id, "energy-window")
  assert_true(
    items[2].disposition ==
    @moonrobo.RemediationMarginCycleDisposition::FreezeUntilNewSourceEvidence,
  )
  assert_true(items[2].command.contains("manual: keep energy-window frozen"))
  for item in items {
    assert_true(item.state == @moonclaw.MoonClawReceiptStatus::Accepted)
    assert_eq(
      item.plan_id,
      "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan",
    )
    assert_eq(
      item.source_review_transition_id,
      "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
    )
    assert_true(
      item.source_review_decision ==
      @moonclaw.MoonClawCloseoutActionReviewDecision::Accept,
    )
    assert_true(!item.may_consume_simulation)
    assert_true(!item.automatic_refresh_loop_allowed)
    assert_true(!item.hardware_authority_change)
    assert_true(
      item.simulation_state ==
      @moonrobo.MoonroboExecutionState::SimulationBlocked,
    )
    assert_true(
      item.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
    )
    assert_eq(item.hardware_authority, "moonmoon-safety-gate-only")
    assert_true(item.hardware_denied)
  }
}

///|
test "MoonClaw reviewed remediation margin work item renderers expose safety invariants" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_items_markdown()
  assert_true(
    markdown.contains("MoonClaw Remediation Margin Reviewed Work Items"),
  )
  assert_true(markdown.contains("work-item-1-terrain-northeast-stepout"))
  assert_true(markdown.contains("work-item-2-illumination-northeast-stepout"))
  assert_true(markdown.contains("work-item-3-energy-window"))
  assert_true(markdown.contains("review decision: Accept"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("automatic refresh loop allowed: false"))
  assert_true(markdown.contains("hardware authority change: false"))
  assert_true(markdown.contains("moonmoon-safety-gate-only"))
  assert_true(markdown.contains("hardware-denied"))
  assert_true(markdown.contains("EscalateToOperatorDecision"))
  assert_true(markdown.contains("RetryWithNewEvidence"))
  assert_true(markdown.contains("FreezeUntilNewSourceEvidence"))
  let json = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_items_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"work_item_id\": \"moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout\"",
    ),
  )
  assert_true(json.contains("\"source_review_decision\": \"Accept\""))
  assert_true(json.contains("\"state\": \"Accepted\""))
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"automatic_refresh_loop_allowed\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
  assert_true(json.contains("\"hardware_authority_change\": false"))
}

///|
test "first trusted square reviewed work item receipts carry pending fresh evidence" {
  let receipts = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_item_receipts()
  assert_eq(receipts.length(), 3)
  assert_eq(
    receipts[0].receipt.receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout/receipt",
  )
  assert_eq(
    receipts[1].receipt.receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-2-illumination-northeast-stepout/receipt",
  )
  assert_eq(
    receipts[2].receipt.receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-3-energy-window/receipt",
  )
  for receipt in receipts {
    assert_true(
      receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::Accepted,
    )
    assert_true(
      receipt.result_state ==
      @moonclaw.MoonClawRemediationMarginReviewedWorkItemReceiptState::ReviewedWorkItemsCarriedForward,
    )
    assert_true(
      receipt.work_item_result.status ==
      @moonclaw.MoonClawRemediationMarginReviewedWorkItemResultStatus::ReviewedWorkItemPendingFreshEvidence,
    )
    assert_eq(
      receipt.source_plan_id,
      "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan",
    )
    assert_eq(
      receipt.source_review_transition_id,
      "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
    )
    assert_true(
      receipt.source_review_decision ==
      @moonclaw.MoonClawCloseoutActionReviewDecision::Accept,
    )
    assert_true(!receipt.may_consume_simulation)
    assert_true(!receipt.automatic_refresh_loop_allowed)
    assert_true(!receipt.hardware_authority_change)
    assert_true(
      receipt.simulation_state ==
      @moonrobo.MoonroboExecutionState::SimulationBlocked,
    )
    assert_true(
      receipt.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
    )
    assert_eq(receipt.hardware_authority, "moonmoon-safety-gate-only")
    assert_true(receipt.hardware_denied)
    assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  }
}

///|
test "MoonClaw reviewed remediation margin work item receipt renderers expose accounting" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_item_receipts_markdown()
  assert_true(
    markdown.contains("MoonClaw Remediation Margin Reviewed Work Item Receipts"),
  )
  assert_true(
    markdown.contains("work-item-1-terrain-northeast-stepout/receipt"),
  )
  assert_true(markdown.contains("ReviewedWorkItemPendingFreshEvidence"))
  assert_true(markdown.contains("review decision: Accept"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("automatic refresh loop allowed: false"))
  assert_true(markdown.contains("hardware authority change: false"))
  assert_true(markdown.contains("moonmoon-safety-gate-only"))
  assert_true(markdown.contains("EscalateToOperatorDecision"))
  assert_true(markdown.contains("RetryWithNewEvidence"))
  assert_true(markdown.contains("FreezeUntilNewSourceEvidence"))
  let json = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_item_receipts_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains(
      "\"receipt_id\": \"moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan/work-item-1-terrain-northeast-stepout/receipt\"",
    ),
  )
  assert_true(
    json.contains("\"result_state\": \"ReviewedWorkItemsCarriedForward\""),
  )
  assert_true(
    json.contains("\"status\": \"ReviewedWorkItemPendingFreshEvidence\""),
  )
  assert_true(json.contains("\"source_review_decision\": \"Accept\""))
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"automatic_refresh_loop_allowed\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
  assert_true(json.contains("\"hardware_authority_change\": false"))
}

///|
test "first trusted square reviewed fresh evidence task consumes pending receipts" {
  let tasks = @moonclaw.first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks()
  assert_eq(tasks.length(), 1)
  let task = tasks[0]
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task",
  )
  assert_eq(
    task.source_plan_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan",
  )
  assert_eq(
    task.source_review_transition_id,
    "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
  )
  assert_true(
    task.source_review_decision ==
    @moonclaw.MoonClawCloseoutActionReviewDecision::Accept,
  )
  assert_true(task.state == @moonclaw.MoonClawReceiptStatus::Accepted)
  assert_eq(task.source_receipt_count, 3)
  assert_eq(task.pending_receipt_count, 3)
  assert_eq(task.pending_margin_ids[0], "terrain-northeast-stepout")
  assert_eq(task.pending_margin_ids[1], "illumination-northeast-stepout")
  assert_eq(task.pending_margin_ids[2], "energy-window")
  assert_eq(task.pending_refresh_ids[0], "refresh-terrain-northeast-stepout")
  assert_eq(
    task.pending_refresh_ids[1],
    "refresh-illumination-northeast-stepout",
  )
  assert_eq(task.pending_refresh_ids[2], "refresh-energy-window")
  assert_true(!task.may_consume_simulation)
  assert_true(!task.automatic_refresh_loop_allowed)
  assert_true(!task.hardware_authority_change)
  assert_true(
    task.simulation_state == @moonrobo.MoonroboExecutionState::SimulationBlocked,
  )
  assert_true(
    task.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(task.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(task.hardware_denied)
  assert_eq(task.fresh_evidence_actions.length(), 3)
  assert_true(
    task.fresh_evidence_actions.all(fn(action) {
      action.result_status ==
      @moonclaw.MoonClawRemediationMarginReviewedWorkItemResultStatus::ReviewedWorkItemPendingFreshEvidence &&
      action.source_receipt_id.contains("/receipt") &&
      action.command != "" &&
      action.acceptance_check != "" &&
      action.target_artifact_path != ""
    }),
  )
  assert_true(
    task.fresh_evidence_actions.any(fn(action) {
      action.blocker_domain == "terrain" &&
      action.execution_mode == "operator-escalation" &&
      action.disposition ==
      @moonrobo.RemediationMarginCycleDisposition::EscalateToOperatorDecision
    }),
  )
  assert_true(
    task.fresh_evidence_actions.any(fn(action) {
      action.blocker_domain == "local-horizon" &&
      action.execution_mode == "bounded-regeneration" &&
      action.acceptance_check.contains("check_selected_route_horizon_model.py")
    }),
  )
  assert_true(
    task.fresh_evidence_actions.any(fn(action) {
      action.blocker_domain == "energy" &&
      action.execution_mode == "manual-freeze-verification" &&
      action.acceptance_check.contains("check_energy_margin_remediation.py")
    }),
  )
}

///|
test "MoonClaw reviewed fresh evidence task renderers expose commands and gates" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks_markdown()
  assert_true(
    markdown.contains(
      "MoonClaw Remediation Margin Reviewed Fresh Evidence Tasks",
    ),
  )
  assert_true(markdown.contains("reviewed-fresh-evidence-task"))
  assert_true(markdown.contains("pending receipts: 3"))
  assert_true(markdown.contains("ReviewedWorkItemPendingFreshEvidence"))
  assert_true(markdown.contains("operator-escalation"))
  assert_true(markdown.contains("bounded-regeneration"))
  assert_true(markdown.contains("manual-freeze-verification"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("automatic refresh loop allowed: false"))
  assert_true(markdown.contains("hardware authority change: false"))
  assert_true(markdown.contains("moonmoon-safety-gate-only"))
  let json = @moonclaw.first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"pending_receipt_count\": 3"))
  assert_true(json.contains("\"execution_mode\": \"operator-escalation\""))
  assert_true(json.contains("\"execution_mode\": \"bounded-regeneration\""))
  assert_true(
    json.contains("\"execution_mode\": \"manual-freeze-verification\""),
  )
  assert_true(json.contains("\"may_consume_simulation\": false"))
  assert_true(json.contains("\"automatic_refresh_loop_allowed\": false"))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}

///|
test "first trusted square remediation margin refresh follow-up receipt carries follow-up refreshes forward" {
  let receipt = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_receipt()
  assert_eq(
    receipt.receipt.receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt",
  )
  assert_eq(
    receipt.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
  )
  assert_eq(
    receipt.source_refresh_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
  )
  assert_eq(receipt.route_id, "northeast-stepout")
  assert_true(
    receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::Accepted,
  )
  assert_true(
    receipt.refresh_state ==
    @moonclaw.MoonClawRemediationMarginRefreshFollowupState::FollowupRefreshesCarriedForward,
  )
  assert_true(
    receipt.source_modeling_state ==
    @moonrobo.RemediationMarginRefreshModelingState::AllRefreshesStillBlocking,
  )
  assert_true(
    receipt.source_projection_status ==
    @moonrobo.RemediationMarginRefreshProjectionStatus::NoConsumeRefreshSimulationBlocked,
  )
  assert_true(!receipt.may_consume_simulation)
  assert_eq(receipt.followup_action_count, 3)
  assert_eq(receipt.refreshed_count, 0)
  assert_eq(receipt.still_blocking_count, 3)
  assert_eq(
    receipt.blocking_refresh_ids[0],
    "refresh-terrain-northeast-stepout",
  )
  assert_eq(
    receipt.blocking_refresh_ids[1],
    "refresh-illumination-northeast-stepout",
  )
  assert_eq(receipt.blocking_refresh_ids[2], "refresh-energy-window")
  assert_eq(receipt.blocking_margin_ids[0], "terrain-northeast-stepout")
  assert_eq(receipt.blocking_margin_ids[1], "illumination-northeast-stepout")
  assert_eq(receipt.blocking_margin_ids[2], "energy-window")
  assert_true(
    receipt.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(receipt.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(receipt.hardware_denied)
  assert_eq(receipt.followup_results.length(), 3)
  assert_true(
    receipt.followup_results.all(fn(result) {
      result.status ==
      @moonclaw.MoonClawRemediationMarginRefreshFollowupResultStatus::FollowupRefreshStillBlocking &&
      result.target_artifact_path != "" &&
      result.command != "" &&
      result.acceptance_check != ""
    }),
  )
  assert_true(
    receipt.followup_results.any(fn(result) {
      result.rank == 1 &&
      result.refresh_id == "refresh-terrain-northeast-stepout" &&
      result.command.contains("generate_selected_route_terrain_remediation.py")
    }),
  )
  assert_true(
    receipt.followup_results.any(fn(result) {
      result.rank == 2 &&
      result.margin_id == "illumination-northeast-stepout" &&
      result.acceptance_check.contains("check_selected_route_horizon_model.py")
    }),
  )
  assert_true(
    receipt.followup_results.any(fn(result) {
      result.rank == 3 &&
      result.margin_id == "energy-window" &&
      result.evidence_path.contains(
        "first_trusted_square_energy_remediation.json",
      )
    }),
  )
  assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("followup-refreshes-carried-forward: pass")
    }),
  )
}

///|
test "MoonClaw remediation margin refresh follow-up receipt renderers expose state and authority" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_receipts_markdown()
  assert_true(
    markdown.contains("MoonClaw Remediation Margin Refresh Follow-Up Receipts"),
  )
  assert_true(markdown.contains("FollowupRefreshesCarriedForward"))
  assert_true(markdown.contains("NoConsumeRefreshSimulationBlocked"))
  assert_true(markdown.contains("AllRefreshesStillBlocking"))
  assert_true(markdown.contains("may consume simulation: false"))
  assert_true(markdown.contains("still blocking: 3"))
  assert_true(markdown.contains("refresh-terrain-northeast-stepout"))
  assert_true(markdown.contains("refresh-illumination-northeast-stepout"))
  assert_true(markdown.contains("refresh-energy-window"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  let json = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_receipts_json().stringify(
    indent=2,
  )
  assert_true(
    json.contains("\"refresh_state\": \"FollowupRefreshesCarriedForward\""),
  )
  assert_true(json.contains("\"still_blocking_count\": 3"))
  assert_true(json.contains("\"status\": \"FollowupRefreshStillBlocking\""))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}

///|
test "first trusted square remediation margin refresh receipt carries ranked refreshes forward" {
  let receipt = @moonclaw.first_trusted_square_remediation_margin_refresh_receipt()
  assert_eq(
    receipt.receipt.receipt_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt",
  )
  assert_eq(
    receipt.source_task_id,
    "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task",
  )
  assert_eq(
    receipt.source_projection_id,
    "moonrobo/first-trusted-square/remediation-margin-v1/projection",
  )
  assert_eq(receipt.route_id, "northeast-stepout")
  assert_true(
    receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::Accepted,
  )
  assert_true(
    receipt.refresh_state ==
    @moonclaw.MoonClawRemediationMarginRefreshState::RefreshesCarriedForward,
  )
  assert_eq(receipt.refresh_action_count, 3)
  assert_eq(receipt.refreshed_count, 0)
  assert_eq(receipt.still_blocking_count, 3)
  assert_eq(receipt.ranked_margin_ids[0], "terrain-northeast-stepout")
  assert_eq(receipt.ranked_margin_ids[1], "illumination-northeast-stepout")
  assert_eq(receipt.ranked_margin_ids[2], "energy-window")
  assert_true(
    receipt.hardware_state == @moonrobo.MoonroboExecutionState::HardwareDenied,
  )
  assert_eq(receipt.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(receipt.hardware_denied)
  assert_eq(receipt.refresh_results.length(), 3)
  assert_true(
    receipt.refresh_results.all(fn(result) {
      result.status ==
      @moonclaw.MoonClawRemediationMarginRefreshResultStatus::RefreshStillBlocking &&
      result.target_artifact_path != "" &&
      result.command != "" &&
      result.acceptance_check != ""
    }),
  )
  assert_true(
    receipt.refresh_results.any(fn(result) {
      result.rank == 1 &&
      result.margin_id == "terrain-northeast-stepout" &&
      result.command.contains("generate_selected_route_terrain_remediation.py")
    }),
  )
  assert_true(
    receipt.refresh_results.any(fn(result) {
      result.rank == 2 &&
      result.margin_id == "illumination-northeast-stepout" &&
      result.acceptance_check.contains("check_selected_route_horizon_model.py")
    }),
  )
  assert_true(
    receipt.refresh_results.any(fn(result) {
      result.rank == 3 &&
      result.margin_id == "energy-window" &&
      result.evidence_path.contains(
        "first_trusted_square_energy_remediation.json",
      )
    }),
  )
  assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("hardware-denial-preserved: pass")
    }),
  )
}

///|
test "MoonClaw remediation margin refresh receipt renderers expose state and authority" {
  let markdown = @moonclaw.first_trusted_square_remediation_margin_refresh_receipts_markdown()
  assert_true(markdown.contains("MoonClaw Remediation Margin Refresh Receipts"))
  assert_true(markdown.contains("RefreshesCarriedForward"))
  assert_true(markdown.contains("still blocking: 3"))
  assert_true(markdown.contains("refresh-terrain-northeast-stepout"))
  assert_true(markdown.contains("refresh-illumination-northeast-stepout"))
  assert_true(markdown.contains("refresh-energy-window"))
  assert_true(markdown.contains("NoConsumeSimulationBlocked"))
  assert_true(
    markdown.contains("hardware authority: moonmoon-safety-gate-only"),
  )
  let json = @moonclaw.first_trusted_square_remediation_margin_refresh_receipts_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"refresh_state\": \"RefreshesCarriedForward\""))
  assert_true(json.contains("\"still_blocking_count\": 3"))
  assert_true(json.contains("\"status\": \"RefreshStillBlocking\""))
  assert_true(json.contains("\"hardware_state\": \"HardwareDenied\""))
}
