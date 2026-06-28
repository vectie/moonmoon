///|
pub(all) struct RigidBodyWorldDynamicSupportFrame {
  frame_index : Int
  time_s : Double
  body_count : Int
  contact_count : Int
  center_of_mass : Vec3
  center_of_mass_velocity : Vec3
  capture_point_assessment : CapturePointAssessment
  capture_support_recovery : SupportRecoveryCorrection
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldDynamicSupportTrace {
  trace_id : String
  frame_count : Int
  body_count : Int
  contact_count : Int
  capture_stable_frame_count : Int
  review_frame_count : Int
  worst_capture_margin_m : Double
  max_capture_recovery_shift_m : Double
  frames : Array[RigidBodyWorldDynamicSupportFrame]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn rigid_body_world_dynamic_support_frame_status(
  assessment : CapturePointAssessment,
) -> String {
  if assessment.stable {
    "world-capture-point-stable"
  } else {
    "world-capture-point-review"
  }
}

///|
fn rigid_body_world_dynamic_support_trace_status(
  frame_count : Int,
  review_count : Int,
) -> String {
  if frame_count <= 0 {
    "world-dynamic-support-trace-empty"
  } else if review_count > 0 {
    "world-dynamic-support-trace-review"
  } else {
    "world-dynamic-support-trace-stable"
  }
}

///|
pub fn rigid_body_world_dynamic_support_frame(
  step : RigidBodyHeightfieldWorldStep,
) -> RigidBodyWorldDynamicSupportFrame {
  let support_frame = rigid_body_world_support_frame(step)
  let center = rigid_body_world_center_of_mass(step.after)
  let velocity = rigid_body_world_center_of_mass_velocity(step.after)
  let assessment = capture_point_assessment(
    step.after.environment,
    center,
    velocity,
    support_frame.footprints,
  )
  let recovery = support_recovery_correction(
    assessment.capture_point,
    support_frame.footprints,
  )
  {
    frame_index: step.frame_index,
    time_s: step.time_s,
    body_count: step.body_count,
    contact_count: support_frame.contact_count,
    center_of_mass: center,
    center_of_mass_velocity: velocity,
    capture_point_assessment: assessment,
    capture_support_recovery: recovery,
    status: rigid_body_world_dynamic_support_frame_status(assessment),
  }
}

///|
fn rigid_body_world_dynamic_support_trace_from_frames(
  trace_id : String,
  body_count : Int,
  steps : Array[RigidBodyHeightfieldWorldStep],
) -> RigidBodyWorldDynamicSupportTrace {
  let frames : Array[RigidBodyWorldDynamicSupportFrame] = []
  let mut contact_count = 0
  let mut stable_count = 0
  let mut review_count = 0
  let mut worst_margin = 0.0
  let mut max_recovery_shift = 0.0
  for index, step in steps {
    let frame = rigid_body_world_dynamic_support_frame(step)
    contact_count += frame.contact_count
    if frame.capture_point_assessment.stable {
      stable_count += 1
    } else {
      review_count += 1
    }
    if index == 0 ||
      frame.capture_point_assessment.capture_margin_m < worst_margin {
      worst_margin = frame.capture_point_assessment.capture_margin_m
    }
    if frame.capture_support_recovery.required_shift_m > max_recovery_shift {
      max_recovery_shift = frame.capture_support_recovery.required_shift_m
    }
    frames.push(frame)
  }
  {
    trace_id,
    frame_count: steps.length(),
    body_count,
    contact_count,
    capture_stable_frame_count: stable_count,
    review_frame_count: review_count,
    worst_capture_margin_m: worst_margin,
    max_capture_recovery_shift_m: max_recovery_shift,
    frames,
    status: rigid_body_world_dynamic_support_trace_status(
      frames.length(),
      review_count,
    ),
  }
}

///|
pub fn rigid_body_heightfield_world_dynamic_support_trace(
  trace : RigidBodyHeightfieldWorldTrace,
) -> RigidBodyWorldDynamicSupportTrace {
  rigid_body_world_dynamic_support_trace_from_frames(
    trace.trace_id,
    trace.final_world.bodies.length(),
    trace.frames,
  )
}

///|
pub fn rigid_body_heightfield_world_hinge_motor_dynamic_support_trace(
  trace : RigidBodyHeightfieldWorldHingeMotorTrace,
) -> RigidBodyWorldDynamicSupportTrace {
  let steps : Array[RigidBodyHeightfieldWorldStep] = []
  for frame in trace.frames {
    steps.push(frame.world_step)
  }
  rigid_body_world_dynamic_support_trace_from_frames(
    trace.trace_id,
    trace.final_world.bodies.length(),
    steps,
  )
}
