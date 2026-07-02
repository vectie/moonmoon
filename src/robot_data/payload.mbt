///|
pub type RobotPayloadRefId = String

///|
pub(all) struct RobotPayloadRef {
  ref_id : RobotPayloadRefId
  role : String
  path : String
  content_type : String
  byte_count : Int64
  checksum : @data_core.DeclaredChecksum
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
  robot_payload_ref_with_checksum(
    ref_id,
    role,
    path,
    content_type,
    byte_count,
    @data_core.declared_checksum(@data_core.ChecksumKind::Sha256, sha256),
  )
}

///|
pub fn robot_payload_ref_with_checksum(
  ref_id : RobotPayloadRefId,
  role : String,
  path : String,
  content_type : String,
  byte_count : Int64,
  checksum : @data_core.DeclaredChecksum,
) -> RobotPayloadRef {
  { ref_id, role, path, content_type, byte_count, checksum }
}

///|
pub fn robot_payload_data_ref(payload : RobotPayloadRef) -> @data_core.DataRef {
  @data_core.data_ref(
    payload.ref_id,
    payload.role,
    @data_core.data_uri(payload.path),
    content_type=payload.content_type,
    byte_count=payload.byte_count,
    checksum=payload.checksum,
  )
}
