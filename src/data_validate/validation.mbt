///|
pub(all) struct StoredValidationResult {
  root : String
  validation_report_id : String
  report_path : String
  catalog_path : String
  status : @data_core.ValidationStatus
  finding_count : Int
  blocker_count : Int
  warning_count : Int
  report : @data_core.ValidationReport
} derive(Debug, Eq, ToJson, FromJson)

///|
fn report_id(generated_at_ms : Int64) -> String {
  "validation-\{generated_at_ms}"
}

///|
fn join(root : String, relative : String) -> String {
  if root.has_suffix("/") {
    root + relative
  } else {
    root + "/" + relative
  }
}

///|
fn artifact_key(kind : String, id : String) -> String {
  "\{kind}:\{id}"
}

///|
fn entry_key(entry : @data_core.CatalogEntry) -> String {
  artifact_key(entry.artifact_kind, entry.artifact_id)
}

///|
fn artifact_ref_key(artifact : @data_core.ArtifactRef) -> String {
  artifact_key(artifact.artifact_kind, artifact.artifact_id)
}

///|
fn count_severity(
  findings : Array[@data_core.ValidationFinding],
  severity : @data_core.FindingSeverity,
) -> Int {
  let mut count = 0
  for finding in findings {
    if finding.severity == severity {
      count += 1
    }
  }
  count
}

///|
fn validation_status(
  findings : Array[@data_core.ValidationFinding],
) -> @data_core.ValidationStatus {
  if count_severity(findings, @data_core.FindingSeverity::Blocker) > 0 {
    @data_core.ValidationStatus::BlockedValidation
  } else if count_severity(
      findings,
      @data_core.FindingSeverity::WarningSeverity,
    ) >
    0 {
    @data_core.ValidationStatus::Warning
  } else {
    @data_core.ValidationStatus::Passed
  }
}

///|
fn finding(
  rule_id : String,
  severity : @data_core.FindingSeverity,
  entry : @data_core.CatalogEntry,
  message : String,
  recommendation : String,
) -> @data_core.ValidationFinding {
  @data_core.validation_finding(
    rule_id,
    severity,
    @data_core.catalog_entry_ref(entry),
    message,
    recommendation~,
  )
}

///|
fn catalog_marker(root : String) -> @data_core.CatalogEntry {
  @data_core.catalog_entry(
    "catalog",
    "data-catalog-v1",
    @data_store.catalog_path(root),
    status=@data_core.DataStatus::UnknownStatus,
    summary="data catalog",
  )
}

///|
fn has_entry(entries : Array[@data_core.CatalogEntry], key : String) -> Bool {
  for entry in entries {
    if entry_key(entry) == key {
      return true
    }
  }
  false
}

///|
fn add_duplicate_findings(
  findings : Array[@data_core.ValidationFinding],
  entries : Array[@data_core.CatalogEntry],
) -> Unit {
  for i in 0..<entries.length() {
    for j in (i + 1)..<entries.length() {
      if entry_key(entries[i]) == entry_key(entries[j]) {
        findings.push(
          finding(
            "duplicate-artifact-id",
            @data_core.FindingSeverity::Blocker,
            entries[i],
            "catalog contains duplicate artifact identity \{entry_key(entries[i])}",
            "keep exactly one manifest for each artifact kind and id",
          ),
        )
      }
    }
  }
}

///|
fn expected_manifest_path(
  root : String,
  entry : @data_core.CatalogEntry,
) -> String? {
  match entry.artifact_kind {
    "source" => Some(@data_store.source_path(root, entry.artifact_id))
    "dataset" => Some(@data_store.dataset_path(root, entry.artifact_id))
    "dataset-version" =>
      Some(@data_store.dataset_version_path(root, entry.artifact_id))
    "lineage" => Some(@data_store.lineage_path(root, entry.artifact_id))
    "validation-report" =>
      Some(@data_store.validation_report_path(root, entry.artifact_id))
    _ => None
  }
}

///|
fn add_manifest_path_findings(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  entry : @data_core.CatalogEntry,
) -> Unit {
  if entry.manifest_path == "" {
    findings.push(
      finding(
        "manifest-path-required",
        @data_core.FindingSeverity::Blocker,
        entry,
        "catalog entry has no manifest path",
        "write catalog entries with durable manifest paths",
      ),
    )
    return
  }
  if entry.manifest_path.contains("://") ||
    !entry.manifest_path.has_prefix(root) {
    findings.push(
      finding(
        "manifest-path-outside-root",
        @data_core.FindingSeverity::Blocker,
        entry,
        "catalog entry manifest is outside the data root",
        "keep cataloged manifests under the selected data root",
      ),
    )
  }
  match expected_manifest_path(root, entry) {
    Some(expected) =>
      if entry.manifest_path != expected {
        findings.push(
          finding(
            "manifest-path-not-canonical",
            @data_core.FindingSeverity::Blocker,
            entry,
            "catalog entry manifest path is not canonical",
            "rebuild the catalog from data_store-owned manifests",
          ),
        )
      }
    None => ()
  }
  if !@fsx.path_exists(entry.manifest_path) {
    findings.push(
      finding(
        "manifest-missing",
        @data_core.FindingSeverity::Blocker,
        entry,
        "catalog entry manifest file is missing",
        "remove stale catalog entries or restore the manifest",
      ),
    )
  }
}

///|
fn local_payload_path(root : String, data_ref : @data_core.DataRef) -> String? {
  match @data_core.data_payload_uri_relative_path(data_ref.uri) {
    Some(relative) => Some(join(root, relative))
    None => None
  }
}

///|
fn checksum_for_text(kind : @data_core.ChecksumKind, body : String) -> String {
  match kind {
    TextSumV1 => "text-sum-v1:bytes=\{body.length()}"
    BytesSumV1 => "bytes-sum-v1:bytes=\{body.length()}"
    _ => ""
  }
}

///|
fn validate_data_ref(
  findings : Array[@data_core.ValidationFinding],
  owner : @data_core.CatalogEntry,
  root : String,
  data_ref : @data_core.DataRef,
) -> Unit {
  let artifact = @data_core.catalog_entry_ref(owner)
  if !data_ref.uri.has_prefix("data://") {
    findings.push(
      @data_core.validation_finding(
        "data-ref-external-uri",
        @data_core.FindingSeverity::Blocker,
        artifact,
        "data ref \{data_ref.ref_id} uses non-local URI \{data_ref.uri}",
        recommendation="store durable payload refs as data:// relative paths",
      ),
    )
    return
  }
  let path = match local_payload_path(root, data_ref) {
    Some(value) => value
    None => {
      findings.push(
        @data_core.validation_finding(
          "data-ref-unsafe-uri",
          @data_core.FindingSeverity::Blocker,
          artifact,
          "data ref \{data_ref.ref_id} uses unsafe URI \{data_ref.uri}",
          recommendation="use relative data:// paths without absolute, empty, backslash, or parent-directory segments",
        ),
      )
      return
    }
  }
  if !@fsx.path_exists(path) {
    findings.push(
      @data_core.validation_finding(
        "payload-missing",
        @data_core.FindingSeverity::Blocker,
        artifact,
        "data ref \{data_ref.ref_id} payload is missing at \{path}",
        recommendation="restore the payload or remove the stale ref",
      ),
    )
    return
  }
  let maybe_body : String? = Some(@fsx.read_file_to_string(path)) catch {
    _ => None
  }
  let body = match maybe_body {
    Some(text) => text
    None => {
      findings.push(
        @data_core.validation_finding(
          "payload-read-failed",
          @data_core.FindingSeverity::Blocker,
          artifact,
          "data ref \{data_ref.ref_id} payload could not be read",
          recommendation="fix payload permissions or replace the payload",
        ),
      )
      return
    }
  }
  if data_ref.byte_count > 0L && body.length().to_int64() != data_ref.byte_count {
    findings.push(
      @data_core.validation_finding(
        "payload-byte-count-mismatch",
        @data_core.FindingSeverity::Blocker,
        artifact,
        "data ref \{data_ref.ref_id} byte count does not match payload",
        recommendation="refresh payload metadata from the stored file",
      ),
    )
  }
  match data_ref.checksum.kind {
    NoChecksum => ()
    TextSumV1 | BytesSumV1 => {
      let actual = checksum_for_text(data_ref.checksum.kind, body)
      if data_ref.checksum.value != actual {
        findings.push(
          @data_core.validation_finding(
            "payload-checksum-mismatch",
            @data_core.FindingSeverity::Blocker,
            artifact,
            "data ref \{data_ref.ref_id} checksum does not match payload",
            recommendation="refresh checksum metadata or restore the expected payload",
          ),
        )
      }
    }
    Sha256 | UnknownChecksumKind =>
      findings.push(
        @data_core.validation_finding(
          "payload-checksum-unsupported",
          @data_core.FindingSeverity::WarningSeverity,
          artifact,
          "data ref \{data_ref.ref_id} uses checksum kind \{@data_core.checksum_kind_label(data_ref.checksum.kind)} that this validator cannot compute yet",
          recommendation="use text-sum-v1 or bytes-sum-v1 until SHA-256 validation is implemented",
        ),
      )
  }
}

///|
fn add_source_findings(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  entry : @data_core.CatalogEntry,
) -> Unit {
  match @data_store.read_source(root, entry.artifact_id) {
    Ok(source) =>
      for data_ref in source.source_refs {
        validate_data_ref(findings, entry, root, data_ref)
      }
    Err(_) =>
      findings.push(
        finding(
          "source-read-failed",
          @data_core.FindingSeverity::Blocker,
          entry,
          "source manifest could not be read",
          "repair or remove the source manifest",
        ),
      )
  }
}

///|
fn add_dataset_findings(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  entry : @data_core.CatalogEntry,
) -> Unit {
  match @data_store.read_dataset(root, entry.artifact_id) {
    Ok(dataset) =>
      for data_ref in dataset.data_refs {
        validate_data_ref(findings, entry, root, data_ref)
      }
    Err(_) =>
      findings.push(
        finding(
          "dataset-read-failed",
          @data_core.FindingSeverity::Blocker,
          entry,
          "dataset manifest could not be read",
          "repair or remove the dataset manifest",
        ),
      )
  }
}

///|
fn add_version_findings(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  entry : @data_core.CatalogEntry,
) -> Unit {
  match @data_store.read_dataset_version(root, entry.artifact_id) {
    Ok(version) =>
      for data_ref in version.data_refs {
        validate_data_ref(findings, entry, root, data_ref)
      }
    Err(_) =>
      findings.push(
        finding(
          "dataset-version-read-failed",
          @data_core.FindingSeverity::Blocker,
          entry,
          "dataset version manifest could not be read",
          "repair or remove the dataset version manifest",
        ),
      )
  }
}

///|
fn add_lineage_findings(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  entries : Array[@data_core.CatalogEntry],
  entry : @data_core.CatalogEntry,
) -> Unit {
  match @data_store.read_lineage_manifest(root, entry.artifact_id) {
    Ok(lineage) => {
      let root_key = artifact_ref_key(lineage.root_artifact)
      if !has_entry(entries, root_key) {
        findings.push(
          finding(
            "lineage-root-missing",
            @data_core.FindingSeverity::Blocker,
            entry,
            "lineage root artifact \{root_key} is not cataloged",
            "catalog all artifacts referenced by lineage manifests",
          ),
        )
      }
      for edge in lineage.edges {
        let from_key = artifact_ref_key(edge.from_artifact)
        let to_key = artifact_ref_key(edge.to_artifact)
        if !has_entry(entries, from_key) {
          findings.push(
            finding(
              "lineage-edge-source-missing",
              @data_core.FindingSeverity::Blocker,
              entry,
              "lineage edge source \{from_key} is not cataloged",
              "catalog all source artifacts referenced by lineage edges",
            ),
          )
        }
        if !has_entry(entries, to_key) {
          findings.push(
            finding(
              "lineage-edge-target-missing",
              @data_core.FindingSeverity::Blocker,
              entry,
              "lineage edge target \{to_key} is not cataloged",
              "catalog all target artifacts referenced by lineage edges",
            ),
          )
        }
      }
    }
    Err(_) =>
      findings.push(
        finding(
          "lineage-read-failed",
          @data_core.FindingSeverity::Blocker,
          entry,
          "lineage manifest could not be read",
          "repair or remove the lineage manifest",
        ),
      )
  }
}

///|
fn add_catalog_stale_finding(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  previous : @data_core.DataCatalog?,
  rebuilt : @data_core.DataCatalog,
) -> Unit {
  let marker = catalog_marker(root)
  match previous {
    None =>
      findings.push(
        finding(
          "catalog-missing",
          @data_core.FindingSeverity::WarningSeverity,
          marker,
          "catalog was missing before validation rebuilt it",
          "commit or publish the rebuilt catalog before handoff",
        ),
      )
    Some(catalog) =>
      if catalog.entries != rebuilt.entries {
        findings.push(
          finding(
            "catalog-stale",
            @data_core.FindingSeverity::Blocker,
            marker,
            "stored catalog does not match manifests in the data root",
            "rebuild catalog from manifests before handoff",
          ),
        )
      }
  }
}

///|
fn add_entry_findings(
  findings : Array[@data_core.ValidationFinding],
  root : String,
  entries : Array[@data_core.CatalogEntry],
) -> Unit {
  add_duplicate_findings(findings, entries)
  for entry in entries {
    add_manifest_path_findings(findings, root, entry)
    match entry.artifact_kind {
      "source" => add_source_findings(findings, root, entry)
      "dataset" => add_dataset_findings(findings, root, entry)
      "dataset-version" => add_version_findings(findings, root, entry)
      "lineage" => add_lineage_findings(findings, root, entries, entry)
      _ => ()
    }
  }
}

///|
pub fn validate_root(
  root : String,
  generated_at_ms : Int64,
) -> Result[@data_core.ValidationReport, @data_store.DataStoreIssue] {
  let previous_catalog = match @data_store.read_catalog(root) {
    Ok(catalog) => Some(catalog)
    Err(_) => None
  }
  let rebuilt = match @data_store.rebuild_catalog(root, generated_at_ms) {
    Ok(value) => value.catalog
    Err(error) => return Err(error)
  }
  let findings : Array[@data_core.ValidationFinding] = []
  add_catalog_stale_finding(findings, root, previous_catalog, rebuilt)
  add_entry_findings(findings, root, rebuilt.entries)
  Ok(
    @data_core.validation_report(
      report_id(generated_at_ms),
      root,
      generated_at_ms,
      validation_status(findings),
      findings~,
    ),
  )
}

///|
pub fn validate_and_write_root(
  root : String,
  generated_at_ms : Int64,
) -> Result[StoredValidationResult, @data_store.DataStoreIssue] {
  let report = match validate_root(root, generated_at_ms) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let persisted = match @data_store.write_validation_report(root, report) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match @data_store.rebuild_catalog(root, generated_at_ms) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok({
    root,
    validation_report_id: report.validation_report_id,
    report_path: persisted.path,
    catalog_path: @data_store.catalog_path(root),
    status: report.status,
    finding_count: @data_core.validation_finding_count(report),
    blocker_count: @data_core.validation_blocker_count(report),
    warning_count: count_severity(
      report.findings,
      @data_core.FindingSeverity::WarningSeverity,
    ),
    report,
  })
}
