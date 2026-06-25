///|
pub(all) struct TerrainRemediationEvidence {
  evidence_id : String
  route_id : String
  site_id : String
  source_dataset_id : String
  source_tile_id : String
  source_path : String
  output_path : String
  method_id : String
  generated_by : String
  rows : Int
  cols : Int
  cell_size_m : Double
  edge_count : Int
  blocking_edge_count : Int
  max_neighbor_delta_m : Double
  max_neighbor_grade : Double
  roughness_m : Double
  grade_limit : Double
  roughness_limit_m : Double
  grade_margin : Double
  roughness_margin_m : Double
  confidence : Double
  decision : TraverseDecision
  reasons : Array[String]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_northeast_stepout_terrain_remediation() -> TerrainRemediationEvidence {
  generated_first_trusted_square_northeast_stepout_terrain_remediation()
}

///|
pub fn first_trusted_square_northeast_stepout_terrain_remediation_json() -> Json {
  first_trusted_square_northeast_stepout_terrain_remediation().to_json()
}

///|
pub fn first_trusted_square_northeast_stepout_terrain_remediation_markdown() -> String {
  let evidence = first_trusted_square_northeast_stepout_terrain_remediation()
  let mut text = "# Selected Route Terrain Remediation\n\n"
  text += "- evidence: \{evidence.evidence_id}\n"
  text += "- site: \{evidence.site_id}\n"
  text += "- route: \{evidence.route_id}\n"
  text += "- source: \{evidence.source_path}\n"
  text += "- method: \{evidence.method_id}\n"
  text += "- decision: \{traverse_decision_label(evidence.decision)}\n"
  text += "- max neighbor grade: \{evidence.max_neighbor_grade}\n"
  text += "- grade limit: \{evidence.grade_limit}\n"
  text += "- grade margin: \{evidence.grade_margin}\n"
  text += "- roughness: \{evidence.roughness_m} m\n"
  text += "- roughness limit: \{evidence.roughness_limit_m} m\n"
  text += "- roughness margin: \{evidence.roughness_margin_m} m\n"
  text += "- blocking edges: \{evidence.blocking_edge_count} / \{evidence.edge_count}\n"
  text += "- confidence: \{evidence.confidence}\n\n"
  text += "## Reasons\n\n"
  for reason in evidence.reasons {
    text += "- \{reason}\n"
  }
  text += "\n## Next Action\n\n"
  text += evidence.next_action
  text += "\n"
  text
}

///|
fn proxy_terrain_remediation_evidence(
  route_id : String,
  grid : @terrain.TerrainGrid,
  metrics : @terrain.TerrainMetrics,
  profile : TraverseProfile,
) -> TerrainRemediationEvidence {
  let grade_margin = metrics.max_neighbor_grade - profile.max_grade
  let roughness_margin = metrics.roughness_m - profile.max_roughness_m
  let decision = if grade_margin >= 0.0 || roughness_margin >= 0.0 {
    Block
  } else if metrics.max_neighbor_grade >= profile.caution_grade ||
    metrics.roughness_m >= profile.caution_roughness_m {
    Review
  } else {
    Allow
  }
  {
    evidence_id: "terrain-remediation-proxy/\{route_id}",
    route_id,
    site_id: "first-trusted-square",
    source_dataset_id: grid.source_manifest.dataset_id,
    source_tile_id: grid.tile_id,
    source_path: grid.source_manifest.source_path,
    output_path: "",
    method_id: "terrain-metrics-proxy-v1",
    generated_by: "src/mission/terrain_remediation.mbt",
    rows: grid.rows,
    cols: grid.cols,
    cell_size_m: grid.cell_size_m,
    edge_count: grid.rows * (grid.cols - 1) + (grid.rows - 1) * grid.cols,
    blocking_edge_count: if decision == Block {
      1
    } else {
      0
    },
    max_neighbor_delta_m: metrics.max_neighbor_grade * grid.cell_size_m,
    max_neighbor_grade: metrics.max_neighbor_grade,
    roughness_m: metrics.roughness_m,
    grade_limit: profile.max_grade,
    roughness_limit_m: profile.max_roughness_m,
    grade_margin,
    roughness_margin_m: roughness_margin,
    confidence: metrics.uncertainty.confidence,
    decision,
    reasons: [
      "terrain remediation proxy mirrors current terrain metrics until a bounded selected-route model is generated",
    ],
    next_action: "generate bounded terrain remediation evidence before MoonRobo simulation",
  }
}

///|
fn terrain_remediation_evidence(
  route_id : String,
  grid : @terrain.TerrainGrid,
  metrics : @terrain.TerrainMetrics,
  profile : TraverseProfile,
) -> TerrainRemediationEvidence {
  if route_id == "northeast-stepout" &&
    grid.tile_id == "first-trusted-square-northeast-stepout-lola" {
    first_trusted_square_northeast_stepout_terrain_remediation()
  } else {
    proxy_terrain_remediation_evidence(route_id, grid, metrics, profile)
  }
}
