///|
fn catalog_issue(
  code : String,
  path : String,
  message : String,
) -> DataStoreIssue {
  { code, path, message }
}

///|
fn catalog_join(root : String, relative : String) -> String {
  if root.has_suffix("/") {
    root + relative
  } else {
    root + "/" + relative
  }
}

///|
fn decode_catalog_entry(
  path : String,
  artifact_kind : String,
  json : Json,
) -> Result[@data_core.CatalogEntry, DataStoreIssue] {
  match artifact_kind {
    "source" => {
      let value : @data_core.DataSource = @json.from_json(json) catch {
        _ =>
          return Err(
            catalog_issue("decode-source", path, "failed to decode source"),
          )
      }
      Ok(
        @data_core.catalog_entry(
          "source",
          value.source_id,
          path,
          status=@data_core.DataStatus::Verified,
          summary=value.label,
        ),
      )
    }
    "dataset" => {
      let value : @data_core.DatasetManifest = @json.from_json(json) catch {
        _ =>
          return Err(
            catalog_issue("decode-dataset", path, "failed to decode dataset"),
          )
      }
      Ok(
        @data_core.catalog_entry(
          "dataset",
          value.dataset_id,
          path,
          status=value.status,
          summary=value.summary,
        ),
      )
    }
    "dataset-version" => {
      let value : @data_core.DatasetVersion = @json.from_json(json) catch {
        _ =>
          return Err(
            catalog_issue(
              "decode-dataset-version", path, "failed to decode dataset version",
            ),
          )
      }
      Ok(
        @data_core.catalog_entry(
          "dataset-version",
          value.version_id,
          path,
          status=value.status,
          summary=value.summary,
        ),
      )
    }
    "artifact" => {
      let value : @data_core.ArtifactRef = @json.from_json(json) catch {
        _ =>
          return Err(
            catalog_issue("decode-artifact", path, "failed to decode artifact"),
          )
      }
      Ok(
        @data_core.catalog_entry(
          value.artifact_kind,
          value.artifact_id,
          path,
          status=value.status,
          summary=value.summary,
        ),
      )
    }
    "lineage" => {
      let value : @data_core.LineageManifest = @json.from_json(json) catch {
        _ =>
          return Err(
            catalog_issue("decode-lineage", path, "failed to decode lineage"),
          )
      }
      Ok(
        @data_core.catalog_entry(
          "lineage",
          value.lineage_id,
          path,
          status=@data_core.DataStatus::Verified,
          summary=value.root_artifact.summary,
        ),
      )
    }
    "validation-report" => {
      let value : @data_core.ValidationReport = @json.from_json(json) catch {
        _ =>
          return Err(
            catalog_issue(
              "decode-validation-report", path, "failed to decode validation report",
            ),
          )
      }
      Ok(
        @data_core.catalog_entry(
          "validation-report",
          value.validation_report_id,
          path,
          status=match value.status {
            Passed => @data_core.DataStatus::Verified
            Warning => @data_core.DataStatus::Curated
            BlockedValidation => @data_core.DataStatus::Blocked
          },
          summary="\{@data_core.validation_finding_count(value)} finding(s)",
        ),
      )
    }
    _ =>
      Err(catalog_issue("unknown-manifest-kind", path, "unknown manifest kind"))
  }
}

///|
fn read_manifest_json(path : String) -> Result[Json, DataStoreIssue] {
  let text = @fsx.read_file_to_string(path) catch {
    _ =>
      return Err(
        catalog_issue("read-manifest", path, "failed to read data manifest"),
      )
  }
  let json = @json.parse(text) catch {
    _ =>
      return Err(
        catalog_issue("parse-manifest", path, "failed to parse data manifest"),
      )
  }
  Ok(json)
}

///|
fn collect_entries(
  root : String,
  dir_name : String,
  artifact_kind : String,
  entries : Array[@data_core.CatalogEntry],
) -> Result[Unit, DataStoreIssue] {
  let dir = catalog_join(root, dir_name)
  if !@fsx.path_exists(dir) {
    return Ok(())
  }
  let names = @fsx.read_dir(dir) catch {
    _ =>
      return Err(
        catalog_issue(
          "read-manifest-dir", dir, "failed to read manifest directory",
        ),
      )
  }
  names.sort()
  for name in names {
    if name.has_suffix(".json") {
      let path = catalog_join(dir, name)
      let json = match read_manifest_json(path) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match decode_catalog_entry(path, artifact_kind, json) {
        Ok(entry) => entries.push(entry)
        Err(error) => return Err(error)
      }
    }
  }
  Ok(())
}

///|
pub fn rebuild_catalog(
  root : String,
  generated_at_ms : Int64,
) -> Result[CatalogRebuild, DataStoreIssue] {
  let entries : Array[@data_core.CatalogEntry] = []
  match collect_entries(root, "sources", "source", entries) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match collect_entries(root, "datasets", "dataset", entries) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match collect_entries(root, "versions", "dataset-version", entries) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match collect_entries(root, "artifacts", "artifact", entries) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match collect_entries(root, "lineage", "lineage", entries) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match collect_entries(root, "validations", "validation-report", entries) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let catalog = @data_core.data_catalog(root, generated_at_ms, entries)
  match write_catalog(root, catalog) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok({
    root,
    catalog_path: catalog_path(root),
    generated_at_ms,
    entry_count: entries.length(),
    catalog,
  })
}
