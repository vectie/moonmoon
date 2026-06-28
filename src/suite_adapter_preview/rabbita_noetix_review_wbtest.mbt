///|
fn fixture_vec3(
  x : Double,
  y : Double,
  z : Double,
) -> SuiteAdapterLiveNoetixVec3 {
  { x, y, z }
}

///|
fn fixture_joint_sample(phase : Double) -> SuiteAdapterAuthoredJointSample {
  {
    phase,
    left_hip_rad: -0.12,
    left_knee_rad: -0.22,
    left_ankle_rad: 0.04,
    left_shoulder_rad: 0.08,
    left_elbow_rad: 0.18,
    right_hip_rad: 0.12,
    right_knee_rad: -0.22,
    right_ankle_rad: -0.04,
    right_shoulder_rad: -0.08,
    right_elbow_rad: 0.18,
  }
}

///|
fn fixture_motion_sample(phase : Double) -> SuiteAdapterAuthoredMotionSample {
  {
    phase,
    root_cycle_forward_m: phase * 0.38,
    root_sway_m: 0.0,
    root_bob_m: -0.01,
    torso_counter_rotation_rad: 0.04,
    left_foot_x_m: 0.12,
    left_foot_y_m: 0.0,
    left_foot_z_m: 0.0,
    left_foot_roll_pitch_rad: 0.02,
    right_foot_x_m: -0.12,
    right_foot_y_m: 0.0,
    right_foot_z_m: 0.0,
    right_foot_roll_pitch_rad: -0.02,
  }
}

///|
fn fixture_contact_frame(
  frame_index : Int,
  phase : Double,
  time_s : Double,
) -> SuiteAdapterLiveNoetixContactFrame {
  let foot = if frame_index == 0 { "left" } else { "right" }
  {
    frame_index,
    time_s,
    phase,
    phase_label: "\{foot}-stance-fixture",
    support_foot: foot,
    review_id: "fixture-motion-frame/\{frame_index}",
    center_of_mass: fixture_vec3(0.0, 0.0, 0.42),
    center_of_mass_velocity: fixture_vec3(0.02, 0.0, 0.0),
    total_mass_kg: 12.0,
    contact_count: 1,
    active_footprint_count: 1,
    contacts: [
      {
        contact_id: "\{foot}-fixture-contact",
        footprint: {
          footprint_id: "\{foot}-fixture-footprint",
          center: fixture_vec3(0.0, 0.0, 0.0),
          half_length_m: 0.18,
          half_width_m: 0.09,
          active: true,
        },
        patch: {
          patch_id: "\{foot}-fixture-patch",
          center: fixture_vec3(0.0, 0.0, 0.0),
          half_length_m: 0.18,
          half_width_m: 0.09,
          sample_count: 4,
          contact_count: 4,
          min_clearance_m: 0.0,
          max_clearance_m: 0.0,
          average_surface_elevation_m: 0.0,
          average_surface_normal: fixture_vec3(0.0, 0.0, 1.0),
          samples: [
            {
              probe_id: "\{foot}-fixture-probe/0",
              position: fixture_vec3(-0.05, -0.03, 0.0),
              surface_elevation_m: 0.0,
              surface_normal: fixture_vec3(0.0, 0.0, 1.0),
              clearance_m: 0.0,
              in_contact: true,
              local_grade: 0.0,
              status: "contact",
            },
            {
              probe_id: "\{foot}-fixture-probe/1",
              position: fixture_vec3(0.05, -0.03, 0.0),
              surface_elevation_m: 0.0,
              surface_normal: fixture_vec3(0.0, 0.0, 1.0),
              clearance_m: 0.0,
              in_contact: true,
              local_grade: 0.0,
              status: "contact",
            },
            {
              probe_id: "\{foot}-fixture-probe/2",
              position: fixture_vec3(0.05, 0.03, 0.0),
              surface_elevation_m: 0.0,
              surface_normal: fixture_vec3(0.0, 0.0, 1.0),
              clearance_m: 0.0,
              in_contact: true,
              local_grade: 0.0,
              status: "contact",
            },
            {
              probe_id: "\{foot}-fixture-probe/3",
              position: fixture_vec3(-0.05, 0.03, 0.0),
              surface_elevation_m: 0.0,
              surface_normal: fixture_vec3(0.0, 0.0, 1.0),
              clearance_m: 0.0,
              in_contact: true,
              local_grade: 0.0,
              status: "contact",
            },
          ],
          status: "patch-contact",
        },
        applied_force_n: fixture_vec3(0.0, 0.0, 60.0),
      },
    ],
    status: "motion-contact-frame-ready",
  }
}

///|
fn fixture_motor_frame(
  frame_index : Int,
  phase_start : Double,
  phase_end : Double,
  time_s : Double,
) -> SuiteAdapterMotorFrameSample {
  {
    frame_index,
    time_s,
    dt_s: 0.1,
    phase_start,
    phase_end,
    phase_label: "fixture-phase",
    support_foot: if frame_index == 0 {
      "left"
    } else {
      "right"
    },
    joint_count: 1,
    driven_joint_count: 1,
    review_count: 0,
    max_abs_angle_delta_rad: 0.05,
    max_abs_velocity_rad_s: 0.5,
    max_abs_commanded_torque_nm: 0.4,
    total_absolute_work_j: 0.02,
    steps: [
      {
        joint_id: "fixture_joint",
        parent_link: "fixture_parent",
        child_link: "fixture_child",
        side: "left",
        field: "hip",
        before_position_rad: 0.0,
        target_position_rad: 0.05,
        target_velocity_rad_s: 0.5,
        bounded_velocity_rad_s: 0.5,
        angle_delta_rad: 0.05,
        commanded_torque_nm: 0.4,
        work_j: 0.02,
        min_position_rad: -1.0,
        max_position_rad: 1.0,
        max_velocity_rad_s: 2.0,
        max_torque_nm: 10.0,
        stiffness_nm_per_rad: 8.0,
        damping_nm_s_per_rad: 0.4,
        position_within_limits: true,
        velocity_within_limits: true,
        torque_saturated: false,
        status: "joint-commanded",
      },
    ],
    status: "world-heightfield-hinge-motor-driven",
  }
}

///|
fn fixture_live_contract() -> SuiteAdapterLiveNoetixContract {
  {
    contract_id: "fixture-noetix/moonmoon-locomotion-source-contract",
    target_payload_type: "vectie/moonmoon/src/suite_adapter_preview.NoetixSuiteAdapterPayload",
    robot_id: "fixture-noetix",
    robot_label: "Fixture Noetix",
    platform: "noetix-fixture",
    profile_path: "examples/noetix-fixture/robot.json",
    urdf_path: "examples/noetix-fixture/model/robot.urdf",
    mesh_paths: ["examples/noetix-fixture/model/meshes/base.obj"],
    expected_profile_joint_count: 1,
    profile_joint_ids: ["fixture_joint"],
    required_motion_joint_ids: ["fixture_joint"],
    walk_clip: {
      clip_id: "fixture-noetix/endless-forward-walk",
      source: "vectie/moonrobo/src/moonmoon_adapter#fixture_walk_clip",
      cycle_hz: 0.5,
      root_speed_mps: 0.1,
      stride_m: 0.2,
      sample_count: 2,
      foot_phase_sequence: ["stance", "swing"],
      phase_labels: ["left-stance-fixture", "right-stance-fixture"],
      foot_phase_specs: [
        {
          role: "stance",
          phase_start: 0.0,
          phase_end: 0.5,
          support: true,
          lock_window: true,
        },
        {
          role: "swing",
          phase_start: 0.5,
          phase_end: 1.0,
          support: false,
          lock_window: false,
        },
      ],
      required_joint_ids: ["fixture_joint"],
      joint_anchors: [
        {
          joint_id: "fixture_joint",
          side: "left",
          field: "hip",
          phase: 0.0,
          position_rad: 0.0,
        },
      ],
      joint_curve_params: [{ name: "fixture_curve", value: 1.0 }],
      authored_joint_samples: [
        fixture_joint_sample(0.0),
        fixture_joint_sample(0.5),
      ],
      authored_motion_samples: [
        fixture_motion_sample(0.0),
        fixture_motion_sample(0.5),
      ],
      authored_contact_frames: [
        fixture_contact_frame(0, 0.0, 0.0),
        fixture_contact_frame(1, 0.5, 0.1),
      ],
      authored_motor_frames: [
        fixture_motor_frame(0, 0.0, 0.5, 0.0),
        fixture_motor_frame(1, 0.5, 1.0, 0.1),
      ],
      blocker_count: 0,
      blockers: [],
      ready: true,
      status: "moonmoon-noetix-walk-clip-ready",
    },
    source_refs: [
      {
        source_id: "fixture-profile",
        source_family: "moonrobo.robot-profile",
        local_path: "examples/noetix-fixture/robot.json",
        role: "fixture robot profile",
        status: "typed-source",
      },
      {
        source_id: "fixture-urdf",
        source_family: "moonrobo.urdf",
        local_path: "examples/noetix-fixture/model/robot.urdf",
        role: "fixture URDF",
        status: "typed-source",
      },
    ],
    blocker_count: 0,
    blockers: [],
    ready: true,
    status: "moonmoon-noetix-locomotion-contract-ready",
  }
}

///|
test "Rabbita Noetix evidence feeds compiled Moonphys review" {
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
test "Moonrobo live contract JSON ingestion builds suite payload explicitly" {
  let payload = try
    moonrobo_noetix_suite_adapter_payload_from_live_json(
      fixture_live_contract().to_json(),
    )
  catch {
    _ => {
      assert_true(false)
      moonrobo_noetix_suite_adapter_payload_from_live_contract(
        fixture_live_contract(),
      )
    }
  } noraise {
    payload => payload
  }
  assert_true(payload.ready)
  assert_eq(payload.status, "moonrobo-noetix-live-suite-payload-ready")
  assert_eq(payload.review_status, "moonrobo-noetix-live-review-ready")
  assert_eq(payload.robot_id, "fixture-noetix")
  assert_eq(payload.walk_sample_count, 2)
  assert_eq(payload.frame_count, 2)
  assert_eq(payload.authored_joint_samples.length(), 2)
  assert_eq(payload.authored_motion_samples.length(), 2)
  assert_eq(payload.authored_contact_frames.length(), 2)
  assert_eq(payload.authored_motor_frames.length(), 2)
  assert_eq(payload.live_suite_evidence.sample_count, 2)
  assert_eq(payload.live_suite_evidence.authored_contact_frame_count, 2)
  assert_eq(payload.live_suite_evidence.authored_motor_frame_count, 2)
  assert_eq(payload.live_suite_evidence.loaded_contact_count, 2)
  assert_eq(payload.live_suite_evidence.driven_motor_frame_count, 2)
  assert_eq(payload.live_suite_evidence.blocker_count, 0)
  assert_eq(payload.source_refs.length(), 5)
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.moonmoon-adapter-contract" &&
      source.status == "live-typed-source"
    }),
  )
  assert_true(
    payload.source_refs.any(fn(source) {
      source.source_family == "moonrobo.moonmoon-adapter-contact-evidence" &&
      source.status == "live-typed-source"
    }),
  )
  assert_true(
    !payload.source_refs.any(fn(source) {
      source.source_family == "moonmoon.rabbita.generated-evidence"
    }),
  )
}

///|
test "Moonrobo live contract JSON text ingestion reports blockers" {
  let blocked = fixture_live_contract()
  let blocked = { ..blocked, target_payload_type: "wrong.Payload" }
  let payload = try
    moonrobo_noetix_suite_adapter_payload_from_live_json_text(
      blocked.to_json().stringify(),
    )
  catch {
    _ => {
      assert_true(false)
      moonrobo_noetix_suite_adapter_payload_from_live_contract(blocked)
    }
  } noraise {
    payload => payload
  }
  assert_true(!payload.ready)
  assert_eq(payload.status, "moonrobo-noetix-live-suite-payload-blocked")
  assert_true(
    payload.blockers.contains("moonrobo-live-contract-target:wrong.Payload"),
  )
}
