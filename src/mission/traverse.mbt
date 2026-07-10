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
  min_sun_altitude_deg : Double
  max_sun_altitude_deg : Double
  min_sunlit_hours : Double
  max_dark_hours : Double
  max_relief_shadow_risk : Double
  caution_relief_shadow_risk : Double
  min_confidence : Double
  has_time_window_ephemeris : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LocalHorizonEvidence {
  evidence_id : String
  route_id : String
  site_id : String
  source_dataset_id : String
  source_tile_id : String
  source_path : String
  power_window_evidence_id : String
  power_window_source_path : String
  output_path : String
  method_id : String
  generated_by : String
  rows : Int
  cols : Int
  cell_size_m : Double
  center_elevation_m : Double
  max_obstruction_elevation_m : Double
  max_horizon_angle_deg : Double
  min_sun_altitude_deg : Double
  max_sun_altitude_deg : Double
  evaluated_sample_count : Int
  spherical_sunlit_hours : Double
  terrain_sunlit_hours : Double
  terrain_shadowed_hours : Double
  longest_dark_hours : Double
  terrain_available_energy_wh : Double
  minimum_solar_clearance_deg : Double
  maximum_solar_clearance_deg : Double
  azimuth_samples : Array[HorizonAzimuthSample]
  confidence : Double
  decision : TraverseDecision
  reasons : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct HorizonAzimuthSample {
  sector_id : String
  label : String
  azimuth_center_deg : Double
  obstruction_row : Int
  obstruction_col : Int
  obstruction_elevation_m : Double
  distance_m : Double
  horizon_angle_deg : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct IlluminationAssessment {
  constraint : IlluminationConstraint
  evidence_dataset_id : String
  evidence_tile_id : String
  local_horizon : LocalHorizonEvidence
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
pub(all) struct PowerWindowSourceFile {
  file_id : String
  label : String
  source_url : String
  local_path : String
  sha256 : String
  bytes : Int
  role : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PowerWindowComputation {
  method_id : String
  generated_by : String
  time_step_minutes : Int
  horizon_model : String
  rover_power_model : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PowerWindowEvidence {
  evidence_id : String
  source_status : String
  source_family_url : String
  local_source_path : String
  source_sha256 : String
  source_bytes : Int
  source_files : Array[PowerWindowSourceFile]
  computation : PowerWindowComputation
  observer_geometry : @lunar_ephemeris.ObserverGeometryTimeline
  time_start_utc : String
  time_end_utc : String
  target_lat_deg : Double
  target_lon_deg : Double
  min_sun_altitude_deg : Double
  max_sun_altitude_deg : Double
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
pub(all) struct EnergyRemediationEvidence {
  evidence_id : String
  site_id : String
  route_id : String
  power_window_evidence_id : String
  power_window_source_path : String
  terrain_evidence_path : String
  horizon_evidence_path : String
  output_path : String
  method_id : String
  generated_by : String
  source_budget_id : String
  route_count_before_bound : Int
  selected_route_count : Int
  blocked_route_count : Int
  all_route_required_energy_wh : Double
  bounded_required_energy_wh : Double
  verified_available_energy_wh : Double
  all_route_margin_wh : Double
  bounded_margin_wh : Double
  minimum_margin_wh : Double
  margin_gap_wh : Double
  route_count_demand_reduction_wh : Double
  selected_route_drive_hours : Double
  dark_survival_hours : Double
  reserve_wh : Double
  drive_energy_wh : Double
  comms_energy_wh : Double
  thermal_survival_energy_wh : Double
  max_dark_survival_hours_for_min_margin : Double
  dark_survival_reduction_needed_hours : Double
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
  terrain_remediation : TerrainRemediationEvidence
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
pub fn energy_remediation_decision_label(
  evidence : EnergyRemediationEvidence,
) -> String {
  traverse_decision_label(evidence.decision)
}

///|
pub fn first_trusted_square_power_window_evidence() -> PowerWindowEvidence {
  generated_first_trusted_square_power_window_evidence()
}

///|
pub fn first_trusted_square_northeast_stepout_horizon_evidence() -> LocalHorizonEvidence {
  let power = first_trusted_square_power_window_evidence()
  bounded_local_horizon_evidence(
    @terrain.first_trusted_square_northeast_stepout_grid(),
    conservative_illumination_constraint(),
    power.observer_geometry.hourly_solar_track,
  )
}

///|
pub fn first_trusted_square_northeast_stepout_horizon_json() -> Json {
  first_trusted_square_northeast_stepout_horizon_evidence().to_json()
}

///|
pub fn first_trusted_square_northeast_stepout_horizon_markdown() -> String {
  let evidence = first_trusted_square_northeast_stepout_horizon_evidence()
  let mut text = "# Selected Route Local Horizon\n\n"
  text += "- evidence: \{evidence.evidence_id}\n"
  text += "- site: \{evidence.site_id}\n"
  text += "- route: \{evidence.route_id}\n"
  text += "- source: \{evidence.source_path}\n"
  text += "- power window: \{evidence.power_window_evidence_id}\n"
  text += "- method: \{evidence.method_id}\n"
  text += "- decision: \{traverse_decision_label(evidence.decision)}\n"
  text += "- max horizon angle: \{evidence.max_horizon_angle_deg} deg\n"
  text += "- max sun altitude: \{evidence.max_sun_altitude_deg} deg\n"
  text += "- evaluated hourly samples: \{evidence.evaluated_sample_count}\n"
  text += "- terrain-visible sunlight: \{evidence.terrain_sunlit_hours} h\n"
  text += "- terrain-shadowed daylight: \{evidence.terrain_shadowed_hours} h\n"
  text += "- longest darkness: \{evidence.longest_dark_hours} h\n"
  text += "- route-available energy: \{evidence.terrain_available_energy_wh} Wh\n"
  text += "- solar clearance range: \{evidence.minimum_solar_clearance_deg} to \{evidence.maximum_solar_clearance_deg} deg\n"
  text += "- confidence: \{evidence.confidence}\n\n"
  text += "## Azimuth Profile\n\n"
  for sample in evidence.azimuth_samples {
    text += "- \{sample.label} (\{sample.azimuth_center_deg} deg): \{sample.horizon_angle_deg} deg at r\{sample.obstruction_row} c\{sample.obstruction_col}\n"
  }
  text += "\n"
  text += "## Reasons\n\n"
  for reason in evidence.reasons {
    text += "- \{reason}\n"
  }
  text += "\n## Next Action\n\n"
  text += evidence.next_action
  text += "\n"
  text
}

///|
pub fn first_trusted_square_energy_remediation() -> EnergyRemediationEvidence {
  energy_remediation_for_selected_route(
    first_trusted_square_energy_assessment(),
    "northeast-stepout",
    "artifact/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
    first_trusted_square_northeast_stepout_horizon_evidence().output_path,
    "artifact/mission/first_trusted_square_energy_remediation.json",
  )
}

///|
pub fn first_trusted_square_energy_remediation_json() -> Json {
  first_trusted_square_energy_remediation().to_json()
}

///|
pub fn first_trusted_square_energy_remediation_markdown() -> String {
  let evidence = first_trusted_square_energy_remediation()
  let mut text = "# Selected Route Energy Remediation\n\n"
  text += "- evidence: \{evidence.evidence_id}\n"
  text += "- site: \{evidence.site_id}\n"
  text += "- route: \{evidence.route_id}\n"
  text += "- power window: \{evidence.power_window_evidence_id}\n"
  text += "- decision: \{energy_remediation_decision_label(evidence)}\n"
  text += "- all-route required energy: \{evidence.all_route_required_energy_wh} Wh\n"
  text += "- bounded required energy: \{evidence.bounded_required_energy_wh} Wh\n"
  text += "- verified available energy: \{evidence.verified_available_energy_wh} Wh\n"
  text += "- bounded margin: \{evidence.bounded_margin_wh} Wh\n"
  text += "- margin gap: \{evidence.margin_gap_wh} Wh\n"
  text += "- selected-route drive hours: \{evidence.selected_route_drive_hours}\n"
  text += "- dark survival hours: \{evidence.dark_survival_hours}\n"
  text += "- route-count demand reduction: \{evidence.route_count_demand_reduction_wh} Wh\n\n"
  text += "## Demand Components\n\n"
  text += "- reserve: \{evidence.reserve_wh} Wh\n"
  text += "- drive: \{evidence.drive_energy_wh} Wh\n"
  text += "- comms: \{evidence.comms_energy_wh} Wh\n"
  text += "- thermal survival: \{evidence.thermal_survival_energy_wh} Wh\n\n"
  text += "## Reasons\n\n"
  for reason in evidence.reasons {
    text += "- \{reason}\n"
  }
  text += "\n## Next Action\n\n"
  text += evidence.next_action
  text += "\n"
  text
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
    min_sun_altitude_deg: evidence.min_sun_altitude_deg,
    max_sun_altitude_deg: evidence.max_sun_altitude_deg,
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
  let assumed_dark_survival_hours = if evidence.has_time_window_ephemeris {
    evidence.dark_hours
  } else {
    2.0
  }
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
    assumed_dark_survival_hours,
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
fn route_candidate_next_action(
  terrain_decision : TraverseDecision,
  illumination : IlluminationAssessment,
  terrain_action : String,
) -> String {
  match (terrain_decision, illumination.decision) {
    (Allow, Allow) | (Block, Allow) | (Review, Allow) => terrain_action
    (Allow, Block) | (Allow, Review) => illumination.next_action
    (Block, Block) | (Block, Review) | (Review, Block) | (Review, Review) =>
      "\{terrain_action}; \{illumination.next_action}"
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
fn local_horizon_evidence(
  grid : @terrain.TerrainGrid,
  constraint : IlluminationConstraint,
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
) -> LocalHorizonEvidence {
  bounded_local_horizon_evidence(grid, constraint, solar_track)
}

///|
pub fn assess_illumination(
  grid : @terrain.TerrainGrid,
  constraint : IlluminationConstraint,
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
) -> IlluminationAssessment {
  let metrics = @terrain.analyze(grid)
  let risk = relief_shadow_risk(grid, metrics)
  let local_horizon = local_horizon_evidence(grid, constraint, solar_track)
  let confidence = metrics.uncertainty.confidence * 0.6
  let reasons : Array[String] = []
  let missing_ephemeris = !constraint.has_time_window_ephemeris
  let risk_blocked = risk >= constraint.max_relief_shadow_risk
  let risk_review = risk >= constraint.caution_relief_shadow_risk
  let horizon_blocked = local_horizon.decision == Block
  let horizon_review = local_horizon.decision == Review
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
    horizon_blocked,
    "hourly route exposure has \{local_horizon.terrain_sunlit_hours} sunlit hours and \{local_horizon.longest_dark_hours} continuous dark hours",
  )
  add_reason_if(
    reasons,
    !risk_blocked && risk_review,
    "local relief shadow proxy needs illumination review",
  )
  add_reason_if(
    reasons,
    !horizon_blocked && horizon_review,
    "bounded local horizon evidence needs illumination review",
  )
  add_reason_if(
    reasons, confidence_review, "illumination confidence below power planning threshold",
  )
  let decision = if missing_ephemeris || risk_blocked || horizon_blocked {
    Block
  } else if risk_review || horizon_review || confidence_review {
    Review
  } else {
    Allow
  }
  {
    constraint,
    evidence_dataset_id: grid.source_manifest.dataset_id,
    evidence_tile_id: grid.tile_id,
    local_horizon,
    relief_shadow_risk: risk,
    confidence,
    decision,
    reasons,
    next_action: match decision {
      Allow => "illumination gate may advance to energy simulation"
      Review => "review illumination window before route simulation"
      Block =>
        if missing_ephemeris {
          "attach time-windowed solar ephemeris and widen terrain evidence before route simulation"
        } else if horizon_blocked {
          local_horizon.next_action
        } else {
          "widen local horizon and terrain-shadow evidence before route simulation"
        }
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
        if !budget.has_time_window_ephemeris {
          "attach time-windowed solar ephemeris and verify rover energy budget before simulation"
        } else {
          "revise rover power model, route count, or site window before simulation"
        }
    },
  }
}

///|
pub fn energy_remediation_for_selected_route(
  energy : EnergyAssessment,
  route_id : String,
  terrain_evidence_path : String,
  horizon_evidence_path : String,
  output_path : String,
) -> EnergyRemediationEvidence {
  let budget = energy.budget
  let selected_route_drive_hours = 0.25
  let drive_energy_wh = budget.drive_power_w * selected_route_drive_hours
  let comms_energy_wh = budget.comms_power_w * selected_route_drive_hours
  let thermal_survival_energy_wh = budget.thermal_survival_power_w *
    energy.estimated_dark_survival_hours
  let bounded_required_energy_wh = budget.reserve_wh +
    drive_energy_wh +
    comms_energy_wh +
    thermal_survival_energy_wh
  let bounded_margin_wh = energy.available_energy_wh -
    bounded_required_energy_wh
  let margin_gap_wh = if bounded_margin_wh >= budget.min_energy_margin_wh {
    0.0
  } else {
    budget.min_energy_margin_wh - bounded_margin_wh
  }
  let route_count_demand_reduction_wh = energy.required_energy_wh -
    bounded_required_energy_wh
  let raw_max_dark_survival_hours_for_min_margin = (
      energy.available_energy_wh -
      budget.reserve_wh -
      drive_energy_wh -
      comms_energy_wh -
      budget.min_energy_margin_wh
    ) /
    budget.thermal_survival_power_w
  let max_dark_survival_hours_for_min_margin = if raw_max_dark_survival_hours_for_min_margin <=
    0.0 {
    0.0
  } else {
    raw_max_dark_survival_hours_for_min_margin
  }
  let dark_survival_reduction_needed_hours = if max_dark_survival_hours_for_min_margin >=
    energy.estimated_dark_survival_hours {
    0.0
  } else if max_dark_survival_hours_for_min_margin <= 0.0 {
    energy.estimated_dark_survival_hours
  } else {
    energy.estimated_dark_survival_hours -
    max_dark_survival_hours_for_min_margin
  }
  let reasons : Array[String] = []
  add_reason_if(
    reasons,
    !budget.has_time_window_ephemeris,
    "no time-windowed solar ephemeris is attached for bounded energy remediation",
  )
  add_reason_if(
    reasons,
    bounded_margin_wh < 0.0,
    "selected-route bounded demand still exceeds verified available energy by \{0.0 - bounded_margin_wh} Wh",
  )
  add_reason_if(
    reasons,
    bounded_margin_wh >= 0.0 && bounded_margin_wh < budget.min_energy_margin_wh,
    "selected-route bounded margin is below the minimum margin by \{margin_gap_wh} Wh",
  )
  add_reason_if(
    reasons,
    route_count_demand_reduction_wh > 0.0,
    "bounding demand from \{energy.route_count} candidate routes to one selected route removes \{route_count_demand_reduction_wh} Wh but does not clear the gate",
  )
  add_reason_if(
    reasons,
    thermal_survival_energy_wh > energy.available_energy_wh,
    "thermal survival demand \{thermal_survival_energy_wh} Wh exceeds verified available energy \{energy.available_energy_wh} Wh",
  )
  add_reason_if(
    reasons,
    energy.blocked_route_count > 0,
    "\{energy.blocked_route_count} route candidates remain blocked before energy can move out of review",
  )
  let decision = if !budget.has_time_window_ephemeris || bounded_margin_wh < 0.0 {
    Block
  } else if bounded_margin_wh < budget.min_energy_margin_wh ||
    energy.blocked_route_count > 0 {
    Review
  } else {
    Allow
  }
  {
    evidence_id: "first-trusted-square-energy-remediation-v1",
    site_id: "first-trusted-square",
    route_id,
    power_window_evidence_id: budget.power_window_evidence_id,
    power_window_source_path: budget.power_window_source_path,
    terrain_evidence_path,
    horizon_evidence_path,
    output_path,
    method_id: "bounded-selected-route-energy-remediation-v1",
    generated_by: "src/mission/traverse.mbt",
    source_budget_id: budget.budget_id,
    route_count_before_bound: energy.route_count,
    selected_route_count: 1,
    blocked_route_count: energy.blocked_route_count,
    all_route_required_energy_wh: energy.required_energy_wh,
    bounded_required_energy_wh,
    verified_available_energy_wh: energy.available_energy_wh,
    all_route_margin_wh: energy.margin_wh,
    bounded_margin_wh,
    minimum_margin_wh: budget.min_energy_margin_wh,
    margin_gap_wh,
    route_count_demand_reduction_wh,
    selected_route_drive_hours,
    dark_survival_hours: energy.estimated_dark_survival_hours,
    reserve_wh: budget.reserve_wh,
    drive_energy_wh,
    comms_energy_wh,
    thermal_survival_energy_wh,
    max_dark_survival_hours_for_min_margin,
    dark_survival_reduction_needed_hours,
    confidence: if decision == Allow {
      0.78
    } else {
      0.66
    },
    decision,
    reasons,
    next_action: match decision {
      Allow =>
        "selected-route energy remediation clears the conservative power-demand gate"
      Review =>
        "review route blockers and bounded energy margin before simulation"
      Block =>
        "reduce reserve or dark-survival demand, increase verified power-window energy, or keep northeast-stepout out of Simulation"
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
  illumination_constraint : IlluminationConstraint,
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
  extra_reason : String,
  next_action : String,
) -> RouteCandidate {
  let metrics = @terrain.analyze(grid)
  let reasons : Array[String] = []
  let expected_max_grade = metrics.max_neighbor_grade
  let expected_roughness_m = metrics.roughness_m
  let confidence = metrics.uncertainty.confidence
  let terrain_remediation = terrain_remediation_evidence(
    route_id, grid, metrics, profile,
  )
  let illumination = assess_illumination(
    grid, illumination_constraint, solar_track,
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
  let terrain_decision = terrain_remediation.decision
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
    terrain_remediation,
    expected_max_grade,
    expected_roughness_m,
    confidence,
    illumination,
    decision,
    score: route_score(decision, confidence, illumination),
    reasons,
    next_action: route_candidate_next_action(
      terrain_decision, illumination, next_action,
    ),
  }
}

///|
pub fn first_trusted_square_route_candidates() -> Array[RouteCandidate] {
  let profile = conservative_rover_profile()
  let illumination_constraint = conservative_illumination_constraint()
  let solar_track = first_trusted_square_power_window_evidence().observer_geometry.hourly_solar_track
  [
    make_route_candidate(
      "direct-lola-window",
      "Direct traverse across measured LOLA patch",
      "Use the active 4x4 measured window as-is.",
      @terrain.first_trusted_square_grid(),
      profile,
      illumination_constraint,
      solar_track,
      "active LOLA patch is blocked",
      "do not traverse directly; use this as the baseline hazard case",
    ),
    make_route_candidate(
      "west-contour-detour",
      "West contour detour candidate",
      "Test the west-adjacent LOLA window as a possible contour route around the active patch.",
      @terrain.first_trusted_square_west_contour_grid(),
      profile,
      illumination_constraint,
      solar_track,
      "west-adjacent LOLA window is measured but still blocked at this scale",
      "widen the west corridor extraction before simulation",
    ),
    make_route_candidate(
      "north-rim-stepout",
      "North rim step-out candidate",
      "Test the north-adjacent LOLA window as a possible step-out toward a smoother rim approach.",
      @terrain.first_trusted_square_north_rim_grid(),
      profile,
      illumination_constraint,
      solar_track,
      "north-adjacent LOLA window is measured but still blocked at this scale",
      "widen the north corridor extraction before simulation",
    ),
    make_route_candidate(
      "southwest-bypass",
      "Southwest widened bypass candidate",
      "Use the lowest-grade measured window from the first 5x5 corridor scan as a possible bypass direction.",
      @terrain.first_trusted_square_southwest_bypass_grid(),
      profile,
      illumination_constraint,
      solar_track,
      "southwest widened corridor is measured and lower risk but still blocked",
      "continue corridor search beyond the southwest bypass before simulation",
    ),
    make_route_candidate(
      "south-stepout",
      "South step-out candidate",
      "Use the south measured window from the first 5x5 corridor scan as a second widened route direction.",
      @terrain.first_trusted_square_south_stepout_grid(),
      profile,
      illumination_constraint,
      solar_track,
      "south widened corridor is measured and smoother than the active patch but still blocked",
      "continue south corridor extraction before simulation",
    ),
    make_route_candidate(
      "northeast-stepout",
      "Northeast 9x9 step-out candidate",
      "Promote the best measured window from the active 9x9 corridor scan into a named route fixture.",
      @terrain.first_trusted_square_northeast_stepout_grid(),
      profile,
      illumination_constraint,
      solar_track,
      "best active 9x9 corridor window is measured and selected but still blocked",
      "review the promoted route fixture before simulation",
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
