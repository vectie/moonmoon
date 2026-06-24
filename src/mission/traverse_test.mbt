///|
test "first trusted square traverse score requires operator review" {
  let score = @mission.first_trusted_square_traverse_score()
  assert_true(score.decision == Review)
  assert_eq(score.profile.profile_id, "conservative-lunar-rover-v1")
  assert_true(score.score < 70)
  assert_true(score.reasons.any(fn(reason) { reason.contains("confidence") }))
  assert_eq(@mission.traverse_decision_label(score.decision), "review")
}
