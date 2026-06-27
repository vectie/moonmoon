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
pub(all) struct RigidBodyHingeAxisCorrection {
  assessment : RigidBodyHingeAxisAssessment
  inertia_a : RigidBodyInertia
  inertia_b : RigidBodyInertia
  inverse_inertia_a : Double
  inverse_inertia_b : Double
  correction_a_rad : Vec3
  correction_b_rad : Vec3
  velocity_delta_a_rad_s : Vec3
  velocity_delta_b_rad_s : Vec3
  angular_impulse_nms : Double
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

///|
fn hinge_axis_inertia(inertia : RigidBodyInertia, axis : Vec3) -> Double {
  let a = normalized_axis(axis)
  a.x * a.x * inertia.diagonal_kg_m2.x +
  a.y * a.y * inertia.diagonal_kg_m2.y +
  a.z * a.z * inertia.diagonal_kg_m2.z
}

///|
fn hinge_inverse_inertia(inertia : RigidBodyInertia, axis : Vec3) -> Double {
  let value = hinge_axis_inertia(inertia, axis)
  if value > 0.0 {
    1.0 / value
  } else {
    0.0
  }
}

///|
fn hinge_axis_correction_status(
  assessment : RigidBodyHingeAxisAssessment,
  inverse_inertia_sum : Double,
) -> String {
  if assessment.status == "hinge-axis-body-mismatch-review" {
    "hinge-correction-body-mismatch-review"
  } else if inverse_inertia_sum <= 0.0 {
    "hinge-correction-static-review"
  } else if assessment.angular_error_rad > 0.000001 ||
    hinge_abs(assessment.relative_axis_velocity_rad_s) > 0.000001 {
    "hinge-correction-estimated"
  } else {
    "hinge-correction-satisfied"
  }
}

///|
pub fn rigid_body_hinge_axis_correction(
  constraint : RigidBodyHingeAxisConstraint,
  state_a : RigidBodyAngularState,
  inertia_a : RigidBodyInertia,
  state_b : RigidBodyAngularState,
  inertia_b : RigidBodyInertia,
) -> RigidBodyHingeAxisCorrection {
  let assessment = rigid_body_hinge_axis_assessment(
    constraint, state_a, state_b,
  )
  let axis = if assessment.correction_axis.length_squared() > 0.0 {
    assessment.correction_axis
  } else {
    normalized_axis(assessment.world_axis_a)
  }
  let inverse_inertia_a = hinge_inverse_inertia(inertia_a, axis)
  let inverse_inertia_b = hinge_inverse_inertia(inertia_b, axis)
  let inverse_inertia_sum = inverse_inertia_a + inverse_inertia_b
  let correction_mag_a = if inverse_inertia_sum > 0.0 {
    assessment.correction_angle_rad * inverse_inertia_a / inverse_inertia_sum
  } else {
    0.0
  }
  let correction_mag_b = if inverse_inertia_sum > 0.0 {
    assessment.correction_angle_rad * inverse_inertia_b / inverse_inertia_sum
  } else {
    0.0
  }
  let angular_impulse = if inverse_inertia_sum > 0.0 {
    hinge_abs(assessment.relative_axis_velocity_rad_s) / inverse_inertia_sum
  } else {
    0.0
  }
  let velocity_delta_a = if inverse_inertia_sum > 0.0 {
    assessment.world_axis_a.scale(
      assessment.relative_axis_velocity_rad_s *
      inverse_inertia_a /
      inverse_inertia_sum,
    )
  } else {
    vec3(0.0, 0.0, 0.0)
  }
  let velocity_delta_b = if inverse_inertia_sum > 0.0 {
    assessment.world_axis_a.scale(
      0.0 -
      assessment.relative_axis_velocity_rad_s *
      inverse_inertia_b /
      inverse_inertia_sum,
    )
  } else {
    vec3(0.0, 0.0, 0.0)
  }
  {
    assessment,
    inertia_a,
    inertia_b,
    inverse_inertia_a,
    inverse_inertia_b,
    correction_a_rad: axis.scale(correction_mag_a),
    correction_b_rad: axis.scale(0.0 - correction_mag_b),
    velocity_delta_a_rad_s: velocity_delta_a,
    velocity_delta_b_rad_s: velocity_delta_b,
    angular_impulse_nms: angular_impulse,
    status: hinge_axis_correction_status(assessment, inverse_inertia_sum),
  }
}
