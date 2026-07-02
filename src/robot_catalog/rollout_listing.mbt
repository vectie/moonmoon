///|
pub(all) struct RobotRolloutCatalogDossier {
  root : String
  rollout_id : @robot_data.RobotRolloutId
  episode_id : @robot_data.RobotEpisodeId
  task_label_id : @robot_data.RobotTaskLabelId
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
  rollout_ref_count : Int
  model_ref_count : Int
  data_ref_count : Int
  rollout_ref_uris : Array[String]
  model_ref_uris : Array[String]
  data_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn rollout_version_id(rollout_id : @robot_data.RobotRolloutId) -> String {
  "\{rollout_id}-v1"
}

///|
pub fn robot_rollout_catalog_dossier_from_root(
  root : String,
  rollout_id : @robot_data.RobotRolloutId,
) -> Result[RobotRolloutCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match catalog_entry_for(catalog, "dataset", rollout_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-rollout-dataset-not-cataloged", rollout_id, "robot rollout summary dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = rollout_version_id(rollout_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-rollout-version-not-cataloged", version_id, "robot rollout summary version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, rollout_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-rollout-source-missing", rollout_id, "robot rollout summary dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-rollout-source-not-cataloged", source_id, "robot rollout summary source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-rollout-validation-not-cataloged", root, "robot rollout data root has no cataloged validation report",
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
  let rollout_refs = refs_of_kind(dataset.data_refs, "robot-rollout-summary")
  let model_refs = refs_of_kind(dataset.data_refs, "urdf")
  Ok({
    root,
    rollout_id,
    episode_id: parent_id_at(version, 0),
    task_label_id: parent_id_at(version, 1),
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
    rollout_ref_count: rollout_refs.length(),
    model_ref_count: model_refs.length(),
    data_ref_count: dataset.data_refs.length(),
    rollout_ref_uris: data_ref_uris(rollout_refs),
    model_ref_uris: data_ref_uris(model_refs),
    data_ref_uris: data_ref_uris(dataset.data_refs),
  })
}
