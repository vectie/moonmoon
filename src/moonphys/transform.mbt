///|
pub(all) struct Basis3 {
  xx : Double
  xy : Double
  xz : Double
  yx : Double
  yy : Double
  yz : Double
  zx : Double
  zy : Double
  zz : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Transform3 {
  basis : Basis3
  translation : Vec3
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn identity_basis3() -> Basis3 {
  {
    xx: 1.0,
    xy: 0.0,
    xz: 0.0,
    yx: 0.0,
    yy: 1.0,
    yz: 0.0,
    zx: 0.0,
    zy: 0.0,
    zz: 1.0,
  }
}

///|
pub fn yaw_basis3(yaw_rad : Double) -> Basis3 {
  let c = @math.cos(yaw_rad)
  let s = @math.sin(yaw_rad)
  {
    xx: c,
    xy: 0.0 - s,
    xz: 0.0,
    yx: s,
    yy: c,
    yz: 0.0,
    zx: 0.0,
    zy: 0.0,
    zz: 1.0,
  }
}

///|
pub fn Basis3::mul_vec3(self : Basis3, value : Vec3) -> Vec3 {
  vec3(
    self.xx * value.x + self.xy * value.y + self.xz * value.z,
    self.yx * value.x + self.yy * value.y + self.yz * value.z,
    self.zx * value.x + self.zy * value.y + self.zz * value.z,
  )
}

///|
pub fn transform3(basis : Basis3, translation : Vec3) -> Transform3 {
  { basis, translation }
}

///|
pub fn Transform3::transform_point(self : Transform3, point : Vec3) -> Vec3 {
  self.basis.mul_vec3(point).add(self.translation)
}
