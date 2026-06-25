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
    #|<style>
    #|:root {
    #|  color-scheme: light;
    #|  --paper: #eef2f3;
    #|  --panel: #ffffff;
    #|  --ink: #1f2428;
    #|  --muted: #697177;
    #|  --line: #ccd3d6;
    #|  --line-strong: #87979f;
    #|  --danger: #b2362e;
    #|  --warn: #b67818;
    #|  --ok: #28765f;
    #|  --teal: #287d84;
    #|  --route: #2f5f93;
    #|}
    #|* { box-sizing: border-box; }
    #|body {
    #|  margin: 0;
    #|  background: var(--paper);
    #|  color: var(--ink);
    #|  font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    #|  letter-spacing: 0;
    #|}
    #|button, select { font: inherit; }
    #|.shell {
    #|  min-height: 100vh;
    #|  display: grid;
    #|  grid-template-columns: minmax(320px, 1fr) minmax(360px, 520px);
    #|  gap: 0;
    #|}
    #|.map-pane {
    #|  padding: 24px;
    #|  border-right: 1px solid var(--line);
    #|}
    #|.side-pane {
    #|  padding: 20px;
    #|  background: var(--panel);
    #|  overflow: auto;
    #|  max-height: 100vh;
    #|}
    #|.topline {
    #|  display: flex;
    #|  justify-content: space-between;
    #|  gap: 16px;
    #|  align-items: flex-start;
    #|  margin-bottom: 18px;
    #|}
    #|h1 {
    #|  margin: 0 0 6px;
    #|  font-size: 24px;
    #|  line-height: 1.2;
    #|  font-weight: 700;
    #|}
    #|h2 {
    #|  margin: 0 0 10px;
    #|  font-size: 15px;
    #|  line-height: 1.25;
    #|  font-weight: 700;
    #|}
    #|p { margin: 0; color: var(--muted); line-height: 1.45; }
    #|.status-pill {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  min-height: 30px;
    #|  padding: 4px 10px;
    #|  border: 1px solid var(--line-strong);
    #|  background: #f6fbfa;
    #|  color: var(--ink);
    #|  font-size: 13px;
    #|  white-space: nowrap;
    #|}
    #|.toolbar {
    #|  display: flex;
    #|  flex-wrap: wrap;
    #|  gap: 8px;
    #|  margin: 0 0 16px;
    #|}
    #|.layer-button {
    #|  min-height: 34px;
    #|  padding: 6px 10px;
    #|  border: 1px solid var(--line);
    #|  background: #fbfcfd;
    #|  color: var(--ink);
    #|  cursor: pointer;
    #|}
    #|.layer-button[aria-pressed="true"] {
    #|  border-color: var(--teal);
    #|  outline: 2px solid color-mix(in srgb, var(--teal) 20%, transparent);
    #|}
    #|.map-wrap {
    #|  display: grid;
    #|  gap: 14px;
    #|  align-items: start;
    #|}
    #|.terrain-grid {
    #|  width: min(100%, 760px);
    #|  aspect-ratio: 1.57;
    #|  display: grid;
    #|  grid-template-columns: repeat(var(--cols), minmax(0, 1fr));
    #|  grid-template-rows: repeat(var(--rows), minmax(0, 1fr));
    #|  border: 1px solid var(--line-strong);
    #|  background: #1e2628;
    #|  position: relative;
    #|  overflow: hidden;
    #|}
    #|.terrain-cell {
    #|  border: 1px solid rgba(255,255,255,0.22);
    #|  color: #fff;
    #|  cursor: pointer;
    #|  position: relative;
    #|  min-width: 0;
    #|  min-height: 0;
    #|  display: flex;
    #|  align-items: flex-end;
    #|  justify-content: flex-start;
    #|  padding: 7px;
    #|  text-align: left;
    #|}
    #|.terrain-cell::after {
    #|  content: "";
    #|  position: absolute;
    #|  inset: 0;
    #|  border: 0 solid transparent;
    #|  pointer-events: none;
    #|}
    #|.terrain-cell[aria-selected="true"]::after {
    #|  border-width: 4px;
    #|  border-color: #ffffff;
    #|  box-shadow: inset 0 0 0 2px var(--ink);
    #|}
    #|.cell-label {
    #|  position: relative;
    #|  z-index: 1;
    #|  font-size: 12px;
    #|  line-height: 1.2;
    #|  text-shadow: 0 1px 2px rgba(0,0,0,0.65);
    #|}
    #|.legend {
    #|  display: flex;
    #|  gap: 10px;
    #|  flex-wrap: wrap;
    #|  color: var(--muted);
    #|  font-size: 13px;
    #|}
    #|.route-list, .fact-list, .review-list {
    #|  display: grid;
    #|  gap: 8px;
    #|}
    #|.clearance-list {
    #|  display: grid;
    #|  gap: 10px;
    #|}
    #|.route-row, .fact-row, .review-row {
    #|  border: 1px solid var(--line);
    #|  background: #fbfcfd;
    #|  padding: 10px;
    #|}
    #|.clearance-row {
    #|  border: 1px solid var(--line);
    #|  background: #fbfcfd;
    #|  padding: 10px;
    #|  display: grid;
    #|  gap: 8px;
    #|}
    #|.clearance-row[data-review-decision="Accept"] {
    #|  border-color: color-mix(in srgb, var(--ok) 55%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.clearance-row[data-review-decision="Reject"] {
    #|  border-color: color-mix(in srgb, var(--danger) 55%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
    #|}
    #|.clearance-row[data-review-decision="RequestEvidence"] {
    #|  border-color: color-mix(in srgb, var(--warn) 45%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--warn);
    #|}
    #|.route-row[aria-current="true"] {
    #|  border-color: var(--route);
    #|  box-shadow: inset 3px 0 0 var(--route);
    #|}
    #|.decision-group {
    #|  display: grid;
    #|  grid-template-columns: repeat(3, minmax(0, 1fr));
    #|  gap: 6px;
    #|}
    #|.decision-button {
    #|  min-height: 34px;
    #|  border: 1px solid var(--line);
    #|  background: #f6fbfa;
    #|  color: var(--ink);
    #|  cursor: pointer;
    #|  padding: 6px 8px;
    #|}
    #|.decision-button[aria-pressed="true"] {
    #|  border-color: var(--teal);
    #|  background: #eef9f7;
    #|}
    #|.export-actions {
    #|  display: flex;
    #|  gap: 8px;
    #|  flex-wrap: wrap;
    #|}
    #|.export-button {
    #|  min-height: 34px;
    #|  border: 1px solid var(--line-strong);
    #|  background: #f6fbfa;
    #|  color: var(--ink);
    #|  cursor: pointer;
    #|  padding: 6px 10px;
    #|}
    #|.export-box {
    #|  width: 100%;
    #|  min-height: 160px;
    #|  resize: vertical;
    #|  border: 1px solid var(--line);
    #|  background: #fbfcfd;
    #|  color: var(--ink);
    #|  padding: 10px;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|  font-size: 12px;
    #|  line-height: 1.35;
    #|}
    #|.export-status {
    #|  min-height: 18px;
    #|  color: var(--muted);
    #|  font-size: 12px;
    #|}
    #|.section {
    #|  padding: 14px 0;
    #|  border-top: 1px solid var(--line);
    #|}
    #|.section:first-child { border-top: 0; padding-top: 0; }
    #|.metrics {
    #|  display: grid;
    #|  grid-template-columns: repeat(2, minmax(0, 1fr));
    #|  gap: 8px;
    #|}
    #|.metric {
    #|  border: 1px solid var(--line);
    #|  background: #fbfcfd;
    #|  padding: 10px;
    #|  min-height: 66px;
    #|}
    #|.metric b, .route-row b, .fact-row b, .review-row b {
    #|  display: block;
    #|  font-size: 12px;
    #|  color: var(--muted);
    #|  font-weight: 600;
    #|  margin-bottom: 3px;
    #|}
    #|.metric span, .route-row span, .fact-row span, .review-row span {
    #|  font-size: 14px;
    #|  line-height: 1.3;
    #|}
    #|.source-path {
    #|  overflow-wrap: anywhere;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|  font-size: 12px;
    #|}
    #|@media (max-width: 880px) {
    #|  .shell { grid-template-columns: 1fr; }
    #|  .side-pane { max-height: none; }
    #|  .map-pane { border-right: 0; border-bottom: 1px solid var(--line); padding: 16px; }
    #|  .metrics { grid-template-columns: 1fr; }
    #|  .decision-group { grid-template-columns: 1fr; }
    #|}
    #|</style>
    #|
  css
}

///|
fn app_script() -> String {
  let script =
    #|<script>
    #|const view = JSON.parse(document.getElementById('moonmoon-view-model').textContent);
    #|const book = JSON.parse(document.getElementById('moonmoon-moonbook').textContent);
    #|let activeLayer = view.active_layer_id;
    #|let selectedCellId = view.selected_cell_id;
    #|const reviewByItem = new Map(book.review_queue.map(item => [item.item_id, item]));
    #|const transitionByItem = new Map(book.review_transitions.map(item => [item.item_id, item]));
    #|const clearanceItems = book.review_queue.filter(item => item.item_id.startsWith('clear-'));
    #|const clearanceDecisions = new Map(clearanceItems.map(item => [item.item_id, initialClearanceDecision(item)]));
    #|const decisionOptions = [
    #|  ['Accept', 'Accept'],
    #|  ['Reject', 'Reject'],
    #|  ['RequestEvidence', 'Need evidence'],
    #|];
    #|
    #|function layerValue(cell, id) {
    #|  return cell.layer_values.find(value => value.layer_id === id) || cell.layer_values[0];
    #|}
    #|
    #|function colorFor(value) {
    #|  const x = Math.max(0, Math.min(1, Number(value.intensity || 0)));
    #|  if (activeLayer === 'hazard') return value.status === 'blocked'
    #|    ? `rgb(${150 + 70 * x}, ${52 - 16 * x}, ${42 - 10 * x})`
    #|    : `rgb(48, ${128 + 60 * x}, 96)`;
    #|  if (activeLayer === 'power') return `rgb(${72 + 130 * x}, ${116 + 56 * x}, ${126 - 42 * x})`;
    #|  if (activeLayer === 'route') return `rgb(${44 + 45 * x}, ${82 + 55 * x}, ${138 + 45 * x})`;
    #|  if (activeLayer === 'evidence') return `rgb(${62 + 30 * x}, ${118 + 70 * x}, ${103 + 35 * x})`;
    #|  return `rgb(${72 + 95 * x}, ${74 + 80 * x}, ${70 + 36 * x})`;
    #|}
    #|
    #|function el(tag, attrs = {}, children = []) {
    #|  const node = document.createElement(tag);
    #|  for (const [key, value] of Object.entries(attrs)) {
    #|    if (key === 'className') node.className = value;
    #|    else if (key === 'text') node.textContent = value;
    #|    else node.setAttribute(key, value);
    #|  }
    #|  for (const child of children) node.append(child);
    #|  return node;
    #|}
    #|
    #|function renderToolbar() {
    #|  const toolbar = document.getElementById('layer-toolbar');
    #|  toolbar.replaceChildren(...view.layers.map(layer => {
    #|    const button = el('button', {
    #|      className: 'layer-button',
    #|      type: 'button',
    #|      'aria-pressed': String(layer.layer_id === activeLayer),
    #|      title: `${layer.label}: ${layer.status}`,
    #|      text: layer.label
    #|    });
    #|    button.addEventListener('click', () => {
    #|      activeLayer = layer.layer_id;
    #|      render();
    #|    });
    #|    return button;
    #|  }));
    #|}
    #|
    #|function renderGrid() {
    #|  const grid = document.getElementById('terrain-grid');
    #|  grid.style.setProperty('--rows', view.viewport.rows);
    #|  grid.style.setProperty('--cols', view.viewport.cols);
    #|  grid.replaceChildren(...view.terrain_cells.map(cell => {
    #|    const value = layerValue(cell, activeLayer);
    #|    const button = el('button', {
    #|      className: 'terrain-cell',
    #|      type: 'button',
    #|      'aria-selected': String(cell.cell_id === selectedCellId),
    #|      title: `${cell.cell_id}: ${value.value_label}`,
    #|    }, [el('span', {
    #|      className: 'cell-label',
    #|      text: `r${cell.row} c${cell.col}\n${value.value_label}`
    #|    })]);
    #|    button.style.background = colorFor(value);
    #|    button.addEventListener('click', () => {
    #|      selectedCellId = cell.cell_id;
    #|      render();
    #|    });
    #|    return button;
    #|  }));
    #|}
    #|
    #|function selectedCell() {
    #|  return view.terrain_cells.find(cell => cell.cell_id === selectedCellId) || view.terrain_cells[0];
    #|}
    #|
    #|function renderInspector() {
    #|  const cell = selectedCell();
    #|  const value = layerValue(cell, activeLayer);
    #|  document.getElementById('selected-cell').textContent = cell.cell_id;
    #|  document.getElementById('active-layer').textContent = `${activeLayer}: ${value.value_label}`;
    #|  const metrics = [
    #|    ['Elevation', `${cell.elevation_m} m`],
    #|    ['Slope', `${cell.slope_grade.toFixed(3)} grade`],
    #|    ['Roughness', `${cell.roughness_m.toFixed(3)} m`],
    #|    ['Hazard', cell.hazard],
    #|    ['Source', cell.source_dataset_id],
    #|    ['Confidence', `${Math.round(cell.confidence * 100)}%`],
    #|  ];
    #|  document.getElementById('metrics').replaceChildren(...metrics.map(([label, value]) =>
    #|    el('div', { className: 'metric' }, [
    #|      el('b', { text: label }),
    #|      el('span', { text: value })
    #|    ])
    #|  ));
    #|}
    #|
    #|function renderRoutes() {
    #|  document.getElementById('routes').replaceChildren(...view.routes.map(route =>
    #|    el('div', { className: 'route-row', 'aria-current': String(route.selected) }, [
    #|      el('b', { text: `${route.label} - ${route.decision}` }),
    #|      el('span', { text: `score ${route.score}, grade ${route.max_grade}, roughness ${route.roughness_m} m` }),
    #|      el('p', { text: route.next_action })
    #|    ])
    #|  ));
    #|}
    #|
    #|function renderFacts() {
    #|  document.getElementById('facts').replaceChildren(...view.inspector_facts.map(fact =>
    #|    el('div', { className: 'fact-row' }, [
    #|      el('b', { text: `${fact.label} - ${fact.status}` }),
    #|      el('span', { text: fact.value }),
    #|      el('p', { className: 'source-path', text: fact.evidence_path })
    #|    ])
    #|  ));
    #|}
    #|
    #|function renderReview() {
    #|  const rows = ['workspace-materialized', 'route-direct-lola-window', 'corridor-scan-best-window', 'energy-window', 'moonrobo-handoff']
    #|    .map(id => ({ item: reviewByItem.get(id), transition: transitionByItem.get(id) }))
    #|    .filter(row => row.item && row.transition);
    #|  document.getElementById('review').replaceChildren(...rows.map(row =>
    #|    el('div', { className: 'review-row' }, [
    #|      el('b', { text: `${row.item.item_id} - ${row.item.status}` }),
    #|      el('span', { text: row.item.reason }),
    #|      el('p', { className: 'source-path', text: row.transition.source_evidence_refs.map(ref => ref.immutable_uri).join(' | ') })
    #|    ])
    #|  ));
    #|}
    #|
    #|function transitionDecisionStatus(decision) {
    #|  if (decision === 'Accept') return 'Accepted';
    #|  if (decision === 'Reject') return 'Rejected';
    #|  return 'NeedsEvidence';
    #|}
    #|
    #|function initialClearanceDecision(item) {
    #|  const transition = transitionByItem.get(item.item_id);
    #|  if (transition && transition.decision) return transition.decision;
    #|  if (item.status === 'Accepted') return 'Accept';
    #|  if (item.status === 'Rejected') return 'Reject';
    #|  return 'RequestEvidence';
    #|}
    #|
    #|function clearanceReviewStatus(item) {
    #|  const transition = transitionByItem.get(item.item_id);
    #|  if (transition && transition.resulting_status) return transition.resulting_status;
    #|  return item.status;
    #|}
    #|
    #|function clearanceReviewNote(item) {
    #|  const transition = transitionByItem.get(item.item_id);
    #|  if (transition && transition.rationale) return transition.rationale;
    #|  return item.reason;
    #|}
    #|
    #|function transitionSuffix(decision) {
    #|  if (decision === 'Accept') return 'accept';
    #|  if (decision === 'Reject') return 'reject';
    #|  return 'request-evidence';
    #|}
    #|
    #|function transitionEvidenceRefs(item) {
    #|  const transition = transitionByItem.get(item.item_id);
    #|  if (transition && transition.source_evidence_refs.length) return transition.source_evidence_refs;
    #|  return [{
    #|    ref_id: item.item_id,
    #|    entry_id: 'mission/first-trusted-square/selected-route-clearance',
    #|    path: 'mission/first-trusted-square/selected-route-clearance.json',
    #|    immutable_uri: `moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#${item.item_id}`
    #|  }];
    #|}
    #|
    #|function buildClearanceTransition(item) {
    #|  const decision = clearanceDecisions.get(item.item_id) || 'RequestEvidence';
    #|  return {
    #|    transition_id: `rabbita-${item.item_id}-${transitionSuffix(decision)}`,
    #|    item_id: item.item_id,
    #|    previous_status: item.status,
    #|    decision,
    #|    resulting_status: transitionDecisionStatus(decision),
    #|    reviewer_id: 'operator/rabbita-clearance-review',
    #|    reviewer_role: item.owner,
    #|    timestamp_policy: 'operator-browser-export',
    #|    recorded_at_utc: new Date().toISOString(),
    #|    append_only: true,
    #|    source_evidence_refs: transitionEvidenceRefs(item),
    #|    rationale: `Rabbita ${transitionSuffix(decision)} decision for ${item.item_id}: ${item.reason}`
    #|  };
    #|}
    #|
    #|function clearanceTransitionExport() {
    #|  return {
    #|    workspace: book.workspace,
    #|    site_id: book.site_id,
    #|    generated_by: 'output/ui/rabbita/first_trusted_square.html',
    #|    transitions: clearanceItems.map(buildClearanceTransition)
    #|  };
    #|}
    #|
    #|function renderTransitionExport() {
    #|  const box = document.getElementById('transition-export');
    #|  if (!box) return;
    #|  box.value = JSON.stringify(clearanceTransitionExport(), null, 2);
    #|}
    #|
    #|function renderClearanceReview() {
    #|  const list = document.getElementById('clearance-review');
    #|  list.replaceChildren(...clearanceItems.map(item => {
    #|    const selected = clearanceDecisions.get(item.item_id) || 'RequestEvidence';
    #|    const reviewStatus = clearanceReviewStatus(item);
    #|    const controls = el('div', { className: 'decision-group', role: 'group', 'aria-label': item.item_id },
    #|      decisionOptions.map(([decision, label]) => {
    #|        const button = el('button', {
    #|          className: 'decision-button',
    #|          type: 'button',
    #|          'aria-pressed': String(decision === selected),
    #|          text: label
    #|        });
    #|        button.addEventListener('click', () => {
    #|          clearanceDecisions.set(item.item_id, decision);
    #|          renderClearanceReview();
    #|          renderTransitionExport();
    #|        });
    #|        return button;
    #|      })
    #|    );
    #|    return el('div', {
    #|      className: 'clearance-row',
    #|      'data-review-decision': selected,
    #|      'data-review-status': reviewStatus,
    #|    }, [
    #|      el('b', { text: `${item.item_id} - ${reviewStatus}` }),
    #|      el('span', { text: clearanceReviewNote(item) }),
    #|      controls
    #|    ]);
    #|  }));
    #|  renderTransitionExport();
    #|}
    #|
    #|function copyTransitionExport() {
    #|  const box = document.getElementById('transition-export');
    #|  const status = document.getElementById('transition-export-status');
    #|  if (!navigator.clipboard) {
    #|    box.select();
    #|    status.textContent = 'Select the export JSON manually';
    #|    return;
    #|  }
    #|  navigator.clipboard.writeText(box.value).then(() => {
    #|    status.textContent = 'Transition JSON copied';
    #|  }).catch(() => {
    #|    box.select();
    #|    status.textContent = 'Select the export JSON manually';
    #|  });
    #|}
    #|
    #|function downloadTransitionExport() {
    #|  const blob = new Blob([document.getElementById('transition-export').value], { type: 'application/json' });
    #|  const link = document.createElement('a');
    #|  link.href = URL.createObjectURL(blob);
    #|  link.download = 'first_trusted_square_clearance_transitions.json';
    #|  link.click();
    #|  URL.revokeObjectURL(link.href);
    #|}
    #|
    #|function render() {
    #|  renderToolbar();
    #|  renderGrid();
    #|  renderInspector();
    #|  renderRoutes();
    #|  renderFacts();
    #|  renderReview();
    #|  renderClearanceReview();
    #|}
    #|
    #|document.getElementById('copy-transition-export').addEventListener('click', copyTransitionExport);
    #|document.getElementById('download-transition-export').addEventListener('click', downloadTransitionExport);
    #|render();
    #|</script>
    #|
  script
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
    $|</body>
    $|</html>
    $|
  html
}

///|
pub fn first_trusted_square_html() -> String {
  render_html(
    @ui.first_trusted_square_view_model(),
    @moonbook.first_trusted_square_book_dossier(),
  )
}
