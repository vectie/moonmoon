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
