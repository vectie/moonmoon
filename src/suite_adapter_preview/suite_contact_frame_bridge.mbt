///|
fn generated_vec3_to_suite_sample(
  value : RabbitaNoetixGeneratedVec3,
) -> SuiteAdapterVec3Sample {
  { x: value.x, y: value.y, z: value.z }
}

///|
fn suite_vec3_to_generated(
  value : SuiteAdapterVec3Sample,
) -> RabbitaNoetixGeneratedVec3 {
  { x: value.x, y: value.y, z: value.z }
}

///|
fn generated_footprint_to_suite_sample(
  value : RabbitaNoetixGeneratedFootprint,
) -> SuiteAdapterFootprintSample {
  {
    footprint_id: value.footprint_id,
    center: generated_vec3_to_suite_sample(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    active: value.active,
  }
}

///|
fn suite_footprint_to_generated(
  value : SuiteAdapterFootprintSample,
) -> RabbitaNoetixGeneratedFootprint {
  {
    footprint_id: value.footprint_id,
    center: suite_vec3_to_generated(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    active: value.active,
  }
}

///|
fn generated_contact_probe_to_suite_sample(
  value : RabbitaNoetixGeneratedContactProbe,
) -> SuiteAdapterContactProbeSample {
  {
    probe_id: value.probe_id,
    position: generated_vec3_to_suite_sample(value.position),
    surface_elevation_m: value.surface_elevation_m,
    surface_normal: generated_vec3_to_suite_sample(value.surface_normal),
    clearance_m: value.clearance_m,
    in_contact: value.in_contact,
    local_grade: value.local_grade,
    status: value.status,
  }
}

///|
fn suite_contact_probe_to_generated(
  value : SuiteAdapterContactProbeSample,
) -> RabbitaNoetixGeneratedContactProbe {
  {
    probe_id: value.probe_id,
    position: suite_vec3_to_generated(value.position),
    surface_elevation_m: value.surface_elevation_m,
    surface_normal: suite_vec3_to_generated(value.surface_normal),
    clearance_m: value.clearance_m,
    in_contact: value.in_contact,
    local_grade: value.local_grade,
    status: value.status,
  }
}

///|
fn generated_contact_patch_to_suite_sample(
  value : RabbitaNoetixGeneratedContactPatch,
) -> SuiteAdapterContactPatchSample {
  {
    patch_id: value.patch_id,
    center: generated_vec3_to_suite_sample(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    sample_count: value.sample_count,
    contact_count: value.contact_count,
    min_clearance_m: value.min_clearance_m,
    max_clearance_m: value.max_clearance_m,
    average_surface_elevation_m: value.average_surface_elevation_m,
    average_surface_normal: generated_vec3_to_suite_sample(
      value.average_surface_normal,
    ),
    samples: value.samples.map(generated_contact_probe_to_suite_sample),
    status: value.status,
  }
}

///|
fn suite_contact_patch_to_generated(
  value : SuiteAdapterContactPatchSample,
) -> RabbitaNoetixGeneratedContactPatch {
  {
    patch_id: value.patch_id,
    center: suite_vec3_to_generated(value.center),
    half_length_m: value.half_length_m,
    half_width_m: value.half_width_m,
    sample_count: value.sample_count,
    contact_count: value.contact_count,
    min_clearance_m: value.min_clearance_m,
    max_clearance_m: value.max_clearance_m,
    average_surface_elevation_m: value.average_surface_elevation_m,
    average_surface_normal: suite_vec3_to_generated(
      value.average_surface_normal,
    ),
    samples: value.samples.map(suite_contact_probe_to_generated),
    status: value.status,
  }
}

///|
fn generated_contact_to_suite_sample(
  value : RabbitaNoetixGeneratedContact,
) -> SuiteAdapterContactEvidenceSample {
  {
    contact_id: value.contact_id,
    footprint: generated_footprint_to_suite_sample(value.footprint),
    patch: generated_contact_patch_to_suite_sample(value.patch),
    applied_force_n: generated_vec3_to_suite_sample(value.applied_force_n),
  }
}

///|
fn suite_contact_to_generated(
  value : SuiteAdapterContactEvidenceSample,
) -> RabbitaNoetixGeneratedContact {
  {
    contact_id: value.contact_id,
    footprint: suite_footprint_to_generated(value.footprint),
    patch: suite_contact_patch_to_generated(value.patch),
    applied_force_n: suite_vec3_to_generated(value.applied_force_n),
  }
}

///|
fn generated_contact_frame_to_suite_sample(
  frame_index : Int,
  sample_count : Int,
  value : RabbitaNoetixGeneratedMotionFrame,
) -> SuiteAdapterContactFrameSample {
  let active_footprint_count = value.contacts.fold(init=0, fn(count, contact) {
    if contact.footprint.active {
      count + 1
    } else {
      count
    }
  })
  {
    frame_index,
    time_s: value.time_s,
    phase: frame_index.to_double() / sample_count.to_double(),
    phase_label: value.phase_label,
    support_foot: value.support_foot,
    review_id: value.review_id,
    center_of_mass: generated_vec3_to_suite_sample(value.center_of_mass),
    center_of_mass_velocity: generated_vec3_to_suite_sample(
      value.center_of_mass_velocity,
    ),
    total_mass_kg: value.total_mass_kg,
    contact_count: value.contacts.length(),
    active_footprint_count,
    contacts: value.contacts.map(generated_contact_to_suite_sample),
    status: "moonrobo-suite-contact-frame-ready",
  }
}

///|
fn suite_contact_frame_to_generated(
  value : SuiteAdapterContactFrameSample,
) -> RabbitaNoetixGeneratedMotionFrame {
  {
    time_s: value.time_s,
    phase_label: value.phase_label,
    support_foot: value.support_foot,
    review_id: value.review_id,
    center_of_mass: suite_vec3_to_generated(value.center_of_mass),
    center_of_mass_velocity: suite_vec3_to_generated(
      value.center_of_mass_velocity,
    ),
    total_mass_kg: value.total_mass_kg,
    contacts: value.contacts.map(suite_contact_to_generated),
  }
}

///|
fn suite_contact_frames_for_review(
  frames : Array[SuiteAdapterContactFrameSample],
) -> Array[RabbitaNoetixGeneratedMotionFrame] {
  frames.map(suite_contact_frame_to_generated)
}

///|
fn generated_moonrobo_noetix_suite_contact_frames() -> Array[
  SuiteAdapterContactFrameSample,
] {
  let frames : Array[SuiteAdapterContactFrameSample] = []
  let sample_count = generated_moonrobo_noetix_walk_sample_count()
  for index, frame in generated_moonrobo_noetix_contact_frames() {
    frames.push(
      generated_contact_frame_to_suite_sample(index, sample_count, frame),
    )
  }
  frames
}
