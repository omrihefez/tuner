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
};

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
    });
    $strings.appendChild(btn);
  });
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

// === Autocorrelation pitch detector (bass-focused) ===
function detectPitch(buf, sampleRate) {
  const SIZE = buf.length;
  // RMS — if signal too quiet, return -1
  let rms = 0;
  for (let i = 0; i < SIZE; i++) rms += buf[i] * buf[i];
  rms = Math.sqrt(rms / SIZE);
  if (rms < 0.01) return -1;

  // Trim silent ends
  let r1 = 0, r2 = SIZE - 1, thres = 0.2;
  for (let i = 0; i < SIZE/2; i++) if (Math.abs(buf[i]) < thres) { r1 = i; break; }
  for (let i = 1; i < SIZE/2; i++) if (Math.abs(buf[SIZE - i]) < thres) { r2 = SIZE - i; break; }
  const trimmed = buf.subarray(r1, r2);

  // Period search range: 30–500 Hz (covers all bass strings + harmonics)
  const minPeriod = Math.floor(sampleRate / 500);
  const maxPeriod = Math.floor(sampleRate / 30);

  // Autocorrelation
  let bestPeriod = -1;
  let bestCorr = 0;
  const N = trimmed.length;
  for (let lag = minPeriod; lag < Math.min(maxPeriod, N / 2); lag++) {
    let sum = 0;
    for (let i = 0; i < N - lag; i++) sum += trimmed[i] * trimmed[i + lag];
    sum /= (N - lag);
    if (sum > bestCorr) {
      bestCorr = sum;
      bestPeriod = lag;
    }
  }

  if (bestPeriod === -1 || bestCorr < 0.01) return -1;

  // Parabolic interpolation around the peak for sub-sample accuracy
  if (bestPeriod > 1 && bestPeriod < N - 1) {
    const acAt = (lag) => {
      let s = 0;
      for (let i = 0; i < N - lag; i++) s += trimmed[i] * trimmed[i + lag];
      return s / (N - lag);
    };
    const y1 = acAt(bestPeriod - 1), y2 = bestCorr, y3 = acAt(bestPeriod + 1);
    const denom = 2 * (2 * y2 - y1 - y3);
    if (Math.abs(denom) > 1e-10) {
      const shift = (y3 - y1) / denom;
      return sampleRate / (bestPeriod + shift);
    }
  }
  return sampleRate / bestPeriod;
}

// === Loop ===
function tick() {
  if (!state.analyser) return;
  const buf = new Float32Array(state.analyser.fftSize);
  state.analyser.getFloatTimeDomainData(buf);
  const freq = detectPitch(buf, state.audioCtx.sampleRate);

  if (freq > 30 && freq < 600) {
    // Pick string (or use selected)
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

    // needle position: -50..+50 cents maps to 0..100% left
    const clamped = Math.max(-50, Math.min(50, cents));
    const leftPct = 50 + clamped;
    $needle.style.left = `${leftPct}%`;

    $needle.className = "needle";
    const abs = Math.abs(cents);
    if (abs < 5) $needle.classList.add("in-tune");
    else if (abs < 15) $needle.classList.add(cents < 0 ? "flat" : "sharp");
    else $needle.classList.add("way-off");
  }

  state.rafId = requestAnimationFrame(tick);
}

// === Mic start/stop ===
async function start() {
  try {
    state.audioCtx = new (window.AudioContext || window.webkitAudioContext)({ latencyHint: "interactive" });
    state.micStream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false }
    });
    const source = state.audioCtx.createMediaStreamSource(state.micStream);
    state.analyser = state.audioCtx.createAnalyser();
    state.analyser.fftSize = 4096;     // ~93 ms at 44.1 kHz — enough cycles of even E1 (41 Hz = ~24 ms)
    state.analyser.smoothingTimeConstant = 0;
    source.connect(state.analyser);

    $startBtn.textContent = "Stop";
    $startBtn.classList.add("listening");
    $micStatus.textContent = "Listening…";
    $micStatus.classList.remove("hidden", "error");

    tick();
  } catch (err) {
    const name = err.name || "Error";
    let msg = `Mic error: ${err.message || name}`;
    if (name === "NotAllowedError" || /denied/i.test(err.message || "")) {
      msg = "Mic permission denied. Tap the 🔒 lock icon in the URL bar → Permissions → Microphone → Allow, then reload. Or open this page in Incognito for a fresh prompt.";
    } else if (name === "NotFoundError") {
      msg = "No microphone found on this device.";
    } else if (location.protocol !== "https:") {
      msg = "Mic only works over HTTPS. Visit the site at https://tuner.omrihefez.com.";
    }
    $micStatus.textContent = msg;
    $micStatus.classList.remove("hidden");
    $micStatus.classList.add("error");
  }
}

function stop() {
  if (state.rafId) cancelAnimationFrame(state.rafId);
  state.rafId = null;
  if (state.micStream) state.micStream.getTracks().forEach(t => t.stop());
  state.micStream = null;
  if (state.audioCtx) state.audioCtx.close();
  state.audioCtx = null;
  state.analyser = null;
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
  });
});

$startBtn.addEventListener("click", () => {
  if (state.audioCtx) stop();
  else start();
});

// Initial render
renderStrings();

// Register service worker for PWA installability
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").catch(() => {});
}
