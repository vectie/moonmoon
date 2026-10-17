///|
priv struct Pds3Image {
  rows : Int
  cols : Int
  little_endian : Bool
  scale : Double
  offset : Double
  missing : Int?
  invalid : Int?
}

///|
// Comments can span lines; quoted text is never interpreted as a comment.
// Multi-line scalar values and ODL sequences are outside this bounded profile.
fn pds3_uncomment(text : String) -> String raise ImportError {
  need(text.length() <= 65536, "PDS3 label exceeds 64 KiB character limit")
  let out = StringBuilder()
  let mut quoted = false
  let mut comment = false
  let mut i = 0
  while i < text.length() {
    let c = text[i]
    need(
      c < 128 && (c >= 32 || c == 9 || c == 10 || c == 13),
      "PDS3 profile requires ASCII label text",
    )
    if comment {
      if c == 42 && i + 1 < text.length() && text[i + 1] == 47 {
        comment = false
        out.write_string(" ")
        i += 2
      } else {
        if c == 10 {
          out.write_string("\n")
        }
        i += 1
      }
    } else if !quoted && c == 47 && i + 1 < text.length() && text[i + 1] == 42 {
      comment = true
      out.write_string(" ")
      i += 2
    } else {
      if c == 34 {
        quoted = !quoted
      }
      need(
        !(quoted && (c == 10 || c == 13)),
        "PDS3 profile does not support multi-line quoted values",
      )
      out.write_string(text[i:i + 1].to_owned())
      i += 1
    }
  }
  need(!comment && !quoted, "Unterminated PDS3 comment or quoted value")
  out.to_string()
}

///|
fn pds3_scalar(value : String) -> String raise ImportError {
  if value.has_prefix("\"") {
    need(
      value.length() >= 2 && value.has_suffix("\""),
      "Invalid PDS3 quoted scalar",
    )
    let inner = value[1:value.length() - 1].to_owned()
    need(!inner.contains("\""), "PDS3 profile does not support embedded quotes")
    inner
  } else {
    need(!value.is_empty() && !value.contains("\""), "Invalid PDS3 scalar")
    value
  }
}

///|
fn pds3_label(
  text : String,
  image_name : String,
) -> Pds3Image raise ImportError {
  let root : Map[String, String] = Map([])
  let image : Map[String, String] = Map([])
  let mut in_image = false
  let mut seen_image = false
  let mut ended = false
  for raw in pds3_uncomment(text).split("\n") {
    let line = raw.trim().to_owned()
    if line.is_empty() {
      continue
    }
    need(!ended, "PDS3 content after END is unsupported")
    if line == "END" {
      need(!in_image && seen_image, "PDS3 END needs one closed IMAGE object")
      ended = true
      continue
    }
    guard line.find("=") is Some(equals) else {
      raise InvalidRaster(
        "PDS3 profile requires one scalar assignment per line",
      )
    }
    let key = line[:equals].trim().to_owned()
    if key == "^IMAGE" {
      need(
        line[equals + 1:].trim().has_prefix("\""),
        "PDS3 detached pointer must be a quoted filename",
      )
    }
    let value = pds3_scalar(line[equals + 1:].trim().to_owned())
    if key == "OBJECT" {
      need(
        value == "IMAGE" && !in_image && !seen_image,
        "PDS3 profile supports exactly one IMAGE object and no other objects",
      )
      in_image = true
      seen_image = true
    } else if key == "END_OBJECT" {
      need(value == "IMAGE" && in_image, "Mismatched PDS3 END_OBJECT")
      in_image = false
    } else {
      let allowed = if in_image {
        [
          "LINES", "LINE_SAMPLES", "SAMPLE_TYPE", "SAMPLE_BITS", "BANDS", "BAND_STORAGE_TYPE",
          "UNIT", "SCALING_FACTOR", "OFFSET", "MISSING_CONSTANT", "INVALID_CONSTANT",
          "LINE_PREFIX_BYTES", "LINE_SUFFIX_BYTES", "ENCODING_TYPE", "SAMPLE_BIT_MASK",
          "MINIMUM", "MAXIMUM", "DERIVED_MINIMUM", "DERIVED_MAXIMUM", "DESCRIPTION",
          "NOTE",
        ]
      } else {
        [
          "PDS_VERSION_ID", "RECORD_TYPE", "RECORD_BYTES", "FILE_RECORDS", "^IMAGE",
          "DATA_SET_ID", "PRODUCT_ID", "TARGET_NAME", "INSTRUMENT_HOST_NAME", "INSTRUMENT_HOST_ID",
          "INSTRUMENT_NAME", "INSTRUMENT_ID", "PRODUCT_CREATION_TIME", "DESCRIPTION",
          "NOTE",
        ]
      }
      need(allowed.contains(key), "Unsupported PDS3 profile field " + key)
      let fields = if in_image { image } else { root }
      need(!fields.contains(key), "Duplicate PDS3 field " + key)
      fields[key] = value
    }
  }
  need(ended && seen_image && !in_image, "Incomplete PDS3 label")
  fn required(
    fields : Map[String, String],
    key : String,
  ) -> String raise ImportError {
    guard fields.get(key) is Some(value) else {
      raise InvalidRaster("Missing PDS3 field " + key)
    }
    value
  }
  need(
    required(root, "PDS_VERSION_ID") == "PDS3",
    "Expected PDS_VERSION_ID = PDS3",
  )
  need(
    required(root, "RECORD_TYPE") == "FIXED_LENGTH",
    "PDS3 profile requires FIXED_LENGTH records",
  )
  let pointer = required(root, "^IMAGE")
  need(
    pointer == image_name &&
    pointer.length() > 4 &&
    pointer.length() <= 128 &&
    !pointer.has_prefix(".") &&
    pointer.has_suffix(".IMG"),
    "PDS3 detached .IMG filename must match the supplied image filename",
  )
  for c in pointer {
    need(
      (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '.',
      "PDS3 detached pointer must be an uppercase simple filename, without offsets or directories",
    )
  }
  let rows = dimension(required(image, "LINES"), "PDS3 LINES")
  let cols = dimension(required(image, "LINE_SAMPLES"), "PDS3 LINE_SAMPLES")
  need(
    rows * cols <= 4096,
    "PDS3 profile supports at most 4096 cells; supply a bounded clip",
  )
  need(
    pds3_exact_integer(
      required(root, "RECORD_BYTES"),
      8192,
      "PDS3 RECORD_BYTES",
    ) ==
    cols * 2,
    "PDS3 RECORD_BYTES must equal two bytes per sample with no padding",
  )
  need(
    pds3_exact_integer(
      required(root, "FILE_RECORDS"),
      4096,
      "PDS3 FILE_RECORDS",
    ) ==
    rows,
    "PDS3 FILE_RECORDS must equal LINES",
  )
  let sample_type = required(image, "SAMPLE_TYPE")
  need(
    sample_type == "MSB_INTEGER" || sample_type == "LSB_INTEGER",
    "PDS3 profile supports only MSB_INTEGER or LSB_INTEGER",
  )
  need(
    required(image, "SAMPLE_BITS") == "16",
    "PDS3 profile requires SAMPLE_BITS = 16",
  )
  need(
    required(image, "UNIT") == "METER",
    "PDS3 scaled values must use UNIT = METER",
  )
  for
    (key, expected) in [
      ("BANDS", "1"),
      ("BAND_STORAGE_TYPE", "BAND_SEQUENTIAL"),
      ("LINE_PREFIX_BYTES", "0"),
      ("LINE_SUFFIX_BYTES", "0"),
      ("ENCODING_TYPE", "N/A"),
      ("SAMPLE_BIT_MASK", "2#1111111111111111#"),
    ] {
    if image.get(key) is Some(value) {
      need(value == expected, "Unsupported PDS3 " + key)
    }
  }
  fn missing_code(key : String) -> Int? raise ImportError {
    match image.get(key) {
      None => None
      Some(value) => {
        let parsed = @string.parse_int(value) catch {
          _ =>
            raise InvalidRaster(
              "PDS3 " + key + " requires a signed decimal integer",
            )
        }
        need(
          parsed >= -32768 && parsed <= 32767,
          "PDS3 " + key + " is outside signed 16-bit range",
        )
        Some(parsed)
      }
    }
  }
  let scale = number(required(image, "SCALING_FACTOR"), "PDS3 SCALING_FACTOR")
  need(scale != 0.0, "PDS3 SCALING_FACTOR must be nonzero")
  {
    rows,
    cols,
    little_endian: sample_type == "LSB_INTEGER",
    scale,
    offset: number(required(image, "OFFSET"), "PDS3 OFFSET"),
    missing: missing_code("MISSING_CONSTANT"),
    invalid: missing_code("INVALID_CONSTANT"),
  }
}
