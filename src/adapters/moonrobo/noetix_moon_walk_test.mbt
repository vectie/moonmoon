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
