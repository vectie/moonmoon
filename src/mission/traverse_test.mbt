///|
test "first trusted square traverse score blocks measured rough terrain" {
  let score = @mission.first_trusted_square_traverse_score()
  assert_true(score.decision == Block)
  assert_eq(score.profile.profile_id, "conservative-lunar-rover-v1")
  assert_true(score.score <= 20)
  assert_true(score.reasons.any(fn(reason) { reason.contains("hard limit") }))
  assert_eq(@mission.traverse_decision_label(score.decision), "block")
}

///|
test "first trusted square route candidates propose reviewable detours" {
  let routes = @mission.first_trusted_square_route_candidates()
  assert_eq(routes.length(), 3)
  assert_eq(routes[0].route_id, "direct-lola-window")
  assert_true(routes[0].decision == Block)
  assert_true(routes[0].reasons.any(fn(reason) { reason.contains("blocked") }))
  assert_eq(routes[1].route_id, "west-contour-detour")
  assert_true(routes[1].decision == Review)
  assert_true(routes[1].confidence < 0.7)
  assert_eq(@mission.route_candidate_status_label(routes[1]), "review")
  assert_eq(routes[2].route_id, "north-rim-stepout")
  assert_true(routes[2].next_action.contains("illumination"))
}
