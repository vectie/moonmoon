///|
let pds_label =
  #|PDS_VERSION_ID = PDS3
  #|RECORD_TYPE = FIXED_LENGTH
  #|RECORD_BYTES = 8
  #|FILE_RECORDS = 3
  #|^IMAGE = "DEMO.IMG"
  #|OBJECT = IMAGE
  #|  LINES = 3
  #|  LINE_SAMPLES = 4
  #|  SAMPLE_TYPE = MSB_INTEGER
  #|  SAMPLE_BITS = 16
  #|  UNIT = METER
  #|  SCALING_FACTOR = 0.5
  #|  OFFSET = 100
  #|  MISSING_CONSTANT = -32768
  #|END_OBJECT = IMAGE
  #|END

///|
let pds_spec =
  #|{"contract_id":"moonmoon.pds3-grid.v1","tile_id":"pds-demo","coordinate_frame":"Synthetic local Cartesian frame","horizontal_unit":"m","source_note":"Synthetic Apache-2.0 fixture, not lunar observations","rows":3,"cols":4,"origin_x":100,"origin_y":200,"cell_size":5,"vertical_quantity":"elevation","vertical_datum":"Synthetic zero-height plane","uncertainty_note":"Synthetic exact codes; no acquired-data accuracy claim","row_order":"top-to-bottom","column_order":"left-to-right"}

///|
fn pds_bytes(values : Array[Int], little? : Bool = false) -> Bytes {
  Bytes::makei(values.length() * 2, i => {
    let v = values[i / 2] & 65535
    (if (i % 2 == 0) != little { v >> 8 } else { v & 255 }).to_byte()
  })
}

///|
let pds_codes : Array[Int] = [-4, 0, 4, 8, 12, -32768, 20, 24, 28, 32, 36, 40]

///|
fn pds_field(value : Json, name : String) -> Json {
  guard value is Object(fields) && fields.get(name) is Some(result) else {
    abort("Missing test field " + name)
  }
  result
}

///|
fn rejects_pds(
  label : String,
  bytes : Bytes,
  spec? : String = pds_spec,
  name? : String = "DEMO.IMG",
) -> Unit raise {
  try @terrain_import.import_pds3_bundle(label, bytes, name, spec) catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected PDS3 refusal")
  }
}

///|
test "PDS3 both endian layouts decode signed words and preserve exact sources" {
  let a = @terrain_import.import_pds3_bundle(
    pds_label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  let b = @terrain_import.import_pds3_bundle(
    pds_label.replace(old="MSB_INTEGER", new="LSB_INTEGER"),
    pds_bytes(pds_codes, little=true),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(a, "samples"), pds_field(b, "samples"))
  assert_eq(pds_field(a, "source_text"), pds_label.to_json())
  assert_eq(pds_field(a, "grid_specification_text"), pds_spec.to_json())
  assert_eq(pds_field(a, "sample_count"), 11)
  assert_eq(pds_field(a, "nodata_count"), 1)
  assert_eq(pds_field(a, "minimum_elevation_m"), 98)
  assert_eq(pds_field(a, "maximum_elevation_m"), 120)
  assert_eq(
    pds_field(a, "image_hex"),
    "fffc000000040008000c800000140018001c002000240028".to_json(),
  )
  assert_eq(
    pds_field(a, "terrain_csv"),
    "tile_id,row,col,elevation_m\npds-demo,0,0,98\npds-demo,0,1,100\npds-demo,0,2,102\npds-demo,0,3,104\npds-demo,1,0,106\npds-demo,1,2,110\npds-demo,1,3,112\npds-demo,2,0,114\npds-demo,2,1,116\npds-demo,2,2,118\npds-demo,2,3,120\n".to_json(),
  )
  assert_true(pds_field(a, "source_digest") != pds_field(b, "source_digest"))
  assert_eq(@terrain_import.reopen_bundle(a.stringify(indent=2)), a)
  assert_eq(@terrain_import.reopen_bundle(b.stringify()), b)
}

///|
test "PDS3 signed endpoints remain values unless a special code declares otherwise" {
  let label = pds_label
    .replace(old="  MISSING_CONSTANT = -32768\n", new="")
    .replace(old="SCALING_FACTOR = 0.5", new="SCALING_FACTOR = 1")
    .replace(old="OFFSET = 100", new="OFFSET = 0")
  let a = @terrain_import.import_pds3_bundle(
    label,
    pds_bytes([-32768, 32767, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8]),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(a, "minimum_elevation_m"), (-32768).to_json())
  assert_eq(pds_field(a, "maximum_elevation_m"), 32767)
  assert_eq(pds_field(a, "nodata_count"), 0)
}

///|
test "PDS3 missing and invalid constants are withheld before scaling" {
  let label = pds_label.replace(
    old="END_OBJECT = IMAGE",
    new="INVALID_CONSTANT = 0\nEND_OBJECT = IMAGE",
  )
  let bundle = @terrain_import.import_pds3_bundle(
    label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(bundle, "nodata_count"), 2)
  guard pds_field(bundle, "decoded_samples_csv") is String(csv) else {
    fail("CSV")
  }
  assert_true(csv.contains("0,1,0,,invalid-constant"))
  assert_true(csv.contains("1,1,-32768,,missing-constant"))
  let empty = @terrain_import.import_pds3_bundle(
    pds_label,
    pds_bytes(Array::make(12, -32768)),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(empty, "sample_count"), 0)
  assert_eq(pds_field(empty, "minimum_elevation_m"), Json::null())
}

///|
test "PDS3 negative scale applies literally without reordering or guessed datum" {
  let bundle = @terrain_import.import_pds3_bundle(
    pds_label.replace(old="SCALING_FACTOR = 0.5", new="SCALING_FACTOR = -0.5"),
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(bundle, "minimum_elevation_m"), 80)
  assert_eq(pds_field(bundle, "maximum_elevation_m"), 102)
}

///|
test "PDS3 retained sources feed editing analysis contour crop and mesh consumers" {
  let original = @terrain_import.import_pds3_bundle(
    pds_label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  let revised = @terrain_import.revise_bundle(
    original.stringify(),
    "row,col,expected_elevation_m,elevation_m\n1,1,unknown,108\n",
    "Synthetic declared gap replacement",
  )
  assert_eq(pds_field(revised, "base_source_bundle"), original)
  assert_eq(pds_field(revised, "sample_count"), 12)
  assert_eq(@terrain_import.reopen_bundle(revised.stringify()), revised)
  let analysis = @terrain_import.analyze_bundle(
    revised.stringify(),
    "row",
    1,
    70.0,
  )
  assert_eq(pds_field(analysis, "source_bundle"), revised)
  let contours = @terrain_import.contour_bundle(revised.stringify(), [
    105.0, 110.0, 115.0,
  ])
  assert_eq(pds_field(contours, "source_bundle"), revised)
  let mesh = @terrain_import.export_mesh_bundle(revised.stringify())
  assert_eq(pds_field(mesh, "source_bundle"), revised)
  let clip = @terrain_import.crop_bundle(
    revised.stringify(),
    0,
    0,
    3,
    4,
    "exchange",
    "Portable full-grid export",
  )
  let imported = pds_field(clip, "terrain_bundle")
  assert_eq(pds_field(imported, "samples"), pds_field(revised, "samples"))
  assert_eq(pds_field(original, "nodata_count"), 1)
}

///|
test "PDS3 declaration binds dimensions frame units datum quantity orientation and uncertainty" {
  for
    (old, replacement) in [
      ("\"rows\":3", "\"rows\":2"),
      ("\"cols\":4", "\"cols\":3"),
      ("\"cell_size\":5", "\"cell_size\":0"),
      ("\"origin_x\":100", "\"origin_x\":1e300"),
      ("\"m\"", "\"feet\""),
      ("\"elevation\"", "\"radius\""),
      ("Synthetic zero-height plane", ""),
      ("Synthetic local Cartesian frame", ""),
      ("Synthetic exact codes; no acquired-data accuracy claim", ""),
      ("top-to-bottom", "bottom-to-top"),
      ("left-to-right", "right-to-left"),
      ("moonmoon.pds3-grid.v1", "moonmoon.xyz-grid.v1"),
    ] {
    rejects_pds(
      pds_label,
      pds_bytes(pds_codes),
      spec=pds_spec.replace(old~, new=replacement),
    )
  }
  rejects_pds(pds_label, pds_bytes(pds_codes), spec="{}")
  rejects_pds(
    pds_label,
    pds_bytes(pds_codes),
    spec=pds_spec.replace(old="\"rows\":3", new="\"invented\":1,\"rows\":3"),
  )
}

///|
test "PDS3 degree source remains inspectable but cannot enter metre analysis" {
  let bundle = @terrain_import.import_pds3_bundle(
    pds_label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec.replace(old="\"m\"", new="\"degrees\""),
  )
  assert_eq(@terrain_import.reopen_bundle(bundle.stringify()), bundle)
  try @terrain_import.analyze_bundle(bundle.stringify(), "row", 0, 10.0) catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected metric refusal")
  }
  try @terrain_import.export_mesh_bundle(bundle.stringify()) catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected mesh refusal")
  }
}

///|
test "PDS3 refuses unsupported encodings padding bands masks and special codes" {
  for
    (old, replacement) in [
      ("MSB_INTEGER", "MSB_UNSIGNED_INTEGER"),
      ("MSB_INTEGER", "IEEE_REAL"),
      ("SAMPLE_BITS = 16", "SAMPLE_BITS = 32"),
      ("UNIT = METER", "UNIT = KILOMETER"),
      ("FIXED_LENGTH", "STREAM"),
      ("RECORD_BYTES = 8", "RECORD_BYTES = 10"),
      ("FILE_RECORDS = 3", "FILE_RECORDS = 4"),
      ("MISSING_CONSTANT = -32768", "MISSING_CONSTANT = 32768"),
      ("MISSING_CONSTANT = -32768", "MISSING_CONSTANT = 16#8000#"),
    ] {
    rejects_pds(pds_label.replace(old~, new=replacement), pds_bytes(pds_codes))
  }
  for
    field in [
      "BANDS = 2", "LINE_PREFIX_BYTES = 2", "LINE_SUFFIX_BYTES = 2", "ENCODING_TYPE = HUFFMAN_FIRST_DIFFERENCE",
      "SAMPLE_BIT_MASK = 2#0111111111111111#", "VALID_MINIMUM = -100", "SATURATION_CONSTANT = 32767",
    ] {
    rejects_pds(
      pds_label.replace(
        old="END_OBJECT = IMAGE",
        new=field + "\nEND_OBJECT = IMAGE",
      ),
      pds_bytes(pds_codes),
    )
  }
}

///|
test "PDS3 accepts explicit supported single-band layout declarations" {
  let label = pds_label.replace(
    old="END_OBJECT = IMAGE",
    new="BANDS = 1\nBAND_STORAGE_TYPE = BAND_SEQUENTIAL\nLINE_PREFIX_BYTES = 0\nLINE_SUFFIX_BYTES = 0\nENCODING_TYPE = N/A\nSAMPLE_BIT_MASK = 2#1111111111111111#\nEND_OBJECT = IMAGE",
  )
  let bundle = @terrain_import.import_pds3_bundle(
    label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(bundle, "sample_count"), 11)
}

///|
test "PDS3 refuses attached offset directory mismatched and unquoted pointers" {
  for
    pointer in [
      "1", "(\"DEMO.IMG\", 1)", "(\"DEMO.IMG\", 1 <BYTES>)", "\"../DEMO.IMG\"", "\"OTHER.IMG\"",
      "DEMO.IMG", "\"SOURCE.LBL\"", "\"demo.img\"",
    ] {
    rejects_pds(
      pds_label.replace(old="\"DEMO.IMG\"", new=pointer),
      pds_bytes(pds_codes),
    )
  }
  rejects_pds(pds_label, pds_bytes(pds_codes), name="OTHER.IMG")
}

///|
test "PDS3 rejects truncated extra data oversized grids and incomplete labels" {
  rejects_pds(pds_label, b"")
  rejects_pds(pds_label, pds_bytes([1, 2]))
  rejects_pds(pds_label, pds_bytes(pds_codes + [1]))
  rejects_pds(
    pds_label.replace(old="LINES = 3", new="LINES = 4096"),
    pds_bytes(pds_codes),
  )
  for
    label in [
      "",
      pds_label + "\nEXTRA = 1",
      pds_label.replace(old="END_OBJECT = IMAGE", new="END_OBJECT = TABLE"),
      pds_label.replace(
        old="PDS_VERSION_ID = PDS3",
        new="PDS_VERSION_ID = PDS4",
      ),
      pds_label.replace(
        old="SAMPLE_BITS = 16",
        new="SAMPLE_BITS = 16\nSAMPLE_BITS = 16",
      ),
      pds_label.replace(old="OBJECT = IMAGE", new="OBJECT = TABLE"),
      pds_label.replace(old="OFFSET = 100", new="OFFSET = 100\nOBJECT = IMAGE"),
      pds_label.replace(old="\nEND", new=""),
      pds_label + "\n/* unterminated",
    ] {
    rejects_pds(label, pds_bytes(pds_codes))
  }
}

///|
test "PDS3 parses comments and CRLF while retaining raw label bytes" {
  let label = ("/* two-line\ncomment */\n" +
  pds_label.replace(
    old="OFFSET = 100",
    new="OFFSET = 100 /* metres */\nNOTE = \"literal /* text */ and = text\"",
  )).replace(old="\n", new="\r\n")
  let bundle = @terrain_import.import_pds3_bundle(
    label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  assert_eq(pds_field(bundle, "source_text"), label.to_json())
  assert_eq(pds_field(bundle, "sample_count"), 11)
  rejects_pds(
    pds_label.replace(old="UNIT = METER", new="UNIT = \"METER\nMETER\""),
    pds_bytes(pds_codes),
  )
}

///|
test "PDS3 rejects nonfinite zero and overflowed scale arithmetic" {
  for scale in ["0", "nan", "1e999", "1e308"] {
    rejects_pds(
      pds_label.replace(
        old="SCALING_FACTOR = 0.5",
        new="SCALING_FACTOR = " + scale,
      ),
      pds_bytes(pds_codes),
    )
  }
  rejects_pds(
    pds_label.replace(old="OFFSET = 100", new="OFFSET = inf"),
    pds_bytes(pds_codes),
  )
  rejects_pds(
    pds_label
    .replace(old="SCALING_FACTOR = 0.5", new="SCALING_FACTOR = 1e307")
    .replace(old="OFFSET = 100", new="OFFSET = 1e308"),
    pds_bytes(Array::make(12, 8)),
  )
}

///|
test "PDS3 reopening recomputes bytes declaration report and every exported field" {
  let original = @terrain_import.import_pds3_bundle(
    pds_label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    pds_spec,
  )
  for
    (key, replacement) in [
      ("image_hex", "fffz".to_json()),
      ("image_hex", "0".to_json()),
      ("source_digest", "sha256:changed".to_json()),
      ("image_name", "OTHER.IMG".to_json()),
      (
        "grid_specification_text",
        pds_spec
        .replace(old="\"origin_x\":100", new="\"origin_x\":101")
        .to_json(),
      ),
      (
        "source_text",
        pds_label.replace(old="OFFSET = 100", new="OFFSET = 0").to_json(),
      ),
      ("sample_count", (12).to_json()),
      ("physical_readiness", true.to_json()),
      ("import_report_markdown", "fabricated".to_json()),
      ("decoded_samples_csv", "fabricated".to_json()),
    ] {
    let changed = @json.parse(original.stringify())
    guard changed is Object(fields) else { fail("object") }
    fields[key] = replacement
    assert_true(
      @terrain_import.reopen_json(changed.stringify()).contains("\"ok\":false"),
    )
  }
}

///|
test "PDS3 integer counts reject exact fractional tokens that round to integers" {
  for
    (field, before, bad) in [
      ("RECORD_BYTES", "8", "8.0000000000000001"),
      ("RECORD_BYTES", "8", "7.99999999999999999"),
      ("RECORD_BYTES", "8", "80000000000000001e-16"),
      ("FILE_RECORDS", "3", "2.99999999999999999"),
      ("FILE_RECORDS", "3", "3.0000000000000001"),
      ("FILE_RECORDS", "3", "30000000000000001e-16"),
      ("LINES", "3", "3.0000000000000001"),
      ("LINE_SAMPLES", "4", "3.99999999999999999"),
    ] {
    rejects_pds(
      pds_label.replace(old=field + " = " + before, new=field + " = " + bad),
      pds_bytes(pds_codes),
    )
  }
  for
    (key, before, bad) in [
      ("rows", "3", "3.0000000000000001"),
      ("rows", "3", "2.99999999999999999"),
      ("rows", "3", "30000000000000001e-16"),
      ("cols", "4", "3.99999999999999999"),
      ("cols", "4", "4.0000000000000001"),
      ("cols", "4", "399999999999999999e-17"),
    ] {
    rejects_pds(
      pds_label,
      pds_bytes(pds_codes),
      spec=pds_spec.replace(
        old="\"" + key + "\":" + before,
        new="\"" + key + "\":" + bad,
      ),
    )
  }
}

///|
test "PDS3 preserves mathematically integral decimal and exponent count forms" {
  for
    (bytes_token, records_token, rows_token, cols_token) in [
      ("8.0000000000000000", "3.00000000000000000", "3.0", "4.000"),
      ("80e-1", "0.03e2", "300e-2", "0.04e2"),
      ("+8E+0", "30E-1", "3e+0", "40e-1"),
      (
        "800000000000000000000e-20", "300000000000000000000e-20", "300000000000000000000e-20",
        "400000000000000000000e-20",
      ),
    ] {
    let label = pds_label
      .replace(old="RECORD_BYTES = 8", new="RECORD_BYTES = " + bytes_token)
      .replace(old="FILE_RECORDS = 3", new="FILE_RECORDS = " + records_token)
    let spec = pds_spec
      .replace(old="\"rows\":3", new="\"rows\":" + rows_token)
      .replace(old="\"cols\":4", new="\"cols\":" + cols_token)
    let bundle = @terrain_import.import_pds3_bundle(
      label,
      pds_bytes(pds_codes),
      "DEMO.IMG",
      spec,
    )
    assert_eq(pds_field(bundle, "sample_count"), 11)
    assert_eq(@terrain_import.reopen_bundle(bundle.stringify()), bundle)
  }
}

///|
test "PDS3 integer token checks remain bounded for huge exponents and zeroes" {
  for
    token in [
      "0", "0e999999999999999999999", "-3", "3e999999999999999999999999", "3e-999999999999999999999999",
      "300e-3", "3.1", "3e", "3e+", "3e0garbage",
    ] {
    rejects_pds(
      pds_label.replace(old="FILE_RECORDS = 3", new="FILE_RECORDS = " + token),
      pds_bytes(pds_codes),
    )
  }
}

///|
test "PDS3 duplicate decoded declaration keys reject contradictions and identical values" {
  for
    (before, after) in [
      ("\"rows\":3", "\"rows\":4,\"rows\":3"),
      ("\"rows\":3", "\"rows\":3,\"rows\":3"),
      ("\"rows\":3", "\"r\\u006fws\":4,\"rows\":3"),
      ("\"rows\":3", "\"rows\":4,\"\\u0072ows\":3"),
      (
        "\"vertical_quantity\":\"elevation\"", "\"vertical_quantity\":\"radius\",\"vertical_quantity\":\"elevation\"",
      ),
      (
        "\"vertical_quantity\":\"elevation\"", "\"vertical_qu\\u0061ntity\":\"radius\",\"vertical_quantity\":\"elevation\"",
      ),
      (
        "\"horizontal_unit\":\"m\"", "\"horizontal_unit\":\"degrees\",\"horizontal_unit\":\"m\"",
      ),
    ] {
    rejects_pds(
      pds_label,
      pds_bytes(pds_codes),
      spec=pds_spec.replace(old=before, new=after),
    )
  }
}

///|
test "PDS3 declaration scanner respects JSON string content and escaped unique keys" {
  let spec = pds_spec
    .replace(old="\"rows\":3", new="\"r\\u006fws\":3")
    .replace(
      old="Synthetic Apache-2.0 fixture, not lunar observations",
      new="Quoted \\\"rows\\\":4, \\\"rows\\\":3, braces {} and escaped \\\\ slash",
    )
  let bundle = @terrain_import.import_pds3_bundle(
    pds_label,
    pds_bytes(pds_codes),
    "DEMO.IMG",
    spec,
  )
  assert_eq(pds_field(bundle, "sample_count"), 11)
  assert_eq(@terrain_import.reopen_bundle(bundle.stringify()), bundle)
  for
    invalid in [
      pds_spec + "{}",
      pds_spec.replace(old="\"rows\":3", new="\"rows\":{\"rows\":3}"),
      pds_spec.replace(old="\"rows\":3", new="\"rows\":[3]"),
      pds_spec.replace(old="\"rows\":3", new="\"rows\" 3"),
      pds_spec.replace(old="\"rows\":3", new="\"rows\":\"3\""),
      pds_spec.replace(old="\"rows\":3,", new="\"rows\":3,,"),
    ] {
    rejects_pds(pds_label, pds_bytes(pds_codes), spec=invalid)
  }
}

///|
test "PDS3 validates every adjacent center on both axes beyond endpoint checks" {
  for key in ["origin_x", "origin_y"] {
    let old = if key == "origin_x" { "100" } else { "200" }
    let collapsed = pds_spec
      .replace(
        old="\"" + key + "\":" + old,
        new="\"" + key + "\":10000000000000000",
      )
      .replace(old="\"cell_size\":5", new="\"cell_size\":1.1")
    rejects_pds(pds_label, pds_bytes(pds_codes), spec=collapsed)
    let valid = collapsed.replace(
      old="\"cell_size\":1.1",
      new="\"cell_size\":2",
    )
    let bundle = @terrain_import.import_pds3_bundle(
      pds_label,
      pds_bytes(pds_codes),
      "DEMO.IMG",
      valid,
    )
    assert_eq(pds_field(bundle, "sample_count"), 11)
    assert_eq(@terrain_import.reopen_bundle(bundle.stringify()), bundle)
  }
}
