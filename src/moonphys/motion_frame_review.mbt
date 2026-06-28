///|
pub(all) struct MotionContactEvidence {
  contact_id : String
  footprint : SupportFootprint
  patch : HeightfieldContactPatch
  applied_force_n : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MotionContactReview {
  contact_id : String
  footprint_id : String
  patch_status : String
  load_status : String
  wrench_status : String
  traction_status : String
  normal_force_n : Double
  tangential_force_n : Double
  friction_utilization : Double
  max_pressure_pa : Double
  center_of_pressure : Vec3
  patch_load : ContactPatchLoadAssessment
  patch_wrench : ContactPatchWrenchAssessment
  traction : TractionAssessment
  ready : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MotionFrameReview {
  review_id : String
  contact_count : Int
  active_footprint_count : Int
  total_normal_force_n : Double
  patch_review_count : Int
  load_review_count : Int
  wrench_review_count : Int
  traction_review_count : Int
  support_status : String
  support_load_status : String
  capture_status : String
  min_support_margin_m : Double
  center_of_pressure_error_m : Double
  capture_margin_m : Double
  contact_reviews : Array[MotionContactReview]
  support : SupportAssessment
  support_load : SupportLoadAssessment
  capture : CapturePointAssessment
  blocker_count : Int
  blockers : Array[String]
  ready : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MotionFrameTraceReview {
  trace_id : String
  frame_count : Int
  ready_frame_count : Int
  blocked_frame_count : Int
  contact_count : Int
  contact_review_count : Int
  patch_review_count : Int
  load_review_count : Int
  wrench_review_count : Int
  traction_review_count : Int
  max_total_normal_force_n : Double
  max_contact_normal_force_n : Double
  max_contact_tangential_force_n : Double
  max_contact_force_n : Double
  max_contact_torque_nm : Double
  max_friction_utilization : Double
  max_pressure_pa : Double
  min_support_margin_m : Double
  worst_capture_margin_m : Double
  max_center_of_pressure_error_m : Double
  blocker_count : Int
  blockers : Array[String]
  ready : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn motion_contact_evidence(
  contact_id : String,
  footprint : SupportFootprint,
  patch : HeightfieldContactPatch,
  applied_force_n : Vec3,
) -> MotionContactEvidence {
  { contact_id, footprint, patch, applied_force_n }
}

///|
fn motion_status_has_review(status : String) -> Bool {
  status.contains("review") ||
  status.contains("no-") ||
  status.contains("clear") ||
  status.contains("outside") ||
  status.contains("invalid") ||
  status.contains("exceeded") ||
  status.contains("slip")
}

///|
fn motion_contact_ready(
  patch : HeightfieldContactPatch,
  load : ContactPatchLoadAssessment,
  wrench : ContactPatchWrenchAssessment,
  traction : TractionAssessment,
) -> Bool {
  !motion_status_has_review(patch.status) &&
  !motion_status_has_review(load.status) &&
  !motion_status_has_review(wrench.status) &&
  traction.status == "traction-ok"
}

///|
fn motion_contacts_total_normal_force(
  material : MaterialContactModel,
  contacts : Array[MotionContactEvidence],
) -> Double {
  let mut total = 0.0
  for contact in contacts {
    let traction = surface_traction_assessment(
      contact.contact_id,
      material,
      contact.applied_force_n,
      contact.patch.average_surface_normal,
    )
    total += traction.normal_force_n
  }
  total
}

///|
fn motion_active_footprints(
  contacts : Array[MotionContactEvidence],
) -> Array[SupportFootprint] {
  let footprints : Array[SupportFootprint] = []
  for contact in contacts {
    if contact.footprint.active {
      footprints.push(contact.footprint)
    }
  }
  footprints
}

///|
fn motion_contact_review(
  contact : MotionContactEvidence,
  material : MaterialContactModel,
) -> MotionContactReview {
  let traction = surface_traction_assessment(
    contact.contact_id,
    material,
    contact.applied_force_n,
    contact.patch.average_surface_normal,
  )
  let load = contact_patch_load_assessment(
    contact.patch,
    traction.normal_force_n,
  )
  let wrench = contact_patch_wrench_assessment(
    load,
    contact.footprint.center,
    contact.patch.average_surface_normal,
  )
  let ready = motion_contact_ready(contact.patch, load, wrench, traction)
  {
    contact_id: contact.contact_id,
    footprint_id: contact.footprint.footprint_id,
    patch_status: contact.patch.status,
    load_status: load.status,
    wrench_status: wrench.status,
    traction_status: traction.status,
    normal_force_n: traction.normal_force_n,
    tangential_force_n: traction.tangential_force_n,
    friction_utilization: traction.utilization,
    max_pressure_pa: load.max_pressure_pa,
    center_of_pressure: load.center_of_pressure,
    patch_load: load,
    patch_wrench: wrench,
    traction,
    ready,
    status: if ready {
      "motion-contact-ready"
    } else {
      "motion-contact-review"
    },
  }
}

///|
fn motion_frame_review_blockers(
  contacts : Array[MotionContactReview],
  support : SupportAssessment,
  support_load : SupportLoadAssessment,
  capture : CapturePointAssessment,
) -> Array[String] {
  let blockers : Array[String] = []
  if !support.stable {
    blockers.push("support:\{support.status}")
  }
  if !support_load.balanced {
    blockers.push("support-load:\{support_load.status}")
  }
  if !capture.stable {
    blockers.push("capture:\{capture.status}")
  }
  for contact in contacts {
    if !contact.ready {
      blockers.push("contact:\{contact.contact_id}:\{contact.status}")
    }
  }
  blockers
}

///|
fn motion_frame_review_status(blockers : Array[String]) -> String {
  if blockers.is_empty() {
    "motion-frame-review-ready"
  } else {
    "motion-frame-review-blocked"
  }
}

///|
fn motion_trace_blocker(frame_index : Int, blocker : String) -> String {
  "frame:\{frame_index}:\{blocker}"
}

///|
fn motion_frame_trace_status(
  frame_count : Int,
  blockers : Array[String],
) -> String {
  if frame_count == 0 {
    "motion-frame-trace-review-empty"
  } else if blockers.is_empty() {
    "motion-frame-trace-review-ready"
  } else {
    "motion-frame-trace-review-blocked"
  }
}

///|
fn motion_frame_trace_min_support(
  has_frame : Bool,
  current : Double,
  candidate : Double,
) -> Double {
  if !has_frame || candidate < current {
    candidate
  } else {
    current
  }
}

///|
fn motion_frame_trace_worst_capture(
  has_frame : Bool,
  current : Double,
  candidate : Double,
) -> Double {
  if !has_frame || candidate < current {
    candidate
  } else {
    current
  }
}

///|
pub fn motion_frame_review(
  review_id : String,
  environment : PhysicsEnvironment,
  material : MaterialContactModel,
  center_of_mass : Vec3,
  center_of_mass_velocity : Vec3,
  contacts : Array[MotionContactEvidence],
  total_normal_force_n? : Double = motion_contacts_total_normal_force(
    material, contacts,
  ),
  nominal_com_height_m? : Double = center_of_mass.z,
) -> MotionFrameReview {
  let footprints = motion_active_footprints(contacts)
  let support = support_assessment(center_of_mass, footprints)
  let support_load = support_load_assessment(
    center_of_mass, footprints, total_normal_force_n,
  )
  let capture = capture_point_assessment(
    environment,
    center_of_mass,
    center_of_mass_velocity,
    footprints,
    nominal_com_height_m~,
  )
  let contact_reviews : Array[MotionContactReview] = []
  let mut patch_review_count = 0
  let mut load_review_count = 0
  let mut wrench_review_count = 0
  let mut traction_review_count = 0
  for contact in contacts {
    let review = motion_contact_review(contact, material)
    if motion_status_has_review(review.patch_status) {
      patch_review_count += 1
    }
    if motion_status_has_review(review.load_status) {
      load_review_count += 1
    }
    if motion_status_has_review(review.wrench_status) {
      wrench_review_count += 1
    }
    if review.traction_status != "traction-ok" {
      traction_review_count += 1
    }
    contact_reviews.push(review)
  }
  let blockers = motion_frame_review_blockers(
    contact_reviews, support, support_load, capture,
  )
  {
    review_id,
    contact_count: contacts.length(),
    active_footprint_count: footprints.length(),
    total_normal_force_n,
    patch_review_count,
    load_review_count,
    wrench_review_count,
    traction_review_count,
    support_status: support.status,
    support_load_status: support_load.status,
    capture_status: capture.status,
    min_support_margin_m: support.planar_margin_m,
    center_of_pressure_error_m: support_load.center_of_pressure_error_m,
    capture_margin_m: capture.capture_margin_m,
    contact_reviews,
    support,
    support_load,
    capture,
    blocker_count: blockers.length(),
    blockers,
    ready: blockers.is_empty(),
    status: motion_frame_review_status(blockers),
  }
}

///|
pub fn motion_frame_trace_review(
  trace_id : String,
  frames : Array[MotionFrameReview],
) -> MotionFrameTraceReview {
  let blockers : Array[String] = []
  let mut ready_frame_count = 0
  let mut blocked_frame_count = 0
  let mut contact_count = 0
  let mut contact_review_count = 0
  let mut patch_review_count = 0
  let mut load_review_count = 0
  let mut wrench_review_count = 0
  let mut traction_review_count = 0
  let mut max_total_normal_force = 0.0
  let mut max_contact_normal_force = 0.0
  let mut max_contact_tangential_force = 0.0
  let mut max_contact_force = 0.0
  let mut max_contact_torque = 0.0
  let mut max_friction = 0.0
  let mut max_pressure = 0.0
  let mut min_support_margin = 0.0
  let mut worst_capture_margin = 0.0
  let mut max_center_of_pressure_error = 0.0
  let mut has_frame = false
  for frame_index in 0..<frames.length() {
    let frame = frames[frame_index]
    if frame.ready {
      ready_frame_count += 1
    } else {
      blocked_frame_count += 1
      for blocker in frame.blockers {
        blockers.push(motion_trace_blocker(frame_index, blocker))
      }
    }
    contact_count += frame.contact_count
    contact_review_count += frame.contact_reviews.length()
    patch_review_count += frame.patch_review_count
    load_review_count += frame.load_review_count
    wrench_review_count += frame.wrench_review_count
    traction_review_count += frame.traction_review_count
    max_total_normal_force = max_double(
      max_total_normal_force,
      frame.total_normal_force_n,
    )
    min_support_margin = motion_frame_trace_min_support(
      has_frame,
      min_support_margin,
      frame.min_support_margin_m,
    )
    worst_capture_margin = motion_frame_trace_worst_capture(
      has_frame,
      worst_capture_margin,
      frame.capture_margin_m,
    )
    max_center_of_pressure_error = max_double(
      max_center_of_pressure_error,
      frame.center_of_pressure_error_m,
    )
    has_frame = true
    for contact in frame.contact_reviews {
      max_contact_normal_force = max_double(
        max_contact_normal_force,
        contact.normal_force_n,
      )
      max_contact_tangential_force = max_double(
        max_contact_tangential_force,
        contact.tangential_force_n,
      )
      max_contact_force = max_double(
        max_contact_force,
        contact.patch_wrench.total_force_n.length(),
      )
      max_contact_torque = max_double(
        max_contact_torque,
        contact.patch_wrench.total_torque_nm.length(),
      )
      max_friction = max_double(max_friction, contact.friction_utilization)
      max_pressure = max_double(max_pressure, contact.max_pressure_pa)
    }
  }
  let status = motion_frame_trace_status(frames.length(), blockers)
  {
    trace_id,
    frame_count: frames.length(),
    ready_frame_count,
    blocked_frame_count,
    contact_count,
    contact_review_count,
    patch_review_count,
    load_review_count,
    wrench_review_count,
    traction_review_count,
    max_total_normal_force_n: max_total_normal_force,
    max_contact_normal_force_n: max_contact_normal_force,
    max_contact_tangential_force_n: max_contact_tangential_force,
    max_contact_force_n: max_contact_force,
    max_contact_torque_nm: max_contact_torque,
    max_friction_utilization: max_friction,
    max_pressure_pa: max_pressure,
    min_support_margin_m: min_support_margin,
    worst_capture_margin_m: worst_capture_margin,
    max_center_of_pressure_error_m: max_center_of_pressure_error,
    blocker_count: blockers.length(),
    blockers,
    ready: blockers.is_empty() && frames.length() > 0,
    status,
  }
}
