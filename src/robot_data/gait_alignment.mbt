///|
pub type RobotGaitAlignmentId = String

///|
pub(all) struct RobotGaitAlignmentPayloadRef {
  role : String
  line_count : Int
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotGaitAlignmentManifest {
  alignment_id : RobotGaitAlignmentId
  robot_id : RobotId
  episode_id : RobotEpisodeId
  clip_id : RobotGaitClipId
  annotation_id : RobotGaitAnnotationId
  source_id : @data_core.SourceId
  source_label : String
  source_url : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  model_refs : Array[RobotModelRef]
  payload_refs : Array[RobotGaitAlignmentPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_gait_alignment_payload_ref(
  role : String,
  line_count : Int,
  payload : RobotPayloadRef,
) -> RobotGaitAlignmentPayloadRef {
  { role, line_count, payload }
}

///|
pub fn robot_gait_alignment_manifest(
  alignment_id : RobotGaitAlignmentId,
  robot_id : RobotId,
  episode_id : RobotEpisodeId,
  clip_id : RobotGaitClipId,
  annotation_id : RobotGaitAnnotationId,
  source_id : @data_core.SourceId,
  source_label : String,
  source_url : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  model_refs : Array[RobotModelRef],
  payload_refs : Array[RobotGaitAlignmentPayloadRef],
  summary : String,
) -> RobotGaitAlignmentManifest {
  {
    alignment_id,
    robot_id,
    episode_id,
    clip_id,
    annotation_id,
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
fn alignment_model_data_refs(
  models : Array[RobotModelRef],
) -> Array[@data_core.DataRef] {
  models.map(fn(model) { robot_payload_data_ref(model.payload) })
}

///|
fn alignment_payload_data_refs(
  payloads : Array[RobotGaitAlignmentPayloadRef],
) -> Array[@data_core.DataRef] {
  payloads.map(fn(payload) { robot_payload_data_ref(payload.payload) })
}

///|
pub fn robot_gait_alignment_data_refs(
  alignment : RobotGaitAlignmentManifest,
) -> Array[@data_core.DataRef] {
  alignment_model_data_refs(alignment.model_refs) +
  alignment_payload_data_refs(alignment.payload_refs)
}

///|
pub fn robot_gait_alignment_source_ids(
  alignment : RobotGaitAlignmentManifest,
) -> Array[@data_core.SourceId] {
  [alignment.source_id] +
  alignment.model_refs.map(fn(model) { model.source_id })
}

///|
pub fn robot_gait_alignment_data_source(
  alignment : RobotGaitAlignmentManifest,
) -> @data_core.DataSource {
  @data_core.data_source(
    alignment.source_id,
    "Robot gait alignment",
    alignment.source_label,
    alignment.source_url,
    "local import",
    "Imported by Moonmoon robot_catalog",
    alignment.created_at_ms,
    source_refs=alignment_payload_data_refs(alignment.payload_refs),
  )
}

///|
pub fn robot_gait_alignment_dataset(
  alignment : RobotGaitAlignmentManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    alignment.alignment_id,
    "robot-gait-alignment",
    alignment.status,
    alignment.created_at_ms,
    source_ids=robot_gait_alignment_source_ids(alignment),
    data_refs=robot_gait_alignment_data_refs(alignment),
    summary=alignment.summary,
  )
}

///|
pub fn robot_gait_alignment_version(
  alignment : RobotGaitAlignmentManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    alignment.alignment_id,
    alignment.status,
    alignment.created_at_ms,
    parent_version_ids~,
    data_refs=robot_gait_alignment_data_refs(alignment),
    summary=alignment.summary,
  )
}

///|
pub fn robot_gait_alignment_lineage(
  alignment : RobotGaitAlignmentManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_gait_alignment_dataset(alignment)
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
        alignment.source_id,
        "sources/\{alignment.source_id}.json",
        status=alignment.status,
        summary=alignment.source_label,
      ),
      root,
      "robot-gait-alignment-import",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        alignment.episode_id,
        "datasets/\{alignment.episode_id}.json",
        status=alignment.status,
        summary="aligned robot episode",
      ),
      root,
      "robot-episode-aligned",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        alignment.clip_id,
        "datasets/\{alignment.clip_id}.json",
        status=alignment.status,
        summary="aligned gait clip",
      ),
      root,
      "robot-gait-clip-aligned",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        alignment.annotation_id,
        "datasets/\{alignment.annotation_id}.json",
        status=alignment.status,
        summary="aligned gait annotation",
      ),
      root,
      "robot-gait-annotation-aligned",
    ),
  ]
  for model in alignment.model_refs {
    let source = robot_model_data_source(model)
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source.source_id,
          "sources/\{source.source_id}.json",
          status=alignment.status,
          summary=source.label,
        ),
        root,
        "robot-gait-alignment-model-source",
      ),
    )
  }
  @data_core.lineage_manifest(lineage_id, root, alignment.created_at_ms, edges~)
}
