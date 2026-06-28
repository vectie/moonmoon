///|
pub(all) struct SuiteAdapterSourceRef {
  source_id : String
  source_family : String
  local_path : String
  role : String
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
fn noetix_expected_profile_joint_count() -> Int {
  24
}

///|
fn noetix_required_driven_joint_ids() -> Array[String] {
  [
    "leg_l1_joint", "leg_l4_joint", "leg_l6_joint", "leg_r1_joint", "leg_r4_joint",
    "leg_r6_joint", "arm_l1_joint", "arm_l4_joint", "arm_r1_joint", "arm_r4_joint",
  ]
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
pub fn moonrobo_noetix_suite_source_refs() -> Array[SuiteAdapterSourceRef] {
  [
    noetix_suite_source_ref(
      "moonrobo-noetix-e1-profile", "moonrobo.robot-profile", "../moonrobo/examples/noetix-e1/robot.json",
      "robot profile, bridge limits, capability contract", "referenced",
    ),
    noetix_suite_source_ref(
      "moonrobo-noetix-e1-urdf", "moonrobo.urdf", "../moonrobo/examples/noetix-e1/model/robot.urdf",
      "joint tree, axes, limits, and visual geometry references", "referenced",
    ),
    noetix_suite_source_ref(
      "moonrobo-noetix-e1-base-mesh", "moonrobo.mesh", "../moonrobo/examples/noetix-e1/model/meshes/base.obj",
      "base_link visual mesh attachment", "referenced",
    ),
    noetix_suite_source_ref(
      "rabbita-noetix-generated-gait",
      "moonmoon.rabbita.generated-evidence",
      generated_rabbita_noetix_evidence_source(),
      "sampled FK/contact/motor evidence consumed by compiled Moonphys",
      "generated",
    ),
  ]
}

///|
fn moonrobo_noetix_suite_payload_blockers(
  review_status : String,
  driven_joint_ids : Array[String],
  frame_count : Int,
) -> Array[String] {
  let blockers : Array[String] = []
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
    payload_id: "moonrobo-noetix-e1-lab-01/rabbita-walk-cycle",
    robot_id: "noetix-e1-lab-01",
    robot_label: "Noetix E1 Lab 01",
    platform: "noetix-e1",
    profile_path: "../moonrobo/examples/noetix-e1/robot.json",
    urdf_path: "../moonrobo/examples/noetix-e1/model/robot.urdf",
    mesh_paths: ["../moonrobo/examples/noetix-e1/model/meshes/base.obj"],
    evidence_source: generated_rabbita_noetix_evidence_source(),
    motion_trace_id: generated_rabbita_noetix_motion_trace_id(),
    hinge_trace_id: generated_rabbita_noetix_hinge_trace_id(),
    combined_review_id: generated_rabbita_noetix_combined_review_id(),
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
