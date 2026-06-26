///|
fn globe_point(
  point_id : String,
  label : String,
  latitude_deg : Double,
  longitude_deg : Double,
  role : String,
  status : String,
) -> GlobeOverlayPoint {
  { point_id, label, latitude_deg, longitude_deg, role, status }
}

///|
fn signed_site_latitude(site : @core.LunarSite, row_offset : Int) -> Double {
  let offset = 0.0 - row_offset.to_double()
  let span = if offset >= 0.0 {
    site.bounds.north_deg - site.center.latitude_deg
  } else {
    site.center.latitude_deg - site.bounds.south_deg
  }
  site.center.latitude_deg + offset / 16.0 * span
}

///|
fn signed_site_longitude(site : @core.LunarSite, col_offset : Int) -> Double {
  let offset = col_offset.to_double()
  let span = if offset >= 0.0 {
    site.bounds.east_deg - site.center.longitude_deg
  } else {
    site.center.longitude_deg - site.bounds.west_deg
  }
  site.center.longitude_deg + offset / 16.0 * span
}

///|
fn selected_corridor_window(
  windows : Array[@mission.CorridorScanWindow],
  selected_route_id : String,
) -> @mission.CorridorScanWindow {
  let mut picked = windows[0]
  for window in windows {
    if window.selected_route_id == selected_route_id &&
      (
        picked.selected_route_id != selected_route_id ||
        window.rank < picked.rank
      ) {
      picked = window
    }
  }
  picked
}

///|
fn site_footprint(site : @core.LunarSite) -> Array[GlobeOverlayPoint] {
  [
    globe_point(
      "site-footprint/sw",
      "southwest bound",
      site.bounds.south_deg,
      site.bounds.west_deg,
      "footprint",
      "measured",
    ),
    globe_point(
      "site-footprint/nw",
      "northwest bound",
      site.bounds.north_deg,
      site.bounds.west_deg,
      "footprint",
      "measured",
    ),
    globe_point(
      "site-footprint/ne",
      "northeast bound",
      site.bounds.north_deg,
      site.bounds.east_deg,
      "footprint",
      "measured",
    ),
    globe_point(
      "site-footprint/se",
      "southeast bound",
      site.bounds.south_deg,
      site.bounds.east_deg,
      "footprint",
      "measured",
    ),
  ]
}

///|
fn selected_route_trace(
  site : @core.LunarSite,
  window : @mission.CorridorScanWindow,
  selected_route_id : String,
) -> GlobeOverlayPath {
  let end_lat = signed_site_latitude(site, window.row_offset)
  let end_lon = signed_site_longitude(site, window.col_offset)
  let mid_lat = (site.center.latitude_deg + end_lat) / 2.0
  let mid_lon = (site.center.longitude_deg + end_lon) / 2.0
  {
    path_id: "globe-route/\{selected_route_id}",
    label: selected_route_id,
    kind: "selected-route",
    status: @mission.corridor_scan_window_status_label(window),
    points: [
      globe_point(
        "route/\{selected_route_id}/start",
        "trusted square center",
        site.center.latitude_deg,
        site.center.longitude_deg,
        "route-start",
        "measured",
      ),
      globe_point(
        "route/\{selected_route_id}/mid",
        "corridor approach",
        mid_lat,
        mid_lon,
        "route-mid",
        "derived",
      ),
      globe_point(
        "route/\{selected_route_id}/window",
        window.window_id,
        end_lat,
        end_lon,
        "route-window",
        @mission.corridor_scan_window_status_label(window),
      ),
    ],
  }
}

///|
fn globe_corridor_window(
  site : @core.LunarSite,
  selected_route_id : String,
  window : @mission.CorridorScanWindow,
) -> GlobeOverlayWindow {
  {
    window_id: window.window_id,
    rank: window.rank,
    row_offset: window.row_offset,
    col_offset: window.col_offset,
    latitude_deg: signed_site_latitude(site, window.row_offset),
    longitude_deg: signed_site_longitude(site, window.col_offset),
    decision: @mission.corridor_scan_window_status_label(window),
    selected: window.selected_route_id == selected_route_id,
    selected_route_id: window.selected_route_id,
    max_neighbor_grade: window.max_neighbor_grade,
    roughness_m: window.roughness_m,
  }
}

///|
fn globe_corridor_windows(
  site : @core.LunarSite,
  windows : Array[@mission.CorridorScanWindow],
  selected_route_id : String,
) -> Array[GlobeOverlayWindow] {
  windows.map(window => globe_corridor_window(site, selected_route_id, window))
}

///|
fn hardware_authority(blocker_count : Int) -> String {
  if blocker_count > 0 {
    "hardware denied"
  } else {
    "operator review"
  }
}

///|
fn globe_overlay(
  dossier : @site.SiteDossier,
  grid : @terrain.TerrainGrid,
  selected_route_id : String,
) -> GlobeOverlayView {
  let selected_window = selected_corridor_window(
    dossier.corridor_scan,
    selected_route_id,
  )
  let trace = selected_route_trace(
    dossier.site,
    selected_window,
    selected_route_id,
  )
  let blocker_count = dossier.blockers.length()
  {
    overlay_id: "globe-overlay/\{dossier.site.site_id}",
    source_dataset_id: grid.source_manifest.dataset_id,
    source_path: grid.source_manifest.source_path,
    claim: "projected site bounds and promoted route window for browser globe context",
    footprint: site_footprint(dossier.site),
    selected_route_trace: trace,
    corridor_windows: globe_corridor_windows(
      dossier.site,
      dossier.corridor_scan,
      selected_route_id,
    ),
    hardware_authority: hardware_authority(blocker_count),
    blocker_count,
    status: trace.status,
    summary: "trusted square bounds, 81 measured corridor windows, and \{selected_route_id} route window projected from MoonBit view-model data",
  }
}
