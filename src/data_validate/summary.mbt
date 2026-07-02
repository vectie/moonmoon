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
  dataset_kind_counts : Array[DataKindCount]
  data_ref_kind_counts : Array[DataKindCount]
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DataKindCount {
  kind : String
  count : Int
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
fn increment_kind_count(counts : Array[DataKindCount], kind : String) -> Unit {
  for index in 0..<counts.length() {
    if counts[index].kind == kind {
      counts[index] = { kind, count: counts[index].count + 1 }
      return
    }
  }
  counts.push({ kind, count: 1 })
}

///|
fn add_dataset_kind_counts(
  root : String,
  catalog : @data_core.DataCatalog,
  dataset_kind_counts : Array[DataKindCount],
  data_ref_kind_counts : Array[DataKindCount],
) -> Result[Unit, @data_store.DataStoreIssue] {
  for entry in catalog.entries {
    if entry.artifact_kind == "dataset" {
      let dataset = match @data_store.read_dataset(root, entry.artifact_id) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      increment_kind_count(dataset_kind_counts, dataset.kind)
      for data_ref in dataset.data_refs {
        increment_kind_count(data_ref_kind_counts, data_ref.kind)
      }
    }
  }
  Ok(())
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
  let dataset_kind_counts : Array[DataKindCount] = []
  let data_ref_kind_counts : Array[DataKindCount] = []
  match
    add_dataset_kind_counts(
      root, catalog, dataset_kind_counts, data_ref_kind_counts,
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
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
    dataset_kind_counts,
    data_ref_kind_counts,
    next_action: if ready {
      "continue domain migration against this validated data root"
    } else {
      "repair the root validation report findings before adding domain data"
    },
  })
}
