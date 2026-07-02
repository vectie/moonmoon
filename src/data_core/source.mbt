///|
pub type SourceId = String

///|
pub(all) struct DataSource {
  source_id : SourceId
  authority : String
  label : String
  source_url : String
  license : String
  citation : String
  created_at_ms : Int64
  source_refs : Array[DataRef]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn data_source(
  source_id : SourceId,
  authority : String,
  label : String,
  source_url : String,
  license : String,
  citation : String,
  created_at_ms : Int64,
  source_refs? : Array[DataRef] = [],
) -> DataSource {
  {
    source_id,
    authority,
    label,
    source_url,
    license,
    citation,
    created_at_ms,
    source_refs,
  }
}
