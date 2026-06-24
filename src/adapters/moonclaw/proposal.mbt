///|
pub(all) enum MoonClawJobKind {
  CorridorExpansion
  EphemerisAcquisition
  RouteScoring
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawJobPriority {
  Low
  Medium
  High
  Critical
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MoonClawReceiptStatus {
  Pending
  Accepted
  Rejected
  NeedsReview
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawJobInput {
  input_id : String
  evidence_path : String
  claim_kind : @core.ClaimKind
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawAcceptanceCriterion {
  criterion_id : String
  description : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawProposal {
  proposal_id : String
  site_id : @core.SiteId
  job_kind : MoonClawJobKind
  priority : MoonClawJobPriority
  title : String
  objective : String
  inputs : Array[MoonClawJobInput]
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  blocked_by : Array[String]
  expected_outputs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawReceipt {
  receipt_id : String
  proposal_id : String
  status : MoonClawReceiptStatus
  accepted_outputs : Array[String]
  validation_notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawReceiptValidation {
  validation_id : String
  passed : Bool
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRouteScore {
  route_id : String
  rank : Int
  route_decision : @mission.TraverseDecision
  illumination_decision : @mission.TraverseDecision
  route_score : Int
  risk_index : Double
  max_grade : Double
  roughness_m : Double
  confidence : Double
  evidence_path : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawRouteScoringReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  selected_route_id : String
  route_scores : Array[MoonClawRouteScore]
  validation_checks : Array[MoonClawReceiptValidation]
  moonrobo_handoff_decision : @mission.TraverseDecision
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawCorridorWindowScore {
  window_id : String
  rank : Int
  row_offset : Int
  col_offset : Int
  decision : @mission.TraverseDecision
  selected_route_id : String
  risk_index : Double
  max_grade : Double
  roughness_m : Double
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawCorridorExpansionReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  scan_id : String
  sampled_window_count : Int
  best_window_id : String
  selected_route_id : String
  window_scores : Array[MoonClawCorridorWindowScore]
  validation_checks : Array[MoonClawReceiptValidation]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonClawEphemerisAcquisitionReceipt {
  receipt : MoonClawReceipt
  site_id : @core.SiteId
  energy_decision : @mission.TraverseDecision
  has_time_window_ephemeris : Bool
  power_window_evidence_id : String
  power_window_source_path : String
  power_window_source_status : String
  route_count : Int
  blocked_route_count : Int
  required_sunlit_hours : Double
  assumed_dark_survival_hours : Double
  required_energy_wh : Double
  verified_available_energy_wh : Double
  missing_outputs : Array[String]
  validation_checks : Array[MoonClawReceiptValidation]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn job_kind_label(kind : MoonClawJobKind) -> String {
  match kind {
    CorridorExpansion => "corridor-expansion"
    EphemerisAcquisition => "ephemeris-acquisition"
    RouteScoring => "route-scoring"
  }
}

///|
pub fn priority_label(priority : MoonClawJobPriority) -> String {
  match priority {
    Low => "low"
    Medium => "medium"
    High => "high"
    Critical => "critical"
  }
}

///|
pub fn receipt_status_label(status : MoonClawReceiptStatus) -> String {
  match status {
    Pending => "pending"
    Accepted => "accepted"
    Rejected => "rejected"
    NeedsReview => "needs-review"
  }
}

///|
fn input(
  input_id : String,
  evidence_path : String,
  claim_kind : @core.ClaimKind,
  summary : String,
) -> MoonClawJobInput {
  { input_id, evidence_path, claim_kind, summary }
}

///|
fn criterion(
  criterion_id : String,
  description : String,
) -> MoonClawAcceptanceCriterion {
  { criterion_id, description }
}

///|
fn validation(
  validation_id : String,
  passed : Bool,
  note : String,
) -> MoonClawReceiptValidation {
  { validation_id, passed, note }
}

///|
fn validation_notes(checks : Array[MoonClawReceiptValidation]) -> Array[String] {
  let notes : Array[String] = []
  for check in checks {
    let status = if check.passed { "pass" } else { "fail" }
    notes.push("\{check.validation_id}: \{status} - \{check.note}")
  }
  notes
}

///|
fn all_checks_pass(checks : Array[MoonClawReceiptValidation]) -> Bool {
  for check in checks {
    if !check.passed {
      return false
    }
  }
  true
}

///|
fn verified_validation_count(
  validations : Array[@dataset.DatasetValidation],
) -> Int {
  let mut count = 0
  for validation in validations {
    if validation.status == @dataset.DatasetValidationStatus::Verified {
      count = count + 1
    }
  }
  count
}

///|
fn manifest_checksum(
  manifests : Array[@dataset.DatasetManifest],
  dataset_id : String,
) -> String {
  for manifest in manifests {
    if manifest.dataset_id == dataset_id {
      return manifest.checksum
    }
  }
  ""
}

///|
fn validation_matches_manifest(
  validation : @dataset.DatasetValidation,
  manifests : Array[@dataset.DatasetManifest],
) -> Bool {
  let expected = manifest_checksum(manifests, validation.dataset_id)
  validation.status == @dataset.DatasetValidationStatus::Verified &&
  expected != "" &&
  validation.expected_checksum == expected &&
  validation.actual_checksum == expected
}

///|
fn all_validations_match_manifests(dossier : @site.SiteDossier) -> Bool {
  if dossier.validations.length() != dossier.datasets.length() {
    return false
  }
  for validation in dossier.validations {
    if !validation_matches_manifest(validation, dossier.datasets) {
      return false
    }
  }
  true
}

///|
fn route_id_exists(
  routes : Array[@mission.RouteCandidate],
  route_id : String,
) -> Bool {
  routes.any(fn(route) { route.route_id == route_id })
}

///|
fn route_by_id(
  routes : Array[@mission.RouteCandidate],
  route_id : String,
) -> @mission.RouteCandidate {
  for route in routes {
    if route.route_id == route_id {
      return route
    }
  }
  routes[0]
}

///|
fn route_rank(
  route : @mission.RouteCandidate,
  routes : Array[@mission.RouteCandidate],
) -> Int {
  let mut rank = 1
  for other in routes {
    if route_risk_index(other) < route_risk_index(route) {
      rank = rank + 1
    }
  }
  rank
}

///|
fn route_risk_index(route : @mission.RouteCandidate) -> Double {
  route.expected_max_grade + route.expected_roughness_m / 10.0
}

///|
fn corridor_window_risk_index(window : @mission.CorridorScanWindow) -> Double {
  window.max_neighbor_grade + window.roughness_m / 10.0
}

///|
fn route_score(
  route : @mission.RouteCandidate,
  routes : Array[@mission.RouteCandidate],
  site_id : @core.SiteId,
) -> MoonClawRouteScore {
  {
    route_id: route.route_id,
    rank: route_rank(route, routes),
    route_decision: route.decision,
    illumination_decision: route.illumination.decision,
    route_score: route.score,
    risk_index: route_risk_index(route),
    max_grade: route.expected_max_grade,
    roughness_m: route.expected_roughness_m,
    confidence: route.confidence,
    evidence_path: "mission/\{site_id}/routes/\{route.route_id}.json",
    next_action: route.next_action,
  }
}

///|
fn corridor_window_score(
  window : @mission.CorridorScanWindow,
) -> MoonClawCorridorWindowScore {
  {
    window_id: window.window_id,
    rank: window.rank,
    row_offset: window.row_offset,
    col_offset: window.col_offset,
    decision: window.decision,
    selected_route_id: window.selected_route_id,
    risk_index: corridor_window_risk_index(window),
    max_grade: window.max_neighbor_grade,
    roughness_m: window.roughness_m,
    note: window.note,
  }
}

///|
fn corridor_window_scores(
  windows : Array[@mission.CorridorScanWindow],
) -> Array[MoonClawCorridorWindowScore] {
  let scores : Array[MoonClawCorridorWindowScore] = []
  for window in windows {
    scores.push(corridor_window_score(window))
  }
  scores
}

///|
fn all_corridor_windows_blocked(
  windows : Array[@mission.CorridorScanWindow],
) -> Bool {
  for window in windows {
    if window.decision != @mission.TraverseDecision::Block {
      return false
    }
  }
  true
}

///|
fn corridor_receipt_next_action(best : @mission.CorridorScanWindow) -> String {
  match best.decision {
    Allow =>
      "MoonClaw corridor expansion found an allowable measured window; route scoring and Moonrobo preconditions must be recomputed"
    Review =>
      "MoonClaw corridor expansion found a reviewable measured window; operator review is required before route scoring changes"
    Block =>
      "MoonClaw corridor expansion accepts the bounded search result but proves every sampled LOLA window remains blocked"
  }
}

///|
fn ephemeris_receipt_next_action() -> String {
  "MoonClaw ephemeris acquisition cannot clear the energy gate until a cited time-windowed solar source, checksum, and generated MoonBit power window are attached"
}

///|
fn route_scores(
  routes : Array[@mission.RouteCandidate],
  site_id : @core.SiteId,
) -> Array[MoonClawRouteScore] {
  let scores : Array[MoonClawRouteScore] = []
  for route in routes {
    scores.push(route_score(route, routes, site_id))
  }
  scores
}

///|
fn route_receipt_next_action(
  handoff_decision : @mission.TraverseDecision,
) -> String {
  match handoff_decision {
    Allow =>
      "MoonClaw route scoring validates a Moonrobo-allowable route; operator should inspect the handoff before simulation"
    Review =>
      "MoonClaw route scoring found a reviewable route; operator review is required before Moonrobo simulation"
    Block =>
      "MoonClaw route scoring accepts the current evidence result but keeps Moonrobo blocked until corridor and power evidence improve"
  }
}

///|
fn blocker_current(
  blocker_id : String,
  dossier : @site.SiteDossier,
  handoff : @moonrobo.MoonroboTaskHandoff,
) -> Bool {
  if blocker_id == "corridor-scan-best-window" {
    dossier.corridor_scan[0].decision == @mission.TraverseDecision::Block
  } else if blocker_id == "energy-window" {
    dossier.energy.decision == @mission.TraverseDecision::Block
  } else if blocker_id == "moonrobo-handoff" {
    handoff.decision == @mission.TraverseDecision::Block
  } else {
    false
  }
}

///|
fn proposal_blockers_current(
  proposal : MoonClawProposal,
  dossier : @site.SiteDossier,
  handoff : @moonrobo.MoonroboTaskHandoff,
) -> Bool {
  for blocker in proposal.blocked_by {
    if !blocker_current(blocker, dossier, handoff) {
      return false
    }
  }
  true
}

///|
pub fn ephemeris_acquisition_proposal(
  dossier : @site.SiteDossier,
) -> MoonClawProposal {
  {
    proposal_id: "moonclaw/\{dossier.site.site_id}/ephemeris-energy-v1",
    site_id: dossier.site.site_id,
    job_kind: EphemerisAcquisition,
    priority: Critical,
    title: "Attach ephemeris-backed power and thermal windows",
    objective: "Replace relief-shadow and zero-available-energy proxies with time-windowed solar ephemeris evidence before Moonrobo simulation is allowed.",
    inputs: [
      input(
        "energy-window",
        "mission/\{dossier.site.site_id}/energy-window.json",
        @core.ClaimKind::Derived,
        "Conservative rover energy budget currently blocks because no verified sunlit power window is attached.",
      ),
      input(
        "route-illumination",
        "mission/\{dossier.site.site_id}/routes/*.illumination.json",
        @core.ClaimKind::Derived,
        "Per-route illumination gates use measured relief as a shadow-risk proxy and require time-windowed replacement evidence.",
      ),
      input(
        "lola-product-label",
        "source-products/lola-south-pole-20m-dem.json",
        @core.ClaimKind::Unknown,
        "Pinned LOLA product label gives the site projection and bounds needed to request matching ephemeris products.",
      ),
    ],
    acceptance_criteria: [
      criterion(
        "official-source", "Name the ephemeris or illumination source family, citation, local evidence path, checksum, and temporal coverage window.",
      ),
      criterion(
        "power-budget", "Compute sunlit hours, expected generation Wh, dark-survival Wh, and margin for the selected route window.",
      ),
      criterion(
        "moonbit-update", "Update the MoonBit energy and illumination assessments and add tests that prove Moonrobo remains blocked or becomes reviewable for cited reasons.",
      ),
    ],
    blocked_by: [
      "energy-window", "illumination-southwest-bypass", "moonrobo-handoff",
    ],
    expected_outputs: [
      "data/sources/lunar_ephemeris/first_trusted_square_power_window.json", "src/mission/generated_first_trusted_square_power_window.mbt",
      "output/site/first_trusted_square.json", "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/energy-window.json",
    ],
  }
}

///|
pub fn corridor_expansion_proposal(
  dossier : @site.SiteDossier,
) -> MoonClawProposal {
  {
    proposal_id: "moonclaw/\{dossier.site.site_id}/corridor-expansion-v1",
    site_id: dossier.site.site_id,
    job_kind: CorridorExpansion,
    priority: High,
    title: "Widen the LOLA route-corridor search",
    objective: "Search beyond the current 5x5 corridor ranking to either find a rover-reviewable local window or prove the bounded site remains blocked.",
    inputs: [
      input(
        "corridor-scan",
        "mission/\{dossier.site.site_id}/corridor-scan.json",
        @core.ClaimKind::Derived,
        "Current ranked 5x5 corridor scan selects southwest-bypass but still exceeds rover grade and roughness limits.",
      ),
      input(
        "selected-route",
        "mission/\{dossier.site.site_id}/routes/southwest-bypass.json",
        @core.ClaimKind::Derived,
        "Lowest-risk route candidate found so far; it is progress evidence, not a safe route.",
      ),
      input(
        "source-extraction",
        "source-extractions/first-trusted-square-southwest-bypass-20m.json",
        @core.ClaimKind::Measured,
        "Existing byte-range extraction pattern for adding adjacent LOLA evidence windows.",
      ),
    ],
    acceptance_criteria: [
      criterion(
        "bounded-search", "Publish the search radius, sampled windows, ordering rule, CSV checksum, and generator command.",
      ),
      criterion(
        "route-outcome", "Return at least one lower-risk route candidate or a measured proof that every sampled window remains blocked.",
      ),
      criterion(
        "workspace-refresh", "Refresh MoonBook route, corridor, and MoonClaw proposal payloads so the operator can audit the result as files.",
      ),
    ],
    blocked_by: [
      "corridor-scan-best-window", "route-southwest-bypass", "moonrobo-handoff",
    ],
    expected_outputs: [
      "data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv", "src/mission/generated_first_trusted_square_corridor_scan.mbt",
      "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/corridor-scan.json",
    ],
  }
}

///|
pub fn route_scoring_proposal(dossier : @site.SiteDossier) -> MoonClawProposal {
  {
    proposal_id: "moonclaw/\{dossier.site.site_id}/route-scoring-v1",
    site_id: dossier.site.site_id,
    job_kind: RouteScoring,
    priority: High,
    title: "Score route candidates after terrain and power evidence improves",
    objective: "Combine terrain, corridor, illumination, and energy evidence into a route-scoring receipt that Moonmoon can validate before Moonrobo consumes a simulation precondition packet.",
    inputs: [
      input(
        "route-candidates",
        "mission/\{dossier.site.site_id}/routes/*.json",
        @core.ClaimKind::Derived,
        "All current route alternatives with terrain score, confidence, and next action.",
      ),
      input(
        "moonrobo-handoff",
        "moonrobo/\{dossier.site.site_id}/handoffs.json",
        @core.ClaimKind::Derived,
        "Robot-facing precondition packets that must remain blocked until Moonmoon evidence clears the gates.",
      ),
      input(
        "review-queue",
        "review_queue.json",
        @core.ClaimKind::Derived,
        "MoonBook review state that records which blockers need evidence or operator attention.",
      ),
    ],
    acceptance_criteria: [
      criterion(
        "scoring-receipt", "Emit a receipt with sorted candidates, decision rationale, rejected assumptions, and exact evidence paths used for each score.",
      ),
      criterion(
        "validation", "Moonmoon validates the receipt against current route IDs, review items, and source checksums before accepting it.",
      ),
      criterion(
        "handoff-compatibility", "The accepted scoring result must explain whether the primary Moonrobo handoff remains blocked, moves to review, or becomes allowed.",
      ),
    ],
    blocked_by: [
      "corridor-scan-best-window", "energy-window", "moonrobo-handoff",
    ],
    expected_outputs: [
      "output/moonclaw/first_trusted_square_route_scoring_receipt.json", "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
    ],
  }
}

///|
pub fn from_site_dossier(
  dossier : @site.SiteDossier,
) -> Array[MoonClawProposal] {
  [
    ephemeris_acquisition_proposal(dossier),
    corridor_expansion_proposal(dossier),
    route_scoring_proposal(dossier),
  ]
}

///|
pub fn first_trusted_square_proposals() -> Array[MoonClawProposal] {
  from_site_dossier(@site.first_trusted_square_dossier())
}

///|
pub fn first_trusted_square_primary_proposal() -> MoonClawProposal {
  first_trusted_square_proposals()[0]
}

///|
pub fn route_scoring_receipt(
  dossier : @site.SiteDossier,
) -> MoonClawRouteScoringReceipt {
  let proposal = route_scoring_proposal(dossier)
  let selected_route_id = dossier.corridor_scan[0].selected_route_id
  let selected_route_present = route_id_exists(
    dossier.route_candidates,
    selected_route_id,
  )
  let selected_route = route_by_id(dossier.route_candidates, selected_route_id)
  let handoff = @moonrobo.route_handoff(dossier, selected_route)
  let checks = [
    validation(
      "route-candidates-present",
      !dossier.route_candidates.is_empty(),
      "\{dossier.route_candidates.length()} route candidates are available for scoring.",
    ),
    validation(
      "selected-route-present",
      selected_route_present,
      "corridor-selected route \{selected_route_id} exists in the current route candidate set.",
    ),
    validation(
      "source-checksums-verified",
      all_validations_match_manifests(dossier),
      "\{verified_validation_count(dossier.validations)} of \{dossier.datasets.length()} dataset source fingerprints match their manifests.",
    ),
    validation(
      "proposal-blockers-current",
      proposal_blockers_current(proposal, dossier, handoff),
      "route-scoring proposal blockers remain active: \{proposal.blocked_by.join(", ")}.",
    ),
    validation(
      "energy-blocker-current",
      dossier.energy.decision == @mission.TraverseDecision::Block,
      "current energy assessment is \{@mission.energy_decision_label(dossier.energy)} and must remain a scoring blocker until ephemeris evidence is attached.",
    ),
    validation(
      "moonrobo-handoff-compatible",
      handoff.decision == @mission.TraverseDecision::Block,
      "primary Moonrobo handoff is \{@moonrobo.handoff_status_label(handoff)}, matching the blocked route-scoring result.",
    ),
  ]
  let status = if all_checks_pass(checks) { Accepted } else { NeedsReview }
  {
    receipt: {
      receipt_id: "moonclaw/\{dossier.site.site_id}/route-scoring-v1/current-receipt",
      proposal_id: proposal.proposal_id,
      status,
      accepted_outputs: [
        "route-scoreboard", "moonrobo-handoff-compatibility", "blocked-evidence-summary",
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: dossier.site.site_id,
    selected_route_id,
    route_scores: route_scores(dossier.route_candidates, dossier.site.site_id),
    validation_checks: checks,
    moonrobo_handoff_decision: handoff.decision,
    next_action: route_receipt_next_action(handoff.decision),
  }
}

///|
pub fn corridor_expansion_receipt(
  dossier : @site.SiteDossier,
) -> MoonClawCorridorExpansionReceipt {
  let proposal = corridor_expansion_proposal(dossier)
  let best = dossier.corridor_scan[0]
  let checks = [
    validation(
      "corridor-scan-present",
      !dossier.corridor_scan.is_empty(),
      "\{dossier.corridor_scan.length()} measured LOLA corridor windows are available.",
    ),
    validation(
      "bounded-search-size",
      dossier.corridor_scan.length() == 25,
      "current corridor expansion receipt covers the reproducible 5x5 LOLA search surface.",
    ),
    validation(
      "best-window-selected-route",
      best.selected_route_id != "",
      "best measured window \{best.window_id} selects route \{best.selected_route_id}.",
    ),
    validation(
      "all-sampled-windows-blocked",
      all_corridor_windows_blocked(dossier.corridor_scan),
      "all sampled corridor windows remain blocked by conservative rover limits.",
    ),
    validation(
      "source-checksums-verified",
      all_validations_match_manifests(dossier),
      "\{verified_validation_count(dossier.validations)} of \{dossier.datasets.length()} dataset source fingerprints match their manifests.",
    ),
    validation(
      "proposal-blockers-current",
      best.decision == @mission.TraverseDecision::Block,
      "corridor proposal blocker corridor-scan-best-window remains active.",
    ),
  ]
  let status = if all_checks_pass(checks) { Accepted } else { NeedsReview }
  {
    receipt: {
      receipt_id: "moonclaw/\{dossier.site.site_id}/corridor-expansion-v1/current-receipt",
      proposal_id: proposal.proposal_id,
      status,
      accepted_outputs: [
        "bounded-corridor-search", "blocked-window-proof", "best-window-summary",
      ],
      validation_notes: validation_notes(checks),
    },
    site_id: dossier.site.site_id,
    scan_id: best.scan_id,
    sampled_window_count: dossier.corridor_scan.length(),
    best_window_id: best.window_id,
    selected_route_id: best.selected_route_id,
    window_scores: corridor_window_scores(dossier.corridor_scan),
    validation_checks: checks,
    next_action: corridor_receipt_next_action(best),
  }
}

///|
pub fn ephemeris_acquisition_receipt(
  dossier : @site.SiteDossier,
) -> MoonClawEphemerisAcquisitionReceipt {
  let proposal = ephemeris_acquisition_proposal(dossier)
  let energy = dossier.energy
  let evidence = @mission.first_trusted_square_power_window_evidence()
  let checks = [
    validation(
      "energy-window-present",
      energy.route_count == dossier.route_candidates.length(),
      "\{energy.route_count} route candidates are represented in the current energy assessment.",
    ),
    validation(
      "time-window-ephemeris-missing",
      !energy.budget.has_time_window_ephemeris &&
      !evidence.has_time_window_ephemeris,
      "current energy budget explicitly reads \{evidence.evidence_id}, which has no time-windowed ephemeris attached.",
    ),
    validation(
      "power-window-source-status-missing",
      evidence.source_status == "missing-source",
      "generated power-window evidence source status is \{evidence.source_status}.",
    ),
    validation(
      "verified-available-energy-zero",
      energy.available_energy_wh == 0.0,
      "verified available energy remains zero without a time-windowed power source.",
    ),
    validation(
      "source-checksums-verified",
      all_validations_match_manifests(dossier),
      "\{verified_validation_count(dossier.validations)} of \{dossier.datasets.length()} dataset source fingerprints match their manifests.",
    ),
    validation(
      "expected-output-contract-present",
      proposal.expected_outputs.length() >= 4,
      "ephemeris proposal names the source evidence, generated MoonBit window, site output, and MoonBook energy payload outputs.",
    ),
  ]
  {
    receipt: {
      receipt_id: "moonclaw/\{dossier.site.site_id}/ephemeris-energy-v1/current-receipt",
      proposal_id: proposal.proposal_id,
      status: NeedsReview,
      accepted_outputs: [],
      validation_notes: validation_notes(checks),
    },
    site_id: dossier.site.site_id,
    energy_decision: energy.decision,
    has_time_window_ephemeris: energy.budget.has_time_window_ephemeris,
    power_window_evidence_id: evidence.evidence_id,
    power_window_source_path: evidence.local_source_path,
    power_window_source_status: evidence.source_status,
    route_count: energy.route_count,
    blocked_route_count: energy.blocked_route_count,
    required_sunlit_hours: energy.budget.required_sunlit_hours,
    assumed_dark_survival_hours: energy.estimated_dark_survival_hours,
    required_energy_wh: energy.required_energy_wh,
    verified_available_energy_wh: energy.available_energy_wh,
    missing_outputs: proposal.expected_outputs,
    validation_checks: checks,
    next_action: ephemeris_receipt_next_action(),
  }
}

///|
pub fn first_trusted_square_route_scoring_receipt() -> MoonClawRouteScoringReceipt {
  route_scoring_receipt(@site.first_trusted_square_dossier())
}

///|
pub fn first_trusted_square_ephemeris_acquisition_receipt() -> MoonClawEphemerisAcquisitionReceipt {
  ephemeris_acquisition_receipt(@site.first_trusted_square_dossier())
}

///|
pub fn first_trusted_square_corridor_expansion_receipt() -> MoonClawCorridorExpansionReceipt {
  corridor_expansion_receipt(@site.first_trusted_square_dossier())
}

///|
pub fn first_trusted_square_receipts() -> Array[MoonClawRouteScoringReceipt] {
  [first_trusted_square_route_scoring_receipt()]
}

///|
pub fn first_trusted_square_corridor_receipts() -> Array[
  MoonClawCorridorExpansionReceipt,
] {
  [first_trusted_square_corridor_expansion_receipt()]
}

///|
pub fn first_trusted_square_ephemeris_receipts() -> Array[
  MoonClawEphemerisAcquisitionReceipt,
] {
  [first_trusted_square_ephemeris_acquisition_receipt()]
}

///|
pub fn render_receipts_markdown(
  receipts : Array[MoonClawRouteScoringReceipt],
) -> String {
  let mut text = "# MoonClaw Modeling Receipts\n\n"
  for scoring in receipts {
    text += "- \{scoring.receipt.receipt_id}\n"
    text += "  - proposal: \{scoring.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(scoring.receipt.status)}\n"
    text += "  - selected route: \{scoring.selected_route_id}\n"
    text += "  - Moonrobo handoff: \{@mission.traverse_decision_label(scoring.moonrobo_handoff_decision)}\n"
    text += "  - next action: \{scoring.next_action}\n"
    text += "  - validation:\n"
    for check in scoring.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - route scores:\n"
    for score in scoring.route_scores {
      text += "    - #\{score.rank} \{score.route_id}: \{@mission.traverse_decision_label(score.route_decision)} route score \{score.route_score}, risk \{score.risk_index}, grade \{score.max_grade}, roughness \{score.roughness_m} m\n"
    }
  }
  text
}

///|
pub fn render_corridor_receipts_markdown(
  receipts : Array[MoonClawCorridorExpansionReceipt],
) -> String {
  let mut text = "# MoonClaw Corridor Receipts\n\n"
  for corridor in receipts {
    text += "- \{corridor.receipt.receipt_id}\n"
    text += "  - proposal: \{corridor.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(corridor.receipt.status)}\n"
    text += "  - scan: \{corridor.scan_id}\n"
    text += "  - sampled windows: \{corridor.sampled_window_count}\n"
    text += "  - best window: \{corridor.best_window_id}\n"
    text += "  - selected route: \{corridor.selected_route_id}\n"
    text += "  - next action: \{corridor.next_action}\n"
    text += "  - validation:\n"
    for check in corridor.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - top windows:\n"
    for score in corridor.window_scores {
      if score.rank <= 5 {
        text += "    - #\{score.rank} \{score.window_id}: \{@mission.traverse_decision_label(score.decision)} risk \{score.risk_index}, grade \{score.max_grade}, roughness \{score.roughness_m} m"
        if score.selected_route_id != "" {
          text += ", route \{score.selected_route_id}"
        }
        text += "\n"
      }
    }
  }
  text
}

///|
pub fn render_ephemeris_receipts_markdown(
  receipts : Array[MoonClawEphemerisAcquisitionReceipt],
) -> String {
  let mut text = "# MoonClaw Ephemeris Receipts\n\n"
  for ephemeris in receipts {
    text += "- \{ephemeris.receipt.receipt_id}\n"
    text += "  - proposal: \{ephemeris.receipt.proposal_id}\n"
    text += "  - status: \{receipt_status_label(ephemeris.receipt.status)}\n"
    text += "  - energy decision: \{@mission.traverse_decision_label(ephemeris.energy_decision)}\n"
    text += "  - has time-windowed ephemeris: \{ephemeris.has_time_window_ephemeris}\n"
    text += "  - power-window evidence: \{ephemeris.power_window_evidence_id}\n"
    text += "  - power-window source: \{ephemeris.power_window_source_path}\n"
    text += "  - power-window source status: \{ephemeris.power_window_source_status}\n"
    text += "  - routes: \{ephemeris.route_count} total, \{ephemeris.blocked_route_count} blocked\n"
    text += "  - required sunlit hours: \{ephemeris.required_sunlit_hours}\n"
    text += "  - dark survival hours: \{ephemeris.assumed_dark_survival_hours}\n"
    text += "  - required energy: \{ephemeris.required_energy_wh} Wh\n"
    text += "  - verified available energy: \{ephemeris.verified_available_energy_wh} Wh\n"
    text += "  - next action: \{ephemeris.next_action}\n"
    text += "  - validation:\n"
    for check in ephemeris.validation_checks {
      let status = if check.passed { "pass" } else { "fail" }
      text += "    - \{check.validation_id}: \{status} - \{check.note}\n"
    }
    text += "  - missing outputs:\n"
    for output in ephemeris.missing_outputs {
      text += "    - \{output}\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_receipts_markdown() -> String {
  render_receipts_markdown(first_trusted_square_receipts())
}

///|
pub fn first_trusted_square_ephemeris_receipts_markdown() -> String {
  render_ephemeris_receipts_markdown(first_trusted_square_ephemeris_receipts())
}

///|
pub fn first_trusted_square_corridor_receipts_markdown() -> String {
  render_corridor_receipts_markdown(first_trusted_square_corridor_receipts())
}

///|
pub fn render_receipts_json(
  receipts : Array[MoonClawRouteScoringReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn render_ephemeris_receipts_json(
  receipts : Array[MoonClawEphemerisAcquisitionReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn render_corridor_receipts_json(
  receipts : Array[MoonClawCorridorExpansionReceipt],
) -> Json {
  receipts.to_json()
}

///|
pub fn first_trusted_square_receipts_json() -> Json {
  render_receipts_json(first_trusted_square_receipts())
}

///|
pub fn first_trusted_square_ephemeris_receipts_json() -> Json {
  render_ephemeris_receipts_json(first_trusted_square_ephemeris_receipts())
}

///|
pub fn first_trusted_square_corridor_receipts_json() -> Json {
  render_corridor_receipts_json(first_trusted_square_corridor_receipts())
}

///|
pub fn render_markdown(proposals : Array[MoonClawProposal]) -> String {
  let mut text = "# MoonClaw Modeling Proposals\n\n"
  for proposal in proposals {
    text += "- \{proposal.proposal_id}\n"
    text += "  - kind: \{job_kind_label(proposal.job_kind)}\n"
    text += "  - priority: \{priority_label(proposal.priority)}\n"
    text += "  - title: \{proposal.title}\n"
    text += "  - objective: \{proposal.objective}\n"
    text += "  - blocked by: \{proposal.blocked_by.join(", ")}\n"
    text += "  - inputs:\n"
    for input in proposal.inputs {
      text += "    - \{input.input_id}: \{input.evidence_path} - \{input.summary}\n"
    }
    text += "  - acceptance:\n"
    for acceptance in proposal.acceptance_criteria {
      text += "    - \{acceptance.criterion_id}: \{acceptance.description}\n"
    }
    text += "  - expected outputs:\n"
    for output in proposal.expected_outputs {
      text += "    - \{output}\n"
    }
  }
  text
}

///|
pub fn first_trusted_square_markdown() -> String {
  render_markdown(first_trusted_square_proposals())
}

///|
pub fn render_json(proposals : Array[MoonClawProposal]) -> Json {
  proposals.to_json()
}

///|
pub fn first_trusted_square_json() -> Json {
  render_json(first_trusted_square_proposals())
}
