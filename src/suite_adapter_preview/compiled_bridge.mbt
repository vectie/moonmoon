///|
pub fn compiled_moonphys_bridge_environment_id() -> String {
  @moonphys.lunar_environment().environment_id
}

///|
pub fn compiled_moonphys_bridge_status() -> String {
  let motion_frames = generated_moonrobo_noetix_contact_frames()
  let ui_motion_frames = generated_rabbita_noetix_motion_frames()
  let hinge_frames = generated_moonrobo_noetix_authored_motor_frames()
  let ui_hinge_frames = generated_rabbita_noetix_hinge_frames()
  let ui_hinge_gate = generated_rabbita_noetix_hinge_ui_gate()
  let field = @moonphys.heightfield(
    "rabbita-noetix-generated-flat-field",
    1,
    1,
    1.0,
    [0.0],
  )
  let motion = rabbita_noetix_generated_motion_trace_review()
  let hinge = rabbita_noetix_generated_hinge_trace(field)
  let replay = rabbita_noetix_generated_replay_review(hinge)
  let review = @moonphys.motion_hinge_replay_review_with_replay(
    generated_rabbita_noetix_combined_review_id(),
    motion,
    hinge,
    replay,
  )
  if motion_frames.length() == 24 &&
    ui_motion_frames.length() == 24 &&
    hinge_frames.length() == 24 &&
    ui_hinge_frames.length() == 24 &&
    ui_hinge_gate &&
    motion_frames[0].time_s == 0.0 &&
    motion_frames[0].phase_label == "left-stance-right-swing" &&
    motion_frames[0].support_foot == "left" &&
    hinge_frames[0].time_s == 0.0 &&
    ui_hinge_frames[0].time_s == 0.0 &&
    hinge.status == "world-heightfield-hinge-motor-trace-driven" &&
    hinge.review_count == 0 &&
    motion.ready &&
    replay.ready &&
    review.ready &&
    review.status == "motion-hinge-replay-review-ready" {
    "moonrobo-noetix-generated-review-ready"
  } else if motion_frames.length() == 24 &&
    ui_motion_frames.length() == 24 &&
    hinge_frames.length() == 24 &&
    ui_hinge_frames.length() == 24 &&
    ui_hinge_gate &&
    hinge.status == "world-heightfield-hinge-motor-trace-driven" &&
    hinge.review_count == 0 &&
    !review.ready &&
    review.status == "motion-hinge-replay-review-blocked" {
    "moonrobo-noetix-generated-review-blocked"
  } else {
    "moonrobo-noetix-generated-review-mismatch"
  }
}
