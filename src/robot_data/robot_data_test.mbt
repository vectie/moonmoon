///|
fn sha(value : String) -> String {
  value + value + value + value
}

///|
fn fixture_model() -> @robot_data.RobotModelRef {
  @robot_data.robot_model_ref(
    "model-robot-alpha-v1",
    "robot-alpha",
    "source-robot-alpha-model-v1",
    "Robot Alpha model",
    "urdf-model",
    "Robot Lab",
    "https://example.invalid/robot-alpha/model",
    "internal test fixture",
    "Robot Alpha model fixture for data-layer migration tests.",
    10L,
    @robot_data.robot_payload_ref(
      "robot-alpha-model-payload",
      "robot-model",
      "payloads/robot_data/robot-alpha/model.urdf",
      "application/xml",
      400L,
      sha("abcdef0123456789"),
    ),
  )
}

///|
fn fixture_episode() -> @robot_data.RobotEpisodeManifest {
  let signal = @robot_data.robot_signal_ref(
    "signal-joint-positions-v1",
    "frame-0001",
    "joint.position",
    24,
    "rad",
    @robot_data.robot_payload_ref(
      "robot-alpha-signal-frame-0001",
      "robot-signal-frame",
      "payloads/robot_data/robot-alpha/signals/frame-0001.json",
      "application/json",
      512L,
      sha("0123456789abcdef"),
    ),
  )
  let replay = @robot_data.robot_replay_artifact(
    "replay-robot-alpha-episode-1",
    "robot-replay",
    @robot_data.robot_payload_ref(
      "robot-alpha-replay-episode-1",
      "robot-replay",
      "payloads/robot_data/robot-alpha/replay/episode-1.json",
      "application/json",
      2048L,
      sha("fedcba9876543210"),
    ),
  )
  @robot_data.robot_episode_manifest(
    "episode-robot-alpha-1",
    "robot-alpha",
    "session-robot-alpha-1",
    @data_core.DataStatus::Verified,
    20L,
    1,
    [fixture_model()],
    [signal],
    [replay],
    [
      @robot_data.robot_payload_ref(
        "robot-alpha-quality-episode-1",
        "robot-quality-report",
        "payloads/robot_data/robot-alpha/quality/episode-1.json",
        "application/json",
        256L,
        sha("1111222233334444"),
      ),
    ],
    "Robot Alpha accepted replay episode.",
  )
}

///|
test "robot model source projects through data_core" {
  let model = fixture_model()
  let source = @robot_data.robot_model_data_source(model)
  assert_eq(source.source_id, "source-robot-alpha-model-v1")
  assert_eq(source.source_refs.length(), 1)
  assert_eq(
    @data_core.data_payload_uri_relative_path(source.source_refs[0].uri).unwrap(),
    "payloads/robot_data/robot-alpha/model.urdf",
  )
  assert_true(
    source.source_refs[0].checksum.kind == @data_core.ChecksumKind::Sha256,
  )
}

///|
test "robot episode maps to generic dataset version and lineage" {
  let episode = fixture_episode()
  let dataset = @robot_data.robot_episode_dataset(episode)
  assert_eq(dataset.dataset_id, "episode-robot-alpha-1")
  assert_eq(dataset.kind, "robot-episode")
  assert_true(dataset.source_ids == ["source-robot-alpha-model-v1"])
  assert_eq(dataset.data_refs.length(), 4)
  assert_eq(
    dataset.data_refs[1].uri,
    "data://payloads/robot_data/robot-alpha/signals/frame-0001.json",
  )
  let version = @robot_data.robot_episode_version(
    episode, "episode-robot-alpha-1-v1",
  )
  assert_eq(version.dataset_id, dataset.dataset_id)
  assert_eq(version.data_refs.length(), dataset.data_refs.length())
  let lineage = @robot_data.robot_episode_lineage(
    episode, "lineage-episode-robot-alpha-1",
  )
  assert_eq(lineage.root_artifact.artifact_id, dataset.dataset_id)
  assert_eq(lineage.edges.length(), 2)
}

///|
test "robot gait clip maps to generic dataset version and lineage" {
  let gait_payload = @robot_data.robot_gait_clip_payload_ref(
    "walk-cycle",
    24,
    1.2,
    @robot_data.robot_payload_ref(
      "robot-alpha-gait-walk-cycle",
      "robot-gait-clip",
      "payloads/robot_data/robot-alpha/gait/walk-cycle.json",
      "application/json",
      1024L,
      sha("aaaabbbbccccdddd"),
    ),
  )
  let clip = @robot_data.robot_gait_clip_manifest(
    "gait-robot-alpha-walk",
    "robot-alpha",
    "source-robot-alpha-gait-walk",
    "Robot Alpha walk gait",
    "https://example.invalid/robot-alpha/gait/walk",
    @data_core.DataStatus::Verified,
    40L,
    [fixture_model()],
    [gait_payload],
    "Robot Alpha walk gait clip.",
  )
  let source = @robot_data.robot_gait_clip_data_source(clip)
  assert_eq(source.source_id, "source-robot-alpha-gait-walk")
  assert_eq(source.source_refs.length(), 1)
  let dataset = @robot_data.robot_gait_clip_dataset(clip)
  assert_eq(dataset.dataset_id, "gait-robot-alpha-walk")
  assert_eq(dataset.kind, "robot-gait-clip")
  assert_eq(dataset.source_ids.length(), 2)
  assert_eq(dataset.data_refs.length(), 2)
  assert_eq(dataset.data_refs[1].kind, "robot-gait-clip")
  let version = @robot_data.robot_gait_clip_version(
    clip, "gait-robot-alpha-walk-v1",
  )
  assert_eq(version.dataset_id, dataset.dataset_id)
  assert_eq(version.data_refs.length(), dataset.data_refs.length())
  let lineage = @robot_data.robot_gait_clip_lineage(
    clip, "lineage-gait-robot-alpha-walk",
  )
  assert_eq(lineage.root_artifact.artifact_id, dataset.dataset_id)
  assert_eq(lineage.edges.length(), 2)
}

///|
test "robot quality report projects to generic validation report" {
  let episode_artifact = @data_core.artifact_ref(
    "dataset", "episode-robot-alpha-1", "datasets/episode-robot-alpha-1.json",
  )
  let finding = @data_core.validation_finding(
    "frame-count-ok",
    @data_core.FindingSeverity::Info,
    episode_artifact,
    "frame count accepted",
  )
  let report = @robot_data.robot_quality_report(
    "quality-episode-robot-alpha-1",
    "episode-robot-alpha-1",
    @data_core.ValidationStatus::Passed,
    30L,
    1,
    0,
    findings=[finding],
  )
  let validation = @robot_data.robot_quality_validation_report(
    "robot-data-root", report,
  )
  assert_eq(validation.validation_report_id, report.report_id)
  assert_eq(validation.findings.length(), 1)
  assert_true(validation.status == @data_core.ValidationStatus::Passed)
  assert_true(validation.to_json().stringify().contains("frame-count-ok"))
}

///|
test "legacy moondata refs normalize into robot payload data refs" {
  let payload = @robot_data.robot_legacy_moondata_payload_ref(
    "robot-alpha-replay-legacy",
    "moondata://robot-alpha/replay/episode-1.json",
    "robot-replay",
    "application/json",
    2048L,
    sha("abcdefabcdefabcd"),
  ).unwrap()
  assert_eq(
    payload.path,
    "payloads/robot_data/robot-alpha/replay/episode-1.json",
  )
  let data_ref = @robot_data.robot_payload_data_ref(payload)
  assert_eq(
    data_ref.uri,
    "data://payloads/robot_data/robot-alpha/replay/episode-1.json",
  )
}

///|
test "legacy moondata refs reject unsafe or non legacy paths" {
  let rejected = [
    "data://robot-alpha/replay/episode-1.json", "moondata://", "moondata:///robot-alpha/replay/episode-1.json",
    "moondata://../robot-alpha/replay/episode-1.json", "moondata://robot-alpha//replay/episode-1.json",
    "moondata://robot-alpha/./replay/episode-1.json", "moondata://robot-alpha\\replay\\episode-1.json",
  ]
  for uri in rejected {
    assert_true(@robot_data.robot_legacy_moondata_payload_path(uri) is None)
  }
}
