///|
pub(all) struct RobotTelemetryCatalogDossier {
  root : String
  stream_id : @robot_data.RobotTelemetryStreamId
  catalog_entry_count : Int
  source_artifact : @data_core.ArtifactRef
  dataset_artifact : @data_core.ArtifactRef
  version_artifact : @data_core.ArtifactRef
  validation_artifact : @data_core.ArtifactRef
  source : @data_core.DataSource
  dataset : @data_core.DatasetManifest
  version : @data_core.DatasetVersion
  validation_status : @data_core.ValidationStatus
  blocker_count : Int
  warning_count : Int
  telemetry_ref_count : Int
  data_ref_count : Int
  telemetry_ref_uris : Array[String]
  data_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn telemetry_version_id(
  stream_id : @robot_data.RobotTelemetryStreamId,
) -> String {
  "\{stream_id}-v1"
}

///|
pub fn robot_telemetry_catalog_dossier_from_root(
  root : String,
  stream_id : @robot_data.RobotTelemetryStreamId,
) -> Result[RobotTelemetryCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match catalog_entry_for(catalog, "dataset", stream_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-telemetry-dataset-not-cataloged", stream_id, "robot telemetry stream dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = telemetry_version_id(stream_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-telemetry-version-not-cataloged", version_id, "robot telemetry stream version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, stream_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-telemetry-source-missing", stream_id, "robot telemetry stream dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-telemetry-source-not-cataloged", source_id, "robot telemetry stream source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-telemetry-validation-not-cataloged", root, "robot telemetry data root has no cataloged validation report",
        ),
      )
  }
  let source = match @data_store.read_source(root, source_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let version = match @data_store.read_dataset_version(root, version_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let report = match
    @data_store.read_validation_report(root, validation_entry.artifact_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let telemetry_refs = refs_of_kind(dataset.data_refs, "robot-telemetry-sample")
  Ok({
    root,
    stream_id,
    catalog_entry_count: catalog.entries.length(),
    source_artifact: @data_core.catalog_entry_ref(source_entry),
    dataset_artifact: @data_core.catalog_entry_ref(dataset_entry),
    version_artifact: @data_core.catalog_entry_ref(version_entry),
    validation_artifact: @data_core.catalog_entry_ref(validation_entry),
    source,
    dataset,
    version,
    validation_status: report.status,
    blocker_count: @data_core.validation_blocker_count(report),
    warning_count: warning_count(report),
    telemetry_ref_count: telemetry_refs.length(),
    data_ref_count: dataset.data_refs.length(),
    telemetry_ref_uris: data_ref_uris(telemetry_refs),
    data_ref_uris: data_ref_uris(dataset.data_refs),
  })
}
