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
pub(all) struct ContactPatchLoadSample {
  probe_id : String
  position : Vec3
  clearance_m : Double
  in_contact : Bool
  load_fraction : Double
  normal_force_n : Double
  pressure_pa : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ContactPatchLoadAssessment {
  patch_id : String
  sample_count : Int
  contact_count : Int
  loaded_sample_count : Int
  total_normal_force_n : Double
  contact_area_m2 : Double
  sample_area_m2 : Double
  center_of_pressure : Vec3
  max_pressure_pa : Double
  average_pressure_pa : Double
  samples : Array[ContactPatchLoadSample]
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ContactPatchWrenchAssessment {
  patch_id : String
  reference_point : Vec3
  surface_normal : Vec3
  center_of_pressure : Vec3
  total_force_n : Vec3
  total_torque_nm : Vec3
  normal_force_n : Double
  loaded_sample_count : Int
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
fn normalized_patch_axis(axis : Vec3, fallback : Vec3) -> Vec3 {
  let length = axis.length()
  if length > 0.0 {
    axis.scale(1.0 / length)
  } else {
    fallback
  }
}

///|
fn contact_patch_oriented_sample(
  field : Heightfield,
  patch_id : String,
  center : Vec3,
  length_axis : Vec3,
  width_axis : Vec3,
  offset_length : Double,
  offset_width : Double,
  contact_tolerance_m : Double,
) -> ContactProbe {
  let position = center
    .add(length_axis.scale(offset_length))
    .add(width_axis.scale(offset_width))
  heightfield_contact_probe(
    field,
    "\{patch_id}/sample/\{offset_length}/\{offset_width}",
    position,
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
fn nonnegative_contact_load(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else {
    value
  }
}

///|
fn contact_patch_area(patch : HeightfieldContactPatch) -> Double {
  nonnegative_contact_load(patch.half_length_m) *
  nonnegative_contact_load(patch.half_width_m) *
  4.0
}

///|
fn contact_sample_weight(probe : ContactProbe) -> Double {
  if probe.in_contact {
    nonnegative_contact_load(0.0 - probe.clearance_m)
  } else {
    0.0
  }
}

///|
fn contact_patch_load_status(
  contact_count : Int,
  loaded_sample_count : Int,
  total_normal_force_n : Double,
) -> String {
  if contact_count <= 0 {
    "patch-load-no-contact"
  } else if total_normal_force_n <= 0.0 {
    "patch-load-no-force"
  } else if loaded_sample_count < contact_count {
    "patch-load-partial-contact-review"
  } else {
    "patch-load-distributed"
  }
}

///|
pub fn contact_patch_load_assessment(
  patch : HeightfieldContactPatch,
  total_normal_force_n : Double,
) -> ContactPatchLoadAssessment {
  let total_force = nonnegative_contact_load(total_normal_force_n)
  let area = contact_patch_area(patch)
  let sample_area = if patch.sample_count > 0 {
    area / patch.sample_count.to_double()
  } else {
    0.0
  }
  let mut weight_sum = 0.0
  for probe in patch.samples {
    weight_sum += contact_sample_weight(probe)
  }
  let equal_contact_weight = weight_sum <= 0.0 && patch.contact_count > 0
  let denominator = if equal_contact_weight {
    patch.contact_count.to_double()
  } else {
    weight_sum
  }
  let samples : Array[ContactPatchLoadSample] = []
  let mut loaded_count = 0
  let mut max_pressure = 0.0
  let mut center = vec3(0.0, 0.0, 0.0)
  for probe in patch.samples {
    let raw_weight = if equal_contact_weight {
      if probe.in_contact {
        1.0
      } else {
        0.0
      }
    } else {
      contact_sample_weight(probe)
    }
    let fraction = if denominator > 0.0 {
      raw_weight / denominator
    } else {
      0.0
    }
    let normal_force = total_force * fraction
    let pressure = if sample_area > 0.0 {
      normal_force / sample_area
    } else {
      0.0
    }
    if normal_force > 0.0 {
      loaded_count += 1
    }
    max_pressure = max_double(max_pressure, pressure)
    center = center.add(probe.position.scale(fraction))
    samples.push({
      probe_id: probe.probe_id,
      position: probe.position,
      clearance_m: probe.clearance_m,
      in_contact: probe.in_contact,
      load_fraction: fraction,
      normal_force_n: normal_force,
      pressure_pa: pressure,
      status: if normal_force > 0.0 {
        "sample-loaded"
      } else if probe.in_contact {
        "sample-contact-unloaded"
      } else {
        "sample-clear"
      },
    })
  }
  let contact_area = sample_area * patch.contact_count.to_double()
  {
    patch_id: patch.patch_id,
    sample_count: patch.sample_count,
    contact_count: patch.contact_count,
    loaded_sample_count: loaded_count,
    total_normal_force_n: total_force,
    contact_area_m2: contact_area,
    sample_area_m2: sample_area,
    center_of_pressure: if denominator > 0.0 {
      center
    } else {
      patch.center
    },
    max_pressure_pa: max_pressure,
    average_pressure_pa: if contact_area > 0.0 {
      total_force / contact_area
    } else {
      0.0
    },
    samples,
    status: contact_patch_load_status(
      patch.contact_count,
      loaded_count,
      total_force,
    ),
  }
}

///|
fn normalized_patch_normal(surface_normal : Vec3) -> Vec3 {
  let length = surface_normal.length()
  if length > 0.0 {
    surface_normal.scale(1.0 / length)
  } else {
    vec3(0.0, 0.0, 1.0)
  }
}

///|
fn contact_patch_wrench_status(
  normal_force_n : Double,
  loaded_sample_count : Int,
) -> String {
  if loaded_sample_count <= 0 {
    "patch-wrench-no-load"
  } else if normal_force_n <= 0.0 {
    "patch-wrench-no-force"
  } else {
    "patch-wrench-resolved"
  }
}

///|
pub fn contact_patch_wrench_assessment(
  load : ContactPatchLoadAssessment,
  reference_point : Vec3,
  surface_normal : Vec3,
) -> ContactPatchWrenchAssessment {
  let normal = normalized_patch_normal(surface_normal)
  let mut force = vec3(0.0, 0.0, 0.0)
  let mut torque = vec3(0.0, 0.0, 0.0)
  for sample in load.samples {
    let sample_force = normal.scale(sample.normal_force_n)
    force = force.add(sample_force)
    torque = torque.add(
      contact_torque(reference_point, sample.position, sample_force),
    )
  }
  {
    patch_id: load.patch_id,
    reference_point,
    surface_normal: normal,
    center_of_pressure: load.center_of_pressure,
    total_force_n: force,
    total_torque_nm: torque,
    normal_force_n: load.total_normal_force_n,
    loaded_sample_count: load.loaded_sample_count,
    status: contact_patch_wrench_status(
      load.total_normal_force_n,
      load.loaded_sample_count,
    ),
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
  heightfield_oriented_contact_patch(
    field,
    patch_id,
    center,
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    half_length_m,
    half_width_m,
    contact_tolerance_m~,
  )
}

///|
pub fn heightfield_oriented_contact_patch(
  field : Heightfield,
  patch_id : String,
  center : Vec3,
  length_axis : Vec3,
  width_axis : Vec3,
  half_length_m : Double,
  half_width_m : Double,
  contact_tolerance_m? : Double = 0.001,
) -> HeightfieldContactPatch {
  let length_basis = normalized_patch_axis(length_axis, vec3(1.0, 0.0, 0.0))
  let width_basis = normalized_patch_axis(width_axis, vec3(0.0, 1.0, 0.0))
  let samples = [
    contact_patch_oriented_sample(
      field, patch_id, center, length_basis, width_basis, 0.0, 0.0, contact_tolerance_m,
    ),
    contact_patch_oriented_sample(
      field, patch_id, center, length_basis, width_basis, half_length_m, half_width_m,
      contact_tolerance_m,
    ),
    contact_patch_oriented_sample(
      field,
      patch_id,
      center,
      length_basis,
      width_basis,
      half_length_m,
      0.0 - half_width_m,
      contact_tolerance_m,
    ),
    contact_patch_oriented_sample(
      field,
      patch_id,
      center,
      length_basis,
      width_basis,
      0.0 - half_length_m,
      half_width_m,
      contact_tolerance_m,
    ),
    contact_patch_oriented_sample(
      field,
      patch_id,
      center,
      length_basis,
      width_basis,
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
