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
  assert_true(html.contains("Remediation Margin Refresh Task"))
  assert_true(html.contains("Remediation Margin Refresh Follow-Up Task"))
  assert_true(html.contains("Remediation Margin Refresh Follow-Up Receipt"))
  assert_true(html.contains("Remediation Margin Refresh Receipt"))
  assert_true(html.contains("Remediation Margin Receipt"))
  assert_true(html.contains("Remediation Margin Modeling"))
  assert_true(html.contains("Remediation Margin Refresh Modeling"))
  assert_true(html.contains("Remediation Margin Refresh Follow-Up Modeling"))
  assert_true(html.contains("Remediation Margin Refresh Follow-Up Projection"))
  assert_true(html.contains("Remediation Margin Cycle Closeout"))
  assert_true(html.contains("Remediation Margin Closeout Action"))
  assert_true(html.contains("Remediation Margin Reviewed Action Plan"))
  assert_true(html.contains("Closeout Action Review"))
  assert_true(html.contains("Remediation Margin Refresh Projection"))
  assert_true(html.contains("Remediation Margin Projection"))
  assert_true(html.contains("Selected Route Clearance"))
  assert_true(html.contains("selected-route-remediation"))
  assert_true(html.contains("simulation-review-packet"))
  assert_true(html.contains("simulation-review-decision"))
  assert_true(html.contains("simulation-blocker-reduction"))
  assert_true(html.contains("remediation-margin-task"))
  assert_true(html.contains("remediation-margin-refresh-task"))
  assert_true(html.contains("remediation-margin-refresh-followup-task"))
  assert_true(html.contains("remediation-margin-refresh-followup-receipt"))
  assert_true(html.contains("remediation-margin-refresh-receipt"))
  assert_true(html.contains("remediation-margin-receipt"))
  assert_true(html.contains("remediation-margin-modeling"))
  assert_true(html.contains("remediation-margin-refresh-modeling"))
  assert_true(html.contains("remediation-margin-refresh-followup-modeling"))
  assert_true(html.contains("remediation-margin-refresh-followup-projection"))
  assert_true(html.contains("remediation-margin-cycle-closeout"))
  assert_true(html.contains("remediation-margin-closeout-action"))
  assert_true(html.contains("remediation-margin-reviewed-action-plan"))
  assert_true(html.contains("closeout-action-review"))
  assert_true(html.contains("closeout-action-review-export"))
  assert_true(html.contains("remediation-margin-refresh-projection"))
  assert_true(html.contains("remediation-margin-projection"))
  assert_true(html.contains("clearance-review"))
  assert_true(html.contains("transition-export"))
  assert_true(html.contains("first_trusted_square_clearance_transitions.json"))
  assert_true(html.contains("first_trusted_square_closeout_action_review.json"))
  assert_true(html.contains("function buildClearanceTransition(item)"))
  assert_true(html.contains("function buildCloseoutActionReviewTransition()"))
  assert_true(html.contains("function closeoutActionReviewExport()"))
  assert_true(html.contains("function renderCloseoutActionReview()"))
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
  assert_true(html.contains("function renderRemediationMarginRefreshTask()"))
  assert_true(
    html.contains("function renderRemediationMarginRefreshFollowupTask()"),
  )
  assert_true(
    html.contains("function renderRemediationMarginRefreshFollowupReceipt()"),
  )
  assert_true(html.contains("function renderRemediationMarginRefreshReceipt()"))
  assert_true(html.contains("function renderRemediationMarginReceipt()"))
  assert_true(html.contains("function renderRemediationMarginModeling()"))
  assert_true(
    html.contains("function renderRemediationMarginRefreshModeling()"),
  )
  assert_true(
    html.contains("function renderRemediationMarginRefreshFollowupModeling()"),
  )
  assert_true(
    html.contains("function renderRemediationMarginRefreshFollowupProjection()"),
  )
  assert_true(html.contains("function renderRemediationMarginCycleCloseout()"))
  assert_true(html.contains("function renderRemediationMarginCloseoutAction()"))
  assert_true(
    html.contains("function renderRemediationMarginReviewedActionPlan()"),
  )
  assert_true(
    html.contains("function renderRemediationMarginRefreshProjection()"),
  )
  assert_true(html.contains("function renderRemediationMarginProjection()"))
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
  assert_true(
    html.contains(
      "moonclaw/first-trusted-square/remediation-margin-refresh-task",
    ),
  )
  assert_true(
    html.contains(
      "moonclaw/first-trusted-square/remediation-margin-refresh-followup-task",
    ),
  )
  assert_true(
    html.contains(
      "moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt",
    ),
  )
  assert_true(
    html.contains(
      "moonclaw/first-trusted-square/remediation-margin-refresh-receipt",
    ),
  )
  assert_true(
    html.contains("moonclaw/first-trusted-square/remediation-margin-receipt"),
  )
  assert_true(
    html.contains("moonrobo/first-trusted-square/remediation-margin-modeling"),
  )
  assert_true(
    html.contains(
      "moonrobo/first-trusted-square/remediation-margin-refresh-modeling",
    ),
  )
  assert_true(
    html.contains(
      "moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling",
    ),
  )
  assert_true(
    html.contains(
      "moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection",
    ),
  )
  assert_true(
    html.contains(
      "moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy",
    ),
  )
  assert_true(
    html.contains(
      "moonclaw/first-trusted-square/remediation-margin-closeout-action-task",
    ),
  )
  assert_true(
    html.contains(
      "moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan",
    ),
  )
  assert_true(html.contains("operator/rabbita-closeout-action-review"))
  assert_true(html.contains("moonclaw-closeout-action-review"))
  assert_true(html.contains("hardware_authority_change"))
  assert_true(html.contains("Defer"))
  assert_true(html.contains("Deferred"))
  assert_true(
    html.contains(
      "moonrobo/first-trusted-square/remediation-margin-refresh-projection",
    ),
  )
  assert_true(
    html.contains("moonrobo/first-trusted-square/remediation-margin-projection"),
  )
  assert_true(html.contains("RefreshesCarriedForward"))
  assert_true(html.contains("FollowupRefreshesCarriedForward"))
  assert_true(html.contains("3 still-blocking refreshes"))
  assert_true(html.contains("3 still-blocking follow-up refreshes"))
  assert_true(html.contains("0 refreshed"))
  assert_true(html.contains("OpenMarginsCarriedForward"))
  assert_true(html.contains("AllMarginsStillBlocking"))
  assert_true(html.contains("AllRefreshesStillBlocking"))
  assert_true(html.contains("AllFollowupRefreshesStillBlocking"))
  assert_true(html.contains("NoConsumeSimulationBlocked"))
  assert_true(html.contains("NoConsumeRefreshSimulationBlocked"))
  assert_true(html.contains("NoConsumeFollowupRefreshSimulationBlocked"))
  assert_true(html.contains("NoConsumeCycleClosedForPolicy"))
  assert_true(html.contains("3 blocking refreshes"))
  assert_true(html.contains("2 refresh cycles"))
  assert_true(html.contains("refresh-terrain-northeast-stepout"))
  assert_true(html.contains("refresh-illumination-northeast-stepout"))
  assert_true(html.contains("refresh-energy-window"))
  assert_true(html.contains("EscalateToOperatorDecision"))
  assert_true(html.contains("RetryWithNewEvidence"))
  assert_true(html.contains("FreezeUntilNewSourceEvidence"))
  assert_true(html.contains("needs-review"))
  assert_true(html.contains("MoonClaw remediation-margin closeout action task"))
  assert_true(html.contains("accepted reviewed action plan"))
  assert_true(html.contains("automatic refresh loop allowed false"))
  assert_true(html.contains("3 ranked refreshes"))
  assert_true(html.contains("simulation-blocked"))
  assert_true(html.contains("may consume false"))
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
