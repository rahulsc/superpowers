const crypto = require('crypto');
const http = require('http');
const fs = require('fs');
const path = require('path');

// ========== WebSocket Protocol (RFC 6455) ==========

const OPCODES = { TEXT: 0x01, CLOSE: 0x08, PING: 0x09, PONG: 0x0A };
const WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

function computeAcceptKey(clientKey) {
  return crypto.createHash('sha1').update(clientKey + WS_MAGIC).digest('base64');
}

function encodeFrame(opcode, payload) {
  const fin = 0x80;
  const len = payload.length;
  let header;

  if (len < 126) {
    header = Buffer.alloc(2);
    header[0] = fin | opcode;
    header[1] = len;
  } else if (len < 65536) {
    header = Buffer.alloc(4);
    header[0] = fin | opcode;
    header[1] = 126;
    header.writeUInt16BE(len, 2);
  } else {
    header = Buffer.alloc(10);
    header[0] = fin | opcode;
    header[1] = 127;
    header.writeBigUInt64BE(BigInt(len), 2);
  }

  return Buffer.concat([header, payload]);
}

function decodeFrame(buffer) {
  if (buffer.length < 2) return null;

  const secondByte = buffer[1];
  const opcode = buffer[0] & 0x0F;
  const masked = (secondByte & 0x80) !== 0;
  let payloadLen = secondByte & 0x7F;
  let offset = 2;

  if (!masked) throw new Error('Client frames must be masked');

  if (payloadLen === 126) {
    if (buffer.length < 4) return null;
    payloadLen = buffer.readUInt16BE(2);
    offset = 4;
  } else if (payloadLen === 127) {
    if (buffer.length < 10) return null;
    payloadLen = Number(buffer.readBigUInt64BE(2));
    offset = 10;
  }

  const maskOffset = offset;
  const dataOffset = offset + 4;
  const totalLen = dataOffset + payloadLen;
  if (buffer.length < totalLen) return null;

  const mask = buffer.slice(maskOffset, dataOffset);
  const data = Buffer.alloc(payloadLen);
  for (let i = 0; i < payloadLen; i++) {
    data[i] = buffer[dataOffset + i] ^ mask[i % 4];
  }

  return { opcode, payload: data, bytesConsumed: totalLen };
}

// ========== Configuration ==========

const PORT = process.env.FORGE_VIZ_PORT || (49152 + Math.floor(Math.random() * 16383));
const HOST = process.env.FORGE_VIZ_HOST || '127.0.0.1';
const URL_HOST = process.env.FORGE_VIZ_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
const FORGE_DIR = process.env.FORGE_VIZ_DIR || path.join(process.cwd(), '.forge', 'local');
const OWNER_PID = process.env.FORGE_VIZ_OWNER_PID ? Number(process.env.FORGE_VIZ_OWNER_PID) : null;

const PIPELINE_PHASES = ['design', 'setup', 'planning', 'executing', 'verification', 'review', 'completion'];

// ========== State Reading ==========

function readForgeState() {
  const stateFile = path.join(FORGE_DIR, 'state.json');
  let state = {};
  if (fs.existsSync(stateFile)) {
    try {
      state = JSON.parse(fs.readFileSync(stateFile, 'utf-8'));
    } catch (e) {
      // malformed JSON — return empty state
    }
  }
  return state;
}

function readEvidenceDir() {
  const evidenceDir = path.join(FORGE_DIR, 'evidence');
  const evidence = {};
  if (!fs.existsSync(evidenceDir)) return evidence;

  try {
    const entries = fs.readdirSync(evidenceDir);
    for (const entry of entries) {
      const entryPath = path.join(evidenceDir, entry);
      const stat = fs.statSync(entryPath);
      if (stat.isDirectory()) {
        // task directory: evidence/<task-id>/
        const artifacts = fs.readdirSync(entryPath).filter(f => !f.startsWith('.'));
        evidence[entry] = artifacts;
      } else if (entry.endsWith('.json')) {
        // flat JSON evidence file
        try {
          const data = JSON.parse(fs.readFileSync(entryPath, 'utf-8'));
          const taskId = entry.replace('.json', '');
          evidence[taskId] = data.artifacts || data.collected || [];
        } catch (e) {
          // skip malformed file
        }
      }
    }
  } catch (e) {
    // evidence dir unreadable
  }
  return evidence;
}

function buildStateUpdate() {
  const state = readForgeState();
  const evidenceByTask = readEvidenceDir();

  const phase = state.phase || state.current_phase || 'design';
  const riskTier = state.risk_tier || state.tier || 'standard';
  const tasks = state.tasks || {};

  // Build task counts
  const taskEntries = Object.entries(tasks);
  const total = taskEntries.length;
  const complete = taskEntries.filter(([, t]) => t.status === 'complete' || t.status === 'completed').length;
  const active = taskEntries.filter(([, t]) => t.status === 'in_progress' || t.status === 'active').length;

  // Required evidence per risk tier
  const requiredEvidence = {
    minimal: ['verification-log'],
    standard: ['test-output', 'verification-log'],
    elevated: ['test-output', 'review-notes', 'verification-log'],
    critical: ['test-output', 'review-notes', 'verification-log', 'security-review', 'rollback-plan'],
  };
  const required = requiredEvidence[riskTier] || requiredEvidence.standard;

  // Collect all evidence across all tasks
  const allCollected = new Set();
  for (const artifacts of Object.values(evidenceByTask)) {
    for (const a of artifacts) allCollected.add(a);
  }

  // Also check top-level state evidence arrays
  if (Array.isArray(state.evidence)) {
    for (const a of state.evidence) allCollected.add(a);
  }
  if (state.evidence && typeof state.evidence === 'object' && !Array.isArray(state.evidence)) {
    if (Array.isArray(state.evidence.collected)) {
      for (const a of state.evidence.collected) allCollected.add(a);
    }
  }

  const collected = [...allCollected];
  const missing = required.filter(r => !allCollected.has(r));

  // Build per-task evidence summary
  const taskEvidence = {};
  for (const [taskId, taskData] of taskEntries) {
    const taskArtifacts = evidenceByTask[taskId] || [];
    const taskRequired = required;
    taskEvidence[taskId] = {
      tier: taskData.tier || riskTier,
      collected: taskArtifacts,
      missing: taskRequired.filter(r => !taskArtifacts.includes(r)),
      status: taskData.status || 'pending',
    };
  }

  return {
    type: 'state-update',
    phase,
    risk_tier: riskTier,
    evidence: { collected, missing },
    tasks: { total, complete, active },
    task_evidence: taskEvidence,
    pipeline: PIPELINE_PHASES,
    timestamp: Date.now(),
  };
}

// ========== Dashboard HTML ==========

function getDashboardHTML(wsPort) {
  const dashboardTemplate = path.join(__dirname, 'dashboard-template.html');
  if (fs.existsSync(dashboardTemplate)) {
    let html = fs.readFileSync(dashboardTemplate, 'utf-8');
    html = html.replace('__WS_PORT__', wsPort);
    html = html.replace('__WS_HOST__', URL_HOST);
    return html;
  }
  // Inline fallback dashboard
  return getInlineDashboard(wsPort);
}

function getInlineDashboard(wsPort) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Forge Workflow Dashboard</title>
<style>
  *, *::before, *::after { box-sizing: border-box; }
  body {
    font-family: system-ui, -apple-system, sans-serif;
    background: #0f1117;
    color: #e2e8f0;
    margin: 0;
    padding: 1.5rem;
    min-height: 100vh;
  }
  h1 { font-size: 1.4rem; font-weight: 700; color: #f7fafc; margin: 0 0 0.25rem; }
  .subtitle { font-size: 0.85rem; color: #718096; margin-bottom: 2rem; }
  .section { margin-bottom: 2rem; }
  .section-title {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #4a5568;
    margin-bottom: 1rem;
  }

  /* Pipeline */
  .pipeline {
    display: flex;
    align-items: center;
    gap: 0;
    overflow-x: auto;
    padding-bottom: 0.5rem;
  }
  .phase {
    display: flex;
    align-items: center;
    flex-shrink: 0;
  }
  .phase-box {
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-size: 0.8rem;
    font-weight: 500;
    border: 1px solid transparent;
    white-space: nowrap;
    cursor: default;
  }
  .phase-box.done {
    background: #1a3a2a;
    border-color: #276749;
    color: #68d391;
  }
  .phase-box.active {
    background: #1a2a4a;
    border-color: #3182ce;
    color: #90cdf4;
    box-shadow: 0 0 0 2px rgba(49,130,206,0.3);
  }
  .phase-box.pending {
    background: #1a1d27;
    border-color: #2d3748;
    color: #4a5568;
  }
  .phase-icon { margin-right: 0.35rem; }
  .phase-arrow {
    color: #2d3748;
    padding: 0 0.3rem;
    font-size: 0.8rem;
  }

  /* Stats */
  .stats-row { display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1.5rem; }
  .stat-card {
    background: #1a1d27;
    border: 1px solid #2d3748;
    border-radius: 8px;
    padding: 0.75rem 1.25rem;
    min-width: 120px;
  }
  .stat-label { font-size: 0.7rem; color: #718096; text-transform: uppercase; letter-spacing: 0.06em; }
  .stat-value { font-size: 1.5rem; font-weight: 700; color: #e2e8f0; margin-top: 0.1rem; }
  .stat-value.tier-minimal { color: #68d391; }
  .stat-value.tier-standard { color: #90cdf4; }
  .stat-value.tier-elevated { color: #f6ad55; }
  .stat-value.tier-critical { color: #fc8181; }

  /* Evidence */
  .evidence-badges { display: flex; flex-wrap: wrap; gap: 0.4rem; margin-bottom: 0.75rem; }
  .badge {
    font-size: 0.72rem;
    padding: 0.2rem 0.6rem;
    border-radius: 4px;
    font-weight: 500;
  }
  .badge.collected { background: #1a3a2a; color: #68d391; border: 1px solid #276749; }
  .badge.missing { background: #3a1a1a; color: #fc8181; border: 1px solid #742a2a; }
  .evidence-label { font-size: 0.75rem; color: #4a5568; margin-bottom: 0.4rem; }

  /* Task table */
  table { width: 100%; border-collapse: collapse; font-size: 0.8rem; }
  th {
    text-align: left;
    padding: 0.5rem 0.75rem;
    color: #4a5568;
    font-weight: 600;
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    border-bottom: 1px solid #2d3748;
  }
  td { padding: 0.5rem 0.75rem; border-bottom: 1px solid #1a1d27; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #1a1d27; }
  .status-dot {
    display: inline-block;
    width: 7px;
    height: 7px;
    border-radius: 50%;
    margin-right: 0.4rem;
  }
  .status-complete .status-dot { background: #68d391; }
  .status-active .status-dot { background: #90cdf4; }
  .status-pending .status-dot { background: #4a5568; }
  .missing-list { color: #fc8181; }
  .ok-text { color: #68d391; }
  .empty-state {
    color: #4a5568;
    font-style: italic;
    font-size: 0.85rem;
    padding: 1rem 0;
  }

  /* Connection status */
  .conn-bar {
    position: fixed;
    top: 0; left: 0; right: 0;
    padding: 0.35rem 1rem;
    font-size: 0.72rem;
    font-weight: 500;
    text-align: center;
    transition: all 0.3s;
  }
  .conn-bar.connected { background: #276749; color: #c6f6d5; }
  .conn-bar.disconnected { background: #742a2a; color: #fed7d7; }
  .conn-bar.reconnecting { background: #744210; color: #fefcbf; }
  body.has-bar { padding-top: 3rem; }
</style>
</head>
<body>
<div class="conn-bar disconnected" id="conn-bar">Connecting...</div>

<h1>Forge Workflow Dashboard</h1>
<p class="subtitle" id="subtitle">Watching .forge/local/ for changes</p>

<div class="section">
  <div class="section-title">Pipeline</div>
  <div class="pipeline" id="pipeline">
    <span class="empty-state">Loading...</span>
  </div>
</div>

<div class="stats-row" id="stats-row" style="display:none">
  <div class="stat-card">
    <div class="stat-label">Phase</div>
    <div class="stat-value" id="stat-phase">—</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Risk Tier</div>
    <div class="stat-value" id="stat-tier">—</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Tasks</div>
    <div class="stat-value" id="stat-tasks">—</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Complete</div>
    <div class="stat-value" id="stat-complete">—</div>
  </div>
</div>

<div class="section" id="evidence-section" style="display:none">
  <div class="section-title">Evidence</div>
  <div class="evidence-label">Collected</div>
  <div class="evidence-badges" id="evidence-collected"></div>
  <div class="evidence-label">Missing (required for tier)</div>
  <div class="evidence-badges" id="evidence-missing"></div>
</div>

<div class="section" id="tasks-section" style="display:none">
  <div class="section-title">Tasks</div>
  <table>
    <thead>
      <tr>
        <th>Task</th>
        <th>Status</th>
        <th>Tier</th>
        <th>Evidence</th>
        <th>Missing</th>
      </tr>
    </thead>
    <tbody id="task-tbody">
      <tr><td colspan="5" class="empty-state">No tasks in state</td></tr>
    </tbody>
  </table>
</div>

<script>
(function() {
  const WS_HOST = '${URL_HOST}';
  const WS_PORT = ${wsPort};
  const connBar = document.getElementById('conn-bar');
  const PHASES = ['design', 'setup', 'planning', 'executing', 'verification', 'review', 'completion'];

  let ws = null;
  let retryDelay = 1000;
  let retryTimer = null;

  function connect() {
    if (ws) { try { ws.close(); } catch(e) {} }
    ws = new WebSocket('ws://' + WS_HOST + ':' + WS_PORT + '/ws');

    ws.onopen = function() {
      document.body.classList.add('has-bar');
      connBar.className = 'conn-bar connected';
      connBar.textContent = 'Connected — live updates active';
      retryDelay = 1000;
    };

    ws.onmessage = function(ev) {
      let msg;
      try { msg = JSON.parse(ev.data); } catch(e) { return; }
      if (msg.type === 'state-update') renderState(msg);
      if (msg.type === 'ping') ws.send(JSON.stringify({type:'pong'}));
    };

    ws.onclose = function() {
      connBar.className = 'conn-bar reconnecting';
      connBar.textContent = 'Disconnected — reconnecting in ' + (retryDelay/1000).toFixed(0) + 's...';
      retryTimer = setTimeout(function() {
        retryDelay = Math.min(retryDelay * 2, 30000);
        connect();
      }, retryDelay);
    };

    ws.onerror = function() { ws.close(); };
  }

  function renderState(state) {
    renderPipeline(state.phase, state.pipeline || PHASES);
    renderStats(state);
    renderEvidence(state.evidence || {});
    renderTasks(state.task_evidence || {});
    document.getElementById('subtitle').textContent =
      'Last updated: ' + new Date().toLocaleTimeString();
  }

  function renderPipeline(currentPhase, phases) {
    const container = document.getElementById('pipeline');
    container.innerHTML = '';
    const doneIdx = phases.indexOf(currentPhase);

    phases.forEach(function(ph, i) {
      if (i > 0) {
        const arrow = document.createElement('span');
        arrow.className = 'phase-arrow';
        arrow.textContent = '→';
        container.appendChild(arrow);
      }
      const phase = document.createElement('div');
      phase.className = 'phase';
      const box = document.createElement('div');
      let cls = 'phase-box';
      let icon = '○';
      if (i < doneIdx) { cls += ' done'; icon = '✓'; }
      else if (i === doneIdx) { cls += ' active'; icon = '●'; }
      else { cls += ' pending'; }
      box.className = cls;
      box.innerHTML = '<span class="phase-icon">' + icon + '</span>' + ph;
      phase.appendChild(box);
      container.appendChild(phase);
    });
  }

  function renderStats(state) {
    const row = document.getElementById('stats-row');
    row.style.display = '';
    document.getElementById('stat-phase').textContent = state.phase || '—';
    const tierEl = document.getElementById('stat-tier');
    tierEl.textContent = state.risk_tier || '—';
    tierEl.className = 'stat-value tier-' + (state.risk_tier || '');
    const t = state.tasks || {};
    document.getElementById('stat-tasks').textContent = t.total !== undefined ? t.total : '—';
    document.getElementById('stat-complete').textContent =
      (t.complete !== undefined ? t.complete : '—') +
      (t.active ? ' (+' + t.active + ' active)' : '');
  }

  function renderEvidence(evidence) {
    const section = document.getElementById('evidence-section');
    section.style.display = '';
    const collectedEl = document.getElementById('evidence-collected');
    const missingEl = document.getElementById('evidence-missing');

    collectedEl.innerHTML = '';
    (evidence.collected || []).forEach(function(a) {
      const b = document.createElement('span');
      b.className = 'badge collected';
      b.textContent = a;
      collectedEl.appendChild(b);
    });
    if (!(evidence.collected || []).length) {
      collectedEl.innerHTML = '<span class="empty-state">None yet</span>';
    }

    missingEl.innerHTML = '';
    (evidence.missing || []).forEach(function(a) {
      const b = document.createElement('span');
      b.className = 'badge missing';
      b.textContent = a;
      missingEl.appendChild(b);
    });
    if (!(evidence.missing || []).length) {
      missingEl.innerHTML = '<span class="badge collected">All required evidence collected</span>';
    }
  }

  function renderTasks(taskEvidence) {
    const section = document.getElementById('tasks-section');
    const tbody = document.getElementById('task-tbody');
    const entries = Object.entries(taskEvidence);

    if (!entries.length) {
      section.style.display = 'none';
      return;
    }

    section.style.display = '';
    tbody.innerHTML = '';

    entries.forEach(function(entry) {
      const taskId = entry[0];
      const data = entry[1];
      const tr = document.createElement('tr');
      const statusClass = data.status === 'complete' || data.status === 'completed'
        ? 'status-complete'
        : data.status === 'in_progress' || data.status === 'active'
          ? 'status-active'
          : 'status-pending';

      const collected = (data.collected || []).join(', ') || '—';
      const missing = (data.missing || []);

      tr.className = statusClass;
      tr.innerHTML =
        '<td>' + escHtml(taskId) + '</td>' +
        '<td><span class="status-dot"></span>' + escHtml(data.status || 'pending') + '</td>' +
        '<td>' + escHtml(data.tier || '—') + '</td>' +
        '<td class="ok-text">' + escHtml(collected) + '</td>' +
        '<td class="' + (missing.length ? 'missing-list' : 'ok-text') + '">' +
          (missing.length ? escHtml(missing.join(', ')) : 'complete') + '</td>';
      tbody.appendChild(tr);
    });
  }

  function escHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  connect();
})();
</script>
</body>
</html>`;
}

// ========== HTTP Request Handler ==========

function handleRequest(req, res) {
  touchActivity();
  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
    const html = getDashboardHTML(PORT);
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(html);
  } else if (req.method === 'GET' && req.url === '/state') {
    // REST endpoint for current state (useful for debugging)
    const state = buildStateUpdate();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(state, null, 2));
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
}

// ========== WebSocket Connection Handling ==========

const clients = new Set();

function handleUpgrade(req, socket) {
  if (req.url !== '/ws') { socket.destroy(); return; }
  const key = req.headers['sec-websocket-key'];
  if (!key) { socket.destroy(); return; }

  const accept = computeAcceptKey(key);
  socket.write(
    'HTTP/1.1 101 Switching Protocols\r\n' +
    'Upgrade: websocket\r\n' +
    'Connection: Upgrade\r\n' +
    'Sec-WebSocket-Accept: ' + accept + '\r\n\r\n'
  );

  let buffer = Buffer.alloc(0);
  clients.add(socket);
  touchActivity();

  // Send current state immediately on connect
  try {
    const stateMsg = buildStateUpdate();
    socket.write(encodeFrame(OPCODES.TEXT, Buffer.from(JSON.stringify(stateMsg))));
  } catch (e) {
    // state read failed — not fatal
  }

  socket.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    while (buffer.length > 0) {
      let result;
      try {
        result = decodeFrame(buffer);
      } catch (e) {
        socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
        clients.delete(socket);
        return;
      }
      if (!result) break;
      buffer = buffer.slice(result.bytesConsumed);

      switch (result.opcode) {
        case OPCODES.CLOSE:
          socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
          clients.delete(socket);
          return;
        case OPCODES.PING:
          socket.write(encodeFrame(OPCODES.PONG, result.payload));
          break;
        case OPCODES.PONG:
          break;
        default:
          break;
      }
    }
  });

  socket.on('close', () => clients.delete(socket));
  socket.on('error', () => clients.delete(socket));
}

function broadcast(msg) {
  const frame = encodeFrame(OPCODES.TEXT, Buffer.from(JSON.stringify(msg)));
  for (const socket of clients) {
    try { socket.write(frame); } catch (e) { clients.delete(socket); }
  }
}

// ========== Activity Tracking ==========

const IDLE_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes idle auto-shutdown
let lastActivity = Date.now();

function touchActivity() {
  lastActivity = Date.now();
}

// ========== File Watching ==========

const debounceTimers = new Map();

function setupWatcher(dir) {
  if (!fs.existsSync(dir)) {
    // Watch for the directory to be created
    const parent = path.dirname(dir);
    if (fs.existsSync(parent)) {
      const parentWatcher = fs.watch(parent, (eventType, filename) => {
        if (filename === path.basename(dir) && fs.existsSync(dir)) {
          parentWatcher.close();
          setupWatcher(dir);
        }
      });
      parentWatcher.on('error', () => {});
    }
    return;
  }

  try {
    const watcher = fs.watch(dir, { recursive: true }, (eventType, filename) => {
      if (!filename) return;
      // Skip hidden files except state.json
      const basename = path.basename(filename);
      if (basename.startsWith('.') && basename !== 'state.json') return;

      const key = filename;
      if (debounceTimers.has(key)) clearTimeout(debounceTimers.get(key));
      debounceTimers.set(key, setTimeout(() => {
        debounceTimers.delete(key);
        touchActivity();
        console.log(JSON.stringify({ type: 'forge-state-changed', file: filename }));
        try {
          const stateMsg = buildStateUpdate();
          broadcast(stateMsg);
        } catch (e) {
          console.error('broadcast error:', e.message);
        }
      }, 150));
    });
    watcher.on('error', (err) => console.error('fs.watch error:', err.message));
    return watcher;
  } catch (e) {
    console.error('Failed to watch directory:', dir, e.message);
  }
}

// ========== Server Startup ==========

function startServer() {
  const server = http.createServer(handleRequest);
  server.on('upgrade', handleUpgrade);

  const watcher = setupWatcher(FORGE_DIR);

  function shutdown(reason) {
    console.log(JSON.stringify({ type: 'server-stopped', reason }));
    const infoFile = path.join(FORGE_DIR, '.forge-viz-info');
    if (fs.existsSync(infoFile)) {
      try { fs.unlinkSync(infoFile); } catch (e) {}
    }
    if (watcher) watcher.close();
    clearInterval(lifecycleCheck);
    server.close(() => process.exit(0));
    // Force exit if graceful close hangs
    setTimeout(() => process.exit(0), 2000).unref();
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  function ownerAlive() {
    if (!OWNER_PID) return true;
    try { process.kill(OWNER_PID, 0); return true; } catch (e) { return false; }
  }

  // Check every 60s: exit if owner process died or idle for 30 minutes
  const lifecycleCheck = setInterval(() => {
    if (!ownerAlive()) shutdown('owner process exited');
    else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) shutdown('idle timeout');
  }, 60 * 1000);
  lifecycleCheck.unref();

  server.listen(PORT, HOST, () => {
    const info = {
      type: 'server-started',
      port: Number(PORT),
      host: HOST,
      url_host: URL_HOST,
      url: 'http://' + URL_HOST + ':' + PORT,
      forge_dir: FORGE_DIR,
    };
    console.log(JSON.stringify(info));

    // Write server info file (create parent dir if needed)
    try {
      if (!fs.existsSync(FORGE_DIR)) fs.mkdirSync(FORGE_DIR, { recursive: true });
      fs.writeFileSync(path.join(FORGE_DIR, '.forge-viz-info'), JSON.stringify(info) + '\n');
    } catch (e) {
      // Non-fatal — directory may not exist yet
    }
  });
}

if (require.main === module) {
  startServer();
}

module.exports = { computeAcceptKey, encodeFrame, decodeFrame, OPCODES };
