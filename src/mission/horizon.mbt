///|
priv struct HorizonCandidate {
  row : Int
  col : Int
  elevation_m : Double
  distance_m : Double
  horizon_angle_deg : Double
}

///|
priv struct RouteSolarExposure {
  evaluated_sample_count : Int
  spherical_sunlit_hours : Double
  terrain_sunlit_hours : Double
  terrain_shadowed_hours : Double
  longest_dark_hours : Double
  terrain_available_energy_wh : Double
  minimum_solar_clearance_deg : Double
  maximum_solar_clearance_deg : Double
}

///|
fn horizon_cell(
  grid : @terrain.TerrainGrid,
  row : Int,
  col : Int,
) -> @core.TerrainCell {
  grid.cells[row * grid.cols + col]
}

///|
fn horizon_center_elevation(grid : @terrain.TerrainGrid) -> Double {
  let low_row = (grid.rows - 1) / 2
  let high_row = grid.rows / 2
  let low_col = (grid.cols - 1) / 2
  let high_col = grid.cols / 2
  (
    horizon_cell(grid, low_row, low_col).elevation_m +
    horizon_cell(grid, low_row, high_col).elevation_m +
    horizon_cell(grid, high_row, low_col).elevation_m +
    horizon_cell(grid, high_row, high_col).elevation_m
  ) /
  4.0
}

///|
fn horizon_route_id(tile_id : String) -> String {
  match tile_id {
    "first-trusted-square-lola" => "direct-lola-window"
    "first-trusted-square-west-contour-lola" => "west-contour-detour"
    "first-trusted-square-north-rim-lola" => "north-rim-stepout"
    "first-trusted-square-southwest-bypass-lola" => "southwest-bypass"
    "first-trusted-square-south-stepout-lola" => "south-stepout"
    "first-trusted-square-northeast-stepout-lola" => "northeast-stepout"
    _ => tile_id
  }
}

///|
fn horizon_artifact_path(route_id : String) -> String {
  let artifact_id = route_id.replace_all(old="-", new="_")
  "artifact/mission/first_trusted_square_\{artifact_id}_horizon.json"
}

///|
fn horizon_sector_label(sector : Int) -> String {
  match sector {
    0 => "N"
    1 => "NE"
    2 => "E"
    3 => "SE"
    4 => "S"
    5 => "SW"
    6 => "W"
    _ => "NW"
  }
}

///|
fn horizon_sector(azimuth_deg : Double) -> Int {
  let shifted = azimuth_deg + 22.5
  let sector = (shifted / 45.0).to_int()
  if sector >= 8 {
    0
  } else {
    sector
  }
}

///|
fn horizon_sample(
  sector : Int,
  candidate : HorizonCandidate,
) -> HorizonAzimuthSample {
  {
    sector_id: "sector-\{sector}",
    label: horizon_sector_label(sector),
    azimuth_center_deg: sector.to_double() * 45.0,
    obstruction_row: candidate.row,
    obstruction_col: candidate.col,
    obstruction_elevation_m: candidate.elevation_m,
    distance_m: candidate.distance_m,
    horizon_angle_deg: candidate.horizon_angle_deg,
  }
}

///|
fn empty_horizon_sample(sector : Int) -> HorizonAzimuthSample {
  {
    sector_id: "sector-\{sector}",
    label: horizon_sector_label(sector),
    azimuth_center_deg: sector.to_double() * 45.0,
    obstruction_row: -1,
    obstruction_col: -1,
    obstruction_elevation_m: 0.0,
    distance_m: 0.0,
    horizon_angle_deg: -90.0,
  }
}

///|
fn route_solar_exposure(
  horizons : Array[HorizonAzimuthSample],
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
) -> RouteSolarExposure {
  route_solar_exposure_range(
    horizons,
    solar_track,
    0,
    solar_track.sun_altitude_deg
    .length()
    .min(solar_track.sun_azimuth_deg.length()),
  )
}

///|
fn route_solar_exposure_range(
  horizons : Array[HorizonAzimuthSample],
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
  sample_offset : Int,
  requested_sample_count : Int,
) -> RouteSolarExposure {
  let track_sample_count = solar_track.sun_altitude_deg
    .length()
    .min(solar_track.sun_azimuth_deg.length())
  let start = sample_offset.max(0).min(track_sample_count)
  let end = (start + requested_sample_count.max(0)).min(track_sample_count)
  let sample_count = end - start
  let mut spherical_sunlit_hours = 0.0
  let mut terrain_sunlit_hours = 0.0
  let mut terrain_shadowed_hours = 0.0
  let mut current_dark_hours = 0.0
  let mut longest_dark_hours = 0.0
  let mut terrain_available_energy_wh = 0.0
  let mut minimum_solar_clearance_deg = 90.0
  let mut maximum_solar_clearance_deg = -90.0
  for index in start..<end {
    let sun_altitude_deg = solar_track.sun_altitude_deg[index]
    let sun_azimuth_deg = solar_track.sun_azimuth_deg[index]
    let horizon_angle_deg = horizons[horizon_sector(sun_azimuth_deg)].horizon_angle_deg.max(
      0.0,
    )
    let clearance_deg = sun_altitude_deg - horizon_angle_deg
    minimum_solar_clearance_deg = minimum_solar_clearance_deg.min(clearance_deg)
    maximum_solar_clearance_deg = maximum_solar_clearance_deg.max(clearance_deg)
    let spherical_sunlit = sun_altitude_deg > 0.0
    let terrain_sunlit = clearance_deg > 0.0
    if spherical_sunlit {
      spherical_sunlit_hours += 1.0
    }
    if terrain_sunlit {
      terrain_sunlit_hours += 1.0
      current_dark_hours = 0.0
      terrain_available_energy_wh += 450.0 *
        @math.sin(sun_altitude_deg * 3.141592653589793 / 180.0)
    } else {
      current_dark_hours += 1.0
      longest_dark_hours = longest_dark_hours.max(current_dark_hours)
      if spherical_sunlit {
        terrain_shadowed_hours += 1.0
      }
    }
  }
  if sample_count == 0 {
    minimum_solar_clearance_deg = 0.0
    maximum_solar_clearance_deg = 0.0
  }
  {
    evaluated_sample_count: sample_count,
    spherical_sunlit_hours,
    terrain_sunlit_hours,
    terrain_shadowed_hours,
    longest_dark_hours,
    terrain_available_energy_wh,
    minimum_solar_clearance_deg,
    maximum_solar_clearance_deg,
  }
}

///|
pub fn bounded_local_horizon_evidence(
  grid : @terrain.TerrainGrid,
  constraint : IlluminationConstraint,
  solar_track : @lunar_ephemeris.SolarGeometryTrack,
) -> LocalHorizonEvidence {
  let center_elevation_m = horizon_center_elevation(grid)
  let center_row = (grid.rows - 1).to_double() / 2.0
  let center_col = (grid.cols - 1).to_double() / 2.0
  let sectors : Array[HorizonCandidate?] = Array::make(8, None)
  let mut maximum : HorizonCandidate? = None
  for cell in grid.cells {
    let east_m = (cell.col.to_double() - center_col) * grid.cell_size_m
    let north_m = (center_row - cell.row.to_double()) * grid.cell_size_m
    let distance_m = (east_m * east_m + north_m * north_m).sqrt()
    if distance_m > 0.0 {
      let horizon_angle_deg = @math.atan2(
          cell.elevation_m - center_elevation_m,
          distance_m,
        ) *
        180.0 /
        3.141592653589793
      let raw_azimuth_deg = @math.atan2(east_m, north_m) *
        180.0 /
        3.141592653589793
      let azimuth_deg = if raw_azimuth_deg < 0.0 {
        raw_azimuth_deg + 360.0
      } else {
        raw_azimuth_deg
      }
      let candidate = {
        row: cell.row,
        col: cell.col,
        elevation_m: cell.elevation_m,
        distance_m,
        horizon_angle_deg,
      }
      let sector = horizon_sector(azimuth_deg)
      match sectors[sector] {
        Some(current) =>
          if candidate.horizon_angle_deg > current.horizon_angle_deg {
            sectors[sector] = Some(candidate)
          }
        None => sectors[sector] = Some(candidate)
      }
      match maximum {
        Some(current) =>
          if candidate.horizon_angle_deg > current.horizon_angle_deg {
            maximum = Some(candidate)
          }
        None => maximum = Some(candidate)
      }
    }
  }
  let azimuth_samples : Array[HorizonAzimuthSample] = []
  for sector in 0..<8 {
    match sectors[sector] {
      Some(candidate) => azimuth_samples.push(horizon_sample(sector, candidate))
      None => azimuth_samples.push(empty_horizon_sample(sector))
    }
  }
  let maximum = maximum.unwrap()
  let exposure = route_solar_exposure(azimuth_samples, solar_track)
  let missing_samples = exposure.evaluated_sample_count == 0
  let insufficient_sun = exposure.terrain_sunlit_hours <
    constraint.min_sunlit_hours
  let excessive_darkness = exposure.longest_dark_hours >
    constraint.max_dark_hours
  let decision = if missing_samples || insufficient_sun || excessive_darkness {
    Block
  } else if exposure.terrain_shadowed_hours > 0.0 {
    Review
  } else {
    Allow
  }
  let route_id = horizon_route_id(grid.tile_id)
  {
    evidence_id: "first-trusted-square-\{route_id}-local-horizon-v3",
    route_id,
    site_id: "first-trusted-square",
    source_dataset_id: grid.source_manifest.dataset_id,
    source_tile_id: grid.tile_id,
    source_path: grid.source_manifest.source_path,
    power_window_evidence_id: constraint.power_window_evidence_id,
    power_window_source_path: constraint.power_window_source_path,
    output_path: horizon_artifact_path(route_id),
    method_id: "hourly-azimuth-matched-local-horizon-v3",
    generated_by: "vectie/moonmoon/src/mission/horizon.mbt",
    rows: grid.rows,
    cols: grid.cols,
    cell_size_m: grid.cell_size_m,
    center_elevation_m,
    max_obstruction_elevation_m: maximum.elevation_m,
    max_horizon_angle_deg: maximum.horizon_angle_deg,
    min_sun_altitude_deg: constraint.min_sun_altitude_deg,
    max_sun_altitude_deg: constraint.max_sun_altitude_deg,
    evaluated_sample_count: exposure.evaluated_sample_count,
    spherical_sunlit_hours: exposure.spherical_sunlit_hours,
    terrain_sunlit_hours: exposure.terrain_sunlit_hours,
    terrain_shadowed_hours: exposure.terrain_shadowed_hours,
    longest_dark_hours: exposure.longest_dark_hours,
    terrain_available_energy_wh: exposure.terrain_available_energy_wh,
    minimum_solar_clearance_deg: exposure.minimum_solar_clearance_deg,
    maximum_solar_clearance_deg: exposure.maximum_solar_clearance_deg,
    azimuth_samples,
    confidence: @terrain.analyze(grid).uncertainty.confidence * 0.875,
    decision,
    reasons: [
      "eight-sector bounded local horizon computed from \{grid.source_manifest.source_path}",
      "\{exposure.evaluated_sample_count} hourly Sun samples were matched to terrain horizon by azimuth",
      "route receives \{exposure.terrain_sunlit_hours} terrain-visible hours and \{exposure.terrain_available_energy_wh} Wh",
      "longest continuous darkness is \{exposure.longest_dark_hours} hours",
    ],
    next_action: match decision {
      Allow => "hourly route exposure clears the illumination window"
      Review =>
        "review terrain-shadowed daylight intervals before route simulation"
      Block =>
        if missing_samples {
          "attach hourly Sun geometry before route simulation"
        } else if exposure.spherical_sunlit_hours == 0.0 {
          "select a mission window where the Sun rises above the spherical horizon"
        } else {
          "select a lower-obstruction route or a window with enough terrain-visible sunlight"
        }
    },
  }
}
