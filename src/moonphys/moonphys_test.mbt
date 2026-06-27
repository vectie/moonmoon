///|
test "vec3 math is deterministic" {
  let a = vec3(1.0, 2.0, 3.0)
  let b = vec3(4.0, 5.0, 6.0)
  assert_true(a.add(b) == vec3(5.0, 7.0, 9.0))
  assert_true(b.sub(a) == vec3(3.0, 3.0, 3.0))
  assert_true(a.scale(2.0) == vec3(2.0, 4.0, 6.0))
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
  inspect(sample.elevation_m, content="1")
  inspect(sample.local_grade_x, content="0.3")
}

///|
test "contact probe detects clearance" {
  let field = heightfield("test-field", 1, 1, 10.0, [2.0])
  let probe = heightfield_contact_probe(field, "foot", vec3(0.0, 0.0, 2.5))
  assert_true(!probe.in_contact)
  inspect(probe.clearance_m, content="0.5")
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
test "support assessment reports static margin" {
  let assessment = support_assessment(vec3(0.0, 0.0, 1.0), [
    support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1),
  ])
  assert_true(assessment.stable)
  assert_eq(assessment.support_count, 1)
  inspect(assessment.planar_margin_m, content="0.1")
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
test "support assessment handles no active support" {
  let assessment = support_assessment(vec3(0.0, 0.0, 1.0), [
    support_footprint("left", vec3(0.0, 0.0, 0.0), 0.2, 0.1, active=false),
  ])
  assert_true(!assessment.stable)
  assert_eq(assessment.support_count, 0)
  assert_eq(assessment.status, "no-support")
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
