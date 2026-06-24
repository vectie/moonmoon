///|
pub(all) struct SiteDossier {
  site : @core.LunarSite
  datasets : Array[@dataset.DatasetManifest]
  validations : Array[@dataset.DatasetValidation]
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
    terrain,
    traverse,
    summary: "One small lunar site model with explicit provenance, uncertainty, terrain metrics, and first-pass hazard classification.",
    blockers: terrain_blockers(terrain),
    next_questions: [
      "Replace synthetic DEM with an authoritative LOLA/LROC-backed fixture.", "Add illumination windows for robot energy and thermal constraints.",
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
