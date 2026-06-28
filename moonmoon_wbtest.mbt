///|
test "facade markdown stays product-facing" {
  let text = product_kernel_markdown()
  assert_true(text.contains("# MoonMoon Kernel"))
  assert_true(text.contains("time-windowed-energy"))
}
