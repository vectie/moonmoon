///|
pub type RobotPayloadRefId = String

///|
pub(all) struct RobotPayloadRef {
  ref_id : RobotPayloadRefId
  role : String
  path : String
  content_type : String
  byte_count : Int64
  sha256 : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn robot_payload_ref(
  ref_id : RobotPayloadRefId,
  role : String,
  path : String,
  content_type : String,
  byte_count : Int64,
  sha256 : String,
) -> RobotPayloadRef {
  { ref_id, role, path, content_type, byte_count, sha256 }
}

///|
pub fn robot_payload_data_ref(payload : RobotPayloadRef) -> @data_core.DataRef {
  @data_core.data_ref(
    payload.ref_id,
    payload.role,
    @data_core.data_uri(payload.path),
    content_type=payload.content_type,
    byte_count=payload.byte_count,
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::Sha256,
      payload.sha256,
    ),
  )
}
