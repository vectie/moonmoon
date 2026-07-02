///|
pub type RobotEpisodeId = String

///|
pub type RobotSignalId = String

///|
pub type RobotReplayArtifactId = String

///|
pub(all) struct RobotSignalRef {
  signal_id : RobotSignalId
  frame_id : String
  channel : String
  sample_count : Int
  unit : String
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotReplayArtifact {
  artifact_id : RobotReplayArtifactId
  artifact_kind : String
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotEpisodeManifest {
  episode_id : RobotEpisodeId
  robot_id : RobotId
  session_id : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  frame_count : Int
  model_refs : Array[RobotModelRef]
  signal_refs : Array[RobotSignalRef]
  replay_artifacts : Array[RobotReplayArtifact]
  quality_report_refs : Array[RobotPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_signal_ref(
  signal_id : RobotSignalId,
  frame_id : String,
  channel : String,
  sample_count : Int,
  unit : String,
  payload : RobotPayloadRef,
) -> RobotSignalRef {
  { signal_id, frame_id, channel, sample_count, unit, payload }
}

///|
pub fn robot_replay_artifact(
  artifact_id : RobotReplayArtifactId,
  artifact_kind : String,
  payload : RobotPayloadRef,
) -> RobotReplayArtifact {
  { artifact_id, artifact_kind, payload }
}

///|
pub fn robot_episode_manifest(
  episode_id : RobotEpisodeId,
  robot_id : RobotId,
  session_id : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  frame_count : Int,
  model_refs : Array[RobotModelRef],
  signal_refs : Array[RobotSignalRef],
  replay_artifacts : Array[RobotReplayArtifact],
  quality_report_refs : Array[RobotPayloadRef],
  summary : String,
) -> RobotEpisodeManifest {
  {
    episode_id,
    robot_id,
    session_id,
    status,
    created_at_ms,
    frame_count,
    model_refs,
    signal_refs,
    replay_artifacts,
    quality_report_refs,
    summary,
  }
}

///|
fn model_data_refs(models : Array[RobotModelRef]) -> Array[@data_core.DataRef] {
  models.map(fn(model) { robot_payload_data_ref(model.payload) })
}

///|
fn signal_data_refs(
  signals : Array[RobotSignalRef],
) -> Array[@data_core.DataRef] {
  signals.map(fn(signal) { robot_payload_data_ref(signal.payload) })
}

///|
fn replay_data_refs(
  artifacts : Array[RobotReplayArtifact],
) -> Array[@data_core.DataRef] {
  artifacts.map(fn(artifact) { robot_payload_data_ref(artifact.payload) })
}

///|
fn quality_data_refs(
  reports : Array[RobotPayloadRef],
) -> Array[@data_core.DataRef] {
  reports.map(robot_payload_data_ref)
}

///|
pub fn robot_episode_data_refs(
  episode : RobotEpisodeManifest,
) -> Array[@data_core.DataRef] {
  model_data_refs(episode.model_refs) +
  signal_data_refs(episode.signal_refs) +
  replay_data_refs(episode.replay_artifacts) +
  quality_data_refs(episode.quality_report_refs)
}

///|
pub fn robot_episode_source_ids(
  episode : RobotEpisodeManifest,
) -> Array[@data_core.SourceId] {
  episode.model_refs.map(fn(model) { model.source_id })
}

///|
pub fn robot_episode_dataset(
  episode : RobotEpisodeManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    episode.episode_id,
    "robot-episode",
    episode.status,
    episode.created_at_ms,
    source_ids=robot_episode_source_ids(episode),
    data_refs=robot_episode_data_refs(episode),
    summary=episode.summary,
  )
}

///|
pub fn robot_episode_version(
  episode : RobotEpisodeManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    episode.episode_id,
    episode.status,
    episode.created_at_ms,
    parent_version_ids~,
    data_refs=robot_episode_data_refs(episode),
    summary=episode.summary,
  )
}

///|
pub fn robot_episode_lineage(
  episode : RobotEpisodeManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_episode_dataset(episode)
  let root = @data_core.artifact_ref(
    "dataset",
    dataset.dataset_id,
    "datasets/\{dataset.dataset_id}.json",
    status=dataset.status,
    summary=dataset.summary,
  )
  let edges : Array[@data_core.LineageEdge] = []
  for model in episode.model_refs {
    let source = robot_model_data_source(model)
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source.source_id,
          "sources/\{source.source_id}.json",
          status=@data_core.DataStatus::Verified,
          summary=source.label,
        ),
        root,
        "robot-model-source",
      ),
    )
  }
  for replay in episode.replay_artifacts {
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          replay.artifact_kind,
          replay.artifact_id,
          replay.payload.path,
          status=episode.status,
          summary=replay.payload.role,
        ),
        root,
        "episode-payload",
      ),
    )
  }
  @data_core.lineage_manifest(lineage_id, root, episode.created_at_ms, edges~)
}
