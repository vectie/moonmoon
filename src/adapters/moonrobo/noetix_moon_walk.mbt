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
pub fn default_noetix_moon_walk_config() -> NoetixMoonWalkConfig {
  {
    config_id: "moonrobo/noetix-e1/endless-forward-moon-walk-v0",
    gravity_mps2: @moonphys.lunar_environment().gravity_mps2,
    dt_s: 0.1,
    speed_mps: 0.12,
    heading_rad: 0.0,
    start_position: @moonphys.vec3(0.0, 0.0, 0.0),
    step_length_m: 0.16,
    step_height_m: 0.045,
    stride_frequency_hz: 0.75,
    cycle_frames: 20,
    lateral_foot_offset_m: 0.08,
    min_swing_clearance_m: 0.02,
    foot_radius_m: 0.012,
    caution_grade: 0.18,
    body_height_m: 0.72,
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
fn swing_lift(config : NoetixMoonWalkConfig, progress : Double) -> Double {
  config.step_height_m * @math.sin(progress * 3.141592653589793)
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
fn joint_phase(
  joint_name : String,
  role : String,
  side : String,
  position_rad : Double,
) -> NoetixJointPhase {
  joint_phase_with_status(
    joint_name, role, side, position_rad, "kinematic-phase",
  )
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
fn noetix_leg_ik_phases(
  config : NoetixMoonWalkConfig,
  body_position : @moonphys.Vec3,
  foot : NoetixFootContactProbe,
  side : String,
  prefix : String,
) -> Array[NoetixJointPhase] {
  let side_sign = if side == "left" { 1.0 } else { 0.0 - 1.0 }
  let forward = noetix_heading_forward(config)
  let lateral = noetix_heading_lateral(config)
  let hip_world = body_position
    .add(lateral.scale(side_sign * config.lateral_foot_offset_m))
    .add(@moonphys.vec3(0.0, 0.0, -0.08))
  let ankle_target = foot.position
    .sub(forward.scale(0.04))
    .add(@moonphys.vec3(0.0, 0.0, 0.08))
  let relative = ankle_target.sub(hip_world)
  let sagittal_x = relative.dot(forward)
  let lateral_error = relative.dot(lateral)
  let down = 0.0 - relative.z
  let upper_leg_m = 0.32
  let lower_leg_m = 0.34
  let distance = clamp_double(
    (sagittal_x * sagittal_x + down * down).sqrt(),
    0.08,
    upper_leg_m + lower_leg_m - 0.001,
  )
  let knee_cos = clamp_double(
    (
      upper_leg_m * upper_leg_m +
      lower_leg_m * lower_leg_m -
      distance * distance
    ) /
    (2.0 * upper_leg_m * lower_leg_m),
    -1.0,
    1.0,
  )
  let knee_flex = 3.141592653589793 - @math.acos(knee_cos)
  let line_angle = @math.atan2(sagittal_x, down)
  let bend_angle = @math.atan2(
    lower_leg_m * @math.sin(knee_flex),
    upper_leg_m + lower_leg_m * @math.cos(knee_flex),
  )
  let hip_pitch = line_angle - bend_angle
  let hip_roll = clamp_double(lateral_error * 2.5, -0.35, 0.35)
  let knee_upper = knee_flex * 0.55
  let knee_lower = 0.0 - knee_flex * 0.45
  let ankle_roll = 0.0 - hip_roll * 0.45
  let ankle_pitch = 0.0 - (hip_pitch + knee_upper + knee_lower)
  [
    bounded_joint_phase(
      "\{prefix}1_joint",
      "hip-pitch",
      side,
      hip_pitch,
      "urdf-leg-ik",
    ),
    bounded_joint_phase(
      "\{prefix}2_joint",
      "hip-roll",
      side,
      hip_roll,
      "urdf-leg-ik",
    ),
    bounded_joint_phase(
      "\{prefix}3_joint",
      "knee-upper",
      side,
      knee_upper,
      "urdf-leg-ik",
    ),
    bounded_joint_phase(
      "\{prefix}4_joint",
      "knee-lower",
      side,
      knee_lower,
      "urdf-leg-ik",
    ),
    bounded_joint_phase(
      "\{prefix}5_joint",
      "ankle-roll",
      side,
      ankle_roll,
      "urdf-leg-ik",
    ),
    bounded_joint_phase(
      "\{prefix}6_joint",
      "ankle-pitch",
      side,
      ankle_pitch,
      "urdf-leg-ik",
    ),
  ]
}

///|
fn arm_phases(
  left_support : Bool,
  progress : Double,
) -> Array[NoetixJointPhase] {
  let wave = @math.sin(progress * 3.141592653589793)
  let left = if left_support { 0.0 - wave } else { wave }
  let right = 0.0 - left
  [
    joint_phase("arm_l1_joint", "shoulder-pitch", "left", 0.18 * left),
    joint_phase("arm_l2_joint", "shoulder-roll", "left", 0.05 * left),
    joint_phase("arm_l3_joint", "elbow-yaw", "left", 0.04 * left),
    joint_phase("arm_l4_joint", "elbow-pitch", "left", 0.10 * left),
    joint_phase("arm_l5_joint", "wrist-roll", "left", 0.03 * left),
    joint_phase("arm_r1_joint", "shoulder-pitch", "right", 0.18 * right),
    joint_phase("arm_r2_joint", "shoulder-roll", "right", 0.05 * right),
    joint_phase("arm_r3_joint", "elbow-yaw", "right", 0.04 * right),
    joint_phase("arm_r4_joint", "elbow-pitch", "right", 0.10 * right),
    joint_phase("arm_r5_joint", "wrist-roll", "right", 0.03 * right),
  ]
}

///|
fn noetix_joint_phases(
  config : NoetixMoonWalkConfig,
  body_position : @moonphys.Vec3,
  left_foot : NoetixFootContactProbe,
  right_foot : NoetixFootContactProbe,
  left_support : Bool,
  progress : Double,
) -> Array[NoetixJointPhase] {
  let phases : Array[NoetixJointPhase] = []
  phases.push(joint_phase("waist_1_joint", "waist-yaw", "center", 0.0))
  phases.push(joint_phase("waist_2_joint", "waist-pitch", "center", 0.0))
  for
    phase in noetix_leg_ik_phases(
      config, body_position, left_foot, "left", "leg_l",
    ) {
    phases.push(phase)
  }
  for
    phase in noetix_leg_ik_phases(
      config, body_position, right_foot, "right", "leg_r",
    ) {
    phases.push(phase)
  }
  for phase in arm_phases(left_support, progress) {
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
  let progress = phase_progress(local_phase, half_cycle)
  let body_forward = frame_index.to_double() * config.speed_mps * config.dt_s
  let body_xy = noetix_walk_xy(config, body_forward, 0.0)
  let body_sample = @moonphys.sample_heightfield(field, body_xy.x, body_xy.y)
  let body_z = body_sample.elevation_m +
    config.body_height_m +
    config.start_position.z
  let swing_offset = (progress - 0.5) * config.step_length_m
  let support_offset = 0.0 - config.step_length_m * 0.25
  let left = if left_support {
    let foot_xy = noetix_walk_xy(
      config,
      body_forward + support_offset,
      config.lateral_foot_offset_m,
    )
    foot_probe("left-foot", foot_xy.x, foot_xy.y, 0.0, true, field, config)
  } else {
    let foot_xy = noetix_walk_xy(
      config,
      body_forward + swing_offset,
      config.lateral_foot_offset_m,
    )
    foot_probe(
      "left-foot",
      foot_xy.x,
      foot_xy.y,
      swing_lift(config, progress),
      false,
      field,
      config,
    )
  }
  let right = if left_support {
    let foot_xy = noetix_walk_xy(
      config,
      body_forward + swing_offset,
      0.0 - config.lateral_foot_offset_m,
    )
    foot_probe(
      "right-foot",
      foot_xy.x,
      foot_xy.y,
      swing_lift(config, progress),
      false,
      field,
      config,
    )
  } else {
    let foot_xy = noetix_walk_xy(
      config,
      body_forward + support_offset,
      0.0 - config.lateral_foot_offset_m,
    )
    foot_probe("right-foot", foot_xy.x, foot_xy.y, 0.0, true, field, config)
  }
  {
    frame_index,
    time_s: frame_index.to_double() * config.dt_s,
    body_position: @moonphys.vec3(body_xy.x, body_xy.y, body_z),
    support_phase: if left_support {
      "left-support"
    } else {
      "right-support"
    },
    left_foot: left,
    right_foot: right,
    joint_phases: noetix_joint_phases(
      config,
      @moonphys.vec3(body_xy.x, body_xy.y, body_z),
      left,
      right,
      left_support,
      progress,
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
  let phase_repeat = reference.support_phase == repeated.support_phase
  let contact_repeat = reference.left_foot.in_contact ==
    repeated.left_foot.in_contact &&
    reference.right_foot.in_contact == repeated.right_foot.in_contact
  let monotonic = observed_offset > 0.0 &&
    abs_double(observed_offset - expected_offset) < 0.000001
  let ready = phase_repeat && contact_repeat && monotonic
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
    hardware_authority: "moonmoon-safety-gate-only",
    status: if ready {
      "endless-gait-window-verified"
    } else {
      "endless-gait-window-review"
    },
    note: "Finite Noetix walk exports are replay windows over this mathematically endless Moonrobo gait. A frame one cycle later repeats the support/contact phase while the body advances by the configured forward offset. This is simulation evidence only.",
  }
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
  text += "- reference support: \{evidence.reference_support_phase}\n"
  text += "- repeated support: \{evidence.repeated_support_phase}\n"
  text += "- phase repeat verified: \{evidence.phase_repeat_verified}\n"
  text += "- contact repeat verified: \{evidence.contact_repeat_verified}\n"
  text += "- monotonic forward verified: \{evidence.monotonic_forward_verified}\n"
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
    text += "  - joints: \{frame.joint_phases.length()} phases with URDF leg IK\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_walk_markdown() -> String {
  render_noetix_moon_walk_markdown(first_trusted_square_noetix_walk_trace())
}
