import { spawnSync } from 'node:child_process'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const repoRoot = fileURLToPath(new URL('../..', import.meta.url))
const moonroboRoot = fileURLToPath(new URL('../../../moonrobo', import.meta.url))
const generatedDir = fileURLToPath(new URL('./.generated/', import.meta.url))
const contractPath = fileURLToPath(new URL('./.generated/live-moonrobo-contract.json', import.meta.url))
const payloadPath = fileURLToPath(new URL('./.generated/live-suite-preview-payload.json', import.meta.url))
const moonBin = process.env.MOON_BIN ?? 'moon'

function runMoon(cwd, args, label) {
  const result = spawnSync(moonBin, args, {
    cwd,
    encoding: 'utf8',
    maxBuffer: 32 * 1024 * 1024,
  })
  if (result.error) {
    throw result.error
  }
  if (result.status !== 0) {
    throw new Error([
      `${label} failed`,
      result.stdout,
      result.stderr,
    ].filter(Boolean).join('\n'))
  }
  return result.stdout
}

function requireField(value, field, type, label = 'payload') {
  if (typeof value[field] !== type) {
    throw new Error(`${label} field ${field} must be ${type}`)
  }
}

function requireArray(value, field, label = 'payload') {
  if (!Array.isArray(value[field])) {
    throw new Error(`${label} field ${field} must be an array`)
  }
}

function sourceRef(payload, family) {
  return payload.source_refs.find(source => source.source_family === family)
}

mkdirSync(generatedDir, { recursive: true })

const contractJson = runMoon(
  moonroboRoot,
  ['run', 'cmd/moonmoon_contract', '--target', 'native'],
  'MoonRobo live contract export',
)
writeFileSync(contractPath, contractJson)

const payloadJson = runMoon(
  repoRoot,
  ['run', 'cmd/suite_preview', '--target', 'native', '--', '--contract-json', contractPath],
  'MoonMoon live suite-preview payload command',
)
writeFileSync(payloadPath, payloadJson)

const payload = JSON.parse(readFileSync(payloadPath, 'utf8'))

for (const field of [
  'payload_id',
  'robot_id',
  'walk_clip_id',
  'evidence_source',
  'review_status',
  'status',
]) {
  requireField(payload, field, 'string')
}

for (const field of [
  'walk_sample_count',
  'frame_count',
  'blocker_count',
]) {
  requireField(payload, field, 'number')
}

requireField(payload, 'ready', 'boolean')
requireArray(payload, 'authored_joint_samples')
requireArray(payload, 'authored_motion_samples')
requireArray(payload, 'authored_contact_frames')
requireArray(payload, 'authored_motor_frames')
requireArray(payload, 'source_refs')
requireArray(payload, 'blockers')

if (!payload.ready || payload.status !== 'moonrobo-noetix-live-suite-payload-ready') {
  throw new Error(`live suite-preview payload is not ready: ${payload.status}`)
}
if (payload.review_status !== 'moonrobo-noetix-live-review-ready') {
  throw new Error(`live suite-preview payload review is not ready: ${payload.review_status}`)
}
if (payload.blocker_count !== 0 || payload.blockers.length !== 0) {
  throw new Error(`live suite-preview payload reported blockers: ${payload.blockers.join(', ')}`)
}
if (payload.walk_sample_count !== 24 || payload.frame_count !== 24) {
  throw new Error(`live suite-preview payload expected 24 samples/frames, got ${payload.walk_sample_count}/${payload.frame_count}`)
}

for (const field of [
  'authored_joint_samples',
  'authored_motion_samples',
  'authored_contact_frames',
  'authored_motor_frames',
]) {
  if (payload[field].length !== payload.walk_sample_count) {
    throw new Error(`live suite-preview payload ${field} length does not match walk_sample_count`)
  }
}

const evidence = payload.live_suite_evidence
if (!evidence || typeof evidence !== 'object') {
  throw new Error('live suite-preview payload must carry live_suite_evidence')
}
for (const field of [
  'sample_count',
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
  requireField(evidence, field, 'number', 'live suite evidence')
}
requireField(evidence, 'ready', 'boolean', 'live suite evidence')
requireField(evidence, 'regeneration_mode', 'string', 'live suite evidence')
requireField(evidence, 'status', 'string', 'live suite evidence')

if (!evidence.ready || evidence.status !== 'moonmoon-noetix-live-suite-evidence-ready') {
  throw new Error(`live suite evidence is not ready: ${evidence.status}`)
}
if (evidence.regeneration_mode !== 'live-moonrobo-typed-adapter') {
  throw new Error(`live suite evidence used unexpected regeneration mode: ${evidence.regeneration_mode}`)
}
if (evidence.sample_count !== payload.walk_sample_count ||
  evidence.authored_joint_sample_count !== payload.authored_joint_samples.length ||
  evidence.authored_motion_sample_count !== payload.authored_motion_samples.length ||
  evidence.authored_contact_frame_count !== payload.authored_contact_frames.length ||
  evidence.authored_motor_frame_count !== payload.authored_motor_frames.length) {
  throw new Error('live suite evidence counts do not match the suite-preview payload tables')
}
if (evidence.active_contact_frame_count !== payload.walk_sample_count) {
  throw new Error('live suite evidence did not keep every frame contact-supported')
}
if (evidence.loaded_contact_count <= payload.walk_sample_count) {
  throw new Error('live suite evidence did not report multi-contact load evidence')
}
if (evidence.driven_motor_frame_count !== payload.walk_sample_count) {
  throw new Error('live suite evidence did not drive every authored motor frame')
}
if (evidence.motor_review_count !== 0 ||
  evidence.contact_review_count !== 0 ||
  evidence.blocker_count !== 0) {
  throw new Error('live suite evidence reported motor/contact reviews or blockers')
}

const contractRef = sourceRef(payload, 'moonrobo.moonmoon-adapter-contract')
if (!contractRef || contractRef.status !== 'live-typed-source') {
  throw new Error('live suite-preview payload did not cite the live MoonRobo contract source')
}
const contactRef = sourceRef(payload, 'moonrobo.moonmoon-adapter-contact-evidence')
if (!contactRef || contactRef.status !== 'live-typed-source') {
  throw new Error('live suite-preview payload did not cite live MoonRobo contact evidence')
}
const liveEvidenceRef = sourceRef(payload, 'moonrobo.moonmoon-live-suite-evidence')
if (!liveEvidenceRef || liveEvidenceRef.status !== 'live-typed-source') {
  throw new Error('live suite-preview payload did not cite live MoonRobo suite evidence')
}
if (sourceRef(payload, 'moonmoon.rabbita.generated-evidence')) {
  throw new Error('live suite-preview payload must not depend on Rabbita generated evidence')
}

console.log(
  `Live suite payload command check passed: ${payload.walk_sample_count} samples, ${payload.authored_contact_frames.length} contact frames, ${payload.authored_motor_frames.length} motor frames`,
)
