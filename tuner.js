// Bass tuner — Web Audio mic + autocorrelation pitch detection.
// Bass fundamentals run 30–130 Hz, so we sample at 22.05 kHz worth of resolution
// and look for periods of ~170–1400 samples.

const TUNINGS = {
  // MIDI note numbers for each string (1st = lowest)
  standard: { name: "Standard E A D G", notes: [28, 33, 38, 43] },        // E1 A1 D2 G2
  dropD:    { name: "Drop D D A D G",  notes: [26, 33, 38, 43] },        // D1 A1 D2 G2
  dropC:    { name: "Drop C C G C F",  notes: [24, 31, 36, 41] },        // C1 G1 C2 F2
  halfStep: { name: "1/2 step down",   notes: [27, 32, 37, 42] },        // Eb1 Ab1 Db2 Gb2
};
const NOTE_NAMES = ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"];

const state = {
  aref: 440,
  tuningKey: "standard",
  selectedString: null,        // index, or null for auto-detect
  audioCtx: null,
  analyser: null,
  rafId: null,
  micStream: null,
  // Smoothing window — median across last N readings rejects octave jumps and noise.
  history: [],
  historySize: 6,
};

// Median of last N detected pitches. Filters out spurious doubles/halves and noise.
function medianPitch(samples) {
  if (samples.length === 0) return -1;
  const sorted = [...samples].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
}

// === DOM refs ===
const $arefSlider = document.getElementById("aref-slider");
const $arefValue  = document.getElementById("aref-value");
const $strings    = document.getElementById("strings");
const $noteName   = document.getElementById("note-name");
const $noteTarget = document.getElementById("note-target");
const $noteCurrent= document.getElementById("note-current");
const $needle     = document.getElementById("needle");
const $cents      = document.getElementById("cents-display");
const $startBtn   = document.getElementById("start-btn");
const $micStatus  = document.getElementById("mic-status");

// === Note math ===
function midiToFreq(midi, aref) {
  return aref * Math.pow(2, (midi - 69) / 12);
}
function freqToMidi(freq, aref) {
  return 69 + 12 * Math.log2(freq / aref);
}
function noteLabel(midi) {
  const m = Math.round(midi);
  const octave = Math.floor(m / 12) - 1;
  const name = NOTE_NAMES[((m % 12) + 12) % 12];
  return `${name}${octave}`;
}

// === Render UI ===
function renderStrings() {
  const t = TUNINGS[state.tuningKey];
  while ($strings.firstChild) $strings.removeChild($strings.firstChild);
  t.notes.forEach((midi, i) => {
    const f = midiToFreq(midi, state.aref);
    const btn = document.createElement("button");
    btn.className = "string-btn";
    if (i === state.selectedString) btn.classList.add("active");
    const label = document.createTextNode(noteLabel(midi));
    const freqSpan = document.createElement("span");
    freqSpan.className = "freq";
    freqSpan.textContent = `${f.toFixed(2)} Hz`;
    btn.appendChild(label);
    btn.appendChild(freqSpan);
    btn.addEventListener("click", () => {
      state.selectedString = (state.selectedString === i) ? null : i;
      renderStrings();
      updateAutoIndicator();
    });
    $strings.appendChild(btn);
  });
}

function updateAutoIndicator() {
  const el = document.getElementById("auto-indicator");
  if (!el) return;
  if (state.selectedString === null) {
    el.textContent = "Auto-detect — play any string, the tuner picks the closest. Tap a string to lock manually.";
    el.classList.remove("manual");
  } else {
    const midi = TUNINGS[state.tuningKey].notes[state.selectedString];
    el.textContent = `Locked to ${noteLabel(midi)}. Tap the highlighted button again to release.`;
    el.classList.add("manual");
  }
}

// === Auto-detect closest string ===
function closestString(freq) {
  const t = TUNINGS[state.tuningKey];
  let best = 0, bestDist = Infinity;
  for (let i = 0; i < t.notes.length; i++) {
    const target = midiToFreq(t.notes[i], state.aref);
    const dist = Math.abs(Math.log2(freq / target));   // log-scale distance
    if (dist < bestDist) { bestDist = dist; best = i; }
  }
  return best;
}

// === YIN pitch detector (de Cheveigné & Kawahara 2002) ===
// Standard algorithm used by every serious monophonic tuner. Handles harmonic
// confusion (avoids octave-up errors on bass G/D where harmonics outweigh
// fundamentals) via cumulative-mean normalized difference + absolute threshold.
//
// Steps follow the YIN paper:
//   2. Difference function           d(τ) = Σ (x[i] - x[i+τ])²
//   3. Cumulative mean normalize     d'(τ) = d(τ) / ((1/τ) Σ_{j=1..τ} d(j))
//   4. Absolute threshold            smallest τ where d'(τ) < THRESHOLD and d'(τ+1) > d'(τ)
//   5. Parabolic interpolation       refine τ to sub-sample accuracy

const YIN_THRESHOLD = 0.10;     // paper recommends 0.10–0.15; lower is stricter
const MIN_FREQ = 30;            // below E1 (41 Hz) with margin
const MAX_FREQ = 500;           // above G2 (98 Hz) with headroom for harmonics

function detectPitchYIN(buf, sampleRate) {
  const SIZE = buf.length;
  if (SIZE < 2) return -1;

  // Signal gate: too quiet → no detection
  let rms = 0;
  for (let i = 0; i < SIZE; i++) rms += buf[i] * buf[i];
  rms = Math.sqrt(rms / SIZE);
  if (rms < 0.005) return -1;

  const tauMin = Math.max(2, Math.floor(sampleRate / MAX_FREQ));
  const tauMax = Math.min(Math.floor(SIZE / 2), Math.floor(sampleRate / MIN_FREQ));

  // Step 2: difference function
  const diff = new Float32Array(tauMax + 1);
  for (let tau = tauMin; tau <= tauMax; tau++) {
    let sum = 0;
    for (let i = 0; i < SIZE - tauMax; i++) {
      const d = buf[i] - buf[i + tau];
      sum += d * d;
    }
    diff[tau] = sum;
  }

  // Step 3: cumulative mean normalized difference
  const cmnd = new Float32Array(tauMax + 1);
  cmnd[0] = 1;
  let running = 0;
  for (let tau = 1; tau <= tauMax; tau++) {
    running += diff[tau];
    cmnd[tau] = (tau < tauMin || running === 0) ? 1 : diff[tau] * tau / running;
  }

  // Step 4: absolute threshold. Walk from tauMin, find first dip below threshold,
  // then descend to its local minimum (the actual best τ).
  let tau = -1;
  for (let t = tauMin; t < tauMax; t++) {
    if (cmnd[t] < YIN_THRESHOLD) {
      // descend to local min
      while (t + 1 < tauMax && cmnd[t + 1] < cmnd[t]) t++;
      tau = t;
      break;
    }
  }
  if (tau === -1) return -1;     // no period below threshold = unvoiced/noise

  // Step 5: parabolic interpolation around tau for sub-sample precision
  let betterTau = tau;
  if (tau > tauMin && tau < tauMax - 1) {
    const s0 = cmnd[tau - 1], s1 = cmnd[tau], s2 = cmnd[tau + 1];
    const denom = 2 * (2 * s1 - s0 - s2);
    if (Math.abs(denom) > 1e-10) {
      betterTau = tau + (s2 - s0) / denom;
    }
  }

  const freq = sampleRate / betterTau;
  if (freq < MIN_FREQ || freq > MAX_FREQ) return -1;
  return freq;
}

// === Loop ===
function tick() {
  if (!state.analyser) return;
  const buf = new Float32Array(state.analyser.fftSize);
  state.analyser.getFloatTimeDomainData(buf);
  const raw = detectPitchYIN(buf, state.audioCtx.sampleRate);

  // Maintain rolling history. Use -1 (no detection) to clear history so the
  // display stops moving when the player stops playing.
  if (raw < 0) {
    state.history = [];
  } else {
    state.history.push(raw);
    if (state.history.length > state.historySize) state.history.shift();
  }

  // Need a few stable readings before showing anything.
  if (state.history.length >= 3) {
    const freq = medianPitch(state.history);
    // Stability check: discard if spread across recent history is too wide
    // (>30 cents) — usually means we caught an attack transient.
    const minF = Math.min(...state.history);
    const maxF = Math.max(...state.history);
    const spreadCents = 1200 * Math.log2(maxF / minF);

    const t = TUNINGS[state.tuningKey];
    const idx = (state.selectedString !== null) ? state.selectedString : closestString(freq);
    const targetMidi = t.notes[idx];
    const targetFreq = midiToFreq(targetMidi, state.aref);
    const detectedMidi = freqToMidi(freq, state.aref);
    const cents = (detectedMidi - targetMidi) * 100;

    $noteName.textContent = noteLabel(targetMidi);
    $noteTarget.textContent = `target ${targetFreq.toFixed(2)} Hz`;
    $noteCurrent.textContent = `heard ${freq.toFixed(2)} Hz`;
    $cents.textContent = `${cents > 0 ? "+" : ""}${cents.toFixed(1)} cents`;

    const clamped = Math.max(-50, Math.min(50, cents));
    const leftPct = 50 + clamped;
    $needle.style.left = `${leftPct}%`;

    $needle.className = "needle";
    if (spreadCents > 30) {
      // unstable reading — don't claim "in tune"
      $needle.classList.add("way-off");
    } else {
      const abs = Math.abs(cents);
      if (abs < 5) $needle.classList.add("in-tune");
      else if (abs < 15) $needle.classList.add(cents < 0 ? "flat" : "sharp");
      else $needle.classList.add("way-off");
    }
  }

  state.rafId = requestAnimationFrame(tick);
}

// === Mic start ===
// IMPORTANT: getUserMedia MUST be called synchronously inside the click handler,
// not behind any async/await. Chrome on Android loses the user-gesture context
// across awaits and will deny mic access without showing a prompt. Pattern:
//   click → getUserMedia (sync promise) → .then(setup AudioContext etc.).
function start() {
  diag("start clicked");
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    showMicError("This browser doesn't support getUserMedia. Try Chrome or Samsung Internet.");
    return;
  }
  diag("calling getUserMedia({audio:true})…");
  // audio:true is the simplest possible constraint — Chrome won't reject it for unsupported sub-constraints.
  // No AudioContext creation before this call — that could break the user-gesture chain on some browsers.
  navigator.mediaDevices.getUserMedia({ audio: true })
    .then((stream) => {
      diag("getUserMedia resolved — stream tracks: " + stream.getAudioTracks().length);
      state.micStream = stream;
      state.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const source = state.audioCtx.createMediaStreamSource(stream);
      state.analyser = state.audioCtx.createAnalyser();
      state.analyser.fftSize = 4096;
      state.analyser.smoothingTimeConstant = 0;
      source.connect(state.analyser);

      $startBtn.textContent = "Stop";
      $startBtn.classList.add("listening");
      $micStatus.textContent = "Listening…";
      $micStatus.classList.remove("hidden", "error");
      tick();
    })
    .catch((err) => {
      const name = err.name || "Error";
      diag("getUserMedia rejected: " + name + " — " + (err.message || ""));
      let msg = `Mic error: ${err.message || name}`;
      if (name === "NotAllowedError" || /denied/i.test(err.message || "")) {
        msg = "Mic permission denied. Open Chrome ⋮ menu → Settings → Site settings → Microphone → tuner.omrihefez.com → Allow, then reload. Or try https://bass.omrihefez.com for a fresh prompt.";
      } else if (name === "NotFoundError") {
        msg = "No microphone found on this device.";
      } else if (location.protocol !== "https:") {
        msg = "Mic only works over HTTPS.";
      }
      showMicError(msg);
    });
}

function showMicError(msg) {
  $micStatus.textContent = msg;
  $micStatus.classList.remove("hidden");
  $micStatus.classList.add("error");
}

function stop() {
  if (state.rafId) cancelAnimationFrame(state.rafId);
  state.rafId = null;
  if (state.micStream) state.micStream.getTracks().forEach(t => t.stop());
  state.micStream = null;
  if (state.audioCtx) state.audioCtx.close();
  state.audioCtx = null;
  state.analyser = null;
  state.history = [];
  $startBtn.textContent = "Start tuning";
  $startBtn.classList.remove("listening");
  $micStatus.classList.add("hidden");
  $noteName.textContent = "–";
  $noteTarget.textContent = "target — Hz";
  $noteCurrent.textContent = "heard — Hz";
  $cents.textContent = "— cents";
  $needle.style.left = "50%";
  $needle.className = "needle";
}

// === Wiring ===
$arefSlider.addEventListener("input", () => {
  state.aref = parseFloat($arefSlider.value);
  $arefValue.textContent = `${state.aref.toFixed(1)} Hz`;
  // Update preset highlighting
  document.querySelectorAll(".preset").forEach(btn => {
    btn.classList.toggle("active", parseFloat(btn.dataset.aref) === state.aref);
  });
  renderStrings();
});

document.querySelectorAll(".preset").forEach(btn => {
  btn.addEventListener("click", () => {
    state.aref = parseFloat(btn.dataset.aref);
    $arefSlider.value = state.aref;
    $arefValue.textContent = `${state.aref.toFixed(1)} Hz`;
    document.querySelectorAll(".preset").forEach(b => b.classList.toggle("active", b === btn));
    renderStrings();
  });
});

document.querySelectorAll(".tuning").forEach(btn => {
  btn.addEventListener("click", () => {
    state.tuningKey = btn.dataset.tuning;
    state.selectedString = null;
    document.querySelectorAll(".tuning").forEach(b => b.classList.toggle("active", b === btn));
    renderStrings();
    updateAutoIndicator();
  });
});

$startBtn.addEventListener("click", () => {
  if (state.audioCtx) stop();
  else start();
});

// === Inline diagnostic log (visible at page bottom). Helps debug why mic prompt isn't appearing on a real device. ===
function diag(msg) {
  const el = document.getElementById("diag-log");
  if (!el) return;
  const ts = new Date().toISOString().slice(11, 23);
  el.textContent = (el.textContent || "") + `[${ts}] ${msg}\n`;
  el.scrollTop = el.scrollHeight;
}
window.addEventListener("error", (e) => diag("page error: " + e.message));
window.addEventListener("unhandledrejection", (e) => diag("unhandled rejection: " + (e.reason && e.reason.message || e.reason)));
diag("page loaded — protocol=" + location.protocol + " host=" + location.host);
diag("UA: " + (navigator.userAgent || "").slice(0, 110));
diag("mediaDevices: " + (!!navigator.mediaDevices) + " getUserMedia: " + (!!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia)));

// Initial render
renderStrings();
updateAutoIndicator();

// === Diagnostic: surface permission state up-front so the user knows what to expect ===
async function checkPermissionState() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    $micStatus.textContent = "This browser doesn't expose getUserMedia. Try Chrome or Samsung Internet.";
    $micStatus.classList.remove("hidden");
    $micStatus.classList.add("error");
    return;
  }
  if (!navigator.permissions || !navigator.permissions.query) return;
  try {
    const result = await navigator.permissions.query({ name: "microphone" });
    if (result.state === "denied") {
      $micStatus.textContent = "Microphone is blocked for this site. Open the kebab menu (⋮) → Settings → Site settings → Microphone → tuner.omrihefez.com → Allow. Or visit https://bass.omrihefez.com for a fresh prompt.";
      $micStatus.classList.remove("hidden");
      $micStatus.classList.add("error");
    }
    result.addEventListener("change", () => {
      if (result.state === "granted") {
        $micStatus.classList.add("hidden");
        $micStatus.classList.remove("error");
      }
    });
  } catch { /* some browsers don't support querying 'microphone' */ }
}
checkPermissionState();

// Register service worker for PWA installability
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").catch(() => {});
}
