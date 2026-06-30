import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const scene = readFileSync(new URL('./scene3d.js', import.meta.url), 'utf8')
const gaitClip = readFileSync(new URL('./gait-clip.js', import.meta.url), 'utf8')
const generatedClip = readFileSync(new URL('./generated-moonrobo-noetix-clip.js', import.meta.url), 'utf8')
const liveRuntimeClip = readFileSync(new URL('./.generated/live-moonrobo-noetix-runtime.js', import.meta.url), 'utf8')
const liveSuiteEvidence = readFileSync(new URL('./.generated/live-moonrobo-suite-evidence.js', import.meta.url), 'utf8')
const e1AssemblyBridge = readFileSync(new URL('./.generated/e1-asm-assembly.js', import.meta.url), 'utf8')
const plan = readFileSync(new URL('../../docs/ANIMATION_FIRST_LOCOMOTION_PLAN.md', import.meta.url), 'utf8')
const repoRoot = fileURLToPath(new URL('../..', import.meta.url))
const gaitRuntimeSource = `${liveRuntimeClip}\n${e1AssemblyBridge}\n${gaitClip}\n${scene}`
const gaitEvidenceSource = liveSuiteEvidence
const generatedSnapshotSource = generatedClip
const runHeavyIntegration = process.argv.includes('--heavy') || process.env.RABBITA_GAIT_HEAVY === '1'

const sceneContracts = [
  'walkPipeline',
  'gaitQualityStatus',
  'authoredJointSamples',
  'authoredMotion',
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
  'e1AssemblyVisualAttachmentStatus',
  'e1AssemblyVisualAttachments',
  'E1_ASM_DUPLICATE_OFFSET_X',
  'E1_ASM_ASSEMBLY',
  'e1-asm-assembly.js',
  'e1-asm-25-stl-assembly-ready',
  'three-stl-scene-graph',
  'robot-rig-three-rendered',
  'moonmoon-third-person-3d',
  'mission-moon-dock',
  'moon-terrain-switch',
  'robot-drawer',
  'mission-drawer',
  'moon-console-page',
  'moon-console-switch',
  'mission-console-page',
  'mission-page-next',
  'mission-page-back',
  'mission-shortcuts',
  'mission-chat-panel',
  'mission-chat-log',
  'mission-chat-input',
  'mission-chat-send',
  'Moonmoon chat prompt',
  'chat + systems',
  'canvasRenderActive',
  'renderPaused',
  'pausedFrames',
  'renderResumedCount',
  'third-person-moon-walk-rendered',
  'three-third-person-moon-terrain',
  'endless-e1-on-lunar-heightfield',
  'first_trusted_square_lola_5m_129.json',
  'LOLA_TERRAIN_HEIGHT_SCALE',
  'LOLA_TERRAIN_TEXTURE_SOURCE',
  'lola-dem-moonsand-regolith-texture',
  'LOLA_TERRAIN_TEXTURE_SIZE',
  'LOLA_TERRAIN_COLOR_REPEAT',
  'LOLA_TERRAIN_BUMP_REPEAT',
  'LOLA_REGOLITH_MATERIAL_MODEL',
  'lola-hillshade-moonsand-microcrater-pebbles-v1',
  'createLolaRegolithTexture',
  'createLolaRegolithBumpTexture',
  'bumpMap',
  'bumpScale',
  'regolithMaterialModel',
  'terrainTextureResolutionPx',
  'terrainColorTextureRepeat',
  'terrainBumpTextureRepeat',
  'LOLA_TERRAIN_MOTION_MODEL',
  'world-progress-lola-dem',
  'LOLA_DISTANT_RIDGE_MODEL',
  'lola-dem-distant-ridges',
  'CanvasTexture',
  'terrainMotionModel',
  'lolaWorldProgressM',
  'distantRidgeModel',
  'distantRidgeStatus',
  'terrainSourceProduct',
  'terrainSourceResolutionM',
  'terrainTextureSource',
  'earthrise-backdrop',
  'panelBackdrop',
  'EARTHRISE_TEXTURE_SOURCE',
  'earth-atmos-2048-real-texture',
  'earthriseTextureSource',
  'EARTHRISE_LIGHTING_MODEL',
  'utc-subsolar-terminator-v1',
  'EARTHRISE_NIGHT_FILL',
  'EARTHRISE_DAY_BOOST',
  'earthUtcLightingState',
  'createEarthMaterial',
  'updateEarthriseLighting',
  'earthriseLightingModel',
  'earthriseUtcLightingIso',
  'earthriseSubsolarLongitudeDeg',
  'earthriseSubsolarLatitudeDeg',
  'LUNAR_SURFACE_VISUAL_MODEL',
  'curved-lunar-cap',
  'lunarSurfaceVisualModel',
  'OrbitControls',
  'full-stl-source-indexed',
  'realtime-sampled-stl',
  'outer-shell-preserving-cluster-v3',
  'e1FullStlStatus',
  'e1RenderDetailMode',
  'e1MeshReductionAlgorithm',
  'E1_GPU_PALETTE_MODE',
  'single-draw-link-matrix-palette',
  'visualMeshAssetStatus',
  'visualMeshAssets',
  'visual_mesh_assets',
  "geometry: 'mesh'",
  'base_link.STL',
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
  'authored_joint_samples',
  'authored_motion_samples',
  'authored_motor_frames',
  'live-moonrobo-noetix-runtime.js',
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

requireText(generatedSnapshotSource, 'export const MOONROBO_NOETIX_WALK_CLIP', 'generated Moonrobo snapshot source')
requireText(gaitEvidenceSource, 'MOONROBO_NOETIX_LIVE_SUITE_EVIDENCE', 'live Moonrobo suite evidence source')

for (const token of planContracts) {
  requireText(plan, token, 'ANIMATION_FIRST_LOCOMOTION_PLAN.md')
}

const gaitModule = await import(new URL('./gait-clip.js', import.meta.url).href)
const e1AssemblyModule = await import(new URL('./.generated/e1-asm-assembly.js', import.meta.url).href)
if (!e1AssemblyModule.E1_ASM_ASSEMBLY?.ready) {
  throw new Error(`E1 assembly bridge was not ready: ${e1AssemblyModule.E1_ASM_ASSEMBLY?.status}`)
}
if (e1AssemblyModule.E1_ASM_ASSEMBLY.mesh_count !== 25 ||
  e1AssemblyModule.E1_ASM_ASSEMBLY.link_count !== 25 ||
  e1AssemblyModule.E1_ASM_ASSEMBLY.joint_count !== 24) {
  throw new Error(`E1 assembly bridge carried wrong counts: ${JSON.stringify({
    mesh_count: e1AssemblyModule.E1_ASM_ASSEMBLY.mesh_count,
    link_count: e1AssemblyModule.E1_ASM_ASSEMBLY.link_count,
    joint_count: e1AssemblyModule.E1_ASM_ASSEMBLY.joint_count,
  })}`)
}
if (!e1AssemblyModule.E1_ASM_ASSEMBLY.visuals.every(visual => visual.format === 'stl' && visual.status === 'e1-asm-stl-ready')) {
  throw new Error('E1 assembly bridge did not expose 25 ready STL visuals')
}
if (e1AssemblyModule.E1_ASM_ASSEMBLY.reduction_algorithm !== 'outer-shell-preserving-cluster-v3') {
  throw new Error(`E1 assembly bridge used wrong reduction algorithm: ${e1AssemblyModule.E1_ASM_ASSEMBLY.reduction_algorithm}`)
}
if (!e1AssemblyModule.E1_ASM_ASSEMBLY.visuals.every(visual =>
  visual.reduction_algorithm === e1AssemblyModule.E1_ASM_ASSEMBLY.reduction_algorithm &&
  visual.reduction_target_triangles === e1AssemblyModule.E1_ASM_ASSEMBLY.target_triangles_per_mesh &&
  visual.triangle_count > 0 &&
  visual.triangle_count <= Math.ceil(e1AssemblyModule.E1_ASM_ASSEMBLY.target_triangles_per_mesh * 1.42) &&
  visual.sampled_triangles.length === visual.triangle_count &&
  Array.isArray(visual.reduction_cluster_bins) &&
  visual.reduction_cluster_bins.length === 3 &&
  Number.isFinite(visual.reduction_outer_preserved_triangles) &&
  visual.reduction_outer_preserved_triangles > 0 &&
  Number.isFinite(visual.reduction_clustered_triangles))) {
  throw new Error('E1 assembly bridge did not expose bounded viewport-reduced STL visuals')
}
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
if (gaitModule.NOETIX_VISUAL_RIG.meshAssetStatus !== 'moonrobo-noetix-mesh-assets-ready') {
  throw new Error(`Rabbita visual rig did not load Moonrobo mesh assets: ${gaitModule.NOETIX_VISUAL_RIG.meshAssetStatus}`)
}
const baseMeshAsset = gaitModule.visualMeshAsset('base_link')
if (!baseMeshAsset?.local_path?.endsWith('base_link.STL') ||
  baseMeshAsset.format !== 'stl' ||
  baseMeshAsset.status !== 'moonrobo-stl-mesh-referenced') {
  throw new Error('Rabbita visual rig did not expose Moonrobo Noetix base_link STL reference')
}
if (gaitModule.NOETIX_VISUAL_RIG.visualMeshAssets.length !== 25) {
  throw new Error(`Rabbita visual rig did not expose all 25 Moonrobo E1 STL mesh references: ${gaitModule.NOETIX_VISUAL_RIG.visualMeshAssets.length}`)
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
const curveParams = new Map(gaitModule.NOETIX_WALK_CLIP.joint_curve_params.map(param => [param.name, param.value]))
for (const paramName of ['knee_swing_lift_rad', 'arm_phase_lag', 'shoulder_hip_scale', 'elbow_base_rad']) {
  if (!curveParams.has(paramName)) {
    throw new Error(`generated Moonrobo walk clip omitted runtime curve parameter: ${paramName}`)
  }
}
if (gaitModule.NOETIX_WALK_CLIP.authored_joint_samples.length !== gaitModule.NOETIX_WALK_CLIP.sample_count) {
  throw new Error('generated Moonrobo authored joint samples do not match sample_count')
}
if (gaitModule.NOETIX_WALK_CLIP.authored_motion_samples.length !== gaitModule.NOETIX_WALK_CLIP.sample_count) {
  throw new Error('generated Moonrobo authored motion samples do not match sample_count')
}
if (gaitModule.NOETIX_WALK_CLIP.authored_motor_frames.length !== gaitModule.NOETIX_WALK_CLIP.sample_count) {
  throw new Error('generated Moonrobo authored motor frames do not match sample_count')
}
const firstAuthoredSample = gaitModule.NOETIX_WALK_CLIP.authored_joint_samples[0]
const firstMotionSample = gaitModule.NOETIX_WALK_CLIP.authored_motion_samples[0]
const firstJoints = gaitModule.jointSamples(gaitModule.walkClipSample(0))
if (Math.abs(firstJoints.left.knee - firstAuthoredSample.left_knee_rad) > 0.000001) {
  throw new Error('Rabbita left knee did not come from the generated Moonrobo authored sample')
}
if (Math.abs(firstJoints.right.shoulder - firstAuthoredSample.right_shoulder_rad) > 0.000001) {
  throw new Error('Rabbita right shoulder did not come from the generated Moonrobo authored sample')
}
const firstClip = gaitModule.walkClipSample(0)
if (Math.abs(firstClip.bob - firstMotionSample.root_bob_m) > 0.000001) {
  throw new Error('Rabbita root bob did not come from the generated Moonrobo motion sample')
}
if (Math.abs(firstClip.footChannels.left.rollPitch - firstMotionSample.left_foot_roll_pitch_rad) > 0.000001) {
  throw new Error('Rabbita left foot roll did not come from the generated Moonrobo motion sample')
}
const swingJoints = gaitModule.jointSamples(gaitModule.walkClipSample(0.25))
if (Math.abs(swingJoints.left.knee) <= curveParams.get('knee_base_rad')) {
  throw new Error('Rabbita joint sampling did not preserve generated Moonrobo knee swing depth')
}
if (Math.abs(swingJoints.left.shoulder) <= 0.001) {
  throw new Error('Rabbita joint sampling did not preserve generated Moonrobo shoulder motion')
}

await import(new URL('./scene3d.js', import.meta.url).href)

const diagnostics = globalThis.__moonmoonGaitDiagnostics
if (!diagnostics?.sampleRobotGeometry) {
  throw new Error('scene3d.js did not expose the gait diagnostic sampler')
}

if (diagnostics.terrainTile?.source?.product_id !== 'LDEM_875S_5M') {
  throw new Error('scene3d.js did not expose the expected LRO LOLA 5 m terrain tile')
}

if (diagnostics.terrainTile?.grid?.cell_size_m !== 5) {
  throw new Error('scene3d.js terrain tile did not preserve the expected 5 m LOLA source resolution')
}

if (diagnostics.terrainTextureSource !== 'lola-dem-moonsand-regolith-texture') {
  throw new Error('scene3d.js terrain texture is not using the active LOLA regolith material')
}

if (diagnostics.regolithMaterialModel !== 'lola-hillshade-moonsand-microcrater-pebbles-v1') {
  throw new Error('scene3d.js did not expose the expected moonsand regolith material model')
}

if (diagnostics.earthriseLightingModel !== 'utc-subsolar-terminator-v1') {
  throw new Error('scene3d.js did not expose the expected time-based Earthrise lighting model')
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
const sampleCount = runHeavyIntegration ? 24 : 8
const sampleTimes = Array.from({ length: sampleCount }, (_, i) => i * cycleSeconds / sampleCount)
if (runHeavyIntegration) {
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
  if (hingeTrace.sample_source !== 'moonrobo-authored-motor-frames') {
    throw new Error('Moonphys hinge motor trace did not use Moonrobo authored motor frames')
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
}
let maxSupportJointCorrection = 0
let maxTerrainRange = 0
let maxPatchRange = 0
let maxToeRoll = 0
let maxTorsoCounterRotation = 0
const expectedFootRoles = new Set(['contact', 'loading', 'stance', 'passing', 'swing', 'release'])
for (const time of sampleTimes) {
  const frame = diagnostics.sampleRobotGeometry(time).diagnostics
  const moonphysFrame = runHeavyIntegration ? diagnostics.moonphysReviewFrameEvidence(frame) : null
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
  const debugBaseVisualLink = frame.quality.visualLinkAttachments.links.find(link => link.linkId === 'base_link')
  if (debugBaseVisualLink?.geometry !== 'box' || !debugBaseVisualLink.source.includes('debug box')) {
    throw new Error(`debug base_link did not remain boxed at ${time}s: ${JSON.stringify(debugBaseVisualLink)}`)
  }
  if (frame.quality.statuses.e1AssemblyVisualAttachments !== 'pass') {
    throw new Error(`E1 assembly visual attachment failed at ${time}s: ${JSON.stringify(frame.quality.e1AssemblyVisualAttachments)}`)
  }
  if (frame.quality.e1AssemblyVisualAttachments.expectedCount !== 25 ||
    frame.quality.e1AssemblyVisualAttachments.attachedCount !== 25) {
    throw new Error(`E1 assembly duplicate did not attach all 25 URDF STL visuals at ${time}s: ${JSON.stringify(frame.quality.e1AssemblyVisualAttachments)}`)
  }
  const e1BaseVisualLink = frame.quality.e1AssemblyVisualAttachments.links.find(link => link.linkId === 'base_link')
  if (e1BaseVisualLink?.geometry !== 'mesh' ||
    !e1BaseVisualLink.meshPath?.endsWith('base_link.STL') ||
    e1BaseVisualLink.attached !== true) {
    throw new Error(`E1 assembly base_link did not attach from STL mesh at ${time}s: ${JSON.stringify(e1BaseVisualLink)}`)
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
  if (moonphysFrame && moonphysFrame.environment.environment_id !== 'moon/lunar-surface') {
    throw new Error(`Moonphys review frame used unexpected environment at ${time}s`)
  }
  if (moonphysFrame && moonphysFrame.contact_count !== frame.feet.length) {
    throw new Error(`Moonphys review frame contact count mismatch at ${time}s`)
  }
  if (moonphysFrame && moonphysFrame.active_footprint_count <= 0) {
    throw new Error(`Moonphys review frame has no active support footprint at ${time}s`)
  }
  if (moonphysFrame && moonphysFrame.contacts.some(contact => contact.patch.sample_count < 4)) {
    throw new Error(`Moonphys review frame has an undersampled contact patch at ${time}s`)
  }
  if (moonphysFrame && !moonphysFrame.contacts.some(contact => contact.footprint.active && contact.applied_force_n.z > 0)) {
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

function runGate(command, args, cwd, label) {
  const gate = spawnSync(command, args, { cwd, encoding: 'utf8' })
  if (gate.error) {
    throw gate.error
  }
  if (gate.status !== 0) {
    throw new Error(
      [
        `${label} failed`,
        gate.stdout,
        gate.stderr,
      ].filter(Boolean).join('\n'),
    )
  }
}

if (!runHeavyIntegration) {
  console.log(
    `Rabbita gait fast contract passed: ${sceneContracts.length + planContracts.length} contracts, ${sampleTimes.length} runtime samples, viewport mesh reduction gate`,
  )
  process.exit(0)
}

const checkDir = fileURLToPath(new URL('.', import.meta.url))
runGate(process.execPath, ['export-rabbita-gait-evidence.mjs', '--check'], checkDir, 'generated Rabbita gait evidence is stale')
runGate(process.execPath, ['export-moonrobo-contract.mjs', '--check'], checkDir, 'generated Moonrobo Noetix contract bridge is stale')
runGate(process.execPath, ['check-live-moonrobo-suite.mjs'], checkDir, 'live Moonrobo suite evidence gate')
runGate(process.execPath, ['check-live-suite-payload.mjs'], checkDir, 'live suite payload command gate')
runGate(process.env.MOON_BIN ?? 'moon', ['test', 'src/suite_adapter_preview', '--target', 'js'], repoRoot, 'compiled Moonphys gate')

console.log(
  `Rabbita gait heavy contract passed: ${sceneContracts.length + planContracts.length} contracts, ${sampleTimes.length} runtime samples, generated evidence gate, Moonrobo contract gate, live Moonrobo suite gate, live suite payload command gate, compiled Moonphys gate`,
)
