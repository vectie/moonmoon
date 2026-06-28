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
pub(all) struct SuiteAdapterVec3Sample {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterFootprintSample {
  footprint_id : String
  center : SuiteAdapterVec3Sample
  half_length_m : Double
  half_width_m : Double
  active : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterContactProbeSample {
  probe_id : String
  position : SuiteAdapterVec3Sample
  surface_elevation_m : Double
  surface_normal : SuiteAdapterVec3Sample
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterContactPatchSample {
  patch_id : String
  center : SuiteAdapterVec3Sample
  half_length_m : Double
  half_width_m : Double
  sample_count : Int
  contact_count : Int
  min_clearance_m : Double
  max_clearance_m : Double
  average_surface_elevation_m : Double
  average_surface_normal : SuiteAdapterVec3Sample
  samples : Array[SuiteAdapterContactProbeSample]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterContactEvidenceSample {
  contact_id : String
  footprint : SuiteAdapterFootprintSample
  patch : SuiteAdapterContactPatchSample
  applied_force_n : SuiteAdapterVec3Sample
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SuiteAdapterContactFrameSample {
  frame_index : Int
  time_s : Double
  phase : Double
  phase_label : String
  support_foot : String
  review_id : String
  center_of_mass : SuiteAdapterVec3Sample
  center_of_mass_velocity : SuiteAdapterVec3Sample
  total_mass_kg : Double
  contact_count : Int
  active_footprint_count : Int
  contacts : Array[SuiteAdapterContactEvidenceSample]
  status : String
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
pub(all) struct SuiteAdapterLiveSuiteEvidence {
  evidence_id : String
  regeneration_mode : String
  contract_id : String
  robot_id : String
  walk_clip_id : String
  source : String
  sample_count : Int
  profile_joint_count : Int
  required_motion_joint_count : Int
  authored_joint_sample_count : Int
  authored_motion_sample_count : Int
  authored_contact_frame_count : Int
  authored_motor_frame_count : Int
  active_contact_frame_count : Int
  loaded_contact_count : Int
  driven_motor_frame_count : Int
  motor_review_count : Int
  contact_review_count : Int
  blocker_count : Int
  blockers : Array[String]
  ready : Bool
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
  authored_contact_frames : Array[SuiteAdapterContactFrameSample]
  authored_motor_frames : Array[SuiteAdapterMotorFrameSample]
  live_suite_evidence : SuiteAdapterLiveSuiteEvidence
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
