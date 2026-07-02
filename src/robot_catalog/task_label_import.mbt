///|
pub(all) struct RobotTaskLabelDirectoryImportRequest {
  root : String
  source_dir : String
  task_label_id : @robot_data.RobotTaskLabelId
  episode_id : @robot_data.RobotEpisodeId
  alignment_id : @robot_data.RobotGaitAlignmentId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  imported_at_ms : Int64
  source_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotTaskLabelPayload {
  source_path : String
  relative_path : String
  payload_path : String
  task_label : @robot_data.RobotTaskLabelPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotTaskLabelDirectoryImportResult {
  root : String
  source_dir : String
  task_label_id : @robot_data.RobotTaskLabelId
  episode_id : @robot_data.RobotEpisodeId
  alignment_id : @robot_data.RobotGaitAlignmentId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  payload_count : Int
  task_label : @robot_data.RobotTaskLabelManifest
  payloads : Array[ImportedRobotTaskLabelPayload]
  materialization : RobotCatalogMaterialization
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_task_label_directory_import_request(
  root : String,
  source_dir : String,
  task_label_id : @robot_data.RobotTaskLabelId,
  episode_id : @robot_data.RobotEpisodeId,
  alignment_id : @robot_data.RobotGaitAlignmentId,
  robot_id : @robot_data.RobotId,
  model_id : @robot_data.RobotModelId,
  imported_at_ms : Int64,
  source_label? : String = "Robot task label directory import",
) -> RobotTaskLabelDirectoryImportRequest {
  {
    root,
    source_dir,
    task_label_id,
    episode_id,
    alignment_id,
    robot_id,
    model_id,
    imported_at_ms,
    source_label,
  }
}

///|
fn task_label_source_files(
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
          "unsafe-robot-task-label-path", name, "robot task label source contains an unsafe relative path",
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
fn task_label_content_type(relative_path : String) -> String {
  if relative_path.has_suffix(".json") {
    "application/json"
  } else if relative_path.has_suffix(".csv") {
    "text/csv"
  } else {
    "text/plain"
  }
}

///|
fn task_label_role(relative_path : String) -> String {
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
fn task_label_line_count(body : String) -> Int {
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
fn task_label_payload_data_ref(
  task_label_id : @robot_data.RobotTaskLabelId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/task_labels/\{task_label_id}/\{relative_path}"
  @data_core.data_ref(
    "robot-task-label-\{safe_ref_segment(task_label_id)}-\{safe_ref_segment(relative_path)}",
    "robot-task-label",
    @data_core.data_uri(payload_path),
    content_type=task_label_content_type(relative_path),
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
pub fn import_robot_task_label_directory(
  request : RobotTaskLabelDirectoryImportRequest,
) -> Result[RobotTaskLabelDirectoryImportResult, @data_store.DataStoreIssue] {
  match
    validate_episode_import_id(request.task_label_id, "robot-task-label-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match validate_episode_import_id(request.episode_id, "robot-episode-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match
    validate_episode_import_id(request.alignment_id, "robot-gait-alignment-id") {
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
    robot_gait_alignment_catalog_dossier_from_root(
      request.root,
      request.alignment_id,
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let files = match task_label_source_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if files.length() == 0 {
    return Err(
      import_issue(
        "empty-robot-task-label-directory",
        request.source_dir,
        "robot task label source directory has no file payloads",
      ),
    )
  }
  let payloads : Array[ImportedRobotTaskLabelPayload] = []
  for index in 0..<files.length() {
    let (source_path, relative_path) = files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-task-label-payload", source_path, "failed to read robot task label payload as text",
          ),
        )
    }
    let data_ref = task_label_payload_data_ref(
      request.task_label_id,
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
    let task_label = @robot_data.robot_task_label_payload_ref(
      task_label_role(relative_path),
      task_label_line_count(body),
      payload,
    )
    payloads.push({ source_path, relative_path, payload_path, task_label })
  }
  let task_label = @robot_data.robot_task_label_manifest(
    request.task_label_id,
    request.robot_id,
    request.episode_id,
    request.alignment_id,
    "source-robot-task-label-\{request.task_label_id}",
    request.source_label,
    request.source_dir,
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    [model],
    payloads.map(fn(payload) { payload.task_label }),
    "Robot task labels for \{request.episode_id}",
  )
  match write_task_labels(request.root, [task_label]) {
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
    task_label_id: request.task_label_id,
    episode_id: request.episode_id,
    alignment_id: request.alignment_id,
    robot_id: request.robot_id,
    model_id: request.model_id,
    payload_count: payloads.length(),
    task_label,
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
      gait_alignment_count: 0,
      task_label_count: 1,
      quality_report_count: 0,
      catalog_entry_count: catalog.entries.length(),
      validation_status: validation.status,
      blocker_count: validation.blocker_count,
      warning_count: validation.warning_count,
    },
  })
}
