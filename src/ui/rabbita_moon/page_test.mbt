///|
test "Rabbita Moon page renders browser inspection controls" {
  let html = @rabbita_moon.first_trusted_square_html()
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("Rabbita Moon"))
  assert_true(html.contains("moonmoon-view-model"))
  assert_true(html.contains("moonmoon-moonbook"))
  assert_true(html.contains("Layer toggles"))
  assert_true(html.contains("Selectable lunar terrain cells"))
  assert_true(html.contains("Route Overlays"))
  assert_true(html.contains("Source Evidence"))
  assert_true(html.contains("MoonBook Review Status"))
  assert_true(html.contains("function renderGrid()"))
  assert_true(html.contains("function renderReview()"))
  assert_true(html.contains("route-direct-lola-window"))
  assert_true(html.contains("energy-window"))
}
