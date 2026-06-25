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
  power_window_evidence_id : String
  power_window_source_path : String
  power_window_source_status : String
  time_start_utc : String
  time_end_utc : String
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
pub(all) struct EnergyBudget {
  budget_id : String
  label : String
  power_window_evidence_id : String
  power_window_source_path : String
  power_window_source_status : String
  time_start_utc : String
  time_end_utc : String
  battery_capacity_wh : Double
  reserve_wh : Double
  drive_power_w : Double
  thermal_survival_power_w : Double
  comms_power_w : Double
  min_energy_margin_wh : Double
  required_sunlit_hours : Double
  assumed_dark_survival_hours : Double
  verified_available_energy_wh : Double
  has_time_window_ephemeris : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PowerWindowEvidence {
  evidence_id : String
  source_status : String
  source_family_url : String
  local_source_path : String
  source_sha256 : String
  source_bytes : Int
  time_start_utc : String
  time_end_utc : String
  target_lat_deg : Double
  target_lon_deg : Double
  sunlit_hours : Double
  dark_hours : Double
  available_energy_wh : Double
  confidence : Double
  has_time_window_ephemeris : Bool
  reasons : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct EnergyAssessment {
  budget : EnergyBudget
  route_count : Int
  blocked_route_count : Int
  estimated_drive_hours : Double
  estimated_dark_survival_hours : Double
  required_energy_wh : Double
  available_energy_wh : Double
  margin_wh : Double
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
pub(all) struct CorridorScanWindow {
  scan_id : String
  window_id : String
  rank : Int
  row_offset : Int
  col_offset : Int
  source_row_start : Int
  source_col_start : Int
  min_elevation_m : Double
  max_elevation_m : Double
  elevation_range_m : Double
  max_neighbor_grade : Double
  roughness_m : Double
  decision : TraverseDecision
  selected_route_id : String
  note : String
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
pub fn corridor_scan_window_status_label(window : CorridorScanWindow) -> String {
  traverse_decision_label(window.decision)
}

///|
pub fn illumination_decision_label(
  assessment : IlluminationAssessment,
) -> String {
  traverse_decision_label(assessment.decision)
}

///|
pub fn energy_decision_label(assessment : EnergyAssessment) -> String {
  traverse_decision_label(assessment.decision)
}

///|
pub fn first_trusted_square_power_window_evidence() -> PowerWindowEvidence {
  generated_first_trusted_square_power_window_evidence()
}

///|
fn verified_available_energy_wh(evidence : PowerWindowEvidence) -> Double {
  if !evidence.has_time_window_ephemeris {
    0.0
  } else {
    evidence.available_energy_wh
  }
}

///|
pub fn conservative_illumination_constraint() -> IlluminationConstraint {
  let evidence = first_trusted_square_power_window_evidence()
  {
    constraint_id: "conservative-south-pole-power-v1",
    label: "Conservative South Pole Power/Thermal Gate",
    power_window_evidence_id: evidence.evidence_id,
    power_window_source_path: evidence.local_source_path,
    power_window_source_status: evidence.source_status,
    time_start_utc: evidence.time_start_utc,
    time_end_utc: evidence.time_end_utc,
    min_sunlit_hours: 4.0,
    max_dark_hours: 2.0,
    max_relief_shadow_risk: 0.22,
    caution_relief_shadow_risk: 0.14,
    min_confidence: 0.7,
    has_time_window_ephemeris: evidence.has_time_window_ephemeris,
  }
}

///|
pub fn conservative_energy_budget() -> EnergyBudget {
  let evidence = first_trusted_square_power_window_evidence()
  {
    budget_id: "conservative-south-pole-energy-v1",
    label: "Conservative South Pole Rover Energy Budget",
    power_window_evidence_id: evidence.evidence_id,
    power_window_source_path: evidence.local_source_path,
    power_window_source_status: evidence.source_status,
    time_start_utc: evidence.time_start_utc,
    time_end_utc: evidence.time_end_utc,
    battery_capacity_wh: 1200.0,
    reserve_wh: 600.0,
    drive_power_w: 120.0,
    thermal_survival_power_w: 35.0,
    comms_power_w: 20.0,
    min_energy_margin_wh: 250.0,
    required_sunlit_hours: 4.0,
    assumed_dark_survival_hours: 2.0,
    verified_available_energy_wh: verified_available_energy_wh(evidence),
    has_time_window_ephemeris: evidence.has_time_window_ephemeris,
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
    reasons,
    missing_ephemeris,
    "power-window evidence \{constraint.power_window_evidence_id} has source status \{constraint.power_window_source_status}",
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
fn blocked_route_count(routes : Array[RouteCandidate]) -> Int {
  let mut count = 0
  for route in routes {
    if route.decision == Block {
      count += 1
    }
  }
  count
}

///|
pub fn assess_energy_window(
  routes : Array[RouteCandidate],
  budget : EnergyBudget,
) -> EnergyAssessment {
  let route_count = routes.length()
  let blocked_count = blocked_route_count(routes)
  let estimated_drive_hours = route_count.to_double() * 0.25
  let estimated_dark_survival_hours = budget.assumed_dark_survival_hours
  let required_energy_wh = budget.reserve_wh +
    budget.drive_power_w * estimated_drive_hours +
    budget.comms_power_w * estimated_drive_hours +
    budget.thermal_survival_power_w * estimated_dark_survival_hours
  let available_energy_wh = if !budget.has_time_window_ephemeris {
    0.0
  } else if budget.verified_available_energy_wh > budget.battery_capacity_wh {
    budget.battery_capacity_wh
  } else {
    budget.verified_available_energy_wh
  }
  let margin_wh = available_energy_wh - required_energy_wh
  let reasons : Array[String] = []
  add_reason_if(
    reasons,
    !budget.has_time_window_ephemeris,
    "no time-windowed solar ephemeris is attached for energy planning",
  )
  add_reason_if(
    reasons,
    !budget.has_time_window_ephemeris,
    "power-window evidence \{budget.power_window_evidence_id} has source status \{budget.power_window_source_status}",
  )
  add_reason_if(
    reasons,
    margin_wh < 0.0,
    "estimated energy demand exceeds verified available energy",
  )
  add_reason_if(
    reasons,
    margin_wh >= 0.0 && margin_wh < budget.min_energy_margin_wh,
    "estimated energy margin is below conservative reserve",
  )
  add_reason_if(
    reasons,
    blocked_count > 0,
    "\{blocked_count} route candidates remain blocked before energy simulation",
  )
  let decision = if !budget.has_time_window_ephemeris || margin_wh < 0.0 {
    Block
  } else if margin_wh < budget.min_energy_margin_wh || blocked_count > 0 {
    Review
  } else {
    Allow
  }
  {
    budget,
    route_count,
    blocked_route_count: blocked_count,
    estimated_drive_hours,
    estimated_dark_survival_hours,
    required_energy_wh,
    available_energy_wh,
    margin_wh,
    decision,
    reasons,
    next_action: match decision {
      Allow => "energy window may advance to route simulation"
      Review => "review route blockers and energy margin before simulation"
      Block =>
        "attach time-windowed solar ephemeris and verify rover energy budget before simulation"
    },
  }
}

///|
pub fn first_trusted_square_energy_assessment() -> EnergyAssessment {
  assess_energy_window(
    first_trusted_square_route_candidates(),
    conservative_energy_budget(),
  )
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
    make_route_candidate(
      "northeast-stepout",
      "Northeast 9x9 step-out candidate",
      "Promote the best measured window from the active 9x9 corridor scan into a named route fixture.",
      @terrain.first_trusted_square_northeast_stepout_grid(),
      profile,
      "best active 9x9 corridor window is measured and selected but still blocked",
      "review the promoted route fixture and attach ephemeris-backed illumination before simulation",
    ),
  ]
}

///|
pub fn first_trusted_square_corridor_scan() -> Array[CorridorScanWindow] {
  generated_first_trusted_square_corridor_scan()
}

///|
pub fn first_trusted_square_best_corridor_window() -> CorridorScanWindow {
  first_trusted_square_corridor_scan()[0]
}
