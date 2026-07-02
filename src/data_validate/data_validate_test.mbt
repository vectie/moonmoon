///|
fn root_path(name : String) -> String {
  "target/data-validate-tests/\{name}"
}

///|
fn remove_json_files(dir : String) -> Unit {
  if !@fsx.path_exists(dir) {
    return
  }
  let names = @fsx.read_dir(dir) catch { _ => return }
  for name in names {
    if name.has_suffix(".json") {
      @fsx.remove_file(dir + "/\{name}") catch {
        _ => ()
      }
    }
  }
}

///|
fn prepare_root(name : String) -> String {
  let root = root_path(name)
  ignore(@data_store.initialize_root(root))
  remove_json_files(root + "/sources")
  remove_json_files(root + "/datasets")
  remove_json_files(root + "/versions")
  remove_json_files(root + "/artifacts")
  remove_json_files(root + "/lineage")
  remove_json_files(root + "/validations")
  remove_json_files(root + "/indexes")
  if !@fsx.path_exists(root + "/payloads/source") {
    @fsx.create_dir(root + "/payloads/source") catch {
      _ => ()
    }
  }
  remove_json_files(root + "/payloads/source")
  root
}

///|
fn payload_ref(id : String, body : String) -> @data_core.DataRef {
  @data_core.data_ref(
    id,
    "json",
    @data_core.data_uri("payloads/source/\{id}.json"),
    content_type="application/json",
    byte_count=body.length().to_int64(),
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::TextSumV1,
      "text-sum-v1:bytes=\{body.length()}",
    ),
  )
}

///|
fn write_payload(root : String, id : String, body : String) -> Unit {
  @fsx.write_string_to_file(root + "/payloads/source/\{id}.json", body) catch {
    _ => ()
  }
}

///|
fn has_rule(report : @data_core.ValidationReport, rule_id : String) -> Bool {
  for finding in report.findings {
    if finding.rule_id == rule_id {
      return true
    }
  }
  false
}

///|
fn count_for_kind(
  counts : Array[@data_validate.DataKindCount],
  kind : String,
) -> Int {
  for count in counts {
    if count.kind == kind {
      return count.count
    }
  }
  0
}

///|
test "data validation passes a cataloged root with checked local payloads" {
  let root = prepare_root("valid")
  let body = "{\"ok\":true}"
  write_payload(root, "payload-a", body)
  let payload = payload_ref("payload-a", body)
  let source = @data_core.data_source(
    "source-a",
    "Example Authority",
    "Source A",
    "https://example.invalid/source-a",
    "test-license",
    "test citation",
    1L,
    source_refs=[payload],
  )
  let dataset = @data_core.dataset_manifest(
    "dataset-a",
    "generic",
    @data_core.DataStatus::Verified,
    2L,
    source_ids=[source.source_id],
    data_refs=[payload],
    summary="valid dataset",
  )
  ignore(@data_store.write_source(root, source))
  ignore(@data_store.write_dataset(root, dataset))
  ignore(@data_store.rebuild_catalog(root, 3L))
  let result = @data_validate.validate_and_write_root(root, 4L).unwrap()
  assert_true(result.status == @data_core.ValidationStatus::Passed)
  assert_eq(result.finding_count, 0)
  assert_true(@fsx.path_exists(result.report_path))
  ignore(
    @data_store.write_validation_report(
      root,
      @data_core.validation_report(
        "quality-dataset-a",
        root,
        5L,
        @data_core.ValidationStatus::Passed,
        findings=[
          @data_core.validation_finding(
            "auxiliary-quality-report",
            @data_core.FindingSeverity::Info,
            @data_core.artifact_ref(
              "dataset",
              dataset.dataset_id,
              @data_store.dataset_path(root, dataset.dataset_id),
            ),
            "auxiliary validation report should not replace root validation",
          ),
        ],
      ),
    ),
  )
  ignore(@data_store.rebuild_catalog(root, 6L))
  let summary = @data_validate.data_root_validation_summary_from_root(root).unwrap()
  assert_true(summary.ready)
  assert_eq(summary.latest_validation_artifact.artifact_id, "validation-4")
  assert_eq(summary.source_count, 1)
  assert_eq(summary.dataset_count, 1)
  assert_eq(summary.validation_report_count, 2)
  assert_eq(summary.root_validation_report_count, 1)
  assert_eq(summary.auxiliary_validation_report_count, 1)
  assert_eq(count_for_kind(summary.dataset_kind_counts, "generic"), 1)
  assert_eq(count_for_kind(summary.data_ref_kind_counts, "json"), 1)
  let catalog = @data_store.read_catalog(root).unwrap()
  assert_true(catalog.entries.length() >= 3)
}

///|
test "data validation blocks unsafe missing and mismatched payload refs" {
  let root = prepare_root("payload-failures")
  let good_body = "{\"ok\":true}"
  write_payload(root, "good", good_body)
  let good = payload_ref("good", good_body)
  let missing = payload_ref("missing", "{}")
  let unsafe_ref = @data_core.data_ref(
    "unsafe",
    "json",
    "data://../escape.json",
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::TextSumV1,
      "text-sum-v1:bytes=2",
    ),
  )
  let mismatch = @data_core.data_ref(
    "mismatch",
    "json",
    @data_core.data_uri("payloads/source/good.json"),
    byte_count=999L,
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::TextSumV1,
      "text-sum-v1:bytes=999",
    ),
  )
  let dataset = @data_core.dataset_manifest(
    "dataset-bad-payloads",
    "generic",
    @data_core.DataStatus::Verified,
    2L,
    data_refs=[good, missing, unsafe_ref, mismatch],
    summary="bad payload refs",
  )
  ignore(@data_store.write_dataset(root, dataset))
  ignore(@data_store.rebuild_catalog(root, 3L))
  let result = @data_validate.validate_and_write_root(root, 4L).unwrap()
  assert_true(result.status == @data_core.ValidationStatus::BlockedValidation)
  assert_true(has_rule(result.report, "payload-missing"))
  assert_true(has_rule(result.report, "data-ref-unsafe-uri"))
  assert_true(has_rule(result.report, "payload-byte-count-mismatch"))
  assert_true(has_rule(result.report, "payload-checksum-mismatch"))
}

///|
test "data validation detects stale catalog duplicate ids and broken lineage" {
  let root = prepare_root("graph-failures")
  let dataset = @data_core.dataset_manifest(
    "dataset-graph",
    "generic",
    @data_core.DataStatus::Verified,
    1L,
    summary="graph dataset",
  )
  let duplicate = @data_core.artifact_ref(
    "dataset",
    dataset.dataset_id,
    @data_store.dataset_path(root, dataset.dataset_id),
    status=@data_core.DataStatus::Verified,
    summary="duplicate dataset identity",
  )
  let missing = @data_core.artifact_ref(
    "dataset-version",
    "version-missing",
    @data_store.dataset_version_path(root, "version-missing"),
  )
  let dataset_artifact = @data_core.artifact_ref(
    "dataset",
    dataset.dataset_id,
    @data_store.dataset_path(root, dataset.dataset_id),
    status=@data_core.DataStatus::Verified,
  )
  let lineage = @data_core.lineage_manifest(
    "lineage-broken",
    dataset_artifact,
    2L,
    edges=[@data_core.lineage_edge(dataset_artifact, missing, "versioned-as")],
  )
  ignore(@data_store.write_dataset(root, dataset))
  ignore(@data_store.rebuild_catalog(root, 3L))
  ignore(@data_store.write_artifact_ref(root, duplicate))
  ignore(@data_store.write_lineage_manifest(root, lineage))
  let result = @data_validate.validate_and_write_root(root, 4L).unwrap()
  assert_true(result.status == @data_core.ValidationStatus::BlockedValidation)
  assert_true(has_rule(result.report, "catalog-stale"))
  assert_true(has_rule(result.report, "duplicate-artifact-id"))
  assert_true(has_rule(result.report, "lineage-edge-target-missing"))
}
