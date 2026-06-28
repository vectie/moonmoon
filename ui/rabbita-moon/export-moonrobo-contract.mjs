import { spawnSync } from 'node:child_process'
import { existsSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const moonroboRoot = fileURLToPath(new URL('../../../moonrobo', import.meta.url))
const jsTargetPath = fileURLToPath(new URL('./generated-moonrobo-noetix-clip.js', import.meta.url))
const checkOnly = process.argv.includes('--check')
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
      `Moonrobo export failed: ${command}`,
      result.stdout,
      result.stderr,
    ].filter(Boolean).join('\n'))
  }
  return JSON.parse(result.stdout)
}

function runMoonroboContract() {
  return runMoonroboJson('cmd/moonmoon_contract')
}

function runMoonroboLiveEvidence() {
  return runMoonroboJson('cmd/moonmoon_suite_evidence')
}

function requireField(value, field, type) {
  if (typeof value[field] !== type) {
    throw new Error(`Moonrobo contract field ${field} must be ${type}`)
  }
}

function requireArray(value, field) {
  if (!Array.isArray(value[field])) {
    throw new Error(`Moonrobo contract field ${field} must be an array`)
  }
}

function validateContract(contract) {
  for (const field of [
    'contract_id',
    'target_payload_type',
    'robot_id',
    'robot_label',
    'platform',
    'profile_path',
    'urdf_path',
    'status',
  ]) {
    requireField(contract, field, 'string')
  }
  requireField(contract, 'expected_profile_joint_count', 'number')
  requireField(contract, 'blocker_count', 'number')
  requireField(contract, 'ready', 'boolean')
  for (const field of [
    'mesh_paths',
    'profile_joint_ids',
    'required_motion_joint_ids',
    'source_refs',
    'blockers',
  ]) {
    requireArray(contract, field)
  }
  if (!contract.walk_clip || typeof contract.walk_clip !== 'object') {
    throw new Error('Moonrobo contract must include walk_clip')
  }
  if (contract.target_payload_type !== 'vectie/moonmoon/src/suite_adapter_preview.NoetixSuiteAdapterPayload') {
    throw new Error(`Moonrobo contract targets unexpected payload type: ${contract.target_payload_type}`)
  }
  if (contract.platform !== 'noetix-e1') {
    throw new Error(`Moonrobo contract targets unexpected platform: ${contract.platform}`)
  }
  if (contract.expected_profile_joint_count !== contract.profile_joint_ids.length) {
    throw new Error('Moonrobo contract profile joint count does not match profile_joint_ids')
  }
  if (contract.blocker_count !== contract.blockers.length) {
    throw new Error('Moonrobo contract blocker count does not match blockers')
  }
  for (const jointId of contract.required_motion_joint_ids) {
    if (!contract.profile_joint_ids.includes(jointId)) {
      throw new Error(`Moonrobo contract requires joint outside profile: ${jointId}`)
    }
  }
  for (const source of contract.source_refs) {
    for (const field of ['source_id', 'source_family', 'local_path', 'role', 'status']) {
      requireField(source, field, 'string')
    }
  }
  validateWalkClip(contract.walk_clip, contract.required_motion_joint_ids)
}

function validateLiveEvidence(evidence, contract) {
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
  requireArray(evidence, 'blockers')
  if (evidence.contract_id !== contract.contract_id) {
    throw new Error('Moonrobo live suite evidence contract_id does not match contract')
  }
  if (evidence.walk_clip_id !== contract.walk_clip.clip_id) {
    throw new Error('Moonrobo live suite evidence walk_clip_id does not match contract')
  }
  if (evidence.regeneration_mode !== 'live-moonrobo-typed-adapter') {
    throw new Error(`Moonrobo live suite evidence used unexpected mode: ${evidence.regeneration_mode}`)
  }
  if (!evidence.ready || evidence.status !== 'moonmoon-noetix-live-suite-evidence-ready') {
    throw new Error(`Moonrobo live suite evidence is not ready: ${evidence.status}`)
  }
  if (evidence.blocker_count !== 0 || evidence.blockers.length !== 0) {
    throw new Error(`Moonrobo live suite evidence reported blockers: ${evidence.blockers.join(', ')}`)
  }
  if (evidence.sample_count !== contract.walk_clip.sample_count ||
    evidence.profile_joint_count !== contract.profile_joint_ids.length ||
    evidence.required_motion_joint_count !== contract.required_motion_joint_ids.length ||
    evidence.authored_joint_sample_count !== contract.walk_clip.authored_joint_samples.length ||
    evidence.authored_motion_sample_count !== contract.walk_clip.authored_motion_samples.length ||
    evidence.authored_contact_frame_count !== contract.walk_clip.authored_contact_frames.length ||
    evidence.authored_motor_frame_count !== contract.walk_clip.authored_motor_frames.length) {
    throw new Error('Moonrobo live suite evidence counts do not match contract payload')
  }
}

function validateWalkClip(clip, requiredJointIds) {
  for (const field of ['clip_id', 'source', 'status']) {
    requireField(clip, field, 'string')
  }
  for (const field of ['cycle_hz', 'root_speed_mps', 'stride_m']) {
    requireField(clip, field, 'number')
  }
  requireField(clip, 'sample_count', 'number')
  requireField(clip, 'blocker_count', 'number')
  requireField(clip, 'ready', 'boolean')
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
    'blockers',
  ]) {
    requireArray(clip, field)
  }
  if (clip.blocker_count !== clip.blockers.length) {
    throw new Error('Moonrobo walk clip blocker count does not match blockers')
  }
  if (clip.sample_count !== 24) {
    throw new Error(`Moonrobo walk clip sample_count must be 24, got ${clip.sample_count}`)
  }
  for (const jointId of requiredJointIds) {
    if (!clip.required_joint_ids.includes(jointId)) {
      throw new Error(`Moonrobo walk clip omits required joint ${jointId}`)
    }
    if (!clip.joint_anchors.some(anchor => anchor.joint_id === jointId)) {
      throw new Error(`Moonrobo walk clip omits joint anchor ${jointId}`)
    }
  }
  for (const spec of clip.foot_phase_specs) {
    for (const field of ['role']) {
      requireField(spec, field, 'string')
    }
    for (const field of ['phase_start', 'phase_end']) {
      requireField(spec, field, 'number')
    }
    requireField(spec, 'support', 'boolean')
    requireField(spec, 'lock_window', 'boolean')
  }
  for (const anchor of clip.joint_anchors) {
    for (const field of ['joint_id', 'side', 'field']) {
      requireField(anchor, field, 'string')
    }
    for (const field of ['phase', 'position_rad']) {
      requireField(anchor, field, 'number')
    }
  }
  for (const param of clip.joint_curve_params) {
    requireField(param, 'name', 'string')
    requireField(param, 'value', 'number')
  }
  if (clip.authored_joint_samples.length !== clip.sample_count) {
    throw new Error('Moonrobo walk clip authored_joint_samples length must match sample_count')
  }
  if (clip.authored_motion_samples.length !== clip.sample_count) {
    throw new Error('Moonrobo walk clip authored_motion_samples length must match sample_count')
  }
  if (clip.authored_contact_frames.length !== clip.sample_count) {
    throw new Error('Moonrobo walk clip authored_contact_frames length must match sample_count')
  }
  if (clip.authored_motor_frames.length !== clip.sample_count) {
    throw new Error('Moonrobo walk clip authored_motor_frames length must match sample_count')
  }
  for (const sample of clip.authored_joint_samples) {
    for (const field of [
      'phase',
      'left_hip_rad',
      'left_knee_rad',
      'left_ankle_rad',
      'left_shoulder_rad',
      'left_elbow_rad',
      'right_hip_rad',
      'right_knee_rad',
      'right_ankle_rad',
      'right_shoulder_rad',
      'right_elbow_rad',
    ]) {
      requireField(sample, field, 'number')
    }
    if (sample.left_knee_rad > 0 || sample.right_knee_rad > 0) {
      throw new Error(`Moonrobo walk clip authored sample has backward knee sign at phase ${sample.phase}`)
    }
  }
  for (const sample of clip.authored_motion_samples) {
    for (const field of [
      'phase',
      'root_cycle_forward_m',
      'root_sway_m',
      'root_bob_m',
      'torso_counter_rotation_rad',
      'left_foot_x_m',
      'left_foot_y_m',
      'left_foot_z_m',
      'left_foot_roll_pitch_rad',
      'right_foot_x_m',
      'right_foot_y_m',
      'right_foot_z_m',
      'right_foot_roll_pitch_rad',
    ]) {
      requireField(sample, field, 'number')
    }
    if (sample.left_foot_x_m < 0 || sample.right_foot_x_m > 0) {
      throw new Error(`Moonrobo walk clip authored foot sample has wrong side sign at phase ${sample.phase}`)
    }
  }
  for (const frame of clip.authored_contact_frames) {
    for (const field of ['frame_index', 'contact_count', 'active_footprint_count']) {
      requireField(frame, field, 'number')
    }
    for (const field of ['time_s', 'phase', 'total_mass_kg']) {
      requireField(frame, field, 'number')
    }
    for (const field of ['phase_label', 'support_foot', 'review_id', 'status']) {
      requireField(frame, field, 'string')
    }
    validateVec3(frame.center_of_mass, `contact frame ${frame.frame_index} center_of_mass`)
    validateVec3(frame.center_of_mass_velocity, `contact frame ${frame.frame_index} center_of_mass_velocity`)
    requireArray(frame, 'contacts')
    if (frame.contacts.length !== 2) {
      throw new Error(`Moonrobo contact frame ${frame.frame_index} must include both feet`)
    }
    if (frame.active_footprint_count <= 0 || frame.status.includes('review')) {
      throw new Error(`Moonrobo contact frame ${frame.frame_index} is not support-ready: ${frame.status}`)
    }
    for (const contact of frame.contacts) {
      validateContact(contact, frame.frame_index)
    }
  }
  for (const frame of clip.authored_motor_frames) {
    for (const field of ['frame_index', 'joint_count', 'driven_joint_count', 'review_count']) {
      requireField(frame, field, 'number')
    }
    for (const field of [
      'time_s',
      'dt_s',
      'phase_start',
      'phase_end',
      'max_abs_angle_delta_rad',
      'max_abs_velocity_rad_s',
      'max_abs_commanded_torque_nm',
      'total_absolute_work_j',
    ]) {
      requireField(frame, field, 'number')
    }
    for (const field of ['phase_label', 'support_foot', 'status']) {
      requireField(frame, field, 'string')
    }
    requireArray(frame, 'steps')
    if (frame.steps.length !== requiredJointIds.length) {
      throw new Error(`Moonrobo motor frame ${frame.frame_index} has wrong step count`)
    }
    if (frame.review_count !== 0 || frame.status.includes('review')) {
      throw new Error(`Moonrobo motor frame ${frame.frame_index} is not command-ready: ${frame.status}`)
    }
    for (const step of frame.steps) {
      for (const field of ['joint_id', 'parent_link', 'child_link', 'side', 'field', 'status']) {
        requireField(step, field, 'string')
      }
      for (const field of [
        'before_position_rad',
        'target_position_rad',
        'target_velocity_rad_s',
        'bounded_velocity_rad_s',
        'angle_delta_rad',
        'commanded_torque_nm',
        'work_j',
        'min_position_rad',
        'max_position_rad',
        'max_velocity_rad_s',
        'max_torque_nm',
        'stiffness_nm_per_rad',
        'damping_nm_s_per_rad',
      ]) {
        requireField(step, field, 'number')
      }
      for (const field of ['position_within_limits', 'velocity_within_limits', 'torque_saturated']) {
        requireField(step, field, 'boolean')
      }
      if (!step.position_within_limits || !step.velocity_within_limits || step.torque_saturated) {
        throw new Error(`Moonrobo motor step ${step.joint_id} failed limits at frame ${frame.frame_index}`)
      }
    }
  }
  for (const required of [
    'hip_swing_start_rad',
    'hip_swing_end_rad',
    'knee_base_rad',
    'knee_swing_lift_rad',
    'ankle_stance_start_rad',
    'ankle_stance_end_rad',
    'arm_phase_lag',
    'shoulder_hip_scale',
    'elbow_base_rad',
  ]) {
    if (!clip.joint_curve_params.some(param => param.name === required)) {
      throw new Error(`Moonrobo walk clip omits joint curve parameter ${required}`)
    }
  }
}

function validateVec3(value, label) {
  if (!value || typeof value !== 'object') {
    throw new Error(`Moonrobo ${label} must be an object`)
  }
  for (const field of ['x', 'y', 'z']) {
    requireField(value, field, 'number')
  }
}

function validateContact(contact, frameIndex) {
  requireField(contact, 'contact_id', 'string')
  validateVec3(contact.applied_force_n, `contact ${contact.contact_id} applied_force_n`)
  if (!contact.footprint || typeof contact.footprint !== 'object') {
    throw new Error(`Moonrobo contact ${contact.contact_id} in frame ${frameIndex} needs a footprint`)
  }
  requireField(contact.footprint, 'footprint_id', 'string')
  validateVec3(contact.footprint.center, `contact ${contact.contact_id} footprint center`)
  for (const field of ['half_length_m', 'half_width_m']) {
    requireField(contact.footprint, field, 'number')
  }
  requireField(contact.footprint, 'active', 'boolean')
  if (!contact.patch || typeof contact.patch !== 'object') {
    throw new Error(`Moonrobo contact ${contact.contact_id} in frame ${frameIndex} needs a patch`)
  }
  requireField(contact.patch, 'patch_id', 'string')
  validateVec3(contact.patch.center, `contact ${contact.contact_id} patch center`)
  for (const field of [
    'half_length_m',
    'half_width_m',
    'sample_count',
    'contact_count',
    'min_clearance_m',
    'max_clearance_m',
    'average_surface_elevation_m',
  ]) {
    requireField(contact.patch, field, 'number')
  }
  validateVec3(contact.patch.average_surface_normal, `contact ${contact.contact_id} patch normal`)
  requireField(contact.patch, 'status', 'string')
  requireArray(contact.patch, 'samples')
  if (contact.patch.samples.length !== 4) {
    throw new Error(`Moonrobo contact ${contact.contact_id} in frame ${frameIndex} must have four patch samples`)
  }
  if (contact.footprint.active) {
    if (contact.patch.contact_count !== contact.patch.samples.length || contact.patch.status !== 'patch-contact') {
      throw new Error(`Moonrobo active contact ${contact.contact_id} in frame ${frameIndex} is not patch-contact`)
    }
    if (contact.applied_force_n.z <= 0) {
      throw new Error(`Moonrobo active contact ${contact.contact_id} in frame ${frameIndex} has no normal load`)
    }
  }
  for (const sample of contact.patch.samples) {
    requireField(sample, 'probe_id', 'string')
    validateVec3(sample.position, `contact ${contact.contact_id} probe position`)
    validateVec3(sample.surface_normal, `contact ${contact.contact_id} probe normal`)
    for (const field of ['surface_elevation_m', 'clearance_m', 'local_grade']) {
      requireField(sample, field, 'number')
    }
    requireField(sample, 'in_contact', 'boolean')
    requireField(sample, 'status', 'string')
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

function generatedJsContent(contract, liveEvidence) {
  const clip = contract.walk_clip
  const runtimeClip = {
    clip_id: clip.clip_id,
    source: clip.source,
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
    live_suite_evidence: liveEvidence,
    ready: clip.ready,
    status: clip.status,
  }
  return `// Generated by ui/rabbita-moon/export-moonrobo-contract.mjs.
// Do not edit this file by hand.
// Generated from ../moonrobo/src/moonmoon_adapter/noetix_contract.mbt.

export const MOONROBO_NOETIX_WALK_CLIP = ${JSON.stringify(runtimeClip, null, 2)}
`
}

const contract = runMoonroboContract()
const liveEvidence = runMoonroboLiveEvidence()
validateContract(contract)
validateLiveEvidence(liveEvidence, contract)
const jsContent = generatedJsContent(contract, liveEvidence)

if (checkOnly) {
  const currentJs = readFileSync(jsTargetPath, 'utf8')
  if (currentJs !== jsContent) {
    throw new Error(`${jsTargetPath} is stale; run npm run export:moonrobo-contract`)
  }
} else {
  writeFileSync(jsTargetPath, jsContent)
  console.log(`wrote ${jsTargetPath}`)
}
