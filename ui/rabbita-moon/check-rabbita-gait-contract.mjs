import { readFileSync } from 'node:fs'

const scene = readFileSync(new URL('./scene3d.js', import.meta.url), 'utf8')
const plan = readFileSync(new URL('../../docs/ANIMATION_FIRST_LOCOMOTION_PLAN.md', import.meta.url), 'utf8')

const sceneContracts = [
  'walkPipeline',
  'gaitQualityStatus',
  'authoredJointSamples',
  'jointSamples',
  'jointCorrectionReport',
  'correctedFootTargets',
  'terrainContactProbes',
  'contactPatches',
  'terrainProfileReport',
  'moonphysReviewFrame',
  'moonphysReviewTrace',
  'moonphysHingeMotorTrace',
  'moonphysMotionHingeReview',
  'NOETIX_URDF_LIMIT_SOURCE',
  'leg_l1_joint',
  'arm_l1_joint',
  'ikCorrectionReport',
  'terrainContactStatus',
  'contactPatchStatus',
  'nonFlatTerrainStatus',
  'ikCorrectionStatus',
  'jointIkStatus',
  'kneeRoleContrastStatus',
  'armCounterSwingStatus',
]

const planContracts = [
  'terrain contact probe',
  'contact patches',
  'terrain-corrected target',
  'FK endpoint',
  'hip/knee/ankle correction',
  'foot lock',
]

function requireText(source, token, label) {
  if (!source.includes(token)) {
    throw new Error(`${label} is missing required gait contract: ${token}`)
  }
}

for (const token of sceneContracts) {
  requireText(scene, token, 'scene3d.js')
}

for (const token of planContracts) {
  requireText(plan, token, 'ANIMATION_FIRST_LOCOMOTION_PLAN.md')
}

await import(new URL('./scene3d.js', import.meta.url).href)

const diagnostics = globalThis.__moonmoonGaitDiagnostics
if (!diagnostics?.sampleRobotGeometry) {
  throw new Error('scene3d.js did not expose the gait diagnostic sampler')
}

if (!diagnostics?.moonphysReviewFrameEvidence) {
  throw new Error('scene3d.js did not expose the Moonphys review evidence bridge')
}

if (!diagnostics?.moonphysReviewTraceEvidence) {
  throw new Error('scene3d.js did not expose the Moonphys review trace evidence bridge')
}

if (!diagnostics?.moonphysHingeMotorReplayEvidence) {
  throw new Error('scene3d.js did not expose the Moonphys hinge motor replay evidence bridge')
}

if (!diagnostics?.moonphysMotionHingeReviewEvidence) {
  throw new Error('scene3d.js did not expose the Moonphys motion hinge review evidence bridge')
}

const cycleSeconds = 1 / diagnostics.rig.cycleHz
const sampleTimes = Array.from({ length: 24 }, (_, i) => i * cycleSeconds / 24)
const moonphysTrace = diagnostics.moonphysReviewTraceEvidence(sampleTimes.length)
const hingeTrace = diagnostics.moonphysHingeMotorReplayEvidence(sampleTimes.length)
const motionHingeReview = diagnostics.moonphysMotionHingeReviewEvidence(sampleTimes.length)
if (moonphysTrace.environment_id !== 'moon/lunar-surface') {
  throw new Error('Moonphys review trace used an unexpected environment')
}
if (moonphysTrace.frame_count !== sampleTimes.length) {
  throw new Error('Moonphys review trace frame count did not match runtime sampling')
}
if (moonphysTrace.frames.length !== sampleTimes.length) {
  throw new Error('Moonphys review trace frame list did not match runtime sampling')
}
if (moonphysTrace.frames.some(frame => frame.review.contact_count !== diagnostics.sampleRobotGeometry(frame.time_s).diagnostics.feet.length)) {
  throw new Error('Moonphys review trace contains a frame with mismatched contact count')
}
if (moonphysTrace.envelope.max_total_normal_force_n <= 0) {
  throw new Error('Moonphys review trace did not report a positive normal-force envelope')
}
if (moonphysTrace.envelope.max_contact_torque_nm <= 0) {
  throw new Error('Moonphys review trace did not report a contact torque envelope')
}
if (moonphysTrace.envelope.max_pressure_pa <= 0) {
  throw new Error('Moonphys review trace did not report a pressure envelope')
}
if (moonphysTrace.envelope.max_friction_utilization <= 0 || moonphysTrace.envelope.max_friction_utilization >= 1) {
  throw new Error('Moonphys review trace friction utilization envelope is outside the expected walking range')
}
if (hingeTrace.environment_id !== 'moon/lunar-surface') {
  throw new Error('Moonphys hinge motor trace used an unexpected environment')
}
if (hingeTrace.sample_source !== 'corrected-fk-joint-samples') {
  throw new Error('Moonphys hinge motor trace did not use corrected FK joint samples')
}
if (hingeTrace.limit_source?.urdf_path !== '../moonrobo/examples/noetix-e1/model/robot.urdf') {
  throw new Error('Moonphys hinge motor trace did not cite the Moonrobo Noetix URDF limit source')
}
if (hingeTrace.limit_source?.robot_profile_path !== '../moonrobo/examples/noetix-e1/robot.json') {
  throw new Error('Moonphys hinge motor trace did not cite the Moonrobo Noetix robot profile')
}
if (hingeTrace.frame_count !== sampleTimes.length || hingeTrace.motor_frame_count !== sampleTimes.length) {
  throw new Error('Moonphys hinge motor trace frame count did not match runtime sampling')
}
if (hingeTrace.frames.length !== sampleTimes.length) {
  throw new Error('Moonphys hinge motor trace frame list did not match runtime sampling')
}
const hingeJointIds = new Set(hingeTrace.frames.flatMap(frame => frame.steps.map(step => step.joint_id)))
for (const jointId of ['leg_l1_joint', 'leg_l4_joint', 'leg_l6_joint', 'leg_r1_joint', 'leg_r4_joint', 'leg_r6_joint', 'arm_l1_joint', 'arm_l4_joint', 'arm_r1_joint', 'arm_r4_joint']) {
  if (!hingeJointIds.has(jointId)) {
    throw new Error(`Moonphys hinge motor trace did not include URDF joint ${jointId}`)
  }
}
if (hingeTrace.joint_count < 10) {
  throw new Error('Moonphys hinge motor trace did not include the expected biped joints')
}
if (hingeTrace.driven_joint_count <= hingeTrace.frame_count) {
  throw new Error('Moonphys hinge motor trace did not drive enough joints across the sampled walk')
}
if (hingeTrace.review_count !== 0 || hingeTrace.status !== 'world-heightfield-hinge-motor-trace-driven') {
  throw new Error(`Moonphys hinge motor trace reported review status: ${hingeTrace.status}`)
}
if (hingeTrace.max_abs_angle_delta_rad <= 0 || hingeTrace.max_abs_velocity_delta_rad_s <= 0) {
  throw new Error('Moonphys hinge motor trace did not report joint motion envelopes')
}
if (hingeTrace.max_abs_commanded_torque_nm <= 0 || hingeTrace.total_absolute_work_j <= 0) {
  throw new Error('Moonphys hinge motor trace did not report motor torque/work envelopes')
}
if (hingeTrace.frames.some(frame => frame.steps.some(step => step.status !== 'joint-commanded'))) {
  throw new Error('Moonphys hinge motor trace contains a joint command review')
}
if (hingeTrace.frames.some(frame => frame.steps.some(step => Math.abs(step.target_velocity_rad_s) > step.limit.max_velocity_rad_s + 0.000001))) {
  throw new Error('Moonphys hinge motor trace exceeded a URDF joint velocity limit')
}
if (hingeTrace.frames.some(frame => frame.steps.some(step => Math.abs(step.commanded_torque_nm) > step.limit.max_torque_nm + 0.000001))) {
  throw new Error('Moonphys hinge motor trace exceeded a URDF joint effort limit')
}
if (motionHingeReview.status !== 'motion-hinge-replay-review-ready' || !motionHingeReview.ready) {
  throw new Error(`Moonphys motion hinge review was not ready: ${motionHingeReview.status}`)
}
if (motionHingeReview.motion_frame_count !== moonphysTrace.frame_count || motionHingeReview.hinge_frame_count !== hingeTrace.frame_count) {
  throw new Error('Moonphys motion hinge review did not align frame counts')
}
if (motionHingeReview.driven_joint_count !== hingeTrace.driven_joint_count) {
  throw new Error('Moonphys motion hinge review did not carry hinge driven joint evidence')
}
let maxSupportJointCorrection = 0
let maxTerrainRange = 0
let maxPatchRange = 0
for (const time of sampleTimes) {
  const frame = diagnostics.sampleRobotGeometry(time).diagnostics
  const moonphysFrame = diagnostics.moonphysReviewFrameEvidence(frame)
  const supportCorrections = frame.ik.jointCorrections[frame.supportFoot]
  const correctionMagnitude =
    Math.abs(supportCorrections.hip) +
    Math.abs(supportCorrections.knee) +
    Math.abs(supportCorrections.ankle)
  maxSupportJointCorrection = Math.max(maxSupportJointCorrection, correctionMagnitude)
  if (frame.quality.status !== 'pass') {
    throw new Error(`gait quality failed at ${time}s: ${JSON.stringify(frame.quality.statuses)}`)
  }
  if (frame.quality.statuses.terrainContact !== 'pass') {
    throw new Error(`terrain contact failed at ${time}s`)
  }
  if (frame.quality.statuses.contactPatch !== 'pass') {
    throw new Error(`contact patch failed at ${time}s`)
  }
  if (frame.quality.statuses.nonFlatTerrain !== 'pass') {
    throw new Error(`non-flat terrain evidence failed at ${time}s`)
  }
  if (frame.quality.statuses.jointIkCorrection !== 'pass') {
    throw new Error(`joint IK correction failed at ${time}s`)
  }
  if (moonphysFrame.environment.environment_id !== 'moon/lunar-surface') {
    throw new Error(`Moonphys review frame used unexpected environment at ${time}s`)
  }
  if (moonphysFrame.contact_count !== frame.feet.length) {
    throw new Error(`Moonphys review frame contact count mismatch at ${time}s`)
  }
  if (moonphysFrame.active_footprint_count <= 0) {
    throw new Error(`Moonphys review frame has no active support footprint at ${time}s`)
  }
  if (moonphysFrame.contacts.some(contact => contact.patch.sample_count < 4)) {
    throw new Error(`Moonphys review frame has an undersampled contact patch at ${time}s`)
  }
  if (!moonphysFrame.contacts.some(contact => contact.footprint.active && contact.applied_force_n.z > 0)) {
    throw new Error(`Moonphys review frame has no loaded active contact at ${time}s`)
  }
  maxTerrainRange = Math.max(maxTerrainRange, frame.terrain.heightRangeM)
  maxPatchRange = Math.max(maxPatchRange, frame.quality.maxContactPatchRange)
  if (frame.quality.supportClearanceError > diagnostics.rig.supportClearanceMaxM) {
    throw new Error(`support clearance error exceeded bound at ${time}s`)
  }
  if (Math.abs(frame.ik.pelvisCorrectionM) > diagnostics.rig.pelvisCorrectionMaxM) {
    throw new Error(`pelvis correction exceeded bound at ${time}s`)
  }
}

if (maxSupportJointCorrection <= 0.001) {
  throw new Error('sampled gait never applied a meaningful support-leg joint correction')
}

if (maxTerrainRange <= 0.010) {
  throw new Error('sampled terrain never produced meaningful non-flat height variation')
}

if (maxPatchRange <= 0) {
  throw new Error('sampled contact patches did not report terrain height range')
}

console.log(
  `Rabbita gait contract check passed: ${sceneContracts.length + planContracts.length} contracts, ${sampleTimes.length} runtime samples`,
)
