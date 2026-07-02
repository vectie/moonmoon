///|
pub(all) struct RobotTaskLabelCatalogDossier {
  root : String
  task_label_id : @robot_data.RobotTaskLabelId
  episode_id : @robot_data.RobotEpisodeId
  alignment_id : @robot_data.RobotGaitAlignmentId
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
  task_label_ref_count : Int
  model_ref_count : Int
  data_ref_count : Int
  task_label_ref_uris : Array[String]
  model_ref_uris : Array[String]
  data_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn task_label_version_id(
  task_label_id : @robot_data.RobotTaskLabelId,
) -> String {
  "\{task_label_id}-v1"
}

///|
pub fn robot_task_label_catalog_dossier_from_root(
  root : String,
  task_label_id : @robot_data.RobotTaskLabelId,
) -> Result[RobotTaskLabelCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match
    catalog_entry_for(catalog, "dataset", task_label_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-task-label-dataset-not-cataloged", task_label_id, "robot task label dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = task_label_version_id(task_label_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-task-label-version-not-cataloged", version_id, "robot task label version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, task_label_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-task-label-source-missing", task_label_id, "robot task label dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-task-label-source-not-cataloged", source_id, "robot task label source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-task-label-validation-not-cataloged", root, "robot task label data root has no cataloged validation report",
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
  let task_label_refs = refs_of_kind(dataset.data_refs, "robot-task-label")
  let model_refs = refs_of_kind(dataset.data_refs, "urdf")
  Ok({
    root,
    task_label_id,
    episode_id: parent_id_at(version, 0),
    alignment_id: parent_id_at(version, 1),
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
    task_label_ref_count: task_label_refs.length(),
    model_ref_count: model_refs.length(),
    data_ref_count: dataset.data_refs.length(),
    task_label_ref_uris: data_ref_uris(task_label_refs),
    model_ref_uris: data_ref_uris(model_refs),
    data_ref_uris: data_ref_uris(dataset.data_refs),
  })
}
