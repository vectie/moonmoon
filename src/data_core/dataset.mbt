///|
pub type DatasetId = String

///|
pub type DatasetVersionId = String

///|
pub(all) struct DatasetManifest {
  dataset_id : DatasetId
  kind : String
  status : DataStatus
  source_ids : Array[SourceId]
  data_refs : Array[DataRef]
  created_at_ms : Int64
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DatasetVersion {
  version_id : DatasetVersionId
  dataset_id : DatasetId
  status : DataStatus
  parent_version_ids : Array[DatasetVersionId]
  data_refs : Array[DataRef]
  created_at_ms : Int64
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn dataset_manifest(
  dataset_id : DatasetId,
  kind : String,
  status : DataStatus,
  created_at_ms : Int64,
  source_ids? : Array[SourceId] = [],
  data_refs? : Array[DataRef] = [],
  summary? : String = "",
) -> DatasetManifest {
  { dataset_id, kind, status, source_ids, data_refs, created_at_ms, summary }
}

///|
pub fn dataset_version(
  version_id : DatasetVersionId,
  dataset_id : DatasetId,
  status : DataStatus,
  created_at_ms : Int64,
  parent_version_ids? : Array[DatasetVersionId] = [],
  data_refs? : Array[DataRef] = [],
  summary? : String = "",
) -> DatasetVersion {
  {
    version_id,
    dataset_id,
    status,
    parent_version_ids,
    data_refs,
    created_at_ms,
    summary,
  }
}
