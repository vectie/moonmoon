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
  [
    "src/data_validate/moon.pkg", "src/data_validate/validation.mbt", "src/data_validate/summary.mbt",
  ]
}

///|
fn lunar_data_files() -> Array[String] {
  [
    "src/lunar_data/moon.pkg", "src/lunar_data/status.mbt", "src/lunar_data/coverage.mbt",
    "src/lunar_data/source.mbt", "src/lunar_data/acquisition.mbt", "src/lunar_data/product.mbt",
    "src/lunar_data/extraction.mbt", "src/lunar_data/terrain_dataset.mbt", "src/lunar_data/ephemeris.mbt",
    "src/lunar_data/tile.mbt",
  ]
}

///|
fn lunar_catalog_files() -> Array[String] {
  [
    "src/lunar_catalog/moon.pkg", "src/lunar_catalog/materialize.mbt", "src/lunar_catalog/listing.mbt",
  ]
}

///|
fn product_evidence_files() -> Array[String] {
  [
    "src/site/moon.pkg", "src/site/site.mbt", "src/site/catalog_evidence.mbt", "src/ui/moon.pkg",
    "src/ui/types.mbt", "src/ui/inspector.mbt", "src/ui/view_model.mbt", "src/kernel/moon.pkg",
    "src/kernel/kernel.mbt",
  ]
}

///|
fn site_catalog_files() -> Array[String] {
  ["src/site_catalog/moon.pkg", "src/site_catalog/catalog_evidence.mbt"]
}

///|
fn robot_data_files() -> Array[String] {
  [
    "src/robot_data/moon.pkg", "src/robot_data/payload.mbt", "src/robot_data/model.mbt",
    "src/robot_data/episode.mbt", "src/robot_data/quality.mbt", "src/robot_data/legacy_ref.mbt",
    "src/robot_data/telemetry.mbt", "src/robot_data/gait.mbt",
  ]
}

///|
fn robot_catalog_files() -> Array[String] {
  [
    "src/robot_catalog/moon.pkg", "src/robot_catalog/bundle.mbt", "src/robot_catalog/materialize.mbt",
    "src/robot_catalog/model_import.mbt", "src/robot_catalog/model_listing.mbt",
    "src/robot_catalog/episode_import.mbt", "src/robot_catalog/episode_listing.mbt",
    "src/robot_catalog/root_listing.mbt", "src/robot_catalog/readiness.mbt", "src/robot_catalog/telemetry_import.mbt",
    "src/robot_catalog/telemetry_listing.mbt", "src/robot_catalog/gait_import.mbt",
    "src/robot_catalog/gait_listing.mbt",
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
test "product evidence consumes catalog refs without store adapters" {
  let forbidden = [
    "\"moonbitlang/x/fs\"", "\"vectie/moonmoon/src/data_store", "\"vectie/moonmoon/src/data_validate",
    "\"vectie/moonmoon/src/lunar_catalog", "\"vectie/moonmoon/src/dataset",
  ]
  for path in product_evidence_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let site_manifest = read_text("src/site/moon.pkg")
  if !site_manifest.contains("\"vectie/moonmoon/src/data_core\"") {
    fail("site must expose catalog evidence through data_core refs")
  }
  if !site_manifest.contains("\"vectie/moonmoon/src/lunar_data\"") {
    fail("site must project catalog evidence from lunar_data")
  }
}

///|
test "site_catalog is the only product data root adapter" {
  let forbidden = [
    "\"moonbitlang/x/fs\"", "\"vectie/moonmoon/src/data_validate", "\"vectie/moonmoon/src/dataset",
    "\"vectie/moonmoon/src/terrain", "\"vectie/moonmoon/src/mission", "\"vectie/moonmoon/src/ui",
    "\"vectie/moonmoon/src/kernel", "\"vectie/moonmoon/src/suite_adapter_preview",
    "\"vectie/moonmoon/src/robot_data", "URDF", "telemetry", "Noetix", "Rabbita",
  ]
  for path in site_catalog_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/site_catalog/moon.pkg")
  for
    required in [
      "\"vectie/moonmoon/src/data_store\"", "\"vectie/moonmoon/src/lunar_catalog\"",
      "\"vectie/moonmoon/src/site\"",
    ] {
    if !manifest.contains(required) {
      fail("site_catalog missing required import " + required)
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

///|
test "lunar_catalog is the only lunar store validate adapter" {
  let forbidden = [
    "robot", "Robot", "URDF", "telemetry", "bridge", "Noetix", "Rabbita", "\"vectie/moonmoon/src/dataset",
    "\"vectie/moonmoon/src/terrain", "\"vectie/moonmoon/src/mission", "\"vectie/moonmoon/src/site",
    "\"vectie/moonmoon/src/ui", "\"vectie/moonmoon/src/suite_adapter_preview", "\"vectie/moonmoon/src/robot_data",
  ]
  for path in lunar_catalog_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/lunar_catalog/moon.pkg")
  for
    required in [
      "\"vectie/moonmoon/src/data_core\"", "\"vectie/moonmoon/src/data_store\"",
      "\"vectie/moonmoon/src/data_validate\"", "\"vectie/moonmoon/src/lunar_data\"",
    ] {
    if !manifest.contains(required) {
      fail("lunar_catalog missing required import " + required)
    }
  }
}

///|
test "terrain owns terrain source manifests without dataset facade" {
  let manifest = read_text("src/terrain/moon.pkg")
  if manifest.contains("\"vectie/moonmoon/src/dataset\"") {
    fail("terrain must not import the removed dataset facade")
  }
  if !manifest.contains("\"vectie/moonmoon/src/lunar_data\"") {
    fail("terrain source manifests must project from lunar_data")
  }
  let source_manifest = read_text("src/terrain/source_manifest.mbt")
  for
    term in [
      "\"moonbitlang/x/fs\"", "\"vectie/moonmoon/src/data_store", "\"vectie/moonmoon/src/data_validate",
      "\"vectie/moonmoon/src/lunar_catalog", "\"vectie/moonmoon/src/site", "\"vectie/moonmoon/src/ui",
      "\"vectie/moonmoon/src/robot_data", "URDF", "telemetry", "Noetix", "Rabbita",
    ] {
    assert_not_contains(
      source_manifest, term, "src/terrain/source_manifest.mbt",
    )
  }
}

///|
test "robot_data is a pure robot domain projection over data_core" {
  let forbidden = [
    "lunar", "Lunar", "MoonRobo", "Noetix", "Rabbita", "\"moonbitlang/x/fs\"", "\"vectie/moonmoon/src/data_store",
    "\"vectie/moonmoon/src/data_validate", "\"vectie/moonmoon/src/lunar_data", "\"vectie/moonmoon/src/lunar_catalog",
    "\"vectie/moonmoon/src/site", "\"vectie/moonmoon/src/site_catalog", "\"vectie/moonmoon/src/ui",
    "\"vectie/moonmoon/src/kernel", "\"vectie/moonmoon/src/suite_adapter_preview",
  ]
  for path in robot_data_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/robot_data/moon.pkg")
  if !manifest.contains("\"vectie/moonmoon/src/data_core\"") {
    fail("robot_data must project records through data_core")
  }
}

///|
test "robot_catalog is the robot store validate adapter" {
  let forbidden = [
    "lunar", "Lunar", "MoonRobo", "Noetix", "Rabbita", "\"vectie/moonmoon/src/lunar_data",
    "\"vectie/moonmoon/src/lunar_catalog", "\"vectie/moonmoon/src/dataset", "\"vectie/moonmoon/src/site",
    "\"vectie/moonmoon/src/site_catalog", "\"vectie/moonmoon/src/ui", "\"vectie/moonmoon/src/kernel",
    "\"vectie/moonmoon/src/suite_adapter_preview",
  ]
  for path in robot_catalog_files() {
    let text = read_text(path)
    for term in forbidden {
      assert_not_contains(text, term, path)
    }
  }
  let manifest = read_text("src/robot_catalog/moon.pkg")
  for
    required in [
      "\"vectie/moonmoon/src/data_core\"", "\"vectie/moonmoon/src/data_store\"",
      "\"vectie/moonmoon/src/data_validate\"", "\"vectie/moonmoon/src/robot_data\"",
    ] {
    if !manifest.contains(required) {
      fail("robot_catalog missing required import " + required)
    }
  }
}
