///|
pub(all) struct RobotModelPackageImportRequest {
  root : String
  source_dir : String
  model_id : @robot_data.RobotModelId
  robot_id : @robot_data.RobotId
  imported_at_ms : Int64
  source_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotModelPayload {
  source_path : String
  relative_path : String
  payload_path : String
  data_ref : @data_core.DataRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotModelPackageImportResult {
  root : String
  source_dir : String
  model_id : @robot_data.RobotModelId
  robot_id : @robot_data.RobotId
  urdf_payload_path : String
  asset_count : Int
  source : @data_core.DataSource
  dataset : @data_core.DatasetManifest
  version : @data_core.DatasetVersion
  payloads : Array[ImportedRobotModelPayload]
  materialization : RobotCatalogMaterialization
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_model_package_import_request(
  root : String,
  source_dir : String,
  model_id : @robot_data.RobotModelId,
  robot_id : @robot_data.RobotId,
  imported_at_ms : Int64,
  source_label? : String = "Robot model package import",
) -> RobotModelPackageImportRequest {
  { root, source_dir, model_id, robot_id, imported_at_ms, source_label }
}

///|
fn import_issue(
  code : String,
  path : String,
  message : String,
) -> @data_store.DataStoreIssue {
  { code, path, message }
}

///|
fn is_directory(path : String) -> Bool {
  @fsx.is_dir(path) catch {
    _ => false
  }
}

///|
fn read_sorted_names(
  path : String,
) -> Result[Array[String], @data_store.DataStoreIssue] {
  let names = @fsx.read_dir(path) catch {
    _ =>
      return Err(
        import_issue(
          "read-robot-model-dir", path, "failed to read robot model source directory",
        ),
      )
  }
  names.sort()
  Ok(names)
}

///|
fn collect_model_files(
  source_dir : String,
  relative_dir : String,
  files : Array[(String, String)],
) -> Result[Unit, @data_store.DataStoreIssue] {
  let dir = if relative_dir == "" {
    source_dir
  } else {
    join(source_dir, relative_dir)
  }
  let names = match read_sorted_names(dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  for name in names {
    let relative = if relative_dir == "" {
      name
    } else {
      relative_dir + "/" + name
    }
    if !@data_core.data_relative_path_is_safe(relative) {
      return Err(
        import_issue(
          "unsafe-robot-model-path", relative, "robot model source contains an unsafe relative path",
        ),
      )
    }
    let path = join(source_dir, relative)
    if is_directory(path) {
      match collect_model_files(source_dir, relative, files) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
    } else {
      files.push((path, relative))
    }
  }
  Ok(())
}

///|
fn validate_import_model_id(
  model_id : @robot_data.RobotModelId,
) -> Result[Unit, @data_store.DataStoreIssue] {
  if model_id == "" ||
    model_id.contains("/") ||
    model_id.contains("\\") ||
    model_id == "." ||
    model_id == ".." {
    Err(
      import_issue(
        "invalid-robot-model-id", model_id, "robot model id must be non-empty and path-safe",
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn safe_ref_segment(path : String) -> String {
  let out = StringBuilder()
  for char in path {
    if char.is_ascii_alphabetic() ||
      char.is_ascii_digit() ||
      char == '-' ||
      char == '_' {
      out.write_char(char)
    } else {
      out.write_char('-')
    }
  }
  let value = out.to_string()
  if value == "" {
    "asset"
  } else {
    value
  }
}

///|
fn model_asset_kind(relative_path : String) -> String {
  if relative_path.has_suffix(".urdf") {
    "urdf"
  } else if relative_path.has_suffix(".stl") {
    "stl"
  } else if relative_path.has_prefix("materials/") ||
    relative_path.contains("/materials/") ||
    relative_path.has_suffix(".mtl") {
    "material"
  } else {
    "robot-model-asset"
  }
}

///|
fn model_asset_content_type(relative_path : String) -> String {
  if relative_path.has_suffix(".urdf") {
    "application/xml"
  } else if relative_path.has_suffix(".json") {
    "application/json"
  } else if relative_path.has_suffix(".stl") {
    "model/stl"
  } else {
    "text/plain"
  }
}

///|
fn text_sum(body : String) -> @data_core.DeclaredChecksum {
  @data_core.declared_checksum(
    @data_core.ChecksumKind::TextSumV1,
    "text-sum-v1:bytes=\{body.length()}",
  )
}

///|
fn model_asset_data_ref(
  model_id : @robot_data.RobotModelId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/robot_models/\{model_id}/\{relative_path}"
  @data_core.data_ref(
    "robot-model-\{safe_ref_segment(model_id)}-\{safe_ref_segment(relative_path)}",
    model_asset_kind(relative_path),
    @data_core.data_uri(payload_path),
    content_type=model_asset_content_type(relative_path),
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
fn stage_text_data_ref(
  root : String,
  data_ref : @data_core.DataRef,
  body : String,
) -> Result[String, @data_store.DataStoreIssue] {
  let relative = match @data_core.data_payload_uri_relative_path(data_ref.uri) {
    Some(value) => value
    None =>
      return Err(
        import_issue(
          "unsafe-robot-model-payload-path",
          data_ref.uri,
          "robot model payload ref is not a safe data-root relative path",
        ),
      )
  }
  match ensure_payload_parent_dirs(root, relative) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let path = join(root, relative)
  @fsx.write_string_to_file(path, body) catch {
    _ =>
      return Err(
        import_issue(
          "write-robot-model-payload", path, "failed to write robot model payload",
        ),
      )
  }
  Ok(path)
}

///|
fn find_urdf_payload(
  payloads : Array[ImportedRobotModelPayload],
) -> ImportedRobotModelPayload? {
  let mut fallback : ImportedRobotModelPayload? = None
  for payload in payloads {
    if payload.relative_path.has_suffix(".urdf") {
      if payload.relative_path.has_suffix("robot.urdf") {
        return Some(payload)
      }
      fallback = match fallback {
        None => Some(payload)
        Some(value) => Some(value)
      }
    }
  }
  fallback
}

///|
fn write_robot_model_import_manifests(
  root : String,
  source : @data_core.DataSource,
  dataset : @data_core.DatasetManifest,
  version : @data_core.DatasetVersion,
  lineage : @data_core.LineageManifest,
) -> Result[Unit, @data_store.DataStoreIssue] {
  match @data_store.write_source(root, source) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match @data_store.write_dataset(root, dataset) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match @data_store.write_dataset_version(root, version) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match @data_store.write_lineage_manifest(root, lineage) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok(())
}

///|
pub fn import_robot_model_package(
  request : RobotModelPackageImportRequest,
) -> Result[RobotModelPackageImportResult, @data_store.DataStoreIssue] {
  match validate_import_model_id(request.model_id) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match @data_store.initialize_root(request.root) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let files : Array[(String, String)] = []
  match collect_model_files(request.source_dir, "", files) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  if files.length() == 0 {
    return Err(
      import_issue(
        "empty-robot-model-package",
        request.source_dir,
        "robot model source directory has no files",
      ),
    )
  }
  let payloads : Array[ImportedRobotModelPayload] = []
  for file in files {
    let (source_path, relative_path) = file
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-model-payload", source_path, "failed to read robot model payload as text",
          ),
        )
    }
    let data_ref = model_asset_data_ref(request.model_id, relative_path, body)
    let payload_path = match stage_text_data_ref(request.root, data_ref, body) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    payloads.push({ source_path, relative_path, payload_path, data_ref })
  }
  let urdf = match find_urdf_payload(payloads) {
    Some(value) => value
    None =>
      return Err(
        import_issue(
          "missing-robot-model-urdf",
          request.source_dir,
          "robot model package must include a .urdf file",
        ),
      )
  }
  let data_refs = payloads.map(fn(payload) { payload.data_ref })
  let source_id = "source-robot-model-\{request.model_id}"
  let dataset_id = "robot-model-package-\{request.model_id}"
  let source = @data_core.data_source(
    source_id,
    "Robot model package",
    request.source_label,
    request.source_dir,
    "local import",
    "Imported by Moonmoon robot_catalog",
    request.imported_at_ms,
    source_refs=[urdf.data_ref],
  )
  let dataset = @data_core.dataset_manifest(
    dataset_id,
    "robot-model-package",
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    source_ids=[source_id],
    data_refs~,
    summary="Robot model package for \{request.robot_id}",
  )
  let version = @data_core.dataset_version(
    "\{dataset_id}-v1",
    dataset_id,
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    data_refs~,
    summary="Initial robot model package import.",
  )
  let lineage = @data_core.lineage_manifest(
    "lineage-\{dataset_id}",
    @data_core.artifact_ref(
      "dataset",
      dataset_id,
      "datasets/\{dataset_id}.json",
      status=@data_core.DataStatus::Verified,
      summary=dataset.summary,
    ),
    request.imported_at_ms,
    edges=[
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source_id,
          "sources/\{source_id}.json",
          status=@data_core.DataStatus::Verified,
          summary=request.source_label,
        ),
        @data_core.artifact_ref(
          "dataset",
          dataset_id,
          "datasets/\{dataset_id}.json",
          status=@data_core.DataStatus::Verified,
          summary=dataset.summary,
        ),
        "robot-model-package-import",
      ),
    ],
  )
  match
    write_robot_model_import_manifests(
      request.root,
      source,
      dataset,
      version,
      lineage,
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match @data_store.rebuild_catalog(request.root, request.imported_at_ms) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let validation = match
    @data_validate.validate_and_write_root(request.root, request.imported_at_ms) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let catalog = match @data_store.read_catalog(request.root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    root: request.root,
    source_dir: request.source_dir,
    model_id: request.model_id,
    robot_id: request.robot_id,
    urdf_payload_path: urdf.payload_path,
    asset_count: payloads.length(),
    source,
    dataset,
    version,
    payloads,
    materialization: {
      root: request.root,
      catalog_path: validation.catalog_path,
      validation_report_path: validation.report_path,
      source_count: 1,
      dataset_count: 1,
      version_count: 1,
      lineage_count: 1,
      telemetry_stream_count: 0,
      gait_clip_count: 0,
      quality_report_count: 0,
      catalog_entry_count: catalog.entries.length(),
      validation_status: validation.status,
      blocker_count: validation.blocker_count,
      warning_count: validation.warning_count,
    },
  })
}
