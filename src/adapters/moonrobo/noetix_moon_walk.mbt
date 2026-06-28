///|
pub(all) struct NoetixMoonWalkRobotProfile {
  robot_id : String
  label : String
  source_suite : String
  source_model_path : String
  source_profile_path : String
  joint_count : Int
  model_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixMoonWalkConfig {
  config_id : String
  gravity_mps2 : Double
  dt_s : Double
  speed_mps : Double
  heading_rad : Double
  start_position : @moonphys.Vec3
  step_length_m : Double
  step_height_m : Double
  stride_frequency_hz : Double
  cycle_frames : Int
  lateral_foot_offset_m : Double
  support_lateral_shift_m : Double
  support_forward_lead_m : Double
  double_support_frames : Int
  min_swing_clearance_m : Double
  foot_radius_m : Double
  caution_grade : Double
  body_height_m : Double
  terrain_source_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixFootContactProbe {
  foot_id : String
  position : @moonphys.Vec3
  terrain_elevation_m : Double
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixJointPhase {
  joint_name : String
  role : String
  side : String
  position_rad : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixMoonWalkFrame {
  frame_index : Int
  time_s : Double
  body_position : @moonphys.Vec3
  support_phase : String
  left_foot : NoetixFootContactProbe
  right_foot : NoetixFootContactProbe
  joint_phases : Array[NoetixJointPhase]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixMoonWalkTrace {
  trace_id : String
  robot : NoetixMoonWalkRobotProfile
  config : NoetixMoonWalkConfig
  terrain_tile_id : String
  terrain_cell_size_m : Double
  frame_count : Int
  endless_axis : String
  frames : Array[NoetixMoonWalkFrame]
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixEndlessGaitSample {
  frame_index : Int
  cycle_index : Int
  phase_index : Int
  support_phase : String
  body_forward_offset_m : Double
  expected_forward_offset_m : Double
  left_contact : Bool
  right_contact : Bool
  phase_matches_reference : Bool
  contact_matches_reference : Bool
  forward_offset_matches_expected : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixEndlessGaitEvidence {
  evidence_id : String
  trace_id : String
  robot_id : String
  terrain_tile_id : String
  reference_frame_index : Int
  repeated_frame_index : Int
  cycle_frames : Int
  dt_s : Double
  speed_mps : Double
  expected_forward_offset_m : Double
  observed_forward_offset_m : Double
  reference_support_phase : String
  repeated_support_phase : String
  phase_repeat_verified : Bool
  contact_repeat_verified : Bool
  monotonic_forward_verified : Bool
  cycle_forward_offset_m : Double
  sample_count : Int
  sample_cycle_count : Int
  samples : Array[NoetixEndlessGaitSample]
  multi_cycle_verified : Bool
  hardware_authority : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn noetix_moon_walk_robot_profile() -> NoetixMoonWalkRobotProfile {
  {
    robot_id: "noetix-e1-lab-01",
    label: "Noetix E1 Lab 01",
    source_suite: "moonrobo",
    source_model_path: "../moonrobo/examples/noetix-e1/model/robot.urdf",
    source_profile_path: "../moonrobo/examples/noetix-e1/robot.json",
    joint_count: 24,
    model_status: "kinematic-urdf-reference; dynamics metadata pending",
  }
}

///|
fn noetix_urdf_base_to_foot_height_m() -> Double {
  0.82
}

///|
pub fn default_noetix_moon_walk_config() -> NoetixMoonWalkConfig {
  {
    config_id: "moonrobo/noetix-e1/endless-forward-moon-walk-v1",
    gravity_mps2: @moonphys.lunar_environment().gravity_mps2,
    dt_s: 0.1,
    speed_mps: 0.12,
    heading_rad: 0.0,
    start_position: @moonphys.vec3(0.0, 0.0, 0.0),
    step_length_m: 0.16,
    step_height_m: 0.045,
    stride_frequency_hz: 0.75,
    cycle_frames: 32,
    lateral_foot_offset_m: 0.08,
    support_lateral_shift_m: 0.04,
    support_forward_lead_m: 0.2,
    double_support_frames: 10,
    min_swing_clearance_m: 0.02,
    foot_radius_m: 0.012,
    caution_grade: 0.18,
    body_height_m: noetix_urdf_base_to_foot_height_m(),
    terrain_source_id: "first-trusted-square-northeast-stepout-lola",
  }
}

///|
fn wrapped_index(index : Int, length : Int) -> Int {
  if length <= 0 {
    0
  } else {
    let wrapped = index - index / length * length
    if wrapped < 0 {
      wrapped + length
    } else {
      wrapped
    }
  }
}

///|
fn phase_index(frame_index : Int, cycle_frames : Int) -> Int {
  wrapped_index(frame_index, cycle_frames)
}

///|
fn phase_progress(phase : Int, half_cycle : Int) -> Double {
  if half_cycle <= 1 {
    0.0
  } else {
    phase.to_double() / (half_cycle - 1).to_double()
  }
}

///|
fn half_cycle_block(frame_index : Int, half_cycle : Int) -> Int {
  if half_cycle <= 0 {
    0
  } else {
    frame_index / half_cycle
  }
}

///|
fn half_cycle_forward_span_m(
  config : NoetixMoonWalkConfig,
  half_cycle : Int,
) -> Double {
  half_cycle.to_double() * config.dt_s * config.speed_mps
}

///|
fn planted_foot_forward_m(
  config : NoetixMoonWalkConfig,
  half_cycle : Int,
  block : Int,
) -> Double {
  let span = half_cycle_forward_span_m(config, half_cycle)
  block.to_double() * span - span * 0.25 + config.support_forward_lead_m
}

///|
fn swing_foot_forward_m(
  config : NoetixMoonWalkConfig,
  half_cycle : Int,
  block : Int,
  progress : Double,
) -> Double {
  let start = planted_foot_forward_m(config, half_cycle, block - 1)
  let finish = planted_foot_forward_m(config, half_cycle, block + 1)
  start + (finish - start) * progress
}

///|
fn double_support_frame_count(
  config : NoetixMoonWalkConfig,
  half_cycle : Int,
) -> Int {
  if config.double_support_frames < 0 {
    0
  } else if config.double_support_frames > half_cycle {
    half_cycle
  } else {
    config.double_support_frames
  }
}

///|
fn support_transfer_progress(
  local_phase : Int,
  transfer_frames : Int,
) -> Double {
  if transfer_frames <= 1 {
    1.0
  } else if local_phase <= 0 {
    0.0
  } else if local_phase >= transfer_frames - 1 {
    1.0
  } else {
    let t = local_phase.to_double() / (transfer_frames - 1).to_double()
    t * t * (3.0 - 2.0 * t)
  }
}

///|
fn smoothstep_double(progress : Double) -> Double {
  let t = clamp_double(progress, 0.0, 1.0)
  t * t * (3.0 - 2.0 * t)
}

///|
fn swing_progress_after_transfer(
  local_phase : Int,
  half_cycle : Int,
  transfer_frames : Int,
) -> Double {
  let swing_frames = half_cycle - transfer_frames
  if swing_frames <= 1 {
    phase_progress(local_phase, half_cycle)
  } else if local_phase < transfer_frames {
    0.0
  } else {
    let swing_phase = local_phase - transfer_frames
    if swing_phase >= swing_frames - 1 {
      1.0
    } else {
      swing_phase.to_double() / (swing_frames - 1).to_double()
    }
  }
}

///|
fn swing_lift(config : NoetixMoonWalkConfig, progress : Double) -> Double {
  config.step_height_m * @math.sin(progress * 3.141592653589793)
}

///|
fn gait_lift_blend(progress : Double) -> Double {
  clamp_double(
    @math.sin(clamp_double(progress, 0.0, 1.0) * 3.141592653589793),
    0.0,
    1.0,
  )
}

///|
fn gait_toe_pitch(progress : Double, lift_blend : Double) -> Double {
  let p = clamp_double(progress, 0.0, 1.0)
  let toe_clear = if p < 0.5 {
    0.16 * (1.0 - p * 2.0)
  } else {
    -0.10 * ((p - 0.5) * 2.0)
  }
  toe_clear * lift_blend
}

///|
fn cycle_progress(phase : Int, cycle_frames : Int) -> Double {
  if cycle_frames <= 1 {
    0.0
  } else {
    phase.to_double() / cycle_frames.to_double()
  }
}

///|
fn noetix_heading_forward(config : NoetixMoonWalkConfig) -> @moonphys.Vec3 {
  @moonphys.vec3(
    @math.cos(config.heading_rad),
    @math.sin(config.heading_rad),
    0.0,
  )
}

///|
fn noetix_heading_lateral(config : NoetixMoonWalkConfig) -> @moonphys.Vec3 {
  @moonphys.vec3(
    0.0 - @math.sin(config.heading_rad),
    @math.cos(config.heading_rad),
    0.0,
  )
}

///|
fn noetix_walk_xy(
  config : NoetixMoonWalkConfig,
  forward_m : Double,
  lateral_m : Double,
) -> @moonphys.Vec3 {
  config.start_position
  .add(noetix_heading_forward(config).scale(forward_m))
  .add(noetix_heading_lateral(config).scale(lateral_m))
}

///|
fn noetix_endless_axis(config : NoetixMoonWalkConfig) -> String {
  if abs_double(config.heading_rad) < 0.000000001 {
    "+x"
  } else {
    "heading-rad:\{config.heading_rad}"
  }
}

///|
fn noetix_support_body_lateral_m(
  config : NoetixMoonWalkConfig,
  left_support : Bool,
  local_phase : Int,
  transfer_frames : Int,
) -> Double {
  let target = if left_support {
    config.support_lateral_shift_m
  } else {
    0.0 - config.support_lateral_shift_m
  }
  let previous = 0.0 - target
  let progress = support_transfer_progress(local_phase, transfer_frames)
  previous + (target - previous) * progress
}

///|
fn noetix_body_bob_m(
  config : NoetixMoonWalkConfig,
  local_phase : Int,
  half_cycle : Int,
) -> Double {
  let progress = phase_progress(local_phase, half_cycle)
  config.step_height_m * 0.35 * @math.sin(progress * 3.141592653589793)
}

///|
fn foot_status(
  in_contact : Bool,
  clearance_m : Double,
  local_grade : Double,
  config : NoetixMoonWalkConfig,
) -> String {
  if local_grade > config.caution_grade {
    "terrain-grade-review"
  } else if !in_contact && clearance_m < config.min_swing_clearance_m {
    "low-clearance-review"
  } else {
    "ok"
  }
}

///|
fn foot_probe(
  foot_id : String,
  x : Double,
  y : Double,
  lift_m : Double,
  in_contact : Bool,
  field : @moonphys.Heightfield,
  config : NoetixMoonWalkConfig,
) -> NoetixFootContactProbe {
  let terrain = @moonphys.sample_heightfield(field, x, y)
  let clearance = if in_contact {
    0.0
  } else if lift_m < config.min_swing_clearance_m + config.foot_radius_m {
    config.min_swing_clearance_m + config.foot_radius_m
  } else if lift_m < config.min_swing_clearance_m {
    config.min_swing_clearance_m
  } else {
    lift_m
  }
  let contact = @moonphys.heightfield_contact_probe(
    field,
    foot_id,
    @moonphys.vec3(x, y, terrain.elevation_m + clearance),
  )
  {
    foot_id,
    position: contact.position,
    terrain_elevation_m: contact.surface_elevation_m,
    clearance_m: contact.clearance_m,
    in_contact: contact.in_contact,
    local_grade: contact.local_grade,
    status: foot_status(
      in_contact,
      contact.clearance_m,
      contact.local_grade,
      config,
    ),
  }
}

///|
fn frame_status(
  left : NoetixFootContactProbe,
  right : NoetixFootContactProbe,
) -> String {
  if left.status == "ok" && right.status == "ok" {
    "walking"
  } else {
    "walking-needs-review"
  }
}

///|
fn joint_phase_with_status(
  joint_name : String,
  role : String,
  side : String,
  position_rad : Double,
  status : String,
) -> NoetixJointPhase {
  { joint_name, role, side, position_rad, status }
}

///|
fn clamp_double(
  value : Double,
  min_value : Double,
  max_value : Double,
) -> Double {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn source_joint_limit_for(joint_name : String) -> NoetixSourceJointLimit {
  for limit in noetix_source_joint_limits() {
    if limit.joint_name == joint_name {
      return limit
    }
  }
  {
    joint_name,
    joint_index: -1,
    lower_rad: -3.141592653589793,
    upper_rad: 3.141592653589793,
    effort_nm: 0.0,
    velocity_rad_s: 0.0,
    source_status: "missing-source-limit",
  }
}

///|
fn bounded_joint_phase(
  joint_name : String,
  role : String,
  side : String,
  position_rad : Double,
  status : String,
) -> NoetixJointPhase {
  let limit = source_joint_limit_for(joint_name)
  joint_phase_with_status(
    joint_name,
    role,
    side,
    clamp_double(position_rad, limit.lower_rad, limit.upper_rad),
    status,
  )
}

///|
fn noetix_leg_gait_clip_phases(
  foot : NoetixFootContactProbe,
  side : String,
  prefix : String,
  gait_progress : Double,
  swing_progress : Double,
) -> Array[NoetixJointPhase] {
  let side_sign = if side == "left" { 1.0 } else { 0.0 - 1.0 }
  let leg_cycle = if side == "left" {
    gait_progress
  } else if gait_progress >= 0.5 {
    gait_progress - 0.5
  } else {
    gait_progress + 0.5
  }
  let support_progress = smoothstep_double(leg_cycle * 2.0)
  let swing_blend = if foot.in_contact {
    0.0
  } else {
    gait_lift_blend(swing_progress)
  }
  let swing_drive = if foot.in_contact {
    0.0
  } else {
    smoothstep_double(swing_progress)
  }
  let support_hip_pitch = -0.20 + 0.34 * support_progress
  let swing_hip_pitch = 0.16 - 0.46 * swing_drive
  let hip_pitch = if foot.in_contact {
    support_hip_pitch
  } else {
    swing_hip_pitch
  }
  let support_knee = 0.10 +
    0.06 * @math.sin(support_progress * 3.141592653589793)
  let shaped_knee_flex = clamp_double(
    if foot.in_contact {
      support_knee
    } else {
      0.18 + swing_blend * 0.78 + swing_drive * 0.08
    },
    0.08,
    1.35,
  )
  let hip_roll = if foot.in_contact {
    side_sign * 0.04
  } else {
    0.0 - side_sign * 0.10 * swing_blend
  }
  let knee_upper = shaped_knee_flex * 0.58
  let knee_lower = shaped_knee_flex * 0.42
  let ankle_roll = 0.0 - hip_roll * 0.45
  let ankle_pitch = 0.0 -
    (hip_pitch + knee_upper + knee_lower) +
    gait_toe_pitch(swing_progress, swing_blend)
  [
    bounded_joint_phase(
      "\{prefix}1_joint",
      "hip-pitch",
      side,
      hip_pitch,
      "urdf-gait-clip",
    ),
    bounded_joint_phase(
      "\{prefix}2_joint",
      "hip-roll",
      side,
      hip_roll,
      "urdf-gait-clip",
    ),
    bounded_joint_phase(
      "\{prefix}3_joint",
      "knee-upper",
      side,
      knee_upper,
      "urdf-gait-clip",
    ),
    bounded_joint_phase(
      "\{prefix}4_joint",
      "knee-lower",
      side,
      knee_lower,
      "urdf-gait-clip",
    ),
    bounded_joint_phase(
      "\{prefix}5_joint",
      "ankle-roll",
      side,
      ankle_roll,
      "urdf-gait-clip",
    ),
    bounded_joint_phase(
      "\{prefix}6_joint",
      "ankle-pitch",
      side,
      ankle_pitch,
      "urdf-gait-clip",
    ),
  ]
}

///|
fn arm_phases(gait_progress : Double) -> Array[NoetixJointPhase] {
  let wave = @math.sin(gait_progress * 2.0 * 3.141592653589793)
  let left = 0.0 - wave
  let right = 0.0 - left
  [
    joint_phase_with_status(
      "arm_l1_joint",
      "shoulder-pitch",
      "left",
      0.22 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l2_joint",
      "shoulder-roll",
      "left",
      0.06 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l3_joint",
      "elbow-yaw",
      "left",
      0.04 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l4_joint",
      "elbow-pitch",
      "left",
      0.12 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l5_joint",
      "wrist-roll",
      "left",
      0.03 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r1_joint",
      "shoulder-pitch",
      "right",
      0.22 * right,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r2_joint",
      "shoulder-roll",
      "right",
      0.06 * right,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r3_joint",
      "elbow-yaw",
      "right",
      0.04 * right,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r4_joint",
      "elbow-pitch",
      "right",
      0.12 * right,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r5_joint",
      "wrist-roll",
      "right",
      0.03 * right,
      "planned-counter-swing",
    ),
  ]
}

///|
fn noetix_joint_phases(
  left_foot : NoetixFootContactProbe,
  right_foot : NoetixFootContactProbe,
  gait_progress : Double,
  left_swing_progress : Double,
  right_swing_progress : Double,
) -> Array[NoetixJointPhase] {
  let phases : Array[NoetixJointPhase] = []
  let cycle_angle = gait_progress * 2.0 * 3.141592653589793
  phases.push(
    joint_phase_with_status(
      "waist_1_joint",
      "waist-yaw",
      "center",
      0.055 * @math.sin(cycle_angle),
      "planned-body-sway",
    ),
  )
  phases.push(
    joint_phase_with_status(
      "waist_2_joint",
      "waist-pitch",
      "center",
      -0.035 + 0.025 * @math.cos(cycle_angle * 2.0),
      "planned-body-sway",
    ),
  )
  for
    phase in noetix_leg_gait_clip_phases(
      left_foot, "left", "leg_l", gait_progress, left_swing_progress,
    ) {
    phases.push(phase)
  }
  for
    phase in noetix_leg_gait_clip_phases(
      right_foot, "right", "leg_r", gait_progress, right_swing_progress,
    ) {
    phases.push(phase)
  }
  for phase in arm_phases(gait_progress) {
    phases.push(phase)
  }
  phases
}

///|
pub fn noetix_moon_walk_frame(
  field : @moonphys.Heightfield,
  config : NoetixMoonWalkConfig,
  frame_index : Int,
) -> NoetixMoonWalkFrame {
  let cycle_frames = if config.cycle_frames < 2 {
    2
  } else {
    config.cycle_frames
  }
  let half_cycle = cycle_frames / 2
  let phase = phase_index(frame_index, cycle_frames)
  let left_support = phase < half_cycle
  let local_phase = if left_support { phase } else { phase - half_cycle }
  let transfer_frames = double_support_frame_count(config, half_cycle)
  let gait_progress = cycle_progress(phase, cycle_frames)
  let progress = swing_progress_after_transfer(
    local_phase, half_cycle, transfer_frames,
  )
  let in_double_support = local_phase < transfer_frames
  let left_swing_progress = if left_support || in_double_support {
    0.0
  } else {
    progress
  }
  let right_swing_progress = if !left_support || in_double_support {
    0.0
  } else {
    progress
  }
  let block = half_cycle_block(frame_index, half_cycle)
  let body_forward = frame_index.to_double() * config.speed_mps * config.dt_s
  let body_lateral = noetix_support_body_lateral_m(
    config, left_support, local_phase, transfer_frames,
  )
  let body_xy = noetix_walk_xy(config, body_forward, body_lateral)
  let body_sample = @moonphys.sample_heightfield(field, body_xy.x, body_xy.y)
  let body_z = body_sample.elevation_m +
    config.body_height_m +
    config.start_position.z +
    noetix_body_bob_m(config, local_phase, half_cycle)
  let left = if left_support {
    let foot_xy = noetix_walk_xy(
      config,
      planted_foot_forward_m(config, half_cycle, block),
      config.lateral_foot_offset_m,
    )
    foot_probe("left-foot", foot_xy.x, foot_xy.y, 0.0, true, field, config)
  } else {
    let foot_xy = noetix_walk_xy(
      config,
      swing_foot_forward_m(config, half_cycle, block, progress),
      config.lateral_foot_offset_m,
    )
    foot_probe(
      "left-foot",
      foot_xy.x,
      foot_xy.y,
      if in_double_support {
        0.0
      } else {
        swing_lift(config, progress)
      },
      in_double_support,
      field,
      config,
    )
  }
  let right = if left_support {
    let foot_xy = noetix_walk_xy(
      config,
      swing_foot_forward_m(config, half_cycle, block, progress),
      0.0 - config.lateral_foot_offset_m,
    )
    foot_probe(
      "right-foot",
      foot_xy.x,
      foot_xy.y,
      if in_double_support {
        0.0
      } else {
        swing_lift(config, progress)
      },
      in_double_support,
      field,
      config,
    )
  } else {
    let foot_xy = noetix_walk_xy(
      config,
      planted_foot_forward_m(config, half_cycle, block),
      0.0 - config.lateral_foot_offset_m,
    )
    foot_probe("right-foot", foot_xy.x, foot_xy.y, 0.0, true, field, config)
  }
  {
    frame_index,
    time_s: frame_index.to_double() * config.dt_s,
    body_position: @moonphys.vec3(body_xy.x, body_xy.y, body_z),
    support_phase: if in_double_support {
      if left_support {
        "double-support-left-transfer"
      } else {
        "double-support-right-transfer"
      }
    } else if left_support {
      "left-support"
    } else {
      "right-support"
    },
    left_foot: left,
    right_foot: right,
    joint_phases: noetix_joint_phases(
      left, right, gait_progress, left_swing_progress, right_swing_progress,
    ),
    status: frame_status(left, right),
  }
}

///|
pub fn noetix_moon_walk_trace(
  field : @moonphys.Heightfield,
  frame_count : Int,
  config? : NoetixMoonWalkConfig = default_noetix_moon_walk_config(),
) -> NoetixMoonWalkTrace {
  let frames : Array[NoetixMoonWalkFrame] = []
  let count = if frame_count < 0 { 0 } else { frame_count }
  for index in 0..<count {
    frames.push(noetix_moon_walk_frame(field, config, index))
  }
  {
    trace_id: "moonrobo/noetix-e1/endless-forward-moon-walk/\{field.field_id}",
    robot: noetix_moon_walk_robot_profile(),
    config,
    terrain_tile_id: field.field_id,
    terrain_cell_size_m: field.cell_size_m,
    frame_count: frames.length(),
    endless_axis: noetix_endless_axis(config),
    frames,
    note: "Kinematic endless-walk trace for MoonSuite collaboration: Moonmoon terrain plus Moonrobo Noetix model references. This is simulation evidence only, not hardware authority.",
  }
}

///|
pub fn noetix_endless_gait_evidence(
  field : @moonphys.Heightfield,
  reference_frame_index? : Int = 0,
  config? : NoetixMoonWalkConfig = default_noetix_moon_walk_config(),
) -> NoetixEndlessGaitEvidence {
  let cycle_frames = if config.cycle_frames < 2 {
    2
  } else {
    config.cycle_frames
  }
  let reference_index = if reference_frame_index < 0 {
    0
  } else {
    reference_frame_index
  }
  let repeated_index = reference_index + cycle_frames
  let reference = noetix_moon_walk_frame(field, config, reference_index)
  let repeated = noetix_moon_walk_frame(field, config, repeated_index)
  let forward = noetix_heading_forward(config)
  let observed_offset = repeated.body_position
    .sub(reference.body_position)
    .dot(forward)
  let expected_offset = cycle_frames.to_double() *
    config.dt_s *
    config.speed_mps
  let samples = noetix_endless_gait_samples(
    field, config, reference, reference_index, cycle_frames, expected_offset,
  )
  let phase_repeat = reference.support_phase == repeated.support_phase
  let contact_repeat = reference.left_foot.in_contact ==
    repeated.left_foot.in_contact &&
    reference.right_foot.in_contact == repeated.right_foot.in_contact
  let monotonic = observed_offset > 0.0 &&
    abs_double(observed_offset - expected_offset) < 0.000001
  let multi_cycle = samples.length() > 0 &&
    samples.all(fn(sample) {
      sample.phase_matches_reference &&
      sample.contact_matches_reference &&
      sample.forward_offset_matches_expected
    })
  let ready = phase_repeat && contact_repeat && monotonic && multi_cycle
  {
    evidence_id: "moonrobo/noetix-e1/endless-gait/\{field.field_id}",
    trace_id: "moonrobo/noetix-e1/endless-forward-moon-walk/\{field.field_id}",
    robot_id: noetix_moon_walk_robot_profile().robot_id,
    terrain_tile_id: field.field_id,
    reference_frame_index: reference_index,
    repeated_frame_index: repeated_index,
    cycle_frames,
    dt_s: config.dt_s,
    speed_mps: config.speed_mps,
    expected_forward_offset_m: expected_offset,
    observed_forward_offset_m: observed_offset,
    reference_support_phase: reference.support_phase,
    repeated_support_phase: repeated.support_phase,
    phase_repeat_verified: phase_repeat,
    contact_repeat_verified: contact_repeat,
    monotonic_forward_verified: monotonic,
    cycle_forward_offset_m: expected_offset,
    sample_count: samples.length(),
    sample_cycle_count: 4,
    samples,
    multi_cycle_verified: multi_cycle,
    hardware_authority: "moonmoon-safety-gate-only",
    status: if ready {
      "endless-gait-window-verified"
    } else {
      "endless-gait-window-review"
    },
    note: "Finite Noetix walk exports are replay windows over this mathematically endless Moonrobo gait. Sampled future cycles repeat the support/contact phase while the body advances by the configured forward offset. This is simulation evidence only.",
  }
}

///|
fn noetix_endless_gait_sample(
  field : @moonphys.Heightfield,
  config : NoetixMoonWalkConfig,
  reference : NoetixMoonWalkFrame,
  reference_frame_index : Int,
  relative_cycle : Int,
  cycle_frames : Int,
  expected_cycle_offset_m : Double,
) -> NoetixEndlessGaitSample {
  let frame_index = reference_frame_index + relative_cycle * cycle_frames
  let frame = noetix_moon_walk_frame(field, config, frame_index)
  let forward = noetix_heading_forward(config)
  let observed_offset = frame.body_position
    .sub(reference.body_position)
    .dot(forward)
  let expected_offset = relative_cycle.to_double() * expected_cycle_offset_m
  {
    frame_index,
    cycle_index: relative_cycle,
    phase_index: phase_index(frame_index, cycle_frames),
    support_phase: frame.support_phase,
    body_forward_offset_m: observed_offset,
    expected_forward_offset_m: expected_offset,
    left_contact: frame.left_foot.in_contact,
    right_contact: frame.right_foot.in_contact,
    phase_matches_reference: frame.support_phase == reference.support_phase,
    contact_matches_reference: frame.left_foot.in_contact ==
    reference.left_foot.in_contact &&
    frame.right_foot.in_contact == reference.right_foot.in_contact,
    forward_offset_matches_expected: abs_double(
      observed_offset - expected_offset,
    ) <
    0.000001,
  }
}

///|
fn noetix_endless_gait_samples(
  field : @moonphys.Heightfield,
  config : NoetixMoonWalkConfig,
  reference : NoetixMoonWalkFrame,
  reference_frame_index : Int,
  cycle_frames : Int,
  expected_cycle_offset_m : Double,
) -> Array[NoetixEndlessGaitSample] {
  [
    noetix_endless_gait_sample(
      field, config, reference, reference_frame_index, 1, cycle_frames, expected_cycle_offset_m,
    ),
    noetix_endless_gait_sample(
      field, config, reference, reference_frame_index, 2, cycle_frames, expected_cycle_offset_m,
    ),
    noetix_endless_gait_sample(
      field, config, reference, reference_frame_index, 3, cycle_frames, expected_cycle_offset_m,
    ),
    noetix_endless_gait_sample(
      field, config, reference, reference_frame_index, 4, cycle_frames, expected_cycle_offset_m,
    ),
  ]
}

///|
pub fn first_trusted_square_noetix_endless_gait_evidence() -> NoetixEndlessGaitEvidence {
  noetix_endless_gait_evidence(first_trusted_square_noetix_heightfield())
}

///|
pub fn first_trusted_square_noetix_endless_gait_json() -> Json {
  first_trusted_square_noetix_endless_gait_evidence().to_json()
}

///|
pub fn first_trusted_square_noetix_walk_trace(
  frame_count? : Int = 32,
) -> NoetixMoonWalkTrace {
  noetix_moon_walk_trace(first_trusted_square_noetix_heightfield(), frame_count)
}

///|
pub fn first_trusted_square_noetix_walk_json() -> Json {
  first_trusted_square_noetix_walk_trace().to_json()
}

///|
pub fn render_noetix_endless_gait_markdown(
  evidence : NoetixEndlessGaitEvidence,
) -> String {
  let mut text = "# Noetix Endless Gait Evidence\n\n"
  text += "- evidence: \{evidence.evidence_id}\n"
  text += "- trace: \{evidence.trace_id}\n"
  text += "- robot: \{evidence.robot_id}\n"
  text += "- terrain: \{evidence.terrain_tile_id}\n"
  text += "- reference frame: \{evidence.reference_frame_index}\n"
  text += "- repeated frame: \{evidence.repeated_frame_index}\n"
  text += "- cycle frames: \{evidence.cycle_frames}\n"
  text += "- expected forward offset: \{evidence.expected_forward_offset_m} m\n"
  text += "- observed forward offset: \{evidence.observed_forward_offset_m} m\n"
  text += "- cycle forward offset: \{evidence.cycle_forward_offset_m} m\n"
  text += "- reference support: \{evidence.reference_support_phase}\n"
  text += "- repeated support: \{evidence.repeated_support_phase}\n"
  text += "- phase repeat verified: \{evidence.phase_repeat_verified}\n"
  text += "- contact repeat verified: \{evidence.contact_repeat_verified}\n"
  text += "- monotonic forward verified: \{evidence.monotonic_forward_verified}\n"
  text += "- multi-cycle verified: \{evidence.multi_cycle_verified}\n"
  text += "- sampled cycles: \{evidence.sample_cycle_count}\n"
  text += "- samples:\n"
  for sample in evidence.samples {
    text += "  - frame \{sample.frame_index}: cycle=\{sample.cycle_index} phase=\{sample.phase_index} offset=\{sample.body_forward_offset_m} expected=\{sample.expected_forward_offset_m} phase-ok=\{sample.phase_matches_reference} contact-ok=\{sample.contact_matches_reference}\n"
  }
  text += "- hardware authority: \{evidence.hardware_authority}\n"
  text += "- status: \{evidence.status}\n"
  text += "- note: \{evidence.note}"
  text
}

///|
pub fn first_trusted_square_noetix_endless_gait_markdown() -> String {
  render_noetix_endless_gait_markdown(
    first_trusted_square_noetix_endless_gait_evidence(),
  )
}

///|
pub fn render_noetix_moon_walk_markdown(trace : NoetixMoonWalkTrace) -> String {
  let mut text = "# Noetix Endless Moon Walk\n\n"
  text += "- trace: \{trace.trace_id}\n"
  text += "- robot: \{trace.robot.robot_id} (\{trace.robot.label})\n"
  text += "- source model: \{trace.robot.source_model_path}\n"
  text += "- terrain: \{trace.terrain_tile_id}\n"
  text += "- terrain source: \{trace.config.terrain_source_id}\n"
  text += "- gravity: \{trace.config.gravity_mps2} m/s^2\n"
  text += "- speed: \{trace.config.speed_mps} m/s\n"
  text += "- heading: \{trace.config.heading_rad} rad\n"
  text += "- stride frequency: \{trace.config.stride_frequency_hz} Hz\n"
  text += "- foot radius: \{trace.config.foot_radius_m} m\n"
  text += "- frames: \{trace.frame_count}\n"
  text += "- endless axis: \{trace.endless_axis}\n"
  text += "- note: \{trace.note}\n\n"
  text += "## Trace Prefix\n\n"
  for frame in trace.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} body_x=\{frame.body_position.x} status=\{frame.status}\n"
    text += "  - left: x=\{frame.left_foot.position.x} z=\{frame.left_foot.position.z} contact=\{frame.left_foot.in_contact} clearance=\{frame.left_foot.clearance_m} status=\{frame.left_foot.status}\n"
    text += "  - right: x=\{frame.right_foot.position.x} z=\{frame.right_foot.position.z} contact=\{frame.right_foot.in_contact} clearance=\{frame.right_foot.clearance_m} status=\{frame.right_foot.status}\n"
    text += "  - joints: \{frame.joint_phases.length()} phases with URDF gait clip\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_walk_markdown() -> String {
  render_noetix_moon_walk_markdown(first_trusted_square_noetix_walk_trace())
}
