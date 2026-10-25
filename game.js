import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import * as SkeletonUtils from 'three/addons/utils/SkeletonUtils.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// ============================================================================
// WORLD OF DHARMA — 100% WOW CLASSIC MECHANICS, SEATED MOUNTS & 7 BIOME REGIONS
// Seated Skeletal Rider Pose • [Z] Mount • [Esc] Settings • 7 Weather Biomes
// ============================================================================

// ============================================================================
// 1. POLYPHONIC WEB AUDIO API WOW ORCHESTRAL & ZONE INSTRUMENTAL MUSIC ENGINE
//    Features 7 Distinct Regional Instrumental Melodies + Tavern/Street Lute Themes
// ============================================================================
const ZONE_INSTRUMENTALS = [
  // I. Sahyadri / Elwynn Sanctuary — Lyrical Celtic Flute & Harp Pastoral in D Lydian
  {
    name: 'Song of the Sahyadri Sanctuary (Harp & Bamboo Flute)',
    tempoMs: 520,
    leadWave: 'sine',
    arpWave: 'triangle',
    droneFreqs: [146.83, 220.0, 293.66],
    melody: [587.33, 659.25, 739.99, 880.0, 739.99, 659.25, 587.33, 493.88, 587.33, 659.25, 440.0, 493.88],
    arp: [293.66, 369.99, 440.0, 554.37, 440.0, 369.99],
  },
  // II. Nilgiri Monsoon Cloudforest — Mystic Santoor & Rain Chimes in A Dorian
  {
    name: 'Monsoon Raga of Agasthya (Santoor & Temple Bells)',
    tempoMs: 460,
    leadWave: 'triangle',
    arpWave: 'sine',
    droneFreqs: [110.0, 164.81, 220.0],
    melody: [440.0, 493.88, 523.25, 659.25, 587.33, 523.25, 493.88, 440.0, 392.0, 440.0, 523.25, 493.88],
    arp: [220.0, 261.63, 329.63, 392.0, 329.63, 261.63],
  },
  // III. Golden Autumn Highlands — Noble French Horn & Acoustic Lute in G Major
  {
    name: 'Amber Highlands Fanfare (Noble Horn & Tavern Lute)',
    tempoMs: 540,
    leadWave: 'sawtooth',
    arpWave: 'triangle',
    droneFreqs: [98.0, 146.83, 196.0],
    melody: [392.0, 440.0, 493.88, 587.33, 659.25, 587.33, 493.88, 392.0, 440.0, 493.88, 392.0, 329.63],
    arp: [196.0, 246.94, 293.66, 392.0, 293.66, 246.94],
  },
  // IV. Sacred Mount Kailash — Dun Morogh / Winterspring Cello & Crystal Choir in E Aeolian
  {
    name: 'Hymn of Sacred Kailash (Alpine Cello & Crystal Chimes)',
    tempoMs: 620,
    leadWave: 'sine',
    arpWave: 'sine',
    droneFreqs: [82.41, 123.47, 164.81],
    melody: [659.25, 739.99, 783.99, 987.77, 880.0, 783.99, 659.25, 587.33, 659.25, 493.88, 587.33, 659.25],
    arp: [164.81, 196.0, 246.94, 329.63, 246.94, 196.0],
  },
  // V. Misty Bamboo Crags — Pandaria Shakuhachi Flute & Guzheng Zither Pentatonic
  {
    name: 'Jade Spirit Melody (Shakuhachi & Guzheng Zither)',
    tempoMs: 480,
    leadWave: 'sine',
    arpWave: 'triangle',
    droneFreqs: [130.81, 196.0, 261.63],
    melody: [523.25, 587.33, 659.25, 783.99, 880.0, 783.99, 659.25, 523.25, 587.33, 659.25, 523.25, 440.0],
    arp: [261.63, 329.63, 392.0, 523.25, 392.0, 329.63],
  },
  // VI. Great Himalayas (Everest) — Storm Peaks Brass & Cathedral Organ in C Minor
  {
    name: 'Crown of Sagarmatha Symphony (Cathedral Brass & Strings)',
    tempoMs: 580,
    leadWave: 'triangle',
    arpWave: 'sine',
    droneFreqs: [130.81, 196.0, 261.63],
    melody: [523.25, 587.33, 622.25, 783.99, 698.46, 622.25, 587.33, 523.25, 466.16, 523.25, 622.25, 587.33],
    arp: [261.63, 311.13, 392.0, 523.25, 392.0, 311.13],
  },
  // VII. Celestial Mount Meru — Sovereign Golden Vina & Celestial Harp in F Lydian
  {
    name: 'Vaikuntha Sovereign Theme (Celestial Vina & Golden Choir)',
    tempoMs: 450,
    leadWave: 'sine',
    arpWave: 'triangle',
    droneFreqs: [174.61, 261.63, 349.23],
    melody: [698.46, 783.99, 880.0, 987.77, 1046.5, 987.77, 880.0, 783.99, 698.46, 880.0, 783.99, 698.46],
    arp: [349.23, 440.0, 523.25, 659.25, 523.25, 440.0],
  },
];

// Lively WoW Tavern / Bazaar Street Lute Jig when walking along the Grand Bazaar Street!
const STREET_TAVERN_THEME = {
  name: 'Lion’s Pride & Bazaar Street Lute Jig',
  melody: [392.0, 440.0, 493.88, 587.33, 493.88, 440.0, 392.0, 329.63, 369.99, 392.0, 440.0, 392.0],
  arp: [196.0, 293.66, 392.0, 293.66],
};

class WoWSoundEngine {
  constructor() {
    this.ctx = null;
    this.muted = false;
    this.musicEnabled = true;
    this.ambientStarted = false;
    this.masterGain = null;
    this.musicGain = null;
    this.reverbNode = null;
    this.masterVol = 0.48;
    this.droneOscs = [];
    this.noteStep = 0;
    this.currentZoneId = 0;
    this.inBazaarStreet = false;
  }

  init() {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') this.ctx.resume();
      return;
    }
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    this.ctx = new AudioCtx();
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.value = this.masterVol;

    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = 1.0;

    this.reverbNode = this.createCathedralReverb(2.5, 2.2);
    const wetGain = this.ctx.createGain();
    wetGain.gain.value = 0.45;
    const dryGain = this.ctx.createGain();
    dryGain.gain.value = 0.78;

    this.masterGain.connect(dryGain);
    this.masterGain.connect(this.reverbNode);
    this.reverbNode.connect(wetGain);
    dryGain.connect(this.ctx.destination);
    wetGain.connect(this.ctx.destination);

    this.startAmbientSoundscape();
  }

  createCathedralReverb(duration, decay) {
    const rate = this.ctx.sampleRate;
    const length = Math.floor(rate * 0.9);
    const impulse = this.ctx.createBuffer(2, length, rate);
    for (let ch = 0; ch < 2; ch++) {
      const channelData = impulse.getChannelData(ch);
      for (let i = 0; i < length; i++) {
        channelData[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay);
      }
    }
    const convolver = this.ctx.createConvolver();
    convolver.buffer = impulse;
    return convolver;
  }

  setVolume(pct) {
    this.init();
    this.masterVol = (pct / 100) * 0.65;
    if (this.masterGain && !this.muted) {
      this.masterGain.gain.setTargetAtTime(this.masterVol, this.ctx.currentTime, 0.08);
    }
  }

  setEnableSound(enabled) {
    this.init();
    this.muted = !enabled;
    if (this.masterGain) {
      this.masterGain.gain.setTargetAtTime(this.muted ? 0.0 : this.masterVol, this.ctx.currentTime, 0.08);
    }
  }

  setEnableMusic(enabled) {
    this.init();
    this.musicEnabled = enabled;
    if (this.musicGain) {
      this.musicGain.gain.setTargetAtTime(enabled ? 1.0 : 0.0, this.ctx.currentTime, 0.1);
    }
  }

  setZoneMusic(continentId, inStreet = false) {
    this.currentZoneId = continentId;
    this.inBazaarStreet = inStreet;
    if (!this.ctx || this.droneOscs.length === 0) return;
    const theme = ZONE_INSTRUMENTALS[continentId] || ZONE_INSTRUMENTALS[0];
    const now = this.ctx.currentTime;
    this.droneOscs.forEach((osc, idx) => {
      const targetFreq = theme.droneFreqs[idx % theme.droneFreqs.length];
      osc.frequency.setTargetAtTime(targetFreq, now, 0.35);
    });
  }

  startAmbientSoundscape() {
    if (this.ambientStarted || !this.ctx) return;
    this.ambientStarted = true;

    const initFreqs = ZONE_INSTRUMENTALS[0].droneFreqs;
    initFreqs.forEach((f, idx) => {
      const osc = this.ctx.createOscillator();
      const filter = this.ctx.createBiquadFilter();
      const gain = this.ctx.createGain();
      osc.type = idx % 2 === 0 ? 'sine' : 'triangle';
      osc.frequency.value = f;
      filter.type = 'lowpass';
      filter.frequency.value = 380 + idx * 90;
      gain.gain.value = 0.026;

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(this.musicGain);
      osc.start();
      this.droneOscs.push(osc);
    });
    this.musicGain.connect(this.masterGain);

    // Continuous WoW Instrumental Sequencer (Lute Arpeggios + Flute/Horn Lead Melody!)
    setInterval(() => {
      if (this.muted || !this.musicEnabled || !this.ctx || this.ctx.state !== 'running') return;
      const theme = ZONE_INSTRUMENTALS[this.currentZoneId] || ZONE_INSTRUMENTALS[0];
      const activeTheme = this.inBazaarStreet ? STREET_TAVERN_THEME : theme;

      const step = this.noteStep++;
      // Play Lute/Harp Arpeggio Note on every beat
      const arpNote = activeTheme.arp[step % activeTheme.arp.length];
      this.playMusicNote(arpNote, 'triangle', 0.65, 0.055, 0.015);

      // Play Expressive Lead Instrumental Note (Flute / Horn / Cello / Vina)
      if (step % 2 === 0 || this.inBazaarStreet) {
        const leadIdx = Math.floor(step / 2) % activeTheme.melody.length;
        const leadNote = activeTheme.melody[leadIdx];
        const wave = this.inBazaarStreet ? 'triangle' : theme.leadWave;
        this.playMusicNote(leadNote, wave, 1.15, 0.068, 0.045);
      }
    }, 520);
  }

  playMusicNote(freq, type = 'sine', duration = 0.8, volume = 0.06, attack = 0.03) {
    if (this.muted || !this.musicEnabled || !this.ctx) return;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const filter = this.ctx.createBiquadFilter();
    const gain = this.ctx.createGain();

    osc.type = type;
    osc.frequency.setValueAtTime(freq, now);
    filter.type = 'lowpass';
    filter.frequency.value = type === 'sawtooth' ? 950 : 1800;

    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.linearRampToValueAtTime(volume, now + attack);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.musicGain);
    osc.start(now);
    osc.stop(now + duration + 0.05);
  }

  playTone(freq, type = 'sine', duration = 0.4, volume = 0.18, attack = 0.015, freqEnd = null) {
    this.init();
    if (this.muted || !this.ctx) return;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = type;
    osc.frequency.setValueAtTime(freq, now);
    if (freqEnd) {
      osc.frequency.exponentialRampToValueAtTime(freqEnd, now + duration);
    }

    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.linearRampToValueAtTime(volume, now + attack);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + duration + 0.05);
  }

  playTargetClick() {
    this.playTone(880, 'triangle', 0.08, 0.14, 0.005, 1320);
  }

  playCastStart() {
    const notes = [440, 554.37, 659.25];
    notes.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'sine', 0.32, 0.09, 0.02, n * 1.12), i * 50);
    });
  }

  playHealImpact() {
    const chord = [587.33, 739.99, 880.0, 1174.66];
    chord.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'sine', 0.6, 0.11, 0.015), i * 35);
    });
  }

  playNovaWave() {
    this.playTone(146.83, 'triangle', 0.9, 0.22, 0.03, 73.42);
    const shimmer = [440, 587.33, 659.25, 880, 1174.66];
    shimmer.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'sine', 0.7, 0.09, 0.02), i * 45);
    });
  }

  playWoWLevelUpFanfare() {
    const brassNotes = [
      { f: 293.66, delay: 0, dur: 0.45 },
      { f: 440.00, delay: 140, dur: 0.45 },
      { f: 587.33, delay: 280, dur: 1.6 },
      { f: 739.99, delay: 320, dur: 1.5 },
      { f: 880.00, delay: 360, dur: 1.7 },
    ];
    brassNotes.forEach((bn) => {
      setTimeout(() => {
        this.playTone(bn.f, 'sawtooth', bn.dur, 0.11, 0.04);
        this.playTone(bn.f * 0.5, 'triangle', bn.dur, 0.15, 0.04);
      }, bn.delay);
    });
  }

  playForgeAnvil() {
    this.playTone(1480, 'square', 0.18, 0.14, 0.004, 740);
    setTimeout(() => this.playTone(2217.46, 'sine', 0.55, 0.16, 0.005), 30);
  }

  playMountWhinnyOrWingbeat() {
    this.playTone(196.0, 'triangle', 0.38, 0.15, 0.02, 392.0);
    setTimeout(() => this.playTone(293.66, 'sine', 0.35, 0.12, 0.02, 587.33), 90);
  }

  playLootCoinBag() {
    this.playTone(1318.5, 'sine', 0.18, 0.14, 0.005, 1975.5);
    setTimeout(() => this.playTone(1760.0, 'sine', 0.28, 0.15, 0.005, 2637.0), 70);
  }

  playQuestAccept() {
    // Iconic WoW Parchment unfurl + warm heroic horn fifth (D4 -> A4 -> D5)
    const notes = [293.66, 440.0, 587.33];
    notes.forEach((f, idx) => {
      setTimeout(() => {
        this.playTone(f, 'triangle', 0.42, 0.14, 0.02);
        this.playTone(f * 1.5, 'sine', 0.35, 0.08, 0.02);
      }, idx * 85);
    });
  }

  playQuestComplete() {
    // Classic WoW Quest Complete brass & chime fanfare
    const chord = [587.33, 739.99, 880.0, 1174.66, 1479.98];
    chord.forEach((f, idx) => {
      setTimeout(() => {
        this.playTone(f, 'sawtooth', 0.65, 0.1, 0.03);
        this.playTone(f * 0.5, 'triangle', 0.7, 0.13, 0.03);
      }, idx * 65);
    });
  }
}

const SFX = new WoWSoundEngine();

// ============================================================================
// 2. THE 7 DISTINCT BIOME CONTINENTS OF THE WORLD
//    Each continent has VAST 15-MINUTE FLATLAND PLAINS & BAZAAR STREETS (`radius: 2600`)
//    plus a Colossal Multi-Peak Mountain Range towering on the northern horizon!
// ============================================================================
const CONTINENTS = [
  {
    id: 0,
    roman: 'I',
    name: 'Lush Greenery — Western Ghats (Sahyadri Plains & Escarpment)',
    shortName: 'I. Greenery (Sahyadri)',
    weather: 'petals',
    weatherLabel: '🎵 Song of Sahyadri (Flute & Harp)',
    skyTopColor: new THREE.Color(0x0d3b66),
    skyHorizonColor: new THREE.Color(0x7dd3fc),
    fogColor: new THREE.Color(0x68b5e8),
    groundTintColor: new THREE.Color(0x22c55e),
    x: 0,
    z: 0,
    radius: 2600,
    peakHeight: 2650.0,
    realMeters: 2695,
    allowFlying: true,
    tier: 1,
    diffMult: 1.0,
    maxHpBase: 120,
    karmaReward: 110,
    chestName: 'Sahyadri Shola Chest',
    relicName: 'Emerald Sahyadri Idol',
    boonIcon: '🌿',
    boonName: 'Boon of Sahyadri (Emerald Grace)',
    boonDesc: '+35% Healing Power & recharges Mount Vigor Orbs 40% faster.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 1,
    roman: 'II',
    name: 'Monsoon Rainy — Nilgiri & Agasthyamalai Cloudforest',
    shortName: 'II. Rainy (Nilgiris)',
    weather: 'rain',
    weatherLabel: '🎵 Monsoon Raga (Santoor & Chimes)',
    skyTopColor: new THREE.Color(0x0f172a),
    skyHorizonColor: new THREE.Color(0x334155),
    fogColor: new THREE.Color(0x3b4f6b),
    groundTintColor: new THREE.Color(0x15803d),
    x: 0,
    z: -4200,
    radius: 2600,
    peakHeight: 2800.0,
    realMeters: 2637,
    allowFlying: false, // No-Fly Trekking Range (Ground Mount Allowed!)
    tier: 2,
    diffMult: 1.8,
    maxHpBase: 220,
    karmaReward: 190,
    chestName: 'Neelakurinji Monsoon Chest',
    relicName: 'Kalash of Monsoon Rain',
    boonIcon: '🌧️',
    boonName: 'Boon of Agasthya (Monsoon Stride)',
    boonDesc: '+50% Ganga Nova AoE Radius & +40% Ground Mount / Trek Speed!',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 2,
    roman: 'III',
    name: 'Golden Autumn — Kilimanjaro & Amber Highlands',
    shortName: 'III. Autumn (Kilimanjaro)',
    weather: 'leaves',
    weatherLabel: '🎵 Amber Highlands (Noble Horn & Lute)',
    skyTopColor: new THREE.Color(0x3b1d5e),
    skyHorizonColor: new THREE.Color(0xf59e0b),
    fogColor: new THREE.Color(0xd97706),
    groundTintColor: new THREE.Color(0xd97706),
    x: 3900,
    z: -2400,
    radius: 2600,
    peakHeight: 3200.0,
    realMeters: 5895,
    allowFlying: true,
    tier: 3,
    diffMult: 2.8,
    maxHpBase: 360,
    karmaReward: 290,
    chestName: 'Uhuru Golden Chest',
    relicName: 'Amber Sun-Crown',
    boonIcon: '🍂',
    boonName: 'Boon of the Sky-Steed (Supersonic Glide)',
    boonDesc: 'Doubles Flying Mount velocity and cuts spell cast time by 35%.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 3,
    roman: 'IV',
    name: 'Snowy Blizzard — Sacred Mount Kailash & Nanda Devi',
    shortName: 'IV. Snowy (Mt. Kailash)',
    weather: 'snow',
    weatherLabel: '🎵 Hymn of Kailash (Cello & Choir)',
    skyTopColor: new THREE.Color(0x1e293b),
    skyHorizonColor: new THREE.Color(0xcbd5e1),
    fogColor: new THREE.Color(0xb8c9dc),
    groundTintColor: new THREE.Color(0xe2e8f0),
    x: 3900,
    z: 2400,
    radius: 2600,
    peakHeight: 3500.0,
    realMeters: 6638,
    allowFlying: false, // Sacred Parikrama Trekking Range
    tier: 4,
    diffMult: 4.2,
    maxHpBase: 540,
    karmaReward: 440,
    chestName: 'Manasarovar Frost Chest',
    relicName: 'Shiva’s Frost Damaru',
    boonIcon: '❄️',
    boonName: 'Boon of Kailash (Shiva’s Parikrama)',
    boonDesc: 'Doubles all Karma Points (☸️) earned across the universe.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 4,
    roman: 'V',
    name: 'Misty Bamboo — Denali & Jade Spirit Crags',
    shortName: 'V. Misty (Denali Jade)',
    weather: 'mist',
    weatherLabel: '🎵 Jade Spirit (Shakuhachi & Zither)',
    skyTopColor: new THREE.Color(0x064e3b),
    skyHorizonColor: new THREE.Color(0x6ee7b7),
    fogColor: new THREE.Color(0x52b788),
    groundTintColor: new THREE.Color(0x10b981),
    x: 0,
    z: 4200,
    radius: 2600,
    peakHeight: 3800.0,
    realMeters: 6961,
    allowFlying: true,
    tier: 5,
    diffMult: 6.0,
    maxHpBase: 780,
    karmaReward: 620,
    chestName: 'Jade Condor Chest',
    relicName: 'Jade Dragon Seal',
    boonIcon: '🌫️',
    boonName: 'Boon of Ganesha (Ridge Breaker)',
    boonDesc: 'All spells automatically chain-heal 2 additional suffering targets within 28m.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 5,
    roman: 'VI',
    name: 'Crystal Glacial — The Great Himalayas (Mount Everest)',
    shortName: 'VI. Glacial (Everest)',
    weather: 'snow',
    weatherLabel: '🎵 Sagarmatha Symphony (Brass & Strings)',
    skyTopColor: new THREE.Color(0x0c4a6e),
    skyHorizonColor: new THREE.Color(0xbae6fd),
    fogColor: new THREE.Color(0x93c5fd),
    groundTintColor: new THREE.Color(0xf1f5f9),
    x: -3900,
    z: 2400,
    radius: 2600,
    peakHeight: 4400.0,
    realMeters: 8848,
    allowFlying: false,
    tier: 6,
    diffMult: 8.5,
    maxHpBase: 1100,
    karmaReward: 950,
    chestName: 'Sagarmatha 8,848m Chest',
    relicName: 'Crown of Sagarmatha',
    boonIcon: '🏔️',
    boonName: 'Boon of Sagarmatha (Crown of the World)',
    boonDesc: 'Grants infinite mountain stamina and +50% Crit Healing.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 6,
    roman: 'VII',
    name: 'Celestial Starlight — Mount Meru (Cosmic Axis)',
    shortName: 'VII. Celestial (Meru)',
    weather: 'celestial',
    weatherLabel: '🎵 Vaikuntha Theme (Golden Vina & Harp)',
    skyTopColor: new THREE.Color(0x1e1b4b),
    skyHorizonColor: new THREE.Color(0xfde047),
    fogColor: new THREE.Color(0xc084fc),
    groundTintColor: new THREE.Color(0xfacc15),
    x: -3900,
    z: -2400,
    radius: 2600,
    peakHeight: 4800.0,
    realMeters: 10800,
    allowFlying: true,
    tier: 7,
    diffMult: 12.0,
    maxHpBase: 1600,
    karmaReward: 1800,
    chestName: 'Vaikuntha Sovereign Chest',
    relicName: 'Vishnu’s Kaustubha Gem',
    boonIcon: '👑',
    boonName: 'Boon of Vishnu (Universal Sovereign)',
    boonDesc: 'Unlocks flying even in No-Fly Zones + Passive Aura heals all beings around your Mount!',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
];

// ============================================================================
// KARMA FORGE ITEMS [K] & BACKPACK INVENTORY [B]
// ============================================================================
const SHOP_TOOLS = [
  {
    id: 'danda_staff',
    icon: '🦯',
    name: 'Sahyadri Brahmadanda Staff',
    category: 'Main Hand • Upgrades [1] & [3]',
    rank: 1,
    maxRank: 10,
    baseCost: 80,
    costMult: 1.55,
    desc: 'Channeling staff carved from sandalwood. Amplifies Sanjeevani Bolt [1], Sunbeam [3] & Summit Chest unlocking.',
    bonusText: (r) => `Current: +${(r - 1) * 45} Healing & Loot Power (Next: +${r * 45})`,
  },
  {
    id: 'dragon_saddle',
    icon: '🐎',
    name: 'Golden Pegasus & Drake Saddle',
    category: 'Mount Gear • Upgrades [Z] & [5]',
    rank: 1,
    maxRank: 8,
    baseCost: 95,
    costMult: 1.55,
    desc: 'Ornate saddle with golden stirrups. Increases Ground & Flying Mount speed and Vigor recharge rate.',
    bonusText: (r) => `Current: +${(r - 1) * 25}% Mount Speed & +${(r - 1) * 20}% Vigor Regen`,
  },
  {
    id: 'crampon_boots',
    icon: '🥾',
    name: 'Himalayan Mithril Crampons',
    category: 'Feet • Upgrades [4] & Climb',
    rank: 1,
    maxRank: 8,
    baseCost: 105,
    costMult: 1.6,
    desc: 'Essential for No-Fly Trekking Peaks (Nilgiris, Kailash, Everest)! Grips steep rock faces and boosts Sprint [4].',
    bonusText: (r) => `Current: +${(r - 1) * 28}% Steep-Slope Climb Speed`,
  },
  {
    id: 'camping_kit',
    icon: '⛺',
    name: 'Sherpa Base-Camp Brazier Kit',
    category: 'Trinket • Upgrades [G]',
    rank: 1,
    maxRank: 6,
    baseCost: 115,
    costMult: 1.6,
    desc: 'Upgrades your pitched Campfire [G] so resting heals all suffering creatures within 45m and refills Vigor.',
    bonusText: (r) => `Current: Campfire heals 45m radius for +${r * 90} Vitality`,
  },
  {
    id: 'sanjeevani_elixir',
    icon: '🧪',
    name: 'Himalayan Soma-Elixir',
    category: 'Consumable • Instant Burst',
    rank: 0,
    maxRank: 99,
    baseCost: 140,
    costMult: 1.15,
    desc: 'Instantly releases a 65-meter Golden Supernova around you, restoring +340 Rejuvenation and refilling all 6 Vigor Orbs!',
    bonusText: () => `Instant Use: 65m +340 Heal + 6/6 Mount Vigor!`,
    isConsumable: true,
  },
  {
    id: 'chakra_resonator',
    icon: '☸️',
    name: 'Sudarshana Dharma Chakra',
    category: 'Mythic Relic • Auto-Renewal Halo',
    rank: 0,
    maxRank: 5,
    baseCost: 240,
    costMult: 1.75,
    desc: 'Summons an orbiting golden Chakra above your head that automatically fires bolts at nearby suffering wildlife & chests!',
    bonusText: (r) => (r === 0 ? 'Not Yet Forged (Buy Rank 1 to Summon!)' : `Active: Auto-pulses nearby targets for ${r * 50}`),
  },
];

const BACKPACK_ITEMS = [
  { icon: '🪨', name: 'Sanctuary Hearthstone', desc: 'Teleports you back to Region I Western Ghats Base Camp.', action: 'hearth' },
  { icon: '⛵', name: 'Royal Canal & Harbor Skiff', desc: 'Summons your 3D Sailboat Skiff whenever you enter the City Canals or Harbor Sea!', action: 'boat' },
  { icon: '⛺', name: 'Sherpa Expedition Tent', desc: 'Pitch a warm 3D Mountain Campfire [G] anywhere.', action: 'camp' },
  { icon: '🐎', name: 'Golden Bridle of Ashva', desc: 'Summons or dismisses your Seated Mount [Z].', action: 'mount' },
  { icon: '🌿', name: 'Sanjeevani Herb Pouch', desc: 'Endless Himalayan healing herbs for wildlife.', action: 'heal' },
];

const STATE = {
  karma: 350,
  lifetimeKarma: 350,
  relicsLooted: 0,
  ascensionStage: 1,
  totalRejuvenated: 0,
  totalSites: 28,
  currentContinent: CONTINENTS[0],
  // DEFAULT MOUNTED & SEATED ON LAUNCH!
  isMounted: true,
  isFlying: false, // Press Space while mounted to lift off into 3D Flight!
  isBoating: false, // Automatically boards your Royal Canal & Harbor Sailboat Skiff on water!
  isSitting: false, // Toggled with [X] when unmounted
  activeVehicle: 'none', // 'carriage' | 'galleon_ferry' | 'none'
  autoRun: false,   // Toggled with [~] or [NumLock]
  speedRunActive: true,
  vigor: 6.0,
  maxVigor: 6,
  trekStamina: 100,
  wellFedTimer: 0,
  gcd: 0,           // WoW Classic 1.5s Global Cooldown
  selectedTarget: null,
  pendingLootEntity: null,
  casting: null,
  cooldowns: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 },
  cdMax:     { 1: 1.5, 2: 2.2, 3: 3.0, 4: 0.5, 5: 1.5, 6: 5.0, 7: 0.5 },
  settings: {
    soundEnabled: true,
    masterVol: 75,
    musicEnabled: true,
    bloomStrength: 0.38,
    weatherEnabled: true,
    shadowsEnabled: true,
    instantMount: true,
    autoLoot: false,
    stickyTarget: true,
  },
};

function showToast(msg) {
  const el = document.getElementById('status-toast-txt');
  if (el) el.textContent = msg;
}

function getHealPower() {
  const staffRank = SHOP_TOOLS[0].rank;
  const boonMult = CONTINENTS[0].completed ? 1.35 : 1.0;
  return Math.round((85 + (staffRank - 1) * 45) * boonMult);
}
function getAoERadius() {
  return CONTINENTS[1].completed ? 34 : 24;
}
function getKarmaMultiplier() {
  let mult = 1.0 + STATE.relicsLooted * 0.15;
  if (CONTINENTS[3].completed) mult *= 2.0;
  return mult;
}
function getMountSpeedMult() {
  let mult = 1.0 + (SHOP_TOOLS[1].rank - 1) * 0.25;
  if (CONTINENTS[2].completed) mult *= 1.5;
  return mult * 0.42; // Realistic WoW scale: takes 10-15 minutes to run across vast 2,600m continent
}
function getTrekSpeedMult() {
  let mult = 1.0 + (SHOP_TOOLS[2].rank - 1) * 0.25;
  if (CONTINENTS[1].completed) mult += 0.4;
  if (STATE.wellFedTimer > 0) mult += 0.25;
  return mult * 0.45; // Realistic pedestrian pacing
}
function canFlyOnContinent(cont) {
  return cont.allowFlying || CONTINENTS[6].completed;
}

// ============================================================================
// 3. 2026 NEXT-GEN WEBGL2 RENDERER + UNREAL BLOOM + BIOME SKY SHADER
// ============================================================================
const container = document.getElementById('canvas-container');
const nameplatesContainer = document.getElementById('nameplates-container');

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0d3b66);

const camera = new THREE.PerspectiveCamera(58, window.innerWidth / window.innerHeight, 0.5, 16000);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.35));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.08;
container.appendChild(renderer.domElement);

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloomPass = new UnrealBloomPass(
  new THREE.Vector2(Math.floor(window.innerWidth * 0.5), Math.floor(window.innerHeight * 0.5)),
  0.34,
  0.5,
  0.82
);
composer.addPass(bloomPass);

// Dynamic Biome Sky Dome (Smoothly transitions sky zenith & horizon colors across the 7 Weather Regions!)
const skyGeo = new THREE.SphereGeometry(12000, 24, 16);
const skyMat = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  depthWrite: false,
  uniforms: {
    uSkyTop: { value: CONTINENTS[0].skyTopColor.clone() },
    uSkyHorizon: { value: CONTINENTS[0].skyHorizonColor.clone() },
    uSunDir: { value: new THREE.Vector3(0.54, 0.38, -0.75).normalize() },
  },
  vertexShader: `
    varying vec3 vWorldPos;
    void main() {
      vec4 wp = modelMatrix * vec4(position, 1.0);
      vWorldPos = wp.xyz;
      gl_Position = projectionMatrix * viewMatrix * wp;
    }
  `,
  fragmentShader: `
    varying vec3 vWorldPos;
    uniform vec3 uSkyTop;
    uniform vec3 uSkyHorizon;
    uniform vec3 uSunDir;
    void main() {
      vec3 dir = normalize(vWorldPos);
      float h = clamp(dir.y * 1.3 + 0.1, 0.0, 1.0);
      vec3 col = mix(uSkyHorizon, uSkyTop, pow(h, 0.62));
      float sunAmt = max(dot(dir, uSunDir), 0.0);
      col += vec3(1.0, 0.78, 0.42) * pow(sunAmt, 9.0) * 0.42;
      col += vec3(1.3, 1.15, 0.85) * smoothstep(0.995, 0.9996, sunAmt);
      gl_FragColor = vec4(col, 1.0);
    }
  `,
});
scene.add(new THREE.Mesh(skyGeo, skyMat));

const hemiLight = new THREE.HemisphereLight(0xd9f0ff, 0x3b4d38, 0.95);
hemiLight.position.set(0, 350, 0);
scene.add(hemiLight);

const sunLight = new THREE.DirectionalLight(0xffeacc, 2.35);
sunLight.position.set(170, 240, -165);
sunLight.castShadow = true;
sunLight.shadow.mapSize.width = 1024;
sunLight.shadow.mapSize.height = 1024;
sunLight.shadow.camera.near = 10;
sunLight.shadow.camera.far = 750;
const d = 150;
sunLight.shadow.camera.left = -d;
sunLight.shadow.camera.right = d;
sunLight.shadow.camera.top = d;
sunLight.shadow.camera.bottom = -d;
sunLight.shadow.bias = -0.0005;
scene.add(sunLight);

// ============================================================================
// 4. ATMOSPHERE CONTROLLER (FALLING RECTANGLES REMOVED FOR CRISP CLEAR VIEW!)
// ============================================================================
function updateWeatherParticles() {
  // Falling rectangle particles removed per user request for crystal-clear vistas & 60 FPS!
}

// ============================================================================
// 5. COLOSSAL CONTINENTAL MOUNTAIN RANGE TOPOGRAPHY & 7-BIOME SHADER
//    True Multi-Peak Ridged Multifractal Mountain Chains (Not a Small Hill!)
//    Towering 2,650m–4,800m vertically so flying to the True Apex takes 15+ minutes!
// ============================================================================
function hash2D(x, z) {
  const s = Math.sin(x * 127.1 + z * 311.7) * 43758.5453123;
  return s - Math.floor(s);
}

function valueNoise(x, z) {
  const ix = Math.floor(x);
  const iz = Math.floor(z);
  const fx = x - ix;
  const fz = z - iz;
  const ux = fx * fx * (3.0 - 2.0 * fx);
  const uz = fz * fz * (3.0 - 2.0 * fz);
  const a = hash2D(ix, iz);
  const b = hash2D(ix + 1, iz);
  const c = hash2D(ix, iz + 1);
  const d = hash2D(ix + 1, iz + 1);
  return a + (b - a) * ux + (c - a) * uz + (a - b - c + d) * ux * uz;
}

function fbm(x, z) {
  let v = 0.0;
  let amp = 0.5;
  let freq = 1.0;
  for (let i = 0; i < 4; i++) {
    v += amp * valueNoise(x * freq, z * freq);
    freq *= 2.03;
    amp *= 0.5;
  }
  return v;
}

// Sharp Ridged Multifractal Noise for Jagged Himalayan / Sahyadri Knife-Edge Arêtes & Crags
function ridgedMultifractal(x, z) {
  let sum = 0.0;
  let amp = 0.58;
  let freq = 1.0;
  let weight = 1.0;
  for (let i = 0; i < 3; i++) {
    let n = 1.0 - Math.abs(valueNoise(x * freq, z * freq) * 2.0 - 1.0);
    n = n * n * weight;
    weight = Math.min(1.0, Math.max(0.15, n * 1.9));
    sum += n * amp;
    freq *= 2.15;
    amp *= 0.48;
  }
  return sum;
}

function getPeakCenter(c) {
  return { px: c.x, pz: c.z - 520 };
}

// Compute the exact (x, z, roadY) along the 3.5-Turn Spiral Mountain Ghat Roadway from Town Plaza (s=0) to Summit (s=1)!
function getSpiralRoadPoint(c, s) {
  const { px, pz } = getPeakCenter(c);
  if (s <= 0.16) {
    // Straight Grand Bazaar & Foothill Approach Highway from Town Plaza (c.z + 40) to the southern base of the mountain (pz + 340)
    const t = s / 0.16;
    const rx = c.x + Math.sin(t * Math.PI) * 14.0;
    const rz = c.z + 40.0 - t * 220.0;
    return { rx, rz };
  }
  // 3.5-Turn Helical Switchback Roadway spiraling around and up the Mountain Massif to the True Summit!
  const u = (s - 0.16) / 0.84;
  const turns = 3.5;
  const angle = Math.PI * 0.5 + u * Math.PI * 2.0 * turns;
  const rX = (1.0 - Math.pow(u, 0.88) * 0.94) * 440.0;
  const rZ = (1.0 - Math.pow(u, 0.88) * 0.94) * 320.0;
  const rx = px + Math.cos(angle) * rX;
  const rz = pz + Math.sin(angle) * rZ;
  return { rx, rz };
}

// Returns [0..1] road mask (>0 if (x,z) is on the Town Bazaar Avenue, Cross-Bazaar Street, or Spiral Mountain Roadway!)
function getRoadwayMask(c, x, z) {
  let mask = 0.0;
  // 1. North-South Grand Bazaar & Approach Highway
  if (z > c.z - 220.0 && z < c.z + 240.0) {
    const dX = Math.abs(x - c.x);
    if (dX < 9.5) {
      mask = Math.max(mask, 1.0 - Math.max(0.0, (dX - 5.5) / 4.0));
    }
  }
  // 2. East-West Cross-Bazaar Merchant Boulevard
  if (x > c.x - 220.0 && x < c.x + 220.0) {
    const dZ = Math.abs(z - c.z);
    if (dZ < 8.5) {
      mask = Math.max(mask, 1.0 - Math.max(0.0, (dZ - 4.8) / 3.7));
    }
  }
  // 3. 3.5-Turn Spiral Mountain Ghat Roadway around and up the Mountain to the Summit!
  const { px, pz } = getPeakCenter(c);
  const dxP = x - px;
  const dzP = z - pz;
  if (Math.abs(dxP) < 470.0 && Math.abs(dzP) < 350.0) {
    const rawAngle = Math.atan2(dzP, dxP);
    let relAngle = rawAngle - Math.PI * 0.5;
    while (relAngle < 0) relAngle += Math.PI * 2.0;
    const turns = 3.5;
    for (let k = 0; k < 4; k++) {
      const totalAngle = relAngle + k * Math.PI * 2.0;
      const u = totalAngle / (Math.PI * 2.0 * turns);
      if (u >= 0.0 && u <= 1.02) {
        const rX = (1.0 - Math.pow(Math.min(1.0, u), 0.88) * 0.94) * 440.0;
        const rZ = (1.0 - Math.pow(Math.min(1.0, u), 0.88) * 0.94) * 320.0;
        const ex = Math.cos(rawAngle) * rX;
        const ez = Math.sin(rawAngle) * rZ;
        const distToRoad = Math.hypot(dxP - ex, dzP - ez);
        if (distToRoad < 12.0) {
          const rm = 1.0 - Math.max(0.0, (distToRoad - 5.5) / 6.5);
          mask = Math.max(mask, rm);
        }
      }
    }
  }
  return mask;
}

function getTerrainHeight(x, z) {
  let maxContinentH = -8.5;

  for (let i = 0; i < CONTINENTS.length; i++) {
    const c = CONTINENTS[i];
    const dx = x - c.x;
    const dz = z - c.z;
    const maxR = c.radius * 1.15;
    // Fast bounding-box reject before Math.hypot or noise evaluation!
    if (Math.abs(dx) > maxR || Math.abs(dz) > maxR) continue;
    const distIsland = Math.hypot(dx, dz);

    if (distIsland < maxR) {
      const normD = distIsland / c.radius;
      // Flat plateau across 92% of the 5,200m continent so the player has 15-minute vast flatlands!
      const edgeFade = normD < 0.88 ? 1.0 : Math.max(0.0, 1.0 - (normD - 0.88) / 0.27);
      const smoothMask = edgeFade * edgeFade * (3.0 - 2.0 * edgeFade);

      const n1 = valueNoise((x + i * 37) * 0.008, (z + i * 53) * 0.008);
      const n2 = valueNoise(x * 0.035, z * 0.035);

      // Expansive Flat Plains & Gentle Meadows (Y ~ 2.6m across miles of flatland!)
      let h = -7.5 + smoothMask * (10.1 + (n1 - 0.5) * 1.4 + (n2 - 0.5) * 0.6);

      // COLOSSAL MULTI-PEAK MOUNTAIN RANGE SPANNING THE NORTHERN HORIZON
      const { px, pz } = getPeakCenter(c);
      const dxRange = x - px;
      const dzRange = z - pz;

      // Amphitheater arc: flanking wings curve slightly southward so the mountain range wraps around the horizon!
      const arcCurveZ = Math.min(180.0, (dxRange * dxRange) * 0.00022) + Math.sin(dxRange * 0.005 + i * 1.3) * 32.0;
      const distFromSpineZ = Math.abs(dzRange - arcCurveZ);
      const lateralNorm = Math.abs(dxRange) / 980.0;
      const depthNorm = distFromSpineZ / 390.0;

      if (lateralNorm < 1.0 && depthNorm < 1.0) {
        const rNoise = ridgedMultifractal((x + i * 71) * 0.014, (z + i * 29) * 0.016);
        const rFine = 1.0 - Math.abs(valueNoise((x - i * 43) * 0.038, (z + i * 19) * 0.038) * 2.0 - 1.0);
        const latEnv = Math.pow(1.0 - lateralNorm * lateralNorm, 0.75);
        const depthEnv = Math.pow(1.0 - depthNorm, 1.45);
        const rangeEnvelope = latEnv * depthEnv;

        // 7 Distinct Jagged Alpine Massifs along the Range (Central Sovereign Apex + 6 Flanking Peaks)
        const p0 = Math.exp(-(dxRange * dxRange) / (2.0 * 95.0 * 95.0) - (distFromSpineZ * distFromSpineZ) / (2.0 * 105.0 * 105.0));
        const pL1 = 0.88 * Math.exp(-Math.pow(dxRange + 195, 2) / 14500 - Math.pow(distFromSpineZ - 12, 2) / 14500);
        const pR1 = 0.90 * Math.exp(-Math.pow(dxRange - 205, 2) / 14800 - Math.pow(distFromSpineZ - 10, 2) / 14800);
        const pL2 = 0.78 * Math.exp(-Math.pow(dxRange + 390, 2) / 18500 - Math.pow(distFromSpineZ - 18, 2) / 16500);
        const pR2 = 0.81 * Math.exp(-Math.pow(dxRange - 400, 2) / 18800 - Math.pow(distFromSpineZ - 15, 2) / 16500);
        const pL3 = 0.68 * Math.exp(-Math.pow(dxRange + 590, 2) / 22500 - Math.pow(distFromSpineZ - 24, 2) / 18500);
        const pR3 = 0.70 * Math.exp(-Math.pow(dxRange - 600, 2) / 22500 - Math.pow(distFromSpineZ - 22, 2) / 18500);
        const massifChain = Math.max(p0, pL1, pR1, pL2, pR2, pL3, pR3);

        // Multi-tiered Ridged Multifractal Crags, Knife-Edge Arêtes & Glacial Cirques
        const highAltitudeScale = c.peakHeight;
        const foothills = Math.pow(rangeEnvelope, 1.25) * (highAltitudeScale * 0.22) * (0.45 + 0.85 * rNoise);
        const toweringSpire = Math.pow(massifChain, 1.35) * (highAltitudeScale * 0.68) * (0.58 + 0.62 * rNoise);
        const serratedCouloirs = (Math.pow(rNoise, 1.8) * 0.7 + rFine * 0.3) * rangeEnvelope * (highAltitudeScale * 0.24);

        let mountainRise = foothills + toweringSpire + serratedCouloirs;

        // Carve Smooth, Walkable & Rideable Terraced Spiral Roadway Switchbacks into the Mountain Slope!
        const roadM = getRoadwayMask(c, x, z);
        if (roadM > 0.01) {
          const smoothGradeRise = foothills * 0.75 + Math.pow(massifChain, 1.15) * (highAltitudeScale * 0.62);
          mountainRise = mountainRise * (1.0 - roadM * 0.65) + smoothGradeRise * (roadM * 0.65);
        }

        h += mountainRise;
      }

      // Perfectly Level Grand Bazaar Street & Town Plaza (Radius 195m)
      if (distIsland < 195.0) {
        const flatF = 1.0 - Math.min(1.0, Math.max(0.0, (distIsland - 125.0) / 70.0));
        const smoothFlat = flatF * flatF * (3.0 - 2.0 * flatF);
        h = h * (1.0 - smoothFlat * 0.98) + 2.6 * (smoothFlat * 0.98);
      }

      // Carve the Grand Imperial Canal & Southern Maritime Harbor Bay right through the City!
      // 1. East-West Grand City Canal at dz = +28m (width 11m, depth Y = -2.35m so Ocean water at Y = -1.6m fills it!)
      if (Math.abs(dx) < 280.0 && Math.abs(dx) > 6.2) {
        const dCanal = Math.abs(dz - 28.0);
        if (dCanal < 6.2) {
          const cF = 1.0 - Math.max(0.0, (dCanal - 3.6) / 2.6);
          h = h * (1.0 - cF) + -2.35 * cF;
        }
      }
      // 2. Southern Maritime Harbor & Shipping Bay (dz > +64m, width 190m) where Galleons & Ferries dock!
      if (dz > 64.0 && dz < 340.0 && Math.abs(dx) < 110.0) {
        const hZ = Math.min(1.0, (dz - 64.0) / 8.0);
        const hX = 1.0 - Math.max(0.0, (Math.abs(dx) - 85.0) / 25.0);
        const bayF = hZ * hX;
        h = h * (1.0 - bayF) + -2.85 * bayF;
      }

      if (h > maxContinentH) maxContinentH = h;
    }
  }
  return maxContinentH;
}

// Winding Expedition Roadway Point from Town Plaza spiraling around & up the Mountain Range to the Summit
function getMountainTrailPoint(c, progress) {
  const { rx, rz } = getSpiralRoadPoint(c, progress);
  const y = getTerrainHeight(rx, rz);
  return new THREE.Vector3(rx, y, rz);
}

function getNearestContinent(x, z) {
  let best = CONTINENTS[0];
  let bestD = Infinity;
  for (let i = 0; i < CONTINENTS.length; i++) {
    const c = CONTINENTS[i];
    const d = Math.hypot(x - c.x, z - c.z);
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return best;
}

const MAX_CLEANSE_ZONES = 16;
const cleanseCenters = [];
for (let i = 0; i < MAX_CLEANSE_ZONES; i++) {
  cleanseCenters.push(new THREE.Vector4(99999, 99999, 0.0, 0.0));
}
// Each Continent's Town Plaza & Flatlands start lush and welcoming!
CONTINENTS.forEach((c, idx) => {
  if (idx < MAX_CLEANSE_ZONES) {
    cleanseCenters[idx].set(c.x, c.z, 240.0, 240.0);
  }
});
let nextCleanseIdx = CONTINENTS.length;

function addRejuvenationZone(x, z, radius = 95.0) {
  const idx = nextCleanseIdx % MAX_CLEANSE_ZONES;
  cleanseCenters[idx].set(x, z, 2.0, radius);
  nextCleanseIdx++;
}

const WORLD_SIZE = 12800;
const terrainGeo = new THREE.PlaneGeometry(WORLD_SIZE, WORLD_SIZE, 280, 280);
terrainGeo.rotateX(-Math.PI / 2);
const posAttr = terrainGeo.attributes.position;
for (let i = 0; i < posAttr.count; i++) {
  const vx = posAttr.getX(i);
  const vz = posAttr.getZ(i);
  // Variable-density vertex mapping: ultra-high resolution around each continent's Town Street, Flatlands & Mountain Range!
  posAttr.setY(i, getTerrainHeight(vx, vz));
}
terrainGeo.computeVertexNormals();

// Photorealistic Golf Turf & Fairway Canvas Textures (Like PGA Tour / EA Sports PGA)
function createPgaGolfTurfTexture() {
  const c = document.createElement('canvas');
  c.width = 256;
  c.height = 256;
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(256, 256);
  for (let y = 0; y < 256; y++) {
    // Subtle fairway mowing stripes (golf course pattern)
    const stripe = Math.sin(y * 0.18) * 14.0;
    for (let x = 0; x < 256; x++) {
      const idx = (y * 256 + x) * 4;
      const nFine = valueNoise(x * 0.45, y * 0.45);
      const nMacro = valueNoise(x * 0.08, y * 0.08);
      const blade = (hash2D(x * 3.1, y * 2.7) - 0.5) * 26.0;
      
      const r = Math.min(255, Math.max(20, 42 + stripe * 0.4 + (nFine - 0.5) * 24 + (nMacro - 0.5) * 30 + blade));
      const g = Math.min(255, Math.max(65, 126 + stripe + (nFine - 0.5) * 45 + (nMacro - 0.5) * 40 + blade));
      const b = Math.min(255, Math.max(15, 34 + stripe * 0.2 + (nFine - 0.5) * 18 + (nMacro - 0.5) * 20));

      img.data[idx] = r;
      img.data[idx + 1] = g;
      img.data[idx + 2] = b;
      img.data[idx + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(128, 128);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

// Photorealistic Sand Trap & Fairway Bunker Texture
function createPgaSandTexture() {
  const c = document.createElement('canvas');
  c.width = 128;
  c.height = 128;
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(128, 128);
  for (let y = 0; y < 128; y++) {
    for (let x = 0; x < 128; x++) {
      const idx = (y * 128 + x) * 4;
      const grain = (hash2D(x * 7.1, y * 5.3) - 0.5) * 32.0;
      const n = valueNoise(x * 0.2, y * 0.2);
      img.data[idx] = Math.min(255, Math.max(140, 218 + grain + (n - 0.5) * 25));
      img.data[idx + 1] = Math.min(255, Math.max(120, 195 + grain * 0.9 + (n - 0.5) * 25));
      img.data[idx + 2] = Math.min(255, Math.max(90, 148 + grain * 0.7 + (n - 0.5) * 20));
      img.data[idx + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(96, 96);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

// Photorealistic Weathered Cobblestone & Paved Roadway Texture
function createPavedRoadwayTexture() {
  const c = document.createElement('canvas');
  c.width = 128;
  c.height = 128;
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(128, 128);
  for (let y = 0; y < 128; y++) {
    const isMortarY = (y % 16 === 0 || y % 16 === 1);
    for (let x = 0; x < 128; x++) {
      const rowOffset = Math.floor(y / 16) % 2 === 0 ? 0 : 8;
      const isMortarX = ((x + rowOffset) % 16 === 0 || (x + rowOffset) % 16 === 1);
      const isMortar = isMortarX || isMortarY;
      const idx = (y * 128 + x) * 4;
      const n = valueNoise(x * 0.35, y * 0.35);
      const pebble = (hash2D(x * 4.3, y * 3.9) - 0.5) * 36;
      if (isMortar) {
        img.data[idx] = 78 + pebble * 0.3;
        img.data[idx + 1] = 72 + pebble * 0.3;
        img.data[idx + 2] = 65 + pebble * 0.3;
      } else {
        img.data[idx] = Math.min(255, Math.max(60, 142 + (n - 0.5) * 40 + pebble));
        img.data[idx + 1] = Math.min(255, Math.max(55, 134 + (n - 0.5) * 38 + pebble));
        img.data[idx + 2] = Math.min(255, Math.max(50, 122 + (n - 0.5) * 34 + pebble));
      }
      img.data[idx + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(160, 160);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

const pgaTurfTex = createPgaGolfTurfTexture();
const pgaSandTex = createPgaSandTexture();
const pavedRoadTex = createPavedRoadwayTexture();

const terrainShaderMat = new THREE.ShaderMaterial({
  uniforms: {
    uCleanseZones: { value: cleanseCenters },
    uSunDir: { value: new THREE.Vector3(0.54, 0.38, -0.75).normalize() },
    uFogColor: { value: CONTINENTS[0].fogColor.clone() },
    uGroundTint: { value: CONTINENTS[0].groundTintColor.clone() },
    uTurfTex: { value: pgaTurfTex },
    uSandTex: { value: pgaSandTex },
    uPavedTex: { value: pavedRoadTex },
    uTime: { value: 0 },
  },
  vertexShader: `
    varying vec3 vWorldPos;
    varying vec3 vNormal;
    varying vec2 vUv;
    void main() {
      vec4 wp = modelMatrix * vec4(position, 1.0);
      vWorldPos = wp.xyz;
      vNormal = normalize(normalMatrix * normal);
      vUv = uv;
      gl_Position = projectionMatrix * viewMatrix * wp;
    }
  `,
  fragmentShader: `
    uniform vec4 uCleanseZones[${MAX_CLEANSE_ZONES}];
    uniform vec3 uSunDir;
    uniform vec3 uFogColor;
    uniform vec3 uGroundTint;
    uniform sampler2D uTurfTex;
    uniform sampler2D uSandTex;
    uniform sampler2D uPavedTex;
    uniform float uTime;
    varying vec3 vWorldPos;
    varying vec3 vNormal;
    varying vec2 vUv;

    float hash(vec2 p) {
      return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
    }

    float noise(vec2 p) {
      vec2 i = floor(p);
      vec2 f = fract(p);
      f = f * f * (3.0 - 2.0 * f);
      return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
      );
    }

    float fbmDetail(vec2 p) {
      float v = 0.0;
      v += 0.60 * noise(p);
      v += 0.30 * noise(p * 2.15);
      v += 0.10 * noise(p * 4.5);
      return v;
    }

    void main() {
      float hC = fbmDetail(vWorldPos.xz * 0.38);
      float macro = noise(vWorldPos.xz * 0.055);
      float slope = 1.0 - max(dot(vNormal, vec3(0.0, 1.0, 0.0)), 0.0);

      float cleanse = 0.0;
      float ringEdge = 0.0;
      for (int i = 0; i < ${MAX_CLEANSE_ZONES}; i++) {
        vec4 cz = uCleanseZones[i];
        if (cz.z > 0.1) {
          float d = distance(vWorldPos.xz, cz.xy);
          if (d < cz.z + 2.5) {
            float factor = 1.0 - smoothstep(cz.z - 8.0, cz.z + 2.0, d);
            cleanse = max(cleanse, factor);
            float edge = smoothstep(cz.z - 2.2, cz.z - 0.4, d) * (1.0 - smoothstep(cz.z - 0.4, cz.z + 1.4, d));
            ringEdge = max(ringEdge, edge);
          }
        }
      }

      // PHOTOREALISTIC GOLF GAME IMAGE-BASED TERRAIN BLENDING (Like PGA Tour / EA Sports Golf)
      // Sample high-resolution photo-sampled textures across micro and macro UV scales
      vec2 turfUv = vWorldPos.xz * 0.085;
      vec3 turfSample = texture2D(uTurfTex, turfUv).rgb;
      vec3 sandSample = texture2D(uSandTex, vWorldPos.xz * 0.065).rgb;
      vec3 pavedSample = texture2D(uPavedTex, vWorldPos.xz * 0.12).rgb;

      // Realistic fairways, greens, roughs & sandy bunkers
      vec3 blightSoil = mix(vec3(0.18, 0.22, 0.20), vec3(0.26, 0.30, 0.25), macro);
      vec3 lushTurf = turfSample * uGroundTint * 1.35;
      float kurinji = smoothstep(0.68, 0.85, hC);
      lushTurf = mix(lushTurf, turfSample * vec3(1.15, 0.95, 0.35), kurinji * 0.45);

      // Sand traps & fairway bunkers nestled along gentle rolls (golf game style)
      float sandTrap = smoothstep(0.72, 0.88, noise(vWorldPos.xz * 0.042));
      if (slope < 0.08 && vWorldPos.y < 12.0 && vWorldPos.y > 1.2) {
        lushTurf = mix(lushTurf, sandSample * 1.05, sandTrap * 0.75);
      }

      // Cobblestone & Paved Roadways, Avenues & Pathways
      vec3 col = mix(blightSoil, lushTurf, cleanse);
      vec3 roadCol = pavedSample;
      if (vWorldPos.y < 16.0) {
        // Grand North-South Highway & City Street
        float nsRoad = (vWorldPos.z > -280.0 && vWorldPos.z < 320.0) ? (1.0 - smoothstep(4.8, 8.2, abs(vWorldPos.x))) : 0.0;
        // East-West Boulevard & Harbor Approach Avenue
        float ewRoad = 1.0 - smoothstep(4.5, 7.8, abs(vWorldPos.z));
        float townRoad = max(ewRoad, nsRoad);
        col = mix(col, roadCol, townRoad * 0.95);
      }

      // Realistic Stratified Basalt / Granite Escarpments, Couloirs & Alpine Rock Faces (No Smooth Green Hills!)
      if (slope > 0.14 || vWorldPos.y > 16.0) {
        float rk = clamp((slope - 0.12) * 2.8 + max(0.0, (vWorldPos.y - 16.0) / 38.0), 0.0, 1.0);
        float strata = noise(vec2(vWorldPos.x * 0.08 + vWorldPos.z * 0.08, vWorldPos.y * 0.35));
        vec3 darkBasalt = vec3(0.19, 0.20, 0.22);
        vec3 lightGranite = vec3(0.46, 0.44, 0.42);
        vec3 cliff = mix(darkBasalt, lightGranite, strata * 0.68 + hC * 0.32);
        // Highlight flatter terraced switchback roadways cut into the mountain slopes with paved roadway texture!
        float mountainTerraceRoad = (vWorldPos.y > 14.0 && slope < 0.36) ? (1.0 - smoothstep(0.18, 0.36, slope)) : 0.0;
        cliff = mix(cliff, roadCol * 1.15, mountainTerraceRoad * 0.88);
        col = mix(col, cliff, rk * 0.92);
      }

      // High-Altitude Glacial Snowfields, Seracs & Ridge Cornices
      if (vWorldPos.y > 420.0) {
        float snowMask = clamp((vWorldPos.y - 420.0) / 380.0 - slope * 0.42 + hC * 0.25, 0.0, 1.0);
        vec3 glacialIce = vec3(0.76, 0.88, 0.98);
        vec3 freshSnow = vec3(0.98, 0.99, 1.0);
        vec3 snowCol = mix(glacialIce, freshSnow, hC);
        col = mix(col, snowCol, snowMask);
      }

      col += vec3(1.35, 1.05, 0.35) * ringEdge;

      vec3 viewDir = normalize(cameraPosition - vWorldPos);
      vec3 halfVec = normalize(uSunDir + viewDir);
      float NdotL = max(dot(vNormal, uSunDir), 0.0);
      float spec = pow(max(dot(vNormal, halfVec), 0.0), 28.0) * 0.18;

      vec3 ambient = mix(vec3(0.24, 0.28, 0.38), vec3(0.44, 0.54, 0.66), vNormal.y * 0.5 + 0.5);
      vec3 lit = col * (ambient + vec3(1.05, 0.96, 0.82) * NdotL * 0.82) + vec3(1.0, 0.92, 0.75) * spec;

      float camDist = length(cameraPosition - vWorldPos);
      float fogF = 1.0 - exp(-camDist * 0.00028);
      gl_FragColor = vec4(mix(lit, uFogColor, clamp(fogF, 0.0, 0.78)), 1.0);
    }
  `,
});

const terrainMesh = new THREE.Mesh(terrainGeo, terrainShaderMat);
terrainMesh.receiveShadow = true;
scene.add(terrainMesh);

// Specular Ocean
const oceanGeo = new THREE.PlaneGeometry(WORLD_SIZE * 1.4, WORLD_SIZE * 1.4, 110, 110);
oceanGeo.rotateX(-Math.PI / 2);
const oceanMat = new THREE.ShaderMaterial({
  transparent: true,
  uniforms: {
    uTime: { value: 0 },
    uSunDir: { value: new THREE.Vector3(0.54, 0.38, -0.75).normalize() },
  },
  vertexShader: `
    uniform float uTime;
    varying vec3 vWorldPos;
    void main() {
      vec3 p = position;
      p.y += sin(p.x * 0.07 + uTime * 2.1) * 0.32 + cos(p.z * 0.07 + uTime * 1.7) * 0.32;
      vec4 wp = modelMatrix * vec4(p, 1.0);
      vWorldPos = wp.xyz;
      gl_Position = projectionMatrix * viewMatrix * wp;
    }
  `,
  fragmentShader: `
    uniform float uTime;
    uniform vec3 uSunDir;
    varying vec3 vWorldPos;
    void main() {
      float w1 = sin(vWorldPos.x * 0.18 + uTime * 2.4) * cos(vWorldPos.z * 0.16 - uTime * 1.9);
      float w2 = sin(vWorldPos.x * 0.42 - uTime * 1.5) * cos(vWorldPos.z * 0.38 + uTime * 2.2);
      vec3 n = normalize(vec3(w1 * 0.15, 1.0, w2 * 0.15));
      vec3 viewDir = normalize(cameraPosition - vWorldPos);
      float fresnel = pow(1.0 - max(dot(viewDir, n), 0.0), 3.0);

      vec3 deep = vec3(0.04, 0.22, 0.40);
      vec3 shallow = vec3(0.12, 0.50, 0.72);
      vec3 col = mix(deep, shallow, w1 * 0.5 + 0.5);
      col = mix(col, vec3(0.55, 0.78, 0.95), fresnel * 0.55);

      vec3 halfV = normalize(uSunDir + viewDir);
      float glint = pow(max(dot(n, halfV), 0.0), 64.0);
      col += vec3(1.3, 1.15, 0.85) * glint * 0.75;

      gl_FragColor = vec4(col, 0.88);
    }
  `,
});
const oceanMesh = new THREE.Mesh(oceanGeo, oceanMat);
oceanMesh.position.y = -1.6;
scene.add(oceanMesh);

// ============================================================================
// 6. ORGANIC TREES, TRAIL CAIRNS & SUMMIT TREASURE CHESTS
// ============================================================================
function createFoliageTexture(baseR, baseG, baseB) {
  const c = document.createElement('canvas');
  c.width = 64;
  c.height = 64;
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(64, 64);
  for (let i = 0; i < 64 * 64; i++) {
    const x = i % 64;
    const y = Math.floor(i / 64);
    const n = valueNoise(x * 0.16, y * 0.16);
    const grain = (hash2D(x, y) - 0.5) * 28;
    img.data[i * 4] = Math.min(255, Math.max(0, baseR + (n - 0.5) * 55 + grain));
    img.data[i * 4 + 1] = Math.min(255, Math.max(0, baseG + (n - 0.5) * 65 + grain));
    img.data[i * 4 + 2] = Math.min(255, Math.max(0, baseB + (n - 0.5) * 40 + grain));
    img.data[i * 4 + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

const barkTex = createFoliageTexture(82, 58, 42);
const witheredTex = createFoliageTexture(78, 56, 88);
const lushLeafTex = createFoliageTexture(44, 132, 58);
const goldenLeafTex = createFoliageTexture(218, 165, 32);
const snowLeafTex = createFoliageTexture(210, 225, 240);
const stoneTex = createFoliageTexture(124, 128, 136);

const barkMat = new THREE.MeshStandardMaterial({ map: barkTex, bumpMap: barkTex, bumpScale: 0.08, roughness: 0.9 });
const witheredCrownMat = new THREE.MeshStandardMaterial({ map: witheredTex, bumpMap: witheredTex, bumpScale: 0.06, roughness: 0.85 });
const lushCrownMat = new THREE.MeshStandardMaterial({ map: lushLeafTex, bumpMap: lushLeafTex, bumpScale: 0.08, roughness: 0.72 });
const goldenCrownMat = new THREE.MeshStandardMaterial({ map: goldenLeafTex, bumpMap: goldenLeafTex, bumpScale: 0.08, roughness: 0.65 });
const snowCrownMat = new THREE.MeshStandardMaterial({ map: snowLeafTex, bumpMap: snowLeafTex, bumpScale: 0.08, roughness: 0.65 });
const stoneMat = new THREE.MeshStandardMaterial({ map: stoneTex, bumpMap: stoneTex, bumpScale: 0.06, roughness: 0.75 });

// ============================================================================
// 6-INSTANCED. HIGH-DENSITY BIOME ECOSYSTEM (TREES, BUSHES, FLORA, ROCK BOULDERS & STREETLAMPS)
// ============================================================================
function spawnHighDensityBiomeObjects() {
  const dummy = new THREE.Object3D();

  // 1. Instanced Pine & Deciduous Trees (3,500 trees across the 7 Continents)
  const treeCount = 3500;
  const instTrunkGeo = new THREE.CylinderGeometry(0.24, 0.48, 4.2, 6);
  instTrunkGeo.translate(0, 2.1, 0);
  const instCanopyGeo = new THREE.ConeGeometry(2.4, 5.2, 6);
  instCanopyGeo.translate(0, 5.8, 0);
  const instTrunkMesh = new THREE.InstancedMesh(instTrunkGeo, barkMat, treeCount);
  const instCanopyMesh = new THREE.InstancedMesh(instCanopyGeo, lushCrownMat, treeCount);

  let tIdx = 0;
  CONTINENTS.forEach((cont) => {
    const treesPerCont = Math.floor(treeCount / CONTINENTS.length);
    for (let i = 0; i < treesPerCont; i++) {
      const angle = hash2D(i, cont.id * 17) * Math.PI * 2.0;
      const dist = 32.0 + Math.pow(hash2D(i * 3, cont.id * 23), 0.7) * 2100.0;
      const x = cont.x + Math.cos(angle) * dist;
      const z = cont.z + Math.sin(angle) * dist;
      if (getRoadwayMask(cont, x, z) > 0.08) continue;
      const y = getTerrainHeight(x, z);
      if (y < 0.2 || y > 180.0) continue;

      const scale = 0.75 + hash2D(i * 7, cont.id) * 0.7;
      dummy.position.set(x, y, z);
      dummy.rotation.set(0, hash2D(i, cont.id) * Math.PI * 2, 0);
      dummy.scale.set(scale, scale, scale);
      dummy.updateMatrix();

      instTrunkMesh.setMatrixAt(tIdx, dummy.matrix);
      instCanopyMesh.setMatrixAt(tIdx, dummy.matrix);
      tIdx++;
    }
  });
  instTrunkMesh.count = tIdx;
  instCanopyMesh.count = tIdx;
  instTrunkMesh.instanceMatrix.needsUpdate = true;
  instCanopyMesh.instanceMatrix.needsUpdate = true;
  scene.add(instTrunkMesh, instCanopyMesh);

  // 2. Instanced Wildflower & Grass Clumps (14,000 flora tufts)
  const grassCount = 14000;
  const grassBladeGeo = new THREE.ConeGeometry(0.35, 1.25, 4);
  grassBladeGeo.translate(0, 0.6, 0);
  const instGrassMat = new THREE.MeshStandardMaterial({
    color: 0x4ade80,
    roughness: 0.8,
    side: THREE.DoubleSide,
  });
  const instGrassMesh = new THREE.InstancedMesh(grassBladeGeo, instGrassMat, grassCount);

  let gIdx = 0;
  CONTINENTS.forEach((cont) => {
    const gPerCont = Math.floor(grassCount / CONTINENTS.length);
    for (let i = 0; i < gPerCont; i++) {
      const angle = hash2D(i * 5, cont.id * 31) * Math.PI * 2.0;
      const dist = 14.0 + Math.pow(hash2D(i * 11, cont.id * 41), 0.6) * 1900.0;
      const x = cont.x + Math.cos(angle) * dist;
      const z = cont.z + Math.sin(angle) * dist;
      const y = getTerrainHeight(x, z);
      if (y < 0.2 || y > 350.0) continue;

      const scale = 0.5 + hash2D(i, 83) * 0.8;
      dummy.position.set(x, y, z);
      dummy.rotation.set(0, hash2D(i, 97) * Math.PI * 2, 0);
      dummy.scale.set(scale, scale * (0.8 + hash2D(i, 47) * 0.6), scale);
      dummy.updateMatrix();

      instGrassMesh.setMatrixAt(gIdx, dummy.matrix);
      gIdx++;
    }
  });
  instGrassMesh.count = gIdx;
  instGrassMesh.instanceMatrix.needsUpdate = true;
  scene.add(instGrassMesh);

  // 3. Instanced Granite Boulders & Mountain Crags (2,800 rocky outcrops)
  const rockCount = 2800;
  const rockGeo = new THREE.DodecahedronGeometry(1.6, 1);
  const instRockMesh = new THREE.InstancedMesh(rockGeo, stoneMat, rockCount);

  let rIdx = 0;
  CONTINENTS.forEach((cont) => {
    const rPerCont = Math.floor(rockCount / CONTINENTS.length);
    for (let i = 0; i < rPerCont; i++) {
      const angle = hash2D(i * 7, cont.id * 59) * Math.PI * 2.0;
      const dist = 45.0 + Math.pow(hash2D(i * 13, cont.id * 67), 0.8) * 2300.0;
      const x = cont.x + Math.cos(angle) * dist;
      const z = cont.z + Math.sin(angle) * dist;
      const y = getTerrainHeight(x, z);
      if (y < 0.2) continue;

      const scale = 0.8 + hash2D(i, 113) * 1.8;
      dummy.position.set(x, y + scale * 0.4, z);
      dummy.rotation.set(hash2D(i, 131) * Math.PI, hash2D(i, 149) * Math.PI, 0);
      dummy.scale.set(scale, scale * 0.75, scale * 1.2);
      dummy.updateMatrix();

      instRockMesh.setMatrixAt(rIdx, dummy.matrix);
      rIdx++;
    }
  });
  instRockMesh.count = rIdx;
  instRockMesh.instanceMatrix.needsUpdate = true;
  scene.add(instRockMesh);

  // 4. Instanced Streetlamps lining City Avenues & Mountain Ghat Roadways (1,200 Lanterns)
  const lampCount = 1200;
  const lampGeo = new THREE.CylinderGeometry(0.12, 0.16, 3.6, 6);
  lampGeo.translate(0, 1.8, 0);
  const instLampMesh = new THREE.InstancedMesh(lampGeo, stoneMat, lampCount);

  let lIdx = 0;
  CONTINENTS.forEach((cont) => {
    // 60 Lamps along the North-South Highway & City Streets
    for (let sz = -220.0; sz <= 240.0; sz += 18.0) {
      [-8.5, 8.5].forEach((sx) => {
        if (lIdx >= lampCount) return;
        const x = cont.x + sx;
        const z = cont.z + sz;
        const y = getTerrainHeight(x, z);
        dummy.position.set(x, y, z);
        dummy.rotation.set(0, 0, 0);
        dummy.scale.set(1, 1, 1);
        dummy.updateMatrix();
        instLampMesh.setMatrixAt(lIdx, dummy.matrix);
        lIdx++;
      });
    }
    // 80 Lamps along the 3.5-Turn Spiral Mountain Roadway to the Summit
    for (let s = 0.05; s <= 0.98; s += 0.015) {
      if (lIdx >= lampCount) return;
      const { rx, rz } = getSpiralRoadPoint(cont, s);
      const y = getTerrainHeight(rx, rz);
      dummy.position.set(rx + 4.2, y, rz);
      dummy.rotation.set(0, 0, 0);
      dummy.scale.set(1, 1, 1);
      dummy.updateMatrix();
      instLampMesh.setMatrixAt(lIdx, dummy.matrix);
      lIdx++;
    }
  });
  instLampMesh.count = lIdx;
  instLampMesh.instanceMatrix.needsUpdate = true;
  scene.add(instLampMesh);
}

// Spawn all high-density instanced biome objects
spawnHighDensityBiomeObjects();
function createSculptedCanopyGeometry(radius) {
  const geo = new THREE.IcosahedronGeometry(radius, 2);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const vx = p.getX(i);
    const vy = p.getY(i);
    const vz = p.getZ(i);
    const n = 0.78 + 0.38 * valueNoise(vx * 0.7 + 5.1, vz * 0.7 + vy * 0.5);
    p.setXYZ(i, vx * n, vy * (0.72 + 0.28 * n), vz * n);
  }
  geo.computeVertexNormals();
  return geo;
}

const canopyGeoMain = createSculptedCanopyGeometry(3.1);
const canopyGeoSub = createSculptedCanopyGeometry(2.1);

const interactables = [];
const continentTrees = [];

function spawnOrganicTree(x, z, continentId, startLush = false) {
  const y = getTerrainHeight(x, z);
  if (y < 0.25 || y > 30.0) return;
  const group = new THREE.Group();
  group.position.set(x, y, z);

  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.56, 4.4, 10), barkMat);
  trunk.position.y = 2.2;
  trunk.castShadow = true;
  group.add(trunk);

  const isSnowRegion = continentId === 3 || continentId === 5;
  const isAutumnRegion = continentId === 2 || continentId === 6;
  const targetLushMat = isSnowRegion ? snowCrownMat : isAutumnRegion ? goldenCrownMat : lushCrownMat;
  const initMat = startLush ? targetLushMat : witheredCrownMat;

  const crownGroup = new THREE.Group();
  crownGroup.position.y = 4.8;
  crownGroup.scale.setScalar(startLush ? 1.1 : 0.62);

  const c1 = new THREE.Mesh(canopyGeoMain, initMat);
  c1.castShadow = true;
  const c2 = new THREE.Mesh(canopyGeoSub, initMat);
  c2.position.set(1.5, -0.5, 0.7);
  c2.castShadow = true;
  const c3 = new THREE.Mesh(canopyGeoSub, initMat);
  c3.position.set(-1.4, -0.6, -0.6);
  c3.castShadow = true;

  crownGroup.add(c1, c2, c3);
  group.add(crownGroup);
  scene.add(group);

  continentTrees.push({ group, crownGroup, meshes: [c1, c2, c3], targetLushMat, x, z, continentId, rejuvenated: startLush });
}

function createTreasureChestMesh() {
  const chestGroup = new THREE.Group();
  const woodMat = new THREE.MeshStandardMaterial({ color: 0x78350f, roughness: 0.6, metalness: 0.2 });
  const goldTrimMat = new THREE.MeshStandardMaterial({
    color: 0xfde047,
    emissive: 0xd97706,
    emissiveIntensity: 1.4,
    metalness: 0.85,
    roughness: 0.2,
  });

  const base = new THREE.Mesh(new THREE.BoxGeometry(1.8, 1.0, 1.2), woodMat);
  base.position.y = 0.5;
  base.castShadow = true;
  chestGroup.add(base);

  const lid = new THREE.Mesh(new THREE.CylinderGeometry(0.6, 0.6, 1.8, 12, 1, false, 0, Math.PI), goldTrimMat);
  lid.rotation.z = Math.PI / 2;
  lid.position.y = 1.0;
  chestGroup.add(lid);

  const lockGem = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.28, 0),
    new THREE.MeshStandardMaterial({ color: 0x38bdf8, emissive: 0x0284c7, emissiveIntensity: 2.5 })
  );
  lockGem.position.set(0, 0.95, 0.68);
  chestGroup.add(lockGem);

  chestGroup._lid = lid;
  return chestGroup;
}

const postMatShared = new THREE.MeshStandardMaterial({ color: 0x5c3a21, roughness: 0.85 });
const goldMatShared = new THREE.MeshStandardMaterial({ color: 0xfde047, emissive: 0xd97706, emissiveIntensity: 1.5 });
const pillarGeoShared = new THREE.CylinderGeometry(0.14, 0.16, 3.2, 6);
const counterGeoShared = new THREE.BoxGeometry(3.4, 1.0, 1.1);
const roofGeoShared = new THREE.ConeGeometry(2.85, 1.5, 4);
const lanternGeoShared = new THREE.SphereGeometry(0.22, 8, 8);
const awningMatCache = {};

function createShopPavilionMesh(awningHex = 0xd97706) {
  const stall = new THREE.Group();
  if (!awningMatCache[awningHex]) {
    awningMatCache[awningHex] = new THREE.MeshStandardMaterial({ color: awningHex, roughness: 0.55, side: THREE.DoubleSide });
  }
  const awningMat = awningMatCache[awningHex];

  // 4 Wooden Pillars
  [[-1.8, -1.3], [1.8, -1.3], [-1.8, 1.3], [1.8, 1.3]].forEach(([px, pz]) => {
    const p = new THREE.Mesh(pillarGeoShared, postMatShared);
    p.position.set(px, 1.6, pz);
    stall.add(p);
  });

  // Merchant Counter Table
  const counter = new THREE.Mesh(counterGeoShared, postMatShared);
  counter.position.set(0, 0.5, 0.7);
  stall.add(counter);

  // Peaked Bazaar Canopy Roof
  const roof = new THREE.Mesh(roofGeoShared, awningMat);
  roof.position.y = 3.85;
  roof.rotation.y = Math.PI / 4;
  stall.add(roof);

  // Hanging Golden Street Lanterns
  [[-1.7, 1.3], [1.7, 1.3]].forEach(([lx, lz]) => {
    const lantern = new THREE.Mesh(lanternGeoShared, goldMatShared);
    lantern.position.set(lx, 2.95, lz);
    stall.add(lantern);
  });

  return stall;
}

function createNameplateDOM(entity) {
  const el = document.createElement('div');
  el.className = 'nameplate';
  const isFriendlyNPC = entity.kind === 'shop_npc' || entity.kind === 'town_npc';
  const qBadge = entity.questMarker
    ? `<span class="np-quest-marker" style="color:${entity.questMarker === '❓' ? '#38bdf8' : '#fde047'};font-size:15px;font-weight:900;text-shadow:0 0 8px #f59e0b;margin-right:3px;">${entity.questMarker}</span>`
    : '';
  el.innerHTML = `
    <div class="np-title">
      ${qBadge}<span class="np-lvl" style="color:${isFriendlyNPC ? '#fde047' : '#38bdf8'}">[${entity.badge}]</span>
      <span class="np-name" style="color:${isFriendlyNPC ? '#4ade80' : '#f8fafc'}">${entity.name}</span>
    </div>
    <div class="np-bar-bg">
      <div class="np-bar-fill ${isFriendlyNPC ? 'rejuvenated' : ''}" style="width: ${(entity.hp / entity.maxHp) * 100}%"></div>
    </div>
  `;
  el.addEventListener('pointerdown', (e) => {
    e.stopPropagation();
    SFX.playTargetClick();
    selectTarget(entity);
    if (entity.kind === 'shop_npc') {
      openNPCInteraction(entity);
    } else if (entity.kind === 'town_npc') {
      openNPCInteraction(entity);
    } else if (e.button === 2 || entity.kind === 'chest') {
      openWoWLootWindow(entity);
    }
  });
  nameplatesContainer.appendChild(el);
  entity.nameplateEl = el;
  entity.npFillEl = el.querySelector('.np-bar-fill');
  entity.npQuestEl = el.querySelector('.np-quest-marker');
}

// ============================================================================
// 6A. PROPER METROPOLIS CITY INFRASTRUCTURE, MARITIME SHIPPING, HARBORS, CANALS,
//     BRIDGES, AQUEDUCTS, WINDMILLS, LIGHTHOUSES, GALLEONS & BOATING!
// ============================================================================
const sharedShopRingGeo = new THREE.RingGeometry(1.4, 1.75, 20).rotateX(-Math.PI / 2);
const sharedShopRingMat = new THREE.MeshBasicMaterial({ color: 0xfde047, side: THREE.DoubleSide, transparent: true, opacity: 0.72 });
const sharedNpcRingGeo = new THREE.RingGeometry(1.0, 1.25, 18).rotateX(-Math.PI / 2);
const sharedNpcRingMat = new THREE.MeshBasicMaterial({ color: 0x4ade80, side: THREE.DoubleSide, transparent: true, opacity: 0.65 });
const sharedRobeGeo = new THREE.CylinderGeometry(0.22, 0.34, 0.88, 8);
const sharedHeadGeo = new THREE.SphereGeometry(0.24, 8, 8);
const sharedHatGeo = new THREE.ConeGeometry(0.32, 0.34, 6);
const sharedLimbGeo = new THREE.CylinderGeometry(0.08, 0.07, 0.56, 6);
const sharedBackpackGeo = new THREE.BoxGeometry(0.36, 0.44, 0.22);
const sharedEarGeo = new THREE.ConeGeometry(0.11, 0.28, 4);
const sharedTailGeo = new THREE.ConeGeometry(0.14, 0.58, 6);
sharedTailGeo.rotateX(Math.PI * 0.35);
const sharedQuestExclamGeo = new THREE.OctahedronGeometry(0.26, 0);
const sharedQuestGlowMat = new THREE.MeshStandardMaterial({ color: 0xfde047, emissive: 0xf59e0b, emissiveIntensity: 3.0 });
const sharedSkinMat = new THREE.MeshStandardMaterial({ color: 0xfbd38d, roughness: 0.6 });
const sharedDarkHairMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.8 });

const kWallMat = new THREE.MeshStandardMaterial({ color: 0xf1f5f9, roughness: 0.72 });
const kStoneTrimMat = new THREE.MeshStandardMaterial({ color: 0x64748b, roughness: 0.8 });
const kWindowGlowMat = new THREE.MeshStandardMaterial({ color: 0xfef08a, emissive: 0xf59e0b, emissiveIntensity: 2.4 });
const kFireGlowMat = new THREE.MeshStandardMaterial({ color: 0xfde047, emissive: 0xf97316, emissiveIntensity: 3.2 });
const kSailMat = new THREE.MeshStandardMaterial({ color: 0xfef9c3, emissive: 0xfde047, emissiveIntensity: 0.25, side: THREE.DoubleSide });
const kCrimsonSailMat = new THREE.MeshStandardMaterial({ color: 0xe11d48, emissive: 0x9f1239, emissiveIntensity: 0.25, side: THREE.DoubleSide });
const kRoofMats = [
  new THREE.MeshStandardMaterial({ color: 0xb45309, roughness: 0.6 }),
  new THREE.MeshStandardMaterial({ color: 0x0369a1, roughness: 0.6 }),
  new THREE.MeshStandardMaterial({ color: 0xbe123c, roughness: 0.6 }),
  new THREE.MeshStandardMaterial({ color: 0x15803d, roughness: 0.6 }),
  new THREE.MeshStandardMaterial({ color: 0x6d28d9, roughness: 0.6 }),
];

const animatedShips = [];
const animatedWindmills = [];
const animatedTransitVehicles = [];

// Shared Geometries for Proper City Buildings, Townhouses, Warehouses, Bridges, Aqueducts, Ships & Boats
const houseBodyGeo = new THREE.BoxGeometry(5.6, 3.4, 4.8);
const houseUpperGeo = new THREE.BoxGeometry(6.1, 3.2, 5.2);
const houseRoofGeo = new THREE.ConeGeometry(4.6, 2.5, 4);
const houseDoorGeo = new THREE.BoxGeometry(1.1, 2.0, 0.25);
const houseWinGeo = new THREE.BoxGeometry(0.95, 0.95, 0.22);
const houseChimneyGeo = new THREE.BoxGeometry(0.75, 2.6, 0.75);
const timberBeamGeo = new THREE.BoxGeometry(6.2, 0.28, 5.3);

function createVillageHouseMesh(roofVariant = 0, isTwoStory = false) {
  const h = new THREE.Group();
  const rMat = kRoofMats[roofVariant % kRoofMats.length];

  const walls = new THREE.Mesh(houseBodyGeo, kWallMat);
  walls.position.y = 1.7;
  walls.castShadow = true;
  walls.receiveShadow = true;
  h.add(walls);

  let roofY = 4.55;
  if (isTwoStory) {
    // 2-Story Stormwind-Style Overhanging Timber-Framed City Townhouse!
    const beam = new THREE.Mesh(timberBeamGeo, postMatShared);
    beam.position.y = 3.45;
    h.add(beam);

    const upper = new THREE.Mesh(houseUpperGeo, kWallMat);
    upper.position.y = 5.1;
    upper.castShadow = true;
    h.add(upper);

    const uw1 = new THREE.Mesh(houseWinGeo, kWindowGlowMat);
    uw1.position.set(-1.6, 5.2, 2.62);
    const uw2 = new THREE.Mesh(houseWinGeo, kWindowGlowMat);
    uw2.position.set(1.6, 5.2, 2.62);
    h.add(uw1, uw2);
    roofY = 7.85;
  }

  const roof = new THREE.Mesh(houseRoofGeo, rMat);
  roof.position.y = roofY;
  roof.rotation.y = Math.PI / 4;
  if (isTwoStory) roof.scale.set(1.08, 1.15, 1.08);
  roof.castShadow = true;
  h.add(roof);

  const door = new THREE.Mesh(houseDoorGeo, postMatShared);
  door.position.set(0, 1.0, 2.42);
  h.add(door);

  const w1 = new THREE.Mesh(houseWinGeo, kWindowGlowMat);
  w1.position.set(-1.55, 1.85, 2.42);
  const w2 = new THREE.Mesh(houseWinGeo, kWindowGlowMat);
  w2.position.set(1.55, 1.85, 2.42);
  h.add(w1, w2);

  const chimney = new THREE.Mesh(houseChimneyGeo, kStoneTrimMat);
  chimney.position.set(1.6, roofY + 0.1, -1.1);
  h.add(chimney);

  return h;
}

// 1. Arched Stone Canal Bridge + Ornamental Streetlamps spanning the Grand City Canal
const bridgeDeckGeo = new THREE.BoxGeometry(11.0, 0.7, 13.5);
const bridgeParapetGeo = new THREE.BoxGeometry(0.65, 1.35, 13.5);
const lampPostPoleGeo = new THREE.CylinderGeometry(0.1, 0.14, 3.8, 6);

function createCanalBridgeMesh() {
  const b = new THREE.Group();
  const deck = new THREE.Mesh(bridgeDeckGeo, stoneMat);
  deck.position.y = 0.25;
  deck.receiveShadow = true;
  b.add(deck);

  [-5.1, 5.1].forEach((px) => {
    const rail = new THREE.Mesh(bridgeParapetGeo, kStoneTrimMat);
    rail.position.set(px, 0.95, 0);
    b.add(rail);

    [-5.8, 5.8].forEach((pz) => {
      const pole = new THREE.Mesh(lampPostPoleGeo, kStoneTrimMat);
      pole.position.set(px, 2.6, pz);
      const lantern = new THREE.Mesh(lanternGeoShared, kWindowGlowMat);
      lantern.scale.setScalar(1.4);
      lantern.position.set(px, 4.6, pz);
      b.add(pole, lantern);
    });
  });
  return b;
}

// 2. Monumental Imperial Stone Aqueduct Viaduct carrying mountain water into the City
const aqPillarGeo = new THREE.BoxGeometry(2.4, 15.0, 2.4);
const aqChannelGeo = new THREE.BoxGeometry(82.0, 2.4, 3.4);
const aqWaterGeo = new THREE.BoxGeometry(81.5, 0.5, 2.2);
const aqWaterMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, emissive: 0x0284c7, emissiveIntensity: 1.2 });

function createImperialAqueductMesh() {
  const aq = new THREE.Group();
  for (let i = -3; i <= 3; i++) {
    const p = new THREE.Mesh(aqPillarGeo, stoneMat);
    p.position.set(i * 12.5, 7.5, 0);
    p.castShadow = true;
    aq.add(p);
  }
  const topChannel = new THREE.Mesh(aqChannelGeo, kStoneTrimMat);
  topChannel.position.y = 15.8;
  aq.add(topChannel);

  const waterStream = new THREE.Mesh(aqWaterGeo, aqWaterMat);
  waterStream.position.y = 17.05;
  aq.add(waterStream);
  return aq;
}

// 3. Rotating Agricultural Windmill & Grain Silo in the City Outskirts
const wmTowerGeo = new THREE.CylinderGeometry(1.9, 3.1, 10.5, 8);
const wmCapGeo = new THREE.ConeGeometry(2.4, 2.5, 8);
const wmBladeGeo = new THREE.BoxGeometry(0.85, 9.2, 0.12);

function createCityWindmillMesh(variant = 0) {
  const wm = new THREE.Group();
  const tower = new THREE.Mesh(wmTowerGeo, kWallMat);
  tower.position.y = 5.25;
  tower.castShadow = true;
  wm.add(tower);

  const cap = new THREE.Mesh(wmCapGeo, kRoofMats[variant % kRoofMats.length]);
  cap.position.y = 11.5;
  wm.add(cap);

  const rotor = new THREE.Group();
  rotor.position.set(0, 8.8, 2.25);
  const b1 = new THREE.Mesh(wmBladeGeo, kSailMat);
  const b2 = new THREE.Mesh(wmBladeGeo, kSailMat);
  b2.rotation.z = Math.PI / 2;
  rotor.add(b1, b2);
  wm.add(rotor);
  wm._rotor = rotor;
  animatedWindmills.push(rotor);
  return wm;
}

// 4. Coastal Harbor Lighthouse, Wooden Shipping Piers, Harbor Cargo Cranes & Crates
const lhTowerGeo = new THREE.CylinderGeometry(1.8, 3.2, 18.5, 10);
const lhBeaconGeo = new THREE.CylinderGeometry(1.6, 1.6, 2.6, 10);
const lhRoofGeo = new THREE.ConeGeometry(2.3, 2.8, 10);
const pierDeckGeo = new THREE.BoxGeometry(7.5, 0.55, 28.0);
const pierPileGeo = new THREE.CylinderGeometry(0.28, 0.28, 5.5, 6);
const crateGeo = new THREE.BoxGeometry(1.4, 1.4, 1.4);
const barrelGeo = new THREE.CylinderGeometry(0.55, 0.55, 1.35, 8);

function createHarborLighthouseMesh() {
  const lh = new THREE.Group();
  const tower = new THREE.Mesh(lhTowerGeo, kWallMat);
  tower.position.y = 9.25;
  tower.castShadow = true;
  lh.add(tower);

  const beacon = new THREE.Mesh(lhBeaconGeo, kWindowGlowMat);
  beacon.position.y = 19.6;
  lh.add(beacon);

  const roof = new THREE.Mesh(lhRoofGeo, kRoofMats[2]);
  roof.position.y = 22.1;
  lh.add(roof);
  return lh;
}

function createHarborShippingPierMesh() {
  const pier = new THREE.Group();
  const deck = new THREE.Mesh(pierDeckGeo, postMatShared);
  deck.position.set(0, 1.2, 14.0);
  deck.receiveShadow = true;
  pier.add(deck);

  for (let pz = 2; pz <= 26; pz += 6) {
    [-3.1, 3.1].forEach((px) => {
      const pile = new THREE.Mesh(pierPileGeo, postMatShared);
      pile.position.set(px, -0.8, pz);
      pier.add(pile);
    });
  }

  // Harbor Cargo Crane + Stacked Shipping Crates & Barrels on the Pier!
  const craneMast = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.35, 7.5, 6), postMatShared);
  craneMast.position.set(-2.4, 4.8, 22.0);
  const craneBoom = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.24, 6.2, 6), postMatShared);
  craneBoom.position.set(-0.6, 7.8, 23.5);
  craneBoom.rotation.z = -Math.PI / 3.2;
  pier.add(craneMast, craneBoom);

  [[-1.8, 6.0], [-0.2, 6.4], [-1.0, 7.4]].forEach(([cx, cz], idx) => {
    const crate = new THREE.Mesh(crateGeo, postMatShared);
    crate.position.set(cx, 2.1 + (idx === 2 ? 1.4 : 0), cz);
    pier.add(crate);
  });
  [[2.0, 9.0], [2.2, 10.4]].forEach(([bx, bz]) => {
    const barrel = new THREE.Mesh(barrelGeo, kRoofMats[0]);
    barrel.position.set(bx, 2.1, bz);
    pier.add(barrel);
  });

  return pier;
}

// 5. Tall-Mast 3D Merchant Galleons & Canal Gondola Skiffs (For Boating & Maritime Shipping!)
const shipHullGeo = new THREE.BoxGeometry(5.6, 3.2, 16.5);
const shipBowGeo = new THREE.ConeGeometry(3.8, 5.5, 4);
shipBowGeo.rotateX(Math.PI / 2);
const shipSternGeo = new THREE.BoxGeometry(5.8, 4.2, 4.6);
const shipMastGeo = new THREE.CylinderGeometry(0.22, 0.32, 14.5, 8);
const shipSailGeo = new THREE.BoxGeometry(8.2, 5.6, 0.18);
const skiffHullGeo = new THREE.BoxGeometry(2.1, 0.75, 5.4);

function createMerchantGalleonMesh(isCrimson = false) {
  const ship = new THREE.Group();
  const hull = new THREE.Mesh(shipHullGeo, postMatShared);
  hull.position.y = 1.4;
  hull.castShadow = true;
  ship.add(hull);

  const bow = new THREE.Mesh(shipBowGeo, postMatShared);
  bow.position.set(0, 1.8, 10.6);
  bow.rotation.z = Math.PI / 4;
  ship.add(bow);

  const stern = new THREE.Mesh(shipSternGeo, postMatShared);
  stern.position.set(0, 2.8, -6.5);
  ship.add(stern);

  // Glowing Captain's Cabin Windows on the Stern
  [-1.4, 0, 1.4].forEach((wx) => {
    const win = new THREE.Mesh(houseWinGeo, kWindowGlowMat);
    win.position.set(wx, 3.4, -8.82);
    ship.add(win);
  });

  // 2 Towering Masts with Billowing Square Sails & Golden Crow's Nest
  const sMat = isCrimson ? kCrimsonSailMat : kSailMat;
  [-2.5, 3.8].forEach((mz, idx) => {
    const mast = new THREE.Mesh(shipMastGeo, postMatShared);
    mast.position.set(0, 8.2, mz);
    ship.add(mast);

    const sail1 = new THREE.Mesh(shipSailGeo, sMat);
    sail1.position.set(0, 7.6, mz + 0.35);
    sail1.scale.setScalar(idx === 0 ? 0.85 : 1.05);
    const sail2 = new THREE.Mesh(shipSailGeo, sMat);
    sail2.position.set(0, 12.6, mz + 0.35);
    sail2.scale.set(0.68, 0.65, 1.0);
    ship.add(sail1, sail2);
  });

  return ship;
}

function createCanalBoatSkiffMesh(variant = 0) {
  const boat = new THREE.Group();
  const hull = new THREE.Mesh(skiffHullGeo, postMatShared);
  hull.position.y = 0.35;
  boat.add(hull);

  const canopy = new THREE.Mesh(new THREE.BoxGeometry(1.9, 0.18, 2.4), kRoofMats[variant % kRoofMats.length]);
  canopy.position.set(0, 1.65, -0.4);
  boat.add(canopy);

  const lantern = new THREE.Mesh(lanternGeoShared, kWindowGlowMat);
  lantern.position.set(0, 1.15, 2.4);
  boat.add(lantern);
  return boat;
}

const towerShaftGeo = new THREE.CylinderGeometry(2.1, 2.6, 11.5, 8);
const towerTopGeo = new THREE.CylinderGeometry(2.8, 2.5, 1.8, 8);
const towerRoofGeo = new THREE.ConeGeometry(3.4, 3.8, 8);

function createKingdomWatchtowerMesh(roofVariant = 0) {
  const t = new THREE.Group();
  const rMat = kRoofMats[roofVariant % kRoofMats.length];
  const shaft = new THREE.Mesh(towerShaftGeo, stoneMat);
  shaft.position.y = 5.75;
  shaft.castShadow = true;
  t.add(shaft);

  const battlement = new THREE.Mesh(towerTopGeo, kWallMat);
  battlement.position.y = 11.8;
  t.add(battlement);

  const spire = new THREE.Mesh(towerRoofGeo, rMat);
  spire.position.y = 14.4;
  t.add(spire);

  const beacon = new THREE.Mesh(lanternGeoShared, kWindowGlowMat);
  beacon.scale.setScalar(2.1);
  beacon.position.set(0, 12.2, 2.6);
  t.add(beacon);
  return t;
}

const citadelBaseGeo = new THREE.BoxGeometry(26.0, 9.0, 20.0);
const citadelTier2Geo = new THREE.BoxGeometry(16.0, 7.5, 13.0);
const citadelDomeGeo = new THREE.SphereGeometry(5.6, 14, 12);
const citadelSpireGeo = new THREE.ConeGeometry(1.4, 6.5, 8);
const gatePillarGeo = new THREE.BoxGeometry(3.2, 10.5, 3.2);
const gateBeamGeo = new THREE.BoxGeometry(16.5, 2.4, 3.6);

function createKingdomCastleMesh(contId = 0) {
  const castle = new THREE.Group();
  const rMat = kRoofMats[contId % kRoofMats.length];

  // Tier 1 Grand Palace Hall
  const base = new THREE.Mesh(citadelBaseGeo, kWallMat);
  base.position.y = 4.5;
  base.castShadow = true;
  base.receiveShadow = true;
  castle.add(base);

  // Tier 2 Royal Upper Keep
  const upper = new THREE.Mesh(citadelTier2Geo, kWallMat);
  upper.position.y = 12.2;
  upper.castShadow = true;
  castle.add(upper);

  // Golden Sovereign Dome & Finial Spire
  const dome = new THREE.Mesh(citadelDomeGeo, goldMatShared);
  dome.position.y = 16.5;
  castle.add(dome);

  const finial = new THREE.Mesh(citadelSpireGeo, goldMatShared);
  finial.position.y = 22.8;
  castle.add(finial);

  // 4 Corner Turret Towers on the Royal Citadel
  [[-12.5, -9.5], [12.5, -9.5], [-12.5, 9.5], [12.5, 9.5]].forEach(([tx, tz]) => {
    const turret = createKingdomWatchtowerMesh(contId);
    turret.position.set(tx, 0, tz);
    castle.add(turret);
  });

  // Grand Golden Archway Windows across the Palace Facade
  for (let wx = -8; wx <= 8; wx += 4) {
    const win = new THREE.Mesh(houseWinGeo, kWindowGlowMat);
    win.scale.set(1.6, 2.4, 1.2);
    win.position.set(wx, 5.2, 10.05);
    castle.add(win);
  }

  // Royal Courtyard Gate Archway in front of the Castle
  const gateL = new THREE.Mesh(gatePillarGeo, stoneMat);
  gateL.position.set(-5.8, 5.25, 15.5);
  const gateR = new THREE.Mesh(gatePillarGeo, stoneMat);
  gateR.position.set(5.8, 5.25, 15.5);
  const gateTop = new THREE.Mesh(gateBeamGeo, rMat);
  gateTop.position.set(0, 10.8, 15.5);
  castle.add(gateL, gateR, gateTop);

  return castle;
}

const campTentGeo = new THREE.ConeGeometry(2.3, 2.7, 4);
const campLogGeo = new THREE.CylinderGeometry(0.24, 0.24, 2.4, 6);
campLogGeo.rotateZ(Math.PI / 2);
const campFireConeGeo = new THREE.ConeGeometry(0.65, 1.45, 7);

function createExpeditionCampgroundMesh(variant = 0) {
  const camp = new THREE.Group();
  const tentMat1 = kRoofMats[variant % kRoofMats.length];
  const tentMat2 = kRoofMats[(variant + 2) % kRoofMats.length];

  // 3 Pitched Expedition Tents in a semi-circle
  [
    { x: -3.4, z: -2.0, rot: 0.5, m: tentMat1 },
    { x: 3.4, z: -2.0, rot: -0.5, m: tentMat2 },
    { x: 0, z: -4.2, rot: 0, m: tentMat1 },
  ].forEach((td) => {
    const tent = new THREE.Mesh(campTentGeo, td.m);
    tent.position.set(td.x, 1.35, td.z);
    tent.rotation.y = Math.PI / 4 + td.rot;
    tent.castShadow = true;
    camp.add(tent);
  });

  // Central Roaring Campfire + Sitting Logs
  const fire = new THREE.Mesh(campFireConeGeo, kFireGlowMat);
  fire.position.set(0, 0.72, 0.6);
  camp.add(fire);

  const log1 = new THREE.Mesh(campLogGeo, postMatShared);
  log1.position.set(0, 0.24, 2.4);
  const log2 = new THREE.Mesh(campLogGeo, postMatShared);
  log2.position.set(-2.1, 0.24, 0.9);
  log2.rotation.y = Math.PI / 3;
  const log3 = new THREE.Mesh(campLogGeo, postMatShared);
  log3.position.set(2.1, 0.24, 0.9);
  log3.rotation.y = -Math.PI / 3;
  camp.add(log1, log2, log3);

  return camp;
}

function spawnContinentKingdomAndVillages(cont) {
  // 1. Grand Royal Kingdom Citadel / Palace overlooking the Capital Plaza (at cont.z - 62)
  const castle = createKingdomCastleMesh(cont.id);
  const castleZ = cont.z - 62.0;
  castle.position.set(cont.x, getTerrainHeight(cont.x, castleZ), castleZ);
  scene.add(castle);

  // 2. Southern Kingdom City Gate & Twin Watchtowers welcoming travelers from the Harbor (at cont.z + 52)
  const southGateZ = cont.z + 52.0;
  const wtL = createKingdomWatchtowerMesh(cont.id);
  wtL.position.set(cont.x - 13.5, getTerrainHeight(cont.x - 13.5, southGateZ), southGateZ);
  const wtR = createKingdomWatchtowerMesh(cont.id);
  wtR.position.set(cont.x + 13.5, getTerrainHeight(cont.x + 13.5, southGateZ), southGateZ);
  scene.add(wtL, wtR);

  // 3. Arched Stone Canal Bridge spanning the Grand Imperial City Canal at (cont.x, cont.z + 28)
  const canalBridge = createCanalBridgeMesh();
  canalBridge.position.set(cont.x, 2.35, cont.z + 28.0);
  scene.add(canalBridge);

  // 4. Imperial Stone Aqueduct Viaduct carrying mountain water into the West City Quarter
  const aqueduct = createImperialAqueductMesh();
  aqueduct.position.set(cont.x - 68.0, 2.5, cont.z - 18.0);
  aqueduct.rotation.y = Math.PI * 0.5;
  scene.add(aqueduct);

  // 5. Rotating Agricultural Windmills on the East & West City Outskirts
  [-58.0, 58.0].forEach((wx, wIdx) => {
    const wm = createCityWindmillMesh(cont.id + wIdx);
    wm.position.set(cont.x + wx, getTerrainHeight(cont.x + wx, cont.z + 12.0), cont.z + 12.0);
    scene.add(wm);
  });

  // 6. Grand Maritime Harbor Seaport: Lighthouse, 3 Shipping Piers, Cargo Cranes, Galleons & Interactive Harbor Master!
  const harborZ = cont.z + 64.0;
  const lighthouse = createHarborLighthouseMesh();
  lighthouse.position.set(cont.x - 36.0, 2.4, harborZ - 2.0);
  scene.add(lighthouse);

  [-22.0, 0.0, 22.0].forEach((px, pIdx) => {
    const pier = createHarborShippingPierMesh();
    pier.position.set(cont.x + px, 1.4, harborZ);
    scene.add(pier);

    // Docked Tall-Mast Merchant Galleons on the Left & Right Piers
    if (pIdx !== 1) {
      const galleon = createMerchantGalleonMesh(pIdx === 2);
      galleon.position.set(cont.x + px + (pIdx === 0 ? -6.5 : 6.5), -1.5, harborZ + 22.0);
      galleon.rotation.y = pIdx === 0 ? 0.15 : -0.15;
      scene.add(galleon);
      animatedShips.push({
        mesh: galleon,
        continent: cont,
        baseX: galleon.position.x,
        baseZ: galleon.position.z,
        isCruising: false,
        phase: cont.id * 1.7 + pIdx,
      });
    }
  });

  // 2 Actively Sailing Offshore Trade Galleons + 2 Canal Gondola Skiffs gliding along the City Canal!
  for (let s = 0; s < 2; s++) {
    const cruiser = createMerchantGalleonMesh(s === 1);
    const cz = harborZ + 52.0 + s * 26.0;
    cruiser.position.set(cont.x, -1.5, cz);
    scene.add(cruiser);
    animatedShips.push({
      mesh: cruiser,
      continent: cont,
      baseX: cont.x,
      baseZ: cz,
      isCruising: true,
      isSkiff: false,
      cruiseRadius: 72.0 + s * 22.0,
      speed: 0.22 + s * 0.08,
      phase: cont.id + s * 3.1,
    });

    // Canal Skiff gliding along the East-West Grand City Canal (at cont.z + 28)
    const skiff = createCanalBoatSkiffMesh(cont.id + s);
    const skX = cont.x + (s === 0 ? -26.0 : 26.0);
    skiff.position.set(skX, -1.45, cont.z + 28.0);
    skiff.rotation.y = Math.PI * 0.5;
    scene.add(skiff);
    animatedShips.push({
      mesh: skiff,
      continent: cont,
      baseX: skX,
      baseZ: cont.z + 28.0,
      isCruising: true,
      isSkiff: true,
      cruiseRadius: 16.0,
      speed: 0.55,
      phase: s * 2.2,
    });
  }

  // Interactive Harbor Master & Royal Skiff Captain at the Central Pier (Allows Boarding & Sailing a Boat or Fast-Sailing!)
  const harborCaptainGroup = new THREE.Group();
  harborCaptainGroup.position.set(cont.x + 3.2, 2.6, harborZ + 6.0);
  const capRing = new THREE.Mesh(sharedShopRingGeo, sharedShopRingMat);
  capRing.position.y = 0.12;
  harborCaptainGroup.add(capRing);
  const capModel = createArticulatedTeenOrAnimalNPC(0x0284c7, true, true);
  harborCaptainGroup.add(capModel);
  scene.add(harborCaptainGroup);

  const harborEntity = {
    id: `harbor-master-${cont.id}`,
    continent: cont,
    tier: cont.tier,
    badge: `⛵ HARBOR PORT #${cont.id + 1}`,
    kind: 'shop_npc',
    shopAction: 'boating',
    questMarker: '⛵',
    greeting: 'Ahoy Sadhak! Board your Royal Canal Skiff to sail the City Canals & Seas, or take a Merchant Galleon to any Continent!',
    icon: '⛵',
    name: `Admiral Varuna (Shipping & Boating)`,
    hp: 100,
    maxHp: 100,
    rejuvenated: true,
    mesh: harborCaptainGroup,
    blightRing: capRing,
    homeX: cont.x + 3.2,
    homeZ: harborZ + 6.0,
    wanderAngle: 0,
    heightOffset: 3.4,
    mixer: null,
  };
  createNameplateDOM(harborEntity);
  interactables.push(harborEntity);

  // 7. 26 Multi-Story City Townhouses, Guildhalls & Mountain Cottages per Kingdom (182 Buildings total!)
  for (let hIdx = 0; hIdx < 26; hIdx++) {
    let hx = cont.x;
    let hz = cont.z;
    let hRot = 0;
    const isTwoStory = hIdx < 16 && hIdx % 2 === 0;
    if (hIdx < 12) {
      // 12 Inner City Multi-Story Townhouses flanking the Grand Bazaar Avenues
      const side = hIdx % 2 === 0 ? -1 : 1;
      const row = Math.floor(hIdx / 2);
      hx = cont.x + side * (28.0 + (row % 2) * 9.5);
      hz = cont.z - 36.0 + row * 11.5;
      hRot = side < 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
    } else if (hIdx < 20) {
      // 8 Harbor & Canal Waterfront Warehouses / Merchant Guildhalls
      const side = hIdx % 2 === 0 ? -1 : 1;
      const col = Math.floor((hIdx - 12) / 2);
      hx = cont.x + side * (18.0 + col * 12.5);
      hz = cont.z + 42.0;
      hRot = 0;
    } else {
      // 6 Scenic Mountain Hamlet Cottages nestled along the lower Spiral Mountain Ghat Roadway!
      const roadS = 0.08 + (hIdx - 20) * 0.11;
      const { rx, rz } = getSpiralRoadPoint(cont, roadS);
      hx = rx - 11.5;
      hz = rz + 8.5;
      hRot = (hIdx * 1.1) % (Math.PI * 2);
    }
    const house = createVillageHouseMesh(cont.id + hIdx, isTwoStory);
    house.position.set(hx, getTerrainHeight(hx, hz), hz);
    house.rotation.y = hRot;
    scene.add(house);
  }

  // 8. 6 Permanent Multi-Tent Expedition Campgrounds per Continent (42 Campgrounds total across the World!)
  for (let cIdx = 0; cIdx < 6; cIdx++) {
    let cx = cont.x;
    let cz = cont.z;
    if (cIdx < 2) {
      // 2 Flatland Meadow Campgrounds near the City Outskirts
      cx = cont.x + (cIdx === 0 ? -42.0 : 42.0);
      cz = cont.z - 12.0;
    } else {
      // 4 High-Altitude Trekking Base-Camps along the 3.5-Turn Spiral Mountain Roadway!
      const roadS = 0.14 + (cIdx - 2) * 0.21;
      const { rx, rz } = getSpiralRoadPoint(cont, roadS);
      cx = rx + 9.5;
      cz = rz - 7.5;
    }
    const campY = getTerrainHeight(cx, cz);
    const campMesh = createExpeditionCampgroundMesh(cont.id + cIdx);
    campMesh.position.set(cx, campY, cz);
    scene.add(campMesh);
  }

  // 9. REAL WORKING CITY TRANSPORTATION: Royal Horse-Drawn Carriage & Harbor Ferry Service!
  // A. Royal Stagecoach Carriage on the Grand Highway (Rideable Transportation!)
  const carriageGroup = new THREE.Group();
  const coachBody = new THREE.Mesh(new THREE.BoxGeometry(3.6, 2.2, 5.4), kWallMat);
  coachBody.position.y = 2.1;
  const coachRoof = new THREE.Mesh(new THREE.ConeGeometry(3.2, 1.4, 4), kRoofMats[cont.id % kRoofMats.length]);
  coachRoof.position.y = 3.8;
  coachRoof.rotation.y = Math.PI / 4;
  coachRoof.scale.set(1.1, 0.8, 1.4);
  const wheelGeo = new THREE.CylinderGeometry(0.85, 0.85, 0.35, 12).rotateZ(Math.PI / 2);
  [[-1.9, 0.85, -1.8], [1.9, 0.85, -1.8], [-1.9, 0.85, 1.8], [1.9, 0.85, 1.8]].forEach(([wx, wy, wz]) => {
    const wh = new THREE.Mesh(wheelGeo, postMatShared);
    wh.position.set(wx, wy, wz);
    carriageGroup.add(wh);
  });
  carriageGroup.add(coachBody, coachRoof);
  carriageGroup.position.set(cont.x + 2.5, getTerrainHeight(cont.x + 2.5, cont.z - 120.0), cont.z - 120.0);
  scene.add(carriageGroup);

  const carriageEntity = {
    id: `carriage-${cont.id}`,
    continent: cont,
    tier: cont.tier,
    badge: `🚖 CITY STAGECOACH #${cont.id + 1}`,
    kind: 'shop_npc',
    shopAction: 'stagecoach',
    questMarker: '🚖',
    greeting: 'Hop in! The Royal Stagecoach runs the full North-South Highway from the City Gates to the Grand Mountain Roadway!',
    icon: '🚖',
    name: `Royal City Stagecoach (Working Transit)`,
    hp: 100,
    maxHp: 100,
    rejuvenated: true,
    mesh: carriageGroup,
    homeX: cont.x + 2.5,
    homeZ: cont.z - 120.0,
    wanderAngle: 0,
    heightOffset: 3.8,
    mixer: null,
  };
  createNameplateDOM(carriageEntity);
  interactables.push(carriageEntity);

  animatedTransitVehicles.push({
    mesh: carriageGroup,
    continent: cont,
    type: 'carriage',
    zMin: cont.z - 220.0,
    zMax: cont.z + 50.0,
    speed: 14.5,
    progress: (cont.id * 0.25) % 1.0,
  });
}

const gltfLoader = new GLTFLoader();
const mixers = [];
const modelCache = {};
const modelLoadCallbacks = {};

function loadSharedGLTF(url, onReady) {
  if (modelCache[url]) {
    onReady(modelCache[url]);
    return;
  }
  if (!modelLoadCallbacks[url]) {
    modelLoadCallbacks[url] = [onReady];
    gltfLoader.load(url, (gltf) => {
      modelCache[url] = gltf;
      modelLoadCallbacks[url].forEach((cb) => cb(gltf));
      delete modelLoadCallbacks[url];
    });
  } else {
    modelLoadCallbacks[url].push(onReady);
  }
}

const WILDLIFE_MODELS = [
  {
    url: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
    scale: 0.024,
    icon: '🦊',
    species: 'Sahyadri Fox',
  },
  {
    url: 'https://threejs.org/examples/models/gltf/Horse.glb',
    scale: 0.015,
    icon: '🦌',
    species: 'Nilgiri Tahr (Ibex)',
  },
  {
    url: 'https://threejs.org/examples/models/gltf/Stork.glb',
    scale: 0.018,
    icon: '🦢',
    species: 'Himalayan Monal Crane',
    flyHeight: 2.6,
  },
  {
    url: 'https://threejs.org/examples/models/gltf/Flamingo.glb',
    scale: 0.018,
    icon: '🦅',
    species: 'Malabar Hornbill',
    flyHeight: 2.8,
  },
];

CONTINENTS.forEach((cont) => {
  const cy = getTerrainHeight(cont.x, cont.z);

  // Build this Continent's 3D Kingdom Citadel, City Gate, Watchtowers, 18 Village Houses & 6 Campgrounds!
  spawnContinentKingdomAndVillages(cont);

  const altar = new THREE.Group();
  altar.position.set(cont.x, cy, cont.z);
  const dais = new THREE.Mesh(new THREE.CylinderGeometry(4.2, 5.0, 0.65, 24), stoneMat);
  dais.position.y = 0.32;
  dais.receiveShadow = true;
  altar.add(dais);

  const crystal = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.85, 0),
    new THREE.MeshStandardMaterial({ color: 0xfef08a, emissive: 0xf59e0b, emissiveIntensity: 2.2 })
  );
  crystal.position.y = 2.6;
  altar.add(crystal);
  cont.crystalMesh = crystal;
  scene.add(altar);

  const torchMat = new THREE.MeshStandardMaterial({
    color: cont.allowFlying ? 0x38bdf8 : 0xfde047,
    emissive: cont.allowFlying ? 0x0284c7 : 0xf59e0b,
    emissiveIntensity: 2.2,
  });
  const cairnPostGeo = new THREE.CylinderGeometry(0.18, 0.28, 1.6, 6);
  const cairnFlameGeo = new THREE.SphereGeometry(0.24, 8, 8);
  // 42 Guiding Roadway Lanterns & Milestones along the 3.5-Turn Spiral Mountain Roadway to the Summit!
  for (let step = 1; step <= 42; step++) {
    const pt = getMountainTrailPoint(cont, step / 43);
    const cairn = new THREE.Group();
    cairn.position.copy(pt);
    const post = new THREE.Mesh(cairnPostGeo, stoneMat);
    post.position.y = 0.8;
    cairn.add(post);
    const flame = new THREE.Mesh(cairnFlameGeo, torchMat);
    flame.position.y = 1.75;
    cairn.add(flame);
    scene.add(cairn);
  }

  // DENSE HIGH-DENSITY BIOME FORESTRY & FLORA (140 Organic Trees per Continent = ~1,000 Major Trees across the World!)
  for (let t = 0; t < 140; t++) {
    const angle = (t / 140) * Math.PI * 2 + hash2D(cont.id, t) * 0.8;
    const rad = 28 + hash2D(t, cont.id * 11) * 380;
    const tx = cont.x + Math.cos(angle) * rad;
    const tz = cont.z + Math.sin(angle) * rad;
    if (getRoadwayMask(cont, tx, tz) > 0.1) continue;
    const isNearStart = cont.id === 0 && Math.hypot(tx, tz) < 48;
    spawnOrganicTree(tx, tz, cont.id, isNearStart);
  }

  const midTrailPt = getMountainTrailPoint(cont, 0.28);
  const highPassPt = getMountainTrailPoint(cont, 0.56);
  const alpineRidgePt = getMountainTrailPoint(cont, 0.88);

  const objectives = [
    {
      pos: new THREE.Vector3(cont.x - 10, getTerrainHeight(cont.x - 10, cont.z - 8), cont.z - 8),
      kind: 'wildlife',
      wIdx: (cont.id * 2) % WILDLIFE_MODELS.length,
      badge: `Foothills`,
    },
    {
      pos: midTrailPt,
      kind: 'wildlife',
      wIdx: (cont.id * 2 + 1) % WILDLIFE_MODELS.length,
      badge: `Lower Ridge`,
    },
    {
      pos: highPassPt,
      kind: 'shrine',
      badge: `High Pass`,
    },
    {
      pos: alpineRidgePt,
      kind: 'chest',
      badge: `🏔️ RIDGE CHEST`,
    },
  ];

  objectives.forEach((obj, sIdx) => {
    const group = new THREE.Group();
    group.position.copy(obj.pos);

    const ringColor = obj.kind === 'chest' ? 0xfacc15 : 0xa855f7;
    const blightRing = new THREE.Mesh(
      new THREE.RingGeometry(1.4, 1.8, 32).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ color: ringColor, side: THREE.DoubleSide, transparent: true, opacity: 0.8 })
    );
    blightRing.position.y = 0.14;
    group.add(blightRing);

    let icon = '🎁';
    let name = '';
    let heightOffset = 2.6;
    const maxHp = cont.maxHpBase;

    const entity = {
      id: `site-${cont.id}-${sIdx}`,
      continent: cont,
      tier: cont.tier,
      badge: obj.badge,
      kind: obj.kind,
      icon,
      name,
      hp: Math.round(maxHp * 0.15),
      maxHp,
      rejuvenated: false,
      mesh: group,
      blightRing,
      homeX: obj.pos.x,
      homeZ: obj.pos.z,
      wanderAngle: sIdx * 1.7 + cont.id,
      heightOffset,
      mixer: null,
    };

    if (obj.kind === 'wildlife') {
      const wDef = WILDLIFE_MODELS[obj.wIdx];
      entity.icon = wDef.icon;
      entity.name = `Distressed ${wDef.species}`;
      entity.heightOffset = (wDef.flyHeight || 0) + 2.4;

      loadSharedGLTF(wDef.url, (gltf) => {
        const model = SkeletonUtils.clone(gltf.scene);
        model.scale.setScalar(wDef.scale);
        model.position.y = wDef.flyHeight || 0;
        model.traverse((c) => {
          if (c.isMesh) {
            c.castShadow = true;
            c.receiveShadow = true;
          }
        });
        group.add(model);
        if (gltf.animations && gltf.animations.length > 0) {
          const m = new THREE.AnimationMixer(model);
          const clip = gltf.animations.length > 1 ? gltf.animations[1] : gltf.animations[0];
          m.clipAction(clip).play();
          entity.mixer = m;
        }
      });
    } else if (obj.kind === 'shrine') {
      entity.icon = '🔥';
      entity.name = `${cont.shortName} High-Pass Cairn`;
      entity.heightOffset = 6.2;

      const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.55, 0.95, 4.6, 8), stoneMat);
      shaft.position.y = 2.3;
      shaft.castShadow = true;
      group.add(shaft);

      const cap = new THREE.Mesh(new THREE.ConeGeometry(0.8, 1.3, 8), stoneMat);
      cap.position.y = 5.1;
      group.add(cap);
    } else {
      entity.icon = '🎁';
      entity.name = `🎁 ${cont.chestName}`;
      entity.heightOffset = 3.4;

      const chestMesh = createTreasureChestMesh();
      group.add(chestMesh);
      group._chest = chestMesh;
    }

    scene.add(group);
    createNameplateDOM(entity);
    interactables.push(entity);
  });
});

// ============================================================================
// 6B. 108 SACRED BAZAAR SHOPS, 108 FORWARD-FACING ANIMAL & TEEN NPCs, & WOW QUESTS!
// ============================================================================
const SHOP_ARCHETYPES = [
  { awning: 0xd97706, badge: '🛠️ FORGE SHOP', icon: '🦊', title: 'Kitsune Armorer Apprent.', action: 'shop', greeting: 'Welcome to the Royal Kingdom Forge! Upgrade your Sacred Staff, Saddle & Crampons here.' },
  { awning: 0x059669, badge: '🧪 APOTHECARY', icon: '🦌', title: 'Young Fawn Herbalist', action: 'apothecary', greeting: 'Drink this Himalayan Soma-Elixir! Your Vigor Orbs and Stamina are 100% restored!' },
  { awning: 0x0284c7, badge: '🐎 STABLE MASTER', icon: '🐎', title: 'Teen Ashva Colt-Keeper', action: 'mounts', greeting: 'Your Golden Ashva Warsteed is groomed and ready! Press [Z] to Mount or [Space] to Fly.' },
  { awning: 0x7c3aed, badge: '🍻 TAVERN INN', icon: '🐼', title: 'Red-Panda Innkeeper Youth', action: 'innkeeper', greeting: 'Welcome to the Kingdom Sanctuary Inn! Enjoy the Tavern Lute music and +60s Well-Fed Speed Buff!' },
  { awning: 0xe11d48, badge: '💎 RELIC BAZAAR', icon: '🦢', title: 'Crane-kin Relic Apprentice', action: 'bags', greeting: 'Behold your 16-Slot Traveler’s Backpack and ancient Kingdom mountain relics!' },
  { awning: 0x0d9488, badge: '📜 EXPEDITION GUILD', icon: '🧒', title: 'Gurukul Teen Quest Scout', action: 'quests', greeting: 'Walk, camp, or ride along the 3.5-Turn Spiral Mountain Roadway from our Kingdom to the Summit!' },
];

const CITIZEN_ARCHETYPES = [
  { badge: '🦊 ANIMAL SCOUT', icon: '🦊', title: 'Golden Fox Kingdom Scout', role: 'quests', robeColor: 0xf59e0b, isAnimal: true, questMarker: '❗' },
  { badge: '🧒 TEEN BARD', icon: '🎵', title: 'Gurukul Teen Lute Bard', role: 'bard', robeColor: 0x38bdf8, isAnimal: false, questMarker: null },
  { badge: '🦌 FAWN RANGER', icon: '🦌', title: 'Royal Stag & Fawn Guide', role: 'quests', robeColor: 0x10b981, isAnimal: true, questMarker: '❗' },
  { badge: '👧 YOUTH CADET', icon: '🛡️', title: 'Kingdom Teen Cadet', role: 'guard', robeColor: 0xef4444, isAnimal: false, questMarker: null },
  { badge: '🦢 CRANE ENVOY', icon: '🦢', title: 'Himalayan Crane Messenger', role: 'bags', robeColor: 0xa855f7, isAnimal: true, questMarker: '❓' },
  { badge: '🧒 YOUNG TREKKER', icon: '🥾', title: 'Young Pilgrim Camper', role: 'quests', robeColor: 0xf97316, isAnimal: false, questMarker: '❗' },
];

// Creates an articulated Youth/Teen Adventurer OR Kemono Animal-Folk Character facing +Z with swinging arms & legs!
function createArticulatedTeenOrAnimalNPC(tunicHex, isAnimalFolk = false, hasQuestGem = false) {
  const g = new THREE.Group();
  const tunicMat = awningMatCache[tunicHex] || (awningMatCache[tunicHex] = new THREE.MeshStandardMaterial({ color: tunicHex, roughness: 0.65 }));

  // Youth Torso
  const body = new THREE.Mesh(sharedRobeGeo, tunicMat);
  body.position.y = 0.72;
  body.castShadow = true;
  g.add(body);

  // Adventurer Backpack on back (-Z is back when facing +Z!)
  const pack = new THREE.Mesh(sharedBackpackGeo, postMatShared);
  pack.position.set(0, 0.78, -0.22);
  g.add(pack);

  // Youthful Head + Eyes facing +Z (Forward!)
  const head = new THREE.Mesh(sharedHeadGeo, isAnimalFolk ? tunicMat : sharedSkinMat);
  head.position.y = 1.34;
  g.add(head);

  // Forward Snout / Nose Bridge on +Z so facing direction is 100% unmistakable!
  const snout = new THREE.Mesh(
    new THREE.ConeGeometry(isAnimalFolk ? 0.13 : 0.06, isAnimalFolk ? 0.28 : 0.14, 5).rotateX(Math.PI / 2),
    isAnimalFolk ? sharedSkinMat : sharedSkinMat
  );
  snout.position.set(0, 1.32, 0.24);
  g.add(snout);

  if (isAnimalFolk) {
    // Perky Fox / Wolf / Stag Ears & Fluffy Tail!
    const earL = new THREE.Mesh(sharedEarGeo, tunicMat);
    earL.position.set(-0.14, 1.62, 0.02);
    earL.rotation.z = 0.2;
    const earR = new THREE.Mesh(sharedEarGeo, tunicMat);
    earR.position.set(0.14, 1.62, 0.02);
    earR.rotation.z = -0.2;
    const tail = new THREE.Mesh(sharedTailGeo, tunicMat);
    tail.position.set(0, 0.52, -0.32);
    g.add(earL, earR, tail);
  } else {
    // Gurukul Teen Adventurer Cap / Bandana
    const cap = new THREE.Mesh(sharedHatGeo, goldMatShared);
    cap.position.y = 1.58;
    g.add(cap);
  }

  // Articulated Arms & Legs for natural forward walking swing!
  const armL = new THREE.Mesh(sharedLimbGeo, tunicMat);
  armL.position.set(-0.32, 0.75, 0);
  const armR = new THREE.Mesh(sharedLimbGeo, tunicMat);
  armR.position.set(0.32, 0.75, 0);
  const legL = new THREE.Mesh(sharedLimbGeo, sharedDarkHairMat);
  legL.position.set(-0.13, 0.28, 0);
  const legR = new THREE.Mesh(sharedLimbGeo, sharedDarkHairMat);
  legR.position.set(0.13, 0.28, 0);
  g.add(armL, armR, legL, legR);

  // Floating Golden WoW Quest Diamond above Quest Givers!
  if (hasQuestGem) {
    const qGem = new THREE.Mesh(sharedQuestExclamGeo, sharedQuestGlowMat);
    qGem.position.set(0, 2.25, 0);
    g.add(qGem);
    g._questGem = qGem;
  }

  g._armL = armL;
  g._armR = armR;
  g._legL = legL;
  g._legR = legR;
  return g;
}

// Spawn Exactly 108 Interactive 3D Shops Across the 7 Continents (Grand Bazaar Avenues + Mountain Roadway Outposts!)
for (let sIdx = 0; sIdx < 108; sIdx++) {
  const cont = CONTINENTS[sIdx % CONTINENTS.length];
  const localIdx = Math.floor(sIdx / CONTINENTS.length); // 0..15 per continent
  const arch = SHOP_ARCHETYPES[sIdx % SHOP_ARCHETYPES.length];

  let sx = cont.x;
  let sz = cont.z;
  let rotY = 0;

  if (localIdx < 8) {
    // 8 Shops lining the North-South Grand Bazaar Avenue
    const side = localIdx % 2 === 0 ? -1 : 1;
    const row = Math.floor(localIdx / 2);
    sx = cont.x + side * 15.5;
    sz = cont.z - 22.0 + row * 18.0;
    rotY = side < 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
  } else if (localIdx < 12) {
    // 4 Shops lining the East-West Cross-Bazaar Boulevard
    const side = localIdx % 2 === 0 ? -1 : 1;
    const col = localIdx - 8;
    sx = cont.x + (col < 2 ? -34.0 - col * 16.0 : 34.0 + (col - 2) * 16.0);
    sz = cont.z + side * 14.5;
    rotY = side < 0 ? 0 : Math.PI;
  } else {
    // 4 Mountain Roadway Waystation Shops along the Spiral Ghat Roadway to the Summit!
    const roadFrac = 0.18 + (localIdx - 12) * 0.19;
    const { rx, rz } = getSpiralRoadPoint(cont, roadFrac);
    sx = rx + 6.5;
    sz = rz + 6.5;
    rotY = Math.PI * 0.25;
  }

  const sy = getTerrainHeight(sx, sz);
  const shopGroup = new THREE.Group();
  shopGroup.position.set(sx, sy, sz);
  shopGroup.rotation.y = rotY;

  shopGroup.add(createShopPavilionMesh(arch.awning));

  const shopRing = new THREE.Mesh(sharedShopRingGeo, sharedShopRingMat);
  shopRing.position.set(0, 0.12, 1.4);
  shopGroup.add(shopRing);

  // Mix of Animal & Teen Shopkeepers standing behind counter facing customers (+Z)!
  if (localIdx % 3 === 0) {
    loadSharedGLTF('https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb', (gltf) => {
      const foxKeeper = SkeletonUtils.clone(gltf.scene);
      foxKeeper.scale.setScalar(0.022);
      foxKeeper.position.set(0, 0, 1.35);
      foxKeeper.rotation.y = 0; // Fox.glb faces +Z natively!
      shopGroup.add(foxKeeper);
    });
  } else {
    const keeper = createArticulatedTeenOrAnimalNPC(arch.awning, localIdx % 2 === 1, arch.action === 'quests');
    keeper.position.set(0, 0, 1.35);
    shopGroup.add(keeper);
  }

  scene.add(shopGroup);

  const shopEntity = {
    id: `shop-108-${sIdx}`,
    continent: cont,
    tier: cont.tier,
    badge: `${arch.badge} #${sIdx + 1}`,
    kind: 'shop_npc',
    shopAction: arch.action,
    questMarker: arch.action === 'quests' ? '❗' : null,
    greeting: arch.greeting,
    icon: arch.icon,
    name: `${arch.title} #${sIdx + 1}`,
    hp: 100,
    maxHp: 100,
    rejuvenated: true,
    mesh: shopGroup,
    blightRing: shopRing,
    homeX: sx,
    homeZ: sz,
    wanderAngle: 0,
    heightOffset: 3.6,
    mixer: null,
  };

  createNameplateDOM(shopEntity);
  interactables.push(shopEntity);
}

// Spawn Exactly 108 Active Forward-Facing Animal & Teen Adventurer NPCs Across the 7 Kingdoms & Mountain Roadways!
for (let nIdx = 0; nIdx < 108; nIdx++) {
  const cont = CONTINENTS[nIdx % CONTINENTS.length];
  const localIdx = Math.floor(nIdx / CONTINENTS.length); // 0..15 per continent
  const arch = CITIZEN_ARCHETYPES[nIdx % CITIZEN_ARCHETYPES.length];

  let nx = cont.x;
  let nz = cont.z;
  let patrolRadius = 14.0;
  let isRoadTrekker = false;
  let roadProgress = 0;

  if (localIdx < 9) {
    // 9 Bustling Kingdom Citizens (Animal Scouts & Gurukul Teens) patrolling the Bazaar Streets, Houses & Castle Plaza
    const angle = (localIdx / 9) * Math.PI * 2.0;
    const dist = 8.0 + (localIdx % 3) * 18.0;
    nx = cont.x + Math.cos(angle) * dist;
    nz = cont.z + Math.sin(angle) * dist;
    patrolRadius = 12.0 + (localIdx % 4) * 6.0;
  } else {
    // 7 Mountain Roadway Teen & Animal Trekkers walking steadily FORWARD up the Spiral Mountain Roadway to the Summit!
    isRoadTrekker = true;
    roadProgress = 0.06 + ((localIdx - 9) / 7.0) * 0.86;
    const { rx, rz } = getSpiralRoadPoint(cont, roadProgress);
    nx = rx;
    nz = rz;
  }

  const ny = getTerrainHeight(nx, nz);
  const npcGroup = new THREE.Group();
  npcGroup.position.set(nx, ny, nz);

  const npcRing = new THREE.Mesh(sharedNpcRingGeo, sharedNpcRingMat);
  npcRing.position.y = 0.12;
  npcGroup.add(npcRing);

  // Mix of Rigged 3D Animal Characters (Foxes & Foals/Stags) + Articulated Teen/Youth Adventurers & Kemono Animal-Folk!
  if (localIdx % 4 === 0) {
    // Rigged Golden Fox Scout (Fox.glb faces +Z natively, matching Math.atan2(dx, dz) 100% forward!)
    loadSharedGLTF('https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb', (gltf) => {
      const foxModel = SkeletonUtils.clone(gltf.scene);
      foxModel.scale.setScalar(0.024);
      foxModel.rotation.y = 0; // +Z is forward for Fox.glb
      npcGroup.add(foxModel);
      if (gltf.animations && gltf.animations.length > 0) {
        const m = new THREE.AnimationMixer(foxModel);
        const runClip = gltf.animations[1] || gltf.animations[0];
        m.clipAction(runClip).play();
        citizenEntity.mixer = m;
      }
    });
    if (arch.questMarker) {
      const qGem = new THREE.Mesh(sharedQuestExclamGeo, sharedQuestGlowMat);
      qGem.position.set(0, 2.1, 0);
      npcGroup.add(qGem);
      npcGroup._questGem = qGem;
    }
  } else if (localIdx % 4 === 2) {
    // Rigged Young Fawn / Foal Companion (Horse.glb faces +Z natively, matching Math.atan2(dx, dz) 100% forward!)
    loadSharedGLTF('https://threejs.org/examples/models/gltf/Horse.glb', (gltf) => {
      const foalModel = SkeletonUtils.clone(gltf.scene);
      foalModel.scale.setScalar(0.0115);
      foalModel.rotation.y = 0; // +Z is forward for Horse.glb
      npcGroup.add(foalModel);
      if (gltf.animations && gltf.animations[0]) {
        const m = new THREE.AnimationMixer(foalModel);
        m.clipAction(gltf.animations[0]).play();
        citizenEntity.mixer = m;
      }
    });
  } else {
    // Articulated Youth / Teen Adventurer or Kemono Animal-Folk with swinging limbs facing +Z!
    const walker = createArticulatedTeenOrAnimalNPC(arch.robeColor, arch.isAnimal, Boolean(arch.questMarker));
    npcGroup.add(walker);
    npcGroup._robeWalker = walker;
  }

  scene.add(npcGroup);

  const citizenEntity = {
    id: `npc-108-${nIdx}`,
    continent: cont,
    tier: cont.tier,
    badge: `${arch.badge} #${nIdx + 1}`,
    kind: 'town_npc',
    npcRole: arch.role,
    questMarker: arch.questMarker,
    questCompleted: false,
    icon: arch.icon,
    name: `${arch.title} #${nIdx + 1}`,
    hp: 100,
    maxHp: 100,
    rejuvenated: true,
    mesh: npcGroup,
    blightRing: npcRing,
    homeX: nx,
    homeZ: nz,
    patrolRadius,
    isRoadTrekker,
    roadProgress,
    wanderAngle: nIdx * 1.1,
    heightOffset: 2.8,
    mixer: null,
  };

  createNameplateDOM(citizenEntity);
  interactables.push(citizenEntity);
}

// ============================================================================
// 6C. FLOCKS OF RANDOMLY SOARING 3D BIRDS ACROSS THE SKIES & MOUNTAIN PEAKS!
// ============================================================================
const ambientBirds = [];
const birdWingGeo = new THREE.ConeGeometry(0.18, 1.05, 4);
birdWingGeo.rotateZ(Math.PI / 2);
const birdBodyGeo = new THREE.ConeGeometry(0.16, 0.75, 5);
birdBodyGeo.rotateX(Math.PI / 2);
const birdColors = [0xf8fafc, 0x38bdf8, 0xfbbf24, 0xf472b6, 0x34d399];
const birdMats = birdColors.map((hex) => new THREE.MeshStandardMaterial({ color: hex, emissive: hex, emissiveIntensity: 0.35, side: THREE.DoubleSide }));

function createSoaringBirdMesh(mat) {
  const bGroup = new THREE.Group();
  const body = new THREE.Mesh(birdBodyGeo, mat);
  bGroup.add(body);
  const lw = new THREE.Mesh(birdWingGeo, mat);
  lw.position.set(-0.45, 0, 0);
  const rw = new THREE.Mesh(birdWingGeo.clone(), mat);
  rw.scale.x = -1;
  rw.position.set(0.45, 0, 0);
  bGroup.add(lw, rw);
  bGroup._lw = lw;
  bGroup._rw = rw;
  return bGroup;
}

// Spawn 112 Randomly Soaring Birds Across the 7 Continents (16 per Continent + Rigged Stork/Flamingo Leaders!)
for (let bIdx = 0; bIdx < 112; bIdx++) {
  const cont = CONTINENTS[bIdx % CONTINENTS.length];
  const mat = birdMats[bIdx % birdMats.length];
  const birdMesh = createSoaringBirdMesh(mat);

  const centerAngle = hash2D(bIdx, 19) * Math.PI * 2.0;
  const centerDist = 15.0 + hash2D(bIdx, 43) * 280.0;
  const cx = cont.x + Math.cos(centerAngle) * centerDist;
  const cz = cont.z - 80.0 + Math.sin(centerAngle) * centerDist;
  const baseAlt = Math.max(12.0, getTerrainHeight(cx, cz) + 14.0 + hash2D(bIdx, 71) * 48.0);

  birdMesh.position.set(cx, baseAlt, cz);
  birdMesh.scale.setScalar(1.1 + (bIdx % 3) * 0.35);
  scene.add(birdMesh);

  // Load rigged Stork/Flamingo on flock leaders near Base Camp!
  if (bIdx < 14) {
    const birdUrl = bIdx % 2 === 0
      ? 'https://threejs.org/examples/models/gltf/Stork.glb'
      : 'https://threejs.org/examples/models/gltf/Flamingo.glb';
    loadSharedGLTF(birdUrl, (gltf) => {
      const m = SkeletonUtils.clone(gltf.scene);
      m.scale.setScalar(0.016);
      birdMesh.add(m);
    });
  }

  ambientBirds.push({
    mesh: birdMesh,
    continent: cont,
    cx,
    cz,
    baseAlt,
    orbitR: 22.0 + hash2D(bIdx, 101) * 65.0,
    speed: 0.45 + hash2D(bIdx, 137) * 0.65,
    phase: bIdx * 0.9,
    flapSpeed: 7.5 + (bIdx % 5) * 1.4,
  });
}

// ============================================================================
// 7. SEATED SKELETAL RIDER ON MOUNT (`Soldier.glb` Astride `Horse.glb` + Wings)
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, getTerrainHeight(0, 9), 9);
scene.add(playerGroup);

// 3D Mount Container inside playerGroup so Mount & Seated Rider move in 100% unison!
const mountGroup = new THREE.Group();
playerGroup.add(mountGroup);

// 3D Royal Sailboat Skiff Container inside playerGroup for City Canal & Ocean Boating!
const playerBoatGroup = new THREE.Group();
const pBoatMesh = createCanalBoatSkiffMesh(1);
pBoatMesh.scale.set(1.25, 1.2, 1.28);
pBoatMesh.rotation.y = Math.PI; // Align prow with player forward (-Z)
const pBoatMast = new THREE.Mesh(new THREE.CylinderGeometry(0.11, 0.14, 5.2, 6), postMatShared);
pBoatMast.position.set(0, 2.7, -0.5);
const pBoatSail = new THREE.Mesh(new THREE.BoxGeometry(3.2, 2.8, 0.12), kSailMat);
pBoatSail.position.set(0, 3.2, -0.7);
playerBoatGroup.add(pBoatMesh, pBoatMast, pBoatSail);
playerBoatGroup.visible = false;
playerGroup.add(playerBoatGroup);

// Ornate Golden Saddle & Reins on the Mount's Back
const saddleMesh = new THREE.Mesh(
  new THREE.BoxGeometry(0.75, 0.25, 0.95),
  new THREE.MeshStandardMaterial({ color: 0x78350f, roughness: 0.6 })
);
saddleMesh.position.set(0, 1.42, -0.05);
mountGroup.add(saddleMesh);

// Unfurling Golden Pegasus / Dragon Wings attached to the Mount's Shoulders
const mountWingsGroup = new THREE.Group();
mountWingsGroup.position.set(0, 1.55, 0.15);
const wingMat = new THREE.MeshStandardMaterial({
  color: 0xfde047,
  emissive: 0xd97706,
  emissiveIntensity: 1.4,
  side: THREE.DoubleSide,
});
const leftWing = new THREE.Group();
const rightWing = new THREE.Group();
for (let f = 0; f < 5; f++) {
  const featherGeo = new THREE.ConeGeometry(0.22, 2.3 - f * 0.25, 4);
  featherGeo.rotateZ(Math.PI / 2);
  const fl = new THREE.Mesh(featherGeo, wingMat);
  fl.position.set(-0.9 - f * 0.28, f * 0.16, 0);
  fl.rotation.z = -0.18 * f;
  leftWing.add(fl);

  const fr = new THREE.Mesh(featherGeo.clone(), wingMat);
  fr.scale.x = -1;
  fr.position.set(0.9 + f * 0.28, f * 0.16, 0);
  fr.rotation.z = 0.18 * f;
  rightWing.add(fr);
}
mountWingsGroup.add(leftWing, rightWing);
mountGroup.add(mountWingsGroup);

let mountMixer = null;
let mountAction = null;

// Load Rigged `Horse.glb` Mount via Shared Cache
loadSharedGLTF('https://threejs.org/examples/models/gltf/Horse.glb', (gltf) => {
  const horse = SkeletonUtils.clone(gltf.scene);
  horse.scale.setScalar(0.0155);
  horse.rotation.y = Math.PI; // Align with rider forward direction (-Z)
  horse.traverse((c) => {
    if (c.isMesh) {
      c.castShadow = true;
      c.receiveShadow = true;
    }
  });
  mountGroup.add(horse);

  if (gltf.animations && gltf.animations[0]) {
    mountMixer = new THREE.AnimationMixer(horse);
    mountAction = mountMixer.clipAction(gltf.animations[0]);
    mountAction.play();
    mixers.push(mountMixer);
  }
});

// Load Rigged `Soldier.glb` Character & Cache Mixamo Skeleton Bones for Seated Saddle Pose!
const playerBones = {};
const BONE_NAMES = [
  'mixamorigHips',
  'mixamorigSpine',
  'mixamorigSpine1',
  'mixamorigLeftUpLeg',
  'mixamorigRightUpLeg',
  'mixamorigLeftLeg',
  'mixamorigRightLeg',
  'mixamorigLeftFoot',
  'mixamorigRightFoot',
  'mixamorigLeftArm',
  'mixamorigRightArm',
  'mixamorigLeftForeArm',
  'mixamorigRightForeArm',
];

let playerModel = null;
let playerMixer = null;
let playerActions = {};
let activePlayerAction = null;

gltfLoader.load('https://threejs.org/examples/models/gltf/Soldier.glb', (gltf) => {
  playerModel = gltf.scene;
  playerModel.scale.setScalar(1.32);
  playerModel.traverse((c) => {
    if (c.isMesh) {
      c.castShadow = true;
      c.receiveShadow = true;
    }
    if (c.isBone && BONE_NAMES.includes(c.name)) {
      playerBones[c.name] = c;
    }
  });
  playerGroup.add(playerModel);

  playerMixer = new THREE.AnimationMixer(playerModel);
  mixers.push(playerMixer);
  gltf.animations.forEach((clip) => {
    playerActions[clip.name] = playerMixer.clipAction(clip);
  });
  if (playerActions['Idle']) {
    activePlayerAction = playerActions['Idle'];
    activePlayerAction.play();
  }
});

function setPlayerAnim(name) {
  if (!playerActions[name] || activePlayerAction === playerActions[name]) return;
  const next = playerActions[name];
  next.reset().fadeIn(0.18).play();
  if (activePlayerAction) activePlayerAction.fadeOut(0.18);
  activePlayerAction = next;
}

// Apply Seated Astride Saddle Pose (or Ground Meditation Sit [X]) AFTER mixer.update(dt)!
function applySeatedRiderPose(elapsed, isMoving) {
  if (!playerModel) return;

  mountGroup.visible = STATE.isMounted && !STATE.isBoating;
  playerBoatGroup.visible = STATE.isBoating;
  mountWingsGroup.visible = STATE.isMounted && !STATE.isBoating && (STATE.isFlying || canFlyOnContinent(STATE.currentContinent));

  if (!STATE.isMounted && !STATE.isSitting && !STATE.isBoating) {
    playerModel.position.set(0, 0, 0);
    return;
  }

  const gallopBob = isMoving ? Math.sin(elapsed * 11.0) * 0.055 : Math.sin(elapsed * 2.5) * 0.015;

  if (STATE.isBoating) {
    // Seated comfortably inside the Royal Canal & Harbor Sailboat Skiff!
    playerModel.position.set(0, 0.45 + Math.sin(elapsed * 3.2) * 0.04, 0.15);
  } else if (STATE.isMounted) {
    // Lock Rider Pelvis directly onto the Mount's Saddle!
    playerModel.position.set(0, 1.18 + gallopBob, -0.06);
  } else {
    // Sitting on the ground [X]
    playerModel.position.set(0, -0.52, 0);
  }

  const LUpLeg = playerBones['mixamorigLeftUpLeg'];
  const RUpLeg = playerBones['mixamorigRightUpLeg'];
  const LLeg = playerBones['mixamorigLeftLeg'];
  const RLeg = playerBones['mixamorigRightLeg'];
  const LFoot = playerBones['mixamorigLeftFoot'];
  const RFoot = playerBones['mixamorigRightFoot'];
  const Spine = playerBones['mixamorigSpine'];
  const LArm = playerBones['mixamorigLeftArm'];
  const RArm = playerBones['mixamorigRightArm'];
  const LFore = playerBones['mixamorigLeftForeArm'];
  const RFore = playerBones['mixamorigRightForeArm'];

  // 1. Thighs pitched forward (-1.28 rad) and splayed outward (±0.52 rad) straddling the mount's saddle!
  const splay = STATE.isMounted ? 0.52 : 0.35;
  if (LUpLeg) LUpLeg.rotation.set(-1.28, -0.22, splay, 'XYZ');
  if (RUpLeg) RUpLeg.rotation.set(-1.28, 0.22, -splay, 'XYZ');

  // 2. Knees bent downward gripping the stirrups (+1.38 rad)
  const kneeBend = STATE.isMounted ? 1.38 + gallopBob * 0.6 : 1.52;
  if (LLeg) LLeg.rotation.set(kneeBend, 0, 0, 'XYZ');
  if (RLeg) RLeg.rotation.set(kneeBend, 0, 0, 'XYZ');

  // 3. Heels down in stirrups
  if (LFoot) LFoot.rotation.set(-0.25, 0, 0, 'XYZ');
  if (RFoot) RFoot.rotation.set(-0.25, 0, 0, 'XYZ');

  // 4. Upright Spine with subtle forward riding lean
  if (Spine) Spine.rotation.set(STATE.isMounted && isMoving ? 0.15 : 0.05, 0, 0, 'XYZ');

  // 5. Hands forward holding the reins!
  if (LArm) LArm.rotation.set(-0.58, 0.25, -0.32, 'XYZ');
  if (LFore) LFore.rotation.set(-0.45, 0, 0, 'XYZ');
  if (RArm) RArm.rotation.set(-0.58, -0.25, 0.32, 'XYZ');
  if (RFore) RFore.rotation.set(-0.45, 0, 0, 'XYZ');
}

// ============================================================================
// 8. WOW MOUNT TOGGLE [Z], SIT/DESCEND [X], AUTO-RUN [~] & CAMPFIRE [G]
// ============================================================================
function toggleMountUp() {
  SFX.init();
  if (STATE.isMounted) {
    // Dismount immediately
    STATE.isMounted = false;
    STATE.isFlying = false;
    document.getElementById('slot-mount').classList.remove('active-aura');
    SFX.playTargetClick();
    showToast('🥾 Dismounted (On Foot). Press [Z] anytime to Mount Up!');
    updateVigorOrbsUI();
    updateAllHUD();
    return;
  }

  const doMount = () => {
    STATE.isMounted = true;
    STATE.isSitting = false;
    document.getElementById('slot-mount').classList.add('active-aura');
    document.getElementById('slot-sit').classList.remove('active-aura');
    SFX.playMountWhinnyOrWingbeat();
    spawnShockwave(playerGroup.position, 0xfde047, 6.0, 0.5);
    showToast('🐎 Mounted (Seated Astride Saddle)! Press [Space] to Fly Up or [WASD] to Gallop!');
    updateVigorOrbsUI();
    updateAllHUD();
  };

  if (STATE.settings.instantMount) {
    doMount();
  } else {
    // Authentic WoW 1.5s Mount Summon Castbar
    SFX.playCastStart();
    STATE.casting = {
      name: 'Summoning Ashva Mount...',
      duration: 1.5,
      elapsed: 0,
      onComplete: doMount,
    };
    document.getElementById('wow-castbar').classList.remove('cast-hidden');
    document.getElementById('cast-label').textContent = STATE.casting.name;
  }
}

function toggleSitOrDescend() {
  SFX.init();
  if (STATE.isMounted && STATE.isFlying) {
    // Descending in flight
    playerGroup.position.y = Math.max(
      getTerrainHeight(playerGroup.position.x, playerGroup.position.z),
      playerGroup.position.y - 8.0
    );
    return;
  }
  if (STATE.isMounted) {
    toggleMountUp();
  }
  STATE.isSitting = !STATE.isSitting;
  document.getElementById('slot-sit').classList.toggle('active-aura', STATE.isSitting);
  showToast(STATE.isSitting ? '🧘 Sitting & Meditating (+100% Stamina/Vigor Regen)' : 'Standing');
}

function toggleAutoRun() {
  STATE.autoRun = !STATE.autoRun;
  document.getElementById('slot-autorun').classList.toggle('active-aura', STATE.autoRun);
  showToast(STATE.autoRun ? '⏩ Auto-Run Engaged ([W] or [S] cancels)' : 'Auto-Run Off');
}

const activeCampfires = [];
function pitchMountainCampfire() {
  SFX.playHealImpact();
  const pos = playerGroup.position.clone();
  pos.y = getTerrainHeight(pos.x, pos.z);

  const campGroup = new THREE.Group();
  campGroup.position.copy(pos);

  const tentMat = new THREE.MeshStandardMaterial({ color: 0xd97706, roughness: 0.8, side: THREE.DoubleSide });
  const tent = new THREE.Mesh(new THREE.ConeGeometry(1.9, 2.2, 4), tentMat);
  tent.position.set(-2.2, 1.1, -1.2);
  tent.rotation.y = Math.PI / 4;
  tent.castShadow = true;
  campGroup.add(tent);

  const fireOrb = new THREE.Mesh(
    new THREE.ConeGeometry(0.55, 1.35, 8),
    new THREE.MeshStandardMaterial({ color: 0xfde047, emissive: 0xf97316, emissiveIntensity: 3.2 })
  );
  fireOrb.position.set(0, 0.68, 1.4);
  campGroup.add(fireOrb);

  scene.add(campGroup);
  activeCampfires.push({ group: campGroup, fireOrb, x: pos.x, z: pos.z });

  STATE.trekStamina = 100;
  STATE.vigor = STATE.maxVigor;
  STATE.wellFedTimer = 30.0;
  updateVigorOrbsUI();

  const campHeal = SHOP_TOOLS[3].rank * 90;
  rejuvenateEnvironmentAround(pos.x, pos.z, 48.0);
  spawnShockwave(pos, 0xf97316, 18.0, 0.9);
  spawnFloatingText(pos, '⛺ CAMPFIRE PITCHED! (+6/6 Vigor & Well-Fed)', '#fde047');
  showToast(`⛺ Campfire Pitched! Refilled 6/6 Vigor Orbs and healed nearby creatures for +${campHeal}!`);

  interactables.forEach((ent) => {
    if (ent.mesh.position.distanceTo(pos) <= 45.0) {
      applyRejuvenation(ent, campHeal, 'Campfire');
    }
  });
}

// ============================================================================
// 9. WOW CLASSIC LOOT WINDOW, REJUVENATION & GLOBAL COOLDOWN (GCD)
// ============================================================================
const targetRing = new THREE.Mesh(
  new THREE.RingGeometry(1.4, 1.75, 32).rotateX(-Math.PI / 2),
  new THREE.MeshBasicMaterial({ color: 0xfde047, side: THREE.DoubleSide, transparent: true, opacity: 0.9 })
);
targetRing.visible = false;
scene.add(targetRing);

const activeProjectiles = [];
const activeShockwaves = [];

function selectTarget(entity) {
  STATE.selectedTarget = entity;
  document.querySelectorAll('.nameplate').forEach((el) => el.classList.remove('selected'));
  if (!entity) {
    targetRing.visible = false;
    return;
  }
  if (entity.nameplateEl) entity.nameplateEl.classList.add('selected');
  targetRing.visible = true;
  updateTargetFrameUI();
}

function updateTargetFrameUI() {
  const t = STATE.selectedTarget;
  if (!t) return;
  document.getElementById('wow-target-icon').textContent = t.icon;
  document.getElementById('wow-target-name').textContent = t.name;
  const alt = Math.max(0, Math.round(t.mesh.position.y));
  document.getElementById('wow-target-diff').textContent = `${t.badge} (${alt}m)`;

  const hpPct = Math.min(100, Math.round((t.hp / t.maxHp) * 100));
  const blightPct = Math.max(0, 100 - hpPct);
  document.getElementById('wow-target-hp-bar').style.width = `${hpPct}%`;
  document.getElementById('wow-target-hp-txt').textContent =
    t.kind === 'chest'
      ? `${Math.round(t.hp)} / ${t.maxHp} Seal`
      : t.kind === 'shop_npc' || t.kind === 'town_npc'
      ? `Friendly Merchant / NPC`
      : `${Math.round(t.hp)} / ${t.maxHp} Vitality`;
  document.getElementById('wow-target-blight-bar').style.width = `${blightPct}%`;
  document.getElementById('wow-target-status-txt').textContent =
    t.kind === 'shop_npc' || t.kind === 'town_npc'
      ? '💬 Click or Right-Click to Interact / Open Shop'
      : t.rejuvenated
      ? '🌟 Rejuvenated • ToT: Sadhak'
      : `Right-Click or Cast [1] [2] • ToT: Sadhak`;
}

function openNPCInteraction(entity) {
  if (!entity) return;
  SFX.init();
  if (entity.greeting) {
    showToast(`💬 ${entity.name}: "${entity.greeting}"`);
    spawnFloatingText(entity.mesh.position, `💬 ${entity.badge}`, '#fde047');
  }
  if (entity.kind === 'shop_npc') {
    SFX.playLootCoinBag();
    if (entity.shopAction === 'shop') {
      toggleModal('shop-modal');
    } else if (entity.shopAction === 'apothecary') {
      STATE.vigor = STATE.maxVigor;
      STATE.trekStamina = 100;
      updateVigorOrbsUI();
      spawnShockwave(playerGroup.position, 0x34d399, 14.0, 0.7);
      spawnFloatingText(playerGroup.position, '🧪 +100% Vigor & Stamina Restored!', '#4ade80');
      toggleModal('shop-modal');
    } else if (entity.shopAction === 'mounts') {
      openInspectorModal('mounts');
    } else if (entity.shopAction === 'innkeeper') {
      STATE.wellFedTimer = 60.0;
      STATE.vigor = STATE.maxVigor;
      SFX.setZoneMusic(STATE.currentContinent.id, true);
      updateVigorOrbsUI();
      spawnShockwave(playerGroup.position, 0xfde047, 14.0, 0.7);
      spawnFloatingText(playerGroup.position, '🍻 +60s Tavern Well-Fed Speed & Lute Music!', '#fde047');
    } else if (entity.shopAction === 'quests') {
      SFX.playQuestAccept();
      openInspectorModal('quests');
    } else if (entity.shopAction === 'bags') {
      openInspectorModal('bags');
    } else if (entity.shopAction === 'boating') {
      // Board the Royal Canal & Harbor Skiff right into the Harbor Bay!
      const c = entity.continent;
      playerGroup.position.set(c.x + 12.0, -1.45, c.z + 78.0);
      STATE.isBoating = true;
      STATE.isFlying = false;
      STATE.activeVehicle = 'none';
      updateVigorOrbsUI();
      spawnShockwave(playerGroup.position, 0x38bdf8, 14.0, 0.75);
      spawnFloatingText(playerGroup.position, '⛵ BOARDED ROYAL SAILBOAT SKIFF! Sail with [WASD]!', '#38bdf8');
      showToast('⛵ Boarded Royal Sailboat Skiff in the Harbor! Sail across the Canal & Sea with [WASD] or press [M] to Fast-Sail!');
    } else if (entity.shopAction === 'stagecoach') {
      // Board the Royal Stagecoach Carriage!
      if (STATE.activeVehicle === entity.id) {
        STATE.activeVehicle = 'none';
        showToast('🚖 Stepped off the Stagecoach onto the Highway.');
      } else {
        STATE.activeVehicle = entity.id;
        STATE.isFlying = false;
        STATE.isBoating = false;
        showToast('🚖 Boarded the Royal Stagecoach! Relax as it carries you along the Grand Highway!');
        spawnShockwave(playerGroup.position, 0xfde047, 8.0, 0.5);
      }
    }
  } else if (entity.kind === 'town_npc') {
    if (entity.questMarker && !entity.questCompleted) {
      if (entity.questMarker === '❗') {
        entity.questMarker = '❓';
        if (entity.npQuestEl) {
          entity.npQuestEl.textContent = '❓';
          entity.npQuestEl.style.color = '#38bdf8';
        }
        SFX.playQuestAccept();
        const qGain = earnKarma(65 * entity.continent.diffMult);
        spawnShockwave(entity.mesh.position, 0xfde047, 8.5, 0.6);
        spawnFloatingText(entity.mesh.position, `📜 QUEST ACCEPTED! (+${qGain} ☸️ Karma)`, '#fde047');
        showToast(`📜 Quest Accepted from ${entity.name}! Click again or heal nearby wildlife to Complete [❓]!`);
      } else {
        entity.questCompleted = true;
        entity.questMarker = '🌟';
        if (entity.npQuestEl) {
          entity.npQuestEl.textContent = '🌟';
          entity.npQuestEl.style.color = '#4ade80';
        }
        SFX.playQuestComplete();
        const qReward = earnKarma(145 * entity.continent.diffMult);
        STATE.vigor = STATE.maxVigor;
        updateVigorOrbsUI();
        rejuvenateEnvironmentAround(entity.mesh.position.x, entity.mesh.position.z, 55.0);
        spawnShockwave(playerGroup.position, 0x34d399, 16.0, 0.85);
        spawnFloatingText(playerGroup.position, `🏆 QUEST COMPLETE! +${qReward} ☸️ Karma!`, '#4ade80');
        showToast(`🏆 Quest Completed for ${entity.name}! Earned +${qReward} ☸️ Karma & 6/6 Mount Vigor!`);
      }
      return;
    }
    SFX.playLootCoinBag();
    if (entity.npcRole === 'quests') {
      SFX.playQuestAccept();
      openInspectorModal('quests');
    } else if (entity.npcRole === 'bags') {
      openInspectorModal('bags');
    } else if (entity.npcRole === 'bard') {
      SFX.setZoneMusic(STATE.currentContinent.id, true);
      showToast(`🎵 ${entity.name} plays the lively Kingdom Bazaar Street Lute & Flute Melody!`);
      spawnFloatingText(entity.mesh.position, '🎵 Playing Street Lute Jig!', '#fde047');
    } else {
      showToast(`🦊 ${entity.name}: "Welcome to our Kingdom! Explore the Royal Citadel, Village Houses, and Mountain Roadway!"`);
      spawnFloatingText(entity.mesh.position, '🏰 Safe Travels in the Kingdom!', '#38bdf8');
    }
  }
}

// WoW Classic Right-Click Loot Popup Window
function openWoWLootWindow(entity) {
  if (!entity || entity.kind !== 'chest') return;
  SFX.playLootCoinBag();
  STATE.pendingLootEntity = entity;

  if (STATE.settings.autoLoot) {
    claimChestLoot(entity);
    return;
  }

  const cont = entity.continent;
  document.getElementById('loot-box-title').textContent = entity.name;
  const list = document.getElementById('loot-items-list');
  list.innerHTML = `
    <div class="loot-slot" id="loot-row-1">
      <span>👑</span>
      <span>${cont.relicName} (+15% Karma Power)</span>
    </div>
    <div class="loot-slot" id="loot-row-2">
      <span>☸️</span>
      <span>${cont.karmaReward * 2} Karma Points Pouch</span>
    </div>
    <div class="loot-slot" id="loot-row-3">
      <span>🧪</span>
      <span>Mountain Soma Draught (+6/6 Vigor)</span>
    </div>
  `;
  list.querySelectorAll('.loot-slot').forEach((row) => {
    row.addEventListener('click', () => claimChestLoot(entity));
  });
  document.getElementById('loot-modal').classList.remove('wow-modal-hidden');
}

function claimChestLoot(entity) {
  document.getElementById('loot-modal').classList.add('wow-modal-hidden');
  if (!entity) return;
  SFX.playLootCoinBag();
  if (!entity.rejuvenated) {
    BACKPACK_ITEMS.push({
      icon: '👑',
      name: entity.continent.relicName,
      desc: `Looted from ${entity.name} in ${entity.continent.shortName}.`,
      action: 'relic',
    });
    applyRejuvenation(entity, entity.maxHp, 'Looted');
  }
}

function spawnFloatingText(worldPos, text, color = '#4ade80') {
  const v = worldPos.clone();
  v.y += 2.6;
  v.project(camera);
  if (v.z > 1) return;
  const x = (v.x * 0.5 + 0.5) * window.innerWidth;
  const y = (-(v.y * 0.5) + 0.5) * window.innerHeight;

  const el = document.createElement('div');
  el.className = 'float-text';
  el.style.left = `${x}px`;
  el.style.top = `${y}px`;
  el.style.color = color;
  el.textContent = text;
  document.getElementById('floating-text-container').appendChild(el);
  setTimeout(() => el.remove(), 1300);
}

function spawnShockwave(pos, colorHex, maxRadius = 12.0, duration = 0.85) {
  const geo = new THREE.RingGeometry(0.45, 0.9, 40).rotateX(-Math.PI / 2);
  const mat = new THREE.MeshBasicMaterial({
    color: colorHex,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0.85,
  });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.copy(pos);
  mesh.position.y = Math.max(-1.0, getTerrainHeight(pos.x, pos.z)) + 0.35;
  scene.add(mesh);
  activeShockwaves.push({ mesh, elapsed: 0, duration, maxRadius });
}

function earnKarma(baseAmount) {
  const gain = Math.round(baseAmount * getKarmaMultiplier());
  STATE.karma += gain;
  STATE.lifetimeKarma += gain;
  updateAllHUD();
  return gain;
}

function rejuvenateEnvironmentAround(x, z, radius = 64.0) {
  addRejuvenationZone(x, z, radius);
  continentTrees.forEach((tr) => {
    if (!tr.rejuvenated && Math.hypot(tr.x - x, tr.z - z) <= radius) {
      tr.rejuvenated = true;
      tr.meshes.forEach((m) => (m.material = tr.targetLushMat));
      tr.crownGroup.scale.setScalar(1.15);
    }
  });
}

function applyRejuvenation(entity, rawAmount, spellLabel) {
  const prevHp = entity.hp;
  entity.hp = Math.min(entity.maxHp, entity.hp + rawAmount);
  if (entity.npFillEl) {
    entity.npFillEl.style.width = `${(entity.hp / entity.maxHp) * 100}%`;
  }

  SFX.playHealImpact();
  spawnFloatingText(entity.mesh.position, `+${rawAmount} ${spellLabel}`, '#4ade80');
  spawnShockwave(entity.mesh.position, 0x34d399, 4.2, 0.5);

  if (prevHp < entity.maxHp) {
    const pulseKarma = earnKarma(Math.round(18 * entity.continent.diffMult));
    spawnFloatingText(
      entity.mesh.position.clone().add(new THREE.Vector3(0, 1.1, 0)),
      `+${pulseKarma} ☸️ Karma`,
      '#fde047'
    );
  }

  if (entity.hp >= entity.maxHp && !entity.rejuvenated) {
    entity.rejuvenated = true;
    if (entity.nameplateEl) entity.nameplateEl.classList.add('rejuvenated');
    if (entity.npFillEl) entity.npFillEl.classList.add('rejuvenated');
    if (entity.blightRing) entity.blightRing.material.color.setHex(0x22c55e);

    if (entity.kind === 'chest') {
      STATE.relicsLooted += 1;
      if (entity.mesh._chest && entity.mesh._chest._lid) {
        entity.mesh._chest._lid.rotation.x = -0.85;
      }
      SFX.playWoWLevelUpFanfare();
      const chestKarma = earnKarma(entity.continent.karmaReward * 2);
      showToast(`🎁 Looted ${entity.name}! +${chestKarma} ☸️ Karma & ${entity.continent.relicName} added to Bags [B]!`);
    } else {
      earnKarma(entity.continent.karmaReward);
    }

    rejuvenateEnvironmentAround(entity.mesh.position.x, entity.mesh.position.z, 76.0);

    const cont = entity.continent;
    cont.rejuvenatedCount = Math.min(cont.goalCount, cont.rejuvenatedCount + 1);
    STATE.totalRejuvenated += 1;

    if (cont.rejuvenatedCount >= cont.goalCount && !cont.completed) {
      cont.completed = true;
      STATE.ascensionStage = Math.min(7, STATE.ascensionStage + 1);
      rejuvenateEnvironmentAround(cont.x, cont.z, cont.radius * 1.25);

      SFX.playWoWLevelUpFanfare();

      document.getElementById('gift-tier').textContent = `🏔️ REGION ${cont.roman} REBORN • VIRTUOUS BOON ATTAINED`;
      document.getElementById('gift-icon').textContent = cont.boonIcon;
      document.getElementById('gift-title').textContent = cont.boonName;
      document.getElementById('gift-desc').textContent = `You conquered ${cont.name} (${cont.realMeters.toLocaleString()}m)! ${cont.boonDesc}`;
      document.getElementById('gift-modal').classList.remove('wow-modal-hidden');
    }
  }

  updateAllHUD();
  if (STATE.selectedTarget === entity) updateTargetFrameUI();
}

// ============================================================================
// 10. HOTBAR SPELLS WITH 1.5s WOW GLOBAL COOLDOWN (GCD)
// ============================================================================
function updateVigorOrbsUI() {
  const fullOrbs = Math.floor(STATE.vigor);
  const orbs = document.querySelectorAll('#vigor-orbs-row .v-orb');
  orbs.forEach((el, idx) => {
    el.classList.toggle('full', idx < fullOrbs);
  });

  const mountNameEl = document.getElementById('vigor-mount-name');
  const statusEl = document.getElementById('vigor-status-txt');
  const badgeEl = document.getElementById('wow-mount-badge');

  if (STATE.isBoating) {
    mountNameEl.textContent = '⛵ ROYAL HARBOR SKIFF (SAILING)';
    statusEl.textContent = 'Sailing Canal & Sea ([WASD] Steer • [Space] Fly)';
    badgeEl.textContent = '⛵ Sailing Skiff';
  } else if (!STATE.isMounted) {
    mountNameEl.textContent = '🥾 ON FOOT ([Z] TO MOUNT)';
    statusEl.textContent = 'Press [Z] to Mount Up';
    badgeEl.textContent = STATE.isSitting ? '🧘 Sitting' : '🥾 On Foot';
  } else if (STATE.isFlying) {
    mountNameEl.textContent = '🦅 PEGASUS FLIGHT (SEATED)';
    statusEl.textContent = `Flying (${fullOrbs}/6 Vigor • [X] Descend)`;
    badgeEl.textContent = '🦅 Flying (Seated)';
  } else {
    mountNameEl.textContent = '🐎 ASHVA STEED (SEATED)';
    statusEl.textContent = canFlyOnContinent(STATE.currentContinent)
      ? '[Space] Lift Off into Flight'
      : '🥾 No-Fly Peak (Gallop Up Trail!)';
    badgeEl.textContent = '🐎 Mounted (Seated)';
  }
}

function triggerGlobalCooldown() {
  STATE.gcd = 1.2;
  for (let s = 1; s <= 3; s++) {
    STATE.cooldowns[s] = Math.max(STATE.cooldowns[s], 1.2);
  }
}

function triggerActionSlot(slot) {
  SFX.init();
  if (STATE.cooldowns[slot] > 0) return;

  const healPwr = getHealPower();
  const aoeRad = getAoERadius();

  if (slot === 1) {
    let target = STATE.selectedTarget;
    if (!target || target.rejuvenated) {
      target = findNearestSufferingEntity() || STATE.selectedTarget;
      if (target) selectTarget(target);
    }
    if (!target) return;

    if (target.kind === 'chest' && !STATE.settings.autoLoot && target.hp + healPwr >= target.maxHp) {
      openWoWLootWindow(target);
      return;
    }

    triggerGlobalCooldown();
    SFX.playCastStart();
    const castDur = CONTINENTS[2].completed ? 0.25 : 0.38;
    STATE.casting = {
      name: target.kind === 'chest' ? `Unlocking ${target.name}...` : `Sanjeevani Bolt → ${target.name}`,
      duration: castDur,
      elapsed: 0,
      onComplete: () => {
        STATE.cooldowns[1] = STATE.cdMax[1];
        launchProjectile(playerGroup.position, target, healPwr, 0x34d399);
        if (CONTINENTS[4].completed) {
          interactables
            .filter((e) => e !== target && !e.rejuvenated && e.mesh.position.distanceTo(target.mesh.position) < 28)
            .slice(0, 2)
            .forEach((extra) => launchProjectile(target.mesh.position, extra, Math.round(healPwr * 0.75), 0x38bdf8));
        }
      },
    };
    document.getElementById('wow-castbar').classList.remove('cast-hidden');
    document.getElementById('cast-label').textContent = STATE.casting.name;
    return;
  }

  if (slot === 2) {
    triggerGlobalCooldown();
    STATE.cooldowns[2] = STATE.cdMax[2];
    SFX.playNovaWave();
    spawnShockwave(playerGroup.position, 0x38bdf8, aoeRad, 0.85);
    rejuvenateEnvironmentAround(playerGroup.position.x, playerGroup.position.z, aoeRad * 1.45);

    const aoeHeal = Math.round(healPwr * 0.9);
    let hits = 0;
    interactables.forEach((ent) => {
      if (ent.mesh.position.distanceTo(playerGroup.position) <= aoeRad + 8) {
        applyRejuvenation(ent, aoeHeal, 'Ganga Nova');
        hits++;
      }
    });
    if (hits === 0 && STATE.selectedTarget) {
      applyRejuvenation(STATE.selectedTarget, aoeHeal, 'Ganga Nova');
    }
    return;
  }

  if (slot === 3) {
    triggerGlobalCooldown();
    STATE.cooldowns[3] = STATE.cdMax[3];
    SFX.playNovaWave();
    let target = STATE.selectedTarget || findNearestSufferingEntity();
    if (target) {
      selectTarget(target);
      spawnShockwave(target.mesh.position, 0xfde047, 8.5, 0.75);
      applyRejuvenation(target, Math.round(healPwr * 1.45), 'Sunbeam');
    }
    return;
  }

  if (slot === 4) {
    STATE.cooldowns[4] = STATE.cdMax[4];
    STATE.speedRunActive = !STATE.speedRunActive;
    SFX.playMountWhinnyOrWingbeat();
    document.getElementById('slot-4').classList.toggle('active-aura', STATE.speedRunActive);
    spawnShockwave(playerGroup.position, 0xfacc15, 5.5, 0.45);
    showToast(STATE.speedRunActive ? '🥾 Trail-Sprint Active (+150% Speed)' : 'Normal Pace');
    return;
  }

  if (slot === 5) {
    if (STATE.vigor < 1.0) {
      showToast('⚠️ Need 1 Vigor Orb for Skyward Ascent! Pitch a Campfire [G] to refill Vigor.');
      return;
    }
    STATE.vigor = Math.max(0, STATE.vigor - 1.0);
    updateVigorOrbsUI();
    STATE.cooldowns[5] = STATE.cdMax[5];
    SFX.playMountWhinnyOrWingbeat();

    const forward = new THREE.Vector3(-Math.sin(cameraYaw), 0, -Math.cos(cameraYaw));
    playerGroup.position.addScaledVector(forward, 18.0);
    playerVelY = 30.0;
    isGrounded = false;
    if (STATE.isMounted && canFlyOnContinent(STATE.currentContinent)) {
      STATE.isFlying = true;
      playerGroup.position.y += 18.0;
    }

    spawnShockwave(playerGroup.position, 0x38bdf8, 6.5, 0.5);
    spawnFloatingText(playerGroup.position, '🚀 SKYWARD ASCENT!', '#38bdf8');
    return;
  }

  if (slot === 6) {
    STATE.cooldowns[6] = STATE.cdMax[6];
    pitchMountainCampfire();
  }
}

function findNearestSufferingEntity() {
  let best = null;
  let bestD = Infinity;
  interactables.forEach((ent) => {
    if (ent.rejuvenated || ent.kind === 'shop_npc' || ent.kind === 'town_npc') return;
    const d = ent.mesh.position.distanceTo(playerGroup.position);
    if (d < bestD) {
      bestD = d;
      best = ent;
    }
  });
  return best;
}

function launchProjectile(fromPos, target, healAmount, colorHex) {
  const orb = new THREE.Mesh(
    new THREE.SphereGeometry(0.42, 12, 12),
    new THREE.MeshBasicMaterial({ color: colorHex })
  );
  orb.position.copy(fromPos);
  orb.position.y += 1.8;
  scene.add(orb);
  activeProjectiles.push({ mesh: orb, target, healAmount, speed: 40.0 });
}

function travelToPeakBaseCamp(continentId) {
  const cont = CONTINENTS[continentId];
  if (!cont) return;
  SFX.playMountWhinnyOrWingbeat();
  closeAllModals();

  STATE.currentContinent = cont;
  STATE.isMounted = true;
  STATE.isFlying = false;
  document.getElementById('slot-mount').classList.add('active-aura');

  const groundY = getTerrainHeight(cont.x, cont.z + 10);
  playerGroup.position.set(cont.x, groundY, cont.z + 10);

  spawnShockwave(playerGroup.position, 0xfde047, 11.0, 0.75);
  showToast(`🗺️ Arrived at ${cont.name} (${cont.weatherLabel})!`);

  const chestTarget = interactables.find((e) => e.continent.id === cont.id && e.kind === 'chest' && !e.rejuvenated);
  const nextTarget = chestTarget || interactables.find((e) => e.continent.id === cont.id && !e.rejuvenated);
  if (nextTarget) selectTarget(nextTarget);
  updateVigorOrbsUI();
  updateAllHUD();
}

// ============================================================================
// 11. WOW WINDOWS: CHARACTER [C], MOUNTS [P], QUESTS [L], BAGS [B], FORGE [K], SETTINGS [Esc]
// ============================================================================
function closeAllModals() {
  ['shop-modal', 'worldmap-modal', 'settings-modal', 'inspector-modal', 'loot-modal', 'gift-modal'].forEach((id) => {
    const el = document.getElementById(id);
    if (el) el.classList.add('wow-modal-hidden');
  });
}

function openInspectorModal(mode) {
  SFX.playTargetClick();
  closeAllModals();
  const modal = document.getElementById('inspector-modal');
  const title = document.getElementById('insp-title');
  const sub = document.getElementById('insp-sub');
  const body = document.getElementById('insp-body');

  if (mode === 'char') {
    title.textContent = '👤 WOW CHARACTER SHEET ("PAPERDOLL") & STATS [C]';
    sub.textContent = `Sadhak — Level ${STATE.ascensionStage} Restoration Vaidya • Heal Power: ${getHealPower()} • Mount Speed: +${Math.round(
      getMountSpeedMult() * 100
    )}%`;
    body.innerHTML = SHOP_TOOLS.map(
      (it) => `
      <div class="shop-card">
        <div class="shop-top">
          <span class="shop-icon">${it.icon}</span>
          <div>
            <div class="shop-title">${it.name}</div>
            <div class="shop-rank">${it.category} • Rank ${it.rank}/${it.maxRank}</div>
          </div>
        </div>
        <div class="shop-bonus">${it.bonusText(it.rank)}</div>
      </div>
    `
    ).join('');
  } else if (mode === 'mounts') {
    title.textContent = '📖 SPELLBOOK & MOUNTS JOURNAL [P]';
    sub.textContent = 'Your character sits astride your mount automatically. Press [Z] to Mount/Dismount and [Space] to Fly!';
    body.innerHTML = `
      <div class="shop-card">
        <div class="shop-top"><span class="shop-icon">🐎</span><div><div class="shop-title">Golden Ashva Warsteed</div><div class="shop-rank">Ground &amp; Skyriding Mount [Z]</div></div></div>
        <div class="shop-desc">Seated astride saddle with golden Pegasus wings that unfurl when you press [Space] in flyable regions.</div>
        <button class="shop-buy-btn" id="btn-summon-ashva"><span>Summon / Dismount Now</span><span>[Z]</span></button>
      </div>
      <div class="shop-card">
        <div class="shop-top"><span class="shop-icon">🌿</span><div><div class="shop-title">Sanjeevani Bolt [1]</div><div class="shop-rank">Restoration • 1.5s GCD</div></div></div>
        <div class="shop-desc">Heals distressed mountain wildlife and unlocks Summit Treasure Chests for +${getHealPower()} Vitality.</div>
      </div>
      <div class="shop-card">
        <div class="shop-top"><span class="shop-icon">💧</span><div><div class="shop-title">Ganga Jal Nova [2]</div><div class="shop-rank">AoE Restoration • ${getAoERadius()}m</div></div></div>
        <div class="shop-desc">Releases an expanding ring of sacred river water that transforms blighted terrain into lush greenery.</div>
      </div>
    `;
    const mBtn = body.querySelector('#btn-summon-ashva');
    if (mBtn) mBtn.addEventListener('click', () => { closeAllModals(); toggleMountUp(); });
  } else if (mode === 'quests') {
    title.textContent = '📜 WOW CLASSIC QUEST LOG — 7 MOUNTAIN EXPEDITIONS [L]';
    sub.textContent = 'Climb or fly to each mountain summit, open its Treasure Chest, and heal distressed wildlife.';
    body.innerHTML = CONTINENTS.map(
      (c) => `
      <div class="shop-card">
        <div class="shop-top">
          <span class="shop-icon">${c.boonIcon}</span>
          <div>
            <div class="shop-title">${c.roman}. ${c.name}</div>
            <div class="shop-rank">${c.weatherLabel} • Progress: ${c.rejuvenatedCount}/${c.goalCount}</div>
          </div>
        </div>
        <div class="shop-desc">Summit Chest: <strong>${c.chestName}</strong> (${c.realMeters}m)</div>
        <div class="shop-bonus">Reward: ☸️ ${c.karmaReward} Karma &amp; ${c.boonName}</div>
        <button class="shop-buy-btn" data-q-fly="${c.id}"><span>Travel to Region</span><span>Embark</span></button>
      </div>
    `
    ).join('');
    body.querySelectorAll('[data-q-fly]').forEach((b) =>
      b.addEventListener('click', () => travelToPeakBaseCamp(parseInt(b.getAttribute('data-q-fly'), 10)))
    );
  } else if (mode === 'bags') {
    title.textContent = '🎒 16-SLOT TRAVELER’S BACKPACK & LOOTED RELICS [B]';
    sub.textContent = `☸️ ${STATE.karma.toLocaleString()} Karma Points • 🎁 ${STATE.relicsLooted}/7 Summit Relics Collected`;
    body.innerHTML = BACKPACK_ITEMS.map(
      (item, idx) => `
      <div class="shop-card">
        <div class="shop-top">
          <span class="shop-icon">${item.icon}</span>
          <div>
            <div class="shop-title">${item.name}</div>
            <div class="shop-rank">Backpack Slot #${idx + 1}</div>
          </div>
        </div>
        <div class="shop-desc">${item.desc}</div>
        <button class="shop-buy-btn" data-bag-act="${item.action}"><span>Use Item</span><span>Click</span></button>
      </div>
    `
    ).join('');
    body.querySelectorAll('[data-bag-act]').forEach((b) => {
      b.addEventListener('click', () => {
        const act = b.getAttribute('data-bag-act');
        closeAllModals();
        if (act === 'hearth') travelToPeakBaseCamp(0);
        else if (act === 'boat') {
          const c = STATE.currentContinent;
          playerGroup.position.set(c.x + 12.0, -1.45, c.z + 82.0);
          playerGroup.rotation.y = 0.25;
          cameraYaw = 0.25;
          STATE.isBoating = true;
          STATE.isFlying = false;
          updateVigorOrbsUI();
          showToast('⛵ Boarded Royal Canal & Harbor Skiff! Sail with [WASD] across the Harbor & Canals!');
        }
        else if (act === 'camp') pitchMountainCampfire();
        else if (act === 'mount') toggleMountUp();
        else triggerActionSlot(1);
      });
    });
  }

  modal.classList.remove('wow-modal-hidden');
}

function renderKarmaShopModal() {
  document.getElementById('shop-karma-balance').textContent = STATE.karma.toLocaleString();
  const grid = document.getElementById('shop-items-grid');

  grid.innerHTML = SHOP_TOOLS.map((item) => {
    const cost = Math.round(item.baseCost * Math.pow(item.costMult, item.rank));
    const isMax = item.rank >= item.maxRank;
    const canAfford = STATE.karma >= cost && !isMax;

    return `
      <div class="shop-card">
        <div class="shop-top">
          <div style="display:flex;align-items:center;gap:10px;">
            <span class="shop-icon">${item.icon}</span>
            <div>
              <div class="shop-title">${item.name}</div>
              <div class="shop-rank">${item.category} • ${item.isConsumable ? 'Instant' : `Rank ${item.rank}/${item.maxRank}`}</div>
            </div>
          </div>
        </div>
        <div class="shop-desc">${item.desc}</div>
        <div class="shop-bonus">${item.bonusText(item.rank)}</div>
        <button class="shop-buy-btn ${canAfford ? '' : 'disabled'}" data-shop-id="${item.id}">
          <span>${isMax ? 'MAX RANK FORGED' : item.isConsumable ? 'Invoke Elixir Now' : `Forge Rank ${item.rank + 1}`}</span>
          <span>☸️ ${isMax ? '—' : cost.toLocaleString()}</span>
        </button>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('.shop-buy-btn').forEach((btn) => {
    btn.addEventListener('click', () => purchaseShopItem(btn.getAttribute('data-shop-id')));
  });
}

function purchaseShopItem(itemId) {
  const item = SHOP_TOOLS.find((i) => i.id === itemId);
  if (!item || item.rank >= item.maxRank) return;
  const cost = Math.round(item.baseCost * Math.pow(item.costMult, item.rank));
  if (STATE.karma < cost) {
    SFX.playTargetClick();
    showToast(`⚠️ Need ☸️ ${cost} Karma Points to forge ${item.name}!`);
    return;
  }

  STATE.karma -= cost;
  item.rank += 1;
  SFX.playForgeAnvil();

  if (item.isConsumable) {
    STATE.vigor = STATE.maxVigor;
    updateVigorOrbsUI();
    spawnShockwave(playerGroup.position, 0xfde047, 65.0, 1.25);
    rejuvenateEnvironmentAround(playerGroup.position.x, playerGroup.position.z, 75.0);
    interactables.forEach((ent) => {
      if (ent.mesh.position.distanceTo(playerGroup.position) <= 68.0) {
        applyRejuvenation(ent, 340, 'Soma Elixir');
      }
    });
  } else {
    spawnShockwave(playerGroup.position, 0x38bdf8, 8.0, 0.6);
    spawnFloatingText(playerGroup.position, `🛠️ Forged ${item.name} (Rank ${item.rank})!`, '#fde047');
  }

  updateAllHUD();
  renderKarmaShopModal();
}

function renderWorldMapModal() {
  const grid = document.getElementById('continents-modal-grid');
  grid.innerHTML = CONTINENTS.map(
    (c) => `
    <div class="continent-card">
      <div class="cc-top">
        <span class="cc-title">${c.roman}. ${c.name}</span>
        <span class="cc-tier">${c.realMeters.toLocaleString()}m</span>
      </div>
      <div class="cc-desc">
        Biome Weather: <strong>${c.weatherLabel}</strong><br/>
        Rule: <strong style="color:${c.allowFlying ? '#38bdf8' : '#fb7185'}">${
          c.allowFlying ? '🦅 Flying Allowed [Space]' : '🥾 No-Fly Peak (Mounted Ground Trek)'
        }</strong> • Progress: <strong>${c.rejuvenatedCount}/${c.goalCount}</strong>
      </div>
      <div class="cc-boon">${c.boonIcon} ${c.boonName}: ${c.boonDesc}</div>
      <button class="cc-fly-btn" data-cont-id="${c.id}">
        <span>🐎 Travel to ${c.shortName}</span>
        <span>${c.completed ? '🏔️ Reborn' : 'Embark'}</span>
      </button>
    </div>
  `
  ).join('');

  grid.querySelectorAll('.cc-fly-btn').forEach((btn) => {
    btn.addEventListener('click', () => travelToPeakBaseCamp(parseInt(btn.getAttribute('data-cont-id'), 10)));
  });
}

function updateAllHUD() {
  const c = STATE.currentContinent;
  document.getElementById('wow-player-lvl').textContent = STATE.ascensionStage;
  document.getElementById('wow-player-hp-txt').textContent = `${Math.round(STATE.trekStamina)}% Stamina • Power: ${getHealPower()}`;
  document.getElementById('wow-player-mp-txt').textContent = `☸️ ${STATE.karma.toLocaleString()} KARMA • 🎁 ${STATE.relicsLooted}/7 RELICS`;
  document.getElementById('stat-karma').textContent = `${STATE.karma.toLocaleString()}☸️`;

  document.getElementById('hud-continent-name').textContent = `${c.roman}. ${c.name.toUpperCase()}`;
  document.getElementById('hud-weather-pill').textContent = c.weatherLabel;

  const ruleEl = document.getElementById('hud-fly-rule');
  const canFly = canFlyOnContinent(c);
  ruleEl.textContent = canFly
    ? '🦅 Flying Allowed ([Space] Fly Up • [X] Sit/Down • [Z] Mount)'
    : '🥾 Sacred No-Fly Zone (Mounted Ground Trek & Camp [G])';
  ruleEl.className = `fly-rule-pill ${canFly ? 'allowed' : 'nofly'}`;

  document.getElementById('wq-active-title').textContent = `REGION ${c.roman} • ${c.shortName.toUpperCase()}`;
  document.getElementById('wq-active-bar').style.width = `${(c.rejuvenatedCount / c.goalCount) * 100}%`;
  document.getElementById('wq-active-cnt').textContent = `${c.rejuvenatedCount}/${c.goalCount}`;

  const listEl = document.getElementById('wq-continents-list');
  listEl.innerHTML = CONTINENTS.map(
    (cont) => `
    <div class="wq-cont-item ${cont.id === c.id ? 'active-continent' : ''} ${cont.completed ? 'completed-continent' : ''}" data-goto-cont="${cont.id}">
      <span>${cont.boonIcon} ${cont.shortName}</span>
      <span class="wq-c-stat">${cont.completed ? '🌟' : `${cont.rejuvenatedCount}/${cont.goalCount}`}</span>
    </div>
  `
  ).join('');

  listEl.querySelectorAll('.wq-cont-item').forEach((row) => {
    row.addEventListener('click', () => travelToPeakBaseCamp(parseInt(row.getAttribute('data-goto-cont'), 10)));
  });

  const worldPct = Math.min(100, (STATE.totalRejuvenated / STATE.totalSites) * 100);
  const conqueredPeaks = CONTINENTS.filter((ct) => ct.completed).length;
  document.getElementById('wow-rep-fill').style.width = `${worldPct}%`;
  document.getElementById('wow-rep-label').textContent = `WORLD RENEWAL: ${STATE.totalRejuvenated} / ${STATE.totalSites} Objectives • ${conqueredPeaks}/7 Weather Regions Reborn • 🎁 ${STATE.relicsLooted} Relics`;
}

// ============================================================================
// 12. INPUT CONTROLS, 100% WOW CLASSIC MOUSE CAMERA/STEERING & KEYBINDS
//    • Left-Click Drag (LMB): Free-orbit camera 360° Yaw & Full Up/Down Pitch (-82° to +85°)
//    • Right-Click Drag (RMB): Mouselook + Steer Character/Mount facing direction
//    • LMB + RMB Held Together: WoW Dual-Mouse-Button Forward Run/Fly!
//    • Scroll Wheel: Smooth Zoom from 3.5m up to 65m
// ============================================================================
function lerpAngle(current, target, factor) {
  let diff = ((target - current + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (diff < -Math.PI) diff += Math.PI * 2;
  return current + diff * Math.min(1.0, factor);
}

const keys = {};
let cameraYaw = 0;
let cameraPitch = 0.04;
let cameraDist = 17.5;
let isLeftMouseDown = false;
let isRightMouseDown = false;
let isDragging = false;
let prevMouse = { x: 0, y: 0 };
let playerVelY = 0;
let isGrounded = true;

window.addEventListener('contextmenu', (e) => e.preventDefault());

window.addEventListener('keydown', (e) => {
  SFX.init();
  const k = e.key.toLowerCase();
  keys[k] = true;

  if (e.key === 'Escape') {
    const anyOpen = ['shop-modal', 'worldmap-modal', 'inspector-modal', 'loot-modal', 'gift-modal'].some(
      (id) => !document.getElementById(id).classList.contains('wow-modal-hidden')
    );
    if (anyOpen) {
      closeAllModals();
    } else {
      const sm = document.getElementById('settings-modal');
      sm.classList.toggle('wow-modal-hidden');
    }
    return;
  }

  if (e.key === 'Tab') {
    e.preventDefault();
    SFX.playTargetClick();
    const near = findNearestSufferingEntity();
    if (near) selectTarget(near);
  } else if (e.key === '1') triggerActionSlot(1);
  else if (e.key === '2') triggerActionSlot(2);
  else if (e.key === '3') triggerActionSlot(3);
  else if (e.key === '4') triggerActionSlot(4);
  else if (e.key === '5') triggerActionSlot(5);
  else if (k === 'g') triggerActionSlot(6);
  else if (k === 'z' || k === 'f') toggleMountUp();
  else if (k === 'x') toggleSitOrDescend();
  else if (e.key === '`' || e.key === '~' || e.key === 'NumLock') toggleAutoRun();
  else if (k === 'c') openInspectorModal('char');
  else if (k === 'p') openInspectorModal('mounts');
  else if (k === 'l') openInspectorModal('quests');
  else if (k === 'b') openInspectorModal('bags');
  else if (k === 'k') toggleModal('shop-modal');
  else if (k === 'm') toggleModal('worldmap-modal');
  else if (e.key === 'Enter') {
    closeAllModals();
  } else if (e.key === ' ') {
    // If Loot Modal is open, Space takes all loot!
    if (!document.getElementById('loot-modal').classList.contains('wow-modal-hidden')) {
      claimChestLoot(STATE.pendingLootEntity);
      return;
    }
    // If Mounted in a Flyable Region, Space lifts off into 3D Flight!
    if (STATE.isMounted && canFlyOnContinent(STATE.currentContinent)) {
      if (!STATE.isFlying) {
        STATE.isFlying = true;
        SFX.playMountWhinnyOrWingbeat();
        playerGroup.position.y += 4.5;
        updateVigorOrbsUI();
        showToast('🦅 Lifted Off into 3D Flight! Hold [Space] to Ascend, [X] to Descend, [WASD] to Soar!');
      }
    } else if (isGrounded) {
      SFX.playMountWhinnyOrWingbeat();
      playerVelY = 18.0;
      isGrounded = false;
    }
  }
});

window.addEventListener('keyup', (e) => {
  keys[e.key.toLowerCase()] = false;
});

function toggleModal(id) {
  SFX.playTargetClick();
  const el = document.getElementById(id);
  if (!el) return;
  const hidden = el.classList.contains('wow-modal-hidden');
  closeAllModals();
  if (hidden) {
    if (id === 'shop-modal') renderKarmaShopModal();
    if (id === 'worldmap-modal') renderWorldMapModal();
    el.classList.remove('wow-modal-hidden');
  }
}

for (let s = 1; s <= 6; s++) {
  const el = document.getElementById(`slot-${s}`);
  if (el) el.addEventListener('click', () => triggerActionSlot(s));
}
document.getElementById('slot-mount').addEventListener('click', () => toggleMountUp());
document.getElementById('slot-sit').addEventListener('click', () => toggleSitOrDescend());
document.getElementById('slot-autorun').addEventListener('click', () => toggleAutoRun());

document.getElementById('btn-char').addEventListener('click', () => openInspectorModal('char'));
document.getElementById('btn-spells').addEventListener('click', () => openInspectorModal('mounts'));
document.getElementById('btn-quests').addEventListener('click', () => openInspectorModal('quests'));
document.getElementById('btn-bags').addEventListener('click', () => openInspectorModal('bags'));
document.getElementById('btn-shop').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('btn-worldmap').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('minimap-canvas').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('btn-settings').addEventListener('click', () => toggleModal('settings-modal'));

document.getElementById('btn-close-shop').addEventListener('click', closeAllModals);
document.getElementById('btn-close-map').addEventListener('click', closeAllModals);
document.getElementById('btn-close-settings').addEventListener('click', closeAllModals);
document.getElementById('btn-close-insp').addEventListener('click', closeAllModals);
document.getElementById('btn-close-loot').addEventListener('click', closeAllModals);
document.getElementById('btn-claim-gift').addEventListener('click', closeAllModals);
document.getElementById('btn-loot-all').addEventListener('click', () => claimChestLoot(STATE.pendingLootEntity));

// Wire Settings Menu Controls
document.getElementById('opt-sound-enable').addEventListener('change', (e) => {
  STATE.settings.soundEnabled = e.target.checked;
  SFX.setEnableSound(e.target.checked);
});
document.getElementById('opt-vol-master').addEventListener('input', (e) => {
  const v = parseInt(e.target.value, 10);
  STATE.settings.masterVol = v;
  document.getElementById('lbl-vol-master').textContent = `${v}%`;
  SFX.setVolume(v);
});
document.getElementById('opt-music-enable').addEventListener('change', (e) => {
  STATE.settings.musicEnabled = e.target.checked;
  SFX.setEnableMusic(e.target.checked);
});
document.getElementById('opt-bloom').addEventListener('input', (e) => {
  const b = parseInt(e.target.value, 10) / 100;
  STATE.settings.bloomStrength = b;
  bloomPass.strength = b;
  document.getElementById('lbl-bloom').textContent = b.toFixed(2);
});
document.getElementById('opt-weather-enable').addEventListener('change', (e) => {
  STATE.settings.weatherEnabled = e.target.checked;
});
document.getElementById('opt-shadows-enable').addEventListener('change', (e) => {
  STATE.settings.shadowsEnabled = e.target.checked;
  renderer.shadowMap.enabled = e.target.checked;
});
document.getElementById('opt-instant-mount').addEventListener('change', (e) => {
  STATE.settings.instantMount = e.target.checked;
});
document.getElementById('opt-autoloot').addEventListener('change', (e) => {
  STATE.settings.autoLoot = e.target.checked;
});
document.getElementById('opt-sticky-target').addEventListener('change', (e) => {
  STATE.settings.stickyTarget = e.target.checked;
});
document.getElementById('btn-hearthstone').addEventListener('click', () => {
  closeAllModals();
  travelToPeakBaseCamp(0);
});

const raycaster = new THREE.Raycaster();
const mouseNDC = new THREE.Vector2();

renderer.domElement.addEventListener('pointerdown', (e) => {
  SFX.init();
  if (e.button === 0) isLeftMouseDown = true;
  if (e.button === 2) isRightMouseDown = true;
  isDragging = true;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;

  mouseNDC.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouseNDC.y = -(e.clientY / window.innerHeight) * 2 + 1;
  raycaster.setFromCamera(mouseNDC, camera);

  let best = null;
  let bestD = 5.5;
  interactables.forEach((ent) => {
    const d = raycaster.ray.distanceToPoint(ent.mesh.position);
    if (d < bestD) {
      bestD = d;
      best = ent;
    }
  });
  if (best) {
    SFX.playTargetClick();
    selectTarget(best);
    if (best.kind === 'shop_npc' || best.kind === 'town_npc') {
      openNPCInteraction(best);
    } else if (e.button === 2 && best.kind === 'chest') {
      openWoWLootWindow(best);
    }
  } else if (!STATE.settings.stickyTarget && e.button === 0) {
    selectTarget(null);
  }
});

window.addEventListener('pointermove', (e) => {
  if (!isDragging && !isLeftMouseDown && !isRightMouseDown) return;
  const dx = e.clientX - prevMouse.x;
  const dy = e.clientY - prevMouse.y;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;

  // Full 360° Horizontal Orbit + Full Vertical Up/Down Camera Pitch (-82° look straight up at peaks to +85° top-down!)
  cameraYaw -= dx * 0.0068;
  cameraPitch = Math.max(-1.42, Math.min(1.48, cameraPitch + dy * 0.0062));

  // WoW Right-Mouse-Button (RMB) Mouselook immediately turns your character/mount to face camera direction!
  if (isRightMouseDown) {
    playerGroup.rotation.y = cameraYaw;
  }
});

window.addEventListener('pointerup', (e) => {
  if (e.button === 0) isLeftMouseDown = false;
  if (e.button === 2) isRightMouseDown = false;
  if (!isLeftMouseDown && !isRightMouseDown) {
    isDragging = false;
  }
});

window.addEventListener('wheel', (e) => {
  cameraDist = Math.max(3.5, Math.min(65.0, cameraDist + e.deltaY * 0.018));
});

// ============================================================================
// 13. RADAR & 3D FLOATING NAMEPLATES
// ============================================================================
const minimapCanvas = document.getElementById('minimap-canvas');
const mCtx = minimapCanvas.getContext('2d');

function drawMinimap() {
  const w = minimapCanvas.width;
  const h = minimapCanvas.height;
  const cx = w / 2;
  const cy = h / 2;
  const scale = STATE.isFlying ? 0.14 : 0.42;

  mCtx.clearRect(0, 0, w, h);
  mCtx.fillStyle = 'rgba(7, 16, 28, 0.52)';
  mCtx.beginPath();
  mCtx.arc(cx, cy, cx - 2, 0, Math.PI * 2);
  mCtx.fill();

  CONTINENTS.forEach((cont) => {
    const dx = (cont.x - playerGroup.position.x) * scale;
    const dz = (cont.z - playerGroup.position.z) * scale;
    const r = Math.max(9, cont.radius * scale * 0.7);
    if (Math.hypot(dx, dz) > cx + r) return;

    mCtx.fillStyle = cont.completed
      ? 'rgba(34, 197, 94, 0.42)'
      : cont.allowFlying
      ? 'rgba(14, 165, 233, 0.35)'
      : 'rgba(244, 63, 94, 0.35)';
    mCtx.beginPath();
    mCtx.arc(cx + dx, cy + dz, r, 0, Math.PI * 2);
    mCtx.fill();
  });

  interactables.forEach((ent) => {
    const sx = cx + (ent.mesh.position.x - playerGroup.position.x) * scale;
    const sz = cy + (ent.mesh.position.z - playerGroup.position.z) * scale;
    if (Math.hypot(sx - cx, sz - cy) > cx - 6) return;
    mCtx.fillStyle = ent.rejuvenated ? '#4ade80' : ent.kind === 'chest' ? '#fde047' : '#38bdf8';
    mCtx.beginPath();
    mCtx.arc(sx, sz, ent.kind === 'chest' ? 4.2 : 2.8, 0, Math.PI * 2);
    mCtx.fill();
  });

  mCtx.fillStyle = '#ffffff';
  mCtx.beginPath();
  mCtx.arc(cx, cy, 3.5, 0, Math.PI * 2);
  mCtx.fill();

  const curAlt = Math.max(0, Math.round(playerGroup.position.y));
  const scaledAlt = Math.min(
    STATE.currentContinent.realMeters,
    Math.round((curAlt / STATE.currentContinent.peakHeight) * STATE.currentContinent.realMeters)
  );
  document.getElementById('minimap-coords').textContent = `${Math.round(playerGroup.position.x)}, ${Math.round(
    playerGroup.position.z
  )} • Alt ${scaledAlt}m`;
  document.getElementById(
    'hud-altimeter'
  ).textContent = `⛰️ ${scaledAlt.toLocaleString()}m / ${STATE.currentContinent.realMeters.toLocaleString()}m`;
}

const projVec = new THREE.Vector3();
function updateWorldNameplates() {
  const halfW = window.innerWidth / 2;
  const halfH = window.innerHeight / 2;

  interactables.forEach((ent) => {
    if (!ent.nameplateEl) return;
    const dist = camera.position.distanceTo(ent.mesh.position);
    const maxNameDist = ent === STATE.selectedTarget ? 220 : ent.kind === 'shop_npc' || ent.kind === 'town_npc' ? 42 : 125;
    if (dist > maxNameDist) {
      ent.nameplateEl.style.display = 'none';
      return;
    }
    projVec.copy(ent.mesh.position);
    projVec.y += ent.heightOffset || 2.5;
    projVec.project(camera);
    if (projVec.z > 1.0) {
      ent.nameplateEl.style.display = 'none';
      return;
    }
    ent.nameplateEl.style.display = 'block';
    ent.nameplateEl.style.left = `${projVec.x * halfW + halfW}px`;
    ent.nameplateEl.style.top = `${-(projVec.y * halfH) + halfH}px`;
  });
}

// ============================================================================
// 14. MAIN 60FPS GAME LOOP (SEATED POSE, BIOME INTERPOLATION, WEATHER, FLIGHT)
// ============================================================================
const clock = new THREE.Clock();
let chakraTimer = 0;

setTimeout(() => {
  const firstChest = interactables.find((e) => e.continent.id === 0 && e.kind === 'chest');
  selectTarget(firstChest || interactables[0]);
  updateVigorOrbsUI();
  updateAllHUD();
}, 300);

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();

  oceanMat.uniforms.uTime.value = elapsed;
  terrainShaderMat.uniforms.uTime.value = elapsed;

  // Smoothly interpolate Sky, Horizon, Fog & Ground Biome Colors based on current Region!
  const targetBiome = STATE.currentContinent;
  skyMat.uniforms.uSkyTop.value.lerp(targetBiome.skyTopColor, dt * 2.2);
  skyMat.uniforms.uSkyHorizon.value.lerp(targetBiome.skyHorizonColor, dt * 2.2);
  terrainShaderMat.uniforms.uFogColor.value.lerp(targetBiome.fogColor, dt * 2.2);
  terrainShaderMat.uniforms.uGroundTint.value.lerp(targetBiome.groundTintColor, dt * 2.2);

  // Update 3D Weather Particles (Rain / Snow / Leaves / Blossoms / Mist / Starlight)
  updateWeatherParticles(dt, elapsed);

  for (let i = 0; i < MAX_CLEANSE_ZONES; i++) {
    const cz = cleanseCenters[i];
    if (cz.z < cz.w) {
      cz.z = Math.min(cz.w, cz.z + dt * 38.0);
    }
  }

  const vigorRegenRate = (0.35 + (SHOP_TOOLS[1].rank - 1) * 0.08) * (CONTINENTS[0].completed ? 1.4 : 1.0);
  if (STATE.vigor < STATE.maxVigor) {
    const prevFloor = Math.floor(STATE.vigor);
    STATE.vigor = Math.min(STATE.maxVigor, STATE.vigor + vigorRegenRate * dt);
    if (Math.floor(STATE.vigor) !== prevFloor) updateVigorOrbsUI();
  }

  if (STATE.wellFedTimer > 0) {
    STATE.wellFedTimer = Math.max(0, STATE.wellFedTimer - dt);
  }

  CONTINENTS.forEach((c) => {
    if (c.crystalMesh) {
      c.crystalMesh.rotation.y = elapsed * 1.4;
      c.crystalMesh.position.y = 2.6 + Math.sin(elapsed * 2.2) * 0.22;
    }
  });

  activeCampfires.forEach((cf) => {
    cf.fireOrb.scale.y = 0.9 + Math.sin(elapsed * 12.0 + cf.x) * 0.18;
  });

  // Flap Golden Pegasus Wings when mounted
  if (STATE.isMounted) {
    const flapSpeed = STATE.isFlying ? 9.5 : 3.2;
    const flapAmp = STATE.isFlying ? 0.45 : 0.12;
    const flap = Math.sin(elapsed * flapSpeed) * flapAmp;
    leftWing.rotation.z = flap;
    rightWing.rotation.z = -flap;
  }

  // Movement Input (100% Default WoW Keyboard Steering + Camera Follow + Mouse Control)
  // • [A / LeftArrow] & [D / RightArrow]: Turn BOTH Character & Viewing Angle (unless holding RMB, where A/D strafes)
  // • [Q] & [E]: Strafe Left / Right
  // • Moving forward/diagonally automatically rotates the viewing angle to follow your movement direction!
  let moveX = 0;
  let moveZ = 0;
  let turnDir = 0;
  const dualMouseRun = isLeftMouseDown && isRightMouseDown;

  if (keys['w'] || keys['arrowup'] || dualMouseRun) {
    moveZ -= 1;
    if (!dualMouseRun) STATE.autoRun = false;
  }
  if (keys['s'] || keys['arrowdown']) {
    moveZ += 1;
    STATE.autoRun = false;
  }
  if (STATE.autoRun) moveZ -= 1;

  if (isRightMouseDown) {
    // When holding Right-Mouse-Button, A/D strafes (authentic WoW behavior)
    if (keys['a'] || keys['arrowleft'] || keys['q']) moveX -= 1;
    if (keys['d'] || keys['arrowright'] || keys['e']) moveX += 1;
  } else {
    // Default Settings: [A / D / Left / Right] turns both character and viewing angle!
    if (keys['a'] || keys['arrowleft']) turnDir += 1;
    if (keys['d'] || keys['arrowright']) turnDir -= 1;
    if (keys['q']) moveX -= 1;
    if (keys['e']) moveX += 1;
  }

  if (turnDir !== 0) {
    const turnSpeed = 2.35 * dt;
    playerGroup.rotation.y += turnDir * turnSpeed;
    // Rotate viewing angle (cameraYaw) directly with turning direction unless LMB is free-looking!
    if (!isLeftMouseDown) {
      cameraYaw += turnDir * turnSpeed;
    }
  }

  const isMoving = moveX !== 0 || moveZ !== 0;

  if (isMoving) {
    STATE.isSitting = false;
    const len = Math.hypot(moveX, moveZ);
    moveX /= len;
    moveZ /= len;

    const speed = STATE.isFlying
      ? 54.0 * getMountSpeedMult()
      : STATE.isMounted
      ? 32.0 * getMountSpeedMult()
      : (STATE.speedRunActive ? 24.0 : 11.5) * getTrekSpeedMult();

    // If neither mouse button is held, move relative to character's current facing (or cameraYaw) and smoothly lock viewing angle behind movement direction!
    const refYaw = isRightMouseDown ? cameraYaw : playerGroup.rotation.y;
    const sinY = Math.sin(refYaw);
    const cosY = Math.cos(refYaw);
    const dx = moveX * cosY + moveZ * sinY;
    const dz = -moveX * sinY + moveZ * cosY;

    playerGroup.position.x += dx * speed * dt;
    playerGroup.position.z += dz * speed * dt;

    // Face character in movement direction (unless backpedaling with S)
    const moveHeading = Math.atan2(dx, dz) + Math.PI;
    if (moveZ <= 0) {
      playerGroup.rotation.y = lerpAngle(playerGroup.rotation.y, moveHeading, dt * 10.0);
    }

    // Default WoW Smart Camera Follow: moving automatically swings the viewing angle to align with your movement direction!
    if (!isLeftMouseDown && !isRightMouseDown) {
      const targetCamYaw = moveZ > 0 ? playerGroup.rotation.y : moveHeading;
      cameraYaw = lerpAngle(cameraYaw, targetCamYaw, dt * 6.5);
    }

    // RMB or Pitch-guided 3D Flight: when flying and holding RMB (or pitching up/down), fly directly along camera pitch!
    if (STATE.isMounted && STATE.isFlying && (isRightMouseDown || Math.abs(cameraPitch) > 0.22)) {
      const pitchClimb = -Math.sin(cameraPitch) * speed * 0.18 * dt;
      playerGroup.position.y = Math.max(
        getTerrainHeight(playerGroup.position.x, playerGroup.position.z) + 0.5,
        playerGroup.position.y + pitchClimb
      );
    }
    setPlayerAnim(STATE.isMounted ? 'Idle' : 'Run');
  } else {
    setPlayerAnim('Idle');
  }

  // Advance Skeletal Mixers & Apply Seated Astride Saddle Pose!
  if (mountAction) {
    mountAction.timeScale = isMoving || STATE.isFlying ? 1.15 : 0.0;
  }
  if (playerMixer) playerMixer.update(dt);
  if (mountMixer && (isMoving || STATE.isFlying)) mountMixer.update(dt);
  applySeatedRiderPose(elapsed, isMoving || STATE.isFlying);

  // Vertical Flight, Automatic Canal/Harbor Sailboat Boating & Realistic High-Altitude Thin-Air Resistance
  const rawGroundY = getTerrainHeight(playerGroup.position.x, playerGroup.position.z);
  const groundY = Math.max(-1.45, rawGroundY);
  const inWaterZone = rawGroundY < -1.65 && !STATE.isFlying;
  if (inWaterZone !== STATE.isBoating) {
    STATE.isBoating = inWaterZone;
    updateVigorOrbsUI();
    if (inWaterZone) {
      showToast('⛵ Boarded Royal Canal & Harbor Sailboat Skiff! Sail with [WASD] or press [Space] to Fly!');
    }
  }
  if (STATE.isMounted && STATE.isFlying) {
    const altAboveSea = Math.max(0, playerGroup.position.y);
    // In lower foothills (<65m), responsive lift-off; in thin alpine stratosphere, realistic 2.6m/s climb rate (~17 mins to 2,695m apex!)
    const thinAirFactor = altAboveSea < 65.0 ? 8.5 : Math.max(2.6, 5.2 - (altAboveSea / 650.0));
    if (keys[' ']) playerGroup.position.y += thinAirFactor * getMountSpeedMult() * dt;
    if (keys['x'] || keys['shift']) playerGroup.position.y -= 24.0 * dt;
    // Touching terrain transitions smoothly back to Mounted Ground Riding!
    if (playerGroup.position.y <= groundY + 0.4) {
      playerGroup.position.y = groundY;
      STATE.isFlying = false;
      updateVigorOrbsUI();
    }
  } else {
    playerVelY -= 32.0 * dt;
    playerGroup.position.y += playerVelY * dt;
    if (playerGroup.position.y <= groundY) {
      playerGroup.position.y = groundY;
      playerVelY = 0;
      isGrounded = true;
    }
  }

  // Detect Region Change, Switch Zone Instrumental Music & Enforce Sacred No-Fly Trekking Rule
  const nearCont = getNearestContinent(playerGroup.position.x, playerGroup.position.z);
  const distToTownStreet = Math.hypot(playerGroup.position.x - nearCont.x, playerGroup.position.z - nearCont.z);
  const inStreet = distToTownStreet < 32.0;

  if (nearCont !== STATE.currentContinent) {
    STATE.currentContinent = nearCont;
    SFX.setZoneMusic(nearCont.id, inStreet);
    SFX.playMountWhinnyOrWingbeat();
    if (STATE.isFlying && !canFlyOnContinent(nearCont)) {
      STATE.isFlying = false;
      showToast(`🥾 Entered Sacred No-Fly Region: ${nearCont.shortName}! Switched to Mounted Ground Trek.`);
    } else {
      showToast(`🗺️ Entered ${nearCont.name} (${nearCont.weatherLabel})`);
    }
    updateVigorOrbsUI();
    updateAllHUD();
  } else if (SFX.inBazaarStreet !== inStreet) {
    SFX.setZoneMusic(nearCont.id, inStreet);
  }

  // Sudarshana Chakra Auto-Pulse
  chakraTimer += dt;
  if (chakraTimer >= 1.4) {
    chakraTimer = 0;
    const chakraRank = SHOP_TOOLS[5].rank;
    if (chakraRank > 0 || CONTINENTS[6].completed) {
      const near = findNearestSufferingEntity();
      if (near && near.mesh.position.distanceTo(playerGroup.position) <= 38) {
        const autoAmt = chakraRank * 50 + (CONTINENTS[6].completed ? 130 : 0);
        launchProjectile(playerGroup.position, near, autoAmt, 0xfde047);
      }
    }
  }

  const px = playerGroup.position.x;
  const pz = playerGroup.position.z;

  // Animate 112 Randomly Soaring Birds Across the Skies & Mountain Peaks!
  for (let b = 0; b < ambientBirds.length; b++) {
    const bd = ambientBirds[b];
    if (bd.continent !== STATE.currentContinent) continue;
    const t = elapsed * bd.speed + bd.phase;
    const bx = bd.cx + Math.cos(t) * bd.orbitR + Math.sin(t * 2.3) * 14.0;
    const bz = bd.cz + Math.sin(t * 0.85) * bd.orbitR + Math.cos(t * 1.7) * 14.0;
    const by = bd.baseAlt + Math.sin(t * 1.6) * 6.5;
    const dxB = bx - bd.mesh.position.x;
    const dzB = bz - bd.mesh.position.z;
    bd.mesh.position.set(bx, by, bz);
    if (Math.abs(dxB) + Math.abs(dzB) > 0.001) {
      bd.mesh.rotation.y = Math.atan2(dxB, dzB);
    }
    const flap = Math.sin(elapsed * bd.flapSpeed + bd.phase) * 0.55;
    if (bd.mesh._lw) bd.mesh._lw.rotation.z = flap;
    if (bd.mesh._rw) bd.mesh._rw.rotation.z = -flap;
  }

  // Animate City Windmills & Maritime Harbor Galleons + Canal Gondola Skiffs!
  for (let w = 0; w < animatedWindmills.length; w++) {
    animatedWindmills[w].rotation.z = elapsed * 0.95;
  }
  for (let s = 0; s < animatedShips.length; s++) {
    const sh = animatedShips[s];
    if (sh.continent !== STATE.currentContinent) continue;
    const bob = Math.sin(elapsed * 2.1 + sh.phase) * 0.22;
    sh.mesh.rotation.z = Math.sin(elapsed * 1.6 + sh.phase) * 0.04;
    if (!sh.isCruising) {
      sh.mesh.position.y = -1.5 + bob;
    } else if (sh.isSkiff) {
      // Canal Gondola Skiff gliding back and forth along the East-West City Canal!
      const t = elapsed * sh.speed + sh.phase;
      const nx = sh.baseX + Math.sin(t) * sh.cruiseRadius;
      const dxS = nx - sh.mesh.position.x;
      sh.mesh.position.set(nx, -1.45 + bob * 0.6, sh.baseZ);
      if (Math.abs(dxS) > 0.001) {
        sh.mesh.rotation.y = dxS > 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
      }
    } else {
      // Offshore Tall-Mast Merchant Galleons sailing across the Harbor Bay!
      const t = elapsed * sh.speed + sh.phase;
      const nx = sh.baseX + Math.sin(t) * sh.cruiseRadius;
      const nz = sh.baseZ + Math.cos(t * 0.7) * 18.0;
      const dxS = nx - sh.mesh.position.x;
      const dzS = nz - sh.mesh.position.z;
      sh.mesh.position.set(nx, -1.5 + bob, nz);
      if (Math.abs(dxS) + Math.abs(dzS) > 0.001) {
        sh.mesh.rotation.y = Math.atan2(dxS, dzS);
      }
    }
  }

  // Animate Working City Transportation (Horse-Drawn Stagecoaches patrolling the Grand Highway!)
  for (let v = 0; v < animatedTransitVehicles.length; v++) {
    const veh = animatedTransitVehicles[v];
    if (veh.continent !== STATE.currentContinent) continue;
    if (veh.type === 'carriage') {
      const zRange = veh.zMax - veh.zMin;
      veh.progress = (veh.progress + (veh.speed / zRange) * dt) % 2.0;
      // Ping-pong travel back and forth along the highway
      const forward = veh.progress <= 1.0;
      const t = forward ? veh.progress : 2.0 - veh.progress;
      const curZ = veh.zMin + t * zRange;
      const curX = veh.mesh.position.x;
      const curY = getTerrainHeight(curX, curZ);
      veh.mesh.position.set(curX, curY, curZ);
      veh.mesh.rotation.y = forward ? 0 : Math.PI;

      // If player is currently riding this carriage, carry them seamlessly along the highway!
      if (STATE.activeVehicle === `carriage-${veh.continent.id}`) {
        playerGroup.position.set(curX, curY + 1.25, curZ);
        playerGroup.rotation.y = veh.mesh.rotation.y;
        if (!isLeftMouseDown && !isRightMouseDown) {
          cameraYaw = veh.mesh.rotation.y;
        }
      }
    }
  }

  interactables.forEach((ent) => {
    const distSq = (ent.mesh.position.x - px) ** 2 + (ent.mesh.position.z - pz) ** 2;
    // Skip CPU physics & skeletal updates for distant continents (>180m away)
    if (distSq > 32400) return;

    if (ent.mixer) ent.mixer.update(dt);
    if (ent.kind === 'wildlife') {
      ent.wanderAngle += dt * 0.55;
      const tx = ent.homeX + Math.cos(ent.wanderAngle) * 3.5;
      const tz = ent.homeZ + Math.sin(ent.wanderAngle * 0.8) * 3.5;
      const dx = tx - ent.mesh.position.x;
      const dz = tz - ent.mesh.position.z;
      ent.mesh.position.x += dx * dt;
      ent.mesh.position.z += dz * dt;
      ent.mesh.position.y = getTerrainHeight(ent.mesh.position.x, ent.mesh.position.z);
      ent.mesh.rotation.y = Math.atan2(dx, dz);
    } else if (ent.kind === 'town_npc') {
      if (ent.isRoadTrekker) {
        // Mountain Roadway Trekkers & Pilgrims walking steadily up the 3.5-Turn Spiral Roadway to the Summit!
        ent.roadProgress = (ent.roadProgress + dt * 0.0065) % 0.96;
        if (ent.roadProgress < 0.04) ent.roadProgress = 0.04;
        const { rx, rz } = getSpiralRoadPoint(ent.continent, ent.roadProgress);
        const dx = rx - ent.mesh.position.x;
        const dz = rz - ent.mesh.position.z;
        ent.mesh.position.x = rx;
        ent.mesh.position.z = rz;
        ent.mesh.position.y = getTerrainHeight(rx, rz);
        if (Math.abs(dx) + Math.abs(dz) > 0.001) {
          ent.mesh.rotation.y = Math.atan2(dx, dz);
        }
      } else {
        // Bustling Town Citizens, Bards & Guards patrolling along the Grand Bazaar Street & Flatlands!
        ent.wanderAngle += dt * 0.45;
        const r = ent.patrolRadius || 10.0;
        const tx = ent.homeX + Math.sin(ent.wanderAngle * 0.7) * (r * 0.35);
        const tz = ent.homeZ + Math.cos(ent.wanderAngle) * r;
        const dx = tx - ent.mesh.position.x;
        const dz = tz - ent.mesh.position.z;
        ent.mesh.position.x += dx * dt * 1.4;
        ent.mesh.position.z += dz * dt * 1.4;
        ent.mesh.position.y = getTerrainHeight(ent.mesh.position.x, ent.mesh.position.z);
        ent.mesh.rotation.y = Math.atan2(dx, dz);
      }
      if (ent.mesh._robeWalker) {
        const w = ent.mesh._robeWalker;
        const stride = Math.sin(elapsed * 8.5 + ent.wanderAngle) * 0.45;
        w.position.y = Math.abs(Math.sin(elapsed * 8.5 + ent.wanderAngle)) * 0.11;
        if (w._armL) w._armL.rotation.x = stride;
        if (w._armR) w._armR.rotation.x = -stride;
        if (w._legL) w._legL.rotation.x = -stride;
        if (w._legR) w._legR.rotation.x = stride;
        if (w._questGem) w._questGem.rotation.y = elapsed * 2.4;
      }
      if (ent.mesh._questGem) {
        ent.mesh._questGem.rotation.y = elapsed * 2.4;
      }
    } else if (ent.kind === 'chest' && !ent.rejuvenated) {
      ent.mesh.rotation.y = Math.sin(elapsed * 1.5) * 0.15;
    }
  });

  if (STATE.selectedTarget) {
    targetRing.position.copy(STATE.selectedTarget.mesh.position);
    targetRing.position.y = getTerrainHeight(targetRing.position.x, targetRing.position.z) + 0.2;
    targetRing.rotation.z = elapsed * 2.0;
  }

  if (STATE.casting) {
    if (isMoving) {
      STATE.casting = null;
      document.getElementById('wow-castbar').classList.add('cast-hidden');
      showToast('⚠️ Interrupted (Moving)');
    } else {
      STATE.casting.elapsed += dt;
      const pct = Math.min(100, (STATE.casting.elapsed / STATE.casting.duration) * 100);
      document.getElementById('cast-fill').style.width = `${pct}%`;
      document.getElementById('cast-timer').textContent = `${Math.max(
        0,
        STATE.casting.duration - STATE.casting.elapsed
      ).toFixed(1)}s`;
      if (STATE.casting.elapsed >= STATE.casting.duration) {
        const done = STATE.casting.onComplete;
        STATE.casting = null;
        document.getElementById('wow-castbar').classList.add('cast-hidden');
        if (done) done();
      }
    }
  }

  for (let s = 1; s <= 7; s++) {
    if (STATE.cooldowns[s] > 0) {
      STATE.cooldowns[s] = Math.max(0, STATE.cooldowns[s] - dt);
      const cdEl = document.getElementById(`cd-${s}`);
      if (cdEl) cdEl.style.height = `${(STATE.cooldowns[s] / STATE.cdMax[s]) * 100}%`;
    }
  }

  for (let i = activeProjectiles.length - 1; i >= 0; i--) {
    const p = activeProjectiles[i];
    const tPos = p.target.mesh.position.clone();
    tPos.y += 1.3;
    const dir = tPos.sub(p.mesh.position);
    if (dir.length() < 1.1) {
      scene.remove(p.mesh);
      activeProjectiles.splice(i, 1);
      applyRejuvenation(p.target, p.healAmount, 'Sanjeevani');
    } else {
      dir.normalize();
      p.mesh.position.addScaledVector(dir, p.speed * dt);
    }
  }

  for (let i = activeShockwaves.length - 1; i >= 0; i--) {
    const sw = activeShockwaves[i];
    sw.elapsed += dt;
    const t = sw.elapsed / sw.duration;
    if (t >= 1.0) {
      scene.remove(sw.mesh);
      activeShockwaves.splice(i, 1);
    } else {
      const sc = 1.0 + t * sw.maxRadius;
      sw.mesh.scale.set(sc, sc, 1);
      sw.mesh.material.opacity = (1.0 - t) * 0.78;
    }
  }

  // True WoW Spherical Orbit Camera around Rider's Head/Shoulders (Look Up at Peaks or Down at Streets at ANY Angle!)
  const pivotY = playerGroup.position.y + 3.0;
  const camX = playerGroup.position.x + Math.sin(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camZ = playerGroup.position.z + Math.cos(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const rawCamY = pivotY + Math.sin(cameraPitch) * cameraDist;
  const minCamY = getTerrainHeight(camX, camZ) + 0.85;

  camera.position.set(camX, Math.max(rawCamY, minCamY), camZ);
  // Look through the rider pivot along the exact pitch & yaw vector so looking straight up (-82°) aims at the mountain peaks!
  const lookTarget = new THREE.Vector3(
    playerGroup.position.x - Math.sin(cameraYaw) * 6.0,
    pivotY - Math.sin(cameraPitch) * 6.0,
    playerGroup.position.z - Math.cos(cameraYaw) * 6.0
  );
  camera.lookAt(lookTarget);

  updateWorldNameplates();
  drawMinimap();
  composer.render();
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  composer.setSize(window.innerWidth, window.innerHeight);
  bloomPass.setSize(Math.floor(window.innerWidth * 0.5), Math.floor(window.innerHeight * 0.5));
});

animate();
