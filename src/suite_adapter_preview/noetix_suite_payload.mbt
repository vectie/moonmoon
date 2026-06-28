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
  let frames = generated_rabbita_noetix_hinge_frames()
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
      "rabbita-noetix-generated-gait",
      "moonmoon.rabbita.generated-evidence",
      generated_rabbita_noetix_evidence_source(),
      "sampled FK/contact/motor evidence consumed by compiled Moonphys",
      "generated",
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
  if review_status != "rabbita-noetix-generated-review-ready" {
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
  let frame_count = generated_rabbita_noetix_motion_frames().length()
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
    evidence_source: generated_rabbita_noetix_evidence_source(),
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
