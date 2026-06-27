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
  steps : Array[NoetixJointControlStep]
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
  max_abs_position_error_rad : Double
  max_abs_velocity_rad_s : Double
  max_abs_mechanical_power_w : Double
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
fn within_limit(value : Double, min_value : Double, max_value : Double) -> Bool {
  value >= min_value && value <= max_value
}

///|
fn joint_step_status(
  motor_step : @moonphys.JointMotorStep,
  position_within_limits : Bool,
  velocity_within_limits : Bool,
) -> String {
  if !position_within_limits || !velocity_within_limits {
    "joint-limit-review"
  } else if motor_step.servo.saturated {
    "joint-torque-review"
  } else {
    "joint-command-review"
  }
}

///|
fn noetix_joint_control_step(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  phase : NoetixJointPhase,
  profile : NoetixPhysicsProfile,
) -> NoetixJointControlStep {
  let previous = previous_frame(trace, frame_index)
  let dt = frame_dt_s(trace, frame_index)
  let actuator = actuator_profile_for(profile, phase.joint_name)
  let previous_position = phase_position(previous, phase.joint_name)
  let target_velocity = if dt > 0.0 {
    (phase.position_rad - previous_position) / dt
  } else {
    0.0
  }
  let motor_step = @moonphys.integrate_joint_motor(
    @moonphys.joint_motor_state(phase.joint_name, previous_position, 0.0),
    @moonphys.joint_motor_command(
      phase.joint_name,
      phase.position_rad,
      target_velocity,
      0.0,
    ),
    actuator.servo,
    actuator.limit,
    actuator.inertia_kg_m2,
    dt,
  )
  let position_within_limits = within_limit(
    phase.position_rad,
    actuator.limit.min_position_rad,
    actuator.limit.max_position_rad,
  )
  let velocity_within_limits = abs_double(target_velocity) <=
    actuator.limit.max_velocity_rad_s
  let status = joint_step_status(
    motor_step, position_within_limits, velocity_within_limits,
  )
  {
    joint_name: phase.joint_name,
    joint_index: actuator.joint_index,
    target_position_rad: phase.position_rad,
    target_velocity_rad_s: target_velocity,
    motor_step,
    position_within_limits,
    velocity_within_limits,
    status,
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
  let steps : Array[NoetixJointControlStep] = []
  let mut saturated_count = 0
  let mut limit_review_count = 0
  let mut max_position_error = 0.0
  let mut max_velocity = 0.0
  let mut max_power = 0.0
  let mut net_work = 0.0
  let mut total_abs_work = 0.0
  for phase in frame.joint_phases {
    let step = noetix_joint_control_step(trace, frame_index, phase, profile)
    if step.motor_step.servo.saturated {
      saturated_count += 1
    }
    if !step.position_within_limits || !step.velocity_within_limits {
      limit_review_count += 1
    }
    let position_error = abs_double(
      step.motor_step.after.position_rad - step.target_position_rad,
    )
    if position_error > max_position_error {
      max_position_error = position_error
    }
    let velocity = abs_double(step.target_velocity_rad_s)
    if velocity > max_velocity {
      max_velocity = velocity
    }
    let power = abs_double(step.motor_step.average_mechanical_power_w)
    if power > max_power {
      max_power = power
    }
    net_work += step.motor_step.work_j
    total_abs_work += step.motor_step.absolute_work_j
    steps.push(step)
  }
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    joint_count: steps.length(),
    saturated_joint_count: saturated_count,
    limit_review_count,
    max_abs_position_error_rad: max_position_error,
    max_abs_velocity_rad_s: max_velocity,
    max_abs_mechanical_power_w: max_power,
    net_work_j: net_work,
    total_absolute_work_j: total_abs_work,
    steps,
    status: joint_control_frame_status(saturated_count, limit_review_count),
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
  let mut max_position_error = 0.0
  let mut max_velocity = 0.0
  let mut max_power = 0.0
  let mut net_work = 0.0
  let mut total_abs_work = 0.0
  let mut joint_count_per_frame = 0
  for index, _frame in trace.frames {
    let control_frame = noetix_joint_control_frame(trace, index, profile)
    if control_frame.saturated_joint_count > 0 {
      saturated_frame_count += 1
    }
    if control_frame.limit_review_count > 0 {
      limit_review_frame_count += 1
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
    net_work += control_frame.net_work_j
    total_abs_work += control_frame.total_absolute_work_j
    if index == 0 {
      joint_count_per_frame = control_frame.joint_count
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
    max_abs_position_error_rad: max_position_error,
    max_abs_velocity_rad_s: max_velocity,
    max_abs_mechanical_power_w: max_power,
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
    note: "Joint-control evidence replays kinematic Noetix joint phases through Moonphys servo, torque, velocity, and position limits. It remains review evidence only because servo gains and joint inertias are assumptions.",
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
  text += "- max position error: \{report.max_abs_position_error_rad} rad\n"
  text += "- max target velocity: \{report.max_abs_velocity_rad_s} rad/s\n"
  text += "- max mechanical power: \{report.max_abs_mechanical_power_w} W\n"
  text += "- net joint work: \{report.net_work_j} J\n"
  text += "- absolute joint work: \{report.total_absolute_work_j} J\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Frame Joint Control\n\n"
  for frame in report.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s joints=\{frame.joint_count} saturated=\{frame.saturated_joint_count} limit_review=\{frame.limit_review_count} max_power=\{frame.max_abs_mechanical_power_w}W abs_work=\{frame.total_absolute_work_j}J status=\{frame.status}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_joint_control_markdown() -> String {
  render_noetix_joint_control_markdown(
    first_trusted_square_noetix_joint_control_report(),
  )
}
