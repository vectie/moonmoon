///|
pub type RobotTelemetryStreamId = String

///|
pub(all) struct RobotTelemetryPayloadRef {
  channel : String
  sample_count : Int
  unit : String
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotTelemetryStreamManifest {
  stream_id : RobotTelemetryStreamId
  robot_id : RobotId
  session_id : String
  source_id : @data_core.SourceId
  source_label : String
  source_url : String
  status : @data_core.DataStatus
  created_at_ms : Int64
  payload_refs : Array[RobotTelemetryPayloadRef]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_telemetry_payload_ref(
  channel : String,
  sample_count : Int,
  unit : String,
  payload : RobotPayloadRef,
) -> RobotTelemetryPayloadRef {
  { channel, sample_count, unit, payload }
}

///|
pub fn robot_telemetry_stream_manifest(
  stream_id : RobotTelemetryStreamId,
  robot_id : RobotId,
  session_id : String,
  source_id : @data_core.SourceId,
  source_label : String,
  source_url : String,
  status : @data_core.DataStatus,
  created_at_ms : Int64,
  payload_refs : Array[RobotTelemetryPayloadRef],
  summary : String,
) -> RobotTelemetryStreamManifest {
  {
    stream_id,
    robot_id,
    session_id,
    source_id,
    source_label,
    source_url,
    status,
    created_at_ms,
    payload_refs,
    summary,
  }
}

///|
pub fn robot_telemetry_data_refs(
  stream : RobotTelemetryStreamManifest,
) -> Array[@data_core.DataRef] {
  stream.payload_refs.map(fn(payload) {
    robot_payload_data_ref(payload.payload)
  })
}

///|
pub fn robot_telemetry_data_source(
  stream : RobotTelemetryStreamManifest,
) -> @data_core.DataSource {
  @data_core.data_source(
    stream.source_id,
    "Robot telemetry stream",
    stream.source_label,
    stream.source_url,
    "local import",
    "Imported by MoonMoon robot_catalog",
    stream.created_at_ms,
    source_refs=robot_telemetry_data_refs(stream),
  )
}

///|
pub fn robot_telemetry_dataset(
  stream : RobotTelemetryStreamManifest,
) -> @data_core.DatasetManifest {
  @data_core.dataset_manifest(
    stream.stream_id,
    "robot-telemetry-stream",
    stream.status,
    stream.created_at_ms,
    source_ids=[stream.source_id],
    data_refs=robot_telemetry_data_refs(stream),
    summary=stream.summary,
  )
}

///|
pub fn robot_telemetry_version(
  stream : RobotTelemetryStreamManifest,
  version_id : @data_core.DatasetVersionId,
  parent_version_ids? : Array[@data_core.DatasetVersionId] = [],
) -> @data_core.DatasetVersion {
  @data_core.dataset_version(
    version_id,
    stream.stream_id,
    stream.status,
    stream.created_at_ms,
    parent_version_ids~,
    data_refs=robot_telemetry_data_refs(stream),
    summary=stream.summary,
  )
}

///|
pub fn robot_telemetry_lineage(
  stream : RobotTelemetryStreamManifest,
  lineage_id : @data_core.LineageId,
) -> @data_core.LineageManifest {
  let dataset = robot_telemetry_dataset(stream)
  let root = @data_core.artifact_ref(
    "dataset",
    dataset.dataset_id,
    "datasets/\{dataset.dataset_id}.json",
    status=dataset.status,
    summary=dataset.summary,
  )
  @data_core.lineage_manifest(lineage_id, root, stream.created_at_ms, edges=[
    @data_core.lineage_edge(
      @data_core.artifact_ref(
        "source",
        stream.source_id,
        "sources/\{stream.source_id}.json",
        status=stream.status,
        summary=stream.source_label,
      ),
      root,
      "robot-telemetry-stream-import",
    ),
  ])
}
