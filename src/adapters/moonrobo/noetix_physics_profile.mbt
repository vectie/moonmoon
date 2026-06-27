///|
pub(all) struct NoetixMassModel {
  model_id : String
  mass_kg : Double
  nominal_com_height_m : Double
  com_x_offset_m : Double
  com_y_offset_m : Double
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixFootGeometry {
  foot_id : String
  link_name : String
  half_length_m : Double
  half_width_m : Double
  sole_radius_m : Double
  friction_coefficient : Double
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixPhysicsProfile {
  profile_id : String
  robot_id : String
  source_model_path : String
  source_profile_path : String
  mass_model : NoetixMassModel
  foot_geometry : Array[NoetixFootGeometry]
  material_model : String
  hardware_authority : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixWalkStabilityFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  com_projection : @moonphys.Vec3
  support_assessment : @moonphys.SupportAssessment
  terrain_contact_status : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixWalkStabilityReport {
  report_id : String
  trace_id : String
  profile : NoetixPhysicsProfile
  frame_count : Int
  stable_frame_count : Int
  review_frame_count : Int
  worst_planar_margin_m : Double
  frames : Array[NoetixWalkStabilityFrame]
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_noetix_physics_profile() -> NoetixPhysicsProfile {
  let robot = noetix_moon_walk_robot_profile()
  {
    profile_id: "moonrobo/noetix-e1/physics-profile-v0",
    robot_id: robot.robot_id,
    source_model_path: robot.source_model_path,
    source_profile_path: robot.source_profile_path,
    mass_model: {
      model_id: "noetix-e1-assumed-lumped-mass-v0",
      mass_kg: 38.0,
      nominal_com_height_m: 0.72,
      com_x_offset_m: 0.0,
      com_y_offset_m: 0.0,
      source_status: "simulation-assumption; no inertial tags in referenced URDF/profile",
    },
    foot_geometry: [
      {
        foot_id: "left-foot",
        link_name: "left_foot",
        half_length_m: 0.11,
        half_width_m: 0.045,
        sole_radius_m: 0.012,
        friction_coefficient: 0.62,
        source_status: "simulation-assumption; URDF names link but omits sole collision geometry",
      },
      {
        foot_id: "right-foot",
        link_name: "right_foot",
        half_length_m: 0.11,
        half_width_m: 0.045,
        sole_radius_m: 0.012,
        friction_coefficient: 0.62,
        source_status: "simulation-assumption; URDF names link but omits sole collision geometry",
      },
    ],
    material_model: "dry-regolith-review-assumption",
    hardware_authority: "moonmoon-safety-gate-only",
    status: "review-only",
    note: "Mass, center of mass, foot sole geometry, and friction are explicit simulation assumptions until Moonrobo provides inertial/collision metadata.",
  }
}

///|
fn foot_geometry(
  profile : NoetixPhysicsProfile,
  foot_id : String,
) -> NoetixFootGeometry {
  for geometry in profile.foot_geometry {
    if geometry.foot_id == foot_id {
      return geometry
    }
  }
  profile.foot_geometry[0]
}

///|
fn contact_terrain_status(frame : NoetixMoonWalkFrame) -> String {
  if frame.left_foot.status == "ok" && frame.right_foot.status == "ok" {
    "terrain-contact-ok"
  } else {
    "terrain-contact-review"
  }
}

///|
fn stability_status(
  assessment : @moonphys.SupportAssessment,
  terrain_status : String,
) -> String {
  if assessment.stable && terrain_status == "terrain-contact-ok" {
    "static-margin-ok"
  } else if assessment.stable {
    "terrain-contact-review"
  } else {
    "static-margin-review"
  }
}

///|
fn contact_footprint(
  foot : NoetixFootContactProbe,
  geometry : NoetixFootGeometry,
) -> @moonphys.SupportFootprint {
  @moonphys.support_footprint(
    geometry.foot_id,
    foot.position,
    geometry.half_length_m,
    geometry.half_width_m,
    active=foot.in_contact,
  )
}

///|
pub fn noetix_walk_stability_frame(
  frame : NoetixMoonWalkFrame,
  profile : NoetixPhysicsProfile,
) -> NoetixWalkStabilityFrame {
  let com_projection = @moonphys.vec3(
    frame.body_position.x + profile.mass_model.com_x_offset_m,
    frame.body_position.y + profile.mass_model.com_y_offset_m,
    frame.body_position.z,
  )
  let left_geometry = foot_geometry(profile, "left-foot")
  let right_geometry = foot_geometry(profile, "right-foot")
  let assessment = @moonphys.support_assessment(com_projection, [
    contact_footprint(frame.left_foot, left_geometry),
    contact_footprint(frame.right_foot, right_geometry),
  ])
  let terrain_status = contact_terrain_status(frame)
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    com_projection,
    support_assessment: assessment,
    terrain_contact_status: terrain_status,
    status: stability_status(assessment, terrain_status),
  }
}

///|
pub fn noetix_walk_stability_report(
  trace : NoetixMoonWalkTrace,
  profile? : NoetixPhysicsProfile = default_noetix_physics_profile(),
) -> NoetixWalkStabilityReport {
  let frames : Array[NoetixWalkStabilityFrame] = []
  let mut stable_count = 0
  let mut worst_margin = 0.0
  for index, frame in trace.frames {
    let stability_frame = noetix_walk_stability_frame(frame, profile)
    if index == 0 ||
      stability_frame.support_assessment.planar_margin_m < worst_margin {
      worst_margin = stability_frame.support_assessment.planar_margin_m
    }
    if stability_frame.status == "static-margin-ok" {
      stable_count += 1
    }
    frames.push(stability_frame)
  }
  let review_count = frames.length() - stable_count
  {
    report_id: "moonrobo/noetix-e1/static-support/\{trace.terrain_tile_id}",
    trace_id: trace.trace_id,
    profile,
    frame_count: frames.length(),
    stable_frame_count: stable_count,
    review_frame_count: review_count,
    worst_planar_margin_m: worst_margin,
    frames,
    status: if review_count == 0 {
      "static-support-ok"
    } else {
      "static-support-review"
    },
    note: "Static support evidence only: dynamic walking can be valid with COM outside the instantaneous single-foot rectangle, but that requires a controller/dynamics model not yet present.",
  }
}

///|
pub fn first_trusted_square_noetix_stability_report() -> NoetixWalkStabilityReport {
  noetix_walk_stability_report(first_trusted_square_noetix_walk_trace())
}

///|
pub fn first_trusted_square_noetix_stability_json() -> Json {
  first_trusted_square_noetix_stability_report().to_json()
}

///|
pub fn render_noetix_stability_markdown(
  report : NoetixWalkStabilityReport,
) -> String {
  let mut text = "# Noetix Static Support Evidence\n\n"
  text += "- report: \{report.report_id}\n"
  text += "- trace: \{report.trace_id}\n"
  text += "- profile: \{report.profile.profile_id}\n"
  text += "- mass: \{report.profile.mass_model.mass_kg} kg (\{report.profile.mass_model.source_status})\n"
  text += "- frames: \{report.frame_count}\n"
  text += "- stable frames: \{report.stable_frame_count}\n"
  text += "- review frames: \{report.review_frame_count}\n"
  text += "- worst planar margin: \{report.worst_planar_margin_m} m\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.profile.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Frame Margins\n\n"
  for frame in report.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} margin=\{frame.support_assessment.planar_margin_m}m status=\{frame.status}\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_stability_markdown() -> String {
  render_noetix_stability_markdown(
    first_trusted_square_noetix_stability_report(),
  )
}
