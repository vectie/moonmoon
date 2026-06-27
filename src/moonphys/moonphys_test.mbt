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
test "transform translates local point" {
  let transform = transform3(identity_basis3(), vec3(1.0, 2.0, 3.0))
  assert_true(
    transform.transform_point(vec3(4.0, 5.0, 6.0)) == vec3(5.0, 7.0, 9.0),
  )
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
