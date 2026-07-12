///|
pub(all) struct MissionPayload {
  mass_kg : Double
  delivery_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotArtifactBinding {
  robot_id : String
  robot_revision : String
  artifact_root : String
  robot_json_path : String
  robot_urdf_path : String
  validation_receipt_path : String
  bridge_config_path : String
  robot_json_sha256 : String
  robot_urdf_sha256 : String
  validation_receipt_sha256 : String
  validation_status : String
  physical_transport_enabled : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionScenario {
  scenario_id : String
  seed : Int
  scenario_kind : String
  injected_faults : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct FaultCalibration {
  fault_id : String
  severity : Int
  observable : Bool
  recoverable : Bool
  retained_performance : Double
  energy_multiplier : Double
  recovery_action : String
  calibration_reference : String
  uncertainty_fraction : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DigitalTwinCalibration {
  contract_id : String
  testbed_reference : String
  authoritative_source : String
  qualified : Bool
  fault_models : Array[FaultCalibration]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionIdentity {
  authority : String
  payload : MissionPayload
  route_id : String
  source_route_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct IlluminationEvidence {
  terrain_available_energy_wh : Double
  longest_dark_hours : Double
  decision : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DustAndThermal {
  thermal_survival_power_w : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionEnvironment {
  terrain_source_path : String
  cell_size_m : Double
  path_cells : Array[Array[Int]]
  whole_grid_max_neighbor_grade_deg : Double
  whole_grid_status : String
  illumination : IlluminationEvidence
  dust_and_thermal : DustAndThermal
  calibration : DigitalTwinCalibration
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Subsystem {
  id : String
  kind : String
  battery_capacity_wh : Double?
  reserve_wh : Double?
  drive_power_w : Double?
  comms_power_w : Double?
  minimum_energy_margin_wh : Double?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NumericBound {
  min : Double
  max : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionConstraints {
  payload_mass_kg : NumericBound
  route_length_m : NumericBound
  max_path_slope_deg : NumericBound
  waypoint_spacing_m : NumericBound
  commanded_speed_mps : NumericBound
  replay_count : NumericBound
  delivery_count : NumericBound
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PathCriteria {
  distance_m : Double
  waypoint_spacing_m : Double
  waypoint_count : Int
  commanded_speed_mps : Double
  drive_duration_s : Double
  maximum_measured_segment_slope_deg : Double
  blocked_cell_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct EnergyCriteria {
  drive_energy_wh : Double
  comms_energy_wh : Double
  thermal_survival_energy_wh : Double
  reserve_wh : Double
  bounded_required_energy_wh : Double
  verified_available_energy_wh : Double
  expected_margin_wh : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DeliveryCriteria {
  expected_payload_mass_kg : Double
  expected_delivery_count : Int
  final_state : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SafetyCriteria {
  fail_closed : Bool
  unverified_route_bypass_allowed : Bool
  physical_deployment_claim_allowed : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ReplayCriteria {
  required_runs : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct VerificationCriteria {
  path : PathCriteria
  energy : EnergyCriteria
  delivery : DeliveryCriteria
  safety : SafetyCriteria
  replay : ReplayCriteria
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotMissionDesign {
  contract_id : String
  design_id : String
  revision : String
  robot_artifact : RobotArtifactBinding
  scenario : MissionScenario
  mission : MissionIdentity
  environment : MissionEnvironment
  subsystems : Array[Subsystem]
  constraints : MissionConstraints
  verification_criteria : VerificationCriteria
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SegmentEvidence {
  from_row : Int
  from_col : Int
  to_row : Int
  to_col : Int
  elevation_delta_m : Double
  distance_m : Double
  slope_deg : Double
  accepted : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct EnergyResult {
  drive_wh : Double
  comms_wh : Double
  thermal_survival_wh : Double
  reserve_wh : Double
  required_wh : Double
  available_wh : Double
  margin_wh : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct FaultResponseEvidence {
  fault_id : String
  severity : Int
  states : Array[String]
  outcome : String
  retained_performance : Double
  energy_multiplier : Double
  recovery_action : String
  calibration_reference : String
  uncertainty_fraction : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotMissionResult {
  contract_id : String
  design_id : String
  revision : String
  robot_id : String
  robot_revision : String
  artifact_binding_verified : Bool
  scenario_id : String
  seed : Int
  scenario_kind : String
  injected_faults : Array[String]
  fault_responses : Array[FaultResponseEvidence]
  scenario_outcome : String
  evidence_claim : String
  physical_readiness : Bool
  route_id : String
  authority : String
  result : String
  terrain_source_path : String
  terrain_source_verified : Bool
  whole_grid_status : String
  whole_grid_max_neighbor_grade_deg : Double
  whole_grid_blocker_preserved : Bool
  segment_evidence : Array[SegmentEvidence]
  maximum_measured_segment_slope_deg : Double
  distance_m : Double
  waypoint_spacing_m : Double
  waypoint_count : Int
  duration_s : Double
  energy : EnergyResult
  delivery_count : Int
  final_state : String
  replay_count : Int
  deterministic_replay_required : Bool
  blockers : Array[String]
  limitations : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn close(a : Double, b : Double, tolerance? : Double = 0.000001) -> Bool {
  let delta = if a < b { b - a } else { a - b }
  delta <= tolerance
}

///|
fn add_blocker(
  blockers : Array[String],
  condition : Bool,
  message : String,
) -> Unit {
  if condition {
    blockers.push(message)
  }
}

///|
fn parse_dem(csv : String) -> Result[Map[String, Double], String] {
  let elevations : Map[String, Double] = {}
  let lines = csv.split("\n").map(line => line.to_owned()).collect()
  for index in 1..<lines.length() {
    let line = lines[index].trim()
    if line != "" {
      let fields = line.split(",").map(field => field.to_owned()).collect()
      if fields.length() != 4 {
        return Err("terrain CSV row \{index + 1} must have four fields")
      }
      let row = @string.parse_int(fields[1].trim()) catch {
        _ => return Err("terrain CSV row \{index + 1} has an invalid row index")
      }
      let col = @string.parse_int(fields[2].trim()) catch {
        _ =>
          return Err("terrain CSV row \{index + 1} has an invalid column index")
      }
      let elevation = @string.parse_double(fields[3].trim()) catch {
        _ => return Err("terrain CSV row \{index + 1} has an invalid elevation")
      }
      elevations["\{row},\{col}"] = elevation
    }
  }
  if elevations.is_empty() {
    Err("terrain CSV contains no elevation samples")
  } else {
    Ok(elevations)
  }
}

///|
fn power_subsystem(subsystems : Array[Subsystem]) -> Subsystem? {
  for subsystem in subsystems {
    if subsystem.id == "power" {
      return Some(subsystem)
    }
  }
  None
}

///|
fn required_double(
  value : Double?,
  label : String,
  blockers : Array[String],
) -> Double {
  match value {
    Some(number) => number
    None => {
      blockers.push("power subsystem is missing \{label}")
      0.0
    }
  }
}

///|
fn lowercase_sha256(value : String) -> Bool {
  if value.length() != 64 {
    return false
  }
  for char in value {
    if !(char >= '0' && char <= '9') && !(char >= 'a' && char <= 'f') {
      return false
    }
  }
  true
}

///|
fn artifact_binding_valid(design : RobotMissionDesign) -> Bool {
  let binding = design.robot_artifact
  binding.robot_id == design.design_id &&
  binding.robot_revision == design.revision &&
  binding.validation_status == "accepted" &&
  !binding.physical_transport_enabled &&
  !binding.artifact_root.trim().is_empty() &&
  !binding.robot_json_path.trim().is_empty() &&
  !binding.robot_urdf_path.trim().is_empty() &&
  !binding.validation_receipt_path.trim().is_empty() &&
  !binding.bridge_config_path.trim().is_empty() &&
  lowercase_sha256(binding.robot_json_sha256) &&
  lowercase_sha256(binding.robot_urdf_sha256) &&
  lowercase_sha256(binding.validation_receipt_sha256)
}

///|
fn calibrated_fault(
  calibration : DigitalTwinCalibration,
  fault_id : String,
) -> FaultCalibration? {
  for model in calibration.fault_models {
    if model.fault_id == fault_id {
      return Some(model)
    }
  }
  None
}

///|
fn evaluate_faults(
  design : RobotMissionDesign,
  blockers : Array[String],
) -> (Array[FaultResponseEvidence], String, Double) {
  let calibration = design.environment.calibration
  let responses : Array[FaultResponseEvidence] = []
  let mut aggregate = "nominal"
  let mut energy_multiplier = 1.0
  for fault_id in design.scenario.injected_faults {
    match calibrated_fault(calibration, fault_id) {
      None => {
        blockers.push(
          "fault \{fault_id} has no qualified calibration and cannot be simulated safely",
        )
        responses.push({
          fault_id,
          severity: 10,
          states: ["normal", "degraded", "fail-closed"],
          outcome: "fail-closed",
          retained_performance: 0.0,
          energy_multiplier: 1.0,
          recovery_action: "none",
          calibration_reference: "",
          uncertainty_fraction: 1.0,
        })
        aggregate = "fail-closed"
      }
      Some(model) => {
        let valid = model.severity >= 1 &&
          model.severity <= 10 &&
          model.retained_performance >= 0.0 &&
          model.retained_performance <= 1.0 &&
          model.energy_multiplier >= 1.0 &&
          model.uncertainty_fraction >= 0.0 &&
          model.uncertainty_fraction <= 0.25 &&
          !model.calibration_reference.trim().is_empty()
        if !valid {
          blockers.push("fault \{fault_id} has an invalid calibration model")
        }
        let states : Array[String] = ["normal", "degraded"]
        let outcome = if !valid || !model.observable {
          states.push("safe-return")
          "safe-return"
        } else if model.recoverable && model.retained_performance >= 0.75 {
          states.push("diagnosis")
          states.push("recovery-attempt")
          states.push("recovered")
          "recovered"
        } else if model.recoverable && model.retained_performance >= 0.4 {
          states.push("diagnosis")
          states.push("recovery-attempt")
          states.push("reduced-mission")
          "reduced-mission"
        } else {
          states.push("safe-return")
          "safe-return"
        }
        if outcome == "safe-return" && aggregate != "fail-closed" {
          aggregate = "safe-return"
        } else if outcome == "reduced-mission" &&
          aggregate != "safe-return" &&
          aggregate != "fail-closed" {
          aggregate = "reduced-mission"
        } else if outcome == "recovered" && aggregate == "nominal" {
          aggregate = "recovered"
        }
        if model.energy_multiplier > energy_multiplier {
          energy_multiplier = model.energy_multiplier
        }
        responses.push({
          fault_id,
          severity: model.severity,
          states,
          outcome,
          retained_performance: model.retained_performance,
          energy_multiplier: model.energy_multiplier,
          recovery_action: model.recovery_action,
          calibration_reference: model.calibration_reference,
          uncertainty_fraction: model.uncertainty_fraction,
        })
      }
    }
  }
  (responses, aggregate, energy_multiplier)
}

///|
pub fn simulate(
  design : RobotMissionDesign,
  terrain_csv : String,
) -> RobotMissionResult {
  let blockers : Array[String] = []
  add_blocker(
    blockers,
    design.contract_id != "moonsuite.robot-design.v1",
    "unsupported design contract",
  )
  let binding_valid = artifact_binding_valid(design)
  add_blocker(
    blockers,
    !binding_valid,
    "MoonRobo artifact binding is incomplete, mismatched, unsafe, or unvalidated",
  )
  add_blocker(
    blockers,
    design.scenario.scenario_id.trim().is_empty() || design.scenario.seed <= 0,
    "scenario id and positive deterministic seed are required",
  )
  let calibration = design.environment.calibration
  add_blocker(
    blockers,
    calibration.contract_id != "moonmoon.digital-twin-calibration.v1" ||
    calibration.testbed_reference.trim().is_empty() ||
    calibration.authoritative_source.trim().is_empty(),
    "qualified calibration with testbed and authoritative references is required",
  )
  let (fault_responses, scenario_outcome, fault_energy_multiplier) = evaluate_faults(
    design, blockers,
  )
  add_blocker(
    blockers,
    design.mission.authority != "digital-only",
    "mission authority must be digital-only",
  )
  add_blocker(
    blockers,
    design.environment.whole_grid_status != "blocked" &&
    design.environment.whole_grid_status != "verified",
    "whole-grid status must be explicitly blocked or verified",
  )
  add_blocker(
    blockers,
    !design.verification_criteria.safety.fail_closed,
    "safety policy must fail closed",
  )
  add_blocker(
    blockers,
    design.verification_criteria.safety.unverified_route_bypass_allowed,
    "unverified route bypass is forbidden",
  )
  add_blocker(
    blockers,
    design.verification_criteria.safety.physical_deployment_claim_allowed,
    "physical deployment claims are forbidden",
  )
  let required_replays = design.verification_criteria.replay.required_runs
  add_blocker(
    blockers,
    required_replays < 1 ||
    required_replays.to_double() < design.constraints.replay_count.min ||
    required_replays.to_double() > design.constraints.replay_count.max,
    "deterministic replay count is outside design constraints",
  )
  let elevations = match parse_dem(terrain_csv) {
    Ok(value) => value
    Err(error) => {
      blockers.push(error)
      {}
    }
  }
  let segments : Array[SegmentEvidence] = []
  let mut distance_m = 0.0
  let mut max_slope_deg = 0.0
  if design.environment.path_cells.length() < 2 {
    blockers.push("path must contain at least two cells")
  } else {
    for index in 0..<(design.environment.path_cells.length() - 1) {
      let from = design.environment.path_cells[index]
      let to = design.environment.path_cells[index + 1]
      if from.length() != 2 || to.length() != 2 {
        blockers.push("each path cell must contain row and column")
        continue
      }
      let row_delta = if from[0] < to[0] {
        to[0] - from[0]
      } else {
        from[0] - to[0]
      }
      let col_delta = if from[1] < to[1] {
        to[1] - from[1]
      } else {
        from[1] - to[1]
      }
      if row_delta + col_delta != 1 {
        blockers.push("path segment \{index} is not orthogonally adjacent")
        continue
      }
      let from_key = "\{from[0]},\{from[1]}"
      let to_key = "\{to[0]},\{to[1]}"
      let from_elevation = match elevations.get(from_key) {
        Some(value) => value
        None => {
          blockers.push("path cell \{from_key} is absent from terrain source")
          continue
        }
      }
      let to_elevation = match elevations.get(to_key) {
        Some(value) => value
        None => {
          blockers.push("path cell \{to_key} is absent from terrain source")
          continue
        }
      }
      let elevation_delta_m = if from_elevation < to_elevation {
        to_elevation - from_elevation
      } else {
        from_elevation - to_elevation
      }
      let slope_deg = @math.atan2(
          elevation_delta_m,
          design.environment.cell_size_m,
        ) *
        180.0 /
        3.141592653589793
      let accepted = slope_deg <= design.constraints.max_path_slope_deg.max
      if !accepted {
        blockers.push(
          "path segment \{index} slope \{slope_deg} exceeds \{design.constraints.max_path_slope_deg.max} degrees",
        )
      }
      if slope_deg > max_slope_deg {
        max_slope_deg = slope_deg
      }
      distance_m += design.environment.cell_size_m
      segments.push({
        from_row: from[0],
        from_col: from[1],
        to_row: to[0],
        to_col: to[1],
        elevation_delta_m,
        distance_m: design.environment.cell_size_m,
        slope_deg,
        accepted,
      })
    }
  }
  let path = design.verification_criteria.path
  add_blocker(
    blockers,
    !close(distance_m, path.distance_m),
    "measured route distance does not match verification criteria",
  )
  add_blocker(
    blockers,
    distance_m < design.constraints.route_length_m.min ||
    distance_m > design.constraints.route_length_m.max,
    "measured route distance is outside design constraints",
  )
  add_blocker(
    blockers,
    path.waypoint_spacing_m < design.constraints.waypoint_spacing_m.min ||
    path.waypoint_spacing_m > design.constraints.waypoint_spacing_m.max,
    "waypoint spacing is outside design constraints",
  )
  let expected_waypoints = (distance_m / path.waypoint_spacing_m)
    .ceil()
    .to_int() +
    1
  add_blocker(
    blockers,
    path.waypoint_count != expected_waypoints,
    "waypoint count must include both route endpoints",
  )
  add_blocker(
    blockers,
    path.commanded_speed_mps < design.constraints.commanded_speed_mps.min ||
    path.commanded_speed_mps > design.constraints.commanded_speed_mps.max,
    "commanded speed is outside design constraints",
  )
  let duration_s = if path.commanded_speed_mps > 0.0 {
    distance_m / path.commanded_speed_mps
  } else {
    0.0
  }
  add_blocker(
    blockers,
    !close(duration_s, path.drive_duration_s),
    "computed drive duration does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(
      max_slope_deg,
      path.maximum_measured_segment_slope_deg,
      tolerance=0.00001,
    ),
    "source-derived maximum slope does not match verification criteria",
  )
  add_blocker(
    blockers,
    path.blocked_cell_count != 0,
    "selected path reports blocked cells",
  )
  add_blocker(
    blockers,
    design.mission.payload.mass_kg < design.constraints.payload_mass_kg.min ||
    design.mission.payload.mass_kg > design.constraints.payload_mass_kg.max,
    "payload mass is outside design constraints",
  )
  add_blocker(
    blockers,
    design.mission.payload.delivery_count.to_double() <
    design.constraints.delivery_count.min ||
    design.mission.payload.delivery_count.to_double() >
    design.constraints.delivery_count.max,
    "delivery count is outside design constraints",
  )
  let power = match power_subsystem(design.subsystems) {
    Some(value) => value
    None => {
      blockers.push("design is missing a power subsystem")
      {
        id: "power",
        kind: "missing",
        battery_capacity_wh: None,
        reserve_wh: None,
        drive_power_w: None,
        comms_power_w: None,
        minimum_energy_margin_wh: None,
      }
    }
  }
  let drive_power_w = required_double(
    power.drive_power_w,
    "drive_power_w",
    blockers,
  )
  let comms_power_w = required_double(
    power.comms_power_w,
    "comms_power_w",
    blockers,
  )
  let reserve_wh = required_double(power.reserve_wh, "reserve_wh", blockers)
  let minimum_margin_wh = required_double(
    power.minimum_energy_margin_wh,
    "minimum_energy_margin_wh",
    blockers,
  )
  let drive_wh = drive_power_w * duration_s / 3600.0 * fault_energy_multiplier
  let comms_wh = comms_power_w * duration_s / 3600.0
  let thermal_wh = design.environment.dust_and_thermal.thermal_survival_power_w *
    design.environment.illumination.longest_dark_hours
  let required_wh = drive_wh + comms_wh + thermal_wh + reserve_wh
  let available_wh = design.environment.illumination.terrain_available_energy_wh
  let margin_wh = available_wh - required_wh
  let battery_capacity_wh = required_double(
    power.battery_capacity_wh,
    "battery_capacity_wh",
    blockers,
  )
  add_blocker(
    blockers,
    design.environment.illumination.decision != "Allow",
    "illumination evidence does not allow traverse",
  )
  add_blocker(
    blockers,
    margin_wh < minimum_margin_wh,
    "energy margin is below the required minimum",
  )
  let expected_energy = design.verification_criteria.energy
  add_blocker(
    blockers,
    !close(drive_wh, expected_energy.drive_energy_wh, tolerance=0.00001),
    "computed drive energy does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(comms_wh, expected_energy.comms_energy_wh, tolerance=0.00001),
    "computed communications energy does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(
      thermal_wh,
      expected_energy.thermal_survival_energy_wh,
      tolerance=0.00001,
    ),
    "computed thermal survival energy does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(reserve_wh, expected_energy.reserve_wh, tolerance=0.00001),
    "configured reserve does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(
      required_wh,
      expected_energy.bounded_required_energy_wh,
      tolerance=0.00001,
    ),
    "computed required energy does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(margin_wh, expected_energy.expected_margin_wh, tolerance=0.00001),
    "computed energy margin does not match verification criteria",
  )
  add_blocker(
    blockers,
    !close(
      available_wh,
      expected_energy.verified_available_energy_wh,
      tolerance=0.00001,
    ),
    "available terrain energy does not match verification criteria",
  )
  add_blocker(
    blockers,
    required_wh - reserve_wh > battery_capacity_wh,
    "active mission energy exceeds modeled battery capacity",
  )
  let delivery = design.verification_criteria.delivery
  add_blocker(
    blockers,
    !close(design.mission.payload.mass_kg, delivery.expected_payload_mass_kg),
    "payload mass does not match delivery criteria",
  )
  add_blocker(
    blockers,
    design.mission.payload.delivery_count != delivery.expected_delivery_count,
    "delivery count does not match delivery criteria",
  )
  let mission_continues = scenario_outcome != "safe-return" &&
    scenario_outcome != "fail-closed"
  let accepted = blockers.is_empty() && mission_continues
  {
    contract_id: "moonmoon.robot-mission-result.v1",
    design_id: design.design_id,
    revision: design.revision,
    robot_id: design.robot_artifact.robot_id,
    robot_revision: design.robot_artifact.robot_revision,
    artifact_binding_verified: binding_valid,
    scenario_id: design.scenario.scenario_id,
    seed: design.scenario.seed,
    scenario_kind: design.scenario.scenario_kind,
    injected_faults: design.scenario.injected_faults.copy(),
    fault_responses,
    scenario_outcome,
    evidence_claim: if accepted && calibration.qualified {
      "calibrated-digital-twin"
    } else if accepted {
      "scenario-qualified"
    } else {
      "bounded-digital-simulation"
    },
    physical_readiness: false,
    route_id: design.mission.route_id,
    authority: design.mission.authority,
    result: if accepted {
      "accepted"
    } else {
      "rejected"
    },
    terrain_source_path: design.environment.terrain_source_path,
    terrain_source_verified: !elevations.is_empty(),
    whole_grid_status: design.environment.whole_grid_status,
    whole_grid_max_neighbor_grade_deg: design.environment.whole_grid_max_neighbor_grade_deg,
    whole_grid_blocker_preserved: design.environment.whole_grid_status ==
    "blocked" ||
    design.environment.whole_grid_status == "verified",
    segment_evidence: segments,
    maximum_measured_segment_slope_deg: max_slope_deg,
    distance_m,
    waypoint_spacing_m: path.waypoint_spacing_m,
    waypoint_count: path.waypoint_count,
    duration_s,
    energy: {
      drive_wh,
      comms_wh,
      thermal_survival_wh: thermal_wh,
      reserve_wh,
      required_wh,
      available_wh,
      margin_wh,
    },
    delivery_count: if accepted {
      design.mission.payload.delivery_count
    } else {
      0
    },
    final_state: if accepted {
      if scenario_outcome == "reduced-mission" {
        "completed-reduced-mission"
      } else {
        delivery.final_state
      }
    } else if scenario_outcome == "safe-return" {
      "safe-return"
    } else {
      "stopped-with-blocker"
    },
    replay_count: required_replays,
    deterministic_replay_required: true,
    blockers,
    limitations: [
      if design.environment.whole_grid_status == "blocked" {
        "The broader terrain source remains blocked; acceptance applies only to the enumerated and measured path cells."
      } else {
        "The broader terrain source is verified only to the declared source quality; path acceptance remains bounded to enumerated cells."
      },
      "This deterministic digital simulation does not establish obstacle, slip, sinkage, localization, dust, thermal-vacuum, manufacturing, launch, landing, or physical lunar readiness.",
    ],
  }
}

///|
fn safe_relative_artifact_path(path : String) -> Bool {
  let normalized = path.trim().replace(old="\\", new="/")
  !normalized.is_empty() &&
  !normalized.has_prefix("/") &&
  !normalized.split("/").any(segment => segment == "..")
}

///|
fn staged_binding_issue(
  design : RobotMissionDesign,
  moonmoon_root : String,
) -> String? {
  let binding = design.robot_artifact
  for
    path in [
      binding.artifact_root,
      binding.robot_json_path,
      binding.robot_urdf_path,
      binding.validation_receipt_path,
      binding.bridge_config_path,
    ] {
    if !safe_relative_artifact_path(path) {
      return Some("robot artifact binding contains an unsafe relative path")
    }
  }
  let base = moonmoon_root + "/" + binding.artifact_root
  let robot_json = @fsx.read_file_to_string(
    base + "/" + binding.robot_json_path,
  ) catch {
    _ => return Some("failed to read staged MoonRobo robot.json")
  }
  if !robot_json.contains("\"id\": \"\{binding.robot_id}\"") {
    return Some("staged robot.json does not match the bound robot id")
  }
  let urdf = @fsx.read_file_to_string(base + "/" + binding.robot_urdf_path) catch {
    _ => return Some("failed to read staged MoonRobo URDF")
  }
  if !urdf.contains("<robot name=\"\{binding.robot_id}\">") {
    return Some("staged URDF does not match the bound robot id")
  }
  let receipt = @fsx.read_file_to_string(
    base + "/" + binding.validation_receipt_path,
  ) catch {
    _ => return Some("failed to read staged MoonRobo validation receipt")
  }
  if !receipt.contains("\"status\": \"accepted\"") ||
    !receipt.contains("\"physical_transport_enabled\": false") ||
    !receipt.contains("\"book_id\": \"\{binding.robot_id}\"") {
    return Some("staged MoonRobo receipt is not accepted and simulation-only")
  }
  let bridge = @fsx.read_file_to_string(base + "/" + binding.bridge_config_path) catch {
    _ => return Some("failed to read staged MoonRobo bridge config")
  }
  if !bridge.contains("\"mode\": \"simulation-only\"") ||
    !bridge.contains("\"physical_transport_enabled\": false") ||
    !bridge.contains("\"design_id\": \"\{binding.robot_id}\"") {
    return Some("staged MoonRobo bridge is not simulation-only")
  }
  None
}

///|
pub fn simulate_files(
  design_path : String,
  moonmoon_root : String,
  output_path : String,
) -> Result[RobotMissionResult, String] {
  let design_text = @fsx.read_file_to_string(design_path) catch {
    _ => return Err("failed to read robot design: \{design_path}")
  }
  let design : RobotMissionDesign = @json.from_json(@json.parse(design_text)) catch {
    _ => return Err("failed to parse typed robot design: \{design_path}")
  }
  let terrain_path = moonmoon_root +
    "/" +
    design.environment.terrain_source_path
  let terrain_csv = @fsx.read_file_to_string(terrain_path) catch {
    _ => return Err("failed to read terrain source: \{terrain_path}")
  }
  let simulated = simulate(design, terrain_csv)
  let result = match staged_binding_issue(design, moonmoon_root) {
    None => simulated
    Some(error) => {
      let blockers = simulated.blockers.copy()
      blockers.push(error)
      {
        ..simulated,
        result: "rejected",
        artifact_binding_verified: false,
        delivery_count: 0,
        final_state: "stopped-with-blocker",
        blockers,
      }
    }
  }
  @fsx.write_string_to_file(
    output_path,
    result.to_json().stringify(indent=2) + "\n",
  ) catch {
    _ => return Err("failed to write simulation result: \{output_path}")
  }
  Ok(result)
}
