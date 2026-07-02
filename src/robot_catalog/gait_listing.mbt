///|
pub(all) struct RobotGaitClipCatalogDossier {
  root : String
  clip_id : @robot_data.RobotGaitClipId
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
  gait_ref_count : Int
  model_ref_count : Int
  data_ref_count : Int
  gait_ref_uris : Array[String]
  model_ref_uris : Array[String]
  data_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn gait_clip_version_id(clip_id : @robot_data.RobotGaitClipId) -> String {
  "\{clip_id}-v1"
}

///|
pub fn robot_gait_clip_catalog_dossier_from_root(
  root : String,
  clip_id : @robot_data.RobotGaitClipId,
) -> Result[RobotGaitClipCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match catalog_entry_for(catalog, "dataset", clip_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-clip-dataset-not-cataloged", clip_id, "robot gait clip dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = gait_clip_version_id(clip_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-clip-version-not-cataloged", version_id, "robot gait clip version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, clip_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-gait-clip-source-missing", clip_id, "robot gait clip dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-clip-source-not-cataloged", source_id, "robot gait clip source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-clip-validation-not-cataloged", root, "robot gait clip data root has no cataloged validation report",
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
  let gait_refs = refs_of_kind(dataset.data_refs, "robot-gait-clip")
  let model_refs = refs_of_kind(dataset.data_refs, "urdf")
  Ok({
    root,
    clip_id,
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
    gait_ref_count: gait_refs.length(),
    model_ref_count: model_refs.length(),
    data_ref_count: dataset.data_refs.length(),
    gait_ref_uris: data_ref_uris(gait_refs),
    model_ref_uris: data_ref_uris(model_refs),
    data_ref_uris: data_ref_uris(dataset.data_refs),
  })
}
