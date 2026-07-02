///|
pub(all) struct RobotGaitAnnotationCatalogDossier {
  root : String
  annotation_id : @robot_data.RobotGaitAnnotationId
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
  annotation_ref_count : Int
  model_ref_count : Int
  data_ref_count : Int
  annotation_ref_uris : Array[String]
  model_ref_uris : Array[String]
  data_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn gait_annotation_version_id(
  annotation_id : @robot_data.RobotGaitAnnotationId,
) -> String {
  "\{annotation_id}-v1"
}

///|
fn gait_annotation_clip_id(version : @data_core.DatasetVersion) -> String {
  if version.parent_version_ids.is_empty() {
    ""
  } else {
    let parent = version.parent_version_ids[0]
    if parent.has_suffix("-v1") && parent.length() > 3 {
      parent[0:parent.length() - 3].to_owned()
    } else {
      parent
    }
  }
}

///|
pub fn robot_gait_annotation_catalog_dossier_from_root(
  root : String,
  annotation_id : @robot_data.RobotGaitAnnotationId,
) -> Result[RobotGaitAnnotationCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_entry = match
    catalog_entry_for(catalog, "dataset", annotation_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-annotation-dataset-not-cataloged", annotation_id, "robot gait annotation dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = gait_annotation_version_id(annotation_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-annotation-version-not-cataloged", version_id, "robot gait annotation version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, annotation_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-gait-annotation-source-missing", annotation_id, "robot gait annotation dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-annotation-source-not-cataloged", source_id, "robot gait annotation source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-gait-annotation-validation-not-cataloged", root, "robot gait annotation data root has no cataloged validation report",
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
  let annotation_refs = refs_of_kind(dataset.data_refs, "robot-gait-annotation")
  let model_refs = refs_of_kind(dataset.data_refs, "urdf")
  Ok({
    root,
    annotation_id,
    clip_id: gait_annotation_clip_id(version),
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
    annotation_ref_count: annotation_refs.length(),
    model_ref_count: model_refs.length(),
    data_ref_count: dataset.data_refs.length(),
    annotation_ref_uris: data_ref_uris(annotation_refs),
    model_ref_uris: data_ref_uris(model_refs),
    data_ref_uris: data_ref_uris(dataset.data_refs),
  })
}
