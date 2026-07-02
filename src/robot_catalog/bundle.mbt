///|
pub(all) struct RobotCatalogBundle {
  bundle_id : String
  models : Array[@robot_data.RobotModelRef]
  episodes : Array[@robot_data.RobotEpisodeManifest]
  telemetry_streams : Array[@robot_data.RobotTelemetryStreamManifest]
  quality_reports : Array[@robot_data.RobotQualityReport]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotCatalogMaterialization {
  root : String
  catalog_path : String
  validation_report_path : String
  source_count : Int
  dataset_count : Int
  version_count : Int
  lineage_count : Int
  telemetry_stream_count : Int
  quality_report_count : Int
  catalog_entry_count : Int
  validation_status : @data_core.ValidationStatus
  blocker_count : Int
  warning_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_catalog_bundle(
  bundle_id : String,
  models : Array[@robot_data.RobotModelRef],
  episodes : Array[@robot_data.RobotEpisodeManifest],
  telemetry_streams? : Array[@robot_data.RobotTelemetryStreamManifest] = [],
  quality_reports? : Array[@robot_data.RobotQualityReport] = [],
) -> RobotCatalogBundle {
  { bundle_id, models, episodes, telemetry_streams, quality_reports }
}
