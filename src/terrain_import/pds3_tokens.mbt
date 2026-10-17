///|
// Compare the exact decimal value, before binary floating-point conversion.
// Strip coefficient zeroes and account for the decimal exponent without ever
// rounding, allocating an expanded exponent or overflowing an integer.
fn pds3_exact_integer(
  text : String,
  maximum : Int,
  label : String,
) -> Int raise ImportError {
  let token = text.trim().to_owned()
  let mut i = 0
  let mut negative = false
  if i < token.length() && (token[i] == 43 || token[i] == 45) {
    negative = token[i] == 45
    i += 1
  }
  let digits : Array[Int] = []
  let mut fractional = 0
  while i < token.length() && token[i] >= 48 && token[i] <= 57 {
    digits.push(token[i].to_int() - 48)
    i += 1
  }
  if i < token.length() && token[i] == 46 {
    i += 1
    while i < token.length() && token[i] >= 48 && token[i] <= 57 {
      digits.push(token[i].to_int() - 48)
      fractional += 1
      i += 1
    }
  }
  need(
    !digits.is_empty(),
    label + " requires an exact positive decimal integer",
  )
  let mut exponent = 0
  if i < token.length() && (token[i] == 69 || token[i] == 101) {
    i += 1
    let mut exponent_negative = false
    if i < token.length() && (token[i] == 43 || token[i] == 45) {
      exponent_negative = token[i] == 45
      i += 1
    }
    let start = i
    while i < token.length() && token[i] >= 48 && token[i] <= 57 {
      // Input is bounded to 64 KiB. An exponent beyond 100000 cannot
      // describe a bounded positive integer, regardless of coefficient zeroes.
      exponent = (exponent * 10 + token[i].to_int() - 48).min(100000)
      i += 1
    }
    need(i > start, label + " has an invalid decimal exponent")
    if exponent_negative {
      exponent = -exponent
    }
  }
  need(
    i == token.length() && !negative,
    label + " requires an exact positive decimal integer",
  )
  let mut first = 0
  while first < digits.length() && digits[first] == 0 {
    first += 1
  }
  need(first < digits.length(), label + " must be positive")
  let mut last = digits.length() - 1
  while digits[last] == 0 {
    last -= 1
  }
  let power = exponent - fractional + digits.length() - 1 - last
  need(power >= 0, label + " is fractional before floating-point rounding")
  need(
    last - first + 1 + power <= maximum.to_string().length(),
    label + " exceeds its supported integer range",
  )
  let mut value = 0
  for j in first..<=last {
    value = value * 10 + digits[j]
  }
  for _ in 0..<power {
    value *= 10
  }
  need(value <= maximum, label + " exceeds its supported integer range")
  value
}

///|
fn pds3_json_space(c : UInt16) -> Bool {
  c == 32 || c == 9 || c == 10 || c == 13
}

///|
fn pds3_json_string_end(text : String, start : Int) -> Int raise ImportError {
  need(
    start < text.length() && text[start] == 34,
    "PDS3 declaration requires a quoted key or value",
  )
  let mut i = start + 1
  while i < text.length() {
    if text[i] == 34 {
      return i + 1
    }
    if text[i] == 92 {
      i += 1
    }
    i += 1
  }
  raise InvalidRaster("Unterminated PDS3 declaration JSON string")
}

///|
// The declaration schema is a flat object of string/number scalars. Keep exact
// value tokens and decode each key before checking uniqueness; JSON map parsing
// alone would erase contradictory duplicates and rounded dimension spellings.
fn pds3_declaration_tokens(
  text : String,
) -> Map[String, String] raise ImportError {
  let tokens : Map[String, String] = Map([])
  let mut i = 0
  while i < text.length() && pds3_json_space(text[i]) {
    i += 1
  }
  need(
    i < text.length() && text[i] == 123,
    "PDS3 declaration must be a JSON object",
  )
  i += 1
  while i < text.length() && pds3_json_space(text[i]) {
    i += 1
  }
  if i < text.length() && text[i] == 125 {
    i += 1
  } else {
    while true {
      let key_end = pds3_json_string_end(text, i)
      let key_json = @json.parse(text[i:key_end]) catch {
        _ => raise InvalidRaster("Invalid PDS3 declaration key")
      }
      guard key_json is String(key) else {
        raise InvalidRaster("Invalid PDS3 declaration key")
      }
      need(
        !tokens.contains(key),
        "Duplicate decoded PDS3 declaration key " + key,
      )
      i = key_end
      while i < text.length() && pds3_json_space(text[i]) {
        i += 1
      }
      need(
        i < text.length() && text[i] == 58,
        "PDS3 declaration key needs a colon",
      )
      i += 1
      while i < text.length() && pds3_json_space(text[i]) {
        i += 1
      }
      let start = i
      if i < text.length() && text[i] == 34 {
        i = pds3_json_string_end(text, i)
      } else {
        while i < text.length() && text[i] != 44 && text[i] != 125 {
          need(
            text[i] != 123 && text[i] != 91,
            "PDS3 declaration supports only scalar values",
          )
          i += 1
        }
      }
      let token = text[start:i].trim().to_owned()
      need(!token.is_empty(), "Missing PDS3 declaration value")
      tokens[key] = token
      while i < text.length() && pds3_json_space(text[i]) {
        i += 1
      }
      need(i < text.length(), "Unterminated PDS3 declaration object")
      if text[i] == 125 {
        i += 1
        break
      }
      need(text[i] == 44, "PDS3 declaration members need a comma")
      i += 1
      while i < text.length() && pds3_json_space(text[i]) {
        i += 1
      }
    }
  }
  while i < text.length() && pds3_json_space(text[i]) {
    i += 1
  }
  need(i == text.length(), "Unexpected content after PDS3 declaration")
  tokens
}
