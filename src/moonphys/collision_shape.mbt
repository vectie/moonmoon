///|
pub(all) enum CollisionShapeKind {
  SphereShape
  CapsuleShape
  BoxShape
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CollisionShape {
  shape_id : String
  kind : CollisionShapeKind
  radius_m : Double
  half_height_m : Double
  half_extents_m : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CollisionBounds {
  shape_id : String
  kind : CollisionShapeKind
  center : Vec3
  bounding_radius_m : Double
  min : Vec3
  max : Vec3
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CollisionPairProbe {
  shape_a_id : String
  shape_b_id : String
  center_distance_m : Double
  separation_m : Double
  overlapping : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn nonnegative(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else {
    value
  }
}

///|
pub fn collision_sphere(shape_id : String, radius_m : Double) -> CollisionShape {
  {
    shape_id,
    kind: SphereShape,
    radius_m: nonnegative(radius_m),
    half_height_m: 0.0,
    half_extents_m: vec3(0.0, 0.0, 0.0),
  }
}

///|
pub fn collision_capsule(
  shape_id : String,
  radius_m : Double,
  half_height_m : Double,
) -> CollisionShape {
  {
    shape_id,
    kind: CapsuleShape,
    radius_m: nonnegative(radius_m),
    half_height_m: nonnegative(half_height_m),
    half_extents_m: vec3(0.0, 0.0, 0.0),
  }
}

///|
pub fn collision_box(
  shape_id : String,
  half_extents_m : Vec3,
) -> CollisionShape {
  {
    shape_id,
    kind: BoxShape,
    radius_m: 0.0,
    half_height_m: 0.0,
    half_extents_m: vec3(
      nonnegative(half_extents_m.x),
      nonnegative(half_extents_m.y),
      nonnegative(half_extents_m.z),
    ),
  }
}

///|
pub fn collision_shape_kind_label(kind : CollisionShapeKind) -> String {
  match kind {
    SphereShape => "sphere"
    CapsuleShape => "capsule"
    BoxShape => "box"
  }
}

///|
pub fn collision_bounding_radius(shape : CollisionShape) -> Double {
  match shape.kind {
    SphereShape => shape.radius_m
    CapsuleShape => shape.half_height_m + shape.radius_m
    BoxShape => shape.half_extents_m.length_squared().sqrt()
  }
}

///|
pub fn collision_world_bounds(
  shape : CollisionShape,
  transform : Transform3,
) -> CollisionBounds {
  let center = transform.translation
  let radius = collision_bounding_radius(shape)
  {
    shape_id: shape.shape_id,
    kind: shape.kind,
    center,
    bounding_radius_m: radius,
    min: center.sub(vec3(radius, radius, radius)),
    max: center.add(vec3(radius, radius, radius)),
    status: "conservative-bounds",
  }
}

///|
pub fn collision_pair_probe(
  shape_a : CollisionShape,
  transform_a : Transform3,
  shape_b : CollisionShape,
  transform_b : Transform3,
) -> CollisionPairProbe {
  let bounds_a = collision_world_bounds(shape_a, transform_a)
  let bounds_b = collision_world_bounds(shape_b, transform_b)
  let center_distance = bounds_a.center
    .sub(bounds_b.center)
    .length_squared()
    .sqrt()
  let separation = center_distance -
    bounds_a.bounding_radius_m -
    bounds_b.bounding_radius_m
  let overlapping = separation <= 0.0
  {
    shape_a_id: shape_a.shape_id,
    shape_b_id: shape_b.shape_id,
    center_distance_m: center_distance,
    separation_m: separation,
    overlapping,
    status: if overlapping {
      "broadphase-overlap"
    } else {
      "broadphase-clear"
    },
  }
}
