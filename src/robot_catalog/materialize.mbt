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
          issue("create-dir", path, "failed to create robot catalog directory"),
        )
    }
    Ok(())
  }
}

///|
fn ensure_payload_parent_dirs(
  root : String,
  relative_path : String,
) -> Result[Unit, @data_store.DataStoreIssue] {
  let mut current = root
  let mut segment = ""
  for char in relative_path {
    if char == '/' {
      if segment != "" {
        current = join(current, segment)
        match ensure_dir(current) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
        segment = ""
      }
    } else {
      segment = segment + char.to_string()
    }
  }
  Ok(())
}

///|
pub fn stage_robot_payload_text(
  root : String,
  payload : @robot_data.RobotPayloadRef,
  body : String,
) -> Result[Unit, @data_store.DataStoreIssue] {
  let relative = match
    @data_core.data_payload_uri_relative_path(@data_core.data_uri(payload.path)) {
    Some(value) => value
    None =>
      return Err(
        issue(
          "unsafe-payload-path",
          payload.path,
          "robot payload path is not a safe data-root relative path",
        ),
      )
  }
  let path = join(root, relative)
  match ensure_payload_parent_dirs(root, relative) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  @fsx.write_string_to_file(path, body) catch {
    _ =>
      return Err(issue("write-payload", path, "failed to write robot payload"))
  }
  Ok(())
}

///|
fn write_models(
  root : String,
  models : Array[@robot_data.RobotModelRef],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for model in models {
    match
      @data_store.write_source(root, @robot_data.robot_model_data_source(model)) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_episodes(
  root : String,
  episodes : Array[@robot_data.RobotEpisodeManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for episode in episodes {
    match
      @data_store.write_dataset(
        root,
        @robot_data.robot_episode_dataset(episode),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset_version(
        root,
        @robot_data.robot_episode_version(episode, "\{episode.episode_id}-v1"),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    for replay in episode.replay_artifacts {
      match
        @data_store.write_artifact_ref(
          root,
          @data_core.artifact_ref(
            replay.artifact_kind,
            replay.artifact_id,
            replay.payload.path,
            status=episode.status,
            summary=replay.payload.role,
          ),
        ) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
    }
    match
      @data_store.write_lineage_manifest(
        root,
        @robot_data.robot_episode_lineage(
          episode,
          "lineage-\{episode.episode_id}",
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_telemetry_streams(
  root : String,
  streams : Array[@robot_data.RobotTelemetryStreamManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for stream in streams {
    match
      @data_store.write_source(
        root,
        @robot_data.robot_telemetry_data_source(stream),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset(
        root,
        @robot_data.robot_telemetry_dataset(stream),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset_version(
        root,
        @robot_data.robot_telemetry_version(stream, "\{stream.stream_id}-v1"),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_lineage_manifest(
        root,
        @robot_data.robot_telemetry_lineage(
          stream,
          "lineage-\{stream.stream_id}",
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_gait_clips(
  root : String,
  clips : Array[@robot_data.RobotGaitClipManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for clip in clips {
    match
      @data_store.write_source(
        root,
        @robot_data.robot_gait_clip_data_source(clip),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset(root, @robot_data.robot_gait_clip_dataset(clip)) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset_version(
        root,
        @robot_data.robot_gait_clip_version(clip, "\{clip.clip_id}-v1"),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_lineage_manifest(
        root,
        @robot_data.robot_gait_clip_lineage(clip, "lineage-\{clip.clip_id}"),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_gait_annotations(
  root : String,
  annotations : Array[@robot_data.RobotGaitAnnotationManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for annotation in annotations {
    match
      @data_store.write_source(
        root,
        @robot_data.robot_gait_annotation_data_source(annotation),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset(
        root,
        @robot_data.robot_gait_annotation_dataset(annotation),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset_version(
        root,
        @robot_data.robot_gait_annotation_version(
          annotation,
          "\{annotation.annotation_id}-v1",
          parent_version_ids=["\{annotation.clip_id}-v1"],
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_lineage_manifest(
        root,
        @robot_data.robot_gait_annotation_lineage(
          annotation,
          "lineage-\{annotation.annotation_id}",
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_gait_alignments(
  root : String,
  alignments : Array[@robot_data.RobotGaitAlignmentManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for alignment in alignments {
    match
      @data_store.write_source(
        root,
        @robot_data.robot_gait_alignment_data_source(alignment),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset(
        root,
        @robot_data.robot_gait_alignment_dataset(alignment),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset_version(
        root,
        @robot_data.robot_gait_alignment_version(
          alignment,
          "\{alignment.alignment_id}-v1",
          parent_version_ids=[
            "\{alignment.episode_id}-v1",
            "\{alignment.clip_id}-v1",
            "\{alignment.annotation_id}-v1",
          ],
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_lineage_manifest(
        root,
        @robot_data.robot_gait_alignment_lineage(
          alignment,
          "lineage-\{alignment.alignment_id}",
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_task_labels(
  root : String,
  task_labels : Array[@robot_data.RobotTaskLabelManifest],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for task_label in task_labels {
    match
      @data_store.write_source(
        root,
        @robot_data.robot_task_label_data_source(task_label),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset(
        root,
        @robot_data.robot_task_label_dataset(task_label),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_dataset_version(
        root,
        @robot_data.robot_task_label_version(
          task_label,
          "\{task_label.task_label_id}-v1",
          parent_version_ids=[
            "\{task_label.episode_id}-v1",
            "\{task_label.alignment_id}-v1",
          ],
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match
      @data_store.write_lineage_manifest(
        root,
        @robot_data.robot_task_label_lineage(
          task_label,
          "lineage-\{task_label.task_label_id}",
        ),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_quality_reports(
  root : String,
  reports : Array[@robot_data.RobotQualityReport],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for report in reports {
    match
      @data_store.write_validation_report(
        root,
        @robot_data.robot_quality_validation_report(root, report),
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
pub fn materialize_robot_catalog_bundle(
  root : String,
  bundle : RobotCatalogBundle,
  generated_at_ms : Int64,
) -> Result[RobotCatalogMaterialization, @data_store.DataStoreIssue] {
  match @data_store.initialize_root(root) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_models(root, bundle.models) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_episodes(root, bundle.episodes) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_telemetry_streams(root, bundle.telemetry_streams) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_gait_clips(root, bundle.gait_clips) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_gait_annotations(root, bundle.gait_annotations) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_gait_alignments(root, bundle.gait_alignments) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_task_labels(root, bundle.task_labels) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_quality_reports(root, bundle.quality_reports) {
    Ok(_) => ()
    Err(error) => return Err(error)
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
    source_count: bundle.models.length() +
    bundle.telemetry_streams.length() +
    bundle.gait_clips.length() +
    bundle.gait_annotations.length() +
    bundle.gait_alignments.length() +
    bundle.task_labels.length(),
    dataset_count: bundle.episodes.length() +
    bundle.telemetry_streams.length() +
    bundle.gait_clips.length() +
    bundle.gait_annotations.length() +
    bundle.gait_alignments.length() +
    bundle.task_labels.length(),
    version_count: bundle.episodes.length() +
    bundle.telemetry_streams.length() +
    bundle.gait_clips.length() +
    bundle.gait_annotations.length() +
    bundle.gait_alignments.length() +
    bundle.task_labels.length(),
    lineage_count: bundle.episodes.length() +
    bundle.telemetry_streams.length() +
    bundle.gait_clips.length() +
    bundle.gait_annotations.length() +
    bundle.gait_alignments.length() +
    bundle.task_labels.length(),
    telemetry_stream_count: bundle.telemetry_streams.length(),
    gait_clip_count: bundle.gait_clips.length(),
    gait_annotation_count: bundle.gait_annotations.length(),
    gait_alignment_count: bundle.gait_alignments.length(),
    task_label_count: bundle.task_labels.length(),
    quality_report_count: bundle.quality_reports.length(),
    catalog_entry_count: catalog.entries.length(),
    validation_status: validation.status,
    blocker_count: validation.blocker_count,
    warning_count: validation.warning_count,
  })
}
