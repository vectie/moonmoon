///|
fn read_text(path : String) -> String raise {
  @fsx.read_file_to_string(path) catch {
    _ => fail("failed to read " + path)
  }
}

///|
fn assert_not_contains(
  text : String,
  needle : String,
  label : String,
) -> Unit raise {
  if text.contains(needle) {
    fail(label + " contains forbidden term " + needle)
  }
}

///|
fn data_core_files() -> Array[String] {
  [
    "src/data_core/moon.pkg", "src/data_core/catalog.mbt", "src/data_core/checksum.mbt",
    "src/data_core/dataset.mbt", "src/data_core/lineage.mbt", "src/data_core/ref.mbt",
    "src/data_core/source.mbt", "src/data_core/status.mbt", "src/data_core/uri.mbt",
    "src/data_core/validation.mbt",
  ]
}

///|
fn data_store_files() -> Array[String] {
  [
    "src/data_store/moon.pkg", "src/data_store/store.mbt", "src/data_store/catalog_rebuild.mbt",
  ]
}

///|
fn data_validate_files() -> Array[String] {
  ["src/data_validate/moon.pkg", "src/data_validate/validation.mbt"]
}

///|
fn lunar_data_files() -> Array[String] {
  [
    "src/lunar_data/moon.pkg", "src/lunar_data/status.mbt", "src/lunar_data/coverage.mbt",
    "src/lunar_data/source.mbt", "src/lunar_data/product.mbt", "src/lunar_data/extraction.mbt",
    "src/lunar_data/ephemeris.mbt", "src/lunar_data/tile.mbt",
  ]
}

///|
test "data_core stays domain neutral and filesystem free" {
  let forbidden = [
    "lunar", "Lunar", "Moon", "LOLA", "SPICE", "crater", "robot", "Robot", "URDF",
    "telemetry", "bridge", "\"moonbitlang/x/fs\"", "\"vectie/moonmoon/src/",
  ]
  for path in data_core_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
}

///|
test "data_validate depends only on data_core data_store and filesystem" {
  let forbidden = [
    "lunar", "Lunar", "Moon", "LOLA", "SPICE", "crater", "robot", "Robot", "URDF",
    "telemetry", "bridge", "\"vectie/moonmoon/src/core", "\"vectie/moonmoon/src/dataset",
    "\"vectie/moonmoon/src/terrain", "\"vectie/moonmoon/src/mission", "\"vectie/moonmoon/src/site",
    "\"vectie/moonmoon/src/ui", "\"vectie/moonmoon/src/lunar_data", "\"vectie/moonmoon/src/robot_data",
  ]
  for path in data_validate_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/data_validate/moon.pkg")
  if !manifest.contains("\"vectie/moonmoon/src/data_core\"") {
    fail("data_validate must import data_core")
  }
  if !manifest.contains("\"vectie/moonmoon/src/data_store\"") {
    fail("data_validate must import data_store")
  }
  if !manifest.contains("\"moonbitlang/x/fs\"") {
    fail("data_validate must own validation-time filesystem reads")
  }
}

///|
test "data_store depends only on data_core and filesystem" {
  let forbidden = [
    "lunar", "Lunar", "Moon", "LOLA", "SPICE", "crater", "robot", "Robot", "URDF",
    "telemetry", "bridge", "\"vectie/moonmoon/src/core", "\"vectie/moonmoon/src/dataset",
    "\"vectie/moonmoon/src/terrain", "\"vectie/moonmoon/src/mission", "\"vectie/moonmoon/src/site",
    "\"vectie/moonmoon/src/ui", "\"vectie/moonmoon/src/data_validate",
  ]
  for path in data_store_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/data_store/moon.pkg")
  if !manifest.contains("\"vectie/moonmoon/src/data_core\"") {
    fail("data_store must import data_core")
  }
  if !manifest.contains("\"moonbitlang/x/fs\"") {
    fail("data_store must own the filesystem boundary")
  }
}

///|
test "lunar_data owns lunar records without store validate robot or ui imports" {
  let forbidden = [
    "robot", "Robot", "URDF", "telemetry", "bridge", "Noetix", "Rabbita", "\"moonbitlang/x/fs\"",
    "\"vectie/moonmoon/src/data_store", "\"vectie/moonmoon/src/data_validate", "\"vectie/moonmoon/src/dataset",
    "\"vectie/moonmoon/src/terrain", "\"vectie/moonmoon/src/mission", "\"vectie/moonmoon/src/site",
    "\"vectie/moonmoon/src/ui", "\"vectie/moonmoon/src/suite_adapter_preview", "\"vectie/moonmoon/src/robot_data",
  ]
  for path in lunar_data_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/lunar_data/moon.pkg")
  if !manifest.contains("\"vectie/moonmoon/src/data_core\"") {
    fail("lunar_data must project records through data_core")
  }
}
