///|
test "standalone MoonMoon UI renders from the MoonBit view model" {
  let html = @ui.first_trusted_square_html()
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("MoonMoon"))
  assert_true(html.contains("moonmoon-view-model"))
  assert_true(html.contains("moonmoon-motion-contract"))
  assert_true(html.contains("moonmoon-globe-runtime"))
  assert_true(html.contains("moon-globe-canvas"))
  assert_true(
    html.contains("data-terrain-texture=\"lola-dem-elevation-hazard\""),
  )
  assert_true(html.contains("operable Moon globe"))
  assert_true(html.contains("Moon context"))
  assert_true(html.contains("data-moon-action=\"focus\""))
  assert_true(html.contains("data-moon-action=\"reset\""))
  assert_true(html.contains("data-moon-action=\"orbit\""))
  assert_true(html.contains("motion contract"))
  assert_true(html.contains("terrain cells"))
  assert_true(html.contains("selected cell"))
  assert_true(
    html.contains("datasets/lro-lola-first-trusted-square-dem-v1.json"),
  )
  assert_true(html.contains("northeast-stepout"))
  assert_true(html.contains("site_latitude_deg"))
  assert_true(html.contains("globe_overlay"))
  assert_true(html.contains("drawSourceTerrainTexture"))
  assert_true(html.contains("terrainColor"))
  assert_true(html.contains("terrain_cells"))
  assert_true(html.contains("site-footprint/ne"))
  assert_true(html.contains("globe-route/northeast-stepout"))
  assert_true(
    html.contains(
      "trusted square bounds, 81 measured corridor windows, and northeast-stepout",
    ),
  )
}

///|
test "standalone MoonMoon UI has no stale external asset bundle" {
  let html = @ui.first_trusted_square_html()
  assert_true(!html.contains("assets/rabbita_moon.css"))
  assert_true(!html.contains("assets/rabbita_app.js"))
  assert_true(!html.contains("moonmoon-moonbook"))
  assert_true(!html.contains("moonmoon-noetix"))
  assert_true(!html.contains("src/ui/rabbita_moon"))
  assert_true(!html.contains("three.module.js"))
  assert_true(!html.contains("https://esm.sh"))
}

///|
test "standalone motion contract keeps robot gait outside core packages" {
  let contract = @ui.first_trusted_square_motion_contract()
  assert_eq(contract.physics_core_package, "src/moonphys")
  assert_eq(contract.motion_owner_package, "future-suite-adapter")
  assert_eq(contract.gait_asset_status, "not-in-standalone-model")
  assert_eq(contract.status, "mission-gated")
  assert_eq(contract.simulation_status, "simulation-preview-blocked")
  let json = @ui.first_trusted_square_motion_contract_json().stringify(indent=2)
  assert_true(json.contains("standalone-route-motion-contract"))
  assert_true(json.contains("future-suite-adapter"))
}
