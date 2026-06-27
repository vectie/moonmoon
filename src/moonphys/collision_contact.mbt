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
pub(all) struct CollisionManifoldResolution {
  before : RigidBodyState
  after : RigidBodyState
  manifold_id : String
  contact_count : Int
  max_penetration_m : Double
  material : MaterialContactModel
  average_normal : Vec3
  correction : Vec3
  velocity_delta : Vec3
  normal_speed_mps : Double
  tangent_speed_mps : Double
  normal_impulse_ns : Double
  friction_impulse_ns : Double
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
fn exact_contact_status(prefix : String, in_contact : Bool) -> String {
  if in_contact {
    "\{prefix}-contact"
  } else {
    "\{prefix}-clear"
  }
}

///|
fn clamp_double(value : Double, low : Double, high : Double) -> Double {
  if value < low {
    low
  } else if value > high {
    high
  } else {
    value
  }
}

///|
fn normalized_or_x(value : Vec3) -> Vec3 {
  let length = value.length_squared().sqrt()
  if length > 0.0 {
    value.scale(1.0 / length)
  } else {
    vec3(1.0, 0.0, 0.0)
  }
}

///|
fn basis_x(basis : Basis3) -> Vec3 {
  basis.mul_vec3(vec3(1.0, 0.0, 0.0))
}

///|
fn basis_y(basis : Basis3) -> Vec3 {
  basis.mul_vec3(vec3(0.0, 1.0, 0.0))
}

///|
fn basis_z(basis : Basis3) -> Vec3 {
  basis.mul_vec3(vec3(0.0, 0.0, 1.0))
}

///|
fn inverse_transform_point(transform : Transform3, point : Vec3) -> Vec3 {
  let delta = point.sub(transform.translation)
  vec3(
    transform.basis.xx * delta.x +
    transform.basis.yx * delta.y +
    transform.basis.zx * delta.z,
    transform.basis.xy * delta.x +
    transform.basis.yy * delta.y +
    transform.basis.zy * delta.z,
    transform.basis.xz * delta.x +
    transform.basis.yz * delta.y +
    transform.basis.zz * delta.z,
  )
}

///|
fn clamped_box_point(box : CollisionShape, local_point : Vec3) -> Vec3 {
  vec3(
    clamp_double(
      local_point.x,
      0.0 - box.half_extents_m.x,
      box.half_extents_m.x,
    ),
    clamp_double(
      local_point.y,
      0.0 - box.half_extents_m.y,
      box.half_extents_m.y,
    ),
    clamp_double(
      local_point.z,
      0.0 - box.half_extents_m.z,
      box.half_extents_m.z,
    ),
  )
}

///|
fn capsule_axis_start(shape : CollisionShape, transform : Transform3) -> Vec3 {
  transform.transform_point(vec3(0.0, 0.0, 0.0 - shape.half_height_m))
}

///|
fn capsule_axis_end(shape : CollisionShape, transform : Transform3) -> Vec3 {
  transform.transform_point(vec3(0.0, 0.0, shape.half_height_m))
}

///|
fn closest_point_on_segment(point : Vec3, start : Vec3, end : Vec3) -> Vec3 {
  let segment = end.sub(start)
  let length_squared = segment.length_squared()
  if length_squared > 0.0 {
    let t = clamp_double(
      point.sub(start).dot(segment) / length_squared,
      0.0,
      1.0,
    )
    start.add(segment.scale(t))
  } else {
    start
  }
}

///|
priv struct SegmentClosest {
  point_a : Vec3
  point_b : Vec3
}

///|
fn closest_points_between_segments(
  a0 : Vec3,
  a1 : Vec3,
  b0 : Vec3,
  b1 : Vec3,
) -> SegmentClosest {
  let d1 = a1.sub(a0)
  let d2 = b1.sub(b0)
  let r = a0.sub(b0)
  let a = d1.dot(d1)
  let e = d2.dot(d2)
  let epsilon = 0.000000001
  let mut s = 0.0
  let mut t = 0.0
  if a <= epsilon && e <= epsilon {
    { point_a: a0, point_b: b0 }
  } else {
    if a <= epsilon {
      s = 0.0
      t = clamp_double(d2.dot(r) / e, 0.0, 1.0)
    } else {
      let c = d1.dot(r)
      if e <= epsilon {
        t = 0.0
        s = clamp_double((0.0 - c) / a, 0.0, 1.0)
      } else {
        let b = d1.dot(d2)
        let f = d2.dot(r)
        let denom = a * e - b * b
        s = if denom != 0.0 {
          clamp_double((b * f - c * e) / denom, 0.0, 1.0)
        } else {
          0.0
        }
        let t_nom = b * s + f
        if t_nom < 0.0 {
          t = 0.0
          s = clamp_double((0.0 - c) / a, 0.0, 1.0)
        } else if t_nom > e {
          t = 1.0
          s = clamp_double((b - c) / a, 0.0, 1.0)
        } else {
          t = t_nom / e
        }
      }
    }
    { point_a: a0.add(d1.scale(s)), point_b: b0.add(d2.scale(t)) }
  }
}

///|
fn distance_contact(
  shape_a_id : String,
  shape_b_id : String,
  anchor_a : Vec3,
  radius_a : Double,
  anchor_b : Vec3,
  radius_b : Double,
  status_prefix : String,
) -> CollisionContact {
  let normal = normalized_or_x(anchor_b.sub(anchor_a))
  let distance = anchor_a.sub(anchor_b).length_squared().sqrt()
  let separation = distance - radius_a - radius_b
  let penetration = if separation < 0.0 { 0.0 - separation } else { 0.0 }
  let in_contact = separation <= 0.0
  {
    shape_a_id,
    shape_b_id,
    point: anchor_a.add(normal.scale(radius_a - penetration * 0.5)),
    normal,
    separation_m: separation,
    penetration_depth_m: penetration,
    in_contact,
    status: exact_contact_status(status_prefix, in_contact),
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
fn sphere_capsule_contact(
  sphere : CollisionShape,
  sphere_transform : Transform3,
  capsule : CollisionShape,
  capsule_transform : Transform3,
) -> CollisionContact {
  distance_contact(
    sphere.shape_id,
    capsule.shape_id,
    sphere_transform.translation,
    sphere.radius_m,
    closest_point_on_segment(
      sphere_transform.translation,
      capsule_axis_start(capsule, capsule_transform),
      capsule_axis_end(capsule, capsule_transform),
    ),
    capsule.radius_m,
    "sphere-capsule",
  )
}

///|
fn nearest_box_face_normal(box : CollisionShape, local_point : Vec3) -> Vec3 {
  let dx = box.half_extents_m.x - abs_double(local_point.x)
  let dy = box.half_extents_m.y - abs_double(local_point.y)
  let dz = box.half_extents_m.z - abs_double(local_point.z)
  if dx <= dy && dx <= dz {
    vec3(if local_point.x < 0.0 { 0.0 - 1.0 } else { 1.0 }, 0.0, 0.0)
  } else if dy <= dz {
    vec3(0.0, if local_point.y < 0.0 { 0.0 - 1.0 } else { 1.0 }, 0.0)
  } else {
    vec3(0.0, 0.0, if local_point.z < 0.0 { 0.0 - 1.0 } else { 1.0 })
  }
}

///|
fn nearest_box_face_distance(
  box : CollisionShape,
  local_point : Vec3,
) -> Double {
  let dx = box.half_extents_m.x - abs_double(local_point.x)
  let dy = box.half_extents_m.y - abs_double(local_point.y)
  let dz = box.half_extents_m.z - abs_double(local_point.z)
  if dx <= dy && dx <= dz {
    dx
  } else if dy <= dz {
    dy
  } else {
    dz
  }
}

///|
fn sphere_box_contact(
  sphere : CollisionShape,
  sphere_transform : Transform3,
  box : CollisionShape,
  box_transform : Transform3,
) -> CollisionContact {
  let sphere_local = inverse_transform_point(
    box_transform,
    sphere_transform.translation,
  )
  let closest_local = clamped_box_point(box, sphere_local)
  let delta_local = closest_local.sub(sphere_local)
  if delta_local.length_squared() > 0.0 {
    distance_contact(
      sphere.shape_id,
      box.shape_id,
      sphere_transform.translation,
      sphere.radius_m,
      box_transform.transform_point(closest_local),
      0.0,
      "sphere-box",
    )
  } else {
    let local_normal = nearest_box_face_normal(box, sphere_local)
    let normal = box_transform.basis.mul_vec3(local_normal)
    let face_distance = nearest_box_face_distance(box, sphere_local)
    let separation = 0.0 - sphere.radius_m - face_distance
    let penetration = 0.0 - separation
    {
      shape_a_id: sphere.shape_id,
      shape_b_id: box.shape_id,
      point: sphere_transform.translation.add(
        normal.scale(sphere.radius_m - penetration * 0.5),
      ),
      normal,
      separation_m: separation,
      penetration_depth_m: penetration,
      in_contact: true,
      status: "sphere-box-contact",
    }
  }
}

///|
fn capsule_capsule_contact(
  shape_a : CollisionShape,
  transform_a : Transform3,
  shape_b : CollisionShape,
  transform_b : Transform3,
) -> CollisionContact {
  let closest = closest_points_between_segments(
    capsule_axis_start(shape_a, transform_a),
    capsule_axis_end(shape_a, transform_a),
    capsule_axis_start(shape_b, transform_b),
    capsule_axis_end(shape_b, transform_b),
  )
  distance_contact(
    shape_a.shape_id,
    shape_b.shape_id,
    closest.point_a,
    shape_a.radius_m,
    closest.point_b,
    shape_b.radius_m,
    "capsule-capsule",
  )
}

///|
fn capsule_box_contact(
  capsule : CollisionShape,
  capsule_transform : Transform3,
  box : CollisionShape,
  box_transform : Transform3,
) -> CollisionContact {
  let segment_start = inverse_transform_point(
    box_transform,
    capsule_axis_start(capsule, capsule_transform),
  )
  let segment_end = inverse_transform_point(
    box_transform,
    capsule_axis_end(capsule, capsule_transform),
  )
  let mut capsule_local = closest_point_on_segment(
    vec3(0.0, 0.0, 0.0),
    segment_start,
    segment_end,
  )
  let mut box_local = clamped_box_point(box, capsule_local)
  capsule_local = closest_point_on_segment(
    box_local, segment_start, segment_end,
  )
  box_local = clamped_box_point(box, capsule_local)
  capsule_local = closest_point_on_segment(
    box_local, segment_start, segment_end,
  )
  box_local = clamped_box_point(box, capsule_local)
  distance_contact(
    capsule.shape_id,
    box.shape_id,
    box_transform.transform_point(capsule_local),
    capsule.radius_m,
    box_transform.transform_point(box_local),
    0.0,
    "capsule-box",
  )
}

///|
fn box_projection_radius(
  shape : CollisionShape,
  transform : Transform3,
  axis : Vec3,
) -> Double {
  shape.half_extents_m.x * abs_double(axis.dot(basis_x(transform.basis))) +
  shape.half_extents_m.y * abs_double(axis.dot(basis_y(transform.basis))) +
  shape.half_extents_m.z * abs_double(axis.dot(basis_z(transform.basis)))
}

///|
fn box_box_contact(
  shape_a : CollisionShape,
  transform_a : Transform3,
  shape_b : CollisionShape,
  transform_b : Transform3,
) -> CollisionContact {
  let axes : Array[Vec3] = [
    basis_x(transform_a.basis),
    basis_y(transform_a.basis),
    basis_z(transform_a.basis),
    basis_x(transform_b.basis),
    basis_y(transform_b.basis),
    basis_z(transform_b.basis),
  ]
  let ax = basis_x(transform_a.basis)
  let ay = basis_y(transform_a.basis)
  let az = basis_z(transform_a.basis)
  let bx = basis_x(transform_b.basis)
  let by = basis_y(transform_b.basis)
  let bz = basis_z(transform_b.basis)
  for
    axis in [
      ax.cross(bx),
      ax.cross(by),
      ax.cross(bz),
      ay.cross(bx),
      ay.cross(by),
      ay.cross(bz),
      az.cross(bx),
      az.cross(by),
      az.cross(bz),
    ] {
    if axis.length_squared() > 0.000000000001 {
      axes.push(axis)
    }
  }
  let center_delta = transform_b.translation.sub(transform_a.translation)
  let mut best_separation = 0.0 - 1000000000.0
  let mut best_axis = vec3(1.0, 0.0, 0.0)
  let mut best_radius_a = 0.0
  for raw_axis in axes {
    let axis = normalized_or_x(raw_axis)
    let radius_a = box_projection_radius(shape_a, transform_a, axis)
    let radius_b = box_projection_radius(shape_b, transform_b, axis)
    let signed_distance = center_delta.dot(axis)
    let separation = abs_double(signed_distance) - radius_a - radius_b
    let oriented_axis = if signed_distance < 0.0 {
      axis.scale(0.0 - 1.0)
    } else {
      axis
    }
    if separation > 0.0 {
      return distance_contact(
        shape_a.shape_id,
        shape_b.shape_id,
        transform_a.translation,
        radius_a,
        transform_a.translation.add(oriented_axis.scale(radius_a + separation)),
        0.0,
        "box-box",
      )
    }
    if separation > best_separation {
      best_separation = separation
      best_axis = oriented_axis
      best_radius_a = radius_a
    }
  }
  let penetration = 0.0 - best_separation
  {
    shape_a_id: shape_a.shape_id,
    shape_b_id: shape_b.shape_id,
    point: transform_a.translation.add(
      best_axis.scale(best_radius_a - penetration * 0.5),
    ),
    normal: best_axis,
    separation_m: best_separation,
    penetration_depth_m: penetration,
    in_contact: true,
    status: "box-box-contact",
  }
}

///|
fn reverse_contact(
  contact : CollisionContact,
  shape_a_id : String,
  shape_b_id : String,
  status_prefix : String,
) -> CollisionContact {
  {
    shape_a_id,
    shape_b_id,
    point: contact.point,
    normal: contact.normal.scale(0.0 - 1.0),
    separation_m: contact.separation_m,
    penetration_depth_m: contact.penetration_depth_m,
    in_contact: contact.in_contact,
    status: exact_contact_status(status_prefix, contact.in_contact),
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
  } else if shape_a.kind == SphereShape && shape_b.kind == CapsuleShape {
    sphere_capsule_contact(shape_a, transform_a, shape_b, transform_b)
  } else if shape_a.kind == CapsuleShape && shape_b.kind == SphereShape {
    reverse_contact(
      sphere_capsule_contact(shape_b, transform_b, shape_a, transform_a),
      shape_a.shape_id,
      shape_b.shape_id,
      "capsule-sphere",
    )
  } else if shape_a.kind == SphereShape && shape_b.kind == BoxShape {
    sphere_box_contact(shape_a, transform_a, shape_b, transform_b)
  } else if shape_a.kind == BoxShape && shape_b.kind == SphereShape {
    reverse_contact(
      sphere_box_contact(shape_b, transform_b, shape_a, transform_a),
      shape_a.shape_id,
      shape_b.shape_id,
      "box-sphere",
    )
  } else if shape_a.kind == CapsuleShape && shape_b.kind == CapsuleShape {
    capsule_capsule_contact(shape_a, transform_a, shape_b, transform_b)
  } else if shape_a.kind == CapsuleShape && shape_b.kind == BoxShape {
    capsule_box_contact(shape_a, transform_a, shape_b, transform_b)
  } else if shape_a.kind == BoxShape && shape_b.kind == CapsuleShape {
    reverse_contact(
      capsule_box_contact(shape_b, transform_b, shape_a, transform_a),
      shape_a.shape_id,
      shape_b.shape_id,
      "box-capsule",
    )
  } else if shape_a.kind == BoxShape && shape_b.kind == BoxShape {
    box_box_contact(shape_a, transform_a, shape_b, transform_b)
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
fn collision_friction_scale(material : MaterialContactModel) -> Double {
  let raw = 1.0 - material.friction_coefficient
  if raw < 0.0 {
    0.0
  } else if raw > 1.0 {
    1.0
  } else {
    raw
  }
}

///|
pub fn resolve_collision_manifold(
  state : RigidBodyState,
  manifold : CollisionContactManifold,
  material : MaterialContactModel,
) -> CollisionManifoldResolution {
  if manifold.contact_count == 0 {
    {
      before: state,
      after: state,
      manifold_id: manifold.manifold_id,
      contact_count: 0,
      max_penetration_m: 0.0,
      material,
      average_normal: vec3(0.0, 0.0, 1.0),
      correction: vec3(0.0, 0.0, 0.0),
      velocity_delta: vec3(0.0, 0.0, 0.0),
      normal_speed_mps: 0.0,
      tangent_speed_mps: state.velocity.length_squared().sqrt(),
      normal_impulse_ns: 0.0,
      friction_impulse_ns: 0.0,
      status: "no-contact",
    }
  } else {
    let normal = normalized_or_up(manifold.average_normal)
    let normal_speed = state.velocity.dot(normal)
    let normal_velocity = normal.scale(normal_speed)
    let tangent_velocity = state.velocity.sub(normal_velocity)
    let tangent_speed = tangent_velocity.length_squared().sqrt()
    let scale = collision_friction_scale(material)
    let resolved_normal_velocity = if normal_speed > 0.0 {
      normal.scale((0.0 - normal_speed) * material.restitution_coefficient)
    } else {
      normal_velocity
    }
    let correction = normal.scale(0.0 - manifold.max_penetration_m)
    let after = {
      body_id: state.body_id,
      mass_kg: state.mass_kg,
      collision_radius_m: state.collision_radius_m,
      position: state.position.add(correction),
      velocity: tangent_velocity.scale(scale).add(resolved_normal_velocity),
    }
    let velocity_delta = after.velocity.sub(state.velocity)
    let normal_impulse = abs_double(velocity_delta.dot(normal)) * state.mass_kg
    let friction_impulse = velocity_delta
      .sub(normal.scale(velocity_delta.dot(normal)))
      .length_squared()
      .sqrt() *
      state.mass_kg
    {
      before: state,
      after,
      manifold_id: manifold.manifold_id,
      contact_count: manifold.contact_count,
      max_penetration_m: manifold.max_penetration_m,
      material,
      average_normal: normal,
      correction,
      velocity_delta,
      normal_speed_mps: normal_speed,
      tangent_speed_mps: tangent_speed,
      normal_impulse_ns: normal_impulse,
      friction_impulse_ns: friction_impulse,
      status: if manifold.contact_count > 1 {
        "multi-contact-resolved"
      } else {
        "single-contact-resolved"
      },
    }
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
