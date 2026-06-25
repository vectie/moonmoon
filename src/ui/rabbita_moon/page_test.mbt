///|
test "Rabbita Moon page renders browser inspection controls" {
  let html = @rabbita_moon.first_trusted_square_html()
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("Rabbita Moon"))
  assert_true(html.contains("moonmoon-view-model"))
  assert_true(html.contains("moonmoon-moonbook"))
  assert_true(html.contains("Layer toggles"))
  assert_true(html.contains("Selectable lunar terrain cells"))
  assert_true(html.contains("Route Overlays"))
  assert_true(html.contains("Source Evidence"))
  assert_true(html.contains("MoonBook Review Status"))
  assert_true(html.contains("Selected Route Remediation Evidence"))
  assert_true(html.contains("Simulation Review Packet"))
  assert_true(html.contains("Simulation Review Decision"))
  assert_true(html.contains("Simulation Blocker Reduction"))
  assert_true(html.contains("Remediation Margin Task"))
  assert_true(html.contains("Selected Route Clearance"))
  assert_true(html.contains("selected-route-remediation"))
  assert_true(html.contains("simulation-review-packet"))
  assert_true(html.contains("simulation-review-decision"))
  assert_true(html.contains("simulation-blocker-reduction"))
  assert_true(html.contains("remediation-margin-task"))
  assert_true(html.contains("clearance-review"))
  assert_true(html.contains("transition-export"))
  assert_true(html.contains("first_trusted_square_clearance_transitions.json"))
  assert_true(html.contains("function buildClearanceTransition(item)"))
  assert_true(html.contains("function initialClearanceDecision(item)"))
  assert_true(html.contains("function clearanceReviewStatus(item)"))
  assert_true(html.contains("function clearanceTransitionExport()"))
  assert_true(html.contains("function renderGrid()"))
  assert_true(html.contains("function renderReview()"))
  assert_true(html.contains("function renderRemediationEvidence()"))
  assert_true(html.contains("function renderMoonBookEntry("))
  assert_true(html.contains("function renderSimulationReviewPacket()"))
  assert_true(html.contains("function renderSimulationReviewDecision()"))
  assert_true(html.contains("function renderSimulationBlockerReduction()"))
  assert_true(html.contains("function renderRemediationMarginTask()"))
  assert_true(html.contains("function renderClearanceReview()"))
  assert_true(
    html.contains("moonrobo/first-trusted-square/simulation-review-packet"),
  )
  assert_true(
    html.contains("moonrobo/first-trusted-square/simulation-review-decision"),
  )
  assert_true(
    html.contains("moonrobo/first-trusted-square/simulation-blocker-reduction"),
  )
  assert_true(
    html.contains("moonclaw/first-trusted-square/remediation-margin-task"),
  )
  assert_true(html.contains("terrain-northeast-stepout"))
  assert_true(html.contains("illumination-northeast-stepout"))
  assert_true(
    html.contains("terrain-remediation/first-trusted-square/northeast-stepout"),
  )
  assert_true(
    html.contains("local-horizon/first-trusted-square/northeast-stepout"),
  )
  assert_true(
    html.contains("energy-remediation/first-trusted-square/northeast-stepout"),
  )
  assert_true(
    html.contains(
      "mission/first-trusted-square/northeast-stepout-terrain-remediation.json",
    ),
  )
  assert_true(
    html.contains("mission/first-trusted-square/northeast-stepout-horizon.json"),
  )
  assert_true(
    html.contains("mission/first-trusted-square/energy-remediation.json"),
  )
  assert_true(html.contains("grade margin"))
  assert_true(html.contains("roughness margin"))
  assert_true(html.contains("terrain-shadow margin"))
  assert_true(html.contains("bounded margin"))
  assert_true(html.contains("margin gap"))
  assert_true(html.contains("hardware-denial"))
  assert_true(html.contains("data-review-decision"))
  assert_true(html.contains("data-review-status"))
  assert_true(html.contains("route-direct-lola-window"))
  assert_true(html.contains("energy-window"))
  assert_true(html.contains("clear-terrain-grade-northeast-stepout"))
  assert_true(html.contains("clear-energy-margin"))
  assert_true(html.contains("operator/rabbita-clearance-review"))
  assert_true(html.contains("RequestEvidence"))
}
