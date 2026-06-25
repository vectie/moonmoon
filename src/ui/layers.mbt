///|
pub fn view_layer_kind_label(kind : ViewLayerKind) -> String {
  match kind {
    ElevationLayer => "elevation"
    SlopeLayer => "slope"
    RoughnessLayer => "roughness"
    HazardLayer => "hazard"
    RouteLayer => "route"
    EvidenceLayer => "evidence"
    PowerLayer => "power"
  }
}

///|
fn layer_toggle(
  kind : ViewLayerKind,
  label : String,
  visible : Bool,
  value_unit : String,
  legend_min : Double,
  legend_max : Double,
  status : String,
) -> LayerToggle {
  {
    layer_id: view_layer_kind_label(kind),
    kind,
    label,
    visible,
    value_unit,
    legend_min,
    legend_max,
    status,
  }
}

///|
fn view_layers(
  metrics : @terrain.TerrainMetrics,
  energy : @mission.EnergyAssessment,
) -> Array[LayerToggle] {
  [
    layer_toggle(
      ElevationLayer,
      "Elevation",
      true,
      "m",
      metrics.min_elevation_m,
      metrics.max_elevation_m,
      "measured",
    ),
    layer_toggle(
      SlopeLayer,
      "Slope",
      true,
      "grade",
      0.0,
      metrics.max_neighbor_grade,
      "derived",
    ),
    layer_toggle(
      RoughnessLayer,
      "Roughness",
      false,
      "m",
      0.0,
      metrics.roughness_m,
      "derived",
    ),
    layer_toggle(
      HazardLayer,
      "Hazard",
      true,
      "risk",
      0.0,
      1.0,
      @terrain.hazard_label(metrics.hazard_class),
    ),
    layer_toggle(RouteLayer, "Routes", true, "state", 0.0, 1.0, "blocked"),
    layer_toggle(EvidenceLayer, "Evidence", false, "state", 0.0, 1.0, "ready"),
    layer_toggle(
      PowerLayer,
      "Power",
      false,
      "Wh",
      0.0,
      energy.available_energy_wh,
      @mission.energy_decision_label(energy),
    ),
  ]
}

///|
fn bounded_intensity(
  value : Double,
  min_value : Double,
  max_value : Double,
) -> Double {
  if max_value <= min_value {
    0.0
  } else {
    let raw = (value - min_value) / (max_value - min_value)
    if raw < 0.0 {
      0.0
    } else if raw > 1.0 {
      1.0
    } else {
      raw
    }
  }
}

///|
fn hazard_score(hazard : String) -> Double {
  match hazard {
    "clear" => 0.0
    "caution" => 0.55
    _ => 1.0
  }
}

///|
fn cell_layer_values(
  cell : @core.TerrainCell,
  slope_grade : Double,
  roughness_m : Double,
  hazard : String,
  metrics : @terrain.TerrainMetrics,
  energy : @mission.EnergyAssessment,
) -> Array[CellLayerValue] {
  [
    {
      layer_id: "elevation",
      value: cell.elevation_m,
      value_label: "\{cell.elevation_m} m",
      status: "measured",
      intensity: bounded_intensity(
        cell.elevation_m,
        metrics.min_elevation_m,
        metrics.max_elevation_m,
      ),
    },
    {
      layer_id: "slope",
      value: slope_grade,
      value_label: "\{slope_grade} grade",
      status: "derived",
      intensity: bounded_intensity(slope_grade, 0.0, metrics.max_neighbor_grade),
    },
    {
      layer_id: "roughness",
      value: roughness_m,
      value_label: "\{roughness_m} m",
      status: "derived",
      intensity: bounded_intensity(roughness_m, 0.0, metrics.roughness_m),
    },
    {
      layer_id: "hazard",
      value: hazard_score(hazard),
      value_label: hazard,
      status: hazard,
      intensity: hazard_score(hazard),
    },
    {
      layer_id: "power",
      value: energy.available_energy_wh,
      value_label: "\{energy.available_energy_wh} Wh",
      status: @mission.energy_decision_label(energy),
      intensity: bounded_intensity(
        energy.available_energy_wh,
        0.0,
        energy.required_energy_wh,
      ),
    },
  ]
}
