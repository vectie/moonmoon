///|
pub(all) struct RigidBodyInertia {
  body_id : String
  diagonal_kg_m2 : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyAngularState {
  body_id : String
  orientation : Basis3
  angular_velocity_rad_s : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyAngularStep {
  dt_s : Double
  torque_nm : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_inertia(
  body_id : String,
  diagonal_kg_m2 : Vec3,
) -> RigidBodyInertia {
  { body_id, diagonal_kg_m2 }
}

///|
pub fn rigid_body_angular_state(
  body_id : String,
  orientation : Basis3,
  angular_velocity_rad_s : Vec3,
) -> RigidBodyAngularState {
  { body_id, orientation, angular_velocity_rad_s }
}

///|
fn safe_axis_acceleration(torque : Double, inertia : Double) -> Double {
  if inertia > 0.0 {
    torque / inertia
  } else {
    0.0
  }
}

///|
pub fn angular_acceleration(
  inertia : RigidBodyInertia,
  torque_nm : Vec3,
) -> Vec3 {
  vec3(
    safe_axis_acceleration(torque_nm.x, inertia.diagonal_kg_m2.x),
    safe_axis_acceleration(torque_nm.y, inertia.diagonal_kg_m2.y),
    safe_axis_acceleration(torque_nm.z, inertia.diagonal_kg_m2.z),
  )
}

///|
pub fn angular_momentum(
  inertia : RigidBodyInertia,
  state : RigidBodyAngularState,
) -> Vec3 {
  vec3(
    inertia.diagonal_kg_m2.x * state.angular_velocity_rad_s.x,
    inertia.diagonal_kg_m2.y * state.angular_velocity_rad_s.y,
    inertia.diagonal_kg_m2.z * state.angular_velocity_rad_s.z,
  )
}

///|
pub fn contact_torque(
  center_of_mass : Vec3,
  application_point : Vec3,
  force_n : Vec3,
) -> Vec3 {
  application_point.sub(center_of_mass).cross(force_n)
}

///|
fn integrate_orientation(
  orientation : Basis3,
  angular_velocity : Vec3,
  dt_s : Double,
) -> Basis3 {
  let speed = angular_velocity.length_squared().sqrt()
  if speed <= 0.0 || dt_s <= 0.0 {
    orientation
  } else {
    orientation.mul_basis3(axis_angle_basis3(angular_velocity, speed * dt_s))
  }
}

///|
pub fn integrate_angular_rigid_body(
  state : RigidBodyAngularState,
  inertia : RigidBodyInertia,
  step : RigidBodyAngularStep,
) -> RigidBodyAngularState {
  let velocity = state.angular_velocity_rad_s.add(
    angular_acceleration(inertia, step.torque_nm).scale(step.dt_s),
  )
  {
    body_id: state.body_id,
    orientation: integrate_orientation(state.orientation, velocity, step.dt_s),
    angular_velocity_rad_s: velocity,
  }
}
