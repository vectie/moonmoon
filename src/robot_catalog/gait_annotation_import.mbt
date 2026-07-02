///|
pub(all) struct RobotGaitAnnotationDirectoryImportRequest {
  root : String
  source_dir : String
  annotation_id : @robot_data.RobotGaitAnnotationId
  clip_id : @robot_data.RobotGaitClipId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  imported_at_ms : Int64
  source_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotGaitAnnotationPayload {
  source_path : String
  relative_path : String
  payload_path : String
  annotation : @robot_data.RobotGaitAnnotationPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotGaitAnnotationDirectoryImportResult {
  root : String
  source_dir : String
  annotation_id : @robot_data.RobotGaitAnnotationId
  clip_id : @robot_data.RobotGaitClipId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  payload_count : Int
  gait_annotation : @robot_data.RobotGaitAnnotationManifest
  payloads : Array[ImportedRobotGaitAnnotationPayload]
  materialization : RobotCatalogMaterialization
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_gait_annotation_directory_import_request(
  root : String,
  source_dir : String,
  annotation_id : @robot_data.RobotGaitAnnotationId,
  clip_id : @robot_data.RobotGaitClipId,
  robot_id : @robot_data.RobotId,
  model_id : @robot_data.RobotModelId,
  imported_at_ms : Int64,
  source_label? : String = "Robot gait annotation directory import",
) -> RobotGaitAnnotationDirectoryImportRequest {
  {
    root,
    source_dir,
    annotation_id,
    clip_id,
    robot_id,
    model_id,
    imported_at_ms,
    source_label,
  }
}

///|
fn gait_annotation_source_files(
  source_dir : String,
) -> Result[Array[(String, String)], @data_store.DataStoreIssue] {
  let names = match read_sorted_names(source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let files : Array[(String, String)] = []
  for name in names {
    if !@data_core.data_relative_path_is_safe(name) {
      return Err(
        import_issue(
          "unsafe-robot-gait-annotation-path", name, "robot gait annotation source contains an unsafe relative path",
        ),
      )
    }
    let path = join(source_dir, name)
    if !is_directory(path) {
      files.push((path, name))
    }
  }
  Ok(files)
}

///|
fn gait_annotation_content_type(relative_path : String) -> String {
  if relative_path.has_suffix(".json") {
    "application/json"
  } else if relative_path.has_suffix(".csv") {
    "text/csv"
  } else {
    "text/plain"
  }
}

///|
fn gait_annotation_role(relative_path : String) -> String {
  let mut value = relative_path
  if value.has_suffix(".json") {
    value = value[0:value.length() - 5].to_owned()
  } else if value.has_suffix(".csv") {
    value = value[0:value.length() - 4].to_owned()
  } else if value.has_suffix(".txt") {
    value = value[0:value.length() - 4].to_owned()
  }
  value
}

///|
fn annotation_line_count(body : String) -> Int {
  if body.length() == 0 {
    0
  } else {
    let mut count = 1
    for char in body {
      if char == '\n' {
        count += 1
      }
    }
    count
  }
}

///|
fn gait_annotation_payload_data_ref(
  annotation_id : @robot_data.RobotGaitAnnotationId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/gait_annotations/\{annotation_id}/\{relative_path}"
  @data_core.data_ref(
    "robot-gait-annotation-\{safe_ref_segment(annotation_id)}-\{safe_ref_segment(relative_path)}",
    "robot-gait-annotation",
    @data_core.data_uri(payload_path),
    content_type=gait_annotation_content_type(relative_path),
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
pub fn import_robot_gait_annotation_directory(
  request : RobotGaitAnnotationDirectoryImportRequest,
) -> Result[
  RobotGaitAnnotationDirectoryImportResult,
  @data_store.DataStoreIssue,
] {
  match
    validate_episode_import_id(
      request.annotation_id,
      "robot-gait-annotation-id",
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match validate_episode_import_id(request.clip_id, "robot-gait-clip-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let model_dossier = match
    robot_model_catalog_dossier_from_root(request.root, request.model_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let model = match model_ref_from_dossier(model_dossier, request.robot_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match
    robot_gait_clip_catalog_dossier_from_root(request.root, request.clip_id) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let files = match gait_annotation_source_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if files.length() == 0 {
    return Err(
      import_issue(
        "empty-robot-gait-annotation-directory",
        request.source_dir,
        "robot gait annotation source directory has no file payloads",
      ),
    )
  }
  let payloads : Array[ImportedRobotGaitAnnotationPayload] = []
  for index in 0..<files.length() {
    let (source_path, relative_path) = files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-gait-annotation-payload", source_path, "failed to read robot gait annotation payload as text",
          ),
        )
    }
    let data_ref = gait_annotation_payload_data_ref(
      request.annotation_id,
      relative_path,
      body,
    )
    let payload_path = match stage_text_data_ref(request.root, data_ref, body) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let payload = match payload_from_data_ref(data_ref) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let annotation = @robot_data.robot_gait_annotation_payload_ref(
      gait_annotation_role(relative_path),
      annotation_line_count(body),
      payload,
    )
    payloads.push({ source_path, relative_path, payload_path, annotation })
  }
  let gait_annotation = @robot_data.robot_gait_annotation_manifest(
    request.annotation_id,
    request.robot_id,
    request.clip_id,
    "source-robot-gait-annotation-\{request.annotation_id}",
    request.source_label,
    request.source_dir,
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    [model],
    payloads.map(fn(payload) { payload.annotation }),
    "Robot gait annotation for \{request.clip_id}",
  )
  match write_gait_annotations(request.root, [gait_annotation]) {
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
    annotation_id: request.annotation_id,
    clip_id: request.clip_id,
    robot_id: request.robot_id,
    model_id: request.model_id,
    payload_count: payloads.length(),
    gait_annotation,
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
      gait_annotation_count: 1,
      quality_report_count: 0,
      catalog_entry_count: catalog.entries.length(),
      validation_status: validation.status,
      blocker_count: validation.blocker_count,
      warning_count: validation.warning_count,
    },
  })
}
