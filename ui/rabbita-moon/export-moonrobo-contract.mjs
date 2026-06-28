import { spawnSync } from 'node:child_process'
import { readFileSync, unlinkSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const repoRoot = fileURLToPath(new URL('../..', import.meta.url))
const moonroboRoot = fileURLToPath(new URL('../../../moonrobo', import.meta.url))
const moonbitTargetPath = fileURLToPath(new URL('../../src/suite_adapter_preview/generated_moonrobo_noetix_contract.mbt', import.meta.url))
const jsTargetPath = fileURLToPath(new URL('./generated-moonrobo-noetix-clip.js', import.meta.url))
const checkOnly = process.argv.includes('--check')
const moonBin = process.env.MOON_BIN ?? 'moon'
const contractSource = '../moonrobo/src/moonmoon_adapter/noetix_contract.mbt#noetix_e1_moonmoon_locomotion_contract'
const liveEvidenceSource = '../moonrobo/src/moonmoon_adapter/noetix_live_suite_evidence.mbt#noetix_e1_moonmoon_live_suite_evidence'

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

function moonroboPath(path) {
  return path.startsWith('../moonrobo/') ? path : `../moonrobo/${path}`
}

function mbString(value) {
  return JSON.stringify(value)
}

function mbBool(value) {
  return value ? 'true' : 'false'
}

function mbDouble(value) {
  if (!Number.isFinite(value)) {
    throw new Error(`Cannot emit non-finite MoonBit number: ${value}`)
  }
  const rounded = Number(value.toFixed(6))
  if (Object.is(rounded, -0)) {
    return '0.0'
  }
  if (Number.isInteger(rounded)) {
    return `${rounded}.0`
  }
  return String(rounded)
}

function indent(text, spaces = 2) {
  const prefix = ' '.repeat(spaces)
  return text.split('\n').map(line => line ? `${prefix}${line}` : line).join('\n')
}

function mbArray(items, render) {
  if (items.length === 0) {
    return '[]'
  }
  return `[\n${items.map(item => indent(render(item), 2)).join(',\n')},\n]`
}

function mbStringArray(items) {
  return mbArray(items, mbString)
}

function mbSourceRef(source) {
  return `noetix_suite_source_ref(
  ${mbString(source.source_id)},
  ${mbString(source.source_family)},
  ${mbString(moonroboPath(source.local_path))},
  ${mbString(source.role)},
  ${mbString(source.status)},
)`
}

function mbFootPhaseSpec(spec) {
  return `noetix_suite_foot_phase_spec(
  ${mbString(spec.role)},
  ${mbDouble(spec.phase_start)},
  ${mbDouble(spec.phase_end)},
  ${mbBool(spec.support)},
  ${mbBool(spec.lock_window)},
)`
}

function mbJointAnchor(anchor) {
  return `noetix_suite_joint_anchor(
  ${mbString(anchor.joint_id)},
  ${mbString(anchor.side)},
  ${mbString(anchor.field)},
  ${mbDouble(anchor.phase)},
  ${mbDouble(anchor.position_rad)},
)`
}

function mbJointCurveParam(param) {
  return `noetix_suite_joint_curve_param(
  ${mbString(param.name)},
  ${mbDouble(param.value)},
)`
}

function mbAuthoredJointSample(sample) {
  return `noetix_suite_authored_joint_sample(
  ${mbDouble(sample.phase)},
  ${mbDouble(sample.left_hip_rad)},
  ${mbDouble(sample.left_knee_rad)},
  ${mbDouble(sample.left_ankle_rad)},
  ${mbDouble(sample.left_shoulder_rad)},
  ${mbDouble(sample.left_elbow_rad)},
  ${mbDouble(sample.right_hip_rad)},
  ${mbDouble(sample.right_knee_rad)},
  ${mbDouble(sample.right_ankle_rad)},
  ${mbDouble(sample.right_shoulder_rad)},
  ${mbDouble(sample.right_elbow_rad)},
)`
}

function mbAuthoredMotionSample(sample) {
  return `noetix_suite_authored_motion_sample(
  ${mbDouble(sample.phase)},
  ${mbDouble(sample.root_cycle_forward_m)},
  ${mbDouble(sample.root_sway_m)},
  ${mbDouble(sample.root_bob_m)},
  ${mbDouble(sample.torso_counter_rotation_rad)},
  ${mbDouble(sample.left_foot_x_m)},
  ${mbDouble(sample.left_foot_y_m)},
  ${mbDouble(sample.left_foot_z_m)},
  ${mbDouble(sample.left_foot_roll_pitch_rad)},
  ${mbDouble(sample.right_foot_x_m)},
  ${mbDouble(sample.right_foot_y_m)},
  ${mbDouble(sample.right_foot_z_m)},
  ${mbDouble(sample.right_foot_roll_pitch_rad)},
)`
}

function mbVec3(value) {
  return `{ x: ${mbDouble(value.x)}, y: ${mbDouble(value.y)}, z: ${mbDouble(value.z)} }`
}

function mbContactProbe(sample) {
  return `{
  probe_id: ${mbString(sample.probe_id)},
  position: ${mbVec3(sample.position)},
  surface_elevation_m: ${mbDouble(sample.surface_elevation_m)},
  surface_normal: ${mbVec3(sample.surface_normal)},
  clearance_m: ${mbDouble(sample.clearance_m)},
  in_contact: ${mbBool(sample.in_contact)},
  local_grade: ${mbDouble(sample.local_grade)},
  status: ${mbString(sample.status)},
}`
}

function mbContactPatch(patch) {
  return `{
  patch_id: ${mbString(patch.patch_id)},
  center: ${mbVec3(patch.center)},
  half_length_m: ${mbDouble(patch.half_length_m)},
  half_width_m: ${mbDouble(patch.half_width_m)},
  sample_count: ${patch.sample_count},
  contact_count: ${patch.contact_count},
  min_clearance_m: ${mbDouble(patch.min_clearance_m)},
  max_clearance_m: ${mbDouble(patch.max_clearance_m)},
  average_surface_elevation_m: ${mbDouble(patch.average_surface_elevation_m)},
  average_surface_normal: ${mbVec3(patch.average_surface_normal)},
  samples: ${indent(mbArray(patch.samples, mbContactProbe), 2).trimStart()},
  status: ${mbString(patch.status)},
}`
}

function mbContact(contact) {
  return `{
  contact_id: ${mbString(contact.contact_id)},
  footprint: {
    footprint_id: ${mbString(contact.footprint.footprint_id)},
    center: ${mbVec3(contact.footprint.center)},
    half_length_m: ${mbDouble(contact.footprint.half_length_m)},
    half_width_m: ${mbDouble(contact.footprint.half_width_m)},
    active: ${mbBool(contact.footprint.active)},
  },
  patch: ${indent(mbContactPatch(contact.patch), 2).trimStart()},
  applied_force_n: ${mbVec3(contact.applied_force_n)},
}`
}

function mbContactFrame(frame) {
  return `{
  time_s: ${mbDouble(frame.time_s)},
  phase_label: ${mbString(frame.phase_label)},
  support_foot: ${mbString(frame.support_foot)},
  review_id: ${mbString(frame.review_id)},
  center_of_mass: ${mbVec3(frame.center_of_mass)},
  center_of_mass_velocity: ${mbVec3(frame.center_of_mass_velocity)},
  total_mass_kg: ${mbDouble(frame.total_mass_kg)},
  contacts: ${indent(mbArray(frame.contacts, mbContact), 2).trimStart()},
}`
}

function mbLiveSuiteEvidence(evidence) {
  return `noetix_suite_live_evidence(
  ${mbString(evidence.evidence_id)},
  ${mbString(evidence.regeneration_mode)},
  ${mbString(evidence.contract_id)},
  ${mbString(evidence.robot_id)},
  ${mbString(evidence.walk_clip_id)},
  ${mbString(evidence.source)},
  ${evidence.sample_count},
  ${evidence.profile_joint_count},
  ${evidence.required_motion_joint_count},
  ${evidence.authored_joint_sample_count},
  ${evidence.authored_motion_sample_count},
  ${evidence.authored_contact_frame_count},
  ${evidence.authored_motor_frame_count},
  ${evidence.active_contact_frame_count},
  ${evidence.loaded_contact_count},
  ${evidence.driven_motor_frame_count},
  ${evidence.motor_review_count},
  ${evidence.contact_review_count},
  ${evidence.blocker_count},
  ${indent(mbStringArray(evidence.blockers), 2).trimStart()},
  ${mbBool(evidence.ready)},
  ${mbString(evidence.status)},
)`
}

function mbMotorTargetStep(step) {
  return `noetix_suite_motor_target_step(
  ${mbString(step.joint_id)},
  ${mbString(step.parent_link)},
  ${mbString(step.child_link)},
  ${mbString(step.side)},
  ${mbString(step.field)},
  ${mbDouble(step.before_position_rad)},
  ${mbDouble(step.target_position_rad)},
  ${mbDouble(step.target_velocity_rad_s)},
  ${mbDouble(step.bounded_velocity_rad_s)},
  ${mbDouble(step.angle_delta_rad)},
  ${mbDouble(step.commanded_torque_nm)},
  ${mbDouble(step.work_j)},
  ${mbDouble(step.min_position_rad)},
  ${mbDouble(step.max_position_rad)},
  ${mbDouble(step.max_velocity_rad_s)},
  ${mbDouble(step.max_torque_nm)},
  ${mbDouble(step.stiffness_nm_per_rad)},
  ${mbDouble(step.damping_nm_s_per_rad)},
  ${mbBool(step.position_within_limits)},
  ${mbBool(step.velocity_within_limits)},
  ${mbBool(step.torque_saturated)},
  ${mbString(step.status)},
)`
}

function mbMotorFrame(frame) {
  return `noetix_suite_motor_frame_sample(
  ${frame.frame_index},
  ${mbDouble(frame.time_s)},
  ${mbDouble(frame.dt_s)},
  ${mbDouble(frame.phase_start)},
  ${mbDouble(frame.phase_end)},
  ${mbString(frame.phase_label)},
  ${mbString(frame.support_foot)},
  ${frame.joint_count},
  ${frame.driven_joint_count},
  ${frame.review_count},
  ${mbDouble(frame.max_abs_angle_delta_rad)},
  ${mbDouble(frame.max_abs_velocity_rad_s)},
  ${mbDouble(frame.max_abs_commanded_torque_nm)},
  ${mbDouble(frame.total_absolute_work_j)},
  ${indent(mbArray(frame.steps, mbMotorTargetStep), 2).trimStart()},
  ${mbString(frame.status)},
)`
}

function generatedContent(contract, liveEvidence) {
  const clip = contract.walk_clip
  return `///| Generated by ui/rabbita-moon/export-moonrobo-contract.mjs.
///| Do not edit this file by hand.
///| Generated from ../moonrobo/src/moonmoon_adapter/noetix_contract.mbt.

///|
fn generated_moonrobo_noetix_contract_source() -> String {
  ${mbString(contractSource)}
}

///|
fn generated_moonrobo_noetix_contract_id() -> String {
  ${mbString(contract.contract_id)}
}

///|
fn generated_moonrobo_noetix_target_payload_type() -> String {
  ${mbString(contract.target_payload_type)}
}

///|
fn generated_moonrobo_noetix_robot_id() -> String {
  ${mbString(contract.robot_id)}
}

///|
fn generated_moonrobo_noetix_robot_label() -> String {
  ${mbString(contract.robot_label)}
}

///|
fn generated_moonrobo_noetix_platform() -> String {
  ${mbString(contract.platform)}
}

///|
fn generated_moonrobo_noetix_profile_path() -> String {
  ${mbString(moonroboPath(contract.profile_path))}
}

///|
fn generated_moonrobo_noetix_urdf_path() -> String {
  ${mbString(moonroboPath(contract.urdf_path))}
}

///|
fn generated_moonrobo_noetix_mesh_paths() -> Array[String] {
  ${indent(mbStringArray(contract.mesh_paths.map(moonroboPath)), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_expected_profile_joint_count() -> Int {
  ${contract.expected_profile_joint_count}
}

///|
fn generated_moonrobo_noetix_profile_joint_ids() -> Array[String] {
  ${indent(mbStringArray(contract.profile_joint_ids), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_required_motion_joint_ids() -> Array[String] {
  ${indent(mbStringArray(contract.required_motion_joint_ids), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_walk_clip_id() -> String {
  ${mbString(clip.clip_id)}
}

///|
fn generated_moonrobo_noetix_walk_clip_source() -> String {
  ${mbString(clip.source)}
}

///|
fn generated_moonrobo_noetix_contact_frame_source() -> String {
  ${mbString(`${clip.source}#authored_contact_frames`)}
}

///|
fn generated_moonrobo_noetix_walk_cycle_hz() -> Double {
  ${mbDouble(clip.cycle_hz)}
}

///|
fn generated_moonrobo_noetix_root_speed_mps() -> Double {
  ${mbDouble(clip.root_speed_mps)}
}

///|
fn generated_moonrobo_noetix_stride_m() -> Double {
  ${mbDouble(clip.stride_m)}
}

///|
fn generated_moonrobo_noetix_walk_sample_count() -> Int {
  ${clip.sample_count}
}

///|
fn generated_moonrobo_noetix_foot_phase_sequence() -> Array[String] {
  ${indent(mbStringArray(clip.foot_phase_sequence), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_walk_phase_labels() -> Array[String] {
  ${indent(mbStringArray(clip.phase_labels), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_foot_phase_specs() -> Array[
  SuiteAdapterFootPhaseSpec,
] {
  ${indent(mbArray(clip.foot_phase_specs, mbFootPhaseSpec), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_joint_anchors() -> Array[
  SuiteAdapterJointAnchor,
] {
  ${indent(mbArray(clip.joint_anchors, mbJointAnchor), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_joint_curve_params() -> Array[
  SuiteAdapterJointCurveParam,
] {
  ${indent(mbArray(clip.joint_curve_params, mbJointCurveParam), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_authored_joint_samples() -> Array[
  SuiteAdapterAuthoredJointSample,
] {
  ${indent(mbArray(clip.authored_joint_samples, mbAuthoredJointSample), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_authored_motion_samples() -> Array[
  SuiteAdapterAuthoredMotionSample,
] {
  ${indent(mbArray(clip.authored_motion_samples, mbAuthoredMotionSample), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_contact_frames() -> Array[
  RabbitaNoetixGeneratedMotionFrame,
] {
  ${indent(mbArray(clip.authored_contact_frames, mbContactFrame), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_authored_motor_frames() -> Array[
  SuiteAdapterMotorFrameSample,
] {
  ${indent(mbArray(clip.authored_motor_frames, mbMotorFrame), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_walk_clip_blockers() -> Array[String] {
  ${indent(mbStringArray(clip.blockers), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_walk_clip_ready() -> Bool {
  ${mbBool(clip.ready)}
}

///|
fn generated_moonrobo_noetix_walk_clip_status() -> String {
  ${mbString(clip.status)}
}

///|
fn generated_moonrobo_noetix_source_contract_ref() -> SuiteAdapterSourceRef {
  noetix_suite_source_ref(
    "moonrobo-noetix-e1-moonmoon-contract",
    "moonrobo.moonmoon-adapter-contract",
    generated_moonrobo_noetix_contract_source(),
    "typed Moonrobo source contract used to regenerate Moonmoon suite evidence",
    "generated-from-typed-source",
  )
}

///|
fn generated_moonrobo_noetix_live_evidence_source() -> String {
  ${mbString(liveEvidenceSource)}
}

///|
fn generated_moonrobo_noetix_live_suite_evidence() -> SuiteAdapterLiveSuiteEvidence {
  ${indent(mbLiveSuiteEvidence(liveEvidence), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_source_refs() -> Array[SuiteAdapterSourceRef] {
  ${indent(mbArray(contract.source_refs, mbSourceRef), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_source_blockers() -> Array[String] {
  ${indent(mbStringArray(contract.blockers), 2).trimStart()}
}

///|
fn generated_moonrobo_noetix_source_ready() -> Bool {
  ${contract.ready ? 'true' : 'false'}
}

///|
fn generated_moonrobo_noetix_source_status() -> String {
  ${mbString(contract.status)}
}
`
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

function moonFmt(path) {
  const result = spawnSync(moonBin, ['fmt', path], {
    cwd: repoRoot,
    encoding: 'utf8',
  })
  if (result.error) {
    throw result.error
  }
  if (result.status !== 0) {
    throw new Error([
      `moon fmt failed for ${path}`,
      result.stdout,
      result.stderr,
    ].filter(Boolean).join('\n'))
  }
}

function formattedMoonBit(content) {
  const tempPath = fileURLToPath(new URL('../../src/suite_adapter_preview/generated_moonrobo_noetix_contract_check.mbt', import.meta.url))
  writeFileSync(tempPath, content)
  try {
    moonFmt(tempPath)
    return readFileSync(tempPath, 'utf8')
  } finally {
    unlinkSync(tempPath)
  }
}

const contract = runMoonroboContract()
const liveEvidence = runMoonroboLiveEvidence()
validateContract(contract)
validateLiveEvidence(liveEvidence, contract)
const formatted = formattedMoonBit(generatedContent(contract, liveEvidence))
const jsContent = generatedJsContent(contract, liveEvidence)

if (checkOnly) {
  const current = readFileSync(moonbitTargetPath, 'utf8')
  if (current !== formatted) {
    throw new Error(`${moonbitTargetPath} is stale; run npm run export:moonrobo-contract`)
  }
  const currentJs = readFileSync(jsTargetPath, 'utf8')
  if (currentJs !== jsContent) {
    throw new Error(`${jsTargetPath} is stale; run npm run export:moonrobo-contract`)
  }
} else {
  writeFileSync(moonbitTargetPath, formatted)
  writeFileSync(jsTargetPath, jsContent)
  console.log(`wrote ${moonbitTargetPath}`)
  console.log(`wrote ${jsTargetPath}`)
}
