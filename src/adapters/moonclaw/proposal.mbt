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
