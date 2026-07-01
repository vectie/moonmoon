///|
test "root facade exposes the standalone product kernel" {
  let kernel = @moonmoon.product_kernel()
  assert_eq(kernel.product_name, "MoonMoon")
  assert_eq(kernel.current_site_id, "first-trusted-square")
  assert_true(kernel.layers.length() >= 5)
  assert_true(kernel.build_queue.length() >= 3)
}

///|
test "root facade exposes moonsuite product home contract" {
  let home = @moonmoon.moonsuite_product_home(book_id="lunar-site")
  assert_eq(home.product_id, "moonmoon")
  assert_eq(home.state_path, ".moonsuite/products/moonmoon")
  assert_eq(home.service_path, ".moonsuite/products/moonmoon/service.json")
  assert_eq(home.cache_path, ".moonsuite/products/moonmoon/cache")
  assert_eq(home.tmp_path, ".tmp/products/moonmoon")
  assert_eq(home.accepted_output_path, "books/lunar-site/outputs/moonmoon")
}

///|
test "root facade exposes promoted corridor route state" {
  let dossier = @moonmoon.trusted_square_dossier()
  let best = dossier.corridor_scan[0]
  assert_eq(best.window_id, "r-12-c+16")
  assert_eq(best.selected_route_id, "northeast-stepout")
  assert_eq(dossier.route_candidates.length(), 6)
  assert_eq(dossier.datasets.length(), 6)
}

///|
test "root facade renders standalone evidence" {
  let site_json = @moonmoon.trusted_square_json().stringify(indent=2)
  assert_true(site_json.contains("northeast-stepout"))
  assert_true(site_json.contains("power_window_evidence"))
  assert_true(site_json.contains("route_candidates"))
}

///|
test "root facade exposes operator view model and page" {
  let view = @moonmoon.trusted_square_view_model()
  assert_eq(view.selected_route_id, "northeast-stepout")
  assert_eq(view.terrain_cells.length(), 16)
  assert_true(
    @moonmoon.trusted_square_view_json()
    .stringify(indent=2)
    .contains("terrain_cells"),
  )
  assert_true(@moonmoon.trusted_square_html().contains("moonmoon-view-model"))
}
