///|
pub(all) struct SupportFootprint {
  footprint_id : String
  center : Vec3
  half_length_m : Double
  half_width_m : Double
  active : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupportAssessment {
  support_count : Int
  com_projection : Vec3
  min_x_m : Double
  max_x_m : Double
  min_y_m : Double
  max_y_m : Double
  margin_x_m : Double
  margin_y_m : Double
  planar_margin_m : Double
  stable : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn support_footprint(
  footprint_id : String,
  center : Vec3,
  half_length_m : Double,
  half_width_m : Double,
  active? : Bool = true,
) -> SupportFootprint {
  { footprint_id, center, half_length_m, half_width_m, active }
}

///|
fn min_double(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_double(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn support_assessment(
  com_projection : Vec3,
  footprints : Array[SupportFootprint],
) -> SupportAssessment {
  let active : Array[SupportFootprint] = []
  for footprint in footprints {
    if footprint.active {
      active.push(footprint)
    }
  }
  if active.is_empty() {
    {
      support_count: 0,
      com_projection,
      min_x_m: 0.0,
      max_x_m: 0.0,
      min_y_m: 0.0,
      max_y_m: 0.0,
      margin_x_m: 0.0 - 1.0,
      margin_y_m: 0.0 - 1.0,
      planar_margin_m: 0.0 - 1.0,
      stable: false,
      status: "no-support",
    }
  } else {
    let first = active[0]
    let mut min_x = first.center.x - first.half_length_m
    let mut max_x = first.center.x + first.half_length_m
    let mut min_y = first.center.y - first.half_width_m
    let mut max_y = first.center.y + first.half_width_m
    for footprint in active {
      min_x = min_double(min_x, footprint.center.x - footprint.half_length_m)
      max_x = max_double(max_x, footprint.center.x + footprint.half_length_m)
      min_y = min_double(min_y, footprint.center.y - footprint.half_width_m)
      max_y = max_double(max_y, footprint.center.y + footprint.half_width_m)
    }
    let margin_x = min_double(
      com_projection.x - min_x,
      max_x - com_projection.x,
    )
    let margin_y = min_double(
      com_projection.y - min_y,
      max_y - com_projection.y,
    )
    let planar_margin = min_double(margin_x, margin_y)
    let stable = planar_margin >= 0.0
    {
      support_count: active.length(),
      com_projection,
      min_x_m: min_x,
      max_x_m: max_x,
      min_y_m: min_y,
      max_y_m: max_y,
      margin_x_m: margin_x,
      margin_y_m: margin_y,
      planar_margin_m: planar_margin,
      stable,
      status: if stable {
        "inside-support"
      } else {
        "outside-support"
      },
    }
  }
}
