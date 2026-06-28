///|
pub fn compiled_moonphys_bridge_environment_id() -> String {
  @moonphys.lunar_environment().environment_id
}

///|
pub fn compiled_moonphys_bridge_status() -> String {
  let ui_motion_frames = generated_rabbita_noetix_motion_frames()
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
  if ui_motion_frames.length() == 24 &&
    ui_hinge_frames.length() == 24 &&
    ui_hinge_gate &&
    ui_motion_frames[0].time_s == 0.0 &&
    ui_motion_frames[0].phase_label == "left-stance-right-swing" &&
    ui_motion_frames[0].support_foot == "left" &&
    ui_hinge_frames[0].time_s == 0.0 &&
    hinge.status == "world-heightfield-hinge-motor-trace-driven" &&
    hinge.review_count == 0 &&
    motion.ready &&
    replay.ready &&
    review.ready &&
    review.status == "motion-hinge-replay-review-ready" {
    "rabbita-noetix-generated-review-ready"
  } else if ui_motion_frames.length() == 24 &&
    ui_hinge_frames.length() == 24 &&
    ui_hinge_gate &&
    hinge.status == "world-heightfield-hinge-motor-trace-driven" &&
    hinge.review_count == 0 &&
    !review.ready &&
    review.status == "motion-hinge-replay-review-blocked" {
    "rabbita-noetix-generated-review-blocked"
  } else {
    "rabbita-noetix-generated-review-mismatch"
  }
}
