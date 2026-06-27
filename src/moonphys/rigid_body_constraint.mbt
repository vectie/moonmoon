///|
pub(all) struct RigidBodyWorldDistanceConstraint {
  constraint_id : String
  body_a_id : String
  body_b_id : String
  anchor_a_m : Vec3
  anchor_b_m : Vec3
  rest_length_m : Double
  stiffness : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldConstraintResolution {
  constraint_id : String
  body_a_id : String
  body_b_id : String
  anchor_a_m : Vec3
  anchor_b_m : Vec3
  world_anchor_a : Vec3
  world_anchor_b : Vec3
  rest_length_m : Double
  current_length_m : Double
  error_m : Double
  before_a : RigidBodyState
  before_b : RigidBodyState
  after_a : RigidBodyState
  after_b : RigidBodyState
  correction_a : Vec3
  correction_b : Vec3
  velocity_delta_a : Vec3
  velocity_delta_b : Vec3
  impulse_ns : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldConstraintFrame {
  world_id : String
  constraint_count : Int
  resolved_constraint_count : Int
  max_error_m : Double
  impulse_ns : Double
  resolutions : Array[RigidBodyWorldConstraintResolution]
  before : RigidBodyHeightfieldWorld
  after : RigidBodyHeightfieldWorld
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_world_distance_constraint(
  constraint_id : String,
  body_a_id : String,
  body_b_id : String,
  rest_length_m : Double,
  anchor_a_m? : Vec3 = vec3(0.0, 0.0, 0.0),
  anchor_b_m? : Vec3 = vec3(0.0, 0.0, 0.0),
  stiffness? : Double = 1.0,
) -> RigidBodyWorldDistanceConstraint {
  {
    constraint_id,
    body_a_id,
    body_b_id,
    anchor_a_m,
    anchor_b_m,
    rest_length_m,
    stiffness: clamp_unit(stiffness),
  }
}

///|
fn absolute_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn rigid_body_world_constraint_status(
  index_a : Int,
  index_b : Int,
  inverse_mass_sum : Double,
  correction_length : Double,
  velocity_delta_length : Double,
) -> String {
  if index_a < 0 || index_b < 0 {
    "world-constraint-missing-body-review"
  } else if index_a == index_b {
    "world-constraint-same-body-review"
  } else if inverse_mass_sum <= 0.0 {
    "world-constraint-static-review"
  } else if correction_length > 0.0 || velocity_delta_length > 0.0 {
    "world-constraint-resolved"
  } else {
    "world-constraint-satisfied"
  }
}

///|
fn rigid_body_world_unresolved_constraint(
  constraint : RigidBodyWorldDistanceConstraint,
  body_a : RigidBodyWorldBody,
  body_b : RigidBodyWorldBody,
  world_anchor_a : Vec3,
  world_anchor_b : Vec3,
  current_length : Double,
  error : Double,
  status : String,
) -> RigidBodyWorldConstraintResolution {
  {
    constraint_id: constraint.constraint_id,
    body_a_id: constraint.body_a_id,
    body_b_id: constraint.body_b_id,
    anchor_a_m: constraint.anchor_a_m,
    anchor_b_m: constraint.anchor_b_m,
    world_anchor_a,
    world_anchor_b,
    rest_length_m: constraint.rest_length_m,
    current_length_m: current_length,
    error_m: error,
    before_a: body_a.state,
    before_b: body_b.state,
    after_a: body_a.state,
    after_b: body_b.state,
    correction_a: vec3(0.0, 0.0, 0.0),
    correction_b: vec3(0.0, 0.0, 0.0),
    velocity_delta_a: vec3(0.0, 0.0, 0.0),
    velocity_delta_b: vec3(0.0, 0.0, 0.0),
    impulse_ns: 0.0,
    status,
  }
}

///|
fn rigid_body_world_distance_constraint_resolution(
  constraint : RigidBodyWorldDistanceConstraint,
  bodies : Array[RigidBodyWorldBody],
) -> RigidBodyWorldConstraintResolution {
  let index_a = rigid_body_world_body_array_find_index(
    bodies,
    constraint.body_a_id,
  )
  let index_b = rigid_body_world_body_array_find_index(
    bodies,
    constraint.body_b_id,
  )
  let fallback = if bodies.length() > 0 {
    bodies[0]
  } else {
    rigid_body_world_body(
      rigid_body_state("", 0.0, 0.0, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0)),
    )
  }
  let body_a = if index_a >= 0 { bodies[index_a] } else { fallback }
  let body_b = if index_b >= 0 { bodies[index_b] } else { fallback }
  let world_anchor_a = body_a.state.position.add(constraint.anchor_a_m)
  let world_anchor_b = body_b.state.position.add(constraint.anchor_b_m)
  let delta = world_anchor_b.sub(world_anchor_a)
  let current_length = delta.length()
  let error = current_length - constraint.rest_length_m
  let normal = if current_length > 0.0 {
    delta.scale(1.0 / current_length)
  } else {
    vec3(1.0, 0.0, 0.0)
  }
  let inverse_mass_a = rigid_body_world_inverse_mass(body_a.state)
  let inverse_mass_b = rigid_body_world_inverse_mass(body_b.state)
  let inverse_mass_sum = inverse_mass_a + inverse_mass_b
  if index_a < 0 || index_b < 0 || index_a == index_b || inverse_mass_sum <= 0.0 {
    rigid_body_world_unresolved_constraint(
      constraint,
      body_a,
      body_b,
      world_anchor_a,
      world_anchor_b,
      current_length,
      error,
      rigid_body_world_constraint_status(
        index_a, index_b, inverse_mass_sum, 0.0, 0.0,
      ),
    )
  } else {
    let correction_mag_a = error *
      inverse_mass_a /
      inverse_mass_sum *
      constraint.stiffness
    let correction_mag_b = error *
      inverse_mass_b /
      inverse_mass_sum *
      constraint.stiffness
    let correction_a = normal.scale(correction_mag_a)
    let correction_b = normal.scale(0.0 - correction_mag_b)
    let relative_velocity = body_b.state.velocity.sub(body_a.state.velocity)
    let relative_speed = relative_velocity.dot(normal)
    let impulse_mag = if constraint.stiffness > 0.0 {
      relative_speed * constraint.stiffness / inverse_mass_sum
    } else {
      0.0
    }
    let impulse = normal.scale(impulse_mag)
    let velocity_delta_a = impulse.scale(inverse_mass_a)
    let velocity_delta_b = impulse.scale(0.0 - inverse_mass_b)
    let after_a = {
      body_id: body_a.state.body_id,
      mass_kg: body_a.state.mass_kg,
      collision_radius_m: body_a.state.collision_radius_m,
      position: body_a.state.position.add(correction_a),
      velocity: body_a.state.velocity.add(velocity_delta_a),
    }
    let after_b = {
      body_id: body_b.state.body_id,
      mass_kg: body_b.state.mass_kg,
      collision_radius_m: body_b.state.collision_radius_m,
      position: body_b.state.position.add(correction_b),
      velocity: body_b.state.velocity.add(velocity_delta_b),
    }
    let status = rigid_body_world_constraint_status(
      index_a,
      index_b,
      inverse_mass_sum,
      correction_a.length() + correction_b.length(),
      velocity_delta_a.length() + velocity_delta_b.length(),
    )
    {
      constraint_id: constraint.constraint_id,
      body_a_id: constraint.body_a_id,
      body_b_id: constraint.body_b_id,
      anchor_a_m: constraint.anchor_a_m,
      anchor_b_m: constraint.anchor_b_m,
      world_anchor_a,
      world_anchor_b,
      rest_length_m: constraint.rest_length_m,
      current_length_m: current_length,
      error_m: error,
      before_a: body_a.state,
      before_b: body_b.state,
      after_a,
      after_b,
      correction_a,
      correction_b,
      velocity_delta_a,
      velocity_delta_b,
      impulse_ns: absolute_double(impulse_mag),
      status,
    }
  }
}

///|
pub fn rigid_body_world_distance_constraint_assessment(
  constraint : RigidBodyWorldDistanceConstraint,
  state_a : RigidBodyState,
  state_b : RigidBodyState,
) -> RigidBodyWorldConstraintResolution {
  rigid_body_world_distance_constraint_resolution(constraint, [
    rigid_body_world_body(state_a),
    rigid_body_world_body(state_b),
  ])
}

///|
fn rigid_body_world_constraint_frame_status(
  resolved_constraint_count : Int,
  review_count : Int,
) -> String {
  if review_count > 0 {
    "world-constraint-review"
  } else if resolved_constraint_count > 0 {
    "world-constraint-resolved"
  } else {
    "world-constraint-satisfied"
  }
}

///|
pub fn rigid_body_world_resolve_constraints(
  world : RigidBodyHeightfieldWorld,
) -> RigidBodyWorldConstraintFrame {
  let bodies : Array[RigidBodyWorldBody] = []
  for body in world.bodies {
    bodies.push(body)
  }
  let resolutions : Array[RigidBodyWorldConstraintResolution] = []
  let mut resolved_count = 0
  let mut review_count = 0
  let mut max_error = 0.0
  let mut impulse = 0.0
  for constraint in world.constraints {
    let resolution = rigid_body_world_distance_constraint_resolution(
      constraint, bodies,
    )
    let error = absolute_double(resolution.error_m)
    if error > max_error {
      max_error = error
    }
    if resolution.status == "world-constraint-resolved" {
      resolved_count += 1
      impulse += resolution.impulse_ns
      let index_a = rigid_body_world_body_array_find_index(
        bodies,
        resolution.body_a_id,
      )
      let index_b = rigid_body_world_body_array_find_index(
        bodies,
        resolution.body_b_id,
      )
      if index_a >= 0 && index_b >= 0 {
        rigid_body_world_replace_body(bodies, index_a, resolution.after_a)
        rigid_body_world_replace_body(bodies, index_b, resolution.after_b)
      }
    } else if resolution.status.contains("review") {
      review_count += 1
    }
    resolutions.push(resolution)
  }
  let after = {
    world_id: world.world_id,
    environment: world.environment,
    material: world.material,
    heightfield_id: world.heightfield_id,
    bodies,
    constraints: world.constraints,
    motion_bodies: world.motion_bodies,
    hinge_constraints: world.hinge_constraints,
  }
  {
    world_id: world.world_id,
    constraint_count: world.constraints.length(),
    resolved_constraint_count: resolved_count,
    max_error_m: max_error,
    impulse_ns: impulse,
    resolutions,
    before: world,
    after,
    status: rigid_body_world_constraint_frame_status(
      resolved_count, review_count,
    ),
  }
}
