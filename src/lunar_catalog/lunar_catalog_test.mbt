///|
fn root_path(name : String) -> String {
  "target/lunar-catalog-tests/\{name}"
}

///|
fn remove_files(dir : String) -> Unit {
  if !@fsx.path_exists(dir) {
    return
  }
  let names = @fsx.read_dir(dir) catch { _ => return }
  for name in names {
    let path = dir + "/\{name}"
    if !name.contains(".") {
      continue
    }
    @fsx.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn prepare_root(name : String) -> String {
  let root = root_path(name)
  ignore(@data_store.initialize_root(root))
  remove_files(root + "/sources")
  remove_files(root + "/sources/lro_lola")
  remove_files(root + "/sources/lunar_ephemeris")
  remove_files(root + "/datasets")
  remove_files(root + "/versions")
  remove_files(root + "/artifacts")
  remove_files(root + "/lineage")
  remove_files(root + "/validations")
  remove_files(root + "/indexes")
  root
}

///|
test "materializes first trusted square into generic catalog root" {
  let root = prepare_root("materialize")
  let result = @lunar_catalog.materialize_first_trusted_square_catalog(
    root, 100L,
  ).unwrap()
  assert_eq(result.source_count, 2)
  assert_eq(result.dataset_count, 2)
  assert_eq(result.catalog_entry_count, 5)
  assert_eq(result.blocker_count, 0)
  assert_true(result.warning_count > 0)
  assert_true(result.validation_status == @data_core.ValidationStatus::Warning)
  assert_true(@fsx.path_exists(result.catalog_path))
  assert_true(@fsx.path_exists(result.validation_report_path))
  assert_true(
    @fsx.path_exists(root + "/sources/lro_lola/first_trusted_square_dem.csv"),
  )
  assert_true(
    @fsx.path_exists(
      root + "/sources/lunar_ephemeris/first_trusted_square_power_window.json",
    ),
  )
}

///|
test "lists first trusted square evidence from cataloged manifests" {
  let root = prepare_root("listing")
  ignore(
    @lunar_catalog.materialize_first_trusted_square_catalog(root, 200L).unwrap(),
  )
  let sources = @lunar_catalog.first_trusted_square_catalog_sources(root).unwrap()
  assert_eq(sources.length(), 2)
  assert_eq(sources[0].authority, "NASA PDS Geosciences / LRO LOLA")
  assert_eq(sources[0].source_ref_count, 2)
  assert_eq(sources[1].authority, "NASA NAIF")
  let datasets = @lunar_catalog.first_trusted_square_catalog_datasets(root).unwrap()
  assert_eq(datasets.length(), 2)
  assert_eq(datasets[0].dataset_id, "lro-lola-first-trusted-square-dem-v1")
  assert_eq(datasets[0].coverage.body, "Moon")
  assert_eq(datasets[0].data_ref_count, 1)
  assert_eq(
    datasets[1].dataset_id,
    "naif-lunar-first-trusted-square-power-window-v1",
  )
}
