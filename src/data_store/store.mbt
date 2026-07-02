///|
pub(all) struct DataStoreIssue {
  code : String
  path : String
  message : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DataStoreInit {
  root : String
  created_dir_count : Int
  directories : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PersistedManifest {
  artifact_kind : String
  artifact_id : String
  path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CatalogRebuild {
  root : String
  catalog_path : String
  generated_at_ms : Int64
  entry_count : Int
  catalog : @data_core.DataCatalog
} derive(Debug, Eq, ToJson, FromJson)

///|
fn issue(code : String, path : String, message : String) -> DataStoreIssue {
  { code, path, message }
}

///|
fn join(root : String, relative : String) -> String {
  if root.has_suffix("/") {
    root + relative
  } else {
    root + "/" + relative
  }
}

///|
pub fn source_path(root : String, source_id : @data_core.SourceId) -> String {
  join(root, "sources/\{source_id}.json")
}

///|
pub fn dataset_path(root : String, dataset_id : @data_core.DatasetId) -> String {
  join(root, "datasets/\{dataset_id}.json")
}

///|
pub fn dataset_version_path(
  root : String,
  version_id : @data_core.DatasetVersionId,
) -> String {
  join(root, "versions/\{version_id}.json")
}

///|
pub fn artifact_path(
  root : String,
  artifact_id : @data_core.ArtifactId,
) -> String {
  join(root, "artifacts/\{artifact_id}.json")
}

///|
pub fn lineage_path(root : String, lineage_id : @data_core.LineageId) -> String {
  join(root, "lineage/\{lineage_id}.json")
}

///|
pub fn validation_report_path(
  root : String,
  validation_report_id : @data_core.ValidationReportId,
) -> String {
  join(root, "validations/\{validation_report_id}.json")
}

///|
pub fn catalog_path(root : String) -> String {
  join(root, "indexes/catalog.json")
}

///|
fn ensure_dir(path : String) -> Result[Bool, DataStoreIssue] {
  if @fsx.path_exists(path) {
    Ok(false)
  } else {
    @fsx.create_dir(path) catch {
      _ =>
        return Err(
          issue("create-dir", path, "failed to create data store directory"),
        )
    }
    Ok(true)
  }
}

///|
pub fn initialize_root(root : String) -> Result[DataStoreInit, DataStoreIssue] {
  let dirs = [
    "", "sources", "datasets", "versions", "artifacts", "payloads", "lineage", "validations",
    "indexes",
  ]
  let created : Array[String] = []
  for relative in dirs {
    let path = if relative == "" { root } else { join(root, relative) }
    match ensure_dir(path) {
      Ok(value) => if value { created.push(path) }
      Err(error) => return Err(error)
    }
  }
  Ok({ root, created_dir_count: created.length(), directories: created })
}

///|
fn write_json(
  path : String,
  artifact_kind : String,
  artifact_id : String,
  body : Json,
) -> Result[PersistedManifest, DataStoreIssue] {
  @fsx.write_string_to_file(path, body.stringify(indent=2)) catch {
    _ =>
      return Err(
        issue("write-manifest", path, "failed to write data store manifest"),
      )
  }
  Ok({ artifact_kind, artifact_id, path })
}

///|
fn read_json(path : String) -> Result[Json, DataStoreIssue] {
  let text = @fsx.read_file_to_string(path) catch {
    _ =>
      return Err(
        issue("read-manifest", path, "failed to read data store manifest"),
      )
  }
  let json = @json.parse(text) catch {
    _ =>
      return Err(
        issue("parse-manifest", path, "failed to parse data store manifest"),
      )
  }
  Ok(json)
}

///|
pub fn write_source(
  root : String,
  source : @data_core.DataSource,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    source_path(root, source.source_id),
    "source",
    source.source_id,
    source.to_json(),
  )
}

///|
pub fn read_source(
  root : String,
  source_id : @data_core.SourceId,
) -> Result[@data_core.DataSource, DataStoreIssue] {
  let path = source_path(root, source_id)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let source : @data_core.DataSource = @json.from_json(json) catch {
    _ => return Err(issue("decode-source", path, "failed to decode source"))
  }
  Ok(source)
}

///|
pub fn write_dataset(
  root : String,
  dataset : @data_core.DatasetManifest,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    dataset_path(root, dataset.dataset_id),
    "dataset",
    dataset.dataset_id,
    dataset.to_json(),
  )
}

///|
pub fn read_dataset(
  root : String,
  dataset_id : @data_core.DatasetId,
) -> Result[@data_core.DatasetManifest, DataStoreIssue] {
  let path = dataset_path(root, dataset_id)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dataset : @data_core.DatasetManifest = @json.from_json(json) catch {
    _ => return Err(issue("decode-dataset", path, "failed to decode dataset"))
  }
  Ok(dataset)
}

///|
pub fn write_dataset_version(
  root : String,
  version : @data_core.DatasetVersion,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    dataset_version_path(root, version.version_id),
    "dataset-version",
    version.version_id,
    version.to_json(),
  )
}

///|
pub fn read_dataset_version(
  root : String,
  version_id : @data_core.DatasetVersionId,
) -> Result[@data_core.DatasetVersion, DataStoreIssue] {
  let path = dataset_version_path(root, version_id)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let version : @data_core.DatasetVersion = @json.from_json(json) catch {
    _ =>
      return Err(
        issue(
          "decode-dataset-version", path, "failed to decode dataset version",
        ),
      )
  }
  Ok(version)
}

///|
pub fn write_artifact_ref(
  root : String,
  artifact : @data_core.ArtifactRef,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    artifact_path(root, artifact.artifact_id),
    artifact.artifact_kind,
    artifact.artifact_id,
    artifact.to_json(),
  )
}

///|
pub fn read_artifact_ref(
  root : String,
  artifact_id : @data_core.ArtifactId,
) -> Result[@data_core.ArtifactRef, DataStoreIssue] {
  let path = artifact_path(root, artifact_id)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let artifact : @data_core.ArtifactRef = @json.from_json(json) catch {
    _ => return Err(issue("decode-artifact", path, "failed to decode artifact"))
  }
  Ok(artifact)
}

///|
pub fn write_lineage_manifest(
  root : String,
  lineage : @data_core.LineageManifest,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    lineage_path(root, lineage.lineage_id),
    "lineage",
    lineage.lineage_id,
    lineage.to_json(),
  )
}

///|
pub fn read_lineage_manifest(
  root : String,
  lineage_id : @data_core.LineageId,
) -> Result[@data_core.LineageManifest, DataStoreIssue] {
  let path = lineage_path(root, lineage_id)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let lineage : @data_core.LineageManifest = @json.from_json(json) catch {
    _ => return Err(issue("decode-lineage", path, "failed to decode lineage"))
  }
  Ok(lineage)
}

///|
pub fn write_validation_report(
  root : String,
  report : @data_core.ValidationReport,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    validation_report_path(root, report.validation_report_id),
    "validation-report",
    report.validation_report_id,
    report.to_json(),
  )
}

///|
pub fn read_validation_report(
  root : String,
  validation_report_id : @data_core.ValidationReportId,
) -> Result[@data_core.ValidationReport, DataStoreIssue] {
  let path = validation_report_path(root, validation_report_id)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let report : @data_core.ValidationReport = @json.from_json(json) catch {
    _ =>
      return Err(
        issue(
          "decode-validation-report", path, "failed to decode validation report",
        ),
      )
  }
  Ok(report)
}

///|
pub fn write_catalog(
  root : String,
  catalog : @data_core.DataCatalog,
) -> Result[PersistedManifest, DataStoreIssue] {
  write_json(
    catalog_path(root),
    "catalog",
    catalog.catalog_id,
    catalog.to_json(),
  )
}

///|
pub fn read_catalog(
  root : String,
) -> Result[@data_core.DataCatalog, DataStoreIssue] {
  let path = catalog_path(root)
  let json = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let catalog : @data_core.DataCatalog = @json.from_json(json) catch {
    _ => return Err(issue("decode-catalog", path, "failed to decode catalog"))
  }
  Ok(catalog)
}
