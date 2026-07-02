///|
pub type RobotRolloutId = String

///|
pub(all) struct RobotRolloutPayloadRef {
  role : String
  line_count : Int
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotRolloutManifest {
  rollout_id : RobotRolloutId
  robot_id : RobotId
  episode_id : RobotEpisodeId
  task_label_id : RobotTaskLabelId
  source_id : @data_core.SourceId
  source_label : String
  source_url : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  model_refs : Array[RobotModelRef]
  payload_refs : Array[RobotRolloutPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_rollout_payload_ref(
  role : String,
  line_count : Int,
  payload : RobotPayloadRef,
) -> RobotRolloutPayloadRef {
  { role, line_count, payload }
}

///|
pub fn robot_rollout_manifest(
  rollout_id : RobotRolloutId,
  robot_id : RobotId,
  episode_id : RobotEpisodeId,
  task_label_id : RobotTaskLabelId,
  source_id : @data_core.SourceId,
  source_label : String,
  source_url : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  model_refs : Array[RobotModelRef],
  payload_refs : Array[RobotRolloutPayloadRef],
  summary : String,
) -> RobotRolloutManifest {
  {
    rollout_id,
    robot_id,
    episode_id,
    task_label_id,
    source_id,
    source_label,
    source_url,
    status,
    created_at_ms,
    model_refs,
    payload_refs,
    summary,
  }
}

///|
fn rollout_model_data_refs(
  models : Array[RobotModelRef],
) -> Array[@data_core.DataRef] {
  models.map(fn(model) { robot_payload_data_ref(model.payload) })
}

///|
fn rollout_payload_data_refs(
  payloads : Array[RobotRolloutPayloadRef],
) -> Array[@data_core.DataRef] {
  payloads.map(fn(payload) { robot_payload_data_ref(payload.payload) })
}

///|
pub fn robot_rollout_data_refs(
  rollout : RobotRolloutManifest,
) -> Array[@data_core.DataRef] {
  rollout_model_data_refs(rollout.model_refs) +
  rollout_payload_data_refs(rollout.payload_refs)
}

///|
pub fn robot_rollout_source_ids(
  rollout : RobotRolloutManifest,
) -> Array[@data_core.SourceId] {
  [rollout.source_id] + rollout.model_refs.map(fn(model) { model.source_id })
}

///|
pub fn robot_rollout_data_source(
  rollout : RobotRolloutManifest,
) -> @data_core.DataSource {
  @data_core.data_source(
    rollout.source_id,
    "Robot rollout summary",
    rollout.source_label,
    rollout.source_url,
    "local import",
    "Imported by Moonmoon robot_catalog",
    rollout.created_at_ms,
    source_refs=rollout_payload_data_refs(rollout.payload_refs),
  )
}

///|
pub fn robot_rollout_dataset(
  rollout : RobotRolloutManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    rollout.rollout_id,
    "robot-rollout-summary",
    rollout.status,
    rollout.created_at_ms,
    source_ids=robot_rollout_source_ids(rollout),
    data_refs=robot_rollout_data_refs(rollout),
    summary=rollout.summary,
  )
}

///|
pub fn robot_rollout_version(
  rollout : RobotRolloutManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    rollout.rollout_id,
    rollout.status,
    rollout.created_at_ms,
    parent_version_ids~,
    data_refs=robot_rollout_data_refs(rollout),
    summary=rollout.summary,
  )
}

///|
pub fn robot_rollout_lineage(
  rollout : RobotRolloutManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_rollout_dataset(rollout)
  let root = @data_core.artifact_ref(
    "dataset",
    dataset.dataset_id,
    "datasets/\{dataset.dataset_id}.json",
    status=dataset.status,
    summary=dataset.summary,
  )
  let edges : Array[@data_core.LineageEdge] = [
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "source",
        rollout.source_id,
        "sources/\{rollout.source_id}.json",
        status=rollout.status,
        summary=rollout.source_label,
      ),
      root,
      "robot-rollout-summary-import",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        rollout.episode_id,
        "datasets/\{rollout.episode_id}.json",
        status=rollout.status,
        summary="summarized robot episode",
      ),
      root,
      "robot-episode-summarized",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        rollout.task_label_id,
        "datasets/\{rollout.task_label_id}.json",
        status=rollout.status,
        summary="summarized robot task labels",
      ),
      root,
      "robot-task-label-summarized",
    ),
  ]
  for model in rollout.model_refs {
    let source = robot_model_data_source(model)
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source.source_id,
          "sources/\{source.source_id}.json",
          status=rollout.status,
          summary=source.label,
        ),
        root,
        "robot-rollout-model-source",
      ),
    )
  }
  @data_core.lineage_manifest(lineage_id, root, rollout.created_at_ms, edges~)
}
