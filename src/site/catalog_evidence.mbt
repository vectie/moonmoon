///|
pub(all) struct SiteCatalogEvidence {
  artifact : @data_core.ArtifactRef
  authority : String
  label : String
  source_url : String
  ref_uris : Array[String]
  linked_source_ids : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SiteCatalogValidationEvidence {
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
fn source_manifest_path(source_id : String) -> String {
  "sources/\{source_id}.json"
}

///|
fn dataset_manifest_path(dataset_id : String) -> String {
  "datasets/\{dataset_id}.json"
}

///|
fn catalog_source_evidence(
  source : @data_core.DataSource,
) -> SiteCatalogEvidence {
  {
    artifact: @data_core.artifact_ref(
      "source",
      source.source_id,
      source_manifest_path(source.source_id),
      status=@data_core.DataStatus::Verified,
      summary=source.label,
    ),
    authority: source.authority,
    label: source.label,
    source_url: source.source_url,
    ref_uris: ref_uris(source.source_refs),
    linked_source_ids: [source.source_id],
  }
}

///|
fn first_source_for_dataset(
  dataset : @data_core.DatasetManifest,
  sources : Array[@data_core.DataSource],
) -> @data_core.DataSource? {
  if dataset.source_ids.is_empty() {
    return None
  }
  let source_id = dataset.source_ids[0]
  for source in sources {
    if source.source_id == source_id {
      return Some(source)
    }
  }
  None
}

///|
fn catalog_dataset_evidence(
  dataset : @data_core.DatasetManifest,
  sources : Array[@data_core.DataSource],
) -> SiteCatalogEvidence {
  let source = first_source_for_dataset(dataset, sources)
  {
    artifact: @data_core.artifact_ref(
      "dataset",
      dataset.dataset_id,
      dataset_manifest_path(dataset.dataset_id),
      status=dataset.status,
      summary=dataset.summary,
    ),
    authority: match source {
      Some(value) => value.authority
      None => ""
    },
    label: dataset.summary,
    source_url: match source {
      Some(value) => value.source_url
      None => ""
    },
    ref_uris: ref_uris(dataset.data_refs),
    linked_source_ids: dataset.source_ids,
  }
}

///|
pub fn first_trusted_square_catalog_evidence() -> Array[SiteCatalogEvidence] {
  let sources = @lunar_data.first_trusted_square_lunar_sources()
  let datasets = @lunar_data.first_trusted_square_lunar_datasets()
  sources.map(catalog_source_evidence) +
  datasets.map(fn(dataset) { catalog_dataset_evidence(dataset, sources) })
}

///|
pub fn missing_catalog_validation_evidence() -> SiteCatalogValidationEvidence {
  {
    artifact: @data_core.artifact_ref(
      "validation-report",
      "",
      "",
      status=@data_core.DataStatus::UnknownStatus,
      summary="catalog validation has not been read from a data root",
    ),
    validation_status: @data_core.ValidationStatus::Warning,
    ready: false,
    finding_count: 0,
    blocker_count: 0,
    warning_count: 0,
    summary: "catalog validation has not been read from a data root",
  }
}

///|
pub fn catalog_evidence_for_artifact(
  dossier : SiteDossier,
  artifact_kind : String,
  artifact_id : String,
) -> SiteCatalogEvidence? {
  for evidence in dossier.catalog_evidence {
    if evidence.artifact.artifact_kind == artifact_kind &&
      evidence.artifact.artifact_id == artifact_id {
      return Some(evidence)
    }
  }
  None
}
