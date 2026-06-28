import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const scene = readFileSync(new URL('./scene3d.js', import.meta.url), 'utf8')
const gaitClip = readFileSync(new URL('./gait-clip.js', import.meta.url), 'utf8')
const generatedClip = readFileSync(new URL('./generated-moonrobo-noetix-clip.js', import.meta.url), 'utf8')
const plan = readFileSync(new URL('../../docs/ANIMATION_FIRST_LOCOMOTION_PLAN.md', import.meta.url), 'utf8')
const repoRoot = fileURLToPath(new URL('../..', import.meta.url))
const gaitRuntimeSource = `${generatedClip}\n${gaitClip}\n${scene}`

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
  'FOOT_PHASE_SEQUENCE',
  'gaitPhaseLabel',
  'footPhaseChannels',
  'footPhaseCoverageStatus',
  'stanceFootWorldLockStatus',
  'stanceFootWorldDrift',
  'footWorldMotionContinuityStatus',
  'footWorldMotionContinuity',
  'footLockRootCorrection',
  'rootCorrectionContinuityStatus',
  'rootCorrectionContinuity',
  'flatTerrainPreservationStatus',
  'flatTerrainPreservation',
  'swingFootClearanceStatus',
  'swingFootClearance',
  'visualAttachmentStatus',
  'visualLinkAttachments',
  'limbForwardBendStatus',
  'limbForwardBend',
  'ikCorrectionReport',
  'terrainContactStatus',
  'contactPatchStatus',
  'nonFlatTerrainStatus',
  'ikCorrectionStatus',
  'jointIkStatus',
  'supportSoleAlignmentStatus',
  'kneeRoleContrastStatus',
  'armCounterSwingStatus',
  'toeRollStatus',
  'torsoCounterRotationStatus',
  'rollPitch',
  'torsoCounterRotation',
  'MOONROBO_NOETIX_WALK_CLIP',
  'NOETIX_WALK_CLIP',
  'generated-moonrobo-noetix-clip.js',
]

const planContracts = [
  'terrain contact probe',
  'contact patches',
  'terrain-corrected target',
  'FK endpoint',
  'hip/knee/ankle correction',
  'support sole alignment',
  'phase labels: `contact`, `loading`, `stance`, `passing`, `swing`, `release`',
  'foot lock',
  'visible stance foot world delta stays near zero',
  'full foot world motion remains continuous through lift-off, release, and loop wrap',
  'root correction remains continuous through support transfer',
  'flat-terrain preservation',
  'swing foot clearance',
  'visual mesh or primitive attachment per link',
  'toe-off/contact ankle curve',
  'arm lag and counter-swing',
  'torso/waist counter-rotation',
  'forward-bend convention',
]

function requireText(source, token, label) {
  if (!source.includes(token)) {
    throw new Error(`${label} is missing required gait contract: ${token}`)
  }
}

for (const token of sceneContracts) {
  requireText(gaitRuntimeSource, token, 'gait runtime source')
}

for (const token of planContracts) {
  requireText(plan, token, 'ANIMATION_FIRST_LOCOMOTION_PLAN.md')
}

const gaitModule = await import(new URL('./gait-clip.js', import.meta.url).href)
if (!gaitModule.NOETIX_WALK_CLIP?.ready) {
  throw new Error(`generated Moonrobo walk clip was not ready: ${gaitModule.NOETIX_WALK_CLIP?.status}`)
}
if (gaitModule.NOETIX_VISUAL_RIG.source !== gaitModule.NOETIX_WALK_CLIP.source) {
  throw new Error('Rabbita visual rig source does not come from the generated Moonrobo walk clip')
}
if (gaitModule.NOETIX_VISUAL_RIG.cycleHz !== gaitModule.NOETIX_WALK_CLIP.cycle_hz) {
  throw new Error('Rabbita visual rig cycle rate does not come from the generated Moonrobo walk clip')
}
if (gaitModule.NOETIX_VISUAL_RIG.rootSpeedMps !== gaitModule.NOETIX_WALK_CLIP.root_speed_mps) {
  throw new Error('Rabbita visual rig root speed does not come from the generated Moonrobo walk clip')
}
if (JSON.stringify(gaitModule.FOOT_PHASE_SEQUENCE) !== JSON.stringify(gaitModule.NOETIX_WALK_CLIP.foot_phase_sequence)) {
  throw new Error('Rabbita foot phase sequence does not come from the generated Moonrobo walk clip')
}
const clipZero = gaitModule.walkClipSample(0)
if (clipZero.strideM !== gaitModule.NOETIX_WALK_CLIP.stride_m) {
  throw new Error('Rabbita walk sample stride does not come from the generated Moonrobo walk clip')
}
if (clipZero.footChannels.left.role !== gaitModule.NOETIX_WALK_CLIP.foot_phase_specs[0].role) {
  throw new Error('Rabbita foot role did not resolve through the generated Moonrobo foot phase specs')
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
if (moonphysTrace.envelope.max_center_of_mass_speed_mps <= 0) {
  throw new Error('Moonphys review trace did not report COM speed accounting')
}
if (moonphysTrace.envelope.max_linear_momentum_kg_mps <= 0) {
  throw new Error('Moonphys review trace did not report linear momentum accounting')
}
if (moonphysTrace.envelope.max_linear_kinetic_energy_j <= 0) {
  throw new Error('Moonphys review trace did not report linear kinetic energy accounting')
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
if (motionHingeReview.max_motion_linear_momentum_kg_mps <= 0) {
  throw new Error('Moonphys motion hinge review did not carry motion linear momentum evidence')
}
if (motionHingeReview.max_motion_linear_kinetic_energy_j <= 0) {
  throw new Error('Moonphys motion hinge review did not carry motion kinetic energy evidence')
}
let maxSupportJointCorrection = 0
let maxTerrainRange = 0
let maxPatchRange = 0
let maxToeRoll = 0
let maxTorsoCounterRotation = 0
const expectedFootRoles = new Set(['contact', 'loading', 'stance', 'passing', 'swing', 'release'])
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
  if (frame.quality.statuses.supportSoleAlignment !== 'pass') {
    throw new Error(`support sole alignment failed at ${time}s: ${JSON.stringify(frame.quality.supportSoleAlignment)}`)
  }
  if (frame.quality.statuses.toeRoll !== 'pass') {
    throw new Error(`toe roll failed at ${time}s`)
  }
  if (frame.quality.statuses.torsoCounterRotation !== 'pass') {
    throw new Error(`torso counter-rotation failed at ${time}s`)
  }
  if (frame.quality.statuses.footPhaseCoverage !== 'pass') {
    throw new Error(`foot phase coverage failed at ${time}s: ${JSON.stringify(frame.quality.footPhaseCoverage.missing)}`)
  }
  if (frame.quality.statuses.stanceFootWorldLock !== 'pass') {
    throw new Error(`visible stance foot stability failed at ${time}s: ${JSON.stringify(frame.quality.footLockDrift)}`)
  }
  if (frame.quality.statuses.footWorldMotionContinuity !== 'pass') {
    throw new Error(`foot world motion continuity failed at ${time}s: ${JSON.stringify(frame.quality.footWorldMotionContinuity)}`)
  }
  if (frame.quality.statuses.rootCorrectionContinuity !== 'pass') {
    throw new Error(`root correction continuity failed at ${time}s: ${JSON.stringify(frame.quality.rootCorrectionContinuity)}`)
  }
  if (frame.quality.statuses.flatTerrainPreservation !== 'pass') {
    throw new Error(`flat terrain preservation failed at ${time}s: ${JSON.stringify(frame.quality.flatTerrainPreservation)}`)
  }
  if (frame.quality.statuses.swingFootClearance !== 'pass') {
    throw new Error(`swing foot clearance failed at ${time}s: ${JSON.stringify(frame.quality.swingFootClearance)}`)
  }
  if (frame.quality.statuses.visualLinkAttachments !== 'pass') {
    throw new Error(`visual link attachment failed at ${time}s: ${JSON.stringify(frame.quality.visualLinkAttachments)}`)
  }
  if (frame.quality.statuses.limbForwardBend !== 'pass') {
    throw new Error(`limb forward-bend convention failed at ${time}s: ${JSON.stringify(frame.quality.limbForwardBend)}`)
  }
  if (!frame.gaitPhaseLabel.includes(frame.supportFoot) || !frame.gaitPhaseLabel.includes(frame.swingFoot)) {
    throw new Error(`gait phase label did not cite support/swing feet at ${time}s`)
  }
  for (const footName of ['left', 'right']) {
    const foot = frame.footChannels[footName]
    if (!expectedFootRoles.has(foot.role)) {
      throw new Error(`unexpected ${footName} foot role at ${time}s: ${foot.role}`)
    }
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
  maxToeRoll = Math.max(maxToeRoll, frame.quality.toeRoll)
  maxTorsoCounterRotation = Math.max(maxTorsoCounterRotation, frame.quality.torsoCounterRotation)
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

if (maxToeRoll < diagnostics.rig.toeRollMinRad) {
  throw new Error('sampled gait never produced a visible toe-off/contact foot roll')
}

if (maxTorsoCounterRotation < diagnostics.rig.torsoCounterRotationMinRad) {
  throw new Error('sampled gait never produced visible torso counter-rotation')
}

const generatedEvidenceGate = spawnSync(
  process.execPath,
  ['export-rabbita-gait-evidence.mjs', '--check'],
  {
    cwd: fileURLToPath(new URL('.', import.meta.url)),
    encoding: 'utf8',
  },
)

if (generatedEvidenceGate.error) {
  throw generatedEvidenceGate.error
}

if (generatedEvidenceGate.status !== 0) {
  throw new Error(
    [
      'generated Rabbita gait evidence is stale',
      generatedEvidenceGate.stdout,
      generatedEvidenceGate.stderr,
    ].filter(Boolean).join('\n'),
  )
}

const moonroboContractGate = spawnSync(
  process.execPath,
  ['export-moonrobo-contract.mjs', '--check'],
  {
    cwd: fileURLToPath(new URL('.', import.meta.url)),
    encoding: 'utf8',
  },
)

if (moonroboContractGate.error) {
  throw moonroboContractGate.error
}

if (moonroboContractGate.status !== 0) {
  throw new Error(
    [
      'generated Moonrobo Noetix contract bridge is stale',
      moonroboContractGate.stdout,
      moonroboContractGate.stderr,
    ].filter(Boolean).join('\n'),
  )
}

const compiledMoonphysGate = spawnSync(
  process.env.MOON_BIN ?? 'moon',
  ['test', 'src/suite_adapter_preview', '--target', 'js'],
  {
    cwd: repoRoot,
    encoding: 'utf8',
  },
)

if (compiledMoonphysGate.error) {
  throw compiledMoonphysGate.error
}

if (compiledMoonphysGate.status !== 0) {
  throw new Error(
    [
      'compiled Moonphys gate failed',
      compiledMoonphysGate.stdout,
      compiledMoonphysGate.stderr,
    ].filter(Boolean).join('\n'),
  )
}

console.log(
  `Rabbita gait contract check passed: ${sceneContracts.length + planContracts.length} contracts, ${sampleTimes.length} runtime samples, generated evidence gate, Moonrobo contract gate, compiled Moonphys gate`,
)
