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
    #|.lunar-viewport {
    #|  width: min(100%, 760px);
    #|  margin: 0 0 16px;
    #|  border: 1px solid var(--line-strong);
    #|  background: #0f1415;
    #|  color: #f5f7f4;
    #|  position: relative;
    #|  overflow: hidden;
    #|  display: grid;
    #|  gap: 0;
    #|}
    #|.moon-globe {
    #|  height: 390px;
    #|  position: relative;
    #|  overflow: hidden;
    #|  background:
    #|    radial-gradient(circle at 18% 18%, rgba(255,255,255,0.18), transparent 0 1px, transparent 2px),
    #|    radial-gradient(circle at 76% 12%, rgba(255,255,255,0.14), transparent 0 1px, transparent 2px),
    #|    radial-gradient(circle at 86% 72%, rgba(255,255,255,0.14), transparent 0 1px, transparent 2px),
    #|    linear-gradient(145deg, #030607 0%, #0a1011 52%, #111819 100%);
    #|}
    #|.moon-globe-canvas {
    #|  width: 100%;
    #|  height: 390px;
    #|  display: block;
    #|  cursor: grab;
    #|  touch-action: none;
    #|}
    #|.moon-globe-canvas:active { cursor: grabbing; }
    #|.moon-globe-fallback {
    #|  position: absolute;
    #|  inset: 0;
    #|  transition: opacity 220ms ease-out;
    #|}
    #|.moon-globe-ready .moon-globe-fallback {
    #|  opacity: 0;
    #|  pointer-events: none;
    #|}
    #|.moon-landscape {
    #|  min-height: 390px;
    #|  position: relative;
    #|  overflow: hidden;
    #|  background: #0b0f10;
    #|}
    #|.moon-landscape img {
    #|  width: 100%;
    #|  height: 100%;
    #|  min-height: 390px;
    #|  display: block;
    #|  object-fit: cover;
    #|  object-position: 50% 53%;
    #|  filter: contrast(1.08) brightness(0.92);
    #|}
    #|.moon-landscape::after {
    #|  content: "";
    #|  position: absolute;
    #|  inset: 0;
    #|  background:
    #|    linear-gradient(180deg, rgba(3,5,6,0.12) 0%, rgba(3,5,6,0.04) 42%, rgba(3,5,6,0.68) 100%),
    #|    radial-gradient(circle at 58% 58%, transparent 0 9%, rgba(4,7,8,0.28) 21%, rgba(4,7,8,0.58) 100%);
    #|  pointer-events: none;
    #|}
    #|.moon-globe-marker {
    #|  position: absolute;
    #|  z-index: 3;
    #|  width: 18px;
    #|  height: 18px;
    #|  border: 2px solid #f0c45d;
    #|  border-radius: 50%;
    #|  box-shadow: 0 0 0 1px rgba(0,0,0,0.7), 0 0 18px rgba(240,196,93,0.78);
    #|  transform: translate(-50%, -50%);
    #|  pointer-events: none;
    #|}
    #|.moon-globe-marker::after {
    #|  content: "";
    #|  position: absolute;
    #|  left: 50%;
    #|  top: 50%;
    #|  width: 4px;
    #|  height: 4px;
    #|  border-radius: 50%;
    #|  background: #f0c45d;
    #|  transform: translate(-50%, -50%);
    #|}
    #|.moon-globe-overlay {
    #|  position: absolute;
    #|  inset: 0;
    #|  z-index: 2;
    #|  width: 100%;
    #|  height: 100%;
    #|  pointer-events: none;
    #|}
    #|.moon-globe-footprint {
    #|  fill: rgba(240,196,93,0.13);
    #|  stroke: #f0c45d;
    #|  stroke-width: 1.8;
    #|  vector-effect: non-scaling-stroke;
    #|  filter: drop-shadow(0 0 5px rgba(240,196,93,0.48));
    #|}
    #|.moon-globe-route {
    #|  fill: none;
    #|  stroke: #75d1c5;
    #|  stroke-width: 2.6;
    #|  stroke-linecap: round;
    #|  stroke-linejoin: round;
    #|  vector-effect: non-scaling-stroke;
    #|  filter: drop-shadow(0 0 5px rgba(117,209,197,0.78));
    #|}
    #|.moon-globe-route-end {
    #|  fill: #75d1c5;
    #|  stroke: #071112;
    #|  stroke-width: 1.5;
    #|  vector-effect: non-scaling-stroke;
    #|}
    #|.moon-globe-corridor {
    #|  fill: rgba(245,247,244,0.42);
    #|  stroke: rgba(7,17,18,0.76);
    #|  stroke-width: 0.7;
    #|  vector-effect: non-scaling-stroke;
    #|}
    #|.moon-globe-corridor-selected {
    #|  fill: #75d1c5;
    #|  stroke: #071112;
    #|  stroke-width: 1.2;
    #|  filter: drop-shadow(0 0 5px rgba(117,209,197,0.78));
    #|}
    #|.moon-globe-controls {
    #|  position: absolute;
    #|  right: 14px;
    #|  top: 14px;
    #|  z-index: 4;
    #|  display: grid;
    #|  grid-template-columns: repeat(2, 34px);
    #|  gap: 6px;
    #|}
    #|.moon-globe-controls button {
    #|  width: 34px;
    #|  height: 34px;
    #|  border: 1px solid rgba(255,255,255,0.32);
    #|  background: rgba(7,11,12,0.72);
    #|  color: #f5f7f4;
    #|  cursor: pointer;
    #|  font-size: 13px;
    #|}
    #|.moon-globe-controls button:hover,
    #|.moon-globe-controls button:focus-visible {
    #|  border-color: #f0c45d;
    #|  outline: 2px solid rgba(240,196,93,0.26);
    #|  outline-offset: 1px;
    #|}
    #|.moon-globe-controls button[aria-pressed="false"] {
    #|  color: rgba(245,247,244,0.48);
    #|  border-color: rgba(255,255,255,0.18);
    #|}
    #|.moon-globe-status {
    #|  position: absolute;
    #|  left: 18px;
    #|  top: 14px;
    #|  z-index: 4;
    #|  color: rgba(245,247,244,0.78);
    #|  font-size: 12px;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|}
    #|.moon-globe-authority {
    #|  position: absolute;
    #|  left: 18px;
    #|  top: 40px;
    #|  z-index: 4;
    #|  max-width: 210px;
    #|  color: #ffd7cf;
    #|  font-size: 12px;
    #|  line-height: 1.25;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|  text-shadow: 0 1px 5px rgba(0,0,0,0.86);
    #|}
    #|.moon-globe-readout {
    #|  position: absolute;
    #|  left: 18px;
    #|  bottom: 86px;
    #|  z-index: 4;
    #|  min-width: 188px;
    #|  color: #f5f7f4;
    #|  font-size: 12px;
    #|  line-height: 1.28;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|  text-shadow: 0 1px 5px rgba(0,0,0,0.9);
    #|}
    #|.moon-globe-compass {
    #|  position: absolute;
    #|  right: 14px;
    #|  bottom: 86px;
    #|  z-index: 4;
    #|  width: 42px;
    #|  height: 42px;
    #|  border: 1px solid rgba(255,255,255,0.28);
    #|  border-radius: 50%;
    #|  background: rgba(7,11,12,0.56);
    #|  color: #f5f7f4;
    #|  display: grid;
    #|  place-items: center;
    #|  font-size: 11px;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|}
    #|.moon-globe-compass::before {
    #|  content: "";
    #|  position: absolute;
    #|  left: 50%;
    #|  top: 7px;
    #|  width: 0;
    #|  height: 0;
    #|  border-left: 5px solid transparent;
    #|  border-right: 5px solid transparent;
    #|  border-bottom: 16px solid #f0c45d;
    #|  transform: translateX(-50%);
    #|}
    #|.moon-globe-scale {
    #|  position: absolute;
    #|  right: 66px;
    #|  bottom: 89px;
    #|  z-index: 4;
    #|  min-width: 112px;
    #|  color: #f5f7f4;
    #|  font-size: 11px;
    #|  line-height: 1.2;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|  text-align: right;
    #|  text-shadow: 0 1px 5px rgba(0,0,0,0.9);
    #|}
    #|.moon-globe-scale-bar {
    #|  display: block;
    #|  width: var(--scale-width, 82px);
    #|  height: 6px;
    #|  margin-left: auto;
    #|  margin-bottom: 4px;
    #|  border-left: 1px solid #f5f7f4;
    #|  border-right: 1px solid #f5f7f4;
    #|  border-bottom: 2px solid #f5f7f4;
    #|}
    #|.landscape-target {
    #|  position: absolute;
    #|  left: 54%;
    #|  top: 48%;
    #|  width: clamp(58px, 11vw, 96px);
    #|  aspect-ratio: 1;
    #|  border: 1px solid #f0c45d;
    #|  box-shadow: 0 0 0 1px rgba(15,20,21,0.72), 0 0 22px rgba(240,196,93,0.46);
    #|  transform: translate(-50%, -50%);
    #|  z-index: 1;
    #|}
    #|.landscape-target::before,
    #|.landscape-target::after {
    #|  content: "";
    #|  position: absolute;
    #|  background: #f0c45d;
    #|  left: 50%;
    #|  top: 50%;
    #|  transform: translate(-50%, -50%);
    #|}
    #|.landscape-target::before { width: 44%; height: 1px; }
    #|.landscape-target::after { width: 1px; height: 44%; }
    #|.landscape-label {
    #|  position: absolute;
    #|  left: calc(54% + clamp(36px, 6vw, 56px));
    #|  top: 48%;
    #|  transform: translateY(-50%);
    #|  z-index: 1;
    #|  max-width: 210px;
    #|  color: #f5f7f4;
    #|  text-shadow: 0 1px 6px rgba(0,0,0,0.9);
    #|}
    #|.landscape-label b,
    #|.landscape-caption b {
    #|  display: block;
    #|  font-size: 12px;
    #|  color: #f0c45d;
    #|  font-weight: 700;
    #|}
    #|.landscape-label span,
    #|.landscape-caption span {
    #|  display: block;
    #|  font-size: 13px;
    #|  line-height: 1.32;
    #|}
    #|.landscape-caption {
    #|  position: absolute;
    #|  left: 18px;
    #|  right: 18px;
    #|  bottom: 14px;
    #|  z-index: 1;
    #|  display: flex;
    #|  justify-content: space-between;
    #|  gap: 14px;
    #|  align-items: end;
    #|  text-shadow: 0 1px 6px rgba(0,0,0,0.9);
    #|}
    #|.zoom-stack {
    #|  display: grid;
    #|  grid-template-columns: minmax(240px, 1fr) minmax(200px, 248px);
    #|  gap: 16px;
    #|  align-items: center;
    #|  padding: 16px 18px 18px;
    #|  border-top: 1px solid rgba(255,255,255,0.2);
    #|  background:
    #|    radial-gradient(circle at 16% 12%, rgba(255,255,255,0.1), transparent 0 18%, transparent 26%),
    #|    linear-gradient(140deg, #111819 0%, #172224 56%, #20292a 100%);
    #|}
    #|.lola-map {
    #|  width: min(100%, 430px);
    #|  aspect-ratio: 1.12;
    #|  position: relative;
    #|  justify-self: center;
    #|  border: 1px solid rgba(255,255,255,0.34);
    #|  background: #12191c;
    #|  overflow: hidden;
    #|  filter: drop-shadow(0 0 22px rgba(186,205,199,0.2));
    #|}
    #|.site-marker {
    #|  fill: rgba(240,196,93,0.18);
    #|  stroke: #f0c45d;
    #|  stroke-width: 2;
    #|  vector-effect: non-scaling-stroke;
    #|}
    #|.route-trace {
    #|  fill: none;
    #|  stroke: #75d1c5;
    #|  stroke-width: 4;
    #|  stroke-linecap: round;
    #|  stroke-linejoin: round;
    #|  vector-effect: non-scaling-stroke;
    #|  filter: drop-shadow(0 0 5px rgba(117,209,197,0.85));
    #|}
    #|.lola-data-map {
    #|  width: 100%;
    #|  height: 100%;
    #|  display: block;
    #|}
    #|.lola-window {
    #|  stroke: rgba(255,255,255,0.2);
    #|  stroke-width: 0.8;
    #|  vector-effect: non-scaling-stroke;
    #|}
    #|.lola-window-selected {
    #|  stroke: #f0c45d;
    #|  stroke-width: 2.5;
    #|  vector-effect: non-scaling-stroke;
    #|  filter: drop-shadow(0 0 5px rgba(240,196,93,0.72));
    #|}
    #|.lola-label {
    #|  fill: rgba(255,255,255,0.72);
    #|  font-size: 8px;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|}
    #|.lola-source-label {
    #|  fill: rgba(245,247,244,0.82);
    #|  font-size: 10px;
    #|  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    #|}
    #|.site-pin {
    #|  fill: #f0c45d;
    #|  stroke: #171d1e;
    #|  stroke-width: 2;
    #|  vector-effect: non-scaling-stroke;
    #|}
    #|.map-controls {
    #|  position: absolute;
    #|  right: 10px;
    #|  top: 10px;
    #|  display: grid;
    #|  gap: 4px;
    #|}
    #|.map-controls span {
    #|  width: 28px;
    #|  height: 28px;
    #|  display: grid;
    #|  place-items: center;
    #|  border: 1px solid rgba(255,255,255,0.34);
    #|  background: rgba(13,18,20,0.64);
    #|  color: #f5f7f4;
    #|  font-size: 13px;
    #|}
    #|.lunar-summary {
    #|  display: grid;
    #|  gap: 10px;
    #|  align-content: center;
    #|}
    #|.lunar-summary b {
    #|  font-size: 13px;
    #|  color: #c8d0d0;
    #|  font-weight: 600;
    #|}
    #|.lunar-summary span {
    #|  display: block;
    #|  font-size: 14px;
    #|  line-height: 1.35;
    #|}
    #|.lunar-summary .hardware-denied {
    #|  color: #ffd7cf;
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
    #|.remediation-row {
    #|  border-color: color-mix(in srgb, var(--warn) 38%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--warn);
    #|}
    #|.simulation-packet-row {
    #|  border-color: color-mix(in srgb, var(--teal) 45%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--teal);
    #|}
    #|.simulation-decision-row {
    #|  border-color: color-mix(in srgb, var(--danger) 45%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
    #|}
    #|.remediation-margin-task-row {
    #|  border-color: color-mix(in srgb, var(--warn) 52%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--warn);
    #|}
    #|.remediation-margin-refresh-task-row {
    #|  border-color: color-mix(in srgb, var(--teal) 52%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--teal);
    #|}
    #|.remediation-margin-refresh-receipt-row {
    #|  border-color: color-mix(in srgb, var(--ok) 48%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.remediation-margin-refresh-followup-receipt-row {
    #|  border-color: color-mix(in srgb, var(--ok) 58%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.remediation-margin-receipt-row {
    #|  border-color: color-mix(in srgb, var(--ok) 44%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.remediation-margin-modeling-row {
    #|  border-color: color-mix(in srgb, var(--teal) 48%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--teal);
    #|}
    #|.remediation-margin-refresh-modeling-row {
    #|  border-color: color-mix(in srgb, var(--teal) 60%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--teal);
    #|}
    #|.remediation-margin-refresh-followup-modeling-row {
    #|  border-color: color-mix(in srgb, var(--teal) 66%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--teal);
    #|}
    #|.remediation-margin-refresh-followup-projection-row {
    #|  border-color: color-mix(in srgb, var(--danger) 52%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
    #|}
    #|.remediation-margin-cycle-closeout-row {
    #|  border-color: color-mix(in srgb, var(--danger) 60%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
    #|}
    #|.remediation-margin-closeout-action-row {
    #|  border-color: color-mix(in srgb, var(--warn) 64%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--warn);
    #|}
    #|.remediation-margin-reviewed-work-item-receipts-row {
    #|  border-color: color-mix(in srgb, var(--ok) 64%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.remediation-margin-reviewed-fresh-evidence-task-row {
    #|  border-color: color-mix(in srgb, var(--warn) 58%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--warn);
    #|}
    #|.remediation-margin-fresh-evidence-action-receipts-row {
    #|  border-color: color-mix(in srgb, var(--ok) 62%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.remediation-margin-regenerated-reviewed-work-item-receipts-row {
    #|  border-color: color-mix(in srgb, var(--teal) 66%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--teal);
    #|}
    #|.remediation-margin-regenerated-receipt-readiness-row {
    #|  border-color: color-mix(in srgb, var(--danger) 58%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
    #|}
    #|.regenerated-receipt-readiness-fresh-evidence-task-row {
    #|  border-color: color-mix(in srgb, var(--warn) 66%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--warn);
    #|}
    #|.regenerated-receipt-readiness-fresh-evidence-action-receipts-row {
    #|  border-color: color-mix(in srgb, var(--ok) 66%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--ok);
    #|}
    #|.regenerated-receipt-readiness-action-receipt-closeout-row {
    #|  border-color: color-mix(in srgb, var(--danger) 56%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
    #|}
    #|.remediation-margin-projection-row {
    #|  border-color: color-mix(in srgb, var(--danger) 42%, var(--line));
    #|  box-shadow: inset 3px 0 0 var(--danger);
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
    #|  .moon-globe { height: 300px; }
    #|  .moon-globe-canvas { height: 300px; }
    #|  .moon-landscape, .moon-landscape img { min-height: 300px; }
    #|  .landscape-label { left: 18px; right: 18px; top: 18px; transform: none; max-width: none; }
    #|  .landscape-caption { display: grid; justify-content: start; }
    #|  .zoom-stack { grid-template-columns: 1fr; }
    #|  .lola-map { width: min(100%, 360px); }
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
    #|const closeoutActionEntryId = 'moonclaw/first-trusted-square/remediation-margin-closeout-action-task';
    #|const closeoutActionReviewItemId = 'moonclaw-remediation-margin-closeout-action-review';
    #|let closeoutActionDecision = 'RequestEvidence';
    #|const decisionOptions = [
    #|  ['Accept', 'Accept'],
    #|  ['Reject', 'Reject'],
    #|  ['RequestEvidence', 'Need evidence'],
    #|];
    #|const closeoutActionDecisionOptions = [
    #|  ['Accept', 'Accept'],
    #|  ['RequestEvidence', 'Need evidence'],
    #|  ['Defer', 'Defer'],
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
    #|function svgEl(tag, attrs = {}, children = []) {
    #|  const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
    #|  for (const [key, value] of Object.entries(attrs)) {
    #|    if (key === 'text') node.textContent = value;
    #|    else node.setAttribute(key, value);
    #|  }
    #|  for (const child of children) node.append(child);
    #|  return node;
    #|}
    #|
    #|function lolaWindowFill(window, minElevation, maxElevation) {
    #|  const mid = (window.min_elevation_m + window.max_elevation_m) / 2;
    #|  const t = (mid - minElevation) / Math.max(1, maxElevation - minElevation);
    #|  const shade = Math.round(54 + t * 118);
    #|  const warm = Math.round(shade * 0.96);
    #|  return `rgb(${shade}, ${warm}, ${Math.round(shade * 0.86)})`;
    #|}
    #|
    #|function renderLolaDataViewport() {
    #|  const svg = document.getElementById('lola-data-map');
    #|  const windows = view.corridor_windows || [];
    #|  if (!svg || windows.length === 0) return;
    #|  const rows = windows.map(window => window.row_offset);
    #|  const cols = windows.map(window => window.col_offset);
    #|  const minRow = Math.min(...rows);
    #|  const maxRow = Math.max(...rows);
    #|  const minCol = Math.min(...cols);
    #|  const maxCol = Math.max(...cols);
    #|  const minElevation = Math.min(...windows.map(window => window.min_elevation_m));
    #|  const maxElevation = Math.max(...windows.map(window => window.max_elevation_m));
    #|  const pad = 18;
    #|  const span = 324;
    #|  const stepX = span / Math.max(1, (maxCol - minCol) / 4 + 1);
    #|  const stepY = span / Math.max(1, (maxRow - minRow) / 4 + 1);
    #|  const ordered = [...windows].sort((a, b) => a.rank - b.rank);
    #|  const selected = ordered.find(window => window.selected_route_id === view.selected_route_id) || ordered[0];
    #|  const cells = ordered.map(window => {
    #|    const x = pad + ((window.col_offset - minCol) / 4) * stepX;
    #|    const y = pad + ((window.row_offset - minRow) / 4) * stepY;
    #|    const selectedWindow = window.window_id === selected.window_id;
    #|    return svgEl('rect', {
    #|      class: selectedWindow ? 'lola-window lola-window-selected' : 'lola-window',
    #|      x: x.toFixed(2),
    #|      y: y.toFixed(2),
    #|      width: (stepX - 2).toFixed(2),
    #|      height: (stepY - 2).toFixed(2),
    #|      fill: lolaWindowFill(window, minElevation, maxElevation),
    #|      'data-window-id': window.window_id,
    #|      'data-rank': String(window.rank)
    #|    });
    #|  });
    #|  const routeX = pad + ((selected.col_offset - minCol) / 4) * stepX + stepX / 2;
    #|  const routeY = pad + ((selected.row_offset - minRow) / 4) * stepY + stepY / 2;
    #|  const route = svgEl('path', {
    #|    class: 'route-trace',
    #|    d: `M${pad + stepX * 0.5} ${pad + stepY * 7.7} C${routeX - 66} ${routeY + 38}, ${routeX - 32} ${routeY + 12}, ${routeX} ${routeY}`
    #|  });
    #|  const marker = svgEl('rect', {
    #|    class: 'site-marker',
    #|    x: (routeX - stepX * 0.52).toFixed(2),
    #|    y: (routeY - stepY * 0.52).toFixed(2),
    #|    width: (stepX * 1.04).toFixed(2),
    #|    height: (stepY * 1.04).toFixed(2),
    #|    rx: '2'
    #|  });
    #|  const pin = svgEl('circle', {
    #|    class: 'site-pin',
    #|    cx: routeX.toFixed(2),
    #|    cy: routeY.toFixed(2),
    #|    r: '5'
    #|  });
    #|  const label = svgEl('text', {
    #|    class: 'lola-source-label',
    #|    x: '18',
    #|    y: '356',
    #|    text: `LOLA GDR 20m DEM, ${windows.length} measured corridor windows`
    #|  });
    #|  svg.replaceChildren(
    #|    svgEl('rect', { x: '0', y: '0', width: '360', height: '380', fill: '#111819' }),
    #|    svgEl('g', {}, cells),
    #|    route,
    #|    marker,
    #|    pin,
    #|    svgEl('text', {
    #|      class: 'lola-label',
    #|      x: (routeX + 8).toFixed(2),
    #|      y: (routeY - 8).toFixed(2),
    #|      text: `rank ${selected.rank} ${view.selected_route_id}`
    #|    }),
    #|    label
    #|  );
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
    #|function entryById(id) {
    #|  return book.entries.find(entry => entry.entry_id === id);
    #|}
    #|
    #|function renderGapEvidence() {
    #|  const ids = [
    #|    'moonclaw/first-trusted-square/moonrobo-gap-remediation-task',
    #|    'moonclaw/first-trusted-square/moonrobo-gap-remediation-receipt'
    #|  ];
    #|  const entries = ids
    #|    .map(entryById)
    #|    .filter(Boolean);
    #|  document.getElementById('moonclaw-gap-evidence').replaceChildren(...entries.map(entry =>
    #|    el('div', { className: 'review-row', 'data-entry-id': entry.entry_id }, [
    #|      el('b', { text: `${entry.title} - ${entry.kind}` }),
    #|      el('span', { text: entry.summary }),
    #|      el('p', { className: 'source-path', text: entry.path })
    #|    ])
    #|  ));
    #|}
    #|
    #|function renderRemediationEvidence() {
    #|  const ids = [
    #|    'terrain-remediation/first-trusted-square/northeast-stepout',
    #|    'local-horizon/first-trusted-square/northeast-stepout',
    #|    'energy-remediation/first-trusted-square/northeast-stepout'
    #|  ];
    #|  const entries = ids.map(entryById).filter(Boolean);
    #|  document.getElementById('selected-route-remediation').replaceChildren(...entries.map(entry =>
    #|    el('div', { className: 'review-row remediation-row', 'data-entry-id': entry.entry_id }, [
    #|      el('b', { text: `${entry.title} - ${entry.kind}` }),
    #|      el('span', { text: entry.summary }),
    #|      el('p', { className: 'source-path', text: `moonbook://moonmoon/first-trusted-square/${entry.path}` })
    #|    ])
    #|  ));
    #|}
    #|
    #|function renderMoonBookEntry(targetId, entryId, rowClass) {
    #|  const entry = entryById(entryId);
    #|  const target = document.getElementById(targetId);
    #|  if (!entry) {
    #|    target.replaceChildren();
    #|    return;
    #|  }
    #|  target.replaceChildren(el('div', {
    #|    className: `review-row ${rowClass}`,
    #|    'data-entry-id': entry.entry_id
    #|  }, [
    #|    el('b', { text: `${entry.title} - ${entry.kind}` }),
    #|    el('span', { text: entry.summary }),
    #|    el('p', { className: 'source-path', text: `moonbook://moonmoon/first-trusted-square/${entry.path}` })
    #|  ]));
    #|}
    #|
    #|function renderSimulationReviewPacket() {
    #|  renderMoonBookEntry(
    #|    'simulation-review-packet',
    #|    'moonrobo/first-trusted-square/simulation-review-packet',
    #|    'simulation-packet-row'
    #|  );
    #|}
    #|
    #|function renderSimulationReviewDecision() {
    #|  renderMoonBookEntry(
    #|    'simulation-review-decision',
    #|    'moonrobo/first-trusted-square/simulation-review-decision',
    #|    'simulation-decision-row'
    #|  );
    #|}
    #|
    #|function renderSimulationBlockerReduction() {
    #|  renderMoonBookEntry(
    #|    'simulation-blocker-reduction',
    #|    'moonrobo/first-trusted-square/simulation-blocker-reduction',
    #|    'simulation-blocker-reduction-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginTask() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-task',
    #|    'moonclaw/first-trusted-square/remediation-margin-task',
    #|    'remediation-margin-task-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshTask() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-task',
    #|    'moonclaw/first-trusted-square/remediation-margin-refresh-task',
    #|    'remediation-margin-refresh-task-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshFollowupTask() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-followup-task',
    #|    'moonclaw/first-trusted-square/remediation-margin-refresh-followup-task',
    #|    'remediation-margin-refresh-followup-task-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshFollowupReceipt() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-followup-receipt',
    #|    'moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt',
    #|    'remediation-margin-refresh-followup-receipt-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshReceipt() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-receipt',
    #|    'moonclaw/first-trusted-square/remediation-margin-refresh-receipt',
    #|    'remediation-margin-refresh-receipt-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginReceipt() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-receipt',
    #|    'moonclaw/first-trusted-square/remediation-margin-receipt',
    #|    'remediation-margin-receipt-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginModeling() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-modeling',
    #|    'moonrobo/first-trusted-square/remediation-margin-modeling',
    #|    'remediation-margin-modeling-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshModeling() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-modeling',
    #|    'moonrobo/first-trusted-square/remediation-margin-refresh-modeling',
    #|    'remediation-margin-refresh-modeling-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshFollowupModeling() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-followup-modeling',
    #|    'moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling',
    #|    'remediation-margin-refresh-followup-modeling-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshFollowupProjection() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-followup-projection',
    #|    'moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection',
    #|    'remediation-margin-refresh-followup-projection-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginCycleCloseout() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-cycle-closeout',
    #|    'moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy',
    #|    'remediation-margin-cycle-closeout-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginCloseoutAction() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-closeout-action',
    #|    'moonclaw/first-trusted-square/remediation-margin-closeout-action-task',
    #|    'remediation-margin-closeout-action-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginReviewedActionPlan() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-reviewed-action-plan',
    #|    'moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan',
    #|    'remediation-margin-reviewed-action-plan-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginReviewedWorkItems() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-reviewed-work-items',
    #|    'moonclaw/first-trusted-square/remediation-margin-reviewed-work-items',
    #|    'remediation-margin-reviewed-work-items-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginReviewedWorkItemReceipts() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-reviewed-work-item-receipts',
    #|    'moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts',
    #|    'remediation-margin-reviewed-work-item-receipts-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginReviewedFreshEvidenceTask() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-reviewed-fresh-evidence-task',
    #|    'moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task',
    #|    'remediation-margin-reviewed-fresh-evidence-task-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginFreshEvidenceActionReceipts() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-fresh-evidence-action-receipts',
    #|    'moonclaw/first-trusted-square/remediation-margin-fresh-evidence-action-receipts',
    #|    'remediation-margin-fresh-evidence-action-receipts-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRegeneratedReviewedWorkItemReceipts() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-regenerated-reviewed-work-item-receipts',
    #|    'moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts',
    #|    'remediation-margin-regenerated-reviewed-work-item-receipts-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRegeneratedReceiptReadiness() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-regenerated-receipt-readiness',
    #|    'moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness',
    #|    'remediation-margin-regenerated-receipt-readiness-row'
    #|  );
    #|}
    #|
    #|function renderRegeneratedReceiptReadinessFreshEvidenceTask() {
    #|  renderMoonBookEntry(
    #|    'regenerated-receipt-readiness-fresh-evidence-task',
    #|    'moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task',
    #|    'regenerated-receipt-readiness-fresh-evidence-task-row'
    #|  );
    #|}
    #|
    #|function renderRegeneratedReceiptReadinessFreshEvidenceActionReceipts() {
    #|  renderMoonBookEntry(
    #|    'regenerated-receipt-readiness-fresh-evidence-action-receipts',
    #|    'moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-action-receipts',
    #|    'regenerated-receipt-readiness-fresh-evidence-action-receipts-row'
    #|  );
    #|}
    #|
    #|function renderRegeneratedReceiptReadinessActionReceiptCloseout() {
    #|  renderMoonBookEntry(
    #|    'regenerated-receipt-readiness-action-receipt-closeout',
    #|    'moonrobo/first-trusted-square/regenerated-receipt-readiness-action-receipt-closeout',
    #|    'regenerated-receipt-readiness-action-receipt-closeout-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginRefreshProjection() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-refresh-projection',
    #|    'moonrobo/first-trusted-square/remediation-margin-refresh-projection',
    #|    'remediation-margin-refresh-projection-row'
    #|  );
    #|}
    #|
    #|function renderRemediationMarginProjection() {
    #|  renderMoonBookEntry(
    #|    'remediation-margin-projection',
    #|    'moonrobo/first-trusted-square/remediation-margin-projection',
    #|    'remediation-margin-projection-row'
    #|  );
    #|}
    #|
    #|function transitionDecisionStatus(decision) {
    #|  if (decision === 'Accept') return 'Accepted';
    #|  if (decision === 'Reject') return 'Rejected';
    #|  if (decision === 'Defer') return 'Deferred';
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
    #|  if (decision === 'Defer') return 'defer';
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
    #|function closeoutActionEntry() {
    #|  return entryById(closeoutActionEntryId);
    #|}
    #|
    #|function closeoutActionEvidenceRefs(entry) {
    #|  if (!entry) return [];
    #|  return [{
    #|    ref_id: closeoutActionReviewItemId,
    #|    entry_id: entry.entry_id,
    #|    path: entry.path,
    #|    immutable_uri: `moonbook://moonmoon/first-trusted-square/${entry.path}#${closeoutActionReviewItemId}`
    #|  }];
    #|}
    #|
    #|function buildCloseoutActionReviewTransition() {
    #|  const entry = closeoutActionEntry();
    #|  return {
    #|    transition_id: `rabbita-${closeoutActionReviewItemId}-${transitionSuffix(closeoutActionDecision)}`,
    #|    item_id: closeoutActionReviewItemId,
    #|    entry_id: closeoutActionEntryId,
    #|    previous_status: 'NeedsReview',
    #|    decision: closeoutActionDecision,
    #|    resulting_status: transitionDecisionStatus(closeoutActionDecision),
    #|    reviewer_id: 'operator/rabbita-closeout-action-review',
    #|    reviewer_role: 'moonclaw-closeout-action-review',
    #|    timestamp_policy: 'operator-browser-export',
    #|    recorded_at_utc: new Date().toISOString(),
    #|    append_only: true,
    #|    hardware_authority_change: false,
    #|    hardware_state: 'HardwareDenied',
    #|    hardware_authority: 'moonmoon-safety-gate-only',
    #|    source_evidence_refs: closeoutActionEvidenceRefs(entry),
    #|    rationale: `Rabbita ${transitionSuffix(closeoutActionDecision)} decision for ${closeoutActionReviewItemId}: ${entry ? entry.summary : 'closeout action entry missing'}`
    #|  };
    #|}
    #|
    #|function closeoutActionReviewExport() {
    #|  return {
    #|    workspace: book.workspace,
    #|    site_id: book.site_id,
    #|    generated_by: 'output/ui/rabbita/first_trusted_square.html',
    #|    review_kind: 'moonclaw-remediation-margin-closeout-action',
    #|    transitions: [buildCloseoutActionReviewTransition()]
    #|  };
    #|}
    #|
    #|function renderCloseoutActionReviewExport() {
    #|  const box = document.getElementById('closeout-action-review-export');
    #|  if (!box) return;
    #|  box.value = JSON.stringify(closeoutActionReviewExport(), null, 2);
    #|}
    #|
    #|function renderCloseoutActionReview() {
    #|  const list = document.getElementById('closeout-action-review');
    #|  if (!list) return;
    #|  const entry = closeoutActionEntry();
    #|  const controls = el('div', { className: 'decision-group', role: 'group', 'aria-label': closeoutActionReviewItemId },
    #|    closeoutActionDecisionOptions.map(([decision, label]) => {
    #|      const button = el('button', {
    #|        className: 'decision-button',
    #|        type: 'button',
    #|        'aria-pressed': String(decision === closeoutActionDecision),
    #|        text: label
    #|      });
    #|      button.addEventListener('click', () => {
    #|        closeoutActionDecision = decision;
    #|        renderCloseoutActionReview();
    #|      });
    #|      return button;
    #|    })
    #|  );
    #|  list.replaceChildren(el('div', {
    #|    className: 'clearance-row closeout-action-review-row',
    #|    'data-review-decision': closeoutActionDecision,
    #|    'data-review-status': transitionDecisionStatus(closeoutActionDecision),
    #|    'data-entry-id': closeoutActionEntryId,
    #|  }, [
    #|    el('b', { text: `${closeoutActionReviewItemId} - ${transitionDecisionStatus(closeoutActionDecision)}` }),
    #|    el('span', { text: entry ? entry.summary : 'Closeout action entry is missing from MoonBook' }),
    #|    controls
    #|  ]));
    #|  renderCloseoutActionReviewExport();
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
    #|function copyCloseoutActionReviewExport() {
    #|  const box = document.getElementById('closeout-action-review-export');
    #|  const status = document.getElementById('closeout-action-review-export-status');
    #|  if (!navigator.clipboard) {
    #|    box.select();
    #|    status.textContent = 'Select the export JSON manually';
    #|    return;
    #|  }
    #|  navigator.clipboard.writeText(box.value).then(() => {
    #|    status.textContent = 'Closeout action review JSON copied';
    #|  }).catch(() => {
    #|    box.select();
    #|    status.textContent = 'Select the export JSON manually';
    #|  });
    #|}
    #|
    #|function downloadCloseoutActionReviewExport() {
    #|  const blob = new Blob([document.getElementById('closeout-action-review-export').value], { type: 'application/json' });
    #|  const link = document.createElement('a');
    #|  link.href = URL.createObjectURL(blob);
    #|  link.download = 'first_trusted_square_closeout_action_review.json';
    #|  link.click();
    #|  URL.revokeObjectURL(link.href);
    #|}
    #|
    #|function render() {
    #|  renderLolaDataViewport();
    #|  renderToolbar();
    #|  renderGrid();
    #|  renderInspector();
    #|  renderRoutes();
    #|  renderFacts();
    #|  renderReview();
    #|  renderGapEvidence();
    #|  renderRemediationEvidence();
    #|  renderSimulationReviewPacket();
    #|  renderSimulationReviewDecision();
    #|  renderSimulationBlockerReduction();
    #|  renderRemediationMarginTask();
    #|  renderRemediationMarginRefreshTask();
    #|  renderRemediationMarginRefreshFollowupTask();
    #|  renderRemediationMarginRefreshFollowupReceipt();
    #|  renderRemediationMarginRefreshReceipt();
    #|  renderRemediationMarginReceipt();
    #|  renderRemediationMarginModeling();
    #|  renderRemediationMarginRefreshModeling();
    #|  renderRemediationMarginRefreshFollowupModeling();
    #|  renderRemediationMarginRefreshFollowupProjection();
    #|  renderRemediationMarginCycleCloseout();
    #|  renderRemediationMarginCloseoutAction();
    #|  renderRemediationMarginReviewedActionPlan();
    #|  renderRemediationMarginReviewedWorkItems();
    #|  renderRemediationMarginReviewedWorkItemReceipts();
    #|  renderRemediationMarginReviewedFreshEvidenceTask();
    #|  renderRemediationMarginFreshEvidenceActionReceipts();
    #|  renderRemediationMarginRegeneratedReviewedWorkItemReceipts();
    #|  renderRemediationMarginRegeneratedReceiptReadiness();
    #|  renderRegeneratedReceiptReadinessFreshEvidenceTask();
    #|  renderRegeneratedReceiptReadinessFreshEvidenceActionReceipts();
    #|  renderRegeneratedReceiptReadinessActionReceiptCloseout();
    #|  renderRemediationMarginRefreshProjection();
    #|  renderRemediationMarginProjection();
    #|  renderClearanceReview();
    #|  renderCloseoutActionReview();
    #|}
    #|
    #|document.getElementById('copy-transition-export').addEventListener('click', copyTransitionExport);
    #|document.getElementById('download-transition-export').addEventListener('click', downloadTransitionExport);
    #|document.getElementById('copy-closeout-action-review-export').addEventListener('click', copyCloseoutActionReviewExport);
    #|document.getElementById('download-closeout-action-review-export').addEventListener('click', downloadCloseoutActionReviewExport);
    #|render();
    #|</script>
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
