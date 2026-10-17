# Detached PDS3 elevation import

This bounded profile imports local signed-16-bit images into the same terrain
editing and analysis APIs as ASCII and XYZ sources. It never infers a map
projection or subtracts a planetary reference radius. The declaration affirms
that the scaled quantity is elevation in metres and names its vertical datum.

```mbt check
///|
test "PDS3 literal conversion and replay" {
  let label = "PDS_VERSION_ID = PDS3\nRECORD_TYPE = FIXED_LENGTH\nRECORD_BYTES = 2\nFILE_RECORDS = 1\n^IMAGE = \"ONE.IMG\"\nOBJECT = IMAGE\nLINES = 1\nLINE_SAMPLES = 1\nSAMPLE_TYPE = MSB_INTEGER\nSAMPLE_BITS = 16\nUNIT = METER\nSCALING_FACTOR = 0.5\nOFFSET = 100\nEND_OBJECT = IMAGE\nEND\n"
  let declaration =
    #|{"contract_id":"moonmoon.pds3-grid.v1","tile_id":"one","coordinate_frame":"Synthetic Cartesian","horizontal_unit":"m","source_note":"Synthetic example only","rows":1,"cols":1,"origin_x":0,"origin_y":0,"cell_size":1,"vertical_quantity":"elevation","vertical_datum":"Synthetic zero plane","uncertainty_note":"No external data quality claim","row_order":"top-to-bottom","column_order":"left-to-right"}
  let image : Bytes = [0xff, 0xfc] // signed -4, not unsigned 65532
  let bundle = @terrain_import.import_pds3_bundle(
    label, image, "ONE.IMG", declaration,
  )
  guard bundle is Object(fields) else { fail("Expected bundle") }
  assert_eq(fields.get("minimum_elevation_m"), Some((98).to_json()))
  assert_eq(@terrain_import.reopen_bundle(bundle.stringify()), bundle)
}
```

See `docs/PDS3_IMPORT.md` for the complete local file journey, supported label
fields, raw-byte examples, failure states and primary standards references.
