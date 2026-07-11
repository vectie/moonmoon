import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { MOONROBO_NOETIX_WALK_CLIP as GENERATED_MOONROBO_NOETIX_WALK_CLIP } from './generated-moonrobo-noetix-clip.js'
import {
  MOONROBO_NOETIX_LIVE_SUITE_EVIDENCE,
  MOONROBO_NOETIX_WALK_CLIP as LIVE_MOONROBO_NOETIX_WALK_CLIP,
} from './.generated/live-moonrobo-noetix-clip.js'

const moonroboRoot = fileURLToPath(new URL('../../../moonrobo', import.meta.url))
const moonBin = process.env.MOON_BIN ?? 'moon'

function runLiveEvidence() {
  const result = spawnSync(
    moonBin,
    ['run', 'cmd/moonmoon_suite_evidence', '--target', 'native'],
    {
      cwd: moonroboRoot,
      encoding: 'utf8',
    },
  )
  if (result.error) {
    throw result.error
  }
  if (result.status !== 0) {
    throw new Error([
      'MoonRobo live suite evidence export failed',
      result.stdout,
      result.stderr,
    ].filter(Boolean).join('\n'))
  }
  return JSON.parse(result.stdout)
}

function requireField(value, field, type) {
  if (typeof value[field] !== type) {
    throw new Error(`live MoonRobo suite evidence field ${field} must be ${type}`)
  }
}

function validateLiveEvidence(evidence) {
  for (const field of [
    'evidence_id',
    'regeneration_mode',
    'contract_id',
    'robot_id',
    'walk_clip_id',
    'source',
    'status',
  ]) {
    requireField(evidence, field, 'string')
  }
  for (const field of [
    'sample_count',
    'profile_joint_count',
    'required_motion_joint_count',
    'authored_joint_sample_count',
    'authored_motion_sample_count',
    'authored_contact_frame_count',
    'authored_motor_frame_count',
    'active_contact_frame_count',
    'loaded_contact_count',
    'driven_motor_frame_count',
    'motor_review_count',
    'contact_review_count',
    'blocker_count',
  ]) {
    requireField(evidence, field, 'number')
  }
  requireField(evidence, 'ready', 'boolean')
  if (!Array.isArray(evidence.blockers)) {
    throw new Error('live MoonRobo suite evidence blockers must be an array')
  }
  if (evidence.regeneration_mode !== 'live-moonrobo-typed-adapter') {
    throw new Error(`unexpected live MoonRobo regeneration mode: ${evidence.regeneration_mode}`)
  }
  if (!evidence.ready || evidence.status !== 'moonmoon-noetix-live-suite-evidence-ready') {
    throw new Error(`live MoonRobo suite evidence is not ready: ${evidence.status}`)
  }
  if (evidence.blocker_count !== 0 || evidence.blockers.length !== 0) {
    throw new Error(`live MoonRobo suite evidence reported blockers: ${evidence.blockers.join(', ')}`)
  }
  if (evidence.sample_count !== 24) {
    throw new Error(`live MoonRobo suite evidence sample_count must be 24, got ${evidence.sample_count}`)
  }
  if (evidence.authored_joint_sample_count !== evidence.sample_count ||
    evidence.authored_motion_sample_count !== evidence.sample_count ||
    evidence.authored_contact_frame_count !== evidence.sample_count ||
    evidence.authored_motor_frame_count !== evidence.sample_count) {
    throw new Error('live MoonRobo suite evidence sample tables are not aligned')
  }
  if (evidence.active_contact_frame_count !== evidence.sample_count) {
    throw new Error('live MoonRobo suite evidence did not keep every frame supported')
  }
  if (evidence.loaded_contact_count < evidence.sample_count) {
    throw new Error('live MoonRobo suite evidence did not load enough active contacts')
  }
  if (evidence.driven_motor_frame_count !== evidence.sample_count) {
    throw new Error('live MoonRobo suite evidence did not drive every motor frame')
  }
  if (evidence.motor_review_count !== 0 || evidence.contact_review_count !== 0) {
    throw new Error('live MoonRobo suite evidence reported contact or motor reviews')
  }
}

function validateAgainstRuntimeBridge(evidence) {
  if (MOONROBO_NOETIX_LIVE_SUITE_EVIDENCE.regeneration_mode !== 'live-moonrobo-typed-adapter') {
    throw new Error('runtime MoonRobo bridge did not carry live suite evidence')
  }
  if (evidence.walk_clip_id !== LIVE_MOONROBO_NOETIX_WALK_CLIP.clip_id) {
    throw new Error('runtime MoonRobo clip id does not match live suite evidence')
  }
  if (!LIVE_MOONROBO_NOETIX_WALK_CLIP.source.endsWith('#live-runtime')) {
    throw new Error('runtime MoonRobo clip source does not mark live runtime generation')
  }
  if (evidence.sample_count !== LIVE_MOONROBO_NOETIX_WALK_CLIP.sample_count) {
    throw new Error('runtime MoonRobo sample count does not match live suite evidence')
  }
  if (evidence.required_motion_joint_count !== LIVE_MOONROBO_NOETIX_WALK_CLIP.required_joint_ids.length) {
    throw new Error('runtime MoonRobo required joint count does not match live suite evidence')
  }
  if (evidence.authored_joint_sample_count !== LIVE_MOONROBO_NOETIX_WALK_CLIP.authored_joint_samples.length ||
    evidence.authored_motion_sample_count !== LIVE_MOONROBO_NOETIX_WALK_CLIP.authored_motion_samples.length ||
    evidence.authored_contact_frame_count !== LIVE_MOONROBO_NOETIX_WALK_CLIP.authored_contact_frames.length ||
    evidence.authored_motor_frame_count !== LIVE_MOONROBO_NOETIX_WALK_CLIP.authored_motor_frames.length) {
    throw new Error('runtime MoonRobo authored sample tables do not match live suite evidence')
  }
  validateMeshAssets(LIVE_MOONROBO_NOETIX_WALK_CLIP, 'runtime MoonRobo')
}

function validateAgainstGeneratedBridge(evidence) {
  if (evidence.walk_clip_id !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.clip_id) {
    throw new Error('generated MoonRobo clip id does not match live suite evidence')
  }
  if (evidence.sample_count !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.sample_count) {
    throw new Error('generated MoonRobo sample count does not match live suite evidence')
  }
  if (evidence.required_motion_joint_count !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.required_joint_ids.length) {
    throw new Error('generated MoonRobo required joint count does not match live suite evidence')
  }
  if (evidence.authored_joint_sample_count !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.authored_joint_samples.length ||
    evidence.authored_motion_sample_count !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.authored_motion_samples.length ||
    evidence.authored_contact_frame_count !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.authored_contact_frames.length ||
    evidence.authored_motor_frame_count !== GENERATED_MOONROBO_NOETIX_WALK_CLIP.authored_motor_frames.length) {
    throw new Error('generated MoonRobo authored sample tables do not match live suite evidence')
  }
  validateMeshAssets(GENERATED_MOONROBO_NOETIX_WALK_CLIP, 'generated MoonRobo')
}

function validateMeshAssets(clip, label) {
  if (!Array.isArray(clip.visual_mesh_assets) || clip.visual_mesh_assets.length === 0) {
    throw new Error(`${label} bridge did not carry visual_mesh_assets`)
  }
  const baseMesh = clip.visual_mesh_assets.find(asset => asset.link_id === 'base_link')
  if (!baseMesh) {
    throw new Error(`${label} bridge did not carry base_link mesh asset`)
  }
  if (!baseMesh.local_path.endsWith('examples/noetix-e1/e1_asm_251028/meshes/base_link.STL')) {
    throw new Error(`${label} bridge carried unexpected base_link mesh path: ${baseMesh.local_path}`)
  }
  if (baseMesh.format !== 'stl' ||
    baseMesh.status !== 'moonrobo-stl-mesh-referenced' ||
    baseMesh.byte_length <= 0) {
    throw new Error(`${label} bridge carried an invalid base_link STL mesh reference`)
  }
  if (clip.visual_mesh_assets.length !== 25 ||
    clip.visual_mesh_assets.some(asset => asset.format !== 'stl' || asset.status !== 'moonrobo-stl-mesh-referenced')) {
    throw new Error(`${label} bridge must carry 25 referenced E1 STL mesh assets`)
  }
}

const evidence = runLiveEvidence()
validateLiveEvidence(evidence)
validateAgainstRuntimeBridge(evidence)
validateAgainstGeneratedBridge(evidence)

console.log(
  `Live MoonRobo suite evidence check passed: ${evidence.sample_count} samples, ${evidence.loaded_contact_count} loaded contacts, ${evidence.driven_motor_frame_count} driven motor frames`,
)
