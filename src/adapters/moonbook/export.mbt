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
  LocalHorizonEvidence
  TerrainRemediationEvidence
  PowerWindowEvidence
  EnergyWindow
  EnergyRemediationEvidence
  SelectedRouteClearance
  MoonroboHandoff
  MoonroboNoetixWalk
  MoonroboNoetixPhysics
  MoonroboNoetixDynamics
  MoonroboNoetixLinkPoses
  MoonroboGapModeling
  MoonroboRemediationMarginModeling
  MoonroboRemediationMarginProjection
  MoonroboRemediationMarginRefreshModeling
  MoonroboRemediationMarginRefreshFollowupModeling
  MoonroboRemediationMarginRefreshProjection
  MoonroboRemediationMarginRefreshFollowupProjection
  MoonroboRemediationMarginCycleCloseoutPolicy
  MoonroboRemediationMarginRegeneratedReceiptReadiness
  MoonroboRegeneratedReceiptReadinessActionReceiptCloseout
  MoonroboSimulationReviewPacket
  MoonClawProposal
  MoonClawTask
  MoonClawNoetixReviewTask
  MoonClawRemediationMarginRefreshTask
  MoonClawRemediationMarginRefreshFollowupTask
  MoonClawRemediationMarginCloseoutActionTask
  MoonClawRemediationMarginReviewedActionPlan
  MoonClawRemediationMarginReviewedWorkItems
  MoonClawRemediationMarginReviewedWorkItemReceipts
  MoonClawRemediationMarginReviewedFreshEvidenceTask
  MoonClawRemediationMarginFreshEvidenceActionReceipts
  MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipts
  MoonClawRegeneratedReceiptReadinessFreshEvidenceTask
  MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipts
  MoonClawRemediationMarginRefreshReceipt
  MoonClawRemediationMarginRefreshFollowupReceipt
  MoonClawReceipt
  MoonClawRemediationMarginReceipt
  MoonClawEphemerisReceipt
  MoonClawCorridorReceipt
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
pub(all) struct ReviewEvidenceReference {
  ref_id : String
  entry_id : String
  path : String
  immutable_uri : String
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
  previous_status : ReviewItemStatus
  decision : ReviewDecision
  resulting_status : ReviewItemStatus
  reviewer_id : String
  reviewer_role : String
  timestamp_policy : String
  recorded_at_utc : String
  append_only : Bool
  source_evidence_refs : Array[ReviewEvidenceReference]
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonBookDossier {
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
    LocalHorizonEvidence => "local-horizon-evidence"
    TerrainRemediationEvidence => "terrain-remediation-evidence"
    PowerWindowEvidence => "power-window-evidence"
    EnergyWindow => "energy-window"
    EnergyRemediationEvidence => "energy-remediation-evidence"
    SelectedRouteClearance => "selected-route-clearance"
    MoonroboHandoff => "moonrobo-handoff"
    MoonroboNoetixWalk => "moonrobo-noetix-walk"
    MoonroboNoetixPhysics => "moonrobo-noetix-physics"
    MoonroboNoetixDynamics => "moonrobo-noetix-dynamics"
    MoonroboNoetixLinkPoses => "moonrobo-noetix-link-poses"
    MoonroboGapModeling => "moonrobo-gap-modeling"
    MoonroboRemediationMarginModeling => "moonrobo-remediation-margin-modeling"
    MoonroboRemediationMarginProjection =>
      "moonrobo-remediation-margin-projection"
    MoonroboRemediationMarginRefreshModeling =>
      "moonrobo-remediation-margin-refresh-modeling"
    MoonroboRemediationMarginRefreshFollowupModeling =>
      "moonrobo-remediation-margin-refresh-followup-modeling"
    MoonroboRemediationMarginRefreshProjection =>
      "moonrobo-remediation-margin-refresh-projection"
    MoonroboRemediationMarginRefreshFollowupProjection =>
      "moonrobo-remediation-margin-refresh-followup-projection"
    MoonroboRemediationMarginCycleCloseoutPolicy =>
      "moonrobo-remediation-margin-cycle-closeout-policy"
    MoonroboRemediationMarginRegeneratedReceiptReadiness =>
      "moonrobo-remediation-margin-regenerated-receipt-readiness"
    MoonroboRegeneratedReceiptReadinessActionReceiptCloseout =>
      "moonrobo-regenerated-receipt-readiness-action-receipt-closeout"
    MoonroboSimulationReviewPacket => "moonrobo-simulation-review-packet"
    MoonClawProposal => "moonclaw-proposal"
    MoonClawTask => "moonclaw-task"
    MoonClawNoetixReviewTask => "moonclaw-noetix-review-task"
    MoonClawRemediationMarginRefreshTask =>
      "moonclaw-remediation-margin-refresh-task"
    MoonClawRemediationMarginRefreshFollowupTask =>
      "moonclaw-remediation-margin-refresh-followup-task"
    MoonClawRemediationMarginCloseoutActionTask =>
      "moonclaw-remediation-margin-closeout-action-task"
    MoonClawRemediationMarginReviewedActionPlan =>
      "moonclaw-remediation-margin-reviewed-action-plan"
    MoonClawRemediationMarginReviewedWorkItems =>
      "moonclaw-remediation-margin-reviewed-work-items"
    MoonClawRemediationMarginReviewedWorkItemReceipts =>
      "moonclaw-remediation-margin-reviewed-work-item-receipts"
    MoonClawRemediationMarginReviewedFreshEvidenceTask =>
      "moonclaw-remediation-margin-reviewed-fresh-evidence-task"
    MoonClawRemediationMarginFreshEvidenceActionReceipts =>
      "moonclaw-remediation-margin-fresh-evidence-action-receipts"
    MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipts =>
      "moonclaw-remediation-margin-regenerated-reviewed-work-item-receipts"
    MoonClawRegeneratedReceiptReadinessFreshEvidenceTask =>
      "moonclaw-regenerated-receipt-readiness-fresh-evidence-task"
    MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipts =>
      "moonclaw-regenerated-receipt-readiness-fresh-evidence-action-receipts"
    MoonClawRemediationMarginRefreshReceipt =>
      "moonclaw-remediation-margin-refresh-receipt"
    MoonClawRemediationMarginRefreshFollowupReceipt =>
      "moonclaw-remediation-margin-refresh-followup-receipt"
    MoonClawReceipt => "moonclaw-receipt"
    MoonClawRemediationMarginReceipt => "moonclaw-remediation-margin-receipt"
    MoonClawEphemerisReceipt => "moonclaw-ephemeris-receipt"
    MoonClawCorridorReceipt => "moonclaw-corridor-receipt"
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
fn review_transition_for_item(
  transitions : Array[ReviewTransition],
  item_id : String,
) -> ReviewTransition? {
  for transition in transitions {
    if transition.item_id == item_id {
      return Some(transition)
    }
  }
  None
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
fn review_evidence_ref(
  workspace : String,
  ref_id : String,
  entry_id : String,
  path : String,
) -> ReviewEvidenceReference {
  { ref_id, entry_id, path, immutable_uri: "\{workspace}/\{path}" }
}

///|
fn review_evidence_refs(
  item : ReviewQueueItem,
  dossier : @site.SiteDossier,
) -> Array[ReviewEvidenceReference] {
  let workspace = "moonbook://moonmoon/first-trusted-square"
  let refs : Array[ReviewEvidenceReference] = []
  if item.item_id == "workspace-materialized" {
    refs.push(
      review_evidence_ref(
        workspace, "workspace-index", "workspace/index", "index.json",
      ),
    )
  }
  for candidate in dossier.source_candidates {
    if item.item_id == "source-candidate-\{candidate.candidate_id}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "source-candidate-\{candidate.candidate_id}",
          "source-candidate/\{candidate.candidate_id}",
          "source-candidates/\{candidate.candidate_id}.json",
        ),
      )
    }
  }
  for validation in dossier.validations {
    if item.item_id == "validation-\{validation.dataset_id}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "validation-\{validation.dataset_id}",
          "validation/\{validation.dataset_id}",
          "datasets/\{validation.dataset_id}.validation.json",
        ),
      )
    }
  }
  for index, _blocker in dossier.blockers {
    if item.item_id == "blocker-\{index}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "traverse-blocker-\{index}",
          "mission/\{dossier.site.site_id}/traverse",
          "mission/\{dossier.site.site_id}/traverse.json",
        ),
      )
    }
  }
  for index, _reason in dossier.traverse.reasons {
    if item.item_id == "traverse-\{index}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "traverse-reason-\{index}",
          "mission/\{dossier.site.site_id}/traverse",
          "mission/\{dossier.site.site_id}/traverse.json",
        ),
      )
    }
  }
  for route in dossier.route_candidates {
    if item.item_id == "route-\{route.route_id}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "route-\{route.route_id}",
          "route/\{dossier.site.site_id}/\{route.route_id}",
          "mission/\{dossier.site.site_id}/routes/\{route.route_id}.json",
        ),
      )
    }
    if item.item_id == "illumination-\{route.route_id}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "illumination-\{route.route_id}",
          "illumination/\{dossier.site.site_id}/\{route.route_id}",
          "mission/\{dossier.site.site_id}/routes/\{route.route_id}.illumination.json",
        ),
      )
    }
  }
  if item.item_id == "corridor-scan-best-window" {
    refs.push(
      review_evidence_ref(
        workspace,
        "corridor-scan-best-window",
        "corridor/\{dossier.site.site_id}/first-trusted-square-9x9",
        "mission/\{dossier.site.site_id}/corridor-scan.json",
      ),
    )
  }
  if item.item_id == "power-window-evidence" {
    refs.push(
      review_evidence_ref(
        workspace,
        "power-window-evidence",
        "power-window/\{dossier.site.site_id}/ephemeris-evidence",
        "mission/\{dossier.site.site_id}/power-window-evidence.json",
      ),
    )
  }
  if item.item_id == "energy-window" {
    refs.push(
      review_evidence_ref(
        workspace,
        "energy-window",
        "energy/\{dossier.site.site_id}/conservative-window",
        "mission/\{dossier.site.site_id}/energy-window.json",
      ),
    )
  }
  if item.item_id == "moonrobo-handoff" {
    refs.push(
      review_evidence_ref(
        workspace,
        "moonrobo-handoff",
        "moonrobo/\{dossier.site.site_id}/simulation-preconditions",
        "moonrobo/\{dossier.site.site_id}/handoffs.json",
      ),
    )
  }
  if item.item_id == "selected-route-clearance" {
    refs.push(
      review_evidence_ref(
        workspace,
        "selected-route-clearance",
        "mission/\{dossier.site.site_id}/selected-route-clearance",
        "mission/\{dossier.site.site_id}/selected-route-clearance.json",
      ),
    )
  }
  let primary_handoff = @moonrobo.route_handoff(
    dossier,
    primary_route_candidate(dossier),
  )
  for clearance in primary_handoff.clearance_plan.items {
    if item.item_id == clearance.clearance_id {
      refs.push(
        review_evidence_ref(
          workspace,
          clearance.clearance_id,
          "mission/\{dossier.site.site_id}/selected-route-clearance",
          "mission/\{dossier.site.site_id}/selected-route-clearance.json",
        ),
      )
    }
  }
  if item.item_id == "moonclaw-proposals" {
    refs.push(
      review_evidence_ref(
        workspace,
        "moonclaw-proposals",
        "moonclaw/\{dossier.site.site_id}/modeling-proposals",
        "moonclaw/\{dossier.site.site_id}/proposals.json",
      ),
    )
  }
  if item.item_id == "moonclaw-ephemeris-task" {
    refs.push(
      review_evidence_ref(
        workspace,
        "moonclaw-ephemeris-task",
        "moonclaw/\{dossier.site.site_id}/ephemeris-acquisition-task",
        "moonclaw/\{dossier.site.site_id}/ephemeris-task.json",
      ),
    )
  }
  if item.item_id == "moonclaw-corridor-task" {
    refs.push(
      review_evidence_ref(
        workspace,
        "moonclaw-corridor-task",
        "moonclaw/\{dossier.site.site_id}/corridor-expansion-task",
        "moonclaw/\{dossier.site.site_id}/corridor-task.json",
      ),
    )
  }
  for index, _question in dossier.next_questions {
    if item.item_id == "question-\{index}" {
      refs.push(
        review_evidence_ref(
          workspace,
          "question-\{index}",
          "site/\{dossier.site.site_id}/next-question-\{index}",
          "review_queue.json",
        ),
      )
    }
  }
  refs
}

///|
fn make_review_transition(
  item : ReviewQueueItem,
  dossier : @site.SiteDossier,
) -> ReviewTransition {
  let decision = review_decision_for_item(item)
  {
    transition_id: transition_id(item, decision),
    item_id: item.item_id,
    previous_status: item.status,
    decision,
    resulting_status: resulting_status_for_decision(decision),
    reviewer_id: "operator/moonbook-policy-v1",
    reviewer_role: item.owner,
    timestamp_policy: "deterministic-evidence-window-start",
    recorded_at_utc: dossier.power_window_evidence.time_start_utc,
    append_only: true,
    source_evidence_refs: review_evidence_refs(item, dossier),
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
  dossier : @site.SiteDossier,
  imported_transitions : Array[ReviewTransition],
) -> Array[ReviewTransition] {
  let transitions : Array[ReviewTransition] = []
  for item in items {
    match review_transition_for_item(imported_transitions, item.item_id) {
      Some(transition) => transitions.push(transition)
      None => transitions.push(make_review_transition(item, dossier))
    }
  }
  transitions
}

///|
fn clearance_review_decision(
  decision : ReviewDecision,
) -> @mission.MissionClearanceReviewDecision? {
  match decision {
    Accept => Some(@mission.MissionClearanceReviewDecision::ClearanceAccept)
    Reject => Some(@mission.MissionClearanceReviewDecision::ClearanceReject)
    RequestEvidence =>
      Some(@mission.MissionClearanceReviewDecision::ClearanceRequestEvidence)
    KeepOpen => None
  }
}

///|
fn first_evidence_ref(transition : ReviewTransition) -> String {
  if transition.source_evidence_refs.is_empty() {
    ""
  } else {
    transition.source_evidence_refs[0].immutable_uri
  }
}

///|
fn clearance_transition_from_review_transition(
  transition : ReviewTransition,
) -> @mission.MissionClearanceTransition? {
  if !transition.item_id.has_prefix("clear-") {
    return None
  }
  match clearance_review_decision(transition.decision) {
    Some(decision) =>
      Some(
        @mission.clearance_transition(
          transition.transition_id,
          transition.item_id,
          decision,
          transition.reviewer_id,
          transition.recorded_at_utc,
          first_evidence_ref(transition),
          transition.rationale,
        ),
      )
    None => None
  }
}

///|
pub fn clearance_transitions_from_review_transitions(
  transitions : Array[ReviewTransition],
) -> Array[@mission.MissionClearanceTransition] {
  let clearance_transitions : Array[@mission.MissionClearanceTransition] = []
  for transition in transitions {
    match clearance_transition_from_review_transition(transition) {
      Some(clearance_transition) =>
        clearance_transitions.push(clearance_transition)
      None => ()
    }
  }
  clearance_transitions
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
fn blocker_count_label(count : Int) -> String {
  if count == 1 {
    "1 blocker"
  } else {
    "\{count} blockers"
  }
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
  let selected_route = if best.selected_route_id == "" {
    "no promoted route yet"
  } else {
    best.selected_route_id
  }
  {
    entry_id: "corridor/\{dossier.site.site_id}/first-trusted-square-9x9",
    title: "9x9 LOLA corridor scan for \{dossier.site.name}",
    kind: CorridorScan,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.75,
    path: "mission/\{dossier.site.site_id}/corridor-scan.json",
    summary: "best window \{best.window_id} rank \{best.rank} selects \{selected_route}: \{@mission.corridor_scan_window_status_label(best)} with grade \{best.max_neighbor_grade} and roughness \{best.roughness_m} m",
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
fn selected_route_horizon_entry(dossier : @site.SiteDossier) -> BookEntry {
  let route = primary_route_candidate(dossier)
  let horizon = route.illumination.local_horizon
  {
    entry_id: "local-horizon/\{dossier.site.site_id}/\{route.route_id}",
    title: "Local horizon evidence for \{route.label}",
    kind: LocalHorizonEvidence,
    claim_kind: @core.ClaimKind::Derived,
    confidence: horizon.confidence,
    path: "mission/\{dossier.site.site_id}/\{route.route_id}-horizon.json",
    summary: "\{@mission.traverse_decision_label(horizon.decision)} with terrain-shadow margin \{horizon.terrain_shadow_margin_deg} deg from \{horizon.source_path}",
  }
}

///|
fn selected_route_terrain_remediation_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let route = primary_route_candidate(dossier)
  let remediation = route.terrain_remediation
  {
    entry_id: "terrain-remediation/\{dossier.site.site_id}/\{route.route_id}",
    title: "Terrain remediation evidence for \{route.label}",
    kind: TerrainRemediationEvidence,
    claim_kind: @core.ClaimKind::Derived,
    confidence: remediation.confidence,
    path: "mission/\{dossier.site.site_id}/\{route.route_id}-terrain-remediation.json",
    summary: "\{@mission.traverse_decision_label(remediation.decision)} with grade margin \{remediation.grade_margin} and roughness margin \{remediation.roughness_margin_m} m from \{remediation.source_path}",
  }
}

///|
fn energy_entry(dossier : @site.SiteDossier) -> BookEntry {
  {
    entry_id: "energy/\{dossier.site.site_id}/conservative-window",
    title: "Energy window budget for \{dossier.site.name}",
    kind: EnergyWindow,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.45,
    path: "mission/\{dossier.site.site_id}/energy-window.json",
    summary: "\{@mission.energy_decision_label(dossier.energy)} with \{dossier.energy.required_energy_wh} Wh required and \{dossier.energy.available_energy_wh} Wh verified available: \{dossier.energy.next_action}",
  }
}

///|
fn selected_route_energy_remediation_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let route = primary_route_candidate(dossier)
  let remediation = @mission.first_trusted_square_energy_remediation()
  {
    entry_id: "energy-remediation/\{dossier.site.site_id}/\{route.route_id}",
    title: "Energy remediation evidence for \{route.label}",
    kind: EnergyRemediationEvidence,
    claim_kind: @core.ClaimKind::Derived,
    confidence: remediation.confidence,
    path: "mission/\{dossier.site.site_id}/energy-remediation.json",
    summary: "\{@mission.energy_remediation_decision_label(remediation)} with bounded margin \{remediation.bounded_margin_wh} Wh and margin gap \{remediation.margin_gap_wh} Wh from \{remediation.power_window_source_path}",
  }
}

///|
fn power_window_evidence_entry(dossier : @site.SiteDossier) -> BookEntry {
  let evidence = dossier.power_window_evidence
  {
    entry_id: "power-window/\{dossier.site.site_id}/ephemeris-evidence",
    title: "Power-window evidence for \{dossier.site.name}",
    kind: PowerWindowEvidence,
    claim_kind: @core.ClaimKind::Derived,
    confidence: evidence.confidence,
    path: "mission/\{dossier.site.site_id}/power-window-evidence.json",
    summary: "\{evidence.source_status} \{evidence.evidence_id}: \{evidence.available_energy_wh} Wh verified from \{evidence.local_source_path}",
  }
}

///|
fn primary_route_candidate(
  dossier : @site.SiteDossier,
) -> @mission.RouteCandidate {
  let selected_route_id = dossier.corridor_scan[0].selected_route_id
  let mut selected_route = dossier.route_candidates[0]
  for route in dossier.route_candidates {
    if route.route_id == selected_route_id {
      selected_route = route
    }
  }
  selected_route
}

///|
fn moonrobo_handoff_entry(
  dossier : @site.SiteDossier,
  clearance_transitions : Array[@mission.MissionClearanceTransition],
) -> BookEntry {
  let selected_route = primary_route_candidate(dossier)
  let handoff = @moonrobo.route_handoff_with_clearance_transitions(
    dossier, selected_route, clearance_transitions,
  )
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/simulation-preconditions",
    title: "Moonrobo simulation preconditions for \{dossier.site.name}",
    kind: MoonroboHandoff,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.6,
    path: "moonrobo/\{dossier.site.site_id}/handoffs.json",
    summary: "\{@moonrobo.handoff_status_label(handoff)} primary route \{handoff.route_id}: \{handoff.next_action}",
  }
}

///|
fn moonrobo_noetix_walk_entry(dossier : @site.SiteDossier) -> BookEntry {
  let trace = @moonrobo.first_trusted_square_noetix_walk_trace()
  let joint_count = if trace.frames.is_empty() {
    0
  } else {
    trace.frames[0].joint_phases.length()
  }
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/noetix-walk",
    title: "Moonrobo Noetix endless moon-walk trace for \{dossier.site.name}",
    kind: MoonroboNoetixWalk,
    claim_kind: @core.ClaimKind::Simulated,
    confidence: 0.62,
    path: "moonrobo/\{dossier.site.site_id}/noetix-walk.json",
    summary: "\{trace.robot.robot_id} kinematic endless walk over \{trace.terrain_tile_id} with \{trace.frame_count} frames, \{joint_count} joint phases per frame, and hardware authority denied",
  }
}

///|
fn moonrobo_noetix_physics_entry(dossier : @site.SiteDossier) -> BookEntry {
  let report = @moonrobo.first_trusted_square_noetix_stability_report()
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/noetix-physics",
    title: "Moonrobo Noetix physics assumptions and static support report for \{dossier.site.name}",
    kind: MoonroboNoetixPhysics,
    claim_kind: @core.ClaimKind::Simulated,
    confidence: 0.54,
    path: "moonrobo/\{dossier.site.site_id}/noetix-physics.json",
    summary: "\{report.profile.robot_id} \{report.profile.status} profile uses explicit mass/sole/friction assumptions; \{report.review_frame_count}/\{report.frame_count} frames need static-support review, worst margin \{report.worst_planar_margin_m} m, hardware authority \{report.profile.hardware_authority}",
  }
}

///|
fn moonrobo_noetix_link_poses_entry(dossier : @site.SiteDossier) -> BookEntry {
  let trace = @moonrobo.first_trusted_square_noetix_link_pose_trace()
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/noetix-link-poses",
    title: "Moonrobo Noetix URDF-reference link poses for \{dossier.site.name}",
    kind: MoonroboNoetixLinkPoses,
    claim_kind: @core.ClaimKind::Simulated,
    confidence: 0.56,
    path: "moonrobo/\{dossier.site.site_id}/noetix-link-poses.json",
    summary: "\{trace.robot_id} review-only link pose trace has \{trace.frame_count} frames and \{trace.links_per_frame} URDF-reference links per frame; non-foot links use URDF forward kinematics, feet are contact-bound, and no hardware authority is implied",
  }
}

///|
fn moonrobo_noetix_dynamics_entry(dossier : @site.SiteDossier) -> BookEntry {
  let report = @moonrobo.first_trusted_square_noetix_dynamic_stability_report()
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/noetix-dynamics",
    title: "Moonrobo Noetix dynamic stability evidence for \{dossier.site.name}",
    kind: MoonroboNoetixDynamics,
    claim_kind: @core.ClaimKind::Simulated,
    confidence: 0.55,
    path: "moonrobo/\{dossier.site.site_id}/noetix-dynamics.json",
    summary: "\{report.profile.robot_id} capture-point report has \{report.review_frame_count}/\{report.frame_count} review frames, worst capture margin \{report.worst_capture_margin_m} m, status \{report.status}, hardware authority \{report.hardware_authority}",
  }
}

///|
fn moonclaw_noetix_review_task_entry(dossier : @site.SiteDossier) -> BookEntry {
  let task = @moonclaw.first_trusted_square_noetix_review_task()
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/noetix-review-task",
    title: "MoonClaw Noetix simulation review task for \{dossier.site.name}",
    kind: MoonClawNoetixReviewTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.58,
    path: "moonclaw/\{dossier.site.site_id}/noetix-review-task.json",
    summary: "\{task.robot_id} review task links walk, link poses, static support, dynamic stability, and Rabbita playback; \{task.dynamic_stability_review_frame_count}/\{task.frame_count} frames require dynamic-stability review, hardware authority \{task.hardware_authority}",
  }
}

///|
fn selected_route_clearance_entry(
  dossier : @site.SiteDossier,
  clearance_transitions : Array[@mission.MissionClearanceTransition],
) -> BookEntry {
  let selected_route = primary_route_candidate(dossier)
  let handoff = @moonrobo.route_handoff_with_clearance_transitions(
    dossier, selected_route, clearance_transitions,
  )
  let plan = handoff.clearance_plan
  {
    entry_id: "mission/\{dossier.site.site_id}/selected-route-clearance",
    title: "Selected route clearance plan for \{dossier.site.name}",
    kind: SelectedRouteClearance,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.62,
    path: "mission/\{dossier.site.site_id}/selected-route-clearance.json",
    summary: "\{@mission.traverse_decision_label(plan.decision)} \{plan.route_id}: \{plan.items.length()} clearance items, \{plan.blocking_items.length()} blockers",
  }
}

///|
fn moonclaw_proposal_entry(dossier : @site.SiteDossier) -> BookEntry {
  let proposal = @moonclaw.ephemeris_acquisition_proposal(dossier)
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/modeling-proposals",
    title: "MoonClaw modeling proposals for \{dossier.site.name}",
    kind: MoonClawProposal,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.65,
    path: "moonclaw/\{dossier.site.site_id}/proposals.json",
    summary: "\{@moonclaw.priority_label(proposal.priority)} \{@moonclaw.job_kind_label(proposal.job_kind)} job: \{proposal.objective}",
  }
}

///|
fn moonclaw_ephemeris_task_entry(dossier : @site.SiteDossier) -> BookEntry {
  let task = @moonclaw.ephemeris_acquisition_task(dossier)
  let blockers = @moonclaw.task_blocked_artifact_count(task)
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/ephemeris-acquisition-task",
    title: "MoonClaw ephemeris acquisition task for \{dossier.site.name}",
    kind: MoonClawTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.6,
    path: "moonclaw/\{dossier.site.site_id}/ephemeris-task.json",
    summary: "\{@moonclaw.receipt_status_label(task.state)} task tracks \{task.artifacts.length()} artifacts with \{blocker_count_label(blockers)} before Moonrobo power evidence can unblock",
  }
}

///|
fn moonclaw_corridor_task_entry(dossier : @site.SiteDossier) -> BookEntry {
  let task = @moonclaw.corridor_expansion_task(dossier)
  let blockers = @moonclaw.corridor_task_blocked_artifact_count(task)
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/corridor-expansion-task",
    title: "MoonClaw corridor expansion task for \{dossier.site.name}",
    kind: MoonClawTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.65,
    path: "moonclaw/\{dossier.site.site_id}/corridor-task.json",
    summary: "\{@moonclaw.receipt_status_label(task.state)} task plans \{task.planned_window_count} windows with \{blocker_count_label(blockers)} before route promotion",
  }
}

///|
fn moonclaw_remediation_margin_task_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let task = @moonclaw.first_trusted_square_remediation_margin_task()
  let blockers = @moonclaw.remediation_margin_task_blocked_artifact_count(task)
  let margin_ids = task.active_margin_ids.join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-task",
    title: "MoonClaw remediation-margin task for \{dossier.site.name}",
    kind: MoonClawTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.68,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-task.json",
    summary: "\{@moonclaw.receipt_status_label(task.state)} task preserves \{task.active_margin_count} active remediation margins (\{margin_ids}) with \{blocker_count_label(blockers)} and hardware authority \{task.hardware_authority} at \{@moonrobo.execution_state_label(task.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_refresh_task_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let task = @moonclaw.first_trusted_square_remediation_margin_refresh_task()
  let margin_ids = task.ranked_margin_ids.join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-task",
    title: "MoonClaw remediation-margin refresh task for \{dossier.site.name}",
    kind: MoonClawRemediationMarginRefreshTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.72,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-task.json",
    summary: "\{@moonclaw.receipt_status_label(task.state)} refresh task consumes \{@moonrobo.remediation_margin_projection_status_label(task.source_projection_status)} with \{task.blocking_margin_count} ranked refreshes (\{margin_ids}); simulation \{@moonrobo.execution_state_label(task.source_simulation_state)}, may consume \{task.may_consume_simulation}, hardware authority \{task.hardware_authority} at \{@moonrobo.execution_state_label(task.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_refresh_receipt_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipt = @moonclaw.first_trusted_square_remediation_margin_refresh_receipt()
  let margin_ids = receipt.refresh_results
    .map(fn(result) { result.margin_id })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-receipt",
    title: "MoonClaw remediation-margin refresh receipt for \{dossier.site.name}",
    kind: MoonClawRemediationMarginRefreshReceipt,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-receipt.json",
    summary: "\{@moonclaw.remediation_margin_refresh_state_label(receipt.refresh_state)} with \{receipt.still_blocking_count} still-blocking refreshes (\{margin_ids}), \{receipt.refreshed_count} refreshed, source projection \{receipt.source_projection_id}, and hardware authority \{receipt.hardware_authority} at \{@moonrobo.execution_state_label(receipt.hardware_state)}",
  }
}

///|
fn moonclaw_receipt_entry(dossier : @site.SiteDossier) -> BookEntry {
  let receipt = @moonclaw.route_scoring_receipt(dossier)
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/route-scoring-receipt",
    title: "MoonClaw route-scoring receipt for \{dossier.site.name}",
    kind: MoonClawReceipt,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonclaw/\{dossier.site.site_id}/receipts.json",
    summary: "\{@moonclaw.receipt_status_label(receipt.receipt.status)} receipt keeps primary Moonrobo handoff \{@mission.traverse_decision_label(receipt.moonrobo_handoff_decision)}: \{receipt.next_action}",
  }
}

///|
fn moonclaw_remediation_margin_receipt_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipt = @moonclaw.first_trusted_square_remediation_margin_receipt()
  let margin_ids = receipt.margin_results
    .map(fn(result) { result.margin_id })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-receipt",
    title: "MoonClaw remediation-margin receipt for \{dossier.site.name}",
    kind: MoonClawRemediationMarginReceipt,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-receipt.json",
    summary: "\{@moonclaw.remediation_margin_state_label(receipt.remediation_state)} with \{receipt.still_blocking_margin_count} remediation margins still blocking (\{margin_ids}), \{receipt.cleared_margin_count} cleared, and hardware authority \{receipt.hardware_authority} at \{@moonrobo.execution_state_label(receipt.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_modeling_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let pass = @moonrobo.first_trusted_square_remediation_margin_modeling_pass()
  let margin_ids = pass.margin_results
    .map(fn(result) { result.margin_id })
    .join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-modeling",
    title: "MoonRobo remediation-margin modeling pass for \{dossier.site.name}",
    kind: MoonroboRemediationMarginModeling,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.68,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-modeling.json",
    summary: "\{@moonrobo.remediation_margin_modeling_state_label(pass.state)} with \{pass.still_blocking_margin_count} still-blocking margins (\{margin_ids}) from \{pass.source_remediation_state}; hardware authority \{pass.hardware_authority} at \{@moonrobo.execution_state_label(pass.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_projection_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let projection = @moonrobo.first_trusted_square_remediation_margin_projection()
  let margin_ids = projection.blocking_margin_ids.join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-projection",
    title: "MoonRobo remediation-margin projection for \{dossier.site.name}",
    kind: MoonroboRemediationMarginProjection,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-projection.json",
    summary: "\{@moonrobo.remediation_margin_projection_status_label(projection.projection_status)} from \{@moonrobo.remediation_margin_modeling_state_label(projection.source_modeling_state)} with \{projection.still_blocking_margin_count} still-blocking margins (\{margin_ids}); simulation \{@moonrobo.execution_state_label(projection.simulation_state)}, hardware authority \{projection.hardware_authority} at \{@moonrobo.execution_state_label(projection.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_refresh_modeling_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let pass = @moonrobo.first_trusted_square_remediation_margin_refresh_modeling_pass()
  let margin_ids = pass.refresh_results
    .map(fn(result) { result.margin_id })
    .join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-modeling",
    title: "MoonRobo remediation-margin refresh modeling pass for \{dossier.site.name}",
    kind: MoonroboRemediationMarginRefreshModeling,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-modeling.json",
    summary: "\{@moonrobo.remediation_margin_refresh_modeling_state_label(pass.state)} with \{pass.still_blocking_count} still-blocking refreshes (\{margin_ids}), \{pass.refreshed_count} refreshed, source receipt \{pass.source_receipt_id}, no-consume simulation \{@moonrobo.execution_state_label(pass.simulation_state)}, and hardware authority \{pass.hardware_authority} at \{@moonrobo.execution_state_label(pass.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_refresh_projection_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let projection = @moonrobo.first_trusted_square_remediation_margin_refresh_projection()
  let refresh_ids = projection.blocking_refresh_ids.join(", ")
  let margin_ids = projection.blocking_margin_ids.join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-projection",
    title: "MoonRobo remediation-margin refresh projection for \{dossier.site.name}",
    kind: MoonroboRemediationMarginRefreshProjection,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-projection.json",
    summary: "\{@moonrobo.remediation_margin_refresh_projection_status_label(projection.projection_status)} from \{@moonrobo.remediation_margin_refresh_modeling_state_label(projection.source_modeling_state)} with \{projection.still_blocking_count} still-blocking refreshes (\{refresh_ids}) over margins (\{margin_ids}); simulation \{@moonrobo.execution_state_label(projection.simulation_state)}, hardware authority \{projection.hardware_authority} at \{@moonrobo.execution_state_label(projection.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_refresh_followup_task_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let task = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_task()
  let refresh_ids = task.blocking_refresh_ids.join(", ")
  let margin_ids = task.blocking_margin_ids.join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-followup-task",
    title: "MoonClaw remediation-margin refresh follow-up task for \{dossier.site.name}",
    kind: MoonClawRemediationMarginRefreshFollowupTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.72,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-followup-task.json",
    summary: "\{@moonclaw.receipt_status_label(task.state)} follow-up task consumes \{@moonrobo.remediation_margin_refresh_projection_status_label(task.source_projection_status)} from \{@moonrobo.remediation_margin_refresh_modeling_state_label(task.source_modeling_state)} with \{task.blocking_refresh_count} blocking refreshes (\{refresh_ids}) over margins (\{margin_ids}); simulation \{@moonrobo.execution_state_label(task.source_simulation_state)}, may consume \{task.may_consume_simulation}, hardware authority \{task.hardware_authority} at \{@moonrobo.execution_state_label(task.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_refresh_followup_receipt_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipt = @moonclaw.first_trusted_square_remediation_margin_refresh_followup_receipt()
  let refresh_ids = receipt.blocking_refresh_ids.join(", ")
  let margin_ids = receipt.blocking_margin_ids.join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-followup-receipt",
    title: "MoonClaw remediation-margin refresh follow-up receipt for \{dossier.site.name}",
    kind: MoonClawRemediationMarginRefreshFollowupReceipt,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-refresh-followup-receipt.json",
    summary: "\{@moonclaw.remediation_margin_refresh_followup_state_label(receipt.refresh_state)} with \{receipt.still_blocking_count} still-blocking follow-up refreshes (\{refresh_ids}) over margins (\{margin_ids}), \{receipt.refreshed_count} refreshed, source task \{receipt.source_task_id}, source projection \{receipt.source_refresh_projection_id}, simulation \{@moonrobo.execution_state_label(receipt.source_simulation_state)}, may consume \{receipt.may_consume_simulation}, and hardware authority \{receipt.hardware_authority} at \{@moonrobo.execution_state_label(receipt.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_refresh_followup_modeling_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let pass = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_modeling_pass()
  let refresh_ids = pass.followup_results
    .map(fn(result) { result.refresh_id })
    .join(", ")
  let margin_ids = pass.followup_results
    .map(fn(result) { result.margin_id })
    .join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-followup-modeling",
    title: "MoonRobo remediation-margin refresh follow-up modeling pass for \{dossier.site.name}",
    kind: MoonroboRemediationMarginRefreshFollowupModeling,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-followup-modeling.json",
    summary: "\{@moonrobo.remediation_margin_refresh_followup_modeling_state_label(pass.state)} with \{pass.still_blocking_count} still-blocking follow-up refreshes (\{refresh_ids}) over margins (\{margin_ids}), \{pass.refreshed_count} refreshed, source receipt \{pass.source_receipt_id}, source projection \{pass.source_refresh_projection_id}, no-consume simulation \{@moonrobo.execution_state_label(pass.simulation_state)}, and hardware authority \{pass.hardware_authority} at \{@moonrobo.execution_state_label(pass.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_refresh_followup_projection_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let projection = @moonrobo.first_trusted_square_remediation_margin_refresh_followup_projection()
  let refresh_ids = projection.blocking_refresh_ids.join(", ")
  let margin_ids = projection.blocking_margin_ids.join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-followup-projection",
    title: "MoonRobo remediation-margin refresh follow-up projection for \{dossier.site.name}",
    kind: MoonroboRemediationMarginRefreshFollowupProjection,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-refresh-followup-projection.json",
    summary: "\{@moonrobo.remediation_margin_refresh_followup_projection_status_label(projection.projection_status)} from \{@moonrobo.remediation_margin_refresh_followup_modeling_state_label(projection.source_modeling_state)} with \{projection.still_blocking_count} still-blocking follow-up refreshes (\{refresh_ids}) over margins (\{margin_ids}); simulation \{@moonrobo.execution_state_label(projection.simulation_state)}, hardware authority \{projection.hardware_authority} at \{@moonrobo.execution_state_label(projection.hardware_state)}",
  }
}

///|
fn moonrobo_remediation_margin_cycle_closeout_policy_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let policy = @moonrobo.first_trusted_square_remediation_margin_cycle_closeout_policy()
  let refresh_ids = policy.blocking_refresh_ids.join(", ")
  let margin_ids = policy.blocking_margin_ids.join(", ")
  let dispositions = policy.dispositions
    .map(fn(item) {
      "\{item.blocker_domain}=\{@moonrobo.remediation_margin_cycle_disposition_label(item.disposition)}"
    })
    .join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-cycle-closeout-policy",
    title: "MoonRobo remediation-margin cycle closeout policy for \{dossier.site.name}",
    kind: MoonroboRemediationMarginCycleCloseoutPolicy,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.7,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-cycle-closeout-policy.json",
    summary: "\{@moonrobo.remediation_margin_cycle_closeout_status_label(policy.closeout_status)} after \{policy.refresh_cycle_count} refresh cycles with \{policy.blocker_count} terrain/horizon/energy blockers (\{refresh_ids}) over margins (\{margin_ids}); dispositions \{dispositions}; simulation \{@moonrobo.execution_state_label(policy.simulation_state)}, hardware authority \{policy.hardware_authority} at \{@moonrobo.execution_state_label(policy.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_closeout_action_task_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let task = @moonclaw.first_trusted_square_remediation_margin_closeout_action_task()
  let refresh_ids = task.blocking_refresh_ids.join(", ")
  let margin_ids = task.blocking_margin_ids.join(", ")
  let actions = task.closeout_actions
    .map(fn(action) {
      "\{action.blocker_domain}=\{@moonrobo.remediation_margin_cycle_disposition_label(action.disposition)}"
    })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-closeout-action-task",
    title: "MoonClaw remediation-margin closeout action task for \{dossier.site.name}",
    kind: MoonClawRemediationMarginCloseoutActionTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.72,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-closeout-action-task.json",
    summary: "\{@moonclaw.receipt_status_label(task.state)} closeout action task consumes \{@moonrobo.remediation_margin_cycle_closeout_status_label(task.source_closeout_status)} after \{task.refresh_cycle_count} refresh cycles with \{task.blocker_count} terrain/horizon/energy blockers (\{refresh_ids}) over margins (\{margin_ids}); actions \{actions}; simulation \{@moonrobo.execution_state_label(task.simulation_state)}, may consume \{task.may_consume_simulation}, hardware authority \{task.hardware_authority} at \{@moonrobo.execution_state_label(task.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_reviewed_action_plan_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let plans = @moonclaw.first_trusted_square_remediation_margin_reviewed_action_plans()
  let plan = plans[0]
  let refresh_ids = plan.blocking_refresh_ids.join(", ")
  let margin_ids = plan.blocking_margin_ids.join(", ")
  let actions = plan.actions
    .map(fn(action) {
      "\{action.blocker_domain}=\{@moonrobo.remediation_margin_cycle_disposition_label(action.disposition)}"
    })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-action-plan",
    title: "MoonClaw reviewed remediation-margin action plan for \{dossier.site.name}",
    kind: MoonClawRemediationMarginReviewedActionPlan,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.74,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-action-plan.json",
    summary: "\{@moonclaw.receipt_status_label(plan.state)} reviewed action plan from \{@moonclaw.closeout_action_review_decision_label(plan.source_review_decision)} closeout review \{plan.source_review_transition_id} with \{plan.blocker_count} terrain/horizon/energy blockers (\{refresh_ids}) over margins (\{margin_ids}); actions \{actions}; automatic refresh loop allowed \{plan.automatic_refresh_loop_allowed}, simulation \{@moonrobo.execution_state_label(plan.simulation_state)}, may consume \{plan.may_consume_simulation}, hardware authority \{plan.hardware_authority} at \{@moonrobo.execution_state_label(plan.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_reviewed_work_items_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let items = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_items()
  let margin_ids = items.map(fn(item) { item.margin_id }).join(", ")
  let refresh_ids = items.map(fn(item) { item.refresh_id }).join(", ")
  let actions = items
    .map(fn(item) {
      "\{item.blocker_domain}=\{@moonrobo.remediation_margin_cycle_disposition_label(item.disposition)}"
    })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-work-items",
    title: "MoonClaw reviewed remediation-margin work items for \{dossier.site.name}",
    kind: MoonClawRemediationMarginReviewedWorkItems,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.75,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-work-items.json",
    summary: "\{items.length()} accepted reviewed work items for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); actions \{actions}; automatic refresh loop allowed false, simulation simulation-blocked, may consume false, hardware authority moonmoon-safety-gate-only at hardware-denied",
  }
}

///|
fn moonclaw_remediation_margin_reviewed_work_item_receipts_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipts = @moonclaw.first_trusted_square_remediation_margin_reviewed_work_item_receipts()
  let margin_ids = receipts
    .map(fn(receipt) { receipt.work_item_result.margin_id })
    .join(", ")
  let states = receipts
    .map(fn(receipt) {
      "\{receipt.work_item_result.blocker_domain}=\{@moonclaw.remediation_margin_reviewed_work_item_result_status_label(receipt.work_item_result.status)}"
    })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-work-item-receipts",
    title: "MoonClaw reviewed remediation-margin work item receipts for \{dossier.site.name}",
    kind: MoonClawRemediationMarginReviewedWorkItemReceipts,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.76,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-work-item-receipts.json",
    summary: "\{receipts.length()} accepted reviewed work item receipts for terrain/horizon/energy margins (\{margin_ids}); states \{states}; pending fresh evidence, accepted review provenance, automatic refresh loop allowed false, simulation simulation-blocked, may consume false, hardware authority moonmoon-safety-gate-only at hardware-denied",
  }
}

///|
fn moonclaw_remediation_margin_reviewed_fresh_evidence_task_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let tasks = @moonclaw.first_trusted_square_remediation_margin_reviewed_fresh_evidence_tasks()
  let task = tasks[0]
  let margin_ids = task.pending_margin_ids.join(", ")
  let refresh_ids = task.pending_refresh_ids.join(", ")
  let actions = task.fresh_evidence_actions
    .map(fn(action) { "\{action.blocker_domain}=\{action.execution_mode}" })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-fresh-evidence-task",
    title: "MoonClaw reviewed remediation-margin fresh evidence task for \{dossier.site.name}",
    kind: MoonClawRemediationMarginReviewedFreshEvidenceTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.77,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-reviewed-fresh-evidence-task.json",
    summary: "\{task.pending_receipt_count} pending reviewed work item receipts become fresh-evidence actions for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); actions \{actions}; source receipt provenance, accepted review provenance, automatic refresh loop allowed \{task.automatic_refresh_loop_allowed}, simulation \{@moonrobo.execution_state_label(task.simulation_state)}, may consume \{task.may_consume_simulation}, hardware authority \{task.hardware_authority} at \{@moonrobo.execution_state_label(task.hardware_state)}",
  }
}

///|
fn moonclaw_remediation_margin_fresh_evidence_action_receipts_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipts = @moonclaw.first_trusted_square_remediation_margin_fresh_evidence_action_receipts()
  let margin_ids = receipts
    .map(fn(receipt) { receipt.action_result.margin_id })
    .join(", ")
  let refresh_ids = receipts
    .map(fn(receipt) { receipt.action_result.refresh_id })
    .join(", ")
  let actions = receipts
    .map(fn(receipt) {
      "\{receipt.action_result.blocker_domain}=\{receipt.action_result.execution_mode}"
    })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-fresh-evidence-action-receipts",
    title: "MoonClaw remediation-margin fresh evidence action receipts for \{dossier.site.name}",
    kind: MoonClawRemediationMarginFreshEvidenceActionReceipts,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.78,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-fresh-evidence-action-receipts.json",
    summary: "\{receipts.length()} accepted fresh-evidence action receipts for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); actions \{actions}; source receipt provenance, reviewed work items remain pending fresh evidence, automatic refresh loop allowed false, simulation simulation-blocked, may consume false, hardware authority moonmoon-safety-gate-only at hardware-denied",
  }
}

///|
fn moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipts = @moonclaw.first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts()
  let margin_ids = receipts
    .map(fn(receipt) { receipt.work_item_result.margin_id })
    .join(", ")
  let refresh_ids = receipts
    .map(fn(receipt) { receipt.work_item_result.refresh_id })
    .join(", ")
  let states = receipts
    .map(fn(receipt) {
      "\{receipt.work_item_result.blocker_domain}=\{@moonclaw.remediation_margin_reviewed_work_item_result_status_label(receipt.work_item_result.status)}"
    })
    .join(", ")
  let execution_modes = receipts
    .map(fn(receipt) {
      "\{receipt.work_item_result.blocker_domain}=\{receipt.execution_mode}"
    })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/remediation-margin-regenerated-reviewed-work-item-receipts",
    title: "MoonClaw regenerated reviewed work item receipts for \{dossier.site.name}",
    kind: MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipts,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.79,
    path: "moonclaw/\{dossier.site.site_id}/remediation-margin-regenerated-reviewed-work-item-receipts.json",
    summary: "\{receipts.length()} regenerated reviewed work item receipts for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); states \{states}; execution modes \{execution_modes}; source action receipt provenance, source receipt provenance, accepted review provenance, automatic refresh loop allowed false, simulation simulation-blocked, may consume false, hardware authority moonmoon-safety-gate-only at hardware-denied",
  }
}

///|
fn moonrobo_remediation_margin_regenerated_receipt_readiness_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let gate = @moonrobo.first_trusted_square_remediation_margin_regenerated_receipt_readiness_gate()
  let margin_ids = gate.pending_margin_ids.join(", ")
  let refresh_ids = gate.pending_refresh_ids.join(", ")
  let execution_modes = gate.execution_modes.join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/remediation-margin-regenerated-receipt-readiness",
    title: "MoonRobo regenerated receipt readiness for \{dossier.site.name}",
    kind: MoonroboRemediationMarginRegeneratedReceiptReadiness,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.8,
    path: "moonrobo/\{dossier.site.site_id}/remediation-margin-regenerated-receipt-readiness.json",
    summary: "\{@moonrobo.remediation_margin_regenerated_receipt_readiness_state_label(gate.readiness_state)} with \{gate.pending_receipt_count} pending regenerated receipts and \{gate.ready_receipt_count} ready receipts for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); execution modes \{execution_modes}; source action receipt provenance, no automatic refresh loop, no simulation consumption, simulation \{@moonrobo.execution_state_label(gate.simulation_state)}, may consume \{gate.may_consume_simulation}, hardware authority \{gate.hardware_authority} at \{@moonrobo.execution_state_label(gate.hardware_state)}",
  }
}

///|
fn moonclaw_regenerated_receipt_readiness_fresh_evidence_task_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let tasks = @moonclaw.first_trusted_square_regenerated_receipt_readiness_fresh_evidence_tasks()
  let task = tasks[0]
  let margin_ids = task.pending_margin_ids.join(", ")
  let refresh_ids = task.pending_refresh_ids.join(", ")
  let actions = task.fresh_evidence_actions
    .map(fn(action) { "\{action.blocker_domain}=\{action.execution_mode}" })
    .join(", ")
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/regenerated-receipt-readiness-fresh-evidence-task",
    title: "MoonClaw regenerated receipt readiness fresh evidence task for \{dossier.site.name}",
    kind: MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.81,
    path: "moonclaw/\{dossier.site.site_id}/regenerated-receipt-readiness-fresh-evidence-task.json",
    summary: "\{task.pending_receipt_count} pending regenerated receipts and \{task.ready_receipt_count} ready receipts become explicit fresh-evidence actions for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); readiness \{@moonrobo.remediation_margin_regenerated_receipt_readiness_state_label(task.source_readiness_state)}; actions \{actions}; source action receipt provenance, source readiness gate \{task.source_readiness_gate_id}, no automatic refresh loop, no simulation consumption, simulation \{@moonrobo.execution_state_label(task.simulation_state)}, may consume \{task.may_consume_simulation}, hardware authority \{task.hardware_authority} at \{@moonrobo.execution_state_label(task.hardware_state)}",
  }
}

///|
fn moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let receipts = @moonclaw.first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts()
  let margin_ids = receipts
    .map(fn(receipt) { receipt.action_result.margin_id })
    .join(", ")
  let refresh_ids = receipts
    .map(fn(receipt) { receipt.action_result.refresh_id })
    .join(", ")
  let actions = receipts
    .map(fn(receipt) {
      "\{receipt.action_result.blocker_domain}=\{receipt.action_result.execution_mode}"
    })
    .join(", ")
  let receipt_state = @moonclaw.regenerated_readiness_fresh_evidence_action_receipt_state_label(
    receipts[0].action_state,
  )
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/regenerated-receipt-readiness-fresh-evidence-action-receipts",
    title: "MoonClaw regenerated receipt readiness fresh evidence action receipts for \{dossier.site.name}",
    kind: MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipts,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.82,
    path: "moonclaw/\{dossier.site.site_id}/regenerated-receipt-readiness-fresh-evidence-action-receipts.json",
    summary: "\{receipts.length()} regenerated readiness fresh-evidence action receipts with \{receipt_state} for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); actions \{actions}; source readiness gate \{receipts[0].source_readiness_gate_id}, source readiness state \{@moonrobo.remediation_margin_regenerated_receipt_readiness_state_label(receipts[0].source_readiness_state)}, source receipt provenance, source action receipt provenance, no automatic refresh loop, no simulation consumption, simulation \{@moonrobo.execution_state_label(receipts[0].simulation_state)}, may consume \{receipts[0].may_consume_simulation}, hardware authority \{receipts[0].hardware_authority} at \{@moonrobo.execution_state_label(receipts[0].hardware_state)}",
  }
}

///|
fn moonrobo_regenerated_receipt_readiness_action_receipt_closeout_entry(
  dossier : @site.SiteDossier,
) -> BookEntry {
  let closeout = @moonrobo.first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout()
  let margin_ids = closeout.margin_ids.join(", ")
  let refresh_ids = closeout.refresh_ids.join(", ")
  let execution_modes = closeout.execution_modes.join(", ")
  {
    entry_id: "moonrobo/\{dossier.site.site_id}/regenerated-receipt-readiness-action-receipt-closeout",
    title: "MoonRobo regenerated receipt readiness action receipt closeout for \{dossier.site.name}",
    kind: MoonroboRegeneratedReceiptReadinessActionReceiptCloseout,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.83,
    path: "moonrobo/\{dossier.site.site_id}/regenerated-receipt-readiness-action-receipt-closeout.json",
    summary: "\{@moonrobo.regenerated_receipt_readiness_action_receipt_closeout_state_label(closeout.closeout_state)} with \{closeout.pending_receipt_count} pending regenerated receipts and \{closeout.ready_receipt_count} ready receipts after \{closeout.source_action_receipt_count} fresh-evidence action receipts for terrain/horizon/energy margins (\{margin_ids}) over refreshes (\{refresh_ids}); execution modes \{execution_modes}; source readiness gate \{closeout.source_readiness_gate_id}, source readiness state \{@moonrobo.remediation_margin_regenerated_receipt_readiness_state_label(closeout.source_readiness_state)}, source action receipt provenance, no automatic refresh loop, no simulation consumption, simulation \{@moonrobo.execution_state_label(closeout.simulation_state)}, may consume \{closeout.may_consume_simulation}, hardware authority \{closeout.hardware_authority} at \{@moonrobo.execution_state_label(closeout.hardware_state)}",
  }
}

///|
fn moonclaw_ephemeris_receipt_entry(dossier : @site.SiteDossier) -> BookEntry {
  let receipt = @moonclaw.ephemeris_acquisition_receipt(dossier)
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/ephemeris-receipt",
    title: "MoonClaw ephemeris receipt for \{dossier.site.name}",
    kind: MoonClawEphemerisReceipt,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.55,
    path: "moonclaw/\{dossier.site.site_id}/ephemeris-receipts.json",
    summary: "\{@moonclaw.receipt_status_label(receipt.receipt.status)} receipt keeps energy \{@mission.traverse_decision_label(receipt.energy_decision)} with \{receipt.verified_available_energy_wh} Wh verified available: \{receipt.next_action}",
  }
}

///|
fn moonclaw_corridor_receipt_entry(dossier : @site.SiteDossier) -> BookEntry {
  let receipt = @moonclaw.corridor_expansion_receipt(dossier)
  {
    entry_id: "moonclaw/\{dossier.site.site_id}/corridor-expansion-receipt",
    title: "MoonClaw corridor-expansion receipt for \{dossier.site.name}",
    kind: MoonClawCorridorReceipt,
    claim_kind: @core.ClaimKind::Derived,
    confidence: 0.75,
    path: "moonclaw/\{dossier.site.site_id}/corridor-receipts.json",
    summary: "\{@moonclaw.receipt_status_label(receipt.receipt.status)} receipt covers \{receipt.sampled_window_count} measured windows and keeps best window \{receipt.best_window_id} \{@mission.corridor_scan_window_status_label(dossier.corridor_scan[0])}: \{receipt.next_action}",
  }
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
  let selected_route = if best.selected_route_id == "" {
    "no promoted route yet"
  } else {
    best.selected_route_id
  }
  if best.decision != @mission.TraverseDecision::Allow {
    items.push(
      review_item(
        "corridor-scan-best-window",
        decision_severity(best.decision),
        "best measured corridor window \{best.window_id} selects \{selected_route} and remains \{@mission.corridor_scan_window_status_label(best)}: \{best.note}",
        "mission-review",
      ),
    )
  }
  if !dossier.power_window_evidence.has_time_window_ephemeris ||
    dossier.power_window_evidence.source_status != "ready" {
    items.push(
      review_item(
        "power-window-evidence",
        "high",
        "power-window evidence \{dossier.power_window_evidence.evidence_id} is not computed-ready; compute and review a time-windowed power result before energy review",
        "power-thermal-review",
      ),
    )
  }
  if dossier.energy.decision != @mission.TraverseDecision::Allow {
    items.push(
      review_item(
        "energy-window",
        decision_severity(dossier.energy.decision),
        "energy window budget: \{dossier.energy.next_action}",
        "power-thermal-review",
      ),
    )
  }
  let moonrobo_handoff = @moonrobo.route_handoff(
    dossier,
    primary_route_candidate(dossier),
  )
  if moonrobo_handoff.clearance_plan.decision !=
    @mission.TraverseDecision::Allow {
    for clearance in moonrobo_handoff.clearance_plan.items {
      items.push(
        review_item(
          clearance.clearance_id,
          decision_severity(clearance.decision),
          "\{clearance.label}: \{clearance.clearance_action}",
          clearance_owner(clearance.kind),
        ),
      )
    }
  }
  if moonrobo_handoff.decision != @mission.TraverseDecision::Allow {
    items.push(
      review_item(
        "moonrobo-handoff",
        decision_severity(moonrobo_handoff.decision),
        "Moonrobo handoff: \{moonrobo_handoff.next_action}",
        "moonrobo",
      ),
    )
  }
  items.push(
    review_item(
      "moonclaw-proposals", "high", "MoonClaw proposals dispatch ephemeris, corridor, and route-scoring work before Moonrobo simulation can become reviewable",
      "moonclaw",
    ),
  )
  let ephemeris_task = @moonclaw.ephemeris_acquisition_task(dossier)
  let blocked_artifacts = @moonclaw.task_blocked_artifact_count(ephemeris_task)
  if blocked_artifacts > 0 {
    items.push(
      review_item(
        "moonclaw-ephemeris-task",
        "high",
        "MoonClaw ephemeris task has \{blocker_count_label(blocked_artifacts)} before power-window evidence can become robot-facing input",
        "moonclaw",
      ),
    )
  }
  let corridor_task = @moonclaw.corridor_expansion_task(dossier)
  let corridor_blocked_artifacts = @moonclaw.corridor_task_blocked_artifact_count(
    corridor_task,
  )
  if corridor_blocked_artifacts > 0 {
    items.push(
      review_item(
        "moonclaw-corridor-task",
        "high",
        "MoonClaw corridor task has \{blocker_count_label(corridor_blocked_artifacts)} before the planned \{corridor_task.planned_window_count}-window search can update route evidence",
        "moonclaw",
      ),
    )
  }
  for index, question in dossier.next_questions {
    items.push(review_item("question-\{index}", "low", question, "moonclaw"))
  }
  items
}

///|
fn clearance_owner(kind : @mission.MissionClearanceKind) -> String {
  match kind {
    TerrainGradeClearance => "mission-review"
    IlluminationConfidenceClearance => "power-thermal-review"
    EnergyMarginClearance => "power-thermal-review"
    MoonBookReviewClearance => "mission-review"
  }
}

///|
fn book_entries(
  dossier : @site.SiteDossier,
  clearance_transitions : Array[@mission.MissionClearanceTransition],
) -> Array[BookEntry] {
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
  entries.push(selected_route_horizon_entry(dossier))
  entries.push(selected_route_terrain_remediation_entry(dossier))
  entries.push(power_window_evidence_entry(dossier))
  entries.push(energy_entry(dossier))
  entries.push(selected_route_energy_remediation_entry(dossier))
  entries.push(selected_route_clearance_entry(dossier, clearance_transitions))
  entries.push(moonrobo_handoff_entry(dossier, clearance_transitions))
  entries.push(moonclaw_proposal_entry(dossier))
  entries.push(moonclaw_ephemeris_task_entry(dossier))
  entries.push(moonclaw_corridor_task_entry(dossier))
  entries.push(moonclaw_remediation_margin_task_entry(dossier))
  entries.push(moonclaw_remediation_margin_refresh_task_entry(dossier))
  entries.push(moonclaw_remediation_margin_refresh_receipt_entry(dossier))
  entries.push(moonclaw_receipt_entry(dossier))
  entries.push(moonclaw_remediation_margin_receipt_entry(dossier))
  entries.push(moonrobo_remediation_margin_modeling_entry(dossier))
  entries.push(moonrobo_remediation_margin_projection_entry(dossier))
  entries.push(moonrobo_remediation_margin_refresh_modeling_entry(dossier))
  entries.push(moonrobo_remediation_margin_refresh_projection_entry(dossier))
  entries.push(moonclaw_remediation_margin_refresh_followup_task_entry(dossier))
  entries.push(
    moonclaw_remediation_margin_refresh_followup_receipt_entry(dossier),
  )
  entries.push(
    moonrobo_remediation_margin_refresh_followup_modeling_entry(dossier),
  )
  entries.push(
    moonrobo_remediation_margin_refresh_followup_projection_entry(dossier),
  )
  entries.push(moonrobo_remediation_margin_cycle_closeout_policy_entry(dossier))
  entries.push(moonclaw_remediation_margin_closeout_action_task_entry(dossier))
  entries.push(moonclaw_remediation_margin_reviewed_action_plan_entry(dossier))
  entries.push(moonclaw_remediation_margin_reviewed_work_items_entry(dossier))
  entries.push(
    moonclaw_remediation_margin_reviewed_work_item_receipts_entry(dossier),
  )
  entries.push(
    moonclaw_remediation_margin_reviewed_fresh_evidence_task_entry(dossier),
  )
  entries.push(
    moonclaw_remediation_margin_fresh_evidence_action_receipts_entry(dossier),
  )
  entries.push(
    moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts_entry(
      dossier,
    ),
  )
  entries.push(
    moonrobo_remediation_margin_regenerated_receipt_readiness_entry(dossier),
  )
  entries.push(
    moonclaw_regenerated_receipt_readiness_fresh_evidence_task_entry(dossier),
  )
  entries.push(
    moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts_entry(
      dossier,
    ),
  )
  entries.push(
    moonrobo_regenerated_receipt_readiness_action_receipt_closeout_entry(
      dossier,
    ),
  )
  entries.push(moonclaw_ephemeris_receipt_entry(dossier))
  entries.push(moonclaw_corridor_receipt_entry(dossier))
  entries.push(moonrobo_noetix_walk_entry(dossier))
  entries.push(moonrobo_noetix_physics_entry(dossier))
  entries.push(moonrobo_noetix_dynamics_entry(dossier))
  entries.push(moonrobo_noetix_link_poses_entry(dossier))
  entries.push(moonclaw_noetix_review_task_entry(dossier))
  entries
}

///|
pub fn from_site_dossier(dossier : @site.SiteDossier) -> MoonBookDossier {
  from_site_dossier_with_review_transitions(dossier, [])
}

///|
pub fn from_site_dossier_with_review_transitions(
  dossier : @site.SiteDossier,
  imported_transitions : Array[ReviewTransition],
) -> MoonBookDossier {
  let raw_review_queue = open_review_queue(dossier)
  let review_transitions = review_transitions_for_queue(
    raw_review_queue, dossier, imported_transitions,
  )
  let clearance_transitions = clearance_transitions_from_review_transitions(
    review_transitions,
  )
  {
    workspace: "moonbook://moonmoon/first-trusted-square",
    site_id: dossier.site.site_id,
    title: "Moonmoon evidence dossier: \{dossier.site.name}",
    entries: book_entries(dossier, clearance_transitions),
    review_queue: apply_review_transitions(raw_review_queue, review_transitions),
    review_transitions,
  }
}

///|
pub fn first_trusted_square_book_dossier() -> MoonBookDossier {
  from_site_dossier(@site.first_trusted_square_dossier())
}

///|
pub fn render_markdown(dossier : MoonBookDossier) -> String {
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
      text += "  - reviewer: \{transition.reviewer_id} as \{transition.reviewer_role}\n"
      text += "  - timestamp: \{transition.recorded_at_utc} (\{transition.timestamp_policy})\n"
      text += "  - append only: \{transition.append_only}\n"
      for source in transition.source_evidence_refs {
        text += "  - source: \{source.entry_id} at \{source.immutable_uri}\n"
      }
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
pub fn render_json(dossier : MoonBookDossier) -> Json {
  dossier.to_json()
}

///|
pub fn first_trusted_square_book_json() -> Json {
  render_json(first_trusted_square_book_dossier())
}
