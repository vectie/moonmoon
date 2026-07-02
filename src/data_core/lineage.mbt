///|
pub type LineageId = String

///|
pub(all) struct LineageEdge {
  from_artifact : ArtifactRef
  to_artifact : ArtifactRef
  relation : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LineageManifest {
  lineage_id : LineageId
  root_artifact : ArtifactRef
  created_at_ms : Int64
  edges : Array[LineageEdge]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn lineage_edge(
  from_artifact : ArtifactRef,
  to_artifact : ArtifactRef,
  relation : String,
) -> LineageEdge {
  { from_artifact, to_artifact, relation }
}

///|
pub fn lineage_manifest(
  lineage_id : LineageId,
  root_artifact : ArtifactRef,
  created_at_ms : Int64,
  edges? : Array[LineageEdge] = [],
) -> LineageManifest {
  { lineage_id, root_artifact, created_at_ms, edges }
}
