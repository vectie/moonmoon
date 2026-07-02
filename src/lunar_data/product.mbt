///|
pub(all) struct LunarProductSelection {
  selection_id : String
  source_id : String
  product_id : String
  product_lid : String
  image_url : String
  label_url : String
  local_label_path : String
  label_sha256 : String
  label_bytes : Int64
  image_bytes : Int64
  coordinate_frame : LunarCoordinateFrame
  coverage : LunarCoverage
  lines : Int
  samples : Int
  data_type : String
  unit : String
  value_offset_km : Double
  selection_reason : String
  review_status : LunarReviewStatus
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_lola_product_selection() -> LunarProductSelection {
  {
    selection_id: "select-ldem-875s-20m-float-v1",
    source_id: first_trusted_square_lola_source_candidate().source_id,
    product_id: "ldem_875s_20m_float",
    product_lid: "urn:nasa:pds:lro_lola_rdr:data_gridded:ldem_875s_20m_float",
    image_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    label_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.xml",
    local_label_path: "data/sources/lro_lola/ldem_875s_20m_float.xml",
    label_sha256: "10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53",
    label_bytes: 11629L,
    image_bytes: 230068224L,
    coordinate_frame: lro_lola_south_pole_frame(),
    coverage: lunar_coverage(-90.0, -87.5, 0.0, 360.0, -89.88, 0.12, 20.0),
    lines: 7584,
    samples: 7584,
    data_type: "IEEE754LSBSingle",
    unit: "KILOMETER",
    value_offset_km: 1737.4,
    selection_reason: "Covers the first trusted square near 89.88S with south-polar 20 m/pixel LOLA DEM data.",
    review_status: AcceptedForSoftwareProof,
  }
}
