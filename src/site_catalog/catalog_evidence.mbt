///|
fn source_evidence(
  source : @lunar_catalog.CatalogedLunarSource,
) -> @site.SiteCatalogEvidence {
  {
    artifact: source.artifact,
    authority: source.authority,
    label: source.label,
    source_url: source.source_url,
    ref_uris: source.source_ref_uris,
    linked_source_ids: [source.source_id],
  }
}

///|
fn dataset_evidence(
  dataset : @lunar_catalog.CatalogedLunarDataset,
) -> @site.SiteCatalogEvidence {
  {
    artifact: dataset.artifact,
    authority: dataset.authority,
    label: dataset.artifact.summary,
    source_url: dataset.source_url,
    ref_uris: dataset.data_ref_uris,
    linked_source_ids: dataset.source_ids,
  }
}

///|
fn validation_evidence(
  validation : @lunar_catalog.CatalogedLunarValidation,
) -> @site.SiteCatalogValidationEvidence {
  {
    artifact: validation.artifact,
    validation_status: validation.validation_status,
    ready: validation.ready,
    finding_count: validation.finding_count,
    blocker_count: validation.blocker_count,
    warning_count: validation.warning_count,
    summary: validation.summary,
  }
}

///|
pub fn first_trusted_square_catalog_evidence_from_root(
  root : String,
) -> Result[Array[@site.SiteCatalogEvidence], @data_store.DataStoreIssue] {
  let sources = match
    @lunar_catalog.first_trusted_square_catalog_sources(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let datasets = match
    @lunar_catalog.first_trusted_square_catalog_datasets(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(sources.map(source_evidence) + datasets.map(dataset_evidence))
}

///|
pub fn first_trusted_square_catalog_validation_from_root(
  root : String,
) -> Result[@site.SiteCatalogValidationEvidence, @data_store.DataStoreIssue] {
  match @lunar_catalog.first_trusted_square_catalog_validation(root) {
    Ok(value) => Ok(validation_evidence(value))
    Err(error) => Err(error)
  }
}

///|
pub fn first_trusted_square_dossier_from_catalog_root(
  root : String,
) -> Result[@site.SiteDossier, @data_store.DataStoreIssue] {
  let catalog_evidence = match
    first_trusted_square_catalog_evidence_from_root(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let catalog_validation = match
    first_trusted_square_catalog_validation_from_root(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dossier = @site.first_trusted_square_dossier()
  Ok({
    site: dossier.site,
    datasets: dossier.datasets,
    validations: dossier.validations,
    catalog_evidence,
    catalog_validation,
    source_candidates: dossier.source_candidates,
    source_acquisition_plans: dossier.source_acquisition_plans,
    source_product_selections: dossier.source_product_selections,
    source_extraction_candidates: dossier.source_extraction_candidates,
    terrain: dossier.terrain,
    traverse: dossier.traverse,
    corridor_scan: dossier.corridor_scan,
    route_candidates: dossier.route_candidates,
    power_window_evidence: dossier.power_window_evidence,
    window_search_evidence: dossier.window_search_evidence,
    energy: dossier.energy,
    clearance_plan: dossier.clearance_plan,
    summary: dossier.summary,
    blockers: dossier.blockers,
    next_questions: dossier.next_questions,
  })
}
