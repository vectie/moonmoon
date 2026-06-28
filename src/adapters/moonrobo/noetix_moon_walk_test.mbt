///|
fn nearly_equal_double(a : Double, b : Double) -> Bool {
  let delta = a - b
  let absolute = if delta < 0.0 { 0.0 - delta } else { delta }
  absolute < 0.0000001
}

///|
test "noetix endless moon walk advances in one direction" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=24)
  assert_eq(trace.frame_count, 24)
  assert_eq(trace.robot.robot_id, "noetix-e1-lab-01")
  assert_eq(trace.config.terrain_source_id, trace.terrain_tile_id)
  assert_eq(trace.config.heading_rad, 0.0)
  assert_true(trace.config.start_position == @moonphys.vec3(0.0, 0.0, 0.0))
  assert_true(trace.config.foot_radius_m > 0.0)
  assert_true(
    trace.config.speed_mps ==
    trace.config.step_length_m * trace.config.stride_frequency_hz,
  )
  assert_true(
    trace.frames[23].body_position.x > trace.frames[0].body_position.x,
  )
  assert_eq(trace.frames[0].support_phase, "double-support-left-transfer")
  assert_eq(trace.frames[10].support_phase, "double-support-right-transfer")
}

///|
test "noetix endless moon walk honors heading and start position" {
  let field = first_trusted_square_noetix_heightfield()
  let config : NoetixMoonWalkConfig = {
    config_id: "test/heading",
    gravity_mps2: @moonphys.lunar_environment().gravity_mps2,
    dt_s: 0.1,
    speed_mps: 0.12,
    heading_rad: 3.141592653589793 / 2.0,
    start_position: @moonphys.vec3(1.0, 2.0, 0.1),
    step_length_m: 0.16,
    step_height_m: 0.045,
    stride_frequency_hz: 0.75,
    cycle_frames: 20,
    lateral_foot_offset_m: 0.08,
    support_lateral_shift_m: 0.08,
    support_forward_lead_m: 0.11,
    double_support_frames: 6,
    min_swing_clearance_m: 0.02,
    foot_radius_m: 0.012,
    caution_grade: 0.18,
    body_height_m: 0.72,
    terrain_source_id: field.field_id,
  }
  let trace = noetix_moon_walk_trace(field, 3, config~)
  assert_eq(trace.endless_axis, "heading-rad:\{config.heading_rad}")
  assert_true(trace.frames[0].body_position.x > 1.0)
  assert_true(trace.frames[0].body_position.y > 1.999999)
  assert_true(trace.frames[2].body_position.y > trace.frames[0].body_position.y)
  assert_true(
    trace.frames[2].body_position.x < trace.frames[0].body_position.x + 0.000001,
  )
  assert_true(
    trace.frames[0].body_position.z >
    @moonphys.sample_heightfield(field, 1.0, 2.0).elevation_m +
    config.body_height_m,
  )
}

///|
test "noetix moon walk shifts body over support foot" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=16)
  assert_true(trace.config.support_lateral_shift_m > 0.0)
  assert_true(trace.config.support_forward_lead_m > 0.0)
  assert_true(trace.config.double_support_frames > 0)
  assert_true(trace.frames[0].left_foot.in_contact)
  assert_true(trace.frames[0].right_foot.in_contact)
  assert_true(trace.frames[5].body_position.y > 0.0)
  assert_true(trace.frames[10].left_foot.in_contact)
  assert_true(trace.frames[10].right_foot.in_contact)
  assert_true(trace.frames[15].body_position.y < 0.0)
  assert_true(
    nearly_equal_double(
      trace.frames[5].body_position.y,
      trace.config.support_lateral_shift_m,
    ),
  )
}

///|
test "noetix endless moon walk alternates contact feet" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  assert_true(trace.frames[0].left_foot.in_contact)
  assert_true(trace.frames[0].right_foot.in_contact)
  assert_true(!trace.frames[6].right_foot.in_contact)
  assert_true(trace.frames[10].left_foot.in_contact)
  assert_true(trace.frames[10].right_foot.in_contact)
}

///|
test "noetix support feet stay planted while in contact" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=24)
  let left_plant = trace.frames[0].left_foot.position
  for index in 0..<10 {
    assert_true(trace.frames[index].left_foot.in_contact)
    let delta = trace.frames[index].left_foot.position.sub(left_plant)
    assert_true(delta.length_squared() < 0.000000000001)
  }
  let right_plant = trace.frames[10].right_foot.position
  for index in 10..<20 {
    assert_true(trace.frames[index].right_foot.in_contact)
    let delta = trace.frames[index].right_foot.position.sub(right_plant)
    assert_true(delta.length_squared() < 0.000000000001)
  }
}

///|
test "noetix endless gait evidence verifies periodic phase and forward offset" {
  let evidence = first_trusted_square_noetix_endless_gait_evidence()
  assert_eq(evidence.robot_id, "noetix-e1-lab-01")
  assert_eq(evidence.reference_frame_index, 0)
  assert_eq(evidence.repeated_frame_index, evidence.cycle_frames)
  assert_eq(evidence.reference_support_phase, evidence.repeated_support_phase)
  assert_true(evidence.phase_repeat_verified)
  assert_true(evidence.contact_repeat_verified)
  assert_true(evidence.monotonic_forward_verified)
  assert_true(evidence.observed_forward_offset_m > 0.0)
  let offset_error = evidence.observed_forward_offset_m -
    evidence.expected_forward_offset_m
  assert_true(offset_error < 0.000001 && offset_error > -0.000001)
  assert_eq(evidence.status, "endless-gait-window-verified")
  assert_eq(evidence.hardware_authority, "moonmoon-safety-gate-only")
}

///|
test "noetix endless moon walk carries urdf leg ik phases" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  assert_eq(trace.frames[0].joint_phases.length(), 24)
  assert_true(
    trace.frames[0].joint_phases.any(fn(phase) {
      phase.joint_name == "leg_r3_joint" &&
      phase.status == "urdf-leg-ik" &&
      phase.position_rad > 0.0
    }),
  )
  assert_true(
    trace.frames[5].joint_phases.any(fn(phase) {
      phase.joint_name == "leg_r1_joint" &&
      phase.status == "urdf-leg-ik" &&
      phase.position_rad >= -1.2 &&
      phase.position_rad <= 1.2
    }),
  )
}

///|
test "noetix physics profile keeps assumed dynamics explicit" {
  let profile = default_noetix_physics_profile()
  assert_eq(profile.robot_id, "noetix-e1-lab-01")
  assert_eq(profile.foot_geometry.length(), 2)
  assert_eq(profile.actuator_profiles.length(), 24)
  assert_true(profile.collision_shapes.length() >= 6)
  assert_true(profile.mass_model.mass_kg > 0.0)
  assert_eq(
    profile.physical_model_readiness.readiness_id,
    "moonrobo/noetix-e1/physical-model-readiness-v0",
  )
  assert_eq(profile.physical_model_readiness.required_item_count, 11)
  assert_eq(profile.physical_model_readiness.authoritative_item_count, 2)
  assert_eq(profile.physical_model_readiness.assumed_item_count, 7)
  assert_eq(profile.physical_model_readiness.missing_item_count, 2)
  assert_eq(profile.physical_model_readiness.blocker_count, 9)
  assert_eq(
    profile.physical_model_readiness.blocker_ids.length(),
    profile.physical_model_readiness.blocker_count,
  )
  assert_true(!profile.physical_model_readiness.ready)
  assert_eq(
    profile.physical_model_readiness.status,
    "physical-model-assumption-review",
  )
  assert_true(
    profile.physical_model_readiness.authoritative_items.contains(
      "joint-effort-limits",
    ),
  )
  assert_true(profile.physical_model_readiness.assumed_items.contains("mass"))
  assert_true(
    profile.physical_model_readiness.missing_items.contains("joint-damping"),
  )
  assert_true(
    profile.physical_model_readiness.blocker_ids.contains("assumed:mass"),
  )
  assert_true(
    profile.physical_model_readiness.blocker_ids.contains(
      "missing:joint-damping",
    ),
  )
  assert_true(
    profile.mass_model.source_status.contains("simulation-assumption"),
  )
  assert_true(profile.note.contains("URDF joint limits"))
  assert_true(profile.note.contains("simulation assumptions"))
  assert_eq(profile.hardware_authority, "moonmoon-safety-gate-only")
}

///|
test "noetix actuator profiles carry urdf joint limits into moonphys" {
  let actuators = noetix_joint_actuator_profiles()
  assert_eq(actuators.length(), 24)
  assert_true(
    actuators.any(fn(actuator) {
      actuator.joint_name == "leg_l4_joint" &&
      actuator.joint_index == 8 &&
      actuator.limit.min_position_rad == -1.8 &&
      actuator.limit.max_position_rad == 1.8 &&
      actuator.limit.max_torque_nm == 100.0 &&
      actuator.limit.max_velocity_rad_s == 3.0 &&
      actuator.source_status.contains("urdf-limit-tag")
    }),
  )
  assert_true(
    actuators.any(fn(actuator) {
      actuator.joint_name == "waist_2_joint" &&
      actuator.limit.max_velocity_rad_s == 2.0
    }),
  )
}

///|
test "noetix source model audit records moonrobo urdf metadata gaps" {
  let report = first_trusted_square_noetix_source_model_report()
  assert_eq(report.robot_id, "noetix-e1-lab-01")
  assert_eq(report.link_count, 25)
  assert_eq(report.joint_count, 24)
  assert_eq(report.joint_limit_count, 24)
  assert_eq(report.joint_limits.length(), 24)
  assert_eq(report.visual_geometry_count, 6)
  assert_eq(report.mesh_asset_count, 1)
  assert_eq(report.collision_tag_count, 0)
  assert_eq(report.inertial_tag_count, 0)
  assert_eq(report.missing_collision_link_count, 25)
  assert_eq(report.missing_inertial_link_count, 25)
  assert_eq(report.source_metadata_blocker_count, 50)
  assert_eq(
    report.source_metadata_blocker_ids.length(),
    report.source_metadata_blocker_count,
  )
  assert_eq(
    report.source_metadata_inventory.blocker_ids.length(),
    report.source_metadata_blocker_count,
  )
  assert_eq(report.missing_collision_links.length(), 25)
  assert_eq(report.missing_inertial_links.length(), 25)
  assert_true(report.missing_collision_links.contains("left_foot"))
  assert_true(report.missing_inertial_links.contains("right_foot"))
  assert_true(
    report.source_metadata_blocker_ids.contains(
      "missing-collision-shape:left_foot",
    ),
  )
  assert_true(
    report.source_metadata_blocker_ids.contains("missing-inertial:right_foot"),
  )
  assert_eq(report.status, "source-model-metadata-blocked")
  assert_true(!report.low_level_joint_control_enabled)
  assert_true(report.high_level_walk_requires_approval)
  assert_true(
    report.note.contains("no authoritative collision or inertial tags"),
  )
  assert_true(
    report.joint_limits.any(fn(limit) {
      limit.joint_name == "leg_l4_joint" &&
      limit.joint_index == 8 &&
      limit.effort_nm == 100.0 &&
      limit.velocity_rad_s == 3.0 &&
      limit.source_status == "urdf-limit-tag"
    }),
  )
  assert_true(
    report.visual_geometries.any(fn(geometry) {
      geometry.link_name == "base_link" &&
      geometry.kind == SourceMeshGeometry &&
      geometry.mesh_path.contains("base.obj") &&
      geometry.size_m == @moonphys.vec3(0.24, 0.20, 0.04)
    }),
  )
}

///|
test "noetix collision profiles expose moonphys review shapes" {
  let profile = default_noetix_physics_profile()
  assert_true(profile.collision_shapes.length() >= 8)
  assert_true(
    profile.collision_shapes.any(fn(collision) {
      collision.link_name == "base_link" &&
      collision.shape.kind == @moonphys.BoxShape &&
      collision.source_status.contains("urdf-visual-mesh")
    }),
  )
  assert_true(
    profile.collision_shapes.any(fn(collision) {
      collision.link_name == "chest_link" &&
      collision.shape.kind == @moonphys.BoxShape &&
      collision.source_status == "urdf-visual-box"
    }),
  )
  assert_true(
    profile.collision_shapes.any(fn(collision) {
      collision.link_name == "left_foot" &&
      collision.shape.kind == @moonphys.BoxShape &&
      collision.source_status.contains("simulation-assumption")
    }),
  )
}

///|
test "noetix static support report flags kinematic walk for review" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  let report = noetix_walk_stability_report(trace)
  assert_eq(report.frame_count, 12)
  assert_eq(report.profile.robot_id, trace.robot.robot_id)
  assert_true(report.stable_frame_count >= 0)
  assert_eq(report.traction_review_frame_count, 0)
  assert_true(report.worst_planar_margin_m <= 1.0)
  assert_true(report.worst_traction_margin_n > 0.0)
  assert_true(report.status.contains("static-support"))
  assert_true(
    report.frames.any(fn(frame) {
      frame.status == "static-margin-review" ||
      frame.status == "contact-patch-review"
    }),
  )
  assert_eq(report.frames[0].contact_patches.length(), 2)
  assert_true(
    report.frames.any(fn(frame) {
      frame.contact_patch_status == "contact-patch-review"
    }),
  )
  assert_true(report.note.contains("friction-cone"))
  assert_true(report.note.contains("contact-patch"))
  assert_true(report.note.contains("patch-load pressure review"))
  assert_true(report.note.contains("terrain-normal force projection"))
  assert_eq(report.frames[0].support_load_assessment.load_count, 2)
  assert_true(
    report.frames[0].support_load_assessment.total_normal_force_n > 0.0,
  )
  assert_true(
    report.frames[0].support_load_assessment.loads[0].normal_force_n > 0.0,
  )
  assert_eq(report.frames[0].contact_patch_loads.length(), 2)
  assert_true(report.frames[0].contact_patch_loads[0].loaded_sample_count > 0)
  assert_true(report.frames[0].contact_patch_loads[0].max_pressure_pa > 0.0)
  assert_eq(report.frames[0].traction_assessments.length(), 2)
  assert_eq(report.frames[0].traction_status, "traction-ok")
  assert_true(
    report.frames[0].traction_assessments.any(fn(traction) {
      traction.status == "traction-ok" &&
      traction.normal_force_n > 0.0 &&
      traction.margin_n > 0.0
    }),
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
test "noetix joint control report replays gait phases through moonphys" {
  let trace = first_trusted_square_noetix_walk_trace(frame_count=12)
  let report = noetix_joint_control_report(trace)
  assert_eq(report.frame_count, 12)
  assert_eq(report.joint_count_per_frame, 24)
  assert_eq(report.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(report.status.contains("joint-control"))
  assert_true(report.note.contains("joint-frame motor integration"))
  assert_true(report.note.contains("hinge-joint frame assessment"))
  assert_true(report.note.contains("world hinge constraint replay"))
  assert_true(report.note.contains("world hinge motor replay"))
  assert_true(report.note.contains("sequential world hinge motor trace"))
  assert_true(report.note.contains("motor-driven heightfield world replay"))
  assert_true(report.note.contains("servo gains"))
  assert_eq(report.hinge_joint_frame_count, 12)
  assert_eq(report.hinge_joint_count_per_frame, 24)
  assert_eq(report.hinge_motor_driven_frame_count, 12)
  assert_true(report.hinge_motor_driven_joint_count > 0)
  assert_eq(report.hinge_motor_trace.frame_count, 12)
  assert_eq(
    report.hinge_motor_trace.driven_joint_count,
    report.hinge_motor_driven_joint_count,
  )
  assert_eq(report.hinge_motor_trace.final_projected_body_count, 25)
  assert_true(
    report.hinge_motor_trace.status.contains("world-hinge-motor-trace"),
  )
  assert_eq(report.hinge_motor_world_trace.frame_count, 12)
  assert_eq(report.hinge_motor_world_trace.motor_frame_count, 12)
  assert_eq(
    report.hinge_motor_world_trace.driven_joint_count,
    report.hinge_motor_driven_joint_count,
  )
  assert_true(report.hinge_motor_world_trace.contact_count > 0)
  assert_true(report.hinge_motor_world_trace.support_contact_count > 0)
  assert_true(report.hinge_motor_world_trace.stable_support_frame_count >= 0)
  assert_true(report.hinge_motor_world_trace.support_review_frame_count >= 0)
  assert_eq(
    report.hinge_motor_world_trace.capture_stable_support_frame_count +
    report.hinge_motor_world_trace.capture_support_review_frame_count,
    report.hinge_motor_world_trace.frame_count,
  )
  assert_true(
    report.hinge_motor_world_trace.resolved_hinge_constraint_count >
    report.hinge_motor_driven_joint_count,
  )
  assert_eq(report.hinge_motor_world_trace.final_body_count, 25)
  assert_eq(report.hinge_motor_world_trace.final_projected_body_count, 25)
  assert_eq(report.hinge_motor_world_trace.body_sample_count, 325)
  assert_true(report.hinge_motor_world_trace.max_position.x > 0.0)
  assert_true(
    report.hinge_motor_world_trace.max_position.z >=
    report.hinge_motor_world_trace.min_position.z,
  )
  assert_true(report.hinge_motor_world_trace.max_speed_mps >= 0.0)
  assert_true(report.hinge_motor_world_trace.max_kinetic_energy_j >= 0.0)
  assert_true(report.hinge_motor_world_trace.total_mass_kg > 0.0)
  assert_true(
    report.hinge_motor_world_trace.final_center_of_mass.x >=
    report.hinge_motor_world_trace.initial_center_of_mass.x,
  )
  assert_true(
    report.hinge_motor_world_trace.max_center_of_mass.z >=
    report.hinge_motor_world_trace.min_center_of_mass.z,
  )
  assert_true(
    report.hinge_motor_world_trace.max_center_of_mass_speed_mps >= 0.0,
  )
  assert_true(report.hinge_motor_world_trace.min_support_margin_m <= 1.0)
  assert_true(
    report.hinge_motor_world_trace.max_support_recovery_shift_m >= 0.0,
  )
  assert_true(
    report.hinge_motor_world_trace.worst_capture_support_margin_m <= 1.0,
  )
  assert_true(
    report.hinge_motor_world_trace.max_capture_recovery_shift_m >= 0.0,
  )
  assert_true(
    report.hinge_motor_world_trace.max_center_of_pressure_error_m >= 0.0,
  )
  assert_true(
    report.hinge_motor_world_trace.max_body_linear_momentum_kg_mps >= 0.0,
  )
  assert_true(
    report.hinge_motor_world_trace.max_world_linear_momentum_kg_mps >= 0.0,
  )
  assert_true(
    report.hinge_motor_world_trace.max_frame_kinetic_energy_delta_j >= 0.0,
  )
  assert_true(
    report.hinge_motor_world_trace.envelope_status.contains(
      "world-trace-envelope",
    ),
  )
  assert_eq(
    report.hinge_motor_world_trace.envelope_status,
    "world-trace-envelope-bounded",
  )
  assert_true(
    report.hinge_motor_world_trace.world_review_status.contains(
      "world-replay-review",
    ),
  )
  assert_true(!report.hinge_motor_world_trace.world_review_ready)
  assert_eq(report.hinge_motor_world_trace.world_review_blocker_count, 2)
  assert_true(
    !report.hinge_motor_world_trace.world_review_blockers.contains(
      "world-envelope-review",
    ),
  )
  assert_true(
    report.hinge_motor_world_trace.world_review_blockers.contains(
      "world-support-review",
    ),
  )
  assert_true(
    report.hinge_motor_world_trace.world_review_blockers.contains(
      "world-dynamic-support-review",
    ),
  )
  assert_true(
    report.hinge_motor_world_trace.status.contains(
      "world-heightfield-hinge-motor-trace",
    ),
  )
  assert_true(report.hinge_review_frame_count >= 0)
  assert_true(report.max_hinge_position_error_m >= 0.0)
  assert_true(report.max_hinge_angular_error_rad >= 0.0)
  assert_true(report.max_hinge_motor_angle_delta_rad >= 0.0)
  assert_true(report.max_hinge_motor_velocity_delta_rad_s >= 0.0)
  assert_true(report.hinge_linear_impulse_ns >= 0.0)
  assert_true(report.hinge_angular_impulse_nms >= 0.0)
  assert_true(report.max_abs_velocity_rad_s <= 3.0)
  assert_true(report.max_abs_mechanical_power_w > 0.0)
  assert_true(report.total_absolute_work_j > 0.0)
  assert_true(report.frames[0].steps.length() == 24)
  assert_eq(report.frames[0].hinge_joint_frame.body_count, 25)
  assert_eq(report.frames[0].hinge_joint_frame.joint_count, 24)
  assert_eq(report.frames[0].hinge_joint_frame.assessed_joint_count, 24)
  assert_eq(report.frames[0].hinge_joint_frame.projected_body_count, 25)
  assert_true(
    report.frames[0].hinge_joint_frame.resolved_hinge_constraint_count >= 0,
  )
  assert_true(report.frames[0].hinge_joint_frame.motor_driven_joint_count > 0)
  assert_true(report.frames[0].hinge_joint_frame.motor_review_count >= 0)
  assert_true(
    report.frames[0].hinge_joint_frame.max_motor_angle_delta_rad >= 0.0,
  )
  assert_true(
    report.frames[0].hinge_joint_frame.max_motor_velocity_delta_rad_s >= 0.0,
  )
  assert_true(
    report.frames[0].hinge_joint_frame.world_status.contains(
      "world-hinge-constraint",
    ),
  )
  assert_true(
    report.frames[0].hinge_joint_frame.assessment_status.contains(
      "hinge-joint-frame",
    ),
  )
  assert_true(
    report.frames[0].hinge_joint_frame.status.contains("noetix-hinge-world"),
  )
  assert_true(
    report.frames[0].hinge_joint_frame.motor_status.contains(
      "world-hinge-motor",
    ),
  )
  assert_true(
    report.frames[0].hinge_joint_frame.motor_world_status.contains(
      "world-hinge-constraint",
    ),
  )
  assert_true(
    report.frames.any(fn(frame) {
      frame.hinge_joint_frame.resolved_hinge_constraint_count > 0 &&
      frame.hinge_joint_frame.world_status == "world-hinge-constraint-resolved"
    }),
  )
  assert_true(
    report.frames.any(fn(frame) {
      frame.hinge_joint_frame.motor_driven_joint_count > 0 &&
      frame.hinge_joint_frame.motor_status == "world-hinge-motor-driven"
    }),
  )
  assert_true(
    report.frames.any(fn(frame) {
      frame.steps.any(fn(step) {
        step.joint_name == "leg_r3_joint" &&
        step.motor_step.limit.max_torque_nm == 100.0 &&
        step.motor_step.absolute_work_j >= 0.0
      })
    }),
  )
}

///|
test "noetix joint control report preserves urdf limits" {
  let report = first_trusted_square_noetix_joint_control_report()
  assert_true(
    report.frames[0].steps.any(fn(step) {
      step.joint_name == "waist_2_joint" &&
      step.motor_step.limit.min_position_rad == -0.5 &&
      step.motor_step.limit.max_position_rad == 0.5 &&
      step.motor_step.limit.max_velocity_rad_s == 2.0
    }),
  )
  assert_eq(report.limit_review_frame_count, 0)
  assert_eq(report.status, "joint-control-assumption-review")
  assert_true(
    report.frames[3].steps.any(fn(step) {
      step.joint_name == "leg_r3_joint" &&
      step.velocity_within_limits &&
      step.target_velocity_rad_s <= 3.0 &&
      step.target_velocity_rad_s >= -3.0
    }),
  )
}

///|
test "noetix inertial collision report maps profile shapes onto moonphys" {
  let field = first_trusted_square_noetix_heightfield()
  let trace = noetix_moon_walk_trace(field, 12)
  let report = noetix_inertial_collision_report(trace, field)
  assert_eq(report.frame_count, 12)
  assert_eq(report.profile.robot_id, trace.robot.robot_id)
  assert_eq(report.hardware_authority, "moonmoon-safety-gate-only")
  assert_true(report.shapes_per_frame >= 6)
  assert_true(report.max_support_contact_torque_nm > 0.0)
  assert_true(report.max_self_contact_correction_m >= 0.0)
  assert_true(report.max_self_contact_world_correction_m > 0.0)
  assert_true(report.max_self_contact_normal_impulse_ns >= 0.0)
  assert_true(report.max_self_contact_friction_impulse_ns > 0.0)
  assert_eq(report.frames[0].support_contact_wrenches.length(), 2)
  assert_true(
    report.frames[0].support_contact_wrenches.any(fn(wrench) {
      wrench.status == "patch-wrench-resolved" &&
      wrench.loaded_sample_count > 0 &&
      wrench.normal_force_n > 0.0
    }),
  )
  assert_true(
    report.note.contains("Moonphys composite primitive-shape mass properties"),
  )
  assert_true(
    report.frames[0].mass_properties.status == "composite-mass-resolved" &&
    report.frames[0].mass_properties.element_count ==
    report.frames[0].shape_count &&
    nearly_equal_double(
      report.frames[0].mass_properties.total_mass_kg,
      report.profile.mass_model.mass_kg,
    ),
  )
  assert_eq(
    report.frames[0].support_wrench_motion_step.status,
    "wrench-integrated",
  )
  assert_true(
    report.frames[0].support_wrench_motion_step.wrench.force_n.z > 0.0,
  )
  assert_true(
    report.frames[0].support_wrench_motion_step.angular_acceleration_rad_s2.length() >
    0.0,
  )
  assert_true(
    report.frames[0].support_wrench_motion_step.linear_impulse_ns.z > 0.0,
  )
  assert_true(
    report.frames[0].support_wrench_motion_step.angular_impulse_nms.length() >
    0.0,
  )
  assert_true(
    report.frames[0].support_wrench_motion_step.kinetic_energy_delta_j > 0.0,
  )
  assert_eq(
    report.frames[0].self_contact_world_response.status,
    "world-contact-resolved",
  )
  assert_eq(
    report.frames[0].self_contact_world_response.contact_count,
    report.frames[0].self_contact_world_response.resolved_contact_count,
  )
  assert_true(report.frames[0].self_contact_world_correction_m > 0.0)
  assert_true(
    report.frames[0].self_contact_world_response.resolved_pairs.any(fn(pair) {
      pair.status == "world-pair-resolved" &&
      pair.correction_a_m > 0.0 &&
      pair.correction_b_m > 0.0
    }),
  )
  assert_true(report.note.contains("patch-load contact wrench torque"))
  assert_true(report.note.contains("support-wrench motion preview"))
  assert_true(report.note.contains("world body-pair contact response"))
  assert_true(report.note.contains("kinetic-energy accounting"))
  assert_true(report.note.contains("impulse accounting"))
  assert_true(report.note.contains("not authoritative"))
  assert_true(
    report.frames[0].shapes.any(fn(shape) {
      shape.link_name == "chest_link" &&
      shape.bounds.status == "conservative-bounds"
    }),
  )
}

///|
test "noetix inertial collision report checks terrain and self contacts" {
  let report = first_trusted_square_noetix_inertial_collision_report()
  assert_eq(report.frame_count, 32)
  assert_true(report.frames[0].terrain_collisions.length() == 2)
  assert_true(
    report.frames.all(fn(frame) {
      frame.terrain_collisions.any(fn(collision) {
        collision.link_name == "left_foot" &&
        collision.status == "terrain-collision-matches-walk-contact"
      }) &&
      frame.terrain_collisions.any(fn(collision) {
        collision.link_name == "right_foot" &&
        collision.status == "terrain-collision-matches-walk-contact"
      })
    }),
  )
  assert_true(report.self_contact_frame_count > 0)
  assert_true(report.max_self_penetration_m >= 0.0)
  assert_true(report.frames[0].self_contact_manifold.contacts.length() > 0)
  assert_true(
    report.frames.any(fn(frame) {
      frame.self_contact_resolution.status == "multi-contact-resolved" &&
      frame.self_contact_correction_m > 0.0 &&
      frame.self_contact_resolution.friction_impulse_ns > 0.0
    }),
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
      link.link_name == "left_foot" &&
      link.joint_name == "leg_l6_joint" &&
      link.joint_axis == @moonphys.vec3(0.0, 1.0, 0.0)
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
  assert_true(poses.note.contains("hardware authority"))
  assert_true(poses.note.contains("not full dynamics"))
  let first = poses.frames[0]
  assert_eq(first.links.length(), 25)
  assert_true(
    first.links.any(fn(link) {
      link.link_name == "left_foot" &&
      link.world_position == walk.frames[0].left_foot.position &&
      link.source_status == "urdf-fk-contact-bound" &&
      !link.visual_geometry.has_visual_geometry &&
      link.visual_geometry.source_status == "urdf-visual-geometry-missing" &&
      link.contact_error_m >= 0.0
    }),
  )
  assert_true(
    first.links.any(fn(link) {
      link.link_name == "base_link" &&
      link.visual_geometry.has_visual_geometry &&
      link.visual_geometry.kind == SourceMeshGeometry &&
      link.visual_geometry.mesh_path.contains("base.obj") &&
      link.visual_geometry.size_m == @moonphys.vec3(0.24, 0.20, 0.04)
    }),
  )
  assert_true(
    first.links.any(fn(link) {
      link.link_name == "chest_link" &&
      link.visual_geometry.has_visual_geometry &&
      link.visual_geometry.kind == SourceBoxGeometry &&
      link.visual_geometry.world_origin_xyz_m.z > link.world_position.z
    }),
  )
  assert_true(
    first.links.any(fn(link) {
      link.link_name == "right_foot" &&
      link.world_position == walk.frames[0].right_foot.position
    }),
  )
  assert_true(
    first.links.any(fn(link) {
      link.role == "foot" && link.contact_error_m > 0.0
    }),
  )
}

///|
test "noetix link pose trace carries URDF forward kinematics" {
  let walk = first_trusted_square_noetix_walk_trace(frame_count=12)
  let poses = noetix_link_pose_trace(walk)
  let frame0 = poses.frames[0]
  let frame5 = poses.frames[5]
  let mut leg0_x = 0.0
  let mut leg5_x = 0.0
  let mut arm0_x = 0.0
  let mut arm5_x = 0.0
  for link in frame0.links {
    if link.link_name == "right_leg_3" {
      leg0_x = link.fk_world_position.x
    }
    if link.link_name == "right_arm_1" {
      arm0_x = link.world_position.x
    }
    if link.link_name == "right_leg_3" {
      assert_eq(link.source_status, "urdf-forward-kinematics")
    }
  }
  for link in frame5.links {
    if link.link_name == "right_leg_3" {
      leg5_x = link.fk_world_position.x
    }
    if link.link_name == "right_arm_1" {
      arm5_x = link.world_position.x
    }
  }
  assert_true(leg5_x != leg0_x)
  assert_true(arm5_x != arm0_x)
  assert_true(poses.note.contains("forward-kinematics"))
}
