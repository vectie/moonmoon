///|
pub(all) struct RobotTelemetryDirectoryImportRequest {
  root : String
  source_dir : String
  stream_id : @robot_data.RobotTelemetryStreamId
  robot_id : @robot_data.RobotId
  session_id : String
  imported_at_ms : Int64
  source_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotTelemetryPayload {
  source_path : String
  relative_path : String
  payload_path : String
  telemetry : @robot_data.RobotTelemetryPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotTelemetryDirectoryImportResult {
  root : String
  source_dir : String
  stream_id : @robot_data.RobotTelemetryStreamId
  robot_id : @robot_data.RobotId
  session_id : String
  payload_count : Int
  stream : @robot_data.RobotTelemetryStreamManifest
  payloads : Array[ImportedRobotTelemetryPayload]
  materialization : RobotCatalogMaterialization
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_telemetry_directory_import_request(
  root : String,
  source_dir : String,
  stream_id : @robot_data.RobotTelemetryStreamId,
  robot_id : @robot_data.RobotId,
  session_id : String,
  imported_at_ms : Int64,
  source_label? : String = "Robot telemetry directory import",
) -> RobotTelemetryDirectoryImportRequest {
  {
    root,
    source_dir,
    stream_id,
    robot_id,
    session_id,
    imported_at_ms,
    source_label,
  }
}

///|
fn telemetry_source_files(
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
          "unsafe-robot-telemetry-path", name, "robot telemetry source contains an unsafe relative path",
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
fn telemetry_content_type(relative_path : String) -> String {
  if relative_path.has_suffix(".json") {
    "application/json"
  } else if relative_path.has_suffix(".csv") {
    "text/csv"
  } else {
    "text/plain"
  }
}

///|
fn telemetry_channel(relative_path : String) -> String {
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
fn telemetry_payload_data_ref(
  stream_id : @robot_data.RobotTelemetryStreamId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/telemetry/\{stream_id}/\{relative_path}"
  @data_core.data_ref(
    "robot-telemetry-\{safe_ref_segment(stream_id)}-\{safe_ref_segment(relative_path)}",
    "robot-telemetry-sample",
    @data_core.data_uri(payload_path),
    content_type=telemetry_content_type(relative_path),
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
pub fn import_robot_telemetry_directory(
  request : RobotTelemetryDirectoryImportRequest,
) -> Result[RobotTelemetryDirectoryImportResult, @data_store.DataStoreIssue] {
  match
    validate_episode_import_id(request.stream_id, "robot-telemetry-stream-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match @data_store.initialize_root(request.root) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let files = match telemetry_source_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if files.length() == 0 {
    return Err(
      import_issue(
        "empty-robot-telemetry-directory",
        request.source_dir,
        "robot telemetry source directory has no file payloads",
      ),
    )
  }
  let payloads : Array[ImportedRobotTelemetryPayload] = []
  for index in 0..<files.length() {
    let (source_path, relative_path) = files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-telemetry-payload", source_path, "failed to read robot telemetry payload as text",
          ),
        )
    }
    let data_ref = telemetry_payload_data_ref(
      request.stream_id,
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
    let telemetry = @robot_data.robot_telemetry_payload_ref(
      telemetry_channel(relative_path),
      1,
      "payload",
      payload,
    )
    payloads.push({ source_path, relative_path, payload_path, telemetry })
  }
  let stream = @robot_data.robot_telemetry_stream_manifest(
    request.stream_id,
    request.robot_id,
    request.session_id,
    "source-robot-telemetry-\{request.stream_id}",
    request.source_label,
    request.source_dir,
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    payloads.map(fn(payload) { payload.telemetry }),
    "Robot telemetry stream for \{request.robot_id}",
  )
  match write_telemetry_streams(request.root, [stream]) {
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
    stream_id: request.stream_id,
    robot_id: request.robot_id,
    session_id: request.session_id,
    payload_count: payloads.length(),
    stream,
    payloads,
    materialization: {
      root: request.root,
      catalog_path: validation.catalog_path,
      validation_report_path: validation.report_path,
      source_count: 1,
      dataset_count: 1,
      version_count: 1,
      lineage_count: 1,
      telemetry_stream_count: 1,
      gait_clip_count: 0,
      gait_annotation_count: 0,
      gait_alignment_count: 0,
      quality_report_count: 0,
      catalog_entry_count: catalog.entries.length(),
      validation_status: validation.status,
      blocker_count: validation.blocker_count,
      warning_count: validation.warning_count,
    },
  })
}
