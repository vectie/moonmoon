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
fn review_status_from_lunar(
  status : @lunar_data.LunarReviewStatus,
) -> ReviewStatus {
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
fn acquisition_step_from_lunar(
  step : @lunar_data.LunarAcquisitionStep,
) -> SourceAcquisitionStep {
  {
    step_id: step.step_id,
    title: step.title,
    action: step.action,
    expected_evidence: step.expected_evidence,
    done_when: step.done_when,
  }
}

///|
fn acquisition_plan_from_lunar(
  plan : @lunar_data.LunarAcquisitionPlan,
  candidate_id : String,
) -> SourceAcquisitionPlan {
  {
    plan_id: plan.plan_id,
    candidate_id,
    product_family_id: plan.product_family_id,
    source_family_url: plan.source_family_url,
    source_metadata_url: plan.source_metadata_url,
    source_metadata_sha256: plan.source_metadata_sha256,
    source_metadata_bytes: plan.source_metadata_bytes.to_int(),
    discovery_url: plan.discovery_url,
    target_region: plan.target_region,
    expected_format: plan.expected_format,
    local_source_directory: plan.local_source_directory,
    local_metadata_path: plan.local_metadata_path,
    extracted_fixture_path: plan.extracted_fixture_path,
    trust_gate: plan.trust_gate,
    steps: plan.steps.map(fn(step) { acquisition_step_from_lunar(step) }),
  }
}

///|
fn extraction_candidate_from_lunar(
  extraction : @lunar_data.LunarExtractionCandidate,
) -> SourceExtractionCandidate {
  {
    extraction_id: extraction.extraction_id,
    selection_id: extraction.selection_id,
    generated_by: extraction.generated_by,
    output_path: extraction.output_path,
    output_sha256: extraction.output_sha256,
    output_bytes: extraction.output_bytes.to_int(),
    tile_id: extraction.tile_id,
    center_lat_deg: extraction.coverage.center_lat_deg,
    center_lon_deg: extraction.coverage.center_lon_deg,
    source_row_start: extraction.source_row_start,
    source_col_start: extraction.source_col_start,
    rows: extraction.rows,
    cols: extraction.cols,
    cell_size_m: extraction.cell_size_m,
    elevation_unit: extraction.value_unit,
    claim_kind: claim_kind_from_lunar(extraction.claim_kind),
    review_status: review_status_from_lunar(extraction.review_status),
    notes: extraction.notes,
  }
}

///|
fn terrain_manifest_from_lunar(
  record : @lunar_data.LunarTerrainDatasetRecord,
) -> DatasetManifest {
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
pub(all) enum ChecksumKind {
  InlineFixtureFingerprint
  Sha256
  UnknownChecksumKind
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
pub fn first_trusted_square_lola_candidate() -> SourceCandidate {
  let source = @lunar_data.first_trusted_square_lola_source_candidate()
  let extraction = @lunar_data.first_trusted_square_lola_extraction_candidate()
  {
    candidate_id: "candidate-lro-lola-sldem-first-trusted-square",
    title: source.title + " candidate",
    body: source.body,
    mission: source.mission,
    instrument: source.instrument,
    product_family: source.product_family + " / SLDEM derived gridded terrain",
    official_source_url: source.official_source_url,
    access_url: source.access_url,
    local_target_path: "data/sources/lro_lola/first_trusted_square_dem.csv plus adjacent route-window CSVs",
    intended_use: source.intended_use,
    next_action: "Use the checked LOLA byte-range fixtures for software proof, then add illumination and wider corridor search before any rover claim.",
    review_status: review_status_from_lunar(source.review_status),
    notes: source.notes +
    [
      "Active extraction: \{extraction.extraction_id}.",
      "PDS Geosciences identifies LOLA as the LRO Lunar Orbiter Laser Altimeter for high-resolution lunar topography.",
      "The PDS page lists derived GDR and SLDEM product families and points recent LOLA data discovery to ODE/LOLA Data Node.",
    ],
  }
}

///|
pub fn first_trusted_square_lola_acquisition_plan() -> SourceAcquisitionPlan {
  acquisition_plan_from_lunar(
    @lunar_data.first_trusted_square_lola_acquisition_plan(),
    "candidate-lro-lola-sldem-first-trusted-square",
  )
}

///|
pub fn first_trusted_square_ephemeris_candidate() -> SourceCandidate {
  let source = @lunar_data.first_trusted_square_ephemeris_source_candidate()
  let window = @lunar_data.first_trusted_square_ephemeris_window()
  {
    candidate_id: "candidate-lunar-solar-ephemeris-first-trusted-square",
    title: source.title,
    body: source.body,
    mission: source.mission,
    instrument: source.instrument,
    product_family: source.product_family,
    official_source_url: source.official_source_url,
    access_url: source.access_url,
    local_target_path: window.output_path,
    intended_use: source.intended_use,
    next_action: "Review the computed low-sun-angle power window, local horizon assumptions, and rover power model before clearing the energy gate.",
    review_status: review_status_from_lunar(source.review_status),
    notes: source.notes +
    [
      "Window fixture: \{window.window_id}.",
      "The current illumination and energy gates deliberately block because computed power remains below the conservative route demand.",
    ],
  }
}

///|
pub fn first_trusted_square_ephemeris_acquisition_plan() -> SourceAcquisitionPlan {
  acquisition_plan_from_lunar(
    @lunar_data.first_trusted_square_ephemeris_acquisition_plan(),
    "candidate-lunar-solar-ephemeris-first-trusted-square",
  )
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
  let selection = @lunar_data.first_trusted_square_lola_product_selection()
  {
    selection_id: selection.selection_id,
    plan_id: "acquire-lro-lola-gdr-south-pole-20m-v1",
    product_id: selection.product_id,
    product_lid: selection.product_lid,
    image_url: selection.image_url,
    label_url: selection.label_url,
    local_label_path: selection.local_label_path,
    label_sha256: selection.label_sha256,
    label_bytes: selection.label_bytes.to_int(),
    image_bytes: selection.image_bytes.to_int(),
    projection: selection.coordinate_frame.projection,
    resolution_m: selection.coverage.resolution_m,
    west_deg: selection.coverage.west_deg,
    east_deg: selection.coverage.east_deg,
    south_deg: selection.coverage.south_deg,
    north_deg: selection.coverage.north_deg,
    lines: selection.lines,
    samples: selection.samples,
    data_type: selection.data_type,
    unit: selection.unit,
    value_offset_km: selection.value_offset_km,
    selection_reason: selection.selection_reason +
    " The XML label remains the committed extractor boundary.",
    extraction_risk: "The image is about 230 MB and should be window-read from the float raster after projection math is tested; do not commit the raw image.",
    review_status: review_status_from_lunar(selection.review_status),
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
  extraction_candidate_from_lunar(
    @lunar_data.first_trusted_square_lola_extraction_candidate(),
  )
}

///|
pub fn first_trusted_square_west_contour_lola_extraction_candidate() -> SourceExtractionCandidate {
  extraction_candidate_from_lunar(
    @lunar_data.first_trusted_square_west_contour_lola_extraction_candidate(),
  )
}

///|
pub fn first_trusted_square_north_rim_lola_extraction_candidate() -> SourceExtractionCandidate {
  extraction_candidate_from_lunar(
    @lunar_data.first_trusted_square_north_rim_lola_extraction_candidate(),
  )
}

///|
pub fn first_trusted_square_southwest_bypass_lola_extraction_candidate() -> SourceExtractionCandidate {
  extraction_candidate_from_lunar(
    @lunar_data.first_trusted_square_southwest_bypass_lola_extraction_candidate(),
  )
}

///|
pub fn first_trusted_square_south_stepout_lola_extraction_candidate() -> SourceExtractionCandidate {
  extraction_candidate_from_lunar(
    @lunar_data.first_trusted_square_south_stepout_lola_extraction_candidate(),
  )
}

///|
pub fn first_trusted_square_northeast_stepout_lola_extraction_candidate() -> SourceExtractionCandidate {
  extraction_candidate_from_lunar(
    @lunar_data.first_trusted_square_northeast_stepout_lola_extraction_candidate(),
  )
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
    first_trusted_square_northeast_stepout_lola_extraction_candidate(),
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
  terrain_manifest_from_lunar(
    @lunar_data.first_trusted_square_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_west_contour_manifest() -> DatasetManifest {
  terrain_manifest_from_lunar(
    @lunar_data.first_trusted_square_west_contour_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_north_rim_manifest() -> DatasetManifest {
  terrain_manifest_from_lunar(
    @lunar_data.first_trusted_square_north_rim_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_southwest_bypass_manifest() -> DatasetManifest {
  terrain_manifest_from_lunar(
    @lunar_data.first_trusted_square_southwest_bypass_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_south_stepout_manifest() -> DatasetManifest {
  terrain_manifest_from_lunar(
    @lunar_data.first_trusted_square_south_stepout_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_northeast_stepout_manifest() -> DatasetManifest {
  terrain_manifest_from_lunar(
    @lunar_data.first_trusted_square_northeast_stepout_lola_terrain_dataset_record(),
  )
}

///|
pub fn first_trusted_square_route_manifests() -> Array[DatasetManifest] {
  [
    first_trusted_square_west_contour_manifest(),
    first_trusted_square_north_rim_manifest(),
    first_trusted_square_southwest_bypass_manifest(),
    first_trusted_square_south_stepout_manifest(),
    first_trusted_square_northeast_stepout_manifest(),
  ]
}
