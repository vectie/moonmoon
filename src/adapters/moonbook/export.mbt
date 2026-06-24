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
  CorridorScan
  RouteAlternative
  IlluminationAssessment
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
  status : ReviewItemStatus
  last_transition_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ReviewDecision {
  KeepOpen
  Accept
  Reject
  RequestEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ReviewItemStatus {
  Open
  Accepted
  Rejected
  NeedsEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ReviewTransition {
  transition_id : String
  item_id : String
  decision : ReviewDecision
  resulting_status : ReviewItemStatus
  reviewer : String
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarBookDossier {
  workspace : String
  site_id : @core.SiteId
  title : String
  entries : Array[BookEntry]
  review_queue : Array[ReviewQueueItem]
  review_transitions : Array[ReviewTransition]
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
    CorridorScan => "corridor-scan"
    RouteAlternative => "route-alternative"
    IlluminationAssessment => "illumination-assessment"
    OpenQuestion => "open-question"
  }
}

///|
pub fn review_decision_label(decision : ReviewDecision) -> String {
  match decision {
    KeepOpen => "keep-open"
    Accept => "accept"
    Reject => "reject"
    RequestEvidence => "request-evidence"
  }
}

///|
pub fn review_item_status_label(status : ReviewItemStatus) -> String {
  match status {
    Open => "open"
    Accepted => "accepted"
    Rejected => "rejected"
    NeedsEvidence => "needs-evidence"
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
fn review_item(
  item_id : String,
  severity : String,
  reason : String,
  owner : String,
) -> ReviewQueueItem {
  { item_id, severity, reason, owner, status: Open, last_transition_id: "" }
}

///|
fn review_decision_for_item(item : ReviewQueueItem) -> ReviewDecision {
  if item.item_id == "workspace-materialized" {
    Accept
  } else if item.item_id == "route-direct-lola-window" {
    Reject
  } else if item.severity == "high" {
    RequestEvidence
  } else {
    KeepOpen
  }
}

///|
fn resulting_status_for_decision(decision : ReviewDecision) -> ReviewItemStatus {
  match decision {
    KeepOpen => Open
    Accept => Accepted
    Reject => Rejected
    RequestEvidence => NeedsEvidence
  }
}

///|
fn transition_rationale(
  item : ReviewQueueItem,
  decision : ReviewDecision,
) -> String {
  match decision {
    Accept =>
      "accepted because the materialized workspace is present in generated MoonBook output"
    Reject =>
      "rejected for this proof slice because the evidence explicitly says not to traverse directly"
    RequestEvidence =>
      "kept in review with a request for stronger measured evidence before mission use: \{item.reason}"
    KeepOpen => "left open for \{item.owner} follow-up"
  }
}

///|
fn transition_id(item : ReviewQueueItem, decision : ReviewDecision) -> String {
  "review-\{item.item_id}-\{review_decision_label(decision)}"
}

///|
fn make_review_transition(item : ReviewQueueItem) -> ReviewTransition {
  let decision = review_decision_for_item(item)
  {
    transition_id: transition_id(item, decision),
    item_id: item.item_id,
    decision,
    resulting_status: resulting_status_for_decision(decision),
    reviewer: "moonbook-policy-v1",
    rationale: transition_rationale(item, decision),
  }
}

///|
fn apply_review_transition(
  item : ReviewQueueItem,
  transition : ReviewTransition,
) -> ReviewQueueItem {
  {
    item_id: item.item_id,
    severity: item.severity,
    reason: item.reason,
    owner: item.owner,
    status: transition.resulting_status,
    last_transition_id: transition.transition_id,
  }
}

///|
fn review_transitions_for_queue(
  items : Array[ReviewQueueItem],
) -> Array[ReviewTransition] {
  let transitions : Array[ReviewTransition] = []
  for item in items {
    transitions.push(make_review_transition(item))
  }
  transitions
}

///|
fn apply_review_transitions(
  items : Array[ReviewQueueItem],
  transitions : Array[ReviewTransition],
) -> Array[ReviewQueueItem] {
  let reviewed : Array[ReviewQueueItem] = []
  for index, item in items {
    reviewed.push(apply_review_transition(item, transitions[index]))
  }
  reviewed
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
fn corridor_scan_entry(dossier : @site.SiteDossier) -> BookEntry {
  let best = dossier.corridor_scan[0]
  {
    entry_id: "corridor/\{dossier.site.site_id}/first-trusted-square-5x5",
    title: "5x5 LOLA corridor scan for \{dossier.site.name}",
    kind: CorridorScan,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.75,
    path: "mission/\{dossier.site.site_id}/corridor-scan.json",
    summary: "best window \{best.window_id} rank \{best.rank} selects \{best.selected_route_id}: \{@mission.corridor_scan_window_status_label(best)} with grade \{best.max_neighbor_grade} and roughness \{best.roughness_m} m",
  }
}

///|
fn route_candidate_entries(dossier : @site.SiteDossier) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for route in dossier.route_candidates {
    entries.push({
      entry_id: "route/\{dossier.site.site_id}/\{route.route_id}",
      title: route.label,
      kind: RouteAlternative,
      claim_kind: @core.ClaimKind::Derived,
      confidence: route.confidence,
      path: "mission/\{dossier.site.site_id}/routes/\{route.route_id}.json",
      summary: "\{@mission.route_candidate_status_label(route)} with score \{route.score} from \{route.evidence_dataset_id}: \{route.next_action}",
    })
  }
  entries
}

///|
fn illumination_entries(dossier : @site.SiteDossier) -> Array[BookEntry] {
  let entries : Array[BookEntry] = []
  for route in dossier.route_candidates {
    entries.push({
      entry_id: "illumination/\{dossier.site.site_id}/\{route.route_id}",
      title: "Illumination gate for \{route.label}",
      kind: IlluminationAssessment,
      claim_kind: @core.ClaimKind::Derived,
      confidence: route.illumination.confidence,
      path: "mission/\{dossier.site.site_id}/routes/\{route.route_id}.illumination.json",
      summary: "\{@mission.illumination_decision_label(route.illumination)} with relief-shadow risk \{route.illumination.relief_shadow_risk}: \{route.illumination.next_action}",
    })
  }
  entries
}

///|
fn open_review_queue(dossier : @site.SiteDossier) -> Array[ReviewQueueItem] {
  let items : Array[ReviewQueueItem] = []
  items.push(
    review_item(
      "workspace-materialized", "low", "MoonBook workspace files are materialized from the current generated dossier",
      "moonbook",
    ),
  )
  for candidate in dossier.source_candidates {
    if candidate.review_status !=
      @dataset.ReviewStatus::AcceptedForSoftwareProof {
      items.push(
        review_item(
          "source-candidate-\{candidate.candidate_id}",
          "medium",
          candidate.next_action,
          "data-review",
        ),
      )
    }
  }
  for validation in dossier.validations {
    if validation.status != @dataset.DatasetValidationStatus::Verified {
      items.push(
        review_item(
          "validation-\{validation.dataset_id}",
          validation_severity(validation.status),
          validation.note,
          "data-review",
        ),
      )
    }
  }
  for index, blocker in dossier.blockers {
    items.push(
      review_item(
        "blocker-\{index}",
        decision_severity(dossier.traverse.decision),
        blocker,
        "operator",
      ),
    )
  }
  for index, reason in dossier.traverse.reasons {
    items.push(
      review_item(
        "traverse-\{index}",
        decision_severity(dossier.traverse.decision),
        reason,
        "mission-review",
      ),
    )
  }
  for route in dossier.route_candidates {
    if route.decision != @mission.TraverseDecision::Allow {
      items.push(
        review_item(
          "route-\{route.route_id}",
          decision_severity(route.decision),
          "\{route.label} from \{route.evidence_dataset_id}: \{route.next_action}",
          "mission-review",
        ),
      )
    }
    if route.illumination.decision != @mission.TraverseDecision::Allow {
      items.push(
        review_item(
          "illumination-\{route.route_id}",
          decision_severity(route.illumination.decision),
          "\{route.label}: \{route.illumination.next_action}",
          "power-thermal-review",
        ),
      )
    }
  }
  let best = dossier.corridor_scan[0]
  if best.decision != @mission.TraverseDecision::Allow {
    items.push(
      review_item(
        "corridor-scan-best-window",
        decision_severity(best.decision),
        "best measured corridor window \{best.window_id} selects \{best.selected_route_id} but remains \{@mission.corridor_scan_window_status_label(best)}: \{best.note}",
        "mission-review",
      ),
    )
  }
  for index, question in dossier.next_questions {
    items.push(review_item("question-\{index}", "low", question, "moonclaw"))
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
  entries.push(corridor_scan_entry(dossier))
  for entry in route_candidate_entries(dossier) {
    entries.push(entry)
  }
  for entry in illumination_entries(dossier) {
    entries.push(entry)
  }
  let raw_review_queue = open_review_queue(dossier)
  let review_transitions = review_transitions_for_queue(raw_review_queue)
  {
    workspace: "moonbook://moonmoon/first-trusted-square",
    site_id: dossier.site.site_id,
    title: "Moonmoon evidence dossier: \{dossier.site.name}",
    entries,
    review_queue: apply_review_transitions(raw_review_queue, review_transitions),
    review_transitions,
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
      text += "- \{item.item_id} [\{item.severity}/\{review_item_status_label(item.status)}] \{item.reason} -> \{item.owner}\n"
    }
  }
  text += "\n## Review Transitions\n\n"
  if dossier.review_transitions.is_empty() {
    text += "- empty\n"
  } else {
    for transition in dossier.review_transitions {
      text += "- \{transition.transition_id}: \{review_decision_label(transition.decision)} \{transition.item_id} -> \{review_item_status_label(transition.resulting_status)}\n"
      text += "  - reviewer: \{transition.reviewer}\n"
      text += "  - rationale: \{transition.rationale}\n"
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
