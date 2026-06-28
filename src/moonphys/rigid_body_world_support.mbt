///|
pub(all) struct RigidBodyWorldSupportFrame {
  frame_index : Int
  time_s : Double
  body_count : Int
  contact_count : Int
  total_mass_kg : Double
  center_of_mass : Vec3
  footprints : Array[SupportFootprint]
  support : SupportAssessment
  recovery : SupportRecoveryCorrection
  load : SupportLoadAssessment
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyWorldSupportTrace {
  trace_id : String
  frame_count : Int
  body_count : Int
  support_frame_count : Int
  contact_count : Int
  stable_frame_count : Int
  review_frame_count : Int
  min_planar_margin_m : Double
  max_support_recovery_shift_m : Double
  max_center_of_pressure_error_m : Double
  frames : Array[RigidBodyWorldSupportFrame]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn rigid_body_world_support_frame_status(
  support : SupportAssessment,
  load : SupportLoadAssessment,
) -> String {
  if support.support_count <= 0 {
    "world-support-no-contact"
  } else if !support.stable {
    "world-support-margin-review"
  } else if load.status.contains("review") {
    "world-support-load-review"
  } else {
    "world-support-stable"
  }
}

///|
fn rigid_body_world_support_trace_status(
  frame_count : Int,
  review_count : Int,
) -> String {
  if frame_count <= 0 {
    "world-support-trace-empty"
  } else if review_count > 0 {
    "world-support-trace-review"
  } else {
    "world-support-trace-stable"
  }
}

///|
fn rigid_body_world_support_footprint(
  body_frame : RigidBodyWorldBodyFrame,
) -> SupportFootprint {
  let collision = body_frame.resolution.collision
  support_footprint(
    body_frame.body_id,
    collision.contact_point,
    body_frame.after.collision_radius_m,
    body_frame.after.collision_radius_m,
    active=collision.in_contact,
  )
}

///|
fn rigid_body_world_support_frame_footprints(
  step : RigidBodyHeightfieldWorldStep,
) -> Array[SupportFootprint] {
  let footprints : Array[SupportFootprint] = []
  for body_frame in step.body_frames {
    footprints.push(rigid_body_world_support_footprint(body_frame))
  }
  footprints
}

///|
fn rigid_body_world_support_contact_count(
  footprints : Array[SupportFootprint],
) -> Int {
  let mut contact_count = 0
  for footprint in footprints {
    if footprint.active {
      contact_count += 1
    }
  }
  contact_count
}

///|
pub fn rigid_body_world_support_frame_with_footprints(
  step : RigidBodyHeightfieldWorldStep,
  footprints : Array[SupportFootprint],
) -> RigidBodyWorldSupportFrame {
  let center = rigid_body_world_center_of_mass(step.after)
  let support = support_assessment(center, footprints)
  let recovery = support_recovery_correction(center, footprints)
  let total_mass = rigid_body_world_total_mass(step.after)
  let load = support_load_assessment(
    center,
    footprints,
    total_mass * step.after.environment.gravity_mps2,
  )
  {
    frame_index: step.frame_index,
    time_s: step.time_s,
    body_count: step.body_count,
    contact_count: rigid_body_world_support_contact_count(footprints),
    total_mass_kg: total_mass,
    center_of_mass: center,
    footprints,
    support,
    recovery,
    load,
    status: rigid_body_world_support_frame_status(support, load),
  }
}

///|
pub fn rigid_body_world_support_frame(
  step : RigidBodyHeightfieldWorldStep,
) -> RigidBodyWorldSupportFrame {
  rigid_body_world_support_frame_with_footprints(
    step,
    rigid_body_world_support_frame_footprints(step),
  )
}

///|
fn rigid_body_world_support_trace_from_frames(
  trace_id : String,
  body_count : Int,
  steps : Array[RigidBodyHeightfieldWorldStep],
) -> RigidBodyWorldSupportTrace {
  let frames : Array[RigidBodyWorldSupportFrame] = []
  let mut contact_count = 0
  let mut stable_count = 0
  let mut review_count = 0
  let mut max_recovery_shift = 0.0
  let mut max_center_error = 0.0
  let mut min_margin = 0.0
  let mut has_margin = false
  for step in steps {
    let frame = rigid_body_world_support_frame(step)
    contact_count += frame.contact_count
    if frame.support.stable {
      stable_count += 1
    }
    if frame.status.contains("review") || frame.status.contains("no-contact") {
      review_count += 1
    }
    if !has_margin || frame.support.planar_margin_m < min_margin {
      min_margin = frame.support.planar_margin_m
      has_margin = true
    }
    if frame.recovery.required_shift_m > max_recovery_shift {
      max_recovery_shift = frame.recovery.required_shift_m
    }
    if frame.load.center_of_pressure_error_m > max_center_error {
      max_center_error = frame.load.center_of_pressure_error_m
    }
    frames.push(frame)
  }
  {
    trace_id,
    frame_count: steps.length(),
    body_count,
    support_frame_count: frames.length(),
    contact_count,
    stable_frame_count: stable_count,
    review_frame_count: review_count,
    min_planar_margin_m: min_margin,
    max_support_recovery_shift_m: max_recovery_shift,
    max_center_of_pressure_error_m: max_center_error,
    frames,
    status: rigid_body_world_support_trace_status(frames.length(), review_count),
  }
}

///|
fn rigid_body_world_support_trace_target_footprints(
  footprint_frames : Array[Array[SupportFootprint]],
  index : Int,
) -> Array[SupportFootprint] {
  if index < footprint_frames.length() {
    footprint_frames[index]
  } else {
    []
  }
}

///|
fn rigid_body_world_support_trace_from_footprint_frames(
  trace_id : String,
  body_count : Int,
  steps : Array[RigidBodyHeightfieldWorldStep],
  footprint_frames : Array[Array[SupportFootprint]],
) -> RigidBodyWorldSupportTrace {
  let frames : Array[RigidBodyWorldSupportFrame] = []
  let mut contact_count = 0
  let mut stable_count = 0
  let mut review_count = 0
  let mut max_recovery_shift = 0.0
  let mut max_center_error = 0.0
  let mut min_margin = 0.0
  let mut has_margin = false
  for index, step in steps {
    let target_footprints = rigid_body_world_support_trace_target_footprints(
      footprint_frames, index,
    )
    let frame = if target_footprints.is_empty() {
      rigid_body_world_support_frame(step)
    } else {
      rigid_body_world_support_frame_with_footprints(step, target_footprints)
    }
    contact_count += frame.contact_count
    if frame.support.stable {
      stable_count += 1
    }
    if frame.status.contains("review") || frame.status.contains("no-contact") {
      review_count += 1
    }
    if !has_margin || frame.support.planar_margin_m < min_margin {
      min_margin = frame.support.planar_margin_m
      has_margin = true
    }
    if frame.recovery.required_shift_m > max_recovery_shift {
      max_recovery_shift = frame.recovery.required_shift_m
    }
    if frame.load.center_of_pressure_error_m > max_center_error {
      max_center_error = frame.load.center_of_pressure_error_m
    }
    frames.push(frame)
  }
  {
    trace_id,
    frame_count: steps.length(),
    body_count,
    support_frame_count: frames.length(),
    contact_count,
    stable_frame_count: stable_count,
    review_frame_count: review_count,
    min_planar_margin_m: min_margin,
    max_support_recovery_shift_m: max_recovery_shift,
    max_center_of_pressure_error_m: max_center_error,
    frames,
    status: rigid_body_world_support_trace_status(frames.length(), review_count),
  }
}

///|
pub fn rigid_body_heightfield_world_support_trace(
  trace : RigidBodyHeightfieldWorldTrace,
) -> RigidBodyWorldSupportTrace {
  rigid_body_world_support_trace_from_frames(
    trace.trace_id,
    trace.final_world.bodies.length(),
    trace.frames,
  )
}

///|
pub fn rigid_body_heightfield_world_support_trace_with_footprints(
  trace : RigidBodyHeightfieldWorldTrace,
  footprint_frames : Array[Array[SupportFootprint]],
) -> RigidBodyWorldSupportTrace {
  rigid_body_world_support_trace_from_footprint_frames(
    trace.trace_id,
    trace.final_world.bodies.length(),
    trace.frames,
    footprint_frames,
  )
}

///|
pub fn rigid_body_heightfield_world_hinge_motor_support_trace(
  trace : RigidBodyHeightfieldWorldHingeMotorTrace,
) -> RigidBodyWorldSupportTrace {
  let steps : Array[RigidBodyHeightfieldWorldStep] = []
  for frame in trace.frames {
    steps.push(frame.world_step)
  }
  rigid_body_world_support_trace_from_frames(
    trace.trace_id,
    trace.final_world.bodies.length(),
    steps,
  )
}

///|
pub fn rigid_body_heightfield_world_hinge_motor_support_trace_with_footprints(
  trace : RigidBodyHeightfieldWorldHingeMotorTrace,
  footprint_frames : Array[Array[SupportFootprint]],
) -> RigidBodyWorldSupportTrace {
  let steps : Array[RigidBodyHeightfieldWorldStep] = []
  for frame in trace.frames {
    steps.push(frame.world_step)
  }
  rigid_body_world_support_trace_from_footprint_frames(
    trace.trace_id,
    trace.final_world.bodies.length(),
    steps,
    footprint_frames,
  )
}
