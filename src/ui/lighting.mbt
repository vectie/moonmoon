///|
fn lunar_lighting_view(
  evidence : @mission.PowerWindowEvidence,
) -> LunarLightingView {
  let timeline = evidence.observer_geometry
  let samples : Array[LunarLightingSampleView] = []
  let mut default_sample_index = 0
  let mut maximum_altitude = -90.0
  for index, sample in timeline.samples {
    if sample.sun_altitude_deg > maximum_altitude {
      maximum_altitude = sample.sun_altitude_deg
      default_sample_index = index
    }
    samples.push({
      timestamp_utc: sample.timestamp_utc,
      sun_body_x: sample.sun_body_fixed.x,
      sun_body_y: sample.sun_body_fixed.y,
      sun_body_z: sample.sun_body_fixed.z,
      earth_body_x: sample.earth_body_fixed.x,
      earth_body_y: sample.earth_body_fixed.y,
      earth_body_z: sample.earth_body_fixed.z,
      sun_altitude_deg: sample.sun_altitude_deg,
      sun_azimuth_deg: sample.sun_azimuth_deg,
      earth_altitude_deg: sample.earth_altitude_deg,
      earth_azimuth_deg: sample.earth_azimuth_deg,
      earth_illuminated_fraction: sample.earth_illuminated_fraction,
    })
  }
  {
    method_id: timeline.method_id,
    frame_id: timeline.frame_id,
    source_path: timeline.source_path,
    orientation_source_path: timeline.orientation_source_path,
    target_lat_deg: timeline.target_lat_deg,
    target_lon_deg: timeline.target_lon_deg,
    sample_step_minutes: timeline.sample_step_minutes,
    default_sample_index,
    samples,
  }
}
