///|
pub(all) struct RobotGaitAlignmentDirectoryImportRequest {
  root : String
  source_dir : String
  alignment_id : @robot_data.RobotGaitAlignmentId
  episode_id : @robot_data.RobotEpisodeId
  clip_id : @robot_data.RobotGaitClipId
  annotation_id : @robot_data.RobotGaitAnnotationId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  imported_at_ms : Int64
  source_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotGaitAlignmentPayload {
  source_path : String
  relative_path : String
  payload_path : String
  alignment : @robot_data.RobotGaitAlignmentPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotGaitAlignmentDirectoryImportResult {
  root : String
  source_dir : String
  alignment_id : @robot_data.RobotGaitAlignmentId
  episode_id : @robot_data.RobotEpisodeId
  clip_id : @robot_data.RobotGaitClipId
  annotation_id : @robot_data.RobotGaitAnnotationId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  payload_count : Int
  gait_alignment : @robot_data.RobotGaitAlignmentManifest
  payloads : Array[ImportedRobotGaitAlignmentPayload]
  materialization : RobotCatalogMaterialization
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_gait_alignment_directory_import_request(
  root : String,
  source_dir : String,
  alignment_id : @robot_data.RobotGaitAlignmentId,
  episode_id : @robot_data.RobotEpisodeId,
  clip_id : @robot_data.RobotGaitClipId,
  annotation_id : @robot_data.RobotGaitAnnotationId,
  robot_id : @robot_data.RobotId,
  model_id : @robot_data.RobotModelId,
  imported_at_ms : Int64,
  source_label? : String = "Robot gait alignment directory import",
) -> RobotGaitAlignmentDirectoryImportRequest {
  {
    root,
    source_dir,
    alignment_id,
    episode_id,
    clip_id,
    annotation_id,
    robot_id,
    model_id,
    imported_at_ms,
    source_label,
  }
}

///|
fn gait_alignment_source_files(
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
          "unsafe-robot-gait-alignment-path", name, "robot gait alignment source contains an unsafe relative path",
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
fn gait_alignment_content_type(relative_path : String) -> String {
  if relative_path.has_suffix(".json") {
    "application/json"
  } else if relative_path.has_suffix(".csv") {
    "text/csv"
  } else {
    "text/plain"
  }
}

///|
fn gait_alignment_role(relative_path : String) -> String {
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
fn alignment_line_count(body : String) -> Int {
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
fn gait_alignment_payload_data_ref(
  alignment_id : @robot_data.RobotGaitAlignmentId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/gait_alignments/\{alignment_id}/\{relative_path}"
  @data_core.data_ref(
    "robot-gait-alignment-\{safe_ref_segment(alignment_id)}-\{safe_ref_segment(relative_path)}",
    "robot-gait-alignment",
    @data_core.data_uri(payload_path),
    content_type=gait_alignment_content_type(relative_path),
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
pub fn import_robot_gait_alignment_directory(
  request : RobotGaitAlignmentDirectoryImportRequest,
) -> Result[RobotGaitAlignmentDirectoryImportResult, @data_store.DataStoreIssue] {
  match
    validate_episode_import_id(request.alignment_id, "robot-gait-alignment-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match validate_episode_import_id(request.episode_id, "robot-episode-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match validate_episode_import_id(request.clip_id, "robot-gait-clip-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match
    validate_episode_import_id(
      request.annotation_id,
      "robot-gait-annotation-id",
    ) {
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
    robot_episode_catalog_dossier_from_root(request.root, request.episode_id) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match
    robot_gait_clip_catalog_dossier_from_root(request.root, request.clip_id) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match
    robot_gait_annotation_catalog_dossier_from_root(
      request.root,
      request.annotation_id,
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let files = match gait_alignment_source_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if files.length() == 0 {
    return Err(
      import_issue(
        "empty-robot-gait-alignment-directory",
        request.source_dir,
        "robot gait alignment source directory has no file payloads",
      ),
    )
  }
  let payloads : Array[ImportedRobotGaitAlignmentPayload] = []
  for index in 0..<files.length() {
    let (source_path, relative_path) = files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-gait-alignment-payload", source_path, "failed to read robot gait alignment payload as text",
          ),
        )
    }
    let data_ref = gait_alignment_payload_data_ref(
      request.alignment_id,
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
    let alignment = @robot_data.robot_gait_alignment_payload_ref(
      gait_alignment_role(relative_path),
      alignment_line_count(body),
      payload,
    )
    payloads.push({ source_path, relative_path, payload_path, alignment })
  }
  let gait_alignment = @robot_data.robot_gait_alignment_manifest(
    request.alignment_id,
    request.robot_id,
    request.episode_id,
    request.clip_id,
    request.annotation_id,
    "source-robot-gait-alignment-\{request.alignment_id}",
    request.source_label,
    request.source_dir,
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    [model],
    payloads.map(fn(payload) { payload.alignment }),
    "Robot gait alignment for \{request.episode_id} and \{request.clip_id}",
  )
  match write_gait_alignments(request.root, [gait_alignment]) {
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
    alignment_id: request.alignment_id,
    episode_id: request.episode_id,
    clip_id: request.clip_id,
    annotation_id: request.annotation_id,
    robot_id: request.robot_id,
    model_id: request.model_id,
    payload_count: payloads.length(),
    gait_alignment,
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
      gait_annotation_count: 0,
      gait_alignment_count: 1,
      quality_report_count: 0,
      catalog_entry_count: catalog.entries.length(),
      validation_status: validation.status,
      blocker_count: validation.blocker_count,
      warning_count: validation.warning_count,
    },
  })
}
