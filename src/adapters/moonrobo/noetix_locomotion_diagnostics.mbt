///|
pub(all) struct NoetixLocomotionFootDiagnostic {
  foot_id : String
  link_name : String
  side : String
  gait_phase : String
  locked : Bool
  contact_expected : Bool
  authored_target_position : @moonphys.Vec3
  fk_foot_position : @moonphys.Vec3
  contact_probe_position : @moonphys.Vec3
  fk_to_authored_target_delta_m : Double
  fk_to_contact_probe_delta_m : Double
  authored_target_to_contact_probe_delta_m : Double
  source_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLocomotionDiagnosticFrame {
  frame_index : Int
  time_s : Double
  support_phase : String
  gait_phase : String
  root_motion_forward_m : Double
  root_motion_cycle_stride_m : Double
  root_motion_position : @moonphys.Vec3
  body_position : @moonphys.Vec3
  left_foot : NoetixLocomotionFootDiagnostic
  right_foot : NoetixLocomotionFootDiagnostic
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixLocomotionDiagnosticTrace {
  trace_id : String
  source_walk_trace_id : String
  source_link_pose_trace_id : String
  robot_id : String
  terrain_tile_id : String
  frame_count : Int
  diagnostic_contract_status : String
  frames : Array[NoetixLocomotionDiagnosticFrame]
  status : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn locomotion_distance_m(a : @moonphys.Vec3, b : @moonphys.Vec3) -> Double {
  a.sub(b).length_squared().sqrt()
}

///|
fn locomotion_pose_frame_for(
  trace : NoetixLinkPoseTrace,
  frame_index : Int,
) -> NoetixLinkPoseFrame? {
  for frame in trace.frames {
    if frame.frame_index == frame_index {
      return Some(frame)
    }
  }
  None
}

///|
fn locomotion_link_position(
  pose_frame : NoetixLinkPoseFrame,
  link_name : String,
) -> @moonphys.Vec3 {
  for link in pose_frame.links {
    if link.link_name == link_name {
      return link.world_position
    }
  }
  @moonphys.vec3(0.0, 0.0, 0.0)
}

///|
fn locomotion_contact_position(
  frame : NoetixMoonWalkFrame,
  side : String,
) -> @moonphys.Vec3 {
  if side == "left" {
    frame.left_foot.position
  } else {
    frame.right_foot.position
  }
}

///|
fn locomotion_clip_foot(
  clip : NoetixWalkClipSample,
  side : String,
) -> NoetixWalkClipFootSample {
  if side == "left" {
    clip.left_foot
  } else {
    clip.right_foot
  }
}

///|
fn locomotion_foot_link_name(side : String) -> String {
  if side == "left" {
    "left_foot"
  } else {
    "right_foot"
  }
}

///|
fn locomotion_clearance_m(
  config : NoetixMoonWalkConfig,
  foot : NoetixWalkClipFootSample,
) -> Double {
  if foot.contact_expected {
    0.0
  } else if foot.lift_m < config.min_swing_clearance_m + config.foot_radius_m {
    config.min_swing_clearance_m + config.foot_radius_m
  } else if foot.lift_m < config.min_swing_clearance_m {
    config.min_swing_clearance_m
  } else {
    foot.lift_m
  }
}

///|
fn locomotion_authored_target_position(
  config : NoetixMoonWalkConfig,
  field : @moonphys.Heightfield,
  foot : NoetixWalkClipFootSample,
) -> @moonphys.Vec3 {
  let xy = noetix_walk_xy(config, foot.forward_m, foot.lateral_m)
  let terrain = @moonphys.sample_heightfield(field, xy.x, xy.y)
  @moonphys.vec3(
    xy.x,
    xy.y,
    terrain.elevation_m + locomotion_clearance_m(config, foot),
  )
}

///|
fn locomotion_foot_diagnostic(
  config : NoetixMoonWalkConfig,
  field : @moonphys.Heightfield,
  frame : NoetixMoonWalkFrame,
  pose_frame : NoetixLinkPoseFrame,
  clip : NoetixWalkClipSample,
  side : String,
) -> NoetixLocomotionFootDiagnostic {
  let clip_foot = locomotion_clip_foot(clip, side)
  let link_name = locomotion_foot_link_name(side)
  let fk = locomotion_link_position(pose_frame, link_name)
  let target = locomotion_authored_target_position(config, field, clip_foot)
  let contact = locomotion_contact_position(frame, side)
  {
    foot_id: clip_foot.foot_id,
    link_name,
    side,
    gait_phase: clip_foot.phase_label,
    locked: clip_foot.locked,
    contact_expected: clip_foot.contact_expected,
    authored_target_position: target,
    fk_foot_position: fk,
    contact_probe_position: contact,
    fk_to_authored_target_delta_m: locomotion_distance_m(fk, target),
    fk_to_contact_probe_delta_m: locomotion_distance_m(fk, contact),
    authored_target_to_contact_probe_delta_m: locomotion_distance_m(
      target, contact,
    ),
    source_status: "walk-clip-target-fk-contact-diagnostic",
  }
}

///|
fn noetix_locomotion_diagnostic_frame(
  field : @moonphys.Heightfield,
  config : NoetixMoonWalkConfig,
  frame : NoetixMoonWalkFrame,
  pose_frame : NoetixLinkPoseFrame,
) -> NoetixLocomotionDiagnosticFrame {
  let clip = noetix_walk_clip_sample(config, frame.frame_index)
  let root_xy = noetix_walk_xy(config, frame.root_motion_forward_m, 0.0)
  let left = locomotion_foot_diagnostic(
    config, field, frame, pose_frame, clip, "left",
  )
  let right = locomotion_foot_diagnostic(
    config, field, frame, pose_frame, clip, "right",
  )
  {
    frame_index: frame.frame_index,
    time_s: frame.time_s,
    support_phase: frame.support_phase,
    gait_phase: frame.gait_phase,
    root_motion_forward_m: frame.root_motion_forward_m,
    root_motion_cycle_stride_m: frame.root_motion_cycle_stride_m,
    root_motion_position: @moonphys.vec3(
      root_xy.x,
      root_xy.y,
      frame.body_position.z,
    ),
    body_position: frame.body_position,
    left_foot: left,
    right_foot: right,
    status: if left.source_status == "walk-clip-target-fk-contact-diagnostic" &&
      right.source_status == "walk-clip-target-fk-contact-diagnostic" {
      "locomotion-diagnostics-ready"
    } else {
      "locomotion-diagnostics-review"
    },
  }
}

///|
pub fn noetix_locomotion_diagnostic_trace(
  field : @moonphys.Heightfield,
  walk : NoetixMoonWalkTrace,
  link_poses : NoetixLinkPoseTrace,
) -> NoetixLocomotionDiagnosticTrace {
  let frames : Array[NoetixLocomotionDiagnosticFrame] = []
  for frame in walk.frames {
    match locomotion_pose_frame_for(link_poses, frame.frame_index) {
      Some(pose_frame) =>
        frames.push(
          noetix_locomotion_diagnostic_frame(
            field,
            walk.config,
            frame,
            pose_frame,
          ),
        )
      None => ()
    }
  }
  {
    trace_id: "moonrobo/noetix-e1/locomotion-diagnostics/\{walk.terrain_tile_id}",
    source_walk_trace_id: walk.trace_id,
    source_link_pose_trace_id: link_poses.trace_id,
    robot_id: walk.robot.robot_id,
    terrain_tile_id: walk.terrain_tile_id,
    frame_count: frames.length(),
    diagnostic_contract_status: if frames.length() == walk.frame_count {
      "walk-clip-fk-contact-diagnostics-ready"
    } else {
      "walk-clip-fk-contact-diagnostics-incomplete"
    },
    frames,
    status: "review-only",
    note: "Moonrobo locomotion diagnostics separate the Noetix walk-clip authored target, URDF FK foot endpoint, and Moonphys contact probe for Rabbita inspection. This data explains wrong-looking motion without giving Rabbita pose authority and without putting Noetix gait semantics into Moonphys.",
  }
}

///|
pub fn first_trusted_square_noetix_locomotion_diagnostic_trace() -> NoetixLocomotionDiagnosticTrace {
  let field = first_trusted_square_noetix_heightfield()
  let walk = first_trusted_square_noetix_walk_trace()
  noetix_locomotion_diagnostic_trace(field, walk, noetix_link_pose_trace(walk))
}

///|
pub fn first_trusted_square_noetix_locomotion_diagnostic_json() -> Json {
  first_trusted_square_noetix_locomotion_diagnostic_trace().to_json()
}
