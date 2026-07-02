///|
pub(all) struct RobotGaitAlignmentCatalogDossier {
  root : String
  alignment_id : @robot_data.RobotGaitAlignmentId
  episode_id : @robot_data.RobotEpisodeId
  clip_id : @robot_data.RobotGaitClipId
  annotation_id : @robot_data.RobotGaitAnnotationId
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
  alignment_ref_count : Int
  model_ref_count : Int
  data_ref_count : Int
  alignment_ref_uris : Array[String]
  model_ref_uris : Array[String]
  data_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn gait_alignment_version_id(
  alignment_id : @robot_data.RobotGaitAlignmentId,
) -> String {
  "\{alignment_id}-v1"
}

///|
fn strip_v1(version_id : String) -> String {
  if version_id.has_suffix("-v1") && version_id.length() > 3 {
    version_id[0:version_id.length() - 3].to_owned()
  } else {
    version_id
  }
}

///|
fn parent_id_at(version : @data_core.DatasetVersion, index : Int) -> String {
  if index < version.parent_version_ids.length() {
    strip_v1(version.parent_version_ids[index])
  } else {
    ""
  }
}

///|
pub fn robot_gait_alignment_catalog_dossier_from_root(
  root : String,
  alignment_id : @robot_data.RobotGaitAlignmentId,
) -> Result[RobotGaitAlignmentCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match
    catalog_entry_for(catalog, "dataset", alignment_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-alignment-dataset-not-cataloged", alignment_id, "robot gait alignment dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = gait_alignment_version_id(alignment_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-alignment-version-not-cataloged", version_id, "robot gait alignment version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, alignment_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-gait-alignment-source-missing", alignment_id, "robot gait alignment dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-alignment-source-not-cataloged", source_id, "robot gait alignment source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-alignment-validation-not-cataloged", root, "robot gait alignment data root has no cataloged validation report",
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
  let alignment_refs = refs_of_kind(dataset.data_refs, "robot-gait-alignment")
  let model_refs = refs_of_kind(dataset.data_refs, "urdf")
  Ok({
    root,
    alignment_id,
    episode_id: parent_id_at(version, 0),
    clip_id: parent_id_at(version, 1),
    annotation_id: parent_id_at(version, 2),
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
    alignment_ref_count: alignment_refs.length(),
    model_ref_count: model_refs.length(),
    data_ref_count: dataset.data_refs.length(),
    alignment_ref_uris: data_ref_uris(alignment_refs),
    model_ref_uris: data_ref_uris(model_refs),
    data_ref_uris: data_ref_uris(dataset.data_refs),
  })
}
