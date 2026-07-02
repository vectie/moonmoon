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
pub fn first_trusted_square_west_contour_lola_extraction_candidate() -> LunarExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-west-contour-v1",
    selection_id: first_trusted_square_lola_product_selection().selection_id,
    generated_by: "MoonBit source extraction",
    output_path: "data/sources/lro_lola/first_trusted_square_west_contour_dem.csv",
    output_sha256: "1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6",
    output_bytes: 844L,
    tile_id: "first-trusted-square-west-contour-lola",
    coverage: lunar_coverage(-89.90, -89.86, 0.06, 0.10, -89.88, 0.08, 20.0),
    source_row_start: 3972,
    source_col_start: 3786,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    value_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: "measured",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the west-adjacent HTTP byte ranges next to the active trusted-square window.",
      "This window gives the west-contour route candidate measured terrain evidence rather than a hand-authored estimate.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_north_rim_lola_extraction_candidate() -> LunarExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-north-rim-v1",
    selection_id: first_trusted_square_lola_product_selection().selection_id,
    generated_by: "MoonBit source extraction",
    output_path: "data/sources/lro_lola/first_trusted_square_north_rim_dem.csv",
    output_sha256: "40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28",
    output_bytes: 796L,
    tile_id: "first-trusted-square-north-rim-lola",
    coverage: lunar_coverage(-89.86, -89.82, 0.10, 0.14, -89.86, 0.12, 20.0),
    source_row_start: 3968,
    source_col_start: 3790,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    value_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: "measured",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the north-adjacent HTTP byte ranges next to the active trusted-square window.",
      "This window gives the north-rim route candidate measured terrain evidence before illumination analysis exists.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_southwest_bypass_lola_extraction_candidate() -> LunarExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-southwest-bypass-v1",
    selection_id: first_trusted_square_lola_product_selection().selection_id,
    generated_by: "MoonBit source extraction",
    output_path: "data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv",
    output_sha256: "c47b837a8ed5bb818c865782396d44dae01b15b03a2a6a83c372548092c1ace5",
    output_bytes: 908L,
    tile_id: "first-trusted-square-southwest-bypass-lola",
    coverage: lunar_coverage(-89.92, -89.88, 0.02, 0.06, -89.90, 0.04, 20.0),
    source_row_start: 3980,
    source_col_start: 3782,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    value_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: "measured",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the wider southwest HTTP byte ranges after the first adjacent west/north windows remained blocked.",
      "This is the lowest-grade window in the first 5x5 corridor scan, but still exceeds the conservative rover traverse limits.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_south_stepout_lola_extraction_candidate() -> LunarExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-south-stepout-v1",
    selection_id: first_trusted_square_lola_product_selection().selection_id,
    generated_by: "MoonBit source extraction",
    output_path: "data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv",
    output_sha256: "dde783fcf74ac0567bb2d6bb8eead6c2f83b620603319690aa51011486d7a19c",
    output_bytes: 860L,
    tile_id: "first-trusted-square-south-stepout-lola",
    coverage: lunar_coverage(-89.92, -89.88, 0.10, 0.14, -89.90, 0.12, 20.0),
    source_row_start: 3980,
    source_col_start: 3790,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    value_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: "measured",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the wider south HTTP byte ranges after the first adjacent west/north windows remained blocked.",
      "This window is smoother than the active patch but still exceeds conservative rover traverse limits.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_northeast_stepout_lola_extraction_candidate() -> LunarExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-northeast-stepout-v1",
    selection_id: first_trusted_square_lola_product_selection().selection_id,
    generated_by: "MoonBit source extraction",
    output_path: "data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv",
    output_sha256: "b04648fc553a9c55effd9b6900039cc722b05de8b284dae353c9eba660c18b4c",
    output_bytes: 924L,
    tile_id: "first-trusted-square-northeast-stepout-lola",
    coverage: lunar_coverage(-89.78, -89.74, 0.26, 0.30, -89.76, 0.28, 20.0),
    source_row_start: 3960,
    source_col_start: 3806,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    value_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: "measured",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the best measured window in the active 9x9 LOLA corridor scan.",
      "This window now has a named route fixture and route id instead of staying only as a ranked scan row.",
      "The route remains blocked by conservative terrain and power gates before simulation.",
    ],
  }
}

///|
pub fn first_trusted_square_route_lola_extraction_candidates() -> Array[
  LunarExtractionCandidate,
] {
  [
    first_trusted_square_west_contour_lola_extraction_candidate(),
    first_trusted_square_north_rim_lola_extraction_candidate(),
    first_trusted_square_southwest_bypass_lola_extraction_candidate(),
    first_trusted_square_south_stepout_lola_extraction_candidate(),
    first_trusted_square_northeast_stepout_lola_extraction_candidate(),
  ]
}

///|
pub fn first_trusted_square_all_lola_extraction_candidates() -> Array[
  LunarExtractionCandidate,
] {
  [first_trusted_square_lola_extraction_candidate()] +
  first_trusted_square_route_lola_extraction_candidates()
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
