///|
test "data uri accepts only local safe relative payload paths" {
  let uri = @data_core.data_uri("payloads/lro/tile.json")
  assert_eq(uri, "data://payloads/lro/tile.json")
  assert_eq(
    @data_core.data_payload_uri_relative_path(uri).unwrap(),
    "payloads/lro/tile.json",
  )
  assert_eq(@data_core.data_payload_root(uri), "payloads")
  assert_true(
    @data_core.data_payload_uri_relative_path("file:///tmp/a") is None,
  )
  assert_true(
    @data_core.data_payload_uri_relative_path("data:///tmp/a") is None,
  )
  assert_true(@data_core.data_payload_uri_relative_path("data://../a") is None)
  assert_true(
    @data_core.data_payload_uri_relative_path("data://a/../b") is None,
  )
  assert_true(@data_core.data_payload_uri_relative_path("data://a\\b") is None)
  assert_true(@data_core.data_payload_uri_relative_path("data://a//b") is None)
}

///|
test "generic refs and catalog stay domain neutral" {
  let payload = @data_core.data_ref(
    "ref-dem-window",
    "terrain-window",
    @data_core.data_uri("payloads/sources/window.csv"),
    content_type="text/csv",
    byte_count=42L,
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::Sha256,
      "abc123",
    ),
  )
  let source = @data_core.data_source(
    "source-alpha",
    "Example Authority",
    "Selected source product",
    "https://example.invalid/source",
    "public-domain",
    "citation",
    10L,
    source_refs=[payload],
  )
  assert_eq(source.source_refs.length(), 1)
  let dataset = @data_core.dataset_manifest(
    "dataset-window",
    "raster-window",
    @data_core.DataStatus::Verified,
    11L,
    source_ids=[source.source_id],
    data_refs=[payload],
    summary="checked source-backed tile",
  )
  assert_eq(@data_core.data_status_label(dataset.status), "verified")
  let entry = @data_core.catalog_entry(
    "dataset",
    dataset.dataset_id,
    "datasets/dataset-window.json",
    status=dataset.status,
    summary=dataset.summary,
  )
  let catalog = @data_core.data_catalog("data-root", 12L, [entry])
  let refs = @data_core.catalog_refs(catalog)
  assert_eq(refs.length(), 1)
  assert_eq(refs[0].artifact_id, dataset.dataset_id)
  assert_eq(@data_core.artifact_ref_status_label(refs[0]), "verified")
}

///|
test "lineage and validation reports compose artifact refs" {
  let raw = @data_core.artifact_ref(
    "dataset",
    "raw-ds",
    "datasets/raw-ds.json",
    status=@data_core.DataStatus::Raw,
  )
  let curated = @data_core.artifact_ref(
    "dataset-version",
    "curated-v1",
    "versions/curated-v1.json",
    status=@data_core.DataStatus::Curated,
  )
  let lineage = @data_core.lineage_manifest("lineage-1", raw, 20L, edges=[
    @data_core.lineage_edge(raw, curated, "curated-into"),
  ])
  assert_eq(lineage.edges.length(), 1)
  let finding = @data_core.validation_finding(
    "missing-payload",
    @data_core.FindingSeverity::Blocker,
    curated,
    "payload is missing",
    recommendation="rebuild payload",
  )
  let report = @data_core.validation_report(
    "validation-1",
    "data-root",
    21L,
    @data_core.ValidationStatus::BlockedValidation,
    findings=[finding],
  )
  assert_eq(@data_core.validation_finding_count(report), 1)
  assert_eq(@data_core.validation_blocker_count(report), 1)
  assert_eq(@data_core.validation_status_label(report.status), "blocked")
}

///|
test "catalog json round trip preserves stable contract shape" {
  let entry = @data_core.catalog_entry(
    "dataset",
    "dataset-1",
    "datasets/dataset-1.json",
    status=@data_core.DataStatus::Verified,
    summary="first cataloged dataset",
  )
  let catalog = @data_core.data_catalog("data-root", 100L, [entry])
  let body = catalog.to_json().stringify()
  let decoded : @data_core.DataCatalog = @json.from_json(@json.parse(body))
  assert_true(decoded == catalog)
  assert_eq(decoded.entries[0].artifact_id, "dataset-1")
  assert_true(body.contains("\"catalog_id\""))
  assert_true(body.contains("\"entries\""))
}
