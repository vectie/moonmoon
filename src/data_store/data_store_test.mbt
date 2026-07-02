///|
fn root_path(name : String) -> String {
  "target/data-store-tests/\{name}"
}

///|
fn sample_payload() -> @data_core.DataRef {
  @data_core.data_ref(
    "payload-1",
    "source-json",
    @data_core.data_uri("payloads/source/payload-1.json"),
    content_type="application/json",
    byte_count=17L,
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::Sha256,
      "abc",
    ),
  )
}

///|
test "data store initializes generic root layout" {
  let root = root_path("init")
  let result = @data_store.initialize_root(root).unwrap()
  assert_eq(result.root, root)
  assert_true(@fsx.path_exists(root + "/sources"))
  assert_true(@fsx.path_exists(root + "/datasets"))
  assert_true(@fsx.path_exists(root + "/payloads"))
  assert_true(@fsx.path_exists(@data_store.catalog_path(root)) == false)
}

///|
test "data store writes and reads core manifests" {
  let root = root_path("roundtrip")
  ignore(@data_store.initialize_root(root))
  let payload = sample_payload()
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
    summary="generic dataset",
  )
  let version = @data_core.dataset_version(
    "version-a",
    dataset.dataset_id,
    @data_core.DataStatus::Curated,
    3L,
    data_refs=[payload],
    summary="first immutable version",
  )
  ignore(@data_store.write_source(root, source))
  ignore(@data_store.write_dataset(root, dataset))
  ignore(@data_store.write_dataset_version(root, version))
  assert_true(
    @data_store.read_source(root, source.source_id).unwrap() == source,
  )
  assert_true(
    @data_store.read_dataset(root, dataset.dataset_id).unwrap() == dataset,
  )
  assert_true(
    @data_store.read_dataset_version(root, version.version_id).unwrap() ==
    version,
  )
}

///|
test "data store rebuilds catalog from generic manifests" {
  let root = root_path("catalog")
  ignore(@data_store.initialize_root(root))
  let source = @data_core.data_source(
    "source-b", "Example Authority", "Source B", "https://example.invalid/source-b",
    "test-license", "test citation", 10L,
  )
  let dataset = @data_core.dataset_manifest(
    "dataset-b",
    "generic",
    @data_core.DataStatus::Verified,
    11L,
    source_ids=[source.source_id],
    summary="cataloged dataset",
  )
  let dataset_ref = @data_core.artifact_ref(
    "dataset",
    dataset.dataset_id,
    @data_store.dataset_path(root, dataset.dataset_id),
    status=dataset.status,
    summary=dataset.summary,
  )
  let version_ref = @data_core.artifact_ref(
    "dataset-version",
    "version-b",
    @data_store.dataset_version_path(root, "version-b"),
    status=@data_core.DataStatus::Curated,
    summary="cataloged version",
  )
  let lineage = @data_core.lineage_manifest("lineage-b", dataset_ref, 12L, edges=[
    @data_core.lineage_edge(dataset_ref, version_ref, "versioned-as"),
  ])
  let report = @data_core.validation_report(
    "validation-b",
    root,
    13L,
    @data_core.ValidationStatus::Passed,
  )
  ignore(@data_store.write_source(root, source))
  ignore(@data_store.write_dataset(root, dataset))
  ignore(@data_store.write_artifact_ref(root, version_ref))
  ignore(@data_store.write_lineage_manifest(root, lineage))
  ignore(@data_store.write_validation_report(root, report))
  let rebuild = @data_store.rebuild_catalog(root, 14L).unwrap()
  assert_eq(rebuild.entry_count, 5)
  assert_true(@fsx.path_exists(rebuild.catalog_path))
  let catalog = @data_store.read_catalog(root).unwrap()
  assert_eq(catalog.entries.length(), 5)
  assert_eq(catalog.entries[0].artifact_kind, "source")
  assert_eq(catalog.entries[1].artifact_kind, "dataset")
  assert_true(catalog.entries[4].artifact_kind == "validation-report")
}
