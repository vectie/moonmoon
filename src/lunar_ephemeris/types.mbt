///|
pub(all) struct Vector3 {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ObserverGeometrySample {
  timestamp_utc : String
  ephemeris_time_s : Double
  sun_body_fixed : Vector3
  earth_body_fixed : Vector3
  sun_altitude_deg : Double
  sun_azimuth_deg : Double
  earth_altitude_deg : Double
  earth_azimuth_deg : Double
  earth_illuminated_fraction : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SolarGeometryTrack {
  time_start_utc : String
  step_minutes : Int
  sun_altitude_deg : Array[Double]
  sun_azimuth_deg : Array[Double]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ObserverGeometryTimeline {
  method_id : String
  frame_id : String
  source_path : String
  orientation_source_path : String
  target_lat_deg : Double
  target_lon_deg : Double
  sample_step_minutes : Int
  aggregate_step_minutes : Int
  min_sun_altitude_deg : Double
  max_sun_altitude_deg : Double
  sunlit_hours : Double
  dark_hours : Double
  available_energy_wh : Double
  hourly_solar_track : SolarGeometryTrack
  samples : Array[ObserverGeometrySample]
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct SpkSegment {
  target : Int
  start_et : Double
  end_et : Double
  start_address : Int
  init_et : Double
  interval_length_s : Double
  record_size : Int
  record_count : Int
}

///|
priv struct SpkKernel {
  data : Bytes
  segments : Array[SpkSegment]
}
