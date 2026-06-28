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
  physical_model_readiness : @moonphys.PhysicalModelReadiness
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
  support_load_assessment : @moonphys.SupportLoadAssessment
  contact_patches : Array[@moonphys.HeightfieldContactPatch]
  contact_patch_loads : Array[@moonphys.ContactPatchLoadAssessment]
  contact_patch_status : String
  traction_assessments : Array[@moonphys.TractionAssessment]
  traction_status : String
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
  traction_review_frame_count : Int
  worst_planar_margin_m : Double
  worst_traction_margin_n : Double
  frames : Array[NoetixWalkStabilityFrame]
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn actuator_profile(
  source_limit : NoetixSourceJointLimit,
  inertia_kg_m2 : Double,
) -> NoetixJointActuatorProfile {
  {
    joint_name: source_limit.joint_name,
    joint_index: source_limit.joint_index,
    limit: @moonphys.joint_limit(
      source_limit.joint_name,
      source_limit.lower_rad,
      source_limit.upper_rad,
      source_limit.velocity_rad_s,
      source_limit.effort_nm,
    ),
    servo: @moonphys.joint_servo_config(
      source_limit.joint_name,
      source_limit.effort_nm * 0.25,
      source_limit.effort_nm * 0.02,
    ),
    inertia_kg_m2,
    source_status: "\{source_limit.source_status}; servo gains and inertia are simulation assumptions",
  }
}

///|
fn assumed_joint_inertia_kg_m2(joint_name : String) -> Double {
  match joint_name {
    "leg_l3_joint" | "leg_l4_joint" | "leg_r3_joint" | "leg_r4_joint" => 0.10
    "leg_l1_joint"
    | "leg_l2_joint"
    | "leg_l5_joint"
    | "leg_r1_joint"
    | "leg_r2_joint"
    | "leg_r5_joint" => 0.08
    "leg_l6_joint" | "leg_r6_joint" => 0.06
    "arm_l1_joint" | "arm_l2_joint" | "arm_r1_joint" | "arm_r2_joint" => 0.04
    "arm_l3_joint" | "arm_l4_joint" | "arm_r3_joint" | "arm_r4_joint" => 0.03
    "arm_l5_joint" | "arm_r5_joint" => 0.02
    "waist_1_joint" | "waist_2_joint" => 0.12
    _ => 0.05
  }
}

///|
pub fn noetix_joint_actuator_profiles() -> Array[NoetixJointActuatorProfile] {
  let profiles : Array[NoetixJointActuatorProfile] = []
  for source_limit in noetix_source_joint_limits() {
    profiles.push(
      actuator_profile(
        source_limit,
        assumed_joint_inertia_kg_m2(source_limit.joint_name),
      ),
    )
  }
  profiles
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
fn noetix_physical_model_readiness() -> @moonphys.PhysicalModelReadiness {
  @moonphys.physical_model_readiness(
    "moonrobo/noetix-e1/physical-model-readiness-v0",
    [
      "mass", "center-of-mass", "link-inertia", "collision-shapes", "foot-sole-geometry",
      "joint-effort-limits", "joint-velocity-limits", "joint-servo-gains", "joint-damping",
      "joint-stiffness", "friction",
    ],
    ["joint-effort-limits", "joint-velocity-limits"],
    [
      "mass", "center-of-mass", "link-inertia", "collision-shapes", "foot-sole-geometry",
      "joint-servo-gains", "friction",
    ],
  )
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
    physical_model_readiness: noetix_physical_model_readiness(),
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
  contact_patch_status : String,
  traction_status : String,
  terrain_status : String,
) -> String {
  if traction_status == "traction-review" {
    "traction-review"
  } else if contact_patch_status == "contact-patch-review" {
    "contact-patch-review"
  } else if assessment.stable && terrain_status == "terrain-contact-ok" {
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
fn contact_patch(
  field : @moonphys.Heightfield,
  foot : NoetixFootContactProbe,
  geometry : NoetixFootGeometry,
) -> @moonphys.HeightfieldContactPatch {
  @moonphys.heightfield_contact_patch(
    field,
    geometry.foot_id,
    foot.position,
    geometry.half_length_m,
    geometry.half_width_m,
  )
}

///|
fn contact_patch_status(
  patches : Array[@moonphys.HeightfieldContactPatch],
) -> String {
  for patch in patches {
    if patch.status == "patch-penetration-review" ||
      patch.status == "patch-partial-contact-review" {
      return "contact-patch-review"
    }
  }
  "contact-patch-ok"
}

///|
fn contact_patch_loads_for_frame(
  patches : Array[@moonphys.HeightfieldContactPatch],
  support_load : @moonphys.SupportLoadAssessment,
  left_geometry : NoetixFootGeometry,
  right_geometry : NoetixFootGeometry,
) -> Array[@moonphys.ContactPatchLoadAssessment] {
  [
    @moonphys.contact_patch_load_assessment(
      patches[0],
      support_load_normal_force(support_load, left_geometry.foot_id),
    ),
    @moonphys.contact_patch_load_assessment(
      patches[1],
      support_load_normal_force(support_load, right_geometry.foot_id),
    ),
  ]
}

///|
fn support_count_for_frame(frame : NoetixMoonWalkFrame) -> Int {
  let mut count = 0
  if frame.left_foot.in_contact {
    count += 1
  }
  if frame.right_foot.in_contact {
    count += 1
  }
  count
}

///|
fn noetix_lateral_speed(config : NoetixMoonWalkConfig) -> Double {
  let transfer_s = config.dt_s * config.double_support_frames.to_double()
  if transfer_s > 0.0 {
    config.support_lateral_shift_m * 2.0 / transfer_s
  } else {
    0.0
  }
}

///|
fn noetix_review_total_tangential_force_vector(
  frame : NoetixMoonWalkFrame,
  config : NoetixMoonWalkConfig,
  profile : NoetixPhysicsProfile,
  support_count : Int,
) -> @moonphys.Vec3 {
  if support_count <= 0 {
    @moonphys.vec3(0.0, 0.0, 0.0)
  } else {
    let cycle_s = config.dt_s * config.cycle_frames.to_double()
    if cycle_s > 0.0 {
      let lateral_direction = if frame.support_phase.contains("left") {
        1.0
      } else {
        0.0 - 1.0
      }
      noetix_heading_forward(config)
      .scale(config.speed_mps)
      .add(
        noetix_heading_lateral(config).scale(
          lateral_direction * noetix_lateral_speed(config),
        ),
      )
      .scale(profile.mass_model.mass_kg / cycle_s)
    } else {
      @moonphys.vec3(0.0, 0.0, 0.0)
    }
  }
}

///|
fn noetix_contact_material(
  geometry : NoetixFootGeometry,
) -> @moonphys.MaterialContactModel {
  @moonphys.material_contact_model(
    "\{geometry.foot_id}/review-friction",
    geometry.friction_coefficient,
    @moonphys.lunar_regolith_contact_model().restitution_coefficient,
  )
}

///|
fn foot_traction_assessment(
  foot : NoetixFootContactProbe,
  geometry : NoetixFootGeometry,
  normal_force_n : Double,
  tangential_force_n : @moonphys.Vec3,
  surface_normal : @moonphys.Vec3,
) -> @moonphys.TractionAssessment {
  let applied_force = if foot.in_contact {
    surface_normal.scale(normal_force_n).add(tangential_force_n)
  } else {
    @moonphys.vec3(0.0, 0.0, 0.0)
  }
  @moonphys.surface_traction_assessment(
    geometry.foot_id,
    noetix_contact_material(geometry),
    applied_force,
    surface_normal,
  )
}

///|
fn traction_assessments_for_frame(
  frame : NoetixMoonWalkFrame,
  config : NoetixMoonWalkConfig,
  profile : NoetixPhysicsProfile,
  left_geometry : NoetixFootGeometry,
  right_geometry : NoetixFootGeometry,
  support_load : @moonphys.SupportLoadAssessment,
  patches : Array[@moonphys.HeightfieldContactPatch],
) -> Array[@moonphys.TractionAssessment] {
  let support_count = support_count_for_frame(frame)
  let tangential_force = noetix_review_total_tangential_force_vector(
    frame, config, profile, support_count,
  )
  let left_fraction = support_load_fraction(support_load, left_geometry.foot_id)
  let right_fraction = support_load_fraction(
    support_load,
    right_geometry.foot_id,
  )
  [
    foot_traction_assessment(
      frame.left_foot,
      left_geometry,
      support_load_normal_force(support_load, left_geometry.foot_id),
      tangential_force.scale(left_fraction),
      patches[0].average_surface_normal,
    ),
    foot_traction_assessment(
      frame.right_foot,
      right_geometry,
      support_load_normal_force(support_load, right_geometry.foot_id),
      tangential_force.scale(right_fraction),
      patches[1].average_surface_normal,
    ),
  ]
}

///|
fn support_load_normal_force(
  assessment : @moonphys.SupportLoadAssessment,
  foot_id : String,
) -> Double {
  for load in assessment.loads {
    if load.footprint_id == foot_id {
      return load.normal_force_n
    }
  }
  0.0
}

///|
fn support_load_fraction(
  assessment : @moonphys.SupportLoadAssessment,
  foot_id : String,
) -> Double {
  for load in assessment.loads {
    if load.footprint_id == foot_id {
      return load.load_fraction
    }
  }
  0.0
}

///|
fn traction_status(assessments : Array[@moonphys.TractionAssessment]) -> String {
  for assessment in assessments {
    if assessment.slipping {
      return "traction-review"
    }
  }
  "traction-ok"
}

///|
pub fn noetix_walk_stability_frame(
  frame : NoetixMoonWalkFrame,
  profile : NoetixPhysicsProfile,
  field? : @moonphys.Heightfield = first_trusted_square_noetix_heightfield(),
  config? : NoetixMoonWalkConfig = default_noetix_moon_walk_config(),
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
  let support_load = @moonphys.support_load_assessment(
    com_projection,
    [
      contact_footprint(frame.left_foot, left_geometry),
      contact_footprint(frame.right_foot, right_geometry),
    ],
    profile.mass_model.mass_kg * @moonphys.lunar_environment().gravity_mps2,
  )
  let patches = [
    contact_patch(field, frame.left_foot, left_geometry),
    contact_patch(field, frame.right_foot, right_geometry),
  ]
  let contact_patch_status = contact_patch_status(patches)
  let contact_patch_loads = contact_patch_loads_for_frame(
    patches, support_load, left_geometry, right_geometry,
  )
  let traction = traction_assessments_for_frame(
    frame, config, profile, left_geometry, right_geometry, support_load, patches,
  )
  let traction_status = traction_status(traction)
  let terrain_status = contact_terrain_status(frame)
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    com_projection,
    support_assessment: assessment,
    support_load_assessment: support_load,
    contact_patches: patches,
    contact_patch_loads,
    contact_patch_status,
    traction_assessments: traction,
    traction_status,
    terrain_contact_status: terrain_status,
    status: stability_status(
      assessment, contact_patch_status, traction_status, terrain_status,
    ),
  }
}

///|
pub fn noetix_walk_stability_report(
  trace : NoetixMoonWalkTrace,
  field? : @moonphys.Heightfield = first_trusted_square_noetix_heightfield(),
  profile? : NoetixPhysicsProfile = default_noetix_physics_profile(),
) -> NoetixWalkStabilityReport {
  let frames : Array[NoetixWalkStabilityFrame] = []
  let mut stable_count = 0
  let mut traction_review_count = 0
  let mut worst_margin = 0.0
  let mut worst_traction_margin = 0.0
  let mut has_loaded_traction = false
  for index, frame in trace.frames {
    let stability_frame = noetix_walk_stability_frame(
      frame,
      profile,
      field~,
      config=trace.config,
    )
    if index == 0 ||
      stability_frame.support_assessment.planar_margin_m < worst_margin {
      worst_margin = stability_frame.support_assessment.planar_margin_m
    }
    for traction in stability_frame.traction_assessments {
      if traction.normal_force_n > 0.0 &&
        (!has_loaded_traction || traction.margin_n < worst_traction_margin) {
        worst_traction_margin = traction.margin_n
        has_loaded_traction = true
      }
    }
    if stability_frame.status == "static-margin-ok" {
      stable_count += 1
    }
    if stability_frame.traction_status == "traction-review" {
      traction_review_count += 1
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
    traction_review_frame_count: traction_review_count,
    worst_planar_margin_m: worst_margin,
    worst_traction_margin_n: worst_traction_margin,
    frames,
    status: if review_count == 0 {
      "static-support-ok"
    } else {
      "static-support-review"
    },
    note: "Static support, contact-patch, and traction evidence only: dynamic walking can be valid with COM outside the instantaneous single-foot rectangle, but that requires a controller/dynamics model not yet present. Contact patches use Moonphys heightfield patch sampling and patch-load pressure review over assumed foot soles, and traction margins use Moonphys terrain-normal force projection plus friction-cone review over assumed foot friction.",
  }
}

///|
pub fn first_trusted_square_noetix_stability_report() -> NoetixWalkStabilityReport {
  let field = first_trusted_square_noetix_heightfield()
  noetix_walk_stability_report(first_trusted_square_noetix_walk_trace(), field~)
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
  text += "- traction-review frames: \{report.traction_review_frame_count}\n"
  text += "- worst planar margin: \{report.worst_planar_margin_m} m\n"
  text += "- worst traction margin: \{report.worst_traction_margin_n} N\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.profile.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Frame Margins\n\n"
  for frame in report.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} margin=\{frame.support_assessment.planar_margin_m}m patch=\{frame.contact_patch_status} traction=\{frame.traction_status} status=\{frame.status}\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_stability_markdown() -> String {
  render_noetix_stability_markdown(
    first_trusted_square_noetix_stability_report(),
  )
}
