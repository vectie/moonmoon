///|
test "first trusted square exports a LunarBook evidence dossier" {
  let dossier = @moonbook.first_trusted_square_book_dossier()
  assert_eq(dossier.site_id, "first-trusted-square")
  assert_eq(dossier.entries.length(), 8)
  assert_true(dossier.review_queue.length() >= 5)
  assert_eq(
    dossier.entries[0].entry_id,
    "dataset/fixture-first-trusted-square-dem-v1",
  )
  assert_true(
    dossier.entries[1].kind == @moonbook.BookEntryKind::SourceUpgradeCandidate,
  )
  assert_true(
    dossier.entries[2].kind == @moonbook.BookEntryKind::SourceAcquisitionPlan,
  )
  assert_true(
    dossier.entries[3].kind == @moonbook.BookEntryKind::SourceProductSelection,
  )
  assert_true(
    dossier.entries[4].kind ==
    @moonbook.BookEntryKind::SourceExtractionCandidate,
  )
  assert_true(
    dossier.entries[5].kind == @moonbook.BookEntryKind::SourceValidation,
  )
  assert_true(
    dossier.entries[6].kind == @moonbook.BookEntryKind::DerivedTerrain,
  )
  assert_true(
    dossier.entries[7].kind == @moonbook.BookEntryKind::MissionDecision,
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[7].kind),
    "mission-decision",
  )
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
  assert_true(markdown.contains("## Review Queue"))
  assert_true(markdown.contains("Select a specific LOLA/SLDEM product"))
  assert_true(markdown.contains("terrain confidence below traverse threshold"))
  let json = @moonbook.first_trusted_square_book_json().stringify(indent=2)
  assert_true(json.contains("\"review_queue\""))
  assert_true(json.contains("\"SourceUpgradeCandidate\""))
  assert_true(json.contains("\"SourceAcquisitionPlan\""))
  assert_true(json.contains("\"SourceProductSelection\""))
  assert_true(json.contains("\"SourceExtractionCandidate\""))
  assert_true(json.contains("\"SourceValidation\""))
  assert_true(json.contains("\"MissionDecision\""))
}
