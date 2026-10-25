import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import * as SkeletonUtils from 'three/addons/utils/SkeletonUtils.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// ============================================================================
// WORLD OF DHARMA (2026) — DRAGONFLIGHT SKYRIDING, 7 WORLD PEAKS & TREKKING
// Western Ghats • Nilgiris • Kilimanjaro • Kailash • Denali • Everest • Meru
// ============================================================================

// ============================================================================
// 1. POLYPHONIC WEB AUDIO API WOW ORCHESTRAL & SPATIAL SOUND ENGINE
// ============================================================================
class WoWSoundEngine {
  constructor() {
    this.ctx = null;
    this.muted = false;
    this.ambientStarted = false;
    this.masterGain = null;
    this.reverbNode = null;
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
    this.masterGain.gain.value = 0.42;

    this.reverbNode = this.createCathedralReverb(2.6, 2.2);
    const wetGain = this.ctx.createGain();
    wetGain.gain.value = 0.48;
    const dryGain = this.ctx.createGain();
    dryGain.gain.value = 0.75;

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

  toggleMute() {
    this.init();
    this.muted = !this.muted;
    if (this.masterGain) {
      this.masterGain.gain.setTargetAtTime(this.muted ? 0.0 : 0.42, this.ctx.currentTime, 0.1);
    }
    const pill = document.getElementById('btn-audio-toggle');
    if (pill) {
      pill.textContent = this.muted ? '🔇 WoW Audio: MUTED' : '🔊 WoW Audio: ON';
      pill.style.color = this.muted ? '#94a3b8' : '#4ade80';
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
      filter.frequency.value = 420 + idx * 80;
      gain.gain.value = 0.03;

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(this.masterGain);
      osc.start();
    });

    setInterval(() => {
      if (this.muted || !this.ctx || this.ctx.state !== 'running') return;
      const scale = [293.66, 329.63, 369.99, 440.0, 493.88, 587.33, 659.25];
      const f = scale[Math.floor(Math.random() * scale.length)];
      this.playTone(f, 'sine', 1.8, 0.042, 0.08);
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
    this.playTone(880, 'triangle', 0.09, 0.14, 0.005, 1320);
  }

  playCastStart() {
    const notes = [440, 554.37, 659.25];
    notes.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'sine', 0.35, 0.09, 0.02, n * 1.12), i * 55);
    });
  }

  playHealImpact() {
    const chord = [587.33, 739.99, 880.0, 1174.66];
    chord.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'sine', 0.65, 0.11, 0.015), i * 35);
    });
  }

  playNovaWave() {
    this.playTone(146.83, 'triangle', 0.95, 0.22, 0.03, 73.42);
    const shimmer = [440, 587.33, 659.25, 880, 1174.66];
    shimmer.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'sine', 0.75, 0.09, 0.02), i * 45);
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

  playDragonRoarWingbeat() {
    this.playTone(130.81, 'sawtooth', 0.55, 0.16, 0.03, 65.41);
    setTimeout(() => this.playTone(261.63, 'triangle', 0.4, 0.12, 0.02, 523.25), 90);
  }

  playCampfireCrackle() {
    const notes = [329.63, 392.0, 493.88, 659.25];
    notes.forEach((n, i) => {
      setTimeout(() => this.playTone(n, 'triangle', 0.5, 0.12, 0.02), i * 70);
    });
  }
}

const SFX = new WoWSoundEngine();

// ============================================================================
// 2. THE 7 GREAT MOUNTAINS OF THE WORLD (SKYRIDING vs NO-FLY TREKKING PEAKS)
// ============================================================================
const CONTINENTS = [
  {
    id: 0,
    roman: 'I',
    name: 'Western Ghats (Sahyadri — Kalsubai & Anamudi)',
    shortName: 'I. Western Ghats',
    x: 0,
    z: 0,
    radius: 175,
    peakHeight: 58.0, // Towering 3D summit with spiral trekking path!
    realMeters: 2695,
    allowFlying: true,
    tier: 1,
    diffMult: 1.0,
    maxHpBase: 120,
    karmaReward: 110,
    chestName: 'Sahyadri Shola Chest',
    boonIcon: '🐉',
    boonName: 'Boon of Sahyadri (Monsoon Updraft)',
    boonDesc: '+35% Healing Power & recharges Dragonflight Vigor Orbs 40% faster.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 1,
    roman: 'II',
    name: 'Nilgiri & Agasthyamalai Ghats (Doddabetta)',
    shortName: 'II. Nilgiri Ghats',
    x: 0,
    z: -430,
    radius: 175,
    peakHeight: 68.0,
    realMeters: 2637,
    allowFlying: false, // SACRED NO-FLY TREKKING ZONE!
    tier: 2,
    diffMult: 1.8,
    maxHpBase: 220,
    karmaReward: 190,
    chestName: 'Neelakurinji Summit Chest',
    boonIcon: '🥾',
    boonName: 'Boon of Agasthya (Master Trekker)',
    boonDesc: '+50% Ganga Nova AoE Radius & +40% Foot-Trekking Sprint Speed on No-Fly Peaks!',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 2,
    roman: 'III',
    name: 'Mount Kilimanjaro & Matterhorn Crags',
    shortName: 'III. Kilimanjaro',
    x: 390,
    z: -240,
    radius: 175,
    peakHeight: 78.0,
    realMeters: 5895,
    allowFlying: true,
    tier: 3,
    diffMult: 2.8,
    maxHpBase: 360,
    karmaReward: 290,
    chestName: 'Uhuru Crater Chest',
    boonIcon: '⚡',
    boonName: 'Boon of the Sky-Drake (Supersonic Glide)',
    boonDesc: 'Doubles Sky-Dragon Flight velocity and cuts spell cast time by 35%.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 3,
    roman: 'IV',
    name: 'Sacred Mount Kailash & Nanda Devi',
    shortName: 'IV. Mt. Kailash',
    x: 390,
    z: 240,
    radius: 175,
    peakHeight: 92.0,
    realMeters: 6638,
    allowFlying: false, // SACRED NO-FLY PILGRIMAGE PARIKRAMA!
    tier: 4,
    diffMult: 4.2,
    maxHpBase: 540,
    karmaReward: 440,
    chestName: 'Manasarovar Relic Chest',
    boonIcon: '🔱',
    boonName: 'Boon of Kailash (Shiva’s Parikrama)',
    boonDesc: 'Doubles all Karma Points (☸️) earned across the universe and empowers Campfires [C].',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 4,
    roman: 'V',
    name: 'Denali & Aconcagua (Andean-Alaskan Ridge)',
    shortName: 'V. Denali Peak',
    x: 0,
    z: 430,
    radius: 175,
    peakHeight: 104.0,
    realMeters: 6961,
    allowFlying: true,
    tier: 5,
    diffMult: 6.0,
    maxHpBase: 780,
    karmaReward: 620,
    chestName: 'High-Andes Condor Chest',
    boonIcon: '🐘',
    boonName: 'Boon of Ganesha (Ridge Breaker)',
    boonDesc: 'All spells automatically chain-heal 2 additional suffering targets within 28m.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 5,
    roman: 'VI',
    name: 'The Great Himalayas (Mount Everest & K2)',
    shortName: 'VI. Mt. Everest',
    x: -390,
    z: 240,
    radius: 185,
    peakHeight: 122.0,
    realMeters: 8848,
    allowFlying: false, // EXTREME KHUMBU GALE NO-FLY TREKKING ZONE!
    tier: 6,
    diffMult: 8.5,
    maxHpBase: 1100,
    karmaReward: 950,
    chestName: 'Sagarmatha 8,848m Chest',
    boonIcon: '🏔️',
    boonName: 'Boon of Sagarmatha (Crown of the World)',
    boonDesc: 'Cuts Surge [R] cooldown by 50% and grants immunity to high-altitude stamina drain.',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 6,
    roman: 'VII',
    name: 'Mount Meru (Cosmic Axis of the Universe)',
    shortName: 'VII. Mount Meru',
    x: -390,
    z: -240,
    radius: 185,
    peakHeight: 138.0,
    realMeters: 10800,
    allowFlying: true,
    tier: 7,
    diffMult: 12.0,
    maxHpBase: 1600,
    karmaReward: 1800,
    chestName: 'Vaikuntha Sovereign Chest',
    boonIcon: '👑',
    boonName: 'Boon of Vishnu (Universal Sovereign)',
    boonDesc: 'Unlocks flying even in No-Fly Zones + Passive Aura heals all beings around your Dragon!',
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
];

// ============================================================================
// KARMA & MOUNTAINEERING FORGE ITEMS [K]
// ============================================================================
const SHOP_TOOLS = [
  {
    id: 'danda_staff',
    icon: '🦯',
    name: 'Sahyadri Brahmadanda Staff',
    category: 'Sacred Tool • Upgrades [1] & [3]',
    rank: 1,
    maxRank: 10,
    baseCost: 80,
    costMult: 1.55,
    desc: 'Carved from Western Ghats sandalwood. Amplifies Sanjeevani Bolt [1], Sunbeam [3] & Summit Chest unlocking.',
    bonusText: (r) => `Current: +${(r - 1) * 45} Healing & Loot Power (Next: +${r * 45})`,
  },
  {
    id: 'dragon_saddle',
    icon: '🐉',
    name: 'Drake-Scale Skyriding Harness',
    category: 'Dragon Gear • Upgrades [F] & [5]',
    rank: 1,
    maxRank: 8,
    baseCost: 95,
    costMult: 1.55,
    desc: 'Aerodynamic saddle for your Sky-Dragon companion. Increases Dragonflight cruise speed & Vigor recharge rate.',
    bonusText: (r) => `Current: +${(r - 1) * 25}% Dragon Speed & +${(r - 1) * 20}% Vigor Regen`,
  },
  {
    id: 'crampon_boots',
    icon: '🥾',
    name: 'Himalayan Mithril Crampons',
    category: 'Trekking Gear • Upgrades [4] & Climb',
    rank: 1,
    maxRank: 8,
    baseCost: 105,
    costMult: 1.6,
    desc: 'Essential for No-Fly Trekking Peaks (Nilgiris, Kailash, Everest)! Grips steep 75° rock faces and boosts Sprint [4].',
    bonusText: (r) => `Current: +${(r - 1) * 28}% Steep-Slope Climb Speed & Stamina`,
  },
  {
    id: 'camping_kit',
    icon: '⛺',
    name: 'Sherpa Base-Camp Brazier Kit',
    category: 'Expedition Gear • Upgrades [C]',
    rank: 1,
    maxRank: 6,
    baseCost: 115,
    costMult: 1.6,
    desc: 'Upgrades your pitched Campfire [C] so resting heals all suffering creatures within 45m and grants a longer Well-Fed speed buff.',
    bonusText: (r) => `Current: Campfire heals 45m radius for +${r * 90} Vitality`,
  },
  {
    id: 'sanjeevani_elixir',
    icon: '🧪',
    name: 'Himalayan Soma-Elixir',
    category: 'Consumable • Instant Summit Burst',
    rank: 0,
    maxRank: 99,
    baseCost: 140,
    costMult: 1.15,
    desc: 'Instantly releases a 65-meter Golden Supernova around you, restoring +340 Rejuvenation and refilling all 6 Dragon Vigor Orbs!',
    bonusText: () => `Instant Use: 65m +340 Heal + 6/6 Dragon Vigor!`,
    isConsumable: true,
  },
  {
    id: 'chakra_resonator',
    icon: '☸️',
    name: 'Sudarshana Dharma Chakra',
    category: 'Mythic Artifact • Auto-Renewal Halo',
    rank: 0,
    maxRank: 5,
    baseCost: 240,
    costMult: 1.75,
    desc: 'Summons an orbiting golden Chakra above your head that automatically fires bolts at nearby suffering wildlife & chests!',
    bonusText: (r) => (r === 0 ? 'Not Yet Forged (Buy Rank 1 to Summon!)' : `Active: Auto-pulses nearby targets for ${r * 50}`),
  },
];

const STATE = {
  karma: 350,
  lifetimeKarma: 350,
  relicsLooted: 0,
  ascensionStage: 1,
  totalRejuvenated: 0,
  totalSites: 28,
  currentContinent: CONTINENTS[0],
  speedRunActive: true,
  mountedOnDragon: false, // Toggle with [F] (Skyriding!)
  vigor: 6.0,
  maxVigor: 6,
  trekStamina: 100,
  wellFedTimer: 0,        // From pitching a Campfire [C]
  selectedTarget: null,
  casting: null,
  cooldowns: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0 },
  cdMax:     { 1: 0.85, 2: 2.0, 3: 2.8, 4: 0.4, 5: 1.4, 6: 5.0, 7: 0.4, 8: 5.0 },
};

function getHealPower() {
  const staffRank = SHOP_TOOLS[0].rank;
  const boonMult = CONTINENTS[0].completed ? 1.35 : 1.0;
  return Math.round((85 + (staffRank - 1) * 45) * boonMult);
}
function getAoERadius() {
  return CONTINENTS[1].completed ? 34 : 24;
}
function getKarmaMultiplier() {
  let mult = 1.0 + (STATE.relicsLooted * 0.15);
  if (CONTINENTS[3].completed) mult *= 2.0;
  return mult;
}
function getTrekMobilityMult() {
  let mult = 1.0 + (SHOP_TOOLS[2].rank - 1) * 0.25;
  if (CONTINENTS[1].completed) mult += 0.4;
  if (STATE.wellFedTimer > 0) mult += 0.3;
  return mult;
}
function getDragonMobilityMult() {
  let mult = 1.0 + (SHOP_TOOLS[1].rank - 1) * 0.25;
  if (CONTINENTS[2].completed) mult *= 1.55;
  return mult;
}
function canFlyOnContinent(cont) {
  return cont.allowFlying || CONTINENTS[6].completed;
}

// ============================================================================
// 3. 2026 NEXT-GEN WEBGL2 RENDERER + UNREAL BLOOM POST-PROCESSING PIPELINE
// ============================================================================
const container = document.getElementById('canvas-container');
const nameplatesContainer = document.getElementById('nameplates-container');

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1f3a5c);

const camera = new THREE.PerspectiveCamera(58, window.innerWidth / window.innerHeight, 0.5, 2500);
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

// Atmospheric Sky Dome
const skyGeo = new THREE.SphereGeometry(2000, 32, 24);
const skyMat = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  depthWrite: false,
  uniforms: {
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
    uniform vec3 uSunDir;
    void main() {
      vec3 dir = normalize(vWorldPos);
      float h = clamp(dir.y * 1.3 + 0.1, 0.0, 1.0);
      vec3 zenith = vec3(0.08, 0.22, 0.46);
      vec3 horizon = vec3(0.56, 0.76, 0.92);
      vec3 col = mix(horizon, zenith, pow(h, 0.62));
      float sunAmt = max(dot(dir, uSunDir), 0.0);
      col += vec3(1.0, 0.78, 0.42) * pow(sunAmt, 9.0) * 0.45;
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
// 4. VAST MOUNTAIN TOPOGRAPHY WITH SPIRAL TREKKING TRAILS & SNOW SUMMITS
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

// Each of the 7 Ranges has:
// - A Base Camp Valley around (c.x, c.z + 25)
// - A Towering Mountain Summit centered at (c.x, c.z - 68) so you look straight at the majestic mountain from Base Camp!
function getPeakCenter(c) {
  return { px: c.x, pz: c.z - 68 };
}

function getTerrainHeight(x, z) {
  let maxContinentH = -8.5;

  for (let i = 0; i < CONTINENTS.length; i++) {
    const c = CONTINENTS[i];
    const distIsland = Math.hypot(x - c.x, z - c.z);

    if (distIsland < c.radius * 1.28) {
      const normD = distIsland / c.radius;
      const mask = Math.max(0.0, 1.0 - normD * normD);
      const smoothMask = mask * mask * (3.0 - 2.0 * mask);

      const n1 = fbm((x + i * 37) * 0.016, (z + i * 53) * 0.016);
      const n2 = fbm(x * 0.05, z * 0.05);

      // Base valley + rolling Western Ghats / Himalayan foothills
      let h = -7.5 + smoothMask * (9.5 + (n1 - 0.35) * 11.0 + (n2 - 0.5) * 2.5);

      // Towering Mountain Peak at (px, pz)
      const { px, pz } = getPeakCenter(c);
      const dxP = x - px;
      const dzP = z - pz;
      const distPeak = Math.hypot(dxP, dzP);
      const peakRadius = 64.0;

      if (distPeak < peakRadius) {
        const pNorm = 1.0 - distPeak / peakRadius;
        const plateauNorm = Math.min(1.0, pNorm / 0.88);
        const ridgeCrags = (n1 - 0.3) * 12.0 * Math.sin(plateauNorm * Math.PI);
        let mountainRise = Math.pow(plateauNorm, 1.45) * c.peakHeight + ridgeCrags;

        // Carve a Spiral Switchback Trekking Trail winding around the mountain
        const angle = Math.atan2(dzP, dxP) + Math.PI;
        let onTrail = 0.0;
        for (let turn = 0; turn < 2; turn++) {
          const totalAngle = angle + turn * Math.PI * 2;
          const progress = totalAngle / (Math.PI * 4);
          const expectedDist = (1.0 - progress * 0.82) * (peakRadius * 0.88);
          const distToTrail = Math.abs(distPeak - expectedDist);
          if (distToTrail < 5.0) {
            const tf = 1.0 - distToTrail / 5.0;
            onTrail = Math.max(onTrail, tf * tf);
          }
        }
        mountainRise -= onTrail * ridgeCrags * 0.85;
        h += mountainRise;
      }

      // Flatten Base Camp Sanctuary Plaza at (c.x, c.z)
      const distBaseCamp = Math.hypot(x - c.x, z - c.z);
      if (distBaseCamp < 20.0) {
        const flatF = 1.0 - Math.min(1.0, Math.max(0.0, (distBaseCamp - 10.0) / 10.0));
        h = h * (1.0 - flatF * 0.88) + 2.4 * (flatF * 0.88);
      }

      if (h > maxContinentH) maxContinentH = h;
    }
  }
  return maxContinentH;
}

// Helper to get 3D coordinates along a mountain's spiral trekking trail (t from 0.0 base to 1.0 summit)
function getMountainTrailPoint(c, progress) {
  const { px, pz } = getPeakCenter(c);
  const peakRadius = 64.0;
  const totalAngle = progress * Math.PI * 3.4 - Math.PI * 0.5;
  const r = (1.0 - progress * 0.85) * (peakRadius * 0.86);
  const x = px + Math.cos(totalAngle) * r;
  const z = pz + Math.sin(totalAngle) * r;
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
// Western Ghats Base Camp & Foothills start lush emerald-green so players immediately see the vibrant Shola biome!
cleanseCenters[0].set(0, 0, 52.0, 52.0);
let nextCleanseIdx = 1;

function addRejuvenationZone(x, z, radius = 68.0) {
  const idx = nextCleanseIdx % MAX_CLEANSE_ZONES;
  cleanseCenters[idx].set(x, z, 2.0, radius);
  nextCleanseIdx++;
}

const WORLD_SIZE = 1480;
const terrainGeo = new THREE.PlaneGeometry(WORLD_SIZE, WORLD_SIZE, 300, 300);
terrainGeo.rotateX(-Math.PI / 2);
const posAttr = terrainGeo.attributes.position;
for (let i = 0; i < posAttr.count; i++) {
  const vx = posAttr.getX(i);
  const vz = posAttr.getZ(i);
  posAttr.setY(i, getTerrainHeight(vx, vz));
}
terrainGeo.computeVertexNormals();

// 2026 PBR Mountain Biome Shader: Western Ghats Laterite/Shola Moss + Himalayan Glacier Snow + Trekking Trails
const terrainShaderMat = new THREE.ShaderMaterial({
  uniforms: {
    uCleanseZones: { value: cleanseCenters },
    uSunDir: { value: new THREE.Vector3(0.54, 0.38, -0.75).normalize() },
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

      // 1. SUFFERING BLIGHT BIOME (Dark mossy slate & glowing violet fissures)
      vec3 blightSoil = mix(vec3(0.18, 0.22, 0.20), vec3(0.26, 0.28, 0.24), macro);
      float fissure = smoothstep(0.72, 0.85, hC);
      blightSoil = mix(blightSoil, vec3(0.55, 0.22, 0.72), fissure * 0.45);

      // 2. REJUVENATED WESTERN GHATS SHOLA & KURINJI MEADOWS (Rich emerald moss, warm laterite earth & Neelakurinji blooms)
      vec3 lushTurf = mix(vec3(0.10, 0.48, 0.16), vec3(0.30, 0.68, 0.20), macro);
      float kurinji = smoothstep(0.68, 0.85, hC);
      lushTurf = mix(lushTurf, vec3(0.96, 0.82, 0.24), kurinji * 0.48);

      vec3 col = mix(blightSoil, lushTurf, cleanse);

      // Steep Basalt / Granite Mountain Cliffs (Western Ghats Deccan Traps & Himalayan Crags)
      if (slope > 0.34 || vWorldPos.y > 22.0) {
        float rk = clamp((slope - 0.32) * 2.2 + max(0.0, (vWorldPos.y - 22.0) / 32.0), 0.0, 1.0);
        float strata = noise(vec2(vWorldPos.x * 0.2, vWorldPos.y * 0.75));
        vec3 cliff = mix(vec3(0.28, 0.26, 0.25), vec3(0.48, 0.45, 0.42), strata);
        col = mix(col, cliff, rk * 0.82);
      }

      // High-Altitude Himalayan / Alpine Glacial Snowline (Above Y = 38m)
      if (vWorldPos.y > 38.0) {
        float snowMask = clamp((vWorldPos.y - 38.0) / 14.0 - slope * 0.45, 0.0, 1.0);
        vec3 snowCol = mix(vec3(0.85, 0.90, 0.98), vec3(0.99, 0.99, 1.0), hC);
        col = mix(col, snowCol, snowMask);
      }

      // Golden Rejuvenation Wave Ring
      col += vec3(1.35, 1.05, 0.35) * ringEdge;

      // PBR Sun Direct + Specular + Sky Bounce
      vec3 viewDir = normalize(cameraPosition - vWorldPos);
      vec3 halfVec = normalize(uSunDir + viewDir);
      float NdotL = max(dot(bumpNormal, uSunDir), 0.0);
      float spec = pow(max(dot(bumpNormal, halfVec), 0.0), 28.0) * 0.22;

      vec3 ambient = mix(vec3(0.24, 0.28, 0.38), vec3(0.44, 0.54, 0.66), bumpNormal.y * 0.5 + 0.5);
      vec3 lit = col * (ambient + vec3(1.05, 0.96, 0.82) * NdotL * 0.82) + vec3(1.0, 0.92, 0.75) * spec;

      float camDist = length(cameraPosition - vWorldPos);
      float fogF = 1.0 - exp(-camDist * 0.00068);
      vec3 fogCol = vec3(0.46, 0.65, 0.82);
      gl_FragColor = vec4(mix(lit, fogCol, clamp(fogF, 0.0, 0.84)), 1.0);
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
// 5. ORGANIC TREES, TRAIL CAIRN MARKERS & SUMMIT TREASURE CHESTS
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
const stoneTex = createFoliageTexture(124, 128, 136);

const barkMat = new THREE.MeshStandardMaterial({ map: barkTex, bumpMap: barkTex, bumpScale: 0.08, roughness: 0.9 });
const witheredCrownMat = new THREE.MeshStandardMaterial({ map: witheredTex, bumpMap: witheredTex, bumpScale: 0.06, roughness: 0.85 });
const lushCrownMat = new THREE.MeshStandardMaterial({ map: lushLeafTex, bumpMap: lushLeafTex, bumpScale: 0.08, roughness: 0.72 });
const goldenCrownMat = new THREE.MeshStandardMaterial({ map: goldenLeafTex, bumpMap: goldenLeafTex, bumpScale: 0.08, roughness: 0.65 });
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
  if (y < 0.25 || y > 30.0) return; // Trees below alpine snowline
  const group = new THREE.Group();
  group.position.set(x, y, z);

  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.56, 4.4, 10), barkMat);
  trunk.position.y = 2.2;
  trunk.castShadow = true;
  group.add(trunk);

  const initMat = startLush ? lushCrownMat : witheredCrownMat;
  const crownGroup = new THREE.Group();
  crownGroup.position.y = 4.8;
  crownGroup.scale.setScalar(startLush ? 1.1 : 0.58);

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

  continentTrees.push({ group, crownGroup, meshes: [c1, c2, c3], x, z, continentId, rejuvenated: startLush });
}

// Helper to build a 3D Golden Ornate Summit Loot Chest
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

// Populate All 7 Mountain Ranges with Base Camps, Trekking Trail Torch Cairns, Wildlife & Summit Loot Chests!
CONTINENTS.forEach((cont) => {
  const cy = getTerrainHeight(cont.x, cont.z);

  // Base Camp Sanctuary Altar at (cont.x, cont.z)
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

  // Place 14 Glowing Trekking Trail Torch Cairns winding up the mountain from Base Camp to the Summit!
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

  // Spawn 26 Shola / Pine Trees around the mountain base
  for (let t = 0; t < 26; t++) {
    const angle = (t / 26) * Math.PI * 2 + hash2D(cont.id, t) * 0.4;
    const rad = 20 + hash2D(t, cont.id * 7) * 90;
    const tx = cont.x + Math.cos(angle) * rad;
    const tz = cont.z + Math.sin(angle) * rad;
    const isNearStart = cont.id === 0 && Math.hypot(tx, tz) < 26;
    spawnOrganicTree(tx, tz, cont.id, isNearStart);
  }

  // 4 Expedition Objectives per Mountain:
  // 1. Base-Camp Wildlife
  // 2. Mid-Trail Ridge Wildlife (at 45% trail elevation)
  // 3. High-Pass Shrine (at 75% trail elevation)
  // 4. SUMMIT LOOT CHEST at the very top of the mountain peak!
  const { px, pz } = getPeakCenter(cont);
  const midTrailPt = getMountainTrailPoint(cont, 0.45);
  const highPassPt = getMountainTrailPoint(cont, 0.78);
  const summitY = getTerrainHeight(px, pz);

  const objectives = [
    {
      pos: new THREE.Vector3(cont.x - 10, getTerrainHeight(cont.x - 10, cont.z - 6), cont.z - 6),
      kind: 'wildlife',
      wIdx: (cont.id * 2) % WILDLIFE_MODELS.length,
      badge: `Base`,
    },
    {
      pos: midTrailPt,
      kind: 'wildlife',
      wIdx: (cont.id * 2 + 1) % WILDLIFE_MODELS.length,
      badge: `Ridge`,
    },
    {
      pos: highPassPt,
      kind: 'shrine',
      badge: `High Pass`,
    },
    {
      pos: new THREE.Vector3(px, summitY, pz),
      kind: 'chest',
      badge: `🏔️ SUMMIT`,
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
      // SUMMIT TREASURE CHEST!
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
// 6. PLAYER HERO & ANIMATED 3D SKY-DRAGON PET / MOUNT (`Flamingo.glb` + Wings)
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, getTerrainHeight(0, 9), 9);
scene.add(playerGroup);

// Ornate Lotus Trekking Staff
const staffGroup = new THREE.Group();
const staffPole = new THREE.Mesh(
  new THREE.CylinderGeometry(0.048, 0.062, 2.4, 8),
  new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.7, roughness: 0.25 })
);
staffPole.position.y = 1.2;
staffGroup.add(staffPole);
const staffHead = new THREE.Mesh(
  new THREE.OctahedronGeometry(0.24, 0),
  new THREE.MeshStandardMaterial({ color: 0x34d399, emissive: 0x10b981, emissiveIntensity: 2.5 })
);
staffHead.position.y = 2.5;
staffGroup.add(staffHead);
staffGroup.position.set(0.5, 0.1, 0.25);
playerGroup.add(staffGroup);

// 3D SKY-DRAGON COMPANION PET & SKYRIDING MOUNT!
// Follows beside the player when trekking on foot; locks underneath the player when mounted with [F]!
const dragonCompanionGroup = new THREE.Group();
dragonCompanionGroup.position.set(-2.5, getTerrainHeight(0, 9) + 2.8, 7.5);
scene.add(dragonCompanionGroup);

// Sculpted Dragon Crest & Aura Ring on the Sky-Dragon
const dragonAura = new THREE.Mesh(
  new THREE.TorusGeometry(0.85, 0.05, 8, 24).rotateX(Math.PI / 2),
  new THREE.MeshStandardMaterial({ color: 0x38bdf8, emissive: 0x0284c7, emissiveIntensity: 2.2 })
);
dragonCompanionGroup.add(dragonAura);

gltfLoader.load('https://threejs.org/examples/models/gltf/Parrot.glb', (gltf) => {
  const drake = gltf.scene;
  drake.scale.setScalar(0.042);
  drake.traverse((c) => {
    if (c.isMesh) {
      c.castShadow = true;
    }
  });
  dragonCompanionGroup.add(drake);
  if (gltf.animations && gltf.animations[0]) {
    const dm = new THREE.AnimationMixer(drake);
    dm.clipAction(gltf.animations[0]).play();
    mixers.push(dm);
  }
});

let playerMixer = null;
let playerActions = {};
let activePlayerAction = null;

gltfLoader.load('https://threejs.org/examples/models/gltf/Soldier.glb', (gltf) => {
  const model = gltf.scene;
  model.scale.setScalar(1.35);
  model.traverse((c) => {
    if (c.isMesh) {
      c.castShadow = true;
      c.receiveShadow = true;
    }
  });
  playerGroup.add(model);

  playerMixer = new THREE.AnimationMixer(model);
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

// ============================================================================
// 7. PITCHING 3D MOUNTAIN CAMPFIRES [C] (TENT + LOGS + WARM FIRE LIGHT)
// ============================================================================
const activeCampfires = [];

function pitchMountainCampfire() {
  SFX.playCampfireCrackle();
  const pos = playerGroup.position.clone();
  pos.y = getTerrainHeight(pos.x, pos.z);

  const campGroup = new THREE.Group();
  campGroup.position.copy(pos);

  // Canvas Expedition Tent beside the fire
  const tentMat = new THREE.MeshStandardMaterial({ color: 0xd97706, roughness: 0.8, side: THREE.DoubleSide });
  const tent = new THREE.Mesh(new THREE.ConeGeometry(1.9, 2.2, 4), tentMat);
  tent.position.set(-2.2, 1.1, -1.2);
  tent.rotation.y = Math.PI / 4;
  tent.castShadow = true;
  campGroup.add(tent);

  // Campfire Stone Ring & Glowing Flame
  const fireOrb = new THREE.Mesh(
    new THREE.ConeGeometry(0.55, 1.35, 8),
    new THREE.MeshStandardMaterial({ color: 0xfde047, emissive: 0xf97316, emissiveIntensity: 3.2 })
  );
  fireOrb.position.set(0, 0.68, 1.4);
  campGroup.add(fireOrb);

  const fireLight = new THREE.PointLight(0xffedd5, 3.5, 22);
  fireLight.position.set(0, 1.8, 1.4);
  campGroup.add(fireLight);

  scene.add(campGroup);
  activeCampfires.push({ group: campGroup, fireOrb, x: pos.x, z: pos.z });

  // Restore 100% Trek Stamina, Refill All 6 Dragon Vigor Orbs, Grant Well-Fed Speed Buff & Heal Nearby!
  STATE.trekStamina = 100;
  STATE.vigor = STATE.maxVigor;
  STATE.wellFedTimer = 30.0;
  updateVigorOrbsUI();

  const campHeal = SHOP_TOOLS[3].rank * 90;
  rejuvenateEnvironmentAround(pos.x, pos.z, 48.0);
  spawnShockwave(pos, 0xf97316, 18.0, 0.9);
  spawnFloatingText(pos, '⛺ CAMPFIRE PITCHED! (+100% Vigor & Well-Fed Speed)', '#fde047');
  addChatMessage(
    'gold',
    `⛺ Pitched a <strong>Mountain Base Camp</strong>! Restored 100% Trek Stamina, 6/6 Dragon Vigor Orbs, and healed nearby wildlife for +${campHeal}!`
  );

  interactables.forEach((ent) => {
    if (ent.mesh.position.distanceTo(pos) <= 45.0) {
      applyRejuvenation(ent, campHeal, 'Campfire Warmth');
    }
  });
}

// ============================================================================
// 8. TARGETING, SUMMIT CHEST LOOTING & REJUVENATION ENGINE
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
    t.kind === 'chest' ? `${Math.round(t.hp)} / ${t.maxHp} Chest Seal` : `${Math.round(t.hp)} / ${t.maxHp} Vitality`;
  document.getElementById('wow-target-blight-bar').style.width = `${blightPct}%`;
  document.getElementById('wow-target-status-txt').textContent = t.rejuvenated
    ? t.kind === 'chest'
      ? '🎁 Summit Chest Looted!'
      : '🌟 Rejuvenated & Blossoming!'
    : t.kind === 'chest'
    ? `🏔️ Climb to Summit & Cast [1] [2] to Open Chest!`
    : `${blightPct}% Suffering — Cast [1] [2] [3] [R]`;
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

function addChatMessage(colorClass, textHtml) {
  const box = document.getElementById('chat-messages');
  const div = document.createElement('div');
  div.className = `chat-line ${colorClass}`;
  div.innerHTML = textHtml;
  box.appendChild(div);
  while (box.children.length > 5) {
    box.removeChild(box.firstChild);
  }
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

function earnKarma(baseAmount, reasonText) {
  const gain = Math.round(baseAmount * getKarmaMultiplier());
  STATE.karma += gain;
  STATE.lifetimeKarma += gain;
  updateAllHUD();
  if (reasonText) {
    addChatMessage('gold', `☸️ <strong>+${gain} Karma Points</strong> (${reasonText})`);
  }
  return gain;
}

function rejuvenateEnvironmentAround(x, z, radius = 64.0) {
  addRejuvenationZone(x, z, radius);
  continentTrees.forEach((tr) => {
    if (!tr.rejuvenated && Math.hypot(tr.x - x, tr.z - z) <= radius) {
      tr.rejuvenated = true;
      const mat = hash2D(tr.x, tr.z) > 0.74 ? goldenCrownMat : lushCrownMat;
      tr.meshes.forEach((m) => (m.material = mat));
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
    const pulseKarma = earnKarma(Math.round(18 * entity.continent.diffMult), null);
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

    // If this was a SUMMIT TREASURE CHEST, pop open its golden lid and award Mythic Loot + 2x Karma!
    if (entity.kind === 'chest') {
      STATE.relicsLooted += 1;
      if (entity.mesh._chest && entity.mesh._chest._lid) {
        entity.mesh._chest._lid.rotation.x = -0.85;
      }
      SFX.playWoWLevelUpFanfare();
      const chestKarma = earnKarma(entity.continent.karmaReward * 2, `Looted ${entity.name}!`);
      spawnFloatingText(
        entity.mesh.position.clone().add(new THREE.Vector3(0, 2.2, 0)),
        `🎁 CHEST LOOTED! +${chestKarma} ☸️ & +15% Relic Power!`,
        '#fde047'
      );
      addChatMessage(
        'gold',
        `🎁 <strong>SUMMIT TREASURE LOOTED:</strong> Opened <strong>${entity.name}</strong> at the peak of ${entity.continent.shortName}! (+${chestKarma} ☸️ Karma & +15% Permanent Karma Bonus)`
      );
    } else {
      earnKarma(entity.continent.karmaReward, `Rejuvenated ${entity.name}`);
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

      document.getElementById('gift-tier').textContent = `🏔️ PEAK ${cont.roman} CONQUERED • VIRTUOUS BOON ATTAINED`;
      document.getElementById('gift-icon').textContent = cont.boonIcon;
      document.getElementById('gift-title').textContent = cont.boonName;
      document.getElementById('gift-desc').textContent = `You conquered ${cont.name} (${cont.realMeters.toLocaleString()}m)! ${cont.boonDesc}`;
      document.getElementById('gift-modal').classList.remove('wow-modal-hidden');

      addChatMessage('green', `🎉 <strong>${cont.name} Conquered!</strong> Unlocked <strong>${cont.boonName}</strong>!`);
    }
  }

  updateAllHUD();
  if (STATE.selectedTarget === entity) updateTargetFrameUI();
}

// ============================================================================
// 9. DRAGONFLIGHT SKYRIDING, VIGOR ORBS, NO-FLY ZONES & CAMPING ACTIONS
// ============================================================================
function updateVigorOrbsUI() {
  const fullOrbs = Math.floor(STATE.vigor);
  const orbs = document.querySelectorAll('#vigor-orbs-row .v-orb');
  orbs.forEach((el, idx) => {
    el.classList.toggle('full', idx < fullOrbs);
  });

  const statusEl = document.getElementById('vigor-status-txt');
  if (!canFlyOnContinent(STATE.currentContinent)) {
    statusEl.textContent = '🥾 No-Fly Peak (Trek on Foot!)';
    statusEl.style.color = '#fb7185';
  } else if (STATE.mountedOnDragon) {
    statusEl.textContent = `🐉 Skyriding (${fullOrbs}/6 Vigor)`;
    statusEl.style.color = '#38bdf8';
  } else {
    statusEl.textContent = `🐉 Companion Ready [F] (${fullOrbs}/6)`;
    statusEl.style.color = '#fef08a';
  }
}

function triggerActionSlot(slot) {
  SFX.init();
  if (STATE.cooldowns[slot] > 0) return;

  const healPwr = getHealPower();
  const aoeRad = getAoERadius();

  // [1] Sanjeevani Bolt / Open Summit Chest
  if (slot === 1) {
    let target = STATE.selectedTarget;
    if (!target || target.rejuvenated) {
      target = findNearestSufferingEntity() || STATE.selectedTarget;
      if (target) selectTarget(target);
    }
    if (!target) return;

    SFX.playCastStart();
    const castDur = CONTINENTS[2].completed ? 0.25 : 0.38;
    STATE.casting = {
      name: target.kind === 'chest' ? `Opening ${target.name}...` : `Sanjeevani Bolt → ${target.name}`,
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

  // [2] Ganga Jal Nova
  if (slot === 2) {
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

  // [3] Surya Sunbeam
  if (slot === 3) {
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

  // [4] Trekking Trail-Sprint Toggle
  if (slot === 4) {
    STATE.cooldowns[4] = STATE.cdMax[4];
    STATE.speedRunActive = !STATE.speedRunActive;
    SFX.playDragonRoarWingbeat();
    document.getElementById('slot-4').classList.toggle('active-aura', STATE.speedRunActive);
    spawnShockwave(playerGroup.position, 0xfacc15, 5.5, 0.45);
    spawnFloatingText(
      playerGroup.position,
      STATE.speedRunActive ? '🥾 TRAIL-SPRINT ON' : 'Pace Normal',
      '#fde047'
    );
    return;
  }

  // [5] Skyward Ascent / Crag Leap (Uses 1 Dragon Vigor Orb to surge 34m up a mountain cliff!)
  if (slot === 5) {
    if (STATE.vigor < 1.0) {
      addChatMessage('yellow', `⚠️ Need 1 Dragon Vigor Orb for Skyward Ascent! Pitch a <strong>Campfire [C]</strong> to refill Vigor.`);
      return;
    }
    STATE.vigor = Math.max(0, STATE.vigor - 1.0);
    updateVigorOrbsUI();
    STATE.cooldowns[5] = STATE.cdMax[5];
    SFX.playDragonRoarWingbeat();

    const forward = new THREE.Vector3(-Math.sin(cameraYaw), 0, -Math.cos(cameraYaw));
    playerGroup.position.addScaledVector(forward, 16.0);
    playerVelY = 30.0;
    isGrounded = false;
    if (STATE.mountedOnDragon) playerGroup.position.y += 22.0;

    spawnShockwave(playerGroup.position, 0x38bdf8, 6.5, 0.5);
    spawnFloatingText(playerGroup.position, '🚀 SKYWARD ASCENT! (-1 Vigor)', '#38bdf8');
    return;
  }

  // [6] Pitch Mountain Campfire [C]
  if (slot === 6) {
    STATE.cooldowns[6] = STATE.cdMax[6];
    pitchMountainCampfire();
    return;
  }

  // [7] Summon Sky-Dragon Mount [F] (Checks Sacred No-Fly Trekking Rule!)
  if (slot === 7) {
    STATE.cooldowns[7] = STATE.cdMax[7];
    if (!STATE.mountedOnDragon && !canFlyOnContinent(STATE.currentContinent)) {
      SFX.playTargetClick();
      spawnFloatingText(playerGroup.position, '🥾 SACRED NO-FLY PEAK! TREK ON FOOT!', '#fb7185');
      addChatMessage(
        'cyan',
        `🥾 <strong>${STATE.currentContinent.shortName}</strong> is a <strong>Sacred No-Fly Trekking Peak</strong>! Follow the golden torch cairns up the spiral mountain trail using <strong>Trek Sprint [4]</strong>, <strong>Crag Leap [5]</strong>, and <strong>Campfires [C]</strong>!`
      );
      return;
    }

    STATE.mountedOnDragon = !STATE.mountedOnDragon;
    SFX.playDragonRoarWingbeat();
    document.getElementById('slot-7').classList.toggle('active-aura', STATE.mountedOnDragon);
    if (STATE.mountedOnDragon) {
      playerGroup.position.y = Math.max(playerGroup.position.y + 7.5, 10.0);
      spawnShockwave(playerGroup.position, 0x38bdf8, 8.0, 0.55);
      spawnFloatingText(playerGroup.position, '🐉 MOUNTED SKY-DRAGON!', '#38bdf8');
    } else {
      spawnFloatingText(playerGroup.position, '🥾 Dismounted (Trekking Mode)', '#fef08a');
    }
    updateVigorOrbsUI();
    updateAllHUD();
    return;
  }

  // [8] Whirling Surge / World Pulse [R]
  if (slot === 8) {
    STATE.cooldowns[8] = CONTINENTS[5].completed ? STATE.cdMax[8] * 0.5 : STATE.cdMax[8];
    SFX.playWoWLevelUpFanfare();

    // Surge forward 35m if mounted on Sky-Dragon!
    if (STATE.mountedOnDragon && STATE.vigor >= 1.0) {
      STATE.vigor -= 1.0;
      const forward = new THREE.Vector3(-Math.sin(cameraYaw), 0, -Math.cos(cameraYaw));
      playerGroup.position.addScaledVector(forward, 38.0);
      updateVigorOrbsUI();
    }

    const pulseRad = aoeRad * 2.0;
    spawnShockwave(playerGroup.position, 0xfacc15, pulseRad, 1.1);
    rejuvenateEnvironmentAround(playerGroup.position.x, playerGroup.position.z, pulseRad * 1.35);

    const burstHeal = Math.round(healPwr * 1.65);
    interactables.forEach((ent) => {
      if (ent.mesh.position.distanceTo(playerGroup.position) <= pulseRad + 8) {
        applyRejuvenation(ent, burstHeal, 'Whirling Surge');
      }
    });
    spawnFloatingText(playerGroup.position, '🌟 WHIRLING SURGE!', '#fde047');
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

// Travel to a Mountain's Base Camp (Respects No-Fly rule on arrival!)
function travelToPeakBaseCamp(continentId) {
  const cont = CONTINENTS[continentId];
  if (!cont) return;
  SFX.playDragonRoarWingbeat();
  document.getElementById('worldmap-modal').classList.add('wow-modal-hidden');

  STATE.currentContinent = cont;
  const canFly = canFlyOnContinent(cont);
  STATE.mountedOnDragon = canFly;
  document.getElementById('slot-7').classList.toggle('active-aura', STATE.mountedOnDragon);

  const groundY = getTerrainHeight(cont.x, cont.z + 10);
  playerGroup.position.set(cont.x, groundY + (canFly ? 6.0 : 0.2), cont.z + 10);

  spawnShockwave(playerGroup.position, 0xfde047, 11.0, 0.75);
  spawnFloatingText(
    playerGroup.position,
    canFly ? `🐉 Arrived at ${cont.shortName} (Skyriding)` : `🥾 Arrived at ${cont.shortName} Base Camp (No-Fly Trek!)`,
    canFly ? '#38bdf8' : '#fb7185'
  );
  addChatMessage(
    'cyan',
    `🏔️ Arrived at <strong>${cont.name}</strong> (Summit: ${cont.realMeters.toLocaleString()}m • ${
      canFly ? '🐉 Skyriding Allowed' : '🥾 Sacred No-Fly Trekking Peak — Follow the Torch Cairns up the Ridge!'
    }).`
  );

  // Target the Summit Loot Chest or nearest objective on this mountain
  const chestTarget = interactables.find((e) => e.continent.id === cont.id && e.kind === 'chest' && !e.rejuvenated);
  const nextTarget = chestTarget || interactables.find((e) => e.continent.id === cont.id && !e.rejuvenated);
  if (nextTarget) selectTarget(nextTarget);
  updateVigorOrbsUI();
  updateAllHUD();
}

// ============================================================================
// 10. KARMA FORGE SHOP & 7 WORLD PEAKS EXPEDITION MAP MODALS
// ============================================================================
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
    addChatMessage('yellow', `⚠️ Need <strong>☸️ ${cost} Karma</strong> to forge ${item.name}!`);
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
        Rule: <strong style="color:${c.allowFlying ? '#38bdf8' : '#fb7185'}">${
          c.allowFlying ? '🐉 Skyriding Allowed [F]' : '🥾 Sacred No-Fly Trekking Peak'
        }</strong><br/>
        Objectives &amp; Summit Chest: <strong>${c.rejuvenatedCount} / ${c.goalCount}</strong> • Reward: ☸️ +${c.karmaReward}
      </div>
      <div class="cc-boon">${c.boonIcon} ${c.boonName}: ${c.boonDesc}</div>
      <button class="cc-fly-btn" data-cont-id="${c.id}">
        <span>${c.allowFlying ? '🐉 Fly to Base Camp' : '🥾 Trek Base Camp'}</span>
        <span>${c.completed ? '🏔️ Conquered' : 'Embark'}</span>
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
  document.getElementById('wow-current-stage').textContent = `Peak ${CONTINENTS[STATE.ascensionStage - 1].roman}/VII`;
  document.getElementById('wow-player-hp-txt').textContent = `Trek Stamina: ${Math.round(STATE.trekStamina)}% • Power: ${getHealPower()}`;
  document.getElementById('wow-player-mp-txt').textContent = `☸️ ${STATE.karma.toLocaleString()} KARMA • 🎁 ${STATE.relicsLooted}/7 CHESTS`;
  document.getElementById('stat-karma').textContent = `${STATE.karma.toLocaleString()} ☸️`;

  document.getElementById('hud-continent-name').textContent = `${c.roman}. ${c.name.toUpperCase()}`;
  const ruleEl = document.getElementById('hud-fly-rule');
  const canFly = canFlyOnContinent(c);
  ruleEl.textContent = canFly ? '🐉 Skyriding Allowed [F]' : '🥾 Sacred No-Fly Zone (Trek & Camp [C])';
  ruleEl.className = `fly-rule-pill ${canFly ? 'allowed' : 'nofly'}`;

  document.getElementById('hud-continent-state').textContent = c.completed
    ? `🏔️ Summit Conquered (${c.rejuvenatedCount}/${c.goalCount})`
    : `${c.rejuvenatedCount}/${c.goalCount} Summit Objectives`;

  document.getElementById('wq-active-title').textContent = `PEAK ${c.roman} • ${c.shortName.toUpperCase()}`;
  document.getElementById('wq-active-desc').textContent = canFly
    ? `Fly [F] or climb to loot ${c.chestName} & heal wildlife`
    : `No-Fly Peak: Sprint [4] up the torch trail & Camp [C] to reach ${c.chestName}`;
  document.getElementById('wq-active-bar').style.width = `${(c.rejuvenatedCount / c.goalCount) * 100}%`;
  document.getElementById('wq-active-cnt').textContent = `${c.rejuvenatedCount}/${c.goalCount}`;

  const listEl = document.getElementById('wq-continents-list');
  listEl.innerHTML = CONTINENTS.map(
    (cont) => `
    <div class="wq-cont-item ${cont.id === c.id ? 'active-continent' : ''} ${cont.completed ? 'completed-continent' : ''}" data-goto-cont="${cont.id}">
      <span>${cont.allowFlying ? '🐉' : '🥾'} ${cont.shortName} (${cont.realMeters}m)</span>
      <span class="wq-c-stat">${cont.completed ? '🏔️' : `${cont.rejuvenatedCount}/${cont.goalCount}`}</span>
    </div>
  `
  ).join('');

  listEl.querySelectorAll('.wq-cont-item').forEach((row) => {
    row.addEventListener('click', () => travelToPeakBaseCamp(parseInt(row.getAttribute('data-goto-cont'), 10)));
  });

  const worldPct = Math.min(100, (STATE.totalRejuvenated / STATE.totalSites) * 100);
  const conqueredPeaks = CONTINENTS.filter((ct) => ct.completed).length;
  document.getElementById('wow-rep-fill').style.width = `${worldPct}%`;
  document.getElementById('wow-rep-label').textContent = `EXPEDITION PROGRESS: ${STATE.totalRejuvenated} / ${STATE.totalSites} Summit Objectives • ${conqueredPeaks}/7 World Peaks Conquered • 🎁 ${STATE.relicsLooted} Summit Chests Looted`;
}

// ============================================================================
// 11. INPUT CONTROLS, SKYRIDING / TREKKING PHYSICS & CAMERA ORBIT
// ============================================================================
const keys = {};
let cameraYaw = 0;
let cameraPitch = 0.18;
let cameraDist = 17.5;
let isDragging = false;
let prevMouse = { x: 0, y: 0 };
let playerVelY = 0;
let isGrounded = true;

window.addEventListener('keydown', (e) => {
  SFX.init();
  if (document.activeElement === document.getElementById('chat-input')) {
    if (e.key === 'Enter') {
      const inp = document.getElementById('chat-input');
      if (inp.value.trim()) {
        addChatMessage('yellow', `[You]: ${inp.value.trim()}`);
        inp.value = '';
      }
      inp.blur();
    }
    return;
  }

  const k = e.key.toLowerCase();
  keys[k] = true;

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
  else if (k === 'c') triggerActionSlot(6);
  else if (k === 'f') triggerActionSlot(7);
  else if (k === 'r') triggerActionSlot(8);
  else if (k === 'k' || k === 'b') toggleModal('shop-modal');
  else if (k === 'm') toggleModal('worldmap-modal');
  else if (e.key === 'Enter') {
    document.getElementById('gift-modal').classList.add('wow-modal-hidden');
  } else if (e.key === ' ' && !STATE.mountedOnDragon && isGrounded) {
    SFX.playDragonRoarWingbeat();
    playerVelY = 18.0;
    isGrounded = false;
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
  document.getElementById('shop-modal').classList.add('wow-modal-hidden');
  document.getElementById('worldmap-modal').classList.add('wow-modal-hidden');
  if (hidden) {
    if (id === 'shop-modal') renderKarmaShopModal();
    if (id === 'worldmap-modal') renderWorldMapModal();
    el.classList.remove('wow-modal-hidden');
  }
}

for (let s = 1; s <= 8; s++) {
  const el = document.getElementById(`slot-${s}`);
  if (el) el.addEventListener('click', () => triggerActionSlot(s));
}

document.getElementById('btn-shop').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('btn-close-shop').addEventListener('click', () =>
  document.getElementById('shop-modal').classList.add('wow-modal-hidden')
);
document.getElementById('btn-worldmap').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('minimap-canvas').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('btn-close-map').addEventListener('click', () =>
  document.getElementById('worldmap-modal').classList.add('wow-modal-hidden')
);
document.getElementById('btn-claim-gift').addEventListener('click', () =>
  document.getElementById('gift-modal').classList.add('wow-modal-hidden')
);
document.getElementById('btn-audio-toggle').addEventListener('click', () => SFX.toggleMute());

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
  }
});

window.addEventListener('pointermove', (e) => {
  if (!isDragging) return;
  const dx = e.clientX - prevMouse.x;
  const dy = e.clientY - prevMouse.y;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;
  cameraYaw -= dx * 0.0065;
  cameraPitch = Math.max(0.08, Math.min(1.22, cameraPitch + dy * 0.0055));
});

window.addEventListener('pointerup', () => {
  isDragging = false;
});

window.addEventListener('wheel', (e) => {
  cameraDist = Math.max(7.0, Math.min(44.0, cameraDist + e.deltaY * 0.015));
});

// ============================================================================
// 12. BORDERLESS RADAR & 3D FLOATING NAMEPLATES
// ============================================================================
const minimapCanvas = document.getElementById('minimap-canvas');
const mCtx = minimapCanvas.getContext('2d');

function drawMinimap() {
  const w = minimapCanvas.width;
  const h = minimapCanvas.height;
  const cx = w / 2;
  const cy = h / 2;
  const scale = STATE.mountedOnDragon ? 0.14 : 0.42;

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
  ).textContent = `⛰️ Elevation: ${scaledAlt.toLocaleString()}m / ${STATE.currentContinent.realMeters.toLocaleString()}m`;
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
// 13. MAIN 60FPS GAME LOOP (DRAGON COMPANION, NO-FLY ENFORCEMENT, VIGOR, BLOOM)
// ============================================================================
const clock = new THREE.Clock();
let chakraTimer = 0;

setTimeout(() => {
  // Select the Sahyadri Summit Chest or nearest wildlife on launch
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

  for (let i = 0; i < MAX_CLEANSE_ZONES; i++) {
    const cz = cleanseCenters[i];
    if (cz.z < cz.w) {
      cz.z = Math.min(cz.w, cz.z + dt * 38.0);
    }
  }

  // Recharge Dragonflight Vigor Orbs automatically over time
  const vigorRegenRate = (0.32 + (SHOP_TOOLS[1].rank - 1) * 0.08) * (CONTINENTS[0].completed ? 1.4 : 1.0);
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

  // Update 3D Sky-Dragon Companion Position:
  // If mounted [F], Dragon locks directly beneath the player as a Skyriding Mount!
  // If trekking on foot, Dragon circles gracefully beside/above the player as a loyal Pet!
  if (STATE.mountedOnDragon) {
    dragonCompanionGroup.position.set(
      playerGroup.position.x,
      playerGroup.position.y + 0.6,
      playerGroup.position.z
    );
    dragonCompanionGroup.rotation.y = playerGroup.rotation.y + Math.PI;
  } else {
    const petTargetX = playerGroup.position.x + Math.cos(elapsed * 1.1) * 3.2;
    const petTargetZ = playerGroup.position.z + Math.sin(elapsed * 1.1) * 3.2;
    const petTargetY = playerGroup.position.y + 3.2 + Math.sin(elapsed * 2.6) * 0.45;
    dragonCompanionGroup.position.x = THREE.MathUtils.lerp(dragonCompanionGroup.position.x, petTargetX, dt * 3.5);
    dragonCompanionGroup.position.z = THREE.MathUtils.lerp(dragonCompanionGroup.position.z, petTargetZ, dt * 3.5);
    dragonCompanionGroup.position.y = THREE.MathUtils.lerp(dragonCompanionGroup.position.y, petTargetY, dt * 3.5);
    dragonCompanionGroup.rotation.y = elapsed * 1.1 + Math.PI / 2;
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

  for (let i = 0; i < mixers.length; i++) {
    mixers[i].update(dt);
  }

  // Player Movement (Skyriding vs Mountain Trail Trekking)
  let moveX = 0;
  let moveZ = 0;
  if (keys['w'] || keys['arrowup']) moveZ -= 1;
  if (keys['s'] || keys['arrowdown']) moveZ += 1;
  if (keys['a'] || keys['arrowleft']) moveX -= 1;
  if (keys['d'] || keys['arrowright']) moveX += 1;

  const isMoving = moveX !== 0 || moveZ !== 0;

  if (isMoving) {
    const len = Math.hypot(moveX, moveZ);
    moveX /= len;
    moveZ /= len;

    const speed = STATE.mountedOnDragon
      ? 52.0 * getDragonMobilityMult()
      : (STATE.speedRunActive ? 25.0 : 11.5) * getTrekMobilityMult();

    const sinY = Math.sin(cameraYaw);
    const cosY = Math.cos(cameraYaw);
    const dx = moveX * cosY + moveZ * sinY;
    const dz = -moveX * sinY + moveZ * cosY;

    playerGroup.position.x += dx * speed * dt;
    playerGroup.position.z += dz * speed * dt;
    playerGroup.rotation.y = Math.atan2(dx, dz) + Math.PI;
    setPlayerAnim('Run');
  } else {
    setPlayerAnim('Idle');
  }

  const groundY = Math.max(-1.2, getTerrainHeight(playerGroup.position.x, playerGroup.position.z));
  if (STATE.mountedOnDragon) {
    if (keys[' ']) playerGroup.position.y += 32.0 * dt;
    if (keys['c'] || keys['shift']) playerGroup.position.y -= 30.0 * dt;
    playerGroup.position.y = Math.max(groundY + 2.5, playerGroup.position.y);
  } else {
    playerVelY -= 32.0 * dt;
    playerGroup.position.y += playerVelY * dt;
    if (playerGroup.position.y <= groundY) {
      playerGroup.position.y = groundY;
      playerVelY = 0;
      isGrounded = true;
    }
  }

  // Detect Mountain Range Entry & Enforce Sacred No-Fly Trekking Rule!
  const nearCont = getNearestContinent(playerGroup.position.x, playerGroup.position.z);
  if (nearCont !== STATE.currentContinent) {
    STATE.currentContinent = nearCont;
    SFX.playDragonRoarWingbeat();
    if (STATE.mountedOnDragon && !canFlyOnContinent(nearCont)) {
      STATE.mountedOnDragon = false;
      document.getElementById('slot-7').classList.remove('active-aura');
      spawnFloatingText(playerGroup.position, `🥾 ENTERED NO-FLY TREKKING PEAK: ${nearCont.shortName}!`, '#fb7185');
      addChatMessage(
        'cyan',
        `🥾 Entered <strong>${nearCont.name}</strong> — Sacred No-Fly Trekking Zone! Your Sky-Dragon switched to Pet Companion mode. Sprint up the torch-lit ridge trail!`
      );
    } else {
      addChatMessage('cyan', `🏔️ Entered <strong>${nearCont.name}</strong> (Peak: ${nearCont.realMeters.toLocaleString()}m).`);
    }
    updateVigorOrbsUI();
    updateAllHUD();
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
    STATE.casting.elapsed += dt;
    const pct = Math.min(100, (STATE.casting.elapsed / STATE.casting.duration) * 100);
    document.getElementById('cast-fill').style.width = `${pct}%`;
    document.getElementById('cast-timer').textContent = `${Math.max(0, STATE.casting.duration - STATE.casting.elapsed).toFixed(1)}s`;
    if (STATE.casting.elapsed >= STATE.casting.duration) {
      const done = STATE.casting.onComplete;
      STATE.casting = null;
      document.getElementById('wow-castbar').classList.add('cast-hidden');
      if (done) done();
    }
  }

  for (let s = 1; s <= 8; s++) {
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

  const camTarget = new THREE.Vector3(playerGroup.position.x, playerGroup.position.y + 2.3, playerGroup.position.z);
  const camX = camTarget.x + Math.sin(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camZ = camTarget.z + Math.cos(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camY = camTarget.y + Math.sin(cameraPitch) * cameraDist;
  const minCamY = getTerrainHeight(camX, camZ) + 1.4;

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
