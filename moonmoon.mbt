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
pub fn trusted_square_book_json() -> Json {
  @moonbook.first_trusted_square_book_json()
}

///|
pub fn trusted_square_moonclaw_json() -> Json {
  @moonclaw.first_trusted_square_json()
}

///|
pub fn trusted_square_moonrobo_json() -> Json {
  @moonrobo.first_trusted_square_json()
}
