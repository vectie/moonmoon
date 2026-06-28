///|
pub(all) struct JointLimit {
  joint_id : String
  min_position_rad : Double
  max_position_rad : Double
  max_velocity_rad_s : Double
  max_torque_nm : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointMotorState {
  joint_id : String
  position_rad : Double
  velocity_rad_s : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointMotorCommand {
  joint_id : String
  target_position_rad : Double
  target_velocity_rad_s : Double
  feedforward_torque_nm : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointVelocityLimitedCommand {
  command : JointMotorCommand
  desired_position_rad : Double
  desired_velocity_rad_s : Double
  desired_delta_rad : Double
  applied_delta_rad : Double
  velocity_limited : Bool
  position_limited : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointServoConfig {
  joint_id : String
  stiffness_nm_per_rad : Double
  damping_nm_s_per_rad : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointServoOutput {
  joint_id : String
  position_error_rad : Double
  velocity_error_rad_s : Double
  commanded_torque_nm : Double
  saturated : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointMotorStep {
  before : JointMotorState
  after : JointMotorState
  servo : JointServoOutput
  limit : JointLimit
  dt_s : Double
  inertia_kg_m2 : Double
  average_mechanical_power_w : Double
  work_j : Double
  absolute_work_j : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointMotorFrameStep {
  command : JointMotorCommand
  motor_step : JointMotorStep
  position_within_limits : Bool
  velocity_within_limits : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct JointMotorFrame {
  frame_id : String
  dt_s : Double
  joint_count : Int
  saturated_joint_count : Int
  limit_review_count : Int
  max_abs_position_error_rad : Double
  max_abs_velocity_rad_s : Double
  max_abs_commanded_torque_nm : Double
  max_abs_mechanical_power_w : Double
  net_work_j : Double
  total_absolute_work_j : Double
  steps : Array[JointMotorFrameStep]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn joint_limit(
  joint_id : String,
  min_position_rad : Double,
  max_position_rad : Double,
  max_velocity_rad_s : Double,
  max_torque_nm : Double,
) -> JointLimit {
  {
    joint_id,
    min_position_rad,
    max_position_rad,
    max_velocity_rad_s: nonnegative_scalar(max_velocity_rad_s),
    max_torque_nm: nonnegative_scalar(max_torque_nm),
  }
}

///|
pub fn joint_motor_state(
  joint_id : String,
  position_rad : Double,
  velocity_rad_s : Double,
) -> JointMotorState {
  { joint_id, position_rad, velocity_rad_s }
}

///|
pub fn joint_motor_command(
  joint_id : String,
  target_position_rad : Double,
  target_velocity_rad_s : Double,
  feedforward_torque_nm : Double,
) -> JointMotorCommand {
  {
    joint_id,
    target_position_rad,
    target_velocity_rad_s,
    feedforward_torque_nm,
  }
}

///|
fn positive_dt(value : Double) -> Double {
  if value > 0.0 {
    value
  } else {
    0.0
  }
}

///|
fn velocity_limited_command_status(
  velocity_limited : Bool,
  position_limited : Bool,
) -> String {
  if velocity_limited && position_limited {
    "joint-command-velocity-and-position-limited"
  } else if velocity_limited {
    "joint-command-velocity-limited"
  } else if position_limited {
    "joint-command-position-limited"
  } else {
    "joint-command-within-limits"
  }
}

///|
pub fn joint_velocity_limited_command(
  state : JointMotorState,
  desired_position_rad : Double,
  desired_velocity_rad_s : Double,
  feedforward_torque_nm : Double,
  limit : JointLimit,
  dt_s : Double,
) -> JointVelocityLimitedCommand {
  let dt = positive_dt(dt_s)
  let desired_delta = desired_position_rad - state.position_rad
  let max_delta = limit.max_velocity_rad_s * dt
  let velocity_delta = if dt > 0.0 {
    symmetric_clamp(desired_delta, max_delta)
  } else {
    0.0
  }
  let velocity_limited_by_delta = velocity_delta != desired_delta
  let unclamped_position = state.position_rad + velocity_delta
  let target_position = clamp_scalar(
    unclamped_position,
    limit.min_position_rad,
    limit.max_position_rad,
  )
  let applied_delta = target_position - state.position_rad
  let position_limited = target_position != unclamped_position
  let target_velocity = if dt > 0.0 {
    applied_delta / dt
  } else {
    symmetric_clamp(desired_velocity_rad_s, limit.max_velocity_rad_s)
  }
  let clamped_velocity = symmetric_clamp(
    target_velocity,
    limit.max_velocity_rad_s,
  )
  let velocity_limited = velocity_limited_by_delta ||
    clamped_velocity != target_velocity
  {
    command: joint_motor_command(
      state.joint_id,
      target_position,
      clamped_velocity,
      feedforward_torque_nm,
    ),
    desired_position_rad,
    desired_velocity_rad_s,
    desired_delta_rad: desired_delta,
    applied_delta_rad: applied_delta,
    velocity_limited,
    position_limited,
    status: velocity_limited_command_status(velocity_limited, position_limited),
  }
}

///|
pub fn joint_servo_config(
  joint_id : String,
  stiffness_nm_per_rad : Double,
  damping_nm_s_per_rad : Double,
) -> JointServoConfig {
  {
    joint_id,
    stiffness_nm_per_rad: nonnegative_scalar(stiffness_nm_per_rad),
    damping_nm_s_per_rad: nonnegative_scalar(damping_nm_s_per_rad),
  }
}

///|
fn nonnegative_scalar(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else {
    value
  }
}

///|
fn clamp_scalar(
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
fn symmetric_clamp(value : Double, magnitude : Double) -> Double {
  clamp_scalar(value, 0.0 - magnitude, magnitude)
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn joint_command_within_limits(
  command : JointMotorCommand,
  limit : JointLimit,
) -> Bool {
  command.target_position_rad >= limit.min_position_rad &&
  command.target_position_rad <= limit.max_position_rad
}

///|
fn joint_command_velocity_within_limits(
  command : JointMotorCommand,
  limit : JointLimit,
) -> Bool {
  abs_double(command.target_velocity_rad_s) <= limit.max_velocity_rad_s
}

///|
fn joint_motor_frame_step_status(
  motor_step : JointMotorStep,
  position_within_limits : Bool,
  velocity_within_limits : Bool,
) -> String {
  if !position_within_limits || !velocity_within_limits {
    "joint-limit-review"
  } else if motor_step.servo.saturated {
    "joint-torque-review"
  } else {
    "joint-commanded"
  }
}

///|
fn joint_motor_frame_status(
  expected_count : Int,
  actual_count : Int,
  limit_review_count : Int,
  saturated_joint_count : Int,
) -> String {
  if actual_count != expected_count {
    "joint-frame-input-review"
  } else if limit_review_count > 0 {
    "joint-frame-limit-review"
  } else if saturated_joint_count > 0 {
    "joint-frame-torque-review"
  } else {
    "joint-frame-commanded"
  }
}

///|
pub fn joint_servo_output(
  state : JointMotorState,
  command : JointMotorCommand,
  config : JointServoConfig,
  limit : JointLimit,
) -> JointServoOutput {
  let position_error = command.target_position_rad - state.position_rad
  let velocity_error = command.target_velocity_rad_s - state.velocity_rad_s
  let raw_torque = config.stiffness_nm_per_rad * position_error +
    config.damping_nm_s_per_rad * velocity_error +
    command.feedforward_torque_nm
  let commanded = symmetric_clamp(raw_torque, limit.max_torque_nm)
  let saturated = commanded != raw_torque
  {
    joint_id: state.joint_id,
    position_error_rad: position_error,
    velocity_error_rad_s: velocity_error,
    commanded_torque_nm: commanded,
    saturated,
    status: if saturated {
      "torque-saturated"
    } else {
      "torque-commanded"
    },
  }
}

///|
pub fn integrate_joint_motor_frame(
  frame_id : String,
  states : Array[JointMotorState],
  commands : Array[JointMotorCommand],
  configs : Array[JointServoConfig],
  limits : Array[JointLimit],
  inertias_kg_m2 : Array[Double],
  dt_s : Double,
) -> JointMotorFrame {
  let count = min_int(
    min_int(states.length(), commands.length()),
    min_int(min_int(configs.length(), limits.length()), inertias_kg_m2.length()),
  )
  let expected_count = states.length()
  let steps : Array[JointMotorFrameStep] = []
  let mut saturated_count = 0
  let mut limit_review_count = 0
  let mut max_position_error = 0.0
  let mut max_velocity = 0.0
  let mut max_torque = 0.0
  let mut max_power = 0.0
  let mut net_work = 0.0
  let mut total_abs_work = 0.0
  for index in 0..<count {
    let command = commands[index]
    let limit = limits[index]
    let motor_step = integrate_joint_motor(
      states[index],
      command,
      configs[index],
      limit,
      inertias_kg_m2[index],
      dt_s,
    )
    let position_within_limits = joint_command_within_limits(command, limit)
    let velocity_within_limits = joint_command_velocity_within_limits(
      command, limit,
    )
    let status = joint_motor_frame_step_status(
      motor_step, position_within_limits, velocity_within_limits,
    )
    if motor_step.servo.saturated {
      saturated_count += 1
    }
    if !position_within_limits || !velocity_within_limits {
      limit_review_count += 1
    }
    let position_error = abs_double(
      motor_step.after.position_rad - command.target_position_rad,
    )
    if position_error > max_position_error {
      max_position_error = position_error
    }
    let velocity = abs_double(command.target_velocity_rad_s)
    if velocity > max_velocity {
      max_velocity = velocity
    }
    let torque = abs_double(motor_step.servo.commanded_torque_nm)
    if torque > max_torque {
      max_torque = torque
    }
    let power = abs_double(motor_step.average_mechanical_power_w)
    if power > max_power {
      max_power = power
    }
    net_work += motor_step.work_j
    total_abs_work += motor_step.absolute_work_j
    steps.push({
      command,
      motor_step,
      position_within_limits,
      velocity_within_limits,
      status,
    })
  }
  {
    frame_id,
    dt_s,
    joint_count: steps.length(),
    saturated_joint_count: saturated_count,
    limit_review_count,
    max_abs_position_error_rad: max_position_error,
    max_abs_velocity_rad_s: max_velocity,
    max_abs_commanded_torque_nm: max_torque,
    max_abs_mechanical_power_w: max_power,
    net_work_j: net_work,
    total_absolute_work_j: total_abs_work,
    steps,
    status: joint_motor_frame_status(
      expected_count, count, limit_review_count, saturated_count,
    ),
  }
}

///|
pub fn integrate_joint_motor(
  state : JointMotorState,
  command : JointMotorCommand,
  config : JointServoConfig,
  limit : JointLimit,
  inertia_kg_m2 : Double,
  dt_s : Double,
) -> JointMotorStep {
  let servo = joint_servo_output(state, command, config, limit)
  let acceleration = if inertia_kg_m2 > 0.0 {
    servo.commanded_torque_nm / inertia_kg_m2
  } else {
    0.0
  }
  let velocity = symmetric_clamp(
    state.velocity_rad_s + acceleration * dt_s,
    limit.max_velocity_rad_s,
  )
  let unclamped_position = state.position_rad + velocity * dt_s
  let position = clamp_scalar(
    unclamped_position,
    limit.min_position_rad,
    limit.max_position_rad,
  )
  let hit_limit = position != unclamped_position
  let after = {
    joint_id: state.joint_id,
    position_rad: position,
    velocity_rad_s: if hit_limit {
      0.0
    } else {
      velocity
    },
  }
  let displacement = after.position_rad - state.position_rad
  let work = servo.commanded_torque_nm * displacement
  let average_power = if dt_s > 0.0 { work / dt_s } else { 0.0 }
  {
    before: state,
    after,
    servo,
    limit,
    dt_s,
    inertia_kg_m2,
    average_mechanical_power_w: average_power,
    work_j: work,
    absolute_work_j: abs_double(work),
    status: if hit_limit {
      "position-limit"
    } else {
      servo.status
    },
  }
}
