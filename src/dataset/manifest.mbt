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
pub(all) struct SourceExtractionCandidate {
  extraction_id : String
  selection_id : String
  generated_by : String
  output_path : String
  output_sha256 : String
  output_bytes : Int
  tile_id : String
  center_lat_deg : Double
  center_lon_deg : Double
  source_row_start : Int
  source_col_start : Int
  rows : Int
  cols : Int
  cell_size_m : Double
  elevation_unit : String
  claim_kind : @core.ClaimKind
  review_status : ReviewStatus
  notes : Array[String]
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
  "recorded:\{plan.steps.length()}-steps"
}

///|
pub fn product_selection_status_label(
  selection : SourceProductSelection,
) -> String {
  review_status_label(selection.review_status)
}

///|
pub fn extraction_candidate_status_label(
  extraction : SourceExtractionCandidate,
) -> String {
  review_status_label(extraction.review_status)
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
    local_target_path: "data/sources/lro_lola/first_trusted_square_dem.csv plus adjacent route-window CSVs",
    intended_use: "Replace the synthetic trusted-square DEM with a tiny authoritative lunar south-pole terrain extraction.",
    next_action: "Use the checked LOLA byte-range fixtures for software proof, then add illumination and wider corridor search before any rover claim.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "PDS Geosciences identifies LOLA as the LRO Lunar Orbiter Laser Altimeter for high-resolution lunar topography.",
      "The PDS page lists derived GDR and SLDEM product families and points recent LOLA data discovery to ODE/LOLA Data Node.",
      "The first trusted-square active fixture now uses a checked LOLA GDR byte-range extraction for software proof.",
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
    extracted_fixture_path: "data/sources/lro_lola/first_trusted_square_dem.csv and adjacent route-window CSVs",
    trust_gate: "The active software-proof fixtures must keep product family URL, metadata URL, selected product URL, SHA-256, extraction windows, and generated CSV checksums recorded.",
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
        done_when: "scripts/generate_moonmoon_fixture.py regenerates MoonBit terrain from the authoritative CSV.",
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
        done_when: "The source-upgrade blocker is closed and remaining review focuses on terrain hazards, illumination, and route alternatives.",
      },
    ],
  }
}

///|
pub fn first_trusted_square_ephemeris_candidate() -> SourceCandidate {
  {
    candidate_id: "candidate-lunar-solar-ephemeris-first-trusted-square",
    title: "Lunar solar ephemeris power-window candidate",
    body: "Moon",
    mission: "NASA NAIF SPICE / planetary ephemeris",
    instrument: "SPICE kernels",
    product_family: "Sun/Moon ephemeris and lunar orientation kernels",
    official_source_url: "https://naif.jpl.nasa.gov/naif/data.html",
    access_url: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/",
    local_target_path: "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
    intended_use: "Attach time-windowed Sun/Moon geometry, local sunlit hours, and rover power-window evidence to the first trusted square.",
    next_action: "Select pinned SPICE kernels or an equivalent official illumination source, record checksums, and generate the MoonBit power-window module before clearing the energy gate.",
    review_status: NeedsSourceUpgrade,
    notes: [
      "The current illumination and energy gates deliberately block because only relief-shadow proxies exist.",
      "A real power gate needs a time-bounded Sun/Moon geometry source plus local horizon assumptions.",
      "This candidate turns the missing ephemeris evidence from prose into a typed MoonBook-visible source contract.",
    ],
  }
}

///|
pub fn first_trusted_square_ephemeris_acquisition_plan() -> SourceAcquisitionPlan {
  {
    plan_id: "acquire-lunar-solar-ephemeris-first-trusted-square-v1",
    candidate_id: "candidate-lunar-solar-ephemeris-first-trusted-square",
    product_family_id: "lunar-solar-ephemeris-power-window",
    source_family_url: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/",
    source_metadata_url: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/",
    source_metadata_sha256: "",
    source_metadata_bytes: 0,
    discovery_url: "https://naif.jpl.nasa.gov/naif/data.html",
    target_region: "First Trusted Square near Shackleton rim, 89.88S, 0.12E",
    expected_format: "Pinned ephemeris/orientation source plus generated JSON power-window evidence",
    local_source_directory: "data/sources/lunar_ephemeris/",
    local_metadata_path: "data/sources/lunar_ephemeris/README.md",
    extracted_fixture_path: "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
    trust_gate: "Must cite official ephemeris/illumination source, pin source checksums, compute sunlit/dark hours, and regenerate src/mission/generated_first_trusted_square_power_window.mbt before energy can move out of block.",
    steps: [
      {
        step_id: "discover-source",
        title: "Select official ephemeris source",
        action: "Choose NAIF SPICE kernels or an equivalent official illumination product that can support Sun/Moon geometry for the south-pole tile.",
        expected_evidence: "Source family URL, kernel/product names, access URL, and license/usage notes recorded in MoonBook.",
        done_when: "The candidate names a concrete official source instead of a generic power assumption.",
      },
      {
        step_id: "pin-kernels",
        title: "Pin checksummed inputs",
        action: "Record exact kernel or illumination product files, byte counts, SHA-256 checksums, and local paths under data/sources/lunar_ephemeris.",
        expected_evidence: "A README plus source metadata checksum fields that make reruns deterministic.",
        done_when: "scripts/verify_moonmoon_sources.sh can reject missing or changed ephemeris inputs.",
      },
      {
        step_id: "compute-local-window",
        title: "Compute local power window",
        action: "Evaluate the first trusted square over a declared time span and emit sunlit hours, dark survival hours, incidence notes, and confidence.",
        expected_evidence: "A generated JSON fixture at data/sources/lunar_ephemeris/first_trusted_square_power_window.json.",
        done_when: "The JSON records time range, source checksums, local coordinate, sunlit hours, dark hours, and uncertainty.",
      },
      {
        step_id: "generate-moonbit-window",
        title: "Generate MoonBit evidence",
        action: "Mirror the checked JSON into src/mission/generated_first_trusted_square_power_window.mbt for deterministic mission tests.",
        expected_evidence: "Generated MoonBit power-window module and tests tied to the JSON checksum.",
        done_when: "moon test proves the mission energy gate reads generated ephemeris evidence instead of hard-coded zero Wh.",
      },
      {
        step_id: "review-energy-gate",
        title: "Review before unblocking Moonrobo",
        action: "Have MoonBook record reviewer acceptance that the ephemeris source, local horizon assumptions, and rover power model are coherent.",
        expected_evidence: "A review transition moving the ephemeris source candidate and energy-window item out of needs-evidence.",
        done_when: "Moonrobo handoff remains blocked or becomes reviewable based on measured terrain plus accepted time-windowed power evidence.",
      },
    ],
  }
}

///|
pub fn first_trusted_square_source_candidates() -> Array[SourceCandidate] {
  [
    first_trusted_square_lola_candidate(),
    first_trusted_square_ephemeris_candidate(),
  ]
}

///|
pub fn first_trusted_square_source_acquisition_plans() -> Array[
  SourceAcquisitionPlan,
] {
  [
    first_trusted_square_lola_acquisition_plan(),
    first_trusted_square_ephemeris_acquisition_plan(),
  ]
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
    review_status: AcceptedForSoftwareProof,
  }
}

///|
pub fn first_trusted_square_source_product_selections() -> Array[
  SourceProductSelection,
] {
  [first_trusted_square_lola_product_selection()]
}

///|
pub fn first_trusted_square_lola_extraction_candidate() -> SourceExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-first-trusted-square-v1",
    selection_id: "select-ldem-875s-20m-float-v1",
    generated_by: "scripts/extract_lola_trusted_square.py",
    output_path: "data/sources/lro_lola/first_trusted_square_dem.csv",
    output_sha256: "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
    output_bytes: 636,
    tile_id: "first-trusted-square-lola",
    center_lat_deg: -89.88,
    center_lon_deg: 0.12,
    source_row_start: 3972,
    source_col_start: 3790,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    elevation_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: @core.ClaimKind::Measured,
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from HTTP byte ranges against ldem_875s_20m_float.img, not from a committed raw image.",
      "This extraction is the active Moonmoon trusted-square fixture for software proof.",
      "The output CSV keeps the small Moonmoon fixture shape while replacing synthetic values with measured LOLA DEM values.",
    ],
  }
}

///|
pub fn first_trusted_square_west_contour_lola_extraction_candidate() -> SourceExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-west-contour-v1",
    selection_id: "select-ldem-875s-20m-float-v1",
    generated_by: "scripts/extract_lola_trusted_square.py",
    output_path: "data/sources/lro_lola/first_trusted_square_west_contour_dem.csv",
    output_sha256: "1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6",
    output_bytes: 844,
    tile_id: "first-trusted-square-west-contour-lola",
    center_lat_deg: -89.88,
    center_lon_deg: 0.08,
    source_row_start: 3972,
    source_col_start: 3786,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    elevation_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: @core.ClaimKind::Measured,
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the west-adjacent HTTP byte ranges next to the active trusted-square window.",
      "This window gives the west-contour route candidate measured terrain evidence rather than a hand-authored estimate.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_north_rim_lola_extraction_candidate() -> SourceExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-north-rim-v1",
    selection_id: "select-ldem-875s-20m-float-v1",
    generated_by: "scripts/extract_lola_trusted_square.py",
    output_path: "data/sources/lro_lola/first_trusted_square_north_rim_dem.csv",
    output_sha256: "40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28",
    output_bytes: 796,
    tile_id: "first-trusted-square-north-rim-lola",
    center_lat_deg: -89.86,
    center_lon_deg: 0.12,
    source_row_start: 3968,
    source_col_start: 3790,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    elevation_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: @core.ClaimKind::Measured,
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the north-adjacent HTTP byte ranges next to the active trusted-square window.",
      "This window gives the north-rim route candidate measured terrain evidence before illumination analysis exists.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_southwest_bypass_lola_extraction_candidate() -> SourceExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-southwest-bypass-v1",
    selection_id: "select-ldem-875s-20m-float-v1",
    generated_by: "scripts/extract_lola_trusted_square.py",
    output_path: "data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv",
    output_sha256: "c47b837a8ed5bb818c865782396d44dae01b15b03a2a6a83c372548092c1ace5",
    output_bytes: 908,
    tile_id: "first-trusted-square-southwest-bypass-lola",
    center_lat_deg: -89.90,
    center_lon_deg: 0.04,
    source_row_start: 3980,
    source_col_start: 3782,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    elevation_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: @core.ClaimKind::Measured,
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the wider southwest HTTP byte ranges after the first adjacent west/north windows remained blocked.",
      "This is the lowest-grade window in the first 5x5 corridor scan, but still exceeds the conservative rover traverse limits.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_south_stepout_lola_extraction_candidate() -> SourceExtractionCandidate {
  {
    extraction_id: "extract-ldem-875s-20m-south-stepout-v1",
    selection_id: "select-ldem-875s-20m-float-v1",
    generated_by: "scripts/extract_lola_trusted_square.py",
    output_path: "data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv",
    output_sha256: "dde783fcf74ac0567bb2d6bb8eead6c2f83b620603319690aa51011486d7a19c",
    output_bytes: 860,
    tile_id: "first-trusted-square-south-stepout-lola",
    center_lat_deg: -89.90,
    center_lon_deg: 0.12,
    source_row_start: 3980,
    source_col_start: 3790,
    rows: 4,
    cols: 4,
    cell_size_m: 20.0,
    elevation_unit: "meters relative to 1737.4 km reference radius",
    claim_kind: @core.ClaimKind::Measured,
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Generated from the wider south HTTP byte ranges after the first adjacent west/north windows remained blocked.",
      "This window is smoother than the active patch but still exceeds conservative rover traverse limits.",
      "The local window is still too small for mission-grade corridor planning.",
    ],
  }
}

///|
pub fn first_trusted_square_source_extraction_candidates() -> Array[
  SourceExtractionCandidate,
] {
  [
    first_trusted_square_lola_extraction_candidate(),
    first_trusted_square_west_contour_lola_extraction_candidate(),
    first_trusted_square_north_rim_lola_extraction_candidate(),
    first_trusted_square_southwest_bypass_lola_extraction_candidate(),
    first_trusted_square_south_stepout_lola_extraction_candidate(),
  ]
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
    dataset_id: "lro-lola-first-trusted-square-dem-v1",
    title: "LOLA Shackleton Rim DEM byte-range fixture",
    source_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    license: "Apache-2.0",
    product_type: "lola-gdr-byte-range-dem-fixture",
    trust: Authoritative,
    claim_kind: @core.ClaimKind::Measured,
    coverage: {
      south_deg: -89.90,
      north_deg: -89.86,
      west_deg: 0.10,
      east_deg: 0.14,
    },
    resolution_m: 20.0,
    source_path: "data/sources/lro_lola/first_trusted_square_dem.csv",
    source_sha256: "7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c",
    extractor: "scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: "inline-grid-v1:tile=first-trusted-square-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=499.693:last=441.521",
    citation: "LRO LOLA GDR product ldem_875s_20m_float, extracted from official PDS Geosciences byte ranges for Moonmoon software proof.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "Elevation values are measured LOLA DEM samples converted from kilometers to meters relative to the 1737.4 km reference radius.",
      "The raw 230 MB IMG is not committed; the tiny CSV is reproducibly extracted from HTTP byte ranges.",
      "Do not use this dataset for mission-grade traverse planning without independent geospatial review.",
    ],
  }
}

///|
pub fn first_trusted_square_west_contour_manifest() -> DatasetManifest {
  {
    dataset_id: "lro-lola-first-trusted-square-west-contour-dem-v1",
    title: "LOLA west-contour route-window DEM byte-range fixture",
    source_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    license: "Apache-2.0",
    product_type: "lola-gdr-byte-range-route-window-dem-fixture",
    trust: Authoritative,
    claim_kind: @core.ClaimKind::Measured,
    coverage: {
      south_deg: -89.90,
      north_deg: -89.86,
      west_deg: 0.06,
      east_deg: 0.10,
    },
    resolution_m: 20.0,
    source_path: "data/sources/lro_lola/first_trusted_square_west_contour_dem.csv",
    source_sha256: "1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6",
    extractor: "scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_west_contour_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: "inline-grid-v1:tile=first-trusted-square-west-contour-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=544.454:last=492.629",
    citation: "LRO LOLA GDR product ldem_875s_20m_float, west-adjacent byte-range extraction for Moonmoon route evidence.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "This is measured local terrain evidence for a route alternative, not proof that the route is safe.",
      "The adjacent window remains a tiny software-proof sample and must be expanded before robot planning.",
    ],
  }
}

///|
pub fn first_trusted_square_north_rim_manifest() -> DatasetManifest {
  {
    dataset_id: "lro-lola-first-trusted-square-north-rim-dem-v1",
    title: "LOLA north-rim route-window DEM byte-range fixture",
    source_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    license: "Apache-2.0",
    product_type: "lola-gdr-byte-range-route-window-dem-fixture",
    trust: Authoritative,
    claim_kind: @core.ClaimKind::Measured,
    coverage: {
      south_deg: -89.86,
      north_deg: -89.82,
      west_deg: 0.10,
      east_deg: 0.14,
    },
    resolution_m: 20.0,
    source_path: "data/sources/lro_lola/first_trusted_square_north_rim_dem.csv",
    source_sha256: "40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28",
    extractor: "scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_north_rim_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: "inline-grid-v1:tile=first-trusted-square-north-rim-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=506.517:last=460.176",
    citation: "LRO LOLA GDR product ldem_875s_20m_float, north-adjacent byte-range extraction for Moonmoon route evidence.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "This is measured local terrain evidence for a route alternative, not proof that the route is safe.",
      "Illumination and a wider corridor search are still required before robot planning.",
    ],
  }
}

///|
pub fn first_trusted_square_southwest_bypass_manifest() -> DatasetManifest {
  {
    dataset_id: "lro-lola-first-trusted-square-southwest-bypass-dem-v1",
    title: "LOLA southwest-bypass corridor DEM byte-range fixture",
    source_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    license: "Apache-2.0",
    product_type: "lola-gdr-byte-range-corridor-dem-fixture",
    trust: Authoritative,
    claim_kind: @core.ClaimKind::Measured,
    coverage: {
      south_deg: -89.92,
      north_deg: -89.88,
      west_deg: 0.02,
      east_deg: 0.06,
    },
    resolution_m: 20.0,
    source_path: "data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv",
    source_sha256: "c47b837a8ed5bb818c865782396d44dae01b15b03a2a6a83c372548092c1ace5",
    extractor: "scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: "inline-grid-v1:tile=first-trusted-square-southwest-bypass-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=548.224:last=505.456",
    citation: "LRO LOLA GDR product ldem_875s_20m_float, southwest widened corridor byte-range extraction for Moonmoon route evidence.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "This is measured local terrain evidence from the first widened corridor scan, not proof that the route is safe.",
      "The window is the best sampled local grade among the first 5x5 scan but remains blocked by conservative rover limits.",
    ],
  }
}

///|
pub fn first_trusted_square_south_stepout_manifest() -> DatasetManifest {
  {
    dataset_id: "lro-lola-first-trusted-square-south-stepout-dem-v1",
    title: "LOLA south-stepout corridor DEM byte-range fixture",
    source_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img",
    license: "Apache-2.0",
    product_type: "lola-gdr-byte-range-corridor-dem-fixture",
    trust: Authoritative,
    claim_kind: @core.ClaimKind::Measured,
    coverage: {
      south_deg: -89.92,
      north_deg: -89.88,
      west_deg: 0.10,
      east_deg: 0.14,
    },
    resolution_m: 20.0,
    source_path: "data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv",
    source_sha256: "dde783fcf74ac0567bb2d6bb8eead6c2f83b620603319690aa51011486d7a19c",
    extractor: "scripts/extract_lola_trusted_square.py -> data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv -> scripts/generate_moonmoon_fixture.py -> src/terrain/generated_first_trusted_square_fixture.mbt",
    checksum_kind: InlineFixtureFingerprint,
    checksum: "inline-grid-v1:tile=first-trusted-square-south-stepout-lola:rows=4:cols=4:cell-size-m=20:cells=16:first=453.571:last=409.003",
    citation: "LRO LOLA GDR product ldem_875s_20m_float, south widened corridor byte-range extraction for Moonmoon route evidence.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "This is measured local terrain evidence from the first widened corridor scan, not proof that the route is safe.",
      "The window is smoother than the active patch but remains blocked by conservative rover limits.",
    ],
  }
}

///|
pub fn first_trusted_square_route_manifests() -> Array[DatasetManifest] {
  [
    first_trusted_square_west_contour_manifest(),
    first_trusted_square_north_rim_manifest(),
    first_trusted_square_southwest_bypass_manifest(),
    first_trusted_square_south_stepout_manifest(),
  ]
}
