///|
pub using @spatial_import {
  type SimulationImportIssue,
  type SimulationSpatialInput,
  ingest_moonmold_simulation,
}

///|
pub fn product_kernel() -> @kernel.MoonMoonKernel {
  @kernel.system_kernel()
}

///|
pub fn product_kernel_markdown() -> String {
  @kernel.system_kernel_markdown()
}

///|
pub fn product_kernel_json() -> Json {
  @kernel.system_kernel_json()
}

///|
pub fn trusted_square_dossier() -> @site.SiteDossier {
  @site.first_trusted_square_dossier()
}

///|
pub fn trusted_square_markdown() -> String {
  @site.first_trusted_square_markdown()
}

///|
pub fn trusted_square_json() -> Json {
  @site.first_trusted_square_json()
}

///|
pub fn trusted_square_view_model() -> @ui.TrustedSquareViewModel {
  @ui.first_trusted_square_view_model()
}

///|
pub fn trusted_square_view_markdown() -> String {
  @ui.first_trusted_square_markdown()
}

///|
pub fn trusted_square_view_json() -> Json {
  @ui.first_trusted_square_json()
}

///|
pub fn trusted_square_html() -> String {
  @ui.first_trusted_square_html()
}
