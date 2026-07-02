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
fn moonsuite_active_workspace_root() -> String {
  "."
}

///|
pub fn moonsuite_product_state_path_for_workspace_root(root : String) -> String {
  @moonsuite.product_dir(
    @moonsuite.suite_root_for_workspace_root(root),
    moonsuite_product_id(),
  )
}

///|
pub fn moonsuite_product_state_path() -> String {
  moonsuite_product_state_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_service_path_for_workspace_root(
  root : String,
) -> String {
  @moonsuite.product_service_path(
    @moonsuite.suite_root_for_workspace_root(root),
    moonsuite_product_id(),
  )
}

///|
pub fn moonsuite_product_service_path() -> String {
  moonsuite_product_service_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_cache_path_for_workspace_root(root : String) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    root,
    moonsuite_product_id(),
    "cache",
  )
}

///|
pub fn moonsuite_product_cache_path() -> String {
  moonsuite_product_cache_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_tmp_path_for_workspace_root(root : String) -> String {
  @moonsuite.product_tmp_dir(
    @moonsuite.suite_root_for_workspace_root(root),
    moonsuite_product_id(),
  )
}

///|
pub fn moonsuite_product_tmp_path() -> String {
  moonsuite_product_tmp_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_accepted_output_path_for_workspace_root(
  root : String,
  book_id? : String = "<book-id>",
) -> String {
  @moonsuite.book_artifact(
    @moonsuite.suite_root_for_workspace_root(root),
    book_id,
    "outputs/\{moonsuite_product_id()}",
  )
}

///|
pub fn moonsuite_product_accepted_output_path(
  book_id? : String = "<book-id>",
) -> String {
  moonsuite_product_accepted_output_path_for_workspace_root(
    moonsuite_active_workspace_root(),
    book_id~,
  )
}

///|
pub fn moonsuite_product_home_for_workspace_root(
  root : String,
  book_id? : String = "<book-id>",
) -> MoonMoonMoonSuiteProductHome {
  {
    product_id: moonsuite_product_id(),
    state_path: moonsuite_product_state_path_for_workspace_root(root),
    service_path: moonsuite_product_service_path_for_workspace_root(root),
    cache_path: moonsuite_product_cache_path_for_workspace_root(root),
    tmp_path: moonsuite_product_tmp_path_for_workspace_root(root),
    accepted_output_path: moonsuite_product_accepted_output_path_for_workspace_root(
      root,
      book_id~,
    ),
  }
}

///|
pub fn moonsuite_product_home(
  book_id? : String = "<book-id>",
) -> MoonMoonMoonSuiteProductHome {
  moonsuite_product_home_for_workspace_root(
    moonsuite_active_workspace_root(),
    book_id~,
  )
}
