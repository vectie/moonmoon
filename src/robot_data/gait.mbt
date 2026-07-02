///|
pub type RobotGaitClipId = String

///|
pub type RobotGaitAnnotationId = String

///|
pub(all) struct RobotGaitClipPayloadRef {
  role : String
  frame_count : Int
  duration_s : Double
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotGaitAnnotationPayloadRef {
  role : String
  line_count : Int
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotGaitClipManifest {
  clip_id : RobotGaitClipId
  robot_id : RobotId
  source_id : @data_core.SourceId
  source_label : String
  source_url : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  model_refs : Array[RobotModelRef]
  payload_refs : Array[RobotGaitClipPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotGaitAnnotationManifest {
  annotation_id : RobotGaitAnnotationId
  robot_id : RobotId
  clip_id : RobotGaitClipId
  source_id : @data_core.SourceId
  source_label : String
  source_url : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  model_refs : Array[RobotModelRef]
  payload_refs : Array[RobotGaitAnnotationPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_gait_clip_payload_ref(
  role : String,
  frame_count : Int,
  duration_s : Double,
  payload : RobotPayloadRef,
) -> RobotGaitClipPayloadRef {
  { role, frame_count, duration_s, payload }
}

///|
pub fn robot_gait_annotation_payload_ref(
  role : String,
  line_count : Int,
  payload : RobotPayloadRef,
) -> RobotGaitAnnotationPayloadRef {
  { role, line_count, payload }
}

///|
pub fn robot_gait_clip_manifest(
  clip_id : RobotGaitClipId,
  robot_id : RobotId,
  source_id : @data_core.SourceId,
  source_label : String,
  source_url : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  model_refs : Array[RobotModelRef],
  payload_refs : Array[RobotGaitClipPayloadRef],
  summary : String,
) -> RobotGaitClipManifest {
  {
    clip_id,
    robot_id,
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
pub fn robot_gait_annotation_manifest(
  annotation_id : RobotGaitAnnotationId,
  robot_id : RobotId,
  clip_id : RobotGaitClipId,
  source_id : @data_core.SourceId,
  source_label : String,
  source_url : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  model_refs : Array[RobotModelRef],
  payload_refs : Array[RobotGaitAnnotationPayloadRef],
  summary : String,
) -> RobotGaitAnnotationManifest {
  {
    annotation_id,
    robot_id,
    clip_id,
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
fn gait_model_data_refs(
  models : Array[RobotModelRef],
) -> Array[@data_core.DataRef] {
  models.map(fn(model) { robot_payload_data_ref(model.payload) })
}

///|
fn gait_payload_data_refs(
  payloads : Array[RobotGaitClipPayloadRef],
) -> Array[@data_core.DataRef] {
  payloads.map(fn(payload) { robot_payload_data_ref(payload.payload) })
}

///|
fn annotation_payload_data_refs(
  payloads : Array[RobotGaitAnnotationPayloadRef],
) -> Array[@data_core.DataRef] {
  payloads.map(fn(payload) { robot_payload_data_ref(payload.payload) })
}

///|
pub fn robot_gait_clip_data_refs(
  clip : RobotGaitClipManifest,
) -> Array[@data_core.DataRef] {
  gait_model_data_refs(clip.model_refs) +
  gait_payload_data_refs(clip.payload_refs)
}

///|
pub fn robot_gait_annotation_data_refs(
  annotation : RobotGaitAnnotationManifest,
) -> Array[@data_core.DataRef] {
  gait_model_data_refs(annotation.model_refs) +
  annotation_payload_data_refs(annotation.payload_refs)
}

///|
pub fn robot_gait_clip_source_ids(
  clip : RobotGaitClipManifest,
) -> Array[@data_core.SourceId] {
  [clip.source_id] + clip.model_refs.map(fn(model) { model.source_id })
}

///|
pub fn robot_gait_annotation_source_ids(
  annotation : RobotGaitAnnotationManifest,
) -> Array[@data_core.SourceId] {
  [annotation.source_id] +
  annotation.model_refs.map(fn(model) { model.source_id })
}

///|
pub fn robot_gait_clip_data_source(
  clip : RobotGaitClipManifest,
) -> @data_core.DataSource {
  @data_core.data_source(
    clip.source_id,
    "Robot gait clip",
    clip.source_label,
    clip.source_url,
    "local import",
    "Imported by Moonmoon robot_catalog",
    clip.created_at_ms,
    source_refs=gait_payload_data_refs(clip.payload_refs),
  )
}

///|
pub fn robot_gait_annotation_data_source(
  annotation : RobotGaitAnnotationManifest,
) -> @data_core.DataSource {
  @data_core.data_source(
    annotation.source_id,
    "Robot gait annotation",
    annotation.source_label,
    annotation.source_url,
    "local import",
    "Imported by Moonmoon robot_catalog",
    annotation.created_at_ms,
    source_refs=annotation_payload_data_refs(annotation.payload_refs),
  )
}

///|
pub fn robot_gait_clip_dataset(
  clip : RobotGaitClipManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    clip.clip_id,
    "robot-gait-clip",
    clip.status,
    clip.created_at_ms,
    source_ids=robot_gait_clip_source_ids(clip),
    data_refs=robot_gait_clip_data_refs(clip),
    summary=clip.summary,
  )
}

///|
pub fn robot_gait_annotation_dataset(
  annotation : RobotGaitAnnotationManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    annotation.annotation_id,
    "robot-gait-annotation",
    annotation.status,
    annotation.created_at_ms,
    source_ids=robot_gait_annotation_source_ids(annotation),
    data_refs=robot_gait_annotation_data_refs(annotation),
    summary=annotation.summary,
  )
}

///|
pub fn robot_gait_clip_version(
  clip : RobotGaitClipManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    clip.clip_id,
    clip.status,
    clip.created_at_ms,
    parent_version_ids~,
    data_refs=robot_gait_clip_data_refs(clip),
    summary=clip.summary,
  )
}

///|
pub fn robot_gait_annotation_version(
  annotation : RobotGaitAnnotationManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    annotation.annotation_id,
    annotation.status,
    annotation.created_at_ms,
    parent_version_ids~,
    data_refs=robot_gait_annotation_data_refs(annotation),
    summary=annotation.summary,
  )
}

///|
pub fn robot_gait_clip_lineage(
  clip : RobotGaitClipManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_gait_clip_dataset(clip)
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
        clip.source_id,
        "sources/\{clip.source_id}.json",
        status=clip.status,
        summary=clip.source_label,
      ),
      root,
      "robot-gait-clip-import",
    ),
  ]
  for model in clip.model_refs {
    let source = robot_model_data_source(model)
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source.source_id,
          "sources/\{source.source_id}.json",
          status=clip.status,
          summary=source.label,
        ),
        root,
        "robot-gait-model-source",
      ),
    )
  }
  @data_core.lineage_manifest(lineage_id, root, clip.created_at_ms, edges~)
}

///|
pub fn robot_gait_annotation_lineage(
  annotation : RobotGaitAnnotationManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_gait_annotation_dataset(annotation)
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
        annotation.source_id,
        "sources/\{annotation.source_id}.json",
        status=annotation.status,
        summary=annotation.source_label,
      ),
      root,
      "robot-gait-annotation-import",
    ),
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "dataset",
        annotation.clip_id,
        "datasets/\{annotation.clip_id}.json",
        status=annotation.status,
        summary="annotated gait clip",
      ),
      root,
      "robot-gait-clip-annotated",
    ),
  ]
  for model in annotation.model_refs {
    let source = robot_model_data_source(model)
    edges.push(
      @data_core.lineage_edge(
        @data_core.artifact_ref(
          "source",
          source.source_id,
          "sources/\{source.source_id}.json",
          status=annotation.status,
          summary=source.label,
        ),
        root,
        "robot-gait-annotation-model-source",
      ),
    )
  }
  @data_core.lineage_manifest(
    lineage_id,
    root,
    annotation.created_at_ms,
    edges~,
  )
}
