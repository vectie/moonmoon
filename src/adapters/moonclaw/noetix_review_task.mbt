///|
pub(all) struct MoonClawNoetixReviewTask {
  task_id : String
  site_id : @core.SiteId
  robot_id : String
  priority : MoonClawJobPriority
  state : MoonClawReceiptStatus
  objective : String
  source_model_report_id : String
  source_endless_gait_evidence_id : String
  source_walk_trace_id : String
  source_walk_command_plan_id : String
  source_static_support_report_id : String
  source_dynamic_stability_report_id : String
  source_joint_control_report_id : String
  source_inertial_collision_report_id : String
  source_link_pose_trace_id : String
  frame_count : Int
  endless_gait_cycle_frames : Int
  source_model_collision_tag_count : Int
  source_model_inertial_tag_count : Int
  source_model_missing_collision_link_count : Int
  source_model_missing_inertial_link_count : Int
  source_model_metadata_blocker_count : Int
  source_model_metadata_blocker_ids : Array[String]
  source_model_metadata_inventory : @review.ModelMetadataInventory
  source_model_metadata_gaps : Array[@moonrobo.NoetixSourceMetadataGap]
  physical_model_readiness : @review.PhysicalModelReadiness
  physical_model_blocker_count : Int
  physical_model_blocker_ids : Array[String]
  static_support_stable_frame_count : Int
  static_support_review_frame_count : Int
  dynamic_stability_capture_stable_frame_count : Int
  dynamic_stability_review_frame_count : Int
  joint_control_review_frame_count : Int
  joint_control_world_support_review_frame_count : Int
  joint_control_world_capture_review_frame_count : Int
  joint_control_max_support_recovery_shift_m : Double
  joint_control_worst_capture_support_margin_m : Double
  joint_control_max_capture_recovery_shift_m : Double
  joint_control_world_replay_blocker_count : Int
  joint_control_world_replay_blockers : Array[String]
  inertial_collision_review_frame_count : Int
  link_pose_count_per_frame : Int
  walk_command_segment_count : Int
  hardware_state : @moonrobo.MoonroboExecutionState
  hardware_authority : String
  hardware_denied : Bool
  inputs : Array[MoonClawJobInput]
  artifacts : Array[MoonClawTaskArtifact]
  commands : Array[String]
  acceptance_criteria : Array[MoonClawAcceptanceCriterion]
  safety_gate : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn noetix_walk_artifact(
  trace : @moonrobo.NoetixMoonWalkTrace,
) -> MoonClawTaskArtifact {
  let ready = trace.frame_count > 0 && trace.endless_axis == "+x"
  task_artifact(
    "noetix-endless-walk-trace",
    "output/moonrobo/first_trusted_square_noetix_walk.json",
    "moon run cmd/main -- moonrobo noetix walk json",
    "endless +x Noetix trace with lunar gravity, contact probes, and URDF walk clip joint phases",
    "\{trace.frame_count} frames over \{trace.terrain_tile_id}; axis \{trace.endless_axis}; \{trace.robot.joint_count} referenced joints with bounded URDF walk clip",
    ready,
    if ready {
      "none"
    } else {
      "walk trace must advance in +x with at least one generated frame"
    },
    "python3 scripts/check_moonrobo_noetix_walk.py output/moonrobo/first_trusted_square_noetix_walk.json",
  )
}

///|
fn noetix_endless_gait_artifact(
  evidence : @moonrobo.NoetixEndlessGaitEvidence,
) -> MoonClawTaskArtifact {
  let ready = evidence.phase_repeat_verified &&
    evidence.contact_repeat_verified &&
    evidence.monotonic_forward_verified &&
    evidence.status == "endless-gait-window-verified"
  task_artifact(
    "noetix-endless-gait-window",
    "output/moonrobo/first_trusted_square_noetix_endless_gait.json",
    "moon run cmd/main -- moonrobo noetix endless json",
    "Moonrobo evidence that the finite Noetix trace prefix is a window over an endless one-direction gait",
    "cycle \{evidence.cycle_frames} frames; frame \{evidence.reference_frame_index} repeats at \{evidence.repeated_frame_index}; forward offset \{evidence.observed_forward_offset_m} m; status \{evidence.status}",
    ready,
    if ready {
      "none"
    } else {
      "endless gait evidence must verify phase repeat, contact repeat, and monotonic forward motion"
    },
    "python3 scripts/check_moonrobo_noetix_endless_gait.py output/moonrobo/first_trusted_square_noetix_endless_gait.json",
  )
}

///|
fn noetix_walk_command_artifact(
  plan : @moonrobo.NoetixWalkCommandPlan,
) -> MoonClawTaskArtifact {
  let ready = plan.segment_count > 0 &&
    plan.status == "walk-command-dry-run-review" &&
    !plan.executable_on_hardware
  task_artifact(
    "noetix-high-control-walk-command-plan",
    "output/moonrobo/first_trusted_square_noetix_walk_command.json",
    "moon run cmd/main -- moonrobo noetix command json",
    "Moonrobo high-control walk command plan segments the Noetix trace into dry-run approval windows",
    "\{plan.segment_count} dry-run segments; max x \{plan.max_command_x_abs_mps} m/s; duration limit \{plan.high_control_limits.max_duration_ms} ms; executable \{plan.executable_on_hardware}; status \{plan.status}",
    ready,
    if ready {
      "none"
    } else {
      "walk command plan must remain dry-run review evidence within Moonrobo high-control limits"
    },
    "python3 scripts/check_moonrobo_noetix_walk_command.py output/moonrobo/first_trusted_square_noetix_walk_command.json",
  )
}

///|
fn noetix_source_model_artifact(
  report : @moonrobo.NoetixSourceModelReport,
) -> MoonClawTaskArtifact {
  let ready = report.link_count >= 25 &&
    report.joint_count == 24 &&
    report.joint_limit_count == 24
  task_artifact(
    "noetix-source-model-audit",
    "output/moonrobo/first_trusted_square_noetix_source_model.json",
    "moon run cmd/main -- moonrobo noetix model json",
    "Moonrobo source model audit records URDF links, joints, visual geometry, joint limits, and missing inertial/collision tags",
    "\{report.link_count} links; \{report.joint_count} joints; \{report.joint_limit_count} URDF joint limits; \{report.visual_geometry_count} visual geometries; collision tags \{report.collision_tag_count}; inertial tags \{report.inertial_tag_count}; metadata blockers \{report.source_metadata_blocker_count}",
    ready,
    if ready {
      "none"
    } else {
      "source model audit must preserve Noetix link, joint, and joint-limit counts"
    },
    "python3 scripts/check_moonrobo_noetix_source_model.py output/moonrobo/first_trusted_square_noetix_source_model.json",
  )
}

///|
fn noetix_source_sync_artifact(
  report : @moonrobo.NoetixSourceModelReport,
  plan : @moonrobo.NoetixWalkCommandPlan,
) -> MoonClawTaskArtifact {
  let ready = report.joint_limit_count == 24 &&
    report.collision_tag_count == 0 &&
    report.inertial_tag_count == 0 &&
    report.source_metadata_blocker_count > 0 &&
    plan.high_control_limits.source_profile_path == report.source_profile_path
  task_artifact(
    "noetix-moonrobo-source-sync",
    "output/moonrobo/first_trusted_square_noetix_source_model.json",
    "moon run cmd/main -- moonrobo noetix model json && moon run cmd/main -- moonrobo noetix command json",
    "Cross-checks Moonmoon Noetix evidence against sibling Moonrobo robot.json and URDF source files",
    "\{report.joint_count} URDF joints, \{report.joint_limit_count} limits, \{report.visual_geometry_count} visuals, \{report.collision_tag_count} collision tags, \{report.inertial_tag_count} inertial tags, \{report.source_metadata_blocker_count} metadata blockers, command limit \{plan.high_control_limits.max_x_abs_mps} m/s",
    ready,
    if ready {
      "none"
    } else {
      "Moonmoon Noetix evidence must match sibling Moonrobo robot.json and robot.urdf before review"
    },
    "python3 scripts/check_moonrobo_noetix_source_sync.py output/moonrobo/first_trusted_square_noetix_source_model.json output/moonrobo/first_trusted_square_noetix_walk_command.json",
  )
}

///|
fn noetix_link_pose_artifact(
  trace : @moonrobo.NoetixLinkPoseTrace,
) -> MoonClawTaskArtifact {
  let ready = trace.frame_count > 0 && trace.links_per_frame >= 25
  task_artifact(
    "noetix-urdf-reference-link-poses",
    "output/moonrobo/first_trusted_square_noetix_link_poses.json",
    "moon run cmd/main -- moonrobo noetix poses json",
    "URDF-reference RobotRig, RobotMotionFrame samples, link poses, and rigid visual rig contract are present for each Noetix walk frame",
    "\{trace.frame_count} frames; \{trace.links_per_frame} links per frame; rig \{trace.robot_rig_status}; motion \{trace.motion_frame_source}; rig-motion \{trace.rig_motion_contract_status}; \{trace.visual_geometry_link_count} rigid visuals (\{trace.mesh_visual_geometry_link_count} mesh, \{trace.primitive_visual_geometry_link_count} primitives); rig contract \{trace.rig_render_contract_status}; collision metadata links \{trace.collision_metadata_link_count}; inertial metadata links \{trace.inertial_metadata_link_count}; missing collision links \{trace.missing_collision_link_count}; missing inertial links \{trace.missing_inertial_link_count}; status \{trace.status}",
    ready,
    if ready {
      "none"
    } else {
      "link poses must preserve the compact Noetix URDF-reference tree"
    },
    "python3 scripts/check_moonrobo_noetix_link_poses.py output/moonrobo/first_trusted_square_noetix_link_poses.json",
  )
}

///|
fn noetix_static_support_artifact(
  report : @moonrobo.NoetixWalkStabilityReport,
) -> MoonClawTaskArtifact {
  let ready = report.frame_count > 0 &&
    report.stable_frame_count == report.frame_count
  task_artifact(
    "noetix-static-support-review",
    "output/moonrobo/first_trusted_square_noetix_stability.json",
    "moon run cmd/main -- moonrobo noetix stability json",
    "static support evidence is reviewed before any dynamic-walk or hardware claim",
    "\{report.stable_frame_count}/\{report.frame_count} frames support-stable; \{report.review_frame_count} review frames from contact/model provenance; worst planar margin \{report.worst_planar_margin_m} m; status \{report.status}",
    ready,
    if ready {
      "none"
    } else {
      "static support margins must be stable in every frame before downstream review"
    },
    "python3 scripts/check_moonrobo_noetix_stability.py output/moonrobo/first_trusted_square_noetix_stability.json",
  )
}

///|
fn noetix_dynamic_stability_artifact(
  report : @moonrobo.NoetixDynamicStabilityReport,
) -> MoonClawTaskArtifact {
  let ready = report.frame_count > 0 &&
    report.capture_stable_frame_count == report.frame_count
  task_artifact(
    "noetix-dynamic-stability-review",
    "output/moonrobo/first_trusted_square_noetix_dynamics.json",
    "moon run cmd/main -- moonrobo noetix dynamics json",
    "capture-point dynamic stability evidence is reviewed before any stronger walking claim",
    "\{report.capture_stable_frame_count}/\{report.frame_count} frames capture-stable; \{report.review_frame_count} dynamic review frames from model/provenance blockers; worst capture margin \{report.worst_capture_margin_m} m; status \{report.status}",
    ready,
    if ready {
      "none"
    } else {
      "capture-point margins must be stable in every frame before downstream review"
    },
    "python3 scripts/check_moonrobo_noetix_dynamics.py output/moonrobo/first_trusted_square_noetix_dynamics.json",
  )
}

///|
fn noetix_joint_control_artifact(
  report : @moonrobo.NoetixJointControlReport,
) -> MoonClawTaskArtifact {
  let world = report.hinge_motor_world_trace
  let ready = report.frame_count > 0 &&
    report.joint_count_per_frame == 24 &&
    report.saturated_frame_count == 0 &&
    report.limit_review_frame_count == 0 &&
    world.world_review_blocker_count == 0 &&
    world.support_review_frame_count == 0 &&
    world.capture_support_review_frame_count == 0 &&
    world.worst_capture_support_margin_m > 0.0
  task_artifact(
    "noetix-joint-control-review",
    "output/moonrobo/first_trusted_square_noetix_control.json",
    "moon run cmd/main -- moonrobo noetix control json",
    "Moonphys joint servo replay checks the Noetix gait phases against URDF limits and actuator power/work accounting",
    "\{report.frame_count} frames; \{report.joint_count_per_frame} joints per frame; saturated frames \{report.saturated_frame_count}; limit-review frames \{report.limit_review_frame_count}; heightfield body targets \{report.hinge_motor_world_trace.body_target_count}; heightfield support targets \{report.hinge_motor_world_trace.support_target_count}; center-of-mass target frames \{report.hinge_motor_world_trace.center_of_mass_target_frame_count}; heightfield motor contacts \{report.hinge_motor_world_trace.contact_count}; support-review frames \{report.hinge_motor_world_trace.support_review_frame_count}; capture-review frames \{report.hinge_motor_world_trace.capture_support_review_frame_count}; max support recovery shift \{report.hinge_motor_world_trace.max_support_recovery_shift_m} m; worst capture support margin \{report.hinge_motor_world_trace.worst_capture_support_margin_m} m; max capture recovery shift \{report.hinge_motor_world_trace.max_capture_recovery_shift_m} m; world replay blockers \{report.hinge_motor_world_trace.world_review_blocker_count}; resolved world hinges \{report.hinge_motor_world_trace.resolved_hinge_constraint_count}; body samples \{report.hinge_motor_world_trace.body_sample_count}; max world speed \{report.hinge_motor_world_trace.max_speed_mps} m/s; max world energy \{report.hinge_motor_world_trace.max_kinetic_energy_j} J; envelope \{report.hinge_motor_world_trace.envelope_status}; world review \{report.hinge_motor_world_trace.world_review_status}; max power \{report.max_abs_mechanical_power_w} W; absolute work \{report.total_absolute_work_j} J; status \{report.status}",
    ready,
    if ready {
      "none"
    } else {
      "joint-control replay must clear limit, saturation, support, capture, and Moonphys world replay blockers"
    },
    "python3 scripts/check_moonrobo_noetix_control.py output/moonrobo/first_trusted_square_noetix_control.json",
  )
}

///|
fn noetix_inertial_collision_artifact(
  report : @moonrobo.NoetixInertialCollisionReport,
) -> MoonClawTaskArtifact {
  let ready = report.frame_count > 0 &&
    report.shapes_per_frame > 0 &&
    report.terrain_review_frame_count == 0 &&
    report.self_contact_frame_count == 0 &&
    report.max_self_penetration_m == 0.0 &&
    report.max_self_contact_correction_m == 0.0 &&
    report.max_self_contact_world_correction_m == 0.0 &&
    report.max_support_contact_torque_nm > 0.0 &&
    report.status == "inertial-collision-assumption-review"
  task_artifact(
    "noetix-inertial-collision-review",
    "output/moonrobo/first_trusted_square_noetix_inertial_collision.json",
    "moon run cmd/main -- moonrobo noetix collision json",
    "Moonphys composite primitive-shape mass properties, collision bounds, terrain collisions, contact torque, support-wrench motion preview, and filtered self-collision manifolds are present for review",
    "\{report.frame_count} frames; \{report.shapes_per_frame} shapes per frame; self-contact review frames \{report.self_contact_frame_count}; terrain-review frames \{report.terrain_review_frame_count}; max self penetration \{report.max_self_penetration_m} m; max world correction \{report.max_self_contact_world_correction_m} m; status \{report.status}",
    ready,
    if ready {
      "none"
    } else {
      "inertial/collision review must clear terrain and filtered self-collision review frames while preserving support-wrench evidence"
    },
    "python3 scripts/check_moonrobo_noetix_inertial_collision.py output/moonrobo/first_trusted_square_noetix_inertial_collision.json",
  )
}

///|
fn noetix_rabbita_artifact() -> MoonClawTaskArtifact {
  task_artifact(
    "noetix-rabbita-playback", "output/ui/rabbita/first_trusted_square.html", "scripts/build_rabbita_ui.sh",
    "Rabbita renders Noetix walk, link-pose skeleton, frame controls, and simulation-only authority",
    "Noetix panel consumes walk and link-pose JSON with skeleton playback", true,
    "none", "python3 scripts/check_rabbita_noetix_walk.py",
  )
}

///|
pub fn noetix_review_task_blocked_artifact_count(
  task : MoonClawNoetixReviewTask,
) -> Int {
  let mut count = 0
  for artifact in task.artifacts {
    if !artifact.ready {
      count += 1
    }
  }
  count
}

///|
pub fn first_trusted_square_noetix_review_task() -> MoonClawNoetixReviewTask {
  let source_model = @moonrobo.first_trusted_square_noetix_source_model_report()
  let endless = @moonrobo.first_trusted_square_noetix_endless_gait_evidence()
  let walk = @moonrobo.first_trusted_square_noetix_walk_trace()
  let command = @moonrobo.first_trusted_square_noetix_walk_command_plan()
  let support = @moonrobo.first_trusted_square_noetix_stability_report()
  let dynamic = @moonrobo.first_trusted_square_noetix_dynamic_stability_report()
  let control = @moonrobo.first_trusted_square_noetix_joint_control_report()
  let collision = @moonrobo.first_trusted_square_noetix_inertial_collision_report()
  let poses = @moonrobo.first_trusted_square_noetix_link_pose_trace()
  let physical_readiness = support.profile.physical_model_readiness
  {
    task_id: "moonclaw/first-trusted-square/noetix-review-task",
    site_id: "first-trusted-square",
    robot_id: walk.robot.robot_id,
    priority: High,
    state: Accepted,
    objective: "Review the Noetix endless moon-walk simulation evidence as one MoonClaw work packet before any stronger dynamics or hardware-authority claim.",
    source_model_report_id: source_model.report_id,
    source_endless_gait_evidence_id: endless.evidence_id,
    source_walk_trace_id: walk.trace_id,
    source_walk_command_plan_id: command.plan_id,
    source_static_support_report_id: support.report_id,
    source_dynamic_stability_report_id: dynamic.report_id,
    source_joint_control_report_id: control.report_id,
    source_inertial_collision_report_id: collision.report_id,
    source_link_pose_trace_id: poses.trace_id,
    frame_count: walk.frame_count,
    endless_gait_cycle_frames: endless.cycle_frames,
    source_model_collision_tag_count: source_model.collision_tag_count,
    source_model_inertial_tag_count: source_model.inertial_tag_count,
    source_model_missing_collision_link_count: source_model.missing_collision_link_count,
    source_model_missing_inertial_link_count: source_model.missing_inertial_link_count,
    source_model_metadata_blocker_count: source_model.source_metadata_blocker_count,
    source_model_metadata_blocker_ids: source_model.source_metadata_blocker_ids,
    source_model_metadata_inventory: source_model.source_metadata_inventory,
    source_model_metadata_gaps: source_model.source_metadata_gaps,
    physical_model_readiness: physical_readiness,
    physical_model_blocker_count: physical_readiness.blocker_count,
    physical_model_blocker_ids: physical_readiness.blocker_ids,
    static_support_stable_frame_count: support.stable_frame_count,
    static_support_review_frame_count: support.review_frame_count,
    dynamic_stability_capture_stable_frame_count: dynamic.capture_stable_frame_count,
    dynamic_stability_review_frame_count: dynamic.review_frame_count,
    joint_control_review_frame_count: control.frame_count,
    joint_control_world_support_review_frame_count: control.hinge_motor_world_trace.support_review_frame_count,
    joint_control_world_capture_review_frame_count: control.hinge_motor_world_trace.capture_support_review_frame_count,
    joint_control_max_support_recovery_shift_m: control.hinge_motor_world_trace.max_support_recovery_shift_m,
    joint_control_worst_capture_support_margin_m: control.hinge_motor_world_trace.worst_capture_support_margin_m,
    joint_control_max_capture_recovery_shift_m: control.hinge_motor_world_trace.max_capture_recovery_shift_m,
    joint_control_world_replay_blocker_count: control.hinge_motor_world_trace.world_review_blocker_count,
    joint_control_world_replay_blockers: control.hinge_motor_world_trace.world_review_blockers,
    inertial_collision_review_frame_count: collision.self_contact_frame_count +
    collision.terrain_review_frame_count,
    link_pose_count_per_frame: poses.links_per_frame,
    walk_command_segment_count: command.segment_count,
    hardware_state: @moonrobo.MoonroboExecutionState::HardwareDenied,
    hardware_authority: "moonmoon-safety-gate-only",
    hardware_denied: true,
    inputs: [
      input(
        "noetix-source-model",
        "output/moonrobo/first_trusted_square_noetix_source_model.json",
        @core.ClaimKind::Simulated,
        "Moonrobo source model audit for Noetix URDF/profile metadata and missing collision/inertial tags.",
      ),
      input(
        "noetix-endless-gait",
        "output/moonrobo/first_trusted_square_noetix_endless_gait.json",
        @core.ClaimKind::Simulated,
        "Moonrobo proof that the Noetix finite trace prefix is a window over an endless one-direction gait.",
      ),
      input(
        "noetix-walk-trace",
        "output/moonrobo/first_trusted_square_noetix_walk.json",
        @core.ClaimKind::Simulated,
        "Kinematic endless +x Noetix walk trace over Moonmoon terrain with URDF walk clip phases.",
      ),
      input(
        "noetix-walk-command-plan",
        "output/moonrobo/first_trusted_square_noetix_walk_command.json",
        @core.ClaimKind::Simulated,
        "Moonrobo high-control dry-run command plan for the Noetix walk trace.",
      ),
      input(
        "noetix-link-poses",
        "output/moonrobo/first_trusted_square_noetix_link_poses.json",
        @core.ClaimKind::Simulated,
        "URDF-reference link-pose trace bound to the walk frames and contact probes.",
      ),
      input(
        "noetix-static-support",
        "output/moonrobo/first_trusted_square_noetix_stability.json",
        @core.ClaimKind::Simulated,
        "Static COM/support report that explicitly remains review-only for dynamic walking.",
      ),
      input(
        "noetix-dynamic-stability",
        "output/moonrobo/first_trusted_square_noetix_dynamics.json",
        @core.ClaimKind::Simulated,
        "Capture-point dynamic stability report that remains review-only without controller and inertia evidence.",
      ),
      input(
        "noetix-joint-control",
        "output/moonrobo/first_trusted_square_noetix_control.json",
        @core.ClaimKind::Simulated,
        "Moonphys joint-control replay over Noetix gait phases and URDF joint limits.",
      ),
      input(
        "noetix-inertial-collision",
        "output/moonrobo/first_trusted_square_noetix_inertial_collision.json",
        @core.ClaimKind::Simulated,
        "Moonphys inertial/collision review report over Noetix mass assumptions, shape bounds, terrain collisions, and self-contact manifolds.",
      ),
      input(
        "noetix-rabbita-playback",
        "output/ui/rabbita/first_trusted_square.html",
        @core.ClaimKind::Derived,
        "Rabbita playback for inspecting the walk and link-pose skeleton.",
      ),
    ],
    artifacts: [
      noetix_source_model_artifact(source_model),
      noetix_source_sync_artifact(source_model, command),
      noetix_endless_gait_artifact(endless),
      noetix_walk_artifact(walk),
      noetix_walk_command_artifact(command),
      noetix_link_pose_artifact(poses),
      noetix_static_support_artifact(support),
      noetix_dynamic_stability_artifact(dynamic),
      noetix_joint_control_artifact(control),
      noetix_inertial_collision_artifact(collision),
      noetix_rabbita_artifact(),
    ],
    commands: [
      "python3 scripts/check_moonrobo_noetix_source_model.py output/moonrobo/first_trusted_square_noetix_source_model.json",
      "python3 scripts/check_moonrobo_noetix_source_sync.py output/moonrobo/first_trusted_square_noetix_source_model.json output/moonrobo/first_trusted_square_noetix_walk_command.json",
      "python3 scripts/check_moonrobo_noetix_endless_gait.py output/moonrobo/first_trusted_square_noetix_endless_gait.json",
      "python3 scripts/check_moonrobo_noetix_walk.py output/moonrobo/first_trusted_square_noetix_walk.json",
      "python3 scripts/check_moonrobo_noetix_walk_command.py output/moonrobo/first_trusted_square_noetix_walk_command.json",
      "python3 scripts/check_moonrobo_noetix_link_poses.py output/moonrobo/first_trusted_square_noetix_link_poses.json",
      "python3 scripts/check_moonrobo_noetix_stability.py output/moonrobo/first_trusted_square_noetix_stability.json",
      "python3 scripts/check_moonrobo_noetix_dynamics.py output/moonrobo/first_trusted_square_noetix_dynamics.json",
      "python3 scripts/check_moonrobo_noetix_control.py output/moonrobo/first_trusted_square_noetix_control.json",
      "python3 scripts/check_moonrobo_noetix_inertial_collision.py output/moonrobo/first_trusted_square_noetix_inertial_collision.json",
      "python3 scripts/check_rabbita_noetix_walk.py", "python3 scripts/check_moonclaw_noetix_review_task.py output/moonclaw/first_trusted_square_noetix_review_task.json",
      "/Users/kq/.moon/bin/moon test",
    ],
    acceptance_criteria: [
      criterion(
        "all-noetix-evidence-linked", "Task links source model, walk, link poses, static support, dynamic stability, joint control, inertial/collision, and Rabbita playback evidence with concrete validation commands.",
      ),
      criterion(
        "source-model-gaps-preserved", "Source model audit records zero authoritative collision and inertial tags, keeping physics evidence in review.",
      ),
      criterion(
        "moonrobo-source-sync-preserved", "Noetix source-model and command-plan evidence must stay synchronized with sibling Moonrobo robot.json and URDF facts.",
      ),
      criterion(
        "endless-gait-window-preserved", "Finite Noetix trace exports remain verified windows over a cyclic one-direction gait.",
      ),
      criterion(
        "static-support-margin-ready", "Static support-stable frames are accepted separately from source/physical-model provenance blockers.",
      ),
      criterion(
        "dynamic-stability-margin-reviewed", "Capture-stable frame counts are reviewed separately from source/physical-model provenance blockers and may block downstream review when any frame is unstable.",
      ),
      criterion(
        "joint-control-replay-reviewed", "Joint-control limit, saturation, support, capture, and Moonphys world replay checks are reviewed separately from source/physical-model provenance blockers and may block downstream review when replay blockers remain.",
      ),
      criterion(
        "dry-run-walk-command-preserved", "High-control walk command plan remains dry-run review evidence and never becomes executable hardware authority.",
      ),
      criterion(
        "inertial-collision-review-ready", "Inertial/collision terrain and filtered self-contact replay checks are accepted separately from source/physical-model provenance blockers.",
      ),
      criterion(
        "hardware-denial-preserved", "MoonRobo hardware_state remains HardwareDenied and authority remains moonmoon-safety-gate-only.",
      ),
      criterion(
        "next-physics-step-clear", "Task names authoritative Moonrobo mass, inertia, and collision tags as the next requirement before stronger simulation claims.",
      ),
    ],
    safety_gate: "Do not convert the Noetix source-model audit, endless gait evidence, walk trace, high-control command plan, link poses, static support, dynamic stability, joint-control report, or inertial/collision report into hardware authority. Authoritative Moonrobo mass, inertia, collision tags, and an approved dry-run/hardware handoff must replace assumptions before any claim beyond simulation review.",
    next_action: "Use this task to review source-model, endless-gait, contact, walk-command, link-pose, static-support, dynamic-stability, joint-control, and inertial/collision evidence; then replace assumed mass/collision metadata or keep hardware denied.",
  }
}

///|
pub fn first_trusted_square_noetix_review_tasks() -> Array[
  MoonClawNoetixReviewTask,
] {
  [first_trusted_square_noetix_review_task()]
}

///|
pub fn render_noetix_review_tasks_markdown(
  tasks : Array[MoonClawNoetixReviewTask],
) -> String {
  let mut text = "# MoonClaw Noetix Review Tasks\n\n"
  for task in tasks {
    text += "- \{task.task_id}\n"
    text += "  - priority: \{priority_label(task.priority)}\n"
    text += "  - state: \{receipt_status_label(task.state)}\n"
    text += "  - robot: \{task.robot_id}\n"
    text += "  - frames: \{task.frame_count}\n"
    text += "  - endless gait cycle frames: \{task.endless_gait_cycle_frames}\n"
    text += "  - source collision tags: \{task.source_model_collision_tag_count}\n"
    text += "  - source inertial tags: \{task.source_model_inertial_tag_count}\n"
    text += "  - missing collision links: \{task.source_model_missing_collision_link_count}\n"
    text += "  - missing inertial links: \{task.source_model_missing_inertial_link_count}\n"
    text += "  - source metadata blockers: \{task.source_model_metadata_blocker_count}\n"
    text += "  - source metadata blocker ids:\n"
    for blocker in task.source_model_metadata_blocker_ids {
      text += "    - \{blocker}\n"
    }
    text += "  - source metadata inventory: \{task.source_model_metadata_inventory.status}\n"
    text += "  - source metadata gaps: \{task.source_model_metadata_gaps.length()}\n"
    text += "  - physical model blockers: \{task.physical_model_blocker_count}\n"
    text += "  - physical model blocker ids:\n"
    for blocker in task.physical_model_blocker_ids {
      text += "    - \{blocker}\n"
    }
    text += "  - link poses per frame: \{task.link_pose_count_per_frame}\n"
    text += "  - walk command segments: \{task.walk_command_segment_count}\n"
    text += "  - static-support stable frames: \{task.static_support_stable_frame_count}\n"
    text += "  - static-support review frames: \{task.static_support_review_frame_count}\n"
    text += "  - dynamic-stability capture-stable frames: \{task.dynamic_stability_capture_stable_frame_count}\n"
    text += "  - dynamic-stability review frames: \{task.dynamic_stability_review_frame_count}\n"
    text += "  - joint-control review frames: \{task.joint_control_review_frame_count}\n"
    text += "  - joint-control world-support review frames: \{task.joint_control_world_support_review_frame_count}\n"
    text += "  - joint-control world-capture review frames: \{task.joint_control_world_capture_review_frame_count}\n"
    text += "  - joint-control max support recovery shift: \{task.joint_control_max_support_recovery_shift_m} m\n"
    text += "  - joint-control worst capture support margin: \{task.joint_control_worst_capture_support_margin_m} m\n"
    text += "  - joint-control max capture recovery shift: \{task.joint_control_max_capture_recovery_shift_m} m\n"
    text += "  - joint-control world replay blockers: \{task.joint_control_world_replay_blocker_count}\n"
    text += "  - joint-control world replay blocker ids:\n"
    for blocker in task.joint_control_world_replay_blockers {
      text += "    - \{blocker}\n"
    }
    text += "  - inertial-collision review frames: \{task.inertial_collision_review_frame_count}\n"
    text += "  - hardware state: \{@moonrobo.execution_state_label(task.hardware_state)}\n"
    text += "  - hardware authority: \{task.hardware_authority}\n"
    text += "  - safety gate: \{task.safety_gate}\n"
    text += "  - next action: \{task.next_action}\n"
    text += "  - inputs:\n"
    for input in task.inputs {
      text += "    - \{input.input_id}: \{input.evidence_path} - \{input.summary}\n"
    }
    text += "  - artifacts:\n"
    for artifact in task.artifacts {
      text += "    - \{artifact.artifact_id}: \{artifact.path}\n"
      text += "      - current: \{artifact.current_state}\n"
      text += "      - ready: \{artifact.ready}\n"
      text += "      - blocking: \{artifact.blocking_reason}\n"
      text += "      - gate: \{artifact.validation_gate}\n"
    }
    text += "  - commands:\n"
    for command in task.commands {
      text += "    - \{command}\n"
    }
    text += "  - acceptance:\n"
    for acceptance in task.acceptance_criteria {
      text += "    - \{acceptance.criterion_id}: \{acceptance.description}\n"
    }
  }
  text[:text.length() - 1].to_owned()
}

///|
pub fn first_trusted_square_noetix_review_tasks_markdown() -> String {
  render_noetix_review_tasks_markdown(
    first_trusted_square_noetix_review_tasks(),
  )
}

///|
pub fn render_noetix_review_tasks_json(
  tasks : Array[MoonClawNoetixReviewTask],
) -> Json {
  tasks.to_json()
}

///|
pub fn first_trusted_square_noetix_review_tasks_json() -> Json {
  render_noetix_review_tasks_json(first_trusted_square_noetix_review_tasks())
}
