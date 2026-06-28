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
  assert_eq(generated_moonrobo_noetix_contact_frames().length(), 24)
  assert_eq(generated_rabbita_noetix_hinge_frames().length(), 24)
  assert_eq(generated_moonrobo_noetix_authored_motor_frames().length(), 24)
  let first_motion_frame = generated_moonrobo_noetix_contact_frames()[0]
  let final_motion_frame = generated_moonrobo_noetix_contact_frames()[23]
  let first_hinge_frame = generated_moonrobo_noetix_authored_motor_frames()[0]
  assert_eq(first_motion_frame.phase_label, "left-stance-right-swing")
  assert_eq(first_motion_frame.support_foot, "left")
  assert_true(final_motion_frame.time_s > first_motion_frame.time_s)
  assert_eq(first_hinge_frame.time_s, 0.0)
  assert_eq(
    compiled_moonphys_bridge_status(),
    "moonrobo-noetix-generated-review-ready",
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
  assert_eq(
    generated_moonrobo_noetix_contract_id(),
    "noetix-e1-lab-01/moonmoon-locomotion-source-contract",
  )
  assert_eq(
    generated_moonrobo_noetix_target_payload_type(),
    "vectie/moonmoon/src/suite_adapter_preview.NoetixSuiteAdapterPayload",
  )
  assert_eq(generated_moonrobo_noetix_profile_joint_ids().length(), 24)
  assert_true(generated_moonrobo_noetix_source_ready())
  assert_eq(
    generated_moonrobo_noetix_source_status(),
    "moonmoon-noetix-locomotion-contract-ready",
  )
  assert_true(generated_moonrobo_noetix_walk_clip_ready())
  assert_eq(
    generated_moonrobo_noetix_walk_clip_status(),
    "moonmoon-noetix-walk-clip-ready",
  )
  assert_eq(payload.walk_clip_id, "noetix-e1-lab-01/endless-forward-walk")
  assert_eq(
    payload.walk_clip_source,
    "vectie/moonrobo/src/moonmoon_adapter#noetix_e1_moonmoon_walk_clip_contract",
  )
  assert_eq(payload.walk_cycle_hz, 0.46)
  assert_eq(payload.root_speed_mps, 0.18)
  assert_eq(payload.stride_m, 0.38)
  assert_eq(payload.walk_sample_count, 24)
  assert_eq(payload.foot_phase_sequence.length(), 6)
  assert_true(payload.foot_phase_sequence.contains("contact"))
  assert_true(payload.foot_phase_sequence.contains("swing"))
  assert_true(payload.walk_phase_labels.contains("left-stance-right-swing"))
  assert_true(payload.walk_phase_labels.contains("right-stance-left-swing"))
  assert_eq(payload.foot_phase_specs.length(), 6)
  assert_true(
    payload.foot_phase_specs.any(fn(spec) {
      spec.role == "stance" && spec.support && spec.lock_window
    }),
  )
  assert_true(
    payload.foot_phase_specs.any(fn(spec) {
      spec.role == "swing" && !spec.support && !spec.lock_window
    }),
  )
  assert_true(
    payload.joint_anchors.any(fn(anchor) {
      anchor.joint_id == "leg_l4_joint" &&
      anchor.side == "left" &&
      anchor.field == "knee" &&
      anchor.position_rad < -0.5
    }),
  )
  assert_true(
    payload.joint_anchors.any(fn(anchor) {
      anchor.joint_id == "arm_r4_joint" && anchor.field == "elbow"
    }),
  )
  assert_true(
    payload.joint_curve_params.any(fn(param) {
      param.name == "knee_swing_lift_rad" && param.value > 0.7
    }),
  )
  assert_true(
    payload.joint_curve_params.any(fn(param) {
      param.name == "arm_phase_lag" && param.value == 0.44
    }),
  )
  assert_true(
    payload.joint_curve_params.any(fn(param) {
      param.name == "shoulder_hip_scale" && param.value == 0.76
    }),
  )
  assert_eq(payload.authored_joint_samples.length(), payload.walk_sample_count)
  assert_eq(payload.authored_joint_samples[0].phase, 0.0)
  assert_true(
    payload.authored_joint_samples.any(fn(sample) {
      sample.left_knee_rad < -0.75 || sample.right_knee_rad < -0.75
    }),
  )
  for sample in payload.authored_joint_samples {
    assert_true(sample.left_knee_rad <= 0.0)
    assert_true(sample.right_knee_rad <= 0.0)
  }
  assert_eq(payload.authored_motion_samples.length(), payload.walk_sample_count)
  assert_eq(payload.authored_motion_samples[0].phase, 0.0)
  assert_true(
    payload.authored_motion_samples.any(fn(sample) {
      sample.root_bob_m < -0.03 && sample.root_cycle_forward_m > 0.08
    }),
  )
  assert_true(
    payload.authored_motion_samples.any(fn(sample) {
      sample.torso_counter_rotation_rad > 0.12 ||
      sample.torso_counter_rotation_rad < -0.12
    }),
  )
  for sample in payload.authored_motion_samples {
    assert_true(sample.left_foot_x_m > 0.0)
    assert_true(sample.right_foot_x_m < 0.0)
  }
  assert_eq(payload.authored_motor_frames.length(), payload.walk_sample_count)
  assert_true(
    payload.authored_motor_frames.any(fn(frame) {
      frame.driven_joint_count > 0 &&
      frame.status == "world-heightfield-hinge-motor-driven"
    }),
  )
  for frame in payload.authored_motor_frames {
    assert_eq(frame.joint_count, payload.driven_joint_ids.length())
    assert_eq(frame.review_count, 0)
    assert_true(frame.max_abs_velocity_rad_s <= 3.0)
  }
  assert_eq(payload.frame_count, 24)
  assert_eq(payload.review_status, "moonrobo-noetix-generated-review-ready")
  assert_eq(
    payload.evidence_source,
    "vectie/moonrobo/src/moonmoon_adapter#noetix_e1_moonmoon_walk_clip_contract#authored_contact_frames",
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
  assert_eq(payload.source_refs.length(), 6)
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.moonmoon-adapter-contract" &&
      source.local_path ==
      "../moonrobo/src/moonmoon_adapter/noetix_contract.mbt#noetix_e1_moonmoon_locomotion_contract" &&
      source.status == "generated-from-typed-source"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.robot-profile" &&
      source.local_path == "../moonrobo/examples/noetix-e1/robot.json" &&
      source.status == "typed-source"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.urdf" &&
      source.local_path == "../moonrobo/examples/noetix-e1/model/robot.urdf" &&
      source.status == "typed-source"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.moonmoon-adapter-contact-evidence" &&
      source.local_path ==
      "vectie/moonrobo/src/moonmoon_adapter#noetix_e1_moonmoon_walk_clip_contract#authored_contact_frames" &&
      source.status == "generated-from-typed-source"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonmoon.rabbita.generated-evidence" &&
      source.local_path ==
      "ui/rabbita-moon/scene3d.js#__moonmoonGaitDiagnostics" &&
      source.status == "generated-ui-gate"
    }),
  )
}
