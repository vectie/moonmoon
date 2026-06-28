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
  support_polygon_vertices : Array[Vec3]
  support_polygon_vertex_count : Int
  stable : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupportRecoveryCorrection {
  support_count : Int
  source_point : Vec3
  target_point : Vec3
  required_shift : Vec3
  required_shift_m : Double
  recovered_margin_m : Double
  stable_without_shift : Bool
  recoverable : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupportLoad {
  footprint_id : String
  contact_point : Vec3
  load_fraction : Double
  normal_force_n : Double
  contact_torque_nm : Vec3
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupportLoadAssessment {
  load_count : Int
  center_of_mass : Vec3
  center_of_pressure : Vec3
  center_of_pressure_error_m : Double
  total_normal_force_n : Double
  min_load_fraction : Double
  max_load_fraction : Double
  loads : Array[SupportLoad]
  balanced : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TractionAssessment {
  contact_id : String
  material : MaterialContactModel
  normal_force_n : Double
  tangential_force_n : Double
  friction_limit_n : Double
  utilization : Double
  margin_n : Double
  slipping : Bool
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
fn nonnegative_double(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else {
    value
  }
}

///|
fn clamp_unit(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
pub fn traction_assessment(
  contact_id : String,
  material : MaterialContactModel,
  normal_force_n : Double,
  tangential_force_n : Double,
) -> TractionAssessment {
  let normal = nonnegative_double(normal_force_n)
  let tangential = nonnegative_double(tangential_force_n)
  let limit = nonnegative_double(material.friction_coefficient) * normal
  let utilization = if limit > 0.0 {
    tangential / limit
  } else if tangential > 0.0 {
    1000000000.0
  } else {
    0.0
  }
  let margin = limit - tangential
  let slipping = tangential > limit
  {
    contact_id,
    material,
    normal_force_n: normal,
    tangential_force_n: tangential,
    friction_limit_n: limit,
    utilization,
    margin_n: margin,
    slipping,
    status: if normal <= 0.0 {
      if tangential > 0.0 {
        "no-normal-force-slip"
      } else {
        "no-load"
      }
    } else if slipping {
      "friction-limit-exceeded"
    } else if utilization > 0.8 {
      "friction-margin-low"
    } else {
      "traction-ok"
    },
  }
}

///|
fn normalized_contact_normal(surface_normal : Vec3) -> Vec3 {
  let length = surface_normal.length()
  if length > 0.0 {
    surface_normal.scale(1.0 / length)
  } else {
    vec3(0.0, 0.0, 1.0)
  }
}

///|
pub fn surface_traction_assessment(
  contact_id : String,
  material : MaterialContactModel,
  applied_force_n : Vec3,
  surface_normal : Vec3,
) -> TractionAssessment {
  let normal = normalized_contact_normal(surface_normal)
  let normal_force = nonnegative_double(applied_force_n.dot(normal))
  let tangent_force = applied_force_n.sub(normal.scale(normal_force)).length()
  traction_assessment(contact_id, material, normal_force, tangent_force)
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
fn active_support_footprints(
  footprints : Array[SupportFootprint],
) -> Array[SupportFootprint] {
  let active : Array[SupportFootprint] = []
  for footprint in footprints {
    if footprint.active {
      active.push(footprint)
    }
  }
  active
}

///|
fn footprint_corners(footprint : SupportFootprint) -> Array[Vec3] {
  [
    vec3(
      footprint.center.x - footprint.half_length_m,
      footprint.center.y - footprint.half_width_m,
      footprint.center.z,
    ),
    vec3(
      footprint.center.x + footprint.half_length_m,
      footprint.center.y - footprint.half_width_m,
      footprint.center.z,
    ),
    vec3(
      footprint.center.x + footprint.half_length_m,
      footprint.center.y + footprint.half_width_m,
      footprint.center.z,
    ),
    vec3(
      footprint.center.x - footprint.half_length_m,
      footprint.center.y + footprint.half_width_m,
      footprint.center.z,
    ),
  ]
}

///|
fn support_point_equals(a : Vec3, b : Vec3) -> Bool {
  a.x == b.x && a.y == b.y
}

///|
fn support_point_distance_squared(a : Vec3, b : Vec3) -> Double {
  let dx = a.x - b.x
  let dy = a.y - b.y
  dx * dx + dy * dy
}

///|
fn support_orientation(a : Vec3, b : Vec3, c : Vec3) -> Double {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
fn support_leftmost_point(points : Array[Vec3]) -> Vec3 {
  let mut candidate = points[0]
  for point in points {
    if point.x < candidate.x ||
      (point.x == candidate.x && point.y < candidate.y) {
      candidate = point
    }
  }
  candidate
}

///|
fn support_unique_points(points : Array[Vec3]) -> Array[Vec3] {
  let unique : Array[Vec3] = []
  for point in points {
    if !unique.any(fn(existing) { support_point_equals(existing, point) }) {
      unique.push(point)
    }
  }
  unique
}

///|
fn support_polygon(points : Array[Vec3]) -> Array[Vec3] {
  let unique = support_unique_points(points)
  if unique.length() < 3 {
    unique
  } else {
    let hull : Array[Vec3] = []
    let start = support_leftmost_point(unique)
    let mut current = start
    let mut done = false
    while !done {
      hull.push(current)
      let mut candidate = unique[0]
      if support_point_equals(candidate, current) {
        candidate = unique[1]
      }
      for point in unique {
        if support_point_equals(point, current) {
          continue
        }
        let orientation = support_orientation(current, candidate, point)
        if orientation < 0.0 ||
          (
            orientation == 0.0 &&
            support_point_distance_squared(current, point) >
            support_point_distance_squared(current, candidate)
          ) {
          candidate = point
        }
      }
      current = candidate
      done = support_point_equals(current, start)
    }
    hull
  }
}

///|
fn support_polygon_margin(point : Vec3, polygon : Array[Vec3]) -> Double {
  if polygon.length() < 3 {
    0.0 - support_point_distance_squared(point, polygon[0]).sqrt()
  } else {
    let mut margin = 0.0
    for index, a in polygon {
      let b = polygon[(index + 1) % polygon.length()]
      let edge_x = b.x - a.x
      let edge_y = b.y - a.y
      let edge_length = (edge_x * edge_x + edge_y * edge_y).sqrt()
      let signed_distance = if edge_length > 0.0 {
        (edge_x * (point.y - a.y) - edge_y * (point.x - a.x)) / edge_length
      } else {
        0.0
      }
      if index == 0 || signed_distance < margin {
        margin = signed_distance
      }
    }
    margin
  }
}

///|
fn support_segment_parameter(point : Vec3, a : Vec3, b : Vec3) -> Double {
  let dx = b.x - a.x
  let dy = b.y - a.y
  let length_squared = dx * dx + dy * dy
  if length_squared > 0.0 {
    clamp_unit(((point.x - a.x) * dx + (point.y - a.y) * dy) / length_squared)
  } else {
    0.0
  }
}

///|
fn support_lerp(a : Vec3, b : Vec3, t : Double) -> Vec3 {
  vec3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
}

///|
fn support_planar_distance(a : Vec3, b : Vec3) -> Double {
  support_point_distance_squared(a, b).sqrt()
}

///|
fn support_polygon_centroid(polygon : Array[Vec3], fallback : Vec3) -> Vec3 {
  if polygon.is_empty() {
    fallback
  } else {
    let mut center = vec3(0.0, 0.0, 0.0)
    for point in polygon {
      center = center.add(point)
    }
    center.scale(1.0 / polygon.length().to_double())
  }
}

///|
fn support_closest_polygon_point(point : Vec3, polygon : Array[Vec3]) -> Vec3 {
  if polygon.is_empty() {
    point
  } else if polygon.length() == 1 {
    polygon[0]
  } else {
    let mut closest = polygon[0]
    let mut best_distance = support_planar_distance(point, closest)
    for index, a in polygon {
      let b = polygon[(index + 1) % polygon.length()]
      let candidate = support_lerp(a, b, support_segment_parameter(point, a, b))
      let distance = support_planar_distance(point, candidate)
      if distance < best_distance {
        best_distance = distance
        closest = candidate
      }
    }
    closest
  }
}

///|
fn support_shift_status(
  assessment : SupportAssessment,
  recoverable : Bool,
  shift_m : Double,
) -> String {
  if assessment.support_count <= 0 {
    "support-recovery-no-support"
  } else if assessment.stable {
    "support-recovery-not-needed"
  } else if !recoverable {
    "support-recovery-unavailable"
  } else if shift_m <= 0.000001 {
    "support-recovery-boundary"
  } else {
    "support-recovery-shift-required"
  }
}

///|
pub fn support_recovery_correction(
  point : Vec3,
  footprints : Array[SupportFootprint],
  inward_margin_m? : Double = 0.0,
) -> SupportRecoveryCorrection {
  let assessment = support_assessment(point, footprints)
  if assessment.support_count <= 0 {
    {
      support_count: 0,
      source_point: point,
      target_point: point,
      required_shift: vec3(0.0, 0.0, 0.0),
      required_shift_m: 0.0,
      recovered_margin_m: assessment.planar_margin_m,
      stable_without_shift: false,
      recoverable: false,
      status: support_shift_status(assessment, false, 0.0),
    }
  } else if assessment.stable {
    {
      support_count: assessment.support_count,
      source_point: point,
      target_point: point,
      required_shift: vec3(0.0, 0.0, 0.0),
      required_shift_m: 0.0,
      recovered_margin_m: assessment.planar_margin_m,
      stable_without_shift: true,
      recoverable: true,
      status: support_shift_status(assessment, true, 0.0),
    }
  } else {
    let polygon = assessment.support_polygon_vertices
    let boundary = support_closest_polygon_point(point, polygon)
    let centroid = support_polygon_centroid(polygon, boundary)
    let boundary_at_source_z = vec3(boundary.x, boundary.y, point.z)
    let centroid_at_source_z = vec3(centroid.x, centroid.y, point.z)
    let boundary_to_centroid = support_planar_distance(
      boundary_at_source_z, centroid_at_source_z,
    )
    let inward_t = if inward_margin_m > 0.0 && boundary_to_centroid > 0.0 {
      clamp_unit(inward_margin_m / boundary_to_centroid)
    } else {
      0.0
    }
    let target = support_lerp(
      boundary_at_source_z, centroid_at_source_z, inward_t,
    )
    let shift = target.sub(point)
    let shift_m = support_planar_distance(point, target)
    let recovered = support_assessment(target, footprints)
    let recoverable = recovered.stable || recovered.planar_margin_m >= 0.0
    {
      support_count: assessment.support_count,
      source_point: point,
      target_point: target,
      required_shift: shift,
      required_shift_m: shift_m,
      recovered_margin_m: recovered.planar_margin_m,
      stable_without_shift: false,
      recoverable,
      status: support_shift_status(assessment, recoverable, shift_m),
    }
  }
}

///|
fn support_empty_fractions(count : Int) -> Array[Double] {
  let fractions : Array[Double] = []
  for _ in 0..<count {
    fractions.push(0.0)
  }
  fractions
}

///|
fn support_normalized_triangle_fractions(
  u : Double,
  v : Double,
  w : Double,
) -> Array[Double] {
  let clamped_u = nonnegative_double(u)
  let clamped_v = nonnegative_double(v)
  let clamped_w = nonnegative_double(w)
  let total = clamped_u + clamped_v + clamped_w
  if total > 0.0 {
    [clamped_u / total, clamped_v / total, clamped_w / total]
  } else {
    [0.0, 0.0, 0.0]
  }
}

///|
fn support_try_triangle_fractions(
  point : Vec3,
  a : Vec3,
  b : Vec3,
  c : Vec3,
) -> Array[Double] {
  let v0_x = b.x - a.x
  let v0_y = b.y - a.y
  let v1_x = c.x - a.x
  let v1_y = c.y - a.y
  let v2_x = point.x - a.x
  let v2_y = point.y - a.y
  let d00 = v0_x * v0_x + v0_y * v0_y
  let d01 = v0_x * v1_x + v0_y * v1_y
  let d11 = v1_x * v1_x + v1_y * v1_y
  let d20 = v2_x * v0_x + v2_y * v0_y
  let d21 = v2_x * v1_x + v2_y * v1_y
  let denom = d00 * d11 - d01 * d01
  if denom == 0.0 {
    []
  } else {
    let v = (d11 * d20 - d01 * d21) / denom
    let w = (d00 * d21 - d01 * d20) / denom
    let u = 1.0 - v - w
    if u >= 0.0 - 0.0000001 && v >= 0.0 - 0.0000001 && w >= 0.0 - 0.0000001 {
      support_normalized_triangle_fractions(u, v, w)
    } else {
      []
    }
  }
}

///|
fn support_load_fractions(
  point : Vec3,
  active : Array[SupportFootprint],
) -> Array[Double] {
  if active.is_empty() {
    []
  } else if active.length() == 1 {
    [1.0]
  } else {
    if active.length() >= 3 {
      for i in 0..<active.length() {
        for j in (i + 1)..<active.length() {
          for k in (j + 1)..<active.length() {
            let triangle = support_try_triangle_fractions(
              point,
              active[i].center,
              active[j].center,
              active[k].center,
            )
            if !triangle.is_empty() {
              let fractions = support_empty_fractions(active.length())
              fractions[i] = triangle[0]
              fractions[j] = triangle[1]
              fractions[k] = triangle[2]
              return fractions
            }
          }
        }
      }
    }
    let fractions = support_empty_fractions(active.length())
    let mut first_index = 0
    let mut second_index = 1
    let mut best_t = support_segment_parameter(
      point,
      active[0].center,
      active[1].center,
    )
    let mut best_error = support_planar_distance(
      point,
      support_lerp(active[0].center, active[1].center, best_t),
    )
    for i in 0..<active.length() {
      for j in (i + 1)..<active.length() {
        let t = support_segment_parameter(
          point,
          active[i].center,
          active[j].center,
        )
        let error = support_planar_distance(
          point,
          support_lerp(active[i].center, active[j].center, t),
        )
        if error < best_error {
          first_index = i
          second_index = j
          best_t = t
          best_error = error
        }
      }
    }
    fractions[first_index] = 1.0 - best_t
    fractions[second_index] = best_t
    fractions
  }
}

///|
fn support_weighted_center(
  active : Array[SupportFootprint],
  fractions : Array[Double],
) -> Vec3 {
  let mut center = vec3(0.0, 0.0, 0.0)
  for index, footprint in active {
    center = center.add(footprint.center.scale(fractions[index]))
  }
  center
}

///|
fn support_load_status(
  support : SupportAssessment,
  active_count : Int,
  total_normal_force_n : Double,
  center_error_m : Double,
) -> String {
  if active_count <= 0 {
    "no-support-load"
  } else if total_normal_force_n <= 0.0 {
    "no-normal-load"
  } else if !support.stable {
    "outside-support-load-review"
  } else if active_count == 1 {
    "single-support-load"
  } else if center_error_m <= 0.000001 {
    "center-load-balanced"
  } else {
    "footprint-area-load-review"
  }
}

///|
pub fn support_load_assessment(
  center_of_mass : Vec3,
  footprints : Array[SupportFootprint],
  total_normal_force_n : Double,
) -> SupportLoadAssessment {
  let total_force = nonnegative_double(total_normal_force_n)
  let active = active_support_footprints(footprints)
  let support = support_assessment(center_of_mass, footprints)
  if active.is_empty() {
    {
      load_count: 0,
      center_of_mass,
      center_of_pressure: center_of_mass,
      center_of_pressure_error_m: 0.0,
      total_normal_force_n: total_force,
      min_load_fraction: 0.0,
      max_load_fraction: 0.0,
      loads: [],
      balanced: false,
      status: "no-support-load",
    }
  } else {
    let fractions = support_load_fractions(center_of_mass, active)
    let center_of_pressure = support_weighted_center(active, fractions)
    let center_error = support_planar_distance(
      center_of_mass, center_of_pressure,
    )
    let loads : Array[SupportLoad] = []
    let mut min_fraction = fractions[0]
    let mut max_fraction = fractions[0]
    for index, footprint in active {
      let fraction = fractions[index]
      min_fraction = min_double(min_fraction, fraction)
      max_fraction = max_double(max_fraction, fraction)
      let normal_force = total_force * fraction
      let force = vec3(0.0, 0.0, normal_force)
      loads.push({
        footprint_id: footprint.footprint_id,
        contact_point: footprint.center,
        load_fraction: fraction,
        normal_force_n: normal_force,
        contact_torque_nm: contact_torque(
          center_of_mass,
          footprint.center,
          force,
        ),
        status: if normal_force > 0.0 {
          "loaded"
        } else {
          "unloaded"
        },
      })
    }
    let status = support_load_status(
      support,
      active.length(),
      total_force,
      center_error,
    )
    {
      load_count: loads.length(),
      center_of_mass,
      center_of_pressure,
      center_of_pressure_error_m: center_error,
      total_normal_force_n: total_force,
      min_load_fraction: min_fraction,
      max_load_fraction: max_fraction,
      loads,
      balanced: status == "single-support-load" ||
      status == "center-load-balanced",
      status,
    }
  }
}

///|
pub fn support_assessment(
  com_projection : Vec3,
  footprints : Array[SupportFootprint],
) -> SupportAssessment {
  let active = active_support_footprints(footprints)
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
      support_polygon_vertices: [],
      support_polygon_vertex_count: 0,
      stable: false,
      status: "no-support",
    }
  } else {
    let first = active[0]
    let points : Array[Vec3] = []
    let mut min_x = first.center.x - first.half_length_m
    let mut max_x = first.center.x + first.half_length_m
    let mut min_y = first.center.y - first.half_width_m
    let mut max_y = first.center.y + first.half_width_m
    for footprint in active {
      for corner in footprint_corners(footprint) {
        points.push(corner)
      }
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
    let polygon = support_polygon(points)
    let planar_margin = support_polygon_margin(com_projection, polygon)
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
      support_polygon_vertices: polygon,
      support_polygon_vertex_count: polygon.length(),
      stable,
      status: if stable {
        "inside-support"
      } else {
        "outside-support"
      },
    }
  }
}
