///|
pub(all) struct MoonMoonMoonSuiteProductHome {
  product_id : String
  state_path : String
  service_path : String
  cache_path : String
  tmp_path : String
  accepted_output_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn moonsuite_product_id() -> String {
  "moonmoon"
}

///|
pub fn moonsuite_product_state_path() -> String {
  ".moonsuite/products/moonmoon"
}

///|
pub fn moonsuite_product_service_path() -> String {
  "\{moonsuite_product_state_path()}/service.json"
}

///|
pub fn moonsuite_product_cache_path() -> String {
  "\{moonsuite_product_state_path()}/cache"
}

///|
pub fn moonsuite_product_tmp_path() -> String {
  ".tmp/products/moonmoon"
}

///|
pub fn moonsuite_product_accepted_output_path(
  book_id? : String = "<book-id>",
) -> String {
  "books/\{book_id}/outputs/moonmoon"
}

///|
pub fn moonsuite_product_home(
  book_id? : String = "<book-id>",
) -> MoonMoonMoonSuiteProductHome {
  {
    product_id: moonsuite_product_id(),
    state_path: moonsuite_product_state_path(),
    service_path: moonsuite_product_service_path(),
    cache_path: moonsuite_product_cache_path(),
    tmp_path: moonsuite_product_tmp_path(),
    accepted_output_path: moonsuite_product_accepted_output_path(book_id~),
  }
}
