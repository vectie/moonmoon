///|
pub(all) struct CollisionContact {
  shape_a_id : String
  shape_b_id : String
  point : Vec3
  normal : Vec3
  separation_m : Double
  penetration_depth_m : Double
  in_contact : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CollisionContactManifold {
  manifold_id : String
  contacts : Array[CollisionContact]
  contact_count : Int
  max_penetration_m : Double
  average_normal : Vec3
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn contact_normal(from : Vec3, to : Vec3) -> Vec3 {
  let delta = to.sub(from)
  let distance = delta.length_squared().sqrt()
  if distance > 0.0 {
    delta.scale(1.0 / distance)
  } else {
    vec3(1.0, 0.0, 0.0)
  }
}

///|
fn contact_status(in_contact : Bool, exact : Bool) -> String {
  if exact {
    if in_contact {
      "sphere-sphere-contact"
    } else {
      "sphere-sphere-clear"
    }
  } else if in_contact {
    "conservative-contact"
  } else {
    "conservative-clear"
  }
}

///|
fn collision_contact_from_bounds(
  shape_a : CollisionShape,
  bounds_a : CollisionBounds,
  radius_a : Double,
  shape_b : CollisionShape,
  bounds_b : CollisionBounds,
  radius_b : Double,
  exact : Bool,
) -> CollisionContact {
  let normal = contact_normal(bounds_a.center, bounds_b.center)
  let distance = bounds_a.center.sub(bounds_b.center).length_squared().sqrt()
  let separation = distance - radius_a - radius_b
  let penetration = if separation < 0.0 { 0.0 - separation } else { 0.0 }
  let in_contact = separation <= 0.0
  {
    shape_a_id: shape_a.shape_id,
    shape_b_id: shape_b.shape_id,
    point: bounds_a.center.add(normal.scale(radius_a - penetration * 0.5)),
    normal,
    separation_m: separation,
    penetration_depth_m: penetration,
    in_contact,
    status: contact_status(in_contact, exact),
  }
}

///|
pub fn sphere_sphere_contact(
  shape_a : CollisionShape,
  transform_a : Transform3,
  shape_b : CollisionShape,
  transform_b : Transform3,
) -> CollisionContact {
  collision_contact_from_bounds(
    shape_a,
    collision_world_bounds(shape_a, transform_a),
    shape_a.radius_m,
    shape_b,
    collision_world_bounds(shape_b, transform_b),
    shape_b.radius_m,
    true,
  )
}

///|
pub fn collision_pair_contact(
  shape_a : CollisionShape,
  transform_a : Transform3,
  shape_b : CollisionShape,
  transform_b : Transform3,
) -> CollisionContact {
  if shape_a.kind == SphereShape && shape_b.kind == SphereShape {
    sphere_sphere_contact(shape_a, transform_a, shape_b, transform_b)
  } else {
    let bounds_a = collision_world_bounds(shape_a, transform_a)
    let bounds_b = collision_world_bounds(shape_b, transform_b)
    collision_contact_from_bounds(
      shape_a,
      bounds_a,
      bounds_a.bounding_radius_m,
      shape_b,
      bounds_b,
      bounds_b.bounding_radius_m,
      false,
    )
  }
}

///|
fn normalized_or_up(value : Vec3) -> Vec3 {
  let length = value.length_squared().sqrt()
  if length > 0.0 {
    value.scale(1.0 / length)
  } else {
    vec3(0.0, 0.0, 1.0)
  }
}

///|
pub fn collision_contact_manifold(
  manifold_id : String,
  contacts : Array[CollisionContact],
) -> CollisionContactManifold {
  let mut contact_count = 0
  let mut max_penetration = 0.0
  let mut normal_sum = vec3(0.0, 0.0, 0.0)
  for contact in contacts {
    if contact.in_contact {
      contact_count += 1
      normal_sum = normal_sum.add(contact.normal)
      if contact.penetration_depth_m > max_penetration {
        max_penetration = contact.penetration_depth_m
      }
    }
  }
  {
    manifold_id,
    contacts,
    contact_count,
    max_penetration_m: max_penetration,
    average_normal: normalized_or_up(normal_sum),
    status: if contact_count > 1 {
      "multi-contact"
    } else if contact_count == 1 {
      "single-contact"
    } else {
      "no-contact"
    },
  }
}
