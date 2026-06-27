///|
pub(all) struct RigidBodyHingeAxisConstraint {
  constraint_id : String
  body_a_id : String
  body_b_id : String
  local_axis_a : Vec3
  local_axis_b : Vec3
  stiffness : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyHingeAxisAssessment {
  constraint_id : String
  body_a_id : String
  body_b_id : String
  local_axis_a : Vec3
  local_axis_b : Vec3
  world_axis_a : Vec3
  world_axis_b : Vec3
  alignment_dot : Double
  angular_error_rad : Double
  relative_axis_velocity_rad_s : Double
  correction_axis : Vec3
  correction_angle_rad : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_hinge_axis_constraint(
  constraint_id : String,
  body_a_id : String,
  body_b_id : String,
  local_axis_a? : Vec3 = vec3(0.0, 0.0, 1.0),
  local_axis_b? : Vec3 = vec3(0.0, 0.0, 1.0),
  stiffness? : Double = 1.0,
) -> RigidBodyHingeAxisConstraint {
  {
    constraint_id,
    body_a_id,
    body_b_id,
    local_axis_a: normalized_axis(local_axis_a),
    local_axis_b: normalized_axis(local_axis_b),
    stiffness: clamp_unit(stiffness),
  }
}

///|
fn clamp_signed_unit(value : Double) -> Double {
  if value < -1.0 {
    -1.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn hinge_abs(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn hinge_axis_status(
  body_matches : Bool,
  angular_error_rad : Double,
  relative_axis_velocity_rad_s : Double,
) -> String {
  if !body_matches {
    "hinge-axis-body-mismatch-review"
  } else if angular_error_rad > 0.000001 {
    "hinge-axis-misaligned"
  } else if hinge_abs(relative_axis_velocity_rad_s) > 0.000001 {
    "hinge-axis-spinning"
  } else {
    "hinge-axis-aligned"
  }
}

///|
pub fn rigid_body_hinge_axis_assessment(
  constraint : RigidBodyHingeAxisConstraint,
  state_a : RigidBodyAngularState,
  state_b : RigidBodyAngularState,
) -> RigidBodyHingeAxisAssessment {
  let world_axis_a = normalized_axis(
    state_a.orientation.mul_vec3(constraint.local_axis_a),
  )
  let raw_world_axis_b = normalized_axis(
    state_b.orientation.mul_vec3(constraint.local_axis_b),
  )
  let signed_dot = clamp_signed_unit(world_axis_a.dot(raw_world_axis_b))
  let world_axis_b = if signed_dot < 0.0 {
    raw_world_axis_b.scale(-1.0)
  } else {
    raw_world_axis_b
  }
  let alignment_dot = clamp_signed_unit(world_axis_a.dot(world_axis_b))
  let angular_error = @math.acos(alignment_dot)
  let correction_raw = world_axis_a.cross(world_axis_b)
  let correction_axis = if correction_raw.length_squared() > 0.0 {
    normalized_axis(correction_raw)
  } else {
    vec3(0.0, 0.0, 0.0)
  }
  let average_axis = normalized_axis(world_axis_a.add(world_axis_b))
  let relative_axis_velocity = state_b.angular_velocity_rad_s
    .sub(state_a.angular_velocity_rad_s)
    .dot(average_axis)
  let body_matches = state_a.body_id == constraint.body_a_id &&
    state_b.body_id == constraint.body_b_id
  {
    constraint_id: constraint.constraint_id,
    body_a_id: constraint.body_a_id,
    body_b_id: constraint.body_b_id,
    local_axis_a: constraint.local_axis_a,
    local_axis_b: constraint.local_axis_b,
    world_axis_a,
    world_axis_b,
    alignment_dot,
    angular_error_rad: angular_error,
    relative_axis_velocity_rad_s: relative_axis_velocity,
    correction_axis,
    correction_angle_rad: angular_error * constraint.stiffness,
    status: hinge_axis_status(
      body_matches, angular_error, relative_axis_velocity,
    ),
  }
}
