///|
/// Direct local-file commands only; no listener or remote reference resolution.
fn run() -> Unit raise {
  let args = @env.args()
  match args[1:] {
    ["run-draft", draft_path, new_workspace] => {
      let envelope = @mission_adapter.run_mission_draft(
        @fsx.read_file_to_string(draft_path),
        new_workspace,
      )
      let study = @mission_adapter.decode_study(envelope.to_json().stringify())
      println(
        new_workspace +
        "/" +
        @mission_adapter.study_ref(study.study_id, study.revision),
      )
      println(envelope.dossier_digest)
      println(
        "Reimport this dossier in the study UI. Review is required. Local digital simulation only; no physical authority.",
      )
    }
    ["inspect-draft", draft_path] => {
      let text = @fsx.read_file_to_string(draft_path)
      let envelope : @mission_adapter.MissionDraftEnvelope = @json.from_json(
        @json.parse(text),
      )
      if envelope.contract_id == "moonmoon.mission-draft-envelope.v2" {
        println(
          @mission_adapter.decode_sensitivity_draft(text)
          .to_json()
          .stringify(indent=2),
        )
      } else {
        println(
          @mission_adapter.decode_mission_draft(text)
          .to_json()
          .stringify(indent=2),
        )
      }
    }
    [
      "create",
      root,
      study_id,
      revision,
      parent_digest,
      site_path,
      first,
      second,
    ] => {
      let site : @mission_adapter.StudySite = @json.from_json(
        @json.parse(@fsx.read_file_to_string(site_path)),
      )
      let envelope = @mission_adapter.create_study(
        root,
        study_id,
        revision,
        if parent_digest == "none" {
          ""
        } else {
          parent_digest
        },
        site,
        [first, second],
      )
      let reference = @mission_adapter.save_study(root, envelope)
      println(reference)
      println(envelope.dossier_digest)
    }
    ["inspect", path] => {
      let study = @mission_adapter.decode_study(@fsx.read_file_to_string(path))
      println(study.to_json().stringify(indent=2))
    }
    ["export-result", path, session_id, output] => {
      let study = @mission_adapter.decode_study(@fsx.read_file_to_string(path))
      guard study.alternatives
        .filter(item => item.session_id == session_id)
        .get(0)
        is Some(alternative) else {
        fail("Unknown study session")
      }
      guard study.sources
        .filter(item => item.artifact_ref == alternative.result_ref)
        .get(0)
        is Some(source) else {
        fail("Missing exact result")
      }
      if @fsx.path_exists(output) {
        fail("Output already exists; choose a new path")
      }
      @fsx.write_string_to_file(output, source.text)
      println(source.digest)
      println(
        "Manual digital evidence only. MoonFlow delivery and MoonRobo acknowledgement are pending. No physical authority.",
      )
    }
    _ =>
      println(
        "mission_study create <workspace-root> <study-id> <revision> <parent-digest|none> <site.json> <session-a> <session-b>\nmission_study inspect <dossier.json>\nmission_study export-result <dossier.json> <session-id> <new-output.json>\nmission_study inspect-draft <draft.json>\nmission_study run-draft <draft.json> <new-workspace>",
      )
  }
}

///|
fn main {
  run() catch {
    @mission_adapter.StudyError::InvalidStudy(message) => {
      println("Mission study error: " + message)
      @sys.exit(2)
    }
    error => {
      println("Mission study error: " + error.to_string())
      @sys.exit(2)
    }
  }
}
