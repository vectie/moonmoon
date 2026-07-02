///|
pub(all) struct CatalogedLunarSource {
  artifact : @data_core.ArtifactRef
  source_id : String
  authority : String
  label : String
  source_url : String
  source_ref_count : Int
  source_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CatalogedLunarDataset {
  artifact : @data_core.ArtifactRef
  dataset_id : String
  kind : String
  status : @data_core.DataStatus
  authority : String
  source_url : String
  source_ids : Array[String]
  data_ref_count : Int
  data_ref_uris : Array[String]
  coverage : @lunar_data.LunarCoverage
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CatalogedLunarValidation {
  artifact : @data_core.ArtifactRef
  validation_status : @data_core.ValidationStatus
  ready : Bool
  finding_count : Int
  blocker_count : Int
  warning_count : Int
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn ref_uris(refs : Array[@data_core.DataRef]) -> Array[String] {
  refs.map(fn(data_ref) { data_ref.uri })
}

///|
fn catalog_entry_for(
  catalog : @data_core.DataCatalog,
  artifact_kind : String,
  artifact_id : String,
) -> @data_core.CatalogEntry? {
  for entry in catalog.entries {
    if entry.artifact_kind == artifact_kind && entry.artifact_id == artifact_id {
      return Some(entry)
    }
  }
  None
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
fn warning_count(report : @data_core.ValidationReport) -> Int {
  let mut count = 0
  for finding in report.findings {
    if finding.severity == @data_core.FindingSeverity::WarningSeverity {
      count += 1
    }
  }
  count
}

///|
pub fn first_trusted_square_catalog_validation(
  root : String,
) -> Result[CatalogedLunarValidation, @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let entry = match latest_root_validation_entry(catalog) {
    Some(value) => value
    None =>
      return Err({
        code: "lunar-catalog-validation-not-cataloged",
        path: root,
        message: "first trusted square catalog root has no validation report",
      })
  }
  let report = match
    @data_store.read_validation_report(root, entry.artifact_id) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let blocker_count = @data_core.validation_blocker_count(report)
  let warnings = warning_count(report)
  let finding_count = @data_core.validation_finding_count(report)
  Ok({
    artifact: @data_core.catalog_entry_ref(entry),
    validation_status: report.status,
    ready: report.status == @data_core.ValidationStatus::Passed &&
    blocker_count == 0,
    finding_count,
    blocker_count,
    warning_count: warnings,
    summary: "\{finding_count} finding(s), \{blocker_count} blocker(s), \{warnings} warning(s)",
  })
}

///|
pub fn first_trusted_square_catalog_sources(
  root : String,
) -> Result[Array[CatalogedLunarSource], @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rows : Array[CatalogedLunarSource] = []
  for source in @lunar_data.first_trusted_square_lunar_sources() {
    match catalog_entry_for(catalog, "source", source.source_id) {
      Some(entry) => {
        let stored = match @data_store.read_source(root, source.source_id) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        rows.push({
          artifact: @data_core.catalog_entry_ref(entry),
          source_id: stored.source_id,
          authority: stored.authority,
          label: stored.label,
          source_url: stored.source_url,
          source_ref_count: stored.source_refs.length(),
          source_ref_uris: ref_uris(stored.source_refs),
        })
      }
      None => ()
    }
  }
  Ok(rows)
}

///|
fn dataset_coverage(dataset_id : String) -> @lunar_data.LunarCoverage {
  if dataset_id == @lunar_data.first_trusted_square_lola_dataset().dataset_id {
    @lunar_data.first_trusted_square_lola_extraction_candidate().coverage
  } else if dataset_id ==
    @lunar_data.first_trusted_square_ephemeris_dataset().dataset_id {
    @lunar_data.first_trusted_square_ephemeris_window().coverage
  } else {
    @lunar_data.first_trusted_square_tile_manifest().coverage
  }
}

///|
fn source_for_dataset(
  dataset : @data_core.DatasetManifest,
) -> @data_core.DataSource? {
  if dataset.source_ids.is_empty() {
    return None
  }
  let source_id = dataset.source_ids[0]
  for source in @lunar_data.first_trusted_square_lunar_sources() {
    if source.source_id == source_id {
      return Some(source)
    }
  }
  None
}

///|
pub fn first_trusted_square_catalog_datasets(
  root : String,
) -> Result[Array[CatalogedLunarDataset], @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rows : Array[CatalogedLunarDataset] = []
  for dataset in @lunar_data.first_trusted_square_lunar_datasets() {
    match catalog_entry_for(catalog, "dataset", dataset.dataset_id) {
      Some(entry) => {
        let stored = match @data_store.read_dataset(root, dataset.dataset_id) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let source = source_for_dataset(stored)
        rows.push({
          artifact: @data_core.catalog_entry_ref(entry),
          dataset_id: stored.dataset_id,
          kind: stored.kind,
          status: stored.status,
          authority: match source {
            Some(value) => value.authority
            None => ""
          },
          source_url: match source {
            Some(value) => value.source_url
            None => ""
          },
          source_ids: stored.source_ids,
          data_ref_count: stored.data_refs.length(),
          data_ref_uris: ref_uris(stored.data_refs),
          coverage: dataset_coverage(stored.dataset_id),
        })
      }
      None => ()
    }
  }
  Ok(rows)
}
