///|
fn source_panel(
  dossier : @site.SiteDossier,
  grid : @terrain.TerrainGrid,
) -> SourcePanel {
  let manifest = grid.source_manifest
  let catalog = @site.catalog_evidence_for_artifact(
    dossier,
    "dataset",
    manifest.dataset_id,
  )
  {
    dataset_id: manifest.dataset_id,
    catalog_artifact_kind: match catalog {
      Some(evidence) => evidence.artifact.artifact_kind
      None => ""
    },
    catalog_artifact_id: match catalog {
      Some(evidence) => evidence.artifact.artifact_id
      None => ""
    },
    catalog_manifest_path: match catalog {
      Some(evidence) => evidence.artifact.manifest_path
      None => ""
    },
    catalog_status: match catalog {
      Some(evidence) => @data_core.artifact_ref_status_label(evidence.artifact)
      None => "missing"
    },
    authority: match catalog {
      Some(evidence) => evidence.authority
      None => ""
    },
    source_title: manifest.title,
    source_url: match catalog {
      Some(evidence) => evidence.source_url
      None => manifest.source_url
    },
    local_source_path: manifest.source_path,
    catalog_ref_uris: match catalog {
      Some(evidence) => evidence.ref_uris
      None => []
    },
    claim: @core.claim_kind_label(manifest.claim_kind),
    review_status: @terrain.terrain_source_review_status_label(
      manifest.review_status,
    ),
    checksum: manifest.checksum,
    generated_by: manifest.extractor,
  }
}

///|
fn tile_inspector(
  grid : @terrain.TerrainGrid,
  metrics : @terrain.TerrainMetrics,
  energy : @mission.EnergyAssessment,
  cell : @core.TerrainCell,
  selected_route_id : String,
) -> TileInspector {
  let metric = cell_metric_pair(grid, cell)
  let slope_grade = metric.0
  let roughness_m = metric.1
  let hazard = cell_hazard(slope_grade, roughness_m)
  {
    cell_id: cell_id(grid, cell.row, cell.col),
    row: cell.row,
    col: cell.col,
    elevation_m: cell.elevation_m,
    slope_grade,
    roughness_m,
    hazard,
    source_dataset_id: grid.source_manifest.dataset_id,
    source_path: grid.source_manifest.source_path,
    claim: @core.claim_kind_label(cell.provenance.claim_kind),
    uncertainty_label: cell.uncertainty.label,
    confidence: cell.uncertainty.confidence,
    layer_values: cell_layer_values(
      cell, slope_grade, roughness_m, hazard, metrics, energy,
    ),
    notes: [
      "selected by highest local slope and roughness in the active viewport",
      "active route overlay: \{selected_route_id}",
      cell.uncertainty.note,
    ],
  }
}

///|
fn site_scorecard(
  dossier : @site.SiteDossier,
  selected_route_id : String,
) -> SiteScorecard {
  {
    decision: @mission.traverse_decision_label(dossier.traverse.decision),
    score: dossier.traverse.score,
    terrain_hazard: @terrain.hazard_label(dossier.terrain.hazard_class),
    route_candidates: dossier.route_candidates.length(),
    blocked_route_candidates: dossier.energy.blocked_route_count,
    selected_route_id,
    available_energy_wh: dossier.energy.available_energy_wh,
    energy_margin_wh: dossier.energy.margin_wh,
    confidence: dossier.terrain.uncertainty.confidence,
    next_action: dossier.energy.next_action,
  }
}

///|
fn inspector_facts(
  dossier : @site.SiteDossier,
  selected_route_id : String,
  selected_cell_id : String,
) -> Array[InspectorFact] {
  let best = dossier.corridor_scan[0]
  [
    {
      fact_id: "selected-cell",
      label: "Selected cell",
      value: selected_cell_id,
      status: "inspecting",
      evidence_path: "ui/first-trusted-square/view-model.json",
    },
    {
      fact_id: "catalog-evidence",
      label: "Catalog evidence",
      value: "\{dossier.catalog_evidence.length()} catalog artifacts",
      status: "ready",
      evidence_path: "indexes/catalog.json",
    },
    {
      fact_id: "catalog-validation",
      label: "Catalog validation",
      value: "\{@data_core.validation_status_label(dossier.catalog_validation.validation_status)} / \{dossier.catalog_validation.finding_count} finding(s); \{dossier.catalog_validation.summary}",
      status: if dossier.catalog_validation.ready {
        "ready"
      } else if dossier.catalog_validation.blocker_count > 0 {
        "blocked"
      } else {
        "review"
      },
      evidence_path: dossier.catalog_validation.artifact.manifest_path,
    },
    {
      fact_id: "best-corridor-window",
      label: "Best corridor window",
      value: "\{best.window_id} -> \{selected_route_id}",
      status: @mission.corridor_scan_window_status_label(best),
      evidence_path: "mission/first-trusted-square/corridor-scan.json",
    },
    {
      fact_id: "power-window-evidence",
      label: "Power-window evidence",
      value: dossier.power_window_evidence.source_status,
      status: if dossier.power_window_evidence.has_time_window_ephemeris {
        "ready"
      } else {
        "blocked"
      },
      evidence_path: "mission/first-trusted-square/power-window-evidence.json",
    },
    {
      fact_id: "energy-window",
      label: "Energy window",
      value: "\{dossier.energy.margin_wh} Wh margin",
      status: @mission.energy_decision_label(dossier.energy),
      evidence_path: "mission/first-trusted-square/energy-window.json",
    },
  ]
}
