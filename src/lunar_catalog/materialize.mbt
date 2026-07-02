///|
pub(all) struct FirstTrustedSquareCatalogMaterialization {
  root : String
  catalog_path : String
  validation_report_path : String
  source_count : Int
  dataset_count : Int
  catalog_entry_count : Int
  validation_status : @data_core.ValidationStatus
  blocker_count : Int
  warning_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
fn issue(
  code : String,
  path : String,
  message : String,
) -> @data_store.DataStoreIssue {
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
fn ensure_dir(path : String) -> Result[Unit, @data_store.DataStoreIssue] {
  if @fsx.path_exists(path) {
    Ok(())
  } else {
    @fsx.create_dir(path) catch {
      _ =>
        return Err(
          issue("create-dir", path, "failed to create lunar catalog directory"),
        )
    }
    Ok(())
  }
}

///|
fn copy_text_payload(
  root : String,
  relative_path : String,
) -> Result[Unit, @data_store.DataStoreIssue] {
  let source_path = "data/" + relative_path
  let body = @fsx.read_file_to_string(source_path) catch {
    _ =>
      return Err(
        issue(
          "read-payload", source_path, "failed to read lunar source payload",
        ),
      )
  }
  let target_path = join(root, relative_path)
  @fsx.write_string_to_file(target_path, body) catch {
    _ =>
      return Err(
        issue(
          "write-payload", target_path, "failed to write lunar catalog payload",
        ),
      )
  }
  Ok(())
}

///|
fn prepare_payload_dirs(
  root : String,
) -> Result[Unit, @data_store.DataStoreIssue] {
  match ensure_dir(join(root, "sources/lro_lola")) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match ensure_dir(join(root, "sources/lunar_ephemeris")) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok(())
}

///|
fn payload_refs_from_source(
  source : @data_core.DataSource,
) -> Array[@data_core.DataRef] {
  source.source_refs
}

///|
fn copy_ref_payloads(
  root : String,
  refs : Array[@data_core.DataRef],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for data_ref in refs {
    match @data_core.data_payload_uri_relative_path(data_ref.uri) {
      Some(relative_path) =>
        match copy_text_payload(root, relative_path) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      None =>
        return Err(
          issue(
            "unsafe-data-ref",
            data_ref.uri,
            "lunar catalog payload ref is not a safe local data URI",
          ),
        )
    }
  }
  Ok(())
}

///|
fn copy_first_trusted_square_payloads(
  root : String,
  sources : Array[@data_core.DataSource],
  datasets : Array[@data_core.DatasetManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  match prepare_payload_dirs(root) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  for source in sources {
    match copy_ref_payloads(root, payload_refs_from_source(source)) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  for dataset in datasets {
    match copy_ref_payloads(root, dataset.data_refs) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
pub fn materialize_first_trusted_square_catalog(
  root : String,
  generated_at_ms : Int64,
) -> Result[
  FirstTrustedSquareCatalogMaterialization,
  @data_store.DataStoreIssue,
] {
  match @data_store.initialize_root(root) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let sources = @lunar_data.first_trusted_square_lunar_sources()
  let datasets = @lunar_data.first_trusted_square_lunar_datasets()
  match copy_first_trusted_square_payloads(root, sources, datasets) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  for source in sources {
    match @data_store.write_source(root, source) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  for dataset in datasets {
    match @data_store.write_dataset(root, dataset) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  match @data_store.rebuild_catalog(root, generated_at_ms) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let validation = match
    @data_validate.validate_and_write_root(root, generated_at_ms) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    root,
    catalog_path: validation.catalog_path,
    validation_report_path: validation.report_path,
    source_count: sources.length(),
    dataset_count: datasets.length(),
    catalog_entry_count: catalog.entries.length(),
    validation_status: validation.status,
    blocker_count: validation.blocker_count,
    warning_count: validation.warning_count,
  })
}
