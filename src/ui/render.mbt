///|
pub fn render_markdown(view : TrustedSquareViewModel) -> String {
  let mut text = "# \{view.title} Operator View\n\n"
  text += "- view: \{view.view_id}\n"
  text += "- viewport: \{view.viewport.rows}x\{view.viewport.cols} cells, \{view.viewport.viewport_width_px}x\{view.viewport.viewport_height_px} px\n"
  text += "- active layer: \{view.active_layer_id}\n"
  text += "- selected cell: \{view.selected_cell_id}\n"
  text += "- selected route: \{view.selected_route_id}\n\n"
  text += "## Scorecard\n\n"
  text += "- decision: \{view.scorecard.decision}\n"
  text += "- score: \{view.scorecard.score}\n"
  text += "- terrain hazard: \{view.scorecard.terrain_hazard}\n"
  text += "- routes: \{view.scorecard.route_candidates} candidates, \{view.scorecard.blocked_route_candidates} blocked\n"
  text += "- energy: \{view.scorecard.available_energy_wh} Wh available, \{view.scorecard.energy_margin_wh} Wh margin\n"
  text += "- next action: \{view.scorecard.next_action}\n\n"
  text += "## Layers\n\n"
  for layer in view.layers {
    let visible = if layer.visible { "visible" } else { "available" }
    text += "- \{layer.layer_id}: \{layer.label}, \{visible}, \{layer.status}, legend \{layer.legend_min}..\{layer.legend_max} \{layer.value_unit}\n"
  }
  text += "\n## Selected Tile Inspector\n\n"
  text += "- cell: \{view.selected_tile.cell_id} (r\{view.selected_tile.row}, c\{view.selected_tile.col})\n"
  text += "- elevation: \{view.selected_tile.elevation_m} m\n"
  text += "- slope: \{view.selected_tile.slope_grade}\n"
  text += "- roughness: \{view.selected_tile.roughness_m} m\n"
  text += "- hazard: \{view.selected_tile.hazard}\n"
  text += "- source: \{view.selected_tile.source_dataset_id} / \{view.selected_tile.source_path}\n"
  text += "- claim: \{view.selected_tile.claim}\n"
  text += "- uncertainty: \{view.selected_tile.uncertainty_label}, confidence \{view.selected_tile.confidence}\n"
  text += "- layer values:\n"
  for layer_value in view.selected_tile.layer_values {
    text += "  - \{layer_value.layer_id}: \{layer_value.value_label} (\{layer_value.status}, intensity \{layer_value.intensity})\n"
  }
  text += "\n## Source Panel\n\n"
  text += "- dataset: \{view.source_panel.dataset_id}\n"
  text += "- title: \{view.source_panel.source_title}\n"
  text += "- source: \{view.source_panel.source_url}\n"
  text += "- local path: \{view.source_panel.local_source_path}\n"
  text += "- claim: \{view.source_panel.claim}\n"
  text += "- review: \{view.source_panel.review_status}\n"
  text += "- checksum: \{view.source_panel.checksum}\n\n"
  text += "## Route Overlays\n\n"
  for overlay in view.route_overlays {
    let marker = if overlay.selected { "*" } else { "-" }
    text += "\{marker} \{overlay.route_id}: \{overlay.decision}, \{overlay.viewport_ref}, \{overlay.summary}\n"
  }
  text += "\n## Routes\n\n"
  for route in view.routes {
    let marker = if route.selected { "*" } else { "-" }
    text += "\{marker} \{route.route_id}: \{route.decision}, score \{route.score}, grade \{route.max_grade}, roughness \{route.roughness_m} m\n"
  }
  text += "\n## Inspector Facts\n\n"
  for fact in view.inspector_facts {
    text += "- \{fact.label}: \{fact.value} (\{fact.status})\n"
  }
  text += "\n## Terrain Cells\n\n"
  for cell in view.terrain_cells {
    let marker = if cell.selected { "*" } else { "-" }
    text += "\{marker} r\{cell.row} c\{cell.col}: \{cell.elevation_m} m, slope \{cell.slope_grade}, roughness \{cell.roughness_m} m, \{cell.hazard}, confidence \{cell.confidence}\n"
  }
  text
}

///|
pub fn first_trusted_square_markdown() -> String {
  render_markdown(first_trusted_square_view_model())
}

///|
pub fn render_json(view : TrustedSquareViewModel) -> Json {
  view.to_json()
}

///|
pub fn first_trusted_square_json() -> Json {
  render_json(first_trusted_square_view_model())
}
