///|
pub(all) enum TraverseDecision {
  Allow
  Review
  Block
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TraverseProfile {
  profile_id : String
  label : String
  max_grade : Double
  caution_grade : Double
  max_roughness_m : Double
  caution_roughness_m : Double
  min_confidence : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TraverseScore {
  profile : TraverseProfile
  decision : TraverseDecision
  score : Int
  reasons : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct IlluminationConstraint {
  constraint_id : String
  label : String
  min_sunlit_hours : Double
  max_dark_hours : Double
  max_relief_shadow_risk : Double
  caution_relief_shadow_risk : Double
  min_confidence : Double
  has_time_window_ephemeris : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct IlluminationAssessment {
  constraint : IlluminationConstraint
  evidence_dataset_id : String
  evidence_tile_id : String
  relief_shadow_risk : Double
  confidence : Double
  decision : TraverseDecision
  reasons : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RouteCandidate {
  route_id : String
  label : String
  strategy : String
  evidence_dataset_id : String
  evidence_tile_id : String
  evidence_source_path : String
  evidence_summary : String
  expected_max_grade : Double
  expected_roughness_m : Double
  confidence : Double
  illumination : IlluminationAssessment
  decision : TraverseDecision
  score : Int
  reasons : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn conservative_rover_profile() -> TraverseProfile {
  {
    profile_id: "conservative-lunar-rover-v1",
    label: "Conservative Lunar Rover",
    max_grade: 0.35,
    caution_grade: 0.18,
    max_roughness_m: 2.5,
    caution_roughness_m: 1.2,
    min_confidence: 0.7,
  }
}

///|
pub fn traverse_decision_label(decision : TraverseDecision) -> String {
  match decision {
    Allow => "allow"
    Review => "review"
    Block => "block"
  }
}

///|
pub fn route_candidate_status_label(candidate : RouteCandidate) -> String {
  traverse_decision_label(candidate.decision)
}

///|
pub fn illumination_decision_label(
  assessment : IlluminationAssessment,
) -> String {
  traverse_decision_label(assessment.decision)
}

///|
pub fn conservative_illumination_constraint() -> IlluminationConstraint {
  {
    constraint_id: "conservative-south-pole-power-v1",
    label: "Conservative South Pole Power/Thermal Gate",
    min_sunlit_hours: 4.0,
    max_dark_hours: 2.0,
    max_relief_shadow_risk: 0.22,
    caution_relief_shadow_risk: 0.14,
    min_confidence: 0.7,
    has_time_window_ephemeris: false,
  }
}

///|
fn add_reason_if(
  reasons : Array[String],
  condition : Bool,
  reason : String,
) -> Unit {
  if condition {
    reasons.push(reason)
  }
}

///|
fn score_from_reasons(
  decision : TraverseDecision,
  reasons : Array[String],
) -> Int {
  match decision {
    Allow => 90
    Review => 70 - reasons.length() * 8
    Block => 30 - reasons.length() * 5
  }
}

///|
pub fn score_traverse(
  metrics : @terrain.TerrainMetrics,
  profile : TraverseProfile,
) -> TraverseScore {
  let reasons : Array[String] = []
  let grade_blocked = metrics.max_neighbor_grade >= profile.max_grade
  let roughness_blocked = metrics.roughness_m >= profile.max_roughness_m
  let grade_review = metrics.max_neighbor_grade >= profile.caution_grade
  let roughness_review = metrics.roughness_m >= profile.caution_roughness_m
  let confidence_review = metrics.uncertainty.confidence <
    profile.min_confidence
  add_reason_if(
    reasons, grade_blocked, "max neighbor grade exceeds rover hard limit",
  )
  add_reason_if(
    reasons, roughness_blocked, "roughness exceeds rover hard limit",
  )
  add_reason_if(
    reasons,
    !grade_blocked && grade_review,
    "max neighbor grade needs route review",
  )
  add_reason_if(
    reasons,
    !roughness_blocked && roughness_review,
    "roughness needs route review",
  )
  add_reason_if(
    reasons, confidence_review, "terrain confidence below traverse threshold",
  )
  let decision = if grade_blocked || roughness_blocked {
    Block
  } else if grade_review ||
    roughness_review ||
    confidence_review ||
    metrics.hazard_class == @terrain.HazardClass::Caution {
    Review
  } else {
    Allow
  }
  {
    profile,
    decision,
    score: score_from_reasons(decision, reasons),
    reasons,
    next_action: match decision {
      Allow => "candidate route may advance to simulation"
      Review =>
        "operator should review route and source confidence before simulation"
      Block => "choose alternate route or improve terrain evidence"
    },
  }
}

///|
pub fn first_trusted_square_traverse_score() -> TraverseScore {
  score_traverse(
    @terrain.first_trusted_square_metrics(),
    conservative_rover_profile(),
  )
}

///|
fn combine_decisions(
  terrain_decision : TraverseDecision,
  illumination_decision : TraverseDecision,
) -> TraverseDecision {
  if terrain_decision == Block || illumination_decision == Block {
    Block
  } else if terrain_decision == Review || illumination_decision == Review {
    Review
  } else {
    Allow
  }
}

///|
fn route_score(
  decision : TraverseDecision,
  confidence : Double,
  illumination : IlluminationAssessment,
) -> Int {
  let base = match decision {
    Allow => 88
    Review => 62
    Block => 18
  }
  let confidence_penalty = if confidence < 0.5 {
    14
  } else if confidence < 0.7 {
    8
  } else {
    0
  }
  let illumination_penalty = match illumination.decision {
    Allow => 0
    Review => 6
    Block => 12
  }
  base - confidence_penalty - illumination_penalty
}

///|
fn relief_shadow_risk(
  grid : @terrain.TerrainGrid,
  metrics : @terrain.TerrainMetrics,
) -> Double {
  let span = (grid.rows + grid.cols).to_double() * grid.cell_size_m
  if span <= 0.0 {
    1.0
  } else {
    metrics.elevation_range_m / span
  }
}

///|
pub fn assess_illumination(
  grid : @terrain.TerrainGrid,
  constraint : IlluminationConstraint,
) -> IlluminationAssessment {
  let metrics = @terrain.analyze(grid)
  let risk = relief_shadow_risk(grid, metrics)
  let confidence = metrics.uncertainty.confidence * 0.6
  let reasons : Array[String] = []
  let missing_ephemeris = !constraint.has_time_window_ephemeris
  let risk_blocked = risk >= constraint.max_relief_shadow_risk
  let risk_review = risk >= constraint.caution_relief_shadow_risk
  let confidence_review = confidence < constraint.min_confidence
  add_reason_if(
    reasons, missing_ephemeris, "no time-windowed solar ephemeris is attached",
  )
  add_reason_if(
    reasons, risk_blocked, "local relief shadow proxy exceeds conservative limit",
  )
  add_reason_if(
    reasons,
    !risk_blocked && risk_review,
    "local relief shadow proxy needs illumination review",
  )
  add_reason_if(
    reasons, confidence_review, "illumination confidence below power planning threshold",
  )
  let decision = if missing_ephemeris || risk_blocked {
    Block
  } else if risk_review || confidence_review {
    Review
  } else {
    Allow
  }
  {
    constraint,
    evidence_dataset_id: grid.source_manifest.dataset_id,
    evidence_tile_id: grid.tile_id,
    relief_shadow_risk: risk,
    confidence,
    decision,
    reasons,
    next_action: match decision {
      Allow => "illumination gate may advance to energy simulation"
      Review => "review illumination window before route simulation"
      Block =>
        "attach time-windowed solar ephemeris and widen terrain evidence before route simulation"
    },
  }
}

///|
fn make_route_candidate(
  route_id : String,
  label : String,
  strategy : String,
  grid : @terrain.TerrainGrid,
  profile : TraverseProfile,
  extra_reason : String,
  next_action : String,
) -> RouteCandidate {
  let metrics = @terrain.analyze(grid)
  let reasons : Array[String] = []
  let expected_max_grade = metrics.max_neighbor_grade
  let expected_roughness_m = metrics.roughness_m
  let confidence = metrics.uncertainty.confidence
  let illumination = assess_illumination(
    grid,
    conservative_illumination_constraint(),
  )
  let grade_blocked = expected_max_grade >= profile.max_grade
  let roughness_blocked = expected_roughness_m >= profile.max_roughness_m
  let grade_review = expected_max_grade >= profile.caution_grade
  let roughness_review = expected_roughness_m >= profile.caution_roughness_m
  let confidence_review = confidence < profile.min_confidence
  add_reason_if(
    reasons, grade_blocked, "expected grade exceeds rover hard limit",
  )
  add_reason_if(
    reasons, roughness_blocked, "expected roughness exceeds rover hard limit",
  )
  add_reason_if(
    reasons,
    !grade_blocked && grade_review,
    "expected grade needs route review",
  )
  add_reason_if(
    reasons,
    !roughness_blocked && roughness_review,
    "expected roughness needs route review",
  )
  add_reason_if(reasons, confidence_review, "route confidence below threshold")
  if extra_reason != "" {
    reasons.push(extra_reason)
  }
  let terrain_decision = if grade_blocked || roughness_blocked {
    Block
  } else if grade_review || roughness_review || confidence_review {
    Review
  } else {
    Allow
  }
  let decision = combine_decisions(terrain_decision, illumination.decision)
  if illumination.decision != Allow {
    reasons.push(
      "illumination gate is \{illumination_decision_label(illumination)}",
    )
  }
  {
    route_id,
    label,
    strategy,
    evidence_dataset_id: grid.source_manifest.dataset_id,
    evidence_tile_id: grid.tile_id,
    evidence_source_path: grid.source_manifest.source_path,
    evidence_summary: "\{@terrain.hazard_label(metrics.hazard_class)} measured window; elevation range \{metrics.elevation_range_m} m",
    expected_max_grade,
    expected_roughness_m,
    confidence,
    illumination,
    decision,
    score: route_score(decision, confidence, illumination),
    reasons,
    next_action,
  }
}

///|
pub fn first_trusted_square_route_candidates() -> Array[RouteCandidate] {
  let profile = conservative_rover_profile()
  [
    make_route_candidate(
      "direct-lola-window",
      "Direct traverse across measured LOLA patch",
      "Use the active 4x4 measured window as-is.",
      @terrain.first_trusted_square_grid(),
      profile,
      "active LOLA patch is blocked",
      "do not traverse directly; use this as the baseline hazard case",
    ),
    make_route_candidate(
      "west-contour-detour",
      "West contour detour candidate",
      "Test the west-adjacent LOLA window as a possible contour route around the active patch.",
      @terrain.first_trusted_square_west_contour_grid(),
      profile,
      "west-adjacent LOLA window is measured but still blocked at this scale",
      "widen the west corridor extraction before simulation",
    ),
    make_route_candidate(
      "north-rim-stepout",
      "North rim step-out candidate",
      "Test the north-adjacent LOLA window as a possible step-out toward a smoother rim approach.",
      @terrain.first_trusted_square_north_rim_grid(),
      profile,
      "north-adjacent LOLA window is measured but still blocked at this scale",
      "widen the north corridor extraction and add illumination review",
    ),
    make_route_candidate(
      "southwest-bypass",
      "Southwest widened bypass candidate",
      "Use the lowest-grade measured window from the first 5x5 corridor scan as a possible bypass direction.",
      @terrain.first_trusted_square_southwest_bypass_grid(),
      profile,
      "southwest widened corridor is measured and lower risk but still blocked",
      "continue corridor search beyond the southwest bypass before simulation",
    ),
    make_route_candidate(
      "south-stepout",
      "South step-out candidate",
      "Use the south measured window from the first 5x5 corridor scan as a second widened route direction.",
      @terrain.first_trusted_square_south_stepout_grid(),
      profile,
      "south widened corridor is measured and smoother than the active patch but still blocked",
      "continue south corridor extraction and add ephemeris-backed illumination review",
    ),
  ]
}
