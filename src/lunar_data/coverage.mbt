///|
pub(all) struct LunarCoverage {
  body : String
  south_deg : Double
  north_deg : Double
  west_deg : Double
  east_deg : Double
  center_lat_deg : Double
  center_lon_deg : Double
  resolution_m : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn lunar_coverage(
  south_deg : Double,
  north_deg : Double,
  west_deg : Double,
  east_deg : Double,
  center_lat_deg : Double,
  center_lon_deg : Double,
  resolution_m : Double,
  body? : String = "Moon",
) -> LunarCoverage {
  {
    body,
    south_deg,
    north_deg,
    west_deg,
    east_deg,
    center_lat_deg,
    center_lon_deg,
    resolution_m,
  }
}

///|
pub(all) struct LunarCoordinateFrame {
  frame_id : String
  body : String
  datum : String
  projection : String
  radius_reference_m : Double
  notes : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn lro_lola_south_pole_frame() -> LunarCoordinateFrame {
  {
    frame_id: "moon-lola-south-pole-polar-stereographic-v1",
    body: "Moon",
    datum: "LOLA/GRAIL reference sphere",
    projection: "Polar Stereographic",
    radius_reference_m: 1737400.0,
    notes: "South-pole LOLA GDR DEM frame used for first trusted square extraction.",
  }
}
