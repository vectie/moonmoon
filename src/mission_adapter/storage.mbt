///|
fn issue(code : String, path : String, message : String) -> AdapterRuntimeIssue {
  { code, path, message }
}

///|
fn trim_trailing_slash(path : String) -> String {
  let mut value = path
  while value.length() > 1 && value.has_suffix("/") {
    value = value[:value.length() - 1].to_owned()
  }
  value
}

///|
fn safe_relative_ref(value : String) -> Bool {
  let normalized = value.trim().replace(old="\\", new="/")
  !normalized.is_empty() &&
  !normalized.has_prefix("/") &&
  !normalized
  .split("/")
  .any(segment => segment == "" || segment == "." || segment == "..")
}

///|
fn safe_component(value : String) -> Bool {
  !value.trim().is_empty() &&
  !value.contains("/") &&
  !value.contains("\\") &&
  value != "." &&
  value != ".."
}

///|
fn resolve_ref(
  workspace_root : String,
  artifact_ref : String,
) -> Result[String, AdapterRuntimeIssue] {
  if workspace_root.trim().is_empty() {
    return Err(
      issue(
        "workspace-root-missing", workspace_root, "MoonMoon adapter requires a host-selected workspace root",
      ),
    )
  }
  if !safe_relative_ref(artifact_ref) {
    return Err(
      issue(
        "unsafe-artifact-ref", artifact_ref, "MoonMoon artifacts must be workspace-relative without traversal",
      ),
    )
  }
  Ok(trim_trailing_slash(workspace_root) + "/" + artifact_ref)
}

///|
fn ensure_dir(path : String) -> Result[Unit, AdapterRuntimeIssue] {
  if @fsx.path_exists(path) {
    return Ok(())
  }
  @fsx.create_dir(path) catch {
    _ =>
      return Err(
        issue(
          "create-directory", path, "failed to create MoonMoon adapter directory",
        ),
      )
  }
  Ok(())
}

///|
fn ensure_directory_tree(path : String) -> Result[Unit, AdapterRuntimeIssue] {
  let absolute = path.has_prefix("/")
  let mut current = if absolute { "" } else { "." }
  for component in path.split("/") {
    if component == "" || component == "." {
      continue
    }
    let owned = component.to_owned()
    current = if current == "" || current == "/" {
      "/" + owned
    } else {
      current + "/" + owned
    }
    match ensure_dir(current) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
fn write_text(
  path : String,
  text : String,
) -> Result[Unit, AdapterRuntimeIssue] {
  match ensure_directory_tree(@pathx.dirname(path).to_owned()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  @fsx.write_string_to_file(path, text) catch {
    _ =>
      return Err(
        issue(
          "write-adapter-evidence", path, "failed to persist MoonMoon adapter evidence",
        ),
      )
  }
  Ok(())
}

///|
fn write_json(path : String, value : Json) -> Result[Unit, AdapterRuntimeIssue] {
  write_text(path, value.stringify(indent=2) + "\n")
}

///|
fn read_text(path : String) -> Result[String, AdapterRuntimeIssue] {
  try @fsx.read_file_to_string(path) catch {
    _ =>
      Err(
        issue(
          "read-adapter-evidence", path, "failed to read MoonMoon adapter evidence",
        ),
      )
  } noraise {
    text => Ok(text)
  }
}

///|
fn read_json(path : String) -> Result[Json, AdapterRuntimeIssue] {
  let text = match read_text(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  try @json.parse(text) catch {
    _ =>
      Err(
        issue(
          "parse-adapter-evidence", path, "failed to parse MoonMoon adapter JSON",
        ),
      )
  } noraise {
    value => Ok(value)
  }
}

///|
fn[T : @json.FromJson] read_typed(
  path : String,
) -> Result[T, AdapterRuntimeIssue] {
  let value = match read_json(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  try @json.from_json(value) catch {
    _ =>
      Err(
        issue(
          "decode-adapter-evidence", path, "failed to decode typed MoonMoon adapter evidence",
        ),
      )
  } noraise {
    value => Ok(value)
  }
}

///|
fn sha256_text(text : String) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text)))
}

///|
fn sha256_bytes(bytes : Bytes) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn digest_valid(value : String) -> Bool {
  value.length() == 71 &&
  value.has_prefix("sha256:") &&
  value[7:]
  .iter()
  .all(char => char.is_ascii_digit() || ('a' <= char && char <= 'f'))
}

///|
fn attempt_root_ref(attempt_id : String) -> String {
  ".moonsuite/products/moonmoon/adapter-attempts/\{attempt_id}"
}

///|
fn request_ref(attempt_id : String) -> String {
  attempt_root_ref(attempt_id) + "/request.json"
}

///|
fn state_ref(attempt_id : String) -> String {
  attempt_root_ref(attempt_id) + "/attempt.json"
}

///|
fn operation_receipt_ref(attempt_id : String) -> String {
  attempt_root_ref(attempt_id) + "/operation-receipt.json"
}

///|
fn adapter_result_ref(attempt_id : String) -> String {
  attempt_root_ref(attempt_id) + "/adapter-result.json"
}

///|
fn reconciliation_ref(attempt_id : String) -> String {
  attempt_root_ref(attempt_id) + "/reconciliation.json"
}

///|
fn session_root_ref(session_id : String) -> String {
  ".moonsuite/products/moonmoon/mission-sessions/\{session_id}"
}

///|
fn mission_result_ref(session_id : String) -> String {
  session_root_ref(session_id) + "/mission-result.json"
}

///|
fn replay_result_ref(session_id : String) -> String {
  session_root_ref(session_id) + "/replay-result.json"
}

///|
fn replay_receipt_ref(session_id : String) -> String {
  session_root_ref(session_id) + "/replay-receipt.json"
}

///|
fn provenance_ref(session_id : String) -> String {
  session_root_ref(session_id) + "/provenance.json"
}

///|
fn evaluation_ref(session_id : String) -> String {
  session_root_ref(session_id) + "/evaluation.json"
}

///|
fn inspection_ref(session_id : String, attempt_id : String) -> String {
  session_root_ref(session_id) + "/inspections/\{attempt_id}.json"
}

///|
fn input_artifact(
  workspace_root : String,
  request : MoonflowAdapterRequest,
) -> Result[(String, String, String), AdapterRuntimeIssue] {
  guard request.input_artifacts is [artifact_ref, ..] else {
    return Err(
      issue(
        "missing-operation-input",
        request.operation,
        "operation requires one workspace-relative typed input artifact",
      ),
    )
  }
  let path = match resolve_ref(workspace_root, artifact_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let text = match read_text(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok((artifact_ref, path, text))
}

///|
fn input_artifact_set_digest(
  workspace_root : String,
  artifact_refs : Array[String],
) -> Result[String, AdapterRuntimeIssue] {
  if artifact_refs.is_empty() {
    return Err(
      issue(
        "missing-operation-input", "", "a typed primary input artifact is required",
      ),
    )
  }
  let identities : Array[String] = []
  for artifact_ref in artifact_refs {
    let path = match resolve_ref(workspace_root, artifact_ref) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let bytes = @fsx.read_file_to_bytes(path) catch {
      _ =>
        return Err(
          issue(
            "read-operation-evidence", path, "failed to read MoonMoon input artifact evidence",
          ),
        )
    }
    identities.push("\{artifact_ref}|\{sha256_bytes(bytes)}")
  }
  Ok(sha256_text(identities.join("\n")))
}

///|
fn all_exist(workspace_root : String, refs : Array[String]) -> Bool {
  refs.all(reference => {
    match resolve_ref(workspace_root, reference) {
      Ok(path) => @fsx.path_exists(path)
      Err(_) => false
    }
  })
}

///|
fn any_exist(workspace_root : String, refs : Array[String]) -> Bool {
  refs.any(reference => {
    match resolve_ref(workspace_root, reference) {
      Ok(path) => @fsx.path_exists(path)
      Err(_) => false
    }
  })
}
