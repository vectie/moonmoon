///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    0.0 - value
  } else {
    value
  }
}

///|
fn wrapped_index(index : Int, length : Int) -> Int {
  if length <= 0 {
    0
  } else {
    let wrapped = index - index / length * length
    if wrapped < 0 {
      wrapped + length
    } else {
      wrapped
    }
  }
}
