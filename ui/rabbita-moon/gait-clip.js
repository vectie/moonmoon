export const NOETIX_VISUAL_RIG = {
  robotId: 'noetix-e1-lab-01',
  source: 'moonrobo-urdf-visual-adapter',
  rootLink: 'base_link',
  linkCount: 15,
  estimatedMassKg: 54.0,
  cycleHz: 0.46,
  rootSpeedMps: 0.18,
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

export const FOOT_PHASE_SEQUENCE = ['contact', 'loading', 'stance', 'passing', 'swing', 'release']

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
  if (footPhase < 0.08) return 'contact'
  if (footPhase < 0.18) return 'loading'
  if (footPhase < 0.50) return 'stance'
  if (footPhase < 0.72) return 'passing'
  if (footPhase < 0.92) return 'swing'
  return 'release'
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
  return footPhase < 0.58 || footPhase >= 0.92
}

export function supportMassTransferX(clip) {
  return clip.supportFoot === 'left' ? 0.06 : -0.08
}

function torsoCounterRotation(phase) {
  return -0.16 * Math.sin(phase * Math.PI * 2)
}

function footRollPitch(footPhase) {
  if (footPhase < 0.08) {
    return mix(-0.20, 0.0, smoothstep(footPhase / 0.08))
  }
  if (footPhase >= 0.42 && footPhase < 0.64) {
    return 0.34 * smoothstep((footPhase - 0.42) / 0.22)
  }
  if (footPhase >= 0.64 && footPhase < 0.78) {
    return mix(0.34, 0.10, smoothstep((footPhase - 0.64) / 0.14))
  }
  if (footPhase >= 0.78) {
    return mix(-0.18, 0.0, smoothstep((footPhase - 0.78) / 0.14))
  }
  return 0.0
}

export function walkClipSample(time, options = {}) {
  const phase = cycle01(time * NOETIX_VISUAL_RIG.cycleHz)
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
      rollPitch: footRollPitch(leftPhase),
    },
    right: {
      phase: rightPhase,
      role: footRole(rightPhase),
      locked: footLock(rightPhase),
      lockWeight: footLockWeight(rightPhase),
      supporting: footSupport(rightPhase),
      rollPitch: footRollPitch(rightPhase),
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
    strideM: 0.38,
    bob: Math.cos(phase * Math.PI * 4) * 0.032,
    sway: (leftStance ? 1 : -1) * 0.018 * Math.sin(cycle01(phase * 2) * Math.PI),
    torsoCounterRotation: torsoCounterRotation(phase),
    footChannels,
  }
}

function legAngles(legPhase) {
  const swing = legPhase >= 0.5
  const u = swing ? (legPhase - 0.5) * 2 : legPhase * 2
  const e = smoothstep(u)
  if (swing) {
    const landing = u > 0.45 ? 1 - smoothstep((u - 0.45) / 0.55) : 1
    const lateLanding = smoothstep((u - 0.70) / 0.30)
    const toeOffLift = smoothstep(u / 0.12) * (1 - smoothstep((u - 0.12) / 0.18))
    const swingLift = Math.sin(u * Math.PI)
    const kneeLift = 0.16 * toeOffLift + 0.74 * swingLift * landing
    return {
      hip: mix(0.28, -0.36, e),
      knee: -(0.08 + kneeLift),
      ankle: -0.42 * Math.sin(u * Math.PI) + mix(-0.08, 0.10, e) + 0.04 * lateLanding,
    }
  }
  const stanceProgress = u < 0.48
    ? mix(0, 0.42, smoothstep(u / 0.48))
    : u < 0.74
      ? mix(0.42, 0.56, smoothstep((u - 0.48) / 0.26))
      : mix(0.56, 1, smoothstep((u - 0.74) / 0.26))
  return {
    hip: mix(-0.35, 0.28, stanceProgress),
    knee: -(0.08 + 0.08 * Math.sin(u * Math.PI)),
    ankle: mix(0.12, -0.08, stanceProgress),
  }
}

function armAngles(legPhase) {
  const laggedOppositePhase = cycle01(legPhase + 0.44)
  const a = legAngles(laggedOppositePhase)
  const lagWave = Math.sin(laggedOppositePhase * Math.PI * 2)
  return {
    shoulder: -a.hip * 0.76 + lagWave * 0.035,
    elbow: 0.18 + Math.max(0, -a.hip) * 0.24 + Math.max(0, lagWave) * 0.045,
  }
}

export function jointSamples(clip) {
  const leftLeg = legAngles(clip.leftPhase)
  const rightLeg = legAngles(clip.rightPhase)
  const leftArm = armAngles(clip.leftPhase)
  const rightArm = armAngles(clip.rightPhase)
  return {
    left: { ...leftLeg, ...leftArm },
    right: { ...rightLeg, ...rightArm },
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
