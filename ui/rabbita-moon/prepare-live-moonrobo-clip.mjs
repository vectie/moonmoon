import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const moonroboRoot = fileURLToPath(new URL('../../../moonrobo', import.meta.url))
const targetPath = fileURLToPath(new URL('./.generated/live-moonrobo-noetix-clip.js', import.meta.url))
const moonBin = process.env.MOON_BIN ?? 'moon'

function runMoonroboJson(command) {
  const result = spawnSync(moonBin, ['run', command, '--target', 'native'], {
    cwd: moonroboRoot,
    encoding: 'utf8',
  })
  if (result.error) {
    throw result.error
  }
  if (result.status !== 0) {
    throw new Error([
      `Moonrobo live command failed: ${command}`,
      result.stdout,
      result.stderr,
    ].filter(Boolean).join('\n'))
  }
  return JSON.parse(result.stdout)
}

function requireArray(value, field) {
  if (!Array.isArray(value[field])) {
    throw new Error(`Moonrobo live clip field ${field} must be an array`)
  }
}

function validateContract(contract) {
  if (!contract.ready || contract.status !== 'moonmoon-noetix-locomotion-contract-ready') {
    throw new Error(`Moonrobo live contract is not ready: ${contract.status}`)
  }
  if (!contract.walk_clip || typeof contract.walk_clip !== 'object') {
    throw new Error('Moonrobo live contract did not include walk_clip')
  }
  const clip = contract.walk_clip
  if (!clip.ready || clip.status !== 'moonmoon-noetix-walk-clip-ready') {
    throw new Error(`Moonrobo live walk clip is not ready: ${clip.status}`)
  }
  if (clip.sample_count !== 24) {
    throw new Error(`Moonrobo live walk clip sample_count must be 24, got ${clip.sample_count}`)
  }
  for (const field of [
    'foot_phase_sequence',
    'phase_labels',
    'foot_phase_specs',
    'required_joint_ids',
    'joint_anchors',
    'joint_curve_params',
    'authored_joint_samples',
    'authored_motion_samples',
    'authored_contact_frames',
    'authored_motor_frames',
  ]) {
    requireArray(clip, field)
  }
  for (const field of [
    'authored_joint_samples',
    'authored_motion_samples',
    'authored_contact_frames',
    'authored_motor_frames',
  ]) {
    if (clip[field].length !== clip.sample_count) {
      throw new Error(`Moonrobo live walk clip ${field} length does not match sample_count`)
    }
  }
  return clip
}

function validateEvidence(evidence, clip) {
  if (!evidence.ready || evidence.status !== 'moonmoon-noetix-live-suite-evidence-ready') {
    throw new Error(`Moonrobo live suite evidence is not ready: ${evidence.status}`)
  }
  if (evidence.regeneration_mode !== 'live-moonrobo-typed-adapter') {
    throw new Error(`Moonrobo live suite evidence used unexpected mode: ${evidence.regeneration_mode}`)
  }
  if (evidence.walk_clip_id !== clip.clip_id) {
    throw new Error('Moonrobo live suite evidence clip id does not match live clip')
  }
  if (evidence.sample_count !== clip.sample_count ||
    evidence.authored_joint_sample_count !== clip.authored_joint_samples.length ||
    evidence.authored_motion_sample_count !== clip.authored_motion_samples.length ||
    evidence.authored_contact_frame_count !== clip.authored_contact_frames.length ||
    evidence.authored_motor_frame_count !== clip.authored_motor_frames.length) {
    throw new Error('Moonrobo live suite evidence counts do not match live clip')
  }
  if (evidence.blocker_count !== 0 ||
    evidence.motor_review_count !== 0 ||
    evidence.contact_review_count !== 0 ||
    evidence.active_contact_frame_count !== clip.sample_count ||
    evidence.driven_motor_frame_count !== clip.sample_count) {
    throw new Error('Moonrobo live suite evidence did not clear review gates')
  }
}

function linkIdForMeshPath(path) {
  return path.split('/').pop()?.replace(/\.[^.]+$/, '') ?? 'unknown_link'
}

function visualMeshAssets(contract) {
  const assets = contract.mesh_paths.map(localPath => {
    const absolutePath = fileURLToPath(new URL(`../../../moonrobo/${localPath}`, import.meta.url))
    const format = localPath.split('.').pop()?.toLowerCase() ?? ''
    const exists = existsSync(absolutePath)
    return {
      link_id: linkIdForMeshPath(localPath),
      local_path: localPath,
      moonrobo_path: `../moonrobo/${localPath}`,
      format,
      byte_length: exists ? statSync(absolutePath).size : 0,
      source: `moonrobo:${localPath}`,
      status: exists ? `moonrobo-${format}-mesh-referenced` : 'moonrobo-mesh-missing',
    }
  })
  if (!assets.some(asset => asset.link_id === 'base_link' && asset.format === 'stl')) {
    throw new Error('Moonrobo Noetix contract did not expose base_link STL mesh')
  }
  return assets
}

const contract = runMoonroboJson('cmd/moonmoon_contract')
const evidence = runMoonroboJson('cmd/moonmoon_suite_evidence')
const clip = validateContract(contract)
validateEvidence(evidence, clip)

const runtimeClip = {
  clip_id: clip.clip_id,
  source: `${clip.source}#live-runtime`,
  contract_source: contract.source_refs?.[0]?.local_path ?? 'examples/noetix-e1/robot.json',
  cycle_hz: clip.cycle_hz,
  root_speed_mps: clip.root_speed_mps,
  stride_m: clip.stride_m,
  sample_count: clip.sample_count,
  foot_phase_sequence: clip.foot_phase_sequence,
  phase_labels: clip.phase_labels,
  foot_phase_specs: clip.foot_phase_specs,
  required_joint_ids: clip.required_joint_ids,
  joint_anchors: clip.joint_anchors,
  joint_curve_params: clip.joint_curve_params,
  authored_joint_samples: clip.authored_joint_samples,
  authored_motion_samples: clip.authored_motion_samples,
  authored_contact_frames: clip.authored_contact_frames,
  authored_motor_frames: clip.authored_motor_frames,
  visual_mesh_assets: visualMeshAssets(contract),
  ready: clip.ready,
  status: 'moonrobo-live-runtime-clip-ready',
}

mkdirSync(fileURLToPath(new URL('./.generated', import.meta.url)), { recursive: true })
writeFileSync(
  targetPath,
  `// Generated by ui/rabbita-moon/prepare-live-moonrobo-clip.mjs.
// Do not edit this file by hand.
// Generated from Moonrobo live typed adapter commands.

export const MOONROBO_NOETIX_LIVE_SUITE_EVIDENCE = ${JSON.stringify(evidence, null, 2)}

export const MOONROBO_NOETIX_WALK_CLIP = ${JSON.stringify(runtimeClip, null, 2)}
`,
)

console.log(`wrote ${targetPath}`)
