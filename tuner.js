// Bass tuner — Web Audio mic + autocorrelation pitch detection.
// Bass fundamentals run 30–130 Hz, so we sample at 22.05 kHz worth of resolution
// and look for periods of ~170–1400 samples.

// MIDI note numbers, 1st entry = lowest string.
// Bass: E1=28, A1=33, D2=38, G2=43, B0=23, D1=26
// Guitar: E2=40, A2=45, D3=50, G3=55, B3=59, E4=64, B1=35
const INSTRUMENTS = {
  bass: {
    name: "Bass",
    tunings: {
      standard:  { name: "Standard",      notes: [28, 33, 38, 43] },
      dropD:     { name: "Drop D",        notes: [26, 33, 38, 43] },
      dropC:     { name: "Drop C",        notes: [24, 31, 36, 41] },
      dropCSharp:{ name: "Drop C#",       notes: [25, 32, 37, 42] },         // C#1 G#1 C#2 F#2 (e.g. SOAD B.Y.O.B)
      halfStep:  { name: "½ step down",   notes: [27, 32, 37, 42] },
      fiveString:{ name: "5-string",      notes: [23, 28, 33, 38, 43] },     // B0 E1 A1 D2 G2
    },
  },
  guitar: {
    name: "Guitar",
    tunings: {
      standard:  { name: "Standard",      notes: [40, 45, 50, 55, 59, 64] }, // E2 A2 D3 G3 B3 E4
      dropD:     { name: "Drop D",        notes: [38, 45, 50, 55, 59, 64] }, // D2 A2 D3 G3 B3 E4
      dadgad:    { name: "DADGAD",        notes: [38, 45, 50, 55, 57, 62] }, // D2 A2 D3 G3 A3 D4
      openG:     { name: "Open G",        notes: [38, 43, 50, 55, 59, 62] }, // D2 G2 D3 G3 B3 D4
      halfStep:  { name: "½ step down",   notes: [39, 44, 49, 54, 58, 63] }, // Eb2 Ab2 Db3 Gb3 Bb3 Eb4
      sevenStr:  { name: "7-string",      notes: [35, 40, 45, 50, 55, 59, 64] }, // B1 + standard
    },
  },
};
const NOTE_NAMES = ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"];

const state = {
  aref: 440,
  instrumentKey: "bass",
  tuningKey: "standard",
  selectedString: null,        // index, or null for auto-detect
  audioCtx: null,
  analyser: null,
  rafId: null,
  micStream: null,
  // Smoothing window — median across last N readings rejects octave jumps and noise.
  history: [],
  historySize: 6,
  smoothedFreq: null,   // EMA of detected pitch — calms the readout so it settles
  needleLeft: 50,       // current needle position %, eased toward target each frame
  lastDetectTs: 0,      // throttle YIN independent of the 60fps animation
  lastGoodTs: 0,        // timestamp of last successful detection — drives the note-hold
  wasInTune: false,     // edge-detects entering "in tune" so the haptic buzzes once, not every frame
  lastAnnouncement: null, // last text pushed to the aria-live region — dedupes repeats
  lastAnnounceTs: 0,       // throttles aria-live updates independent of the 60fps animation
  refToneGateUntil: 0,    // performance.now() timestamp — pitch detection is skipped
                           // until this passes, so the played reference tone (which
                           // leaks into the live mic acoustically) can't jerk the needle
};

function currentTuning() {
  return INSTRUMENTS[state.instrumentKey].tunings[state.tuningKey];
}

// Edge-detect entering "in tune" — true only on the transition, so a sustained
// note buzzes once instead of every animation frame while it's held.
function shouldBuzz(wasInTune, isInTune) {
  return isInTune && !wasInTune;
}

// Builds the sentence announced to screen readers. Cents are rounded to
// ANNOUNCE_CENTS_STEP so the live region reads "12 cents sharp" instead of
// flickering through every fractional value the 60fps needle passes through.
function buildAnnouncement(note, cents, isInTune) {
  if (isInTune) return `${note}, in tune`;
  const rounded = Math.round(cents / ANNOUNCE_CENTS_STEP) * ANNOUNCE_CENTS_STEP;
  if (rounded === 0) return `${note}, in tune`;
  return `${note}, ${Math.abs(rounded)} cents ${rounded < 0 ? "flat" : "sharp"}`;
}

// Gates aria-live updates: a screen reader speaks every text change, so pushing
// one on every animation frame (like the visual readout does) is unusable
// chatter. Skip no-op repeats and otherwise throttle to ANNOUNCE_INTERVAL_MS —
// except entering "in tune", which jumps the queue like the haptic buzz does,
// so the confirmation isn't stuck behind a stale throttle window.
function shouldAnnounce(now, lastAnnounceTs, prevText, nextText, justEnteredTune) {
  if (nextText === prevText) return false;
  return justEnteredTune || (now - lastAnnounceTs >= ANNOUNCE_INTERVAL_MS);
}

// Fires the haptic pulse. Feature-detected: desktop/iOS Safari lack
// navigator.vibrate, so this is a silent no-op there.
function triggerHaptic() {
  if (typeof navigator !== "undefined" && typeof navigator.vibrate === "function") {
    navigator.vibrate(HAPTIC_MS);
  }
}

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
const $announcer  = document.getElementById("tuner-announcer");
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

// === Reference tone ===
// Plays the target pitch for a locked string via a short sine-wave burst.
// Reuses the mic AudioContext when the tuner is running; otherwise creates
// a temporary one (valid because this is always called from a click handler).
const REF_TONE_DURATION_S = 1.2;

function playReferenceTone(midi) {
  const freq = midiToFreq(midi, state.aref);
  const ctx = state.audioCtx || new (window.AudioContext || window.webkitAudioContext)();
  const ownCtx = !state.audioCtx;
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = "sine";
  osc.frequency.value = freq;
  osc.connect(gain);
  gain.connect(ctx.destination);
  const t = ctx.currentTime;
  gain.gain.setValueAtTime(0.4, t);
  gain.gain.exponentialRampToValueAtTime(0.001, t + REF_TONE_DURATION_S);
  osc.start(t);
  osc.stop(t + REF_TONE_DURATION_S);
  if (ownCtx) osc.onended = () => ctx.close();
  ctx.resume(); // no-op if already running
  // The tone plays out of the speakers and acoustically leaks back into the live
  // mic, so gate pitch detection while it plays — otherwise the needle jerks to
  // the reference pitch instead of showing the string.
  state.refToneGateUntil = performance.now() + REF_TONE_DURATION_S * 1000;
}

// === Render UI ===
function renderStrings() {
  const t = currentTuning();
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
      if (state.selectedString === i) {
        // Already locked — play tone, stay locked.
        playReferenceTone(currentTuning().notes[i]);
        return;
      }
      state.selectedString = i;
      renderStrings();
      updateAutoIndicator();
      playReferenceTone(currentTuning().notes[i]);
    });
    $strings.appendChild(btn);
  });
}

function updateAutoIndicator() {
  const el = document.getElementById("auto-indicator");
  if (!el) return;
  while (el.firstChild) el.removeChild(el.firstChild);
  if (state.selectedString === null) {
    el.appendChild(document.createTextNode("Auto-detect — play any string, the tuner picks the closest. Tap a string to lock manually."));
    el.classList.remove("manual");
  } else {
    const midi = currentTuning().notes[state.selectedString];
    el.classList.add("manual");
    el.appendChild(document.createTextNode(`Locked to ${noteLabel(midi)} — tap to hear pitch · `));
    const releaseBtn = document.createElement("button");
    releaseBtn.className = "release-btn";
    releaseBtn.textContent = "Auto";
    releaseBtn.addEventListener("click", () => {
      state.selectedString = null;
      renderStrings();
      updateAutoIndicator();
    });
    el.appendChild(releaseBtn);
  }
}

function renderTuningButtons() {
  const container = document.querySelector(".tuning-presets");
  if (!container) return;
  while (container.firstChild) container.removeChild(container.firstChild);
  const tunings = INSTRUMENTS[state.instrumentKey].tunings;
  // Keep the current tuning if it's valid for this instrument (so a restored /
  // persisted choice survives); otherwise fall back to the first one.
  if (!Object.prototype.hasOwnProperty.call(tunings, state.tuningKey)) {
    state.tuningKey = Object.keys(tunings)[0];
  }
  for (const [key, tuning] of Object.entries(tunings)) {
    const btn = document.createElement("button");
    btn.className = "tuning";
    btn.dataset.tuning = key;
    btn.textContent = tuning.name;
    if (key === state.tuningKey) btn.classList.add("active");
    btn.addEventListener("click", () => {
      state.tuningKey = key;
      state.selectedString = null;
      document.querySelectorAll(".tuning").forEach(b => b.classList.toggle("active", b === btn));
      renderStrings();
      updateAutoIndicator();
      saveSettings();
    });
    container.appendChild(btn);
  }
}

function renderInstrumentButtons() {
  const container = document.querySelector(".instrument-selector");
  if (!container) return;
  while (container.firstChild) container.removeChild(container.firstChild);
  for (const [key, inst] of Object.entries(INSTRUMENTS)) {
    const btn = document.createElement("button");
    btn.className = "instrument";
    btn.dataset.instrument = key;
    btn.textContent = inst.name;
    if (key === state.instrumentKey) btn.classList.add("active");
    btn.addEventListener("click", () => {
      state.instrumentKey = key;
      state.selectedString = null;
      // Switching instrument resets to that instrument's first tuning.
      state.tuningKey = Object.keys(INSTRUMENTS[key].tunings)[0];
      document.querySelectorAll(".instrument").forEach(b => b.classList.toggle("active", b === btn));
      renderTuningButtons();
      renderStrings();
      updateAutoIndicator();
      saveSettings();
    });
    container.appendChild(btn);
  }
}

// === Auto-detect closest string ===
function closestString(freq) {
  const t = currentTuning();
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

const YIN_THRESHOLD = 0.12;       // paper recommends 0.10–0.15; lower is stricter
const DETECT_INTERVAL_MS = 45;    // run YIN ~22×/s; the rAF loop eases the needle every frame
const FREQ_EMA = 0.30;            // display smoothing: lower = calmer, higher = snappier
const NOTE_JUMP_CENTS = 80;       // beyond this jump, snap instead of glide (you changed strings)
const SIGNAL_HOLD_MS = 600;       // keep showing the last pitch through sustain/decay gaps;
                                  // only blank after this much continuous silence (continuity, like a hardware tuner)
const CLOSE_CENTS = 3;            // within this, round to 0.0 / "in tune" — close enough
const HAPTIC_MS = 40;             // vibration pulse length when you land in tune
const ANNOUNCE_INTERVAL_MS = 1200; // min gap between aria-live updates — the readout
                                  // itself refreshes every rAF; a screen reader must not.
const ANNOUNCE_CENTS_STEP = 5;    // round announced cents to this grid, same reason

// Search range derived from the CURRENT tuning: a few semitones below the lowest
// string and above the highest. Capping the top below the highest string's harmonics
// is what stops the bass D/G strings from locking onto their 2nd harmonic — the
// "higher strings won't tune / needle runs left-right" bug. Adapts to tuning + A-ref.
// e.g. bass standard → ~[34,131] Hz, so G2's 2nd harmonic (196 Hz) is excluded.
function freqRange() {
  const notes = currentTuning().notes;
  const lo = Math.min(...notes), hi = Math.max(...notes);
  return {
    minFreq: Math.max(25, midiToFreq(lo - 3, state.aref)),
    maxFreq: midiToFreq(hi + 5, state.aref),
  };
}

function detectPitchYIN(buf, sampleRate, minFreq, maxFreq) {
  const SIZE = buf.length;
  if (SIZE < 2) return -1;

  // Signal gate: too quiet → no detection
  let rms = 0;
  for (let i = 0; i < SIZE; i++) rms += buf[i] * buf[i];
  rms = Math.sqrt(rms / SIZE);
  if (rms < 0.003) return -1;   // lower floor → keeps detecting quiet sustain/decay

  const tauMin = Math.max(2, Math.floor(sampleRate / maxFreq));
  const tauMax = Math.min(Math.floor(SIZE / 2), Math.floor(sampleRate / minFreq));

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
  if (freq < minFreq || freq > maxFreq) return -1;
  return freq;
}

// === Loop ===
function tick() {
  if (!state.analyser) return;
  try {
    tickInner();
  } catch (err) {
    diag("tick error: " + err.message);
    // Don't loop on a broken state — surface the error and stop instead of burning CPU.
    showMicError(`Tuner crashed: ${err.message}. Tap Start tuning to retry.`);
    stop();
    return;
  }
  state.rafId = requestAnimationFrame(tick);
}

function tickInner() {
  const now = performance.now();

  // Run the heavier YIN detection on a throttle, decoupled from the 60fps animation.
  // This both cuts CPU and stops the readout twitching on every single frame.
  if (now - state.lastDetectTs >= DETECT_INTERVAL_MS && now >= state.refToneGateUntil) {
    state.lastDetectTs = now;
    const buf = new Float32Array(state.analyser.fftSize);
    state.analyser.getFloatTimeDomainData(buf);
    const { minFreq, maxFreq } = freqRange();
    const raw = detectPitchYIN(buf, state.audioCtx.sampleRate, minFreq, maxFreq);

    if (raw < 0) {
      // Don't blank on the first miss — bass notes dip in and out as they sustain/
      // decay. Hold the last reading for SIGNAL_HOLD_MS so the display stays
      // continuous (like a hardware tuner), then idle once it's truly silent.
      if (now - state.lastGoodTs > SIGNAL_HOLD_MS) {
        state.history = [];
        state.smoothedFreq = null;
      }
    } else {
      state.lastGoodTs = now;
      state.history.push(raw);
      if (state.history.length > state.historySize) state.history.shift();
    }
  }

  let targetLeft = 50;          // needle target this frame (centre = idle)
  let needleClass = "needle";
  let announceNote = null;      // set below only while a pitch is actually being read
  let announceCentsVal = 0;

  // Need a few stable readings before showing a pitch.
  if (state.history.length >= 3) {
    const med = medianPitch(state.history);
    // Spread across recent history — wide spread = attack transient / unstable.
    const minF = Math.min(...state.history);
    const maxF = Math.max(...state.history);
    const spreadCents = 1200 * Math.log2(maxF / minF);

    // EMA the displayed pitch so it glides to rest; snap on a big jump (new string).
    if (state.smoothedFreq === null) {
      state.smoothedFreq = med;
    } else {
      const jumpCents = Math.abs(1200 * Math.log2(med / state.smoothedFreq));
      state.smoothedFreq = (jumpCents > NOTE_JUMP_CENTS)
        ? med
        : state.smoothedFreq + FREQ_EMA * (med - state.smoothedFreq);
    }
    const freq = state.smoothedFreq;

    const t = currentTuning();
    const idx = (state.selectedString !== null) ? state.selectedString : closestString(freq);
    const targetMidi = t.notes[idx];
    const targetFreq = midiToFreq(targetMidi, state.aref);
    const rawCents = (freqToMidi(freq, state.aref) - targetMidi) * 100;
    // Round to dead-on when very close — stops the last-digit flicker around 0
    // and gives a clean "in tune" the moment you're close enough.
    const cents = Math.abs(rawCents) < CLOSE_CENTS ? 0 : rawCents;

    $noteName.textContent = noteLabel(targetMidi);
    $noteTarget.textContent = `target ${targetFreq.toFixed(2)} Hz`;
    $noteCurrent.textContent = `heard ${freq.toFixed(2)} Hz`;
    $cents.textContent = `${cents > 0 ? "+" : ""}${cents.toFixed(1)} cents`;

    targetLeft = 50 + Math.max(-50, Math.min(50, cents));
    if (spreadCents > 35) {
      needleClass = "needle way-off";   // still settling — don't claim a verdict
    } else {
      const abs = Math.abs(cents);
      if (abs < 5) needleClass = "needle in-tune";
      else if (abs < 15) needleClass = "needle " + (cents < 0 ? "flat" : "sharp");
      else needleClass = "needle way-off";
    }

    announceNote = noteLabel(targetMidi);
    announceCentsVal = cents;
  } else {
    $cents.textContent = "— cents";   // idle: recentre the readout
  }

  const isInTune = needleClass === "needle in-tune";
  const enteredTune = shouldBuzz(state.wasInTune, isInTune);
  if (enteredTune) triggerHaptic();
  state.wasInTune = isInTune;

  if (announceNote !== null) {
    const announcement = buildAnnouncement(announceNote, announceCentsVal, isInTune);
    if (shouldAnnounce(now, state.lastAnnounceTs, state.lastAnnouncement, announcement, enteredTune)) {
      $announcer.textContent = announcement;
      state.lastAnnouncement = announcement;
      state.lastAnnounceTs = now;
    }
  }

  // Ease the needle toward its target every animation frame — smooth, calm motion
  // instead of snapping to each raw reading.
  state.needleLeft += (targetLeft - state.needleLeft) * 0.25;
  $needle.style.left = `${state.needleLeft}%`;
  $needle.className = needleClass;
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
      try {
        state.micStream = stream;
        const Ctx = window.AudioContext || window.webkitAudioContext;
        // Bass fundamentals top out ~130 Hz, so 22.05 kHz is ample Nyquist headroom
        // and halves the YIN diff-loop cost vs. native 44.1/48 kHz. The UA resamples
        // the mic input to match; fall back to the device default if it rejects the option.
        try {
          state.audioCtx = new Ctx({ sampleRate: 22050 });
        } catch (e) {
          state.audioCtx = new Ctx();
        }
        const source = state.audioCtx.createMediaStreamSource(stream);
        state.analyser = state.audioCtx.createAnalyser();
        state.analyser.fftSize = 8192;   // ~370ms window at 22.05kHz — more periods per read = cleaner low-freq fundamental
        state.analyser.smoothingTimeConstant = 0;
        source.connect(state.analyser);
      } catch (setupErr) {
        // Setup failed after the mic was already granted — stop the live track so the OS
        // recording indicator turns off, and clear state so the next Start doesn't leak a 2nd stream.
        stream.getTracks().forEach(t => t.stop());
        state.micStream = null;
        if (state.audioCtx) state.audioCtx.close();
        state.audioCtx = null;
        state.analyser = null;
        throw setupErr;
      }

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
  state.smoothedFreq = null;
  state.needleLeft = 50;
  state.lastDetectTs = 0;
  state.lastGoodTs = 0;
  state.wasInTune = false;
  state.lastAnnouncement = null;
  state.lastAnnounceTs = 0;
  state.refToneGateUntil = 0;
  $startBtn.textContent = "Start tuning";
  $startBtn.classList.remove("listening");
  $micStatus.classList.add("hidden");
  $noteName.textContent = "–";
  $noteTarget.textContent = "target — Hz";
  $noteCurrent.textContent = "heard — Hz";
  $cents.textContent = "— cents";
  $announcer.textContent = "";
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
  saveSettings();
});

document.querySelectorAll(".preset").forEach(btn => {
  btn.addEventListener("click", () => {
    state.aref = parseFloat(btn.dataset.aref);
    $arefSlider.value = state.aref;
    $arefValue.textContent = `${state.aref.toFixed(1)} Hz`;
    document.querySelectorAll(".preset").forEach(b => b.classList.toggle("active", b === btn));
    renderStrings();
    saveSettings();
  });
});

// Note: tuning buttons are now rendered dynamically via renderTuningButtons()
// because guitar and bass have different tuning sets. Initial render below.

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

// === Settings persistence (localStorage) — reopen where you left off ===
const SETTINGS_KEY = "tuner:settings:v1";

function saveSettings() {
  try {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify({
      aref: state.aref,
      instrumentKey: state.instrumentKey,
      tuningKey: state.tuningKey,
    }));
  } catch (e) { /* storage blocked (private mode / quota) — non-fatal */ }
}

function loadSettings() {
  let s;
  try { s = JSON.parse(localStorage.getItem(SETTINGS_KEY) || "null"); }
  catch (e) { return; }
  if (!s || typeof s !== "object") return;
  // Instrument + tuning must still exist (guards against preset schema changes).
  if (s.instrumentKey && INSTRUMENTS[s.instrumentKey]) {
    state.instrumentKey = s.instrumentKey;
    const tunings = INSTRUMENTS[s.instrumentKey].tunings;
    if (s.tuningKey && tunings[s.tuningKey]) state.tuningKey = s.tuningKey;
  }
  // A4 only within the slider's range.
  const aref = Number(s.aref);
  if (Number.isFinite(aref) && aref >= 415 && aref <= 466) {
    state.aref = aref;
    if ($arefSlider) $arefSlider.value = String(aref);
    if ($arefValue) $arefValue.textContent = `${aref.toFixed(1)} Hz`;
    document.querySelectorAll(".preset").forEach(btn => {
      btn.classList.toggle("active", parseFloat(btn.dataset.aref) === aref);
    });
  }
}

// Initial render — restore saved settings first so the UI paints in the right state.
loadSettings();
renderInstrumentButtons();
renderTuningButtons();
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

// === Browser feature detection ===
// Fail loud and friendly on browsers that can't run the tuner.
function checkBrowserSupport() {
  const missing = [];
  if (!window.AudioContext && !window.webkitAudioContext) missing.push("Web Audio API");
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) missing.push("getUserMedia");
  if (!window.Promise) missing.push("Promises");
  if (!window.requestAnimationFrame) missing.push("requestAnimationFrame");
  if (missing.length === 0) return true;

  diag("unsupported browser — missing: " + missing.join(", "));
  showMicError(
    `This browser is missing ${missing.join(" + ")}. Use a recent Chrome, Edge, Firefox, or Samsung Internet — Safari 14+ also works.`
  );
  $startBtn.disabled = true;
  return false;
}
checkBrowserSupport();

// === Service worker with update prompt ===
// When a new SW takes over (i.e., new app version is cached), show a toast so
// the user can reload to pick up the new code instead of running stale JS.
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").then((reg) => {
    if (!reg) return;
    diag("service worker registered");
    reg.addEventListener("updatefound", () => {
      const newWorker = reg.installing;
      if (!newWorker) return;
      newWorker.addEventListener("statechange", () => {
        if (newWorker.state === "installed" && navigator.serviceWorker.controller) {
          showUpdateToast();
        }
      });
    });
  }).catch((err) => {
    diag("service worker registration failed: " + err.message);
  });

  let refreshing = false;
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (refreshing) return;
    refreshing = true;
    window.location.reload();
  });
}

function showUpdateToast() {
  let toast = document.getElementById("update-toast");
  if (toast) return;
  toast = document.createElement("div");
  toast.id = "update-toast";
  toast.className = "update-toast";
  const text = document.createElement("span");
  text.textContent = "New version ready.";
  const btn = document.createElement("button");
  btn.textContent = "Reload";
  btn.addEventListener("click", () => {
    navigator.serviceWorker.getRegistrations().then((regs) => {
      const waiting = regs.find((r) => r.waiting);
      if (waiting && waiting.waiting) waiting.waiting.postMessage({ type: "SKIP_WAITING" });
      else window.location.reload();
    });
  });
  toast.appendChild(text);
  toast.appendChild(btn);
  document.body.appendChild(toast);
}
