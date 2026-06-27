///|
test "first trusted square exports a MoonBook evidence dossier" {
  let dossier = @moonbook.first_trusted_square_book_dossier()
  assert_eq(dossier.site_id, "first-trusted-square")
  assert_eq(dossier.entries.length(), 82)
  assert_eq(dossier.review_queue.length(), 29)
  assert_eq(dossier.review_transitions.length(), dossier.review_queue.length())
  assert_eq(
    dossier.entries[0].entry_id,
    "dataset/lro-lola-first-trusted-square-dem-v1",
  )
  assert_eq(
    dossier.entries[1].entry_id,
    "dataset/lro-lola-first-trusted-square-west-contour-dem-v1",
  )
  assert_eq(
    dossier.entries[2].entry_id,
    "dataset/lro-lola-first-trusted-square-north-rim-dem-v1",
  )
  assert_eq(
    dossier.entries[3].entry_id,
    "dataset/lro-lola-first-trusted-square-southwest-bypass-dem-v1",
  )
  assert_eq(
    dossier.entries[4].entry_id,
    "dataset/lro-lola-first-trusted-square-south-stepout-dem-v1",
  )
  assert_eq(
    dossier.entries[5].entry_id,
    "dataset/lro-lola-first-trusted-square-northeast-stepout-dem-v1",
  )
  assert_true(
    dossier.entries[6].kind == @moonbook.BookEntryKind::SourceUpgradeCandidate,
  )
  assert_true(
    dossier.entries[7].kind == @moonbook.BookEntryKind::SourceUpgradeCandidate,
  )
  assert_true(dossier.entries[7].summary.contains("energy gate"))
  assert_true(
    dossier.entries[8].kind == @moonbook.BookEntryKind::SourceAcquisitionPlan,
  )
  assert_true(
    dossier.entries[9].kind == @moonbook.BookEntryKind::SourceAcquisitionPlan,
  )
  assert_true(
    dossier.entries[9].summary.contains(
      "local horizon and rover power assumptions",
    ),
  )
  assert_true(
    dossier.entries[10].kind == @moonbook.BookEntryKind::SourceProductSelection,
  )
  assert_true(
    dossier.entries[11].kind ==
    @moonbook.BookEntryKind::SourceExtractionCandidate,
  )
  assert_true(
    dossier.entries[17].kind == @moonbook.BookEntryKind::SourceValidation,
  )
  assert_true(
    dossier.entries[23].kind == @moonbook.BookEntryKind::DerivedTerrain,
  )
  assert_true(
    dossier.entries[24].kind == @moonbook.BookEntryKind::MissionDecision,
  )
  assert_true(dossier.entries[25].kind == @moonbook.BookEntryKind::CorridorScan)
  assert_true(
    dossier.entries[26].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[29].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[31].kind == @moonbook.BookEntryKind::RouteAlternative,
  )
  assert_true(
    dossier.entries[32].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[36].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[37].kind == @moonbook.BookEntryKind::IlluminationAssessment,
  )
  assert_true(
    dossier.entries[38].kind == @moonbook.BookEntryKind::LocalHorizonEvidence,
  )
  assert_true(
    dossier.entries[39].kind ==
    @moonbook.BookEntryKind::TerrainRemediationEvidence,
  )
  assert_true(
    dossier.entries[40].kind == @moonbook.BookEntryKind::PowerWindowEvidence,
  )
  assert_true(dossier.entries[41].kind == @moonbook.BookEntryKind::EnergyWindow)
  assert_true(
    dossier.entries[42].kind ==
    @moonbook.BookEntryKind::EnergyRemediationEvidence,
  )
  assert_true(
    dossier.entries[43].kind == @moonbook.BookEntryKind::SelectedRouteClearance,
  )
  assert_true(
    dossier.entries[44].kind == @moonbook.BookEntryKind::MoonroboHandoff,
  )
  assert_true(
    dossier.entries[45].kind == @moonbook.BookEntryKind::MoonClawProposal,
  )
  assert_true(dossier.entries[46].kind == @moonbook.BookEntryKind::MoonClawTask)
  assert_true(dossier.entries[47].kind == @moonbook.BookEntryKind::MoonClawTask)
  assert_true(dossier.entries[48].kind == @moonbook.BookEntryKind::MoonClawTask)
  assert_true(
    dossier.entries[49].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginRefreshTask,
  )
  assert_true(
    dossier.entries[50].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginRefreshReceipt,
  )
  assert_true(
    dossier.entries[51].kind == @moonbook.BookEntryKind::MoonClawReceipt,
  )
  assert_true(
    dossier.entries[52].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginReceipt,
  )
  assert_true(
    dossier.entries[53].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginModeling,
  )
  assert_true(
    dossier.entries[54].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginProjection,
  )
  assert_true(
    dossier.entries[55].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginRefreshModeling,
  )
  assert_true(
    dossier.entries[56].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginRefreshProjection,
  )
  assert_true(
    dossier.entries[57].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginRefreshFollowupTask,
  )
  assert_true(
    dossier.entries[58].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginRefreshFollowupReceipt,
  )
  assert_true(
    dossier.entries[59].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginRefreshFollowupModeling,
  )
  assert_true(
    dossier.entries[60].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginRefreshFollowupProjection,
  )
  assert_true(
    dossier.entries[61].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginCycleCloseoutPolicy,
  )
  assert_true(
    dossier.entries[62].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginCloseoutActionTask,
  )
  assert_true(
    dossier.entries[63].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginReviewedActionPlan,
  )
  assert_true(
    dossier.entries[64].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginReviewedWorkItems,
  )
  assert_true(
    dossier.entries[65].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginReviewedWorkItemReceipts,
  )
  assert_true(
    dossier.entries[66].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginReviewedFreshEvidenceTask,
  )
  assert_true(
    dossier.entries[67].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginFreshEvidenceActionReceipts,
  )
  assert_true(
    dossier.entries[68].kind ==
    @moonbook.BookEntryKind::MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipts,
  )
  assert_true(
    dossier.entries[69].kind ==
    @moonbook.BookEntryKind::MoonroboRemediationMarginRegeneratedReceiptReadiness,
  )
  assert_true(
    dossier.entries[70].kind ==
    @moonbook.BookEntryKind::MoonClawRegeneratedReceiptReadinessFreshEvidenceTask,
  )
  assert_true(
    dossier.entries[71].kind ==
    @moonbook.BookEntryKind::MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipts,
  )
  assert_true(
    dossier.entries[72].kind ==
    @moonbook.BookEntryKind::MoonroboRegeneratedReceiptReadinessActionReceiptCloseout,
  )
  assert_true(
    dossier.entries[73].kind ==
    @moonbook.BookEntryKind::MoonClawEphemerisReceipt,
  )
  assert_true(
    dossier.entries[74].kind == @moonbook.BookEntryKind::MoonClawCorridorReceipt,
  )
  assert_true(
    dossier.entries[75].kind == @moonbook.BookEntryKind::MoonroboNoetixWalk,
  )
  assert_true(
    dossier.entries[76].kind == @moonbook.BookEntryKind::MoonroboNoetixPhysics,
  )
  assert_true(
    dossier.entries[77].kind == @moonbook.BookEntryKind::MoonroboNoetixDynamics,
  )
  assert_true(
    dossier.entries[78].kind ==
    @moonbook.BookEntryKind::MoonroboNoetixJointControl,
  )
  assert_true(
    dossier.entries[79].kind ==
    @moonbook.BookEntryKind::MoonroboNoetixInertialCollision,
  )
  assert_true(
    dossier.entries[80].kind == @moonbook.BookEntryKind::MoonroboNoetixLinkPoses,
  )
  assert_true(
    dossier.entries[81].kind ==
    @moonbook.BookEntryKind::MoonClawNoetixReviewTask,
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[24].kind),
    "mission-decision",
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[25].kind),
    "corridor-scan",
  )
  assert_true(dossier.entries[25].summary.contains("r-12-c+16"))
  assert_true(dossier.entries[25].summary.contains("northeast-stepout"))
  assert_true(dossier.entries[27].summary.contains("west-contour"))
  assert_true(dossier.entries[29].summary.contains("southwest"))
  assert_true(dossier.entries[37].summary.contains("relief-shadow risk"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[38].kind),
    "local-horizon-evidence",
  )
  assert_true(dossier.entries[38].summary.contains("terrain-shadow margin"))
  assert_true(dossier.entries[38].path.contains("northeast-stepout-horizon"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[39].kind),
    "terrain-remediation-evidence",
  )
  assert_true(dossier.entries[39].summary.contains("grade margin"))
  assert_true(dossier.entries[39].summary.contains("roughness margin"))
  assert_true(
    dossier.entries[39].path.contains("northeast-stepout-terrain-remediation"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[40].kind),
    "power-window-evidence",
  )
  assert_true(dossier.entries[40].summary.contains("ready"))
  assert_true(dossier.entries[40].summary.contains("234.938073 Wh verified"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[41].kind),
    "energy-window",
  )
  assert_true(
    dossier.entries[41].summary.contains("234.938073 Wh verified available"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[42].kind),
    "energy-remediation-evidence",
  )
  assert_true(dossier.entries[42].summary.contains("bounded margin"))
  assert_true(dossier.entries[42].summary.contains("margin gap"))
  assert_true(dossier.entries[42].path.contains("energy-remediation"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[43].kind),
    "selected-route-clearance",
  )
  assert_true(dossier.entries[43].summary.contains("northeast-stepout"))
  assert_true(dossier.entries[43].summary.contains("4 clearance items"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[44].kind),
    "moonrobo-handoff",
  )
  assert_true(dossier.entries[44].summary.contains("northeast-stepout"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[45].kind),
    "moonclaw-proposal",
  )
  assert_true(dossier.entries[45].summary.contains("ephemeris"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[46].kind),
    "moonclaw-task",
  )
  assert_true(
    dossier.entries[46].summary.contains("5 artifacts with 0 blockers"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[47].kind),
    "moonclaw-task",
  )
  assert_true(
    dossier.entries[47].summary.contains("81 windows with 0 blockers"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[48].kind),
    "moonclaw-task",
  )
  assert_true(
    dossier.entries[48].summary.contains("3 active remediation margins"),
  )
  assert_true(dossier.entries[48].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[48].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[48].summary.contains("energy-window"))
  assert_true(dossier.entries[48].summary.contains("3 blockers"))
  assert_true(dossier.entries[48].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[48].path.contains("remediation-margin-task"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[49].kind),
    "moonclaw-remediation-margin-refresh-task",
  )
  assert_true(
    dossier.entries[49].summary.contains("NoConsumeSimulationBlocked"),
  )
  assert_true(dossier.entries[49].summary.contains("3 ranked refreshes"))
  assert_true(dossier.entries[49].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[49].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[49].summary.contains("energy-window"))
  assert_true(dossier.entries[49].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[49].summary.contains("may consume false"))
  assert_true(dossier.entries[49].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[49].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[49].path.contains("remediation-margin-refresh-task"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[50].kind),
    "moonclaw-remediation-margin-refresh-receipt",
  )
  assert_true(dossier.entries[50].summary.contains("RefreshesCarriedForward"))
  assert_true(
    dossier.entries[50].summary.contains("3 still-blocking refreshes"),
  )
  assert_true(dossier.entries[50].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[50].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[50].summary.contains("energy-window"))
  assert_true(dossier.entries[50].summary.contains("0 refreshed"))
  assert_true(
    dossier.entries[50].summary.contains(
      "moonrobo/first-trusted-square/remediation-margin-v1/projection",
    ),
  )
  assert_true(dossier.entries[50].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[50].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[50].path.contains("remediation-margin-refresh-receipt"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[51].kind),
    "moonclaw-receipt",
  )
  assert_true(dossier.entries[51].summary.contains("accepted"))
  assert_true(dossier.entries[51].summary.contains("Moonrobo handoff block"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[52].kind),
    "moonclaw-remediation-margin-receipt",
  )
  assert_true(dossier.entries[52].summary.contains("OpenMarginsCarriedForward"))
  assert_true(dossier.entries[52].summary.contains("3 remediation margins"))
  assert_true(dossier.entries[52].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[52].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[52].summary.contains("energy-window"))
  assert_true(dossier.entries[52].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[52].summary.contains("hardware-denied"))
  assert_true(dossier.entries[52].path.contains("remediation-margin-receipt"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[53].kind),
    "moonrobo-remediation-margin-modeling",
  )
  assert_true(dossier.entries[53].summary.contains("AllMarginsStillBlocking"))
  assert_true(dossier.entries[53].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[53].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[53].summary.contains("energy-window"))
  assert_true(dossier.entries[53].summary.contains("hardware-denied"))
  assert_true(dossier.entries[53].path.contains("remediation-margin-modeling"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[54].kind),
    "moonrobo-remediation-margin-projection",
  )
  assert_true(
    dossier.entries[54].summary.contains("NoConsumeSimulationBlocked"),
  )
  assert_true(dossier.entries[54].summary.contains("AllMarginsStillBlocking"))
  assert_true(dossier.entries[54].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[54].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[54].summary.contains("energy-window"))
  assert_true(dossier.entries[54].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[54].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[54].path.contains("remediation-margin-projection"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[55].kind),
    "moonrobo-remediation-margin-refresh-modeling",
  )
  assert_true(dossier.entries[55].summary.contains("AllRefreshesStillBlocking"))
  assert_true(
    dossier.entries[55].summary.contains("3 still-blocking refreshes"),
  )
  assert_true(dossier.entries[55].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[55].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[55].summary.contains("energy-window"))
  assert_true(dossier.entries[55].summary.contains("0 refreshed"))
  assert_true(
    dossier.entries[55].summary.contains(
      "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt",
    ),
  )
  assert_true(dossier.entries[55].summary.contains("no-consume simulation"))
  assert_true(dossier.entries[55].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[55].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[55].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[55].path.contains("remediation-margin-refresh-modeling"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[56].kind),
    "moonrobo-remediation-margin-refresh-projection",
  )
  assert_true(
    dossier.entries[56].summary.contains("NoConsumeRefreshSimulationBlocked"),
  )
  assert_true(dossier.entries[56].summary.contains("AllRefreshesStillBlocking"))
  assert_true(
    dossier.entries[56].summary.contains("3 still-blocking refreshes"),
  )
  assert_true(
    dossier.entries[56].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[56].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[56].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[56].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[56].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[56].summary.contains("energy-window"))
  assert_true(dossier.entries[56].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[56].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[56].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[56].path.contains("remediation-margin-refresh-projection"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[57].kind),
    "moonclaw-remediation-margin-refresh-followup-task",
  )
  assert_true(
    dossier.entries[57].summary.contains("NoConsumeRefreshSimulationBlocked"),
  )
  assert_true(dossier.entries[57].summary.contains("AllRefreshesStillBlocking"))
  assert_true(dossier.entries[57].summary.contains("3 blocking refreshes"))
  assert_true(
    dossier.entries[57].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[57].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[57].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[57].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[57].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[57].summary.contains("energy-window"))
  assert_true(dossier.entries[57].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[57].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[57].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[57].path.contains(
      "remediation-margin-refresh-followup-task",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[58].kind),
    "moonclaw-remediation-margin-refresh-followup-receipt",
  )
  assert_true(
    dossier.entries[58].summary.contains("FollowupRefreshesCarriedForward"),
  )
  assert_true(
    dossier.entries[58].summary.contains("3 still-blocking follow-up refreshes"),
  )
  assert_true(
    dossier.entries[58].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[58].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[58].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[58].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[58].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[58].summary.contains("energy-window"))
  assert_true(dossier.entries[58].summary.contains("0 refreshed"))
  assert_true(
    dossier.entries[58].summary.contains(
      "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task",
    ),
  )
  assert_true(
    dossier.entries[58].summary.contains(
      "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
    ),
  )
  assert_true(dossier.entries[58].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[58].summary.contains("may consume false"))
  assert_true(dossier.entries[58].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[58].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[58].path.contains(
      "remediation-margin-refresh-followup-receipt",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[59].kind),
    "moonrobo-remediation-margin-refresh-followup-modeling",
  )
  assert_true(
    dossier.entries[59].summary.contains("AllFollowupRefreshesStillBlocking"),
  )
  assert_true(
    dossier.entries[59].summary.contains("3 still-blocking follow-up refreshes"),
  )
  assert_true(
    dossier.entries[59].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[59].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[59].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[59].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[59].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[59].summary.contains("energy-window"))
  assert_true(dossier.entries[59].summary.contains("0 refreshed"))
  assert_true(
    dossier.entries[59].summary.contains(
      "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt",
    ),
  )
  assert_true(
    dossier.entries[59].summary.contains(
      "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection",
    ),
  )
  assert_true(dossier.entries[59].summary.contains("no-consume simulation"))
  assert_true(dossier.entries[59].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[59].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[59].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[59].path.contains(
      "remediation-margin-refresh-followup-modeling",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[60].kind),
    "moonrobo-remediation-margin-refresh-followup-projection",
  )
  assert_true(
    dossier.entries[60].summary.contains(
      "NoConsumeFollowupRefreshSimulationBlocked",
    ),
  )
  assert_true(
    dossier.entries[60].summary.contains("AllFollowupRefreshesStillBlocking"),
  )
  assert_true(
    dossier.entries[60].summary.contains("3 still-blocking follow-up refreshes"),
  )
  assert_true(
    dossier.entries[60].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[60].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[60].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[60].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[60].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[60].summary.contains("energy-window"))
  assert_true(dossier.entries[60].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[60].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[60].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[60].path.contains(
      "remediation-margin-refresh-followup-projection",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[61].kind),
    "moonrobo-remediation-margin-cycle-closeout-policy",
  )
  assert_true(
    dossier.entries[61].summary.contains("NoConsumeCycleClosedForPolicy"),
  )
  assert_true(dossier.entries[61].summary.contains("2 refresh cycles"))
  assert_true(
    dossier.entries[61].summary.contains("3 terrain/horizon/energy blockers"),
  )
  assert_true(
    dossier.entries[61].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[61].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[61].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[61].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[61].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[61].summary.contains("energy-window"))
  assert_true(
    dossier.entries[61].summary.contains("terrain=EscalateToOperatorDecision"),
  )
  assert_true(
    dossier.entries[61].summary.contains("local-horizon=RetryWithNewEvidence"),
  )
  assert_true(
    dossier.entries[61].summary.contains("energy=FreezeUntilNewSourceEvidence"),
  )
  assert_true(dossier.entries[61].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[61].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[61].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[61].path.contains(
      "remediation-margin-cycle-closeout-policy",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[62].kind),
    "moonclaw-remediation-margin-closeout-action-task",
  )
  assert_true(dossier.entries[62].summary.contains("needs-review"))
  assert_true(
    dossier.entries[62].summary.contains("NoConsumeCycleClosedForPolicy"),
  )
  assert_true(dossier.entries[62].summary.contains("2 refresh cycles"))
  assert_true(
    dossier.entries[62].summary.contains("3 terrain/horizon/energy blockers"),
  )
  assert_true(
    dossier.entries[62].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[62].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[62].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[62].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[62].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[62].summary.contains("energy-window"))
  assert_true(
    dossier.entries[62].summary.contains("terrain=EscalateToOperatorDecision"),
  )
  assert_true(
    dossier.entries[62].summary.contains("local-horizon=RetryWithNewEvidence"),
  )
  assert_true(
    dossier.entries[62].summary.contains("energy=FreezeUntilNewSourceEvidence"),
  )
  assert_true(dossier.entries[62].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[62].summary.contains("may consume false"))
  assert_true(dossier.entries[62].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[62].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[62].path.contains("remediation-margin-closeout-action-task"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[63].kind),
    "moonclaw-remediation-margin-reviewed-action-plan",
  )
  assert_true(dossier.entries[63].summary.contains("accepted"))
  assert_true(dossier.entries[63].summary.contains("Accept closeout review"))
  assert_true(
    dossier.entries[63].summary.contains(
      "rabbita-moonclaw-remediation-margin-closeout-action-review-accept",
    ),
  )
  assert_true(
    dossier.entries[63].summary.contains("3 terrain/horizon/energy blockers"),
  )
  assert_true(
    dossier.entries[63].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[63].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[63].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[63].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[63].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[63].summary.contains("energy-window"))
  assert_true(
    dossier.entries[63].summary.contains("terrain=EscalateToOperatorDecision"),
  )
  assert_true(
    dossier.entries[63].summary.contains("local-horizon=RetryWithNewEvidence"),
  )
  assert_true(
    dossier.entries[63].summary.contains("energy=FreezeUntilNewSourceEvidence"),
  )
  assert_true(
    dossier.entries[63].summary.contains("automatic refresh loop allowed false"),
  )
  assert_true(dossier.entries[63].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[63].summary.contains("may consume false"))
  assert_true(dossier.entries[63].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[63].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[63].path.contains("remediation-margin-reviewed-action-plan"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[64].kind),
    "moonclaw-remediation-margin-reviewed-work-items",
  )
  assert_true(
    dossier.entries[64].summary.contains("3 accepted reviewed work items"),
  )
  assert_true(dossier.entries[64].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[64].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[64].summary.contains("energy-window"))
  assert_true(
    dossier.entries[64].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[64].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[64].summary.contains("refresh-energy-window"))
  assert_true(
    dossier.entries[64].summary.contains("terrain=EscalateToOperatorDecision"),
  )
  assert_true(
    dossier.entries[64].summary.contains("local-horizon=RetryWithNewEvidence"),
  )
  assert_true(
    dossier.entries[64].summary.contains("energy=FreezeUntilNewSourceEvidence"),
  )
  assert_true(
    dossier.entries[64].summary.contains("automatic refresh loop allowed false"),
  )
  assert_true(dossier.entries[64].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[64].summary.contains("may consume false"))
  assert_true(dossier.entries[64].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[64].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[64].path.contains("remediation-margin-reviewed-work-items"),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[65].kind),
    "moonclaw-remediation-margin-reviewed-work-item-receipts",
  )
  assert_true(
    dossier.entries[65].summary.contains(
      "3 accepted reviewed work item receipts",
    ),
  )
  assert_true(dossier.entries[65].summary.contains("pending fresh evidence"))
  assert_true(
    dossier.entries[65].summary.contains(
      "terrain=ReviewedWorkItemPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[65].summary.contains(
      "local-horizon=ReviewedWorkItemPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[65].summary.contains(
      "energy=ReviewedWorkItemPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[65].summary.contains("accepted review provenance"),
  )
  assert_true(
    dossier.entries[65].summary.contains("automatic refresh loop allowed false"),
  )
  assert_true(dossier.entries[65].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[65].summary.contains("may consume false"))
  assert_true(dossier.entries[65].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[65].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[65].path.contains(
      "remediation-margin-reviewed-work-item-receipts",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[66].kind),
    "moonclaw-remediation-margin-reviewed-fresh-evidence-task",
  )
  assert_true(
    dossier.entries[66].summary.contains(
      "3 pending reviewed work item receipts",
    ),
  )
  assert_true(dossier.entries[66].summary.contains("fresh-evidence actions"))
  assert_true(dossier.entries[66].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[66].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[66].summary.contains("energy-window"))
  assert_true(
    dossier.entries[66].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[66].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[66].summary.contains("refresh-energy-window"))
  assert_true(
    dossier.entries[66].summary.contains("terrain=operator-escalation"),
  )
  assert_true(
    dossier.entries[66].summary.contains("local-horizon=bounded-regeneration"),
  )
  assert_true(
    dossier.entries[66].summary.contains("energy=manual-freeze-verification"),
  )
  assert_true(dossier.entries[66].summary.contains("source receipt provenance"))
  assert_true(
    dossier.entries[66].summary.contains("accepted review provenance"),
  )
  assert_true(
    dossier.entries[66].summary.contains("automatic refresh loop allowed false"),
  )
  assert_true(dossier.entries[66].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[66].summary.contains("may consume false"))
  assert_true(dossier.entries[66].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[66].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[66].path.contains(
      "remediation-margin-reviewed-fresh-evidence-task",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[67].kind),
    "moonclaw-remediation-margin-fresh-evidence-action-receipts",
  )
  assert_true(
    dossier.entries[67].summary.contains(
      "3 accepted fresh-evidence action receipts",
    ),
  )
  assert_true(dossier.entries[67].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[67].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[67].summary.contains("energy-window"))
  assert_true(
    dossier.entries[67].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[67].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[67].summary.contains("refresh-energy-window"))
  assert_true(
    dossier.entries[67].summary.contains("terrain=operator-escalation"),
  )
  assert_true(
    dossier.entries[67].summary.contains("local-horizon=bounded-regeneration"),
  )
  assert_true(
    dossier.entries[67].summary.contains("energy=manual-freeze-verification"),
  )
  assert_true(dossier.entries[67].summary.contains("source receipt provenance"))
  assert_true(dossier.entries[67].summary.contains("pending fresh evidence"))
  assert_true(
    dossier.entries[67].summary.contains("automatic refresh loop allowed false"),
  )
  assert_true(dossier.entries[67].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[67].summary.contains("may consume false"))
  assert_true(dossier.entries[67].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[67].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[67].path.contains(
      "remediation-margin-fresh-evidence-action-receipts",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[68].kind),
    "moonclaw-remediation-margin-regenerated-reviewed-work-item-receipts",
  )
  assert_true(
    dossier.entries[68].summary.contains(
      "3 regenerated reviewed work item receipts",
    ),
  )
  assert_true(dossier.entries[68].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[68].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[68].summary.contains("energy-window"))
  assert_true(
    dossier.entries[68].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[68].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[68].summary.contains("refresh-energy-window"))
  assert_true(
    dossier.entries[68].summary.contains(
      "terrain=ReviewedWorkItemPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[68].summary.contains(
      "local-horizon=ReviewedWorkItemPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[68].summary.contains(
      "energy=ReviewedWorkItemPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[68].summary.contains("terrain=operator-escalation"),
  )
  assert_true(
    dossier.entries[68].summary.contains("local-horizon=bounded-regeneration"),
  )
  assert_true(
    dossier.entries[68].summary.contains("energy=manual-freeze-verification"),
  )
  assert_true(
    dossier.entries[68].summary.contains("source action receipt provenance"),
  )
  assert_true(dossier.entries[68].summary.contains("source receipt provenance"))
  assert_true(
    dossier.entries[68].summary.contains("accepted review provenance"),
  )
  assert_true(
    dossier.entries[68].summary.contains("automatic refresh loop allowed false"),
  )
  assert_true(dossier.entries[68].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[68].summary.contains("may consume false"))
  assert_true(dossier.entries[68].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[68].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[68].path.contains(
      "remediation-margin-regenerated-reviewed-work-item-receipts",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[69].kind),
    "moonrobo-remediation-margin-regenerated-receipt-readiness",
  )
  assert_true(
    dossier.entries[69].summary.contains(
      "RegeneratedReceiptsPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[69].summary.contains("3 pending regenerated receipts"),
  )
  assert_true(dossier.entries[69].summary.contains("0 ready receipts"))
  assert_true(dossier.entries[69].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[69].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[69].summary.contains("energy-window"))
  assert_true(
    dossier.entries[69].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[69].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[69].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[69].summary.contains("operator-escalation"))
  assert_true(dossier.entries[69].summary.contains("bounded-regeneration"))
  assert_true(
    dossier.entries[69].summary.contains("manual-freeze-verification"),
  )
  assert_true(
    dossier.entries[69].summary.contains("source action receipt provenance"),
  )
  assert_true(dossier.entries[69].summary.contains("no automatic refresh loop"))
  assert_true(dossier.entries[69].summary.contains("no simulation consumption"))
  assert_true(dossier.entries[69].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[69].summary.contains("may consume false"))
  assert_true(dossier.entries[69].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[69].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[69].path.contains(
      "remediation-margin-regenerated-receipt-readiness",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[70].kind),
    "moonclaw-regenerated-receipt-readiness-fresh-evidence-task",
  )
  assert_true(
    dossier.entries[70].summary.contains("3 pending regenerated receipts"),
  )
  assert_true(dossier.entries[70].summary.contains("0 ready receipts"))
  assert_true(
    dossier.entries[70].summary.contains(
      "RegeneratedReceiptsPendingFreshEvidence",
    ),
  )
  assert_true(dossier.entries[70].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[70].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[70].summary.contains("energy-window"))
  assert_true(
    dossier.entries[70].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[70].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[70].summary.contains("refresh-energy-window"))
  assert_true(
    dossier.entries[70].summary.contains("terrain=operator-escalation"),
  )
  assert_true(
    dossier.entries[70].summary.contains("local-horizon=bounded-regeneration"),
  )
  assert_true(
    dossier.entries[70].summary.contains("energy=manual-freeze-verification"),
  )
  assert_true(
    dossier.entries[70].summary.contains("source action receipt provenance"),
  )
  assert_true(dossier.entries[70].summary.contains("source readiness gate"))
  assert_true(dossier.entries[70].summary.contains("no automatic refresh loop"))
  assert_true(dossier.entries[70].summary.contains("no simulation consumption"))
  assert_true(dossier.entries[70].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[70].summary.contains("may consume false"))
  assert_true(dossier.entries[70].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[70].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[70].path.contains(
      "regenerated-receipt-readiness-fresh-evidence-task",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[71].kind),
    "moonclaw-regenerated-receipt-readiness-fresh-evidence-action-receipts",
  )
  assert_true(
    dossier.entries[71].summary.contains(
      "3 regenerated readiness fresh-evidence action receipts",
    ),
  )
  assert_true(
    dossier.entries[71].summary.contains(
      "RegeneratedFreshEvidenceActionsRecorded",
    ),
  )
  assert_true(
    dossier.entries[71].summary.contains(
      "RegeneratedReceiptsPendingFreshEvidence",
    ),
  )
  assert_true(dossier.entries[71].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[71].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[71].summary.contains("energy-window"))
  assert_true(
    dossier.entries[71].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[71].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[71].summary.contains("refresh-energy-window"))
  assert_true(
    dossier.entries[71].summary.contains("terrain=operator-escalation"),
  )
  assert_true(
    dossier.entries[71].summary.contains("local-horizon=bounded-regeneration"),
  )
  assert_true(
    dossier.entries[71].summary.contains("energy=manual-freeze-verification"),
  )
  assert_true(dossier.entries[71].summary.contains("source readiness gate"))
  assert_true(dossier.entries[71].summary.contains("source receipt provenance"))
  assert_true(
    dossier.entries[71].summary.contains("source action receipt provenance"),
  )
  assert_true(dossier.entries[71].summary.contains("no automatic refresh loop"))
  assert_true(dossier.entries[71].summary.contains("no simulation consumption"))
  assert_true(dossier.entries[71].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[71].summary.contains("may consume false"))
  assert_true(dossier.entries[71].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[71].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[71].path.contains(
      "regenerated-receipt-readiness-fresh-evidence-action-receipts",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[72].kind),
    "moonrobo-regenerated-receipt-readiness-action-receipt-closeout",
  )
  assert_true(
    dossier.entries[72].summary.contains(
      "RegeneratedReceiptsStillPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[72].summary.contains("3 pending regenerated receipts"),
  )
  assert_true(dossier.entries[72].summary.contains("0 ready receipts"))
  assert_true(
    dossier.entries[72].summary.contains("3 fresh-evidence action receipts"),
  )
  assert_true(dossier.entries[72].summary.contains("terrain-northeast-stepout"))
  assert_true(
    dossier.entries[72].summary.contains("illumination-northeast-stepout"),
  )
  assert_true(dossier.entries[72].summary.contains("energy-window"))
  assert_true(
    dossier.entries[72].summary.contains("refresh-terrain-northeast-stepout"),
  )
  assert_true(
    dossier.entries[72].summary.contains(
      "refresh-illumination-northeast-stepout",
    ),
  )
  assert_true(dossier.entries[72].summary.contains("refresh-energy-window"))
  assert_true(dossier.entries[72].summary.contains("operator-escalation"))
  assert_true(dossier.entries[72].summary.contains("bounded-regeneration"))
  assert_true(
    dossier.entries[72].summary.contains("manual-freeze-verification"),
  )
  assert_true(dossier.entries[72].summary.contains("source readiness gate"))
  assert_true(
    dossier.entries[72].summary.contains(
      "RegeneratedReceiptsPendingFreshEvidence",
    ),
  )
  assert_true(
    dossier.entries[72].summary.contains("source action receipt provenance"),
  )
  assert_true(dossier.entries[72].summary.contains("no automatic refresh loop"))
  assert_true(dossier.entries[72].summary.contains("no simulation consumption"))
  assert_true(dossier.entries[72].summary.contains("simulation-blocked"))
  assert_true(dossier.entries[72].summary.contains("may consume false"))
  assert_true(dossier.entries[72].summary.contains("moonmoon-safety-gate-only"))
  assert_true(dossier.entries[72].summary.contains("hardware-denied"))
  assert_true(
    dossier.entries[72].path.contains(
      "regenerated-receipt-readiness-action-receipt-closeout",
    ),
  )
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[73].kind),
    "moonclaw-ephemeris-receipt",
  )
  assert_true(dossier.entries[73].summary.contains("energy block"))
  assert_true(dossier.entries[73].summary.contains("accepted receipt"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[74].kind),
    "moonclaw-corridor-receipt",
  )
  assert_true(dossier.entries[74].summary.contains("81 measured windows"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[75].kind),
    "moonrobo-noetix-walk",
  )
  assert_true(dossier.entries[75].path.contains("noetix-walk"))
  assert_true(dossier.entries[75].summary.contains("noetix-e1-lab-01"))
  assert_true(dossier.entries[75].summary.contains("32 frames"))
  assert_true(dossier.entries[75].summary.contains("24 joint phases"))
  assert_eq(
    @moonbook.book_entry_kind_label(dossier.entries[76].kind),
    "moonrobo-noetix-physics",
  )
  assert_true(dossier.entries[76].path.contains("noetix-physics"))
  assert_true(dossier.entries[76].summary.contains("mass/sole/friction"))
  assert_true(dossier.entries[76].summary.contains("static-support review"))
  assert_true(dossier.entries[76].summary.contains("moonmoon-safety-gate-only"))
  assert_eq(dossier.review_queue[0].item_id, "workspace-materialized")
  assert_true(
    dossier.review_queue[0].status == @moonbook.ReviewItemStatus::Accepted,
  )
  assert_true(
    dossier.review_transitions[0].decision == @moonbook.ReviewDecision::Accept,
  )
  assert_true(
    dossier.review_transitions[0].previous_status ==
    @moonbook.ReviewItemStatus::Open,
  )
  assert_eq(
    dossier.review_transitions[0].reviewer_id,
    "operator/moonbook-policy-v1",
  )
  assert_eq(dossier.review_transitions[0].reviewer_role, "moonbook")
  assert_eq(
    dossier.review_transitions[0].timestamp_policy,
    "deterministic-evidence-window-start",
  )
  assert_eq(
    dossier.review_transitions[0].recorded_at_utc,
    "2026-06-25T00:00:00Z",
  )
  assert_true(dossier.review_transitions[0].append_only)
  assert_eq(
    dossier.review_transitions[0].source_evidence_refs[0].immutable_uri,
    "moonbook://moonmoon/first-trusted-square/index.json",
  )
  assert_eq(
    @moonbook.review_item_status_label(dossier.review_queue[0].status),
    "accepted",
  )
  let ephemeris_candidate = dossier.review_queue[1]
  assert_eq(
    ephemeris_candidate.item_id,
    "source-candidate-candidate-lunar-solar-ephemeris-first-trusted-square",
  )
  assert_true(ephemeris_candidate.status == @moonbook.ReviewItemStatus::Open)
  assert_true(
    dossier.review_transitions[1].decision == @moonbook.ReviewDecision::KeepOpen,
  )
  let direct_route = dossier.review_queue[6]
  assert_eq(direct_route.item_id, "route-direct-lola-window")
  assert_true(direct_route.status == @moonbook.ReviewItemStatus::Rejected)
  assert_true(
    dossier.review_transitions[6].decision == @moonbook.ReviewDecision::Reject,
  )
  assert_true(
    dossier.review_transitions[6].source_evidence_refs[0].entry_id ==
    "route/first-trusted-square/direct-lola-window",
  )
  assert_true(
    dossier.review_transitions[6].source_evidence_refs[0].immutable_uri.contains(
      "mission/first-trusted-square/routes/direct-lola-window.json",
    ),
  )
  assert_eq(
    @moonbook.review_decision_label(dossier.review_transitions[6].decision),
    "reject",
  )
  let corridor = dossier.review_queue[18]
  assert_eq(corridor.item_id, "corridor-scan-best-window")
  assert_true(corridor.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let energy = dossier.review_queue[19]
  assert_eq(energy.item_id, "energy-window")
  assert_true(energy.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let terrain_clearance = dossier.review_queue[20]
  assert_eq(terrain_clearance.item_id, "clear-terrain-grade-northeast-stepout")
  assert_true(
    terrain_clearance.status == @moonbook.ReviewItemStatus::NeedsEvidence,
  )
  assert_true(terrain_clearance.reason.contains("grade and roughness"))
  let illumination_clearance = dossier.review_queue[21]
  assert_eq(
    illumination_clearance.item_id,
    "clear-illumination-confidence-northeast-stepout",
  )
  assert_true(
    illumination_clearance.status == @moonbook.ReviewItemStatus::NeedsEvidence,
  )
  let energy_clearance = dossier.review_queue[22]
  assert_eq(energy_clearance.item_id, "clear-energy-margin")
  assert_true(
    energy_clearance.status == @moonbook.ReviewItemStatus::NeedsEvidence,
  )
  let moonbook_clearance = dossier.review_queue[23]
  assert_eq(
    moonbook_clearance.item_id,
    "clear-moonbook-review-northeast-stepout",
  )
  assert_true(
    moonbook_clearance.status == @moonbook.ReviewItemStatus::NeedsEvidence,
  )
  let handoff = dossier.review_queue[24]
  assert_eq(handoff.item_id, "moonrobo-handoff")
  assert_true(handoff.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let moonclaw = dossier.review_queue[25]
  assert_eq(moonclaw.item_id, "moonclaw-proposals")
  assert_true(moonclaw.status == @moonbook.ReviewItemStatus::NeedsEvidence)
  let first_question = dossier.review_queue[26]
  assert_eq(first_question.item_id, "question-0")
  assert_true(first_question.status == @moonbook.ReviewItemStatus::Open)
}

///|
fn imported_accept_transition(
  clearance_id : String,
) -> @moonbook.ReviewTransition {
  {
    transition_id: "operator-\{clearance_id}-accept",
    item_id: clearance_id,
    previous_status: @moonbook.ReviewItemStatus::Open,
    decision: @moonbook.ReviewDecision::Accept,
    resulting_status: @moonbook.ReviewItemStatus::Accepted,
    reviewer_id: "operator/manual-clearance-import",
    reviewer_role: "mission-review",
    timestamp_policy: "operator-imported",
    recorded_at_utc: "2026-06-25T00:00:00Z",
    append_only: true,
    source_evidence_refs: [
      {
        ref_id: clearance_id,
        entry_id: "mission/first-trusted-square/selected-route-clearance",
        path: "mission/first-trusted-square/selected-route-clearance.json",
        immutable_uri: "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#\{clearance_id}",
      },
    ],
    rationale: "operator accepted imported clearance evidence for \{clearance_id}",
  }
}

///|
fn imported_reject_transition(
  clearance_id : String,
) -> @moonbook.ReviewTransition {
  {
    transition_id: "operator-\{clearance_id}-reject",
    item_id: clearance_id,
    previous_status: @moonbook.ReviewItemStatus::Open,
    decision: @moonbook.ReviewDecision::Reject,
    resulting_status: @moonbook.ReviewItemStatus::Rejected,
    reviewer_id: "operator/manual-clearance-import",
    reviewer_role: "mission-review",
    timestamp_policy: "operator-imported",
    recorded_at_utc: "2026-06-25T00:00:00Z",
    append_only: true,
    source_evidence_refs: [
      {
        ref_id: clearance_id,
        entry_id: "mission/first-trusted-square/selected-route-clearance",
        path: "mission/first-trusted-square/selected-route-clearance.json",
        immutable_uri: "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#\{clearance_id}",
      },
    ],
    rationale: "operator rejected imported clearance evidence for \{clearance_id}",
  }
}

///|
test "imported review transitions drive selected route clearance" {
  let imported = [
    imported_accept_transition("clear-terrain-grade-northeast-stepout"),
    imported_accept_transition(
      "clear-illumination-confidence-northeast-stepout",
    ),
    imported_accept_transition("clear-energy-margin"),
    imported_accept_transition("clear-moonbook-review-northeast-stepout"),
  ]
  let dossier = @moonbook.from_site_dossier_with_review_transitions(
    @site.first_trusted_square_dossier(),
    imported,
  )
  let clearance_transitions = @moonbook.clearance_transitions_from_review_transitions(
    dossier.review_transitions,
  )
  assert_eq(clearance_transitions.length(), 4)
  assert_eq(
    clearance_transitions[0].clearance_id,
    "clear-terrain-grade-northeast-stepout",
  )
  assert_true(
    clearance_transitions[0].decision
    is @mission.MissionClearanceReviewDecision::ClearanceAccept,
  )
  assert_eq(
    dossier.review_queue[20].item_id,
    "clear-terrain-grade-northeast-stepout",
  )
  assert_true(
    dossier.review_queue[20].status == @moonbook.ReviewItemStatus::Accepted,
  )
  assert_eq(
    dossier.review_queue[23].item_id,
    "clear-moonbook-review-northeast-stepout",
  )
  assert_true(
    dossier.review_queue[23].status == @moonbook.ReviewItemStatus::Accepted,
  )
  assert_true(dossier.entries[43].summary.contains("allow northeast-stepout"))
  assert_true(dossier.entries[43].summary.contains("0 blockers"))
  let rejected_dossier = @moonbook.from_site_dossier_with_review_transitions(
    @site.first_trusted_square_dossier(),
    [imported_reject_transition("clear-energy-margin")],
  )
  let rejected_clearance_transitions = @moonbook.clearance_transitions_from_review_transitions(
    rejected_dossier.review_transitions,
  )
  assert_true(
    rejected_clearance_transitions.any(fn(transition) {
      transition.clearance_id == "clear-energy-margin" &&
      transition.decision
      is @mission.MissionClearanceReviewDecision::ClearanceReject
    }),
  )
  assert_true(
    rejected_dossier.review_queue[22].status ==
    @moonbook.ReviewItemStatus::Rejected,
  )
  assert_true(rejected_dossier.entries[43].summary.contains("4 blockers"))
}

///|
test "first trusted square MoonBook renderers expose review work" {
  let markdown = @moonbook.first_trusted_square_book_markdown()
  assert_true(markdown.contains("## Entries"))
  assert_true(markdown.contains("source-upgrade-candidate"))
  assert_true(markdown.contains("source-acquisition-plan"))
  assert_true(markdown.contains("source-product-selection"))
  assert_true(markdown.contains("source-extraction-candidate"))
  assert_true(markdown.contains("source-validation"))
  assert_true(markdown.contains("route-alternative"))
  assert_true(markdown.contains("corridor-scan"))
  assert_true(markdown.contains("illumination-assessment"))
  assert_true(markdown.contains("local-horizon-evidence"))
  assert_true(markdown.contains("terrain-remediation-evidence"))
  assert_true(markdown.contains("power-window-evidence"))
  assert_true(markdown.contains("energy-window"))
  assert_true(markdown.contains("energy-remediation-evidence"))
  assert_true(markdown.contains("selected-route-clearance"))
  assert_true(markdown.contains("moonrobo-handoff"))
  assert_true(markdown.contains("moonclaw-proposal"))
  assert_true(markdown.contains("moonclaw-task"))
  assert_true(markdown.contains("moonclaw-receipt"))
  assert_true(markdown.contains("moonclaw-remediation-margin-receipt"))
  assert_true(
    markdown.contains(
      "moonclaw-remediation-margin-regenerated-reviewed-work-item-receipts",
    ),
  )
  assert_true(
    markdown.contains(
      "moonrobo-remediation-margin-regenerated-receipt-readiness",
    ),
  )
  assert_true(
    markdown.contains(
      "moonclaw-regenerated-receipt-readiness-fresh-evidence-task",
    ),
  )
  assert_true(markdown.contains("moonclaw-ephemeris-receipt"))
  assert_true(markdown.contains("moonclaw-corridor-receipt"))
  assert_true(markdown.contains("## Review Queue"))
  assert_true(markdown.contains("workspace-materialized [low/accepted]"))
  assert_true(markdown.contains("route-direct-lola-window [high/rejected]"))
  assert_true(markdown.contains("## Review Transitions"))
  assert_true(markdown.contains("review-route-direct-lola-window-reject"))
  assert_true(
    markdown.contains("operator/moonbook-policy-v1 as mission-review"),
  )
  assert_true(markdown.contains("deterministic-evidence-window-start"))
  assert_true(markdown.contains("append only: true"))
  assert_true(
    markdown.contains(
      "moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/routes/direct-lola-window.json",
    ),
  )
  assert_true(markdown.contains("source-extraction-candidate"))
  assert_true(markdown.contains("max neighbor grade exceeds rover hard limit"))
  assert_true(markdown.contains("power-thermal-review"))
  let json = @moonbook.first_trusted_square_book_json().stringify(indent=2)
  assert_true(json.contains("\"review_queue\""))
  assert_true(json.contains("\"review_transitions\""))
  assert_true(json.contains("\"reviewer_id\""))
  assert_true(json.contains("\"timestamp_policy\""))
  assert_true(json.contains("\"append_only\""))
  assert_true(json.contains("\"source_evidence_refs\""))
  assert_true(json.contains("\"Accepted\""))
  assert_true(json.contains("\"Rejected\""))
  assert_true(json.contains("\"NeedsEvidence\""))
  assert_true(json.contains("\"RequestEvidence\""))
  assert_true(json.contains("\"SourceUpgradeCandidate\""))
  assert_true(json.contains("\"SourceAcquisitionPlan\""))
  assert_true(json.contains("\"SourceProductSelection\""))
  assert_true(json.contains("\"SourceExtractionCandidate\""))
  assert_true(json.contains("\"SourceValidation\""))
  assert_true(json.contains("\"MissionDecision\""))
  assert_true(json.contains("\"CorridorScan\""))
  assert_true(json.contains("\"RouteAlternative\""))
  assert_true(json.contains("\"IlluminationAssessment\""))
  assert_true(json.contains("\"LocalHorizonEvidence\""))
  assert_true(json.contains("\"TerrainRemediationEvidence\""))
  assert_true(json.contains("\"PowerWindowEvidence\""))
  assert_true(json.contains("\"EnergyWindow\""))
  assert_true(json.contains("\"EnergyRemediationEvidence\""))
  assert_true(json.contains("\"SelectedRouteClearance\""))
  assert_true(json.contains("\"MoonroboHandoff\""))
  assert_true(json.contains("\"MoonClawProposal\""))
  assert_true(json.contains("\"MoonClawTask\""))
  assert_true(json.contains("\"MoonClawRemediationMarginRefreshTask\""))
  assert_true(json.contains("\"MoonClawRemediationMarginRefreshFollowupTask\""))
  assert_true(
    json.contains("\"MoonroboRemediationMarginRegeneratedReceiptReadiness\""),
  )
  assert_true(
    json.contains(
      "\"MoonroboRegeneratedReceiptReadinessActionReceiptCloseout\"",
    ),
  )
  assert_true(
    json.contains("\"MoonClawRegeneratedReceiptReadinessFreshEvidenceTask\""),
  )
  assert_true(json.contains("\"MoonClawRemediationMarginRefreshReceipt\""))
  assert_true(json.contains("\"MoonClawReceipt\""))
  assert_true(json.contains("\"MoonClawRemediationMarginReceipt\""))
  assert_true(json.contains("\"MoonClawEphemerisReceipt\""))
  assert_true(json.contains("\"MoonClawCorridorReceipt\""))
}
