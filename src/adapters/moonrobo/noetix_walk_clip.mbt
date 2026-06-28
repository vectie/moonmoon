///|
pub(all) enum NoetixWalkClipPhase {
  NoetixClipContact
  NoetixClipLoading
  NoetixClipStance
  NoetixClipPassing
  NoetixClipSwing
  NoetixClipRelease
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixWalkClipFootSample {
  foot_id : String
  side : String
  phase : NoetixWalkClipPhase
  phase_label : String
  locked : Bool
  contact_expected : Bool
  swing_progress : Double
  forward_m : Double
  lateral_m : Double
  lift_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixWalkClipSample {
  clip_id : String
  frame_index : Int
  cycle_frames : Int
  phase_index : Int
  local_phase_index : Int
  gait_progress : Double
  support_side : String
  support_phase : String
  phase : NoetixWalkClipPhase
  phase_label : String
  root_motion_forward_m : Double
  root_motion_cycle_stride_m : Double
  body_lateral_m : Double
  body_bob_m : Double
  left_foot : NoetixWalkClipFootSample
  right_foot : NoetixWalkClipFootSample
  joint_phases : Array[NoetixJointPhase]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn noetix_clip_phase_label(phase : NoetixWalkClipPhase) -> String {
  match phase {
    NoetixClipContact => "contact"
    NoetixClipLoading => "loading"
    NoetixClipStance => "stance"
    NoetixClipPassing => "passing"
    NoetixClipSwing => "swing"
    NoetixClipRelease => "release"
  }
}

///|
fn noetix_clip_half_cycle(cycle_frames : Int) -> Int {
  let frames = if cycle_frames < 2 { 2 } else { cycle_frames }
  frames / 2
}

///|
fn noetix_clip_cycle_stride_m(config : NoetixMoonWalkConfig) -> Double {
  let cycle_frames = if config.cycle_frames < 2 {
    2
  } else {
    config.cycle_frames
  }
  cycle_frames.to_double() * config.dt_s * config.speed_mps
}

///|
fn noetix_clip_half_stride_m(config : NoetixMoonWalkConfig) -> Double {
  noetix_clip_cycle_stride_m(config) * 0.5
}

///|
fn noetix_clip_double_support_frames(
  config : NoetixMoonWalkConfig,
  half_cycle : Int,
) -> Int {
  if config.double_support_frames < 0 {
    0
  } else if config.double_support_frames > half_cycle {
    half_cycle
  } else {
    config.double_support_frames
  }
}

///|
fn noetix_clip_phase_progress(phase : Int, frame_count : Int) -> Double {
  if frame_count <= 1 {
    0.0
  } else {
    phase.to_double() / (frame_count - 1).to_double()
  }
}

///|
fn noetix_clip_smoothstep(progress : Double) -> Double {
  let t = clamp_double(progress, 0.0, 1.0)
  t * t * (3.0 - 2.0 * t)
}

///|
fn noetix_clip_support_transfer_progress(
  local_phase : Int,
  transfer_frames : Int,
) -> Double {
  if transfer_frames <= 1 {
    1.0
  } else if local_phase <= 0 {
    0.0
  } else if local_phase >= transfer_frames - 1 {
    1.0
  } else {
    noetix_clip_smoothstep(
      local_phase.to_double() / (transfer_frames - 1).to_double(),
    )
  }
}

///|
fn noetix_clip_swing_progress(
  local_phase : Int,
  half_cycle : Int,
  transfer_frames : Int,
) -> Double {
  let swing_frames = half_cycle - transfer_frames
  if swing_frames <= 1 {
    noetix_clip_phase_progress(local_phase, half_cycle)
  } else if local_phase < transfer_frames {
    0.0
  } else {
    let swing_phase = local_phase - transfer_frames
    if swing_phase >= swing_frames - 1 {
      1.0
    } else {
      swing_phase.to_double() / (swing_frames - 1).to_double()
    }
  }
}

///|
fn noetix_clip_primary_phase(
  local_phase : Int,
  half_cycle : Int,
  transfer_frames : Int,
  swing_progress : Double,
) -> NoetixWalkClipPhase {
  if local_phase <= 0 {
    NoetixClipContact
  } else if local_phase < transfer_frames {
    NoetixClipLoading
  } else if swing_progress < 0.34 {
    NoetixClipPassing
  } else if local_phase >= half_cycle - 2 || swing_progress > 0.84 {
    NoetixClipRelease
  } else {
    NoetixClipSwing
  }
}

///|
fn noetix_clip_root_motion_forward_m(
  config : NoetixMoonWalkConfig,
  frame_index : Int,
) -> Double {
  let cycle_frames = if config.cycle_frames < 2 {
    2
  } else {
    config.cycle_frames
  }
  frame_index.to_double() /
  cycle_frames.to_double() *
  noetix_clip_cycle_stride_m(config)
}

///|
fn noetix_clip_body_lateral_m(
  config : NoetixMoonWalkConfig,
  left_support : Bool,
  local_phase : Int,
  transfer_frames : Int,
) -> Double {
  let target = if left_support {
    config.support_lateral_shift_m
  } else {
    0.0 - config.support_lateral_shift_m
  }
  let previous = 0.0 - target
  let progress = noetix_clip_support_transfer_progress(
    local_phase, transfer_frames,
  )
  previous + (target - previous) * progress
}

///|
fn noetix_clip_body_bob_m(
  config : NoetixMoonWalkConfig,
  local_phase : Int,
  half_cycle : Int,
) -> Double {
  let progress = noetix_clip_phase_progress(local_phase, half_cycle)
  config.step_height_m * 0.35 * @math.sin(progress * 3.141592653589793)
}

///|
fn noetix_clip_planted_foot_forward_m(
  config : NoetixMoonWalkConfig,
  block : Int,
) -> Double {
  let span = noetix_clip_half_stride_m(config)
  block.to_double() * span - span * 0.25 + config.support_forward_lead_m
}

///|
fn noetix_clip_swing_foot_forward_m(
  config : NoetixMoonWalkConfig,
  block : Int,
  progress : Double,
) -> Double {
  let start = noetix_clip_planted_foot_forward_m(config, block - 1)
  let finish = noetix_clip_planted_foot_forward_m(config, block + 1)
  start + (finish - start) * noetix_clip_smoothstep(progress)
}

///|
fn noetix_clip_swing_lift_m(
  config : NoetixMoonWalkConfig,
  progress : Double,
) -> Double {
  config.step_height_m *
  @math.sin(clamp_double(progress, 0.0, 1.0) * 3.141592653589793)
}

///|
fn noetix_clip_lift_blend(progress : Double) -> Double {
  clamp_double(
    @math.sin(clamp_double(progress, 0.0, 1.0) * 3.141592653589793),
    0.0,
    1.0,
  )
}

///|
fn noetix_clip_toe_pitch(progress : Double, lift_blend : Double) -> Double {
  let p = clamp_double(progress, 0.0, 1.0)
  let toe_clear = if p < 0.5 {
    0.16 * (1.0 - p * 2.0)
  } else {
    -0.10 * ((p - 0.5) * 2.0)
  }
  toe_clear * lift_blend
}

///|
fn noetix_clip_foot_sample(
  foot_id : String,
  side : String,
  phase : NoetixWalkClipPhase,
  locked : Bool,
  contact_expected : Bool,
  swing_progress : Double,
  forward_m : Double,
  lateral_m : Double,
  lift_m : Double,
) -> NoetixWalkClipFootSample {
  {
    foot_id,
    side,
    phase,
    phase_label: noetix_clip_phase_label(phase),
    locked,
    contact_expected,
    swing_progress,
    forward_m,
    lateral_m,
    lift_m,
  }
}

///|
fn noetix_clip_leg_phases(
  side : String,
  prefix : String,
  gait_progress : Double,
  foot_locked : Bool,
  swing_progress : Double,
) -> Array[NoetixJointPhase] {
  let side_sign = if side == "left" { 1.0 } else { 0.0 - 1.0 }
  let leg_cycle = if side == "left" {
    gait_progress
  } else if gait_progress >= 0.5 {
    gait_progress - 0.5
  } else {
    gait_progress + 0.5
  }
  let support_progress = noetix_clip_smoothstep(leg_cycle * 2.0)
  let swing_blend = if foot_locked {
    0.0
  } else {
    noetix_clip_lift_blend(swing_progress)
  }
  let swing_drive = if foot_locked {
    0.0
  } else {
    noetix_clip_smoothstep(swing_progress)
  }
  let support_hip_pitch = -0.20 + 0.34 * support_progress
  let swing_hip_pitch = 0.16 - 0.46 * swing_drive
  let hip_pitch = if foot_locked { support_hip_pitch } else { swing_hip_pitch }
  let support_knee = 0.10 +
    0.06 * @math.sin(support_progress * 3.141592653589793)
  let shaped_knee_flex = clamp_double(
    if foot_locked {
      support_knee
    } else {
      0.18 + swing_blend * 0.78 + swing_drive * 0.08
    },
    0.08,
    1.35,
  )
  let hip_roll = if foot_locked {
    side_sign * 0.04
  } else {
    0.0 - side_sign * 0.10 * swing_blend
  }
  let knee_upper = shaped_knee_flex * 0.58
  let knee_lower = shaped_knee_flex * 0.42
  let ankle_roll = 0.0 - hip_roll * 0.45
  let ankle_pitch = 0.0 -
    (hip_pitch + knee_upper + knee_lower) +
    noetix_clip_toe_pitch(swing_progress, swing_blend)
  [
    bounded_joint_phase(
      "\{prefix}1_joint",
      "hip-pitch",
      side,
      hip_pitch,
      "urdf-walk-clip",
    ),
    bounded_joint_phase(
      "\{prefix}2_joint",
      "hip-roll",
      side,
      hip_roll,
      "urdf-walk-clip",
    ),
    bounded_joint_phase(
      "\{prefix}3_joint",
      "knee-upper",
      side,
      knee_upper,
      "urdf-walk-clip",
    ),
    bounded_joint_phase(
      "\{prefix}4_joint",
      "knee-lower",
      side,
      knee_lower,
      "urdf-walk-clip",
    ),
    bounded_joint_phase(
      "\{prefix}5_joint",
      "ankle-roll",
      side,
      ankle_roll,
      "urdf-walk-clip",
    ),
    bounded_joint_phase(
      "\{prefix}6_joint",
      "ankle-pitch",
      side,
      ankle_pitch,
      "urdf-walk-clip",
    ),
  ]
}

///|
fn noetix_clip_arm_phases(gait_progress : Double) -> Array[NoetixJointPhase] {
  let wave = @math.sin(gait_progress * 2.0 * 3.141592653589793)
  let lag = @math.sin((gait_progress - 0.06) * 2.0 * 3.141592653589793)
  let left = 0.0 - wave
  let right = 0.0 - left
  [
    joint_phase_with_status(
      "arm_l1_joint",
      "shoulder-pitch",
      "left",
      0.24 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l2_joint",
      "shoulder-roll",
      "left",
      0.06 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l3_joint",
      "elbow-yaw",
      "left",
      0.04 * lag,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l4_joint",
      "elbow-pitch",
      "left",
      0.12 * left + 0.03 * lag,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_l5_joint",
      "wrist-roll",
      "left",
      0.03 * left,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r1_joint",
      "shoulder-pitch",
      "right",
      0.24 * right,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r2_joint",
      "shoulder-roll",
      "right",
      0.06 * right,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r3_joint",
      "elbow-yaw",
      "right",
      0.0 - 0.04 * lag,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r4_joint",
      "elbow-pitch",
      "right",
      0.12 * right - 0.03 * lag,
      "planned-counter-swing",
    ),
    joint_phase_with_status(
      "arm_r5_joint",
      "wrist-roll",
      "right",
      0.03 * right,
      "planned-counter-swing",
    ),
  ]
}

///|
fn noetix_clip_joint_phases(
  gait_progress : Double,
  left_locked : Bool,
  right_locked : Bool,
  left_swing_progress : Double,
  right_swing_progress : Double,
) -> Array[NoetixJointPhase] {
  let phases : Array[NoetixJointPhase] = []
  let cycle_angle = gait_progress * 2.0 * 3.141592653589793
  phases.push(
    joint_phase_with_status(
      "waist_1_joint",
      "waist-yaw",
      "center",
      0.065 * @math.sin(cycle_angle),
      "planned-body-sway",
    ),
  )
  phases.push(
    joint_phase_with_status(
      "waist_2_joint",
      "waist-pitch",
      "center",
      -0.035 + 0.025 * @math.cos(cycle_angle * 2.0),
      "planned-body-sway",
    ),
  )
  for
    phase in noetix_clip_leg_phases(
      "left", "leg_l", gait_progress, left_locked, left_swing_progress,
    ) {
    phases.push(phase)
  }
  for
    phase in noetix_clip_leg_phases(
      "right", "leg_r", gait_progress, right_locked, right_swing_progress,
    ) {
    phases.push(phase)
  }
  for phase in noetix_clip_arm_phases(gait_progress) {
    phases.push(phase)
  }
  phases
}

///|
pub fn noetix_walk_clip_sample(
  config : NoetixMoonWalkConfig,
  frame_index : Int,
) -> NoetixWalkClipSample {
  let cycle_frames = if config.cycle_frames < 2 {
    2
  } else {
    config.cycle_frames
  }
  let half_cycle = noetix_clip_half_cycle(cycle_frames)
  let phase = phase_index(frame_index, cycle_frames)
  let left_support = phase < half_cycle
  let local_phase = if left_support { phase } else { phase - half_cycle }
  let transfer_frames = noetix_clip_double_support_frames(config, half_cycle)
  let gait_progress = if cycle_frames <= 1 {
    0.0
  } else {
    phase.to_double() / cycle_frames.to_double()
  }
  let swing_progress = noetix_clip_swing_progress(
    local_phase, half_cycle, transfer_frames,
  )
  let in_double_support = local_phase < transfer_frames
  let block = if half_cycle <= 0 { 0 } else { frame_index / half_cycle }
  let primary_phase = noetix_clip_primary_phase(
    local_phase, half_cycle, transfer_frames, swing_progress,
  )
  let left_locked = left_support
  let right_locked = !left_support
  let left_contact = left_locked || in_double_support
  let right_contact = right_locked || in_double_support
  let left_swing_progress = if left_contact { 0.0 } else { swing_progress }
  let right_swing_progress = if right_contact { 0.0 } else { swing_progress }
  let left_forward = if left_locked {
    noetix_clip_planted_foot_forward_m(config, block)
  } else {
    noetix_clip_swing_foot_forward_m(config, block, swing_progress)
  }
  let right_forward = if right_locked {
    noetix_clip_planted_foot_forward_m(config, block)
  } else {
    noetix_clip_swing_foot_forward_m(config, block, swing_progress)
  }
  let left_lift = if left_contact {
    0.0
  } else {
    noetix_clip_swing_lift_m(config, swing_progress)
  }
  let right_lift = if right_contact {
    0.0
  } else {
    noetix_clip_swing_lift_m(config, swing_progress)
  }
  let support_phase = if in_double_support {
    if left_support {
      "double-support-left-transfer"
    } else {
      "double-support-right-transfer"
    }
  } else if left_support {
    "left-support"
  } else {
    "right-support"
  }
  {
    clip_id: "moonrobo/noetix-e1/walk-cycle/root-motion-v1",
    frame_index,
    cycle_frames,
    phase_index: phase,
    local_phase_index: local_phase,
    gait_progress,
    support_side: if left_support {
      "left"
    } else {
      "right"
    },
    support_phase,
    phase: primary_phase,
    phase_label: noetix_clip_phase_label(primary_phase),
    root_motion_forward_m: noetix_clip_root_motion_forward_m(
      config, frame_index,
    ),
    root_motion_cycle_stride_m: noetix_clip_cycle_stride_m(config),
    body_lateral_m: noetix_clip_body_lateral_m(
      config, left_support, local_phase, transfer_frames,
    ),
    body_bob_m: noetix_clip_body_bob_m(config, local_phase, half_cycle),
    left_foot: noetix_clip_foot_sample(
      "left-foot",
      "left",
      if left_locked {
        NoetixClipStance
      } else {
        primary_phase
      },
      left_locked,
      left_contact,
      left_swing_progress,
      left_forward,
      config.lateral_foot_offset_m,
      left_lift,
    ),
    right_foot: noetix_clip_foot_sample(
      "right-foot",
      "right",
      if right_locked {
        NoetixClipStance
      } else {
        primary_phase
      },
      right_locked,
      right_contact,
      right_swing_progress,
      right_forward,
      0.0 - config.lateral_foot_offset_m,
      right_lift,
    ),
    joint_phases: noetix_clip_joint_phases(
      gait_progress, left_locked, right_locked, left_swing_progress, right_swing_progress,
    ),
  }
}
