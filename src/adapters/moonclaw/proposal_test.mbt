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
  assert_true(receipt.next_action.contains("keeps Moonrobo blocked"))
}

///|
test "MoonClaw receipt renderers expose route scoring result" {
  let markdown = @moonclaw.first_trusted_square_receipts_markdown()
  assert_true(markdown.contains("MoonClaw Modeling Receipts"))
  assert_true(markdown.contains("route-scoring-v1/current-receipt"))
  assert_true(markdown.contains("moonrobo-handoff-compatible"))
  assert_true(markdown.contains("southwest-bypass"))
  let json = @moonclaw.first_trusted_square_receipts_json().stringify(indent=2)
  assert_true(json.contains("\"MoonClawRouteScoringReceipt\"") == false)
  assert_true(json.contains("\"route_scores\""))
  assert_true(json.contains("\"Accepted\""))
  assert_true(json.contains("\"moonrobo_handoff_decision\""))
}
