///|
pub(all) struct RigidBodyMotionState {
  body_id : String
  linear : RigidBodyState
  angular : RigidBodyAngularState
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWrench {
  force_n : Vec3
  torque_nm : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWrenchStep {
  before : RigidBodyMotionState
  wrench : RigidBodyWrench
  dt_s : Double
  linear_acceleration_mps2 : Vec3
  angular_acceleration_rad_s2 : Vec3
  linear_impulse_ns : Vec3
  angular_impulse_nms : Vec3
  kinetic_energy_before_j : Double
  kinetic_energy_after_j : Double
  kinetic_energy_delta_j : Double
  after : RigidBodyMotionState
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_motion_state(
  body_id : String,
  mass_kg : Double,
  collision_radius_m : Double,
  position : Vec3,
  velocity : Vec3,
  orientation : Basis3,
  angular_velocity_rad_s : Vec3,
) -> RigidBodyMotionState {
  {
    body_id,
    linear: rigid_body_state(
      body_id, mass_kg, collision_radius_m, position, velocity,
    ),
    angular: rigid_body_angular_state(
      body_id, orientation, angular_velocity_rad_s,
    ),
  }
}

///|
pub fn rigid_body_wrench(force_n : Vec3, torque_nm : Vec3) -> RigidBodyWrench {
  { force_n, torque_nm }
}

///|
fn safe_linear_acceleration(force_n : Vec3, mass_kg : Double) -> Vec3 {
  if mass_kg > 0.0 {
    force_n.scale(1.0 / mass_kg)
  } else {
    vec3(0.0, 0.0, 0.0)
  }
}

///|
fn rigid_body_wrench_step_status(state : RigidBodyMotionState) -> String {
  if state.linear.mass_kg <= 0.0 {
    "wrench-zero-mass-review"
  } else {
    "wrench-integrated"
  }
}

///|
fn linear_kinetic_energy(state : RigidBodyState) -> Double {
  rigid_body_linear_kinetic_energy(state)
}

///|
fn angular_kinetic_energy(
  state : RigidBodyAngularState,
  inertia : RigidBodyInertia,
) -> Double {
  0.5 * state.angular_velocity_rad_s.dot(angular_momentum(inertia, state))
}

///|
fn motion_kinetic_energy(
  state : RigidBodyMotionState,
  inertia : RigidBodyInertia,
) -> Double {
  linear_kinetic_energy(state.linear) +
  angular_kinetic_energy(state.angular, inertia)
}

///|
pub fn integrate_rigid_body_wrench(
  state : RigidBodyMotionState,
  inertia : RigidBodyInertia,
  wrench : RigidBodyWrench,
  dt_s : Double,
) -> RigidBodyWrenchStep {
  let linear_acceleration = safe_linear_acceleration(
    wrench.force_n,
    state.linear.mass_kg,
  )
  let angular_accel = angular_acceleration(inertia, wrench.torque_nm)
  let linear_after = integrate_rigid_body(
    state.linear,
    dt_s,
    linear_acceleration,
  )
  let angular_after = integrate_angular_rigid_body(state.angular, inertia, {
    dt_s,
    torque_nm: wrench.torque_nm,
  })
  let after = {
    body_id: state.body_id,
    linear: linear_after,
    angular: angular_after,
  }
  let energy_before = motion_kinetic_energy(state, inertia)
  let energy_after = motion_kinetic_energy(after, inertia)
  {
    before: state,
    wrench,
    dt_s,
    linear_acceleration_mps2: linear_acceleration,
    angular_acceleration_rad_s2: angular_accel,
    linear_impulse_ns: wrench.force_n.scale(dt_s),
    angular_impulse_nms: wrench.torque_nm.scale(dt_s),
    kinetic_energy_before_j: energy_before,
    kinetic_energy_after_j: energy_after,
    kinetic_energy_delta_j: energy_after - energy_before,
    after,
    status: rigid_body_wrench_step_status(state),
  }
}
