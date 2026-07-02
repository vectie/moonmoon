///|
pub type DataRefId = String

///|
pub type ArtifactId = String

///|
pub(all) struct DataRef {
  ref_id : DataRefId
  kind : String
  uri : String
  content_type : String
  byte_count : Int64
  checksum : DeclaredChecksum
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ArtifactRef {
  artifact_kind : String
  artifact_id : ArtifactId
  manifest_path : String
  status : DataStatus
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn data_ref(
  ref_id : DataRefId,
  kind : String,
  uri : String,
  content_type? : String = "application/octet-stream",
  byte_count? : Int64 = 0L,
  checksum? : DeclaredChecksum = declared_checksum(NoChecksum, ""),
) -> DataRef {
  { ref_id, kind, uri, content_type, byte_count, checksum }
}

///|
pub fn artifact_ref(
  artifact_kind : String,
  artifact_id : ArtifactId,
  manifest_path : String,
  status? : DataStatus = UnknownStatus,
  summary? : String = "",
) -> ArtifactRef {
  { artifact_kind, artifact_id, manifest_path, status, summary }
}

///|
pub fn artifact_ref_status_label(artifact : ArtifactRef) -> String {
  data_status_label(artifact.status)
}
