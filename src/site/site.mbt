///|
pub(all) struct SiteDossier {
  site : @core.LunarSite
  datasets : Array[@dataset.DatasetManifest]
  validations : Array[@dataset.DatasetValidation]
  source_candidates : Array[@dataset.SourceCandidate]
  source_acquisition_plans : Array[@dataset.SourceAcquisitionPlan]
  source_product_selections : Array[@dataset.SourceProductSelection]
  source_extraction_candidates : Array[@dataset.SourceExtractionCandidate]
  terrain : @terrain.TerrainMetrics
  traverse : @mission.TraverseScore
  summary : String
  blockers : Array[String]
  next_questions : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

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
pub fn first_trusted_square_dossier() -> SiteDossier {
  let grid = @terrain.first_trusted_square_grid()
  let terrain = @terrain.analyze(grid)
  let traverse = @mission.score_traverse(
    terrain,
    @mission.conservative_rover_profile(),
  )
  {
    site: first_trusted_square_site(),
    datasets: [grid.source_manifest],
    validations: [@terrain.validate_grid_source(grid)],
    source_candidates: @dataset.first_trusted_square_source_candidates(),
    source_acquisition_plans: @dataset.first_trusted_square_source_acquisition_plans(),
    source_product_selections: @dataset.first_trusted_square_source_product_selections(),
    source_extraction_candidates: @dataset.first_trusted_square_source_extraction_candidates(),
    terrain,
    traverse,
    summary: "One small lunar site model with explicit provenance, uncertainty, terrain metrics, and first-pass hazard classification.",
    blockers: terrain_blockers(terrain),
    next_questions: [
      "Add illumination windows for robot energy and thermal constraints.", "Find alternate route candidates around the blocked LOLA terrain patch.",
      "Export the dossier into a LunarBook workspace for review.",
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
    text += "  - trust: \{@dataset.trust_label(manifest.trust)}\n"
    text += "  - review: \{@dataset.review_status_label(manifest.review_status)}\n"
    text += "  - resolution: \{manifest.resolution_m} m\n"
    text += "  - source path: \{manifest.source_path}\n"
    text += "  - source sha256: \{manifest.source_sha256}\n"
    text += "  - extractor: \{manifest.extractor}\n"
    text += "  - checksum kind: \{@dataset.checksum_kind_label(manifest.checksum_kind)}\n"
    text += "  - checksum: \{manifest.checksum}\n"
  }
  text += "\n"
  text += "## Source Upgrade Candidates\n\n"
  for candidate in dossier.source_candidates {
    text += "- \{candidate.candidate_id}: \{candidate.title}\n"
    text += "  - mission: \{candidate.mission}\n"
    text += "  - instrument: \{candidate.instrument}\n"
    text += "  - product family: \{candidate.product_family}\n"
    text += "  - status: \{@dataset.source_candidate_status_label(candidate)}\n"
    text += "  - official source: \{candidate.official_source_url}\n"
    text += "  - access: \{candidate.access_url}\n"
    text += "  - target path: \{candidate.local_target_path}\n"
    text += "  - next action: \{candidate.next_action}\n"
  }
  text += "\n"
  text += "## Source Acquisition Plans\n\n"
  for plan in dossier.source_acquisition_plans {
    text += "- \{plan.plan_id}: \{plan.product_family_id}\n"
    text += "  - candidate: \{plan.candidate_id}\n"
    text += "  - progress: \{@dataset.acquisition_plan_progress_label(plan)}\n"
    text += "  - discovery: \{plan.discovery_url}\n"
    text += "  - source family: \{plan.source_family_url}\n"
    text += "  - source metadata: \{plan.source_metadata_url}\n"
    text += "  - source metadata sha256: \{plan.source_metadata_sha256}\n"
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
    text += "  - plan: \{selection.plan_id}\n"
    text += "  - status: \{@dataset.product_selection_status_label(selection)}\n"
    text += "  - product lid: \{selection.product_lid}\n"
    text += "  - image: \{selection.image_url}\n"
    text += "  - label: \{selection.label_url}\n"
    text += "  - local label path: \{selection.local_label_path}\n"
    text += "  - label sha256: \{selection.label_sha256}\n"
    text += "  - label bytes: \{selection.label_bytes}\n"
    text += "  - image bytes: \{selection.image_bytes}\n"
    text += "  - projection: \{selection.projection}\n"
    text += "  - resolution: \{selection.resolution_m} m\n"
    text += "  - bounds: \{selection.south_deg}..\{selection.north_deg} lat, \{selection.west_deg}..\{selection.east_deg} lon\n"
    text += "  - shape: \{selection.lines} lines x \{selection.samples} samples\n"
    text += "  - data: \{selection.data_type} / \{selection.unit}, offset \{selection.value_offset_km} km\n"
    text += "  - reason: \{selection.selection_reason}\n"
    text += "  - extraction risk: \{selection.extraction_risk}\n"
  }
  text += "\n"
  text += "## Source Extraction Candidates\n\n"
  for extraction in dossier.source_extraction_candidates {
    text += "- \{extraction.extraction_id}: \{extraction.tile_id}\n"
    text += "  - selection: \{extraction.selection_id}\n"
    text += "  - status: \{@dataset.extraction_candidate_status_label(extraction)}\n"
    text += "  - generated by: \{extraction.generated_by}\n"
    text += "  - output path: \{extraction.output_path}\n"
    text += "  - output sha256: \{extraction.output_sha256}\n"
    text += "  - output bytes: \{extraction.output_bytes}\n"
    text += "  - center: \{extraction.center_lat_deg}, \{extraction.center_lon_deg}\n"
    text += "  - source window: row \{extraction.source_row_start}, col \{extraction.source_col_start}, \{extraction.rows}x\{extraction.cols}\n"
    text += "  - cell size: \{extraction.cell_size_m} m\n"
    text += "  - elevation unit: \{extraction.elevation_unit}\n"
    text += "  - claim: \{@core.claim_kind_label(extraction.claim_kind)}\n"
    text += "  - notes:\n"
    for note in extraction.notes {
      text += "    - \{note}\n"
    }
  }
  text += "\n"
  text += "## Source Validation\n\n"
  for validation in dossier.validations {
    text += "- \{validation.dataset_id}: \{@dataset.validation_status_label(validation.status)}\n"
    text += "  - actual: \{validation.actual_checksum}\n"
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
