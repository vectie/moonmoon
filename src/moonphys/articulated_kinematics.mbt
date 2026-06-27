///|
pub(all) struct ArticulatedLinkSpec {
  link_id : String
  parent_link_id : String
  joint_id : String
  parent_offset_m : Vec3
  joint_axis : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ArticulatedJointPosition {
  joint_id : String
  position_rad : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ArticulatedLinkPose {
  link_id : String
  parent_link_id : String
  joint_id : String
  joint_position_rad : Double
  local_transform : Transform3
  world_transform : Transform3
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ArticulatedPoseTree {
  root_transform : Transform3
  link_count : Int
  missing_parent_count : Int
  links : Array[ArticulatedLinkPose]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn articulated_link_spec(
  link_id : String,
  parent_link_id : String,
  joint_id : String,
  parent_offset_m : Vec3,
  joint_axis : Vec3,
) -> ArticulatedLinkSpec {
  { link_id, parent_link_id, joint_id, parent_offset_m, joint_axis }
}

///|
pub fn articulated_joint_position(
  joint_id : String,
  position_rad : Double,
) -> ArticulatedJointPosition {
  { joint_id, position_rad }
}

///|
fn articulated_joint_position_rad(
  joint_id : String,
  positions : Array[ArticulatedJointPosition],
) -> Double {
  for position in positions {
    if position.joint_id == joint_id {
      return position.position_rad
    }
  }
  0.0
}

///|
fn articulated_parent_transform(
  poses : Array[ArticulatedLinkPose],
  parent_link_id : String,
) -> Transform3? {
  for pose in poses {
    if pose.link_id == parent_link_id {
      return Some(pose.world_transform)
    }
  }
  None
}

///|
fn articulated_local_transform(
  link : ArticulatedLinkSpec,
  joint_position_rad : Double,
) -> Transform3 {
  transform3(
    axis_angle_basis3(link.joint_axis, joint_position_rad),
    link.parent_offset_m,
  )
}

///|
pub fn articulated_pose_tree(
  root_transform : Transform3,
  links : Array[ArticulatedLinkSpec],
  positions : Array[ArticulatedJointPosition],
) -> ArticulatedPoseTree {
  let poses : Array[ArticulatedLinkPose] = []
  let mut missing_parent_count = 0
  for link in links {
    let joint_position_rad = articulated_joint_position_rad(
      link.joint_id,
      positions,
    )
    let local_transform = articulated_local_transform(link, joint_position_rad)
    let (parent_transform, status) = if link.parent_link_id == "" {
      (root_transform, "root-link")
    } else {
      match articulated_parent_transform(poses, link.parent_link_id) {
        Some(transform) => (transform, "parent-resolved")
        None => {
          missing_parent_count = missing_parent_count + 1
          (root_transform, "missing-parent")
        }
      }
    }
    poses.push({
      link_id: link.link_id,
      parent_link_id: link.parent_link_id,
      joint_id: link.joint_id,
      joint_position_rad,
      local_transform,
      world_transform: parent_transform.compose(local_transform),
      status,
    })
  }
  {
    root_transform,
    link_count: poses.length(),
    missing_parent_count,
    links: poses,
    status: if missing_parent_count == 0 {
      "articulated-poses"
    } else {
      "articulated-poses-missing-parent-review"
    },
  }
}

///|
pub fn ArticulatedPoseTree::link_transform(
  self : ArticulatedPoseTree,
  link_id : String,
) -> Transform3 {
  for link in self.links {
    if link.link_id == link_id {
      return link.world_transform
    }
  }
  self.root_transform
}
