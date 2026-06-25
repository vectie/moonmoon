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
