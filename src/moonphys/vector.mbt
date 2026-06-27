///|
pub(all) struct Vec3 {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn vec3(x : Double, y : Double, z : Double) -> Vec3 {
  { x, y, z }
}
