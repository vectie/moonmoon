///|
pub(all) struct LunarSourceCandidate {
  source_id : String
  title : String
  body : String
  mission : String
  instrument : String
  product_family : String
  authority : String
  official_source_url : String
  access_url : String
  local_source_directory : String
  intended_use : String
  review_status : LunarReviewStatus
  notes : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn first_trusted_square_lola_source_candidate() -> LunarSourceCandidate {
  {
    source_id: "source-lro-lola-gdr-south-pole-v1",
    title: "LRO LOLA derived gridded topography",
    body: "Moon",
    mission: "Lunar Reconnaissance Orbiter",
    instrument: "LOLA",
    product_family: "GDR south-polar gridded terrain",
    authority: "NASA PDS Geosciences / LRO LOLA",
    official_source_url: "https://pds-geosciences.wustl.edu/missions/lro/lola.htm",
    access_url: "https://ode.rsl.wustl.edu/moon/",
    local_source_directory: "data/sources/lro_lola/",
    intended_use: "Measured south-pole terrain evidence for the first trusted square.",
    review_status: AcceptedForSoftwareProof,
    notes: [
      "The active fixture is a tiny checked byte-range extraction from the LOLA GDR south-polar float product.",
      "The raw 230 MB image remains external; the local CSV and XML label are the committed source boundary.",
    ],
  }
}

///|
pub fn first_trusted_square_ephemeris_source_candidate() -> LunarSourceCandidate {
  {
    source_id: "source-naif-lunar-ephemeris-first-trusted-square-v1",
    title: "NAIF lunar solar ephemeris power window",
    body: "Moon",
    mission: "NASA NAIF SPICE / planetary ephemeris",
    instrument: "SPICE kernels",
    product_family: "Sun/Moon ephemeris and lunar orientation kernels",
    authority: "NASA NAIF",
    official_source_url: "https://naif.jpl.nasa.gov/naif/data.html",
    access_url: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/",
    local_source_directory: "data/sources/lunar_ephemeris/",
    intended_use: "Time-windowed Sun/Moon geometry and power evidence for the first trusted square.",
    review_status: NeedsHumanReview,
    notes: [
      "The generated JSON pins the first local power-window computation.", "Energy clearance still requires review of horizon and rover power assumptions.",
    ],
  }
}

///|
pub fn first_trusted_square_lunar_source_candidates() -> Array[
  LunarSourceCandidate,
] {
  [
    first_trusted_square_lola_source_candidate(),
    first_trusted_square_ephemeris_source_candidate(),
  ]
}

///|
fn source_ref(
  ref_id : String,
  kind : String,
  path : String,
  content_type : String,
  byte_count : Int64,
  sha256 : String,
) -> @data_core.DataRef {
  @data_core.data_ref(
    ref_id,
    kind,
    @data_core.data_uri(path),
    content_type~,
    byte_count~,
    checksum=@data_core.declared_checksum(
      @data_core.ChecksumKind::Sha256,
      sha256,
    ),
  )
}

///|
pub fn first_trusted_square_lola_source() -> @data_core.DataSource {
  let candidate = first_trusted_square_lola_source_candidate()
  @data_core.data_source(
    candidate.source_id,
    candidate.authority,
    candidate.title,
    candidate.official_source_url,
    "NASA PDS public data",
    "LRO LOLA GDR south-polar terrain products, PDS Geosciences.",
    0L,
    source_refs=[
      source_ref(
        "lro-lola-gdr-catalog", "pds-catalog", "sources/lro_lola/gdr_ds.cat", "text/plain",
        5672L, "f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8",
      ),
      source_ref(
        "ldem-875s-20m-float-label", "pds4-label", "sources/lro_lola/ldem_875s_20m_float.xml",
        "application/xml", 11629L, "10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53",
      ),
    ],
  )
}

///|
pub fn first_trusted_square_ephemeris_source() -> @data_core.DataSource {
  let candidate = first_trusted_square_ephemeris_source_candidate()
  @data_core.data_source(
    candidate.source_id,
    candidate.authority,
    candidate.title,
    candidate.official_source_url,
    "NAIF public data",
    "NAIF generic kernels used for first trusted square Sun/Moon geometry.",
    0L,
    source_refs=[
      source_ref(
        "lunar-ephemeris-readme", "source-readme", "sources/lunar_ephemeris/README.md",
        "text/markdown", 994L, "a0d1c4b19c31e541fe98a6ce90fe08d6e2701a1212b6d018725bbf695be4e015",
      ),
    ],
  )
}

///|
pub fn first_trusted_square_lunar_sources() -> Array[@data_core.DataSource] {
  [first_trusted_square_lola_source(), first_trusted_square_ephemeris_source()]
}
