///|
test "first trusted square exports Moonrobo simulation preconditions" {
  let handoffs = @moonrobo.first_trusted_square_handoffs()
  assert_eq(handoffs.length(), 5)
  assert_eq(handoffs[0].route_id, "direct-lola-window")
  assert_true(handoffs[0].decision == @mission.TraverseDecision::Block)
  assert_eq(handoffs[0].preconditions.length(), 4)
  assert_eq(
    handoffs[0].preconditions[0].precondition_id,
    "route-direct-lola-window",
  )
  assert_eq(
    handoffs[0].preconditions[1].precondition_id,
    "illumination-direct-lola-window",
  )
  assert_eq(handoffs[0].preconditions[2].precondition_id, "energy-window")
  assert_eq(
    handoffs[0].preconditions[3].precondition_id,
    "corridor-scan-best-window",
  )
  assert_eq(@moonrobo.handoff_status_label(handoffs[0]), "block")
  assert_true(handoffs[0].next_action.contains("must not simulate"))
}

///|
test "first trusted square primary Moonrobo handoff follows best corridor route" {
  let handoff = @moonrobo.first_trusted_square_primary_handoff()
  assert_eq(handoff.route_id, "southwest-bypass")
  assert_true(handoff.decision == @mission.TraverseDecision::Block)
  assert_eq(handoff.site_id, "first-trusted-square")
  assert_eq(handoff.target_body, "Moon")
  assert_true(
    handoff.preconditions.any(fn(precondition) {
      precondition.precondition_id == "energy-window" &&
      precondition.decision == @mission.TraverseDecision::Block
    }),
  )
  assert_true(
    handoff.preconditions.any(fn(precondition) {
      precondition.precondition_id == "corridor-scan-best-window" &&
      precondition.reason.contains("still blocked")
    }),
  )
}

///|
test "first trusted square Moonrobo renderers expose blocked handoff evidence" {
  let markdown = @moonrobo.first_trusted_square_markdown()
  assert_true(markdown.contains("Moonrobo Simulation Preconditions"))
  assert_true(markdown.contains("southwest-bypass"))
  assert_true(markdown.contains("energy-window"))
  assert_true(markdown.contains("must not simulate"))
  let json = @moonrobo.first_trusted_square_json().stringify(indent=2)
  assert_true(json.contains("\"task_kind\": \"route-simulation-precondition\""))
  assert_true(json.contains("\"route_id\": \"southwest-bypass\""))
  assert_true(json.contains("\"precondition_id\": \"energy-window\""))
  assert_true(json.contains("\"Block\""))
}
