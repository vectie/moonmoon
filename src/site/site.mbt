///|
pub(all) struct SiteDossier {
  site : @core.LunarSite
  datasets : Array[@terrain.TerrainSourceManifest]
  validations : Array[@terrain.TerrainFixtureValidation]
  catalog_evidence : Array[SiteCatalogEvidence]
  catalog_validation : SiteCatalogValidationEvidence
  source_candidates : Array[@lunar_data.LunarSourceCandidate]
  source_acquisition_plans : Array[@lunar_data.LunarAcquisitionPlan]
  source_product_selections : Array[@lunar_data.LunarProductSelection]
  source_extraction_candidates : Array[@lunar_data.LunarExtractionCandidate]
  terrain : @terrain.TerrainMetrics
  traverse : @mission.TraverseScore
  corridor_scan : Array[@mission.CorridorScanWindow]
  route_candidates : Array[@mission.RouteCandidate]
  power_window_evidence : @mission.PowerWindowEvidence
  energy : @mission.EnergyAssessment
  clearance_plan : @mission.MissionClearancePlan
  summary : String
  blockers : Array[String]
  next_questions : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn pending_label(value : String) -> String {
  if value == "" {
    "pending"
  } else {
    value
  }
}

///|
fn selected_route_label(value : String) -> String {
  if value == "" {
    "none promoted yet"
  } else {
    value
  }
}

///|
fn route_candidate_by_id(
  routes : Array[@mission.RouteCandidate],
  route_id : String,
) -> @mission.RouteCandidate {
  for route in routes {
    if route.route_id == route_id {
      return route
    }
  }
  routes[0]
}

///|
fn selected_route_readiness(
  route : @mission.RouteCandidate,
  corridor : @mission.CorridorScanWindow,
  energy : @mission.EnergyAssessment,
) -> @mission.MissionSimulationReadiness {
  @mission.simulation_readiness(
    "mission/first-trusted-square/\{route.route_id}/simulation-readiness",
    route.route_id,
    [
      @mission.readiness_check(
        "terrain-\{route.route_id}",
        @mission.MissionReadinessCheckKind::TerrainReadiness,
        "Selected-route terrain gate",
        route.terrain_remediation.decision,
        route.terrain_remediation.output_path,
        route.terrain_remediation.next_action,
      ),
      @mission.readiness_check(
        "corridor-scan-best-window",
        @mission.MissionReadinessCheckKind::CorridorReadiness,
        "Measured corridor search gate",
        corridor.decision,
        "mission/first-trusted-square/corridor-scan.json",
        corridor.note,
      ),
      @mission.readiness_check(
        "illumination-\{route.route_id}",
        @mission.MissionReadinessCheckKind::IlluminationReadiness,
        "Selected-route illumination gate",
        route.illumination.decision,
        route.illumination.local_horizon.output_path,
        route.illumination.next_action,
      ),
      @mission.readiness_check(
        "energy-window",
        @mission.MissionReadinessCheckKind::EnergyReadiness,
        "Rover energy window gate",
        energy.decision,
        energy.budget.power_window_source_path,
        energy.next_action,
      ),
      @mission.readiness_check(
        "operator-review",
        @mission.MissionReadinessCheckKind::OperatorReviewReadiness,
        "Operator accepted-review gate",
        @mission.TraverseDecision::Block,
        "artifact/operator-review-transitions.json",
        "Operator review has unresolved blockers for selected route simulation",
      ),
    ],
  )
}

///|
pub fn first_trusted_square_site() -> @core.LunarSite {
  {
    site_id: "first-trusted-square",
    name: "First Trusted Square / Shackleton Rim rehearsal tile",
    body: "Moon",
    bounds: {
      south_deg: -89.90,
      north_deg: -89.86,
      west_deg: 0.10,
      east_deg: 0.14,
    },
    center: { latitude_deg: -89.88, longitude_deg: 0.12, radius_m: 1737400.0 },
    purpose: "Software proof slice for lunar terrain, uncertainty, and robot traverse reasoning.",
  }
}

///|
fn terrain_blockers(metrics : @terrain.TerrainMetrics) -> Array[String] {
  match metrics.hazard_class {
    Clear => []
    Caution =>
      [
        "needs operator review before robot traverse planning", "fixture confidence is not high enough for physical mission planning",
      ]
    Blocked =>
      [
        "terrain exceeds early traverse limits", "requires alternate route or stronger dataset",
      ]
  }
}

///|
fn mission_blockers(
  terrain : @terrain.TerrainMetrics,
  route : @mission.RouteCandidate,
  energy : @mission.EnergyAssessment,
) -> Array[String] {
  let blockers = terrain_blockers(terrain)
  if route.illumination.decision != Allow {
    let horizon = route.illumination.local_horizon
    blockers.push(
      "selected route receives \{horizon.terrain_sunlit_hours} terrain-visible hours; longest darkness is \{horizon.longest_dark_hours} hours",
    )
  }
  if energy.decision != Allow {
    blockers.push(
      "energy margin is \{energy.margin_wh} Wh; required minimum is \{energy.budget.min_energy_margin_wh} Wh",
    )
  }
  blockers
}

///|
pub fn first_trusted_square_dossier() -> SiteDossier {
  let grid = @terrain.first_trusted_square_grid()
  let west_grid = @terrain.first_trusted_square_west_contour_grid()
  let north_grid = @terrain.first_trusted_square_north_rim_grid()
  let southwest_grid = @terrain.first_trusted_square_southwest_bypass_grid()
  let south_grid = @terrain.first_trusted_square_south_stepout_grid()
  let northeast_grid = @terrain.first_trusted_square_northeast_stepout_grid()
  let terrain = @terrain.analyze(grid)
  let traverse = @mission.score_traverse(
    terrain,
    @mission.conservative_rover_profile(),
  )
  let corridor_scan = @mission.first_trusted_square_corridor_scan()
  let route_candidates = @mission.first_trusted_square_route_candidates()
  let energy = @mission.assess_energy_window(
    route_candidates,
    @mission.conservative_energy_budget(),
  )
  let selected_route = route_candidate_by_id(
    route_candidates,
    corridor_scan[0].selected_route_id,
  )
  let readiness = selected_route_readiness(
    selected_route,
    corridor_scan[0],
    energy,
  )
  let clearance_plan = @mission.selected_route_clearance_plan(
    "mission/first-trusted-square/\{selected_route.route_id}/selected-route-clearance",
    selected_route,
    energy,
    readiness,
  )
  {
    site: first_trusted_square_site(),
    datasets: [
      grid.source_manifest,
      west_grid.source_manifest,
      north_grid.source_manifest,
      southwest_grid.source_manifest,
      south_grid.source_manifest,
      northeast_grid.source_manifest,
    ],
    validations: [
      @terrain.validate_grid_source(grid),
      @terrain.validate_grid_source(west_grid),
      @terrain.validate_grid_source(north_grid),
      @terrain.validate_grid_source(southwest_grid),
      @terrain.validate_grid_source(south_grid),
      @terrain.validate_grid_source(northeast_grid),
    ],
    catalog_evidence: first_trusted_square_catalog_evidence(),
    catalog_validation: missing_catalog_validation_evidence(),
    source_candidates: @lunar_data.first_trusted_square_lunar_source_candidates(),
    source_acquisition_plans: @lunar_data.first_trusted_square_lunar_acquisition_plans(),
    source_product_selections: [
      @lunar_data.first_trusted_square_lola_product_selection(),
    ],
    source_extraction_candidates: @lunar_data.first_trusted_square_all_lola_extraction_candidates(),
    terrain,
    traverse,
    corridor_scan,
    route_candidates,
    power_window_evidence: @mission.first_trusted_square_power_window_evidence(),
    energy,
    clearance_plan,
    summary: "One small lunar site model with explicit provenance, measured terrain, a reproducible 9x9 corridor scan, hourly azimuth-matched DE440 route exposure, and a conservative rover energy budget.",
    blockers: mission_blockers(terrain, selected_route, energy),
    next_questions: [
      "Declare and compute a mission window where the Sun rises above the spherical horizon.",
      "Review the promoted northeast-stepout route fixture and decide whether wider sampling should continue around the same corridor.",
      "Review the materialized Operator review workspace entries and close accepted or rejected queue items.",
    ],
  }
}

///|
pub fn render_markdown(dossier : SiteDossier) -> String {
  let terrain = dossier.terrain
  let traverse = dossier.traverse
  let mut text = "# \{dossier.site.name}\n\n"
  text += "Purpose: \{dossier.site.purpose}\n\n"
  text += "Summary: \{dossier.summary}\n\n"
  text += "## Source Datasets\n\n"
  for manifest in dossier.datasets {
    text += "- \{manifest.dataset_id}: \{manifest.title}\n"
    text += "  - trust: \{@terrain.terrain_source_trust_label(manifest.trust)}\n"
    text += "  - review: \{@terrain.terrain_source_review_status_label(manifest.review_status)}\n"
    text += "  - resolution: \{manifest.resolution_m} m\n"
    text += "  - source path: \{manifest.source_path}\n"
    text += "  - source sha256: \{manifest.source_sha256}\n"
    text += "  - extractor: \{manifest.extractor}\n"
    text += "  - checksum kind: \{@terrain.terrain_source_checksum_kind_label(manifest.checksum_kind)}\n"
    text += "  - checksum: \{manifest.checksum}\n"
  }
  text += "\n"
  text += "## Catalog Evidence\n\n"
  for evidence in dossier.catalog_evidence {
    text += "- \{evidence.artifact.artifact_kind}: \{evidence.artifact.artifact_id}\n"
    text += "  - status: \{@data_core.artifact_ref_status_label(evidence.artifact)}\n"
    text += "  - authority: \{evidence.authority}\n"
    text += "  - manifest: \{evidence.artifact.manifest_path}\n"
    text += "  - refs: \{evidence.ref_uris.length()}\n"
  }
  text += "\n"
  text += "## Catalog Validation\n\n"
  text += "- artifact: \{dossier.catalog_validation.artifact.artifact_id}\n"
  text += "  - status: \{@data_core.validation_status_label(dossier.catalog_validation.validation_status)}\n"
  text += "  - ready: \{dossier.catalog_validation.ready}\n"
  text += "  - findings: \{dossier.catalog_validation.finding_count}\n"
  text += "  - blockers: \{dossier.catalog_validation.blocker_count}\n"
  text += "  - warnings: \{dossier.catalog_validation.warning_count}\n"
  text += "  - summary: \{dossier.catalog_validation.summary}\n\n"
  text += "## Source Upgrade Candidates\n\n"
  for candidate in dossier.source_candidates {
    text += "- \{candidate.source_id}: \{candidate.title}\n"
    text += "  - mission: \{candidate.mission}\n"
    text += "  - instrument: \{candidate.instrument}\n"
    text += "  - product family: \{candidate.product_family}\n"
    text += "  - status: \{@lunar_data.lunar_review_status_label(candidate.review_status)}\n"
    text += "  - official source: \{candidate.official_source_url}\n"
    text += "  - access: \{candidate.access_url}\n"
    text += "  - local source directory: \{candidate.local_source_directory}\n"
    text += "  - intended use: \{candidate.intended_use}\n"
  }
  text += "\n"
  text += "## Source Acquisition Plans\n\n"
  for plan in dossier.source_acquisition_plans {
    text += "- \{plan.plan_id}: \{plan.product_family_id}\n"
    text += "  - source: \{plan.source_id}\n"
    text += "  - progress: recorded:\{plan.steps.length()}-steps\n"
    text += "  - discovery: \{plan.discovery_url}\n"
    text += "  - source family: \{plan.source_family_url}\n"
    text += "  - source metadata: \{plan.source_metadata_url}\n"
    text += "  - source metadata sha256: \{pending_label(plan.source_metadata_sha256)}\n"
    text += "  - source metadata bytes: \{plan.source_metadata_bytes}\n"
    text += "  - target region: \{plan.target_region}\n"
    text += "  - local source directory: \{plan.local_source_directory}\n"
    text += "  - local metadata path: \{plan.local_metadata_path}\n"
    text += "  - extracted fixture path: \{plan.extracted_fixture_path}\n"
    text += "  - trust gate: \{plan.trust_gate}\n"
    text += "  - steps:\n"
    for step in plan.steps {
      text += "    - \{step.step_id}: \{step.title} - \{step.done_when}\n"
    }
  }
  text += "\n"
  text += "## Source Product Selections\n\n"
  for selection in dossier.source_product_selections {
    text += "- \{selection.selection_id}: \{selection.product_id}\n"
    text += "  - source: \{selection.source_id}\n"
    text += "  - status: \{@lunar_data.lunar_review_status_label(selection.review_status)}\n"
    text += "  - product lid: \{selection.product_lid}\n"
    text += "  - image: \{selection.image_url}\n"
    text += "  - label: \{selection.label_url}\n"
    text += "  - local label path: \{selection.local_label_path}\n"
    text += "  - label sha256: \{selection.label_sha256}\n"
    text += "  - label bytes: \{selection.label_bytes}\n"
    text += "  - image bytes: \{selection.image_bytes}\n"
    text += "  - projection: \{selection.coordinate_frame.projection}\n"
    text += "  - resolution: \{selection.coverage.resolution_m} m\n"
    text += "  - bounds: \{selection.coverage.south_deg}..\{selection.coverage.north_deg} lat, \{selection.coverage.west_deg}..\{selection.coverage.east_deg} lon\n"
    text += "  - shape: \{selection.lines} lines x \{selection.samples} samples\n"
    text += "  - data: \{selection.data_type} / \{selection.unit}, offset \{selection.value_offset_km} km\n"
    text += "  - reason: \{selection.selection_reason}\n"
  }
  text += "\n"
  text += "## Source Extraction Candidates\n\n"
  for extraction in dossier.source_extraction_candidates {
    text += "- \{extraction.extraction_id}: \{extraction.tile_id}\n"
    text += "  - selection: \{extraction.selection_id}\n"
    text += "  - status: \{@lunar_data.lunar_review_status_label(extraction.review_status)}\n"
    text += "  - generated by: \{extraction.generated_by}\n"
    text += "  - output path: \{extraction.output_path}\n"
    text += "  - output sha256: \{extraction.output_sha256}\n"
    text += "  - output bytes: \{extraction.output_bytes}\n"
    text += "  - center: \{extraction.coverage.center_lat_deg}, \{extraction.coverage.center_lon_deg}\n"
    text += "  - source window: row \{extraction.source_row_start}, col \{extraction.source_col_start}, \{extraction.rows}x\{extraction.cols}\n"
    text += "  - cell size: \{extraction.cell_size_m} m\n"
    text += "  - elevation unit: \{extraction.value_unit}\n"
    text += "  - claim: \{extraction.claim_kind}\n"
    text += "  - notes:\n"
    for note in extraction.notes {
      text += "    - \{note}\n"
    }
  }
  text += "\n"
  text += "## Terrain Fixture Validation\n\n"
  for validation in dossier.validations {
    text += "- \{validation.dataset_id}: \{@terrain.terrain_fixture_validation_status_label(validation.status)}\n"
    text += "  - actual: \{validation.actual_fingerprint}\n"
    text += "  - note: \{validation.note}\n"
  }
  text += "\n"
  text += "## Terrain\n\n"
  text += "- elevation range: \{terrain.elevation_range_m} m (\{terrain.min_elevation_m} to \{terrain.max_elevation_m})\n"
  text += "- max neighbor grade: \{terrain.max_neighbor_grade}\n"
  text += "- roughness: \{terrain.roughness_m} m\n"
  text += "- hazard: \{@terrain.hazard_label(terrain.hazard_class)} - \{terrain.hazard_reason}\n"
  text += "- confidence: \{terrain.uncertainty.label} (\{terrain.uncertainty.confidence})\n"
  text += "- provenance: \{terrain.provenance.dataset_id} / \{terrain.provenance.product_type}\n\n"
  text += "## Traverse Readiness\n\n"
  text += "- profile: \{traverse.profile.label} (\{traverse.profile.profile_id})\n"
  text += "- decision: \{@mission.traverse_decision_label(traverse.decision)}\n"
  text += "- score: \{traverse.score}\n"
  text += "- next action: \{traverse.next_action}\n"
  text += "- reasons:\n"
  if traverse.reasons.is_empty() {
    text += "  - none\n"
  } else {
    for reason in traverse.reasons {
      text += "  - \{reason}\n"
    }
  }
  text += "\n"
  text += "## Corridor Scan\n\n"
  let best_window = dossier.corridor_scan[0]
  text += "- scan: \{best_window.scan_id}\n"
  text += "- windows ranked: \{dossier.corridor_scan.length()}\n"
  text += "- best measured window: \{best_window.window_id} (rank \{best_window.rank})\n"
  text += "- offset: row \{best_window.row_offset}, col \{best_window.col_offset}\n"
  text += "- selected route: \{selected_route_label(best_window.selected_route_id)}\n"
  text += "- decision: \{@mission.corridor_scan_window_status_label(best_window)}\n"
  text += "- max neighbor grade: \{best_window.max_neighbor_grade}\n"
  text += "- roughness: \{best_window.roughness_m} m\n"
  text += "- note: \{best_window.note}\n"
  text += "- top windows:\n"
  for window in dossier.corridor_scan {
    if window.rank <= 5 {
      text += "  - #\{window.rank} \{window.window_id}: grade \{window.max_neighbor_grade}, roughness \{window.roughness_m} m, decision \{@mission.corridor_scan_window_status_label(window)}"
      if window.selected_route_id != "" {
        text += ", route \{window.selected_route_id}"
      }
      text += "\n"
    }
  }
  text += "\n"
  text += "## Power Window Evidence\n\n"
  let power = dossier.power_window_evidence
  text += "- evidence: \{power.evidence_id}\n"
  text += "- source status: \{power.source_status}\n"
  text += "- source family: \{power.source_family_url}\n"
  text += "- local source path: \{power.local_source_path}\n"
  text += "- source sha256: \{pending_label(power.source_sha256)}\n"
  text += "- source bytes: \{power.source_bytes}\n"
  text += "- source files:\n"
  for source_file in power.source_files {
    text += "  - \{source_file.file_id}: \{source_file.status}, \{source_file.role}, sha256 \{pending_label(source_file.sha256)}\n"
  }
  text += "- computation: \{power.computation.method_id} (\{power.computation.status})\n"
  text += "  - generated by: \{power.computation.generated_by}\n"
  text += "  - horizon model: \{power.computation.horizon_model}\n"
  text += "  - rover power model: \{power.computation.rover_power_model}\n"
  text += "- time window: \{power.time_start_utc} -> \{power.time_end_utc}\n"
  text += "- sunlit hours: \{power.sunlit_hours}\n"
  text += "- dark hours: \{power.dark_hours}\n"
  text += "- available energy: \{power.available_energy_wh} Wh\n"
  text += "- confidence: \{power.confidence}\n"
  text += "- has time-windowed ephemeris: \{power.has_time_window_ephemeris}\n"
  text += "- reasons:\n"
  if power.reasons.is_empty() {
    text += "  - none\n"
  } else {
    for reason in power.reasons {
      text += "  - \{reason}\n"
    }
  }
  text += "\n"
  text += "## Energy Window\n\n"
  let energy = dossier.energy
  text += "- budget: \{energy.budget.label} (\{energy.budget.budget_id})\n"
  text += "- power-window evidence: \{energy.budget.power_window_evidence_id}\n"
  text += "- power-window source: \{energy.budget.power_window_source_path}\n"
  text += "- power-window source status: \{energy.budget.power_window_source_status}\n"
  text += "- time window: \{energy.budget.time_start_utc} -> \{energy.budget.time_end_utc}\n"
  text += "- decision: \{@mission.energy_decision_label(energy)}\n"
  text += "- route candidates: \{energy.route_count}\n"
  text += "- blocked route candidates: \{energy.blocked_route_count}\n"
  text += "- estimated drive hours: \{energy.estimated_drive_hours}\n"
  text += "- estimated dark survival hours: \{energy.estimated_dark_survival_hours}\n"
  text += "- required energy: \{energy.required_energy_wh} Wh\n"
  text += "- verified available energy: \{energy.available_energy_wh} Wh\n"
  text += "- energy margin: \{energy.margin_wh} Wh\n"
  text += "- next action: \{energy.next_action}\n"
  text += "- reasons:\n"
  if energy.reasons.is_empty() {
    text += "  - none\n"
  } else {
    for reason in energy.reasons {
      text += "  - \{reason}\n"
    }
  }
  text += "\n"
  text += "## Route Candidates\n\n"
  for route in dossier.route_candidates {
    text += "- \{route.route_id}: \{route.label}\n"
    text += "  - decision: \{@mission.route_candidate_status_label(route)}\n"
    text += "  - score: \{route.score}\n"
    text += "  - strategy: \{route.strategy}\n"
    text += "  - evidence dataset: \{route.evidence_dataset_id}\n"
    text += "  - evidence tile: \{route.evidence_tile_id}\n"
    text += "  - evidence source: \{route.evidence_source_path}\n"
    text += "  - evidence summary: \{route.evidence_summary}\n"
    text += "  - expected max grade: \{route.expected_max_grade}\n"
    text += "  - expected roughness: \{route.expected_roughness_m} m\n"
    text += "  - confidence: \{route.confidence}\n"
    text += "  - illumination decision: \{@mission.illumination_decision_label(route.illumination)}\n"
    text += "  - illumination evidence: \{route.illumination.constraint.power_window_evidence_id}\n"
    text += "  - illumination source status: \{route.illumination.constraint.power_window_source_status}\n"
    text += "  - illumination risk: \{route.illumination.relief_shadow_risk}\n"
    text += "  - illumination confidence: \{route.illumination.confidence}\n"
    text += "  - illumination next action: \{route.illumination.next_action}\n"
    text += "  - illumination reasons:\n"
    if route.illumination.reasons.is_empty() {
      text += "    - none\n"
    } else {
      for reason in route.illumination.reasons {
        text += "    - \{reason}\n"
      }
    }
    text += "  - next action: \{route.next_action}\n"
    text += "  - reasons:\n"
    if route.reasons.is_empty() {
      text += "    - none\n"
    } else {
      for reason in route.reasons {
        text += "    - \{reason}\n"
      }
    }
  }
  text += "\n"
  text += "## Selected Route Clearance\n\n"
  let clearance = dossier.clearance_plan
  text += "- plan: \{clearance.plan_id}\n"
  text += "- route: \{clearance.route_id}\n"
  text += "- decision: \{@mission.traverse_decision_label(clearance.decision)}\n"
  text += "- blocking items: \{clearance.blocking_items.length()}\n"
  text += "- review items: \{clearance.review_items.length()}\n"
  text += "- accepted items: \{clearance.accepted_items.length()}\n"
  text += "- rejected items: \{clearance.rejected_items.length()}\n"
  text += "- next action: \{clearance.next_action}\n"
  text += "- gates:\n"
  for item in clearance.items {
    text += "  - \{item.clearance_id}: \{item.label}\n"
    text += "    - kind: \{@mission.mission_clearance_kind_label(item.kind)}\n"
    text += "    - decision: \{@mission.traverse_decision_label(item.decision)}\n"
    text += "    - status: \{@mission.mission_clearance_status_label(item.status)}\n"
    text += "    - evidence: \{item.evidence_path}\n"
    text += "    - observed: \{item.observed}\n"
    text += "    - required: \{item.required}\n"
    text += "    - action: \{item.clearance_action}\n"
  }
  text += "\n"
  text += "## Blockers\n\n"
  if dossier.blockers.is_empty() {
    text += "- none for this fixture\n"
  } else {
    for blocker in dossier.blockers {
      text += "- \{blocker}\n"
    }
  }
  text += "\n## Next Questions\n\n"
  for question in dossier.next_questions {
    text += "- \{question}\n"
  }
  text
}

///|
pub fn first_trusted_square_markdown() -> String {
  render_markdown(first_trusted_square_dossier())
}

///|
pub fn render_json(dossier : SiteDossier) -> Json {
  dossier.to_json()
}

///|
pub fn first_trusted_square_json() -> Json {
  render_json(first_trusted_square_dossier())
}
