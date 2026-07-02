///|
let data_uri_scheme = "data://"

///|
pub fn data_uri(relative_path : String) -> String {
  data_uri_scheme + relative_path
}

///|
pub fn data_uri_relative_path(uri : String) -> String? {
  if uri.has_prefix(data_uri_scheme) && uri.length() > data_uri_scheme.length() {
    Some(uri[data_uri_scheme.length():uri.length()].to_owned())
  } else {
    None
  }
}

///|
pub fn data_relative_path_is_safe(path : String) -> Bool {
  path != "" &&
  path != "." &&
  path != ".." &&
  !path.has_prefix("/") &&
  !path.has_suffix("/") &&
  !path.contains("\\") &&
  !path.contains("//") &&
  !path.contains("/../") &&
  !path.has_prefix("../") &&
  !path.has_suffix("/..") &&
  !path.contains("/./") &&
  !path.has_prefix("./") &&
  !path.has_suffix("/.")
}

///|
pub fn data_payload_uri_relative_path(uri : String) -> String? {
  match data_uri_relative_path(uri) {
    Some(path) if data_relative_path_is_safe(path) => Some(path)
    _ => None
  }
}

///|
pub fn data_payload_root(uri : String) -> String {
  match data_payload_uri_relative_path(uri) {
    Some(path) =>
      if path.has_prefix("payloads/") {
        "payloads"
      } else if path.has_prefix("artifacts/") {
        "artifacts"
      } else if path.has_prefix("exports/") {
        "exports"
      } else {
        "other"
      }
    None => "external"
  }
}
