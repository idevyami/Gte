#!/usr/bin/env bun
// =============================================================================
// ENTITY_000 — Audio Addendum P3 (WB-10 "The Air Itself": atmosphere pass)
// -----------------------------------------------------------------------------
// Adds 16 files (existing 50 are never touched). Deterministic: mulberry32
// seeded, integer-cycle-safe tonal loops, crossfaded noise-loop seams, events
// placed away from loop seams.
//
//   ambient/amb_whisper_loop.wav  — the dread bed (stage-reactive whisper)
//   ambient/amb_cityfar_loop.wav  — distant city murmur + one far bell
//   ambient/amb_hiss_loop.wav     — vent steam bed (positional)
//   sfx/sfx_drip.wav              — close water plunk (positional, undercity)
//   sfx/sfx_squeak.wav            — vermin squeak (positional)
//   sfx/sfx_page_rustle.wav       — paper flutter (positional, archive)
//   sfx/sfx_chain_creak.wav       — chain creak (positional, hangs)
//   sfx/sfx_bell_far.wav          — distant bell toll (ambient event)
//   sfx/sfx_gust.wav              — wind gust swell (ambient event)
//   sfx/sfx_choir_swell.wav       — faint choir swell (ambient event)
//   sfx/sfx_clank_far.wav         — distant machine clank + echo (event)
//   sfx/sfx_organ_chord.wav       — far organ chord (rare chapel event)
//   sfx/sfx_foot_stone.wav        — footstep variant: hard stone
//   sfx/sfx_foot_metal.wav        — footstep variant: engine plating ring
//   sfx/sfx_foot_carpet.wav       — footstep variant: chapel runner (muffled)
//   sfx/sfx_foot_wet.wav          — footstep variant: undercity damp
//
// Run: bun run /home/z/my-project/tools/gen_audio_p3.ts
// =============================================================================

import { mkdirSync, writeFileSync } from "node:fs";
import * as path from "node:path";

const SR = 44100;
const OUT_ROOT = "/home/z/entity000/audio";
const XFADE = 2205; // 50 ms equal-power loop crossfade

function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rnd = mulberry32(0xa11b0e5);

type Buf = Float32Array;
const samples = (sec: number): number => Math.max(1, Math.round(sec * SR));
const alloc = (sec: number): Buf => new Float32Array(samples(sec));

// ------------------------------- core synthesis ------------------------------

function sine(sec: number, freq: number, amp = 1, phase = 0): Buf {
  const n = samples(sec);
  const o = new Float32Array(n);
  const w = (2 * Math.PI * freq) / SR;
  for (let i = 0; i < n; i++) o[i] = amp * Math.sin(w * i + phase);
  return o;
}

/** Sine pair with slow relative detune (chorus / beating). */
function detunePair(sec: number, freq: number, beatHz: number, amp = 1): Buf {
  const n = samples(sec);
  const o = new Float32Array(n);
  const w1 = (2 * Math.PI * (freq - beatHz / 2)) / SR;
  const w2 = (2 * Math.PI * (freq + beatHz / 2)) / SR;
  for (let i = 0; i < n; i++) o[i] = amp * 0.5 * (Math.sin(w1 * i) + Math.sin(w2 * i));
  return o;
}

function glideSine(sec: number, f0: number, f1: number, tau: number, amp: number): Buf {
  const n = samples(sec);
  const o = new Float32Array(n);
  let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f = f0 + (f1 - f0) * Math.exp(-t / tau);
    ph += (2 * Math.PI * f) / SR;
    o[i] = amp * Math.sin(ph);
  }
  return o;
}

/** One-pole lowpass applied over the whole buffer (cutoff may drift in time). */
function lowpass(b: Buf, cutoffHz: number, endCutoff?: number): Buf {
  const n = b.length;
  const o = new Float32Array(n);
  let last = 0;
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const c = endCutoff !== undefined ? cutoffHz + (endCutoff - cutoffHz) * t : cutoffHz;
    const a = Math.exp((-2 * Math.PI * c) / SR);
    last = a * last + (1 - a) * b[i];
    o[i] = last;
  }
  return o;
}

function highpass(b: Buf, cutoffHz: number): Buf {
  const n = b.length;
  const o = new Float32Array(n);
  const a = Math.exp((-2 * Math.PI * cutoffHz) / SR);
  let last = 0;
  for (let i = 0; i < n; i++) {
    last = a * last + (1 - a) * b[i];
    o[i] = b[i] - last;
  }
  return o;
}

function white(sec: number, amp = 1): Buf {
  const n = samples(sec);
  const o = new Float32Array(n);
  for (let i = 0; i < n; i++) o[i] = (rnd() * 2 - 1) * amp;
  return o;
}

function brown(sec: number, amp = 1): Buf {
  const n = samples(sec);
  const o = new Float32Array(n);
  let last = 0;
  for (let i = 0; i < n; i++) {
    const w = rnd() * 2 - 1;
    last = (last + 0.02 * w) * 0.995;
    o[i] = last * 40 * amp;
  }
  return o;
}

/** Apply an arbitrary envelope function (0..1 over normalized time). */
function env(b: Buf, f: (t01: number) => number): Buf {
  const n = b.length;
  for (let i = 0; i < n; i++) b[i] *= f(i / n);
  return b;
}

/** Slow LFO amplitude modulation. */
function tremolo(b: Buf, hz: number, depth: number, phase = 0): Buf {
  const n = b.length;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    b[i] *= 1 - depth * 0.5 * (1 + Math.sin(2 * Math.PI * hz * t + phase));
  }
  return b;
}

function mix(dest: Buf, src: Buf, atSec: number, gain: number): void {
  const off = Math.round(atSec * SR);
  for (let i = 0; i < src.length && off + i < dest.length; i++) {
    dest[off + i] += src[i] * gain;
  }
}

function normalize(b: Buf, peak: number): Buf {
  let m = 0;
  for (let i = 0; i < b.length; i++) m = Math.max(m, Math.abs(b[i]));
  const k = m > 0 ? peak / m : 0;
  const o = new Float32Array(b.length);
  for (let i = 0; i < b.length; i++) o[i] = b[i] * k;
  return o;
}

/** Equal-power crossfade the tail into the head -> seamless loop of L sec. */
function loopify(b: Buf, L: number): Buf {
  const n = samples(L);
  const out = b.slice(0, n);
  const tail = b.length - n;
  const K = Math.min(XFADE, tail);
  for (let i = 0; i < K; i++) {
    const t = i / K;
    const g = Math.cos((t * Math.PI) / 2); // head gain: 1 -> 0.707
    const h = Math.sin((t * Math.PI) / 2); // tail gain: 0 -> 0.707
    out[i] = out[i] * g + b[n + i] * h;
  }
  return out;
}

function writeWav(p: string, b: Buf): void {
  const n = b.length;
  const buf = Buffer.alloc(44 + n * 2);
  buf.write("RIFF", 0, "ascii");
  buf.writeUInt32LE(36 + n * 2, 4);
  buf.write("WAVE", 8, "ascii");
  buf.write("fmt ", 12, "ascii");
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write("data", 36, "ascii");
  buf.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    let v = b[i];
    v = v < -1 ? -1 : v > 1 ? 1 : v;
    buf.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  mkdirSync(path.dirname(p), { recursive: true });
  writeFileSync(p, buf);
  console.log(`wrote ${p} (${n} samples, ${(n / SR).toFixed(3)}s)`);
}

// ============================================================================
// BEDS (loops)
// ============================================================================

// ------------------------------------------------- amb_whisper_loop (8 s) ----
// The dread bed. NOT words — the shape of listening: three slow breath-syllables
// of bandpassed noise (1.2-3.2 kHz) that swell and die, over a faint detuned
// high shimmer. Played on the Dread bus; volume is stage-driven in-game.
{
  const L = 8.0;
  const air = white(L + 0.05, 0.6);
  const breath = highpass(lowpass(air, 3200), 1200);
  // three syllable swells, placed away from the seam (0..L), unequal spacing
  const shape = alloc(L + 0.05);
  const swells = [
    { at: 0.4, len: 2.2, peak: 0.9 },
    { at: 3.1, len: 1.5, peak: 0.55 },
    { at: 5.0, len: 2.6, peak: 0.75 },
  ];
  for (const s of swells) {
    const n = samples(s.len);
    for (let i = 0; i < n; i++) {
      const t = i / n;
      const a = Math.sin(Math.PI * Math.pow(t, 0.8)); // slow attack, softer tail
      const off = Math.round(s.at * SR) + i;
      if (off < shape.length) shape[off] += a * s.peak;
    }
  }
  for (let i = 0; i < breath.length; i++) breath[i] *= Math.max(0, shape[i]);
  // faint shimmer: two beating high sines (integer Hz -> seam-safe over 8 s)
  const shim = alloc(L + 0.05);
  mix(shim, detunePair(L + 0.05, 2196, 1.3, 0.05), 0, 1.0);
  mix(shim, detunePair(L + 0.05, 3291, 0.9, 0.035), 0, 1.0);
  const b = alloc(L + 0.05);
  for (let i = 0; i < b.length; i++) b[i] = breath[i] * 0.85 + shim[i];
  writeWav(path.join(OUT_ROOT, "ambient", "amb_whisper_loop.wav"),
    normalize(loopify(b, L), 0.35));
}

// ------------------------------------------------ amb_cityfar_loop (12 s) ----
// The city heard from a rooftop: brown murmur bed, slow crowd shimmer, one
// soft far bell at 7 s (away from the seam), occasional cart-rumble dips.
{
  const L = 12.0;
  const bed = brown(L + 0.05, 0.7);
  const shimmer = lowpass(white(L + 0.05, 0.22), 900);
  tremolo(shimmer, 0.11, 0.6);
  tremolo(shimmer, 0.37, 0.3, 1.7);
  const b = alloc(L + 0.05);
  for (let i = 0; i < b.length; i++) b[i] = bed[i] * 0.8 + shimmer[i] * 0.5;
  // the far bell: damped minor partials, quiet
  const bell = alloc(2.2);
  mix(bell, glideSine(2.2, 442, 440, 6.0, 0.5), 0, 1.0);
  mix(bell, glideSine(2.2, 331, 330, 5.0, 0.35), 0, 1.0);
  mix(bell, glideSine(2.2, 221, 220, 4.0, 0.22), 0, 1.0);
  env(bell, (t) => Math.exp(-t * 2.6));
  mix(b, lowpass(bell, 1400), 7.0, 0.10);
  writeWav(path.join(OUT_ROOT, "ambient", "amb_cityfar_loop.wav"),
    normalize(loopify(b, L), 0.35));
}

// -------------------------------------------------- amb_hiss_loop (6 s) ----
// Vent steam: highpassed white noise with a slow breathing wobble. Positional
// emitters place it at the vent mouths.
{
  const L = 6.0;
  const n = white(L + 0.05, 0.8);
  const hp = highpass(n, 2400);
  tremolo(hp, 0.23, 0.45);
  tremolo(hp, 0.61, 0.2, 2.1);
  writeWav(path.join(OUT_ROOT, "ambient", "amb_hiss_loop.wav"),
    normalize(loopify(hp, L), 0.35));
}

// ============================================================================
// WORLD ONE-SHOTS (positional + ambient events)
// ============================================================================

// ------------------------------------------------------------ sfx_drip ----
{
  const b = alloc(0.35);
  mix(b, glideSine(0.16, 1150, 390, 0.025, 0.9), 0, 1.0);
  mix(b, lowpass(white(0.05, 0.3), 3800), 0.115, 0.25); // landing tick
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_drip.wav"), normalize(b, 0.8));
}

// ----------------------------------------------------------- sfx_squeak ----
{
  const b = alloc(0.09);
  const c = glideSine(0.09, 2050, 2950, 0.05, 0.9); // rising chirp
  mix(b, c, 0, 1.0);
  env(b, (t) => Math.exp(-t * 7));
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_squeak.wav"), normalize(b, 0.5));
}

// ----------------------------------------------------- sfx_page_rustle ----
{
  const b = alloc(0.5);
  const flut = lowpass(highpass(white(0.5, 0.8), 1800), 6500);
  tremolo(flut, 17, 0.85);
  env(flut, (t) => Math.sin(Math.PI * Math.pow(t, 0.7)));
  mix(b, flut, 0, 1.0);
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_page_rustle.wav"), normalize(b, 0.8));
}

// ------------------------------------------------------ sfx_chain_creak ----
{
  const b = alloc(0.7);
  // three staggered inharmonic metallic grains with pitch drift
  const grains = [
    { at: 0.0, f: 1710, drift: 60, g: 0.8 },
    { at: 0.18, f: 2380, drift: -90, g: 0.55 },
    { at: 0.37, f: 3140, drift: 120, g: 0.4 },
  ];
  for (const g of grains) {
    const n = 0.22;
    const tone = alloc(n);
    let ph = 0;
    for (let i = 0; i < tone.length; i++) {
      const t = i / SR;
      const f = g.f + g.drift * t * 4;
      ph += (2 * Math.PI * f) / SR;
      tone[i] = Math.sin(ph) * Math.exp(-t * 18);
    }
    mix(b, tone, g.at, g.g);
  }
  mix(b, lowpass(white(0.3, 0.35), 5200), 0.02, 0.4); // rattle body
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_chain_creak.wav"), normalize(b, 0.8));
}

// --------------------------------------------------------- sfx_bell_far ----
{
  const b = alloc(3.0);
  const partials = [220.5, 331.2, 442.0, 554.5, 663.0];
  const gains = [0.5, 0.42, 0.34, 0.2, 0.12];
  for (let k = 0; k < partials.length; k++) {
    const p = glideSine(2.8, partials[k] * 1.004, partials[k], 2.2, gains[k]);
    env(p, (t) => Math.exp(-t * (1.4 + k * 0.55)));
    mix(b, p, 0, 1.0);
  }
  mix(b, lowpass(white(0.08, 0.5), 900), 0, 0.35); // soft strike thump
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_bell_far.wav"), normalize(b, 0.8));
}

// ------------------------------------------------------------ sfx_gust ----
{
  const b = alloc(2.5);
  const w = white(2.5, 0.55);
  const swept = lowpass(w, 500, 1400); // opens up then we close it again by env
  tremolo(swept, 0.8, 0.4);
  env(swept, (t) => Math.pow(Math.sin(Math.PI * Math.pow(t, 0.85)), 1.4));
  mix(b, swept, 0, 1.0);
  mix(b, brown(2.5, 0.25), 0, 0.5);
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_gust.wav"), normalize(b, 0.8));
}

// ----------------------------------------------------- sfx_choir_swell ----
{
  const b = alloc(3.5);
  const stack = [220, 261.6, 329.6]; // A minor-ish, airy
  const amps = [0.4, 0.34, 0.28];
  for (let k = 0; k < stack.length; k++) {
    mix(b, detunePair(3.4, stack[k], 1.1 + k * 0.3, amps[k]), 0, 1.0);
  }
  const air = lowpass(white(3.4, 0.12), 1600);
  env(air, (t) => Math.sin(Math.PI * t));
  mix(b, air, 0, 1.0);
  env(b, (t) => Math.pow(Math.sin(Math.PI * Math.pow(t, 0.75)), 1.2));
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_choir_swell.wav"), normalize(b, 0.45));
}

// ------------------------------------------------------- sfx_clank_far ----
{
  const b = alloc(1.2);
  const strike = alloc(0.3);
  const partials = [812, 1264, 1978, 2530];
  const gains = [0.6, 0.45, 0.3, 0.2];
  for (let k = 0; k < partials.length; k++) {
    const p = glideSine(0.28, partials[k] * 1.01, partials[k], 0.1, gains[k]);
    env(p, (t) => Math.exp(-t * (9 + k * 4)));
    mix(strike, p, 0, 1.0);
  }
  mix(strike, lowpass(white(0.06, 0.5), 3000), 0, 0.4);
  mix(b, lowpass(strike, 2400), 0, 1.0);       // the strike, distance-damped
  mix(b, lowpass(strike, 1500), 0.42, 0.35);   // the echo off the far wall
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_clank_far.wav"), normalize(b, 0.8));
}

// ------------------------------------------------------ sfx_organ_chord ----
{
  const b = alloc(4.0);
  const stack = [110, 220, 261.6, 329.6, 440];
  const amps = [0.5, 0.42, 0.36, 0.3, 0.2];
  for (let k = 0; k < stack.length; k++) {
    const p = detunePair(3.9, stack[k], 0.6 + k * 0.2, amps[k]);
    env(p, (t) => Math.min(1, t * 6) * Math.pow(1 - t, 0.6)); // organ attack
    mix(b, p, 0, 1.0);
  }
  const wind_ = lowpass(white(3.9, 0.1), 700);
  env(wind_, (t) => Math.min(1, t * 6) * (1 - t));
  mix(b, wind_, 0, 1.0);
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_organ_chord.wav"), normalize(b, 0.5));
}

// ============================================================================
// FOOTSTEP MATERIALS (the ground answers the ear)
// ============================================================================

// ------------------------------------------------------- sfx_foot_stone ----
// Harder variant of the default step: a click transient the soft step lacks.
{
  const b = alloc(0.12);
  mix(b, lowpass(highpass(white(0.02, 0.9), 2000), 5200), 0, 0.8);
  mix(b, glideSine(0.09, 98, 70, 0.03, 0.9), 0, 0.8);
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_foot_stone.wav"), normalize(b, 0.8));
}

// ------------------------------------------------------- sfx_foot_metal ----
// Engine plating: the ring carries. Partial stack + thump.
{
  const b = alloc(0.16);
  const ring = alloc(0.14);
  const partials = [617, 1168, 1891];
  const gains = [0.5, 0.32, 0.18];
  for (let k = 0; k < partials.length; k++) {
    const p = sine(0.14, partials[k], gains[k]);
    env(p, (t) => Math.exp(-t * (16 + k * 8)));
    mix(ring, p, 0, 1.0);
  }
  mix(b, ring, 0, 0.9);
  mix(b, glideSine(0.08, 105, 74, 0.025, 1.0), 0, 0.85);
  mix(b, lowpass(white(0.03, 0.4), 4500), 0, 0.35);
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_foot_metal.wav"), normalize(b, 0.8));
}

// ----------------------------------------------------- sfx_foot_carpet ----
// The chapel runner: cloth-muffled, no click, warm body.
{
  const b = alloc(0.14);
  const cloth = lowpass(white(0.14, 0.8), 520);
  env(cloth, (t) => Math.exp(-t * 16));
  mix(b, cloth, 0, 0.9);
  mix(b, glideSine(0.09, 66, 52, 0.04, 1.0), 0, 0.7);
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_foot_carpet.wav"), normalize(b, 0.8));
}

// --------------------------------------------------------- sfx_foot_wet ----
// Undercity damp: a splash-struck step with a micro-scatter tail.
{
  const b = alloc(0.18);
  const splash = lowpass(white(0.09, 0.9), 2600, 700); // closing filter = wet
  env(splash, (t) => Math.exp(-t * 13));
  mix(b, splash, 0, 1.0);
  mix(b, glideSine(0.08, 88, 62, 0.03, 1.0), 0, 0.8);
  mix(b, lowpass(white(0.05, 0.3), 3200), 0.09, 0.3); // the scatter
  writeWav(path.join(OUT_ROOT, "sfx", "sfx_foot_wet.wav"), normalize(b, 0.8));
}

console.log("P3 addendum complete: 16 files.");
