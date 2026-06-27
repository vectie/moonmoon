///|
pub(all) struct PhysicsEnvironment {
  environment_id : String
  gravity_mps2 : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn lunar_environment() -> PhysicsEnvironment {
  { environment_id: "moon/lunar-surface", gravity_mps2: 1.625 }
}
