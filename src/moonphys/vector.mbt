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

///|
pub fn Vec3::add(self : Vec3, other : Vec3) -> Vec3 {
  vec3(self.x + other.x, self.y + other.y, self.z + other.z)
}

///|
pub fn Vec3::sub(self : Vec3, other : Vec3) -> Vec3 {
  vec3(self.x - other.x, self.y - other.y, self.z - other.z)
}

///|
pub fn Vec3::scale(self : Vec3, factor : Double) -> Vec3 {
  vec3(self.x * factor, self.y * factor, self.z * factor)
}

///|
pub fn Vec3::dot(self : Vec3, other : Vec3) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub fn Vec3::length_squared(self : Vec3) -> Double {
  self.dot(self)
}
