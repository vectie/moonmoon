///|
pub(all) struct SuiteAdapterSourceRef {
  source_id : String
  source_family : String
  local_path : String
  role : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterFootPhaseSpec {
  role : String
  phase_start : Double
  phase_end : Double
  support : Bool
  lock_window : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterJointAnchor {
  joint_id : String
  side : String
  field : String
  phase : Double
  position_rad : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterJointCurveParam {
  name : String
  value : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterAuthoredJointSample {
  phase : Double
  left_hip_rad : Double
  left_knee_rad : Double
  left_ankle_rad : Double
  left_shoulder_rad : Double
  left_elbow_rad : Double
  right_hip_rad : Double
  right_knee_rad : Double
  right_ankle_rad : Double
  right_shoulder_rad : Double
  right_elbow_rad : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterAuthoredMotionSample {
  phase : Double
  root_cycle_forward_m : Double
  root_sway_m : Double
  root_bob_m : Double
  torso_counter_rotation_rad : Double
  left_foot_x_m : Double
  left_foot_y_m : Double
  left_foot_z_m : Double
  left_foot_roll_pitch_rad : Double
  right_foot_x_m : Double
  right_foot_y_m : Double
  right_foot_z_m : Double
  right_foot_roll_pitch_rad : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterMotorTargetStep {
  joint_id : String
  parent_link : String
  child_link : String
  side : String
  field : String
  before_position_rad : Double
  target_position_rad : Double
  target_velocity_rad_s : Double
  bounded_velocity_rad_s : Double
  angle_delta_rad : Double
  commanded_torque_nm : Double
  work_j : Double
  min_position_rad : Double
  max_position_rad : Double
  max_velocity_rad_s : Double
  max_torque_nm : Double
  stiffness_nm_per_rad : Double
  damping_nm_s_per_rad : Double
  position_within_limits : Bool
  velocity_within_limits : Bool
  torque_saturated : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterMotorFrameSample {
  frame_index : Int
  time_s : Double
  dt_s : Double
  phase_start : Double
  phase_end : Double
  phase_label : String
  support_foot : String
  joint_count : Int
  driven_joint_count : Int
  review_count : Int
  max_abs_angle_delta_rad : Double
  max_abs_velocity_rad_s : Double
  max_abs_commanded_torque_nm : Double
  total_absolute_work_j : Double
  steps : Array[SuiteAdapterMotorTargetStep]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NoetixSuiteAdapterPayload {
  payload_id : String
  robot_id : String
  robot_label : String
  platform : String
  profile_path : String
  urdf_path : String
  mesh_paths : Array[String]
  evidence_source : String
  motion_trace_id : String
  hinge_trace_id : String
  combined_review_id : String
  walk_clip_id : String
  walk_clip_source : String
  walk_cycle_hz : Double
  root_speed_mps : Double
  stride_m : Double
  walk_sample_count : Int
  foot_phase_sequence : Array[String]
  walk_phase_labels : Array[String]
  foot_phase_specs : Array[SuiteAdapterFootPhaseSpec]
  joint_anchors : Array[SuiteAdapterJointAnchor]
  joint_curve_params : Array[SuiteAdapterJointCurveParam]
  authored_joint_samples : Array[SuiteAdapterAuthoredJointSample]
  authored_motion_samples : Array[SuiteAdapterAuthoredMotionSample]
  authored_motor_frames : Array[SuiteAdapterMotorFrameSample]
  expected_profile_joint_count : Int
  driven_joint_ids : Array[String]
  frame_count : Int
  source_refs : Array[SuiteAdapterSourceRef]
  review_status : String
  blocker_count : Int
  blockers : Array[String]
  ready : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn noetix_suite_source_ref(
  source_id : String,
  source_family : String,
  local_path : String,
  role : String,
  status : String,
) -> SuiteAdapterSourceRef {
  { source_id, source_family, local_path, role, status }
}

///|
fn noetix_suite_foot_phase_spec(
  role : String,
  phase_start : Double,
  phase_end : Double,
  support : Bool,
  lock_window : Bool,
) -> SuiteAdapterFootPhaseSpec {
  { role, phase_start, phase_end, support, lock_window }
}

///|
fn noetix_suite_joint_anchor(
  joint_id : String,
  side : String,
  field : String,
  phase : Double,
  position_rad : Double,
) -> SuiteAdapterJointAnchor {
  { joint_id, side, field, phase, position_rad }
}

///|
fn noetix_suite_joint_curve_param(
  name : String,
  value : Double,
) -> SuiteAdapterJointCurveParam {
  { name, value }
}

///|
fn noetix_suite_authored_joint_sample(
  phase : Double,
  left_hip_rad : Double,
  left_knee_rad : Double,
  left_ankle_rad : Double,
  left_shoulder_rad : Double,
  left_elbow_rad : Double,
  right_hip_rad : Double,
  right_knee_rad : Double,
  right_ankle_rad : Double,
  right_shoulder_rad : Double,
  right_elbow_rad : Double,
) -> SuiteAdapterAuthoredJointSample {
  {
    phase,
    left_hip_rad,
    left_knee_rad,
    left_ankle_rad,
    left_shoulder_rad,
    left_elbow_rad,
    right_hip_rad,
    right_knee_rad,
    right_ankle_rad,
    right_shoulder_rad,
    right_elbow_rad,
  }
}

///|
fn noetix_suite_authored_motion_sample(
  phase : Double,
  root_cycle_forward_m : Double,
  root_sway_m : Double,
  root_bob_m : Double,
  torso_counter_rotation_rad : Double,
  left_foot_x_m : Double,
  left_foot_y_m : Double,
  left_foot_z_m : Double,
  left_foot_roll_pitch_rad : Double,
  right_foot_x_m : Double,
  right_foot_y_m : Double,
  right_foot_z_m : Double,
  right_foot_roll_pitch_rad : Double,
) -> SuiteAdapterAuthoredMotionSample {
  {
    phase,
    root_cycle_forward_m,
    root_sway_m,
    root_bob_m,
    torso_counter_rotation_rad,
    left_foot_x_m,
    left_foot_y_m,
    left_foot_z_m,
    left_foot_roll_pitch_rad,
    right_foot_x_m,
    right_foot_y_m,
    right_foot_z_m,
    right_foot_roll_pitch_rad,
  }
}

///|
fn noetix_suite_motor_target_step(
  joint_id : String,
  parent_link : String,
  child_link : String,
  side : String,
  field : String,
  before_position_rad : Double,
  target_position_rad : Double,
  target_velocity_rad_s : Double,
  bounded_velocity_rad_s : Double,
  angle_delta_rad : Double,
  commanded_torque_nm : Double,
  work_j : Double,
  min_position_rad : Double,
  max_position_rad : Double,
  max_velocity_rad_s : Double,
  max_torque_nm : Double,
  stiffness_nm_per_rad : Double,
  damping_nm_s_per_rad : Double,
  position_within_limits : Bool,
  velocity_within_limits : Bool,
  torque_saturated : Bool,
  status : String,
) -> SuiteAdapterMotorTargetStep {
  {
    joint_id,
    parent_link,
    child_link,
    side,
    field,
    before_position_rad,
    target_position_rad,
    target_velocity_rad_s,
    bounded_velocity_rad_s,
    angle_delta_rad,
    commanded_torque_nm,
    work_j,
    min_position_rad,
    max_position_rad,
    max_velocity_rad_s,
    max_torque_nm,
    stiffness_nm_per_rad,
    damping_nm_s_per_rad,
    position_within_limits,
    velocity_within_limits,
    torque_saturated,
    status,
  }
}

///|
fn noetix_suite_motor_frame_sample(
  frame_index : Int,
  time_s : Double,
  dt_s : Double,
  phase_start : Double,
  phase_end : Double,
  phase_label : String,
  support_foot : String,
  joint_count : Int,
  driven_joint_count : Int,
  review_count : Int,
  max_abs_angle_delta_rad : Double,
  max_abs_velocity_rad_s : Double,
  max_abs_commanded_torque_nm : Double,
  total_absolute_work_j : Double,
  steps : Array[SuiteAdapterMotorTargetStep],
  status : String,
) -> SuiteAdapterMotorFrameSample {
  {
    frame_index,
    time_s,
    dt_s,
    phase_start,
    phase_end,
    phase_label,
    support_foot,
    joint_count,
    driven_joint_count,
    review_count,
    max_abs_angle_delta_rad,
    max_abs_velocity_rad_s,
    max_abs_commanded_torque_nm,
    total_absolute_work_j,
    steps,
    status,
  }
}

///|
fn noetix_expected_profile_joint_count() -> Int {
  generated_moonrobo_noetix_expected_profile_joint_count()
}

///|
fn noetix_required_driven_joint_ids() -> Array[String] {
  generated_moonrobo_noetix_required_motion_joint_ids()
}

///|
fn noetix_generated_driven_joint_ids() -> Array[String] {
  let ids : Array[String] = []
  let frames = generated_moonrobo_noetix_authored_motor_frames()
  if frames.length() > 0 {
    for step in frames[0].steps {
      ids.push(step.joint_id)
    }
  }
  ids
}

///|
fn noetix_missing_required_driven_joint_ids(
  driven : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for joint_id in noetix_required_driven_joint_ids() {
    if !driven.contains(joint_id) {
      missing.push(joint_id)
    }
  }
  missing
}

///|
fn moonrobo_noetix_source_contract_bridge_blockers() -> Array[String] {
  let blockers : Array[String] = []
  if generated_moonrobo_noetix_contract_id() !=
    "\{generated_moonrobo_noetix_robot_id()}/moonmoon-locomotion-source-contract" {
    blockers.push(
      "moonrobo-source-contract-id:\{generated_moonrobo_noetix_contract_id()}",
    )
  }
  if generated_moonrobo_noetix_target_payload_type() !=
    "vectie/moonmoon/src/suite_adapter_preview.NoetixSuiteAdapterPayload" {
    blockers.push(
      "moonrobo-source-contract-target:\{generated_moonrobo_noetix_target_payload_type()}",
    )
  }
  if generated_moonrobo_noetix_profile_joint_ids().length() !=
    noetix_expected_profile_joint_count() {
    blockers.push(
      "moonrobo-source-contract-profile-joint-count:\{generated_moonrobo_noetix_profile_joint_ids().length()}",
    )
  }
  for joint_id in noetix_required_driven_joint_ids() {
    if !generated_moonrobo_noetix_profile_joint_ids().contains(joint_id) {
      blockers.push(
        "moonrobo-source-contract-missing-profile-joint:\{joint_id}",
      )
    }
  }
  if !generated_moonrobo_noetix_walk_clip_ready() {
    blockers.push(
      "moonrobo-walk-clip:\{generated_moonrobo_noetix_walk_clip_status()}",
    )
  }
  for blocker in generated_moonrobo_noetix_walk_clip_blockers() {
    blockers.push("moonrobo-walk-clip-blocker:\{blocker}")
  }
  if generated_moonrobo_noetix_walk_sample_count() != 24 {
    blockers.push(
      "moonrobo-walk-clip-sample-count:\{generated_moonrobo_noetix_walk_sample_count()}",
    )
  }
  if generated_moonrobo_noetix_authored_joint_samples().length() !=
    generated_moonrobo_noetix_walk_sample_count() {
    blockers.push(
      "moonrobo-walk-clip-authored-sample-count:\{generated_moonrobo_noetix_authored_joint_samples().length()}",
    )
  }
  if generated_moonrobo_noetix_authored_motion_samples().length() !=
    generated_moonrobo_noetix_walk_sample_count() {
    blockers.push(
      "moonrobo-walk-clip-authored-motion-sample-count:\{generated_moonrobo_noetix_authored_motion_samples().length()}",
    )
  }
  if generated_moonrobo_noetix_contact_frames().length() !=
    generated_moonrobo_noetix_walk_sample_count() {
    blockers.push(
      "moonrobo-walk-clip-contact-frame-count:\{generated_moonrobo_noetix_contact_frames().length()}",
    )
  }
  if generated_moonrobo_noetix_authored_motor_frames().length() !=
    generated_moonrobo_noetix_walk_sample_count() {
    blockers.push(
      "moonrobo-walk-clip-authored-motor-frame-count:\{generated_moonrobo_noetix_authored_motor_frames().length()}",
    )
  }
  if generated_moonrobo_noetix_foot_phase_sequence().length() != 6 {
    blockers.push(
      "moonrobo-walk-clip-foot-phase-count:\{generated_moonrobo_noetix_foot_phase_sequence().length()}",
    )
  }
  for joint_id in noetix_required_driven_joint_ids() {
    if !generated_moonrobo_noetix_joint_anchors().any(fn(anchor) {
        anchor.joint_id == joint_id
      }) {
      blockers.push("moonrobo-walk-clip-missing-anchor:\{joint_id}")
    }
  }
  for
    required in [
      "hip_swing_start_rad", "hip_swing_end_rad", "knee_base_rad", "knee_swing_lift_rad",
      "ankle_stance_start_rad", "ankle_stance_end_rad", "arm_phase_lag", "shoulder_hip_scale",
      "elbow_base_rad",
    ] {
    if !generated_moonrobo_noetix_joint_curve_params().any(fn(param) {
        param.name == required
      }) {
      blockers.push("moonrobo-walk-clip-missing-curve-param:\{required}")
    }
  }
  for sample in generated_moonrobo_noetix_authored_joint_samples() {
    if sample.left_knee_rad > 0.0 || sample.right_knee_rad > 0.0 {
      blockers.push("moonrobo-walk-clip-authored-knee-sign:\{sample.phase}")
    }
  }
  for sample in generated_moonrobo_noetix_authored_motion_samples() {
    if sample.left_foot_x_m < 0.0 || sample.right_foot_x_m > 0.0 {
      blockers.push("moonrobo-walk-clip-authored-foot-side:\{sample.phase}")
    }
  }
  for frame in generated_moonrobo_noetix_contact_frames() {
    if frame.contacts.length() != 2 {
      blockers.push("moonrobo-walk-clip-contact-count:\{frame.time_s}")
    }
    if !frame.contacts.any(fn(contact) { contact.footprint.active }) {
      blockers.push("moonrobo-walk-clip-contact-no-active-foot:\{frame.time_s}")
    }
    if frame.total_mass_kg <= 0.0 {
      blockers.push("moonrobo-walk-clip-contact-mass:\{frame.time_s}")
    }
  }
  for frame in generated_moonrobo_noetix_authored_motor_frames() {
    if frame.joint_count != noetix_required_driven_joint_ids().length() {
      blockers.push(
        "moonrobo-walk-clip-authored-motor-joint-count:\{frame.frame_index}",
      )
    }
    if frame.review_count > 0 || frame.status.contains("review") {
      blockers.push(
        "moonrobo-walk-clip-authored-motor-review:\{frame.frame_index}",
      )
    }
    for step in frame.steps {
      if !step.position_within_limits ||
        !step.velocity_within_limits ||
        step.torque_saturated {
        blockers.push(
          "moonrobo-walk-clip-authored-motor-step-review:\{frame.frame_index}:\{step.joint_id}",
        )
      }
    }
  }
  blockers
}

///|
pub fn moonrobo_noetix_suite_source_refs() -> Array[SuiteAdapterSourceRef] {
  let refs : Array[SuiteAdapterSourceRef] = []
  refs.push(generated_moonrobo_noetix_source_contract_ref())
  for source in generated_moonrobo_noetix_source_refs() {
    refs.push(source)
  }
  refs.push(
    noetix_suite_source_ref(
      "moonrobo-noetix-authored-contact-frames",
      "moonrobo.moonmoon-adapter-contact-evidence",
      generated_moonrobo_noetix_contact_frame_source(),
      "typed Moonrobo FK/contact evidence consumed by compiled Moonphys",
      "generated-from-typed-source",
    ),
  )
  refs.push(
    noetix_suite_source_ref(
      "rabbita-noetix-generated-ui-evidence",
      "moonmoon.rabbita.generated-evidence",
      generated_rabbita_noetix_evidence_source(),
      "browser visualization evidence and hinge replay freshness gate",
      "generated-ui-gate",
    ),
  )
  refs
}

///|
fn moonrobo_noetix_suite_payload_blockers(
  review_status : String,
  driven_joint_ids : Array[String],
  frame_count : Int,
) -> Array[String] {
  let blockers : Array[String] = []
  if !generated_moonrobo_noetix_source_ready() {
    blockers.push(
      "moonrobo-source-contract:\{generated_moonrobo_noetix_source_status()}",
    )
  }
  for blocker in generated_moonrobo_noetix_source_blockers() {
    blockers.push("moonrobo-source-contract-blocker:\{blocker}")
  }
  for blocker in moonrobo_noetix_source_contract_bridge_blockers() {
    blockers.push(blocker)
  }
  if review_status != "moonrobo-noetix-generated-review-ready" {
    blockers.push("compiled-review:\{review_status}")
  }
  if frame_count <= 0 {
    blockers.push("generated-motion:no-frames")
  }
  for missing in noetix_missing_required_driven_joint_ids(driven_joint_ids) {
    blockers.push("missing-driven-joint:\{missing}")
  }
  blockers
}

///|
pub fn moonrobo_noetix_suite_adapter_payload() -> NoetixSuiteAdapterPayload {
  let driven_joint_ids = noetix_generated_driven_joint_ids()
  let frame_count = generated_moonrobo_noetix_contact_frames().length()
  let review_status = compiled_moonphys_bridge_status()
  let blockers = moonrobo_noetix_suite_payload_blockers(
    review_status, driven_joint_ids, frame_count,
  )
  {
    payload_id: "\{generated_moonrobo_noetix_robot_id()}/rabbita-walk-cycle",
    robot_id: generated_moonrobo_noetix_robot_id(),
    robot_label: generated_moonrobo_noetix_robot_label(),
    platform: generated_moonrobo_noetix_platform(),
    profile_path: generated_moonrobo_noetix_profile_path(),
    urdf_path: generated_moonrobo_noetix_urdf_path(),
    mesh_paths: generated_moonrobo_noetix_mesh_paths(),
    evidence_source: generated_moonrobo_noetix_contact_frame_source(),
    motion_trace_id: generated_rabbita_noetix_motion_trace_id(),
    hinge_trace_id: generated_rabbita_noetix_hinge_trace_id(),
    combined_review_id: generated_rabbita_noetix_combined_review_id(),
    walk_clip_id: generated_moonrobo_noetix_walk_clip_id(),
    walk_clip_source: generated_moonrobo_noetix_walk_clip_source(),
    walk_cycle_hz: generated_moonrobo_noetix_walk_cycle_hz(),
    root_speed_mps: generated_moonrobo_noetix_root_speed_mps(),
    stride_m: generated_moonrobo_noetix_stride_m(),
    walk_sample_count: generated_moonrobo_noetix_walk_sample_count(),
    foot_phase_sequence: generated_moonrobo_noetix_foot_phase_sequence(),
    walk_phase_labels: generated_moonrobo_noetix_walk_phase_labels(),
    foot_phase_specs: generated_moonrobo_noetix_foot_phase_specs(),
    joint_anchors: generated_moonrobo_noetix_joint_anchors(),
    joint_curve_params: generated_moonrobo_noetix_joint_curve_params(),
    authored_joint_samples: generated_moonrobo_noetix_authored_joint_samples(),
    authored_motion_samples: generated_moonrobo_noetix_authored_motion_samples(),
    authored_motor_frames: generated_moonrobo_noetix_authored_motor_frames(),
    expected_profile_joint_count: noetix_expected_profile_joint_count(),
    driven_joint_ids,
    frame_count,
    source_refs: moonrobo_noetix_suite_source_refs(),
    review_status,
    blocker_count: blockers.length(),
    blockers,
    ready: blockers.is_empty(),
    status: if blockers.is_empty() {
      "moonrobo-noetix-suite-payload-ready"
    } else {
      "moonrobo-noetix-suite-payload-blocked"
    },
  }
}
