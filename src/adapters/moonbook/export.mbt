///|
pub(all) enum BookEntryKind {
  SourceDataset
  SourceValidation
  SourceUpgradeCandidate
  SourceAcquisitionPlan
  SourceProductSelection
  SourceExtractionCandidate
  DerivedTerrain
  MissionDecision
  OpenQuestion
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BookEntry {
  entry_id : String
  title : String
  kind : BookEntryKind
  claim_kind : @core.ClaimKind
  confidence : Double
  path : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ReviewQueueItem {
  item_id : String
  severity : String
  reason : String
  owner : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarBookDossier {
  workspace : String
  site_id : @core.SiteId
  title : String
  entries : Array[BookEntry]
  review_queue : Array[ReviewQueueItem]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn book_entry_kind_label(kind : BookEntryKind) -> String {
  match kind {
    SourceDataset => "source-dataset"
    SourceValidation => "source-validation"
    SourceUpgradeCandidate => "source-upgrade-candidate"
    SourceAcquisitionPlan => "source-acquisition-plan"
    SourceProductSelection => "source-product-selection"
    SourceExtractionCandidate => "source-extraction-candidate"
    DerivedTerrain => "derived-terrain"
    MissionDecision => "mission-decision"
    OpenQuestion => "open-question"
  }
}

///|
fn source_candidate_entries(dossier : @site.SiteDossier) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for candidate in dossier.source_candidates {
    entries.push({
      entry_id: "source-candidate/\{candidate.candidate_id}",
      title: candidate.title,
      kind: SourceUpgradeCandidate,
      claim_kind: @core.ClaimKind::Unknown,
      confidence: 0.0,
      path: "source-candidates/\{candidate.candidate_id}.json",
      summary: "\{candidate.instrument} \{candidate.product_family}: \{candidate.next_action}",
    })
  }
  entries
}

///|
fn source_acquisition_plan_entries(
  dossier : @site.SiteDossier,
) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for plan in dossier.source_acquisition_plans {
    entries.push({
      entry_id: "source-acquisition/\{plan.plan_id}",
      title: "Acquire \{plan.product_family_id}",
      kind: SourceAcquisitionPlan,
      claim_kind: @core.ClaimKind::Unknown,
      confidence: 0.0,
      path: "source-acquisition/\{plan.plan_id}.json",
      summary: "\{@dataset.acquisition_plan_progress_label(plan)} for \{plan.target_region}: \{plan.trust_gate}",
    })
  }
  entries
}

///|
fn source_product_selection_entries(
  dossier : @site.SiteDossier,
) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for selection in dossier.source_product_selections {
    entries.push({
      entry_id: "source-product/\{selection.selection_id}",
      title: "Select \{selection.product_id}",
      kind: SourceProductSelection,
      claim_kind: @core.ClaimKind::Unknown,
      confidence: 0.0,
      path: "source-products/\{selection.selection_id}.json",
      summary: "\{selection.projection} \{selection.resolution_m} m/pixel label pinned at \{selection.label_sha256}; \{selection.extraction_risk}",
    })
  }
  entries
}

///|
fn source_extraction_candidate_entries(
  dossier : @site.SiteDossier,
) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for extraction in dossier.source_extraction_candidates {
    entries.push({
      entry_id: "source-extraction/\{extraction.extraction_id}",
      title: "Extract \{extraction.tile_id}",
      kind: SourceExtractionCandidate,
      claim_kind: extraction.claim_kind,
      confidence: 0.0,
      path: "source-extractions/\{extraction.extraction_id}.json",
      summary: "\{extraction.rows}x\{extraction.cols} window at row \{extraction.source_row_start}, col \{extraction.source_col_start}; \{extraction.output_sha256}",
    })
  }
  entries
}

///|
fn validation_confidence(status : @dataset.DatasetValidationStatus) -> Double {
  match status {
    Verified => 1.0
    ChecksumMismatch => 0.1
    MissingChecksum => 0.25
    UnsupportedChecksum => 0.25
  }
}

///|
fn decision_severity(decision : @mission.TraverseDecision) -> String {
  match decision {
    Allow => "low"
    Review => "medium"
    Block => "high"
  }
}

///|
fn validation_severity(status : @dataset.DatasetValidationStatus) -> String {
  match status {
    Verified => "low"
    ChecksumMismatch => "high"
    MissingChecksum => "medium"
    UnsupportedChecksum => "medium"
  }
}

///|
fn dataset_entries(dossier : @site.SiteDossier) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for manifest in dossier.datasets {
    entries.push({
      entry_id: "dataset/\{manifest.dataset_id}",
      title: manifest.title,
      kind: SourceDataset,
      claim_kind: manifest.claim_kind,
      confidence: 1.0,
      path: "datasets/\{manifest.dataset_id}.json",
      summary: "Dataset manifest with coverage, trust, source path, source SHA-256, extractor, checksum, citation, and review status.",
    })
  }
  entries
}

///|
fn validation_entries(dossier : @site.SiteDossier) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for validation in dossier.validations {
    entries.push({
      entry_id: "validation/\{validation.dataset_id}",
      title: "Source validation for \{validation.dataset_id}",
      kind: SourceValidation,
      claim_kind: @core.ClaimKind::Derived,
      confidence: validation_confidence(validation.status),
      path: "datasets/\{validation.dataset_id}.validation.json",
      summary: "\{@dataset.validation_status_label(validation.status)}: \{validation.note}",
    })
  }
  entries
}

///|
fn terrain_entry(dossier : @site.SiteDossier) -> BookEntry {
  {
    entry_id: "terrain/\{dossier.site.site_id}/metrics",
    title: "Terrain metrics for \{dossier.site.name}",
    kind: DerivedTerrain,
    claim_kind: @core.ClaimKind::Derived,
    confidence: dossier.terrain.uncertainty.confidence,
    path: "terrain/\{dossier.site.site_id}/metrics.json",
    summary: "\{@terrain.hazard_label(dossier.terrain.hazard_class)} hazard, \{dossier.terrain.elevation_range_m} m elevation range, \{dossier.terrain.roughness_m} m roughness.",
  }
}

///|
fn traverse_entry(dossier : @site.SiteDossier) -> BookEntry {
  {
    entry_id: "mission/\{dossier.site.site_id}/traverse",
    title: "Traverse readiness for \{dossier.site.name}",
    kind: MissionDecision,
    claim_kind: @core.ClaimKind::Derived,
    confidence: dossier.terrain.uncertainty.confidence,
    path: "mission/\{dossier.site.site_id}/traverse.json",
    summary: "\{@mission.traverse_decision_label(dossier.traverse.decision)} with score \{dossier.traverse.score}: \{dossier.traverse.next_action}",
  }
}

///|
fn review_queue(dossier : @site.SiteDossier) -> Array[ReviewQueueItem] {
  let items : Array[ReviewQueueItem] = []
  for candidate in dossier.source_candidates {
    items.push({
      item_id: "source-candidate-\{candidate.candidate_id}",
      severity: "medium",
      reason: candidate.next_action,
      owner: "data-review",
    })
  }
  for validation in dossier.validations {
    if validation.status != @dataset.DatasetValidationStatus::Verified {
      items.push({
        item_id: "validation-\{validation.dataset_id}",
        severity: validation_severity(validation.status),
        reason: validation.note,
        owner: "data-review",
      })
    }
  }
  for index, blocker in dossier.blockers {
    items.push({
      item_id: "blocker-\{index}",
      severity: decision_severity(dossier.traverse.decision),
      reason: blocker,
      owner: "operator",
    })
  }
  for index, reason in dossier.traverse.reasons {
    items.push({
      item_id: "traverse-\{index}",
      severity: decision_severity(dossier.traverse.decision),
      reason,
      owner: "mission-review",
    })
  }
  for index, question in dossier.next_questions {
    items.push({
      item_id: "question-\{index}",
      severity: "low",
      reason: question,
      owner: "moonclaw",
    })
  }
  items
}

///|
pub fn from_site_dossier(dossier : @site.SiteDossier) -> LunarBookDossier {
  let entries = dataset_entries(dossier)
  for entry in source_candidate_entries(dossier) {
    entries.push(entry)
  }
  for entry in source_acquisition_plan_entries(dossier) {
    entries.push(entry)
  }
  for entry in source_product_selection_entries(dossier) {
    entries.push(entry)
  }
  for entry in source_extraction_candidate_entries(dossier) {
    entries.push(entry)
  }
  for entry in validation_entries(dossier) {
    entries.push(entry)
  }
  entries.push(terrain_entry(dossier))
  entries.push(traverse_entry(dossier))
  {
    workspace: "moonbook://moonmoon/first-trusted-square",
    site_id: dossier.site.site_id,
    title: "Moonmoon evidence dossier: \{dossier.site.name}",
    entries,
    review_queue: review_queue(dossier),
  }
}

///|
pub fn first_trusted_square_book_dossier() -> LunarBookDossier {
  from_site_dossier(@site.first_trusted_square_dossier())
}

///|
pub fn render_markdown(dossier : LunarBookDossier) -> String {
  let mut text = "# \{dossier.title}\n\n"
  text += "- workspace: \{dossier.workspace}\n"
  text += "- site: \{dossier.site_id}\n\n"
  text += "## Entries\n\n"
  for entry in dossier.entries {
    text += "- \{entry.entry_id}: \{entry.title}\n"
    text += "  - kind: \{book_entry_kind_label(entry.kind)}\n"
    text += "  - claim: \{@core.claim_kind_label(entry.claim_kind)}\n"
    text += "  - confidence: \{entry.confidence}\n"
    text += "  - path: \{entry.path}\n"
  }
  text += "\n## Review Queue\n\n"
  if dossier.review_queue.is_empty() {
    text += "- empty\n"
  } else {
    for item in dossier.review_queue {
      text += "- \{item.item_id} [\{item.severity}] \{item.reason} -> \{item.owner}\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_book_markdown() -> String {
  render_markdown(first_trusted_square_book_dossier())
}

///|
pub fn render_json(dossier : LunarBookDossier) -> Json {
  dossier.to_json()
}

///|
pub fn first_trusted_square_book_json() -> Json {
  render_json(first_trusted_square_book_dossier())
}
