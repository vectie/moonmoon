///|
test "Rabbita Moon page renders standalone operator shell" {
  let html = @rabbita_moon.first_trusted_square_html()
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("Rabbita Moon"))
  assert_true(html.contains("moonmoon-view-model"))
  assert_true(html.contains("moonmoon-moonbook"))
  assert_true(html.contains("globe_overlay"))
  assert_true(html.contains("site_latitude_deg"))
  assert_true(html.contains("site_longitude_deg"))
  assert_true(html.contains("hardware_authority"))
  assert_true(html.contains("blocker_count"))
}

///|
test "Rabbita Moon page links local presentation assets" {
  let html = @rabbita_moon.first_trusted_square_html()
  assert_true(html.contains("assets/rabbita_moon.css"))
  assert_true(html.contains("assets/rabbita_app.js"))
  assert_true(html.contains("assets/moon_globe.js"))
  assert_true(html.contains("assets/lunar_global_texture.jpg"))
  assert_true(html.contains("assets/southpole_10deg_print.jpg"))
  assert_true(!html.contains("function renderGrid()"))
  assert_true(!html.contains("function renderLolaDataViewport()"))
  assert_true(!html.contains("<style>"))
}

///|
test "Rabbita Moon page exposes globe and review anchors" {
  let html = @rabbita_moon.first_trusted_square_html()
  assert_true(html.contains("data-moon-globe"))
  assert_true(html.contains("moon-globe-canvas"))
  assert_true(html.contains("moon-globe-overlay"))
  assert_true(html.contains("data-globe-action=\"home\""))
  assert_true(html.contains("data-globe-action=\"site\""))
  assert_true(html.contains("data-globe-layer=\"grid\""))
  assert_true(html.contains("data-globe-layer=\"footprint\""))
  assert_true(html.contains("data-globe-layer=\"route\""))
  assert_true(html.contains("data-globe-layer=\"corridor\""))
  assert_true(html.contains("lola-data-map"))
  assert_true(html.contains("toolbar"))
  assert_true(html.contains("terrain-grid"))
  assert_true(html.contains("clearance-review"))
  assert_true(html.contains("transition-export"))
  assert_true(html.contains("closeout-action-review"))
  assert_true(html.contains("closeout-action-review-export"))
}
