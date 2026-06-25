///|
test "first trusted square view model exposes terrain and routes" {
  let view = @ui.first_trusted_square_view_model()
  assert_eq(view.view_id, "ui/first-trusted-square/operator-view-v1")
  assert_eq(view.rows, 4)
  assert_eq(view.cols, 4)
  assert_eq(view.terrain_cells.length(), 16)
  assert_eq(view.routes.length(), 6)
  assert_eq(view.selected_route_id, "northeast-stepout")
}

///|
test "first trusted square view model marks selected route" {
  let view = @ui.first_trusted_square_view_model()
  let mut selected_count = 0
  for route in view.routes {
    if route.selected {
      selected_count += 1
      assert_eq(route.route_id, "northeast-stepout")
      assert_eq(route.decision, "block")
    }
  }
  assert_eq(selected_count, 1)
}

///|
test "first trusted square view renderers include operator evidence" {
  let markdown = @ui.first_trusted_square_markdown()
  assert_true(markdown.contains("northeast-stepout"))
  assert_true(markdown.contains("Power-window evidence"))
  let json = @ui.first_trusted_square_json().stringify(indent=2)
  assert_true(json.contains("terrain_cells"))
  assert_true(json.contains("energy-window"))
}
