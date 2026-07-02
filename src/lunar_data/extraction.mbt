///|
pub(all) struct LunarExtractionCandidate {
  extraction_id : String
  selection_id : String
  generated_by : String
  output_path : String
  output_sha256 : String
  output_bytes : Int64
  tile_id : String
  coverage : LunarCoverage
  source_row_start : Int
  source_col_start : Int
  rows : Int
  cols : Int
  cell_size_m : Double
  value_unit : String
  claim_kind : String
  review_status : LunarReviewStatus
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_lola_extraction_candidate() -> LunarExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-first-trusted-square-v1",
    selection_id: first_trusted_square_lola_product_selection().selection_id,
    generated_by: "MoonBit source extraction",
    output_path: "data/sources/lro_lola/first_trusted_square_dem.csv",
    output_sha256: "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
    output_bytes: 636L,
    tile_id: "first-trusted-square-lola",
    coverage: lunar_coverage(-89.90, -89.86, 0.10, 0.14, -89.88, 0.12, 20.0),
    source_row_start: 3972,
    source_col_start: 3790,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    value_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: "measured",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from HTTP byte ranges against ldem_875s_20m_float.img, not from a committed raw image.",
      "This extraction is the active Moonmoon trusted-square fixture for software proof.",
    ],
  }
}

///|
pub fn first_trusted_square_lola_dataset() -> @data_core.DatasetManifest {
  let source = first_trusted_square_lola_source()
  let extraction = first_trusted_square_lola_extraction_candidate()
  @data_core.dataset_manifest(
    "lro-lola-first-trusted-square-dem-v1",
    "lunar-terrain-dem",
    @data_core.DataStatus::Verified,
    0L,
    source_ids=[source.source_id],
    data_refs=[
      @data_core.data_ref(
        "first-trusted-square-dem-csv",
        "lunar-dem-csv",
        @data_core.data_uri("sources/lro_lola/first_trusted_square_dem.csv"),
        content_type="text/csv",
        byte_count=extraction.output_bytes,
        checksum=@data_core.declared_checksum(
          @data_core.ChecksumKind::Sha256,
          extraction.output_sha256,
        ),
      ),
    ],
    summary="Measured LOLA DEM extraction for the first trusted square.",
  )
}
