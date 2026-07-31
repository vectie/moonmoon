///|
test "moonbook registry answers mission and project questions from evidence" {
  let view = @ui.first_trusted_square_view_model()
  let registry = @ui.moonbook_registry(view)
  assert_eq(
    registry.blocked.en_us.title,
    "The mission is held by 4 controlling blockers",
  )
  assert_true(registry.blocked.en_us.body.contains(view.scorecard.next_action))
  assert_true(registry.window.en_us.title.contains("2026-11-08T00:00:00Z"))
  assert_true(registry.window.en_us.body.contains("3997.259 Wh available"))
  assert_true(
    registry.terrain_source.en_us.body.contains(
      "NASA PDS Geosciences / LRO LOLA",
    ),
  )
  assert_true(registry.robot_authority.en_us.title.contains("cannot authorize"))
  assert_true(registry.project.en_us.body.contains("Rabbita"))
}

///|
test "moonbook registry includes localized recovery states" {
  let registry = @ui.moonbook_registry(@ui.first_trusted_square_view_model())
  assert_eq(registry.empty.en_us.state, "is-warning")
  assert_eq(registry.unknown.zh_hans.state, "is-unknown")
  assert_true(registry.empty.zh_hans.body.contains("任务"))
  assert_true(registry.unknown.en_us.sources.length() == 1)
}
