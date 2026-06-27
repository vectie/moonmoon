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
pub(all) struct RigidBodyHeightfieldWorld {
  world_id : String
  environment : PhysicsEnvironment
  material : MaterialContactModel
  heightfield_id : String
  bodies : Array[RigidBodyWorldBody]
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
) -> RigidBodyHeightfieldWorld {
  { world_id, environment, material, heightfield_id: field.field_id, bodies }
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
) -> String {
  if !field_matches {
    "world-heightfield-mismatch-review"
  } else if review_count > 0 {
    "world-step-review"
  } else if body_pair_contact_count > 0 {
    "world-step-body-contact"
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
  let after = {
    world_id: world.world_id,
    environment: world.environment,
    material: world.material,
    heightfield_id: world.heightfield_id,
    bodies: next_bodies,
  }
  let contact_schedule = rigid_body_world_contact_schedule(after)
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
    review_count,
    kinetic_energy_before_j: energy_before,
    kinetic_energy_after_j: energy_after,
    kinetic_energy_delta_j: energy_after - energy_before,
    status: rigid_body_heightfield_world_step_status(
      field_matches,
      contact_count,
      review_count,
      contact_schedule.contact_count,
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
