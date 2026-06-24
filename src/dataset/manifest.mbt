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
pub(all) struct SourceCandidate {
  candidate_id : String
  title : String
  body : String
  mission : String
  instrument : String
  product_family : String
  official_source_url : String
  access_url : String
  local_target_path : String
  intended_use : String
  next_action : String
  review_status : ReviewStatus
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SourceAcquisitionStep {
  step_id : String
  title : String
  action : String
  expected_evidence : String
  done_when : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SourceAcquisitionPlan {
  plan_id : String
  candidate_id : String
  product_family_id : String
  source_family_url : String
  source_metadata_url : String
  source_metadata_sha256 : String
  source_metadata_bytes : Int
  discovery_url : String
  target_region : String
  expected_format : String
  local_source_directory : String
  local_metadata_path : String
  extracted_fixture_path : String
  trust_gate : String
  steps : Array[SourceAcquisitionStep]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SourceProductSelection {
  selection_id : String
  plan_id : String
  product_id : String
  product_lid : String
  image_url : String
  label_url : String
  local_label_path : String
  label_sha256 : String
  label_bytes : Int
  image_bytes : Int
  projection : String
  resolution_m : Double
  west_deg : Double
  east_deg : Double
  south_deg : Double
  north_deg : Double
  lines : Int
  samples : Int
  data_type : String
  unit : String
  value_offset_km : Double
  selection_reason : String
  extraction_risk : String
  review_status : ReviewStatus
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
pub fn source_candidate_status_label(candidate : SourceCandidate) -> String {
  review_status_label(candidate.review_status)
}

///|
pub fn acquisition_plan_progress_label(plan : SourceAcquisitionPlan) -> String {
  "planned:\{plan.steps.length()}-steps"
}

///|
pub fn product_selection_status_label(
  selection : SourceProductSelection,
) -> String {
  review_status_label(selection.review_status)
}

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
pub fn first_trusted_square_lola_candidate() -> SourceCandidate {
  {
    candidate_id: "candidate-lro-lola-sldem-first-trusted-square",
    title: "LRO LOLA derived gridded topography candidate",
    body: "Moon",
    mission: "Lunar Reconnaissance Orbiter",
    instrument: "LOLA",
    product_family: "GDR/SLDEM derived gridded terrain",
    official_source_url: "https://pds-geosciences.wustl.edu/missions/lro/lola.htm",
    access_url: "https://ode.rsl.wustl.edu/moon/",
    local_target_path: "data/sources/lro_lola/first_trusted_square_dem.csv",
    intended_use: "Replace the synthetic trusted-square DEM with a tiny authoritative lunar south-pole terrain extraction.",
    next_action: "Select a specific LOLA/SLDEM product, record its source URL and SHA-256, then regenerate the trusted-square fixture.",
    review_status: NeedsSourceUpgrade,
    notes: [
      "PDS Geosciences identifies LOLA as the LRO Lunar Orbiter Laser Altimeter for high-resolution lunar topography.",
      "The PDS page lists derived GDR and SLDEM product families and points recent LOLA data discovery to ODE/LOLA Data Node.",
      "This candidate is not yet ingested; the active trusted-square dataset remains synthetic until a local source file is verified.",
    ],
  }
}

///|
pub fn first_trusted_square_lola_acquisition_plan() -> SourceAcquisitionPlan {
  {
    plan_id: "acquire-lro-lola-gdr-south-pole-20m-v1",
    candidate_id: "candidate-lro-lola-sldem-first-trusted-square",
    product_family_id: "lro-lola-gdr-south-pole-selection",
    source_family_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/",
    source_metadata_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat",
    source_metadata_sha256: "f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8",
    source_metadata_bytes: 5672,
    discovery_url: "https://ode.rsl.wustl.edu/moon/",
    target_region: "Shackleton rim rehearsal tile near 89.88S, 0.12E",
    expected_format: "PDS LOLA GDR south-polar gridded elevation product selected through ODE/PDS metadata",
    local_source_directory: "data/sources/lro_lola/",
    local_metadata_path: "data/sources/lro_lola/gdr_ds.cat",
    extracted_fixture_path: "data/sources/lro_lola/first_trusted_square_dem.csv",
    trust_gate: "Do not replace the synthetic fixture until product family URL, metadata URL, selected product URL, SHA-256, extraction window, and generated CSV checksum are recorded.",
    steps: [
      {
        step_id: "discover",
        title: "Confirm product family",
        action: "Use the PDS LOLA page and Lunar ODE to confirm the south-polar GDR float product is the right first authoritative terrain source.",
        expected_evidence: "Official PDS page URL, ODE discovery URL, GDR family URL, and GDR catalog URL.",
        done_when: "The source candidate points to a named product family and the acquisition plan names a reachable PDS family root.",
      },
      {
        step_id: "metadata",
        title: "Fetch metadata first",
        action: "Download the GDR catalog before any large image and record the selected product route, projection assumptions, units, byte order, and map scale.",
        expected_evidence: "A local GDR catalog file with SHA-256 recorded in the authoritative dataset manifest draft.",
        done_when: "The extractor can derive pixel coordinates for the trusted-square bounds without reading the full image into memory.",
      },
      {
        step_id: "extract",
        title: "Extract tiny tile",
        action: "Read only the needed south-pole window from the float image and emit a compact CSV for the first trusted square.",
        expected_evidence: "A small CSV under data/sources/lro_lola with source product id, bounds, resolution, and SHA-256.",
        done_when: "scripts/generate_moonmoon_fixture.py can regenerate MoonBit terrain from the authoritative CSV.",
      },
      {
        step_id: "validate",
        title: "Verify evidence chain",
        action: "Check raw label checksum, raw image checksum when available, extracted CSV checksum, and generated inline grid fingerprint.",
        expected_evidence: "A passing source verification script and a DatasetValidation with status verified.",
        done_when: "moon test passes while the dossier marks the authoritative dataset as accepted for software proof.",
      },
      {
        step_id: "review",
        title: "Human review before mission claims",
        action: "Review projection math, elevation units, polar singularity handling, and traverse thresholds before raising claim kind beyond derived software evidence.",
        expected_evidence: "MoonBook review notes tied to the dataset, terrain metrics, and traverse decision.",
        done_when: "The review queue no longer contains the source-upgrade blocker for this site.",
      },
    ],
  }
}

///|
pub fn first_trusted_square_source_candidates() -> Array[SourceCandidate] {
  [first_trusted_square_lola_candidate()]
}

///|
pub fn first_trusted_square_source_acquisition_plans() -> Array[
  SourceAcquisitionPlan,
] {
  [first_trusted_square_lola_acquisition_plan()]
}

///|
pub fn first_trusted_square_lola_product_selection() -> SourceProductSelection {
  {
    selection_id: "select-ldem-875s-20m-float-v1",
    plan_id: "acquire-lro-lola-gdr-south-pole-20m-v1",
    product_id: "ldem_875s_20m_float",
    product_lid: "urn:nasa:pds:lro_lola_rdr:data_gridded:ldem_875s_20m_float",
    image_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    label_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.xml",
    local_label_path: "data/sources/lro_lola/ldem_875s_20m_float.xml",
    label_sha256: "10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53",
    label_bytes: 11629,
    image_bytes: 230068224,
    projection: "Polar Stereographic",
    resolution_m: 20.0,
    west_deg: 0.0,
    east_deg: 360.0,
    south_deg: -90.0,
    north_deg: -87.5,
    lines: 7584,
    samples: 7584,
    data_type: "IEEE754LSBSingle",
    unit: "KILOMETER",
    value_offset_km: 1737.4,
    selection_reason: "Covers the first trusted square near 89.88S with south-polar 20 m/pixel LOLA DEM data and has a small pinned XML label for extractor development.",
    extraction_risk: "The image is about 230 MB and should be window-read from the float raster after projection math is tested; do not commit the raw image.",
    review_status: NeedsHumanReview,
  }
}

///|
pub fn first_trusted_square_source_product_selections() -> Array[
  SourceProductSelection,
] {
  [first_trusted_square_lola_product_selection()]
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
