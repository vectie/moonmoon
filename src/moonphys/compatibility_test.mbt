///|
test "legacy geometry retains canonical ownership and method lookup" {
  let point : @canonical.Vec3 = @moonphys.vec3(1.0, 2.0, 3.0)
  let shared : @geometry.Vec3 = point
  let basis : @canonical.Basis3 = @moonphys.identity_basis3()
  let transform : @canonical.Transform3 = @moonphys.transform3(basis, shared)
  assert_eq(transform.transform_point(shared), shared.scale(2.0))
  let legacy : @moonphys.Vec3 = @geometry.vec3(3.0, 2.0, 1.0)
  assert_eq(legacy.dot(shared), 10.0)
  let roundtrip : @moonphys.Vec3 = @json.from_json(shared.to_json())
  assert_eq(roundtrip, point)
}

///|
test "legacy physics types constructors and record JSON use canonical owners" {
  let shape : @canonical.CollisionShape = @moonphys.collision_sphere(
    "shape", 0.5,
  )
  assert_true(shape.kind is @moonphys.CollisionShapeKind::SphereShape)
  let state : @moonphys.RigidBodyState = @canonical.rigid_body_state(
    "body",
    2.0,
    0.5,
    @geometry.vec3(0.0, 0.0, 2.0),
    @moonphys.vec3(0.0, 0.0, 0.0),
  )
  let restored : @canonical.RigidBodyState = @json.from_json(state.to_json())
  assert_eq(restored, state)
  let tree : @moonphys.ArticulatedPoseTree = @canonical.articulated_pose_tree(
    @moonphys.transform3(@moonphys.identity_basis3(), state.position),
    [],
    [],
  )
  let _ = tree.link_transform("missing")
}
