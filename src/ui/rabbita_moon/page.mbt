///|
fn app_data_script(
  view : @ui.TrustedSquareViewModel,
  book : @moonbook.MoonBookDossier,
) -> String {
  let view_json = @ui.render_json(view).stringify(indent=2)
  let book_json = @moonbook.render_json(book).stringify(indent=2)
  let html =
    $|<script id="moonmoon-view-model" type="application/json">
    $|\{view_json}
    $|</script>
    $|<script id="moonmoon-moonbook" type="application/json">
    $|\{book_json}
    $|</script>
    $|
  html
}

///|
fn app_styles() -> String {
  let css =
    #|<link rel="stylesheet" href="assets/rabbita_moon.css">
    #|
  css
}

///|
fn app_script() -> String {
  let script =
    #|<script src="assets/rabbita_app.js"></script>
    #|
  script
}

///|
fn globe_script() -> String {
  (
    #|<script src="assets/moon_globe.js"></script>
    #|
  )
}

///|
pub fn render_html(
  view : @ui.TrustedSquareViewModel,
  book : @moonbook.MoonBookDossier,
) -> String {
  let title = html_escape(view.title)
  let decision = html_escape(view.scorecard.decision)
  let next_action = html_escape(view.scorecard.next_action)
  let source_title = html_escape(view.source_panel.source_title)
  let source_path = html_escape(view.source_panel.local_source_path)
  let source_review = html_escape(view.source_panel.review_status)
  let html =
    $|<!doctype html>
    $|<html lang="en">
    $|<head>
    $|<meta charset="utf-8">
    $|<meta name="viewport" content="width=device-width, initial-scale=1">
    $|<title>Rabbita Moon - \{title}</title>
    $|\{app_styles()}
    $|</head>
    $|<body>
    $|\{app_data_script(view, book)}
    $|<main class="shell">
    $|  <section class="map-pane" aria-label="Lunar terrain inspection">
    $|    <div class="topline">
    $|      <div>
    $|        <h1>Rabbita Moon - \{title}</h1>
    $|        <p>\{next_action}</p>
    $|      </div>
    $|      <span class="status-pill">mission: \{decision}</span>
    $|    </div>
    $|    <section class="lunar-viewport" aria-label="Moon landscape to first trusted square zoom">
    $|      <div id="moon-globe" class="moon-globe" data-moon-globe data-texture="assets/lunar_global_texture.jpg" aria-label="Operable 3D Moon globe for first trusted square">
    $|        <canvas class="moon-globe-canvas" width="760" height="390" aria-label="Drag to rotate the Moon and use the controls to zoom or fly to the trusted square"></canvas>
    $|        <div class="moon-globe-fallback moon-landscape">
    $|          <img src="assets/southpole_10deg_print.jpg" alt="NASA SVS lunar south pole landscape rendered from LRO LOLA and LROC WAC data">
    $|        </div>
    $|        <span class="moon-globe-status">loading globe</span>
    $|        <span class="moon-globe-authority" data-globe-authority>hardware denied</span>
    $|        <span class="moon-globe-readout" data-globe-readout>lat -- lon --</span>
    $|        <span class="moon-globe-scale" data-globe-scale><span class="moon-globe-scale-bar"></span><span data-globe-scale-label>scale --</span></span>
    $|        <span class="moon-globe-compass" data-globe-compass>N</span>
    $|        <svg class="moon-globe-overlay" aria-hidden="true"></svg>
    $|        <div class="moon-globe-marker" hidden aria-hidden="true"></div>
    $|        <div class="moon-globe-controls" aria-label="Moon globe controls">
    $|          <button type="button" data-globe-action="zoom-in" title="Zoom in">+</button>
    $|          <button type="button" data-globe-action="zoom-out" title="Zoom out">-</button>
    $|          <button type="button" data-globe-action="home" title="Reset Moon view">H</button>
    $|          <button type="button" data-globe-action="site" title="Fly to trusted square">S</button>
    $|          <button type="button" data-globe-layer="grid" aria-pressed="true" title="Toggle coordinate grid">G</button>
    $|          <button type="button" data-globe-layer="footprint" aria-pressed="true" title="Toggle trusted square footprint">F</button>
    $|          <button type="button" data-globe-layer="route" aria-pressed="true" title="Toggle promoted route trace">R</button>
    $|          <button type="button" data-globe-layer="corridor" aria-pressed="true" title="Toggle measured corridor windows">C</button>
    $|        </div>
    $|        <div class="landscape-caption">
    $|          <div>
    $|            <b>live moon</b>
    $|            <span>drag, zoom, then fly to the trusted square</span>
    $|          </div>
    $|          <span>global texture for context; LOLA evidence below</span>
    $|        </div>
    $|      </div>
    $|      <div class="zoom-stack">
    $|        <div class="lola-map">
    $|          <svg id="lola-data-map" class="lola-data-map" viewBox="0 0 360 380" role="img" aria-label="LOLA GDR measured corridor scan map for first trusted square">
    $|          </svg>
    $|          <div class="map-controls" aria-hidden="true">
    $|            <span>+</span>
    $|            <span>-</span>
    $|            <span>N</span>
    $|          </div>
    $|        </div>
    $|        <div class="lunar-summary">
    $|          <div>
    $|            <b>lunar site</b>
    $|            <span>\{title}</span>
    $|          </div>
    $|          <div>
    $|            <b>zoom sequence</b>
    $|            <span>south-pole landscape to 81-window measured LOLA corridor</span>
    $|          </div>
    $|          <div>
    $|            <b>selected window</b>
    $|            <span>rank-1 northeast-stepout candidate</span>
    $|          </div>
    $|          <div>
    $|            <b>robot authority</b>
    $|            <span class="hardware-denied">hardware denied until lunar evidence gates clear</span>
    $|          </div>
    $|        </div>
    $|      </div>
    $|    </section>
    $|    <div id="layer-toolbar" class="toolbar" aria-label="Layer toggles"></div>
    $|    <div class="map-wrap">
    $|      <div id="terrain-grid" class="terrain-grid" role="grid" aria-label="Selectable lunar terrain cells"></div>
    $|      <div class="legend">
    $|        <span id="selected-cell"></span>
    $|        <span id="active-layer"></span>
    $|      </div>
    $|    </div>
    $|  </section>
    $|  <aside class="side-pane" aria-label="Inspection details">
    $|    <section class="section">
    $|      <h2>Selected Cell</h2>
    $|      <div id="metrics" class="metrics"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Route Overlays</h2>
    $|      <div id="routes" class="route-list"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Source Evidence</h2>
    $|      <div class="fact-row">
    $|        <b>\{source_title} - \{source_review}</b>
    $|        <span class="source-path">\{source_path}</span>
    $|      </div>
    $|      <div id="facts" class="fact-list" style="margin-top: 8px;"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>MoonBook Review Status</h2>
    $|      <div id="review" class="review-list"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>MoonClaw Gap Evidence</h2>
    $|      <div id="moonclaw-gap-evidence" class="review-list"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Selected Route Remediation Evidence</h2>
    $|      <div id="selected-route-remediation" class="review-list" aria-label="Selected route remediation evidence"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Simulation Review Packet</h2>
    $|      <div id="simulation-review-packet" class="review-list" aria-label="Selected route simulation review packet with hardware-denial invariants"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Simulation Review Decision</h2>
    $|      <div id="simulation-review-decision" class="review-list" aria-label="Selected route simulation review closeout decision with no-consume status"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Simulation Blocker Reduction</h2>
    $|      <div id="simulation-blocker-reduction" class="review-list" aria-label="Selected route simulation blocker reduction with hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Task</h2>
    $|      <div id="remediation-margin-task" class="review-list" aria-label="MoonClaw remediation margin task with three active blockers and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Task</h2>
    $|      <div id="remediation-margin-refresh-task" class="review-list" aria-label="MoonClaw remediation margin refresh task with no-consume projection status, ranked evidence refreshes, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Follow-Up Task</h2>
    $|      <div id="remediation-margin-refresh-followup-task" class="review-list" aria-label="MoonClaw remediation margin refresh follow-up task with no-consume refresh projection status, terrain/horizon/energy refresh blockers, target commands, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Follow-Up Receipt</h2>
    $|      <div id="remediation-margin-refresh-followup-receipt" class="review-list" aria-label="MoonClaw remediation margin refresh follow-up receipt with still-blocking follow-up refresh results and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Receipt</h2>
    $|      <div id="remediation-margin-refresh-receipt" class="review-list" aria-label="MoonClaw remediation margin refresh receipt with still-blocking refresh results and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Receipt</h2>
    $|      <div id="remediation-margin-receipt" class="review-list" aria-label="MoonClaw remediation margin receipt with still-blocking margin results and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Modeling</h2>
    $|      <div id="remediation-margin-modeling" class="review-list" aria-label="MoonRobo remediation margin modeling pass with still-blocking margin results and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Modeling</h2>
    $|      <div id="remediation-margin-refresh-modeling" class="review-list" aria-label="MoonRobo remediation margin refresh modeling pass with still-blocking refresh results, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Follow-Up Modeling</h2>
    $|      <div id="remediation-margin-refresh-followup-modeling" class="review-list" aria-label="MoonRobo remediation margin refresh follow-up modeling pass with still-blocking follow-up refresh results, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Follow-Up Projection</h2>
    $|      <div id="remediation-margin-refresh-followup-projection" class="review-list" aria-label="MoonRobo remediation margin refresh follow-up projection with no-consume simulation status, terrain/horizon/energy follow-up blockers, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Cycle Closeout</h2>
    $|      <div id="remediation-margin-cycle-closeout" class="review-list" aria-label="MoonRobo remediation margin cycle closeout policy with no-consume status, retry/escalate/freeze blocker dispositions, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Closeout Action</h2>
    $|      <div id="remediation-margin-closeout-action" class="review-list" aria-label="MoonClaw remediation margin closeout action task with needs-review state, retry/escalate/freeze actions, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Reviewed Action Plan</h2>
    $|      <div id="remediation-margin-reviewed-action-plan" class="review-list" aria-label="MoonClaw reviewed remediation margin action plan with accepted review provenance, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Reviewed Work Items</h2>
    $|      <div id="remediation-margin-reviewed-work-items" class="review-list" aria-label="MoonClaw reviewed remediation margin work items with terrain escalation, horizon retry-with-new-evidence, energy freeze, no automatic refresh loop, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Reviewed Work Item Receipts</h2>
    $|      <div id="remediation-margin-reviewed-work-item-receipts" class="review-list" aria-label="MoonClaw reviewed remediation margin work item receipts with pending fresh evidence, accepted review provenance, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Reviewed Fresh Evidence Task</h2>
    $|      <div id="remediation-margin-reviewed-fresh-evidence-task" class="review-list" aria-label="MoonClaw reviewed remediation margin fresh-evidence task with source receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Fresh Evidence Action Receipts</h2>
    $|      <div id="remediation-margin-fresh-evidence-action-receipts" class="review-list" aria-label="MoonClaw fresh-evidence action receipts with source receipt provenance, terrain/horizon/energy execution modes, pending reviewed work item state, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Regenerated Reviewed Work Item Receipts</h2>
    $|      <div id="remediation-margin-regenerated-reviewed-work-item-receipts" class="review-list" aria-label="MoonClaw regenerated reviewed work item receipts with source action receipt provenance, source receipt and review provenance, terrain/horizon/energy execution modes, pending fresh evidence state, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Regenerated Receipt Readiness</h2>
    $|      <div id="remediation-margin-regenerated-receipt-readiness" class="review-list" aria-label="MoonRobo regenerated receipt readiness gate with pending fresh evidence state, source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Regenerated Readiness Fresh Evidence Task</h2>
    $|      <div id="regenerated-receipt-readiness-fresh-evidence-task" class="review-list" aria-label="MoonClaw regenerated readiness fresh-evidence task with source action receipt provenance, terrain/horizon/energy execution modes, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Regenerated Readiness Fresh Evidence Action Receipts</h2>
    $|      <div id="regenerated-receipt-readiness-fresh-evidence-action-receipts" class="review-list" aria-label="MoonClaw regenerated readiness fresh-evidence action receipts with source readiness gate provenance, source action receipt provenance, terrain/horizon/energy execution modes, pending regenerated receipt state, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Regenerated Readiness Action Receipt Closeout</h2>
    $|      <div id="regenerated-receipt-readiness-action-receipt-closeout" class="review-list" aria-label="MoonRobo regenerated readiness action receipt closeout with source readiness gate provenance, source action receipt provenance, pending and ready receipt accounting, no automatic refresh loop, no-consume simulation status, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Closeout Action Review</h2>
    $|      <div id="closeout-action-review" class="clearance-list" aria-label="Operator review for MoonClaw remediation margin closeout action task"></div>
    $|      <div class="export-actions" style="margin-top: 10px;">
    $|        <button id="copy-closeout-action-review-export" class="export-button" type="button">Copy</button>
    $|        <button id="download-closeout-action-review-export" class="export-button" type="button">Download</button>
    $|      </div>
    $|      <p id="closeout-action-review-export-status" class="export-status" aria-live="polite"></p>
    $|      <textarea id="closeout-action-review-export" class="export-box" aria-label="Importable MoonClaw closeout action review transition" readonly></textarea>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Refresh Projection</h2>
    $|      <div id="remediation-margin-refresh-projection" class="review-list" aria-label="MoonRobo remediation margin refresh projection with no-consume simulation status, terrain/horizon/energy refresh blockers, and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Remediation Margin Projection</h2>
    $|      <div id="remediation-margin-projection" class="review-list" aria-label="MoonRobo remediation margin projection with no-consume simulation status and hardware-denial authority"></div>
    $|    </section>
    $|    <section class="section">
    $|      <h2>Selected Route Clearance</h2>
    $|      <div id="clearance-review" class="clearance-list"></div>
    $|      <div class="export-actions" style="margin-top: 10px;">
    $|        <button id="copy-transition-export" class="export-button" type="button">Copy</button>
    $|        <button id="download-transition-export" class="export-button" type="button">Download</button>
    $|      </div>
    $|      <p id="transition-export-status" class="export-status" aria-live="polite"></p>
    $|      <textarea id="transition-export" class="export-box" aria-label="Importable selected-route clearance review transitions" readonly></textarea>
    $|    </section>
    $|  </aside>
    $|</main>
    $|\{app_script()}
    $|\{globe_script()}
    $|</body>
    $|</html>
  html
}

///|
pub fn first_trusted_square_html() -> String {
  render_html(
    @ui.first_trusted_square_view_model(),
    @moonbook.first_trusted_square_book_dossier(),
  )
}
