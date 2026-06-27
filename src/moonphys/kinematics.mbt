///|
pub(all) struct KinematicBodyState {
  body_id : String
  position : Vec3
  velocity : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct KinematicStep {
  dt_s : Double
  acceleration : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn kinematic_body_state(
  body_id : String,
  position : Vec3,
  velocity : Vec3,
) -> KinematicBodyState {
  { body_id, position, velocity }
}

///|
pub fn lunar_gravity_acceleration() -> Vec3 {
  vec3(0.0, 0.0, 0.0 - lunar_environment().gravity_mps2)
}

///|
pub fn integrate_kinematic(
  state : KinematicBodyState,
  step : KinematicStep,
) -> KinematicBodyState {
  let velocity = state.velocity.add(step.acceleration.scale(step.dt_s))
  {
    body_id: state.body_id,
    position: state.position.add(velocity.scale(step.dt_s)),
    velocity,
  }
}
