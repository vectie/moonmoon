///|
test "system kernel keeps MoonMoon standalone boundaries explicit" {
  let kernel = @kernel.system_kernel()
  assert_eq(kernel.product_name, "MoonMoon")
  assert_eq(kernel.layers.length(), 5)
  assert_eq(kernel.evidence_gates.length(), 4)
  assert_eq(kernel.suite_boundaries.length(), 5)
  assert_eq(
    @kernel.top_priority_task(kernel).task_id,
    "rabbita-remediation-margin-closeout-action-surface",
  )
}

///|
test "kernel preserves progress and current hard blockers instead of hiding them" {
  let kernel = @kernel.system_kernel()
  let route_gate = kernel.evidence_gates[0]
  let power_gate = kernel.evidence_gates[1]
  assert_true(route_gate.readiness is @kernel.ReadinessState::Ready)
  assert_true(power_gate.readiness is @kernel.ReadinessState::Ready)
  assert_eq(route_gate.blocker, "none")
  assert_eq(power_gate.blocker, "none")
}

///|
test "kernel markdown names suite roles and next product output" {
  let markdown = @kernel.system_kernel_markdown()
  assert_true(
    markdown.contains("MoonTown schedules work; MoonMoon owns lunar physics"),
  )
  assert_true(markdown.contains("src/ui/rabbita_moon/page.mbt"))
  assert_true(markdown.contains("promote-best-9x9-route-fixture"))
  assert_true(markdown.contains("rabbita-layer-view-model"))
  assert_true(markdown.contains("replace-missing-power-window"))
  assert_true(markdown.contains("moonrobo-simulation-contract-v2"))
  assert_true(markdown.contains("moonbook-review-transition-log"))
  assert_true(markdown.contains("rabbita-browser-inspection-surface"))
  assert_true(markdown.contains("mission-simulation-readiness-gate"))
  assert_true(markdown.contains("selected-route-blocker-clearance"))
  assert_true(markdown.contains("operator-clearance-transition-capture"))
  assert_true(markdown.contains("rabbita-clearance-review-controls"))
  assert_true(markdown.contains("rabbita-transition-import-workflow"))
  assert_true(markdown.contains("rabbita-import-feedback-state"))
  assert_true(
    markdown.contains("moonrobo-imported-clearance-readiness-preview"),
  )
  assert_true(markdown.contains("moonrobo-clearance-gap-report"))
  assert_true(markdown.contains("moonclaw-moonrobo-gap-remediation-task"))
  assert_true(
    markdown.contains("moonbook-imported-moonclaw-gap-task-workspace"),
  )
  assert_true(markdown.contains("moonclaw-gap-remediation-receipt-loop"))
  assert_true(markdown.contains("moonbook-imported-gap-receipt-workspace"))
  assert_true(markdown.contains("rabbita-imported-gap-evidence-surface"))
  assert_true(markdown.contains("moonrobo-gap-remediation-modeling-pass"))
  assert_true(markdown.contains("moonbook-gap-remediation-modeling-workspace"))
  assert_true(
    markdown.contains("moonrobo-illumination-local-horizon-remediation"),
  )
  assert_true(markdown.contains("moonbook-selected-route-horizon-workspace"))
  assert_true(markdown.contains("moonrobo-selected-route-terrain-remediation"))
  assert_true(markdown.contains("moonbook-selected-route-terrain-workspace"))
  assert_true(markdown.contains("moonrobo-energy-margin-remediation"))
  assert_true(markdown.contains("moonbook-energy-remediation-workspace"))
  assert_true(markdown.contains("rabbita-remediation-evidence-surface"))
  assert_true(
    markdown.contains("moonrobo-selected-route-simulation-review-packet"),
  )
  assert_true(markdown.contains("moonbook-simulation-review-packet-workspace"))
  assert_true(markdown.contains("rabbita-simulation-review-packet-surface"))
  assert_true(markdown.contains("moonrobo-simulation-review-closeout-decision"))
  assert_true(
    markdown.contains("moonbook-simulation-review-decision-workspace"),
  )
  assert_true(markdown.contains("rabbita-simulation-review-decision-surface"))
  assert_true(markdown.contains("moonrobo-simulation-blocker-reduction-pass"))
  assert_true(
    markdown.contains("moonbook-simulation-blocker-reduction-workspace"),
  )
  assert_true(markdown.contains("rabbita-simulation-blocker-reduction-surface"))
  assert_true(markdown.contains("moonclaw-remediation-margin-task-packet"))
  assert_true(markdown.contains("moonbook-remediation-margin-task-workspace"))
  assert_true(markdown.contains("rabbita-remediation-margin-task-surface"))
  assert_true(markdown.contains("moonclaw-remediation-margin-receipt-loop"))
  assert_true(markdown.contains("rabbita-remediation-margin-receipt-surface"))
  assert_true(markdown.contains("moonrobo-remediation-margin-modeling-pass"))
  assert_true(markdown.contains("rabbita-remediation-margin-modeling-surface"))
  assert_true(
    markdown.contains("moonrobo-remediation-margin-clearance-projection"),
  )
  assert_true(
    markdown.contains("moonbook-remediation-margin-projection-workspace"),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-projection-surface"),
  )
  assert_true(markdown.contains("moonclaw-remediation-margin-refresh-task"))
  assert_true(
    markdown.contains("moonbook-remediation-margin-refresh-task-workspace"),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-refresh-task-surface"),
  )
  assert_true(
    markdown.contains("moonclaw-remediation-margin-refresh-receipt-loop"),
  )
  assert_true(
    markdown.contains("moonbook-remediation-margin-refresh-receipt-workspace"),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-refresh-receipt-surface"),
  )
  assert_true(
    markdown.contains("moonrobo-remediation-margin-refresh-modeling-pass"),
  )
  assert_true(
    markdown.contains("moonbook-remediation-margin-refresh-modeling-workspace"),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-refresh-modeling-surface"),
  )
  assert_true(
    markdown.contains("moonrobo-remediation-margin-refresh-projection"),
  )
  assert_true(
    markdown.contains(
      "moonbook-remediation-margin-refresh-projection-workspace",
    ),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-refresh-projection-surface"),
  )
  assert_true(
    markdown.contains("moonclaw-remediation-margin-refresh-followup-task"),
  )
  assert_true(
    markdown.contains(
      "rabbita-remediation-margin-refresh-followup-task-surface",
    ),
  )
  assert_true(
    markdown.contains(
      "moonclaw-remediation-margin-refresh-followup-receipt-loop",
    ),
  )
  assert_true(
    markdown.contains(
      "rabbita-remediation-margin-refresh-followup-receipt-surface",
    ),
  )
  assert_true(
    markdown.contains(
      "moonrobo-remediation-margin-refresh-followup-modeling-pass",
    ),
  )
  assert_true(
    markdown.contains(
      "moonbook-remediation-margin-refresh-followup-modeling-workspace",
    ),
  )
  assert_true(
    markdown.contains(
      "rabbita-remediation-margin-refresh-followup-modeling-surface",
    ),
  )
  assert_true(
    markdown.contains("moonrobo-remediation-margin-refresh-followup-projection"),
  )
  assert_true(
    markdown.contains(
      "moonbook-remediation-margin-refresh-followup-projection-workspace",
    ),
  )
  assert_true(
    markdown.contains(
      "rabbita-remediation-margin-refresh-followup-projection-surface",
    ),
  )
  assert_true(
    markdown.contains("moonrobo-remediation-margin-cycle-closeout-policy"),
  )
  assert_true(
    markdown.contains("moonbook-remediation-margin-cycle-closeout-workspace"),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-cycle-closeout-surface"),
  )
  assert_true(
    markdown.contains("moonclaw-remediation-margin-closeout-action-task"),
  )
  assert_true(
    markdown.contains("moonbook-remediation-margin-closeout-action-workspace"),
  )
  assert_true(
    markdown.contains("rabbita-remediation-margin-closeout-action-surface"),
  )
  assert_true(markdown.contains("NoConsumeCycleClosedForPolicy"))
  assert_true(markdown.contains("retry/escalate/freeze dispositions"))
  assert_true(markdown.contains("terrain escalate"))
  assert_true(markdown.contains("NeedsReview state"))
  assert_true(markdown.contains("NoConsumeFollowupRefreshSimulationBlocked"))
  assert_true(markdown.contains("FollowupRefreshesCarriedForward state"))
  assert_true(markdown.contains("AllFollowupRefreshesStillBlocking state"))
  assert_true(markdown.contains("AllRefreshesStillBlocking state"))
  assert_true(markdown.contains("no-consume simulation status"))
  assert_true(markdown.contains("hardware-denial invariants"))
}
