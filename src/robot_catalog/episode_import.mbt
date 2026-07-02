///|
pub(all) struct RobotEpisodeDirectoryImportRequest {
  root : String
  source_dir : String
  dataset_id : @data_core.DatasetId
  episode_id : @robot_data.RobotEpisodeId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  imported_at_ms : Int64
  source_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotEpisodeSignal {
  source_path : String
  relative_path : String
  payload_path : String
  signal : @robot_data.RobotSignalRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotEpisodeReplay {
  source_path : String
  relative_path : String
  payload_path : String
  replay : @robot_data.RobotReplayArtifact
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ImportedRobotEpisodeQuality {
  source_path : String
  relative_path : String
  payload_path : String
  payload : @robot_data.RobotPayloadRef
  report : @robot_data.RobotQualityReport
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotEpisodeDirectoryImportResult {
  root : String
  source_dir : String
  dataset_id : @data_core.DatasetId
  episode_id : @robot_data.RobotEpisodeId
  robot_id : @robot_data.RobotId
  model_id : @robot_data.RobotModelId
  signal_count : Int
  replay_count : Int
  quality_report_count : Int
  episode : @robot_data.RobotEpisodeManifest
  signals : Array[ImportedRobotEpisodeSignal]
  replays : Array[ImportedRobotEpisodeReplay]
  quality_reports : Array[ImportedRobotEpisodeQuality]
  materialization : RobotCatalogMaterialization
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_episode_directory_import_request(
  root : String,
  source_dir : String,
  dataset_id : @data_core.DatasetId,
  episode_id : @robot_data.RobotEpisodeId,
  robot_id : @robot_data.RobotId,
  model_id : @robot_data.RobotModelId,
  imported_at_ms : Int64,
  source_label? : String = "Robot episode directory import",
) -> RobotEpisodeDirectoryImportRequest {
  {
    root,
    source_dir,
    dataset_id,
    episode_id,
    robot_id,
    model_id,
    imported_at_ms,
    source_label,
  }
}

///|
fn validate_episode_import_id(
  value : String,
  kind : String,
) -> Result[Unit, @data_store.DataStoreIssue] {
  if value == "" ||
    value.contains("/") ||
    value.contains("\\") ||
    value == "." ||
    value == ".." {
    Err(
      import_issue(
        "invalid-\{kind}",
        value,
        "\{kind} must be non-empty and path-safe",
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn episode_source_files(
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
          "unsafe-robot-episode-path", name, "robot episode source contains an unsafe relative path",
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
fn episode_replay_files(
  source_dir : String,
) -> Result[Array[(String, String)], @data_store.DataStoreIssue] {
  let replay_dir = join(source_dir, "replays")
  if !@fsx.path_exists(replay_dir) {
    return Ok([])
  }
  let names = match read_sorted_names(replay_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let files : Array[(String, String)] = []
  for name in names {
    if !@data_core.data_relative_path_is_safe(name) {
      return Err(
        import_issue(
          "unsafe-robot-replay-path", name, "robot replay source contains an unsafe relative path",
        ),
      )
    }
    let path = join(replay_dir, name)
    if !is_directory(path) {
      files.push((path, name))
    }
  }
  Ok(files)
}

///|
fn episode_quality_files(
  source_dir : String,
) -> Result[Array[(String, String)], @data_store.DataStoreIssue] {
  let quality_dir = join(source_dir, "quality")
  if !@fsx.path_exists(quality_dir) {
    return Ok([])
  }
  let names = match read_sorted_names(quality_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let files : Array[(String, String)] = []
  for name in names {
    if !@data_core.data_relative_path_is_safe(name) {
      return Err(
        import_issue(
          "unsafe-robot-quality-path", name, "robot quality source contains an unsafe relative path",
        ),
      )
    }
    let path = join(quality_dir, name)
    if !is_directory(path) {
      files.push((path, name))
    }
  }
  Ok(files)
}

///|
fn episode_payload_data_ref(
  dataset_id : @data_core.DatasetId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/episodes/\{dataset_id}/\{relative_path}"
  @data_core.data_ref(
    "robot-episode-\{safe_ref_segment(dataset_id)}-\{safe_ref_segment(relative_path)}",
    "robot-signal-frame",
    @data_core.data_uri(payload_path),
    content_type=if relative_path.has_suffix(".json") {
      "application/json"
    } else {
      "text/plain"
    },
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
fn quality_payload_data_ref(
  dataset_id : @data_core.DatasetId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/episodes/\{dataset_id}/quality/\{relative_path}"
  @data_core.data_ref(
    "robot-quality-\{safe_ref_segment(dataset_id)}-\{safe_ref_segment(relative_path)}",
    "robot-quality-report",
    @data_core.data_uri(payload_path),
    content_type=if relative_path.has_suffix(".json") {
      "application/json"
    } else {
      "text/plain"
    },
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
fn replay_payload_data_ref(
  dataset_id : @data_core.DatasetId,
  relative_path : String,
  body : String,
) -> @data_core.DataRef {
  let payload_path = "payloads/robot_data/episodes/\{dataset_id}/replays/\{relative_path}"
  @data_core.data_ref(
    "robot-replay-\{safe_ref_segment(dataset_id)}-\{safe_ref_segment(relative_path)}",
    "robot-replay",
    @data_core.data_uri(payload_path),
    content_type=if relative_path.has_suffix(".json") {
      "application/json"
    } else {
      "text/plain"
    },
    byte_count=body.length().to_int64(),
    checksum=text_sum(body),
  )
}

///|
fn payload_from_data_ref(
  data_ref : @data_core.DataRef,
) -> Result[@robot_data.RobotPayloadRef, @data_store.DataStoreIssue] {
  let path = match @data_core.data_payload_uri_relative_path(data_ref.uri) {
    Some(value) => value
    None =>
      return Err(
        import_issue(
          "unsafe-robot-data-ref",
          data_ref.uri,
          "robot data ref is not a safe data-root payload URI",
        ),
      )
  }
  Ok(
    @robot_data.robot_payload_ref_with_checksum(
      data_ref.ref_id,
      data_ref.kind,
      path,
      data_ref.content_type,
      data_ref.byte_count,
      data_ref.checksum,
    ),
  )
}

///|
fn model_urdf_ref(dossier : RobotModelCatalogDossier) -> @data_core.DataRef? {
  for data_ref in dossier.dataset.data_refs {
    if data_ref.kind == "urdf" {
      return Some(data_ref)
    }
  }
  None
}

///|
fn model_ref_from_dossier(
  dossier : RobotModelCatalogDossier,
  robot_id : @robot_data.RobotId,
) -> Result[@robot_data.RobotModelRef, @data_store.DataStoreIssue] {
  let urdf = match model_urdf_ref(dossier) {
    Some(value) => value
    None =>
      return Err(
        import_issue(
          "robot-model-urdf-ref-missing",
          dossier.model_id,
          "robot model dossier has no URDF data ref",
        ),
      )
  }
  let payload = match payload_from_data_ref(urdf) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(
    @robot_data.robot_model_ref(
      dossier.model_id,
      robot_id,
      dossier.source.source_id,
      dossier.source.label,
      dossier.dataset.kind,
      dossier.source.authority,
      dossier.source.source_url,
      dossier.source.license,
      dossier.source.citation,
      dossier.source.created_at_ms,
      payload,
    ),
  )
}

///|
pub fn import_robot_episode_directory(
  request : RobotEpisodeDirectoryImportRequest,
) -> Result[RobotEpisodeDirectoryImportResult, @data_store.DataStoreIssue] {
  match
    validate_episode_import_id(request.dataset_id, "robot-episode-dataset-id") {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match validate_episode_import_id(request.episode_id, "robot-episode-id") {
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
  let files = match episode_source_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if files.length() == 0 {
    return Err(
      import_issue(
        "empty-robot-episode-directory",
        request.source_dir,
        "robot episode source directory has no file payloads",
      ),
    )
  }
  let replay_files = match episode_replay_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let quality_files = match episode_quality_files(request.source_dir) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let signals : Array[ImportedRobotEpisodeSignal] = []
  for index in 0..<files.length() {
    let (source_path, relative_path) = files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-episode-payload", source_path, "failed to read robot episode payload as text",
          ),
        )
    }
    let data_ref = episode_payload_data_ref(
      request.dataset_id,
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
    let signal = @robot_data.robot_signal_ref(
      "signal-\{safe_ref_segment(request.dataset_id)}-\{index}",
      "frame-\{safe_ref_segment(request.episode_id)}-\{index}",
      "raw-file",
      1,
      "payload",
      payload,
    )
    signals.push({ source_path, relative_path, payload_path, signal })
  }
  let replays : Array[ImportedRobotEpisodeReplay] = []
  for index in 0..<replay_files.length() {
    let (source_path, relative_path) = replay_files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-replay-payload", source_path, "failed to read robot replay payload as text",
          ),
        )
    }
    let data_ref = replay_payload_data_ref(
      request.dataset_id,
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
    let replay = @robot_data.robot_replay_artifact(
      "replay-\{safe_ref_segment(request.dataset_id)}-\{index}",
      "robot-replay",
      payload,
    )
    replays.push({ source_path, relative_path, payload_path, replay })
  }
  let quality_reports : Array[ImportedRobotEpisodeQuality] = []
  for index in 0..<quality_files.length() {
    let (source_path, relative_path) = quality_files[index]
    let body = @fsx.read_file_to_string(source_path) catch {
      _ =>
        return Err(
          import_issue(
            "read-robot-quality-payload", source_path, "failed to read robot quality payload as text",
          ),
        )
    }
    let data_ref = quality_payload_data_ref(
      request.dataset_id,
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
    let report = @robot_data.robot_quality_report(
      "quality-\{safe_ref_segment(request.dataset_id)}-\{index}",
      request.episode_id,
      @data_core.ValidationStatus::Passed,
      request.imported_at_ms,
      signals.length(),
      0,
      findings=[
        @data_core.validation_finding(
          "robot-quality-payload-imported",
          @data_core.FindingSeverity::Info,
          @data_core.artifact_ref(
            "payload",
            payload.ref_id,
            payload.path,
            status=@data_core.DataStatus::Verified,
            summary=payload.role,
          ),
          "robot quality payload imported",
          recommendation="use the domain quality payload for detailed robot acceptance evidence",
        ),
      ],
    )
    quality_reports.push({
      source_path,
      relative_path,
      payload_path,
      payload,
      report,
    })
  }
  let episode = @robot_data.robot_episode_manifest(
    request.episode_id,
    request.robot_id,
    request.dataset_id,
    @data_core.DataStatus::Verified,
    request.imported_at_ms,
    signals.length(),
    [model],
    signals.map(fn(signal) { signal.signal }),
    replays.map(fn(replay) { replay.replay }),
    quality_reports.map(fn(quality) { quality.payload }),
    request.source_label,
  )
  match write_episodes(request.root, [episode]) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match
    write_quality_reports(
      request.root,
      quality_reports.map(fn(quality) { quality.report }),
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
    dataset_id: request.dataset_id,
    episode_id: request.episode_id,
    robot_id: request.robot_id,
    model_id: request.model_id,
    signal_count: signals.length(),
    replay_count: replays.length(),
    quality_report_count: quality_reports.length(),
    episode,
    signals,
    replays,
    quality_reports,
    materialization: {
      root: request.root,
      catalog_path: validation.catalog_path,
      validation_report_path: validation.report_path,
      source_count: 0,
      dataset_count: 1,
      version_count: 1,
      lineage_count: 1,
      telemetry_stream_count: 0,
      quality_report_count: quality_reports.length(),
      catalog_entry_count: catalog.entries.length(),
      validation_status: validation.status,
      blocker_count: validation.blocker_count,
      warning_count: validation.warning_count,
    },
  })
}
