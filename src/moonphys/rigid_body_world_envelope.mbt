///|
pub(all) struct RigidBodyWorldBodyEnvelope {
  body_id : String
  sample_count : Int
  min_position : Vec3
  max_position : Vec3
  max_speed_mps : Double
  max_kinetic_energy_j : Double
  max_linear_momentum_kg_mps : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldTraceEnvelope {
  trace_id : String
  frame_count : Int
  body_count : Int
  body_sample_count : Int
  contact_count : Int
  resolved_hinge_constraint_count : Int
  review_count : Int
  min_position : Vec3
  max_position : Vec3
  max_speed_mps : Double
  max_kinetic_energy_j : Double
  max_body_linear_momentum_kg_mps : Double
  max_world_linear_momentum_kg_mps : Double
  max_frame_kinetic_energy_delta_j : Double
  body_envelopes : Array[RigidBodyWorldBodyEnvelope]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn envelope_min_double(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn envelope_max_double(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn envelope_min_vec3(a : Vec3, b : Vec3) -> Vec3 {
  vec3(
    envelope_min_double(a.x, b.x),
    envelope_min_double(a.y, b.y),
    envelope_min_double(a.z, b.z),
  )
}

///|
fn envelope_max_vec3(a : Vec3, b : Vec3) -> Vec3 {
  vec3(
    envelope_max_double(a.x, b.x),
    envelope_max_double(a.y, b.y),
    envelope_max_double(a.z, b.z),
  )
}

///|
fn body_envelope_status(sample_count : Int) -> String {
  if sample_count > 0 {
    "world-body-envelope-bounded"
  } else {
    "world-body-envelope-empty"
  }
}

///|
fn trace_envelope_status(sample_count : Int, review_count : Int) -> String {
  if sample_count <= 0 {
    "world-trace-envelope-empty"
  } else if review_count > 0 {
    "world-trace-envelope-review"
  } else {
    "world-trace-envelope-bounded"
  }
}

///|
fn body_envelope_find_index(
  envelopes : Array[RigidBodyWorldBodyEnvelope],
  body_id : String,
) -> Int {
  for index, envelope in envelopes {
    if envelope.body_id == body_id {
      return index
    }
  }
  0 - 1
}

///|
fn body_envelope_from_state(
  state : RigidBodyState,
) -> RigidBodyWorldBodyEnvelope {
  let momentum = rigid_body_linear_momentum(state).length()
  {
    body_id: state.body_id,
    sample_count: 1,
    min_position: state.position,
    max_position: state.position,
    max_speed_mps: state.velocity.length(),
    max_kinetic_energy_j: rigid_body_linear_kinetic_energy(state),
    max_linear_momentum_kg_mps: momentum,
    status: body_envelope_status(1),
  }
}

///|
fn body_envelope_with_state(
  envelope : RigidBodyWorldBodyEnvelope,
  state : RigidBodyState,
) -> RigidBodyWorldBodyEnvelope {
  let sample_count = envelope.sample_count + 1
  {
    body_id: envelope.body_id,
    sample_count,
    min_position: envelope_min_vec3(envelope.min_position, state.position),
    max_position: envelope_max_vec3(envelope.max_position, state.position),
    max_speed_mps: envelope_max_double(
      envelope.max_speed_mps,
      state.velocity.length(),
    ),
    max_kinetic_energy_j: envelope_max_double(
      envelope.max_kinetic_energy_j,
      rigid_body_linear_kinetic_energy(state),
    ),
    max_linear_momentum_kg_mps: envelope_max_double(
      envelope.max_linear_momentum_kg_mps,
      rigid_body_linear_momentum(state).length(),
    ),
    status: body_envelope_status(sample_count),
  }
}

///|
fn trace_envelope_add_body(
  body_envelopes : Array[RigidBodyWorldBodyEnvelope],
  body : RigidBodyWorldBody,
) -> Unit {
  let index = body_envelope_find_index(body_envelopes, body.state.body_id)
  if index >= 0 {
    body_envelopes[index] = body_envelope_with_state(
      body_envelopes[index],
      body.state,
    )
  } else {
    body_envelopes.push(body_envelope_from_state(body.state))
  }
}

///|
fn trace_envelope_add_world(
  body_envelopes : Array[RigidBodyWorldBodyEnvelope],
  world : RigidBodyHeightfieldWorld,
) -> Unit {
  for body in world.bodies {
    trace_envelope_add_body(body_envelopes, body)
  }
}

///|
fn trace_envelope_bounds(
  body_envelopes : Array[RigidBodyWorldBodyEnvelope],
) -> RigidBodyWorldTraceEnvelope {
  let mut sample_count = 0
  let mut max_speed = 0.0
  let mut max_energy = 0.0
  let mut max_body_momentum = 0.0
  let mut min_position = vec3(0.0, 0.0, 0.0)
  let mut max_position = vec3(0.0, 0.0, 0.0)
  let mut has_position = false
  for envelope in body_envelopes {
    sample_count += envelope.sample_count
    max_speed = envelope_max_double(max_speed, envelope.max_speed_mps)
    max_energy = envelope_max_double(max_energy, envelope.max_kinetic_energy_j)
    max_body_momentum = envelope_max_double(
      max_body_momentum,
      envelope.max_linear_momentum_kg_mps,
    )
    if has_position {
      min_position = envelope_min_vec3(min_position, envelope.min_position)
      max_position = envelope_max_vec3(max_position, envelope.max_position)
    } else {
      min_position = envelope.min_position
      max_position = envelope.max_position
      has_position = true
    }
  }
  {
    trace_id: "",
    frame_count: 0,
    body_count: body_envelopes.length(),
    body_sample_count: sample_count,
    contact_count: 0,
    resolved_hinge_constraint_count: 0,
    review_count: 0,
    min_position,
    max_position,
    max_speed_mps: max_speed,
    max_kinetic_energy_j: max_energy,
    max_body_linear_momentum_kg_mps: max_body_momentum,
    max_world_linear_momentum_kg_mps: 0.0,
    max_frame_kinetic_energy_delta_j: 0.0,
    body_envelopes,
    status: trace_envelope_status(sample_count, 0),
  }
}

///|
pub fn rigid_body_world_linear_momentum(
  world : RigidBodyHeightfieldWorld,
) -> Vec3 {
  let mut momentum = vec3(0.0, 0.0, 0.0)
  for body in world.bodies {
    momentum = momentum.add(rigid_body_linear_momentum(body.state))
  }
  momentum
}

///|
pub fn rigid_body_heightfield_world_trace_envelope(
  trace : RigidBodyHeightfieldWorldTrace,
) -> RigidBodyWorldTraceEnvelope {
  let body_envelopes : Array[RigidBodyWorldBodyEnvelope] = []
  trace_envelope_add_world(body_envelopes, trace.initial_world)
  let mut max_world_momentum = rigid_body_world_linear_momentum(
    trace.initial_world,
  ).length()
  let mut max_energy_delta = 0.0
  let mut contact_count = 0
  let mut hinge_count = 0
  let mut review_count = 0
  for frame in trace.frames {
    trace_envelope_add_world(body_envelopes, frame.after)
    max_world_momentum = envelope_max_double(
      max_world_momentum,
      rigid_body_world_linear_momentum(frame.after).length(),
    )
    contact_count += frame.contact_count
    hinge_count += frame.resolved_hinge_constraint_count
    review_count += frame.review_count
    max_energy_delta = envelope_max_double(
      max_energy_delta,
      abs_double(frame.kinetic_energy_delta_j),
    )
  }
  let bounds = trace_envelope_bounds(body_envelopes)
  {
    trace_id: trace.trace_id,
    frame_count: trace.frame_count,
    body_count: bounds.body_count,
    body_sample_count: bounds.body_sample_count,
    contact_count,
    resolved_hinge_constraint_count: hinge_count,
    review_count,
    min_position: bounds.min_position,
    max_position: bounds.max_position,
    max_speed_mps: bounds.max_speed_mps,
    max_kinetic_energy_j: bounds.max_kinetic_energy_j,
    max_body_linear_momentum_kg_mps: bounds.max_body_linear_momentum_kg_mps,
    max_world_linear_momentum_kg_mps: max_world_momentum,
    max_frame_kinetic_energy_delta_j: max_energy_delta,
    body_envelopes,
    status: trace_envelope_status(bounds.body_sample_count, review_count),
  }
}

///|
pub fn rigid_body_heightfield_world_hinge_motor_trace_envelope(
  trace : RigidBodyHeightfieldWorldHingeMotorTrace,
) -> RigidBodyWorldTraceEnvelope {
  let body_envelopes : Array[RigidBodyWorldBodyEnvelope] = []
  trace_envelope_add_world(body_envelopes, trace.initial_world)
  let mut max_world_momentum = rigid_body_world_linear_momentum(
    trace.initial_world,
  ).length()
  let mut max_energy_delta = 0.0
  for frame in trace.frames {
    trace_envelope_add_world(body_envelopes, frame.after)
    max_world_momentum = envelope_max_double(
      max_world_momentum,
      rigid_body_world_linear_momentum(frame.after).length(),
    )
    max_energy_delta = envelope_max_double(
      max_energy_delta,
      abs_double(frame.world_step.kinetic_energy_delta_j),
    )
  }
  let bounds = trace_envelope_bounds(body_envelopes)
  {
    trace_id: trace.trace_id,
    frame_count: trace.frame_count,
    body_count: bounds.body_count,
    body_sample_count: bounds.body_sample_count,
    contact_count: trace.contact_count,
    resolved_hinge_constraint_count: trace.resolved_hinge_constraint_count,
    review_count: trace.review_count,
    min_position: bounds.min_position,
    max_position: bounds.max_position,
    max_speed_mps: bounds.max_speed_mps,
    max_kinetic_energy_j: bounds.max_kinetic_energy_j,
    max_body_linear_momentum_kg_mps: bounds.max_body_linear_momentum_kg_mps,
    max_world_linear_momentum_kg_mps: max_world_momentum,
    max_frame_kinetic_energy_delta_j: max_energy_delta,
    body_envelopes,
    status: trace_envelope_status(bounds.body_sample_count, trace.review_count),
  }
}
