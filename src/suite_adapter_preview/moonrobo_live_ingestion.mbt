///|
priv struct SuiteAdapterLiveNoetixVec3 {
  x : Double
  y : Double
  z : Double
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixFootprint {
  footprint_id : String
  center : SuiteAdapterLiveNoetixVec3
  half_length_m : Double
  half_width_m : Double
  active : Bool
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixContactProbe {
  probe_id : String
  position : SuiteAdapterLiveNoetixVec3
  surface_elevation_m : Double
  surface_normal : SuiteAdapterLiveNoetixVec3
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixContactPatch {
  patch_id : String
  center : SuiteAdapterLiveNoetixVec3
  half_length_m : Double
  half_width_m : Double
  sample_count : Int
  contact_count : Int
  min_clearance_m : Double
  max_clearance_m : Double
  average_surface_elevation_m : Double
  average_surface_normal : SuiteAdapterLiveNoetixVec3
  samples : Array[SuiteAdapterLiveNoetixContactProbe]
  status : String
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixContact {
  contact_id : String
  footprint : SuiteAdapterLiveNoetixFootprint
  patch : SuiteAdapterLiveNoetixContactPatch
  applied_force_n : SuiteAdapterLiveNoetixVec3
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixContactFrame {
  frame_index : Int
  time_s : Double
  phase : Double
  phase_label : String
  support_foot : String
  review_id : String
  center_of_mass : SuiteAdapterLiveNoetixVec3
  center_of_mass_velocity : SuiteAdapterLiveNoetixVec3
  total_mass_kg : Double
  contact_count : Int
  active_footprint_count : Int
  contacts : Array[SuiteAdapterLiveNoetixContact]
  status : String
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixWalkClip {
  clip_id : String
  source : String
  cycle_hz : Double
  root_speed_mps : Double
  stride_m : Double
  sample_count : Int
  foot_phase_sequence : Array[String]
  phase_labels : Array[String]
  foot_phase_specs : Array[SuiteAdapterFootPhaseSpec]
  required_joint_ids : Array[String]
  joint_anchors : Array[SuiteAdapterJointAnchor]
  joint_curve_params : Array[SuiteAdapterJointCurveParam]
  authored_joint_samples : Array[SuiteAdapterAuthoredJointSample]
  authored_motion_samples : Array[SuiteAdapterAuthoredMotionSample]
  authored_contact_frames : Array[SuiteAdapterLiveNoetixContactFrame]
  authored_motor_frames : Array[SuiteAdapterMotorFrameSample]
  blocker_count : Int
  blockers : Array[String]
  ready : Bool
  status : String
} derive(ToJson, FromJson)

///|
priv struct SuiteAdapterLiveNoetixContract {
  contract_id : String
  target_payload_type : String
  robot_id : String
  robot_label : String
  platform : String
  profile_path : String
  urdf_path : String
  mesh_paths : Array[String]
  expected_profile_joint_count : Int
  profile_joint_ids : Array[String]
  required_motion_joint_ids : Array[String]
  walk_clip : SuiteAdapterLiveNoetixWalkClip
  source_refs : Array[SuiteAdapterSourceRef]
  blocker_count : Int
  blockers : Array[String]
  ready : Bool
  status : String
} derive(ToJson, FromJson)

///|
fn moonrobo_noetix_prefixed_path(path : String) -> String {
  if path.contains("../moonrobo/") {
    path
  } else {
    "../moonrobo/\{path}"
  }
}

///|
fn live_vec3_to_generated(
  value : SuiteAdapterLiveNoetixVec3,
) -> RabbitaNoetixGeneratedVec3 {
  { x: value.x, y: value.y, z: value.z }
}

///|
fn generated_vec3_to_live(
  value : RabbitaNoetixGeneratedVec3,
) -> SuiteAdapterLiveNoetixVec3 {
  { x: value.x, y: value.y, z: value.z }
}

///|
fn live_footprint_to_generated(
  value : SuiteAdapterLiveNoetixFootprint,
) -> RabbitaNoetixGeneratedFootprint {
  {
    footprint_id: value.footprint_id,
    center: live_vec3_to_generated(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    active: value.active,
  }
}

///|
fn generated_footprint_to_live(
  value : RabbitaNoetixGeneratedFootprint,
) -> SuiteAdapterLiveNoetixFootprint {
  {
    footprint_id: value.footprint_id,
    center: generated_vec3_to_live(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    active: value.active,
  }
}

///|
fn live_contact_probe_to_generated(
  value : SuiteAdapterLiveNoetixContactProbe,
) -> RabbitaNoetixGeneratedContactProbe {
  {
    probe_id: value.probe_id,
    position: live_vec3_to_generated(value.position),
    surface_elevation_m: value.surface_elevation_m,
    surface_normal: live_vec3_to_generated(value.surface_normal),
    clearance_m: value.clearance_m,
    in_contact: value.in_contact,
    local_grade: value.local_grade,
    status: value.status,
  }
}

///|
fn generated_contact_probe_to_live(
  value : RabbitaNoetixGeneratedContactProbe,
) -> SuiteAdapterLiveNoetixContactProbe {
  {
    probe_id: value.probe_id,
    position: generated_vec3_to_live(value.position),
    surface_elevation_m: value.surface_elevation_m,
    surface_normal: generated_vec3_to_live(value.surface_normal),
    clearance_m: value.clearance_m,
    in_contact: value.in_contact,
    local_grade: value.local_grade,
    status: value.status,
  }
}

///|
fn live_contact_patch_to_generated(
  value : SuiteAdapterLiveNoetixContactPatch,
) -> RabbitaNoetixGeneratedContactPatch {
  {
    patch_id: value.patch_id,
    center: live_vec3_to_generated(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    sample_count: value.sample_count,
    contact_count: value.contact_count,
    min_clearance_m: value.min_clearance_m,
    max_clearance_m: value.max_clearance_m,
    average_surface_elevation_m: value.average_surface_elevation_m,
    average_surface_normal: live_vec3_to_generated(value.average_surface_normal),
    samples: value.samples.map(live_contact_probe_to_generated),
    status: value.status,
  }
}

///|
fn generated_contact_patch_to_live(
  value : RabbitaNoetixGeneratedContactPatch,
) -> SuiteAdapterLiveNoetixContactPatch {
  {
    patch_id: value.patch_id,
    center: generated_vec3_to_live(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    sample_count: value.sample_count,
    contact_count: value.contact_count,
    min_clearance_m: value.min_clearance_m,
    max_clearance_m: value.max_clearance_m,
    average_surface_elevation_m: value.average_surface_elevation_m,
    average_surface_normal: generated_vec3_to_live(value.average_surface_normal),
    samples: value.samples.map(generated_contact_probe_to_live),
    status: value.status,
  }
}

///|
fn live_contact_to_generated(
  value : SuiteAdapterLiveNoetixContact,
) -> RabbitaNoetixGeneratedContact {
  {
    contact_id: value.contact_id,
    footprint: live_footprint_to_generated(value.footprint),
    patch: live_contact_patch_to_generated(value.patch),
    applied_force_n: live_vec3_to_generated(value.applied_force_n),
  }
}

///|
fn generated_contact_to_live(
  value : RabbitaNoetixGeneratedContact,
) -> SuiteAdapterLiveNoetixContact {
  {
    contact_id: value.contact_id,
    footprint: generated_footprint_to_live(value.footprint),
    patch: generated_contact_patch_to_live(value.patch),
    applied_force_n: generated_vec3_to_live(value.applied_force_n),
  }
}

///|
fn live_contact_frame_to_generated(
  value : SuiteAdapterLiveNoetixContactFrame,
) -> RabbitaNoetixGeneratedMotionFrame {
  {
    time_s: value.time_s,
    phase_label: value.phase_label,
    support_foot: value.support_foot,
    review_id: value.review_id,
    center_of_mass: live_vec3_to_generated(value.center_of_mass),
    center_of_mass_velocity: live_vec3_to_generated(
      value.center_of_mass_velocity,
    ),
    total_mass_kg: value.total_mass_kg,
    contacts: value.contacts.map(live_contact_to_generated),
  }
}

///|
fn generated_contact_frame_to_live(
  frame_index : Int,
  sample_count : Int,
  value : RabbitaNoetixGeneratedMotionFrame,
) -> SuiteAdapterLiveNoetixContactFrame {
  let active_footprint_count = value.contacts.fold(init=0, fn(count, contact) {
    if contact.footprint.active {
      count + 1
    } else {
      count
    }
  })
  {
    frame_index,
    time_s: value.time_s,
    phase: frame_index.to_double() / sample_count.to_double(),
    phase_label: value.phase_label,
    support_foot: value.support_foot,
    review_id: value.review_id,
    center_of_mass: generated_vec3_to_live(value.center_of_mass),
    center_of_mass_velocity: generated_vec3_to_live(
      value.center_of_mass_velocity,
    ),
    total_mass_kg: value.total_mass_kg,
    contact_count: value.contacts.length(),
    active_footprint_count,
    contacts: value.contacts.map(generated_contact_to_live),
    status: "moonrobo-live-contact-frame-ready",
  }
}

///|
fn live_contact_frames_for_review(
  frames : Array[SuiteAdapterLiveNoetixContactFrame],
) -> Array[RabbitaNoetixGeneratedMotionFrame] {
  frames.map(live_contact_frame_to_generated)
}

///|
fn live_contract_evidence_source() -> String {
  "../moonrobo/src/moonmoon_adapter/noetix_live_suite_evidence.mbt#noetix_e1_moonmoon_live_suite_evidence"
}

///|
fn live_contract_contact_frame_source(
  contract : SuiteAdapterLiveNoetixContract,
) -> String {
  "\{contract.walk_clip.source}#authored_contact_frames"
}

///|
fn live_contract_driven_joint_ids(
  contract : SuiteAdapterLiveNoetixContract,
) -> Array[String] {
  let ids : Array[String] = []
  let frames = contract.walk_clip.authored_motor_frames
  if frames.length() > 0 {
    for step in frames[0].steps {
      ids.push(step.joint_id)
    }
  }
  ids
}

///|
fn live_contract_missing_required_driven_joint_ids(
  contract : SuiteAdapterLiveNoetixContract,
  driven : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for joint_id in contract.required_motion_joint_ids {
    if !driven.contains(joint_id) {
      missing.push(joint_id)
    }
  }
  missing
}

///|
fn live_contract_evidence(
  contract : SuiteAdapterLiveNoetixContract,
) -> SuiteAdapterLiveSuiteEvidence {
  let clip = contract.walk_clip
  let blockers : Array[String] = []
  if !contract.ready {
    blockers.push("contract:\{contract.status}")
  }
  for blocker in contract.blockers {
    blockers.push("contract-blocker:\{blocker}")
  }
  if !clip.ready {
    blockers.push("walk-clip:\{clip.status}")
  }
  for blocker in clip.blockers {
    blockers.push("walk-clip-blocker:\{blocker}")
  }
  if clip.authored_joint_samples.length() != clip.sample_count {
    blockers.push("authored-joint-sample-count")
  }
  if clip.authored_motion_samples.length() != clip.sample_count {
    blockers.push("authored-motion-sample-count")
  }
  if clip.authored_contact_frames.length() != clip.sample_count {
    blockers.push("authored-contact-frame-count")
  }
  if clip.authored_motor_frames.length() != clip.sample_count {
    blockers.push("authored-motor-frame-count")
  }
  let mut active_contact_frame_count = 0
  let mut loaded_contact_count = 0
  let mut contact_review_count = 0
  for frame in clip.authored_contact_frames {
    if frame.active_footprint_count > 0 {
      active_contact_frame_count += 1
    }
    if frame.status.contains("review") {
      contact_review_count += 1
      blockers.push("contact-frame-review:\{frame.frame_index}")
    }
    for contact in frame.contacts {
      if contact.footprint.active && contact.applied_force_n.z > 0.0 {
        loaded_contact_count += 1
      }
    }
  }
  let mut driven_motor_frame_count = 0
  let mut motor_review_count = 0
  for frame in clip.authored_motor_frames {
    if frame.driven_joint_count > 0 {
      driven_motor_frame_count += 1
    }
    motor_review_count += frame.review_count
    if frame.status.contains("review") {
      motor_review_count += 1
    }
    if frame.review_count > 0 || frame.status.contains("review") {
      blockers.push("motor-frame-review:\{frame.frame_index}")
    }
  }
  {
    evidence_id: "\{contract.robot_id}/moonmoon-live-suite-evidence",
    regeneration_mode: "live-moonrobo-typed-adapter",
    contract_id: contract.contract_id,
    robot_id: contract.robot_id,
    walk_clip_id: clip.clip_id,
    source: "vectie/moonrobo/src/moonmoon_adapter#noetix_e1_moonmoon_live_suite_evidence",
    sample_count: clip.sample_count,
    profile_joint_count: contract.profile_joint_ids.length(),
    required_motion_joint_count: contract.required_motion_joint_ids.length(),
    authored_joint_sample_count: clip.authored_joint_samples.length(),
    authored_motion_sample_count: clip.authored_motion_samples.length(),
    authored_contact_frame_count: clip.authored_contact_frames.length(),
    authored_motor_frame_count: clip.authored_motor_frames.length(),
    active_contact_frame_count,
    loaded_contact_count,
    driven_motor_frame_count,
    motor_review_count,
    contact_review_count,
    blocker_count: blockers.length(),
    blockers,
    ready: blockers.is_empty(),
    status: if blockers.is_empty() {
      "moonmoon-noetix-live-suite-evidence-ready"
    } else {
      "moonmoon-noetix-live-suite-evidence-blocked"
    },
  }
}

///|
fn live_contract_review_status(
  contract : SuiteAdapterLiveNoetixContract,
) -> String {
  let clip = contract.walk_clip
  if clip.authored_contact_frames.length() == 0 ||
    clip.authored_motor_frames.length() == 0 {
    return "moonrobo-noetix-live-review-missing-frames"
  }
  let contact_frames = live_contact_frames_for_review(
    clip.authored_contact_frames,
  )
  let field = @moonphys.heightfield(
    "moonrobo-noetix-live-flat-field",
    1,
    1,
    1.0,
    [0.0],
  )
  let motion = rabbita_noetix_motion_trace_review_from_contact_frames(
    "\{contract.robot_id}/live-motion-trace",
    contact_frames,
  )
  let hinge = rabbita_noetix_hinge_trace_from_motor_frames(
    "\{contract.robot_id}/live-hinge-trace",
    field,
    clip.authored_motor_frames,
    live_contract_contact_frame_source(contract),
  )
  let replay = rabbita_noetix_replay_review_from_contact_frames(
    hinge, contact_frames,
  )
  let review = @moonphys.motion_hinge_replay_review_with_replay(
    "\{contract.robot_id}/live-motion-hinge-review",
    motion,
    hinge,
    replay,
  )
  if clip.authored_contact_frames.length() == clip.sample_count &&
    clip.authored_motor_frames.length() == clip.sample_count &&
    hinge.status == "world-heightfield-hinge-motor-trace-driven" &&
    hinge.review_count == 0 &&
    motion.ready &&
    replay.ready &&
    review.ready &&
    review.status == "motion-hinge-replay-review-ready" {
    "moonrobo-noetix-live-review-ready"
  } else if !review.ready &&
    review.status == "motion-hinge-replay-review-blocked" {
    "moonrobo-noetix-live-review-blocked"
  } else {
    "moonrobo-noetix-live-review-mismatch"
  }
}

///|
fn live_contract_source_refs(
  contract : SuiteAdapterLiveNoetixContract,
) -> Array[SuiteAdapterSourceRef] {
  let refs : Array[SuiteAdapterSourceRef] = []
  refs.push(
    noetix_suite_source_ref(
      "moonrobo-noetix-e1-moonmoon-contract", "moonrobo.moonmoon-adapter-contract",
      "../moonrobo/src/moonmoon_adapter/noetix_contract.mbt#noetix_e1_moonmoon_locomotion_contract",
      "live Moonrobo source contract used to ingest Moonmoon suite evidence", "live-typed-source",
    ),
  )
  for source in contract.source_refs {
    refs.push(
      noetix_suite_source_ref(
        source.source_id,
        source.source_family,
        moonrobo_noetix_prefixed_path(source.local_path),
        source.role,
        source.status,
      ),
    )
  }
  refs.push(
    noetix_suite_source_ref(
      "moonrobo-noetix-authored-contact-frames",
      "moonrobo.moonmoon-adapter-contact-evidence",
      live_contract_contact_frame_source(contract),
      "live Moonrobo FK/contact evidence consumed by compiled Moonphys",
      "live-typed-source",
    ),
  )
  refs.push(
    noetix_suite_source_ref(
      "moonrobo-noetix-live-suite-evidence",
      "moonrobo.moonmoon-live-suite-evidence",
      live_contract_evidence_source(),
      "live Moonrobo typed adapter suite evidence ingested by Moonmoon",
      "live-typed-source",
    ),
  )
  refs
}

///|
fn live_contract_payload_blockers(
  contract : SuiteAdapterLiveNoetixContract,
  evidence : SuiteAdapterLiveSuiteEvidence,
  review_status : String,
  driven_joint_ids : Array[String],
) -> Array[String] {
  let blockers : Array[String] = []
  if contract.target_payload_type !=
    "vectie/moonmoon/src/suite_adapter_preview.NoetixSuiteAdapterPayload" {
    blockers.push(
      "moonrobo-live-contract-target:\{contract.target_payload_type}",
    )
  }
  if contract.profile_joint_ids.length() !=
    contract.expected_profile_joint_count {
    blockers.push(
      "moonrobo-live-contract-profile-joint-count:\{contract.profile_joint_ids.length()}",
    )
  }
  for
    missing in live_contract_missing_required_driven_joint_ids(
      contract, driven_joint_ids,
    ) {
    blockers.push("missing-driven-joint:\{missing}")
  }
  if !evidence.ready {
    blockers.push("moonrobo-live-suite-evidence:\{evidence.status}")
  }
  for blocker in evidence.blockers {
    blockers.push("moonrobo-live-suite-blocker:\{blocker}")
  }
  if review_status != "moonrobo-noetix-live-review-ready" {
    blockers.push("compiled-live-review:\{review_status}")
  }
  blockers
}

///|
fn moonrobo_noetix_suite_adapter_payload_from_live_contract(
  contract : SuiteAdapterLiveNoetixContract,
) -> NoetixSuiteAdapterPayload {
  let evidence = live_contract_evidence(contract)
  let driven_joint_ids = live_contract_driven_joint_ids(contract)
  let review_status = live_contract_review_status(contract)
  let blockers = live_contract_payload_blockers(
    contract, evidence, review_status, driven_joint_ids,
  )
  let clip = contract.walk_clip
  {
    payload_id: "\{contract.robot_id}/rabbita-walk-cycle",
    robot_id: contract.robot_id,
    robot_label: contract.robot_label,
    platform: contract.platform,
    profile_path: moonrobo_noetix_prefixed_path(contract.profile_path),
    urdf_path: moonrobo_noetix_prefixed_path(contract.urdf_path),
    mesh_paths: contract.mesh_paths.map(moonrobo_noetix_prefixed_path),
    evidence_source: live_contract_contact_frame_source(contract),
    motion_trace_id: "\{contract.robot_id}/live-motion-trace",
    hinge_trace_id: "\{contract.robot_id}/live-hinge-trace",
    combined_review_id: "\{contract.robot_id}/live-motion-hinge-review",
    walk_clip_id: clip.clip_id,
    walk_clip_source: clip.source,
    walk_cycle_hz: clip.cycle_hz,
    root_speed_mps: clip.root_speed_mps,
    stride_m: clip.stride_m,
    walk_sample_count: clip.sample_count,
    foot_phase_sequence: clip.foot_phase_sequence,
    walk_phase_labels: clip.phase_labels,
    foot_phase_specs: clip.foot_phase_specs,
    joint_anchors: clip.joint_anchors,
    joint_curve_params: clip.joint_curve_params,
    authored_joint_samples: clip.authored_joint_samples,
    authored_motion_samples: clip.authored_motion_samples,
    authored_motor_frames: clip.authored_motor_frames,
    live_suite_evidence: evidence,
    expected_profile_joint_count: contract.expected_profile_joint_count,
    driven_joint_ids,
    frame_count: clip.authored_contact_frames.length(),
    source_refs: live_contract_source_refs(contract),
    review_status,
    blocker_count: blockers.length(),
    blockers,
    ready: blockers.is_empty(),
    status: if blockers.is_empty() {
      "moonrobo-noetix-live-suite-payload-ready"
    } else {
      "moonrobo-noetix-live-suite-payload-blocked"
    },
  }
}

///|
pub fn moonrobo_noetix_suite_adapter_payload_from_live_json(
  json : Json,
) -> NoetixSuiteAdapterPayload raise {
  let contract : SuiteAdapterLiveNoetixContract = @json.from_json(json)
  moonrobo_noetix_suite_adapter_payload_from_live_contract(contract)
}

///|
pub fn moonrobo_noetix_suite_adapter_payload_from_live_json_text(
  text : String,
) -> NoetixSuiteAdapterPayload raise {
  moonrobo_noetix_suite_adapter_payload_from_live_json(@json.parse(text))
}

///|
fn generated_live_contract_contact_frames() -> Array[
  SuiteAdapterLiveNoetixContactFrame,
] {
  let frames : Array[SuiteAdapterLiveNoetixContactFrame] = []
  let source = generated_moonrobo_noetix_contact_frames()
  let sample_count = generated_moonrobo_noetix_walk_sample_count()
  for index, frame in source {
    frames.push(generated_contact_frame_to_live(index, sample_count, frame))
  }
  frames
}

///|
fn moonrobo_noetix_generated_live_contract_fixture() -> SuiteAdapterLiveNoetixContract {
  {
    contract_id: generated_moonrobo_noetix_contract_id(),
    target_payload_type: generated_moonrobo_noetix_target_payload_type(),
    robot_id: generated_moonrobo_noetix_robot_id(),
    robot_label: generated_moonrobo_noetix_robot_label(),
    platform: generated_moonrobo_noetix_platform(),
    profile_path: generated_moonrobo_noetix_profile_path(),
    urdf_path: generated_moonrobo_noetix_urdf_path(),
    mesh_paths: generated_moonrobo_noetix_mesh_paths(),
    expected_profile_joint_count: generated_moonrobo_noetix_expected_profile_joint_count(),
    profile_joint_ids: generated_moonrobo_noetix_profile_joint_ids(),
    required_motion_joint_ids: generated_moonrobo_noetix_required_motion_joint_ids(),
    walk_clip: {
      clip_id: generated_moonrobo_noetix_walk_clip_id(),
      source: generated_moonrobo_noetix_walk_clip_source(),
      cycle_hz: generated_moonrobo_noetix_walk_cycle_hz(),
      root_speed_mps: generated_moonrobo_noetix_root_speed_mps(),
      stride_m: generated_moonrobo_noetix_stride_m(),
      sample_count: generated_moonrobo_noetix_walk_sample_count(),
      foot_phase_sequence: generated_moonrobo_noetix_foot_phase_sequence(),
      phase_labels: generated_moonrobo_noetix_walk_phase_labels(),
      foot_phase_specs: generated_moonrobo_noetix_foot_phase_specs(),
      required_joint_ids: generated_moonrobo_noetix_required_motion_joint_ids(),
      joint_anchors: generated_moonrobo_noetix_joint_anchors(),
      joint_curve_params: generated_moonrobo_noetix_joint_curve_params(),
      authored_joint_samples: generated_moonrobo_noetix_authored_joint_samples(),
      authored_motion_samples: generated_moonrobo_noetix_authored_motion_samples(),
      authored_contact_frames: generated_live_contract_contact_frames(),
      authored_motor_frames: generated_moonrobo_noetix_authored_motor_frames(),
      blocker_count: generated_moonrobo_noetix_walk_clip_blockers().length(),
      blockers: generated_moonrobo_noetix_walk_clip_blockers(),
      ready: generated_moonrobo_noetix_walk_clip_ready(),
      status: generated_moonrobo_noetix_walk_clip_status(),
    },
    source_refs: generated_moonrobo_noetix_source_refs(),
    blocker_count: generated_moonrobo_noetix_source_blockers().length(),
    blockers: generated_moonrobo_noetix_source_blockers(),
    ready: generated_moonrobo_noetix_source_ready(),
    status: generated_moonrobo_noetix_source_status(),
  }
}

///|
pub fn moonrobo_noetix_suite_adapter_payload_from_generated_live_contract() -> NoetixSuiteAdapterPayload raise {
  moonrobo_noetix_suite_adapter_payload_from_live_json(
    moonrobo_noetix_generated_live_contract_fixture().to_json(),
  )
}
