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

const cycleSeconds = 1 / diagnostics.rig.cycleHz
const sampleTimes = Array.from({ length: 24 }, (_, i) => i * cycleSeconds / 24)
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
