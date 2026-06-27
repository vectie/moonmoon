///|
test "noetix endless moon walk advances in one direction" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=24)
  assert_eq(trace.frame_count, 24)
  assert_eq(trace.robot.robot_id, "noetix-e1-lab-01")
  assert_true(
    trace.frames[23].body_position.x > trace.frames[0].body_position.x,
  )
  assert_eq(trace.frames[0].support_phase, "left-support")
  assert_eq(trace.frames[10].support_phase, "right-support")
}

///|
test "noetix endless moon walk alternates contact feet" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  assert_true(trace.frames[0].left_foot.in_contact)
  assert_true(!trace.frames[0].right_foot.in_contact)
  assert_true(!trace.frames[10].left_foot.in_contact)
  assert_true(trace.frames[10].right_foot.in_contact)
}

///|
test "noetix endless moon walk carries animation joint phases" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  assert_eq(trace.frames[0].joint_phases.length(), 24)
  assert_true(
    trace.frames[0].joint_phases.any(fn(phase) {
      phase.joint_name == "leg_r3_joint" && phase.position_rad == 0.0
    }),
  )
  assert_true(
    trace.frames[5].joint_phases.any(fn(phase) {
      phase.joint_name == "leg_r3_joint" && phase.position_rad > 0.0
    }),
  )
}

///|
test "noetix physics profile keeps assumed dynamics explicit" {
  let profile = default_noetix_physics_profile()
  assert_eq(profile.robot_id, "noetix-e1-lab-01")
  assert_eq(profile.foot_geometry.length(), 2)
  assert_true(profile.mass_model.mass_kg > 0.0)
  assert_true(
    profile.mass_model.source_status.contains("simulation-assumption"),
  )
  assert_true(profile.note.contains("simulation assumptions"))
  assert_eq(profile.hardware_authority, "moonmoon-safety-gate-only")
}

///|
test "noetix static support report flags kinematic walk for review" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  let report = noetix_walk_stability_report(trace)
  assert_eq(report.frame_count, 12)
  assert_eq(report.profile.robot_id, trace.robot.robot_id)
  assert_true(report.review_frame_count > 0)
  assert_true(report.worst_planar_margin_m < 0.0)
  assert_eq(report.status, "static-support-review")
  assert_true(
    report.frames.any(fn(frame) { frame.status == "static-margin-review" }),
  )
}

///|
test "noetix dynamic stability report uses capture point evidence" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  let report = noetix_dynamic_stability_report(trace)
  assert_eq(report.frame_count, 12)
  assert_eq(report.profile.robot_id, trace.robot.robot_id)
  assert_eq(report.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(report.review_frame_count > 0)
  assert_true(report.worst_capture_margin_m < 0.0)
  assert_eq(report.status, "dynamic-stability-review")
  assert_true(report.note.contains("no controller"))
  assert_true(
    report.frames.any(fn(frame) { frame.status == "capture-point-review" }),
  )
  assert_true(
    report.frames[0].capture_point_assessment.capture_point.x >
    report.frames[0].com_position.x,
  )
}

///|
test "noetix reference links mirror the compact urdf tree" {
  let links = noetix_reference_links()
  assert_eq(links.length(), 25)
  assert_true(
    links.any(fn(link) {
      link.link_name == "base_link" && link.parent_link == ""
    }),
  )
  assert_true(
    links.any(fn(link) {
      link.link_name == "left_foot" && link.joint_name == "leg_l6_joint"
    }),
  )
  assert_true(
    links.any(fn(link) {
      link.link_name == "right_hand" && link.joint_name == "arm_r5_joint"
    }),
  )
}

///|
test "noetix link pose trace binds feet to walk contact probes" {
  let walk = first_trusted_square_noetix_walk_trace(frame_count=12)
  let poses = noetix_link_pose_trace(walk)
  assert_eq(poses.frame_count, walk.frame_count)
  assert_eq(poses.links_per_frame, 25)
  assert_eq(poses.robot_id, walk.robot.robot_id)
  assert_true(poses.note.contains("not hardware authority"))
  let first = poses.frames[0]
  assert_eq(first.links.length(), 25)
  assert_true(
    first.links.any(fn(link) {
      link.link_name == "left_foot" &&
      link.world_position == walk.frames[0].left_foot.position &&
      link.source_status == "contact-probe-bound"
    }),
  )
  assert_true(
    first.links.any(fn(link) {
      link.link_name == "right_foot" &&
      link.world_position == walk.frames[0].right_foot.position
    }),
  )
}

///|
test "noetix link pose trace carries gait motion proxies" {
  let walk = first_trusted_square_noetix_walk_trace(frame_count=12)
  let poses = noetix_link_pose_trace(walk)
  let frame0 = poses.frames[0]
  let frame5 = poses.frames[5]
  let mut leg0_z = 0.0
  let mut leg5_z = 0.0
  let mut arm0_x = 0.0
  let mut arm5_x = 0.0
  for link in frame0.links {
    if link.link_name == "right_leg_3" {
      leg0_z = link.world_position.z
    }
    if link.link_name == "right_arm_1" {
      arm0_x = link.world_position.x
    }
  }
  for link in frame5.links {
    if link.link_name == "right_leg_3" {
      leg5_z = link.world_position.z
    }
    if link.link_name == "right_arm_1" {
      arm5_x = link.world_position.x
    }
  }
  assert_true(leg5_z > leg0_z)
  assert_true(arm5_x != arm0_x)
}
