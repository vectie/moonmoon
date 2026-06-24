///|
pub(all) enum DatasetTrust {
  Authoritative
  CuratedFixture
  DerivedProduct
  Experimental
  UnknownTrust
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ReviewStatus {
  AcceptedForSoftwareProof
  NeedsSourceUpgrade
  NeedsHumanReview
  Rejected
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ChecksumKind {
  InlineFixtureFingerprint
  Sha256
  UnknownChecksumKind
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum DatasetValidationStatus {
  Verified
  ChecksumMismatch
  MissingChecksum
  UnsupportedChecksum
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DatasetValidation {
  dataset_id : @core.DatasetId
  checksum_kind : ChecksumKind
  expected_checksum : String
  actual_checksum : String
  status : DatasetValidationStatus
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DatasetManifest {
  dataset_id : @core.DatasetId
  title : String
  source_url : String
  license : String
  product_type : String
  trust : DatasetTrust
  claim_kind : @core.ClaimKind
  coverage : @core.LunarBounds
  resolution_m : Double
  source_path : String
  source_sha256 : String
  extractor : String
  checksum_kind : ChecksumKind
  checksum : String
  citation : String
  review_status : ReviewStatus
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn trust_label(trust : DatasetTrust) -> String {
  match trust {
    Authoritative => "authoritative"
    CuratedFixture => "curated-fixture"
    DerivedProduct => "derived-product"
    Experimental => "experimental"
    UnknownTrust => "unknown"
  }
}

///|
pub fn review_status_label(status : ReviewStatus) -> String {
  match status {
    AcceptedForSoftwareProof => "accepted-for-software-proof"
    NeedsSourceUpgrade => "needs-source-upgrade"
    NeedsHumanReview => "needs-human-review"
    Rejected => "rejected"
  }
}

///|
pub fn checksum_kind_label(kind : ChecksumKind) -> String {
  match kind {
    InlineFixtureFingerprint => "inline-fixture-fingerprint"
    Sha256 => "sha256"
    UnknownChecksumKind => "unknown"
  }
}

///|
pub fn validation_status_label(status : DatasetValidationStatus) -> String {
  match status {
    Verified => "verified"
    ChecksumMismatch => "checksum-mismatch"
    MissingChecksum => "missing-checksum"
    UnsupportedChecksum => "unsupported-checksum"
  }
}

///|
pub fn verify_checksum(
  manifest : DatasetManifest,
  actual_checksum : String,
) -> DatasetValidation {
  let status = if manifest.checksum_kind == UnknownChecksumKind {
    UnsupportedChecksum
  } else if manifest.checksum == "" {
    MissingChecksum
  } else if actual_checksum == "" {
    MissingChecksum
  } else if manifest.checksum == actual_checksum {
    Verified
  } else {
    ChecksumMismatch
  }
  {
    dataset_id: manifest.dataset_id,
    checksum_kind: manifest.checksum_kind,
    expected_checksum: manifest.checksum,
    actual_checksum,
    status,
    note: match status {
      Verified => "source fingerprint matches manifest"
      ChecksumMismatch => "source fingerprint differs from manifest"
      MissingChecksum => "manifest or source fingerprint is missing"
      UnsupportedChecksum => "checksum kind is not supported by this verifier"
    },
  }
}

///|
pub fn to_provenance(manifest : DatasetManifest) -> @core.Provenance {
  {
    dataset_id: manifest.dataset_id,
    source_title: manifest.title,
    source_url: manifest.source_url,
    license: manifest.license,
    product_type: manifest.product_type,
    claim_kind: manifest.claim_kind,
    generated_by: "source-manifest",
  }
}

///|
pub fn first_trusted_square_manifest() -> DatasetManifest {
  {
    dataset_id: "fixture-first-trusted-square-dem-v1",
    title: "Synthetic Shackleton Rim DEM fixture",
    source_url: "repo://fixtures/first-trusted-square",
    license: "Apache-2.0",
    product_type: "tiny-dem-fixture",
    trust: CuratedFixture,
    claim_kind: @core.ClaimKind::Simulated,
    coverage: {
      south_deg: -89.90,
      north_deg: -89.86,
      west_deg: 0.10,
      east_deg: 0.14,
    },
    resolution_m: 10.0,
    source_path: "data/fixtures/first_trusted_square_dem.csv",
    source_sha256: "45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7",
    extractor: "scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: "inline-grid-v1:tile=first-trusted-square:rows=4:cols=4:cell-size-m=10:cells=16:first=0:last=5.4",
    citation: "Moonmoon repository fixture for software proof only.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Synthetic elevation values are intentionally small and deterministic.", "This manifest proves the evidence contract before an authoritative LOLA/LROC fixture lands.",
      "Do not use this dataset for mission-grade traverse planning.",
    ],
  }
}
