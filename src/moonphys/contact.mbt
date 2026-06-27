///|
pub(all) struct ContactProbe {
  probe_id : String
  position : Vec3
  surface_elevation_m : Double
  surface_normal : Vec3
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct HeightfieldContactPatch {
  patch_id : String
  center : Vec3
  half_length_m : Double
  half_width_m : Double
  sample_count : Int
  contact_count : Int
  min_clearance_m : Double
  max_clearance_m : Double
  average_surface_elevation_m : Double
  average_surface_normal : Vec3
  samples : Array[ContactProbe]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn heightfield_contact_probe(
  field : Heightfield,
  probe_id : String,
  position : Vec3,
  contact_tolerance_m? : Double = 0.001,
) -> ContactProbe {
  let sample = sample_heightfield(field, position.x, position.y)
  let clearance_m = position.z - sample.elevation_m
  let in_contact = clearance_m <= contact_tolerance_m
  {
    probe_id,
    position,
    surface_elevation_m: sample.elevation_m,
    surface_normal: sample.surface_normal,
    clearance_m,
    in_contact,
    local_grade: max_double(sample.local_grade_x, sample.local_grade_y),
    status: if in_contact {
      "contact"
    } else {
      "clear"
    },
  }
}

///|
fn contact_patch_sample(
  field : Heightfield,
  patch_id : String,
  center : Vec3,
  offset_x : Double,
  offset_y : Double,
  contact_tolerance_m : Double,
) -> ContactProbe {
  heightfield_contact_probe(
    field,
    "\{patch_id}/sample/\{offset_x}/\{offset_y}",
    vec3(center.x + offset_x, center.y + offset_y, center.z),
    contact_tolerance_m~,
  )
}

///|
fn contact_patch_average_normal(samples : Array[ContactProbe]) -> Vec3 {
  let mut normal = vec3(0.0, 0.0, 0.0)
  for probe in samples {
    normal = normal.add(probe.surface_normal)
  }
  if samples.is_empty() {
    vec3(0.0, 0.0, 1.0)
  } else {
    let averaged = normal.scale(1.0 / samples.length().to_double())
    let length = averaged.length()
    if length > 0.0 {
      averaged.scale(1.0 / length)
    } else {
      vec3(0.0, 0.0, 1.0)
    }
  }
}

///|
fn contact_patch_status(
  contact_count : Int,
  sample_count : Int,
  min_clearance_m : Double,
  contact_tolerance_m : Double,
) -> String {
  if contact_count <= 0 {
    "patch-clear"
  } else if min_clearance_m < 0.0 - contact_tolerance_m {
    "patch-penetration-review"
  } else if contact_count < sample_count {
    "patch-partial-contact-review"
  } else {
    "patch-contact"
  }
}

///|
pub fn heightfield_contact_patch(
  field : Heightfield,
  patch_id : String,
  center : Vec3,
  half_length_m : Double,
  half_width_m : Double,
  contact_tolerance_m? : Double = 0.001,
) -> HeightfieldContactPatch {
  let samples = [
    contact_patch_sample(field, patch_id, center, 0.0, 0.0, contact_tolerance_m),
    contact_patch_sample(
      field, patch_id, center, half_length_m, half_width_m, contact_tolerance_m,
    ),
    contact_patch_sample(
      field,
      patch_id,
      center,
      half_length_m,
      0.0 - half_width_m,
      contact_tolerance_m,
    ),
    contact_patch_sample(
      field,
      patch_id,
      center,
      0.0 - half_length_m,
      half_width_m,
      contact_tolerance_m,
    ),
    contact_patch_sample(
      field,
      patch_id,
      center,
      0.0 - half_length_m,
      0.0 - half_width_m,
      contact_tolerance_m,
    ),
  ]
  let first = samples[0]
  let mut contact_count = 0
  let mut min_clearance = first.clearance_m
  let mut max_clearance = first.clearance_m
  let mut elevation_sum = 0.0
  for probe in samples {
    if probe.in_contact {
      contact_count += 1
    }
    min_clearance = min_double(min_clearance, probe.clearance_m)
    max_clearance = max_double(max_clearance, probe.clearance_m)
    elevation_sum += probe.surface_elevation_m
  }
  {
    patch_id,
    center,
    half_length_m,
    half_width_m,
    sample_count: samples.length(),
    contact_count,
    min_clearance_m: min_clearance,
    max_clearance_m: max_clearance,
    average_surface_elevation_m: elevation_sum / samples.length().to_double(),
    average_surface_normal: contact_patch_average_normal(samples),
    samples,
    status: contact_patch_status(
      contact_count,
      samples.length(),
      min_clearance,
      contact_tolerance_m,
    ),
  }
}
