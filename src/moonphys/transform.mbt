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
fn normalized_axis(axis : Vec3) -> Vec3 {
  let length = axis.length_squared().sqrt()
  if length > 0.0 {
    axis.scale(1.0 / length)
  } else {
    vec3(0.0, 0.0, 1.0)
  }
}

///|
pub fn axis_angle_basis3(axis : Vec3, angle_rad : Double) -> Basis3 {
  let a = normalized_axis(axis)
  let c = @math.cos(angle_rad)
  let s = @math.sin(angle_rad)
  let t = 1.0 - c
  {
    xx: t * a.x * a.x + c,
    xy: t * a.x * a.y - s * a.z,
    xz: t * a.x * a.z + s * a.y,
    yx: t * a.x * a.y + s * a.z,
    yy: t * a.y * a.y + c,
    yz: t * a.y * a.z - s * a.x,
    zx: t * a.x * a.z - s * a.y,
    zy: t * a.y * a.z + s * a.x,
    zz: t * a.z * a.z + c,
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
pub fn Basis3::mul_basis3(self : Basis3, other : Basis3) -> Basis3 {
  {
    xx: self.xx * other.xx + self.xy * other.yx + self.xz * other.zx,
    xy: self.xx * other.xy + self.xy * other.yy + self.xz * other.zy,
    xz: self.xx * other.xz + self.xy * other.yz + self.xz * other.zz,
    yx: self.yx * other.xx + self.yy * other.yx + self.yz * other.zx,
    yy: self.yx * other.xy + self.yy * other.yy + self.yz * other.zy,
    yz: self.yx * other.xz + self.yy * other.yz + self.yz * other.zz,
    zx: self.zx * other.xx + self.zy * other.yx + self.zz * other.zx,
    zy: self.zx * other.xy + self.zy * other.yy + self.zz * other.zy,
    zz: self.zx * other.xz + self.zy * other.yz + self.zz * other.zz,
  }
}

///|
pub fn transform3(basis : Basis3, translation : Vec3) -> Transform3 {
  { basis, translation }
}

///|
pub fn Transform3::transform_point(self : Transform3, point : Vec3) -> Vec3 {
  self.basis.mul_vec3(point).add(self.translation)
}

///|
pub fn Transform3::compose(self : Transform3, child : Transform3) -> Transform3 {
  transform3(
    self.basis.mul_basis3(child.basis),
    self.transform_point(child.translation),
  )
}
