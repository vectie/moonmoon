///|
pub(all) struct RobotRigNode {
  link_name : String
  parent_link : String
  joint_name : String
  role : String
  side : String
  parent_offset_m : @moonphys.Vec3
  joint_axis : @moonphys.Vec3
  visual_count : Int
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotRigVisual {
  visual_index : Int
  link_name : String
  kind : NoetixSourceGeometryKind
  size_m : @moonphys.Vec3
  radius_m : Double
  length_m : Double
  mesh_path : String
  local_origin_xyz_m : @moonphys.Vec3
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotRig {
  rig_id : String
  robot_id : String
  source_model_path : String
  node_count : Int
  joint_count : Int
  visual_count : Int
  mesh_visual_count : Int
  primitive_visual_count : Int
  nodes : Array[RobotRigNode]
  visuals : Array[RobotRigVisual]
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotMotionJointSample {
  joint_name : String
  role : String
  side : String
  position_rad : Double
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotMotionFrame {
  motion_id : String
  rig_id : String
  frame_index : Int
  time_s : Double
  floating_base_transform : @moonphys.Transform3
  joint_sample_count : Int
  joint_samples : Array[RobotMotionJointSample]
  source : String
  hardware_authority : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotRigLinkPose {
  link_name : String
  parent_link : String
  joint_name : String
  joint_position_rad : Double
  world_transform : @moonphys.Transform3
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotRigPoseFrame {
  rig_id : String
  motion_id : String
  frame_index : Int
  time_s : Double
  floating_base_transform : @moonphys.Transform3
  link_count : Int
  missing_parent_count : Int
  links : Array[RobotRigLinkPose]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn robot_rig_visual_count_for_link(link_name : String) -> Int {
  let mut count = 0
  for geometry in noetix_source_visual_geometries() {
    if geometry.link_name == link_name {
      count += 1
    }
  }
  count
}

///|
fn joint_position_rad(
  frame : NoetixMoonWalkFrame,
  joint_name : String,
) -> Double {
  for phase in frame.joint_phases {
    if phase.joint_name == joint_name {
      return phase.position_rad
    }
  }
  0.0
}

///|
fn reference_link_spec(
  link : NoetixReferenceLink,
) -> @moonphys.ArticulatedLinkSpec {
  @moonphys.articulated_link_spec(
    link.link_name,
    link.parent_link,
    link.joint_name,
    link.nominal_parent_offset_m,
    link.joint_axis,
  )
}

///|
fn reference_link_specs(
  links : Array[NoetixReferenceLink],
) -> Array[@moonphys.ArticulatedLinkSpec] {
  let specs : Array[@moonphys.ArticulatedLinkSpec] = []
  for link in links {
    specs.push(reference_link_spec(link))
  }
  specs
}

///|
fn articulated_joint_positions(
  frame : NoetixMoonWalkFrame,
) -> Array[@moonphys.ArticulatedJointPosition] {
  let positions : Array[@moonphys.ArticulatedJointPosition] = []
  for phase in frame.joint_phases {
    positions.push(
      @moonphys.articulated_joint_position(phase.joint_name, phase.position_rad),
    )
  }
  positions
}

///|
fn robot_rig_node(link : NoetixReferenceLink) -> RobotRigNode {
  {
    link_name: link.link_name,
    parent_link: link.parent_link,
    joint_name: link.joint_name,
    role: link.role,
    side: link.side,
    parent_offset_m: link.nominal_parent_offset_m,
    joint_axis: link.joint_axis,
    visual_count: robot_rig_visual_count_for_link(link.link_name),
    source_status: link.source_status,
  }
}

///|
fn robot_rig_visual(
  visual_index : Int,
  geometry : NoetixSourceVisualGeometry,
) -> RobotRigVisual {
  {
    visual_index,
    link_name: geometry.link_name,
    kind: geometry.kind,
    size_m: geometry.size_m,
    radius_m: geometry.radius_m,
    length_m: geometry.length_m,
    mesh_path: geometry.mesh_path,
    local_origin_xyz_m: geometry.origin_xyz_m,
    source_status: geometry.source_status,
  }
}

///|
fn robot_rig_joint_count(nodes : Array[RobotRigNode]) -> Int {
  let mut count = 0
  for node in nodes {
    if node.joint_name != "" {
      count += 1
    }
  }
  count
}

///|
fn robot_rig_mesh_visual_count(visuals : Array[RobotRigVisual]) -> Int {
  let mut count = 0
  for visual in visuals {
    if visual.kind == SourceMeshGeometry {
      count += 1
    }
  }
  count
}

///|
pub fn noetix_robot_rig() -> RobotRig {
  let robot = noetix_moon_walk_robot_profile()
  let nodes : Array[RobotRigNode] = []
  for link in noetix_reference_links() {
    nodes.push(robot_rig_node(link))
  }
  let visuals : Array[RobotRigVisual] = []
  let mut visual_index = 0
  for geometry in noetix_source_visual_geometries() {
    visuals.push(robot_rig_visual(visual_index, geometry))
    visual_index += 1
  }
  let mesh_visual_count = robot_rig_mesh_visual_count(visuals)
  {
    rig_id: "moonrobo/noetix-e1/urdf-rigid-rig",
    robot_id: robot.robot_id,
    source_model_path: robot.source_model_path,
    node_count: nodes.length(),
    joint_count: robot_rig_joint_count(nodes),
    visual_count: visuals.length(),
    mesh_visual_count,
    primitive_visual_count: visuals.length() - mesh_visual_count,
    nodes,
    visuals,
    status: if nodes.length() == 25 && visuals.length() == 6 {
      "urdf-rigid-rig-ready"
    } else {
      "urdf-rigid-rig-review"
    },
    note: "Moonrobo-owned rigid robot rig: one node per Noetix URDF link, one joint transform per URDF joint, and source visual geometry attached to link-local frames. This is the robot equivalent of a game skeleton, but links stay rigid and motion comes from robot joint samples rather than skinned character animation.",
  }
}

///|
fn robot_rig_link_spec(node : RobotRigNode) -> @moonphys.ArticulatedLinkSpec {
  @moonphys.articulated_link_spec(
    node.link_name,
    node.parent_link,
    node.joint_name,
    node.parent_offset_m,
    node.joint_axis,
  )
}

///|
fn robot_rig_link_specs(rig : RobotRig) -> Array[@moonphys.ArticulatedLinkSpec] {
  let specs : Array[@moonphys.ArticulatedLinkSpec] = []
  for node in rig.nodes {
    specs.push(robot_rig_link_spec(node))
  }
  specs
}

///|
fn robot_motion_joint_sample(
  phase : NoetixJointPhase,
) -> RobotMotionJointSample {
  {
    joint_name: phase.joint_name,
    role: phase.role,
    side: phase.side,
    position_rad: phase.position_rad,
    source_status: phase.status,
  }
}

///|
pub fn noetix_robot_motion_frame(
  frame : NoetixMoonWalkFrame,
) -> RobotMotionFrame {
  let samples : Array[RobotMotionJointSample] = []
  for phase in frame.joint_phases {
    samples.push(robot_motion_joint_sample(phase))
  }
  let rig = noetix_robot_rig()
  {
    motion_id: "moonrobo/noetix-e1/robot-motion-frame/\{frame.frame_index}",
    rig_id: rig.rig_id,
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    floating_base_transform: @moonphys.transform3(
      @moonphys.identity_basis3(),
      frame.body_position,
    ),
    joint_sample_count: samples.length(),
    joint_samples: samples,
    source: "planned-gait-joint-samples",
    hardware_authority: "moonmoon-safety-gate-only",
    status: if samples.length() == rig.joint_count {
      "robot-motion-frame-ready"
    } else {
      "robot-motion-frame-review"
    },
  }
}

///|
fn robot_motion_joint_positions(
  motion : RobotMotionFrame,
) -> Array[@moonphys.ArticulatedJointPosition] {
  let positions : Array[@moonphys.ArticulatedJointPosition] = []
  for sample in motion.joint_samples {
    positions.push(
      @moonphys.articulated_joint_position(
        sample.joint_name,
        sample.position_rad,
      ),
    )
  }
  positions
}

///|
fn robot_rig_link_pose(
  pose : @moonphys.ArticulatedLinkPose,
) -> RobotRigLinkPose {
  {
    link_name: pose.link_id,
    parent_link: pose.parent_link_id,
    joint_name: pose.joint_id,
    joint_position_rad: pose.joint_position_rad,
    world_transform: pose.world_transform,
    status: pose.status,
  }
}

///|
pub fn robot_rig_pose_frame(
  rig : RobotRig,
  motion : RobotMotionFrame,
) -> RobotRigPoseFrame {
  let tree = @moonphys.articulated_pose_tree(
    motion.floating_base_transform,
    robot_rig_link_specs(rig),
    robot_motion_joint_positions(motion),
  )
  let links : Array[RobotRigLinkPose] = []
  for pose in tree.links {
    links.push(robot_rig_link_pose(pose))
  }
  {
    rig_id: rig.rig_id,
    motion_id: motion.motion_id,
    frame_index: motion.frame_index,
    time_s: motion.time_s,
    floating_base_transform: motion.floating_base_transform,
    link_count: tree.link_count,
    missing_parent_count: tree.missing_parent_count,
    links,
    status: if tree.status == "articulated-poses" &&
      motion.status == "robot-motion-frame-ready" {
      "robot-rig-pose-ready"
    } else {
      "robot-rig-pose-review"
    },
  }
}

///|
fn robot_rig_pose_link(
  frame : RobotRigPoseFrame,
  link_name : String,
) -> RobotRigLinkPose? {
  for link in frame.links {
    if link.link_name == link_name {
      return Some(link)
    }
  }
  None
}

///|
fn robot_rig_pose_link_transform(
  frame : RobotRigPoseFrame,
  link_name : String,
) -> @moonphys.Transform3 {
  match robot_rig_pose_link(frame, link_name) {
    Some(link) => link.world_transform
    None => frame.floating_base_transform
  }
}

///|
fn robot_rig_pose_link_joint_position(
  frame : RobotRigPoseFrame,
  link_name : String,
) -> Double {
  match robot_rig_pose_link(frame, link_name) {
    Some(link) => link.joint_position_rad
    None => 0.0
  }
}
