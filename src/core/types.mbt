///|
pub type SiteId = String

///|
pub type DatasetId = String

///|
pub type TileId = String

///|
pub(all) enum ClaimKind {
  Measured
  Derived
  Simulated
  Assumed
  Unknown
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn claim_kind_label(kind : ClaimKind) -> String {
  match kind {
    Measured => "measured"
    Derived => "derived"
    Simulated => "simulated"
    Assumed => "assumed"
    Unknown => "unknown"
  }
}

///|
pub(all) struct Provenance {
  dataset_id : DatasetId
  source_title : String
  source_url : String
  license : String
  product_type : String
  claim_kind : ClaimKind
  generated_by : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Uncertainty {
  confidence : Double
  label : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarCoordinate {
  latitude_deg : Double
  longitude_deg : Double
  radius_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarBounds {
  south_deg : Double
  north_deg : Double
  west_deg : Double
  east_deg : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarSite {
  site_id : SiteId
  name : String
  body : String
  bounds : LunarBounds
  center : LunarCoordinate
  purpose : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainCell {
  tile_id : TileId
  row : Int
  col : Int
  elevation_m : Double
  provenance : Provenance
  uncertainty : Uncertainty
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn confidence_label(confidence : Double) -> String {
  if confidence >= 0.85 {
    "high"
  } else if confidence >= 0.65 {
    "medium"
  } else if confidence > 0.0 {
    "low"
  } else {
    "unknown"
  }
}

///|
pub fn uncertainty(confidence : Double, note : String) -> Uncertainty {
  { confidence, label: confidence_label(confidence), note }
}

///|
pub fn measured_provenance(
  dataset_id : DatasetId,
  source_title : String,
  source_url : String,
  license : String,
  product_type : String,
) -> Provenance {
  {
    dataset_id,
    source_title,
    source_url,
    license,
    product_type,
    claim_kind: Measured,
    generated_by: "source",
  }
}

///|
pub fn derived_provenance(
  source : Provenance,
  generated_by : String,
  product_type : String,
) -> Provenance {
  {
    dataset_id: source.dataset_id,
    source_title: source.source_title,
    source_url: source.source_url,
    license: source.license,
    product_type,
    claim_kind: Derived,
    generated_by,
  }
}
