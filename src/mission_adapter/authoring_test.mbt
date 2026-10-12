///|
fn authoring_parent_text() -> String raise {
  @fsx.read_file_to_string("ui/rabbita-moon/fixtures/mission-study-local.json")
}

///|
fn authoring_draft(robot? : String = "") -> @mission_adapter.MissionDraft raise {
  let parent_text = authoring_parent_text()
  let envelope : @mission_adapter.StudyEnvelope = @json.from_json(
    @json.parse(parent_text),
  )
  {
    contract_id: "moonmoon.mission-draft.v1",
    study_id: "local-study",
    revision: "authored-r2",
    parent_envelope_json: parent_text,
    parent_digest: envelope.dossier_digest,
    base_session_id: "q11-a",
    robot_envelope_json: robot,
    edits: {
      route_id: "authored-northbound",
      path_cells: [[3, 3], [2, 3], [1, 3], [0, 3]],
      terrain_available_energy_wh: 1.0,
      commanded_speed_mps: 0.05,
      seed: 2026,
      injected_faults: [],
      assumption_note: "Inert fixture: reverse route, lower speed and assumed available energy. Not source truth.",
    },
    review_required: true,
    physical_execution_allowed: false,
  }
}

///|
fn authoring_envelope(draft : @mission_adapter.MissionDraft) -> String {
  let draft_json = draft.to_json().stringify(indent=2) + "\n"
  let envelope : @mission_adapter.MissionDraftEnvelope = {
    contract_id: "moonmoon.mission-draft-envelope.v1",
    draft_digest: "sha256:" + study_hash(draft_json),
    draft_json,
  }
  envelope.to_json().stringify(indent=2) + "\n"
}

///|
fn authoring_new_root(label : String) -> String raise {
  for index in 0..<10000 {
    let path = "/tmp/moonmoon-authoring-" + label + "-" + index.to_string()
    if !@fsx.path_exists(path) {
      return path
    }
  }
  fail("No unused authoring test workspace")
}

///|
fn authoring_result(
  study : @mission_adapter.MissionStudy,
  index : Int,
) -> @robot_mission.RobotMissionResult raise {
  let ref = study.alternatives[index].result_ref
  let source = study.sources.filter(item => item.artifact_ref == ref)[0]
  @json.from_json(@json.parse(source.text))
}

///|
test "authored frozen inputs run real simulator, preserve parent, and keep negative energy rejected" {
  let draft = authoring_draft()
  let text = authoring_envelope(draft)
  assert_eq(@mission_adapter.decode_mission_draft(text), draft)
  let root = authoring_new_root("energy")
  let result = @mission_adapter.run_mission_draft(text, root)
  let study = @mission_adapter.decode_study(result.to_json().stringify())
  assert_eq(study.parent_digest, draft.parent_digest)
  assert_true(study.review_required)
  assert_false(study.physical_readiness)
  assert_eq(
    study.alternatives[0].baseline_digest,
    study.alternatives[1].baseline_digest,
  )
  let reference = authoring_result(study, 0)
  let alternative = authoring_result(study, 1)
  assert_eq(reference.result, "accepted")
  assert_eq(alternative.result, "rejected")
  assert_eq(alternative.seed, 2026)
  assert_eq(alternative.route_id, "authored-northbound")
  assert_eq(alternative.distance_m, 60.0)
  assert_eq(alternative.duration_s, 1200.0)
  assert_true(alternative.energy.margin_wh < 0.0)
  assert_true(
    alternative.blockers.contains("energy margin is below the required minimum"),
  )
  assert_false(
    alternative.blockers.any(item => {
      item.contains("does not match verification criteria")
    }),
  )
  assert_eq(authoring_parent_text(), draft.parent_envelope_json)
  assert_true((try? @mission_adapter.run_mission_draft(text, root)) is Err(_))
  @fsx.write_string_to_file(root + "/input-draft.json", text)
  println("authoring-energy-evidence=" + root)
  // A second fork from an authored dossier must remain usable.
  let second = {
    ..draft,
    revision: "authored-r3",
    parent_envelope_json: result.to_json().stringify(),
    parent_digest: result.dossier_digest,
    base_session_id: study.alternatives[0].session_id,
  }
  let second_result = @mission_adapter.run_mission_draft(
    authoring_envelope(second),
    authoring_new_root("second-fork"),
  )
  assert_eq(
    @mission_adapter.decode_study(second_result.to_json().stringify()).parent_digest,
    result.dossier_digest,
  )
}

///|
test "actual MoonRobo-produced robot package runs compatible pair with calibration reset" {
  let robot = @fsx.read_file_to_string(
    "ui/rabbita-moon/fixtures/moonrobo-simulation-input.json",
  )
  let draft = authoring_draft(robot~)
  let root = authoring_new_root("robot")
  let envelope = @mission_adapter.run_mission_draft(
    authoring_envelope(draft),
    root,
  )
  let study = @mission_adapter.decode_study(envelope.to_json().stringify())
  let result = authoring_result(study, 1)
  assert_eq(result.robot_id, "excavation-haul")
  assert_eq(result.robot_revision, "r1")
  assert_true(result.artifact_binding_verified)
  assert_eq(result.result, "rejected")
  assert_true(result.energy.margin_wh < 0.0)
  assert_eq(
    study.alternatives[0].baseline_digest,
    study.alternatives[1].baseline_digest,
  )
  let parent = @mission_adapter.decode_study(draft.parent_envelope_json)
  assert_true(
    study.alternatives[0].baseline_digest !=
    parent.alternatives[0].baseline_digest,
  )
  assert_true(
    study.limitations.any(item => item.contains("Prior calibration was cleared")),
  )
  @fsx.write_string_to_file(
    root + "/input-draft.json",
    authoring_envelope(draft),
  )
  println("authoring-robot-evidence=" + root)
}

///|
test "unknown faults produce native fail-closed evidence rather than invented physics" {
  let original = authoring_draft()
  let draft = {
    ..original,
    edits: {
      ..original.edits,
      terrain_available_energy_wh: 3997.0,
      injected_faults: ["unknown-wheel-fault"],
    },
  }
  let envelope = @mission_adapter.run_mission_draft(
    authoring_envelope(draft),
    authoring_new_root("fault"),
  )
  let study = @mission_adapter.decode_study(envelope.to_json().stringify())
  let result = authoring_result(study, 1)
  assert_eq(result.result, "rejected")
  assert_eq(result.scenario_outcome, "fail-closed")
  assert_true(
    result.blockers.any(item => item.contains("no qualified calibration")),
  )
}

///|
test "invalid draft fields cannot overwrite parent or start execution" {
  let original = authoring_draft()
  for
    draft in [
      { ..original, physical_execution_allowed: true, },
      { ..original, revision: "r1", },
      { ..original, parent_digest: "sha256:" + "0".repeat(64), },
      { ..original, base_session_id: "missing", },
      {
        ..original,
        edits: { ..original.edits, path_cells: [[-1, 0], [0, 0]], },
      },
      { ..original, edits: { ..original.edits, commanded_speed_mps: 0.0, }, },
      { ..original, edits: { ..original.edits, assumption_note: "", }, },
      {
        ..original,
        edits: { ..original.edits, injected_faults: ["fault", "fault"], },
      },
    ] {
    assert_true(
      (try? @mission_adapter.decode_mission_draft(authoring_envelope(draft)))
      is Err(_),
    )
  }
  let invalid = authoring_envelope(original).replace(
    old="moonmoon.mission-draft-envelope.v1",
    new="physical",
  )
  assert_true((try? @mission_adapter.decode_mission_draft(invalid)) is Err(_))
}
