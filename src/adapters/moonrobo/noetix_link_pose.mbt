///|
pub(all) struct NoetixReferenceLink {
  link_name : String
  parent_link : String
  joint_name : String
  role : String
  side : String
  nominal_parent_offset_m : @moonphys.Vec3
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
  world_position : @moonphys.Vec3
  pitch_proxy_rad : Double
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
) -> NoetixReferenceLink {
  {
    link_name,
    parent_link,
    joint_name,
    role,
    side,
    nominal_parent_offset_m: @moonphys.vec3(x, y, z),
    source_status: "urdf-reference-origin",
  }
}

///|
pub fn noetix_reference_links() -> Array[NoetixReferenceLink] {
  [
    reference_link("base_link", "", "", "body", "center", 0.0, 0.0, 0.0),
    reference_link(
      "torso_link", "base_link", "waist_1_joint", "body", "center", 0.0, 0.0, 0.32,
    ),
    reference_link(
      "chest_link", "torso_link", "waist_2_joint", "body", "center", 0.0, 0.0, 0.18,
    ),
    reference_link(
      "left_arm_1", "chest_link", "arm_l1_joint", "arm", "left", 0.0, 0.16, 0.12,
    ),
    reference_link(
      "left_arm_2", "left_arm_1", "arm_l2_joint", "arm", "left", 0.0, 0.10, -0.10,
    ),
    reference_link(
      "left_arm_3", "left_arm_2", "arm_l3_joint", "arm", "left", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "left_arm_4", "left_arm_3", "arm_l4_joint", "arm", "left", 0.0, 0.0, -0.15,
    ),
    reference_link(
      "left_hand", "left_arm_4", "arm_l5_joint", "hand", "left", 0.0, 0.0, -0.12,
    ),
    reference_link(
      "right_arm_1", "chest_link", "arm_r1_joint", "arm", "right", 0.0, -0.16, 0.12,
    ),
    reference_link(
      "right_arm_2", "right_arm_1", "arm_r2_joint", "arm", "right", 0.0, -0.10, -0.10,
    ),
    reference_link(
      "right_arm_3", "right_arm_2", "arm_r3_joint", "arm", "right", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "right_arm_4", "right_arm_3", "arm_r4_joint", "arm", "right", 0.0, 0.0, -0.15,
    ),
    reference_link(
      "right_hand", "right_arm_4", "arm_r5_joint", "hand", "right", 0.0, 0.0, -0.12,
    ),
    reference_link(
      "left_leg_1", "base_link", "leg_l1_joint", "leg", "left", 0.0, 0.08, -0.08,
    ),
    reference_link(
      "left_leg_2", "left_leg_1", "leg_l2_joint", "leg", "left", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "left_leg_3", "left_leg_2", "leg_l3_joint", "leg", "left", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "left_leg_4", "left_leg_3", "leg_l4_joint", "leg", "left", 0.0, 0.0, -0.18,
    ),
    reference_link(
      "left_leg_5", "left_leg_4", "leg_l5_joint", "leg", "left", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "left_foot", "left_leg_5", "leg_l6_joint", "foot", "left", 0.04, 0.0, -0.08,
    ),
    reference_link(
      "right_leg_1", "base_link", "leg_r1_joint", "leg", "right", 0.0, -0.08, -0.08,
    ),
    reference_link(
      "right_leg_2", "right_leg_1", "leg_r2_joint", "leg", "right", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "right_leg_3", "right_leg_2", "leg_r3_joint", "leg", "right", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "right_leg_4", "right_leg_3", "leg_r4_joint", "leg", "right", 0.0, 0.0, -0.18,
    ),
    reference_link(
      "right_leg_5", "right_leg_4", "leg_r5_joint", "leg", "right", 0.0, 0.0, -0.16,
    ),
    reference_link(
      "right_foot", "right_leg_5", "leg_r6_joint", "foot", "right", 0.04, 0.0, -0.08,
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
fn pose_status(role : String) -> String {
  if role == "foot" {
    "contact-probe-bound"
  } else {
    "urdf-reference-gait-proxy"
  }
}

///|
fn link_pose(
  link : NoetixReferenceLink,
  world_position : @moonphys.Vec3,
  pitch_proxy_rad : Double,
) -> NoetixLinkPose {
  {
    link_name: link.link_name,
    parent_link: link.parent_link,
    joint_name: link.joint_name,
    role: link.role,
    side: link.side,
    nominal_parent_offset_m: link.nominal_parent_offset_m,
    world_position,
    pitch_proxy_rad,
    source_status: pose_status(link.role),
  }
}

///|
fn leg_pose_position(
  frame : NoetixMoonWalkFrame,
  link_name : String,
  side : String,
) -> @moonphys.Vec3 {
  let side_sign = if side == "left" { 1.0 } else { 0.0 - 1.0 }
  let foot = if side == "left" {
    frame.left_foot.position
  } else {
    frame.right_foot.position
  }
  let hip = frame.body_position.add(
    @moonphys.vec3(0.0, side_sign * 0.08, -0.08),
  )
  let (progress, bend) = match link_name {
    "left_leg_1" | "right_leg_1" => (0.16, 0.01)
    "left_leg_2" | "right_leg_2" => (0.32, 0.02)
    "left_leg_3" | "right_leg_3" => (0.50, 0.035)
    "left_leg_4" | "right_leg_4" => (0.68, 0.025)
    "left_leg_5" | "right_leg_5" => (0.84, 0.012)
    _ => (1.0, 0.0)
  }
  hip
  .scale(1.0 - progress)
  .add(foot.scale(progress))
  .add(@moonphys.vec3(bend, 0.0, bend * 0.5))
}

///|
fn arm_pose_position(
  frame : NoetixMoonWalkFrame,
  link_name : String,
  side : String,
) -> @moonphys.Vec3 {
  let side_sign = if side == "left" { 1.0 } else { 0.0 - 1.0 }
  let shoulder_joint = if side == "left" {
    "arm_l1_joint"
  } else {
    "arm_r1_joint"
  }
  let shoulder_phase = joint_position_rad(frame, shoulder_joint)
  let chest = frame.body_position.add(@moonphys.vec3(0.0, 0.0, 0.50))
  let index = match link_name {
    "left_arm_1" | "right_arm_1" => 1.0
    "left_arm_2" | "right_arm_2" => 2.0
    "left_arm_3" | "right_arm_3" => 3.0
    "left_arm_4" | "right_arm_4" => 4.0
    _ => 5.0
  }
  chest.add(
    @moonphys.vec3(
      0.0 - shoulder_phase * 0.45 - index * 0.004,
      side_sign * (0.16 + index * 0.025),
      0.10 - index * 0.12,
    ),
  )
}

///|
fn body_pose_position(
  frame : NoetixMoonWalkFrame,
  link_name : String,
) -> @moonphys.Vec3 {
  match link_name {
    "torso_link" => frame.body_position.add(@moonphys.vec3(0.0, 0.0, 0.32))
    "chest_link" => frame.body_position.add(@moonphys.vec3(0.0, 0.0, 0.50))
    _ => frame.body_position
  }
}

///|
fn link_world_position(
  frame : NoetixMoonWalkFrame,
  link : NoetixReferenceLink,
) -> @moonphys.Vec3 {
  match link.role {
    "body" => body_pose_position(frame, link.link_name)
    "leg" => leg_pose_position(frame, link.link_name, link.side)
    "foot" =>
      if link.side == "left" {
        frame.left_foot.position
      } else {
        frame.right_foot.position
      }
    "arm" | "hand" => arm_pose_position(frame, link.link_name, link.side)
    _ => frame.body_position.add(link.nominal_parent_offset_m)
  }
}

///|
pub fn noetix_link_pose_frame(
  frame : NoetixMoonWalkFrame,
) -> NoetixLinkPoseFrame {
  let links : Array[NoetixLinkPose] = []
  for link in noetix_reference_links() {
    links.push(
      link_pose(
        link,
        link_world_position(frame, link),
        joint_position_rad(frame, link.joint_name),
      ),
    )
  }
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    body_position: frame.body_position,
    links,
    status: "review-only-link-pose",
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
    note: "URDF-reference link pose evidence for visualization and review: link names and nominal origins come from the Noetix URDF, feet are bound to Moonphys contact probes, and non-foot links are gait proxies until full URDF forward kinematics and inertial metadata are available. This is not hardware authority.",
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
