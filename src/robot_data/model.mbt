///|
pub type RobotId = String

///|
pub type RobotModelId = String

///|
pub(all) struct RobotModelRef {
  model_id : RobotModelId
  robot_id : RobotId
  source_id : @data_core.SourceId
  label : String
  model_kind : String
  authority : String
  source_url : String
  license : String
  citation : String
  created_at_ms : Int64
  payload : RobotPayloadRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_model_ref(
  model_id : RobotModelId,
  robot_id : RobotId,
  source_id : @data_core.SourceId,
  label : String,
  model_kind : String,
  authority : String,
  source_url : String,
  license : String,
  citation : String,
  created_at_ms : Int64,
  payload : RobotPayloadRef,
) -> RobotModelRef {
  {
    model_id,
    robot_id,
    source_id,
    label,
    model_kind,
    authority,
    source_url,
    license,
    citation,
    created_at_ms,
    payload,
  }
}

///|
pub fn robot_model_data_source(model : RobotModelRef) -> @data_core.DataSource {
  @data_core.data_source(
    model.source_id,
    model.authority,
    model.label,
    model.source_url,
    model.license,
    model.citation,
    model.created_at_ms,
    source_refs=[robot_payload_data_ref(model.payload)],
  )
}
