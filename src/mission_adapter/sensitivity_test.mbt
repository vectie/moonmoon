///|
fn sensitivity_draft(
  count : Int,
  robot? : String = "",
) -> @mission_adapter.SensitivityMissionDraft raise {
  let single = authoring_draft(robot~)
  let variants : Array[@mission_adapter.MissionDraftVariant] = [
    { variant_id: "energy", name: "Low available energy", edits: single.edits, },
    {
      variant_id: "speed",
      name: "Faster route",
      edits: {
        ..single.edits,
        terrain_available_energy_wh: 3997.0,
        commanded_speed_mps: 0.1,
        seed: 2027,
        assumption_note: "Independent speed assumption",
      },
    },
    {
      variant_id: "fault",
      name: "Unsupported fault",
      edits: {
        ..single.edits,
        terrain_available_energy_wh: 3997.0,
        injected_faults: ["unknown-wheel-fault"],
        seed: 2028,
        assumption_note: "Unsupported fault must fail closed",
      },
    },
    {
      variant_id: "route",
      name: "Unsupported route",
      edits: {
        ..single.edits,
        terrain_available_energy_wh: 3997.0,
        path_cells: [[100, 100], [101, 100]],
        seed: 2029,
        assumption_note: "Out-of-grid route must fail closed",
      },
    },
  ]
  {
    contract_id: "moonmoon.mission-draft.v2",
    study_id: single.study_id,
    revision: "sensitivity-r2",
    parent_envelope_json: single.parent_envelope_json,
    parent_digest: single.parent_digest,
    base_session_id: single.base_session_id,
    robot_envelope_json: single.robot_envelope_json,
    variants: variants[:count].to_array(),
    review_required: true,
    physical_execution_allowed: false,
  }
}

///|
fn sensitivity_envelope(
  draft : @mission_adapter.SensitivityMissionDraft,
) -> String {
  let draft_json = draft.to_json().stringify(indent=2) + "\n"
  let envelope : @mission_adapter.MissionDraftEnvelope = {
    contract_id: "moonmoon.mission-draft-envelope.v2",
    draft_digest: "sha256:" + study_hash(draft_json),
    draft_json,
  }
  envelope.to_json().stringify(indent=2) + "\n"
}

///|
test "sensitivity reference plus two and four variants preserves independent actual outcomes" {
  for count in [2, 4] {
    let draft = sensitivity_draft(count)
    let text = sensitivity_envelope(draft)
    assert_eq(@mission_adapter.decode_sensitivity_draft(text), draft)
    let root = authoring_new_root("sensitivity-" + count.to_string())
    let result = @mission_adapter.run_mission_draft(text, root)
    let study = @mission_adapter.decode_study(result.to_json().stringify())
    assert_eq(study.alternatives.length(), count + 1)
    assert_eq(study.parent_digest, draft.parent_digest)
    assert_true(study.review_required)
    assert_false(study.physical_readiness)
    assert_eq(
      study.alternatives
      .filter(item => item.session_id.has_suffix("-reference"))
      .length(),
      1,
    )
    assert_true(
      study.alternatives.all(item => {
        item.baseline_digest == study.alternatives[0].baseline_digest
      }),
    )
    let reference = authoring_result(study, 0)
    let energy = authoring_result(study, 1)
    let speed = authoring_result(study, 2)
    assert_eq(reference.result, "accepted")
    assert_eq(energy.result, "rejected")
    assert_true(energy.energy.margin_wh < 0.0)
    assert_eq(energy.duration_s, 1200.0)
    assert_eq(speed.duration_s, 600.0)
    assert_true(speed.energy.margin_wh > 0.0)
    assert_eq(speed.seed, 2027)
    assert_false(
      speed.blockers.contains("energy margin is below the required minimum"),
    )
    if count == 4 {
      let fault = authoring_result(study, 3)
      let route = authoring_result(study, 4)
      assert_eq(fault.result, "rejected")
      assert_eq(fault.scenario_outcome, "fail-closed")
      assert_true(
        fault.blockers.any(item => item.contains("no qualified calibration")),
      )
      assert_eq(route.result, "rejected")
      assert_eq(route.seed, 2029)
      assert_true(route.blockers.length() > 0)
    }
    assert_eq(
      study.limitations
      .filter(item => item.has_prefix("Authored variant: "))
      .length(),
      count,
    )
    assert_eq(authoring_parent_text(), draft.parent_envelope_json)
    assert_true((try? @mission_adapter.run_mission_draft(text, root)) is Err(_))
    let repeated = @mission_adapter.run_mission_draft(
      text,
      authoring_new_root("sensitivity-replay-" + count.to_string()),
    )
    assert_eq(repeated, result)
    @fsx.write_string_to_file(root + "/input-draft.json", text)
    println("sensitivity-" + count.to_string() + "-evidence=" + root)
  }
}

///|
test "sensitivity robot adoption clears qualifications and fault models for every alternative" {
  let robot = @fsx.read_file_to_string(
    "ui/rabbita-moon/fixtures/moonrobo-simulation-input.json",
  )
  let draft = sensitivity_draft(4, robot~)
  let root = authoring_new_root("sensitivity-robot")
  let envelope = @mission_adapter.run_mission_draft(
    sensitivity_envelope(draft),
    root,
  )
  let study = @mission_adapter.decode_study(envelope.to_json().stringify())
  let parent = @mission_adapter.decode_study(draft.parent_envelope_json)
  assert_true(
    study.alternatives[0].baseline_digest !=
    parent.alternatives[0].baseline_digest,
  )
  for alternative in study.alternatives {
    let design : @robot_mission.RobotMissionDesign = @json.from_json(
      @json.parse(
        study.sources.filter(item => item.artifact_ref == alternative.design_ref)[0].text,
      ),
    )
    assert_eq(design.robot_artifact.robot_id, "excavation-haul")
    assert_false(design.environment.calibration.qualified)
    assert_eq(design.environment.calibration.fault_models.length(), 0)
    assert_eq(
      design.environment.calibration.testbed_reference,
      "unqualified:robot-input-adoption",
    )
    assert_eq(
      alternative.baseline_digest,
      study.alternatives[0].baseline_digest,
    )
  }
  assert_false(study.physical_readiness)
  assert_eq(authoring_parent_text(), draft.parent_envelope_json)
}

///|
test "sensitivity count identity field and envelope byte bounds reject before output" {
  let draft = sensitivity_draft(2)
  let first = draft.variants[0]
  for
    invalid in [
      { ..draft, variants: [], },
      { ..draft, variants: [first], },
      { ..draft, variants: [first, first, first, first, first], },
      { ..draft, variants: [first, first], },
      { ..draft, variants: [first, { ..first, variant_id: "reference", }], },
      { ..draft, variants: [first, { ..first, variant_id: "../escape", }], },
      { ..draft, variants: [first, { ..first, variant_id: "a".repeat(65), }], },
      {
        ..draft,
        variants: [first, { ..first, variant_id: "other", name: " ", }],
      },
      {
        ..draft,
        variants: [
          first,
          { ..first, variant_id: "other", name: "a".repeat(121), },
        ],
      },
      {
        ..draft,
        variants: [
          first,
          {
            ..first,
            variant_id: "other",
            edits: { ..first.edits, terrain_available_energy_wh: -1.0, },
          },
        ],
      },
      {
        ..draft,
        variants: [
          first,
          {
            ..first,
            variant_id: "other",
            edits: { ..first.edits, assumption_note: "x".repeat(2001), },
          },
        ],
      },
      { ..draft, physical_execution_allowed: true, },
      { ..draft, parent_digest: "sha256:" + "0".repeat(64), },
      { ..draft, revision: "r1", },
    ] {
    let root = authoring_new_root("sensitivity-invalid")
    let text = sensitivity_envelope(invalid)
    assert_true(
      (try? @mission_adapter.decode_sensitivity_draft(text)) is Err(_),
    )
    assert_true((try? @mission_adapter.run_mission_draft(text, root)) is Err(_))
    assert_false(@fsx.path_exists(root))
  }
  let max_id = {
    ..draft,
    variants: [first, { ..first, variant_id: "a".repeat(64), }],
  }
  assert_eq(
    @mission_adapter.decode_sensitivity_draft(sensitivity_envelope(max_id)),
    max_id,
  )
  let text = sensitivity_envelope(draft)
  let oversized = text + " ".repeat(16777217)
  assert_true(
    (try? @mission_adapter.decode_sensitivity_draft(oversized)) is Err(_),
  )
  assert_true(
    (try? @mission_adapter.run_mission_draft(
      oversized,
      authoring_new_root("sensitivity-oversize"),
    ))
    is Err(_),
  )
  assert_true((try? @mission_adapter.decode_mission_draft(text)) is Err(_))
}

///|
test "sensitivity keeps frozen source count per-file and total byte limits" {
  let draft = sensitivity_draft(2)
  let parent = @mission_adapter.decode_study(draft.parent_envelope_json)
  let many : Array[@mission_adapter.StudySource] = []
  for index in 0..<65 {
    many.push({
      artifact_ref: "bounded/" + index.to_string() + ".txt",
      digest: "sha256:" + study_hash("x"),
      text: "x",
    })
  }
  let large = "x".repeat(1048577)
  let chunk = "x".repeat(900000)
  let total : Array[@mission_adapter.StudySource] = []
  for index in 0..<5 {
    total.push({
      artifact_ref: "bounded/" + index.to_string() + ".txt",
      digest: "sha256:" + study_hash(chunk),
      text: chunk,
    })
  }
  for
    sources in [
      many,
      [
        {
          artifact_ref: "bounded/large.txt",
          digest: "sha256:" + study_hash(large),
          text: large,
        },
      ],
      total,
    ] {
    let dossier_json = { ..parent, sources, }.to_json().stringify()
    let envelope : @mission_adapter.StudyEnvelope = {
      contract_id: "moonmoon.mission-study-envelope.v1",
      dossier_digest: "sha256:" + study_hash(dossier_json),
      dossier_json,
    }
    let invalid = {
      ..draft,
      parent_envelope_json: envelope.to_json().stringify(),
      parent_digest: envelope.dossier_digest,
    }
    let root = authoring_new_root("sensitivity-sources")
    assert_true(
      (try? @mission_adapter.run_mission_draft(
        sensitivity_envelope(invalid),
        root,
      ))
      is Err(_),
    )
    assert_false(@fsx.path_exists(root))
  }
}

///|
test "v1 frozen drafts reproduce the existing local and adopted robot dossier bytes" {
  for label in ["local", "robot"] {
    let draft = @fsx.read_file_to_string(
      "ui/rabbita-moon/fixtures/mission-draft-" + label + ".json",
    )
    let expected : @mission_adapter.StudyEnvelope = @json.from_json(
      @json.parse(
        @fsx.read_file_to_string(
          "ui/rabbita-moon/fixtures/mission-authored-" + label + ".json",
        ),
      ),
    )
    let actual = @mission_adapter.run_mission_draft(
      draft,
      authoring_new_root("legacy-exact-" + label),
    )
    assert_eq(actual, expected)
  }
}
