///|
fn le_i32(data : Bytes, offset : Int) -> Int {
  data[offset].to_int() |
  (data[offset + 1].to_int() << 8) |
  (data[offset + 2].to_int() << 16) |
  (data[offset + 3].to_int() << 24)
}

///|
fn le_f64(data : Bytes, offset : Int) -> Double {
  let mut bits = 0UL
  for index in 0..<8 {
    bits = bits | (data[offset + index].to_int().to_uint64() << (index * 8))
  }
  bits.reinterpret_as_double()
}

///|
fn supported_target(target : Int) -> Bool {
  target == 3 || target == 10 || target == 301
}

///|
fn parse_segment(data : Bytes, summary_offset : Int) -> SpkSegment? {
  let target = le_i32(data, summary_offset + 16)
  let data_type = le_i32(data, summary_offset + 28)
  if data_type != 2 || !supported_target(target) {
    return None
  }
  let end_address = le_i32(data, summary_offset + 36)
  Some({
    target,
    start_et: le_f64(data, summary_offset),
    end_et: le_f64(data, summary_offset + 8),
    start_address: le_i32(data, summary_offset + 32),
    init_et: le_f64(data, (end_address - 4) * 8),
    interval_length_s: le_f64(data, (end_address - 3) * 8),
    record_size: le_f64(data, (end_address - 2) * 8).to_int(),
    record_count: le_f64(data, (end_address - 1) * 8).to_int(),
  })
}

///|
fn has_spk_header(data : Bytes) -> Bool {
  data.length() >= 1024 &&
  data[0] == b'D' &&
  data[1] == b'A' &&
  data[2] == b'F' &&
  data[3] == b'/' &&
  data[4] == b'S' &&
  data[5] == b'P' &&
  data[6] == b'K'
}

///|
fn parse_de440s(data : Bytes) -> Result[SpkKernel, String] {
  if !has_spk_header(data) {
    return Err("input is not a DAF/SPK kernel")
  }
  if le_i32(data, 8) != 2 || le_i32(data, 12) != 6 {
    return Err("unsupported DAF summary layout")
  }
  let segments : Array[SpkSegment] = []
  let mut summary_record = le_i32(data, 76)
  while summary_record != 0 {
    let record_offset = (summary_record - 1) * 1024
    if record_offset < 0 || record_offset + 1024 > data.length() {
      return Err("DAF summary record is outside the kernel")
    }
    let next_record = le_f64(data, record_offset).to_int()
    let summary_count = le_f64(data, record_offset + 16).to_int()
    for index in 0..<summary_count {
      match parse_segment(data, record_offset + 24 + index * 40) {
        Some(segment) => segments.push(segment)
        None => ()
      }
    }
    summary_record = next_record
  }
  for target in [3, 10, 301] {
    if !segments.any(fn(segment) { segment.target == target }) {
      return Err("kernel is missing required target \{target}")
    }
  }
  Ok({ data, segments })
}

///|
fn SpkKernel::segment_at(
  self : SpkKernel,
  target : Int,
  ephemeris_time_s : Double,
) -> SpkSegment {
  for segment in self.segments {
    if segment.target == target &&
      ephemeris_time_s >= segment.start_et &&
      ephemeris_time_s <= segment.end_et {
      return segment
    }
  }
  abort("DE440s has no target \{target} segment at ET \{ephemeris_time_s}")
}

///|
fn chebyshev_axis(
  data : Bytes,
  record_offset : Int,
  coefficient_count : Int,
  axis : Int,
  x : Double,
) -> Double {
  let coefficient_offset = record_offset + (2 + axis * coefficient_count) * 8
  let mut b0 = 0.0
  let mut b1 = 0.0
  for reverse_offset in 1..<coefficient_count {
    let index = coefficient_count - reverse_offset
    let coefficient = le_f64(data, coefficient_offset + index * 8)
    let next = 2.0 * x * b0 - b1 + coefficient
    b1 = b0
    b0 = next
  }
  x * b0 - b1 + le_f64(data, coefficient_offset)
}

///|
fn SpkKernel::position(
  self : SpkKernel,
  target : Int,
  ephemeris_time_s : Double,
) -> Vector3 {
  let segment = self.segment_at(target, ephemeris_time_s)
  let raw_index = ((ephemeris_time_s - segment.init_et) /
    segment.interval_length_s)
    .floor()
    .to_int()
  let record_index = if raw_index < 0 {
    0
  } else if raw_index >= segment.record_count {
    segment.record_count - 1
  } else {
    raw_index
  }
  let record_address = segment.start_address +
    record_index * segment.record_size
  let record_offset = (record_address - 1) * 8
  let midpoint = le_f64(self.data, record_offset)
  let radius = le_f64(self.data, record_offset + 8)
  let x = (ephemeris_time_s - midpoint) / radius
  let coefficient_count = (segment.record_size - 2) / 3
  {
    x: chebyshev_axis(self.data, record_offset, coefficient_count, 0, x),
    y: chebyshev_axis(self.data, record_offset, coefficient_count, 1, x),
    z: chebyshev_axis(self.data, record_offset, coefficient_count, 2, x),
  }
}
