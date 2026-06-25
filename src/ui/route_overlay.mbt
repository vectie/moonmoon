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
