///|
pub(all) struct RigidBodyWorldBody {
  state : RigidBodyState
  external_force_n : Vec3
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
  external_force_n? : Vec3 = vec3(0.0, 0.0, 0.0),
) -> RigidBodyWorldBody {
  { state, external_force_n }
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
) -> String {
  if !field_matches {
    "world-heightfield-mismatch-review"
  } else if review_count > 0 {
    "world-step-review"
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
    review_count,
    kinetic_energy_before_j: energy_before,
    kinetic_energy_after_j: energy_after,
    kinetic_energy_delta_j: energy_after - energy_before,
    status: rigid_body_heightfield_world_step_status(
      field_matches, contact_count, review_count,
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
