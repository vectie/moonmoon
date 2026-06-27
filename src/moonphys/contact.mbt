///|
pub(all) struct ContactProbe {
  probe_id : String
  position : Vec3
  surface_elevation_m : Double
  clearance_m : Double
  in_contact : Bool
  local_grade : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn heightfield_contact_probe(
  field : Heightfield,
  probe_id : String,
  position : Vec3,
  contact_tolerance_m? : Double = 0.001,
) -> ContactProbe {
  let sample = sample_heightfield(field, position.x, position.y)
  let clearance_m = position.z - sample.elevation_m
  let in_contact = clearance_m <= contact_tolerance_m
  {
    probe_id,
    position,
    surface_elevation_m: sample.elevation_m,
    clearance_m,
    in_contact,
    local_grade: sample.local_grade_x,
    status: if in_contact {
      "contact"
    } else {
      "clear"
    },
  }
}
