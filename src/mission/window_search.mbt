///|
pub(all) struct RouteMissionWindowCandidate {
  route_id : String
  route_label : String
  time_start_utc : String
  time_end_utc : String
  sample_offset : Int
  window_hours : Int
  spherical_sunlit_hours : Double
  terrain_sunlit_hours : Double
  terrain_shadowed_hours : Double
  longest_dark_hours : Double
  terrain_available_energy_wh : Double
  minimum_solar_clearance_deg : Double
  maximum_solar_clearance_deg : Double
  meets_illumination_constraint : Bool
  decision : TraverseDecision
  reasons : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionWindowSearchEvidence {
  evidence_id : String
  site_id : String
  selected_route_id : String
  selected_candidate_index : Int
  source_path : String
  orientation_source_path : String
  search_start_utc : String
  search_end_utc : String
  window_hours : Int
  stride_hours : Int
  windows_per_route : Int
  generated_by : String
  candidates : Array[RouteMissionWindowCandidate]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn mission_window_iso_timestamp(unix_seconds : Int64) -> String {
  let time = try! @time.unix(unix_seconds)
  let month = time.month().to_string().pad_start(2, '0')
  let day = time.day().to_string().pad_start(2, '0')
  let hour = time.hour().to_string().pad_start(2, '0')
  "\{time.year()}-\{month}-\{day}T\{hour}:00:00Z"
}

///|
fn mission_window_candidate(
  route : RouteCandidate,
  exposure : RouteSolarExposure,
  search_start_unix_s : Int64,
  sample_offset : Int,
  window_hours : Int,
  constraint : IlluminationConstraint,
) -> RouteMissionWindowCandidate {
  let enough_sunlight = exposure.terrain_sunlit_hours >=
    constraint.min_sunlit_hours
  let darkness_bounded = exposure.longest_dark_hours <=
    constraint.max_dark_hours
  let meets_illumination_constraint = enough_sunlight && darkness_bounded
  let reasons : Array[String] = []
  add_reason_if(
    reasons,
    !enough_sunlight,
    "terrain-visible sunlight is below \{constraint.min_sunlit_hours} hours",
  )
  add_reason_if(
    reasons,
    !darkness_bounded,
    "longest darkness exceeds \{constraint.max_dark_hours} hours",
  )
  add_reason_if(
    reasons,
    exposure.terrain_shadowed_hours > 0.0,
    "terrain blocks \{exposure.terrain_shadowed_hours} spherical-sunlit hours",
  )
  {
    route_id: route.route_id,
    route_label: route.label,
    time_start_utc: mission_window_iso_timestamp(
      search_start_unix_s + Int64::from_int(sample_offset) * 3600L,
    ),
    time_end_utc: mission_window_iso_timestamp(
      search_start_unix_s +
      Int64::from_int(sample_offset + window_hours) * 3600L,
    ),
    sample_offset,
    window_hours,
    spherical_sunlit_hours: exposure.spherical_sunlit_hours,
    terrain_sunlit_hours: exposure.terrain_sunlit_hours,
    terrain_shadowed_hours: exposure.terrain_shadowed_hours,
    longest_dark_hours: exposure.longest_dark_hours,
    terrain_available_energy_wh: exposure.terrain_available_energy_wh,
    minimum_solar_clearance_deg: exposure.minimum_solar_clearance_deg,
    maximum_solar_clearance_deg: exposure.maximum_solar_clearance_deg,
    meets_illumination_constraint,
    decision: if meets_illumination_constraint {
      Allow
    } else if exposure.terrain_sunlit_hours > 0.0 {
      Review
    } else {
      Block
    },
    reasons,
  }
}

///|
fn mission_window_better(
  candidate : RouteMissionWindowCandidate,
  current : RouteMissionWindowCandidate,
) -> Bool {
  let energy_delta = candidate.terrain_available_energy_wh -
    current.terrain_available_energy_wh
  if candidate.meets_illumination_constraint !=
    current.meets_illumination_constraint {
    candidate.meets_illumination_constraint
  } else if energy_delta.abs() > 1.0e-9 {
    energy_delta > 0.0
  } else if candidate.longest_dark_hours != current.longest_dark_hours {
    candidate.longest_dark_hours < current.longest_dark_hours
  } else if candidate.terrain_sunlit_hours != current.terrain_sunlit_hours {
    candidate.terrain_sunlit_hours > current.terrain_sunlit_hours
  } else {
    candidate.minimum_solar_clearance_deg > current.minimum_solar_clearance_deg
  }
}

///|
fn best_route_mission_window(
  route : RouteCandidate,
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
  search_start_unix_s : Int64,
  window_hours : Int,
  stride_hours : Int,
  constraint : IlluminationConstraint,
) -> RouteMissionWindowCandidate {
  let horizons = route.illumination.local_horizon.azimuth_samples
  let sample_count = solar_track.sun_altitude_deg
    .length()
    .min(solar_track.sun_azimuth_deg.length())
  let mut best : RouteMissionWindowCandidate? = None
  for sample_offset = 0
      sample_offset + window_hours <= sample_count
      sample_offset = sample_offset + stride_hours {
    let exposure = route_solar_exposure_range(
      horizons, solar_track, sample_offset, window_hours,
    )
    let candidate = mission_window_candidate(
      route, exposure, search_start_unix_s, sample_offset, window_hours, constraint,
    )
    match best {
      Some(current) =>
        if mission_window_better(candidate, current) {
          best = Some(candidate)
        }
      None => best = Some(candidate)
    }
  }
  best.unwrap()
}

///|
pub fn rank_route_mission_windows(
  site_id : String,
  selected_route_id : String,
  routes : Array[RouteCandidate],
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
  search_start_unix_s : Int64,
  window_hours : Int,
  stride_hours : Int,
  source_path : String,
  orientation_source_path : String,
  constraint : IlluminationConstraint,
) -> Result[MissionWindowSearchEvidence, String] {
  let sample_count = solar_track.sun_altitude_deg
    .length()
    .min(solar_track.sun_azimuth_deg.length())
  if routes.is_empty() {
    return Err("mission-window search requires at least one route")
  }
  if solar_track.step_minutes != 60 {
    return Err("mission-window search requires an hourly solar track")
  }
  if window_hours <= 0 || stride_hours <= 0 || sample_count < window_hours {
    return Err("mission-window search range is smaller than its window")
  }
  let candidates : Array[RouteMissionWindowCandidate] = []
  let mut selected_candidate_index = -1
  for route in routes {
    if route.route_id == selected_route_id {
      selected_candidate_index = candidates.length()
    }
    candidates.push(
      best_route_mission_window(
        route, solar_track, search_start_unix_s, window_hours, stride_hours, constraint,
      ),
    )
  }
  if selected_candidate_index < 0 {
    return Err("mission-window search cannot find selected route")
  }
  Ok({
    evidence_id: "\{site_id}-mission-window-search-v1",
    site_id,
    selected_route_id,
    selected_candidate_index,
    source_path,
    orientation_source_path,
    search_start_utc: mission_window_iso_timestamp(search_start_unix_s),
    search_end_utc: mission_window_iso_timestamp(
      search_start_unix_s + Int64::from_int(sample_count) * 3600L,
    ),
    window_hours,
    stride_hours,
    windows_per_route: (sample_count - window_hours) / stride_hours + 1,
    generated_by: "vectie/moonmoon/src/mission/window_search.mbt",
    candidates,
  })
}

///|
pub fn first_trusted_square_window_search_evidence() -> MissionWindowSearchEvidence {
  generated_first_trusted_square_window_search_evidence()
}
