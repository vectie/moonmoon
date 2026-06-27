///|
pub(all) struct NoetixDynamicStabilityFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  com_position : @moonphys.Vec3
  com_velocity : @moonphys.Vec3
  capture_point_assessment : @moonphys.CapturePointAssessment
  terrain_contact_status : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixDynamicStabilityReport {
  report_id : String
  trace_id : String
  source_static_support_report_id : String
  profile : NoetixPhysicsProfile
  frame_count : Int
  capture_stable_frame_count : Int
  review_frame_count : Int
  worst_capture_margin_m : Double
  frames : Array[NoetixDynamicStabilityFrame]
  hardware_authority : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn body_velocity(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
) -> @moonphys.Vec3 {
  if trace.frames.length() < 2 {
    @moonphys.vec3(0.0, 0.0, 0.0)
  } else {
    let current = trace.frames[frame_index]
    let reference = if frame_index == 0 {
      trace.frames[1]
    } else {
      trace.frames[frame_index - 1]
    }
    let dt = if frame_index == 0 {
      reference.time_s - current.time_s
    } else {
      current.time_s - reference.time_s
    }
    if dt > 0.0 {
      if frame_index == 0 {
        reference.body_position.sub(current.body_position).scale(1.0 / dt)
      } else {
        current.body_position.sub(reference.body_position).scale(1.0 / dt)
      }
    } else {
      @moonphys.vec3(0.0, 0.0, 0.0)
    }
  }
}

///|
fn dynamic_status(
  assessment : @moonphys.CapturePointAssessment,
  terrain_status : String,
) -> String {
  if assessment.stable && terrain_status == "terrain-contact-ok" {
    "capture-point-ok"
  } else if assessment.stable {
    "terrain-contact-review"
  } else {
    "capture-point-review"
  }
}

///|
pub fn noetix_dynamic_stability_frame(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> NoetixDynamicStabilityFrame {
  let frame = trace.frames[frame_index]
  let com_position = @moonphys.vec3(
    frame.body_position.x + profile.mass_model.com_x_offset_m,
    frame.body_position.y + profile.mass_model.com_y_offset_m,
    frame.body_position.z,
  )
  let left_geometry = foot_geometry(profile, "left-foot")
  let right_geometry = foot_geometry(profile, "right-foot")
  let assessment = @moonphys.capture_point_assessment(
    @moonphys.lunar_environment(),
    com_position,
    body_velocity(trace, frame_index),
    [
      contact_footprint(frame.left_foot, left_geometry),
      contact_footprint(frame.right_foot, right_geometry),
    ],
    nominal_com_height_m=profile.mass_model.nominal_com_height_m,
  )
  let terrain_status = contact_terrain_status(frame)
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    com_position,
    com_velocity: assessment.com_velocity,
    capture_point_assessment: assessment,
    terrain_contact_status: terrain_status,
    status: dynamic_status(assessment, terrain_status),
  }
}

///|
pub fn noetix_dynamic_stability_report(
  trace : NoetixMoonWalkTrace,
  profile? : NoetixPhysicsProfile = default_noetix_physics_profile(),
) -> NoetixDynamicStabilityReport {
  let frames : Array[NoetixDynamicStabilityFrame] = []
  let mut stable_count = 0
  let mut worst_margin = 0.0
  for index, _frame in trace.frames {
    let dynamic_frame = noetix_dynamic_stability_frame(trace, index, profile)
    if index == 0 ||
      dynamic_frame.capture_point_assessment.capture_margin_m < worst_margin {
      worst_margin = dynamic_frame.capture_point_assessment.capture_margin_m
    }
    if dynamic_frame.status == "capture-point-ok" {
      stable_count += 1
    }
    frames.push(dynamic_frame)
  }
  let review_count = frames.length() - stable_count
  {
    report_id: "moonrobo/noetix-e1/dynamic-stability/\{trace.terrain_tile_id}",
    trace_id: trace.trace_id,
    source_static_support_report_id: noetix_walk_stability_report(
      trace,
      profile~,
    ).report_id,
    profile,
    frame_count: frames.length(),
    capture_stable_frame_count: stable_count,
    review_frame_count: review_count,
    worst_capture_margin_m: worst_margin,
    frames,
    hardware_authority: profile.hardware_authority,
    status: if review_count == 0 {
      "dynamic-stability-ok"
    } else {
      "dynamic-stability-review"
    },
    note: "Capture-point evidence evaluates COM velocity against the support footprint under lunar gravity. It is still review evidence only: no controller, actuator, inertia, collision, or hardware authority is implied.",
  }
}

///|
pub fn first_trusted_square_noetix_dynamic_stability_report() -> NoetixDynamicStabilityReport {
  noetix_dynamic_stability_report(first_trusted_square_noetix_walk_trace())
}

///|
pub fn first_trusted_square_noetix_dynamic_stability_json() -> Json {
  first_trusted_square_noetix_dynamic_stability_report().to_json()
}

///|
pub fn render_noetix_dynamic_stability_markdown(
  report : NoetixDynamicStabilityReport,
) -> String {
  let mut text = "# Noetix Dynamic Stability Evidence\n\n"
  text += "- report: \{report.report_id}\n"
  text += "- trace: \{report.trace_id}\n"
  text += "- static support source: \{report.source_static_support_report_id}\n"
  text += "- profile: \{report.profile.profile_id}\n"
  text += "- frames: \{report.frame_count}\n"
  text += "- capture-stable frames: \{report.capture_stable_frame_count}\n"
  text += "- review frames: \{report.review_frame_count}\n"
  text += "- worst capture margin: \{report.worst_capture_margin_m} m\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Frame Capture Margins\n\n"
  for frame in report.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} capture_margin=\{frame.capture_point_assessment.capture_margin_m}m status=\{frame.status}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_dynamic_stability_markdown() -> String {
  render_noetix_dynamic_stability_markdown(
    first_trusted_square_noetix_dynamic_stability_report(),
  )
}
