///|
pub(all) struct CapturePointAssessment {
  com_position : Vec3
  com_velocity : Vec3
  capture_point : Vec3
  nominal_com_height_m : Double
  omega_rad_s : Double
  support_assessment : SupportAssessment
  capture_margin_m : Double
  stable : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn capture_point_status(
  height_m : Double,
  assessment : SupportAssessment,
) -> String {
  if height_m <= 0.0 {
    "invalid-com-height"
  } else if assessment.stable {
    "capture-point-inside-support"
  } else {
    "capture-point-outside-support"
  }
}

///|
pub fn capture_point_assessment(
  environment : PhysicsEnvironment,
  com_position : Vec3,
  com_velocity : Vec3,
  footprints : Array[SupportFootprint],
  nominal_com_height_m? : Double = com_position.z,
) -> CapturePointAssessment {
  let height = if nominal_com_height_m > 0.0 {
    nominal_com_height_m
  } else {
    0.0
  }
  let omega = if height > 0.0 {
    (environment.gravity_mps2 / height).sqrt()
  } else {
    0.0
  }
  let capture = if omega > 0.0 {
    vec3(
      com_position.x + com_velocity.x / omega,
      com_position.y + com_velocity.y / omega,
      com_position.z,
    )
  } else {
    com_position
  }
  let assessment = support_assessment(capture, footprints)
  let stable = height > 0.0 && assessment.stable
  {
    com_position,
    com_velocity,
    capture_point: capture,
    nominal_com_height_m: height,
    omega_rad_s: omega,
    support_assessment: assessment,
    capture_margin_m: assessment.planar_margin_m,
    stable,
    status: capture_point_status(height, assessment),
  }
}
