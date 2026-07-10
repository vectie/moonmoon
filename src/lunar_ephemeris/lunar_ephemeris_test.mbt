///|
fn close(left : Double, right : Double) -> Bool {
  (left - right).abs() < 1.0e-12
}

///|
fn vector_close(
  left : @lunar_ephemeris.Vector3,
  right : @lunar_ephemeris.Vector3,
) -> Bool {
  close(left.x, right.x) && close(left.y, right.y) && close(left.z, right.z)
}

///|
test "DE440s observer timeline reproduces the checked polar Sun window" {
  let data = @fs.read_file_to_bytes(
    "data/sources/lunar_ephemeris/kernels/de440s.bsp",
  )
  let timeline = @lunar_ephemeris.compute_first_trusted_square_observer_timeline(
    data,
  ).unwrap()
  let fixture = @lunar_ephemeris.first_trusted_square_observer_timeline_fixture()
  assert_eq(timeline.method_id, fixture.method_id)
  assert_eq(timeline.frame_id, fixture.frame_id)
  assert_eq(timeline.source_path, fixture.source_path)
  assert_eq(timeline.orientation_source_path, fixture.orientation_source_path)
  assert_true(
    close(timeline.min_sun_altitude_deg, fixture.min_sun_altitude_deg),
  )
  assert_true(
    close(timeline.max_sun_altitude_deg, fixture.max_sun_altitude_deg),
  )
  assert_true(close(timeline.sunlit_hours, fixture.sunlit_hours))
  assert_true(close(timeline.dark_hours, fixture.dark_hours))
  assert_true(close(timeline.available_energy_wh, fixture.available_energy_wh))
  let actual_track = timeline.hourly_solar_track
  let expected_track = fixture.hourly_solar_track
  assert_eq(actual_track.time_start_utc, expected_track.time_start_utc)
  assert_eq(actual_track.step_minutes, expected_track.step_minutes)
  assert_eq(actual_track.sun_altitude_deg.length(), 336)
  assert_eq(actual_track.sun_azimuth_deg.length(), 336)
  for index in 0..<actual_track.sun_altitude_deg.length() {
    assert_true(
      close(
        actual_track.sun_altitude_deg[index],
        expected_track.sun_altitude_deg[index],
      ),
    )
    assert_true(
      close(
        actual_track.sun_azimuth_deg[index],
        expected_track.sun_azimuth_deg[index],
      ),
    )
  }
  assert_eq(timeline.samples.length(), fixture.samples.length())
  for index in 0..<timeline.samples.length() {
    let actual = timeline.samples[index]
    let expected = fixture.samples[index]
    assert_eq(actual.timestamp_utc, expected.timestamp_utc)
    assert_true(close(actual.ephemeris_time_s, expected.ephemeris_time_s))
    assert_true(vector_close(actual.sun_body_fixed, expected.sun_body_fixed))
    assert_true(
      vector_close(actual.earth_body_fixed, expected.earth_body_fixed),
    )
    assert_true(close(actual.sun_altitude_deg, expected.sun_altitude_deg))
    assert_true(close(actual.sun_azimuth_deg, expected.sun_azimuth_deg))
    assert_true(close(actual.earth_altitude_deg, expected.earth_altitude_deg))
    assert_true(close(actual.earth_azimuth_deg, expected.earth_azimuth_deg))
    assert_true(
      close(
        actual.earth_illuminated_fraction,
        expected.earth_illuminated_fraction,
      ),
    )
  }
  assert_eq(timeline.samples.length(), 14)
  assert_eq(timeline.samples[0].timestamp_utc, "2026-06-25T00:00:00Z")
  assert_eq(timeline.samples[13].timestamp_utc, "2026-07-08T00:00:00Z")
  assert_true(timeline.samples[5].earth_illuminated_fraction < 0.01)
  for sample in timeline.samples {
    assert_true(sample.sun_altitude_deg > -3.0)
    assert_true(sample.sun_altitude_deg < 3.0)
    assert_true(sample.earth_illuminated_fraction >= 0.0)
    assert_true(sample.earth_illuminated_fraction <= 1.0)
  }
}
