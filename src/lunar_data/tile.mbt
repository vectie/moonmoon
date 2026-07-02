///|
pub(all) struct LunarTileManifest {
  tile_id : String
  terrain_dataset_id : String
  ephemeris_dataset_id : String
  coverage : LunarCoverage
  terrain_extraction_id : String
  ephemeris_window_id : String
  review_status : LunarReviewStatus
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_tile_manifest() -> LunarTileManifest {
  {
    tile_id: "first-trusted-square",
    terrain_dataset_id: first_trusted_square_lola_dataset().dataset_id,
    ephemeris_dataset_id: first_trusted_square_ephemeris_dataset().dataset_id,
    coverage: lunar_coverage(-89.90, -89.86, 0.10, 0.14, -89.88, 0.12, 20.0),
    terrain_extraction_id: first_trusted_square_lola_extraction_candidate().extraction_id,
    ephemeris_window_id: first_trusted_square_ephemeris_window().window_id,
    review_status: NeedsHumanReview,
  }
}
