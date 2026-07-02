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
fn telemetry_payload_body() -> String {
  "{\"imu\":{\"x\":0.1,\"y\":0.0,\"z\":1.0}}"
}

///|
fn gait_payload_body() -> String {
  "{\"clip\":\"walk\",\"frames\":[{\"phase\":\"left-stance\"}]}"
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
fn remove_files(dir : String) -> Unit {
  if !@fsx.path_exists(dir) {
    return
  }
  let names = @fsx.read_dir(dir) catch { _ => return }
  for name in names {
    let path = dir + "/\{name}"
    @fsx.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn reset_robot_catalog_root(root : String) -> Unit {
  remove_files(root + "/sources")
  remove_files(root + "/datasets")
  remove_files(root + "/versions")
  remove_files(root + "/artifacts")
  remove_files(root + "/lineage")
  remove_files(root + "/validations")
  remove_files(root + "/indexes")
}

///|
test "robot model package import stages payloads into generic data root" {
  let root = root_path("model-package-import")
  reset_robot_catalog_root(root)
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
  reset_robot_catalog_root(root)
  let model_input = "target/robot-catalog-tests/episode-model-input"
  let episode_input = "target/robot-catalog-tests/episode-payload-input"
  let replay_input = episode_input + "/replays"
  let quality_input = episode_input + "/quality"
  ensure_test_dir("target")
  ensure_test_dir("target/robot-catalog-tests")
  ensure_test_dir(model_input)
  ensure_test_dir(model_input + "/meshes")
  ensure_test_dir(episode_input)
  ensure_test_dir(replay_input)
  ensure_test_dir(quality_input)
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
  @fsx.write_string_to_file(
    replay_input + "/replay-0001.json",
    "{\"replay\":[\"frame-0001\",\"frame-0002\"]}",
  ) catch {
    _ => fail("failed to write episode replay")
  }
  @fsx.write_string_to_file(
    quality_input + "/quality-0001.json",
    "{\"accepted\":2,\"rejected\":0}",
  ) catch {
    _ => fail("failed to write episode quality")
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
  assert_eq(result.replay_count, 1)
  assert_eq(result.quality_report_count, 1)
  assert_eq(result.episode.frame_count, 2)
  assert_eq(
    result.episode.model_refs[0].source_id,
    "source-robot-model-episode-alpha-model",
  )
  assert_eq(result.materialization.blocker_count, 0)
  assert_eq(result.materialization.warning_count, 0)
  assert_eq(result.materialization.quality_report_count, 1)
  assert_true(
    result.materialization.validation_status ==
    @data_core.ValidationStatus::Passed,
  )
  let dataset = @data_store.read_dataset(root, "episode-alpha-1").unwrap()
  assert_eq(dataset.kind, "robot-episode")
  assert_eq(dataset.data_refs.length(), 5)
  assert_true(
    dataset.data_refs[1].uri.contains("/episodes/episode-alpha-dataset/"),
  )
  assert_true(
    dataset.data_refs[3].uri.contains(
      "/episodes/episode-alpha-dataset/replays/",
    ),
  )
  assert_true(
    dataset.data_refs[4].uri.contains(
      "/episodes/episode-alpha-dataset/quality/",
    ),
  )
  let dossier = @robot_catalog.robot_episode_catalog_dossier_from_root(
    root, "episode-alpha-1",
  ).unwrap()
  assert_eq(dossier.episode_id, "episode-alpha-1")
  assert_eq(dossier.dataset.kind, "robot-episode")
  assert_eq(dossier.signal_ref_count, 2)
  assert_eq(dossier.replay_ref_count, 1)
  assert_eq(dossier.quality_ref_count, 1)
  assert_eq(dossier.model_ref_uris.length(), 1)
  assert_eq(dossier.replay_ref_uris.length(), 1)
  assert_eq(dossier.quality_ref_uris.length(), 1)
  assert_eq(dossier.validation_artifact.artifact_id, "validation-901")
  assert_true(dossier.validation_status == @data_core.ValidationStatus::Passed)
  assert_eq(dossier.blocker_count, 0)
  assert_eq(dossier.warning_count, 0)
  let root_dossier = @robot_catalog.robot_catalog_root_dossier_from_root(root).unwrap()
  assert_eq(root_dossier.model_count, 1)
  assert_eq(root_dossier.episode_count, 1)
  assert_eq(root_dossier.telemetry_stream_count, 0)
  assert_eq(root_dossier.gait_clip_count, 0)
  assert_eq(root_dossier.data_ref_count, 7)
  assert_true(root_dossier.model_ids.contains("episode-alpha-model"))
  assert_true(root_dossier.episode_ids.contains("episode-alpha-1"))
  assert_true(
    root_dossier.source_ids.contains("source-robot-model-episode-alpha-model"),
  )
  assert_eq(root_dossier.source_ids.length(), 1)
  assert_true(
    root_dossier.validation_status == @data_core.ValidationStatus::Passed,
  )
  assert_eq(root_dossier.validation_artifact.artifact_id, "validation-901")
  assert_eq(root_dossier.blocker_count, 0)
  assert_eq(root_dossier.warning_count, 0)
  let readiness = @robot_catalog.robot_migration_readiness_from_root(root).unwrap()
  assert_eq(readiness.status, "needs-evidence")
  assert_true(!readiness.ready)
  assert_eq(readiness.model_count, 1)
  assert_eq(readiness.episode_count, 1)
  assert_eq(readiness.telemetry_stream_count, 0)
  assert_eq(readiness.gait_clip_count, 0)
  assert_eq(readiness.signal_ref_count, 2)
  assert_eq(readiness.replay_ref_count, 1)
  assert_eq(readiness.quality_ref_count, 1)
  assert_eq(readiness.telemetry_ref_count, 0)
  assert_eq(readiness.gait_ref_count, 0)
  assert_eq(readiness.data_ref_count, 7)
  assert_eq(readiness.validation_artifact.artifact_id, "validation-901")
  assert_eq(
    readiness.next_action,
    "migrate a standalone robot telemetry stream into the generic data root",
  )
  let telemetry_input = "target/robot-catalog-tests/episode-telemetry-input"
  ensure_test_dir(telemetry_input)
  @fsx.write_string_to_file(
    telemetry_input + "/imu.json",
    telemetry_payload_body(),
  ) catch {
    _ => fail("failed to write episode telemetry imu payload")
  }
  @fsx.write_string_to_file(
    telemetry_input + "/joints.csv",
    "time,hip,knee\n0,0.1,0.2\n",
  ) catch {
    _ => fail("failed to write episode telemetry joints payload")
  }
  ignore(
    @robot_catalog.import_robot_telemetry_directory(
      @robot_catalog.robot_telemetry_directory_import_request(
        root,
        telemetry_input,
        "telemetry-alpha-1",
        "robot-alpha",
        "session-alpha-1",
        902L,
        source_label="Alpha telemetry fixture",
      ),
    ).unwrap(),
  )
  let ready_root = @robot_catalog.robot_catalog_root_dossier_from_root(root).unwrap()
  assert_eq(ready_root.model_count, 1)
  assert_eq(ready_root.episode_count, 1)
  assert_eq(ready_root.telemetry_stream_count, 1)
  assert_eq(ready_root.gait_clip_count, 0)
  assert_eq(ready_root.data_ref_count, 9)
  assert_eq(ready_root.validation_artifact.artifact_id, "validation-902")
  let ready = @robot_catalog.robot_migration_readiness_from_root(root).unwrap()
  assert_eq(ready.status, "needs-evidence")
  assert_true(!ready.ready)
  assert_eq(ready.telemetry_stream_count, 1)
  assert_eq(ready.telemetry_ref_count, 2)
  assert_eq(ready.data_ref_count, 9)
  assert_eq(
    ready.next_action,
    "migrate a robot gait clip into the generic data root",
  )
  let gait_input = "target/robot-catalog-tests/episode-gait-input"
  ensure_test_dir(gait_input)
  @fsx.write_string_to_file(gait_input + "/walk.json", gait_payload_body()) catch {
    _ => fail("failed to write episode gait payload")
  }
  @fsx.write_string_to_file(
    gait_input + "/footfalls.csv",
    "time,foot,phase\n0,left,stance\n",
  ) catch {
    _ => fail("failed to write episode gait footfalls payload")
  }
  ignore(
    @robot_catalog.import_robot_gait_clip_directory(
      @robot_catalog.robot_gait_clip_directory_import_request(
        root,
        gait_input,
        "gait-alpha-walk",
        "robot-alpha",
        "episode-alpha-model",
        903L,
        source_label="Alpha gait fixture",
      ),
    ).unwrap(),
  )
  let gait_ready_root = @robot_catalog.robot_catalog_root_dossier_from_root(
    root,
  ).unwrap()
  assert_eq(gait_ready_root.model_count, 1)
  assert_eq(gait_ready_root.episode_count, 1)
  assert_eq(gait_ready_root.telemetry_stream_count, 1)
  assert_eq(gait_ready_root.gait_clip_count, 1)
  assert_eq(gait_ready_root.gait_annotation_count, 0)
  assert_eq(gait_ready_root.data_ref_count, 12)
  assert_true(gait_ready_root.gait_clip_ids.contains("gait-alpha-walk"))
  assert_eq(gait_ready_root.validation_artifact.artifact_id, "validation-903")
  let gait_ready = @robot_catalog.robot_migration_readiness_from_root(root).unwrap()
  assert_eq(gait_ready.status, "needs-evidence")
  assert_true(!gait_ready.ready)
  assert_eq(gait_ready.gait_clip_count, 1)
  assert_eq(gait_ready.gait_annotation_count, 0)
  assert_eq(gait_ready.gait_ref_count, 2)
  assert_eq(gait_ready.gait_annotation_ref_count, 0)
  assert_eq(gait_ready.data_ref_count, 12)
  assert_eq(
    gait_ready.next_action,
    "migrate gait phase/contact annotations for a cataloged gait clip",
  )
  let annotation_input = "target/robot-catalog-tests/episode-gait-annotation-input"
  ensure_test_dir(annotation_input)
  @fsx.write_string_to_file(
    annotation_input + "/phase-labels.json",
    "{\"labels\":[\"left-stance\",\"right-stance\"]}",
  ) catch {
    _ => fail("failed to write episode gait annotation phase labels")
  }
  @fsx.write_string_to_file(
    annotation_input + "/contacts.csv",
    "time,foot,contact\n0,left,true\n",
  ) catch {
    _ => fail("failed to write episode gait annotation contacts")
  }
  let annotation = @robot_catalog.import_robot_gait_annotation_directory(
    @robot_catalog.robot_gait_annotation_directory_import_request(
      root,
      annotation_input,
      "annotation-alpha-walk-phases",
      "gait-alpha-walk",
      "robot-alpha",
      "episode-alpha-model",
      904L,
      source_label="Alpha gait annotation fixture",
    ),
  ).unwrap()
  assert_eq(annotation.payload_count, 2)
  assert_eq(annotation.gait_annotation.clip_id, "gait-alpha-walk")
  assert_eq(annotation.materialization.gait_annotation_count, 1)
  assert_eq(annotation.materialization.blocker_count, 0)
  assert_eq(annotation.materialization.warning_count, 0)
  let annotation_dossier = @robot_catalog.robot_gait_annotation_catalog_dossier_from_root(
    root, "annotation-alpha-walk-phases",
  ).unwrap()
  assert_eq(annotation_dossier.annotation_id, "annotation-alpha-walk-phases")
  assert_eq(annotation_dossier.clip_id, "gait-alpha-walk")
  assert_eq(annotation_dossier.dataset.kind, "robot-gait-annotation")
  assert_eq(annotation_dossier.annotation_ref_count, 2)
  assert_eq(annotation_dossier.model_ref_count, 1)
  assert_eq(annotation_dossier.data_ref_count, 3)
  assert_eq(
    annotation_dossier.validation_artifact.artifact_id,
    "validation-904",
  )
  assert_true(
    annotation_dossier.validation_status == @data_core.ValidationStatus::Passed,
  )
  let annotation_ready_root = @robot_catalog.robot_catalog_root_dossier_from_root(
    root,
  ).unwrap()
  assert_eq(annotation_ready_root.gait_annotation_count, 1)
  assert_true(
    annotation_ready_root.gait_annotation_ids.contains(
      "annotation-alpha-walk-phases",
    ),
  )
  assert_eq(annotation_ready_root.gait_annotation_dossiers.length(), 1)
  assert_eq(annotation_ready_root.data_ref_count, 15)
  assert_eq(
    annotation_ready_root.validation_artifact.artifact_id,
    "validation-904",
  )
  let annotation_ready = @robot_catalog.robot_migration_readiness_from_root(
    root,
  ).unwrap()
  assert_eq(annotation_ready.status, "ready")
  assert_true(annotation_ready.ready)
  assert_eq(annotation_ready.gait_annotation_count, 1)
  assert_eq(annotation_ready.gait_annotation_ref_count, 2)
  assert_eq(annotation_ready.data_ref_count, 15)
}

///|
test "robot telemetry directory import creates standalone stream dataset" {
  let root = root_path("telemetry-directory-import")
  reset_robot_catalog_root(root)
  let input = "target/robot-catalog-tests/telemetry-payload-input"
  ensure_test_dir("target")
  ensure_test_dir("target/robot-catalog-tests")
  ensure_test_dir(input)
  @fsx.write_string_to_file(input + "/imu.json", telemetry_payload_body()) catch {
    _ => fail("failed to write telemetry imu payload")
  }
  @fsx.write_string_to_file(input + "/joints.csv", "time,hip,knee\n0,0.1,0.2\n") catch {
    _ => fail("failed to write telemetry joints payload")
  }
  let result = @robot_catalog.import_robot_telemetry_directory(
    @robot_catalog.robot_telemetry_directory_import_request(
      root,
      input,
      "telemetry-alpha-1",
      "robot-alpha",
      "session-alpha-1",
      902L,
      source_label="Alpha telemetry fixture",
    ),
  ).unwrap()
  assert_eq(result.payload_count, 2)
  assert_eq(result.stream.stream_id, "telemetry-alpha-1")
  assert_eq(result.materialization.source_count, 1)
  assert_eq(result.materialization.dataset_count, 1)
  assert_eq(result.materialization.telemetry_stream_count, 1)
  assert_eq(result.materialization.blocker_count, 0)
  assert_eq(result.materialization.warning_count, 0)
  assert_true(
    result.materialization.validation_status ==
    @data_core.ValidationStatus::Passed,
  )
  let dataset = @data_store.read_dataset(root, "telemetry-alpha-1").unwrap()
  assert_eq(dataset.kind, "robot-telemetry-stream")
  assert_eq(dataset.data_refs.length(), 2)
  assert_eq(dataset.data_refs[0].kind, "robot-telemetry-sample")
  assert_true(
    dataset.data_refs[0].uri.contains("/telemetry/telemetry-alpha-1/imu.json"),
  )
  let dossier = @robot_catalog.robot_telemetry_catalog_dossier_from_root(
    root, "telemetry-alpha-1",
  ).unwrap()
  assert_eq(dossier.stream_id, "telemetry-alpha-1")
  assert_eq(dossier.dataset.kind, "robot-telemetry-stream")
  assert_eq(dossier.telemetry_ref_count, 2)
  assert_eq(dossier.data_ref_count, 2)
  assert_eq(dossier.telemetry_ref_uris.length(), 2)
  assert_eq(dossier.validation_artifact.artifact_id, "validation-902")
  assert_true(dossier.validation_status == @data_core.ValidationStatus::Passed)
  let root_dossier = @robot_catalog.robot_catalog_root_dossier_from_root(root).unwrap()
  assert_eq(root_dossier.model_count, 0)
  assert_eq(root_dossier.episode_count, 0)
  assert_eq(root_dossier.telemetry_stream_count, 1)
  assert_eq(root_dossier.gait_clip_count, 0)
  assert_eq(root_dossier.data_ref_count, 2)
  assert_true(root_dossier.telemetry_stream_ids.contains("telemetry-alpha-1"))
  assert_eq(root_dossier.telemetry_dossiers.length(), 1)
  let readiness = @robot_catalog.robot_migration_readiness_from_root(root).unwrap()
  assert_eq(readiness.status, "needs-evidence")
  assert_true(!readiness.ready)
  assert_eq(readiness.telemetry_stream_count, 1)
  assert_eq(readiness.telemetry_ref_count, 2)
  assert_eq(readiness.gait_clip_count, 0)
  assert_eq(readiness.gait_annotation_count, 0)
  assert_eq(readiness.gait_ref_count, 0)
  assert_eq(readiness.gait_annotation_ref_count, 0)
  assert_eq(readiness.next_action, "import a robot model package")
}

///|
test "robot gait clip directory import creates standalone clip dataset" {
  let root = root_path("gait-clip-directory-import")
  reset_robot_catalog_root(root)
  let model_input = "target/robot-catalog-tests/gait-model-input"
  let gait_input = "target/robot-catalog-tests/gait-payload-input"
  ensure_test_dir("target")
  ensure_test_dir("target/robot-catalog-tests")
  ensure_test_dir(model_input)
  ensure_test_dir(gait_input)
  @fsx.write_string_to_file(
    model_input + "/robot.urdf",
    "<robot name=\"alpha\"><link name=\"base_link\"/></robot>",
  ) catch {
    _ => fail("failed to write gait model urdf")
  }
  ignore(
    @robot_catalog.import_robot_model_package(
      @robot_catalog.robot_model_package_import_request(
        root, model_input, "gait-alpha-model", "robot-alpha", 950L,
      ),
    ).unwrap(),
  )
  @fsx.write_string_to_file(gait_input + "/walk.json", gait_payload_body()) catch {
    _ => fail("failed to write gait walk payload")
  }
  @fsx.write_string_to_file(
    gait_input + "/footfalls.csv",
    "time,foot,phase\n0,left,stance\n",
  ) catch {
    _ => fail("failed to write gait footfalls payload")
  }
  let result = @robot_catalog.import_robot_gait_clip_directory(
    @robot_catalog.robot_gait_clip_directory_import_request(
      root,
      gait_input,
      "gait-alpha-walk",
      "robot-alpha",
      "gait-alpha-model",
      951L,
      source_label="Alpha gait fixture",
    ),
  ).unwrap()
  assert_eq(result.payload_count, 2)
  assert_eq(result.gait_clip.clip_id, "gait-alpha-walk")
  assert_eq(result.materialization.source_count, 1)
  assert_eq(result.materialization.dataset_count, 1)
  assert_eq(result.materialization.gait_clip_count, 1)
  assert_eq(result.materialization.blocker_count, 0)
  assert_eq(result.materialization.warning_count, 0)
  assert_true(
    result.materialization.validation_status ==
    @data_core.ValidationStatus::Passed,
  )
  let dataset = @data_store.read_dataset(root, "gait-alpha-walk").unwrap()
  assert_eq(dataset.kind, "robot-gait-clip")
  assert_eq(dataset.data_refs.length(), 3)
  assert_eq(dataset.data_refs[1].kind, "robot-gait-clip")
  let mut has_footfalls = false
  for data_ref in dataset.data_refs {
    if data_ref.uri.contains("/gait_clips/gait-alpha-walk/footfalls.csv") {
      has_footfalls = true
    }
  }
  assert_true(has_footfalls)
  let dossier = @robot_catalog.robot_gait_clip_catalog_dossier_from_root(
    root, "gait-alpha-walk",
  ).unwrap()
  assert_eq(dossier.clip_id, "gait-alpha-walk")
  assert_eq(dossier.dataset.kind, "robot-gait-clip")
  assert_eq(dossier.gait_ref_count, 2)
  assert_eq(dossier.model_ref_count, 1)
  assert_eq(dossier.data_ref_count, 3)
  assert_eq(dossier.gait_ref_uris.length(), 2)
  assert_eq(dossier.validation_artifact.artifact_id, "validation-951")
  assert_true(dossier.validation_status == @data_core.ValidationStatus::Passed)
  let root_dossier = @robot_catalog.robot_catalog_root_dossier_from_root(root).unwrap()
  assert_eq(root_dossier.model_count, 1)
  assert_eq(root_dossier.gait_clip_count, 1)
  assert_eq(root_dossier.gait_annotation_count, 0)
  assert_true(root_dossier.gait_clip_ids.contains("gait-alpha-walk"))
  assert_eq(root_dossier.gait_clip_dossiers.length(), 1)
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
