///|
pub(all) struct RigidBodyHeightfieldFrame {
  frame_index : Int
  time_s : Double
  before : RigidBodyState
  integrated : RigidBodyState
  resolution : ContactResolution
  after : RigidBodyState
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyHeightfieldTrace {
  trace_id : String
  environment : PhysicsEnvironment
  material : MaterialContactModel
  heightfield_id : String
  dt_s : Double
  frame_count : Int
  frames : Array[RigidBodyHeightfieldFrame]
  final_state : RigidBodyState
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_heightfield_frame(
  frame_index : Int,
  time_s : Double,
  field : Heightfield,
  material : MaterialContactModel,
  environment : PhysicsEnvironment,
  state : RigidBodyState,
  dt_s : Double,
  external_acceleration : Vec3,
) -> RigidBodyHeightfieldFrame {
  let gravity = vec3(0.0, 0.0, 0.0 - environment.gravity_mps2)
  let integrated = integrate_rigid_body(
    state,
    dt_s,
    gravity.add(external_acceleration),
  )
  let resolution = resolve_heightfield_contact(field, integrated, material)
  {
    frame_index,
    time_s,
    before: state,
    integrated,
    after: resolution.after,
    resolution,
    status: resolution.status,
  }
}

///|
pub fn rigid_body_heightfield_trace(
  trace_id : String,
  field : Heightfield,
  material : MaterialContactModel,
  environment : PhysicsEnvironment,
  initial_state : RigidBodyState,
  dt_s : Double,
  frame_count : Int,
  external_acceleration : Vec3,
  note : String,
) -> RigidBodyHeightfieldTrace {
  let frames : Array[RigidBodyHeightfieldFrame] = []
  let mut state = initial_state
  for index in 0..<frame_count {
    let frame = rigid_body_heightfield_frame(
      index,
      index.to_double() * dt_s,
      field,
      material,
      environment,
      state,
      dt_s,
      external_acceleration,
    )
    frames.push(frame)
    state = frame.after
  }
  {
    trace_id,
    environment,
    material,
    heightfield_id: field.field_id,
    dt_s,
    frame_count: frames.length(),
    frames,
    final_state: state,
    status: if frames.length() == frame_count {
      "deterministic-replay"
    } else {
      "deterministic-replay-truncated"
    },
    note,
  }
}
