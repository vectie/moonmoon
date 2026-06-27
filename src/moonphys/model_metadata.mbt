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
pub(all) struct PhysicalModelReadiness {
  readiness_id : String
  required_item_count : Int
  authoritative_item_count : Int
  assumed_item_count : Int
  missing_item_count : Int
  blocker_count : Int
  ready : Bool
  required_items : Array[String]
  authoritative_items : Array[String]
  assumed_items : Array[String]
  missing_items : Array[String]
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

///|
fn missing_physical_model_items(
  required_items : Array[String],
  authoritative_items : Array[String],
  assumed_items : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for item in required_items {
    if !authoritative_items.contains(item) && !assumed_items.contains(item) {
      missing.push(item)
    }
  }
  missing
}

///|
pub fn physical_model_readiness(
  readiness_id : String,
  required_items : Array[String],
  authoritative_items : Array[String],
  assumed_items : Array[String],
) -> PhysicalModelReadiness {
  let missing_items = missing_physical_model_items(
    required_items, authoritative_items, assumed_items,
  )
  let blocker_count = assumed_items.length() + missing_items.length()
  {
    readiness_id,
    required_item_count: required_items.length(),
    authoritative_item_count: authoritative_items.length(),
    assumed_item_count: assumed_items.length(),
    missing_item_count: missing_items.length(),
    blocker_count,
    ready: blocker_count == 0,
    required_items,
    authoritative_items,
    assumed_items,
    missing_items,
    status: if blocker_count == 0 {
      "physical-model-ready"
    } else {
      "physical-model-assumption-review"
    },
  }
}
