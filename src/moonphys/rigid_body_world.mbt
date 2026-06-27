///|
pub(all) struct RigidBodyWorldBody {
  state : RigidBodyState
  collision_shape : CollisionShape
  external_force_n : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldPairContact {
  body_a_id : String
  body_b_id : String
  broadphase : CollisionPairProbe
  contact : CollisionContact
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldContactSchedule {
  world_id : String
  pair_count : Int
  broadphase_overlap_count : Int
  contact_count : Int
  pairs : Array[RigidBodyWorldPairContact]
  manifold : CollisionContactManifold
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldPairResolution {
  body_a_id : String
  body_b_id : String
  contact : CollisionContact
  before_a : RigidBodyState
  before_b : RigidBodyState
  after_a : RigidBodyState
  after_b : RigidBodyState
  correction_a : Vec3
  correction_b : Vec3
  velocity_delta_a : Vec3
  velocity_delta_b : Vec3
  normal_impulse_ns : Double
  friction_impulse_ns : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldContactResolution {
  world_id : String
  schedule : RigidBodyWorldContactSchedule
  resolutions : Array[RigidBodyWorldPairResolution]
  resolved_contact_count : Int
  normal_impulse_ns : Double
  friction_impulse_ns : Double
  before : RigidBodyHeightfieldWorld
  after : RigidBodyHeightfieldWorld
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyHeightfieldWorld {
  world_id : String
  environment : PhysicsEnvironment
  material : MaterialContactModel
  heightfield_id : String
  bodies : Array[RigidBodyWorldBody]
  constraints : Array[RigidBodyWorldDistanceConstraint]
  motion_bodies : Array[RigidBodyJointFrameBody]
  hinge_constraints : Array[RigidBodyHingeJointConstraint]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldBodyFrame {
  body_id : String
  before : RigidBodyState
  external_force_n : Vec3
  acceleration_mps2 : Vec3
  integrated : RigidBodyState
  resolution : ContactResolution
  after : RigidBodyState
  kinetic_energy_before_j : Double
  kinetic_energy_after_j : Double
  kinetic_energy_delta_j : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyHeightfieldWorldStep {
  frame_index : Int
  time_s : Double
  dt_s : Double
  before : RigidBodyHeightfieldWorld
  body_frames : Array[RigidBodyWorldBodyFrame]
  after : RigidBodyHeightfieldWorld
  body_count : Int
  contact_count : Int
  body_pair_count : Int
  body_pair_overlap_count : Int
  body_pair_contact_count : Int
  body_contact_schedule : RigidBodyWorldContactSchedule
  body_contact_resolution : RigidBodyWorldContactResolution
  constraint_count : Int
  resolved_constraint_count : Int
  constraint_resolution : RigidBodyWorldConstraintFrame
  hinge_constraint_count : Int
  resolved_hinge_constraint_count : Int
  hinge_constraint_resolution : RigidBodyWorldHingeConstraintFrame
  review_count : Int
  kinetic_energy_before_j : Double
  kinetic_energy_after_j : Double
  kinetic_energy_delta_j : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyHeightfieldWorldTrace {
  trace_id : String
  heightfield_id : String
  dt_s : Double
  frame_count : Int
  initial_world : RigidBodyHeightfieldWorld
  frames : Array[RigidBodyHeightfieldWorldStep]
  final_world : RigidBodyHeightfieldWorld
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_world_body(
  state : RigidBodyState,
  collision_shape? : CollisionShape = collision_sphere(
    "\{state.body_id}/sphere",
    state.collision_radius_m,
  ),
  external_force_n? : Vec3 = vec3(0.0, 0.0, 0.0),
) -> RigidBodyWorldBody {
  { state, collision_shape, external_force_n }
}

///|
pub fn rigid_body_heightfield_world(
  world_id : String,
  field : Heightfield,
  material : MaterialContactModel,
  environment : PhysicsEnvironment,
  bodies : Array[RigidBodyWorldBody],
  constraints? : Array[RigidBodyWorldDistanceConstraint] = [],
  motion_bodies? : Array[RigidBodyJointFrameBody] = [],
  hinge_constraints? : Array[RigidBodyHingeJointConstraint] = [],
) -> RigidBodyHeightfieldWorld {
  {
    world_id,
    environment,
    material,
    heightfield_id: field.field_id,
    bodies,
    constraints,
    motion_bodies,
    hinge_constraints,
  }
}

///|
fn rigid_body_world_transform(body : RigidBodyWorldBody) -> Transform3 {
  transform3(identity_basis3(), body.state.position)
}

///|
fn rigid_body_world_pair_status(
  broadphase : CollisionPairProbe,
  contact : CollisionContact,
) -> String {
  if !broadphase.overlapping {
    "world-pair-broadphase-clear"
  } else if contact.in_contact {
    "world-pair-contact"
  } else {
    "world-pair-narrowphase-clear"
  }
}

///|
fn rigid_body_world_pair_normal(
  body_a : RigidBodyWorldBody,
  body_b : RigidBodyWorldBody,
) -> Vec3 {
  let delta = body_b.state.position.sub(body_a.state.position)
  let length = delta.length()
  if length > 0.0 {
    delta.scale(1.0 / length)
  } else {
    vec3(1.0, 0.0, 0.0)
  }
}

///|
fn rigid_body_world_pair_contact(
  body_a : RigidBodyWorldBody,
  body_b : RigidBodyWorldBody,
) -> RigidBodyWorldPairContact {
  let transform_a = rigid_body_world_transform(body_a)
  let transform_b = rigid_body_world_transform(body_b)
  let broadphase = collision_pair_probe(
    body_a.collision_shape,
    transform_a,
    body_b.collision_shape,
    transform_b,
  )
  let contact = if broadphase.overlapping {
    collision_pair_contact(
      body_a.collision_shape,
      transform_a,
      body_b.collision_shape,
      transform_b,
    )
  } else {
    {
      shape_a_id: body_a.collision_shape.shape_id,
      shape_b_id: body_b.collision_shape.shape_id,
      point: body_a.state.position,
      normal: rigid_body_world_pair_normal(body_a, body_b),
      separation_m: broadphase.separation_m,
      penetration_depth_m: 0.0,
      in_contact: false,
      status: "broadphase-clear",
    }
  }
  {
    body_a_id: body_a.state.body_id,
    body_b_id: body_b.state.body_id,
    broadphase,
    contact,
    status: rigid_body_world_pair_status(broadphase, contact),
  }
}

///|
fn rigid_body_world_contact_schedule_status(
  overlap_count : Int,
  contact_count : Int,
) -> String {
  if contact_count > 0 {
    "world-contact-scheduled"
  } else if overlap_count > 0 {
    "world-contact-narrowphase-clear"
  } else {
    "world-contact-clear"
  }
}

///|
pub fn rigid_body_world_contact_schedule(
  world : RigidBodyHeightfieldWorld,
) -> RigidBodyWorldContactSchedule {
  let pairs : Array[RigidBodyWorldPairContact] = []
  let contacts : Array[CollisionContact] = []
  let mut overlap_count = 0
  let mut contact_count = 0
  for i in 0..<world.bodies.length() {
    for j in (i + 1)..<world.bodies.length() {
      let pair = rigid_body_world_pair_contact(world.bodies[i], world.bodies[j])
      if pair.broadphase.overlapping {
        overlap_count += 1
      }
      if pair.contact.in_contact {
        contact_count += 1
      }
      pairs.push(pair)
      contacts.push(pair.contact)
    }
  }
  let manifold = collision_contact_manifold(
    "\{world.world_id}/body-pairs",
    contacts,
  )
  {
    world_id: world.world_id,
    pair_count: pairs.length(),
    broadphase_overlap_count: overlap_count,
    contact_count,
    pairs,
    manifold,
    status: rigid_body_world_contact_schedule_status(
      overlap_count, contact_count,
    ),
  }
}

///|
fn rigid_body_world_body_array_index(
  bodies : Array[RigidBodyWorldBody],
  body_id : String,
) -> Int {
  for index, body in bodies {
    if body.state.body_id == body_id {
      return index
    }
  }
  0
}

///|
fn rigid_body_world_body_array_find_index(
  bodies : Array[RigidBodyWorldBody],
  body_id : String,
) -> Int {
  for index, body in bodies {
    if body.state.body_id == body_id {
      return index
    }
  }
  0 - 1
}

///|
fn rigid_body_world_inverse_mass(state : RigidBodyState) -> Double {
  if state.mass_kg > 0.0 {
    1.0 / state.mass_kg
  } else {
    0.0
  }
}

///|
fn rigid_body_world_resolution_status(
  contact : CollisionContact,
  inverse_mass_sum : Double,
) -> String {
  if !contact.in_contact {
    "world-pair-no-contact"
  } else if inverse_mass_sum <= 0.0 {
    "world-pair-static-review"
  } else {
    "world-pair-resolved"
  }
}

///|
fn resolved_pair_tangent_velocity(
  velocity : Vec3,
  normal : Vec3,
  material : MaterialContactModel,
) -> Vec3 {
  let normal_velocity = normal.scale(velocity.dot(normal))
  let tangent_velocity = velocity.sub(normal_velocity)
  normal_velocity.add(
    tangent_velocity.scale(collision_friction_scale(material)),
  )
}

///|
fn rigid_body_world_pair_resolution(
  body_a : RigidBodyWorldBody,
  body_b : RigidBodyWorldBody,
  contact : CollisionContact,
  material : MaterialContactModel,
) -> RigidBodyWorldPairResolution {
  let inverse_mass_a = rigid_body_world_inverse_mass(body_a.state)
  let inverse_mass_b = rigid_body_world_inverse_mass(body_b.state)
  let inverse_mass_sum = inverse_mass_a + inverse_mass_b
  let status = rigid_body_world_resolution_status(contact, inverse_mass_sum)
  if status != "world-pair-resolved" {
    {
      body_a_id: body_a.state.body_id,
      body_b_id: body_b.state.body_id,
      contact,
      before_a: body_a.state,
      before_b: body_b.state,
      after_a: body_a.state,
      after_b: body_b.state,
      correction_a: vec3(0.0, 0.0, 0.0),
      correction_b: vec3(0.0, 0.0, 0.0),
      velocity_delta_a: vec3(0.0, 0.0, 0.0),
      velocity_delta_b: vec3(0.0, 0.0, 0.0),
      normal_impulse_ns: 0.0,
      friction_impulse_ns: 0.0,
      status,
    }
  } else {
    let normal = contact.normal
    let correction_mag_a = contact.penetration_depth_m *
      inverse_mass_a /
      inverse_mass_sum
    let correction_mag_b = contact.penetration_depth_m *
      inverse_mass_b /
      inverse_mass_sum
    let correction_a = normal.scale(0.0 - correction_mag_a)
    let correction_b = normal.scale(correction_mag_b)
    let relative_velocity = body_b.state.velocity.sub(body_a.state.velocity)
    let normal_speed = relative_velocity.dot(normal)
    let impulse_mag = if normal_speed < 0.0 {
      (0.0 - (1.0 + material.restitution_coefficient) * normal_speed) /
      inverse_mass_sum
    } else {
      0.0
    }
    let impulse = normal.scale(impulse_mag)
    let pre_tangent_speed = relative_velocity
      .sub(normal.scale(normal_speed))
      .length()
    let velocity_a = resolved_pair_tangent_velocity(
      body_a.state.velocity.sub(impulse.scale(inverse_mass_a)),
      normal,
      material,
    )
    let velocity_b = resolved_pair_tangent_velocity(
      body_b.state.velocity.add(impulse.scale(inverse_mass_b)),
      normal,
      material,
    )
    let after_a = {
      body_id: body_a.state.body_id,
      mass_kg: body_a.state.mass_kg,
      collision_radius_m: body_a.state.collision_radius_m,
      position: body_a.state.position.add(correction_a),
      velocity: velocity_a,
    }
    let after_b = {
      body_id: body_b.state.body_id,
      mass_kg: body_b.state.mass_kg,
      collision_radius_m: body_b.state.collision_radius_m,
      position: body_b.state.position.add(correction_b),
      velocity: velocity_b,
    }
    let velocity_delta_a = after_a.velocity.sub(body_a.state.velocity)
    let velocity_delta_b = after_b.velocity.sub(body_b.state.velocity)
    let post_relative = after_b.velocity.sub(after_a.velocity)
    let post_normal_speed = post_relative.dot(normal)
    let post_tangent_speed = post_relative
      .sub(normal.scale(post_normal_speed))
      .length()
    {
      body_a_id: body_a.state.body_id,
      body_b_id: body_b.state.body_id,
      contact,
      before_a: body_a.state,
      before_b: body_b.state,
      after_a,
      after_b,
      correction_a,
      correction_b,
      velocity_delta_a,
      velocity_delta_b,
      normal_impulse_ns: impulse_mag,
      friction_impulse_ns: (pre_tangent_speed - post_tangent_speed) *
      (body_a.state.mass_kg * body_b.state.mass_kg) /
      (body_a.state.mass_kg + body_b.state.mass_kg),
      status,
    }
  }
}

///|
fn rigid_body_world_replace_body(
  bodies : Array[RigidBodyWorldBody],
  index : Int,
  state : RigidBodyState,
) -> Unit {
  let body = bodies[index]
  bodies[index] = {
    state,
    collision_shape: body.collision_shape,
    external_force_n: body.external_force_n,
  }
}

///|
fn rigid_body_world_contact_resolution_status(
  resolved_contact_count : Int,
) -> String {
  if resolved_contact_count > 0 {
    "world-contact-resolved"
  } else {
    "world-contact-no-resolution"
  }
}

///|
pub fn rigid_body_world_resolve_contacts(
  world : RigidBodyHeightfieldWorld,
  schedule : RigidBodyWorldContactSchedule,
) -> RigidBodyWorldContactResolution {
  let bodies : Array[RigidBodyWorldBody] = []
  for body in world.bodies {
    bodies.push(body)
  }
  let resolutions : Array[RigidBodyWorldPairResolution] = []
  let mut resolved_count = 0
  let mut normal_impulse = 0.0
  let mut friction_impulse = 0.0
  for pair in schedule.pairs {
    let index_a = rigid_body_world_body_array_index(bodies, pair.body_a_id)
    let index_b = rigid_body_world_body_array_index(bodies, pair.body_b_id)
    let resolution = rigid_body_world_pair_resolution(
      bodies[index_a],
      bodies[index_b],
      pair.contact,
      world.material,
    )
    if resolution.status == "world-pair-resolved" {
      resolved_count += 1
      normal_impulse += resolution.normal_impulse_ns
      friction_impulse += resolution.friction_impulse_ns
      rigid_body_world_replace_body(bodies, index_a, resolution.after_a)
      rigid_body_world_replace_body(bodies, index_b, resolution.after_b)
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
    schedule,
    resolutions,
    resolved_contact_count: resolved_count,
    normal_impulse_ns: normal_impulse,
    friction_impulse_ns: friction_impulse,
    before: world,
    after,
    status: rigid_body_world_contact_resolution_status(resolved_count),
  }
}

///|
fn rigid_body_world_linear_kinetic_energy(
  world : RigidBodyHeightfieldWorld,
) -> Double {
  let mut energy = 0.0
  for body in world.bodies {
    energy += rigid_body_linear_kinetic_energy(body.state)
  }
  energy
}

///|
fn rigid_body_world_force_acceleration(body : RigidBodyWorldBody) -> Vec3 {
  if body.state.mass_kg > 0.0 {
    body.external_force_n.scale(1.0 / body.state.mass_kg)
  } else {
    vec3(0.0, 0.0, 0.0)
  }
}

///|
fn rigid_body_world_acceleration(
  environment : PhysicsEnvironment,
  body : RigidBodyWorldBody,
) -> Vec3 {
  if body.state.mass_kg > 0.0 {
    vec3(0.0, 0.0, 0.0 - environment.gravity_mps2).add(
      rigid_body_world_force_acceleration(body),
    )
  } else {
    vec3(0.0, 0.0, 0.0)
  }
}

///|
fn rigid_body_world_body_status(
  body : RigidBodyWorldBody,
  resolution : ContactResolution,
) -> String {
  if body.state.mass_kg <= 0.0 {
    "world-body-zero-mass-review"
  } else if resolution.status == "contact-resolved" {
    "world-body-contact-resolved"
  } else {
    "world-body-clear"
  }
}

///|
pub fn rigid_body_heightfield_world_body_frame(
  field : Heightfield,
  material : MaterialContactModel,
  environment : PhysicsEnvironment,
  body : RigidBodyWorldBody,
  dt_s : Double,
) -> RigidBodyWorldBodyFrame {
  let acceleration = rigid_body_world_acceleration(environment, body)
  let integrated = integrate_rigid_body(body.state, dt_s, acceleration)
  let resolution = resolve_heightfield_contact(field, integrated, material)
  let status = rigid_body_world_body_status(body, resolution)
  let energy_before = rigid_body_linear_kinetic_energy(body.state)
  let energy_after = rigid_body_linear_kinetic_energy(resolution.after)
  {
    body_id: body.state.body_id,
    before: body.state,
    external_force_n: body.external_force_n,
    acceleration_mps2: acceleration,
    integrated,
    resolution,
    after: resolution.after,
    kinetic_energy_before_j: energy_before,
    kinetic_energy_after_j: energy_after,
    kinetic_energy_delta_j: energy_after - energy_before,
    status,
  }
}

///|
fn rigid_body_heightfield_world_step_status(
  field_matches : Bool,
  contact_count : Int,
  review_count : Int,
  body_pair_contact_count : Int,
  resolved_constraint_count : Int,
  resolved_hinge_constraint_count : Int,
) -> String {
  if !field_matches {
    "world-heightfield-mismatch-review"
  } else if review_count > 0 {
    "world-step-review"
  } else if body_pair_contact_count > 0 {
    "world-step-body-contact"
  } else if resolved_constraint_count > 0 {
    "world-step-constrained"
  } else if resolved_hinge_constraint_count > 0 {
    "world-step-hinge-constrained"
  } else if contact_count > 0 {
    "world-step-contact"
  } else {
    "world-step-clear"
  }
}

///|
pub fn rigid_body_heightfield_world_step(
  world : RigidBodyHeightfieldWorld,
  field : Heightfield,
  dt_s : Double,
  frame_index? : Int = 0,
  time_s? : Double = 0.0,
) -> RigidBodyHeightfieldWorldStep {
  let body_frames : Array[RigidBodyWorldBodyFrame] = []
  let next_bodies : Array[RigidBodyWorldBody] = []
  let mut contact_count = 0
  let mut review_count = 0
  let mut energy_before = 0.0
  let mut energy_after = 0.0
  for body in world.bodies {
    let frame = rigid_body_heightfield_world_body_frame(
      field,
      world.material,
      world.environment,
      body,
      dt_s,
    )
    if frame.resolution.collision.in_contact {
      contact_count += 1
    }
    if frame.status == "world-body-zero-mass-review" {
      review_count += 1
    }
    energy_before += frame.kinetic_energy_before_j
    energy_after += frame.kinetic_energy_after_j
    body_frames.push(frame)
    next_bodies.push({
      state: frame.after,
      collision_shape: body.collision_shape,
      external_force_n: body.external_force_n,
    })
  }
  let integrated_world = {
    world_id: world.world_id,
    environment: world.environment,
    material: world.material,
    heightfield_id: world.heightfield_id,
    bodies: next_bodies,
    constraints: world.constraints,
    motion_bodies: world.motion_bodies,
    hinge_constraints: world.hinge_constraints,
  }
  let contact_schedule = rigid_body_world_contact_schedule(integrated_world)
  let contact_resolution = rigid_body_world_resolve_contacts(
    integrated_world, contact_schedule,
  )
  let constraint_resolution = rigid_body_world_resolve_constraints(
    contact_resolution.after,
  )
  if constraint_resolution.status == "world-constraint-review" {
    review_count += 1
  }
  let hinge_constraint_resolution = rigid_body_world_resolve_hinge_constraints(
    constraint_resolution.after,
  )
  if hinge_constraint_resolution.status == "world-hinge-constraint-review" {
    review_count += 1
  }
  let after = hinge_constraint_resolution.after
  energy_after = rigid_body_world_linear_kinetic_energy(after)
  let field_matches = world.heightfield_id == field.field_id
  {
    frame_index,
    time_s,
    dt_s,
    before: world,
    body_frames,
    after,
    body_count: next_bodies.length(),
    contact_count,
    body_pair_count: contact_schedule.pair_count,
    body_pair_overlap_count: contact_schedule.broadphase_overlap_count,
    body_pair_contact_count: contact_schedule.contact_count,
    body_contact_schedule: contact_schedule,
    body_contact_resolution: contact_resolution,
    constraint_count: constraint_resolution.constraint_count,
    resolved_constraint_count: constraint_resolution.resolved_constraint_count,
    constraint_resolution,
    hinge_constraint_count: hinge_constraint_resolution.hinge_constraint_count,
    resolved_hinge_constraint_count: hinge_constraint_resolution.resolved_hinge_constraint_count,
    hinge_constraint_resolution,
    review_count,
    kinetic_energy_before_j: energy_before,
    kinetic_energy_after_j: energy_after,
    kinetic_energy_delta_j: energy_after - energy_before,
    status: rigid_body_heightfield_world_step_status(
      field_matches,
      contact_count,
      review_count,
      contact_schedule.contact_count,
      constraint_resolution.resolved_constraint_count,
      hinge_constraint_resolution.resolved_hinge_constraint_count,
    ),
  }
}

///|
pub fn rigid_body_heightfield_world_trace(
  trace_id : String,
  initial_world : RigidBodyHeightfieldWorld,
  field : Heightfield,
  dt_s : Double,
  frame_count : Int,
  note : String,
) -> RigidBodyHeightfieldWorldTrace {
  let frames : Array[RigidBodyHeightfieldWorldStep] = []
  let mut world = initial_world
  for index in 0..<frame_count {
    let frame = rigid_body_heightfield_world_step(
      world,
      field,
      dt_s,
      frame_index=index,
      time_s=index.to_double() * dt_s,
    )
    frames.push(frame)
    world = frame.after
  }
  {
    trace_id,
    heightfield_id: field.field_id,
    dt_s,
    frame_count: frames.length(),
    initial_world,
    frames,
    final_world: world,
    status: if frames.length() == frame_count {
      "world-deterministic-replay"
    } else {
      "world-deterministic-replay-truncated"
    },
    note,
  }
}
