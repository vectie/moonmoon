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
  assert_eq(trace.frames[0].support_phase, "left-support")
  assert_eq(trace.frames[10].support_phase, "right-support")
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
    min_swing_clearance_m: 0.02,
    foot_radius_m: 0.012,
    caution_grade: 0.18,
    body_height_m: 0.72,
    terrain_source_id: field.field_id,
  }
  let trace = noetix_moon_walk_trace(field, 3, config~)
  assert_eq(trace.endless_axis, "heading-rad:\{config.heading_rad}")
  assert_true(trace.frames[0].body_position.x > 0.999999)
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
  assert_eq(profile.actuator_profiles.length(), 24)
  assert_true(profile.collision_shapes.length() >= 6)
  assert_true(profile.mass_model.mass_kg > 0.0)
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
  assert_eq(report.visual_geometry_count, 6)
  assert_eq(report.mesh_asset_count, 1)
  assert_eq(report.collision_tag_count, 0)
  assert_eq(report.inertial_tag_count, 0)
  assert_true(!report.low_level_joint_control_enabled)
  assert_true(report.high_level_walk_requires_approval)
  assert_true(
    report.note.contains("no authoritative collision or inertial tags"),
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
  assert_true(report.review_frame_count > 0)
  assert_eq(report.traction_review_frame_count, 0)
  assert_true(report.worst_planar_margin_m < 0.0)
  assert_true(report.worst_traction_margin_n >= 0.0)
  assert_eq(report.status, "static-support-review")
  assert_true(
    report.frames.any(fn(frame) { frame.status == "static-margin-review" }),
  )
  assert_true(report.note.contains("friction-cone"))
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
  assert_true(report.note.contains("servo gains"))
  assert_true(report.max_abs_velocity_rad_s >= 0.0)
  assert_true(report.max_abs_mechanical_power_w > 0.0)
  assert_true(report.total_absolute_work_j > 0.0)
  assert_true(report.frames[0].steps.length() == 24)
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
  assert_true(report.frames.all(fn(frame) { frame.limit_review_count == 0 }))
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
  assert_true(report.max_self_contact_normal_impulse_ns >= 0.0)
  assert_true(report.max_self_contact_friction_impulse_ns > 0.0)
  assert_true(report.note.contains("Moonphys diagonal inertia"))
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
