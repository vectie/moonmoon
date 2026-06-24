///|
test "first trusted square exports a LunarBook evidence dossier" {
  let dossier = @moonbook.first_trusted_square_book_dossier()
  assert_eq(dossier.site_id, "first-trusted-square")
  assert_eq(dossier.entries.length(), 42)
  assert_eq(dossier.review_queue.length(), 26)
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
    dossier.entries[6].kind == @moonbook.BookEntryKind::SourceUpgradeCandidate,
  )
  assert_true(dossier.entries[6].summary.contains("energy gate"))
  assert_true(
    dossier.entries[7].kind == @moonbook.BookEntryKind::SourceAcquisitionPlan,
  )
  assert_true(
    dossier.entries[8].kind == @moonbook.BookEntryKind::SourceAcquisitionPlan,
  )
  assert_true(
    dossier.entries[8].summary.contains(
      "generated_first_trusted_square_power_window.mbt",
    ),
  )
  assert_true(
    dossier.entries[9].kind == @moonbook.BookEntryKind::SourceProductSelection,
  )
  assert_true(
    dossier.entries[10].kind ==
    @moonbook.BookEntryKind::SourceExtractionCandidate,
  )
  assert_true(
    dossier.entries[15].kind == @moonbook.BookEntryKind::SourceValidation,
  )
  assert_true(
    dossier.entries[20].kind == @moonbook.BookEntryKind::DerivedTerrain,
  )
  assert_true(
    dossier.entries[21].kind == @moonbook.BookEntryKind::MissionDecision,
  )
  assert_true(dossier.entries[22].kind == @moonbook.BookEntryKind::CorridorScan)
  assert_true(
    dossier.entries[23].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[26].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[27].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[28].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[31].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[32].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[33].kind == @moonbook.BookEntryKind::PowerWindowEvidence,
  )
  assert_true(dossier.entries[34].kind == @moonbook.BookEntryKind::EnergyWindow)
  assert_true(
    dossier.entries[35].kind == @moonbook.BookEntryKind::MoonroboHandoff,
  )
  assert_true(
    dossier.entries[36].kind == @moonbook.BookEntryKind::MoonClawProposal,
  )
  assert_true(dossier.entries[37].kind == @moonbook.BookEntryKind::MoonClawTask)
  assert_true(dossier.entries[38].kind == @moonbook.BookEntryKind::MoonClawTask)
  assert_true(
    dossier.entries[39].kind == @moonbook.BookEntryKind::MoonClawReceipt,
  )
  assert_true(
    dossier.entries[40].kind ==
    @moonbook.BookEntryKind::MoonClawEphemerisReceipt,
  )
  assert_true(
    dossier.entries[41].kind == @moonbook.BookEntryKind::MoonClawCorridorReceipt,
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[21].kind),
    "mission-decision",
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[22].kind),
    "corridor-scan",
  )
  assert_true(dossier.entries[22].summary.contains("r+8-c-8"))
  assert_true(dossier.entries[24].summary.contains("west-contour"))
  assert_true(dossier.entries[26].summary.contains("southwest"))
  assert_true(dossier.entries[31].summary.contains("relief-shadow risk"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[33].kind),
    "power-window-evidence",
  )
  assert_true(dossier.entries[33].summary.contains("missing-source"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[34].kind),
    "energy-window",
  )
  assert_true(dossier.entries[34].summary.contains("0 Wh verified available"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[35].kind),
    "moonrobo-handoff",
  )
  assert_true(dossier.entries[35].summary.contains("southwest-bypass"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[36].kind),
    "moonclaw-proposal",
  )
  assert_true(dossier.entries[36].summary.contains("ephemeris"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[37].kind),
    "moonclaw-task",
  )
  assert_true(
    dossier.entries[37].summary.contains("5 artifacts with 2 blockers"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[38].kind),
    "moonclaw-task",
  )
  assert_true(
    dossier.entries[38].summary.contains("81 windows with 2 blockers"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[39].kind),
    "moonclaw-receipt",
  )
  assert_true(dossier.entries[39].summary.contains("Moonrobo handoff block"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[40].kind),
    "moonclaw-ephemeris-receipt",
  )
  assert_true(dossier.entries[40].summary.contains("energy block"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[41].kind),
    "moonclaw-corridor-receipt",
  )
  assert_true(dossier.entries[41].summary.contains("25 measured windows"))
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
  let ephemeris_candidate = dossier.review_queue[1]
  assert_eq(
    ephemeris_candidate.item_id,
    "source-candidate-candidate-lunar-solar-ephemeris-first-trusted-square",
  )
  assert_true(ephemeris_candidate.status == @moonbook.ReviewItemStatus::Open)
  assert_true(
    dossier.review_transitions[1].decision == @moonbook.ReviewDecision::KeepOpen,
  )
  let direct_route = dossier.review_queue[6]
  assert_eq(direct_route.item_id, "route-direct-lola-window")
  assert_true(direct_route.status == @moonbook.ReviewItemStatus::Rejected)
  assert_true(
    dossier.review_transitions[6].decision == @moonbook.ReviewDecision::Reject,
  )
  assert_eq(
    @moonbook.review_decision_label(dossier.review_transitions[6].decision),
    "reject",
  )
  let corridor = dossier.review_queue[16]
  assert_eq(corridor.item_id, "corridor-scan-best-window")
  assert_true(corridor.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let power = dossier.review_queue[17]
  assert_eq(power.item_id, "power-window-evidence")
  assert_true(power.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  assert_true(power.reason.contains("missing-source"))
  assert_true(
    dossier.review_transitions[17].decision ==
    @moonbook.ReviewDecision::RequestEvidence,
  )
  let energy = dossier.review_queue[18]
  assert_eq(energy.item_id, "energy-window")
  assert_true(energy.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let handoff = dossier.review_queue[19]
  assert_eq(handoff.item_id, "moonrobo-handoff")
  assert_true(handoff.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let moonclaw = dossier.review_queue[20]
  assert_eq(moonclaw.item_id, "moonclaw-proposals")
  assert_true(moonclaw.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let ephemeris_task = dossier.review_queue[21]
  assert_eq(ephemeris_task.item_id, "moonclaw-ephemeris-task")
  assert_true(
    ephemeris_task.status == @moonbook.ReviewItemStatus::NeedsEvidence,
  )
  assert_true(ephemeris_task.reason.contains("2 blocking artifacts"))
  let corridor_task = dossier.review_queue[22]
  assert_eq(corridor_task.item_id, "moonclaw-corridor-task")
  assert_true(corridor_task.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  assert_true(corridor_task.reason.contains("2 blocking artifacts"))
  assert_true(corridor_task.reason.contains("81-window search"))
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
  assert_true(markdown.contains("power-window-evidence"))
  assert_true(markdown.contains("energy-window"))
  assert_true(markdown.contains("moonrobo-handoff"))
  assert_true(markdown.contains("moonclaw-proposal"))
  assert_true(markdown.contains("moonclaw-task"))
  assert_true(markdown.contains("moonclaw-receipt"))
  assert_true(markdown.contains("moonclaw-ephemeris-receipt"))
  assert_true(markdown.contains("moonclaw-corridor-receipt"))
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
  assert_true(json.contains("\"PowerWindowEvidence\""))
  assert_true(json.contains("\"EnergyWindow\""))
  assert_true(json.contains("\"MoonroboHandoff\""))
  assert_true(json.contains("\"MoonClawProposal\""))
  assert_true(json.contains("\"MoonClawTask\""))
  assert_true(json.contains("\"MoonClawReceipt\""))
  assert_true(json.contains("\"MoonClawEphemerisReceipt\""))
  assert_true(json.contains("\"MoonClawCorridorReceipt\""))
}
