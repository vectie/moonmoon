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
  assert_eq(view.globe_overlay.corridor_windows.length(), 81)
  assert_eq(view.globe_overlay.hardware_authority, "hardware denied")
  assert_true(view.globe_overlay.blocker_count > 0)
  assert_eq(view.corridor_windows.length(), 81)
  assert_eq(view.corridor_windows[0].window_id, "r-12-c+16")
  assert_eq(view.corridor_windows[0].selected_route_id, "northeast-stepout")
  assert_eq(view.selected_route_id, "northeast-stepout")
  assert_eq(
    view.lighting.method_id,
    "de440s-iau-moon-pck11-observer-geometry-v2",
  )
  assert_eq(view.lighting.samples.length(), 14)
  assert_eq(view.lighting.default_sample_index, 13)
  assert_true(view.lighting.orientation_source_path.contains("pck00011.tpc"))
  assert_true(view.lighting.samples[13].sun_altitude_deg < -1.12)
  assert_eq(view.active_layer_id, "hazard")
  assert_true(view.scorecard.next_action.contains("terrain grade"))
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
      assert_eq(route.illumination.decision, "block")
      assert_true(route.illumination.max_horizon_angle_deg > 26.0)
      assert_true(route.illumination.max_sun_altitude_deg < 0.2)
      assert_true(route.illumination.terrain_shadow_margin_deg > 26.0)
      assert_true(route.illumination.bounded_horizon)
      assert_eq(route.illumination.horizon_profile.length(), 8)
      assert_eq(route.illumination.horizon_profile[6].label, "W")
      assert_true(
        route.illumination.horizon_profile[6].horizon_angle_deg > 26.0,
      )
      assert_true(
        route.illumination.power_window_source_path.contains(
          "first_trusted_square_power_window.json",
        ),
      )
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
  assert_eq(view.source_panel.catalog_artifact_kind, "dataset")
  assert_eq(
    view.source_panel.catalog_artifact_id,
    "lro-lola-first-trusted-square-dem-v1",
  )
  assert_eq(
    view.source_panel.catalog_manifest_path,
    "datasets/lro-lola-first-trusted-square-dem-v1.json",
  )
  assert_eq(view.source_panel.catalog_status, "verified")
  assert_eq(view.source_panel.authority, "NASA PDS Geosciences / LRO LOLA")
  assert_eq(view.source_panel.catalog_ref_uris.length(), 1)
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
      assert_eq(value.value, 0.0)
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
  assert_true(
    markdown.contains("catalog: dataset/lro-lola-first-trusted-square-dem-v1"),
  )
  assert_true(markdown.contains("authority: NASA PDS Geosciences / LRO LOLA"))
  assert_true(markdown.contains("Route Overlays"))
  let json = @ui.first_trusted_square_json().stringify(indent=2)
  assert_true(json.contains("terrain_cells"))
  assert_true(json.contains("route_overlays"))
  assert_true(json.contains("globe_overlay"))
  assert_true(json.contains("site-footprint/ne"))
  assert_true(json.contains("globe-route/northeast-stepout"))
  assert_true(json.contains("corridor_windows"))
  assert_true(json.contains("hardware_authority"))
  assert_true(json.contains("selected_tile"))
  assert_true(json.contains("catalog_artifact_id"))
  assert_true(json.contains("catalog-validation"))
  assert_true(json.contains("catalog validation has not been read"))
  assert_true(json.contains("energy-window"))
  assert_true(json.contains("selected-route-clearance"))
  assert_true(json.contains("terrain_shadow_margin_deg"))
  assert_true(json.contains("max_sun_altitude_deg"))
  assert_true(json.contains("clear-terrain-grade-northeast-stepout"))
  assert_true(json.contains("clear-energy-margin"))
  assert_true(json.contains("operator-review-transitions.json"))
}

///|
test "catalog-backed view model reports missing roots as data store issues" {
  match
    @ui.first_trusted_square_view_model_from_catalog_root(
      "target/ui-tests/missing-catalog-root",
    ) {
    Ok(_) => fail("missing catalog root should fail")
    Err(error) => assert_eq(error.code, "read-manifest")
  }
}

///|
test "robot readiness view model exposes catalog-backed migration evidence" {
  let readiness : @robot_catalog.RobotMigrationReadiness = {
    root: "target/data-roots/robot-ui-test",
    status: "ready",
    ready: true,
    validation_artifact: @data_core.artifact_ref(
      "validation-report",
      "validation-1",
      "validations/validation-1.json",
      status=@data_core.DataStatus::Verified,
      summary="0 finding(s)",
    ),
    validation_status: @data_core.ValidationStatus::Passed,
    blocker_count: 0,
    warning_count: 0,
    model_count: 1,
    episode_count: 1,
    telemetry_stream_count: 1,
    gait_clip_count: 1,
    gait_annotation_count: 1,
    gait_alignment_count: 1,
    task_label_count: 1,
    rollout_count: 1,
    signal_ref_count: 2,
    replay_ref_count: 1,
    quality_ref_count: 1,
    telemetry_ref_count: 2,
    gait_ref_count: 2,
    gait_annotation_ref_count: 2,
    gait_alignment_ref_count: 2,
    task_label_ref_count: 2,
    rollout_ref_count: 2,
    data_ref_count: 24,
    next_action: "migrate the next robot dataset family only after this root stays green",
    summary: "robot root is ready",
  }
  let view = @ui.robot_readiness_view_model(readiness)
  assert_eq(view.view_id, "ui/robot-migration-readiness/operator-view-v1")
  assert_true(view.ready)
  assert_eq(view.validation_status, "passed")
  assert_eq(view.data_ref_count, 24)
  assert_eq(view.metrics.length(), 8)
  assert_eq(view.evidence.length(), 9)
  assert_eq(view.metrics[7].metric_id, "rollouts")
  assert_eq(view.metrics[7].value, 1)
  assert_eq(view.evidence[8].evidence_id, "rollouts")
  assert_eq(view.evidence[8].count, 2)
  let html = @ui.render_robot_readiness_html(view)
  assert_true(html.contains("moonmoon-robot-readiness-view-model"))
  assert_true(html.contains("Robot Migration Readiness"))
  assert_true(html.contains("rollout summaries"))
  assert_true(html.contains("validations/validation-1.json"))
}
