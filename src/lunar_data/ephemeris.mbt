///|
pub(all) struct LunarEphemerisWindow {
  window_id : String
  source_id : String
  output_path : String
  output_sha256 : String
  output_bytes : Int64
  coverage : LunarCoverage
  time_basis : String
  review_status : LunarReviewStatus
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_ephemeris_window() -> LunarEphemerisWindow {
  {
    window_id: "lunar-ephemeris-first-trusted-square-power-window-v1",
    source_id: first_trusted_square_ephemeris_source_candidate().source_id,
    output_path: "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
    output_sha256: "031e5dbb0cc2ec14c15e2b049be66210f871478d602d8185d377257b2809627b",
    output_bytes: 3768L,
    coverage: lunar_coverage(-89.90, -89.86, 0.10, 0.14, -89.88, 0.12, 20.0),
    time_basis: "Pinned local Sun/Moon geometry fixture",
    review_status: NeedsHumanReview,
    notes: [
      "This evidence supports the power-window gate and remains review-blocked for mission clearance.",
      "The fixture is local JSON generated from pinned ephemeris and orientation inputs.",
    ],
  }
}

///|
pub fn first_trusted_square_ephemeris_dataset() -> @data_core.DatasetManifest {
  let source = first_trusted_square_ephemeris_source()
  let window = first_trusted_square_ephemeris_window()
  @data_core.dataset_manifest(
    "naif-lunar-first-trusted-square-power-window-v1",
    "lunar-ephemeris-power-window",
    @data_core.DataStatus::Curated,
    0L,
    source_ids=[source.source_id],
    data_refs=[
      @data_core.data_ref(
        "first-trusted-square-power-window-json",
        "lunar-ephemeris-json",
        @data_core.data_uri(
          "sources/lunar_ephemeris/first_trusted_square_power_window.json",
        ),
        content_type="application/json",
        byte_count=window.output_bytes,
        checksum=@data_core.declared_checksum(
          @data_core.ChecksumKind::Sha256,
          window.output_sha256,
        ),
      ),
    ],
    summary="Curated local Sun/Moon geometry and power-window evidence for the first trusted square.",
  )
}

///|
pub fn first_trusted_square_lunar_datasets() -> Array[
  @data_core.DatasetManifest,
] {
  [
    first_trusted_square_lola_dataset(),
    first_trusted_square_ephemeris_dataset(),
  ]
}
