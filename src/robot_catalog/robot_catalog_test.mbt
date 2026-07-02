///|
fn root_path(name : String) -> String {
  "target/robot-catalog-tests/\{name}"
}

///|
fn checksum(value : String) -> String {
  value + value + value + value
}

///|
fn payload(
  ref_id : String,
  role : String,
  path : String,
  body : String,
) -> @robot_data.RobotPayloadRef {
  @robot_data.robot_payload_ref(
    ref_id,
    role,
    path,
    "application/json",
    body.length().to_int64(),
    checksum("0123456789abcdef"),
  )
}

///|
fn model_payload_body() -> String {
  "{\"model\":\"alpha\"}"
}

///|
fn signal_payload_body() -> String {
  "{\"frame\":\"frame-1\",\"joint\":0.1}"
}

///|
fn replay_payload_body() -> String {
  "{\"replay\":[\"frame-1\"]}"
}

///|
fn quality_payload_body() -> String {
  "{\"quality\":\"passed\"}"
}

///|
fn model_ref() -> @robot_data.RobotModelRef {
  @robot_data.robot_model_ref(
    "model-alpha-v1",
    "robot-alpha",
    "source-robot-alpha-model-v1",
    "Robot Alpha model",
    "robot-profile",
    "Robot Data Fixture",
    "https://example.invalid/robot-alpha",
    "test fixture",
    "Robot Alpha model fixture.",
    100L,
    payload(
      "model-alpha-profile",
      "robot-model",
      "payloads/robot_data/robot-alpha/model.json",
      model_payload_body(),
    ),
  )
}

///|
fn quality_payload() -> @robot_data.RobotPayloadRef {
  payload(
    "quality-alpha-episode-1",
    "robot-quality-report",
    "payloads/robot_data/robot-alpha/quality/episode-1.json",
    quality_payload_body(),
  )
}

///|
fn episode_manifest() -> @robot_data.RobotEpisodeManifest {
  let signal = @robot_data.robot_signal_ref(
    "signal-alpha-frame-1",
    "frame-1",
    "joint.position",
    12,
    "rad",
    payload(
      "signal-alpha-frame-1",
      "robot-signal-frame",
      "payloads/robot_data/robot-alpha/signals/frame-1.json",
      signal_payload_body(),
    ),
  )
  let replay = @robot_data.robot_replay_artifact(
    "replay-alpha-episode-1",
    "robot-replay",
    payload(
      "replay-alpha-episode-1",
      "robot-replay",
      "payloads/robot_data/robot-alpha/replays/episode-1.json",
      replay_payload_body(),
    ),
  )
  @robot_data.robot_episode_manifest(
    "episode-alpha-1",
    "robot-alpha",
    "session-alpha-1",
    @data_core.DataStatus::Verified,
    200L,
    1,
    [model_ref()],
    [signal],
    [replay],
    [quality_payload()],
    "Robot Alpha accepted episode.",
  )
}

///|
fn quality_report() -> @robot_data.RobotQualityReport {
  @robot_data.robot_quality_report(
    "quality-alpha-episode-1",
    "episode-alpha-1",
    @data_core.ValidationStatus::Passed,
    300L,
    1,
    0,
  )
}

///|
fn bundle() -> @robot_catalog.RobotCatalogBundle {
  @robot_catalog.robot_catalog_bundle(
    "robot-alpha-bundle",
    [model_ref()],
    [episode_manifest()],
    quality_reports=[quality_report()],
  )
}

///|
fn stage_payloads(root : String) -> Unit {
  ignore(
    @robot_catalog.stage_robot_payload_text(
      root,
      model_ref().payload,
      model_payload_body(),
    ).unwrap(),
  )
  ignore(
    @robot_catalog.stage_robot_payload_text(
      root,
      episode_manifest().signal_refs[0].payload,
      signal_payload_body(),
    ).unwrap(),
  )
  ignore(
    @robot_catalog.stage_robot_payload_text(
      root,
      episode_manifest().replay_artifacts[0].payload,
      replay_payload_body(),
    ).unwrap(),
  )
  ignore(
    @robot_catalog.stage_robot_payload_text(
      root,
      quality_payload(),
      quality_payload_body(),
    ).unwrap(),
  )
}

///|
test "robot catalog materializes generic data root from robot bundle" {
  let root = root_path("materialize")
  ignore(@data_store.initialize_root(root))
  stage_payloads(root)
  let result = @robot_catalog.materialize_robot_catalog_bundle(
    root,
    bundle(),
    700L,
  ).unwrap()
  assert_eq(result.source_count, 1)
  assert_eq(result.dataset_count, 1)
  assert_eq(result.version_count, 1)
  assert_eq(result.lineage_count, 1)
  assert_eq(result.quality_report_count, 1)
  assert_eq(result.blocker_count, 0)
  assert_true(result.warning_count > 0)
  assert_true(result.validation_status == @data_core.ValidationStatus::Warning)
  let catalog = @data_store.read_catalog(root).unwrap()
  assert_true(catalog.entries.length() >= 6)
  let dataset = @data_store.read_dataset(root, "episode-alpha-1").unwrap()
  assert_eq(dataset.kind, "robot-episode")
  assert_eq(dataset.data_refs.length(), 4)
}

///|
test "robot catalog blocks missing staged payloads" {
  let root = root_path("missing-payload")
  ignore(@data_store.initialize_root(root))
  let result = @robot_catalog.materialize_robot_catalog_bundle(
    root,
    bundle(),
    701L,
  ).unwrap()
  assert_true(
    result.validation_status == @data_core.ValidationStatus::BlockedValidation,
  )
  assert_true(result.blocker_count > 0)
}
