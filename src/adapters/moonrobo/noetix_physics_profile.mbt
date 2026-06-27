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
pub(all) struct NoetixJointActuatorProfile {
  joint_name : String
  joint_index : Int
  limit : @moonphys.JointLimit
  servo : @moonphys.JointServoConfig
  inertia_kg_m2 : Double
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixCollisionShapeProfile {
  link_name : String
  shape : @moonphys.CollisionShape
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
  actuator_profiles : Array[NoetixJointActuatorProfile]
  collision_shapes : Array[NoetixCollisionShapeProfile]
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
fn actuator_profile(
  joint_name : String,
  joint_index : Int,
  lower_rad : Double,
  upper_rad : Double,
  effort_nm : Double,
  velocity_rad_s : Double,
  inertia_kg_m2 : Double,
) -> NoetixJointActuatorProfile {
  {
    joint_name,
    joint_index,
    limit: @moonphys.joint_limit(
      joint_name, lower_rad, upper_rad, velocity_rad_s, effort_nm,
    ),
    servo: @moonphys.joint_servo_config(
      joint_name,
      effort_nm * 0.25,
      effort_nm * 0.02,
    ),
    inertia_kg_m2,
    source_status: "urdf-limit-tag; servo gains and inertia are simulation assumptions",
  }
}

///|
pub fn noetix_joint_actuator_profiles() -> Array[NoetixJointActuatorProfile] {
  [
    actuator_profile("arm_l1_joint", 0, -1.8, 1.8, 45.0, 3.0, 0.04),
    actuator_profile("arm_l2_joint", 1, -1.6, 1.6, 45.0, 3.0, 0.04),
    actuator_profile("arm_l3_joint", 2, -1.8, 1.8, 35.0, 3.0, 0.03),
    actuator_profile("arm_l4_joint", 3, -1.6, 1.6, 30.0, 3.0, 0.03),
    actuator_profile("arm_l5_joint", 4, -1.2, 1.2, 20.0, 3.0, 0.02),
    actuator_profile("leg_l1_joint", 5, -1.2, 1.2, 90.0, 3.0, 0.08),
    actuator_profile("leg_l2_joint", 6, -0.9, 0.9, 90.0, 3.0, 0.08),
    actuator_profile("leg_l3_joint", 7, -1.6, 1.6, 100.0, 3.0, 0.10),
    actuator_profile("leg_l4_joint", 8, -1.8, 1.8, 100.0, 3.0, 0.10),
    actuator_profile("leg_l5_joint", 9, -0.8, 0.8, 80.0, 3.0, 0.08),
    actuator_profile("leg_l6_joint", 10, -0.8, 0.8, 80.0, 3.0, 0.06),
    actuator_profile("arm_r1_joint", 11, -1.8, 1.8, 45.0, 3.0, 0.04),
    actuator_profile("arm_r2_joint", 12, -1.6, 1.6, 45.0, 3.0, 0.04),
    actuator_profile("arm_r3_joint", 13, -1.8, 1.8, 35.0, 3.0, 0.03),
    actuator_profile("arm_r4_joint", 14, -1.6, 1.6, 30.0, 3.0, 0.03),
    actuator_profile("arm_r5_joint", 15, -1.2, 1.2, 20.0, 3.0, 0.02),
    actuator_profile("leg_r1_joint", 16, -1.2, 1.2, 90.0, 3.0, 0.08),
    actuator_profile("leg_r2_joint", 17, -0.9, 0.9, 90.0, 3.0, 0.08),
    actuator_profile("leg_r3_joint", 18, -1.6, 1.6, 100.0, 3.0, 0.10),
    actuator_profile("leg_r4_joint", 19, -1.8, 1.8, 100.0, 3.0, 0.10),
    actuator_profile("leg_r5_joint", 20, -0.8, 0.8, 80.0, 3.0, 0.08),
    actuator_profile("leg_r6_joint", 21, -0.8, 0.8, 80.0, 3.0, 0.06),
    actuator_profile("waist_1_joint", 22, -0.8, 0.8, 80.0, 2.0, 0.12),
    actuator_profile("waist_2_joint", 23, -0.5, 0.5, 80.0, 2.0, 0.12),
  ]
}

///|
fn collision_shape_profile(
  link_name : String,
  shape : @moonphys.CollisionShape,
  source_status : String,
) -> NoetixCollisionShapeProfile {
  { link_name, shape, source_status }
}

///|
fn collision_shape_from_source_visual(
  geometry : NoetixSourceVisualGeometry,
) -> NoetixCollisionShapeProfile {
  match geometry.kind {
    SourceMeshGeometry | SourceBoxGeometry =>
      collision_shape_profile(
        geometry.link_name,
        @moonphys.collision_box(
          "\{geometry.link_name}/urdf-visual-bounds",
          geometry.size_m.scale(0.5),
        ),
        geometry.source_status,
      )
    SourceCylinderGeometry =>
      collision_shape_profile(
        geometry.link_name,
        @moonphys.collision_capsule(
          "\{geometry.link_name}/urdf-visual-cylinder",
          geometry.radius_m,
          geometry.length_m * 0.5,
        ),
        geometry.source_status,
      )
  }
}

///|
fn noetix_collision_shape_profiles(
  left_foot : NoetixFootGeometry,
  right_foot : NoetixFootGeometry,
) -> Array[NoetixCollisionShapeProfile] {
  let shapes : Array[NoetixCollisionShapeProfile] = []
  for geometry in noetix_source_visual_geometries() {
    shapes.push(collision_shape_from_source_visual(geometry))
  }
  shapes.push(
    collision_shape_profile(
      left_foot.link_name,
      @moonphys.collision_box(
        "\{left_foot.link_name}/assumed-sole",
        @moonphys.vec3(
          left_foot.half_length_m,
          left_foot.half_width_m,
          left_foot.sole_radius_m,
        ),
      ),
      left_foot.source_status,
    ),
  )
  shapes.push(
    collision_shape_profile(
      right_foot.link_name,
      @moonphys.collision_box(
        "\{right_foot.link_name}/assumed-sole",
        @moonphys.vec3(
          right_foot.half_length_m,
          right_foot.half_width_m,
          right_foot.sole_radius_m,
        ),
      ),
      right_foot.source_status,
    ),
  )
  shapes
}

///|
pub fn default_noetix_physics_profile() -> NoetixPhysicsProfile {
  let robot = noetix_moon_walk_robot_profile()
  let left_foot : NoetixFootGeometry = {
    foot_id: "left-foot",
    link_name: "left_foot",
    half_length_m: 0.11,
    half_width_m: 0.045,
    sole_radius_m: 0.012,
    friction_coefficient: 0.62,
    source_status: "simulation-assumption; URDF names link but omits sole collision geometry",
  }
  let right_foot : NoetixFootGeometry = {
    foot_id: "right-foot",
    link_name: "right_foot",
    half_length_m: 0.11,
    half_width_m: 0.045,
    sole_radius_m: 0.012,
    friction_coefficient: 0.62,
    source_status: "simulation-assumption; URDF names link but omits sole collision geometry",
  }
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
    foot_geometry: [left_foot, right_foot],
    actuator_profiles: noetix_joint_actuator_profiles(),
    collision_shapes: noetix_collision_shape_profiles(left_foot, right_foot),
    material_model: "dry-regolith-review-assumption",
    hardware_authority: "moonmoon-safety-gate-only",
    status: "review-only",
    note: "URDF joint limits and visual geometry are represented as Moonphys review data. Mass, center of mass, servo gains, inertia, foot sole geometry, friction, and collision tags remain explicit simulation assumptions until Moonrobo provides inertial/collision metadata.",
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
  text += "- actuator profiles: \{report.profile.actuator_profiles.length()} URDF joint limits\n"
  text += "- collision profiles: \{report.profile.collision_shapes.length()} review shapes\n"
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
