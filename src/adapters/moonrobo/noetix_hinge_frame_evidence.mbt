///|
pub(all) struct NoetixHingeJointFrameEvidence {
  frame_id : String
  body_count : Int
  joint_count : Int
  assessed_joint_count : Int
  projected_body_count : Int
  resolved_hinge_constraint_count : Int
  review_count : Int
  max_position_error_m : Double
  max_angular_error_rad : Double
  linear_impulse_ns : Double
  angular_impulse_nms : Double
  assessment_status : String
  world_status : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn pose_link(
  tree : @moonphys.ArticulatedPoseTree,
  link_id : String,
) -> @moonphys.ArticulatedLinkPose? {
  for pose in tree.links {
    if pose.link_id == link_id {
      return Some(pose)
    }
  }
  None
}

///|
fn pose_translation(
  tree : @moonphys.ArticulatedPoseTree,
  link_id : String,
  fallback : @moonphys.Vec3,
) -> @moonphys.Vec3 {
  match pose_link(tree, link_id) {
    Some(pose) => pose.world_transform.translation
    None => fallback
  }
}

///|
fn link_velocity(
  current : @moonphys.Vec3,
  previous : @moonphys.Vec3,
  dt_s : Double,
) -> @moonphys.Vec3 {
  if dt_s > 0.0 {
    current.sub(previous).scale(1.0 / dt_s)
  } else {
    @moonphys.vec3(0.0, 0.0, 0.0)
  }
}

///|
fn link_angular_velocity(
  link : NoetixReferenceLink,
  current_joint_position_rad : Double,
  previous_joint_position_rad : Double,
  dt_s : Double,
) -> @moonphys.Vec3 {
  if dt_s > 0.0 {
    link.joint_axis.scale(
      (current_joint_position_rad - previous_joint_position_rad) / dt_s,
    )
  } else {
    @moonphys.vec3(0.0, 0.0, 0.0)
  }
}

///|
fn noetix_hinge_frame_body(
  link : NoetixReferenceLink,
  current : @moonphys.ArticulatedLinkPose,
  previous_position : @moonphys.Vec3,
  previous_joint_position_rad : Double,
  profile : NoetixPhysicsProfile,
  dt_s : Double,
) -> @moonphys.RigidBodyJointFrameBody {
  let mass_per_link = profile.mass_model.mass_kg /
    noetix_reference_links().length().to_double()
  let radius_m = 0.08
  let velocity = link_velocity(
    current.world_transform.translation,
    previous_position,
    dt_s,
  )
  let angular_velocity = link_angular_velocity(
    link,
    current.joint_position_rad,
    previous_joint_position_rad,
    dt_s,
  )
  @moonphys.rigid_body_joint_frame_body(
    @moonphys.rigid_body_motion_state(
      link.link_name,
      mass_per_link,
      radius_m,
      current.world_transform.translation,
      velocity,
      current.world_transform.basis,
      angular_velocity,
    ),
    @moonphys.sphere_diagonal_inertia(link.link_name, mass_per_link, radius_m),
  )
}

///|
fn noetix_hinge_frame_constraint(
  link : NoetixReferenceLink,
  parent_position : @moonphys.Vec3,
  child_position : @moonphys.Vec3,
) -> @moonphys.RigidBodyHingeJointConstraint {
  @moonphys.rigid_body_hinge_joint_constraint(
    link.joint_name,
    link.parent_link,
    link.link_name,
    anchor_a_m=child_position.sub(parent_position),
    anchor_b_m=@moonphys.vec3(0.0, 0.0, 0.0),
    local_axis_a=link.joint_axis,
    local_axis_b=link.joint_axis,
    stiffness=1.0,
  )
}

///|
fn summarize_hinge_joint_frame(
  assessment : @moonphys.RigidBodyHingeJointFrameAssessment,
  world_resolution : @moonphys.RigidBodyWorldHingeConstraintFrame,
) -> NoetixHingeJointFrameEvidence {
  {
    frame_id: assessment.frame_id,
    body_count: assessment.body_count,
    joint_count: assessment.joint_count,
    assessed_joint_count: assessment.assessed_joint_count,
    projected_body_count: world_resolution.after.motion_bodies.length(),
    resolved_hinge_constraint_count: world_resolution.resolved_hinge_constraint_count,
    review_count: assessment.review_count + world_resolution.review_count,
    max_position_error_m: world_resolution.max_position_error_m,
    max_angular_error_rad: world_resolution.max_angular_error_rad,
    linear_impulse_ns: world_resolution.linear_impulse_ns,
    angular_impulse_nms: world_resolution.angular_impulse_nms,
    assessment_status: assessment.status,
    world_status: world_resolution.status,
    status: if world_resolution.status.contains("review") {
      "noetix-hinge-world-review"
    } else if world_resolution.resolved_hinge_constraint_count > 0 {
      "noetix-hinge-world-projected"
    } else {
      "noetix-hinge-world-satisfied"
    },
  }
}

///|
fn noetix_hinge_world_body(
  body : @moonphys.RigidBodyJointFrameBody,
) -> @moonphys.RigidBodyWorldBody {
  @moonphys.rigid_body_world_body(body.state.linear)
}

///|
fn noetix_hinge_world_bodies(
  bodies : Array[@moonphys.RigidBodyJointFrameBody],
) -> Array[@moonphys.RigidBodyWorldBody] {
  let world_bodies : Array[@moonphys.RigidBodyWorldBody] = []
  for body in bodies {
    world_bodies.push(noetix_hinge_world_body(body))
  }
  world_bodies
}

///|
fn noetix_hinge_projection_world(
  frame : NoetixMoonWalkFrame,
  bodies : Array[@moonphys.RigidBodyJointFrameBody],
  joints : Array[@moonphys.RigidBodyHingeJointConstraint],
) -> @moonphys.RigidBodyHeightfieldWorld {
  @moonphys.rigid_body_heightfield_world(
    "noetix-e1/hinge-projection-world/\{frame.frame_index}",
    @moonphys.heightfield("noetix-e1/hinge-projection-flat-field", 1, 1, 1.0, [
      0.0,
    ]),
    @moonphys.lunar_regolith_contact_model(),
    @moonphys.lunar_environment(),
    noetix_hinge_world_bodies(bodies),
    motion_bodies=bodies,
    hinge_constraints=joints,
  )
}

///|
pub fn noetix_hinge_joint_frame_evidence(
  trace : NoetixMoonWalkTrace,
  frame_index : Int,
  profile : NoetixPhysicsProfile,
) -> NoetixHingeJointFrameEvidence {
  let frame = trace.frames[frame_index]
  let previous = previous_frame(trace, frame_index)
  let dt_s = frame_dt_s(trace, frame_index)
  let links = noetix_reference_links()
  let root_transform = @moonphys.transform3(
    @moonphys.identity_basis3(),
    frame.body_position,
  )
  let previous_root_transform = @moonphys.transform3(
    @moonphys.identity_basis3(),
    previous.body_position,
  )
  let current_tree = @moonphys.articulated_pose_tree(
    root_transform,
    reference_link_specs(links),
    articulated_joint_positions(frame),
  )
  let previous_tree = @moonphys.articulated_pose_tree(
    previous_root_transform,
    reference_link_specs(links),
    articulated_joint_positions(previous),
  )
  let bodies : Array[@moonphys.RigidBodyJointFrameBody] = []
  let joints : Array[@moonphys.RigidBodyHingeJointConstraint] = []
  for link in links {
    match pose_link(current_tree, link.link_name) {
      Some(current_pose) => {
        let previous_position = pose_translation(
          previous_tree,
          link.link_name,
          current_pose.world_transform.translation,
        )
        bodies.push(
          noetix_hinge_frame_body(
            link,
            current_pose,
            previous_position,
            joint_position_rad(previous, link.joint_name),
            profile,
            dt_s,
          ),
        )
        if link.parent_link != "" && link.joint_name != "" {
          let parent_position = pose_translation(
            current_tree,
            link.parent_link,
            frame.body_position,
          )
          joints.push(
            noetix_hinge_frame_constraint(
              link,
              parent_position,
              current_pose.world_transform.translation,
            ),
          )
        }
      }
      None => ()
    }
  }
  let assessment = @moonphys.rigid_body_hinge_joint_frame_assessment(
    "noetix-e1/hinge-joint-frame/\{frame.frame_index}",
    bodies,
    joints,
  )
  let world_resolution = @moonphys.rigid_body_world_resolve_hinge_constraints(
    noetix_hinge_projection_world(frame, bodies, joints),
  )
  summarize_hinge_joint_frame(assessment, world_resolution)
}
