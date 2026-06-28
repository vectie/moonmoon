///|
pub(all) struct RigidBodyWorldCenterOfMassTarget {
  center_of_mass : Vec3
  center_of_mass_velocity : Vec3
  total_mass_kg : Double
  nominal_com_height_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn rigid_body_world_center_of_mass_target(
  center_of_mass : Vec3,
  center_of_mass_velocity : Vec3,
  total_mass_kg? : Double = 0.0,
  nominal_com_height_m? : Double = center_of_mass.z,
) -> RigidBodyWorldCenterOfMassTarget {
  {
    center_of_mass,
    center_of_mass_velocity,
    total_mass_kg,
    nominal_com_height_m,
  }
}

///|
fn rigid_body_world_center_of_mass_target_or_world(
  world : RigidBodyHeightfieldWorld,
  target : RigidBodyWorldCenterOfMassTarget?,
) -> RigidBodyWorldCenterOfMassTarget {
  match target {
    Some(target) => target
    None =>
      rigid_body_world_center_of_mass_target(
        rigid_body_world_center_of_mass(world),
        rigid_body_world_center_of_mass_velocity(world),
        total_mass_kg=rigid_body_world_total_mass(world),
      )
  }
}

///|
fn rigid_body_world_center_of_mass_target_frame(
  targets : Array[RigidBodyWorldCenterOfMassTarget],
  index : Int,
) -> RigidBodyWorldCenterOfMassTarget? {
  if index < targets.length() {
    Some(targets[index])
  } else {
    None
  }
}
