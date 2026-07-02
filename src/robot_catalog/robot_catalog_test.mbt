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

///|
fn ensure_test_dir(path : String) -> Unit {
  if !@fsx.path_exists(path) {
    @fsx.create_dir(path) catch {
      _ => ()
    }
  }
}

///|
test "robot model package import stages payloads into generic data root" {
  let root = root_path("model-package-import")
  let input = "target/robot-catalog-tests/model-package-input"
  ensure_test_dir("target")
  ensure_test_dir("target/robot-catalog-tests")
  ensure_test_dir(input)
  ensure_test_dir(input + "/meshes")
  ensure_test_dir(input + "/materials")
  @fsx.write_string_to_file(
    input + "/robot.urdf",
    "<robot name=\"alpha\"><link name=\"base_link\"/><mesh filename=\"package://alpha/meshes/base.stl\"/></robot>",
  ) catch {
    _ => fail("failed to write robot package urdf")
  }
  @fsx.write_string_to_file(input + "/meshes/base.stl", "solid base\n") catch {
    _ => fail("failed to write robot package mesh")
  }
  @fsx.write_string_to_file(input + "/materials/base.json", "{}") catch {
    _ => fail("failed to write robot package material")
  }
  let result = @robot_catalog.import_robot_model_package(
    @robot_catalog.robot_model_package_import_request(
      root,
      input,
      "alpha-model",
      "robot-alpha",
      800L,
      source_label="Alpha model fixture",
    ),
  ).unwrap()
  assert_eq(result.asset_count, 3)
  assert_eq(result.dataset.kind, "robot-model-package")
  assert_eq(result.dataset.data_refs.length(), 3)
  assert_eq(result.materialization.blocker_count, 0)
  assert_eq(result.materialization.warning_count, 0)
  assert_true(
    result.materialization.validation_status ==
    @data_core.ValidationStatus::Passed,
  )
  assert_true(@fsx.path_exists(result.urdf_payload_path))
  let dataset = @data_store.read_dataset(
    root, "robot-model-package-alpha-model",
  ).unwrap()
  assert_true(
    dataset.data_refs[0].checksum.kind == @data_core.ChecksumKind::TextSumV1,
  )
  assert_true(
    dataset.data_refs[0].uri.has_prefix("data://payloads/robot_data/"),
  )
  let dossier = @robot_catalog.robot_model_catalog_dossier_from_root(
    root, "alpha-model",
  ).unwrap()
  assert_eq(dossier.model_id, "alpha-model")
  assert_eq(dossier.dataset.dataset_id, "robot-model-package-alpha-model")
  assert_eq(dossier.data_ref_count, 3)
  assert_true(dossier.urdf_ref_uri.has_suffix("/robot.urdf"))
  assert_true(dossier.validation_status == @data_core.ValidationStatus::Passed)
  assert_eq(dossier.blocker_count, 0)
  assert_eq(dossier.warning_count, 0)
}

///|
test "robot episode directory import uses cataloged model evidence" {
  let root = root_path("episode-directory-import")
  let model_input = "target/robot-catalog-tests/episode-model-input"
  let episode_input = "target/robot-catalog-tests/episode-payload-input"
  ensure_test_dir("target")
  ensure_test_dir("target/robot-catalog-tests")
  ensure_test_dir(model_input)
  ensure_test_dir(model_input + "/meshes")
  ensure_test_dir(episode_input)
  @fsx.write_string_to_file(
    model_input + "/robot.urdf",
    "<robot name=\"alpha\"><link name=\"base_link\"/></robot>",
  ) catch {
    _ => fail("failed to write episode model urdf")
  }
  @fsx.write_string_to_file(model_input + "/meshes/base.stl", "solid base\n") catch {
    _ => fail("failed to write episode model mesh")
  }
  ignore(
    @robot_catalog.import_robot_model_package(
      @robot_catalog.robot_model_package_import_request(
        root, model_input, "episode-alpha-model", "robot-alpha", 900L,
      ),
    ).unwrap(),
  )
  @fsx.write_string_to_file(
    episode_input + "/frame-0001.json",
    "{\"joint\":\"hip\",\"position\":0.1}",
  ) catch {
    _ => fail("failed to write episode frame 1")
  }
  @fsx.write_string_to_file(
    episode_input + "/frame-0002.json",
    "{\"joint\":\"knee\",\"position\":0.2}",
  ) catch {
    _ => fail("failed to write episode frame 2")
  }
  let result = @robot_catalog.import_robot_episode_directory(
    @robot_catalog.robot_episode_directory_import_request(
      root,
      episode_input,
      "episode-alpha-dataset",
      "episode-alpha-1",
      "robot-alpha",
      "episode-alpha-model",
      901L,
      source_label="Alpha episode fixture",
    ),
  ).unwrap()
  assert_eq(result.signal_count, 2)
  assert_eq(result.episode.frame_count, 2)
  assert_eq(
    result.episode.model_refs[0].source_id,
    "source-robot-model-episode-alpha-model",
  )
  assert_eq(result.materialization.blocker_count, 0)
  assert_eq(result.materialization.warning_count, 0)
  assert_true(
    result.materialization.validation_status ==
    @data_core.ValidationStatus::Passed,
  )
  let dataset = @data_store.read_dataset(root, "episode-alpha-1").unwrap()
  assert_eq(dataset.kind, "robot-episode")
  assert_eq(dataset.data_refs.length(), 3)
  assert_true(
    dataset.data_refs[1].uri.contains("/episodes/episode-alpha-dataset/"),
  )
  let dossier = @robot_catalog.robot_episode_catalog_dossier_from_root(
    root, "episode-alpha-1",
  ).unwrap()
  assert_eq(dossier.episode_id, "episode-alpha-1")
  assert_eq(dossier.dataset.kind, "robot-episode")
  assert_eq(dossier.signal_ref_count, 2)
  assert_eq(dossier.model_ref_uris.length(), 1)
  assert_true(dossier.validation_status == @data_core.ValidationStatus::Passed)
  assert_eq(dossier.blocker_count, 0)
  assert_eq(dossier.warning_count, 0)
}

///|
test "robot model package import rejects unsafe model ids" {
  let input = "target/robot-catalog-tests/model-package-unsafe-input"
  ensure_test_dir("target")
  ensure_test_dir("target/robot-catalog-tests")
  ensure_test_dir(input)
  @fsx.write_string_to_file(
    input + "/robot.urdf",
    "<robot name=\"alpha\"><link name=\"base_link\"/></robot>",
  ) catch {
    _ => fail("failed to write unsafe model fixture")
  }
  match
    @robot_catalog.import_robot_model_package(
      @robot_catalog.robot_model_package_import_request(
        root_path("model-package-unsafe"),
        input,
        "../alpha",
        "robot-alpha",
        801L,
      ),
    ) {
    Ok(_) => fail("unsafe robot model id should fail")
    Err(error) => assert_eq(error.code, "invalid-robot-model-id")
  }
}
