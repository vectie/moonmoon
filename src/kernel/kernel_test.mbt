///|
test "system kernel keeps MoonMoon standalone boundaries explicit" {
  let kernel = @kernel.system_kernel()
  assert_eq(kernel.product_name, "MoonMoon")
  assert_eq(kernel.layers.length(), 5)
  assert_eq(kernel.evidence_gates.length(), 4)
  assert_eq(kernel.suite_boundaries.length(), 5)
  assert_eq(
    @kernel.top_priority_task(kernel).task_id,
    "replace-missing-power-window",
  )
}

///|
test "kernel preserves progress and current hard blockers instead of hiding them" {
  let kernel = @kernel.system_kernel()
  let route_gate = kernel.evidence_gates[0]
  let power_gate = kernel.evidence_gates[1]
  assert_true(route_gate.readiness is @kernel.ReadinessState::Ready)
  assert_true(power_gate.readiness is @kernel.ReadinessState::Blocked)
  assert_eq(route_gate.blocker, "none")
  assert_true(
    power_gate.blocker.contains("verified available energy remains zero"),
  )
}

///|
test "kernel markdown names suite roles and next product output" {
  let markdown = @kernel.system_kernel_markdown()
  assert_true(
    markdown.contains("MoonTown schedules work; MoonMoon owns lunar physics"),
  )
  assert_true(markdown.contains("first terrain layer view model"))
  assert_true(markdown.contains("promote-best-9x9-route-fixture"))
  assert_true(markdown.contains("replace-missing-power-window"))
}
