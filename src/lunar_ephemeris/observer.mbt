///|
let pi = 3.141592653589793

///|
fn radians(degrees : Double) -> Double {
  degrees * pi / 180.0
}

///|
fn degrees(radians : Double) -> Double {
  radians * 180.0 / pi
}

///|
fn Vector3::add(self : Vector3, other : Vector3) -> Vector3 {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
fn Vector3::subtract(self : Vector3, other : Vector3) -> Vector3 {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
fn Vector3::negate(self : Vector3) -> Vector3 {
  { x: 0.0 - self.x, y: 0.0 - self.y, z: 0.0 - self.z }
}

///|
fn Vector3::dot(self : Vector3, other : Vector3) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
fn Vector3::unit(self : Vector3) -> Vector3 {
  let length = (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
  { x: self.x / length, y: self.y / length, z: self.z / length }
}

///|
fn rotate_z(vector : Vector3, angle : Double) -> Vector3 {
  let cosine = @math.cos(angle)
  let sine = @math.sin(angle)
  {
    x: cosine * vector.x + sine * vector.y,
    y: 0.0 - sine * vector.x + cosine * vector.y,
    z: vector.z,
  }
}

///|
fn rotate_x(vector : Vector3, angle : Double) -> Vector3 {
  let cosine = @math.cos(angle)
  let sine = @math.sin(angle)
  {
    x: vector.x,
    y: cosine * vector.y + sine * vector.z,
    z: 0.0 - sine * vector.y + cosine * vector.z,
  }
}

///|
/// Apply the IAU Moon orientation terms pinned in pck00011.tpc.
fn inertial_to_body_fixed(
  vector : Vector3,
  ephemeris_time_s : Double,
) -> Vector3 {
  let days = ephemeris_time_s / 86400.0
  let centuries = days / 36525.0
  let angle_bases = [
    125.045, 250.089, 260.008, 176.625, 357.529, 311.589, 134.963, 276.617, 34.226,
    15.134, 119.743, 239.961, 25.053,
  ]
  let angle_rates = [
    -1935.5364525, -3871.072905, 475263.3328725, 487269.629985, 35999.0509575, 964468.49931,
    477198.869325, 12006.300765, 63863.5132425, -5806.6093575, 131.84064, 6003.1503825,
    473327.79642,
  ]
  let right_ascension_terms = [
    -3.8787, -0.1204, 0.0700, -0.0172, 0.0, 0.0072, 0.0, 0.0, 0.0, -0.0052, 0.0,
    0.0, 0.0043,
  ]
  let declination_terms = [
    1.5419, 0.0239, -0.0278, 0.0068, 0.0, -0.0029, 0.0009, 0.0, 0.0, 0.0008, 0.0,
    0.0, -0.0009,
  ]
  let prime_meridian_terms = [
    3.5610, 0.1208, -0.0642, 0.0158, 0.0252, -0.0066, -0.0047, -0.0046, 0.0028, 0.0052,
    0.0040, 0.0019, -0.0044,
  ]
  let mut right_ascension_deg = 269.9949 + 0.0031 * centuries
  let mut declination_deg = 66.5392 + 0.0130 * centuries
  let mut prime_meridian_deg = 38.3213 +
    13.17635815 * days -
    1.4e-12 * days * days
  for index in 0..<angle_bases.length() {
    let argument = radians(angle_bases[index] + angle_rates[index] * centuries)
    right_ascension_deg += right_ascension_terms[index] * @math.sin(argument)
    declination_deg += declination_terms[index] * @math.cos(argument)
    prime_meridian_deg += prime_meridian_terms[index] * @math.sin(argument)
  }
  let right_ascension = radians(right_ascension_deg)
  let declination = radians(declination_deg)
  let prime_meridian = radians(prime_meridian_deg % 360.0)
  rotate_z(
    rotate_x(
      rotate_z(vector, right_ascension + pi / 2.0),
      pi / 2.0 - declination,
    ),
    prime_meridian,
  )
}

///|
fn local_angles(
  direction : Vector3,
  latitude_deg : Double,
  longitude_deg : Double,
) -> (Double, Double) {
  let latitude = radians(latitude_deg)
  let longitude = radians(longitude_deg)
  let cosine_latitude = @math.cos(latitude)
  let sine_latitude = @math.sin(latitude)
  let cosine_longitude = @math.cos(longitude)
  let sine_longitude = @math.sin(longitude)
  let up = {
    x: cosine_latitude * cosine_longitude,
    y: cosine_latitude * sine_longitude,
    z: sine_latitude,
  }
  let east = { x: 0.0 - sine_longitude, y: cosine_longitude, z: 0.0 }
  let north = {
    x: 0.0 - sine_latitude * cosine_longitude,
    y: 0.0 - sine_latitude * sine_longitude,
    z: cosine_latitude,
  }
  let altitude = degrees(@math.asin(direction.dot(up).clamp(min=-1.0, max=1.0)))
  let raw_azimuth = degrees(
    @math.atan2(direction.dot(east), direction.dot(north)),
  )
  (altitude, if raw_azimuth < 0.0 { raw_azimuth + 360.0 } else { raw_azimuth })
}

///|
fn iso_timestamp(unix_seconds : Int64) -> String {
  let time = try! @time.unix(unix_seconds)
  let month = time.month().to_string().pad_start(2, '0')
  let day = time.day().to_string().pad_start(2, '0')
  let hour = time.hour().to_string().pad_start(2, '0')
  "\{time.year()}-\{month}-\{day}T\{hour}:00:00Z"
}

///|
fn observer_geometry_at(
  kernel : SpkKernel,
  unix_seconds : Int64,
  latitude_deg : Double,
  longitude_deg : Double,
) -> ObserverGeometrySample {
  let ephemeris_time_s = (unix_seconds - 946728000L).to_double() + 69.184
  let sun = kernel.position(10, ephemeris_time_s)
  let earth_moon_barycenter = kernel.position(3, ephemeris_time_s)
  let moon_from_barycenter = kernel.position(301, ephemeris_time_s)
  let moon = earth_moon_barycenter.add(moon_from_barycenter)
  let sun_from_moon = sun.subtract(moon).unit()
  let earth_from_moon = moon_from_barycenter.negate().unit()
  let sun_body_fixed = inertial_to_body_fixed(sun_from_moon, ephemeris_time_s)
  let earth_body_fixed = inertial_to_body_fixed(
    earth_from_moon, ephemeris_time_s,
  )
  let (sun_altitude_deg, sun_azimuth_deg) = local_angles(
    sun_body_fixed, latitude_deg, longitude_deg,
  )
  let (earth_altitude_deg, earth_azimuth_deg) = local_angles(
    earth_body_fixed, latitude_deg, longitude_deg,
  )
  {
    timestamp_utc: iso_timestamp(unix_seconds),
    ephemeris_time_s,
    sun_body_fixed,
    earth_body_fixed,
    sun_altitude_deg,
    sun_azimuth_deg,
    earth_altitude_deg,
    earth_azimuth_deg,
    earth_illuminated_fraction: ((sun_from_moon.dot(earth_from_moon) + 1.0) /
    2.0).clamp(min=0.0, max=1.0),
  }
}

///|
fn first_trusted_square_observer_timeline(
  kernel : SpkKernel,
) -> ObserverGeometryTimeline {
  let samples : Array[ObserverGeometrySample] = []
  let start_unix_s = 1782345600L
  let mut min_sun_altitude_deg = 90.0
  let mut max_sun_altitude_deg = -90.0
  let mut sunlit_hours = 0.0
  let mut dark_hours = 0.0
  let mut available_energy_wh = 0.0
  for hour in 0..<(14 * 24) {
    let sample = observer_geometry_at(
      kernel,
      start_unix_s + Int64::from_int(hour) * 3600L,
      -89.88,
      0.12,
    )
    min_sun_altitude_deg = min_sun_altitude_deg.min(sample.sun_altitude_deg)
    max_sun_altitude_deg = max_sun_altitude_deg.max(sample.sun_altitude_deg)
    if sample.sun_altitude_deg > 0.0 {
      sunlit_hours += 1.0
      available_energy_wh += 450.0 * @math.sin(radians(sample.sun_altitude_deg))
    } else {
      dark_hours += 1.0
    }
  }
  for day in 0..<14 {
    samples.push(
      observer_geometry_at(
        kernel,
        start_unix_s + Int64::from_int(day) * 86400L,
        -89.88,
        0.12,
      ),
    )
  }
  {
    method_id: "de440s-iau-moon-pck11-observer-geometry-v2",
    frame_id: "IAU_MOON",
    source_path: "data/sources/lunar_ephemeris/kernels/de440s.bsp",
    orientation_source_path: "data/sources/lunar_ephemeris/kernels/pck00011.tpc",
    target_lat_deg: -89.88,
    target_lon_deg: 0.12,
    sample_step_minutes: 1440,
    aggregate_step_minutes: 60,
    min_sun_altitude_deg,
    max_sun_altitude_deg,
    sunlit_hours,
    dark_hours,
    available_energy_wh,
    samples,
  }
}

///|
pub fn compute_first_trusted_square_observer_timeline(
  de440s : Bytes,
) -> Result[ObserverGeometryTimeline, String] {
  match parse_de440s(de440s) {
    Ok(kernel) => Ok(first_trusted_square_observer_timeline(kernel))
    Err(error) => Err(error)
  }
}
