///|
test "first trusted square exports a LunarBook evidence dossier" {
  let dossier = @moonbook.first_trusted_square_book_dossier()
  assert_eq(dossier.site_id, "first-trusted-square")
  assert_eq(dossier.entries.length(), 35)
  assert_eq(dossier.review_queue.length(), 22)
  assert_eq(dossier.review_transitions.length(), dossier.review_queue.length())
  assert_eq(
    dossier.entries[0].entry_id,
    "dataset/lro-lola-first-trusted-square-dem-v1",
  )
  assert_eq(
    dossier.entries[1].entry_id,
    "dataset/lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    dossier.entries[2].entry_id,
    "dataset/lro-lola-first-trusted-square-north-rim-dem-v1",
  )
  assert_eq(
    dossier.entries[3].entry_id,
    "dataset/lro-lola-first-trusted-square-southwest-bypass-dem-v1",
  )
  assert_eq(
    dossier.entries[4].entry_id,
    "dataset/lro-lola-first-trusted-square-south-stepout-dem-v1",
  )
  assert_true(
    dossier.entries[5].kind == @moonbook.BookEntryKind::SourceUpgradeCandidate,
  )
  assert_true(
    dossier.entries[6].kind == @moonbook.BookEntryKind::SourceAcquisitionPlan,
  )
  assert_true(
    dossier.entries[7].kind == @moonbook.BookEntryKind::SourceProductSelection,
  )
  assert_true(
    dossier.entries[8].kind ==
    @moonbook.BookEntryKind::SourceExtractionCandidate,
  )
  assert_true(
    dossier.entries[13].kind == @moonbook.BookEntryKind::SourceValidation,
  )
  assert_true(
    dossier.entries[18].kind == @moonbook.BookEntryKind::DerivedTerrain,
  )
  assert_true(
    dossier.entries[19].kind == @moonbook.BookEntryKind::MissionDecision,
  )
  assert_true(dossier.entries[20].kind == @moonbook.BookEntryKind::CorridorScan)
  assert_true(
    dossier.entries[21].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[24].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[25].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[26].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[29].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[30].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(dossier.entries[31].kind == @moonbook.BookEntryKind::EnergyWindow)
  assert_true(
    dossier.entries[32].kind == @moonbook.BookEntryKind::MoonroboHandoff,
  )
  assert_true(
    dossier.entries[33].kind == @moonbook.BookEntryKind::MoonClawProposal,
  )
  assert_true(
    dossier.entries[34].kind == @moonbook.BookEntryKind::MoonClawReceipt,
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[19].kind),
    "mission-decision",
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[20].kind),
    "corridor-scan",
  )
  assert_true(dossier.entries[20].summary.contains("r+8-c-8"))
  assert_true(dossier.entries[22].summary.contains("west-contour"))
  assert_true(dossier.entries[24].summary.contains("southwest"))
  assert_true(dossier.entries[29].summary.contains("relief-shadow risk"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[31].kind),
    "energy-window",
  )
  assert_true(dossier.entries[31].summary.contains("0 Wh verified available"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[32].kind),
    "moonrobo-handoff",
  )
  assert_true(dossier.entries[32].summary.contains("southwest-bypass"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[33].kind),
    "moonclaw-proposal",
  )
  assert_true(dossier.entries[33].summary.contains("ephemeris"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[34].kind),
    "moonclaw-receipt",
  )
  assert_true(dossier.entries[34].summary.contains("Moonrobo handoff block"))
  assert_eq(dossier.review_queue[0].item_id, "workspace-materialized")
  assert_true(
    dossier.review_queue[0].status == @moonbook.ReviewItemStatus::Accepted,
  )
  assert_true(
    dossier.review_transitions[0].decision == @moonbook.ReviewDecision::Accept,
  )
  assert_eq(
    @moonbook.review_item_status_label(dossier.review_queue[0].status),
    "accepted",
  )
  let direct_route = dossier.review_queue[5]
  assert_eq(direct_route.item_id, "route-direct-lola-window")
  assert_true(direct_route.status == @moonbook.ReviewItemStatus::Rejected)
  assert_true(
    dossier.review_transitions[5].decision == @moonbook.ReviewDecision::Reject,
  )
  assert_eq(
    @moonbook.review_decision_label(dossier.review_transitions[5].decision),
    "reject",
  )
  let corridor = dossier.review_queue[15]
  assert_eq(corridor.item_id, "corridor-scan-best-window")
  assert_true(corridor.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let energy = dossier.review_queue[16]
  assert_eq(energy.item_id, "energy-window")
  assert_true(energy.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let handoff = dossier.review_queue[17]
  assert_eq(handoff.item_id, "moonrobo-handoff")
  assert_true(handoff.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let moonclaw = dossier.review_queue[18]
  assert_eq(moonclaw.item_id, "moonclaw-proposals")
  assert_true(moonclaw.status == @moonbook.ReviewItemStatus::NeedsEvidence)
}

///|
test "first trusted square LunarBook renderers expose review work" {
  let markdown = @moonbook.first_trusted_square_book_markdown()
  assert_true(markdown.contains("## Entries"))
  assert_true(markdown.contains("source-upgrade-candidate"))
  assert_true(markdown.contains("source-acquisition-plan"))
  assert_true(markdown.contains("source-product-selection"))
  assert_true(markdown.contains("source-extraction-candidate"))
  assert_true(markdown.contains("source-validation"))
  assert_true(markdown.contains("route-alternative"))
  assert_true(markdown.contains("corridor-scan"))
  assert_true(markdown.contains("illumination-assessment"))
  assert_true(markdown.contains("energy-window"))
  assert_true(markdown.contains("moonrobo-handoff"))
  assert_true(markdown.contains("moonclaw-proposal"))
  assert_true(markdown.contains("moonclaw-receipt"))
  assert_true(markdown.contains("## Review Queue"))
  assert_true(markdown.contains("workspace-materialized [low/accepted]"))
  assert_true(markdown.contains("route-direct-lola-window [high/rejected]"))
  assert_true(markdown.contains("## Review Transitions"))
  assert_true(markdown.contains("review-route-direct-lola-window-reject"))
  assert_true(markdown.contains("source-extraction-candidate"))
  assert_true(markdown.contains("max neighbor grade exceeds rover hard limit"))
  assert_true(markdown.contains("power-thermal-review"))
  let json = @moonbook.first_trusted_square_book_json().stringify(indent=2)
  assert_true(json.contains("\"review_queue\""))
  assert_true(json.contains("\"review_transitions\""))
  assert_true(json.contains("\"Accepted\""))
  assert_true(json.contains("\"Rejected\""))
  assert_true(json.contains("\"NeedsEvidence\""))
  assert_true(json.contains("\"RequestEvidence\""))
  assert_true(json.contains("\"SourceUpgradeCandidate\""))
  assert_true(json.contains("\"SourceAcquisitionPlan\""))
  assert_true(json.contains("\"SourceProductSelection\""))
  assert_true(json.contains("\"SourceExtractionCandidate\""))
  assert_true(json.contains("\"SourceValidation\""))
  assert_true(json.contains("\"MissionDecision\""))
  assert_true(json.contains("\"CorridorScan\""))
  assert_true(json.contains("\"RouteAlternative\""))
  assert_true(json.contains("\"IlluminationAssessment\""))
  assert_true(json.contains("\"EnergyWindow\""))
  assert_true(json.contains("\"MoonroboHandoff\""))
  assert_true(json.contains("\"MoonClawProposal\""))
  assert_true(json.contains("\"MoonClawReceipt\""))
}
