///|
pub(all) struct RigidBodyState {
  body_id : String
  mass_kg : Double
  collision_radius_m : Double
  position : Vec3
  velocity : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MaterialContactModel {
  material_id : String
  friction_coefficient : Double
  restitution_coefficient : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct HeightfieldCollision {
  body_id : String
  sample : HeightfieldSample
  contact_point : Vec3
  clearance_m : Double
  penetration_depth_m : Double
  normal_velocity_mps : Double
  tangent_speed_mps : Double
  in_contact : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ContactResolution {
  before : RigidBodyState
  after : RigidBodyState
  collision : HeightfieldCollision
  material : MaterialContactModel
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_state(
  body_id : String,
  mass_kg : Double,
  collision_radius_m : Double,
  position : Vec3,
  velocity : Vec3,
) -> RigidBodyState {
  { body_id, mass_kg, collision_radius_m, position, velocity }
}

///|
pub fn material_contact_model(
  material_id : String,
  friction_coefficient : Double,
  restitution_coefficient : Double,
) -> MaterialContactModel {
  { material_id, friction_coefficient, restitution_coefficient }
}

///|
pub fn lunar_regolith_contact_model() -> MaterialContactModel {
  material_contact_model("lunar-regolith-review-model", 0.62, 0.04)
}

///|
pub fn integrate_rigid_body(
  state : RigidBodyState,
  dt_s : Double,
  acceleration : Vec3,
) -> RigidBodyState {
  let velocity = state.velocity.add(acceleration.scale(dt_s))
  {
    body_id: state.body_id,
    mass_kg: state.mass_kg,
    collision_radius_m: state.collision_radius_m,
    position: state.position.add(velocity.scale(dt_s)),
    velocity,
  }
}

///|
pub fn integrate_rigid_body_gravity(
  state : RigidBodyState,
  environment : PhysicsEnvironment,
  dt_s : Double,
) -> RigidBodyState {
  integrate_rigid_body(
    state,
    dt_s,
    vec3(0.0, 0.0, 0.0 - environment.gravity_mps2),
  )
}

///|
pub fn heightfield_collision(
  field : Heightfield,
  state : RigidBodyState,
) -> HeightfieldCollision {
  let sample = sample_heightfield(field, state.position.x, state.position.y)
  let contact_z = sample.elevation_m + state.collision_radius_m
  let clearance = state.position.z - contact_z
  let penetration = if clearance < 0.0 { 0.0 - clearance } else { 0.0 }
  let tangent_speed = (state.velocity.x * state.velocity.x +
  state.velocity.y * state.velocity.y).sqrt()
  {
    body_id: state.body_id,
    sample,
    contact_point: vec3(state.position.x, state.position.y, contact_z),
    clearance_m: clearance,
    penetration_depth_m: penetration,
    normal_velocity_mps: state.velocity.z,
    tangent_speed_mps: tangent_speed,
    in_contact: clearance <= 0.0,
    status: if clearance <= 0.0 {
      "heightfield-contact"
    } else {
      "heightfield-clear"
    },
  }
}

///|
fn friction_scale(material : MaterialContactModel) -> Double {
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
fn resolved_normal_velocity(
  velocity_z : Double,
  material : MaterialContactModel,
) -> Double {
  if velocity_z < 0.0 {
    (0.0 - velocity_z) * material.restitution_coefficient
  } else {
    velocity_z
  }
}

///|
pub fn resolve_heightfield_contact(
  field : Heightfield,
  state : RigidBodyState,
  material : MaterialContactModel,
) -> ContactResolution {
  let collision = heightfield_collision(field, state)
  if collision.in_contact {
    let scale = friction_scale(material)
    let after = {
      body_id: state.body_id,
      mass_kg: state.mass_kg,
      collision_radius_m: state.collision_radius_m,
      position: vec3(
        state.position.x,
        state.position.y,
        collision.contact_point.z,
      ),
      velocity: vec3(
        state.velocity.x * scale,
        state.velocity.y * scale,
        resolved_normal_velocity(state.velocity.z, material),
      ),
    }
    { before: state, after, collision, material, status: "contact-resolved" }
  } else {
    { before: state, after: state, collision, material, status: "clear" }
  }
}
