///|
pub(all) struct RigidBodyInertia {
  body_id : String
  diagonal_kg_m2 : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MassPropertyElement {
  element_id : String
  mass_kg : Double
  center_of_mass : Vec3
  inertia_about_center : RigidBodyInertia
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CompositeMassProperties {
  body_id : String
  element_count : Int
  total_mass_kg : Double
  center_of_mass : Vec3
  inertia_about_center : RigidBodyInertia
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyAngularState {
  body_id : String
  orientation : Basis3
  angular_velocity_rad_s : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RigidBodyAngularStep {
  dt_s : Double
  torque_nm : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_inertia(
  body_id : String,
  diagonal_kg_m2 : Vec3,
) -> RigidBodyInertia {
  { body_id, diagonal_kg_m2 }
}

///|
pub fn mass_property_element(
  element_id : String,
  mass_kg : Double,
  center_of_mass : Vec3,
  inertia_about_center : RigidBodyInertia,
) -> MassPropertyElement {
  {
    element_id,
    mass_kg: nonnegative_mass(mass_kg),
    center_of_mass,
    inertia_about_center,
  }
}

///|
fn nonnegative_mass(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else {
    value
  }
}

///|
pub fn sphere_diagonal_inertia(
  body_id : String,
  mass_kg : Double,
  radius_m : Double,
) -> RigidBodyInertia {
  let mass = nonnegative_mass(mass_kg)
  let radius = nonnegative_mass(radius_m)
  let value = 0.4 * mass * radius * radius
  rigid_body_inertia(body_id, vec3(value, value, value))
}

///|
pub fn box_diagonal_inertia(
  body_id : String,
  mass_kg : Double,
  half_extents_m : Vec3,
) -> RigidBodyInertia {
  let mass = nonnegative_mass(mass_kg)
  let x2 = nonnegative_mass(half_extents_m.x) *
    nonnegative_mass(half_extents_m.x)
  let y2 = nonnegative_mass(half_extents_m.y) *
    nonnegative_mass(half_extents_m.y)
  let z2 = nonnegative_mass(half_extents_m.z) *
    nonnegative_mass(half_extents_m.z)
  rigid_body_inertia(
    body_id,
    vec3(mass * (y2 + z2) / 3.0, mass * (x2 + z2) / 3.0, mass * (x2 + y2) / 3.0),
  )
}

///|
pub fn capsule_diagonal_inertia(
  body_id : String,
  mass_kg : Double,
  radius_m : Double,
  half_height_m : Double,
) -> RigidBodyInertia {
  let mass = nonnegative_mass(mass_kg)
  let radius = nonnegative_mass(radius_m)
  let half_height = nonnegative_mass(half_height_m)
  if radius <= 0.0 {
    let transverse = mass * half_height * half_height / 3.0
    rigid_body_inertia(body_id, vec3(transverse, transverse, 0.0))
  } else if half_height <= 0.0 {
    sphere_diagonal_inertia(body_id, mass, radius)
  } else {
    let cylinder_factor = 2.0 * half_height * radius * radius
    let sphere_factor = 4.0 * radius * radius * radius / 3.0
    let total_factor = cylinder_factor + sphere_factor
    let cylinder_mass = mass * cylinder_factor / total_factor
    let sphere_mass = mass - cylinder_mass
    let cylinder_length = 2.0 * half_height
    let cylinder_transverse = cylinder_mass *
      (3.0 * radius * radius + cylinder_length * cylinder_length) /
      12.0
    let cylinder_axial = 0.5 * cylinder_mass * radius * radius
    let cap_transverse = 0.4 * sphere_mass * radius * radius +
      sphere_mass * half_height * half_height +
      0.75 * sphere_mass * half_height * radius
    let cap_axial = 0.4 * sphere_mass * radius * radius
    rigid_body_inertia(
      body_id,
      vec3(
        cylinder_transverse + cap_transverse,
        cylinder_transverse + cap_transverse,
        cylinder_axial + cap_axial,
      ),
    )
  }
}

///|
pub fn collision_shape_diagonal_inertia(
  body_id : String,
  mass_kg : Double,
  shape : CollisionShape,
) -> RigidBodyInertia {
  match shape.kind {
    SphereShape => sphere_diagonal_inertia(body_id, mass_kg, shape.radius_m)
    CapsuleShape =>
      capsule_diagonal_inertia(
        body_id,
        mass_kg,
        shape.radius_m,
        shape.half_height_m,
      )
    BoxShape => box_diagonal_inertia(body_id, mass_kg, shape.half_extents_m)
  }
}

///|
pub fn collision_shape_mass_element(
  element_id : String,
  mass_kg : Double,
  shape : CollisionShape,
  center_of_mass : Vec3,
) -> MassPropertyElement {
  mass_property_element(
    element_id,
    mass_kg,
    center_of_mass,
    collision_shape_diagonal_inertia(element_id, mass_kg, shape),
  )
}

///|
fn mass_weighted_center(elements : Array[MassPropertyElement]) -> Vec3 {
  let mut weighted = vec3(0.0, 0.0, 0.0)
  let mut total_mass = 0.0
  for element in elements {
    let mass = nonnegative_mass(element.mass_kg)
    weighted = weighted.add(element.center_of_mass.scale(mass))
    total_mass += mass
  }
  if total_mass > 0.0 {
    weighted.scale(1.0 / total_mass)
  } else {
    vec3(0.0, 0.0, 0.0)
  }
}

///|
fn parallel_axis_diagonal(mass_kg : Double, offset : Vec3) -> Vec3 {
  let mass = nonnegative_mass(mass_kg)
  vec3(
    mass * (offset.y * offset.y + offset.z * offset.z),
    mass * (offset.x * offset.x + offset.z * offset.z),
    mass * (offset.x * offset.x + offset.y * offset.y),
  )
}

///|
fn composite_mass_status(element_count : Int, total_mass_kg : Double) -> String {
  if element_count <= 0 {
    "composite-mass-empty"
  } else if total_mass_kg <= 0.0 {
    "composite-mass-zero"
  } else {
    "composite-mass-resolved"
  }
}

///|
pub fn composite_mass_properties(
  body_id : String,
  elements : Array[MassPropertyElement],
) -> CompositeMassProperties {
  let center = mass_weighted_center(elements)
  let mut total_mass = 0.0
  let mut inertia = vec3(0.0, 0.0, 0.0)
  for element in elements {
    let mass = nonnegative_mass(element.mass_kg)
    total_mass += mass
    let offset = element.center_of_mass.sub(center)
    inertia = inertia
      .add(element.inertia_about_center.diagonal_kg_m2)
      .add(parallel_axis_diagonal(mass, offset))
  }
  {
    body_id,
    element_count: elements.length(),
    total_mass_kg: total_mass,
    center_of_mass: center,
    inertia_about_center: rigid_body_inertia(body_id, inertia),
    status: composite_mass_status(elements.length(), total_mass),
  }
}

///|
pub fn rigid_body_angular_state(
  body_id : String,
  orientation : Basis3,
  angular_velocity_rad_s : Vec3,
) -> RigidBodyAngularState {
  { body_id, orientation, angular_velocity_rad_s }
}

///|
fn safe_axis_acceleration(torque : Double, inertia : Double) -> Double {
  if inertia > 0.0 {
    torque / inertia
  } else {
    0.0
  }
}

///|
pub fn angular_acceleration(
  inertia : RigidBodyInertia,
  torque_nm : Vec3,
) -> Vec3 {
  vec3(
    safe_axis_acceleration(torque_nm.x, inertia.diagonal_kg_m2.x),
    safe_axis_acceleration(torque_nm.y, inertia.diagonal_kg_m2.y),
    safe_axis_acceleration(torque_nm.z, inertia.diagonal_kg_m2.z),
  )
}

///|
pub fn angular_momentum(
  inertia : RigidBodyInertia,
  state : RigidBodyAngularState,
) -> Vec3 {
  vec3(
    inertia.diagonal_kg_m2.x * state.angular_velocity_rad_s.x,
    inertia.diagonal_kg_m2.y * state.angular_velocity_rad_s.y,
    inertia.diagonal_kg_m2.z * state.angular_velocity_rad_s.z,
  )
}

///|
pub fn contact_torque(
  center_of_mass : Vec3,
  application_point : Vec3,
  force_n : Vec3,
) -> Vec3 {
  application_point.sub(center_of_mass).cross(force_n)
}

///|
fn integrate_orientation(
  orientation : Basis3,
  angular_velocity : Vec3,
  dt_s : Double,
) -> Basis3 {
  let speed = angular_velocity.length_squared().sqrt()
  if speed <= 0.0 || dt_s <= 0.0 {
    orientation
  } else {
    orientation.mul_basis3(axis_angle_basis3(angular_velocity, speed * dt_s))
  }
}

///|
pub fn integrate_angular_rigid_body(
  state : RigidBodyAngularState,
  inertia : RigidBodyInertia,
  step : RigidBodyAngularStep,
) -> RigidBodyAngularState {
  let velocity = state.angular_velocity_rad_s.add(
    angular_acceleration(inertia, step.torque_nm).scale(step.dt_s),
  )
  {
    body_id: state.body_id,
    orientation: integrate_orientation(state.orientation, velocity, step.dt_s),
    angular_velocity_rad_s: velocity,
  }
}
