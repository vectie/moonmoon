///|
pub(all) enum NoetixSourceGeometryKind {
  SourceMeshGeometry
  SourceBoxGeometry
  SourceCylinderGeometry
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSourceVisualGeometry {
  link_name : String
  kind : NoetixSourceGeometryKind
  size_m : @moonphys.Vec3
  radius_m : Double
  length_m : Double
  mesh_path : String
  origin_xyz_m : @moonphys.Vec3
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSourceJointLimit {
  joint_name : String
  joint_index : Int
  lower_rad : Double
  upper_rad : Double
  effort_nm : Double
  velocity_rad_s : Double
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSourceMetadataGap {
  blocker_id : String
  link_name : String
  metadata_kind : String
  current_status : String
  source_path : String
  required_evidence : String
  target_artifact_path : String
  acceptance_check : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSourceModelReport {
  report_id : String
  robot_id : String
  source_model_path : String
  source_profile_path : String
  link_count : Int
  joint_count : Int
  visual_geometry_count : Int
  mesh_asset_count : Int
  collision_tag_count : Int
  inertial_tag_count : Int
  missing_collision_link_count : Int
  missing_inertial_link_count : Int
  source_metadata_blocker_count : Int
  source_metadata_blocker_ids : Array[String]
  source_metadata_inventory : @moonphys.ModelMetadataInventory
  source_metadata_gaps : Array[NoetixSourceMetadataGap]
  joint_limit_count : Int
  low_level_joint_control_enabled : Bool
  high_level_walk_requires_approval : Bool
  visual_geometries : Array[NoetixSourceVisualGeometry]
  joint_limits : Array[NoetixSourceJointLimit]
  missing_collision_links : Array[String]
  missing_inertial_links : Array[String]
  hardware_authority : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn source_box_geometry(
  link_name : String,
  size_m : @moonphys.Vec3,
  origin_xyz_m : @moonphys.Vec3,
) -> NoetixSourceVisualGeometry {
  {
    link_name,
    kind: SourceBoxGeometry,
    size_m,
    radius_m: 0.0,
    length_m: 0.0,
    mesh_path: "",
    origin_xyz_m,
    source_status: "urdf-visual-box",
  }
}

///|
fn source_cylinder_geometry(
  link_name : String,
  radius_m : Double,
  length_m : Double,
  origin_xyz_m : @moonphys.Vec3,
) -> NoetixSourceVisualGeometry {
  {
    link_name,
    kind: SourceCylinderGeometry,
    size_m: @moonphys.vec3(0.0, 0.0, 0.0),
    radius_m,
    length_m,
    mesh_path: "",
    origin_xyz_m,
    source_status: "urdf-visual-cylinder",
  }
}

///|
fn source_mesh_geometry(
  link_name : String,
  mesh_path : String,
  size_m : @moonphys.Vec3,
  origin_xyz_m : @moonphys.Vec3,
) -> NoetixSourceVisualGeometry {
  {
    link_name,
    kind: SourceMeshGeometry,
    size_m,
    radius_m: 0.0,
    length_m: 0.0,
    mesh_path,
    origin_xyz_m,
    source_status: "urdf-visual-mesh; bounds derived from referenced obj vertices",
  }
}

///|
pub fn noetix_source_visual_geometries() -> Array[NoetixSourceVisualGeometry] {
  [
    source_mesh_geometry(
      "base_link",
      "../moonrobo/examples/noetix-e1/model/meshes/base.obj",
      @moonphys.vec3(0.24, 0.20, 0.04),
      @moonphys.vec3(0.0, 0.0, 0.0),
    ),
    source_box_geometry(
      "torso_link",
      @moonphys.vec3(0.22, 0.16, 0.18),
      @moonphys.vec3(0.0, 0.0, 0.08),
    ),
    source_box_geometry(
      "chest_link",
      @moonphys.vec3(0.28, 0.34, 0.18),
      @moonphys.vec3(0.0, 0.0, 0.08),
    ),
    source_cylinder_geometry(
      "left_arm_1",
      0.035,
      0.12,
      @moonphys.vec3(0.0, 0.0, -0.05),
    ),
    source_cylinder_geometry(
      "right_arm_1",
      0.035,
      0.12,
      @moonphys.vec3(0.0, 0.0, -0.05),
    ),
    source_cylinder_geometry(
      "left_leg_1",
      0.045,
      0.14,
      @moonphys.vec3(0.0, 0.0, -0.06),
    ),
  ]
}

///|
fn source_joint_limit(
  joint_name : String,
  joint_index : Int,
  lower_rad : Double,
  upper_rad : Double,
  effort_nm : Double,
  velocity_rad_s : Double,
) -> NoetixSourceJointLimit {
  {
    joint_name,
    joint_index,
    lower_rad,
    upper_rad,
    effort_nm,
    velocity_rad_s,
    source_status: "urdf-limit-tag",
  }
}

///|
pub fn noetix_source_joint_limits() -> Array[NoetixSourceJointLimit] {
  [
    source_joint_limit("arm_l1_joint", 0, -1.8, 1.8, 45.0, 3.0),
    source_joint_limit("arm_l2_joint", 1, -1.6, 1.6, 45.0, 3.0),
    source_joint_limit("arm_l3_joint", 2, -1.8, 1.8, 35.0, 3.0),
    source_joint_limit("arm_l4_joint", 3, -1.6, 1.6, 30.0, 3.0),
    source_joint_limit("arm_l5_joint", 4, -1.2, 1.2, 20.0, 3.0),
    source_joint_limit("leg_l1_joint", 5, -1.2, 1.2, 90.0, 3.0),
    source_joint_limit("leg_l2_joint", 6, -0.9, 0.9, 90.0, 3.0),
    source_joint_limit("leg_l3_joint", 7, -1.6, 1.6, 100.0, 3.0),
    source_joint_limit("leg_l4_joint", 8, -1.8, 1.8, 100.0, 3.0),
    source_joint_limit("leg_l5_joint", 9, -0.8, 0.8, 80.0, 3.0),
    source_joint_limit("leg_l6_joint", 10, -0.8, 0.8, 80.0, 3.0),
    source_joint_limit("arm_r1_joint", 11, -1.8, 1.8, 45.0, 3.0),
    source_joint_limit("arm_r2_joint", 12, -1.6, 1.6, 45.0, 3.0),
    source_joint_limit("arm_r3_joint", 13, -1.8, 1.8, 35.0, 3.0),
    source_joint_limit("arm_r4_joint", 14, -1.6, 1.6, 30.0, 3.0),
    source_joint_limit("arm_r5_joint", 15, -1.2, 1.2, 20.0, 3.0),
    source_joint_limit("leg_r1_joint", 16, -1.2, 1.2, 90.0, 3.0),
    source_joint_limit("leg_r2_joint", 17, -0.9, 0.9, 90.0, 3.0),
    source_joint_limit("leg_r3_joint", 18, -1.6, 1.6, 100.0, 3.0),
    source_joint_limit("leg_r4_joint", 19, -1.8, 1.8, 100.0, 3.0),
    source_joint_limit("leg_r5_joint", 20, -0.8, 0.8, 80.0, 3.0),
    source_joint_limit("leg_r6_joint", 21, -0.8, 0.8, 80.0, 3.0),
    source_joint_limit("waist_1_joint", 22, -0.8, 0.8, 80.0, 2.0),
    source_joint_limit("waist_2_joint", 23, -0.5, 0.5, 80.0, 2.0),
  ]
}

///|
fn source_metadata_gap(
  blocker_id : String,
  link_name : String,
  metadata_kind : String,
  source_path : String,
  required_evidence : String,
  target_artifact_path : String,
  acceptance_check : String,
  next_action : String,
) -> NoetixSourceMetadataGap {
  {
    blocker_id,
    link_name,
    metadata_kind,
    current_status: "missing",
    source_path,
    required_evidence,
    target_artifact_path,
    acceptance_check,
    next_action,
  }
}

///|
fn noetix_source_metadata_gaps(
  robot : NoetixMoonWalkRobotProfile,
  missing_collision_links : Array[String],
  missing_inertial_links : Array[String],
) -> Array[NoetixSourceMetadataGap] {
  let gaps : Array[NoetixSourceMetadataGap] = []
  for link in missing_collision_links {
    gaps.push(
      source_metadata_gap(
        "missing-collision-shape:\{link}",
        link,
        "collision-shape",
        robot.source_model_path,
        "URDF <collision> geometry or an authoritative Moonrobo collision-shape manifest for link \{link}",
        "output/moonrobo/first_trusted_square_noetix_source_model.json",
        "python3 scripts/check_moonrobo_noetix_source_model.py output/moonrobo/first_trusted_square_noetix_source_model.json && python3 scripts/check_moonrobo_noetix_source_sync.py output/moonrobo/first_trusted_square_noetix_source_model.json output/moonrobo/first_trusted_square_noetix_walk_command.json",
        "Add source collision metadata for \{link}, regenerate the Noetix source-model audit, and keep hardware denied.",
      ),
    )
  }
  for link in missing_inertial_links {
    gaps.push(
      source_metadata_gap(
        "missing-inertial:\{link}",
        link,
        "inertial",
        robot.source_model_path,
        "URDF <inertial> mass, origin, and inertia tensor or an authoritative Moonrobo inertial manifest for link \{link}",
        "output/moonrobo/first_trusted_square_noetix_source_model.json",
        "python3 scripts/check_moonrobo_noetix_source_model.py output/moonrobo/first_trusted_square_noetix_source_model.json && python3 scripts/check_moonrobo_noetix_source_sync.py output/moonrobo/first_trusted_square_noetix_source_model.json output/moonrobo/first_trusted_square_noetix_walk_command.json",
        "Add source inertial metadata for \{link}, regenerate the Noetix source-model audit, and keep hardware denied.",
      ),
    )
  }
  gaps
}

///|
pub fn noetix_source_model_report() -> NoetixSourceModelReport {
  let robot = noetix_moon_walk_robot_profile()
  let visuals = noetix_source_visual_geometries()
  let joint_limits = noetix_source_joint_limits()
  let link_names : Array[String] = []
  let missing_collision_links : Array[String] = []
  let missing_inertial_links : Array[String] = []
  for link in noetix_reference_links() {
    link_names.push(link.link_name)
    missing_collision_links.push(link.link_name)
    missing_inertial_links.push(link.link_name)
  }
  let metadata_inventory = @moonphys.model_metadata_inventory(
    "noetix-e1-source-model",
    link_names,
    [],
    [],
  )
  let source_metadata_gaps = noetix_source_metadata_gaps(
    robot, missing_collision_links, missing_inertial_links,
  )
  {
    report_id: "moonrobo/noetix-e1/source-model/audit-v0",
    robot_id: robot.robot_id,
    source_model_path: robot.source_model_path,
    source_profile_path: robot.source_profile_path,
    link_count: noetix_reference_links().length(),
    joint_count: robot.joint_count,
    visual_geometry_count: visuals.length(),
    mesh_asset_count: 1,
    collision_tag_count: 0,
    inertial_tag_count: 0,
    missing_collision_link_count: missing_collision_links.length(),
    missing_inertial_link_count: missing_inertial_links.length(),
    source_metadata_blocker_count: metadata_inventory.blocker_count,
    source_metadata_blocker_ids: metadata_inventory.blocker_ids,
    source_metadata_inventory: metadata_inventory,
    source_metadata_gaps,
    joint_limit_count: joint_limits.length(),
    low_level_joint_control_enabled: false,
    high_level_walk_requires_approval: true,
    visual_geometries: visuals,
    joint_limits,
    missing_collision_links,
    missing_inertial_links,
    hardware_authority: "moonmoon-safety-gate-only",
    status: "source-model-metadata-blocked",
    note: "Sibling Moonrobo Noetix source model provides URDF joint limits and visual geometry, including a placeholder base mesh, but exposes no authoritative collision or inertial tags for any link. Moonphys collision/inertia reports must therefore remain review-only until Moonrobo publishes those tags.",
  }
}

///|
pub fn first_trusted_square_noetix_source_model_report() -> NoetixSourceModelReport {
  noetix_source_model_report()
}

///|
pub fn first_trusted_square_noetix_source_model_json() -> Json {
  first_trusted_square_noetix_source_model_report().to_json()
}

///|
pub fn render_noetix_source_model_markdown(
  report : NoetixSourceModelReport,
) -> String {
  let mut text = "# Noetix Source Model Audit\n\n"
  text += "- report: \{report.report_id}\n"
  text += "- robot: \{report.robot_id}\n"
  text += "- source model: \{report.source_model_path}\n"
  text += "- source profile: \{report.source_profile_path}\n"
  text += "- links: \{report.link_count}\n"
  text += "- joints: \{report.joint_count}\n"
  text += "- visual geometries: \{report.visual_geometry_count}\n"
  text += "- collision tags: \{report.collision_tag_count}\n"
  text += "- inertial tags: \{report.inertial_tag_count}\n"
  text += "- missing collision links: \{report.missing_collision_link_count}\n"
  text += "- missing inertial links: \{report.missing_inertial_link_count}\n"
  text += "- source metadata blockers: \{report.source_metadata_blocker_count}\n"
  text += "- source metadata inventory: \{report.source_metadata_inventory.status}\n"
  text += "- source metadata gaps: \{report.source_metadata_gaps.length()}\n"
  text += "- joint limits: \{report.joint_limit_count}\n"
  text += "- low-level joint control enabled: \{report.low_level_joint_control_enabled}\n"
  text += "- high-level walk requires approval: \{report.high_level_walk_requires_approval}\n"
  text += "- status: \{report.status}\n"
  text += "- hardware authority: \{report.hardware_authority}\n"
  text += "- note: \{report.note}\n\n"
  text += "## Visual Geometry\n\n"
  for geometry in report.visual_geometries {
    text += "- \{geometry.link_name}: \{geometry.source_status}\n"
  }
  text += "\n## Metadata Blockers\n\n"
  text += "- blocker ids: \{report.source_metadata_blocker_ids.join(", ")}\n"
  text += "- missing collision links: \{report.missing_collision_links.join(", ")}\n"
  text += "- missing inertial links: \{report.missing_inertial_links.join(", ")}\n"
  text += "\n## Joint Limits\n\n"
  for limit in report.joint_limits {
    text += "- \{limit.joint_name}[\{limit.joint_index}]: lower=\{limit.lower_rad} upper=\{limit.upper_rad} effort=\{limit.effort_nm} velocity=\{limit.velocity_rad_s} source=\{limit.source_status}\n"
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_source_model_markdown() -> String {
  render_noetix_source_model_markdown(
    first_trusted_square_noetix_source_model_report(),
  )
}
