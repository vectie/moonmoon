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
