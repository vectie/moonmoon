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
  {
    before: state,
    after,
    servo,
    limit,
    dt_s,
    inertia_kg_m2,
    status: if hit_limit {
      "position-limit"
    } else {
      servo.status
    },
  }
}
