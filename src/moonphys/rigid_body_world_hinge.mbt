///|
pub(all) struct RigidBodyWorldHingeJointResolution {
  joint_id : String
  before_a : RigidBodyMotionState
  before_b : RigidBodyMotionState
  assessment : RigidBodyHingeJointAssessment
  after_a : RigidBodyMotionState
  after_b : RigidBodyMotionState
  correction_a_rad : Vec3
  correction_b_rad : Vec3
  velocity_delta_a_rad_s : Vec3
  velocity_delta_b_rad_s : Vec3
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldHingeConstraintFrame {
  world_id : String
  hinge_constraint_count : Int
  resolved_hinge_constraint_count : Int
  review_count : Int
  max_position_error_m : Double
  max_angular_error_rad : Double
  linear_impulse_ns : Double
  angular_impulse_nms : Double
  resolutions : Array[RigidBodyWorldHingeJointResolution]
  before : RigidBodyHeightfieldWorld
  after : RigidBodyHeightfieldWorld
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn angular_correction_basis(correction_rad : Vec3) -> Basis3 {
  let angle = correction_rad.length()
  if angle > 0.0 {
    axis_angle_basis3(correction_rad.scale(1.0 / angle), angle)
  } else {
    identity_basis3()
  }
}

///|
fn corrected_motion_state(
  state : RigidBodyMotionState,
  linear_after : RigidBodyState,
  correction_rad : Vec3,
  velocity_delta_rad_s : Vec3,
) -> RigidBodyMotionState {
  let correction = angular_correction_basis(correction_rad)
  {
    body_id: state.body_id,
    linear: linear_after,
    angular: {
      body_id: state.angular.body_id,
      orientation: correction.mul_basis3(state.angular.orientation),
      angular_velocity_rad_s: state.angular.angular_velocity_rad_s.add(
        velocity_delta_rad_s,
      ),
    },
  }
}

///|
fn rigid_body_world_hinge_status(
  assessment : RigidBodyHingeJointAssessment,
) -> String {
  if assessment.status.contains("review") {
    "world-hinge-review"
  } else if assessment.status == "hinge-joint-correction-estimated" {
    "world-hinge-resolved"
  } else {
    "world-hinge-satisfied"
  }
}

///|
fn rigid_body_world_hinge_resolution(
  joint : RigidBodyHingeJointConstraint,
  body_a : RigidBodyJointFrameBody,
  body_b : RigidBodyJointFrameBody,
) -> RigidBodyWorldHingeJointResolution {
  let assessment = rigid_body_hinge_joint_assessment(
    joint,
    body_a.state,
    body_a.inertia,
    body_b.state,
    body_b.inertia,
  )
  let status = rigid_body_world_hinge_status(assessment)
  let after_a = if status == "world-hinge-resolved" {
    corrected_motion_state(
      body_a.state,
      assessment.position.after_a,
      assessment.axis.correction_a_rad,
      assessment.axis.velocity_delta_a_rad_s,
    )
  } else {
    body_a.state
  }
  let after_b = if status == "world-hinge-resolved" {
    corrected_motion_state(
      body_b.state,
      assessment.position.after_b,
      assessment.axis.correction_b_rad,
      assessment.axis.velocity_delta_b_rad_s,
    )
  } else {
    body_b.state
  }
  {
    joint_id: joint.joint_id,
    before_a: body_a.state,
    before_b: body_b.state,
    assessment,
    after_a,
    after_b,
    correction_a_rad: if status == "world-hinge-resolved" {
      assessment.axis.correction_a_rad
    } else {
      vec3(0.0, 0.0, 0.0)
    },
    correction_b_rad: if status == "world-hinge-resolved" {
      assessment.axis.correction_b_rad
    } else {
      vec3(0.0, 0.0, 0.0)
    },
    velocity_delta_a_rad_s: if status == "world-hinge-resolved" {
      assessment.axis.velocity_delta_a_rad_s
    } else {
      vec3(0.0, 0.0, 0.0)
    },
    velocity_delta_b_rad_s: if status == "world-hinge-resolved" {
      assessment.axis.velocity_delta_b_rad_s
    } else {
      vec3(0.0, 0.0, 0.0)
    },
    status,
  }
}

///|
fn rigid_body_world_motion_body_find_index(
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
fn rigid_body_world_motion_body_for_state(
  body_id : String,
) -> RigidBodyJointFrameBody {
  rigid_body_joint_frame_body(
    rigid_body_motion_state(
      body_id,
      0.0,
      0.0,
      vec3(0.0, 0.0, 0.0),
      vec3(0.0, 0.0, 0.0),
      identity_basis3(),
      vec3(0.0, 0.0, 0.0),
    ),
    rigid_body_inertia(body_id, vec3(0.0, 0.0, 0.0)),
  )
}

///|
fn rigid_body_world_motion_body(
  bodies : Array[RigidBodyJointFrameBody],
  body_id : String,
) -> RigidBodyJointFrameBody {
  let index = rigid_body_world_motion_body_find_index(bodies, body_id)
  if index >= 0 {
    bodies[index]
  } else {
    rigid_body_world_motion_body_for_state(body_id)
  }
}

///|
fn rigid_body_world_replace_motion_body(
  bodies : Array[RigidBodyJointFrameBody],
  state : RigidBodyMotionState,
) -> Unit {
  let index = rigid_body_world_motion_body_find_index(bodies, state.body_id)
  if index >= 0 {
    let body = bodies[index]
    bodies[index] = { body_id: state.body_id, state, inertia: body.inertia }
  }
}

///|
fn rigid_body_world_sync_motion_bodies(
  world : RigidBodyHeightfieldWorld,
) -> Array[RigidBodyJointFrameBody] {
  let synced : Array[RigidBodyJointFrameBody] = []
  for motion in world.motion_bodies {
    let body_index = rigid_body_world_body_array_find_index(
      world.bodies,
      motion.body_id,
    )
    let linear = if body_index >= 0 {
      world.bodies[body_index].state
    } else {
      motion.state.linear
    }
    synced.push({
      body_id: motion.body_id,
      state: {
        body_id: motion.state.body_id,
        linear,
        angular: motion.state.angular,
      },
      inertia: motion.inertia,
    })
  }
  synced
}

///|
fn rigid_body_world_hinge_constraint_frame_status(
  resolved_count : Int,
  review_count : Int,
) -> String {
  if review_count > 0 {
    "world-hinge-constraint-review"
  } else if resolved_count > 0 {
    "world-hinge-constraint-resolved"
  } else {
    "world-hinge-constraint-satisfied"
  }
}

///|
pub fn rigid_body_world_resolve_hinge_constraints(
  world : RigidBodyHeightfieldWorld,
) -> RigidBodyWorldHingeConstraintFrame {
  let motion_bodies = rigid_body_world_sync_motion_bodies(world)
  let linear_bodies : Array[RigidBodyWorldBody] = []
  for body in world.bodies {
    linear_bodies.push(body)
  }
  let resolutions : Array[RigidBodyWorldHingeJointResolution] = []
  let mut resolved_count = 0
  let mut review_count = 0
  let mut max_position_error = 0.0
  let mut max_angular_error = 0.0
  let mut linear_impulse = 0.0
  let mut angular_impulse = 0.0
  for joint in world.hinge_constraints {
    let body_a = rigid_body_world_motion_body(
      motion_bodies,
      joint.position.body_a_id,
    )
    let body_b = rigid_body_world_motion_body(
      motion_bodies,
      joint.position.body_b_id,
    )
    let resolution = rigid_body_world_hinge_resolution(joint, body_a, body_b)
    if resolution.assessment.position_error_m > max_position_error {
      max_position_error = resolution.assessment.position_error_m
    }
    if resolution.assessment.angular_error_rad > max_angular_error {
      max_angular_error = resolution.assessment.angular_error_rad
    }
    if resolution.status == "world-hinge-resolved" {
      resolved_count += 1
      linear_impulse += resolution.assessment.linear_impulse_ns
      angular_impulse += resolution.assessment.angular_impulse_nms
      rigid_body_world_replace_motion_body(motion_bodies, resolution.after_a)
      rigid_body_world_replace_motion_body(motion_bodies, resolution.after_b)
      let index_a = rigid_body_world_body_array_find_index(
        linear_bodies,
        resolution.after_a.body_id,
      )
      let index_b = rigid_body_world_body_array_find_index(
        linear_bodies,
        resolution.after_b.body_id,
      )
      if index_a >= 0 {
        rigid_body_world_replace_body(
          linear_bodies,
          index_a,
          resolution.after_a.linear,
        )
      }
      if index_b >= 0 {
        rigid_body_world_replace_body(
          linear_bodies,
          index_b,
          resolution.after_b.linear,
        )
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
    bodies: linear_bodies,
    constraints: world.constraints,
    motion_bodies,
    hinge_constraints: world.hinge_constraints,
  }
  {
    world_id: world.world_id,
    hinge_constraint_count: world.hinge_constraints.length(),
    resolved_hinge_constraint_count: resolved_count,
    review_count,
    max_position_error_m: max_position_error,
    max_angular_error_rad: max_angular_error,
    linear_impulse_ns: linear_impulse,
    angular_impulse_nms: angular_impulse,
    resolutions,
    before: world,
    after,
    status: rigid_body_world_hinge_constraint_frame_status(
      resolved_count, review_count,
    ),
  }
}
