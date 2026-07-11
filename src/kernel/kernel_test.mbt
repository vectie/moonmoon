///|
test "system kernel keeps MoonMoon standalone boundaries explicit" {
  let kernel = @kernel.system_kernel()
  assert_eq(kernel.product_name, "MoonMoon")
  assert_eq(kernel.current_site_id, "first-trusted-square")
  assert_eq(kernel.layers.length(), 5)
  assert_eq(kernel.evidence_gates.length(), 4)
  assert_eq(
    @kernel.top_priority_task(kernel).task_id,
    "clear-selected-route-blockers",
  )
}

///|
test "kernel does not depend on generated suite output" {
  let markdown = @kernel.system_kernel_markdown()
  assert_true(markdown.contains("MoonBit-native lunar terrain"))
  assert_true(markdown.contains("src/ui/page.mbt"))
  assert_true(markdown.contains("clear-selected-route-blockers"))
  assert_true(markdown.contains("catalog-backed-product-evidence"))
  assert_true(markdown.contains("src/site/catalog_evidence.mbt"))
  assert_true(markdown.contains("moonmoon-ui-package"))
  assert_true(!markdown.contains("output/moonbook"))
  assert_true(!markdown.contains("output/moonclaw"))
  assert_true(!markdown.contains("output/moonrobo"))
  assert_true(!markdown.contains("scripts/"))
}

///|
test "kernel json exposes compact build queue" {
  let json = @kernel.system_kernel_json().stringify(indent=2)
  assert_true(json.contains("\"kernel_id\": \"moonmoon/kernel/standalone-v1\""))
  assert_true(json.contains("\"build_queue\""))
  assert_true(json.contains("\"catalog-backed-source-evidence\""))
  assert_true(json.contains("\"dataset/lro-lola-first-trusted-square-dem-v1\""))
}
