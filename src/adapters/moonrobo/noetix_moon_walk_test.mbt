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
