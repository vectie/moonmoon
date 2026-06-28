///|
test "model metadata inventory reports missing collision and inertial links" {
  let inventory = model_metadata_inventory(
    "model-source",
    ["base", "foot"],
    ["base"],
    [],
  )
  assert_eq(inventory.link_count, 2)
  assert_eq(inventory.collision_shape_link_count, 1)
  assert_eq(inventory.inertial_link_count, 0)
  assert_eq(inventory.blocker_count, 3)
  assert_eq(inventory.blocker_ids.length(), inventory.blocker_count)
  assert_true(!inventory.ready)
  assert_eq(inventory.status, "model-metadata-blocked")
  assert_true(inventory.missing_collision_shape_links.contains("foot"))
  assert_true(inventory.missing_inertial_links.contains("base"))
  assert_true(inventory.missing_inertial_links.contains("foot"))
  assert_true(inventory.blocker_ids.contains("missing-collision-shape:foot"))
  assert_true(inventory.blocker_ids.contains("missing-inertial:base"))
  assert_true(inventory.blocker_ids.contains("missing-inertial:foot"))
}

///|
test "model metadata inventory is ready when required metadata is present" {
  let inventory = model_metadata_inventory(
    "model-source",
    ["base", "foot"],
    ["base", "foot"],
    ["base", "foot"],
  )
  assert_eq(inventory.blocker_count, 0)
  assert_eq(inventory.blocker_ids.length(), 0)
  assert_true(inventory.ready)
  assert_eq(inventory.status, "model-metadata-ready")
}

///|
test "physical model readiness blocks assumed and missing items" {
  let readiness = physical_model_readiness(
    "physical-model",
    ["mass", "collision-shapes", "joint-damping"],
    ["collision-shapes"],
    ["mass"],
  )
  assert_eq(readiness.required_item_count, 3)
  assert_eq(readiness.authoritative_item_count, 1)
  assert_eq(readiness.assumed_item_count, 1)
  assert_eq(readiness.missing_item_count, 1)
  assert_eq(readiness.blocker_count, 2)
  assert_eq(readiness.blocker_ids.length(), readiness.blocker_count)
  assert_true(!readiness.ready)
  assert_eq(readiness.status, "physical-model-assumption-review")
  assert_true(readiness.assumed_items.contains("mass"))
  assert_true(readiness.missing_items.contains("joint-damping"))
  assert_true(readiness.blocker_ids.contains("assumed:mass"))
  assert_true(readiness.blocker_ids.contains("missing:joint-damping"))
}

///|
test "physical model readiness passes authoritative items" {
  let readiness = physical_model_readiness(
    "physical-model",
    ["mass", "collision-shapes"],
    ["mass", "collision-shapes"],
    [],
  )
  assert_eq(readiness.blocker_count, 0)
  assert_eq(readiness.blocker_ids.length(), 0)
  assert_true(readiness.ready)
  assert_eq(readiness.status, "physical-model-ready")
}
