///|
pub(all) struct RigidBodyJointFrameBody {
  body_id : String
  state : RigidBodyMotionState
  inertia : RigidBodyInertia
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyHingeJointFrameAssessment {
  frame_id : String
  body_count : Int
  joint_count : Int
  assessed_joint_count : Int
  review_count : Int
  max_position_error_m : Double
  max_angular_error_rad : Double
  linear_impulse_ns : Double
  angular_impulse_nms : Double
  joints : Array[RigidBodyHingeJointAssessment]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_joint_frame_body(
  state : RigidBodyMotionState,
  inertia : RigidBodyInertia,
) -> RigidBodyJointFrameBody {
  { body_id: state.body_id, state, inertia }
}

///|
fn rigid_body_joint_frame_find_body(
  bodies : Array[RigidBodyJointFrameBody],
  body_id : String,
) -> RigidBodyJointFrameBody {
  for body in bodies {
    if body.body_id == body_id {
      return body
    }
  }
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
fn hinge_joint_frame_status(
  assessed_joint_count : Int,
  review_count : Int,
  max_position_error_m : Double,
  max_angular_error_rad : Double,
) -> String {
  if review_count > 0 {
    "hinge-joint-frame-review"
  } else if assessed_joint_count <= 0 {
    "hinge-joint-frame-empty"
  } else if max_position_error_m > 0.000001 || max_angular_error_rad > 0.000001 {
    "hinge-joint-frame-correction-estimated"
  } else {
    "hinge-joint-frame-satisfied"
  }
}

///|
pub fn rigid_body_hinge_joint_frame_assessment(
  frame_id : String,
  bodies : Array[RigidBodyJointFrameBody],
  joints : Array[RigidBodyHingeJointConstraint],
) -> RigidBodyHingeJointFrameAssessment {
  let assessments : Array[RigidBodyHingeJointAssessment] = []
  let mut review_count = 0
  let mut max_position_error = 0.0
  let mut max_angular_error = 0.0
  let mut linear_impulse = 0.0
  let mut angular_impulse = 0.0
  for joint in joints {
    let body_a = rigid_body_joint_frame_find_body(
      bodies,
      joint.position.body_a_id,
    )
    let body_b = rigid_body_joint_frame_find_body(
      bodies,
      joint.position.body_b_id,
    )
    let assessment = rigid_body_hinge_joint_assessment(
      joint,
      body_a.state,
      body_a.inertia,
      body_b.state,
      body_b.inertia,
    )
    if assessment.status.contains("review") {
      review_count += 1
    }
    if assessment.position_error_m > max_position_error {
      max_position_error = assessment.position_error_m
    }
    if assessment.angular_error_rad > max_angular_error {
      max_angular_error = assessment.angular_error_rad
    }
    linear_impulse += assessment.linear_impulse_ns
    angular_impulse += assessment.angular_impulse_nms
    assessments.push(assessment)
  }
  {
    frame_id,
    body_count: bodies.length(),
    joint_count: joints.length(),
    assessed_joint_count: assessments.length(),
    review_count,
    max_position_error_m: max_position_error,
    max_angular_error_rad: max_angular_error,
    linear_impulse_ns: linear_impulse,
    angular_impulse_nms: angular_impulse,
    joints: assessments,
    status: hinge_joint_frame_status(
      assessments.length(),
      review_count,
      max_position_error,
      max_angular_error,
    ),
  }
}
