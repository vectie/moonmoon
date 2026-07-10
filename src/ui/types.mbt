///|
pub(all) enum ViewLayerKind {
  ElevationLayer
  SlopeLayer
  RoughnessLayer
  HazardLayer
  RouteLayer
  EvidenceLayer
  PowerLayer
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LayerToggle {
  layer_id : String
  kind : ViewLayerKind
  label : String
  visible : Bool
  value_unit : String
  legend_min : Double
  legend_max : Double
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ViewportGeometry {
  rows : Int
  cols : Int
  cell_size_m : Double
  tile_width_px : Int
  tile_height_px : Int
  viewport_width_px : Int
  viewport_height_px : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CellLayerValue {
  layer_id : String
  value : Double
  value_label : String
  status : String
  intensity : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainCellView {
  cell_id : String
  row : Int
  col : Int
  x_px : Int
  y_px : Int
  elevation_m : Double
  slope_grade : Double
  roughness_m : Double
  hazard : String
  selected : Bool
  confidence : Double
  source_dataset_id : String
  layer_values : Array[CellLayerValue]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RouteIlluminationView {
  decision : String
  confidence : Double
  relief_shadow_risk : Double
  max_horizon_angle_deg : Double
  max_sun_altitude_deg : Double
  evaluated_sample_count : Int
  spherical_sunlit_hours : Double
  terrain_sunlit_hours : Double
  terrain_shadowed_hours : Double
  longest_dark_hours : Double
  terrain_available_energy_wh : Double
  minimum_solar_clearance_deg : Double
  maximum_solar_clearance_deg : Double
  bounded_horizon : Bool
  time_start_utc : String
  time_end_utc : String
  power_window_source_path : String
  horizon_evidence_path : String
  horizon_profile : Array[RouteHorizonSampleView]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RouteHorizonSampleView {
  label : String
  azimuth_center_deg : Double
  horizon_angle_deg : Double
  obstruction_elevation_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RouteView {
  route_id : String
  label : String
  selected : Bool
  decision : String
  score : Int
  max_grade : Double
  roughness_m : Double
  evidence_tile_id : String
  illumination : RouteIlluminationView
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RouteOverlay {
  overlay_id : String
  route_id : String
  label : String
  selected : Bool
  decision : String
  evidence_tile_id : String
  viewport_ref : String
  status : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct GlobeOverlayPoint {
  point_id : String
  label : String
  latitude_deg : Double
  longitude_deg : Double
  role : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct GlobeOverlayPath {
  path_id : String
  label : String
  kind : String
  status : String
  points : Array[GlobeOverlayPoint]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct GlobeOverlayWindow {
  window_id : String
  rank : Int
  row_offset : Int
  col_offset : Int
  latitude_deg : Double
  longitude_deg : Double
  decision : String
  selected : Bool
  selected_route_id : String
  max_neighbor_grade : Double
  roughness_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct GlobeOverlayView {
  overlay_id : String
  source_dataset_id : String
  source_path : String
  claim : String
  footprint : Array[GlobeOverlayPoint]
  selected_route_trace : GlobeOverlayPath
  corridor_windows : Array[GlobeOverlayWindow]
  hardware_authority : String
  blocker_count : Int
  status : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CorridorWindowView {
  window_id : String
  rank : Int
  row_offset : Int
  col_offset : Int
  min_elevation_m : Double
  max_elevation_m : Double
  elevation_range_m : Double
  max_neighbor_grade : Double
  roughness_m : Double
  decision : String
  selected_route_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct InspectorFact {
  fact_id : String
  label : String
  value : String
  status : String
  evidence_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TileInspector {
  cell_id : String
  row : Int
  col : Int
  elevation_m : Double
  slope_grade : Double
  roughness_m : Double
  hazard : String
  source_dataset_id : String
  source_path : String
  claim : String
  uncertainty_label : String
  confidence : Double
  layer_values : Array[CellLayerValue]
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SourcePanel {
  dataset_id : String
  catalog_artifact_kind : String
  catalog_artifact_id : String
  catalog_manifest_path : String
  catalog_status : String
  authority : String
  source_title : String
  source_url : String
  local_source_path : String
  catalog_ref_uris : Array[String]
  claim : String
  review_status : String
  checksum : String
  generated_by : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SiteScorecard {
  decision : String
  score : Int
  terrain_hazard : String
  route_candidates : Int
  blocked_route_candidates : Int
  selected_route_id : String
  available_energy_wh : Double
  energy_margin_wh : Double
  confidence : Double
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarLightingSampleView {
  timestamp_utc : String
  sun_body_x : Double
  sun_body_y : Double
  sun_body_z : Double
  earth_body_x : Double
  earth_body_y : Double
  earth_body_z : Double
  sun_altitude_deg : Double
  sun_azimuth_deg : Double
  earth_altitude_deg : Double
  earth_azimuth_deg : Double
  earth_illuminated_fraction : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarLightingView {
  method_id : String
  frame_id : String
  source_path : String
  orientation_source_path : String
  target_lat_deg : Double
  target_lon_deg : Double
  sample_step_minutes : Int
  default_sample_index : Int
  samples : Array[LunarLightingSampleView]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TrustedSquareViewModel {
  view_id : String
  site_id : String
  title : String
  site_latitude_deg : Double
  site_longitude_deg : Double
  viewport : ViewportGeometry
  layers : Array[LayerToggle]
  active_layer_id : String
  selected_cell_id : String
  selected_route_id : String
  terrain_cells : Array[TerrainCellView]
  routes : Array[RouteView]
  route_overlays : Array[RouteOverlay]
  globe_overlay : GlobeOverlayView
  corridor_windows : Array[CorridorWindowView]
  selected_tile : TileInspector
  source_panel : SourcePanel
  scorecard : SiteScorecard
  lighting : LunarLightingView
  inspector_facts : Array[InspectorFact]
  blockers : Array[String]
} derive(Debug, Eq, ToJson, FromJson)
