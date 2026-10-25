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
// 1. POLYPHONIC WEB AUDIO API WOW ORCHESTRAL & SPATIAL SOUND ENGINE
// ============================================================================
class WoWSoundEngine {
  constructor() {
    this.ctx = null;
    this.muted = false;
    this.musicEnabled = true;
    this.ambientStarted = false;
    this.masterGain = null;
    this.musicGain = null;
    this.reverbNode = null;
    this.masterVol = 0.42;
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
    const length = rate * duration;
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
    this.masterVol = (pct / 100) * 0.6;
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

  startAmbientSoundscape() {
    if (this.ambientStarted || !this.ctx) return;
    this.ambientStarted = true;

    const freqs = [73.42, 110.0, 185.0, 220.0, 329.63];
    freqs.forEach((f, idx) => {
      const osc = this.ctx.createOscillator();
      const filter = this.ctx.createBiquadFilter();
      const gain = this.ctx.createGain();
      osc.type = idx % 2 === 0 ? 'sine' : 'triangle';
      osc.frequency.value = f;
      filter.type = 'lowpass';
      filter.frequency.value = 400 + idx * 80;
      gain.gain.value = 0.028;

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(this.musicGain);
      osc.start();
    });
    this.musicGain.connect(this.masterGain);

    setInterval(() => {
      if (this.muted || !this.musicEnabled || !this.ctx || this.ctx.state !== 'running') return;
      const scale = [293.66, 329.63, 369.99, 440.0, 493.88, 587.33, 659.25];
      const f = scale[Math.floor(Math.random() * scale.length)];
      this.playTone(f, 'sine', 1.8, 0.04, 0.08);
    }, 4500);
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
}

const SFX = new WoWSoundEngine();

// ============================================================================
// 2. THE 7 DISTINCT WEATHER & BIOME REGIONS OF THE WORLD
//    Each region features a Colossal Multi-Peak Mountain Range (Not a Hill!)
//    Towering 2,600+ to 4,800+ vertical units (15+ minutes of sustained flight to reach True Apex!)
// ============================================================================
const CONTINENTS = [
  {
    id: 0,
    roman: 'I',
    name: 'Lush Greenery — Western Ghats (Sahyadri Escarpment)',
    shortName: 'I. Greenery (Sahyadri)',
    weather: 'petals',
    weatherLabel: '🌿 Lush Blossoms & Emerald Breeze',
    skyTopColor: new THREE.Color(0x0d3b66),
    skyHorizonColor: new THREE.Color(0x7dd3fc),
    fogColor: new THREE.Color(0x68b5e8),
    groundTintColor: new THREE.Color(0x22c55e),
    x: 0,
    z: 0,
    radius: 680,
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
    weatherLabel: '🌧️ Heavy Monsoon Downpour',
    skyTopColor: new THREE.Color(0x0f172a),
    skyHorizonColor: new THREE.Color(0x334155),
    fogColor: new THREE.Color(0x3b4f6b),
    groundTintColor: new THREE.Color(0x15803d),
    x: 0,
    z: -1650,
    radius: 680,
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
    weatherLabel: '🍂 Drifting Golden Autumn Leaves',
    skyTopColor: new THREE.Color(0x3b1d5e),
    skyHorizonColor: new THREE.Color(0xf59e0b),
    fogColor: new THREE.Color(0xd97706),
    groundTintColor: new THREE.Color(0xd97706),
    x: 1550,
    z: -950,
    radius: 680,
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
    weatherLabel: '❄️ Swirling Alpine Blizzard Snow',
    skyTopColor: new THREE.Color(0x1e293b),
    skyHorizonColor: new THREE.Color(0xcbd5e1),
    fogColor: new THREE.Color(0xb8c9dc),
    groundTintColor: new THREE.Color(0xe2e8f0),
    x: 1550,
    z: 950,
    radius: 680,
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
    weatherLabel: '🌫️ Floating Jade Spirit Mist',
    skyTopColor: new THREE.Color(0x064e3b),
    skyHorizonColor: new THREE.Color(0x6ee7b7),
    fogColor: new THREE.Color(0x52b788),
    groundTintColor: new THREE.Color(0x10b981),
    x: 0,
    z: 1650,
    radius: 680,
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
    weatherLabel: '🌨️ High-Altitude Khumbu Gale Snow',
    skyTopColor: new THREE.Color(0x0c4a6e),
    skyHorizonColor: new THREE.Color(0xbae6fd),
    fogColor: new THREE.Color(0x93c5fd),
    groundTintColor: new THREE.Color(0xf1f5f9),
    x: -1550,
    z: 950,
    radius: 720,
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
    weatherLabel: '✨ Rising Golden Starlight',
    skyTopColor: new THREE.Color(0x1e1b4b),
    skyHorizonColor: new THREE.Color(0xfde047),
    fogColor: new THREE.Color(0xc084fc),
    groundTintColor: new THREE.Color(0xfacc15),
    x: -1550,
    z: -950,
    radius: 720,
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
  isSitting: false, // Toggled with [X] when unmounted
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
  return mult;
}
function getTrekSpeedMult() {
  let mult = 1.0 + (SHOP_TOOLS[2].rank - 1) * 0.25;
  if (CONTINENTS[1].completed) mult += 0.4;
  if (STATE.wellFedTimer > 0) mult += 0.25;
  return mult;
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
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.08;
container.appendChild(renderer.domElement);

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloomPass = new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  0.38,
  0.55,
  0.78
);
composer.addPass(bloomPass);

// Dynamic Biome Sky Dome (Smoothly transitions sky zenith & horizon colors across the 7 Weather Regions!)
const skyGeo = new THREE.SphereGeometry(12000, 32, 24);
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
sunLight.shadow.mapSize.width = 2048;
sunLight.shadow.mapSize.height = 2048;
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
// 4. 3D WEATHER PARTICLE ENGINE (RAIN, SNOW, AUTUMN LEAVES, BLOSSOMS, STARLIGHT)
// ============================================================================
const WEATHER_COUNT = 1400;
const weatherGeo = new THREE.BufferGeometry();
const weatherPos = new Float32Array(WEATHER_COUNT * 3);
const weatherVel = new Float32Array(WEATHER_COUNT * 3);

for (let i = 0; i < WEATHER_COUNT; i++) {
  weatherPos[i * 3] = (Math.random() - 0.5) * 90;
  weatherPos[i * 3 + 1] = Math.random() * 45;
  weatherPos[i * 3 + 2] = (Math.random() - 0.5) * 90;
  weatherVel[i * 3] = (Math.random() - 0.5) * 2.0;
  weatherVel[i * 3 + 1] = 0.65 + Math.random() * 0.7;
  weatherVel[i * 3 + 2] = (Math.random() - 0.5) * 2.0;
}
weatherGeo.setAttribute('position', new THREE.BufferAttribute(weatherPos, 3));

const weatherMat = new THREE.PointsMaterial({
  color: 0x86efac,
  size: 0.45,
  transparent: true,
  opacity: 0.82,
  depthWrite: false,
  blending: THREE.AdditiveBlending,
});
const weatherPoints = new THREE.Points(weatherGeo, weatherMat);
weatherPoints.frustumCulled = false;
scene.add(weatherPoints);

function updateWeatherParticles(dt, elapsed) {
  weatherPoints.visible = STATE.settings.weatherEnabled;
  if (!STATE.settings.weatherEnabled) return;

  const mode = STATE.currentContinent.weather;
  const posArr = weatherGeo.attributes.position.array;
  const px = playerGroup.position.x;
  const py = playerGroup.position.y;
  const pz = playerGroup.position.z;

  if (mode === 'rain') {
    weatherMat.color.setHex(0x93c5fd);
    weatherMat.size = 0.36;
    weatherMat.opacity = 0.82;
  } else if (mode === 'snow') {
    weatherMat.color.setHex(0xf8fafc);
    weatherMat.size = 0.54;
    weatherMat.opacity = 0.92;
  } else if (mode === 'leaves') {
    weatherMat.color.setHex(0xfbbf24);
    weatherMat.size = 0.58;
    weatherMat.opacity = 0.88;
  } else if (mode === 'petals') {
    weatherMat.color.setHex(0x86efac);
    weatherMat.size = 0.46;
    weatherMat.opacity = 0.8;
  } else if (mode === 'mist') {
    weatherMat.color.setHex(0x6ee7b7);
    weatherMat.size = 0.62;
    weatherMat.opacity = 0.68;
  } else {
    weatherMat.color.setHex(0xfef08a);
    weatherMat.size = 0.52;
    weatherMat.opacity = 0.88;
  }

  for (let i = 0; i < WEATHER_COUNT; i++) {
    const i3 = i * 3;
    const speedMult = weatherVel[i3 + 1];

    if (mode === 'rain') {
      posArr[i3] -= 6.5 * dt;
      posArr[i3 + 1] -= 42.0 * speedMult * dt;
    } else if (mode === 'snow') {
      posArr[i3] += Math.sin(elapsed * 1.8 + i) * 4.5 * dt + 3.2 * dt;
      posArr[i3 + 1] -= 7.8 * speedMult * dt;
      posArr[i3 + 2] += Math.cos(elapsed * 1.5 + i) * 3.5 * dt;
    } else if (mode === 'leaves' || mode === 'petals') {
      posArr[i3] += Math.sin(elapsed * 1.2 + i * 0.5) * 3.8 * dt;
      posArr[i3 + 1] -= 3.6 * speedMult * dt;
      posArr[i3 + 2] += Math.cos(elapsed * 1.1 + i * 0.5) * 3.8 * dt;
    } else {
      posArr[i3] += Math.sin(elapsed * 0.9 + i) * 1.8 * dt;
      posArr[i3 + 1] += 2.8 * speedMult * dt;
      posArr[i3 + 2] += Math.cos(elapsed * 0.9 + i) * 1.8 * dt;
    }

    if (posArr[i3] - px < -45) posArr[i3] += 90;
    if (posArr[i3] - px > 45) posArr[i3] -= 90;
    if (posArr[i3 + 2] - pz < -45) posArr[i3 + 2] += 90;
    if (posArr[i3 + 2] - pz > 45) posArr[i3 + 2] -= 90;
    if (posArr[i3 + 1] < py - 6) posArr[i3 + 1] = py + 38;
    if (posArr[i3 + 1] > py + 40) posArr[i3 + 1] = py - 4;
  }

  weatherGeo.attributes.position.needsUpdate = true;
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
  let amp = 0.55;
  let freq = 1.0;
  let weight = 1.0;
  for (let i = 0; i < 4; i++) {
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

function getTerrainHeight(x, z) {
  let maxContinentH = -8.5;

  for (let i = 0; i < CONTINENTS.length; i++) {
    const c = CONTINENTS[i];
    const distIsland = Math.hypot(x - c.x, z - c.z);

    if (distIsland < c.radius * 1.55) {
      const normD = distIsland / (c.radius * 1.45);
      const mask = Math.max(0.0, 1.0 - normD * normD);
      const smoothMask = mask * mask * (3.0 - 2.0 * mask);

      const n1 = fbm((x + i * 37) * 0.011, (z + i * 53) * 0.011);
      const n2 = fbm(x * 0.042, z * 0.042);
      const rNoise = ridgedMultifractal((x + i * 71) * 0.014, (z + i * 29) * 0.016);
      const rFine = ridgedMultifractal((x - i * 43) * 0.038, (z + i * 19) * 0.038);

      // Base Continental Valley & Rolling Foothills
      let h = -7.5 + smoothMask * (8.5 + (n1 - 0.35) * 8.0 + (n2 - 0.5) * 2.5);

      // COLOSSAL MULTI-PEAK MOUNTAIN RANGE SPANNING THE ENTIRE NORTHERN HORIZON
      const { px, pz } = getPeakCenter(c);
      const dxRange = x - px;
      const dzRange = z - pz;

      // Amphitheater arc: flanking wings curve slightly southward so the mountain range wraps around the horizon!
      const arcCurveZ = Math.min(180.0, (dxRange * dxRange) * 0.00028) + Math.sin(dxRange * 0.006 + i * 1.3) * 32.0;
      const distFromSpineZ = Math.abs(dzRange - arcCurveZ);
      const lateralNorm = Math.abs(dxRange) / (c.radius * 1.15);
      const depthNorm = distFromSpineZ / 390.0;

      if (lateralNorm < 1.0 && depthNorm < 1.0) {
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

        h += foothills + toweringSpire + serratedCouloirs;
      }

      // Wide Scenic Base Camp Valley (Radius 95m) so the foreground is flat and the colossal range rises across the entire horizon!
      const distBaseCamp = Math.hypot(x - c.x, z - c.z);
      if (distBaseCamp < 95.0) {
        const flatF = 1.0 - Math.min(1.0, Math.max(0.0, (distBaseCamp - 42.0) / 53.0));
        const smoothFlat = flatF * flatF * (3.0 - 2.0 * flatF);
        h = h * (1.0 - smoothFlat * 0.96) + 2.6 * (smoothFlat * 0.96);
      }

      if (h > maxContinentH) maxContinentH = h;
    }
  }
  return maxContinentH;
}

// Winding Expedition Trail from Base Camp up into the Lower & Mid Ridges of the Mountain Range
function getMountainTrailPoint(c, progress) {
  const x = c.x + Math.sin(progress * Math.PI * 3.0) * (36.0 + progress * 85.0);
  const z = c.z - 28.0 - progress * 440.0;
  const y = getTerrainHeight(x, z);
  return new THREE.Vector3(x, y, z);
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

const MAX_CLEANSE_ZONES = 36;
const cleanseCenters = [];
for (let i = 0; i < MAX_CLEANSE_ZONES; i++) {
  cleanseCenters.push(new THREE.Vector4(99999, 99999, 0.0, 0.0));
}
cleanseCenters[0].set(0, 0, 72.0, 72.0);
let nextCleanseIdx = 1;

function addRejuvenationZone(x, z, radius = 78.0) {
  const idx = nextCleanseIdx % MAX_CLEANSE_ZONES;
  cleanseCenters[idx].set(x, z, 2.0, radius);
  nextCleanseIdx++;
}

const WORLD_SIZE = 5200;
const terrainGeo = new THREE.PlaneGeometry(WORLD_SIZE, WORLD_SIZE, 560, 560);
terrainGeo.rotateX(-Math.PI / 2);
const posAttr = terrainGeo.attributes.position;
for (let i = 0; i < posAttr.count; i++) {
  const vx = posAttr.getX(i);
  const vz = posAttr.getZ(i);
  posAttr.setY(i, getTerrainHeight(vx, vz));
}
terrainGeo.computeVertexNormals();

const terrainShaderMat = new THREE.ShaderMaterial({
  uniforms: {
    uCleanseZones: { value: cleanseCenters },
    uSunDir: { value: new THREE.Vector3(0.54, 0.38, -0.75).normalize() },
    uFogColor: { value: CONTINENTS[0].fogColor.clone() },
    uGroundTint: { value: CONTINENTS[0].groundTintColor.clone() },
    uTime: { value: 0 },
  },
  vertexShader: `
    varying vec3 vWorldPos;
    varying vec3 vNormal;
    void main() {
      vec4 wp = modelMatrix * vec4(position, 1.0);
      vWorldPos = wp.xyz;
      vNormal = normalize(normalMatrix * normal);
      gl_Position = projectionMatrix * viewMatrix * wp;
    }
  `,
  fragmentShader: `
    uniform vec4 uCleanseZones[${MAX_CLEANSE_ZONES}];
    uniform vec3 uSunDir;
    uniform vec3 uFogColor;
    uniform vec3 uGroundTint;
    uniform float uTime;
    varying vec3 vWorldPos;
    varying vec3 vNormal;

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
      v += 0.50 * noise(p);
      v += 0.25 * noise(p * 2.1);
      v += 0.125 * noise(p * 4.3);
      v += 0.0625 * noise(p * 8.7);
      return v;
    }

    void main() {
      float hC = fbmDetail(vWorldPos.xz * 0.45);
      float hX = fbmDetail((vWorldPos.xz + vec2(0.18, 0.0)) * 0.45);
      float hZ = fbmDetail((vWorldPos.xz + vec2(0.0, 0.18)) * 0.45);
      vec3 bumpNormal = normalize(vNormal + vec3(hC - hX, 0.0, hC - hZ) * 1.65);

      float macro = fbmDetail(vWorldPos.xz * 0.055);
      float slope = 1.0 - max(dot(vNormal, vec3(0.0, 1.0, 0.0)), 0.0);

      float cleanse = 0.0;
      float ringEdge = 0.0;
      for (int i = 0; i < ${MAX_CLEANSE_ZONES}; i++) {
        vec4 cz = uCleanseZones[i];
        if (cz.z > 0.1) {
          float d = distance(vWorldPos.xz, cz.xy);
          float factor = 1.0 - smoothstep(cz.z - 8.0, cz.z + 2.0, d);
          cleanse = max(cleanse, factor);
          float edge = smoothstep(cz.z - 2.2, cz.z - 0.4, d) * (1.0 - smoothstep(cz.z - 0.4, cz.z + 1.4, d));
          ringEdge = max(ringEdge, edge);
        }
      }

      vec3 blightSoil = mix(vec3(0.18, 0.22, 0.20), vec3(0.26, 0.30, 0.25), macro);
      vec3 lushTurf = mix(uGroundTint * 0.55, uGroundTint * 0.95, macro);
      float kurinji = smoothstep(0.68, 0.85, hC);
      lushTurf = mix(lushTurf, vec3(0.96, 0.82, 0.24), kurinji * 0.42);

      vec3 col = mix(blightSoil, lushTurf, cleanse);

      // Realistic Stratified Basalt / Granite Escarpments, Couloirs & Alpine Rock Faces (No Smooth Green Hills!)
      if (slope > 0.14 || vWorldPos.y > 16.0) {
        float rk = clamp((slope - 0.12) * 2.8 + max(0.0, (vWorldPos.y - 16.0) / 38.0), 0.0, 1.0);
        float strata = noise(vec2(vWorldPos.x * 0.08 + vWorldPos.z * 0.08, vWorldPos.y * 0.35));
        float cragDetail = fbmDetail(vWorldPos.xz * 0.18 + vec2(vWorldPos.y * 0.12));
        vec3 darkBasalt = vec3(0.19, 0.20, 0.22);
        vec3 lightGranite = vec3(0.46, 0.44, 0.42);
        vec3 cliff = mix(darkBasalt, lightGranite, strata * 0.65 + cragDetail * 0.35);
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
      float NdotL = max(dot(bumpNormal, uSunDir), 0.0);
      float spec = pow(max(dot(bumpNormal, halfVec), 0.0), 28.0) * 0.22;

      vec3 ambient = mix(vec3(0.24, 0.28, 0.38), vec3(0.44, 0.54, 0.66), bumpNormal.y * 0.5 + 0.5);
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
  c.width = 256;
  c.height = 256;
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(256, 256);
  for (let i = 0; i < 256 * 256; i++) {
    const x = i % 256;
    const y = Math.floor(i / 256);
    const n = fbm(x * 0.08, y * 0.08);
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

function createSculptedCanopyGeometry(radius) {
  const geo = new THREE.IcosahedronGeometry(radius, 3);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const vx = p.getX(i);
    const vy = p.getY(i);
    const vz = p.getZ(i);
    const n = 0.78 + 0.38 * fbm(vx * 0.7 + 5.1, vz * 0.7 + vy * 0.5);
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

function createNameplateDOM(entity) {
  const el = document.createElement('div');
  el.className = 'nameplate';
  el.innerHTML = `
    <div class="np-title">
      <span class="np-lvl">[${entity.badge}]</span>
      <span class="np-name">${entity.name}</span>
    </div>
    <div class="np-bar-bg">
      <div class="np-bar-fill" style="width: ${(entity.hp / entity.maxHp) * 100}%"></div>
    </div>
  `;
  el.addEventListener('pointerdown', (e) => {
    e.stopPropagation();
    SFX.playTargetClick();
    selectTarget(entity);
    if (e.button === 2 || entity.kind === 'chest') {
      openWoWLootWindow(entity);
    }
  });
  nameplatesContainer.appendChild(el);
  entity.nameplateEl = el;
  entity.npFillEl = el.querySelector('.np-bar-fill');
}

const gltfLoader = new GLTFLoader();
const mixers = [];

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
  for (let step = 1; step <= 14; step++) {
    const pt = getMountainTrailPoint(cont, step / 15);
    const cairn = new THREE.Group();
    cairn.position.copy(pt);
    const post = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.28, 1.6, 6), stoneMat);
    post.position.y = 0.8;
    cairn.add(post);
    const flame = new THREE.Mesh(new THREE.SphereGeometry(0.24, 8, 8), torchMat);
    flame.position.y = 1.75;
    cairn.add(flame);
    scene.add(cairn);
  }

  for (let t = 0; t < 26; t++) {
    const angle = (t / 26) * Math.PI * 2 + hash2D(cont.id, t) * 0.4;
    const rad = 20 + hash2D(t, cont.id * 7) * 90;
    const tx = cont.x + Math.cos(angle) * rad;
    const tz = cont.z + Math.sin(angle) * rad;
    const isNearStart = cont.id === 0 && Math.hypot(tx, tz) < 48;
    spawnOrganicTree(tx, tz, cont.id, isNearStart);
  }

  const midTrailPt = getMountainTrailPoint(cont, 0.22);
  const highPassPt = getMountainTrailPoint(cont, 0.44);
  const alpineRidgePt = getMountainTrailPoint(cont, 0.65);

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

    if (obj.kind === 'wildlife') {
      const wDef = WILDLIFE_MODELS[obj.wIdx];
      icon = wDef.icon;
      name = `Distressed ${wDef.species}`;
      heightOffset = (wDef.flyHeight || 0) + 2.4;

      gltfLoader.load(wDef.url, (gltf) => {
        const model = gltf.scene;
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
          mixers.push(m);
        }
      });
    } else if (obj.kind === 'shrine') {
      icon = '🔥';
      name = `${cont.shortName} High-Pass Cairn`;
      heightOffset = 6.2;

      const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.55, 0.95, 4.6, 8), stoneMat);
      shaft.position.y = 2.3;
      shaft.castShadow = true;
      group.add(shaft);

      const cap = new THREE.Mesh(new THREE.ConeGeometry(0.8, 1.3, 8), stoneMat);
      cap.position.y = 5.1;
      group.add(cap);
    } else {
      icon = '🎁';
      name = `🎁 ${cont.chestName}`;
      heightOffset = 3.4;

      const chestMesh = createTreasureChestMesh();
      group.add(chestMesh);
      group._chest = chestMesh;
    }

    scene.add(group);

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
    };

    createNameplateDOM(entity);
    interactables.push(entity);
  });
});

// ============================================================================
// 7. SEATED SKELETAL RIDER ON MOUNT (`Soldier.glb` Astride `Horse.glb` + Wings)
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, getTerrainHeight(0, 9), 9);
scene.add(playerGroup);

// 3D Mount Container inside playerGroup so Mount & Seated Rider move in 100% unison!
const mountGroup = new THREE.Group();
playerGroup.add(mountGroup);

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

// Load Rigged `Horse.glb` Mount
gltfLoader.load('https://threejs.org/examples/models/gltf/Horse.glb', (gltf) => {
  const horse = gltf.scene;
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

  mountGroup.visible = STATE.isMounted;
  mountWingsGroup.visible = STATE.isMounted && (STATE.isFlying || canFlyOnContinent(STATE.currentContinent));

  if (!STATE.isMounted && !STATE.isSitting) {
    playerModel.position.set(0, 0, 0);
    return;
  }

  const gallopBob = isMoving ? Math.sin(elapsed * 11.0) * 0.055 : Math.sin(elapsed * 2.5) * 0.015;

  if (STATE.isMounted) {
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
    t.kind === 'chest' ? `${Math.round(t.hp)} / ${t.maxHp} Seal` : `${Math.round(t.hp)} / ${t.maxHp} Vitality`;
  document.getElementById('wow-target-blight-bar').style.width = `${blightPct}%`;
  document.getElementById('wow-target-status-txt').textContent = t.rejuvenated
    ? '🌟 Rejuvenated • ToT: Sadhak'
    : `Right-Click or Cast [1] [2] • ToT: Sadhak`;
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

  if (!STATE.isMounted) {
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
    if (ent.rejuvenated) return;
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
// 12. INPUT CONTROLS, WOW KEYBINDS & SETTINGS WIRING
// ============================================================================
const keys = {};
let cameraYaw = 0;
let cameraPitch = 0.08;
let cameraDist = 17.5;
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
    if (e.button === 2 && best.kind === 'chest') {
      openWoWLootWindow(best);
    }
  } else if (!STATE.settings.stickyTarget) {
    selectTarget(null);
  }
});

window.addEventListener('pointermove', (e) => {
  if (!isDragging) return;
  const dx = e.clientX - prevMouse.x;
  const dy = e.clientY - prevMouse.y;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;
  cameraYaw -= dx * 0.0065;
  cameraPitch = Math.max(0.06, Math.min(1.22, cameraPitch + dy * 0.0055));
});

window.addEventListener('pointerup', () => {
  isDragging = false;
});

window.addEventListener('wheel', (e) => {
  cameraDist = Math.max(7.0, Math.min(44.0, cameraDist + e.deltaY * 0.015));
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
    if (dist > 135) {
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

  // Movement Input (WASD + QE Strafe + Auto-Run)
  let moveX = 0;
  let moveZ = 0;
  if (keys['w'] || keys['arrowup']) {
    moveZ -= 1;
    STATE.autoRun = false;
  }
  if (keys['s'] || keys['arrowdown']) {
    moveZ += 1;
    STATE.autoRun = false;
  }
  if (STATE.autoRun) moveZ -= 1;
  if (keys['a'] || keys['arrowleft'] || keys['q']) moveX -= 1;
  if (keys['d'] || keys['arrowright'] || keys['e']) moveX += 1;

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

    const sinY = Math.sin(cameraYaw);
    const cosY = Math.cos(cameraYaw);
    const dx = moveX * cosY + moveZ * sinY;
    const dz = -moveX * sinY + moveZ * cosY;

    playerGroup.position.x += dx * speed * dt;
    playerGroup.position.z += dz * speed * dt;
    playerGroup.rotation.y = Math.atan2(dx, dz) + Math.PI;
    setPlayerAnim(STATE.isMounted ? 'Idle' : 'Run');
  } else {
    setPlayerAnim('Idle');
  }

  // Advance Skeletal Mixers & Apply Seated Astride Saddle Pose!
  if (mountAction) {
    mountAction.timeScale = isMoving || STATE.isFlying ? 1.15 : 0.0;
  }
  for (let i = 0; i < mixers.length; i++) {
    mixers[i].update(dt);
  }
  applySeatedRiderPose(elapsed, isMoving || STATE.isFlying);

  // Vertical Flight & Realistic High-Altitude Mountain Thin-Air Resistance
  // (True Apex is 2,650m–4,800m tall; vertical ascent rate tapers in thin alpine air so reaching the True Apex takes 15+ minutes!)
  const groundY = Math.max(-1.2, getTerrainHeight(playerGroup.position.x, playerGroup.position.z));
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

  // Detect Region Change & Enforce Sacred No-Fly Trekking Rule
  const nearCont = getNearestContinent(playerGroup.position.x, playerGroup.position.z);
  if (nearCont !== STATE.currentContinent) {
    STATE.currentContinent = nearCont;
    SFX.playMountWhinnyOrWingbeat();
    if (STATE.isFlying && !canFlyOnContinent(nearCont)) {
      STATE.isFlying = false;
      showToast(`🥾 Entered Sacred No-Fly Region: ${nearCont.shortName}! Switched to Mounted Ground Trek.`);
    } else {
      showToast(`🗺️ Entered ${nearCont.name} (${nearCont.weatherLabel})`);
    }
    updateVigorOrbsUI();
    updateAllHUD();
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

  interactables.forEach((ent) => {
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

  const camTarget = new THREE.Vector3(playerGroup.position.x, playerGroup.position.y + 4.8, playerGroup.position.z - 8.0);
  const camX = playerGroup.position.x + Math.sin(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camZ = playerGroup.position.z + Math.cos(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camY = playerGroup.position.y + 2.2 + Math.sin(cameraPitch) * cameraDist;
  const minCamY = getTerrainHeight(camX, camZ) + 1.3;

  camera.position.set(camX, Math.max(camY, minCamY), camZ);
  camera.lookAt(camTarget);

  updateWorldNameplates();
  drawMinimap();
  composer.render();
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  composer.setSize(window.innerWidth, window.innerHeight);
});

animate();
