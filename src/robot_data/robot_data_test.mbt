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
