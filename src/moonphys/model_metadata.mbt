///|
pub(all) struct ModelMetadataInventory {
  model_id : String
  link_count : Int
  collision_shape_link_count : Int
  inertial_link_count : Int
  missing_collision_shape_links : Array[String]
  missing_inertial_links : Array[String]
  blocker_count : Int
  ready : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn missing_metadata_links(
  required_links : Array[String],
  provided_links : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for link in required_links {
    if !provided_links.contains(link) {
      missing.push(link)
    }
  }
  missing
}

///|
pub fn model_metadata_inventory(
  model_id : String,
  link_names : Array[String],
  collision_shape_links : Array[String],
  inertial_links : Array[String],
) -> ModelMetadataInventory {
  let missing_collision_shape_links = missing_metadata_links(
    link_names, collision_shape_links,
  )
  let missing_inertial_links = missing_metadata_links(
    link_names, inertial_links,
  )
  let blocker_count = missing_collision_shape_links.length() +
    missing_inertial_links.length()
  {
    model_id,
    link_count: link_names.length(),
    collision_shape_link_count: collision_shape_links.length(),
    inertial_link_count: inertial_links.length(),
    missing_collision_shape_links,
    missing_inertial_links,
    blocker_count,
    ready: blocker_count == 0,
    status: if blocker_count == 0 {
      "model-metadata-ready"
    } else {
      "model-metadata-blocked"
    },
  }
}
