///|
pub type RobotTaskLabelId = String

///|
pub(all) struct RobotTaskLabelPayloadRef {
  role : String
  line_count : Int
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotTaskLabelManifest {
  task_label_id : RobotTaskLabelId
  robot_id : RobotId
  episode_id : RobotEpisodeId
  alignment_id : RobotGaitAlignmentId
  source_id : @data_core.SourceId
  source_label : String
  source_url : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  model_refs : Array[RobotModelRef]
  payload_refs : Array[RobotTaskLabelPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_task_label_payload_ref(
  role : String,
  line_count : Int,
  payload : RobotPayloadRef,
) -> RobotTaskLabelPayloadRef {
  { role, line_count, payload }
}

///|
pub fn robot_task_label_manifest(
  task_label_id : RobotTaskLabelId,
  robot_id : RobotId,
  episode_id : RobotEpisodeId,
  alignment_id : RobotGaitAlignmentId,
  source_id : @data_core.SourceId,
  source_label : String,
  source_url : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  model_refs : Array[RobotModelRef],
  payload_refs : Array[RobotTaskLabelPayloadRef],
  summary : String,
) -> RobotTaskLabelManifest {
  {
    task_label_id,
    robot_id,
    episode_id,
    alignment_id,
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
fn task_label_model_data_refs(
  models : Array[RobotModelRef],
) -> Array[@data_core.DataRef] {
  models.map(fn(model) { robot_payload_data_ref(model.payload) })
}

///|
fn task_label_payload_data_refs(
  payloads : Array[RobotTaskLabelPayloadRef],
) -> Array[@data_core.DataRef] {
  payloads.map(fn(payload) { robot_payload_data_ref(payload.payload) })
}

///|
pub fn robot_task_label_data_refs(
  task_label : RobotTaskLabelManifest,
) -> Array[@data_core.DataRef] {
  task_label_model_data_refs(task_label.model_refs) +
  task_label_payload_data_refs(task_label.payload_refs)
}

///|
pub fn robot_task_label_source_ids(
  task_label : RobotTaskLabelManifest,
) -> Array[@data_core.SourceId] {
  [task_label.source_id] +
  task_label.model_refs.map(fn(model) { model.source_id })
}

///|
pub fn robot_task_label_data_source(
  task_label : RobotTaskLabelManifest,
) -> @data_core.DataSource {
  @data_core.data_source(
    task_label.source_id,
    "Robot task labels",
    task_label.source_label,
    task_label.source_url,
    "local import",
    "Imported by MoonMoon robot_catalog",
    task_label.created_at_ms,
    source_refs=task_label_payload_data_refs(task_label.payload_refs),
  )
}

///|
pub fn robot_task_label_dataset(
  task_label : RobotTaskLabelManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    task_label.task_label_id,
    "robot-task-label",
    task_label.status,
    task_label.created_at_ms,
    source_ids=robot_task_label_source_ids(task_label),
    data_refs=robot_task_label_data_refs(task_label),
    summary=task_label.summary,
  )
}

///|
pub fn robot_task_label_version(
  task_label : RobotTaskLabelManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    task_label.task_label_id,
    task_label.status,
    task_label.created_at_ms,
    parent_version_ids~,
    data_refs=robot_task_label_data_refs(task_label),
    summary=task_label.summary,
  )
}

///|
pub fn robot_task_label_lineage(
  task_label : RobotTaskLabelManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_task_label_dataset(task_label)
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
        task_label.source_id,
        "sources/\{task_label.source_id}.json",
        status=task_label.status,
        summary=task_label.source_label,
      ),
      root,
      "robot-task-label-import",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        task_label.episode_id,
        "datasets/\{task_label.episode_id}.json",
        status=task_label.status,
        summary="labeled robot episode",
      ),
      root,
      "robot-episode-labeled",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        task_label.alignment_id,
        "datasets/\{task_label.alignment_id}.json",
        status=task_label.status,
        summary="labeled gait alignment",
      ),
      root,
      "robot-gait-alignment-labeled",
    ),
  ]
  for model in task_label.model_refs {
    let source = robot_model_data_source(model)
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source.source_id,
          "sources/\{source.source_id}.json",
          status=task_label.status,
          summary=source.label,
        ),
        root,
        "robot-task-label-model-source",
      ),
    )
  }
  @data_core.lineage_manifest(
    lineage_id,
    root,
    task_label.created_at_ms,
    edges~,
  )
}
