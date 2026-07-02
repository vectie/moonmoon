///|
pub(all) enum TerrainSourceTrust {
  Authoritative
  CuratedFixture
  DerivedProduct
  Experimental
  UnknownTrust
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum TerrainSourceReviewStatus {
  AcceptedForSoftwareProof
  NeedsSourceUpgrade
  NeedsHumanReview
  Rejected
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum TerrainSourceChecksumKind {
  InlineFixtureFingerprint
  Sha256
  UnknownChecksumKind
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TerrainSourceManifest {
  dataset_id : @core.DatasetId
  title : String
  source_url : String
  license : String
  product_type : String
  trust : TerrainSourceTrust
  claim_kind : @core.ClaimKind
  coverage : @core.LunarBounds
  resolution_m : Double
  source_path : String
  source_sha256 : String
  extractor : String
  checksum_kind : TerrainSourceChecksumKind
  checksum : String
  citation : String
  review_status : TerrainSourceReviewStatus
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn review_status_from_lunar(
  status : @lunar_data.LunarReviewStatus,
) -> TerrainSourceReviewStatus {
  match status {
    @lunar_data.LunarReviewStatus::AcceptedForSoftwareProof =>
      AcceptedForSoftwareProof
    @lunar_data.LunarReviewStatus::NeedsSourceUpgrade => NeedsSourceUpgrade
    @lunar_data.LunarReviewStatus::NeedsHumanReview => NeedsHumanReview
    @lunar_data.LunarReviewStatus::Rejected => Rejected
  }
}

///|
fn claim_kind_from_lunar(label : String) -> @core.ClaimKind {
  match label {
    "measured" => @core.ClaimKind::Measured
    "derived" => @core.ClaimKind::Derived
    "simulated" => @core.ClaimKind::Simulated
    "assumed" => @core.ClaimKind::Assumed
    _ => @core.ClaimKind::Unknown
  }
}

///|
fn terrain_source_manifest_from_lunar(
  record : @lunar_data.LunarTerrainDatasetRecord,
) -> TerrainSourceManifest {
  let source = @lunar_data.first_trusted_square_lola_source()
  let product = @lunar_data.first_trusted_square_lola_product_selection()
  let extraction = record.extraction
  {
    dataset_id: record.dataset_id,
    title: record.title,
    source_url: product.image_url,
    license: source.license,
    product_type: record.product_type,
    trust: Authoritative,
    claim_kind: claim_kind_from_lunar(extraction.claim_kind),
    coverage: {
      south_deg: extraction.coverage.south_deg,
      north_deg: extraction.coverage.north_deg,
      west_deg: extraction.coverage.west_deg,
      east_deg: extraction.coverage.east_deg,
    },
    resolution_m: extraction.coverage.resolution_m,
    source_path: extraction.output_path,
    source_sha256: extraction.output_sha256,
    extractor: "MoonBit source extraction -> \{extraction.output_path} -> MoonBit fixture generator -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: record.inline_fingerprint,
    citation: record.citation,
    review_status: review_status_from_lunar(extraction.review_status),
    notes: record.notes,
  }
}

///|
pub fn terrain_source_trust_label(trust : TerrainSourceTrust) -> String {
  match trust {
    Authoritative => "authoritative"
    CuratedFixture => "curated-fixture"
    DerivedProduct => "derived-product"
    Experimental => "experimental"
    UnknownTrust => "unknown"
  }
}

///|
pub fn terrain_source_review_status_label(
  status : TerrainSourceReviewStatus,
) -> String {
  match status {
    AcceptedForSoftwareProof => "accepted-for-software-proof"
    NeedsSourceUpgrade => "needs-source-upgrade"
    NeedsHumanReview => "needs-human-review"
    Rejected => "rejected"
  }
}

///|
pub fn terrain_source_checksum_kind_label(
  kind : TerrainSourceChecksumKind,
) -> String {
  match kind {
    InlineFixtureFingerprint => "inline-fixture-fingerprint"
    Sha256 => "sha256"
    UnknownChecksumKind => "unknown"
  }
}

///|
pub fn terrain_source_provenance(
  manifest : TerrainSourceManifest,
) -> @core.Provenance {
  {
    dataset_id: manifest.dataset_id,
    source_title: manifest.title,
    source_url: manifest.source_url,
    license: manifest.license,
    product_type: manifest.product_type,
    claim_kind: manifest.claim_kind,
    generated_by: "terrain-source-manifest",
  }
}

///|
pub fn first_trusted_square_source_manifest() -> TerrainSourceManifest {
  terrain_source_manifest_from_lunar(
    @lunar_data.first_trusted_square_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_west_contour_source_manifest() -> TerrainSourceManifest {
  terrain_source_manifest_from_lunar(
    @lunar_data.first_trusted_square_west_contour_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_north_rim_source_manifest() -> TerrainSourceManifest {
  terrain_source_manifest_from_lunar(
    @lunar_data.first_trusted_square_north_rim_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_southwest_bypass_source_manifest() -> TerrainSourceManifest {
  terrain_source_manifest_from_lunar(
    @lunar_data.first_trusted_square_southwest_bypass_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_south_stepout_source_manifest() -> TerrainSourceManifest {
  terrain_source_manifest_from_lunar(
    @lunar_data.first_trusted_square_south_stepout_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_northeast_stepout_source_manifest() -> TerrainSourceManifest {
  terrain_source_manifest_from_lunar(
    @lunar_data.first_trusted_square_northeast_stepout_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_route_source_manifests() -> Array[
  TerrainSourceManifest,
] {
  [
    first_trusted_square_west_contour_source_manifest(),
    first_trusted_square_north_rim_source_manifest(),
    first_trusted_square_southwest_bypass_source_manifest(),
    first_trusted_square_south_stepout_source_manifest(),
    first_trusted_square_northeast_stepout_source_manifest(),
  ]
}
