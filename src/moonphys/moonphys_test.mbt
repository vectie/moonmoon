///|
test "vec3 math is deterministic" {
  let a = vec3(1.0, 2.0, 3.0)
  let b = vec3(4.0, 5.0, 6.0)
  assert_true(a.add(b) == vec3(5.0, 7.0, 9.0))
  assert_true(b.sub(a) == vec3(3.0, 3.0, 3.0))
  assert_true(a.scale(2.0) == vec3(2.0, 4.0, 6.0))
  assert_true(
    vec3(1.0, 0.0, 0.0).cross(vec3(0.0, 1.0, 0.0)) == vec3(0.0, 0.0, 1.0),
  )
  inspect(a.dot(b), content="32")
}

///|
fn nearly_equal(a : Double, b : Double) -> Bool {
  let delta = a - b
  let absolute = if delta < 0.0 { 0.0 - delta } else { delta }
  absolute < 0.0000001
}

///|
test "heightfield sample wraps along x" {
  let field = heightfield("test-field", 1, 2, 10.0, [1.0, 4.0])
  let sample = sample_heightfield(field, 21.0, 0.0)
  assert_eq(sample.col, 0)
  assert_true(nearly_equal(sample.elevation_m, 1.3))
  inspect(sample.local_grade_x, content="0.3")
}

///|
test "heightfield sample bilinearly interpolates elevation and normal" {
  let field = heightfield("slope-field", 2, 2, 1.0, [0.0, 1.0, 2.0, 3.0])
  let sample = sample_heightfield(field, 0.5, -0.5)
  assert_eq(sample.row, 0)
  assert_eq(sample.col, 0)
  assert_true(nearly_equal(sample.elevation_m, 1.5))
  assert_true(nearly_equal(sample.local_grade_x, 1.0))
  assert_true(nearly_equal(sample.local_grade_y, 2.0))
  assert_true(sample.surface_normal.x < 0.0)
  assert_true(sample.surface_normal.y < 0.0)
  assert_true(sample.surface_normal.z > 0.0)
  assert_true(nearly_equal(sample.surface_normal.length(), 1.0))
}

///|
test "contact probe detects clearance" {
  let field = heightfield("test-field", 1, 1, 10.0, [2.0])
  let probe = heightfield_contact_probe(field, "foot", vec3(0.0, 0.0, 2.5))
  assert_true(!probe.in_contact)
  inspect(probe.clearance_m, content="0.5")
  assert_true(probe.surface_normal == vec3(0.0, 0.0, 1.0))
}

///|
test "heightfield contact patch samples rectangular sole" {
  let field = heightfield("flat-field", 1, 1, 1.0, [0.0])
  let patch = heightfield_contact_patch(
    field,
    "sole",
    vec3(0.0, 0.0, 0.0),
    0.2,
    0.1,
  )
  assert_eq(patch.sample_count, 5)
  assert_eq(patch.contact_count, 5)
  assert_eq(patch.status, "patch-contact")
  assert_true(nearly_equal(patch.min_clearance_m, 0.0))
  assert_true(nearly_equal(patch.max_clearance_m, 0.0))
  assert_true(patch.average_surface_normal == vec3(0.0, 0.0, 1.0))
}

///|
test "contact patch load distributes normal force over samples" {
  let field = heightfield("flat-field", 1, 1, 1.0, [0.0])
  let patch = heightfield_contact_patch(
    field,
    "sole",
    vec3(0.0, 0.0, 0.0),
    0.2,
    0.1,
  )
  let load = contact_patch_load_assessment(patch, 100.0)
  assert_eq(load.sample_count, 5)
  assert_eq(load.contact_count, 5)
  assert_eq(load.loaded_sample_count, 5)
  assert_true(nearly_equal(load.center_of_pressure.x, 0.0))
  assert_true(nearly_equal(load.center_of_pressure.y, 0.0))
  assert_true(nearly_equal(load.samples[0].normal_force_n, 20.0))
  assert_true(nearly_equal(load.contact_area_m2, 0.08))
  assert_true(nearly_equal(load.max_pressure_pa, 1250.0))
  assert_eq(load.status, "patch-load-distributed")
}

///|
test "contact patch wrench integrates sample loads" {
  let field = heightfield("flat-field", 1, 1, 1.0, [0.0])
  let patch = heightfield_contact_patch(
    field,
    "sole",
    vec3(0.0, 0.0, 0.0),
    0.2,
    0.1,
  )
  let load = contact_patch_load_assessment(patch, 100.0)
  let wrench = contact_patch_wrench_assessment(
    load,
    vec3(0.1, 0.0, 0.0),
    vec3(0.0, 0.0, 2.0),
  )
  assert_true(nearly_equal(wrench.total_force_n.x, 0.0))
  assert_true(nearly_equal(wrench.total_force_n.y, 0.0))
  assert_true(nearly_equal(wrench.total_force_n.z, 100.0))
  assert_true(nearly_equal(wrench.total_torque_nm.x, 0.0))
  assert_true(nearly_equal(wrench.total_torque_nm.y, 10.0))
  assert_true(nearly_equal(wrench.total_torque_nm.z, 0.0))
  assert_eq(wrench.status, "patch-wrench-resolved")
}

///|
test "contact patch load flags partial contact pressure" {
  let field = heightfield("slope-field", 2, 2, 1.0, [0.0, 1.0, 0.0, 1.0])
  let patch = heightfield_contact_patch(
    field,
    "sole",
    vec3(0.5, -0.5, 0.5),
    0.25,
    0.1,
  )
  let load = contact_patch_load_assessment(patch, 100.0)
  assert_true(load.contact_count > 0)
  assert_true(load.loaded_sample_count < load.sample_count)
  assert_true(load.max_pressure_pa > load.average_pressure_pa)
  assert_eq(load.status, "patch-load-partial-contact-review")
}

///|
test "heightfield contact patch exposes partial sole penetration" {
  let field = heightfield("slope-field", 2, 2, 1.0, [0.0, 1.0, 0.0, 1.0])
  let patch = heightfield_contact_patch(
    field,
    "sole",
    vec3(0.5, -0.5, 0.5),
    0.25,
    0.1,
  )
  assert_eq(patch.sample_count, 5)
  assert_true(patch.contact_count > 0)
  assert_true(patch.contact_count < patch.sample_count)
  assert_true(patch.min_clearance_m < 0.0)
  assert_true(patch.max_clearance_m > 0.0)
  assert_eq(patch.status, "patch-penetration-review")
  assert_true(patch.average_surface_normal.x < 0.0)
}

///|
test "kinematic integration applies acceleration" {
  let state = kinematic_body_state(
    "body",
    vec3(0.0, 0.0, 1.0),
    vec3(1.0, 0.0, 0.0),
  )
  let stepped = integrate_kinematic(state, {
    dt_s: 0.5,
    acceleration: vec3(0.0, 0.0, -2.0),
  })
  assert_true(stepped.position == vec3(0.5, 0.0, 0.5))
  assert_true(stepped.velocity == vec3(1.0, 0.0, -1.0))
}

///|
test "rigid body gravity integration uses semi implicit step" {
  let state = rigid_body_state(
    "body",
    4.0,
    0.25,
    vec3(0.0, 0.0, 2.0),
    vec3(1.0, 0.0, 0.0),
  )
  let stepped = integrate_rigid_body_gravity(state, lunar_environment(), 0.5)
  assert_true(stepped.position == vec3(0.5, 0.0, 1.59375))
  assert_true(stepped.velocity == vec3(1.0, 0.0, -0.8125))
}

///|
test "heightfield collision reports penetration and tangent speed" {
  let field = heightfield("test-field", 1, 1, 10.0, [1.0])
  let state = rigid_body_state(
    "body",
    4.0,
    0.2,
    vec3(0.0, 0.0, 1.1),
    vec3(3.0, 4.0, -2.0),
  )
  let collision = heightfield_collision(field, state)
  assert_true(collision.in_contact)
  assert_true(nearly_equal(collision.clearance_m, -0.1))
  assert_true(nearly_equal(collision.penetration_depth_m, 0.1))
  assert_true(nearly_equal(collision.tangent_speed_mps, 5.0))
  assert_eq(collision.status, "heightfield-contact")
}

///|
test "heightfield contact response clamps and damps velocity" {
  let field = heightfield("test-field", 1, 1, 10.0, [1.0])
  let state = rigid_body_state(
    "body",
    4.0,
    0.2,
    vec3(0.0, 0.0, 1.1),
    vec3(2.0, 0.0, -3.0),
  )
  let material = material_contact_model("test-regolith", 0.25, 0.1)
  let resolved = resolve_heightfield_contact(field, state, material)
  assert_eq(resolved.status, "contact-resolved")
  assert_true(resolved.after.position == vec3(0.0, 0.0, 1.2))
  assert_true(nearly_equal(resolved.after.velocity.x, 1.5))
  assert_true(nearly_equal(resolved.after.velocity.y, 0.0))
  assert_true(nearly_equal(resolved.after.velocity.z, 0.3))
}

///|
test "heightfield contact response follows slope normal" {
  let field = heightfield("slope-field", 2, 2, 1.0, [0.0, 1.0, 0.0, 1.0])
  let state = rigid_body_state(
    "body",
    4.0,
    0.1,
    vec3(0.5, -0.5, 0.55),
    vec3(0.0, 0.0, -1.0),
  )
  let resolved = resolve_heightfield_contact(
    field,
    state,
    material_contact_model("test-regolith", 1.0, 0.0),
  )
  assert_eq(resolved.status, "contact-resolved")
  assert_true(resolved.collision.surface_normal.x < 0.0)
  assert_true(resolved.collision.surface_normal.z > 0.0)
  assert_true(resolved.collision.normal_velocity_mps > -1.0)
  assert_true(resolved.after.position.x < state.position.x)
  assert_true(resolved.after.position.z > state.position.z)
  assert_true(nearly_equal(resolved.after.velocity.length(), 0.0))
}

///|
test "heightfield contact response leaves clear body unchanged" {
  let field = heightfield("test-field", 1, 1, 10.0, [1.0])
  let state = rigid_body_state(
    "body",
    4.0,
    0.2,
    vec3(0.0, 0.0, 2.0),
    vec3(2.0, 0.0, -3.0),
  )
  let resolved = resolve_heightfield_contact(
    field,
    state,
    lunar_regolith_contact_model(),
  )
  assert_eq(resolved.status, "clear")
  assert_true(resolved.after == state)
  assert_true(!resolved.collision.in_contact)
}

///|
test "rigid body heightfield trace is deterministic" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let state = rigid_body_state(
    "body",
    4.0,
    0.2,
    vec3(0.0, 0.0, 0.25),
    vec3(0.0, 0.0, -1.0),
  )
  let trace = rigid_body_heightfield_trace(
    "trace",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    state,
    0.2,
    4,
    vec3(0.0, 0.0, 0.0),
    "test trace",
  )
  let replay = rigid_body_heightfield_trace(
    "trace",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    state,
    0.2,
    4,
    vec3(0.0, 0.0, 0.0),
    "test trace",
  )
  assert_true(trace == replay)
  assert_eq(trace.frame_count, 4)
  assert_eq(trace.status, "deterministic-replay")
  assert_eq(trace.frames[0].status, "contact-resolved")
  assert_true(nearly_equal(trace.final_state.position.z, 0.2))
}

///|
test "rigid body heightfield trace keeps stable prefixes" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let state = rigid_body_state(
    "body",
    4.0,
    0.2,
    vec3(0.0, 0.0, 0.25),
    vec3(0.0, 0.0, -1.0),
  )
  let prefix = rigid_body_heightfield_trace(
    "trace",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    state,
    0.2,
    2,
    vec3(0.0, 0.0, 0.0),
    "test trace",
  )
  let longer = rigid_body_heightfield_trace(
    "trace",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    state,
    0.2,
    4,
    vec3(0.0, 0.0, 0.0),
    "test trace",
  )
  assert_true(prefix.frames[0] == longer.frames[0])
  assert_true(prefix.frames[1] == longer.frames[1])
  assert_true(prefix.final_state == longer.frames[1].after)
}

///|
test "rigid body heightfield world trace steps multiple bodies" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "falling",
          4.0,
          0.2,
          vec3(0.0, 0.0, 0.25),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "driven",
          2.0,
          0.1,
          vec3(1.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
        external_force_n=vec3(4.0, 0.0, 0.0),
      ),
    ],
  )
  let step = rigid_body_heightfield_world_step(world, field, 0.2)
  assert_eq(step.status, "world-step-contact")
  assert_eq(step.body_count, 2)
  assert_eq(step.contact_count, 1)
  assert_eq(step.body_pair_count, 1)
  assert_eq(step.body_pair_contact_count, 0)
  assert_eq(step.review_count, 0)
  assert_true(step.body_frames[0].status == "world-body-contact-resolved")
  assert_true(step.body_frames[1].status == "world-body-clear")
  assert_true(step.body_frames[1].acceleration_mps2.x == 2.0)
  assert_true(step.body_frames[1].after.position.x > 1.0)
  assert_true(step.kinetic_energy_after_j > step.kinetic_energy_before_j)
  assert_true(step.after.bodies[0].state == step.body_frames[0].after)
}

///|
test "rigid body world contact schedule skips broadphase clear pairs" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "left",
          1.0,
          0.25,
          vec3(0.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "right",
          1.0,
          0.25,
          vec3(2.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
    ],
  )
  let schedule = rigid_body_world_contact_schedule(world)
  assert_eq(schedule.status, "world-contact-clear")
  assert_eq(schedule.pair_count, 1)
  assert_eq(schedule.broadphase_overlap_count, 0)
  assert_eq(schedule.contact_count, 0)
  assert_eq(schedule.pairs[0].status, "world-pair-broadphase-clear")
  assert_eq(schedule.pairs[0].contact.status, "broadphase-clear")
  assert_true(nearly_equal(schedule.pairs[0].contact.normal.length(), 1.0))
}

///|
test "rigid body world contact schedule records body contacts" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "box-a",
          1.0,
          0.0,
          vec3(0.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
        collision_shape=collision_box("box-a-shape", vec3(0.5, 0.5, 0.5)),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "box-b",
          1.0,
          0.0,
          vec3(0.9, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
        collision_shape=collision_box("box-b-shape", vec3(0.5, 0.5, 0.5)),
      ),
    ],
  )
  let schedule = rigid_body_world_contact_schedule(world)
  assert_eq(schedule.status, "world-contact-scheduled")
  assert_eq(schedule.pair_count, 1)
  assert_eq(schedule.broadphase_overlap_count, 1)
  assert_eq(schedule.contact_count, 1)
  assert_eq(schedule.manifold.status, "single-contact")
  assert_eq(schedule.pairs[0].status, "world-pair-contact")
  assert_eq(schedule.pairs[0].contact.status, "box-box-contact")
  let step = rigid_body_heightfield_world_step(world, field, 0.1)
  assert_eq(step.status, "world-step-body-contact")
  assert_eq(step.contact_count, 0)
  assert_eq(step.body_pair_contact_count, 1)
  assert_eq(step.body_contact_schedule.manifold.status, "single-contact")
}

///|
test "rigid body world contact resolution separates overlapping bodies" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    material_contact_model("test-material", 0.0, 0.0),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "sphere-a",
          1.0,
          0.5,
          vec3(0.0, 0.0, 2.0),
          vec3(1.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "sphere-b",
          1.0,
          0.5,
          vec3(0.9, 0.0, 2.0),
          vec3(0.0 - 1.0, 0.0, 0.0),
        ),
      ),
    ],
  )
  let schedule = rigid_body_world_contact_schedule(world)
  let resolution = rigid_body_world_resolve_contacts(world, schedule)
  assert_eq(resolution.status, "world-contact-resolved")
  assert_eq(resolution.resolved_contact_count, 1)
  assert_true(nearly_equal(resolution.normal_impulse_ns, 1.0))
  assert_true(resolution.resolutions[0].status == "world-pair-resolved")
  assert_true(nearly_equal(resolution.after.bodies[0].state.position.x, -0.05))
  assert_true(nearly_equal(resolution.after.bodies[1].state.position.x, 0.95))
  assert_true(nearly_equal(resolution.after.bodies[0].state.velocity.x, 0.0))
  assert_true(nearly_equal(resolution.after.bodies[1].state.velocity.x, 0.0))
}

///|
test "rigid body heightfield world step applies body contact response" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    material_contact_model("test-material", 0.0, 0.0),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "sphere-a",
          1.0,
          0.5,
          vec3(0.0, 0.0, 2.0),
          vec3(1.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "sphere-b",
          1.0,
          0.5,
          vec3(0.9, 0.0, 2.0),
          vec3(0.0 - 1.0, 0.0, 0.0),
        ),
      ),
    ],
  )
  let step = rigid_body_heightfield_world_step(world, field, 0.0)
  assert_eq(step.status, "world-step-body-contact")
  assert_eq(step.body_contact_resolution.status, "world-contact-resolved")
  assert_eq(step.body_contact_resolution.resolved_contact_count, 1)
  assert_true(step.kinetic_energy_after_j < step.kinetic_energy_before_j)
  assert_true(nearly_equal(step.after.bodies[0].state.position.x, -0.05))
  assert_true(nearly_equal(step.after.bodies[1].state.position.x, 0.95))
  assert_true(nearly_equal(step.after.bodies[0].state.velocity.x, 0.0))
  assert_true(nearly_equal(step.after.bodies[1].state.velocity.x, 0.0))
}

///|
test "rigid body world constraints restore distance" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "left",
          1.0,
          0.1,
          vec3(0.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "right",
          3.0,
          0.1,
          vec3(2.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
    ],
    constraints=[
      rigid_body_world_distance_constraint("link", "left", "right", 1.0),
    ],
  )
  let resolution = rigid_body_world_resolve_constraints(world)
  assert_eq(resolution.status, "world-constraint-resolved")
  assert_eq(resolution.constraint_count, 1)
  assert_eq(resolution.resolved_constraint_count, 1)
  assert_true(nearly_equal(resolution.max_error_m, 1.0))
  assert_true(nearly_equal(resolution.after.bodies[0].state.position.x, 0.75))
  assert_true(nearly_equal(resolution.after.bodies[1].state.position.x, 1.75))
  assert_true(nearly_equal(resolution.resolutions[0].correction_a.x, 0.75))
  assert_true(nearly_equal(resolution.resolutions[0].correction_b.x, -0.25))
}

///|
test "rigid body world constraints resolve anchored points" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "upper-link",
          1.0,
          0.1,
          vec3(0.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "lower-link",
          1.0,
          0.1,
          vec3(3.0, 0.0, 2.0),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
    ],
    constraints=[
      rigid_body_world_distance_constraint(
        "knee-pin",
        "upper-link",
        "lower-link",
        0.0,
        anchor_a_m=vec3(1.0, 0.0, 0.0),
        anchor_b_m=vec3(0.0 - 1.0, 0.0, 0.0),
      ),
    ],
  )
  let resolution = rigid_body_world_resolve_constraints(world)
  let resolved = resolution.resolutions[0]
  assert_eq(resolution.status, "world-constraint-resolved")
  assert_eq(resolved.status, "world-constraint-resolved")
  assert_true(nearly_equal(resolved.current_length_m, 1.0))
  assert_true(nearly_equal(resolved.world_anchor_a.x, 1.0))
  assert_true(nearly_equal(resolved.world_anchor_b.x, 2.0))
  assert_true(nearly_equal(resolution.after.bodies[0].state.position.x, 0.5))
  assert_true(nearly_equal(resolution.after.bodies[1].state.position.x, 2.5))
  assert_true(
    nearly_equal(
      resolution.after.bodies[0].state.position.add(resolved.anchor_a_m).x,
      resolution.after.bodies[1].state.position.add(resolved.anchor_b_m).x,
    ),
  )
}

///|
test "rigid body heightfield world step applies constraints" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "left",
          1.0,
          0.1,
          vec3(0.0, 0.0, 2.0),
          vec3(1.0, 0.0, 0.0),
        ),
      ),
      rigid_body_world_body(
        rigid_body_state(
          "right",
          1.0,
          0.1,
          vec3(2.0, 0.0, 2.0),
          vec3(0.0 - 1.0, 0.0, 0.0),
        ),
      ),
    ],
    constraints=[
      rigid_body_world_distance_constraint("link", "left", "right", 1.0),
    ],
  )
  let step = rigid_body_heightfield_world_step(world, field, 0.0)
  assert_eq(step.status, "world-step-constrained")
  assert_eq(step.constraint_count, 1)
  assert_eq(step.resolved_constraint_count, 1)
  assert_eq(step.constraint_resolution.status, "world-constraint-resolved")
  assert_true(nearly_equal(step.after.bodies[0].state.position.x, 0.5))
  assert_true(nearly_equal(step.after.bodies[1].state.position.x, 1.5))
  assert_true(nearly_equal(step.after.bodies[0].state.velocity.x, 0.0))
  assert_true(nearly_equal(step.after.bodies[1].state.velocity.x, 0.0))
}

///|
test "rigid body heightfield world trace is deterministic" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "body",
          4.0,
          0.2,
          vec3(0.0, 0.0, 0.25),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
    ],
  )
  let trace = rigid_body_heightfield_world_trace(
    "world-trace", world, field, 0.2, 4, "test world trace",
  )
  let replay = rigid_body_heightfield_world_trace(
    "world-trace", world, field, 0.2, 4, "test world trace",
  )
  assert_true(trace == replay)
  assert_eq(trace.status, "world-deterministic-replay")
  assert_eq(trace.frame_count, 4)
  assert_true(trace.frames[0].contact_count == 1)
  assert_true(
    trace.final_world.bodies[0].state == trace.frames[3].after.bodies[0].state,
  )
}

///|
test "rigid body heightfield world step flags review states" {
  let field = heightfield("flat", 1, 1, 1.0, [0.0])
  let other_field = heightfield("other", 1, 1, 1.0, [0.0])
  let world = rigid_body_heightfield_world(
    "world",
    field,
    lunar_regolith_contact_model(),
    lunar_environment(),
    [
      rigid_body_world_body(
        rigid_body_state(
          "massless",
          0.0,
          0.2,
          vec3(0.0, 0.0, 0.25),
          vec3(0.0, 0.0, 0.0),
        ),
      ),
    ],
  )
  let reviewed = rigid_body_heightfield_world_step(world, field, 0.2)
  assert_eq(reviewed.status, "world-step-review")
  assert_eq(reviewed.review_count, 1)
  assert_eq(reviewed.body_frames[0].status, "world-body-zero-mass-review")
  let mismatched = rigid_body_heightfield_world_step(world, other_field, 0.2)
  assert_eq(mismatched.status, "world-heightfield-mismatch-review")
}

///|
test "angular acceleration uses diagonal inertia" {
  let inertia = rigid_body_inertia("body", vec3(2.0, 4.0, 8.0))
  let acceleration = angular_acceleration(inertia, vec3(4.0, 4.0, 4.0))
  assert_true(acceleration == vec3(2.0, 1.0, 0.5))
}

///|
test "hinge axis assessment accepts aligned and reversed axes" {
  let constraint = rigid_body_hinge_axis_constraint(
    "knee-hinge",
    "upper",
    "lower",
    local_axis_a=vec3(0.0, 1.0, 0.0),
    local_axis_b=vec3(0.0, -1.0, 0.0),
  )
  let upper = rigid_body_angular_state(
    "upper",
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let lower = rigid_body_angular_state(
    "lower",
    identity_basis3(),
    vec3(0.0, 2.0, 0.0),
  )
  let assessment = rigid_body_hinge_axis_assessment(constraint, upper, lower)
  assert_eq(assessment.status, "hinge-axis-spinning")
  assert_true(nearly_equal(assessment.angular_error_rad, 0.0))
  assert_true(nearly_equal(assessment.alignment_dot, 1.0))
  assert_true(nearly_equal(assessment.relative_axis_velocity_rad_s, 2.0))
  assert_true(assessment.world_axis_a == vec3(0.0, 1.0, 0.0))
  assert_true(assessment.world_axis_b == vec3(0.0, 1.0, 0.0))
}

///|
test "hinge axis assessment reports angular misalignment" {
  let constraint = rigid_body_hinge_axis_constraint(
    "hip-hinge",
    "pelvis",
    "thigh",
    local_axis_a=vec3(0.0, 1.0, 0.0),
    local_axis_b=vec3(0.0, 1.0, 0.0),
    stiffness=0.5,
  )
  let pelvis = rigid_body_angular_state(
    "pelvis",
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let thigh = rigid_body_angular_state(
    "thigh",
    axis_angle_basis3(vec3(0.0, 0.0, 1.0), 3.141592653589793 / 2.0),
    vec3(0.0, 0.0, 0.0),
  )
  let assessment = rigid_body_hinge_axis_assessment(constraint, pelvis, thigh)
  assert_eq(assessment.status, "hinge-axis-misaligned")
  assert_true(nearly_equal(assessment.alignment_dot, 0.0))
  assert_true(
    nearly_equal(assessment.angular_error_rad, 3.141592653589793 / 2.0),
  )
  assert_true(
    nearly_equal(assessment.correction_angle_rad, 3.141592653589793 / 4.0),
  )
  assert_true(nearly_equal(assessment.correction_axis.length(), 1.0))
  assert_true(
    nearly_equal(
      if assessment.correction_axis.z < 0.0 {
        0.0 - assessment.correction_axis.z
      } else {
        assessment.correction_axis.z
      },
      1.0,
    ),
  )
}

///|
test "hinge axis correction splits angular error by inverse inertia" {
  let constraint = rigid_body_hinge_axis_constraint(
    "hip-hinge",
    "pelvis",
    "thigh",
    local_axis_a=vec3(0.0, 1.0, 0.0),
    local_axis_b=vec3(0.0, 1.0, 0.0),
  )
  let pelvis = rigid_body_angular_state(
    "pelvis",
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let thigh = rigid_body_angular_state(
    "thigh",
    axis_angle_basis3(vec3(0.0, 0.0, 1.0), 3.141592653589793 / 2.0),
    vec3(0.0, 0.0, 0.0),
  )
  let correction = rigid_body_hinge_axis_correction(
    constraint,
    pelvis,
    rigid_body_inertia("pelvis", vec3(1.0, 1.0, 1.0)),
    thigh,
    rigid_body_inertia("thigh", vec3(3.0, 3.0, 3.0)),
  )
  assert_eq(correction.status, "hinge-correction-estimated")
  assert_true(nearly_equal(correction.inverse_inertia_a, 1.0))
  assert_true(nearly_equal(correction.inverse_inertia_b, 1.0 / 3.0))
  assert_true(
    nearly_equal(
      correction.correction_a_rad.length(),
      3.141592653589793 * 0.375,
    ),
  )
  assert_true(
    nearly_equal(
      correction.correction_b_rad.length(),
      3.141592653589793 * 0.125,
    ),
  )
  assert_true(nearly_equal(correction.angular_impulse_nms, 0.0))
}

///|
test "hinge axis correction estimates velocity impulse" {
  let constraint = rigid_body_hinge_axis_constraint(
    "knee-hinge",
    "upper",
    "lower",
    local_axis_a=vec3(0.0, 1.0, 0.0),
    local_axis_b=vec3(0.0, 1.0, 0.0),
  )
  let upper = rigid_body_angular_state(
    "upper",
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let lower = rigid_body_angular_state(
    "lower",
    identity_basis3(),
    vec3(0.0, 4.0, 0.0),
  )
  let correction = rigid_body_hinge_axis_correction(
    constraint,
    upper,
    rigid_body_inertia("upper", vec3(2.0, 2.0, 2.0)),
    lower,
    rigid_body_inertia("lower", vec3(2.0, 2.0, 2.0)),
  )
  assert_eq(correction.status, "hinge-correction-estimated")
  assert_true(nearly_equal(correction.angular_impulse_nms, 4.0))
  assert_true(nearly_equal(correction.velocity_delta_a_rad_s.y, 2.0))
  assert_true(nearly_equal(correction.velocity_delta_b_rad_s.y, -2.0))
}

///|
test "primitive diagonal inertia uses solid shape formulas" {
  let sphere = sphere_diagonal_inertia("sphere", 10.0, 2.0)
  assert_true(nearly_equal(sphere.diagonal_kg_m2.x, 16.0))
  assert_true(nearly_equal(sphere.diagonal_kg_m2.y, 16.0))
  assert_true(nearly_equal(sphere.diagonal_kg_m2.z, 16.0))
  let box = box_diagonal_inertia("box", 12.0, vec3(1.0, 2.0, 3.0))
  assert_true(nearly_equal(box.diagonal_kg_m2.x, 52.0))
  assert_true(nearly_equal(box.diagonal_kg_m2.y, 40.0))
  assert_true(nearly_equal(box.diagonal_kg_m2.z, 20.0))
  let capsule = capsule_diagonal_inertia("capsule", 10.0, 1.0, 1.0)
  assert_true(nearly_equal(capsule.diagonal_kg_m2.x, 12.1))
  assert_true(nearly_equal(capsule.diagonal_kg_m2.y, 12.1))
  assert_true(nearly_equal(capsule.diagonal_kg_m2.z, 4.6))
}

///|
test "collision shape diagonal inertia dispatches by primitive kind" {
  let inertia = collision_shape_diagonal_inertia(
    "body",
    12.0,
    collision_box("body-box", vec3(1.0, 2.0, 3.0)),
  )
  assert_true(nearly_equal(inertia.diagonal_kg_m2.x, 52.0))
  assert_true(nearly_equal(inertia.diagonal_kg_m2.y, 40.0))
  assert_true(nearly_equal(inertia.diagonal_kg_m2.z, 20.0))
}

///|
test "collision shape volume dispatches by primitive kind" {
  assert_true(
    nearly_equal(
      collision_shape_volume(collision_sphere("sphere", 1.0)),
      4.0 * 3.141592653589793 / 3.0,
    ),
  )
  assert_true(
    nearly_equal(
      collision_shape_volume(collision_box("box", vec3(1.0, 2.0, 3.0))),
      48.0,
    ),
  )
  assert_true(
    collision_shape_volume(collision_capsule("capsule", 1.0, 1.0)) >
    collision_shape_volume(collision_sphere("sphere", 1.0)),
  )
}

///|
test "composite mass properties apply parallel axis theorem" {
  let composite = composite_mass_properties("body", [
    mass_property_element(
      "left",
      1.0,
      vec3(0.0, 0.0, 0.0),
      rigid_body_inertia("left", vec3(0.0, 0.0, 0.0)),
    ),
    mass_property_element(
      "right",
      3.0,
      vec3(2.0, 0.0, 0.0),
      rigid_body_inertia("right", vec3(0.0, 0.0, 0.0)),
    ),
  ])
  assert_eq(composite.element_count, 2)
  assert_true(nearly_equal(composite.total_mass_kg, 4.0))
  assert_true(nearly_equal(composite.center_of_mass.x, 1.5))
  assert_true(nearly_equal(composite.center_of_mass.y, 0.0))
  assert_true(
    nearly_equal(composite.inertia_about_center.diagonal_kg_m2.x, 0.0),
  )
  assert_true(
    nearly_equal(composite.inertia_about_center.diagonal_kg_m2.y, 3.0),
  )
  assert_true(
    nearly_equal(composite.inertia_about_center.diagonal_kg_m2.z, 3.0),
  )
  assert_eq(composite.status, "composite-mass-resolved")
}

///|
test "collision shape mass element contributes primitive inertia" {
  let element = collision_shape_mass_element(
    "box",
    12.0,
    collision_box("box-shape", vec3(1.0, 2.0, 3.0)),
    vec3(0.0, 0.0, 0.0),
  )
  assert_true(nearly_equal(element.inertia_about_center.diagonal_kg_m2.x, 52.0))
  assert_true(nearly_equal(element.inertia_about_center.diagonal_kg_m2.y, 40.0))
  assert_true(nearly_equal(element.inertia_about_center.diagonal_kg_m2.z, 20.0))
}

///|
test "angular rigid body integration applies torque semi implicitly" {
  let inertia = rigid_body_inertia("body", vec3(2.0, 2.0, 2.0))
  let state = rigid_body_angular_state(
    "body",
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let stepped = integrate_angular_rigid_body(state, inertia, {
    dt_s: 0.5,
    torque_nm: vec3(0.0, 0.0, 4.0),
  })
  let rotated = stepped.orientation.mul_vec3(vec3(1.0, 0.0, 0.0))
  assert_true(stepped.angular_velocity_rad_s == vec3(0.0, 0.0, 1.0))
  assert_true(nearly_equal(rotated.x, @math.cos(0.5)))
  assert_true(nearly_equal(rotated.y, @math.sin(0.5)))
}

///|
test "rigid body wrench integration combines force and torque" {
  let state = rigid_body_motion_state(
    "body",
    2.0,
    0.0,
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let step = integrate_rigid_body_wrench(
    state,
    rigid_body_inertia("body", vec3(1.0, 2.0, 4.0)),
    rigid_body_wrench(vec3(4.0, 0.0, 0.0), vec3(0.0, 4.0, 8.0)),
    0.5,
  )
  assert_eq(step.status, "wrench-integrated")
  assert_true(step.linear_acceleration_mps2 == vec3(2.0, 0.0, 0.0))
  assert_true(step.angular_acceleration_rad_s2 == vec3(0.0, 2.0, 2.0))
  assert_true(step.linear_impulse_ns == vec3(2.0, 0.0, 0.0))
  assert_true(step.angular_impulse_nms == vec3(0.0, 2.0, 4.0))
  assert_true(step.after.linear.velocity == vec3(1.0, 0.0, 0.0))
  assert_true(step.after.linear.position == vec3(0.5, 0.0, 0.0))
  assert_true(step.after.angular.angular_velocity_rad_s == vec3(0.0, 1.0, 1.0))
  assert_true(nearly_equal(step.kinetic_energy_before_j, 0.0))
  assert_true(nearly_equal(step.kinetic_energy_after_j, 4.0))
  assert_true(nearly_equal(step.kinetic_energy_delta_j, 4.0))
}

///|
test "rigid body wrench integration flags zero mass review" {
  let state = rigid_body_motion_state(
    "body",
    0.0,
    0.0,
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    identity_basis3(),
    vec3(0.0, 0.0, 0.0),
  )
  let step = integrate_rigid_body_wrench(
    state,
    rigid_body_inertia("body", vec3(1.0, 1.0, 1.0)),
    rigid_body_wrench(vec3(4.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0)),
    0.5,
  )
  assert_eq(step.status, "wrench-zero-mass-review")
  assert_true(step.linear_acceleration_mps2 == vec3(0.0, 0.0, 0.0))
  assert_true(step.linear_impulse_ns == vec3(2.0, 0.0, 0.0))
  assert_true(nearly_equal(step.kinetic_energy_delta_j, 0.0))
  assert_true(step.after.linear.position == vec3(0.0, 0.0, 0.0))
}

///|
test "angular momentum and contact torque are deterministic" {
  let inertia = rigid_body_inertia("body", vec3(2.0, 4.0, 8.0))
  let state = rigid_body_angular_state(
    "body",
    identity_basis3(),
    vec3(1.0, 2.0, 3.0),
  )
  assert_true(angular_momentum(inertia, state) == vec3(2.0, 8.0, 24.0))
  assert_true(
    contact_torque(
      vec3(0.0, 0.0, 0.0),
      vec3(0.0, 1.0, 0.0),
      vec3(1.0, 0.0, 0.0),
    ) ==
    vec3(0.0, 0.0, -1.0),
  )
}

///|
test "collision shapes expose conservative bounding radii" {
  assert_eq(collision_shape_kind_label(SphereShape), "sphere")
  assert_true(
    nearly_equal(collision_bounding_radius(collision_sphere("s", 0.5)), 0.5),
  )
  assert_true(
    nearly_equal(
      collision_bounding_radius(collision_capsule("c", 0.2, 1.0)),
      1.2,
    ),
  )
  assert_true(
    nearly_equal(
      collision_bounding_radius(collision_box("b", vec3(1.0, 2.0, 2.0))),
      3.0,
    ),
  )
}

///|
test "collision world bounds follow transform translation" {
  let bounds = collision_world_bounds(
    collision_sphere("s", 0.5),
    transform3(identity_basis3(), vec3(1.0, 2.0, 3.0)),
  )
  assert_true(bounds.center == vec3(1.0, 2.0, 3.0))
  assert_true(bounds.min == vec3(0.5, 1.5, 2.5))
  assert_true(bounds.max == vec3(1.5, 2.5, 3.5))
  assert_eq(bounds.status, "conservative-bounds")
}

///|
test "collision pair probe reports broadphase overlap and clear" {
  let shape = collision_sphere("a", 0.5)
  let overlap = collision_pair_probe(
    shape,
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("b", 0.5),
    transform3(identity_basis3(), vec3(0.75, 0.0, 0.0)),
  )
  let clear = collision_pair_probe(
    shape,
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("b", 0.5),
    transform3(identity_basis3(), vec3(2.0, 0.0, 0.0)),
  )
  assert_true(overlap.overlapping)
  assert_true(nearly_equal(overlap.separation_m, -0.25))
  assert_eq(overlap.status, "broadphase-overlap")
  assert_true(!clear.overlapping)
  assert_true(nearly_equal(clear.separation_m, 1.0))
  assert_eq(clear.status, "broadphase-clear")
}

///|
test "sphere sphere contact reports exact penetration" {
  let contact = sphere_sphere_contact(
    collision_sphere("a", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("b", 0.75),
    transform3(identity_basis3(), vec3(1.0, 0.0, 0.0)),
  )
  assert_true(contact.in_contact)
  assert_true(nearly_equal(contact.separation_m, -0.25))
  assert_true(nearly_equal(contact.penetration_depth_m, 0.25))
  assert_true(contact.normal == vec3(1.0, 0.0, 0.0))
  assert_true(nearly_equal(contact.point.x, 0.375))
  assert_eq(contact.status, "sphere-sphere-contact")
}

///|
test "collision pair contact uses narrow phase for non spheres" {
  let sphere_capsule = collision_pair_contact(
    collision_sphere("sphere", 0.25),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_capsule("capsule", 0.2, 0.5),
    transform3(identity_basis3(), vec3(0.4, 0.0, 0.0)),
  )
  assert_true(sphere_capsule.in_contact)
  assert_eq(sphere_capsule.status, "sphere-capsule-contact")
  let capsule_capsule = collision_pair_contact(
    collision_capsule("a", 0.2, 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_capsule("b", 0.2, 0.5),
    transform3(identity_basis3(), vec3(0.35, 0.0, 0.0)),
  )
  assert_true(capsule_capsule.in_contact)
  assert_eq(capsule_capsule.status, "capsule-capsule-contact")
  let capsule_box = collision_pair_contact(
    collision_capsule("capsule", 0.2, 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_box("box", vec3(0.3, 0.3, 0.3)),
    transform3(identity_basis3(), vec3(0.45, 0.0, 0.0)),
  )
  assert_true(capsule_box.in_contact)
  assert_eq(capsule_box.status, "capsule-box-contact")
}

///|
test "box box narrow phase rejects bounding sphere false positive" {
  let clear = collision_pair_contact(
    collision_box("a", vec3(1.0, 1.0, 0.1)),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_box("b", vec3(1.0, 1.0, 0.1)),
    transform3(identity_basis3(), vec3(2.1, 0.0, 0.0)),
  )
  assert_true(!clear.in_contact)
  assert_eq(clear.status, "box-box-clear")
  assert_true(nearly_equal(clear.separation_m, 0.1))
  let rotated = collision_pair_contact(
    collision_box("a", vec3(1.0, 0.25, 0.25)),
    transform3(yaw_basis3(3.141592653589793 / 4.0), vec3(0.0, 0.0, 0.0)),
    collision_box("b", vec3(0.5, 0.5, 0.5)),
    transform3(identity_basis3(), vec3(0.75, 0.0, 0.0)),
  )
  assert_true(rotated.in_contact)
  assert_eq(rotated.status, "box-box-contact")
  assert_true(rotated.penetration_depth_m > 0.0)
}

///|
test "collision contact manifold summarizes active contacts" {
  let first = sphere_sphere_contact(
    collision_sphere("a", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("b", 0.5),
    transform3(identity_basis3(), vec3(0.75, 0.0, 0.0)),
  )
  let second = sphere_sphere_contact(
    collision_sphere("a", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("c", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.75, 0.0)),
  )
  let clear = sphere_sphere_contact(
    collision_sphere("a", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("d", 0.5),
    transform3(identity_basis3(), vec3(2.0, 0.0, 0.0)),
  )
  let manifold = collision_contact_manifold("m", [first, second, clear])
  assert_eq(manifold.contact_count, 2)
  assert_eq(manifold.status, "multi-contact")
  assert_true(nearly_equal(manifold.max_penetration_m, 0.25))
  assert_true(manifold.average_normal.x > 0.7)
  assert_true(manifold.average_normal.y > 0.7)
}

///|
test "collision manifold resolution separates and damps one body" {
  let contact = sphere_sphere_contact(
    collision_sphere("body", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("blocker", 0.5),
    transform3(identity_basis3(), vec3(0.75, 0.0, 0.0)),
  )
  let manifold = collision_contact_manifold("m", [contact])
  let state = rigid_body_state(
    "body",
    4.0,
    0.5,
    vec3(0.0, 0.0, 0.0),
    vec3(2.0, 1.0, 0.0),
  )
  let resolution = resolve_collision_manifold(
    state,
    manifold,
    material_contact_model("test", 0.25, 0.1),
  )
  assert_eq(resolution.status, "single-contact-resolved")
  assert_true(nearly_equal(resolution.correction.x, -0.25))
  assert_true(nearly_equal(resolution.after.position.x, -0.25))
  assert_true(nearly_equal(resolution.normal_speed_mps, 2.0))
  assert_true(nearly_equal(resolution.tangent_speed_mps, 1.0))
  assert_true(nearly_equal(resolution.after.velocity.x, -0.2))
  assert_true(nearly_equal(resolution.after.velocity.y, 0.75))
  assert_true(resolution.average_normal == vec3(1.0, 0.0, 0.0))
  assert_true(nearly_equal(resolution.velocity_delta.x, -2.2))
  assert_true(nearly_equal(resolution.velocity_delta.y, -0.25))
  assert_true(nearly_equal(resolution.normal_impulse_ns, 8.8))
  assert_true(nearly_equal(resolution.friction_impulse_ns, 1.0))
}

///|
test "collision manifold resolution handles multi and clear contacts" {
  let first = sphere_sphere_contact(
    collision_sphere("body", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("front", 0.5),
    transform3(identity_basis3(), vec3(0.75, 0.0, 0.0)),
  )
  let second = sphere_sphere_contact(
    collision_sphere("body", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    collision_sphere("side", 0.5),
    transform3(identity_basis3(), vec3(0.0, 0.8, 0.0)),
  )
  let state = rigid_body_state(
    "body",
    4.0,
    0.5,
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
  )
  let multi = resolve_collision_manifold(
    state,
    collision_contact_manifold("multi", [first, second]),
    lunar_regolith_contact_model(),
  )
  assert_eq(multi.status, "multi-contact-resolved")
  assert_true(multi.correction.x < 0.0)
  assert_true(multi.correction.y < 0.0)
  let clear = resolve_collision_manifold(
    state,
    collision_contact_manifold("clear", []),
    lunar_regolith_contact_model(),
  )
  assert_eq(clear.status, "no-contact")
  assert_true(clear.after == state)
  assert_true(clear.velocity_delta == vec3(0.0, 0.0, 0.0))
  assert_true(nearly_equal(clear.normal_impulse_ns, 0.0))
  assert_true(nearly_equal(clear.friction_impulse_ns, 0.0))
}

///|
test "joint servo output applies pd torque and saturation" {
  let state = joint_motor_state("hip", 0.0, 0.0)
  let command = joint_motor_command("hip", 1.0, 0.0, 0.0)
  let config = joint_servo_config("hip", 8.0, 1.0)
  let limit = joint_limit("hip", -2.0, 2.0, 4.0, 3.0)
  let servo = joint_servo_output(state, command, config, limit)
  assert_true(nearly_equal(servo.position_error_rad, 1.0))
  assert_true(nearly_equal(servo.commanded_torque_nm, 3.0))
  assert_true(servo.saturated)
  assert_eq(servo.status, "torque-saturated")
}

///|
test "joint motor integration applies torque semi implicitly" {
  let step = integrate_joint_motor(
    joint_motor_state("knee", 0.0, 0.0),
    joint_motor_command("knee", 1.0, 0.0, 0.0),
    joint_servo_config("knee", 2.0, 0.0),
    joint_limit("knee", -2.0, 2.0, 4.0, 10.0),
    2.0,
    0.5,
  )
  assert_eq(step.status, "torque-commanded")
  assert_true(nearly_equal(step.after.velocity_rad_s, 0.5))
  assert_true(nearly_equal(step.after.position_rad, 0.25))
  assert_true(nearly_equal(step.work_j, 0.5))
  assert_true(nearly_equal(step.absolute_work_j, 0.5))
  assert_true(nearly_equal(step.average_mechanical_power_w, 1.0))
}

///|
test "joint motor integration respects velocity and position limits" {
  let step = integrate_joint_motor(
    joint_motor_state("ankle", 0.9, 0.0),
    joint_motor_command("ankle", 5.0, 0.0, 0.0),
    joint_servo_config("ankle", 100.0, 0.0),
    joint_limit("ankle", -1.0, 1.0, 0.5, 100.0),
    1.0,
    1.0,
  )
  assert_eq(step.status, "position-limit")
  assert_true(nearly_equal(step.after.position_rad, 1.0))
  assert_true(nearly_equal(step.after.velocity_rad_s, 0.0))
  assert_true(nearly_equal(step.work_j, 10.0))
  assert_true(nearly_equal(step.average_mechanical_power_w, 10.0))
}

///|
test "joint motor frame integrates and aggregates multiple joints" {
  let frame = integrate_joint_motor_frame(
    "frame-0",
    [joint_motor_state("hip", 0.0, 0.0), joint_motor_state("knee", 0.0, 0.0)],
    [
      joint_motor_command("hip", 1.0, 0.0, 0.0),
      joint_motor_command("knee", 0.0, 5.0, 0.0),
    ],
    [joint_servo_config("hip", 2.0, 0.0), joint_servo_config("knee", 0.0, 1.0)],
    [
      joint_limit("hip", -2.0, 2.0, 4.0, 10.0),
      joint_limit("knee", -2.0, 2.0, 3.0, 10.0),
    ],
    [1.0, 1.0],
    0.5,
  )
  assert_eq(frame.status, "joint-frame-limit-review")
  assert_eq(frame.joint_count, 2)
  assert_eq(frame.saturated_joint_count, 0)
  assert_eq(frame.limit_review_count, 1)
  assert_true(frame.steps[0].position_within_limits)
  assert_true(!frame.steps[1].velocity_within_limits)
  assert_true(nearly_equal(frame.max_abs_velocity_rad_s, 5.0))
  assert_true(nearly_equal(frame.max_abs_commanded_torque_nm, 5.0))
  assert_true(nearly_equal(frame.total_absolute_work_j, 7.25))
}

///|
test "transform translates local point" {
  let transform = transform3(identity_basis3(), vec3(1.0, 2.0, 3.0))
  assert_true(
    transform.transform_point(vec3(4.0, 5.0, 6.0)) == vec3(5.0, 7.0, 9.0),
  )
}

///|
test "axis angle basis rotates around z" {
  let basis = axis_angle_basis3(vec3(0.0, 0.0, 1.0), 3.141592653589793 / 2.0)
  let rotated = basis.mul_vec3(vec3(1.0, 0.0, 0.0))
  assert_true(rotated.x < 0.000001)
  assert_true(rotated.y > 0.999999)
}

///|
test "transform composition applies parent translation and local rotation" {
  let parent = transform3(identity_basis3(), vec3(1.0, 0.0, 0.0))
  let child = transform3(
    axis_angle_basis3(vec3(0.0, 0.0, 1.0), 3.141592653589793 / 2.0),
    vec3(0.0, 2.0, 0.0),
  )
  let composed = parent.compose(child)
  let point = composed.transform_point(vec3(1.0, 0.0, 0.0))
  assert_true(point.x < 1.000001 && point.x > 0.999999)
  assert_true(point.y > 2.999999)
}

///|
test "articulated pose tree resolves parent first chain transforms" {
  let tree = articulated_pose_tree(
    transform3(identity_basis3(), vec3(0.0, 0.0, 0.0)),
    [
      articulated_link_spec(
        "base",
        "",
        "",
        vec3(0.0, 0.0, 0.0),
        vec3(0.0, 0.0, 1.0),
      ),
      articulated_link_spec(
        "shoulder",
        "base",
        "shoulder_yaw",
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 0.0, 1.0),
      ),
      articulated_link_spec(
        "elbow",
        "shoulder",
        "elbow_fixed",
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 0.0, 1.0),
      ),
    ],
    [articulated_joint_position("shoulder_yaw", 3.141592653589793 / 2.0)],
  )
  let shoulder = tree.link_transform("shoulder").translation
  let elbow = tree.link_transform("elbow").translation
  assert_eq(tree.status, "articulated-poses")
  assert_eq(tree.link_count, 3)
  assert_true(shoulder == vec3(1.0, 0.0, 0.0))
  assert_true(nearly_equal(elbow.x, 1.0))
  assert_true(nearly_equal(elbow.y, 1.0))
}

///|
test "articulated pose tree reports missing parent" {
  let tree = articulated_pose_tree(
    transform3(identity_basis3(), vec3(2.0, 0.0, 0.0)),
    [
      articulated_link_spec(
        "forearm",
        "missing-upper-arm",
        "elbow",
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 0.0, 1.0),
      ),
    ],
    [],
  )
  assert_eq(tree.status, "articulated-poses-missing-parent-review")
  assert_eq(tree.missing_parent_count, 1)
  assert_eq(tree.links[0].status, "missing-parent")
  assert_true(tree.links[0].world_transform.translation == vec3(3.0, 0.0, 0.0))
}

///|
test "support assessment reports static margin" {
  let assessment = support_assessment(vec3(0.0, 0.0, 1.0), [
    support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1),
  ])
  assert_true(assessment.stable)
  assert_eq(assessment.support_count, 1)
  assert_eq(assessment.support_polygon_vertex_count, 4)
  assert_true(nearly_equal(assessment.planar_margin_m, 0.1))
  assert_eq(assessment.status, "inside-support")
}

///|
test "support assessment flags projection outside support" {
  let assessment = support_assessment(vec3(0.0, 0.0, 1.0), [
    support_footprint("left", vec3(0.0, 0.2, 0.0), 0.2, 0.05),
  ])
  assert_true(!assessment.stable)
  assert_true(assessment.planar_margin_m < 0.0)
  assert_eq(assessment.status, "outside-support")
}

///|
test "support assessment uses convex support polygon" {
  let footprints = [
    support_footprint("rear-left", vec3(0.0, 0.0, 0.0), 0.1, 0.1),
    support_footprint("front-right", vec3(1.0, 1.0, 0.0), 0.1, 0.1),
  ]
  let inside = support_assessment(vec3(0.5, 0.5, 1.0), footprints)
  assert_true(inside.stable)
  assert_eq(inside.support_count, 2)
  assert_true(inside.support_polygon_vertex_count > 4)
  assert_true(inside.planar_margin_m > 0.0)
  let outside_hull = support_assessment(vec3(0.9, 0.1, 1.0), footprints)
  assert_true(!outside_hull.stable)
  assert_true(outside_hull.margin_x_m > 0.0)
  assert_true(outside_hull.margin_y_m > 0.0)
  assert_true(outside_hull.planar_margin_m < 0.0)
  assert_eq(outside_hull.status, "outside-support")
}

///|
test "support assessment handles no active support" {
  let assessment = support_assessment(vec3(0.0, 0.0, 1.0), [
    support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1, active=false),
  ])
  assert_true(!assessment.stable)
  assert_eq(assessment.support_count, 0)
  assert_eq(assessment.status, "no-support")
}

///|
test "support load assessment splits two-foot normal force" {
  let assessment = support_load_assessment(
    vec3(0.5, 0.0, 1.0),
    [
      support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1),
      support_footprint("right", vec3(1.0, 0.0, 0.0), 0.2, 0.1),
    ],
    120.0,
  )
  assert_eq(assessment.load_count, 2)
  assert_true(assessment.balanced)
  assert_eq(assessment.status, "center-load-balanced")
  assert_true(nearly_equal(assessment.loads[0].load_fraction, 0.5))
  assert_true(nearly_equal(assessment.loads[1].load_fraction, 0.5))
  assert_true(nearly_equal(assessment.loads[0].normal_force_n, 60.0))
  assert_true(nearly_equal(assessment.loads[1].normal_force_n, 60.0))
  assert_true(nearly_equal(assessment.center_of_pressure_error_m, 0.0))
}

///|
test "support load assessment reports off-segment center-load error" {
  let assessment = support_load_assessment(
    vec3(0.5, 0.2, 1.0),
    [
      support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1),
      support_footprint("right", vec3(1.0, 0.0, 0.0), 0.2, 0.1),
    ],
    120.0,
  )
  assert_true(!assessment.balanced)
  assert_eq(assessment.status, "outside-support-load-review")
  assert_true(nearly_equal(assessment.center_of_pressure_error_m, 0.2))
}

///|
test "support load assessment uses triangle barycentric fractions" {
  let assessment = support_load_assessment(
    vec3(0.25, 0.25, 1.0),
    [
      support_footprint("a", vec3(0.0, 0.0, 0.0), 0.05, 0.05),
      support_footprint("b", vec3(1.0, 0.0, 0.0), 0.05, 0.05),
      support_footprint("c", vec3(0.0, 1.0, 0.0), 0.05, 0.05),
    ],
    100.0,
  )
  assert_true(assessment.balanced)
  assert_eq(assessment.status, "center-load-balanced")
  assert_true(nearly_equal(assessment.loads[0].load_fraction, 0.5))
  assert_true(nearly_equal(assessment.loads[1].load_fraction, 0.25))
  assert_true(nearly_equal(assessment.loads[2].load_fraction, 0.25))
  assert_true(nearly_equal(assessment.center_of_pressure_error_m, 0.0))
}

///|
test "support load assessment handles no active support" {
  let assessment = support_load_assessment(
    vec3(0.0, 0.0, 1.0),
    [support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1, active=false)],
    120.0,
  )
  assert_true(!assessment.balanced)
  assert_eq(assessment.load_count, 0)
  assert_eq(assessment.status, "no-support-load")
}

///|
test "traction assessment reports friction margin and slip" {
  let material = material_contact_model("test", 0.5, 0.0)
  let ok = traction_assessment("foot", material, 100.0, 20.0)
  assert_eq(ok.status, "traction-ok")
  assert_true(nearly_equal(ok.friction_limit_n, 50.0))
  assert_true(nearly_equal(ok.utilization, 0.4))
  assert_true(nearly_equal(ok.margin_n, 30.0))
  assert_true(!ok.slipping)
  let low = traction_assessment("foot", material, 100.0, 45.0)
  assert_eq(low.status, "friction-margin-low")
  assert_true(nearly_equal(low.utilization, 0.9))
  let slip = traction_assessment("foot", material, 100.0, 60.0)
  assert_eq(slip.status, "friction-limit-exceeded")
  assert_true(slip.slipping)
  assert_true(nearly_equal(slip.margin_n, 0.0 - 10.0))
  let no_normal = traction_assessment("foot", material, 0.0, 1.0)
  assert_eq(no_normal.status, "no-normal-force-slip")
  assert_true(no_normal.slipping)
}

///|
test "surface traction assessment projects force onto flat normal" {
  let material = material_contact_model("test", 0.5, 0.0)
  let assessment = surface_traction_assessment(
    "foot",
    material,
    vec3(3.0, 0.0, 10.0),
    vec3(0.0, 0.0, 1.0),
  )
  assert_true(nearly_equal(assessment.normal_force_n, 10.0))
  assert_true(nearly_equal(assessment.tangential_force_n, 3.0))
  assert_eq(assessment.status, "traction-ok")
}

///|
test "surface traction assessment exposes slope tangential demand" {
  let material = material_contact_model("test", 0.5, 0.0)
  let normal = vec3(0.0, 1.0, 1.0)
  let assessment = surface_traction_assessment(
    "foot",
    material,
    vec3(0.0, 0.0, 10.0),
    normal,
  )
  let expected = 50.0.sqrt()
  assert_true(nearly_equal(assessment.normal_force_n, expected))
  assert_true(nearly_equal(assessment.tangential_force_n, expected))
  assert_eq(assessment.status, "friction-limit-exceeded")
}

///|
test "capture point assessment keeps slow COM inside support" {
  let assessment = capture_point_assessment(
    lunar_environment(),
    vec3(0.0, 0.0, 0.7),
    vec3(0.02, 0.0, 0.0),
    [support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1)],
    nominal_com_height_m=0.7,
  )
  assert_true(assessment.stable)
  assert_eq(assessment.status, "capture-point-inside-support")
  assert_true(assessment.omega_rad_s > 0.0)
  assert_true(assessment.capture_point.x > assessment.com_position.x)
}

///|
test "capture point assessment flags fast COM outside support" {
  let assessment = capture_point_assessment(
    lunar_environment(),
    vec3(0.0, 0.0, 0.7),
    vec3(0.6, 0.0, 0.0),
    [support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1)],
    nominal_com_height_m=0.7,
  )
  assert_true(!assessment.stable)
  assert_eq(assessment.status, "capture-point-outside-support")
  assert_true(assessment.capture_margin_m < 0.0)
}
