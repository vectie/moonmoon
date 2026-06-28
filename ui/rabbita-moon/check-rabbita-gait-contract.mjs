import { readFileSync } from 'node:fs'

const scene = readFileSync(new URL('./scene3d.js', import.meta.url), 'utf8')
const plan = readFileSync(new URL('../../docs/ANIMATION_FIRST_LOCOMOTION_PLAN.md', import.meta.url), 'utf8')

const sceneContracts = [
  'walkPipeline',
  'gaitQualityStatus',
  'jointSamples',
  'correctedFootTargets',
  'terrainContactProbes',
  'ikCorrectionReport',
  'terrainContactStatus',
  'ikCorrectionStatus',
  'kneeRoleContrastStatus',
  'armCounterSwingStatus',
]

const planContracts = [
  'terrain contact probe',
  'terrain-corrected target',
  'FK endpoint',
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

console.log(`Rabbita gait contract check passed: ${sceneContracts.length + planContracts.length} contracts`)
