///|
pub(all) struct NoetixJointControlStep {
  joint_name : String
  joint_index : Int
  target_position_rad : Double
  target_velocity_rad_s : Double
  motor_step : @moonphys.JointMotorStep
  position_within_limits : Bool
  velocity_within_limits : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixJointControlFrame {
  frame_index : Int
  time_s : Double
  joint_count : Int
  saturated_joint_count : Int
  limit_review_count : Int
  max_abs_position_error_rad : Double
  max_abs_velocity_rad_s : Double
  max_abs_mechanical_power_w : Double
  net_work_j : Double
  total_absolute_work_j : Double
  hinge_joint_frame : NoetixHingeJointFrameEvidence
  steps : Array[NoetixJointControlStep]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixHingeMotorTraceEvidence {
  trace_id : String
  frame_count : Int
  driven_joint_count : Int
  review_count : Int
  max_angle_delta_rad : Double
  max_velocity_delta_rad_s : Double
  final_projected_body_count : Int
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixHingeMotorWorldTraceEvidence {
  trace_id : String
  frame_count : Int
  motor_frame_count : Int
  body_target_frame_count : Int
  body_target_count : Int
  support_target_frame_count : Int
  support_target_count : Int
  center_of_mass_target_frame_count : Int
  driven_joint_count : Int
  contact_count : Int
  support_contact_count : Int
  stable_support_frame_count : Int
  support_review_frame_count : Int
  capture_stable_support_frame_count : Int
  capture_support_review_frame_count : Int
  resolved_hinge_constraint_count : Int
  review_count : Int
  final_body_count : Int
  final_projected_body_count : Int
  body_sample_count : Int
  min_position : @moonphys.Vec3
  max_position : @moonphys.Vec3
  max_speed_mps : Double
  max_kinetic_energy_j : Double
  total_mass_kg : Double
  initial_center_of_mass : @moonphys.Vec3
  final_center_of_mass : @moonphys.Vec3
  min_center_of_mass : @moonphys.Vec3
  max_center_of_mass : @moonphys.Vec3
  max_center_of_mass_speed_mps : Double
  min_support_margin_m : Double
  max_support_recovery_shift_m : Double
  worst_capture_support_margin_m : Double
  max_capture_recovery_shift_m : Double
  max_center_of_pressure_error_m : Double
  max_body_linear_momentum_kg_mps : Double
  max_world_linear_momentum_kg_mps : Double
  max_frame_kinetic_energy_delta_j : Double
  envelope_status : String
  world_review_status : String
  world_review_ready : Bool
  world_review_blocker_count : Int
  world_review_blockers : Array[String]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixJointControlReport {
  report_id : String
  trace_id : String
  profile : NoetixPhysicsProfile
  frame_count : Int
  joint_count_per_frame : Int
  saturated_frame_count : Int
  limit_review_frame_count : Int
  hinge_joint_frame_count : Int
  hinge_review_frame_count : Int
  hinge_joint_count_per_frame : Int
  hinge_motor_driven_frame_count : Int
  hinge_motor_driven_joint_count : Int
  hinge_motor_trace : NoetixHingeMotorTraceEvidence
  hinge_motor_world_trace : NoetixHingeMotorWorldTraceEvidence
  max_abs_position_error_rad : Double
  max_abs_velocity_rad_s : Double
  max_abs_mechanical_power_w : Double
  max_hinge_position_error_m : Double
  max_hinge_angular_error_rad : Double
  max_hinge_motor_angle_delta_rad : Double
  max_hinge_motor_velocity_delta_rad_s : Double
  hinge_linear_impulse_ns : Double
  hinge_angular_impulse_nms : Double
  net_work_j : Double
  total_absolute_work_j : Double
  frames : Array[NoetixJointControlFrame]
  hardware_authority : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn actuator_profile_for(
  profile : NoetixPhysicsProfile,
  joint_name : String,
) -> NoetixJointActuatorProfile {
  for actuator in profile.actuator_profiles {
    if actuator.joint_name == joint_name {
      return actuator
    }
  }
  profile.actuator_profiles[0]
}

///|
fn phase_position(frame : NoetixMoonWalkFrame, joint_name : String) -> Double {
  for phase in frame.joint_phases {
    if phase.joint_name == joint_name {
      return phase.position_rad
    }
  }
  0.0
}

///|
fn previous_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
) -> NoetixMoonWalkFrame {
  if frame_index <= 0 {
    trace.frames[0]
  } else {
    trace.frames[frame_index - 1]
  }
}

///|
fn frame_dt_s(trace : NoetixMoonWalkTrace, frame_index : Int) -> Double {
  if frame_index <= 0 || trace.frames.length() < 2 {
    trace.config.dt_s
  } else {
    let current = trace.frames[frame_index]
    let previous = trace.frames[frame_index - 1]
    let dt = current.time_s - previous.time_s
    if dt > 0.0 {
      dt
    } else {
      trace.config.dt_s
    }
  }
}

///|
fn noetix_joint_motor_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> @moonphys.JointMotorFrame {
  let frame = trace.frames[frame_index]
  let previous = previous_frame(trace, frame_index)
  let dt = frame_dt_s(trace, frame_index)
  let states : Array[@moonphys.JointMotorState] = []
  let commands : Array[@moonphys.JointMotorCommand] = []
  let configs : Array[@moonphys.JointServoConfig] = []
  let limits : Array[@moonphys.JointLimit] = []
  let inertias : Array[Double] = []
  for phase in frame.joint_phases {
    let actuator = actuator_profile_for(profile, phase.joint_name)
    let previous_position = phase_position(previous, phase.joint_name)
    let state = @moonphys.joint_motor_state(
      phase.joint_name,
      previous_position,
      0.0,
    )
    let target_velocity = if dt > 0.0 {
      (phase.position_rad - previous_position) / dt
    } else {
      0.0
    }
    let shaped = @moonphys.joint_velocity_limited_command(
      state,
      phase.position_rad,
      target_velocity,
      0.0,
      actuator.limit,
      dt,
    )
    states.push(state)
    commands.push(shaped.command)
    configs.push(actuator.servo)
    limits.push(actuator.limit)
    inertias.push(actuator.inertia_kg_m2)
  }
  @moonphys.integrate_joint_motor_frame(
    "noetix-e1/joint-control/frame-\{frame.frame_index}",
    states,
    commands,
    configs,
    limits,
    inertias,
    dt,
  )
}

///|
fn noetix_joint_motor_frames(
  trace : NoetixMoonWalkTrace,
  profile : NoetixPhysicsProfile,
) -> Array[@moonphys.JointMotorFrame] {
  let motor_frames : Array[@moonphys.JointMotorFrame] = []
  for index, _frame in trace.frames {
    motor_frames.push(noetix_joint_motor_frame(trace, index, profile))
  }
  motor_frames
}

///|
fn noetix_world_body_targets_for_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> Array[@moonphys.RigidBodyWorldBodyTarget] {
  let projection = noetix_hinge_projection_frame(trace, frame_index, profile)
  let targets : Array[@moonphys.RigidBodyWorldBodyTarget] = []
  for body in projection.world.bodies {
    targets.push(
      @moonphys.rigid_body_world_body_target(
        body.state.body_id,
        body.state.position,
        body.state.velocity,
        max_correction_m=10.0,
      ),
    )
  }
  targets
}

///|
fn noetix_world_body_target_frames(
  trace : NoetixMoonWalkTrace,
  profile : NoetixPhysicsProfile,
) -> Array[Array[@moonphys.RigidBodyWorldBodyTarget]] {
  let frames : Array[Array[@moonphys.RigidBodyWorldBodyTarget]] = []
  for index, _frame in trace.frames {
    frames.push(noetix_world_body_targets_for_frame(trace, index, profile))
  }
  frames
}

///|
fn noetix_body_target_count(
  frames : Array[Array[@moonphys.RigidBodyWorldBodyTarget]],
) -> Int {
  let mut count = 0
  for frame in frames {
    count += frame.length()
  }
  count
}

///|
fn noetix_support_footprints_for_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> Array[@moonphys.SupportFootprint] {
  let frame = trace.frames[frame_index]
  let left_geometry = foot_geometry(profile, "left-foot")
  let right_geometry = foot_geometry(profile, "right-foot")
  [
    contact_footprint(frame.left_foot, left_geometry),
    contact_footprint(frame.right_foot, right_geometry),
  ]
}

///|
fn noetix_support_footprint_frames(
  trace : NoetixMoonWalkTrace,
  profile : NoetixPhysicsProfile,
) -> Array[Array[@moonphys.SupportFootprint]] {
  let frames : Array[Array[@moonphys.SupportFootprint]] = []
  for index, _frame in trace.frames {
    frames.push(noetix_support_footprints_for_frame(trace, index, profile))
  }
  frames
}

///|
fn noetix_support_target_count(
  frames : Array[Array[@moonphys.SupportFootprint]],
) -> Int {
  let mut count = 0
  for frame in frames {
    for footprint in frame {
      if footprint.active {
        count += 1
      }
    }
  }
  count
}

///|
fn noetix_center_of_mass_target_for_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> @moonphys.RigidBodyWorldCenterOfMassTarget {
  let frame = trace.frames[frame_index]
  @moonphys.rigid_body_world_center_of_mass_target(
    @moonphys.vec3(
      frame.body_position.x + profile.mass_model.com_x_offset_m,
      frame.body_position.y + profile.mass_model.com_y_offset_m,
      frame.body_position.z,
    ),
    body_velocity(trace, frame_index),
    total_mass_kg=profile.mass_model.mass_kg,
    nominal_com_height_m=profile.mass_model.nominal_com_height_m,
  )
}

///|
fn noetix_center_of_mass_target_frames(
  trace : NoetixMoonWalkTrace,
  profile : NoetixPhysicsProfile,
) -> Array[@moonphys.RigidBodyWorldCenterOfMassTarget] {
  let frames : Array[@moonphys.RigidBodyWorldCenterOfMassTarget] = []
  for index, _frame in trace.frames {
    frames.push(noetix_center_of_mass_target_for_frame(trace, index, profile))
  }
  frames
}

///|
fn noetix_joint_step_status(step : @moonphys.JointMotorFrameStep) -> String {
  if !step.position_within_limits || !step.velocity_within_limits {
    "joint-limit-review"
  } else if step.motor_step.servo.saturated {
    "joint-torque-review"
  } else {
    "joint-command-review"
  }
}

///|
fn noetix_joint_control_step(
  profile : NoetixPhysicsProfile,
  step : @moonphys.JointMotorFrameStep,
) -> NoetixJointControlStep {
  let actuator = actuator_profile_for(profile, step.command.joint_id)
  {
    joint_name: step.command.joint_id,
    joint_index: actuator.joint_index,
    target_position_rad: step.command.target_position_rad,
    target_velocity_rad_s: step.command.target_velocity_rad_s,
    motor_step: step.motor_step,
    position_within_limits: step.position_within_limits,
    velocity_within_limits: step.velocity_within_limits,
    status: noetix_joint_step_status(step),
  }
}

///|
fn noetix_hinge_motor_trace_evidence(
  trace : NoetixMoonWalkTrace,
  profile : NoetixPhysicsProfile,
) -> NoetixHingeMotorTraceEvidence {
  let motor_frames = noetix_joint_motor_frames(trace, profile)
  let initial = noetix_hinge_projection_frame(trace, 0, profile)
  let motor_trace = @moonphys.rigid_body_world_integrate_hinge_motor_trace(
    "noetix-e1/world-hinge-motor-trace/\{trace.terrain_tile_id}",
    initial.world,
    motor_frames,
    note="Noetix gait phases replayed as a sequential Moonphys world hinge motor trace",
  )
  {
    trace_id: motor_trace.trace_id,
    frame_count: motor_trace.frame_count,
    driven_joint_count: motor_trace.driven_joint_count,
    review_count: motor_trace.review_count,
    max_angle_delta_rad: motor_trace.max_abs_angle_delta_rad,
    max_velocity_delta_rad_s: motor_trace.max_abs_velocity_delta_rad_s,
    final_projected_body_count: motor_trace.final_world.motion_bodies.length(),
    status: motor_trace.status,
  }
}

///|
fn noetix_hinge_motor_world_trace_evidence(
  trace : NoetixMoonWalkTrace,
  profile : NoetixPhysicsProfile,
) -> NoetixHingeMotorWorldTraceEvidence {
  let motor_frames = noetix_joint_motor_frames(trace, profile)
  let body_target_frames = noetix_world_body_target_frames(trace, profile)
  let support_target_frames = noetix_support_footprint_frames(trace, profile)
  let center_of_mass_targets = noetix_center_of_mass_target_frames(
    trace, profile,
  )
  let initial = noetix_hinge_projection_frame(trace, 0, profile)
  let world_trace = @moonphys.rigid_body_heightfield_world_targeted_hinge_motor_trace(
    "noetix-e1/world-heightfield-hinge-motor-trace/\{trace.terrain_tile_id}",
    initial.world,
    first_trusted_square_noetix_heightfield(),
    motor_frames,
    body_target_frames,
    note="Noetix gait phases replayed through Moonphys target-driven hinge motor heightfield world replay",
  )
  let review = @moonphys.rigid_body_heightfield_world_hinge_motor_replay_review_with_targets(
    world_trace, support_target_frames, center_of_mass_targets,
  )
  {
    trace_id: world_trace.trace_id,
    frame_count: world_trace.frame_count,
    motor_frame_count: world_trace.motor_frame_count,
    body_target_frame_count: body_target_frames.length(),
    body_target_count: noetix_body_target_count(body_target_frames),
    support_target_frame_count: support_target_frames.length(),
    support_target_count: noetix_support_target_count(support_target_frames),
    center_of_mass_target_frame_count: center_of_mass_targets.length(),
    driven_joint_count: world_trace.driven_joint_count,
    contact_count: world_trace.contact_count,
    support_contact_count: review.support_contact_count,
    stable_support_frame_count: review.stable_support_frame_count,
    support_review_frame_count: review.support_review_frame_count,
    capture_stable_support_frame_count: review.capture_stable_frame_count,
    capture_support_review_frame_count: review.capture_review_frame_count,
    resolved_hinge_constraint_count: world_trace.resolved_hinge_constraint_count,
    review_count: world_trace.review_count,
    final_body_count: world_trace.final_world.bodies.length(),
    final_projected_body_count: world_trace.final_world.motion_bodies.length(),
    body_sample_count: review.body_sample_count,
    min_position: review.min_position,
    max_position: review.max_position,
    max_speed_mps: review.max_speed_mps,
    max_kinetic_energy_j: review.max_kinetic_energy_j,
    total_mass_kg: review.total_mass_kg,
    initial_center_of_mass: review.initial_center_of_mass,
    final_center_of_mass: review.final_center_of_mass,
    min_center_of_mass: review.min_center_of_mass,
    max_center_of_mass: review.max_center_of_mass,
    max_center_of_mass_speed_mps: review.max_center_of_mass_speed_mps,
    min_support_margin_m: review.min_support_margin_m,
    max_support_recovery_shift_m: review.max_support_recovery_shift_m,
    worst_capture_support_margin_m: review.worst_capture_margin_m,
    max_capture_recovery_shift_m: review.max_capture_recovery_shift_m,
    max_center_of_pressure_error_m: review.max_center_of_pressure_error_m,
    max_body_linear_momentum_kg_mps: review.max_body_linear_momentum_kg_mps,
    max_world_linear_momentum_kg_mps: review.max_world_linear_momentum_kg_mps,
    max_frame_kinetic_energy_delta_j: review.max_frame_kinetic_energy_delta_j,
    envelope_status: review.envelope_status,
    world_review_status: review.status,
    world_review_ready: review.ready,
    world_review_blocker_count: review.blocker_count,
    world_review_blockers: review.blockers,
    status: world_trace.status,
  }
}

///|
fn joint_control_frame_status(
  saturated_count : Int,
  limit_review_count : Int,
) -> String {
  if limit_review_count > 0 {
    "joint-limit-review"
  } else if saturated_count > 0 {
    "joint-torque-review"
  } else {
    "joint-command-review"
  }
}

///|
pub fn noetix_joint_control_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> NoetixJointControlFrame {
  let frame = trace.frames[frame_index]
  let motor_frame = noetix_joint_motor_frame(trace, frame_index, profile)
  let hinge_joint_frame = noetix_hinge_joint_frame_evidence(
    trace, frame_index, profile, motor_frame,
  )
  let steps : Array[NoetixJointControlStep] = []
  for step in motor_frame.steps {
    steps.push(noetix_joint_control_step(profile, step))
  }
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    joint_count: motor_frame.joint_count,
    saturated_joint_count: motor_frame.saturated_joint_count,
    limit_review_count: motor_frame.limit_review_count,
    max_abs_position_error_rad: motor_frame.max_abs_position_error_rad,
    max_abs_velocity_rad_s: motor_frame.max_abs_velocity_rad_s,
    max_abs_mechanical_power_w: motor_frame.max_abs_mechanical_power_w,
    net_work_j: motor_frame.net_work_j,
    total_absolute_work_j: motor_frame.total_absolute_work_j,
    hinge_joint_frame,
    steps,
    status: joint_control_frame_status(
      motor_frame.saturated_joint_count,
      motor_frame.limit_review_count,
    ),
  }
}

///|
pub fn noetix_joint_control_report(
  trace : NoetixMoonWalkTrace,
  profile? : NoetixPhysicsProfile = default_noetix_physics_profile(),
) -> NoetixJointControlReport {
  let frames : Array[NoetixJointControlFrame] = []
  let mut saturated_frame_count = 0
  let mut limit_review_frame_count = 0
  let mut hinge_review_frame_count = 0
  let mut max_position_error = 0.0
  let mut max_velocity = 0.0
  let mut max_power = 0.0
  let mut max_hinge_position_error = 0.0
  let mut max_hinge_angular_error = 0.0
  let mut max_hinge_motor_angle_delta = 0.0
  let mut max_hinge_motor_velocity_delta = 0.0
  let mut hinge_linear_impulse = 0.0
  let mut hinge_angular_impulse = 0.0
  let mut hinge_motor_driven_frame_count = 0
  let mut hinge_motor_driven_joint_count = 0
  let mut net_work = 0.0
  let mut total_abs_work = 0.0
  let mut joint_count_per_frame = 0
  let mut hinge_joint_count_per_frame = 0
  let hinge_motor_trace = noetix_hinge_motor_trace_evidence(trace, profile)
  let hinge_motor_world_trace = noetix_hinge_motor_world_trace_evidence(
    trace, profile,
  )
  for index, _frame in trace.frames {
    let control_frame = noetix_joint_control_frame(trace, index, profile)
    if control_frame.saturated_joint_count > 0 {
      saturated_frame_count += 1
    }
    if control_frame.limit_review_count > 0 {
      limit_review_frame_count += 1
    }
    if control_frame.hinge_joint_frame.review_count > 0 ||
      control_frame.hinge_joint_frame.status.contains("review") {
      hinge_review_frame_count += 1
    }
    if control_frame.hinge_joint_frame.motor_driven_joint_count > 0 {
      hinge_motor_driven_frame_count += 1
      hinge_motor_driven_joint_count += control_frame.hinge_joint_frame.motor_driven_joint_count
    }
    if control_frame.max_abs_position_error_rad > max_position_error {
      max_position_error = control_frame.max_abs_position_error_rad
    }
    if control_frame.max_abs_velocity_rad_s > max_velocity {
      max_velocity = control_frame.max_abs_velocity_rad_s
    }
    if control_frame.max_abs_mechanical_power_w > max_power {
      max_power = control_frame.max_abs_mechanical_power_w
    }
    if control_frame.hinge_joint_frame.max_position_error_m >
      max_hinge_position_error {
      max_hinge_position_error = control_frame.hinge_joint_frame.max_position_error_m
    }
    if control_frame.hinge_joint_frame.max_angular_error_rad >
      max_hinge_angular_error {
      max_hinge_angular_error = control_frame.hinge_joint_frame.max_angular_error_rad
    }
    if control_frame.hinge_joint_frame.max_motor_angle_delta_rad >
      max_hinge_motor_angle_delta {
      max_hinge_motor_angle_delta = control_frame.hinge_joint_frame.max_motor_angle_delta_rad
    }
    if control_frame.hinge_joint_frame.max_motor_velocity_delta_rad_s >
      max_hinge_motor_velocity_delta {
      max_hinge_motor_velocity_delta = control_frame.hinge_joint_frame.max_motor_velocity_delta_rad_s
    }
    hinge_linear_impulse += control_frame.hinge_joint_frame.linear_impulse_ns
    hinge_angular_impulse += control_frame.hinge_joint_frame.angular_impulse_nms
    net_work += control_frame.net_work_j
    total_abs_work += control_frame.total_absolute_work_j
    if index == 0 {
      joint_count_per_frame = control_frame.joint_count
      hinge_joint_count_per_frame = control_frame.hinge_joint_frame.joint_count
    }
    frames.push(control_frame)
  }
  {
    report_id: "moonrobo/noetix-e1/joint-control/\{trace.terrain_tile_id}",
    trace_id: trace.trace_id,
    profile,
    frame_count: frames.length(),
    joint_count_per_frame,
    saturated_frame_count,
    limit_review_frame_count,
    hinge_joint_frame_count: frames.length(),
    hinge_review_frame_count,
    hinge_joint_count_per_frame,
    hinge_motor_driven_frame_count,
    hinge_motor_driven_joint_count,
    hinge_motor_trace,
    hinge_motor_world_trace,
    max_abs_position_error_rad: max_position_error,
    max_abs_velocity_rad_s: max_velocity,
    max_abs_mechanical_power_w: max_power,
    max_hinge_position_error_m: max_hinge_position_error,
    max_hinge_angular_error_rad: max_hinge_angular_error,
    max_hinge_motor_angle_delta_rad: max_hinge_motor_angle_delta,
    max_hinge_motor_velocity_delta_rad_s: max_hinge_motor_velocity_delta,
    hinge_linear_impulse_ns: hinge_linear_impulse,
    hinge_angular_impulse_nms: hinge_angular_impulse,
    net_work_j: net_work,
    total_absolute_work_j: total_abs_work,
    frames,
    hardware_authority: profile.hardware_authority,
    status: if limit_review_frame_count > 0 {
      "joint-control-limit-review"
    } else if saturated_frame_count > 0 {
      "joint-control-torque-review"
    } else {
      "joint-control-assumption-review"
    },
    note: "Joint-control evidence replays Noetix joint phases, including URDF walk clip phases, through Moonphys velocity-limited joint command shaping, joint-frame motor integration, servo, torque, velocity, position limits, and power/work accounting. Each frame also projects the URDF link graph through Moonphys hinge-joint frame assessment, world hinge constraint replay, world hinge motor replay, a sequential world hinge motor trace, and target-driven hinge motor heightfield world replay for generic body/joint/contact constraint evidence. It remains review evidence only because servo gains, joint inertias, and link inertias are assumptions.",
  }
}

///|
pub fn first_trusted_square_noetix_joint_control_report() -> NoetixJointControlReport {
  noetix_joint_control_report(first_trusted_square_noetix_walk_trace())
}

///|
pub fn first_trusted_square_noetix_joint_control_json() -> Json {
  first_trusted_square_noetix_joint_control_report().to_json()
}

///|
pub fn render_noetix_joint_control_markdown(
  report : NoetixJointControlReport,
) -> String {
  let mut text = "# Noetix Joint Control Evidence\n\n"
  text += "- report: \{report.report_id}\n"
  text += "- trace: \{report.trace_id}\n"
  text += "- profile: \{report.profile.profile_id}\n"
  text += "- frames: \{report.frame_count}\n"
  text += "- joints per frame: \{report.joint_count_per_frame}\n"
  text += "- saturated frames: \{report.saturated_frame_count}\n"
  text += "- limit-review frames: \{report.limit_review_frame_count}\n"
  text += "- hinge-joint frames: \{report.hinge_joint_frame_count}\n"
  text += "- hinge joints per frame: \{report.hinge_joint_count_per_frame}\n"
  text += "- hinge-review frames: \{report.hinge_review_frame_count}\n"
  text += "- hinge motor-driven frames: \{report.hinge_motor_driven_frame_count}\n"
  text += "- hinge motor-driven joints: \{report.hinge_motor_driven_joint_count}\n"
  text += "- hinge motor trace frames: \{report.hinge_motor_trace.frame_count}\n"
  text += "- hinge motor trace driven joints: \{report.hinge_motor_trace.driven_joint_count}\n"
  text += "- hinge motor trace status: \{report.hinge_motor_trace.status}\n"
  text += "- hinge motor world trace frames: \{report.hinge_motor_world_trace.frame_count}\n"
  text += "- hinge motor world trace body-target frames: \{report.hinge_motor_world_trace.body_target_frame_count}\n"
  text += "- hinge motor world trace body targets: \{report.hinge_motor_world_trace.body_target_count}\n"
  text += "- hinge motor world trace support-target frames: \{report.hinge_motor_world_trace.support_target_frame_count}\n"
  text += "- hinge motor world trace support targets: \{report.hinge_motor_world_trace.support_target_count}\n"
  text += "- hinge motor world trace center-of-mass-target frames: \{report.hinge_motor_world_trace.center_of_mass_target_frame_count}\n"
  text += "- hinge motor world trace contacts: \{report.hinge_motor_world_trace.contact_count}\n"
  text += "- hinge motor world trace support contacts: \{report.hinge_motor_world_trace.support_contact_count}\n"
  text += "- hinge motor world trace stable support frames: \{report.hinge_motor_world_trace.stable_support_frame_count}\n"
  text += "- hinge motor world trace support-review frames: \{report.hinge_motor_world_trace.support_review_frame_count}\n"
  text += "- hinge motor world trace capture-stable support frames: \{report.hinge_motor_world_trace.capture_stable_support_frame_count}\n"
  text += "- hinge motor world trace capture-review support frames: \{report.hinge_motor_world_trace.capture_support_review_frame_count}\n"
  text += "- hinge motor world trace resolved hinges: \{report.hinge_motor_world_trace.resolved_hinge_constraint_count}\n"
  text += "- hinge motor world trace body samples: \{report.hinge_motor_world_trace.body_sample_count}\n"
  text += "- hinge motor world trace max speed: \{report.hinge_motor_world_trace.max_speed_mps} m/s\n"
  text += "- hinge motor world trace max kinetic energy: \{report.hinge_motor_world_trace.max_kinetic_energy_j} J\n"
  text += "- hinge motor world trace total mass: \{report.hinge_motor_world_trace.total_mass_kg} kg\n"
  text += "- hinge motor world trace center of mass x: \{report.hinge_motor_world_trace.final_center_of_mass.x} m\n"
  text += "- hinge motor world trace max center-of-mass speed: \{report.hinge_motor_world_trace.max_center_of_mass_speed_mps} m/s\n"
  text += "- hinge motor world trace min support margin: \{report.hinge_motor_world_trace.min_support_margin_m} m\n"
  text += "- hinge motor world trace max support recovery shift: \{report.hinge_motor_world_trace.max_support_recovery_shift_m} m\n"
  text += "- hinge motor world trace worst capture support margin: \{report.hinge_motor_world_trace.worst_capture_support_margin_m} m\n"
  text += "- hinge motor world trace max capture recovery shift: \{report.hinge_motor_world_trace.max_capture_recovery_shift_m} m\n"
  text += "- hinge motor world trace max center-of-pressure error: \{report.hinge_motor_world_trace.max_center_of_pressure_error_m} m\n"
  text += "- hinge motor world trace max body momentum: \{report.hinge_motor_world_trace.max_body_linear_momentum_kg_mps} kg*m/s\n"
  text += "- hinge motor world trace max world momentum: \{report.hinge_motor_world_trace.max_world_linear_momentum_kg_mps} kg*m/s\n"
  text += "- hinge motor world trace max frame energy delta: \{report.hinge_motor_world_trace.max_frame_kinetic_energy_delta_j} J\n"
  text += "- hinge motor world trace envelope: \{report.hinge_motor_world_trace.envelope_status}\n"
  text += "- hinge motor world trace review: \{report.hinge_motor_world_trace.world_review_status}\n"
  text += "- hinge motor world trace review blockers: \{report.hinge_motor_world_trace.world_review_blocker_count}\n"
  text += "- hinge motor world trace status: \{report.hinge_motor_world_trace.status}\n"
  text += "- max position error: \{report.max_abs_position_error_rad} rad\n"
  text += "- max target velocity: \{report.max_abs_velocity_rad_s} rad/s\n"
  text += "- max mechanical power: \{report.max_abs_mechanical_power_w} W\n"
  text += "- max hinge position error: \{report.max_hinge_position_error_m} m\n"
  text += "- max hinge angular error: \{report.max_hinge_angular_error_rad} rad\n"
  text += "- max hinge motor angle delta: \{report.max_hinge_motor_angle_delta_rad} rad\n"
  text += "- max hinge motor velocity delta: \{report.max_hinge_motor_velocity_delta_rad_s} rad/s\n"
  text += "- hinge linear impulse: \{report.hinge_linear_impulse_ns} Ns\n"
  text += "- hinge angular impulse: \{report.hinge_angular_impulse_nms} Nms\n"
  text += "- net joint work: \{report.net_work_j} J\n"
  text += "- absolute joint work: \{report.total_absolute_work_j} J\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Frame Joint Control\n\n"
  for frame in report.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s joints=\{frame.joint_count} saturated=\{frame.saturated_joint_count} limit_review=\{frame.limit_review_count} hinge_joints=\{frame.hinge_joint_frame.joint_count} hinge_motor_driven=\{frame.hinge_joint_frame.motor_driven_joint_count} hinge_status=\{frame.hinge_joint_frame.status} hinge_motor_status=\{frame.hinge_joint_frame.motor_status} max_power=\{frame.max_abs_mechanical_power_w}W abs_work=\{frame.total_absolute_work_j}J status=\{frame.status}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_joint_control_markdown() -> String {
  render_noetix_joint_control_markdown(
    first_trusted_square_noetix_joint_control_report(),
  )
}
