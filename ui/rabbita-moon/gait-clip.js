import { MOONROBO_NOETIX_WALK_CLIP } from './generated-moonrobo-noetix-clip.js'

export const NOETIX_VISUAL_RIG = {
  robotId: 'noetix-e1-lab-01',
  source: MOONROBO_NOETIX_WALK_CLIP.source,
  rootLink: 'base_link',
  linkCount: 15,
  estimatedMassKg: 54.0,
  cycleHz: MOONROBO_NOETIX_WALK_CLIP.cycle_hz,
  rootSpeedMps: MOONROBO_NOETIX_WALK_CLIP.root_speed_mps,
  targetFkMaxM: 0.025,
  lockedTargetFkMaxM: 0.010,
  stanceFootWorldStepMaxM: 0.030,
  footWorldStepMaxM: 0.035,
  rootCorrectionStepMaxM: 0.050,
  flatTerrainHeightRangeMaxM: 0.000001,
  flatTerrainContactPatchMaxRangeM: 0.000001,
  flatTerrainSolePitchMaxM: 0.020,
  centerOfMassVelocityScale: 0.12,
  footLockRootCorrectionMaxM: 0.22,
  kneeContrastMin: 0.25,
  armCounterSwingMin: 0.08,
  toeRollMinRad: 0.22,
  torsoCounterRotationMinRad: 0.10,
  swingFootClearanceMinM: 0.0,
  swingFootClearancePhaseMin: 0.54,
  legForwardBendMinM: 0.025,
  armForwardBendMinM: 0.015,
  limbBackFoldToleranceM: -0.004,
  supportTargetClearanceM: 0.006,
  supportSolePitchToleranceM: 0.020,
  jointClearanceToleranceM: 0.0025,
  pelvisCorrectionMaxM: 0.18,
  supportClearanceMaxM: 0.014,
  terrainReliefMaxM: 0.032,
  contactPatchMaxRangeM: 0.014,
  jointCorrectionMaxRad: {
    hip: 0.04,
    knee: 0.14,
    ankle: 0.18,
  },
  lengths: {
    upperLeg: 0.30,
    lowerLeg: 0.31,
    upperArm: 0.25,
    lowerArm: 0.23,
  },
}

export const NOETIX_URDF_LIMIT_SOURCE = {
  robot_profile_path: '../moonrobo/examples/noetix-e1/robot.json',
  urdf_path: '../moonrobo/examples/noetix-e1/model/robot.urdf',
  robot_name: 'noetix_e1_lab_01',
  imported_by: 'moonrobo-urdf-model',
}

export const NOETIX_HINGE_MOTOR_JOINTS = [
  { joint_id: 'leg_l1_joint', side: 'left', field: 'hip', parent_link: 'base_link', child_link: 'left_leg_1', axis: '0 1 0', min: -1.2, max: 1.2, max_velocity: 3.0, max_torque: 90.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'leg_l4_joint', side: 'left', field: 'knee', parent_link: 'left_leg_3', child_link: 'left_leg_4', axis: '0 1 0', min: -1.8, max: 1.8, max_velocity: 3.0, max_torque: 100.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'leg_l6_joint', side: 'left', field: 'ankle', parent_link: 'left_leg_5', child_link: 'left_foot', axis: '0 1 0', min: -0.8, max: 0.8, max_velocity: 3.0, max_torque: 80.0, stiffness: 14.0, damping: 0.6 },
  { joint_id: 'leg_r1_joint', side: 'right', field: 'hip', parent_link: 'base_link', child_link: 'right_leg_1', axis: '0 1 0', min: -1.2, max: 1.2, max_velocity: 3.0, max_torque: 90.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'leg_r4_joint', side: 'right', field: 'knee', parent_link: 'right_leg_3', child_link: 'right_leg_4', axis: '0 1 0', min: -1.8, max: 1.8, max_velocity: 3.0, max_torque: 100.0, stiffness: 18.0, damping: 0.8 },
  { joint_id: 'leg_r6_joint', side: 'right', field: 'ankle', parent_link: 'right_leg_5', child_link: 'right_foot', axis: '0 1 0', min: -0.8, max: 0.8, max_velocity: 3.0, max_torque: 80.0, stiffness: 14.0, damping: 0.6 },
  { joint_id: 'arm_l1_joint', side: 'left', field: 'shoulder', parent_link: 'chest_link', child_link: 'left_arm_1', axis: '0 1 0', min: -1.8, max: 1.8, max_velocity: 3.0, max_torque: 45.0, stiffness: 8.0, damping: 0.4 },
  { joint_id: 'arm_l4_joint', side: 'left', field: 'elbow', parent_link: 'left_arm_3', child_link: 'left_arm_4', axis: '0 1 0', min: -1.6, max: 1.6, max_velocity: 3.0, max_torque: 30.0, stiffness: 8.0, damping: 0.4 },
  { joint_id: 'arm_r1_joint', side: 'right', field: 'shoulder', parent_link: 'chest_link', child_link: 'right_arm_1', axis: '0 1 0', min: -1.8, max: 1.8, max_velocity: 3.0, max_torque: 45.0, stiffness: 8.0, damping: 0.4 },
  { joint_id: 'arm_r4_joint', side: 'right', field: 'elbow', parent_link: 'right_arm_3', child_link: 'right_arm_4', axis: '0 1 0', min: -1.6, max: 1.6, max_velocity: 3.0, max_torque: 30.0, stiffness: 8.0, damping: 0.4 },
]

export const NOETIX_WALK_CLIP = MOONROBO_NOETIX_WALK_CLIP
export const FOOT_PHASE_SEQUENCE = MOONROBO_NOETIX_WALK_CLIP.foot_phase_sequence

export function cycle01(value) {
  return value - Math.floor(value)
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function smoothstep(value) {
  const t = clamp(value, 0, 1)
  return t * t * (3 - 2 * t)
}

function mix(a, b, t) {
  return a + (b - a) * t
}

export function near(a, b, tolerance) {
  return Math.abs(a - b) <= tolerance
}

function footRole(footPhase) {
  return footPhaseSpec(footPhase).role
}

export function footRoleColor(role) {
  if (role === 'contact') return [0.38, 0.92, 0.70]
  if (role === 'loading') return [0.78, 0.86, 0.44]
  if (role === 'stance') return [0.42, 0.68, 0.92]
  if (role === 'passing') return [0.88, 0.62, 0.34]
  if (role === 'swing') return [0.86, 0.50, 0.78]
  return [0.92, 0.78, 0.38]
}

function footLock(footPhase) {
  return footLockWeight(footPhase) > 0.95
}

function footLockWeight(footPhase) {
  if (footPhase < 0.10) return smoothstep(footPhase / 0.10) * 0.12
  if (footPhase < 0.30) return mix(0.12, 1, smoothstep((footPhase - 0.10) / 0.20))
  if (footPhase < 0.34) return 1
  if (footPhase < 0.50) return mix(1, 0, smoothstep((footPhase - 0.34) / 0.16))
  return 0
}

function footSupport(footPhase) {
  return footPhaseSpec(footPhase).support
}

function footPhaseSpec(footPhase) {
  const phase = cycle01(footPhase)
  return MOONROBO_NOETIX_WALK_CLIP.foot_phase_specs.find((spec) => {
    if (spec.phase_end >= 1) {
      return phase >= spec.phase_start && phase <= spec.phase_end
    }
    return phase >= spec.phase_start && phase < spec.phase_end
  }) ?? MOONROBO_NOETIX_WALK_CLIP.foot_phase_specs[0]
}

export function supportMassTransferX(clip) {
  return clip.supportFoot === 'left' ? 0.06 : -0.08
}

export function walkClipSample(time, options = {}) {
  const phase = cycle01(time * NOETIX_VISUAL_RIG.cycleHz)
  const motion = authoredMotionSampleAtPhase(phase)
  const leftStance = phase < 0.5
  const leftPhase = phase
  const rightPhase = cycle01(phase + 0.5)
  const footChannels = {
    left: {
      phase: leftPhase,
      role: footRole(leftPhase),
      locked: footLock(leftPhase),
      lockWeight: footLockWeight(leftPhase),
      supporting: footSupport(leftPhase),
      rollPitch: motion.left_foot_roll_pitch_rad,
    },
    right: {
      phase: rightPhase,
      role: footRole(rightPhase),
      locked: footLock(rightPhase),
      lockWeight: footLockWeight(rightPhase),
      supporting: footSupport(rightPhase),
      rollPitch: motion.right_foot_roll_pitch_rad,
    },
  }
  const supportFoot = leftStance ? 'left' : 'right'
  const swingFoot = leftStance ? 'right' : 'left'
  return {
    phase,
    leftPhase,
    rightPhase,
    phaseLabel: leftStance ? 'left-stance-right-swing' : 'right-stance-left-swing',
    gaitPhaseLabel: `${supportFoot}-${footChannels[supportFoot].role}/${swingFoot}-${footChannels[swingFoot].role}`,
    supportFoot,
    swingFoot,
    rootDistanceM: time * NOETIX_VISUAL_RIG.rootSpeedMps,
    terrainReliefScale: options.terrainReliefScale ?? 1,
    strideM: MOONROBO_NOETIX_WALK_CLIP.stride_m,
    bob: motion.root_bob_m,
    sway: motion.root_sway_m,
    torsoCounterRotation: motion.torso_counter_rotation_rad,
    authoredMotion: motion,
    footChannels,
  }
}

function interp(a, b, t) {
  return a + (b - a) * t
}

function authoredSampleAtPhase(phase) {
  const samples = MOONROBO_NOETIX_WALK_CLIP.authored_joint_samples
  if (!Array.isArray(samples) || samples.length === 0) {
    throw new Error('Moonrobo Noetix walk clip is missing authored joint samples')
  }
  const normalized = cycle01(phase)
  const scaled = normalized * samples.length
  const baseIndex = Math.floor(scaled)
  const nextIndex = (baseIndex + 1) % samples.length
  const t = scaled - baseIndex
  const a = samples[baseIndex % samples.length]
  const b = samples[nextIndex]
  return {
    phase: normalized,
    left_hip_rad: interp(a.left_hip_rad, b.left_hip_rad, t),
    left_knee_rad: interp(a.left_knee_rad, b.left_knee_rad, t),
    left_ankle_rad: interp(a.left_ankle_rad, b.left_ankle_rad, t),
    left_shoulder_rad: interp(a.left_shoulder_rad, b.left_shoulder_rad, t),
    left_elbow_rad: interp(a.left_elbow_rad, b.left_elbow_rad, t),
    right_hip_rad: interp(a.right_hip_rad, b.right_hip_rad, t),
    right_knee_rad: interp(a.right_knee_rad, b.right_knee_rad, t),
    right_ankle_rad: interp(a.right_ankle_rad, b.right_ankle_rad, t),
    right_shoulder_rad: interp(a.right_shoulder_rad, b.right_shoulder_rad, t),
    right_elbow_rad: interp(a.right_elbow_rad, b.right_elbow_rad, t),
  }
}

function authoredMotionSampleAtPhase(phase) {
  const samples = MOONROBO_NOETIX_WALK_CLIP.authored_motion_samples
  if (!Array.isArray(samples) || samples.length === 0) {
    throw new Error('Moonrobo Noetix walk clip is missing authored motion samples')
  }
  const normalized = cycle01(phase)
  const scaled = normalized * samples.length
  const baseIndex = Math.floor(scaled)
  const nextIndex = (baseIndex + 1) % samples.length
  const t = scaled - baseIndex
  const a = samples[baseIndex % samples.length]
  const b = samples[nextIndex]
  return {
    phase: normalized,
    root_cycle_forward_m: normalized * MOONROBO_NOETIX_WALK_CLIP.stride_m,
    root_sway_m: interp(a.root_sway_m, b.root_sway_m, t),
    root_bob_m: interp(a.root_bob_m, b.root_bob_m, t),
    torso_counter_rotation_rad: interp(a.torso_counter_rotation_rad, b.torso_counter_rotation_rad, t),
    left_foot_x_m: interp(a.left_foot_x_m, b.left_foot_x_m, t),
    left_foot_y_m: interp(a.left_foot_y_m, b.left_foot_y_m, t),
    left_foot_z_m: interp(a.left_foot_z_m, b.left_foot_z_m, t),
    left_foot_roll_pitch_rad: interp(a.left_foot_roll_pitch_rad, b.left_foot_roll_pitch_rad, t),
    right_foot_x_m: interp(a.right_foot_x_m, b.right_foot_x_m, t),
    right_foot_y_m: interp(a.right_foot_y_m, b.right_foot_y_m, t),
    right_foot_z_m: interp(a.right_foot_z_m, b.right_foot_z_m, t),
    right_foot_roll_pitch_rad: interp(a.right_foot_roll_pitch_rad, b.right_foot_roll_pitch_rad, t),
  }
}

export function authoredMotionSample(clip) {
  return clip.authoredMotion ?? authoredMotionSampleAtPhase(clip.phase)
}

function sideJointSample(sample, side) {
  return {
    hip: sample[`${side}_hip_rad`],
    knee: sample[`${side}_knee_rad`],
    ankle: sample[`${side}_ankle_rad`],
    shoulder: sample[`${side}_shoulder_rad`],
    elbow: sample[`${side}_elbow_rad`],
  }
}

export function jointSamples(clip) {
  const sample = authoredSampleAtPhase(clip.phase)
  return {
    left: sideJointSample(sample, 'left'),
    right: sideJointSample(sample, 'right'),
  }
}

export function cloneJointSamples(joints) {
  return {
    left: { ...joints.left },
    right: { ...joints.right },
  }
}

export function emptyJointCorrections() {
  return {
    left: { hip: 0, knee: 0, ankle: 0 },
    right: { hip: 0, knee: 0, ankle: 0 },
  }
}
