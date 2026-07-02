///|
pub type CatalogId = String

///|
pub(all) struct CatalogEntry {
  artifact_kind : String
  artifact_id : ArtifactId
  manifest_path : String
  status : DataStatus
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DataCatalog {
  catalog_id : CatalogId
  root : String
  generated_at_ms : Int64
  entries : Array[CatalogEntry]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn catalog_entry(
  artifact_kind : String,
  artifact_id : ArtifactId,
  manifest_path : String,
  status? : DataStatus = UnknownStatus,
  summary? : String = "",
) -> CatalogEntry {
  { artifact_kind, artifact_id, manifest_path, status, summary }
}

///|
pub fn data_catalog(
  root : String,
  generated_at_ms : Int64,
  entries : Array[CatalogEntry],
  catalog_id? : CatalogId = "data-catalog-v1",
) -> DataCatalog {
  { catalog_id, root, generated_at_ms, entries }
}

///|
pub fn catalog_entry_ref(entry : CatalogEntry) -> ArtifactRef {
  artifact_ref(
    entry.artifact_kind,
    entry.artifact_id,
    entry.manifest_path,
    status=entry.status,
    summary=entry.summary,
  )
}

///|
pub fn catalog_refs(catalog : DataCatalog) -> Array[ArtifactRef] {
  catalog.entries.map(fn(entry) { catalog_entry_ref(entry) })
}
