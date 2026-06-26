///|
test "first trusted square view model exposes terrain and routes" {
  let view = @ui.first_trusted_square_view_model()
  assert_eq(view.view_id, "ui/first-trusted-square/operator-view-v2")
  assert_eq(view.viewport.rows, 4)
  assert_eq(view.viewport.cols, 4)
  assert_eq(view.site_latitude_deg, -89.88)
  assert_eq(view.site_longitude_deg, 0.12)
  assert_eq(view.terrain_cells.length(), 16)
  assert_eq(view.routes.length(), 6)
  assert_eq(view.route_overlays.length(), 6)
  assert_eq(view.globe_overlay.footprint.length(), 4)
  assert_eq(view.globe_overlay.selected_route_trace.points.length(), 3)
  assert_eq(
    view.globe_overlay.selected_route_trace.path_id,
    "globe-route/northeast-stepout",
  )
  assert_eq(view.corridor_windows.length(), 81)
  assert_eq(view.corridor_windows[0].window_id, "r-12-c+16")
  assert_eq(view.corridor_windows[0].selected_route_id, "northeast-stepout")
  assert_eq(view.selected_route_id, "northeast-stepout")
  assert_eq(view.active_layer_id, "hazard")
  assert_true(view.layers.length() >= 7)
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
test "first trusted square view model exposes selected tile inspector" {
  let view = @ui.first_trusted_square_view_model()
  assert_eq(view.selected_tile.cell_id, view.selected_cell_id)
  assert_eq(view.selected_tile.hazard, "blocked")
  assert_true(view.selected_tile.slope_grade > 0.7)
  assert_true(view.selected_tile.roughness_m > 7.0)
  assert_eq(
    view.selected_tile.source_dataset_id,
    "lro-lola-first-trusted-square-dem-v1",
  )
  assert_true(view.selected_tile.layer_values.length() >= 5)
  assert_eq(view.source_panel.review_status, "accepted-for-software-proof")
}

///|
test "first trusted square view model supports explicit tile selection" {
  let view = @ui.first_trusted_square_view_model_at(1, 2)
  assert_eq(view.selected_cell_id, "first-trusted-square-lola/r1-c2")
  assert_eq(view.selected_tile.row, 1)
  assert_eq(view.selected_tile.col, 2)
  let mut selected_cells = 0
  for cell in view.terrain_cells {
    if cell.selected {
      selected_cells += 1
      assert_eq(cell.cell_id, view.selected_cell_id)
    }
  }
  assert_eq(selected_cells, 1)
}

///|
test "first trusted square view model exposes layer intensities" {
  let view = @ui.first_trusted_square_view_model_at(3, 3)
  let mut saw_elevation = false
  let mut saw_power = false
  for value in view.selected_tile.layer_values {
    if value.layer_id == "elevation" {
      saw_elevation = true
      assert_true(value.intensity >= 0.0 && value.intensity <= 1.0)
    }
    if value.layer_id == "power" {
      saw_power = true
      assert_eq(value.status, "block")
      assert_true(value.value > 230.0)
    }
  }
  assert_true(saw_elevation)
  assert_true(saw_power)
}

///|
test "first trusted square view renderers include operator evidence" {
  let markdown = @ui.first_trusted_square_markdown()
  assert_true(markdown.contains("northeast-stepout"))
  assert_true(markdown.contains("Power-window evidence"))
  assert_true(markdown.contains("Selected Tile Inspector"))
  assert_true(markdown.contains("Route Overlays"))
  let json = @ui.first_trusted_square_json().stringify(indent=2)
  assert_true(json.contains("terrain_cells"))
  assert_true(json.contains("route_overlays"))
  assert_true(json.contains("globe_overlay"))
  assert_true(json.contains("site-footprint/ne"))
  assert_true(json.contains("globe-route/northeast-stepout"))
  assert_true(json.contains("corridor_windows"))
  assert_true(json.contains("selected_tile"))
  assert_true(json.contains("energy-window"))
}
