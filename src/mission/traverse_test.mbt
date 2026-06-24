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
test "first trusted square route candidates use measured adjacent windows" {
  let routes = @mission.first_trusted_square_route_candidates()
  assert_eq(routes.length(), 5)
  assert_eq(routes[0].route_id, "direct-lola-window")
  assert_true(routes[0].decision == Block)
  assert_true(routes[0].reasons.any(fn(reason) { reason.contains("blocked") }))
  assert_eq(routes[1].route_id, "west-contour-detour")
  assert_true(routes[1].decision == Block)
  assert_eq(
    routes[1].evidence_dataset_id,
    "lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    routes[1].evidence_source_path,
    "data/sources/lro_lola/first_trusted_square_west_contour_dem.csv",
  )
  assert_true(routes[1].expected_max_grade > 0.7)
  assert_eq(@mission.route_candidate_status_label(routes[1]), "block")
  assert_true(routes[1].illumination.decision == Block)
  assert_true(routes[1].illumination.relief_shadow_risk > 0.3)
  assert_true(
    routes[1].illumination.reasons.any(fn(reason) {
      reason.contains("solar ephemeris")
    }),
  )
  assert_eq(
    @mission.illumination_decision_label(routes[1].illumination),
    "block",
  )
  assert_eq(routes[2].route_id, "north-rim-stepout")
  assert_true(routes[2].decision == Block)
  assert_eq(routes[2].evidence_tile_id, "first-trusted-square-north-rim-lola")
  assert_true(routes[2].next_action.contains("illumination"))
  assert_eq(routes[3].route_id, "southwest-bypass")
  assert_true(routes[3].decision == Block)
  assert_eq(
    routes[3].evidence_dataset_id,
    "lro-lola-first-trusted-square-southwest-bypass-dem-v1",
  )
  assert_true(routes[3].expected_max_grade < routes[1].expected_max_grade)
  assert_true(
    routes[3].reasons.any(fn(reason) { reason.contains("lower risk") }),
  )
  assert_eq(routes[4].route_id, "south-stepout")
  assert_true(routes[4].decision == Block)
  assert_eq(
    routes[4].evidence_tile_id,
    "first-trusted-square-south-stepout-lola",
  )
}

///|
test "first trusted square illumination gate blocks missing time window evidence" {
  let assessment = @mission.assess_illumination(
    @terrain.first_trusted_square_grid(),
    @mission.conservative_illumination_constraint(),
  )
  assert_true(assessment.decision == Block)
  assert_eq(
    assessment.constraint.constraint_id,
    "conservative-south-pole-power-v1",
  )
  assert_true(assessment.relief_shadow_risk > 0.3)
  assert_true(assessment.confidence < 0.5)
  assert_true(
    assessment.reasons.any(fn(reason) {
      reason.contains("time-windowed solar ephemeris")
    }),
  )
  assert_true(assessment.next_action.contains("solar ephemeris"))
}
