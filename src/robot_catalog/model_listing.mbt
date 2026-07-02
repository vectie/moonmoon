///|
pub(all) struct RobotModelCatalogDossier {
  root : String
  model_id : @robot_data.RobotModelId
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
  data_ref_count : Int
  data_ref_uris : Array[String]
  urdf_ref_uri : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn dossier_issue(
  code : String,
  path : String,
  message : String,
) -> @data_store.DataStoreIssue {
  { code, path, message }
}

///|
fn model_dataset_id(model_id : @robot_data.RobotModelId) -> String {
  "robot-model-package-\{model_id}"
}

///|
fn model_version_id(model_id : @robot_data.RobotModelId) -> String {
  "\{model_dataset_id(model_id)}-v1"
}

///|
fn catalog_entry_for(
  catalog : @data_core.DataCatalog,
  artifact_kind : String,
  artifact_id : String,
) -> @data_core.CatalogEntry? {
  for entry in catalog.entries {
    if entry.artifact_kind == artifact_kind && entry.artifact_id == artifact_id {
      return Some(entry)
    }
  }
  None
}

///|
fn latest_validation_entry(
  catalog : @data_core.DataCatalog,
) -> @data_core.CatalogEntry? {
  let mut found : @data_core.CatalogEntry? = None
  for entry in catalog.entries {
    if entry.artifact_kind == "validation-report" &&
      entry.artifact_id.has_prefix("validation-") {
      found = Some(entry)
    }
  }
  found
}

///|
fn data_ref_uris(refs : Array[@data_core.DataRef]) -> Array[String] {
  refs.map(fn(data_ref) { data_ref.uri })
}

///|
fn urdf_ref_uri(dataset : @data_core.DatasetManifest) -> String? {
  for data_ref in dataset.data_refs {
    if data_ref.kind == "urdf" {
      return Some(data_ref.uri)
    }
  }
  None
}

///|
fn warning_count(report : @data_core.ValidationReport) -> Int {
  let mut count = 0
  for finding in report.findings {
    if finding.severity == @data_core.FindingSeverity::WarningSeverity {
      count += 1
    }
  }
  count
}

///|
pub fn robot_model_catalog_dossier_from_root(
  root : String,
  model_id : @robot_data.RobotModelId,
) -> Result[RobotModelCatalogDossier, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset_id = model_dataset_id(model_id)
  let dataset_entry = match catalog_entry_for(catalog, "dataset", dataset_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-model-dataset-not-cataloged", dataset_id, "robot model package dataset is not present in the data catalog",
        ),
      )
  }
  let version_id = model_version_id(model_id)
  let version_entry = match
    catalog_entry_for(catalog, "dataset-version", version_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-model-version-not-cataloged", version_id, "robot model package version is not present in the data catalog",
        ),
      )
  }
  let dataset = match @data_store.read_dataset(root, dataset_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if dataset.source_ids.is_empty() {
    return Err(
      dossier_issue(
        "robot-model-source-missing", dataset_id, "robot model package dataset has no source id",
      ),
    )
  }
  let source_id = dataset.source_ids[0]
  let source_entry = match catalog_entry_for(catalog, "source", source_id) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-model-source-not-cataloged", source_id, "robot model package source is not present in the data catalog",
        ),
      )
  }
  let validation_entry = match latest_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-model-validation-not-cataloged", root, "robot model data root has no cataloged validation report",
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
  let urdf_uri = match urdf_ref_uri(dataset) {
    Some(value) => value
    None =>
      return Err(
        dossier_issue(
          "robot-model-urdf-ref-missing", dataset_id, "robot model package dataset has no URDF data ref",
        ),
      )
  }
  Ok({
    root,
    model_id,
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
    data_ref_count: dataset.data_refs.length(),
    data_ref_uris: data_ref_uris(dataset.data_refs),
    urdf_ref_uri: urdf_uri,
  })
}
