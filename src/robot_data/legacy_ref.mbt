///|
let legacy_moondata_scheme = "moondata://"

///|
pub fn robot_legacy_moondata_relative_path(uri : String) -> String? {
  if uri.has_prefix(legacy_moondata_scheme) &&
    uri.length() > legacy_moondata_scheme.length() {
    let path = uri[legacy_moondata_scheme.length():uri.length()].to_owned()
    if @data_core.data_relative_path_is_safe(path) {
      Some(path)
    } else {
      None
    }
  } else {
    None
  }
}

///|
pub fn robot_legacy_moondata_payload_path(uri : String) -> String? {
  match robot_legacy_moondata_relative_path(uri) {
    Some(path) if path.has_prefix("payloads/robot_data/") => Some(path)
    Some(path) => Some("payloads/robot_data/" + path)
    None => None
  }
}

///|
pub fn robot_legacy_moondata_payload_ref(
  ref_id : RobotPayloadRefId,
  legacy_uri : String,
  role : String,
  content_type : String,
  byte_count : Int64,
  sha256 : String,
) -> RobotPayloadRef? {
  match robot_legacy_moondata_payload_path(legacy_uri) {
    Some(path) =>
      Some(
        robot_payload_ref(ref_id, role, path, content_type, byte_count, sha256),
      )
    None => None
  }
}
