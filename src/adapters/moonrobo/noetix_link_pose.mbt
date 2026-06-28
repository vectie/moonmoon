///|
pub(all) struct NoetixReferenceLink {
  link_name : String
  parent_link : String
  joint_name : String
  role : String
  side : String
  nominal_parent_offset_m : @moonphys.Vec3
  joint_axis : @moonphys.Vec3
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkVisualGeometryEvidence {
  link_name : String
  has_visual_geometry : Bool
  kind : NoetixSourceGeometryKind
  size_m : @moonphys.Vec3
  radius_m : Double
  length_m : Double
  mesh_path : String
  local_origin_xyz_m : @moonphys.Vec3
  world_origin_xyz_m : @moonphys.Vec3
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkPhysicalMetadataEvidence {
  link_name : String
  has_collision_metadata : Bool
  has_inertial_metadata : Bool
  collision_source_status : String
  inertial_source_status : String
  collision_blocker_id : String
  inertial_blocker_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkPose {
  link_name : String
  parent_link : String
  joint_name : String
  role : String
  side : String
  nominal_parent_offset_m : @moonphys.Vec3
  joint_axis : @moonphys.Vec3
  joint_position_rad : Double
  fk_world_position : @moonphys.Vec3
  world_position : @moonphys.Vec3
  contact_error_m : Double
  visual_geometry : NoetixLinkVisualGeometryEvidence
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkPoseFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  body_position : @moonphys.Vec3
  robot_rig_id : String
  motion_id : String
  rig_pose_status : String
  links : Array[NoetixLinkPose]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkPoseTrace {
  trace_id : String
  source_walk_trace_id : String
  robot_id : String
  source_model_path : String
  robot_rig_id : String
  robot_rig_status : String
  motion_frame_source : String
  rig_motion_contract_status : String
  frame_count : Int
  links_per_frame : Int
  visual_geometry_link_count : Int
  mesh_visual_geometry_link_count : Int
  primitive_visual_geometry_link_count : Int
  collision_metadata_link_count : Int
  inertial_metadata_link_count : Int
  missing_collision_link_count : Int
  missing_inertial_link_count : Int
  physical_metadata : Array[NoetixLinkPhysicalMetadataEvidence]
  frames : Array[NoetixLinkPoseFrame]
  rig_render_contract_status : String
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn reference_link(
  link_name : String,
  parent_link : String,
  joint_name : String,
  role : String,
  side : String,
  x : Double,
  y : Double,
  z : Double,
  axis_x : Double,
  axis_y : Double,
  axis_z : Double,
) -> NoetixReferenceLink {
  {
    link_name,
    parent_link,
    joint_name,
    role,
    side,
    nominal_parent_offset_m: @moonphys.vec3(x, y, z),
    joint_axis: @moonphys.vec3(axis_x, axis_y, axis_z),
    source_status: "urdf-reference-joint-origin",
  }
}

///|
pub fn noetix_reference_links() -> Array[NoetixReferenceLink] {
  [
    reference_link(
      "base_link", "", "", "body", "center", 0.0, 0.0, 0.0, 0.0, 0.0, 1.0,
    ),
    reference_link(
      "torso_link", "base_link", "waist_1_joint", "body", "center", 0.0, 0.0, 0.32,
      0.0, 0.0, 1.0,
    ),
    reference_link(
      "chest_link", "torso_link", "waist_2_joint", "body", "center", 0.0, 0.0, 0.18,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "left_arm_1", "chest_link", "arm_l1_joint", "arm", "left", 0.0, 0.16, 0.12,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "left_arm_2", "left_arm_1", "arm_l2_joint", "arm", "left", 0.0, 0.10, -0.10,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "left_arm_3", "left_arm_2", "arm_l3_joint", "arm", "left", 0.0, 0.0, -0.16,
      0.0, 0.0, 1.0,
    ),
    reference_link(
      "left_arm_4", "left_arm_3", "arm_l4_joint", "arm", "left", 0.0, 0.0, -0.15,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "left_hand", "left_arm_4", "arm_l5_joint", "hand", "left", 0.0, 0.0, -0.12,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "right_arm_1", "chest_link", "arm_r1_joint", "arm", "right", 0.0, -0.16, 0.12,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "right_arm_2", "right_arm_1", "arm_r2_joint", "arm", "right", 0.0, -0.10, -0.10,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "right_arm_3", "right_arm_2", "arm_r3_joint", "arm", "right", 0.0, 0.0, -0.16,
      0.0, 0.0, 1.0,
    ),
    reference_link(
      "right_arm_4", "right_arm_3", "arm_r4_joint", "arm", "right", 0.0, 0.0, -0.15,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "right_hand", "right_arm_4", "arm_r5_joint", "hand", "right", 0.0, 0.0, -0.12,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "left_leg_1", "base_link", "leg_l1_joint", "leg", "left", 0.0, 0.08, -0.08,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "left_leg_2", "left_leg_1", "leg_l2_joint", "leg", "left", 0.0, 0.0, -0.16,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "left_leg_3", "left_leg_2", "leg_l3_joint", "leg", "left", 0.0, 0.0, -0.16,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "left_leg_4", "left_leg_3", "leg_l4_joint", "leg", "left", 0.0, 0.0, -0.18,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "left_leg_5", "left_leg_4", "leg_l5_joint", "leg", "left", 0.0, 0.0, -0.16,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "left_foot", "left_leg_5", "leg_l6_joint", "foot", "left", 0.04, 0.0, -0.08,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "right_leg_1", "base_link", "leg_r1_joint", "leg", "right", 0.0, -0.08, -0.08,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "right_leg_2", "right_leg_1", "leg_r2_joint", "leg", "right", 0.0, 0.0, -0.16,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "right_leg_3", "right_leg_2", "leg_r3_joint", "leg", "right", 0.0, 0.0, -0.16,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "right_leg_4", "right_leg_3", "leg_r4_joint", "leg", "right", 0.0, 0.0, -0.18,
      0.0, 1.0, 0.0,
    ),
    reference_link(
      "right_leg_5", "right_leg_4", "leg_r5_joint", "leg", "right", 0.0, 0.0, -0.16,
      1.0, 0.0, 0.0,
    ),
    reference_link(
      "right_foot", "right_leg_5", "leg_r6_joint", "foot", "right", 0.04, 0.0, -0.08,
      0.0, 1.0, 0.0,
    ),
  ]
}

///|
fn contact_position(
  frame : NoetixMoonWalkFrame,
  side : String,
) -> @moonphys.Vec3 {
  if side == "left" {
    frame.left_foot.position
  } else {
    frame.right_foot.position
  }
}

///|
fn position_error_m(a : @moonphys.Vec3, b : @moonphys.Vec3) -> Double {
  a.sub(b).length_squared().sqrt()
}

///|
fn source_visual_geometry_for_link(
  link_name : String,
) -> NoetixSourceVisualGeometry? {
  for geometry in noetix_source_visual_geometries() {
    if geometry.link_name == link_name {
      return Some(geometry)
    }
  }
  None
}

///|
fn link_physical_metadata_evidence(
  link_name : String,
  report : NoetixSourceModelReport,
) -> NoetixLinkPhysicalMetadataEvidence {
  let missing_collision = report.missing_collision_links.contains(link_name)
  let missing_inertial = report.missing_inertial_links.contains(link_name)
  {
    link_name,
    has_collision_metadata: !missing_collision,
    has_inertial_metadata: !missing_inertial,
    collision_source_status: if missing_collision {
      "urdf-collision-metadata-missing"
    } else {
      "urdf-collision-metadata-present"
    },
    inertial_source_status: if missing_inertial {
      "urdf-inertial-metadata-missing"
    } else {
      "urdf-inertial-metadata-present"
    },
    collision_blocker_id: if missing_collision {
      "missing-collision-shape:\{link_name}"
    } else {
      ""
    },
    inertial_blocker_id: if missing_inertial {
      "missing-inertial:\{link_name}"
    } else {
      ""
    },
  }
}

///|
fn source_physical_metadata_evidence(
  links : Array[NoetixReferenceLink],
  report : NoetixSourceModelReport,
) -> Array[NoetixLinkPhysicalMetadataEvidence] {
  let metadata : Array[NoetixLinkPhysicalMetadataEvidence] = []
  for link in links {
    metadata.push(link_physical_metadata_evidence(link.link_name, report))
  }
  metadata
}

///|
fn visual_geometry_count_by_kind(kind : NoetixSourceGeometryKind) -> Int {
  let mut count = 0
  for geometry in noetix_source_visual_geometries() {
    if geometry.kind == kind {
      count += 1
    }
  }
  count
}

///|
fn link_visual_geometry_evidence(
  link : NoetixReferenceLink,
  transform : @moonphys.Transform3,
) -> NoetixLinkVisualGeometryEvidence {
  match source_visual_geometry_for_link(link.link_name) {
    Some(geometry) =>
      {
        link_name: link.link_name,
        has_visual_geometry: true,
        kind: geometry.kind,
        size_m: geometry.size_m,
        radius_m: geometry.radius_m,
        length_m: geometry.length_m,
        mesh_path: geometry.mesh_path,
        local_origin_xyz_m: geometry.origin_xyz_m,
        world_origin_xyz_m: transform.transform_point(geometry.origin_xyz_m),
        source_status: geometry.source_status,
      }
    None =>
      {
        link_name: link.link_name,
        has_visual_geometry: false,
        kind: SourceBoxGeometry,
        size_m: @moonphys.vec3(0.0, 0.0, 0.0),
        radius_m: 0.0,
        length_m: 0.0,
        mesh_path: "",
        local_origin_xyz_m: @moonphys.vec3(0.0, 0.0, 0.0),
        world_origin_xyz_m: transform.translation,
        source_status: "urdf-visual-geometry-missing",
      }
  }
}

///|
fn link_pose(
  link : NoetixReferenceLink,
  joint_position : Double,
  transform : @moonphys.Transform3,
  fk_world_position : @moonphys.Vec3,
  world_position : @moonphys.Vec3,
  contact_error_m : Double,
) -> NoetixLinkPose {
  {
    link_name: link.link_name,
    parent_link: link.parent_link,
    joint_name: link.joint_name,
    role: link.role,
    side: link.side,
    nominal_parent_offset_m: link.nominal_parent_offset_m,
    joint_axis: link.joint_axis,
    joint_position_rad: joint_position,
    fk_world_position,
    world_position,
    contact_error_m,
    visual_geometry: link_visual_geometry_evidence(link, transform),
    source_status: if link.role == "foot" {
      "urdf-fk-contact-bound"
    } else {
      "urdf-forward-kinematics"
    },
  }
}

///|
pub fn noetix_link_pose_frame(
  frame : NoetixMoonWalkFrame,
) -> NoetixLinkPoseFrame {
  let reference_links = noetix_reference_links()
  let links : Array[NoetixLinkPose] = []
  let rig = noetix_robot_rig()
  let motion = noetix_robot_motion_frame(frame)
  let rig_pose = robot_rig_pose_frame(rig, motion)
  for link in reference_links {
    let joint_position = robot_rig_pose_link_joint_position(
      rig_pose,
      link.link_name,
    )
    let transform = robot_rig_pose_link_transform(rig_pose, link.link_name)
    let fk_position = transform.translation
    let world_position = if link.role == "foot" {
      contact_position(frame, link.side)
    } else {
      fk_position
    }
    let contact_error = if link.role == "foot" {
      position_error_m(fk_position, world_position)
    } else {
      0.0
    }
    links.push(
      link_pose(
        link, joint_position, transform, fk_position, world_position, contact_error,
      ),
    )
  }
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    body_position: frame.body_position,
    robot_rig_id: rig.rig_id,
    motion_id: motion.motion_id,
    rig_pose_status: rig_pose.status,
    links,
    status: "review-only-urdf-fk",
  }
}

///|
pub fn noetix_link_pose_trace(
  trace : NoetixMoonWalkTrace,
) -> NoetixLinkPoseTrace {
  let frames : Array[NoetixLinkPoseFrame] = []
  let source_model = noetix_source_model_report()
  let reference_links = noetix_reference_links()
  let rig = noetix_robot_rig()
  let mesh_visuals = visual_geometry_count_by_kind(SourceMeshGeometry)
  let box_visuals = visual_geometry_count_by_kind(SourceBoxGeometry)
  let cylinder_visuals = visual_geometry_count_by_kind(SourceCylinderGeometry)
  for frame in trace.frames {
    frames.push(noetix_link_pose_frame(frame))
  }
  {
    trace_id: "moonrobo/noetix-e1/link-poses/\{trace.terrain_tile_id}",
    source_walk_trace_id: trace.trace_id,
    robot_id: trace.robot.robot_id,
    source_model_path: trace.robot.source_model_path,
    robot_rig_id: rig.rig_id,
    robot_rig_status: rig.status,
    motion_frame_source: "planned-gait-joint-samples",
    rig_motion_contract_status: if rig.status == "urdf-rigid-rig-ready" &&
      frames.length() == trace.frame_count {
      "robot-rig-motion-contract-ready"
    } else {
      "robot-rig-motion-contract-review"
    },
    frame_count: frames.length(),
    links_per_frame: reference_links.length(),
    visual_geometry_link_count: source_model.visual_geometry_count,
    mesh_visual_geometry_link_count: mesh_visuals,
    primitive_visual_geometry_link_count: box_visuals + cylinder_visuals,
    collision_metadata_link_count: source_model.source_metadata_inventory.collision_shape_link_count,
    inertial_metadata_link_count: source_model.source_metadata_inventory.inertial_link_count,
    missing_collision_link_count: source_model.missing_collision_link_count,
    missing_inertial_link_count: source_model.missing_inertial_link_count,
    physical_metadata: source_physical_metadata_evidence(
      reference_links, source_model,
    ),
    frames,
    rig_render_contract_status: if source_model.visual_geometry_count > 0 &&
      mesh_visuals > 0 &&
      box_visuals > 0 &&
      cylinder_visuals > 0 {
      "urdf-rigid-visual-contract-ready"
    } else {
      "urdf-rigid-visual-contract-incomplete"
    },
    status: "review-only",
    note: "URDF-reference forward-kinematics evidence for visualization and review: link names, joint origins, joint axes, available source visual geometry, and explicit missing collision/inertial metadata come from the Noetix URDF/source audit. Moonrobo now exposes this through a RobotRig plus RobotMotionFrame contract, mirroring the useful separation in Piccolo-style animation while keeping Noetix links rigid and robot-authored. The rigid render contract carries one mesh visual and primitive box/cylinder visuals as the primary robot body; debug sticks are only a link-tree overlay. Moonphys evaluates the generic articulated pose tree, then feet are bound to Moonphys contact probes and carry FK contact error. This is not full dynamics, collision, inertia, controller evidence, or hardware authority.",
  }
}

///|
pub fn first_trusted_square_noetix_link_pose_trace() -> NoetixLinkPoseTrace {
  noetix_link_pose_trace(first_trusted_square_noetix_walk_trace())
}

///|
pub fn first_trusted_square_noetix_link_pose_json() -> Json {
  first_trusted_square_noetix_link_pose_trace().to_json()
}

///|
pub fn render_noetix_link_pose_markdown(trace : NoetixLinkPoseTrace) -> String {
  let mut text = "# Noetix Link Pose Evidence\n\n"
  text += "- trace: \{trace.trace_id}\n"
  text += "- source walk trace: \{trace.source_walk_trace_id}\n"
  text += "- robot: \{trace.robot_id}\n"
  text += "- source model: \{trace.source_model_path}\n"
  text += "- robot rig: \{trace.robot_rig_id}\n"
  text += "- robot rig status: \{trace.robot_rig_status}\n"
  text += "- motion frame source: \{trace.motion_frame_source}\n"
  text += "- rig motion contract: \{trace.rig_motion_contract_status}\n"
  text += "- frames: \{trace.frame_count}\n"
  text += "- links per frame: \{trace.links_per_frame}\n"
  text += "- visual geometry links: \{trace.visual_geometry_link_count}\n"
  text += "- mesh visual geometry links: \{trace.mesh_visual_geometry_link_count}\n"
  text += "- primitive visual geometry links: \{trace.primitive_visual_geometry_link_count}\n"
  text += "- rig render contract: \{trace.rig_render_contract_status}\n"
  text += "- collision metadata links: \{trace.collision_metadata_link_count}\n"
  text += "- inertial metadata links: \{trace.inertial_metadata_link_count}\n"
  text += "- missing collision links: \{trace.missing_collision_link_count}\n"
  text += "- missing inertial links: \{trace.missing_inertial_link_count}\n"
  text += "- status: \{trace.status}\n"
  text += "- note: \{trace.note}\n\n"
  text += "## Frame Prefix\n\n"
  for frame in trace.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} motion=\{frame.motion_id} rig_pose=\{frame.rig_pose_status} links=\{frame.links.length()} status=\{frame.status}\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_link_pose_markdown() -> String {
  render_noetix_link_pose_markdown(
    first_trusted_square_noetix_link_pose_trace(),
  )
}
