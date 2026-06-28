///|
test "standalone Moonmoon UI renders from the MoonBit view model" {
  let html = @ui.first_trusted_square_html()
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("Moonmoon"))
  assert_true(html.contains("moonmoon-view-model"))
  assert_true(html.contains("terrain cells"))
  assert_true(html.contains("selected cell"))
  assert_true(html.contains("northeast-stepout"))
  assert_true(html.contains("site_latitude_deg"))
}

///|
test "standalone Moonmoon UI has no stale external asset bundle" {
  let html = @ui.first_trusted_square_html()
  assert_true(!html.contains("assets/rabbita_moon.css"))
  assert_true(!html.contains("assets/rabbita_app.js"))
  assert_true(!html.contains("moonmoon-moonbook"))
  assert_true(!html.contains("moonmoon-noetix"))
  assert_true(!html.contains("src/ui/rabbita_moon"))
}
