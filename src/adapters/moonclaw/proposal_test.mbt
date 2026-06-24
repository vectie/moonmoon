///|
test "first trusted square exports bounded MoonClaw modeling proposals" {
  let proposals = @moonclaw.first_trusted_square_proposals()
  assert_eq(proposals.length(), 3)
  let primary = @moonclaw.first_trusted_square_primary_proposal()
  assert_true(
    primary.job_kind == @moonclaw.MoonClawJobKind::EphemerisAcquisition,
  )
  assert_true(primary.priority == @moonclaw.MoonClawJobPriority::Critical)
  assert_true(primary.proposal_id.contains("ephemeris-energy-v1"))
  assert_true(primary.objective.contains("time-windowed solar ephemeris"))
  assert_true(
    primary.inputs.any(fn(input) {
      input.evidence_path == "mission/first-trusted-square/energy-window.json"
    }),
  )
  assert_true(
    primary.acceptance_criteria.any(fn(criterion) {
      criterion.description.contains("ephemeris")
    }),
  )
  let corridor = proposals[1]
  assert_true(corridor.job_kind == @moonclaw.MoonClawJobKind::CorridorExpansion)
  assert_true(corridor.priority == @moonclaw.MoonClawJobPriority::High)
  assert_true(
    corridor.inputs.any(fn(input) {
      input.evidence_path == "mission/first-trusted-square/corridor-scan.json"
    }),
  )
  assert_true(corridor.blocked_by.contains("corridor-scan-best-window"))
  let scoring = proposals[2]
  assert_true(scoring.job_kind == @moonclaw.MoonClawJobKind::RouteScoring)
  assert_true(scoring.blocked_by.contains("moonrobo-handoff"))
}

///|
test "MoonClaw proposal renderers expose job contracts" {
  let markdown = @moonclaw.first_trusted_square_markdown()
  assert_true(markdown.contains("MoonClaw Modeling Proposals"))
  assert_true(markdown.contains("ephemeris-acquisition"))
  assert_true(markdown.contains("corridor-expansion"))
  assert_true(markdown.contains("route-scoring"))
  assert_true(markdown.contains("moonrobo-handoff"))
  let json = @moonclaw.first_trusted_square_json().stringify(indent=2)
  assert_true(json.contains("\"EphemerisAcquisition\""))
  assert_true(json.contains("\"CorridorExpansion\""))
  assert_true(json.contains("\"RouteScoring\""))
  assert_true(json.contains("\"Critical\""))
}

///|
test "first trusted square ephemeris task names executable source gates" {
  let task = @moonclaw.first_trusted_square_ephemeris_acquisition_task()
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/ephemeris-energy-v1/acquisition-task",
  )
  assert_eq(
    task.proposal_id,
    "moonclaw/first-trusted-square/ephemeris-energy-v1",
  )
  assert_true(task.priority == @moonclaw.MoonClawJobPriority::Critical)
  assert_true(task.state == @moonclaw.MoonClawReceiptStatus::NeedsReview)
  assert_true(task.objective.contains("time-windowed solar ephemeris"))
  assert_true(task.safety_gate.contains("Do not allow Moonrobo simulation"))
  assert_true(task.inputs.length() == 3)
  assert_true(task.artifacts.length() == 5)
  assert_eq(@moonclaw.task_blocked_artifact_count(task), 2)
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "power-window-json" &&
      artifact.current_state == "missing-source" &&
      !artifact.ready &&
      artifact.blocking_reason.contains("no time-windowed ephemeris") &&
      artifact.path ==
      "data/sources/lunar_ephemeris/first_trusted_square_power_window.json"
    }),
  )
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "generated-moonbit-window" && artifact.ready
    }),
  )
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "moonrobo-preconditions" &&
      artifact.ready &&
      artifact.validation_gate.contains("moonrobo handoff json")
    }),
  )
  assert_true(
    task.commands.contains("python3 scripts/generate_power_window.py --check"),
  )
  assert_true(
    task.commands.contains("/Users/kq/.moon/bin/moon test src/mission"),
  )
}

///|
test "MoonClaw ephemeris task renderers expose artifact gates" {
  let markdown = @moonclaw.first_trusted_square_ephemeris_tasks_markdown()
  assert_true(markdown.contains("MoonClaw Ephemeris Acquisition Tasks"))
  assert_true(markdown.contains("power-window-json"))
  assert_true(markdown.contains("missing-source"))
  assert_true(markdown.contains("ready: false"))
  assert_true(markdown.contains("blocking: current power-window evidence"))
  assert_true(markdown.contains("moonrobo-preconditions"))
  assert_true(markdown.contains("generate_power_window.py --check"))
  let json = @moonclaw.first_trusted_square_ephemeris_tasks_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"MoonClawEphemerisAcquisitionTask\"") == false)
  assert_true(json.contains("\"artifacts\""))
  assert_true(json.contains("\"ready\": false"))
  assert_true(json.contains("\"blocking_reason\""))
  assert_true(json.contains("\"safety_gate\""))
  assert_true(json.contains("\"state\": \"NeedsReview\""))
}

///|
test "first trusted square corridor task names planned 9x9 search gates" {
  let task = @moonclaw.first_trusted_square_corridor_expansion_task()
  assert_eq(
    task.task_id,
    "moonclaw/first-trusted-square/corridor-expansion-v1/search-task",
  )
  assert_eq(
    task.proposal_id,
    "moonclaw/first-trusted-square/corridor-expansion-v1",
  )
  assert_true(task.priority == @moonclaw.MoonClawJobPriority::High)
  assert_true(task.state == @moonclaw.MoonClawReceiptStatus::NeedsReview)
  assert_eq(task.current_scan_id, "first-trusted-square-5x5-corridor-scan-v1")
  assert_eq(task.planned_scan_id, "first-trusted-square-9x9-corridor-scan-v2")
  assert_eq(task.current_window_count, 25)
  assert_eq(task.planned_window_count, 81)
  assert_eq(task.planned_radius_cells, 16)
  assert_eq(task.planned_step_cells, 4)
  assert_eq(@moonclaw.corridor_task_blocked_artifact_count(task), 3)
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "planned-9x9-search" && artifact.ready
    }),
  )
  assert_true(
    task.artifacts.any(fn(artifact) {
      artifact.artifact_id == "widened-scan-csv" &&
      !artifact.ready &&
      artifact.blocking_reason.contains("9x9 search")
    }),
  )
  assert_true(
    task.commands.contains(
      "python3 scripts/scan_lola_corridor.py --plan --radius 16 --step 4",
    ),
  )
  assert_true(
    task.commands.contains(
      "python3 scripts/scan_lola_corridor.py --radius 16 --step 4 --target data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv",
    ),
  )
}

///|
test "MoonClaw corridor task renderers expose widened search blockers" {
  let markdown = @moonclaw.first_trusted_square_corridor_tasks_markdown()
  assert_true(markdown.contains("MoonClaw Corridor Expansion Tasks"))
  assert_true(markdown.contains("first-trusted-square-9x9-corridor-scan-v2"))
  assert_true(markdown.contains("81 windows"))
  assert_true(markdown.contains("first_trusted_square_corridor_scan_v2.csv"))
  assert_true(markdown.contains("widened-scan-csv"))
  assert_true(markdown.contains("ready: false"))
  let json = @moonclaw.first_trusted_square_corridor_tasks_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"planned_window_count\": 81"))
  assert_true(json.contains("\"planned_radius_cells\": 16"))
  assert_true(json.contains("\"blocking_reason\""))
}

///|
test "first trusted square route scoring receipt validates blocked evidence" {
  let receipt = @moonclaw.first_trusted_square_route_scoring_receipt()
  assert_eq(
    receipt.receipt.proposal_id,
    "moonclaw/first-trusted-square/route-scoring-v1",
  )
  assert_true(
    receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::Accepted,
  )
  assert_eq(receipt.selected_route_id, "southwest-bypass")
  assert_true(
    receipt.moonrobo_handoff_decision == @mission.TraverseDecision::Block,
  )
  assert_eq(receipt.route_scores.length(), 5)
  let southwest = receipt.route_scores[3]
  assert_eq(southwest.route_id, "southwest-bypass")
  assert_eq(southwest.rank, 1)
  assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("moonrobo-handoff-compatible")
    }),
  )
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("source-checksums-verified")
    }),
  )
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("proposal-blockers-current")
    }),
  )
  assert_true(receipt.next_action.contains("keeps Moonrobo blocked"))
}

///|
test "first trusted square corridor receipt validates bounded search result" {
  let receipt = @moonclaw.first_trusted_square_corridor_expansion_receipt()
  assert_eq(
    receipt.receipt.proposal_id,
    "moonclaw/first-trusted-square/corridor-expansion-v1",
  )
  assert_true(
    receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::Accepted,
  )
  assert_eq(receipt.sampled_window_count, 25)
  assert_eq(receipt.best_window_id, "r+8-c-8")
  assert_eq(receipt.selected_route_id, "southwest-bypass")
  assert_true(receipt.window_scores.length() == 25)
  assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("all-sampled-windows-blocked")
    }),
  )
  assert_true(
    receipt.next_action.contains("every sampled LOLA window remains blocked"),
  )
}

///|
test "first trusted square ephemeris receipt records missing power evidence" {
  let receipt = @moonclaw.first_trusted_square_ephemeris_acquisition_receipt()
  assert_eq(
    receipt.receipt.proposal_id,
    "moonclaw/first-trusted-square/ephemeris-energy-v1",
  )
  assert_true(
    receipt.receipt.status == @moonclaw.MoonClawReceiptStatus::NeedsReview,
  )
  assert_true(receipt.energy_decision == @mission.TraverseDecision::Block)
  assert_true(!receipt.has_time_window_ephemeris)
  assert_eq(
    receipt.power_window_evidence_id,
    "first-trusted-square-power-window-missing-v1",
  )
  assert_eq(receipt.power_window_source_status, "missing-source")
  assert_eq(
    receipt.power_window_source_path,
    "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
  )
  assert_eq(receipt.route_count, 5)
  assert_eq(receipt.blocked_route_count, 5)
  assert_eq(receipt.verified_available_energy_wh, 0.0)
  assert_true(receipt.missing_outputs.length() >= 4)
  assert_true(receipt.validation_checks.all(fn(check) { check.passed }))
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("time-window-ephemeris-missing")
    }),
  )
  assert_true(
    receipt.receipt.validation_notes.any(fn(note) {
      note.contains("power-window-source-status-missing")
    }),
  )
  assert_true(receipt.next_action.contains("cannot clear the energy gate"))
}

///|
test "MoonClaw receipt renderers expose route scoring result" {
  let markdown = @moonclaw.first_trusted_square_receipts_markdown()
  assert_true(markdown.contains("MoonClaw Modeling Receipts"))
  assert_true(markdown.contains("route-scoring-v1/current-receipt"))
  assert_true(markdown.contains("moonrobo-handoff-compatible"))
  assert_true(markdown.contains("source-checksums-verified"))
  assert_true(markdown.contains("proposal-blockers-current"))
  assert_true(markdown.contains("southwest-bypass"))
  let json = @moonclaw.first_trusted_square_receipts_json().stringify(indent=2)
  assert_true(json.contains("\"MoonClawRouteScoringReceipt\"") == false)
  assert_true(json.contains("\"route_scores\""))
  assert_true(json.contains("\"Accepted\""))
  assert_true(json.contains("\"moonrobo_handoff_decision\""))
}

///|
test "MoonClaw ephemeris receipt renderers expose missing source contract" {
  let markdown = @moonclaw.first_trusted_square_ephemeris_receipts_markdown()
  assert_true(markdown.contains("MoonClaw Ephemeris Receipts"))
  assert_true(markdown.contains("ephemeris-energy-v1/current-receipt"))
  assert_true(markdown.contains("needs-review"))
  assert_true(markdown.contains("time-window-ephemeris-missing"))
  assert_true(markdown.contains("first-trusted-square-power-window-missing-v1"))
  assert_true(markdown.contains("power-window source status: missing-source"))
  assert_true(markdown.contains("first_trusted_square_power_window.json"))
  let json = @moonclaw.first_trusted_square_ephemeris_receipts_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"missing_outputs\""))
  assert_true(json.contains("\"NeedsReview\""))
  assert_true(json.contains("\"has_time_window_ephemeris\""))
  assert_true(
    json.contains("\"power_window_source_status\": \"missing-source\""),
  )
}

///|
test "MoonClaw corridor receipt renderers expose bounded search result" {
  let markdown = @moonclaw.first_trusted_square_corridor_receipts_markdown()
  assert_true(markdown.contains("MoonClaw Corridor Receipts"))
  assert_true(markdown.contains("corridor-expansion-v1/current-receipt"))
  assert_true(markdown.contains("bounded-search-size"))
  assert_true(markdown.contains("all-sampled-windows-blocked"))
  assert_true(markdown.contains("r+8-c-8"))
  let json = @moonclaw.first_trusted_square_corridor_receipts_json().stringify(
    indent=2,
  )
  assert_true(json.contains("\"window_scores\""))
  assert_true(json.contains("\"sampled_window_count\""))
  assert_true(json.contains("\"Accepted\""))
}
