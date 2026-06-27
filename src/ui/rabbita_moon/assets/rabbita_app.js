const view = JSON.parse(document.getElementById('moonmoon-view-model').textContent);
const book = JSON.parse(document.getElementById('moonmoon-moonbook').textContent);
const noetixTrace = JSON.parse(document.getElementById('moonmoon-noetix-walk').textContent);
const noetixLinkPoseTrace = JSON.parse(document.getElementById('moonmoon-noetix-link-poses').textContent);
const evidence = window.RabbitaEvidence.create(book);
let activeLayer = view.active_layer_id;
let selectedCellId = view.selected_cell_id;
let activeNoetixFrame = 0;
const reviewByItem = new Map(book.review_queue.map(item => [item.item_id, item]));
const transitionByItem = new Map(book.review_transitions.map(item => [item.item_id, item]));
const clearanceItems = book.review_queue.filter(item => item.item_id.startsWith('clear-'));
const clearanceDecisions = new Map(clearanceItems.map(item => [item.item_id, initialClearanceDecision(item)]));
const closeoutActionEntryId = 'moonclaw/first-trusted-square/remediation-margin-closeout-action-task';
const closeoutActionReviewItemId = 'moonclaw-remediation-margin-closeout-action-review';
let closeoutActionDecision = 'RequestEvidence';
let activeEvidenceFamily = 'all';
const decisionOptions = [
  ['Accept', 'Accept'],
  ['Reject', 'Reject'],
  ['RequestEvidence', 'Need evidence'],
];
const closeoutActionDecisionOptions = [
  ['Accept', 'Accept'],
  ['RequestEvidence', 'Need evidence'],
  ['Defer', 'Defer'],
];

function layerValue(cell, id) {
  return cell.layer_values.find(value => value.layer_id === id) || cell.layer_values[0];
}

function colorFor(value) {
  const x = Math.max(0, Math.min(1, Number(value.intensity || 0)));
  if (activeLayer === 'hazard') return value.status === 'blocked'
    ? `rgb(${150 + 70 * x}, ${52 - 16 * x}, ${42 - 10 * x})`
    : `rgb(48, ${128 + 60 * x}, 96)`;
  if (activeLayer === 'power') return `rgb(${72 + 130 * x}, ${116 + 56 * x}, ${126 - 42 * x})`;
  if (activeLayer === 'route') return `rgb(${44 + 45 * x}, ${82 + 55 * x}, ${138 + 45 * x})`;
  if (activeLayer === 'evidence') return `rgb(${62 + 30 * x}, ${118 + 70 * x}, ${103 + 35 * x})`;
  return `rgb(${72 + 95 * x}, ${74 + 80 * x}, ${70 + 36 * x})`;
}

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (key === 'className') node.className = value;
    else if (key === 'text') node.textContent = value;
    else node.setAttribute(key, value);
  }
  for (const child of children) node.append(child);
  return node;
}

function svgEl(tag, attrs = {}, children = []) {
  const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (key === 'text') node.textContent = value;
    else node.setAttribute(key, value);
  }
  for (const child of children) node.append(child);
  return node;
}

function lolaWindowFill(window, minElevation, maxElevation) {
  const mid = (window.min_elevation_m + window.max_elevation_m) / 2;
  const t = (mid - minElevation) / Math.max(1, maxElevation - minElevation);
  const shade = Math.round(54 + t * 118);
  const warm = Math.round(shade * 0.96);
  return `rgb(${shade}, ${warm}, ${Math.round(shade * 0.86)})`;
}

function renderLolaDataViewport() {
  const svg = document.getElementById('lola-data-map');
  const windows = view.corridor_windows || [];
  if (!svg || windows.length === 0) return;
  const rows = windows.map(window => window.row_offset);
  const cols = windows.map(window => window.col_offset);
  const minRow = Math.min(...rows);
  const maxRow = Math.max(...rows);
  const minCol = Math.min(...cols);
  const maxCol = Math.max(...cols);
  const minElevation = Math.min(...windows.map(window => window.min_elevation_m));
  const maxElevation = Math.max(...windows.map(window => window.max_elevation_m));
  const pad = 18;
  const span = 324;
  const stepX = span / Math.max(1, (maxCol - minCol) / 4 + 1);
  const stepY = span / Math.max(1, (maxRow - minRow) / 4 + 1);
  const ordered = [...windows].sort((a, b) => a.rank - b.rank);
  const selected = ordered.find(window => window.selected_route_id === view.selected_route_id) || ordered[0];
  const cells = ordered.map(window => {
    const x = pad + ((window.col_offset - minCol) / 4) * stepX;
    const y = pad + ((window.row_offset - minRow) / 4) * stepY;
    const selectedWindow = window.window_id === selected.window_id;
    return svgEl('rect', {
      class: selectedWindow ? 'lola-window lola-window-selected' : 'lola-window',
      x: x.toFixed(2),
      y: y.toFixed(2),
      width: (stepX - 2).toFixed(2),
      height: (stepY - 2).toFixed(2),
      fill: lolaWindowFill(window, minElevation, maxElevation),
      'data-window-id': window.window_id,
      'data-rank': String(window.rank)
    });
  });
  const routeX = pad + ((selected.col_offset - minCol) / 4) * stepX + stepX / 2;
  const routeY = pad + ((selected.row_offset - minRow) / 4) * stepY + stepY / 2;
  const route = svgEl('path', {
    class: 'route-trace',
    d: `M${pad + stepX * 0.5} ${pad + stepY * 7.7} C${routeX - 66} ${routeY + 38}, ${routeX - 32} ${routeY + 12}, ${routeX} ${routeY}`
  });
  const marker = svgEl('rect', {
    class: 'site-marker',
    x: (routeX - stepX * 0.52).toFixed(2),
    y: (routeY - stepY * 0.52).toFixed(2),
    width: (stepX * 1.04).toFixed(2),
    height: (stepY * 1.04).toFixed(2),
    rx: '2'
  });
  const pin = svgEl('circle', {
    class: 'site-pin',
    cx: routeX.toFixed(2),
    cy: routeY.toFixed(2),
    r: '5'
  });
  const label = svgEl('text', {
    class: 'lola-source-label',
    x: '18',
    y: '356',
    text: `LOLA GDR 20m DEM, ${windows.length} measured corridor windows`
  });
  svg.replaceChildren(
    svgEl('rect', { x: '0', y: '0', width: '360', height: '380', fill: '#111819' }),
    svgEl('g', {}, cells),
    route,
    marker,
    pin,
    svgEl('text', {
      class: 'lola-label',
      x: (routeX + 8).toFixed(2),
      y: (routeY - 8).toFixed(2),
      text: `rank ${selected.rank} ${view.selected_route_id}`
    }),
    label
  );
}

function renderToolbar() {
  const toolbar = document.getElementById('layer-toolbar');
  toolbar.replaceChildren(...view.layers.map(layer => {
    const button = el('button', {
      className: 'layer-button',
      type: 'button',
      'aria-pressed': String(layer.layer_id === activeLayer),
      title: `${layer.label}: ${layer.status}`,
      text: layer.label
    });
    button.addEventListener('click', () => {
      activeLayer = layer.layer_id;
      render();
    });
    return button;
  }));
}

function renderGrid() {
  const grid = document.getElementById('terrain-grid');
  grid.style.setProperty('--rows', view.viewport.rows);
  grid.style.setProperty('--cols', view.viewport.cols);
  grid.replaceChildren(...view.terrain_cells.map(cell => {
    const value = layerValue(cell, activeLayer);
    const button = el('button', {
      className: 'terrain-cell',
      type: 'button',
      'aria-selected': String(cell.cell_id === selectedCellId),
      title: `${cell.cell_id}: ${value.value_label}`,
    }, [el('span', {
      className: 'cell-label',
      text: `r${cell.row} c${cell.col}\n${value.value_label}`
    })]);
    button.style.background = colorFor(value);
    button.addEventListener('click', () => {
      selectedCellId = cell.cell_id;
      render();
    });
    return button;
  }));
}

function selectedCell() {
  return view.terrain_cells.find(cell => cell.cell_id === selectedCellId) || view.terrain_cells[0];
}

function renderInspector() {
  const cell = selectedCell();
  const value = layerValue(cell, activeLayer);
  document.getElementById('selected-cell').textContent = cell.cell_id;
  document.getElementById('active-layer').textContent = `${activeLayer}: ${value.value_label}`;
  const metrics = [
    ['Elevation', `${cell.elevation_m} m`],
    ['Slope', `${cell.slope_grade.toFixed(3)} grade`],
    ['Roughness', `${cell.roughness_m.toFixed(3)} m`],
    ['Hazard', cell.hazard],
    ['Source', cell.source_dataset_id],
    ['Confidence', `${Math.round(cell.confidence * 100)}%`],
  ];
  document.getElementById('metrics').replaceChildren(...metrics.map(([label, value]) =>
    el('div', { className: 'metric' }, [
      el('b', { text: label }),
      el('span', { text: value })
    ])
  ));
}

function renderRoutes() {
  document.getElementById('routes').replaceChildren(...view.routes.map(route =>
    el('div', { className: 'route-row', 'aria-current': String(route.selected) }, [
      el('b', { text: `${route.label} - ${route.decision}` }),
      el('span', { text: `score ${route.score}, grade ${route.max_grade}, roughness ${route.roughness_m} m` }),
      el('p', { text: route.next_action })
    ])
  ));
}

function renderFacts() {
  document.getElementById('facts').replaceChildren(...view.inspector_facts.map(fact =>
    el('div', { className: 'fact-row' }, [
      el('b', { text: `${fact.label} - ${fact.status}` }),
      el('span', { text: fact.value }),
      el('p', { className: 'source-path', text: fact.evidence_path })
    ])
  ));
}

function renderReview() {
  const rows = ['workspace-materialized', 'route-direct-lola-window', 'corridor-scan-best-window', 'energy-window', 'moonrobo-handoff']
    .map(id => ({ item: reviewByItem.get(id), transition: transitionByItem.get(id) }))
    .filter(row => row.item && row.transition);
  document.getElementById('review').replaceChildren(...rows.map(row =>
    el('div', { className: 'review-row' }, [
      el('b', { text: `${row.item.item_id} - ${row.item.status}` }),
      el('span', { text: row.item.reason }),
      el('p', { className: 'source-path', text: row.transition.source_evidence_refs.map(ref => ref.immutable_uri).join(' | ') })
    ])
  ));
}

function renderGapEvidence() {
  const entries = evidence.gapEvidenceEntries();
  document.getElementById('moonclaw-gap-evidence').replaceChildren(...entries.map(entry =>
    el('div', { className: 'review-row', 'data-entry-id': entry.entry_id }, [
      el('b', { text: `${entry.title} - ${entry.kind}` }),
      el('span', { text: entry.summary }),
      el('p', { className: 'source-path', text: entry.path })
    ])
  ));
}

function renderRemediationEvidence() {
  const entries = evidence.selectedRouteRemediationEntries();
  document.getElementById('selected-route-remediation').replaceChildren(...entries.map(entry =>
    el('div', { className: 'review-row remediation-row', 'data-entry-id': entry.entry_id }, [
      el('b', { text: `${entry.title} - ${entry.kind}` }),
      el('span', { text: entry.summary }),
      el('p', { className: 'source-path', text: `moonbook://moonmoon/first-trusted-square/${entry.path}` })
    ])
  ));
}

function noetixFrames() {
  return noetixTrace.frames || [];
}

function noetixPoseFrames() {
  return noetixLinkPoseTrace.frames || [];
}

function noetixPoseFrame(frameIndex) {
  const poses = noetixPoseFrames();
  return poses.find(frame => frame.frame_index === frameIndex) || poses[frameIndex] || { links: [] };
}

function noetixLinkMap(poseFrame) {
  return new Map((poseFrame.links || []).map(link => [link.link_name, link]));
}

function noetixPointBounds(frames, poseFrames) {
  const points = frames.flatMap(frame => [
    frame.body_position,
    frame.left_foot.position,
    frame.right_foot.position,
  ]);
  for (const poseFrame of poseFrames) {
    for (const link of poseFrame.links || []) points.push(link.world_position);
  }
  const xs = points.map(point => point.x);
  const zs = points.map(point => point.z);
  return {
    minX: Math.min(...xs),
    maxX: Math.max(...xs),
    minZ: Math.min(...zs),
    maxZ: Math.max(...zs),
  };
}

function noetixProjector(frames, poseFrames) {
  const bounds = noetixPointBounds(frames, poseFrames);
  const xSpan = Math.max(0.001, bounds.maxX - bounds.minX);
  const zSpan = Math.max(0.001, bounds.maxZ - bounds.minZ);
  return point => ({
    x: 36 + ((point.x - bounds.minX) / xSpan) * 348,
    y: 136 - ((point.z - bounds.minZ) / zSpan) * 92,
  });
}

function noetixPath(frames, pointForFrame, project) {
  return frames.map(frame => {
    const point = project(pointForFrame(frame));
    return `${point.x.toFixed(2)},${point.y.toFixed(2)}`;
  }).join(' ');
}

function noetixStatusClass(status) {
  if (status === 'ok' || status === 'walking') return 'ok';
  if (String(status).includes('review')) return 'review';
  return 'blocked';
}

function noetixLinkRoleClass(role) {
  if (role === 'arm' || role === 'hand') return 'arm';
  if (role === 'leg' || role === 'foot') return 'leg';
  return 'body';
}

function noetixLinkSegments(poseFrame, project) {
  const links = noetixLinkMap(poseFrame);
  return (poseFrame.links || [])
    .filter(link => link.parent_link && links.has(link.parent_link))
    .map(link => {
      const parent = links.get(link.parent_link);
      const a = project(parent.world_position);
      const b = project(link.world_position);
      const role = noetixLinkRoleClass(link.role);
      return svgEl('line', {
        class: `noetix-link-segment noetix-link-${role}`,
        x1: a.x.toFixed(2),
        y1: a.y.toFixed(2),
        x2: b.x.toFixed(2),
        y2: b.y.toFixed(2),
        'data-link-name': link.link_name,
        'data-parent-link': link.parent_link
      });
    });
}

function noetixLinkJoints(poseFrame, project) {
  return (poseFrame.links || []).map(link => {
    const point = project(link.world_position);
    const role = noetixLinkRoleClass(link.role);
    return svgEl('circle', {
      class: `noetix-link-joint noetix-link-${role}`,
      cx: point.x.toFixed(2),
      cy: point.y.toFixed(2),
      r: link.role === 'foot' ? '4.6' : '3.2',
      'data-link-name': link.link_name
    });
  });
}

function renderNoetixWalkViewer(frames, frame, poseFrame, project) {
  const body = project(frame.body_position);
  const left = project(frame.left_foot.position);
  const right = project(frame.right_foot.position);
  const supportFoot = frame.support_phase === 'left-support' ? left : right;
  const linkSegments = noetixLinkSegments(poseFrame, project);
  const linkJoints = noetixLinkJoints(poseFrame, project);
  const svg = svgEl('svg', {
    class: 'noetix-stage',
    viewBox: '0 0 420 170',
    role: 'img',
    'aria-label': `Noetix frame ${frame.frame_index} ${frame.support_phase}`
  }, [
    svgEl('rect', { class: 'noetix-stage-bg', x: '0', y: '0', width: '420', height: '170' }),
    svgEl('line', { class: 'noetix-ground', x1: '28', y1: '138', x2: '392', y2: '138' }),
    svgEl('polyline', {
      class: 'noetix-body-path',
      points: noetixPath(frames, item => item.body_position, project)
    }),
    svgEl('polyline', {
      class: 'noetix-foot-path noetix-left-path',
      points: noetixPath(frames, item => item.left_foot.position, project)
    }),
    svgEl('polyline', {
      class: 'noetix-foot-path noetix-right-path',
      points: noetixPath(frames, item => item.right_foot.position, project)
    }),
    svgEl('g', { class: 'noetix-link-segments' }, linkSegments),
    svgEl('g', { class: 'noetix-link-joints' }, linkJoints),
    svgEl('circle', {
      class: `noetix-foot noetix-foot-left noetix-status-${noetixStatusClass(frame.left_foot.status)}`,
      cx: left.x.toFixed(2),
      cy: left.y.toFixed(2),
      r: frame.left_foot.in_contact ? '7' : '5'
    }),
    svgEl('circle', {
      class: `noetix-foot noetix-foot-right noetix-status-${noetixStatusClass(frame.right_foot.status)}`,
      cx: right.x.toFixed(2),
      cy: right.y.toFixed(2),
      r: frame.right_foot.in_contact ? '7' : '5'
    }),
    svgEl('circle', {
      class: `noetix-body noetix-status-${noetixStatusClass(frame.status)}`,
      cx: body.x.toFixed(2),
      cy: body.y.toFixed(2),
      r: '9'
    }),
    svgEl('line', {
      class: 'noetix-support-line',
      x1: supportFoot.x.toFixed(2),
      y1: supportFoot.y.toFixed(2),
      x2: body.x.toFixed(2),
      y2: body.y.toFixed(2)
    }),
    svgEl('text', { class: 'noetix-axis-label', x: '28', y: '158', text: noetixTrace.endless_axis }),
    svgEl('text', { class: 'noetix-frame-label', x: '318', y: '24', text: `frame ${frame.frame_index}` })
  ]);
  document.getElementById('noetix-walk-viewer').replaceChildren(svg);
}

function renderNoetixWalkControls(frames) {
  const controls = document.getElementById('noetix-walk-controls');
  const previous = el('button', {
    className: 'noetix-step-button',
    type: 'button',
    title: 'Previous frame',
    text: '‹'
  });
  const next = el('button', {
    className: 'noetix-step-button',
    type: 'button',
    title: 'Next frame',
    text: '›'
  });
  const scrubber = el('input', {
    className: 'noetix-scrubber',
    type: 'range',
    min: '0',
    max: String(Math.max(0, frames.length - 1)),
    step: '1',
    value: String(activeNoetixFrame),
    'aria-label': 'Noetix walk frame'
  });
  scrubber.value = String(activeNoetixFrame);
  previous.addEventListener('click', () => {
    activeNoetixFrame = activeNoetixFrame <= 0 ? frames.length - 1 : activeNoetixFrame - 1;
    renderNoetixWalk();
  });
  next.addEventListener('click', () => {
    activeNoetixFrame = (activeNoetixFrame + 1) % frames.length;
    renderNoetixWalk();
  });
  scrubber.addEventListener('input', () => {
    activeNoetixFrame = Number(scrubber.value);
    renderNoetixWalk();
  });
  controls.replaceChildren(previous, scrubber, next);
}

function renderNoetixWalkFacts(frame, poseFrame) {
  const jointCount = frame.joint_phases.length;
  const linkCount = (poseFrame.links || []).length;
  const facts = [
    ['phase', frame.support_phase],
    ['time', `${frame.time_s.toFixed(2)} s`],
    ['body x', `${frame.body_position.x.toFixed(3)} m`],
    ['left foot', `${frame.left_foot.status}, ${frame.left_foot.clearance_m.toFixed(3)} m`],
    ['right foot', `${frame.right_foot.status}, ${frame.right_foot.clearance_m.toFixed(3)} m`],
    ['joints', `${jointCount} kinematic phases`],
    ['links', `${linkCount} URDF-reference poses`],
    ['pose status', poseFrame.status || noetixLinkPoseTrace.status],
  ];
  document.getElementById('noetix-walk-facts').replaceChildren(...facts.map(([label, value]) =>
    el('div', { className: 'noetix-fact' }, [
      el('b', { text: label }),
      el('span', { text: value })
    ])
  ));
}

function renderNoetixWalk() {
  const frames = noetixFrames();
  if (!frames.length) return;
  activeNoetixFrame = Math.max(0, Math.min(frames.length - 1, activeNoetixFrame));
  const frame = frames[activeNoetixFrame];
  const poseFrames = noetixPoseFrames();
  const poseFrame = noetixPoseFrame(frame.frame_index);
  const project = noetixProjector(frames, poseFrames);
  document.getElementById('noetix-walk-summary').textContent =
    `${noetixTrace.robot.label}, ${noetixTrace.frame_count} frames, ${noetixLinkPoseTrace.links_per_frame} links, ${noetixTrace.config.gravity_mps2} m/s²`;
  document.getElementById('noetix-walk-authority').textContent = 'simulation evidence only';
  renderNoetixWalkViewer(frames, frame, poseFrame, project);
  renderNoetixWalkControls(frames);
  renderNoetixWalkFacts(frame, poseFrame);
}

function renderMissionEvidenceSummary(rows, counts) {
  document.getElementById('mission-evidence-summary').replaceChildren(
    el('div', { className: 'evidence-summary-item' }, [
      el('b', { text: String(counts.all) }),
      el('span', { text: 'queued evidence' })
    ]),
    el('div', { className: 'evidence-summary-item' }, [
      el('b', { text: String(counts.blocker) }),
      el('span', { text: 'active blockers' })
    ]),
    el('div', { className: 'evidence-summary-item' }, [
      el('b', { text: String(counts.receipt) }),
      el('span', { text: 'receipts' })
    ]),
    el('div', { className: 'evidence-summary-item' }, [
      el('b', { text: String(rows.filter(row => row.entry.summary.includes('hardware')).length) }),
      el('span', { text: 'hardware-gated' })
    ])
  );
}

function renderMissionEvidenceFilters(counts) {
  document.getElementById('mission-evidence-filters').replaceChildren(...evidence.familyOptions.map(([family, label]) => {
    const button = el('button', {
      className: 'evidence-filter',
      type: 'button',
      'data-evidence-filter': family,
      'aria-pressed': String(family === activeEvidenceFamily),
      text: `${label} ${counts[family]}`
    });
    button.addEventListener('click', () => {
      activeEvidenceFamily = family;
      renderMissionEvidenceQueue();
    });
    return button;
  }));
}

function renderMissionEvidenceQueue() {
  const target = document.getElementById('mission-evidence-queue');
  const rows = evidence.missionEvidenceRows();
  const counts = evidence.evidenceFamilyCounts(rows);
  const visibleRows = activeEvidenceFamily === 'all'
    ? rows
    : rows.filter(row => row.family === activeEvidenceFamily);
  renderMissionEvidenceSummary(rows, counts);
  renderMissionEvidenceFilters(counts);
  target.replaceChildren(...visibleRows.map(row =>
    el('article', {
      className: 'evidence-row',
      'data-evidence-family': row.family,
      'data-entry-id': row.entry.entry_id
    }, [
      el('b', { text: `${row.label} - ${row.entry.kind}` }),
      el('span', { text: row.entry.summary }),
      el('p', { className: 'source-path', text: `moonbook://moonmoon/first-trusted-square/${row.entry.path}` })
    ])
  ));
}

function transitionDecisionStatus(decision) {
  if (decision === 'Accept') return 'Accepted';
  if (decision === 'Reject') return 'Rejected';
  if (decision === 'Defer') return 'Deferred';
  return 'NeedsEvidence';
}

function initialClearanceDecision(item) {
  const transition = transitionByItem.get(item.item_id);
  if (transition && transition.decision) return transition.decision;
  if (item.status === 'Accepted') return 'Accept';
  if (item.status === 'Rejected') return 'Reject';
  return 'RequestEvidence';
}

function clearanceReviewStatus(item) {
  const transition = transitionByItem.get(item.item_id);
  if (transition && transition.resulting_status) return transition.resulting_status;
  return item.status;
}

function clearanceReviewNote(item) {
  const transition = transitionByItem.get(item.item_id);
  if (transition && transition.rationale) return transition.rationale;
  return item.reason;
}

function transitionSuffix(decision) {
  if (decision === 'Accept') return 'accept';
  if (decision === 'Reject') return 'reject';
  if (decision === 'Defer') return 'defer';
  return 'request-evidence';
}

function transitionEvidenceRefs(item) {
  const transition = transitionByItem.get(item.item_id);
  if (transition && transition.source_evidence_refs.length) return transition.source_evidence_refs;
  return [{
    ref_id: item.item_id,
    entry_id: 'mission/first-trusted-square/selected-route-clearance',
    path: 'mission/first-trusted-square/selected-route-clearance.json',
    immutable_uri: `moonbook://moonmoon/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json#${item.item_id}`
  }];
}

function buildClearanceTransition(item) {
  const decision = clearanceDecisions.get(item.item_id) || 'RequestEvidence';
  return {
    transition_id: `rabbita-${item.item_id}-${transitionSuffix(decision)}`,
    item_id: item.item_id,
    previous_status: item.status,
    decision,
    resulting_status: transitionDecisionStatus(decision),
    reviewer_id: 'operator/rabbita-clearance-review',
    reviewer_role: item.owner,
    timestamp_policy: 'operator-browser-export',
    recorded_at_utc: new Date().toISOString(),
    append_only: true,
    source_evidence_refs: transitionEvidenceRefs(item),
    rationale: `Rabbita ${transitionSuffix(decision)} decision for ${item.item_id}: ${item.reason}`
  };
}

function clearanceTransitionExport() {
  return {
    workspace: book.workspace,
    site_id: book.site_id,
    generated_by: 'output/ui/rabbita/first_trusted_square.html',
    transitions: clearanceItems.map(buildClearanceTransition)
  };
}

function renderTransitionExport() {
  const box = document.getElementById('transition-export');
  if (!box) return;
  box.value = JSON.stringify(clearanceTransitionExport(), null, 2);
}

function renderClearanceReview() {
  const list = document.getElementById('clearance-review');
  list.replaceChildren(...clearanceItems.map(item => {
    const selected = clearanceDecisions.get(item.item_id) || 'RequestEvidence';
    const reviewStatus = clearanceReviewStatus(item);
    const controls = el('div', { className: 'decision-group', role: 'group', 'aria-label': item.item_id },
      decisionOptions.map(([decision, label]) => {
        const button = el('button', {
          className: 'decision-button',
          type: 'button',
          'aria-pressed': String(decision === selected),
          text: label
        });
        button.addEventListener('click', () => {
          clearanceDecisions.set(item.item_id, decision);
          renderClearanceReview();
          renderTransitionExport();
        });
        return button;
      })
    );
    return el('div', {
      className: 'clearance-row',
      'data-review-decision': selected,
      'data-review-status': reviewStatus,
    }, [
      el('b', { text: `${item.item_id} - ${reviewStatus}` }),
      el('span', { text: clearanceReviewNote(item) }),
      controls
    ]);
  }));
  renderTransitionExport();
}

function closeoutActionEntry() {
  return evidence.entryById(closeoutActionEntryId);
}

function closeoutActionEvidenceRefs(entry) {
  if (!entry) return [];
  return [{
    ref_id: closeoutActionReviewItemId,
    entry_id: entry.entry_id,
    path: entry.path,
    immutable_uri: `moonbook://moonmoon/first-trusted-square/${entry.path}#${closeoutActionReviewItemId}`
  }];
}

function buildCloseoutActionReviewTransition() {
  const entry = closeoutActionEntry();
  return {
    transition_id: `rabbita-${closeoutActionReviewItemId}-${transitionSuffix(closeoutActionDecision)}`,
    item_id: closeoutActionReviewItemId,
    entry_id: closeoutActionEntryId,
    previous_status: 'NeedsReview',
    decision: closeoutActionDecision,
    resulting_status: transitionDecisionStatus(closeoutActionDecision),
    reviewer_id: 'operator/rabbita-closeout-action-review',
    reviewer_role: 'moonclaw-closeout-action-review',
    timestamp_policy: 'operator-browser-export',
    recorded_at_utc: new Date().toISOString(),
    append_only: true,
    hardware_authority_change: false,
    hardware_state: 'HardwareDenied',
    hardware_authority: 'moonmoon-safety-gate-only',
    source_evidence_refs: closeoutActionEvidenceRefs(entry),
    rationale: `Rabbita ${transitionSuffix(closeoutActionDecision)} decision for ${closeoutActionReviewItemId}: ${entry ? entry.summary : 'closeout action entry missing'}`
  };
}

function closeoutActionReviewExport() {
  return {
    workspace: book.workspace,
    site_id: book.site_id,
    generated_by: 'output/ui/rabbita/first_trusted_square.html',
    review_kind: 'moonclaw-remediation-margin-closeout-action',
    transitions: [buildCloseoutActionReviewTransition()]
  };
}

function renderCloseoutActionReviewExport() {
  const box = document.getElementById('closeout-action-review-export');
  if (!box) return;
  box.value = JSON.stringify(closeoutActionReviewExport(), null, 2);
}

function renderCloseoutActionReview() {
  const list = document.getElementById('closeout-action-review');
  if (!list) return;
  const entry = closeoutActionEntry();
  const controls = el('div', { className: 'decision-group', role: 'group', 'aria-label': closeoutActionReviewItemId },
    closeoutActionDecisionOptions.map(([decision, label]) => {
      const button = el('button', {
        className: 'decision-button',
        type: 'button',
        'aria-pressed': String(decision === closeoutActionDecision),
        text: label
      });
      button.addEventListener('click', () => {
        closeoutActionDecision = decision;
        renderCloseoutActionReview();
      });
      return button;
    })
  );
  list.replaceChildren(el('div', {
    className: 'clearance-row closeout-action-review-row',
    'data-review-decision': closeoutActionDecision,
    'data-review-status': transitionDecisionStatus(closeoutActionDecision),
    'data-entry-id': closeoutActionEntryId,
  }, [
    el('b', { text: `${closeoutActionReviewItemId} - ${transitionDecisionStatus(closeoutActionDecision)}` }),
    el('span', { text: entry ? entry.summary : 'Closeout action entry is missing from MoonBook' }),
    controls
  ]));
  renderCloseoutActionReviewExport();
}

function copyTransitionExport() {
  const box = document.getElementById('transition-export');
  const status = document.getElementById('transition-export-status');
  if (!navigator.clipboard) {
    box.select();
    status.textContent = 'Select the export JSON manually';
    return;
  }
  navigator.clipboard.writeText(box.value).then(() => {
    status.textContent = 'Transition JSON copied';
  }).catch(() => {
    box.select();
    status.textContent = 'Select the export JSON manually';
  });
}

function downloadTransitionExport() {
  const blob = new Blob([document.getElementById('transition-export').value], { type: 'application/json' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'first_trusted_square_clearance_transitions.json';
  link.click();
  URL.revokeObjectURL(link.href);
}

function copyCloseoutActionReviewExport() {
  const box = document.getElementById('closeout-action-review-export');
  const status = document.getElementById('closeout-action-review-export-status');
  if (!navigator.clipboard) {
    box.select();
    status.textContent = 'Select the export JSON manually';
    return;
  }
  navigator.clipboard.writeText(box.value).then(() => {
    status.textContent = 'Closeout action review JSON copied';
  }).catch(() => {
    box.select();
    status.textContent = 'Select the export JSON manually';
  });
}

function downloadCloseoutActionReviewExport() {
  const blob = new Blob([document.getElementById('closeout-action-review-export').value], { type: 'application/json' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'first_trusted_square_closeout_action_review.json';
  link.click();
  URL.revokeObjectURL(link.href);
}

function render() {
  renderLolaDataViewport();
  renderToolbar();
  renderGrid();
  renderInspector();
  renderRoutes();
  renderFacts();
  renderReview();
  renderGapEvidence();
  renderRemediationEvidence();
  renderNoetixWalk();
  renderMissionEvidenceQueue();
  renderClearanceReview();
  renderCloseoutActionReview();
}

document.getElementById('copy-transition-export').addEventListener('click', copyTransitionExport);
document.getElementById('download-transition-export').addEventListener('click', downloadTransitionExport);
document.getElementById('copy-closeout-action-review-export').addEventListener('click', copyCloseoutActionReviewExport);
document.getElementById('download-closeout-action-review-export').addEventListener('click', downloadCloseoutActionReviewExport);
render();
