///|
test "legacy model review records retain canonical type identity" {
  let inventory : @canonical_review.ModelMetadataInventory = @review.model_metadata_inventory(
    "model",
    ["base"],
    ["base"],
    ["base"],
  )
  let legacy : @review.ModelMetadataInventory = inventory
  assert_true(legacy.ready)
  let readiness : @review.PhysicalModelReadiness = @canonical_review.physical_model_readiness(
    "model",
    ["mass"],
    ["mass"],
    [],
  )
  assert_true(readiness.ready)
}
