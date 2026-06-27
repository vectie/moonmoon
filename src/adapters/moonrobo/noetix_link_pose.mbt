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
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkPoseFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  body_position : @moonphys.Vec3
  links : Array[NoetixLinkPose]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLinkPoseTrace {
  trace_id : String
  source_walk_trace_id : String
  robot_id : String
  source_model_path : String
  frame_count : Int
  links_per_frame : Int
  frames : Array[NoetixLinkPoseFrame]
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
priv struct NoetixLinkFkState {
  link_name : String
  transform : @moonphys.Transform3
}

///|
fn find_fk_transform(
  states : Array[NoetixLinkFkState],
  link_name : String,
) -> @moonphys.Transform3 {
  for state in states {
    if state.link_name == link_name {
      return state.transform
    }
  }
  @moonphys.transform3(
    @moonphys.identity_basis3(),
    @moonphys.vec3(0.0, 0.0, 0.0),
  )
}

///|
fn fk_child_transform(
  parent : @moonphys.Transform3,
  link : NoetixReferenceLink,
  joint_position : Double,
) -> @moonphys.Transform3 {
  parent.compose(
    @moonphys.transform3(
      @moonphys.axis_angle_basis3(link.joint_axis, joint_position),
      link.nominal_parent_offset_m,
    ),
  )
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
fn link_pose(
  link : NoetixReferenceLink,
  joint_position : Double,
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
  let links : Array[NoetixLinkPose] = []
  let states : Array[NoetixLinkFkState] = []
  let root_transform = @moonphys.transform3(
    @moonphys.identity_basis3(),
    frame.body_position,
  )
  for link in noetix_reference_links() {
    let joint_position = joint_position_rad(frame, link.joint_name)
    let transform = if link.parent_link == "" {
      root_transform
    } else {
      fk_child_transform(
        find_fk_transform(states, link.parent_link),
        link,
        joint_position,
      )
    }
    states.push({ link_name: link.link_name, transform })
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
        link, joint_position, fk_position, world_position, contact_error,
      ),
    )
  }
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    body_position: frame.body_position,
    links,
    status: "review-only-urdf-fk",
  }
}

///|
pub fn noetix_link_pose_trace(
  trace : NoetixMoonWalkTrace,
) -> NoetixLinkPoseTrace {
  let frames : Array[NoetixLinkPoseFrame] = []
  for frame in trace.frames {
    frames.push(noetix_link_pose_frame(frame))
  }
  {
    trace_id: "moonrobo/noetix-e1/link-poses/\{trace.terrain_tile_id}",
    source_walk_trace_id: trace.trace_id,
    robot_id: trace.robot.robot_id,
    source_model_path: trace.robot.source_model_path,
    frame_count: frames.length(),
    links_per_frame: noetix_reference_links().length(),
    frames,
    status: "review-only",
    note: "URDF-reference forward-kinematics evidence for visualization and review: link names, joint origins, and joint axes come from the Noetix URDF; feet are bound to Moonphys contact probes and carry FK contact error. This is not full dynamics, collision, inertia, controller evidence, or hardware authority.",
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
  text += "- frames: \{trace.frame_count}\n"
  text += "- links per frame: \{trace.links_per_frame}\n"
  text += "- status: \{trace.status}\n"
  text += "- note: \{trace.note}\n\n"
  text += "## Frame Prefix\n\n"
  for frame in trace.frames {
    text += "- frame \{frame.frame_index} t=\{frame.time_s}s phase=\{frame.support_phase} links=\{frame.links.length()} status=\{frame.status}\n"
  }
  text
}

///|
pub fn first_trusted_square_noetix_link_pose_markdown() -> String {
  render_noetix_link_pose_markdown(
    first_trusted_square_noetix_link_pose_trace(),
  )
}
