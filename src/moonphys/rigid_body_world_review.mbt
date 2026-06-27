///|
pub(all) struct RigidBodyWorldReplayReview {
  trace_id : String
  frame_count : Int
  body_count : Int
  contact_count : Int
  review_count : Int
  envelope_status : String
  support_status : String
  dynamic_support_status : String
  body_sample_count : Int
  resolved_hinge_constraint_count : Int
  min_position : Vec3
  max_position : Vec3
  max_speed_mps : Double
  max_kinetic_energy_j : Double
  max_body_linear_momentum_kg_mps : Double
  max_world_linear_momentum_kg_mps : Double
  max_frame_kinetic_energy_delta_j : Double
  total_mass_kg : Double
  initial_center_of_mass : Vec3
  final_center_of_mass : Vec3
  min_center_of_mass : Vec3
  max_center_of_mass : Vec3
  max_center_of_mass_speed_mps : Double
  support_contact_count : Int
  stable_support_frame_count : Int
  support_review_frame_count : Int
  min_support_margin_m : Double
  max_center_of_pressure_error_m : Double
  capture_stable_frame_count : Int
  capture_review_frame_count : Int
  worst_capture_margin_m : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn rigid_body_world_replay_review_status(
  envelope : RigidBodyWorldTraceEnvelope,
  support : RigidBodyWorldSupportTrace,
  dynamic_support : RigidBodyWorldDynamicSupportTrace,
) -> String {
  if envelope.status.contains("empty") ||
    support.status.contains("empty") ||
    dynamic_support.status.contains("empty") {
    "world-replay-review-empty"
  } else if envelope.status.contains("review") ||
    support.review_frame_count > 0 ||
    dynamic_support.review_frame_count > 0 {
    "world-replay-review-blocked"
  } else {
    "world-replay-review-ready"
  }
}

///|
pub fn rigid_body_world_replay_review(
  envelope : RigidBodyWorldTraceEnvelope,
  support : RigidBodyWorldSupportTrace,
  dynamic_support : RigidBodyWorldDynamicSupportTrace,
) -> RigidBodyWorldReplayReview {
  let review_count = envelope.review_count +
    support.review_frame_count +
    dynamic_support.review_frame_count
  {
    trace_id: envelope.trace_id,
    frame_count: envelope.frame_count,
    body_count: envelope.body_count,
    contact_count: envelope.contact_count,
    review_count,
    envelope_status: envelope.status,
    support_status: support.status,
    dynamic_support_status: dynamic_support.status,
    body_sample_count: envelope.body_sample_count,
    resolved_hinge_constraint_count: envelope.resolved_hinge_constraint_count,
    min_position: envelope.min_position,
    max_position: envelope.max_position,
    max_speed_mps: envelope.max_speed_mps,
    max_kinetic_energy_j: envelope.max_kinetic_energy_j,
    max_body_linear_momentum_kg_mps: envelope.max_body_linear_momentum_kg_mps,
    max_world_linear_momentum_kg_mps: envelope.max_world_linear_momentum_kg_mps,
    max_frame_kinetic_energy_delta_j: envelope.max_frame_kinetic_energy_delta_j,
    total_mass_kg: envelope.total_mass_kg,
    initial_center_of_mass: envelope.initial_center_of_mass,
    final_center_of_mass: envelope.final_center_of_mass,
    min_center_of_mass: envelope.min_center_of_mass,
    max_center_of_mass: envelope.max_center_of_mass,
    max_center_of_mass_speed_mps: envelope.max_center_of_mass_speed_mps,
    support_contact_count: support.contact_count,
    stable_support_frame_count: support.stable_frame_count,
    support_review_frame_count: support.review_frame_count,
    min_support_margin_m: support.min_planar_margin_m,
    max_center_of_pressure_error_m: support.max_center_of_pressure_error_m,
    capture_stable_frame_count: dynamic_support.capture_stable_frame_count,
    capture_review_frame_count: dynamic_support.review_frame_count,
    worst_capture_margin_m: dynamic_support.worst_capture_margin_m,
    status: rigid_body_world_replay_review_status(
      envelope, support, dynamic_support,
    ),
  }
}

///|
pub fn rigid_body_heightfield_world_replay_review(
  trace : RigidBodyHeightfieldWorldTrace,
) -> RigidBodyWorldReplayReview {
  rigid_body_world_replay_review(
    rigid_body_heightfield_world_trace_envelope(trace),
    rigid_body_heightfield_world_support_trace(trace),
    rigid_body_heightfield_world_dynamic_support_trace(trace),
  )
}

///|
pub fn rigid_body_heightfield_world_hinge_motor_replay_review(
  trace : RigidBodyHeightfieldWorldHingeMotorTrace,
) -> RigidBodyWorldReplayReview {
  rigid_body_world_replay_review(
    rigid_body_heightfield_world_hinge_motor_trace_envelope(trace),
    rigid_body_heightfield_world_hinge_motor_support_trace(trace),
    rigid_body_heightfield_world_hinge_motor_dynamic_support_trace(trace),
  )
}
