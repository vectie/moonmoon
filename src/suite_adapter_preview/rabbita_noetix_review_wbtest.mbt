///|
test "generated Rabbita Noetix evidence feeds compiled Moonphys review" {
  let motion = rabbita_noetix_generated_motion_trace_review()
  let field = @moonphys.heightfield(
    "rabbita-noetix-generated-flat-field",
    1,
    1,
    1.0,
    [0.0],
  )
  let hinge = rabbita_noetix_generated_hinge_trace(field)
  let replay = rabbita_noetix_generated_replay_review(hinge)
  let review = @moonphys.motion_hinge_replay_review_with_replay(
    generated_rabbita_noetix_combined_review_id(),
    motion,
    hinge,
    replay,
  )
  assert_eq(
    generated_rabbita_noetix_evidence_source(),
    "ui/rabbita-moon/scene3d.js#__moonmoonGaitDiagnostics",
  )
  assert_eq(generated_rabbita_noetix_motion_frames().length(), 24)
  assert_eq(generated_rabbita_noetix_hinge_frames().length(), 24)
  let first_motion_frame = generated_rabbita_noetix_motion_frames()[0]
  let final_motion_frame = generated_rabbita_noetix_motion_frames()[23]
  let first_hinge_frame = generated_rabbita_noetix_hinge_frames()[0]
  assert_eq(first_motion_frame.phase_label, "left-stance-right-swing")
  assert_eq(first_motion_frame.support_foot, "left")
  assert_true(final_motion_frame.time_s > first_motion_frame.time_s)
  assert_eq(first_hinge_frame.time_s, 0.0)
  assert_eq(
    compiled_moonphys_bridge_status(),
    "rabbita-noetix-generated-review-ready",
  )
  assert_true(motion.ready)
  assert_eq(motion.status, "motion-frame-trace-review-ready")
  assert_eq(motion.blocker_count, 0)
  assert_eq(motion.frame_count, 24)
  assert_eq(hinge.frame_count, 24)
  assert_eq(hinge.motor_frame_count, 24)
  assert_eq(hinge.status, "world-heightfield-hinge-motor-trace-driven")
  assert_true(hinge.driven_joint_count >= 24)
  assert_eq(hinge.review_count, 0)
  assert_true(replay.ready)
  assert_eq(replay.status, "world-replay-review-ready")
  assert_eq(replay.blocker_count, 0)
  assert_true(review.ready)
  assert_eq(review.status, "motion-hinge-replay-review-ready")
  assert_eq(review.motion_frame_count, 24)
  assert_eq(review.hinge_frame_count, 24)
  assert_eq(review.frame_count_delta, 0)
  assert_eq(review.blocker_count, 0)
  assert_true(review.driven_joint_count >= 24)
  assert_true(review.max_motion_total_normal_force_n > 0.0)
  assert_true(review.max_motion_contact_torque_nm > 0.0)
  assert_true(review.max_motion_pressure_pa > 0.0)
  assert_true(motion.max_center_of_mass_speed_mps > 0.0)
  assert_true(motion.max_linear_momentum_kg_mps > 0.0)
  assert_true(motion.max_linear_kinetic_energy_j > 0.0)
  assert_true(review.max_motion_linear_momentum_kg_mps > 0.0)
  assert_true(review.max_motion_linear_kinetic_energy_j > 0.0)
  assert_true(review.max_replay_kinetic_energy_j >= 0.0)
}

///|
test "Moonrobo Noetix suite payload records durable source refs" {
  let payload = moonrobo_noetix_suite_adapter_payload()
  assert_true(payload.ready)
  assert_eq(payload.status, "moonrobo-noetix-suite-payload-ready")
  assert_eq(payload.robot_id, "noetix-e1-lab-01")
  assert_eq(payload.platform, "noetix-e1")
  assert_eq(payload.expected_profile_joint_count, 24)
  assert_eq(payload.frame_count, 24)
  assert_eq(payload.review_status, "rabbita-noetix-generated-review-ready")
  assert_eq(
    payload.evidence_source,
    "ui/rabbita-moon/scene3d.js#__moonmoonGaitDiagnostics",
  )
  assert_eq(payload.profile_path, "../moonrobo/examples/noetix-e1/robot.json")
  assert_eq(
    payload.urdf_path,
    "../moonrobo/examples/noetix-e1/model/robot.urdf",
  )
  assert_true(
    payload.mesh_paths.contains(
      "../moonrobo/examples/noetix-e1/model/meshes/base.obj",
    ),
  )
  assert_true(payload.driven_joint_ids.contains("leg_l1_joint"))
  assert_true(payload.driven_joint_ids.contains("leg_r4_joint"))
  assert_true(payload.driven_joint_ids.contains("arm_l1_joint"))
  assert_true(payload.driven_joint_ids.contains("arm_r4_joint"))
  assert_eq(payload.source_refs.length(), 4)
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.robot-profile" &&
      source.local_path == "../moonrobo/examples/noetix-e1/robot.json"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.urdf" &&
      source.local_path == "../moonrobo/examples/noetix-e1/model/robot.urdf"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonmoon.rabbita.generated-evidence" &&
      source.local_path ==
      "ui/rabbita-moon/scene3d.js#__moonmoonGaitDiagnostics"
    }),
  )
}
