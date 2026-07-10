///|
fn route_views(
  routes : Array[@mission.RouteCandidate],
  selected_route_id : String,
) -> Array[RouteView] {
  let views : Array[RouteView] = []
  for route in routes {
    views.push({
      route_id: route.route_id,
      label: route.label,
      selected: route.route_id == selected_route_id,
      decision: @mission.route_candidate_status_label(route),
      score: route.score,
      max_grade: route.expected_max_grade,
      roughness_m: route.expected_roughness_m,
      evidence_tile_id: route.evidence_tile_id,
      illumination: {
        decision: @mission.illumination_decision_label(route.illumination),
        confidence: route.illumination.confidence,
        relief_shadow_risk: route.illumination.relief_shadow_risk,
        max_horizon_angle_deg: route.illumination.local_horizon.max_horizon_angle_deg,
        max_sun_altitude_deg: route.illumination.local_horizon.max_sun_altitude_deg,
        terrain_shadow_margin_deg: route.illumination.terrain_shadow_margin_deg,
        bounded_horizon: route.illumination.local_horizon.output_path != "",
        time_start_utc: route.illumination.constraint.time_start_utc,
        time_end_utc: route.illumination.constraint.time_end_utc,
        power_window_source_path: route.illumination.constraint.power_window_source_path,
        horizon_evidence_path: if route.illumination.local_horizon.output_path !=
          "" {
          route.illumination.local_horizon.output_path
        } else {
          route.illumination.constraint.power_window_source_path
        },
      },
      next_action: route.next_action,
    })
  }
  views
}

///|
fn route_overlays(
  routes : Array[@mission.RouteCandidate],
  selected_route_id : String,
) -> Array[RouteOverlay] {
  let overlays : Array[RouteOverlay] = []
  for route in routes {
    let decision = @mission.route_candidate_status_label(route)
    overlays.push({
      overlay_id: "route-overlay/\{route.route_id}",
      route_id: route.route_id,
      label: route.label,
      selected: route.route_id == selected_route_id,
      decision,
      evidence_tile_id: route.evidence_tile_id,
      viewport_ref: "evidence-window:\{route.evidence_tile_id}",
      status: decision,
      summary: "\{route.evidence_tile_id}: grade \{route.expected_max_grade}, roughness \{route.expected_roughness_m} m",
    })
  }
  overlays
}
