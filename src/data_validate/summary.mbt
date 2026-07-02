///|
pub(all) struct DataRootValidationSummary {
  root : String
  status : String
  ready : Bool
  catalog_entry_count : Int
  source_count : Int
  dataset_count : Int
  version_count : Int
  artifact_count : Int
  lineage_count : Int
  validation_report_count : Int
  root_validation_report_count : Int
  auxiliary_validation_report_count : Int
  latest_validation_artifact : @data_core.ArtifactRef
  validation_status : @data_core.ValidationStatus
  finding_count : Int
  blocker_count : Int
  warning_count : Int
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn summary_issue(
  code : String,
  path : String,
  message : String,
) -> @data_store.DataStoreIssue {
  { code, path, message }
}

///|
fn latest_root_validation_entry(
  catalog : @data_core.DataCatalog,
) -> @data_core.CatalogEntry? {
  let mut found : @data_core.CatalogEntry? = None
  for entry in catalog.entries {
    if entry.artifact_kind == "validation-report" &&
      entry.artifact_id.has_prefix("validation-") {
      found = Some(entry)
    }
  }
  found
}

///|
fn count_entries(catalog : @data_core.DataCatalog, kind : String) -> Int {
  let mut count = 0
  for entry in catalog.entries {
    if entry.artifact_kind == kind {
      count += 1
    }
  }
  count
}

///|
fn artifact_entry_count(catalog : @data_core.DataCatalog) -> Int {
  let mut count = 0
  for entry in catalog.entries {
    if entry.artifact_kind != "source" &&
      entry.artifact_kind != "dataset" &&
      entry.artifact_kind != "dataset-version" &&
      entry.artifact_kind != "lineage" &&
      entry.artifact_kind != "validation-report" {
      count += 1
    }
  }
  count
}

///|
fn root_validation_report_count(catalog : @data_core.DataCatalog) -> Int {
  let mut count = 0
  for entry in catalog.entries {
    if entry.artifact_kind == "validation-report" &&
      entry.artifact_id.has_prefix("validation-") {
      count += 1
    }
  }
  count
}

///|
pub fn data_root_validation_summary_from_root(
  root : String,
) -> Result[DataRootValidationSummary, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let validation_entry = match latest_root_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err(
        summary_issue(
          "data-root-validation-not-cataloged", root, "data root has no cataloged root validation report",
        ),
      )
  }
  let report = match
    @data_store.read_validation_report(root, validation_entry.artifact_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let root_report_count = root_validation_report_count(catalog)
  let validation_report_count = count_entries(catalog, "validation-report")
  let blocker_count = @data_core.validation_blocker_count(report)
  let warning_count = count_severity(
    report.findings,
    @data_core.FindingSeverity::WarningSeverity,
  )
  let ready = report.status == @data_core.ValidationStatus::Passed &&
    blocker_count == 0
  let status = if ready {
    "ready"
  } else if blocker_count > 0 {
    "blocked"
  } else {
    "needs-review"
  }
  Ok({
    root,
    status,
    ready,
    catalog_entry_count: catalog.entries.length(),
    source_count: count_entries(catalog, "source"),
    dataset_count: count_entries(catalog, "dataset"),
    version_count: count_entries(catalog, "dataset-version"),
    artifact_count: artifact_entry_count(catalog),
    lineage_count: count_entries(catalog, "lineage"),
    validation_report_count,
    root_validation_report_count: root_report_count,
    auxiliary_validation_report_count: validation_report_count -
    root_report_count,
    latest_validation_artifact: @data_core.catalog_entry_ref(validation_entry),
    validation_status: report.status,
    finding_count: @data_core.validation_finding_count(report),
    blocker_count,
    warning_count,
    next_action: if ready {
      "continue domain migration against this validated data root"
    } else {
      "repair the root validation report findings before adding domain data"
    },
  })
}
