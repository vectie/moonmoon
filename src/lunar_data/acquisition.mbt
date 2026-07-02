///|
pub(all) struct LunarAcquisitionStep {
  step_id : String
  title : String
  action : String
  expected_evidence : String
  done_when : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct LunarAcquisitionPlan {
  plan_id : String
  source_id : String
  product_family_id : String
  source_family_url : String
  source_metadata_url : String
  source_metadata_sha256 : String
  source_metadata_bytes : Int64
  discovery_url : String
  target_region : String
  expected_format : String
  local_source_directory : String
  local_metadata_path : String
  extracted_fixture_path : String
  trust_gate : String
  steps : Array[LunarAcquisitionStep]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_lola_acquisition_plan() -> LunarAcquisitionPlan {
  {
    plan_id: "acquire-lro-lola-gdr-south-pole-20m-v1",
    source_id: first_trusted_square_lola_source_candidate().source_id,
    product_family_id: "lro-lola-gdr-south-pole-selection",
    source_family_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/",
    source_metadata_url: "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat",
    source_metadata_sha256: "f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8",
    source_metadata_bytes: 5672L,
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
        done_when: "MoonBit fixture generator regenerates MoonBit terrain from the authoritative CSV.",
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
        expected_evidence: "operator review notes tied to the dataset, terrain metrics, and traverse decision.",
        done_when: "The source-upgrade blocker is closed and remaining review focuses on terrain hazards, illumination, and route alternatives.",
      },
    ],
  }
}

///|
pub fn first_trusted_square_ephemeris_acquisition_plan() -> LunarAcquisitionPlan {
  {
    plan_id: "acquire-lunar-solar-ephemeris-first-trusted-square-v1",
    source_id: first_trusted_square_ephemeris_source_candidate().source_id,
    product_family_id: "lunar-solar-ephemeris-power-window",
    source_family_url: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/",
    source_metadata_url: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/",
    source_metadata_sha256: "d1a84599750c76ae4b93afec9ae2e6a002e5a0fba9c6704ca8cd32a530eacf59",
    source_metadata_bytes: 45745465L,
    discovery_url: "https://naif.jpl.nasa.gov/naif/data.html",
    target_region: "First Trusted Square near Shackleton rim, 89.88S, 0.12E",
    expected_format: "Pinned ephemeris/orientation source plus generated JSON power-window evidence",
    local_source_directory: "data/sources/lunar_ephemeris/",
    local_metadata_path: "data/sources/lunar_ephemeris/README.md",
    extracted_fixture_path: "data/sources/lunar_ephemeris/first_trusted_square_power_window.json",
    trust_gate: "Computed from cited NAIF ephemeris/orientation sources with pinned checksums; local horizon and rover power assumptions still require review before energy can move out of block.",
    steps: [
      {
        step_id: "discover-source",
        title: "Select official ephemeris source",
        action: "Choose NAIF SPICE kernels or an equivalent official illumination product that can support Sun/Moon geometry for the south-pole tile.",
        expected_evidence: "Source family URL, kernel/product names, access URL, and license/usage notes recorded in Operator review.",
        done_when: "done: the candidate names concrete official NAIF source files instead of a generic power assumption.",
      },
      {
        step_id: "pin-kernels",
        title: "Pin checksummed inputs",
        action: "Record exact kernel or illumination product files, byte counts, SHA-256 checksums, and local paths under data/sources/lunar_ephemeris.",
        expected_evidence: "A README plus source metadata checksum fields that make reruns deterministic.",
        done_when: "done: moon test rejects missing or changed ephemeris inputs.",
      },
      {
        step_id: "compute-local-window",
        title: "Compute local power window",
        action: "Evaluate the first trusted square over a declared time span and emit sunlit hours, dark survival hours, incidence notes, and confidence.",
        expected_evidence: "A generated JSON fixture at data/sources/lunar_ephemeris/first_trusted_square_power_window.json.",
        done_when: "done: the JSON records time range, source checksums, local coordinate, sunlit hours, dark hours, and uncertainty.",
      },
      {
        step_id: "generate-moonbit-window",
        title: "Generate MoonBit evidence",
        action: "Mirror the checked JSON into src/mission/generated_first_trusted_square_power_window.mbt for deterministic mission tests.",
        expected_evidence: "Generated MoonBit power-window module and tests tied to the JSON checksum.",
        done_when: "done: moon test proves the mission energy gate reads generated ephemeris evidence instead of hard-coded zero Wh.",
      },
      {
        step_id: "review-energy-gate",
        title: "Review before unblocking Moonrobo",
        action: "Have Operator review record reviewer acceptance that the ephemeris source, local horizon assumptions, and rover power model are coherent.",
        expected_evidence: "A review transition moving the ephemeris source candidate and energy-window item out of needs-evidence.",
        done_when: "Moonrobo handoff remains blocked or becomes reviewable based on measured terrain plus accepted time-windowed power evidence.",
      },
    ],
  }
}

///|
pub fn first_trusted_square_lunar_acquisition_plans() -> Array[
  LunarAcquisitionPlan,
] {
  [
    first_trusted_square_lola_acquisition_plan(),
    first_trusted_square_ephemeris_acquisition_plan(),
  ]
}
