///|
fn route_horizon_profile(
  evidence : @mission.LocalHorizonEvidence,
) -> Array[RouteHorizonSampleView] {
  evidence.azimuth_samples.map(fn(sample) {
    {
      label: sample.label,
      azimuth_center_deg: sample.azimuth_center_deg,
      horizon_angle_deg: sample.horizon_angle_deg,
      obstruction_elevation_m: sample.obstruction_elevation_m,
    }
  })
}

///|
fn route_mission_window_view(
  search : @mission.MissionWindowSearchEvidence,
  route_id : String,
) -> RouteMissionWindowView {
  for candidate in search.candidates {
    if candidate.route_id == route_id {
      return {
        decision: @mission.traverse_decision_label(candidate.decision),
        time_start_utc: candidate.time_start_utc,
        time_end_utc: candidate.time_end_utc,
        terrain_sunlit_hours: candidate.terrain_sunlit_hours,
        longest_dark_hours: candidate.longest_dark_hours,
        terrain_available_energy_wh: candidate.terrain_available_energy_wh,
        minimum_solar_clearance_deg: candidate.minimum_solar_clearance_deg,
        maximum_solar_clearance_deg: candidate.maximum_solar_clearance_deg,
        meets_illumination_constraint: candidate.meets_illumination_constraint,
      }
    }
  }
  abort("mission-window search is missing route \{route_id}")
}

///|
fn route_views(
  routes : Array[@mission.RouteCandidate],
  selected_route_id : String,
  window_search : @mission.MissionWindowSearchEvidence,
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
        evaluated_sample_count: route.illumination.local_horizon.evaluated_sample_count,
        spherical_sunlit_hours: route.illumination.local_horizon.spherical_sunlit_hours,
        terrain_sunlit_hours: route.illumination.local_horizon.terrain_sunlit_hours,
        terrain_shadowed_hours: route.illumination.local_horizon.terrain_shadowed_hours,
        longest_dark_hours: route.illumination.local_horizon.longest_dark_hours,
        terrain_available_energy_wh: route.illumination.local_horizon.terrain_available_energy_wh,
        minimum_solar_clearance_deg: route.illumination.local_horizon.minimum_solar_clearance_deg,
        maximum_solar_clearance_deg: route.illumination.local_horizon.maximum_solar_clearance_deg,
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
        horizon_profile: route_horizon_profile(route.illumination.local_horizon),
        recommended_window: route_mission_window_view(
          window_search,
          route.route_id,
        ),
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
