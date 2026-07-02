///|
pub(all) struct CatalogedLunarSource {
  source_id : String
  authority : String
  label : String
  source_ref_count : Int
  source_ref_uris : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CatalogedLunarDataset {
  dataset_id : String
  kind : String
  status : @data_core.DataStatus
  source_ids : Array[String]
  data_ref_count : Int
  data_ref_uris : Array[String]
  coverage : @lunar_data.LunarCoverage
} derive(Debug, Eq, ToJson, FromJson)

///|
fn ref_uris(refs : Array[@data_core.DataRef]) -> Array[String] {
  refs.map(fn(data_ref) { data_ref.uri })
}

///|
fn catalog_contains(
  catalog : @data_core.DataCatalog,
  artifact_kind : String,
  artifact_id : String,
) -> Bool {
  for entry in catalog.entries {
    if entry.artifact_kind == artifact_kind && entry.artifact_id == artifact_id {
      return true
    }
  }
  false
}

///|
pub fn first_trusted_square_catalog_sources(
  root : String,
) -> Result[Array[CatalogedLunarSource], @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rows : Array[CatalogedLunarSource] = []
  for source in @lunar_data.first_trusted_square_lunar_sources() {
    if catalog_contains(catalog, "source", source.source_id) {
      let stored = match @data_store.read_source(root, source.source_id) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      rows.push({
        source_id: stored.source_id,
        authority: stored.authority,
        label: stored.label,
        source_ref_count: stored.source_refs.length(),
        source_ref_uris: ref_uris(stored.source_refs),
      })
    }
  }
  Ok(rows)
}

///|
fn dataset_coverage(dataset_id : String) -> @lunar_data.LunarCoverage {
  if dataset_id == @lunar_data.first_trusted_square_lola_dataset().dataset_id {
    @lunar_data.first_trusted_square_lola_extraction_candidate().coverage
  } else if dataset_id ==
    @lunar_data.first_trusted_square_ephemeris_dataset().dataset_id {
    @lunar_data.first_trusted_square_ephemeris_window().coverage
  } else {
    @lunar_data.first_trusted_square_tile_manifest().coverage
  }
}

///|
pub fn first_trusted_square_catalog_datasets(
  root : String,
) -> Result[Array[CatalogedLunarDataset], @data_store.DataStoreIssue] {
  let catalog = match @data_store.read_catalog(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rows : Array[CatalogedLunarDataset] = []
  for dataset in @lunar_data.first_trusted_square_lunar_datasets() {
    if catalog_contains(catalog, "dataset", dataset.dataset_id) {
      let stored = match @data_store.read_dataset(root, dataset.dataset_id) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      rows.push({
        dataset_id: stored.dataset_id,
        kind: stored.kind,
        status: stored.status,
        source_ids: stored.source_ids,
        data_ref_count: stored.data_refs.length(),
        data_ref_uris: ref_uris(stored.data_refs),
        coverage: dataset_coverage(stored.dataset_id),
      })
    }
  }
  Ok(rows)
}
