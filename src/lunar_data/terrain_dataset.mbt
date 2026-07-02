///|
pub(all) struct LunarTerrainDatasetRecord {
  dataset_id : String
  title : String
  product_type : String
  extraction : LunarExtractionCandidate
  inline_fingerprint : String
  citation : String
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn lola_terrain_dataset(
  dataset_id : String,
  title : String,
  product_type : String,
  extraction : LunarExtractionCandidate,
  inline_fingerprint : String,
  citation : String,
  notes : Array[String],
) -> LunarTerrainDatasetRecord {
  {
    dataset_id,
    title,
    product_type,
    extraction,
    inline_fingerprint,
    citation,
    notes,
  }
}

///|
pub fn first_trusted_square_lola_terrain_dataset_record() -> LunarTerrainDatasetRecord {
  lola_terrain_dataset(
    "lro-lola-first-trusted-square-dem-v1",
    "LOLA Shackleton Rim DEM byte-range fixture",
    "lola-gdr-byte-range-dem-fixture",
    first_trusted_square_lola_extraction_candidate(),
    "inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521",
    "LRO LOLA GDR product ldem_875s_20m_float, extracted from official PDS Geosciences byte ranges for Moonmoon software proof.",
    [
      "Elevation values are measured LOLA DEM samples converted from kilometers to meters relative to the 1737.4 km reference radius.",
      "Do not use this dataset for mission-grade traverse planning without independent geospatial review.",
    ],
  )
}

///|
pub fn first_trusted_square_west_contour_lola_terrain_dataset_record() -> LunarTerrainDatasetRecord {
  lola_terrain_dataset(
    "lro-lola-first-trusted-square-west-contour-dem-v1",
    "LOLA west-contour route-window DEM byte-range fixture",
    "lola-gdr-byte-range-route-window-dem-fixture",
    first_trusted_square_west_contour_lola_extraction_candidate(),
    "inline-grid-v1:tile=first-trusted-square-west-contour-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=544.454:last=492.629",
    "LRO LOLA GDR product ldem_875s_20m_float, west-adjacent byte-range extraction for Moonmoon route evidence.",
    [
      "This is measured local terrain evidence for a route alternative, not proof that the route is safe.",
      "The adjacent window remains a tiny software-proof sample and must be expanded before traverse planning.",
    ],
  )
}

///|
pub fn first_trusted_square_north_rim_lola_terrain_dataset_record() -> LunarTerrainDatasetRecord {
  lola_terrain_dataset(
    "lro-lola-first-trusted-square-north-rim-dem-v1",
    "LOLA north-rim route-window DEM byte-range fixture",
    "lola-gdr-byte-range-route-window-dem-fixture",
    first_trusted_square_north_rim_lola_extraction_candidate(),
    "inline-grid-v1:tile=first-trusted-square-north-rim-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=506.517:last=460.176",
    "LRO LOLA GDR product ldem_875s_20m_float, north-adjacent byte-range extraction for Moonmoon route evidence.",
    [
      "This is measured local terrain evidence for a route alternative, not proof that the route is safe.",
      "Illumination and a wider corridor search are still required before traverse planning.",
    ],
  )
}

///|
pub fn first_trusted_square_southwest_bypass_lola_terrain_dataset_record() -> LunarTerrainDatasetRecord {
  lola_terrain_dataset(
    "lro-lola-first-trusted-square-southwest-bypass-dem-v1",
    "LOLA southwest-bypass corridor DEM byte-range fixture",
    "lola-gdr-byte-range-corridor-dem-fixture",
    first_trusted_square_southwest_bypass_lola_extraction_candidate(),
    "inline-grid-v1:tile=first-trusted-square-southwest-bypass-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=548.224:last=505.456",
    "LRO LOLA GDR product ldem_875s_20m_float, southwest widened corridor byte-range extraction for Moonmoon route evidence.",
    [
      "This is measured local terrain evidence from the first widened corridor scan, not proof that the route is safe.",
      "The window is the best sampled local grade among the first 5x5 scan but remains blocked by conservative rover limits.",
    ],
  )
}

///|
pub fn first_trusted_square_south_stepout_lola_terrain_dataset_record() -> LunarTerrainDatasetRecord {
  lola_terrain_dataset(
    "lro-lola-first-trusted-square-south-stepout-dem-v1",
    "LOLA south-stepout corridor DEM byte-range fixture",
    "lola-gdr-byte-range-corridor-dem-fixture",
    first_trusted_square_south_stepout_lola_extraction_candidate(),
    "inline-grid-v1:tile=first-trusted-square-south-stepout-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=453.571:last=409.003",
    "LRO LOLA GDR product ldem_875s_20m_float, south widened corridor byte-range extraction for Moonmoon route evidence.",
    [
      "This is measured local terrain evidence from the first widened corridor scan, not proof that the route is safe.",
      "The window is smoother than the active patch but remains blocked by conservative rover limits.",
    ],
  )
}

///|
pub fn first_trusted_square_northeast_stepout_lola_terrain_dataset_record() -> LunarTerrainDatasetRecord {
  lola_terrain_dataset(
    "lro-lola-first-trusted-square-northeast-stepout-dem-v1",
    "LOLA northeast-stepout 9x9 corridor DEM byte-range fixture",
    "lola-gdr-byte-range-corridor-dem-fixture",
    first_trusted_square_northeast_stepout_lola_extraction_candidate(),
    "inline-grid-v1:tile=first-trusted-square-northeast-stepout-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=341.536:last=305.726",
    "LRO LOLA GDR product ldem_875s_20m_float, northeast 9x9 corridor byte-range extraction for Moonmoon route evidence.",
    [
      "This is measured local terrain evidence for the best ranked window in the active 9x9 scan, not proof that the route is safe.",
      "The selected route remains blocked until terrain review, wider sampling, and time-windowed power evidence improve.",
    ],
  )
}

///|
pub fn first_trusted_square_route_lola_terrain_dataset_records() -> Array[
  LunarTerrainDatasetRecord,
] {
  [
    first_trusted_square_west_contour_lola_terrain_dataset_record(),
    first_trusted_square_north_rim_lola_terrain_dataset_record(),
    first_trusted_square_southwest_bypass_lola_terrain_dataset_record(),
    first_trusted_square_south_stepout_lola_terrain_dataset_record(),
    first_trusted_square_northeast_stepout_lola_terrain_dataset_record(),
  ]
}

///|
fn data_ref_for_lola_terrain(
  record : LunarTerrainDatasetRecord,
) -> @data_core.DataRef {
  @data_core.data_ref(
    record.extraction.tile_id + "-csv",
    "lunar-dem-csv",
    @data_core.data_uri(
      record.extraction.output_path[5:record.extraction.output_path.length()].to_owned(),
    ),
    content_type="text/csv",
    byte_count=record.extraction.output_bytes,
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::Sha256,
      record.extraction.output_sha256,
    ),
  )
}

///|
pub fn lola_terrain_dataset_manifest(
  record : LunarTerrainDatasetRecord,
) -> @data_core.DatasetManifest {
  let source = first_trusted_square_lola_source()
  @data_core.dataset_manifest(
    record.dataset_id,
    "lunar-terrain-dem",
    @data_core.DataStatus::Verified,
    0L,
    source_ids=[source.source_id],
    data_refs=[data_ref_for_lola_terrain(record)],
    summary=record.title,
  )
}

///|
pub fn first_trusted_square_route_lola_datasets() -> Array[
  @data_core.DatasetManifest,
] {
  first_trusted_square_route_lola_terrain_dataset_records().map(fn(record) {
    lola_terrain_dataset_manifest(record)
  })
}
