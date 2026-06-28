///|
pub(all) struct RigidBodyWorldBodyTarget {
  body_id : String
  target_position : Vec3
  target_velocity : Vec3
  max_correction_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldBodyTargetStep {
  body_id : String
  before : RigidBodyState
  after : RigidBodyState
  target_position : Vec3
  target_velocity : Vec3
  correction_m : Double
  max_correction_m : Double
  matched : Bool
  within_limit : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldBodyTargetFrame {
  world_id : String
  target_count : Int
  applied_count : Int
  review_count : Int
  max_correction_m : Double
  steps : Array[RigidBodyWorldBodyTargetStep]
  before : RigidBodyHeightfieldWorld
  after : RigidBodyHeightfieldWorld
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_world_body_target(
  body_id : String,
  target_position : Vec3,
  target_velocity : Vec3,
  max_correction_m? : Double = 1000000000.0,
) -> RigidBodyWorldBodyTarget {
  { body_id, target_position, target_velocity, max_correction_m }
}

///|
fn body_target_find_body_index(
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
fn body_target_find_motion_index(
  bodies : Array[RigidBodyJointFrameBody],
  body_id : String,
) -> Int {
  for index, body in bodies {
    if body.body_id == body_id {
      return index
    }
  }
  0 - 1
}

///|
fn body_target_status(matched : Bool, within_limit : Bool) -> String {
  if !matched {
    "body-target-missing-body-review"
  } else if !within_limit {
    "body-target-correction-review"
  } else {
    "body-target-applied"
  }
}

///|
fn rigid_body_world_apply_body_target_step(
  bodies : Array[RigidBodyWorldBody],
  motion_bodies : Array[RigidBodyJointFrameBody],
  target : RigidBodyWorldBodyTarget,
) -> RigidBodyWorldBodyTargetStep {
  let body_index = body_target_find_body_index(bodies, target.body_id)
  if body_index < 0 {
    let fallback = rigid_body_state(
      target.body_id,
      0.0,
      0.0,
      target.target_position,
      target.target_velocity,
    )
    {
      body_id: target.body_id,
      before: fallback,
      after: fallback,
      target_position: target.target_position,
      target_velocity: target.target_velocity,
      correction_m: 0.0,
      max_correction_m: target.max_correction_m,
      matched: false,
      within_limit: false,
      status: body_target_status(false, false),
    }
  } else {
    let body = bodies[body_index]
    let correction = target.target_position.sub(body.state.position).length()
    let within_limit = correction <= target.max_correction_m
    let after = {
      body_id: body.state.body_id,
      mass_kg: body.state.mass_kg,
      collision_radius_m: body.state.collision_radius_m,
      position: target.target_position,
      velocity: target.target_velocity,
    }
    bodies[body_index] = {
      state: after,
      collision_shape: body.collision_shape,
      external_force_n: body.external_force_n,
    }
    let motion_index = body_target_find_motion_index(
      motion_bodies,
      target.body_id,
    )
    if motion_index >= 0 {
      let motion = motion_bodies[motion_index]
      motion_bodies[motion_index] = {
        body_id: motion.body_id,
        state: {
          body_id: motion.state.body_id,
          linear: after,
          angular: motion.state.angular,
        },
        inertia: motion.inertia,
      }
    }
    {
      body_id: target.body_id,
      before: body.state,
      after,
      target_position: target.target_position,
      target_velocity: target.target_velocity,
      correction_m: correction,
      max_correction_m: target.max_correction_m,
      matched: true,
      within_limit,
      status: body_target_status(true, within_limit),
    }
  }
}

///|
fn rigid_body_world_body_target_frame_status(
  target_count : Int,
  applied_count : Int,
  review_count : Int,
) -> String {
  if target_count <= 0 {
    "body-target-frame-empty"
  } else if review_count > 0 {
    "body-target-frame-review"
  } else if applied_count > 0 {
    "body-target-frame-applied"
  } else {
    "body-target-frame-idle"
  }
}

///|
pub fn rigid_body_world_apply_body_targets(
  world : RigidBodyHeightfieldWorld,
  targets : Array[RigidBodyWorldBodyTarget],
) -> RigidBodyWorldBodyTargetFrame {
  let bodies : Array[RigidBodyWorldBody] = []
  let motion_bodies : Array[RigidBodyJointFrameBody] = []
  for body in world.bodies {
    bodies.push(body)
  }
  for body in world.motion_bodies {
    motion_bodies.push(body)
  }
  let steps : Array[RigidBodyWorldBodyTargetStep] = []
  let mut applied_count = 0
  let mut review_count = 0
  let mut max_correction = 0.0
  for target in targets {
    let step = rigid_body_world_apply_body_target_step(
      bodies, motion_bodies, target,
    )
    if step.status == "body-target-applied" {
      applied_count += 1
    } else if step.status.contains("review") {
      review_count += 1
    }
    if step.correction_m > max_correction {
      max_correction = step.correction_m
    }
    steps.push(step)
  }
  let after = {
    world_id: world.world_id,
    environment: world.environment,
    material: world.material,
    heightfield_id: world.heightfield_id,
    bodies,
    constraints: world.constraints,
    motion_bodies,
    hinge_constraints: world.hinge_constraints,
  }
  {
    world_id: world.world_id,
    target_count: targets.length(),
    applied_count,
    review_count,
    max_correction_m: max_correction,
    steps,
    before: world,
    after,
    status: rigid_body_world_body_target_frame_status(
      targets.length(),
      applied_count,
      review_count,
    ),
  }
}

///|
fn rigid_body_world_target_frame_targets(
  frames : Array[Array[RigidBodyWorldBodyTarget]],
  index : Int,
) -> Array[RigidBodyWorldBodyTarget] {
  if index < frames.length() {
    frames[index]
  } else {
    []
  }
}

///|
pub fn rigid_body_heightfield_world_targeted_hinge_motor_trace(
  trace_id : String,
  initial_world : RigidBodyHeightfieldWorld,
  field : Heightfield,
  motor_frames : Array[JointMotorFrame],
  body_target_frames : Array[Array[RigidBodyWorldBodyTarget]],
  note? : String = "",
) -> RigidBodyHeightfieldWorldHingeMotorTrace {
  let frames : Array[RigidBodyHeightfieldWorldHingeMotorStep] = []
  let mut world = initial_world
  let mut time_s = 0.0
  let mut driven_count = 0
  let mut contact_count = 0
  let mut resolved_hinge_count = 0
  let mut review_count = 0
  for index, motor_frame in motor_frames {
    let target_frame = rigid_body_world_apply_body_targets(
      world,
      rigid_body_world_target_frame_targets(body_target_frames, index),
    )
    let frame = rigid_body_heightfield_world_hinge_motor_step(
      target_frame.after,
      field,
      motor_frame,
      frame_index=index,
      time_s~,
    )
    frames.push(frame)
    driven_count += frame.driven_joint_count
    contact_count += frame.contact_count
    resolved_hinge_count += frame.resolved_hinge_constraint_count
    review_count += target_frame.review_count + frame.review_count
    world = frame.after
    time_s += motor_frame.dt_s
  }
  {
    trace_id,
    heightfield_id: field.field_id,
    frame_count: frames.length(),
    motor_frame_count: motor_frames.length(),
    driven_joint_count: driven_count,
    contact_count,
    resolved_hinge_constraint_count: resolved_hinge_count,
    review_count,
    initial_world,
    frames,
    final_world: world,
    status: rigid_body_heightfield_world_hinge_motor_trace_status(
      frames.length(),
      motor_frames.length(),
      driven_count,
      review_count,
    ),
    note,
  }
}
