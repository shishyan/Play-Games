import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import * as SkeletonUtils from 'three/addons/utils/SkeletonUtils.js';

// ============================================================================
// WORLD OF DHARMA — 7 CONTINENTS, KARMA CURRENCY & SACRED FORGE MMORPG
// Classic WoW UI • Live GPU Blight-to-Lush Terrain Shader • Boundless Flight
// ============================================================================

const CONTINENTS = [
  {
    id: 0,
    roman: 'I',
    name: 'Jambudvipa — The Ashen Groves',
    shortName: 'I. Jambudvipa',
    x: 0,
    z: 0,
    radius: 175,
    tier: 1,
    diffMult: 1.0,
    maxHpBase: 120,
    karmaReward: 95,
    boonIcon: '☀️',
    boonName: 'Boon of Surya (Solar Renewal)',
    boonDesc: '+35% Sanjeevani Healing Power & +20% Karma Generation from all deeds.',
    lushColor: new THREE.Color(0x2e7d32), // Deep Emerald Forest
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 1,
    roman: 'II',
    name: 'Plakshadvipa — Weeping Fig Basin',
    shortName: 'II. Plakshadvipa',
    x: 0,
    z: -420,
    radius: 175,
    tier: 2,
    diffMult: 1.8,
    maxHpBase: 220,
    karmaReward: 165,
    boonIcon: '💧',
    boonName: 'Boon of Saraswati (Living Waters)',
    boonDesc: 'Ganga Jal Nova [2] radius expands by +50% and restores +60 bonus Vitality.',
    lushColor: new THREE.Color(0x1b8a6b), // Turquoise-Jade Sanctuary
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 2,
    roman: 'III',
    name: 'Salmalidvipa — Silk-Cotton Crags',
    shortName: 'III. Salmalidvipa',
    x: 380,
    z: -240,
    radius: 175,
    tier: 3,
    diffMult: 2.8,
    maxHpBase: 360,
    karmaReward: 260,
    boonIcon: '⚡',
    boonName: 'Boon of Hanuman (Supersonic Wind)',
    boonDesc: 'Doubles Vayu Speed-Run [4] & Garuda Flight [F] velocity and cuts spell cast time by 35%.',
    lushColor: new THREE.Color(0x558b2f), // Golden-Olive Blossom Highland
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 3,
    roman: 'IV',
    name: 'Kushadvipa — Scorched Grasslands',
    shortName: 'IV. Kushadvipa',
    x: 380,
    z: 240,
    radius: 175,
    tier: 4,
    diffMult: 4.2,
    maxHpBase: 540,
    karmaReward: 390,
    boonIcon: '🌸',
    boonName: 'Boon of Lakshmi (Abundant Grace)',
    boonDesc: 'Doubles all Karma Points (☸️) earned across the universe and empowers Sunbeam [3].',
    lushColor: new THREE.Color(0x689f38), // Golden Meadow Steppe
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 4,
    roman: 'V',
    name: 'Kraunchadvipa — Heron Peaks',
    shortName: 'V. Kraunchadvipa',
    x: 0,
    z: 420,
    radius: 175,
    tier: 5,
    diffMult: 6.0,
    maxHpBase: 780,
    karmaReward: 560,
    boonIcon: '🐘',
    boonName: 'Boon of Ganesha (Obstacle Breaker)',
    boonDesc: 'All spells automatically chain-heal 2 additional suffering targets within 25m.',
    lushColor: new THREE.Color(0x26a69a), // Alpine Teal Sanctuary
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 5,
    roman: 'VI',
    name: 'Shakadvipa — Petrified Teak Highlands',
    shortName: 'VI. Shakadvipa',
    x: -380,
    z: 240,
    radius: 175,
    tier: 6,
    diffMult: 8.5,
    maxHpBase: 1100,
    karmaReward: 820,
    boonIcon: '🔱',
    boonName: 'Boon of Shiva (Kailash Omnipresence)',
    boonDesc: 'Amrita World-Pulse [R] cooldown reduced by 50% and cleanses entire regions at once.',
    lushColor: new THREE.Color(0x43a047), // Sacred Cedar Emerald
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
  {
    id: 6,
    roman: 'VII',
    name: 'Pushkaradvipa — Eternal Lotus Citadel',
    shortName: 'VII. Pushkaradvipa',
    x: -380,
    z: -240,
    radius: 175,
    tier: 7,
    diffMult: 12.0,
    maxHpBase: 1600,
    karmaReward: 1500,
    boonIcon: '🦅',
    boonName: 'Boon of Vishnu (Vaikuntha Avatar)',
    boonDesc: 'Ultimate Cosmic Ascension: Passive Aura of Renewal heals all suffering beings around you as you fly!',
    lushColor: new THREE.Color(0x38b2ac), // Celestial Lotus Gold-Emerald
    rejuvenatedCount: 0,
    goalCount: 4,
    completed: false,
  },
];

// ============================================================================
// KARMA EMPORIUM: SACRED TOOLS, ITEMS & ABILITY UPGRADES (UNIVERSAL CURRENCY)
// ============================================================================
const SHOP_TOOLS = [
  {
    id: 'danda_staff',
    icon: '🦯',
    name: 'Brahmadanda Lotus Staff',
    category: 'Sacred Tool • Upgrades [1] & [3]',
    rank: 1,
    maxRank: 10,
    baseCost: 80,
    costMult: 1.55,
    desc: 'Channeling staff carved from celestial sandalwood. Amplifies the rejuvenation power of Sanjeevani Bolt [1] and Sunbeam [3].',
    bonusText: (r) => `Current: +${(r - 1) * 45} Healing Power (Next: +${r * 45})`,
  },
  {
    id: 'kamandalu_vessel',
    icon: '🏺',
    name: 'Amrita Kamandalu Vessel',
    category: 'Sacred Tool • Upgrades [2] & [R]',
    rank: 1,
    maxRank: 10,
    baseCost: 95,
    costMult: 1.55,
    desc: 'Eternally flowing vessel of Himalayan Ganga Jal. Expands AoE radius and potency of Ganga Nova [2] and World Pulse [R].',
    bonusText: (r) => `Current: ${22 + (r - 1) * 5}m AoE Radius & +${(r - 1) * 35} AoE Heal`,
  },
  {
    id: 'garuda_plume',
    icon: '🦅',
    name: 'Suvarna Garuda Plume',
    category: 'Sky Relic • Upgrades [4] & [F]',
    rank: 1,
    maxRank: 7,
    baseCost: 110,
    costMult: 1.6,
    desc: 'Golden wing-feather of Garuda. Boosts your Speed-Running [4] velocity and Sky-Flight [F] cruise speed across continents.',
    bonusText: (r) => `Current: +${(r - 1) * 25}% Flight & Sprint Speed`,
  },
  {
    id: 'rudraksha_mala',
    icon: '📿',
    name: '108-Bead Siddha Mala',
    category: 'Karma Amplifier • Passive Relic',
    rank: 1,
    maxRank: 8,
    baseCost: 120,
    costMult: 1.65,
    desc: 'Sacred prayer beads that resonate with universal Dharma, multiplying the Karma Points (☸️) earned from every healing act.',
    bonusText: (r) => `Current: +${(r - 1) * 30}% Karma Points Earned`,
  },
  {
    id: 'sanjeevani_elixir',
    icon: '🧪',
    name: 'Soma-Sanjeevani Elixir',
    category: 'Consumable Item • Instant Burst',
    rank: 0,
    maxRank: 99,
    baseCost: 140,
    costMult: 1.15,
    desc: 'Instantly releases a 65-meter Golden Supernova around you, restoring +320 Rejuvenation to all suffering beings in range!',
    bonusText: () => `Instant Use on Purchase: 65m +320 Rejuvenation Wave!`,
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
    desc: 'Summons an orbiting golden Chakra above your head that automatically fires healing bolts at nearby suffering creatures every 1.5s!',
    bonusText: (r) => (r === 0 ? 'Not Yet Forged (Buy Rank 1 to Summon!)' : `Active: Auto-heals nearby suffering for ${r * 45}/pulse`),
  },
];

const STATE = {
  karma: 350,          // Current spendable Karma Points (Universal Currency)
  lifetimeKarma: 350,  // Total Karma generated
  ascensionStage: 1,   // 1 to 7 (unlocked by rejuvenating continents)
  totalRejuvenated: 0,
  totalSites: 28,      // 7 continents * 4 major suffering clusters
  currentContinent: CONTINENTS[0],
  speedRunActive: true, // Speed-running enabled right from the start!
  flyingActive: false,  // Toggle anytime with [F]
  selectedTarget: null,
  casting: null,
  cooldowns: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0 },
  cdMax:     { 1: 0.9, 2: 2.2, 3: 3.0, 4: 0.5, 5: 1.8, 6: 3.5, 7: 0.4, 8: 6.0 },
};

// ============================================================================
// HELPER STATS CALCULATED FROM SHOP TOOLS & CONTINENT BOONS
// ============================================================================
function getHealPower() {
  const staffRank = SHOP_TOOLS[0].rank;
  const boonMult = CONTINENTS[0].completed ? 1.35 : 1.0;
  return Math.round((85 + (staffRank - 1) * 45) * boonMult);
}

function getAoERadius() {
  const vesselRank = SHOP_TOOLS[1].rank;
  const boonMult = CONTINENTS[1].completed ? 1.5 : 1.0;
  return Math.round((22 + (vesselRank - 1) * 5) * boonMult);
}

function getAoEBonus() {
  const vesselRank = SHOP_TOOLS[1].rank;
  return (vesselRank - 1) * 35 + (CONTINENTS[1].completed ? 60 : 0);
}

function getKarmaMultiplier() {
  const malaRank = SHOP_TOOLS[3].rank;
  let mult = 1.0 + (malaRank - 1) * 0.3;
  if (CONTINENTS[0].completed) mult += 0.2;
  if (CONTINENTS[3].completed) mult *= 2.0;
  return mult;
}

function getMobilityMultiplier() {
  const plumeRank = SHOP_TOOLS[2].rank;
  let mult = 1.0 + (plumeRank - 1) * 0.25;
  if (CONTINENTS[2].completed) mult *= 1.65;
  return mult;
}

// ============================================================================
// 1. SCENE, CAMERA, RENDERER & CELESTIAL SKY DOME
// ============================================================================
const container = document.getElementById('canvas-container');
const nameplatesContainer = document.getElementById('nameplates-container');

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x5282ad);
scene.fog = new THREE.FogExp2(0x6492ba, 0.00085); // Long view distance so players can see distant continents while flying!

const camera = new THREE.PerspectiveCamera(58, window.innerWidth / window.innerHeight, 0.5, 2200);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.15;
container.appendChild(renderer.domElement);

// Expansive Sky Dome covering all 7 Continents
const skyGeo = new THREE.SphereGeometry(1850, 32, 24);
const skyMat = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  depthWrite: false,
  uniforms: {
    topColor: { value: new THREE.Color(0x163c6e) },
    horizonColor: { value: new THREE.Color(0x88b8de) },
    sunDir: { value: new THREE.Vector3(0.52, 0.46, -0.71).normalize() },
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
    uniform vec3 topColor;
    uniform vec3 horizonColor;
    uniform vec3 sunDir;
    void main() {
      vec3 dir = normalize(vWorldPos);
      float h = clamp(dir.y * 1.4 + 0.12, 0.0, 1.0);
      vec3 col = mix(horizonColor, topColor, pow(h, 0.65));
      float sunAmt = max(dot(dir, sunDir), 0.0);
      col += vec3(1.0, 0.88, 0.6) * pow(sunAmt, 16.0) * 0.48;
      col += vec3(1.0, 0.97, 0.88) * smoothstep(0.996, 0.9996, sunAmt);
      gl_FragColor = vec4(col, 1.0);
    }
  `,
});
scene.add(new THREE.Mesh(skyGeo, skyMat));

const hemiLight = new THREE.HemisphereLight(0xdff2ff, 0x3b4d34, 0.9);
hemiLight.position.set(0, 300, 0);
scene.add(hemiLight);

const sunLight = new THREE.DirectionalLight(0xfff2d6, 2.25);
sunLight.position.set(160, 240, -140);
sunLight.castShadow = true;
sunLight.shadow.mapSize.width = 2048;
sunLight.shadow.mapSize.height = 2048;
sunLight.shadow.camera.near = 10;
sunLight.shadow.camera.far = 650;
const d = 140;
sunLight.shadow.camera.left = -d;
sunLight.shadow.camera.right = d;
sunLight.shadow.camera.top = d;
sunLight.shadow.camera.bottom = -d;
sunLight.shadow.bias = -0.0005;
scene.add(sunLight);

// ============================================================================
// 2. MULTI-CONTINENT ARCHIPELAGO TERRAIN & LIVE GPU REJUVENATION SHADER
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
    freq *= 2.02;
    amp *= 0.5;
  }
  return v;
}

// Compute height across the 7 Continents Archipelago (1500 x 1500m World)
function getTerrainHeight(x, z) {
  let maxContinentH = -8.5; // Deep Cosmic Ocean bed between continents

  for (let i = 0; i < CONTINENTS.length; i++) {
    const c = CONTINENTS[i];
    const dx = x - c.x;
    const dz = z - c.z;
    const dist = Math.hypot(dx, dz);

    if (dist < c.radius * 1.25) {
      const normD = dist / c.radius;
      // Smooth island dome profile with flat sanctuary plaza at center of each continent
      const mask = Math.max(0.0, 1.0 - normD * normD);
      const smoothMask = mask * mask * (3.0 - 2.0 * mask);

      const centerPlazaFlat = Math.min(1.0, Math.max(0.0, (dist - 18.0) / 38.0));
      const n1 = fbm((x + i * 37) * 0.015, (z + i * 53) * 0.015);
      const n2 = fbm(x * 0.045, z * 0.045);

      // Outer mountain rim around each continent
      let rimHills = 0;
      if (normD > 0.52 && normD < 0.96) {
        const rimFactor = Math.sin(((normD - 0.52) / 0.44) * Math.PI);
        rimHills = rimFactor * (14.0 + i * 2.5) * n1;
      }

      const h =
        -7.5 +
        smoothMask * (10.5 + (n1 - 0.35) * 14.0 * centerPlazaFlat + (n2 - 0.5) * 3.0 * centerPlazaFlat + rimHills);

      if (h > maxContinentH) {
        maxContinentH = h;
      }
    }
  }
  return maxContinentH;
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

// GPU Shader Uniform Arrays for 32 Rejuvenation Zones (X, Z, CurrentRadius, TargetRadius)
const MAX_CLEANSE_ZONES = 32;
const cleanseCenters = [];
for (let i = 0; i < MAX_CLEANSE_ZONES; i++) {
  cleanseCenters.push(new THREE.Vector4(99999, 99999, 0.0, 0.0));
}

// Center of Jambudvipa Sanctuary Altar starts partially consecrated (14m golden circle)
cleanseCenters[0].set(0, 0, 14.5, 14.5);
let nextCleanseIdx = 1;

function addRejuvenationZone(x, z, radius = 65.0) {
  const idx = nextCleanseIdx % MAX_CLEANSE_ZONES;
  cleanseCenters[idx].set(x, z, 2.0, radius);
  nextCleanseIdx++;
}

const WORLD_SIZE = 1450;
const terrainGeo = new THREE.PlaneGeometry(WORLD_SIZE, WORLD_SIZE, 280, 280);
terrainGeo.rotateX(-Math.PI / 2);
const posAttr = terrainGeo.attributes.position;
for (let i = 0; i < posAttr.count; i++) {
  const vx = posAttr.getX(i);
  const vz = posAttr.getZ(i);
  posAttr.setY(i, getTerrainHeight(vx, vz));
}
terrainGeo.computeVertexNormals();

// Custom GLSL Terrain Shader: Dynamically transforms Blighted Ashen Wasteland -> Lush Golden-Emerald Paradise!
const terrainShaderMat = new THREE.ShaderMaterial({
  uniforms: {
    uCleanseZones: { value: cleanseCenters },
    uSunDir: { value: new THREE.Vector3(0.52, 0.46, -0.71).normalize() },
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
      return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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

    void main() {
      float n1 = noise(vWorldPos.xz * 0.08);
      float n2 = noise(vWorldPos.xz * 0.35);
      float slope = 1.0 - max(dot(vNormal, vec3(0.0, 1.0, 0.0)), 0.0);

      // Compute how rejuvenated this world coordinate is (0.0 = Suffering Blight, 1.0 = Rejuvenated Paradise)
      float cleanse = 0.0;
      float ringEdge = 0.0;
      for (int i = 0; i < ${MAX_CLEANSE_ZONES}; i++) {
        vec4 cz = uCleanseZones[i];
        if (cz.z > 0.1) {
          float d = distance(vWorldPos.xz, cz.xy);
          float factor = 1.0 - smoothstep(cz.z - 8.0, cz.z + 2.0, d);
          cleanse = max(cleanse, factor);
          float edge = smoothstep(cz.z - 2.5, cz.z - 0.5, d) * (1.0 - smoothstep(cz.z - 0.5, cz.z + 1.5, d));
          ringEdge = max(ringEdge, edge);
        }
      }

      // 1. SUFFERING / KALI BLIGHT PALETTE (Charred purple-ash soil, cracked necrotic veins, dead scrub)
      vec3 blightGrass = mix(vec3(0.22, 0.18, 0.25), vec3(0.32, 0.25, 0.29), n1);
      float darkVein = smoothstep(0.62, 0.78, n2);
      blightGrass = mix(blightGrass, vec3(0.45, 0.16, 0.48), darkVein * 0.45);

      // 2. REJUVENATED DHARMA PALETTE (Rich emerald grass, sunny golden wildflowers, cobblestone paths)
      vec3 lushGrass = mix(vec3(0.18, 0.52, 0.22), vec3(0.38, 0.72, 0.26), n1);
      float flowers = smoothstep(0.68, 0.85, n2);
      lushGrass = mix(lushGrass, vec3(0.95, 0.82, 0.28), flowers * 0.4);

      vec3 surfaceCol = mix(blightGrass, lushGrass, cleanse);

      // Sandy coastline near ocean level
      if (vWorldPos.y < 0.35) {
        float beach = 1.0 - clamp((vWorldPos.y + 1.5) / 1.85, 0.0, 1.0);
        vec3 sandCol = mix(vec3(0.42, 0.38, 0.36), vec3(0.82, 0.74, 0.54), cleanse);
        surfaceCol = mix(surfaceCol, sandCol, beach * 0.85);
      }

      // Steep mountain rock cliffs
      if (slope > 0.26 || vWorldPos.y > 14.0) {
        float rk = clamp((slope - 0.24) * 2.5 + max(0.0, (vWorldPos.y - 14.0) / 14.0), 0.0, 1.0);
        vec3 rockCol = mix(vec3(0.26, 0.24, 0.28), vec3(0.48, 0.50, 0.54), cleanse);
        surfaceCol = mix(surfaceCol, rockCol, rk);
      }

      // Glowing Golden Wave at the boundary of Rejuvenation!
      surfaceCol += vec3(0.98, 0.84, 0.32) * ringEdge * 0.75;

      // Sun & Sky Lighting
      float diff = max(dot(vNormal, uSunDir), 0.0);
      vec3 lit = surfaceCol * (0.52 + diff * 0.68);

      // Atmospheric distance fog
      float camDist = length(cameraPosition - vWorldPos);
      float fogF = 1.0 - exp(-camDist * 0.00075);
      vec3 fogCol = vec3(0.39, 0.57, 0.73);
      gl_FragColor = vec4(mix(lit, fogCol, clamp(fogF, 0.0, 0.85)), 1.0);
    }
  `,
});

const terrainMesh = new THREE.Mesh(terrainGeo, terrainShaderMat);
terrainMesh.receiveShadow = true;
scene.add(terrainMesh);

// Expansive Cosmic Ocean connecting the 7 Continents
const oceanGeo = new THREE.PlaneGeometry(WORLD_SIZE * 1.4, WORLD_SIZE * 1.4, 90, 90);
oceanGeo.rotateX(-Math.PI / 2);
const oceanMat = new THREE.ShaderMaterial({
  transparent: true,
  uniforms: { uTime: { value: 0 } },
  vertexShader: `
    uniform float uTime;
    varying vec3 vWorldPos;
    void main() {
      vec3 p = position;
      p.y += sin(p.x * 0.06 + uTime * 2.0) * 0.35 + cos(p.z * 0.06 + uTime * 1.6) * 0.35;
      vec4 wp = modelMatrix * vec4(p, 1.0);
      vWorldPos = wp.xyz;
      gl_Position = projectionMatrix * viewMatrix * wp;
    }
  `,
  fragmentShader: `
    uniform float uTime;
    varying vec3 vWorldPos;
    void main() {
      float w = sin(vWorldPos.x * 0.12 + uTime * 2.2) * cos(vWorldPos.z * 0.12 - uTime * 1.8);
      vec3 deep = vec3(0.06, 0.28, 0.48);
      vec3 crest = vec3(0.16, 0.56, 0.78);
      vec3 col = mix(deep, crest, w * 0.5 + 0.5);
      gl_FragColor = vec4(col, 0.88);
    }
  `,
});
const oceanMesh = new THREE.Mesh(oceanGeo, oceanMat);
oceanMesh.position.y = -1.6;
scene.add(oceanMesh);

// ============================================================================
// 3. TREES, SANCTUARY ALTARS & SUFFERING SITES ACROSS ALL 7 CONTINENTS
// ============================================================================
const interactables = [];
const continentTrees = []; // Withered trees that bloom green & scale up when rejuvenated!

const barkDarkMat = new THREE.MeshStandardMaterial({ color: 0x3b2d26, roughness: 0.9, flatShading: true });
const witheredCrownMat = new THREE.MeshStandardMaterial({ color: 0x4a3b4e, roughness: 0.85, flatShading: true });
const lushCrownMat = new THREE.MeshStandardMaterial({ color: 0x2e8540, roughness: 0.7, flatShading: true });
const goldenCrownMat = new THREE.MeshStandardMaterial({ color: 0xeab308, roughness: 0.65, flatShading: true });
const stoneMat = new THREE.MeshStandardMaterial({ color: 0x78808a, roughness: 0.75, flatShading: true });

function createOrganicCrown(radius) {
  const geo = new THREE.IcosahedronGeometry(radius, 1);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const vx = p.getX(i);
    const vy = p.getY(i);
    const vz = p.getZ(i);
    const n = 0.82 + 0.34 * hash2D(vx * 2.7 + vy, vz * 2.7 - vy);
    p.setXYZ(i, vx * n, vy * (0.8 + 0.25 * n), vz * n);
  }
  geo.computeVertexNormals();
  return geo;
}
const treeCrownGeo = createOrganicCrown(2.8);

function spawnTree(x, z, continentId) {
  const y = getTerrainHeight(x, z);
  if (y < 0.2) return;
  const group = new THREE.Group();
  group.position.set(x, y, z);

  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.52, 4.0, 6), barkDarkMat);
  trunk.position.y = 2.0;
  trunk.castShadow = true;
  group.add(trunk);

  // Start withered & shrunken under Kali Blight!
  const crown = new THREE.Mesh(treeCrownGeo, witheredCrownMat);
  crown.position.y = 4.6;
  crown.scale.setScalar(0.55);
  crown.castShadow = true;
  group.add(crown);

  scene.add(group);
  continentTrees.push({ group, crown, x, z, continentId, rejuvenated: false });
}

function createNameplateDOM(entity) {
  const el = document.createElement('div');
  el.className = 'nameplate';
  el.innerHTML = `
    <div class="np-title">
      <span class="np-lvl">[T${entity.tier}]</span>
      <span class="np-name">${entity.name}</span>
    </div>
    <div class="np-bar-bg">
      <div class="np-bar-fill" style="width: ${(entity.hp / entity.maxHp) * 100}%"></div>
    </div>
  `;
  el.addEventListener('pointerdown', (e) => {
    e.stopPropagation();
    selectTarget(entity);
  });
  nameplatesContainer.appendChild(el);
  entity.nameplateEl = el;
  entity.npFillEl = el.querySelector('.np-bar-fill');
}

const gltfLoader = new GLTFLoader();
const mixers = [];
const modelCache = {};

const WILDLIFE_MODELS = [
  {
    url: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
    scale: 0.024,
    icon: '🦊',
    species: 'Forest Fox',
  },
  {
    url: 'https://threejs.org/examples/models/gltf/Horse.glb',
    scale: 0.015,
    icon: '🐎',
    species: 'Ashva Stallion',
  },
  {
    url: 'https://threejs.org/examples/models/gltf/Stork.glb',
    scale: 0.018,
    icon: '🦢',
    species: 'Himalayan Saras Crane',
    flyHeight: 2.8,
  },
  {
    url: 'https://threejs.org/examples/models/gltf/Flamingo.glb',
    scale: 0.018,
    icon: '🦩',
    species: 'Sun-Winged Hamsa',
    flyHeight: 3.0,
  },
];

// Build Sanctuary Altars, Trees, and 4 Suffering Sites per Continent (7 * 4 = 28 Total Sites)
CONTINENTS.forEach((cont) => {
  const cy = getTerrainHeight(cont.x, cont.z);

  // Central Continent Beacon & Altar
  const altar = new THREE.Group();
  altar.position.set(cont.x, cy, cont.z);
  const base = new THREE.Mesh(new THREE.CylinderGeometry(4.5, 5.2, 0.8, 12), stoneMat);
  base.position.y = 0.4;
  altar.add(base);

  // Towering Sky Beacon Pillar so players flying high in the sky can spot all 7 Continents!
  const skyBeaconGeo = new THREE.CylinderGeometry(0.6, 0.6, 160, 12, 1, true);
  const skyBeaconMat = new THREE.MeshBasicMaterial({
    color: cont.id === 0 ? 0xfacc15 : 0xa855f7,
    transparent: true,
    opacity: 0.26,
    side: THREE.DoubleSide,
  });
  const skyBeacon = new THREE.Mesh(skyBeaconGeo, skyBeaconMat);
  skyBeacon.position.y = 80;
  altar.add(skyBeacon);
  cont.skyBeaconMat = skyBeaconMat;

  // 4 Sanctuary Pillars around Altar
  for (let p = 0; p < 4; p++) {
    const a = (p * Math.PI) / 2 + Math.PI / 4;
    const pillar = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.55, 5.0, 8), stoneMat);
    pillar.position.set(Math.cos(a) * 8.2, 2.5, Math.sin(a) * 8.2);
    pillar.castShadow = true;
    altar.add(pillar);
  }
  scene.add(altar);

  // Spawn 28 Withered Trees per Continent
  for (let t = 0; t < 28; t++) {
    const angle = (t / 28) * Math.PI * 2 + hash2D(cont.id, t) * 0.4;
    const rad = 22 + hash2D(t, cont.id * 7) * 95;
    spawnTree(cont.x + Math.cos(angle) * rad, cont.z + Math.sin(angle) * rad, cont.id);
  }

  // Spawn 4 Major Suffering Sites on this Continent (2 Wildlife, 1 Blighted Lotus Grove, 1 Corrupted Obelisk)
  const siteOffsets = [
    { dx: -11, dz: -8, type: 'wildlife', wIdx: (cont.id * 2) % WILDLIFE_MODELS.length },
    { dx: 14, dz: -6, type: 'wildlife', wIdx: (cont.id * 2 + 1) % WILDLIFE_MODELS.length },
    { dx: -15, dz: 14, type: 'grove' },
    { dx: 12, dz: 16, type: 'obelisk' },
  ];

  siteOffsets.forEach((sCfg, sIdx) => {
    const sx = cont.x + sCfg.dx * (cont.id === 0 ? 1.0 : 1.45);
    const sz = cont.z + sCfg.dz * (cont.id === 0 ? 1.0 : 1.45);
    const sy = getTerrainHeight(sx, sz);

    const group = new THREE.Group();
    group.position.set(sx, sy, sz);

    // Dark Purple Blight Ring on the ground under every suffering site
    const blightRing = new THREE.Mesh(
      new THREE.RingGeometry(1.4, 1.85, 24).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ color: 0x9333ea, side: THREE.DoubleSide, transparent: true, opacity: 0.75 })
    );
    blightRing.position.y = 0.12;
    group.add(blightRing);

    let icon = '🦊';
    let name = '';
    let heightOffset = 2.6;

    if (sCfg.type === 'wildlife') {
      const wDef = WILDLIFE_MODELS[sCfg.wIdx];
      icon = wDef.icon;
      name = `Suffering ${wDef.species}`;
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
    } else if (sCfg.type === 'grove') {
      icon = '🪷';
      name = `Withered Lotus Grove`;
      heightOffset = 3.2;

      const basin = new THREE.Mesh(new THREE.TorusGeometry(2.3, 0.3, 8, 20).rotateX(Math.PI / 2), stoneMat);
      basin.position.y = 0.25;
      group.add(basin);

      const lotus = new THREE.Group();
      lotus.position.y = 0.45;
      lotus.scale.setScalar(0.45);
      const petalMat = new THREE.MeshStandardMaterial({ color: 0xec4899, emissive: 0xbe185d, emissiveIntensity: 0.5 });
      for (let p = 0; p < 8; p++) {
        const a = (p * Math.PI * 2) / 8;
        const petal = new THREE.Mesh(new THREE.ConeGeometry(0.45, 1.3, 5), petalMat);
        petal.position.set(Math.cos(a) * 0.65, 0.35, Math.sin(a) * 0.65);
        petal.rotation.z = -Math.cos(a) * 0.55;
        petal.rotation.x = Math.sin(a) * 0.55;
        lotus.add(petal);
      }
      group.add(lotus);
      group._lotus = lotus;
    } else {
      icon = '🔥';
      name = `Blighted Guardstone Shrine`;
      heightOffset = 7.8;

      const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.65, 1.15, 5.8, 6), stoneMat);
      shaft.position.y = 2.9;
      shaft.castShadow = true;
      group.add(shaft);

      const cap = new THREE.Mesh(new THREE.ConeGeometry(0.95, 1.5, 6), stoneMat);
      cap.position.y = 6.5;
      group.add(cap);
    }

    scene.add(group);

    const maxHp = cont.maxHpBase;
    const entity = {
      id: `site-${cont.id}-${sIdx}`,
      continent: cont,
      tier: cont.tier,
      kind: sCfg.type,
      icon,
      name,
      hp: Math.round(maxHp * 0.12),
      maxHp,
      rejuvenated: false,
      mesh: group,
      blightRing,
      homeX: sx,
      homeZ: sz,
      wanderAngle: sIdx * 1.7 + cont.id,
      heightOffset,
    };

    createNameplateDOM(entity);
    interactables.push(entity);
  });
});

// ============================================================================
// 4. PLAYER HERO, GOLDEN GARUDA WINGS & SUDARSHANA CHAKRA HALO
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, getTerrainHeight(0, 9), 9);
scene.add(playerGroup);

// Ornate Lotus Staff in right hand
const staffGroup = new THREE.Group();
const staffPole = new THREE.Mesh(
  new THREE.CylinderGeometry(0.05, 0.065, 2.4, 8),
  new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.7, roughness: 0.25 })
);
staffPole.position.y = 1.2;
staffGroup.add(staffPole);
const staffHead = new THREE.Mesh(
  new THREE.OctahedronGeometry(0.26, 0),
  new THREE.MeshStandardMaterial({ color: 0x34d399, emissive: 0x10b981, emissiveIntensity: 2.8 })
);
staffHead.position.y = 2.5;
staffGroup.add(staffHead);
staffGroup.position.set(0.5, 0.1, 0.25);
playerGroup.add(staffGroup);

// Golden Garuda Sky-Wings (Visible when Garuda Flight [F] is toggled ON!)
const garudaWingsGroup = new THREE.Group();
garudaWingsGroup.position.set(0, 1.45, -0.25);
const wingMat = new THREE.MeshStandardMaterial({
  color: 0xfde047,
  emissive: 0xd97706,
  emissiveIntensity: 1.4,
  side: THREE.DoubleSide,
});
const leftWing = new THREE.Group();
const rightWing = new THREE.Group();
for (let f = 0; f < 5; f++) {
  const featherGeo = new THREE.ConeGeometry(0.22, 2.2 - f * 0.25, 4);
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
garudaWingsGroup.add(leftWing, rightWing);
garudaWingsGroup.visible = STATE.flyingActive;
playerGroup.add(garudaWingsGroup);

// Sudarshana Dharma Chakra Halo (orbiting above head)
const chakraHalo = new THREE.Mesh(
  new THREE.TorusGeometry(0.55, 0.045, 8, 24),
  new THREE.MeshStandardMaterial({ color: 0xfef08a, emissive: 0xf59e0b, emissiveIntensity: 2.5 })
);
chakraHalo.rotation.x = Math.PI / 2;
chakraHalo.position.y = 2.45;
playerGroup.add(chakraHalo);

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

  // Spawn Vishwakarma Forge Master NPC & 2 Party Guardians near Jambudvipa Sanctuary
  const NPCS = [
    { name: 'Rishi Vishwakarma [K]', x: -5.5, z: 3.5 },
    { name: 'Arjuna_Palak', x: 6.0, z: 4.0 },
  ];
  NPCS.forEach((n) => {
    const clone = SkeletonUtils.clone(gltf.scene);
    clone.scale.setScalar(1.3);
    const ny = getTerrainHeight(n.x, n.z);
    const ng = new THREE.Group();
    ng.position.set(n.x, ny, n.z);
    ng.add(clone);
    scene.add(ng);
    const cm = new THREE.AnimationMixer(clone);
    mixers.push(cm);
    if (gltf.animations[0]) cm.clipAction(gltf.animations[0]).play();
  });
});

function setPlayerAnim(name) {
  if (!playerActions[name] || activePlayerAction === playerActions[name]) return;
  const next = playerActions[name];
  next.reset().fadeIn(0.18).play();
  if (activePlayerAction) activePlayerAction.fadeOut(0.18);
  activePlayerAction = next;
}

// ============================================================================
// 5. TARGETING, REJUVENATION ENGINE, KARMA POINTS & CONTINENT PROGRESSION
// ============================================================================
const targetRing = new THREE.Mesh(
  new THREE.RingGeometry(1.45, 1.78, 32).rotateX(-Math.PI / 2),
  new THREE.MeshBasicMaterial({ color: 0xfacc15, side: THREE.DoubleSide, transparent: true, opacity: 0.92 })
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
  document.getElementById('wow-target-lvl').textContent = t.tier;
  document.getElementById('wow-target-diff').textContent = `Tier ${t.continent.roman}`;

  const nameBg = document.getElementById('wow-target-name-bg');
  if (t.rejuvenated) nameBg.classList.add('rejuvenated');
  else nameBg.classList.remove('rejuvenated');

  const hpPct = Math.min(100, Math.round((t.hp / t.maxHp) * 100));
  const blightPct = Math.max(0, 100 - hpPct);
  document.getElementById('wow-target-hp-bar').style.width = `${hpPct}%`;
  document.getElementById('wow-target-hp-txt').textContent = `${Math.round(t.hp)} / ${t.maxHp} Rejuvenation`;
  document.getElementById('wow-target-blight-bar').style.width = `${blightPct}%`;
  document.getElementById('wow-target-status-txt').textContent = t.rejuvenated
    ? '🌟 Rejuvenated & Blossoming!'
    : `🌑 ${blightPct}% Suffering — Cast [1] [2] [3] [R]`;
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
  setTimeout(() => el.remove(), 1350);
}

function addChatMessage(colorClass, textHtml) {
  const box = document.getElementById('chat-messages');
  const div = document.createElement('div');
  div.className = `chat-line ${colorClass}`;
  div.innerHTML = textHtml;
  box.appendChild(div);
  box.scrollTop = box.scrollHeight;
}

function spawnShockwave(pos, colorHex, maxRadius = 12.0, duration = 0.85) {
  const geo = new THREE.RingGeometry(0.5, 1.2, 36).rotateX(-Math.PI / 2);
  const mat = new THREE.MeshBasicMaterial({
    color: colorHex,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0.92,
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
    addChatMessage('gold', `[Karma] ☸️ <strong>+${gain} Karma Points</strong> earned (${reasonText})!`);
  }
  return gain;
}

// Rejuvenate nearby withered trees & ground shader whenever a site is healed!
function rejuvenateEnvironmentAround(x, z, radius = 62.0) {
  addRejuvenationZone(x, z, radius);
  continentTrees.forEach((tr) => {
    if (!tr.rejuvenated && Math.hypot(tr.x - x, tr.z - z) <= radius) {
      tr.rejuvenated = true;
      tr.crown.material = hash2D(tr.x, tr.z) > 0.75 ? goldenCrownMat : lushCrownMat;
      tr.crown.scale.setScalar(1.18);
    }
  });
}

function applyRejuvenation(entity, rawAmount, spellLabel) {
  const prevHp = entity.hp;
  entity.hp = Math.min(entity.maxHp, entity.hp + rawAmount);
  if (entity.npFillEl) {
    entity.npFillEl.style.width = `${(entity.hp / entity.maxHp) * 100}%`;
  }

  spawnFloatingText(entity.mesh.position, `+${rawAmount} ${spellLabel}`, '#4ade80');
  spawnShockwave(entity.mesh.position, 0x10b981, 4.5, 0.55);

  // Small Karma reward on every healing pulse, huge Karma reward on full rejuvenation!
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
    if (entity.mesh._lotus) entity.mesh._lotus.scale.setScalar(1.3);

    // Transform the surrounding blighted land & withered trees into lush green paradise!
    rejuvenateEnvironmentAround(entity.mesh.position.x, entity.mesh.position.z, 72.0);

    const cont = entity.continent;
    cont.rejuvenatedCount = Math.min(cont.goalCount, cont.rejuvenatedCount + 1);
    STATE.totalRejuvenated += 1;

    earnKarma(cont.karmaReward, `Rejuvenated ${entity.name} in ${cont.shortName}`);

    // Check if the entire Continent is now 100% Rejuvenated!
    if (cont.rejuvenatedCount >= cont.goalCount && !cont.completed) {
      cont.completed = true;
      STATE.ascensionStage = Math.min(7, STATE.ascensionStage + 1);
      if (cont.skyBeaconMat) cont.skyBeaconMat.color.setHex(0x22c55e);
      rejuvenateEnvironmentAround(cont.x, cont.z, cont.radius * 1.15);

      document.getElementById('gift-tier').textContent = `🌟 CONTINENT ${cont.roman} REJUVENATED • VIRTUOUS BOON ATTAINED 🌟`;
      document.getElementById('gift-icon').textContent = cont.boonIcon;
      document.getElementById('gift-title').textContent = cont.boonName;
      document.getElementById('gift-desc').textContent = `You removed all suffering from ${cont.name}! ${cont.boonDesc}`;
      document.getElementById('gift-modal').classList.remove('wow-modal-hidden');

      addChatMessage(
        'green',
        `🎉 [Continent Reborn] <strong>${cont.name}</strong> has been completely rejuvenated! Permanent Boon unlocked: <strong>${cont.boonName}</strong>!`
      );
    }
  }

  updateAllHUD();
  if (STATE.selectedTarget === entity) updateTargetFrameUI();
}

// ============================================================================
// 6. SPELLS, SPEED-RUNNING [4], GARUDA FLIGHT [F] & WORLD WARP
// ============================================================================
function triggerActionSlot(slot) {
  if (STATE.cooldowns[slot] > 0) return;

  const healPwr = getHealPower();
  const aoeRad = getAoERadius();

  // [1] Sanjeevani Bolt (Homing Emerald Bolt + Chain-Heal if Tier V Ganesha Boon unlocked)
  if (slot === 1) {
    let target = STATE.selectedTarget;
    if (!target || target.rejuvenated) {
      target = findNearestSufferingEntity() || STATE.selectedTarget;
      if (target) selectTarget(target);
    }
    if (!target) return;

    const castDur = CONTINENTS[2].completed ? 0.28 : 0.42;
    STATE.casting = {
      name: `Sanjeevani Bolt → ${target.name}`,
      duration: castDur,
      elapsed: 0,
      onComplete: () => {
        STATE.cooldowns[1] = STATE.cdMax[1];
        launchProjectile(playerGroup.position, target, healPwr, 0x34d399);
        // If Tier V Ganesha Boon unlocked, chain-fire to 2 additional nearby suffering targets!
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

  // [2] Ganga Jal Nova (Expanding Sacred Water Wave)
  if (slot === 2) {
    STATE.cooldowns[2] = STATE.cdMax[2];
    spawnShockwave(playerGroup.position, 0x38bdf8, aoeRad, 0.9);
    rejuvenateEnvironmentAround(playerGroup.position.x, playerGroup.position.z, aoeRad * 1.4);

    const aoeHeal = Math.round(healPwr * 0.85 + getAoEBonus());
    let hits = 0;
    interactables.forEach((ent) => {
      if (ent.mesh.position.distanceTo(playerGroup.position) <= aoeRad + 6) {
        applyRejuvenation(ent, aoeHeal, 'Ganga Nova');
        hits++;
      }
    });
    if (hits === 0 && STATE.selectedTarget) {
      applyRejuvenation(STATE.selectedTarget, aoeHeal, 'Ganga Nova');
    }
    return;
  }

  // [3] Surya Sunbeam (Pillar of Solar Light on Target)
  if (slot === 3) {
    STATE.cooldowns[3] = STATE.cdMax[3];
    let target = STATE.selectedTarget || findNearestSufferingEntity();
    if (target) {
      selectTarget(target);
      spawnSunbeam(target.mesh.position);
      applyRejuvenation(target, Math.round(healPwr * 1.45), 'Sunbeam');
    }
    return;
  }

  // [4] Vayu Speed-Run Toggle (Instant Super-Speed Running!)
  if (slot === 4) {
    STATE.cooldowns[4] = STATE.cdMax[4];
    STATE.speedRunActive = !STATE.speedRunActive;
    document.getElementById('slot-4').classList.toggle('active-toggle', STATE.speedRunActive);
    document.getElementById('buff-speed-txt').textContent = STATE.speedRunActive ? '3.2x' : '1.0x';
    spawnShockwave(playerGroup.position, 0xfacc15, 6.0, 0.45);
    spawnFloatingText(
      playerGroup.position,
      STATE.speedRunActive ? '⚡ VAYU SPEED-RUN ON (3.2x)' : 'Speed Normal',
      '#fde047'
    );
    updateAllHUD();
    return;
  }

  // [5] Padma Sky-Leap (High Vault / Flight Boost)
  if (slot === 5) {
    STATE.cooldowns[5] = STATE.cdMax[5];
    playerVelY = 26.0;
    isGrounded = false;
    if (STATE.flyingActive) playerGroup.position.y += 14.0;
    spawnShockwave(playerGroup.position, 0xf472b6, 6.0, 0.55);
    spawnFloatingText(playerGroup.position, '🌸 PADMA SKY-LEAP!', '#f472b6');
    return;
  }

  // [6] Akashic Warp Blink [T] (Instant 65m Spatial Dash forward in 3D camera direction)
  if (slot === 6) {
    STATE.cooldowns[6] = STATE.cdMax[6];
    spawnShockwave(playerGroup.position, 0xa855f7, 5.0, 0.4);
    const forward = new THREE.Vector3(-Math.sin(cameraYaw), 0, -Math.cos(cameraYaw));
    playerGroup.position.addScaledVector(forward, 65.0);
    if (!STATE.flyingActive) {
      playerGroup.position.y = Math.max(-1.0, getTerrainHeight(playerGroup.position.x, playerGroup.position.z));
    }
    spawnShockwave(playerGroup.position, 0x38bdf8, 6.5, 0.5);
    spawnFloatingText(playerGroup.position, '✨ AKASHIC WARP (+65m)', '#c084fc');
    return;
  }

  // [7] Garuda Sky-Flight [F] (Boundless 3D Flight Across All 7 Continents!)
  if (slot === 7) {
    STATE.cooldowns[7] = STATE.cdMax[7];
    STATE.flyingActive = !STATE.flyingActive;
    garudaWingsGroup.visible = STATE.flyingActive;
    document.getElementById('slot-7').classList.toggle('active-toggle', STATE.flyingActive);
    document.getElementById('buff-flight-txt').textContent = STATE.flyingActive ? 'SOAR' : 'LAND';
    if (STATE.flyingActive) {
      playerGroup.position.y = Math.max(playerGroup.position.y + 8.0, 12.0);
      spawnShockwave(playerGroup.position, 0xfde047, 8.0, 0.6);
      spawnFloatingText(playerGroup.position, '🦅 GARUDA SKY-FLIGHT ACTIVE!', '#fde047');
    } else {
      spawnFloatingText(playerGroup.position, '🦅 Landed', '#94a3b8');
    }
    updateAllHUD();
    return;
  }

  // [8] Amrita World-Pulse [R] (Massive AoE Rejuvenation Supernova)
  if (slot === 8) {
    STATE.cooldowns[8] = CONTINENTS[5].completed ? STATE.cdMax[8] * 0.5 : STATE.cdMax[8];
    const pulseRad = aoeRad * 2.1;
    spawnShockwave(playerGroup.position, 0xfacc15, pulseRad, 1.15);
    rejuvenateEnvironmentAround(playerGroup.position.x, playerGroup.position.z, pulseRad * 1.35);

    const burstHeal = Math.round(healPwr * 1.6 + getAoEBonus());
    interactables.forEach((ent) => {
      if (ent.mesh.position.distanceTo(playerGroup.position) <= pulseRad + 8) {
        applyRejuvenation(ent, burstHeal, 'World Pulse');
      }
    });
    spawnFloatingText(playerGroup.position, '🪷 AMRITA WORLD-PULSE!', '#fde047');
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
  activeProjectiles.push({ mesh: orb, target, healAmount, speed: 38.0 });
}

function spawnSunbeam(pos) {
  const beam = new THREE.Mesh(
    new THREE.CylinderGeometry(1.4, 1.4, 65, 16, 1, true),
    new THREE.MeshBasicMaterial({ color: 0xfde047, transparent: true, opacity: 0.7, side: THREE.DoubleSide })
  );
  beam.position.copy(pos);
  beam.position.y += 32.5;
  scene.add(beam);
  spawnShockwave(pos, 0xfacc15, 9.0, 0.8);
  setTimeout(() => scene.remove(beam), 550);
}

// Fast-Fly / Soar to any of the 7 Continents from the World Map or Quest Tracker!
function flyToContinent(continentId) {
  const cont = CONTINENTS[continentId];
  if (!cont) return;
  document.getElementById('worldmap-modal').classList.add('wow-modal-hidden');

  STATE.flyingActive = true;
  garudaWingsGroup.visible = true;
  document.getElementById('slot-7').classList.add('active-toggle');

  const groundY = getTerrainHeight(cont.x, cont.z + 12);
  playerGroup.position.set(cont.x, groundY + 6.5, cont.z + 12);
  STATE.currentContinent = cont;

  spawnShockwave(playerGroup.position, 0xfde047, 12.0, 0.8);
  spawnFloatingText(playerGroup.position, `🦅 Soared to ${cont.shortName}!`, '#fde047');
  addChatMessage(
    'cyan',
    `🦅 [Sky-Flight] Arrived at <strong>${cont.name}</strong> (Difficulty Tier ${cont.roman} — ${cont.diffMult}x). Cleanse its 4 suffering sites!`
  );

  const nextTarget = interactables.find((e) => e.continent.id === cont.id && !e.rejuvenated);
  if (nextTarget) selectTarget(nextTarget);
  updateAllHUD();
}

// ============================================================================
// 7. KARMA EMPORIUM SHOP & WORLD MAP MODALS
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
          <div class="shop-icon">${item.icon}</div>
          <div>
            <div class="shop-title">${item.name}</div>
            <div class="shop-rank">${item.category} • ${item.isConsumable ? 'Instant' : `Rank ${item.rank}/${item.maxRank}`}</div>
          </div>
        </div>
        <div class="shop-desc">${item.desc}</div>
        <div class="shop-bonus">${item.bonusText(item.rank)}</div>
        <button class="shop-buy-btn ${canAfford ? '' : 'disabled'}" data-shop-id="${item.id}">
          <span>${isMax ? 'MAX RANK FORGED' : item.isConsumable ? 'Invoke Elixir Now' : `Upgrade to Rank ${item.rank + 1}`}</span>
          <span>☸️ ${isMax ? '—' : cost.toLocaleString()}</span>
        </button>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('.shop-buy-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-shop-id');
      purchaseShopItem(id);
    });
  });
}

function purchaseShopItem(itemId) {
  const item = SHOP_TOOLS.find((i) => i.id === itemId);
  if (!item || item.rank >= item.maxRank) return;
  const cost = Math.round(item.baseCost * Math.pow(item.costMult, item.rank));
  if (STATE.karma < cost) {
    addChatMessage('yellow', `⚠️ You need <strong>☸️ ${cost} Karma Points</strong> to forge <strong>${item.name}</strong>! Heal suffering creatures to earn more Karma.`);
    return;
  }

  STATE.karma -= cost;
  item.rank += 1;

  if (item.isConsumable) {
    // Soma-Sanjeevani Elixir: Instant 65m Supernova!
    spawnShockwave(playerGroup.position, 0xfde047, 65.0, 1.3);
    rejuvenateEnvironmentAround(playerGroup.position.x, playerGroup.position.z, 75.0);
    interactables.forEach((ent) => {
      if (ent.mesh.position.distanceTo(playerGroup.position) <= 68.0) {
        applyRejuvenation(ent, 320, 'Soma Elixir');
      }
    });
    addChatMessage('green', `🧪 [Karma Emporium] Invoked <strong>${item.name}</strong>! A 65m Golden Supernova rejuvenated everything around you!`);
  } else {
    spawnShockwave(playerGroup.position, 0x38bdf8, 8.0, 0.6);
    spawnFloatingText(playerGroup.position, `🛠️ Upgraded ${item.name} (Rank ${item.rank})!`, '#fde047');
    addChatMessage('green', `🛠️ [Karma Emporium] Forged <strong>${item.name} (Rank ${item.rank})</strong> using ☸️ ${cost} Karma Points!`);
  }

  updateAllHUD();
  renderKarmaShopModal();
}

function renderWorldMapModal() {
  const grid = document.getElementById('continents-modal-grid');
  grid.innerHTML = CONTINENTS.map(
    (c) => `
    <div class="continent-card ${c.completed ? 'rejuvenated' : ''}">
      <div class="cc-top">
        <span class="cc-title">${c.roman}. ${c.name}</span>
        <span class="cc-tier">Tier ${c.roman} (${c.diffMult}x)</span>
      </div>
      <div class="cc-desc">
        Status: <strong>${c.rejuvenatedCount} / ${c.goalCount} Sites Rejuvenated</strong><br/>
        Site Vitality Requirement: ${c.maxHpBase} • Reward: ☸️ ${c.karmaReward} Karma
      </div>
      <div class="cc-boon">${c.boonIcon} ${c.boonName}: ${c.boonDesc}</div>
      <button class="cc-fly-btn" data-cont-id="${c.id}">
        🦅 Soar to ${c.shortName} (${c.completed ? 'Rejuvenated 🌟' : 'Cleanse Suffering'})
      </button>
    </div>
  `
  ).join('');

  grid.querySelectorAll('.cc-fly-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const cid = parseInt(btn.getAttribute('data-cont-id'), 10);
      flyToContinent(cid);
    });
  });
}

function updateAllHUD() {
  // Player Frame & Karma Currency
  document.getElementById('wow-player-lvl').textContent = STATE.ascensionStage;
  document.getElementById('wow-current-stage').textContent = `Stage ${CONTINENTS[STATE.ascensionStage - 1].roman}/VII`;
  document.getElementById('wow-player-hp-txt').textContent = `Heal Power: ${getHealPower()} • AoE: ${getAoERadius()}m`;
  document.getElementById('wow-player-mp-txt').textContent = `☸️ ${STATE.karma.toLocaleString()} KARMA POINTS`;
  document.getElementById('stat-karma').textContent = STATE.karma.toLocaleString();

  // Top-Center Continent Banner
  const c = STATE.currentContinent;
  document.getElementById('hud-continent-name').textContent = `${c.roman}. ${c.name.toUpperCase()} [TIER ${c.roman}]`;
  const stateBadge = document.getElementById('hud-continent-state');
  if (c.completed) {
    stateBadge.textContent = `🌟 Continent Rejuvenated (${c.rejuvenatedCount}/${c.goalCount}) • ${c.boonName} Active`;
    stateBadge.classList.add('rejuvenated');
  } else {
    stateBadge.textContent = `🌑 Suffering Under Blight (${c.rejuvenatedCount}/${c.goalCount} Rejuvenated • Diff ${c.diffMult}x)`;
    stateBadge.classList.remove('rejuvenated');
  }

  document.getElementById('minimap-zone-label').textContent = `${c.shortName} [Tier ${c.roman}]`;

  // Quest Tracker Right Panel
  document.getElementById('wq-active-title').textContent = `Tier ${c.roman}: Cleanse ${c.shortName}`;
  document.getElementById('wq-active-desc').textContent = `Difficulty: ${c.diffMult}x • Heal ${c.goalCount} suffering sites to unlock ${c.boonName}.`;
  document.getElementById('wq-active-bar').style.width = `${(c.rejuvenatedCount / c.goalCount) * 100}%`;
  document.getElementById('wq-active-cnt').textContent = `${c.rejuvenatedCount} / ${c.goalCount}`;

  const listEl = document.getElementById('wq-continents-list');
  listEl.innerHTML = CONTINENTS.map(
    (cont) => `
    <div class="wq-cont-item ${cont.id === c.id ? 'active-continent' : ''} ${cont.completed ? 'completed-continent' : ''}" data-goto-cont="${cont.id}" title="Click to fly directly to ${cont.name}">
      <span class="wq-c-name">${cont.boonIcon} ${cont.shortName}</span>
      <span class="wq-c-stat">${cont.completed ? '🌟 Reborn' : `${cont.rejuvenatedCount}/${cont.goalCount} ✈️`}</span>
    </div>
  `
  ).join('');

  listEl.querySelectorAll('.wq-cont-item').forEach((row) => {
    row.addEventListener('click', () => {
      flyToContinent(parseInt(row.getAttribute('data-goto-cont'), 10));
    });
  });

  // Bottom WoW XP & World Renewal Strips
  const stagePct = Math.min(100, (STATE.ascensionStage / 7) * 100);
  document.getElementById('wow-xp-fill').style.width = `${stagePct}%`;
  document.getElementById('wow-xp-label').textContent = `ASCENSION STAGE ${STATE.ascensionStage} / 7 • LIFETIME KARMA GENERATED: ${STATE.lifetimeKarma.toLocaleString()} ☸️`;

  const worldPct = Math.min(100, (STATE.totalRejuvenated / STATE.totalSites) * 100);
  const rebornContinents = CONTINENTS.filter((ct) => ct.completed).length;
  document.getElementById('wow-rep-fill').style.width = `${worldPct}%`;
  document.getElementById('wow-rep-label').textContent = `WORLD RENEWAL: ${STATE.totalRejuvenated} / ${STATE.totalSites} Suffering Sites Rejuvenated (${rebornContinents} / 7 Continents Reborn)`;
}

// ============================================================================
// 8. INPUT CONTROLS, 3D FLIGHT PHYSICS & CAMERA ORBIT
// ============================================================================
const keys = {};
let cameraYaw = 0;
let cameraPitch = 0.36;
let cameraDist = 15.5;
let isDragging = false;
let prevMouse = { x: 0, y: 0 };
let playerVelY = 0;
let isGrounded = true;

window.addEventListener('keydown', (e) => {
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
    const near = findNearestSufferingEntity();
    if (near) selectTarget(near);
  } else if (e.key === '1') triggerActionSlot(1);
  else if (e.key === '2') triggerActionSlot(2);
  else if (e.key === '3') triggerActionSlot(3);
  else if (e.key === '4') triggerActionSlot(4);
  else if (e.key === '5') triggerActionSlot(5);
  else if (k === 't') triggerActionSlot(6);
  else if (k === 'f') triggerActionSlot(7);
  else if (k === 'r') triggerActionSlot(8);
  else if (k === 'k' || k === 'b' || k === 'c') toggleModal('shop-modal');
  else if (k === 'm') toggleModal('worldmap-modal');
  else if (e.key === 'Enter') {
    document.getElementById('gift-modal').classList.add('wow-modal-hidden');
  } else if (e.key === ' ' && !STATE.flyingActive && isGrounded) {
    playerVelY = 16.5;
    isGrounded = false;
  }
});

window.addEventListener('keyup', (e) => {
  keys[e.key.toLowerCase()] = false;
});

function toggleModal(id) {
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

// Wire UI Buttons
for (let s = 1; s <= 8; s++) {
  const el = document.getElementById(`slot-${s}`);
  if (el) el.addEventListener('click', () => triggerActionSlot(s));
}
document.getElementById('slot-4').classList.add('active-toggle');

document.getElementById('btn-shop').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('btn-bags').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('btn-left-shop').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('buff-shop').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('hud-karma-box').addEventListener('click', () => toggleModal('shop-modal'));
document.getElementById('btn-close-shop').addEventListener('click', () =>
  document.getElementById('shop-modal').classList.add('wow-modal-hidden')
);

document.getElementById('btn-worldmap').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('btn-open-map').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('btn-tracker-map').addEventListener('click', () => toggleModal('worldmap-modal'));
document.getElementById('btn-close-map').addEventListener('click', () =>
  document.getElementById('worldmap-modal').classList.add('wow-modal-hidden')
);
document.getElementById('btn-claim-gift').addEventListener('click', () =>
  document.getElementById('gift-modal').classList.add('wow-modal-hidden')
);
document.getElementById('buff-speed').addEventListener('click', () => triggerActionSlot(4));
document.getElementById('buff-flight').addEventListener('click', () => triggerActionSlot(7));

// Mouse Orbit & Raycast Entity Selection
const raycaster = new THREE.Raycaster();
const mouseNDC = new THREE.Vector2();

renderer.domElement.addEventListener('pointerdown', (e) => {
  isDragging = true;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;

  mouseNDC.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouseNDC.y = -(e.clientY / window.innerHeight) * 2 + 1;
  raycaster.setFromCamera(mouseNDC, camera);

  let best = null;
  let bestD = 5.0;
  interactables.forEach((ent) => {
    const d = raycaster.ray.distanceToPoint(ent.mesh.position);
    if (d < bestD) {
      bestD = d;
      best = ent;
    }
  });
  if (best) selectTarget(best);
});

window.addEventListener('pointermove', (e) => {
  if (!isDragging) return;
  const dx = e.clientX - prevMouse.x;
  const dy = e.clientY - prevMouse.y;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;
  cameraYaw -= dx * 0.0065;
  cameraPitch = Math.max(0.08, Math.min(1.25, cameraPitch + dy * 0.0055));
});

window.addEventListener('pointerup', () => {
  isDragging = false;
});

window.addEventListener('wheel', (e) => {
  cameraDist = Math.max(7.0, Math.min(42.0, cameraDist + e.deltaY * 0.015));
});

// ============================================================================
// 9. CIRCULAR WOW MINIMAP (SHOWING ALL 7 CONTINENTS & SUFFERING SITES)
// ============================================================================
const minimapCanvas = document.getElementById('minimap-canvas');
const mCtx = minimapCanvas.getContext('2d');

function drawMinimap() {
  const w = minimapCanvas.width;
  const h = minimapCanvas.height;
  const cx = w / 2;
  const cy = h / 2;
  const scale = STATE.flyingActive ? 0.14 : 0.45; // Zoom out automatically when flying across continents!

  mCtx.clearRect(0, 0, w, h);
  mCtx.fillStyle = '#09192b';
  mCtx.fillRect(0, 0, w, h);

  // Draw all 7 Continents on the Radar
  CONTINENTS.forEach((cont) => {
    const dx = (cont.x - playerGroup.position.x) * scale;
    const dz = (cont.z - playerGroup.position.z) * scale;
    const r = Math.max(10, cont.radius * scale * 0.72);

    mCtx.fillStyle = cont.completed ? 'rgba(34, 197, 94, 0.45)' : 'rgba(88, 28, 135, 0.48)';
    mCtx.strokeStyle = cont.completed ? '#4ade80' : '#c084fc';
    mCtx.lineWidth = 1.5;
    mCtx.beginPath();
    mCtx.arc(cx + dx, cy + dz, r, 0, Math.PI * 2);
    mCtx.fill();
    mCtx.stroke();
  });

  // Draw Suffering Sites
  interactables.forEach((ent) => {
    const sx = cx + (ent.mesh.position.x - playerGroup.position.x) * scale;
    const sz = cy + (ent.mesh.position.z - playerGroup.position.z) * scale;
    if (sx < 4 || sx > w - 4 || sz < 4 || sz > h - 4) return;
    mCtx.fillStyle = ent.rejuvenated ? '#4ade80' : '#facc15';
    mCtx.beginPath();
    mCtx.arc(sx, sz, ent === STATE.selectedTarget ? 4.2 : 2.8, 0, Math.PI * 2);
    mCtx.fill();
  });

  // Player center dot
  mCtx.fillStyle = '#ffffff';
  mCtx.beginPath();
  mCtx.arc(cx, cy, 4, 0, Math.PI * 2);
  mCtx.fill();

  const alt = Math.max(0, Math.round(playerGroup.position.y - getTerrainHeight(playerGroup.position.x, playerGroup.position.z)));
  document.getElementById('minimap-coords').textContent = `${Math.round(playerGroup.position.x)}, ${Math.round(
    playerGroup.position.z
  )} • Alt: ${alt}m`;
}

const projVec = new THREE.Vector3();
function updateWorldNameplates() {
  const halfW = window.innerWidth / 2;
  const halfH = window.innerHeight / 2;

  interactables.forEach((ent) => {
    if (!ent.nameplateEl) return;
    const dist = camera.position.distanceTo(ent.mesh.position);
    if (dist > 110) {
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
// 10. MAIN 60FPS GAME LOOP (SHADER EXPANSION, FLIGHT, AUTO-CHAKRA, AI)
// ============================================================================
const clock = new THREE.Clock();
let chakraTimer = 0;

setTimeout(() => {
  const first = findNearestSufferingEntity();
  if (first) selectTarget(first);
  updateAllHUD();
}, 300);

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();

  oceanMat.uniforms.uTime.value = elapsed;
  terrainShaderMat.uniforms.uTime.value = elapsed;

  // Smoothly expand GPU Rejuvenation Circles on the terrain!
  for (let i = 0; i < MAX_CLEANSE_ZONES; i++) {
    const cz = cleanseCenters[i];
    if (cz.z < cz.w) {
      cz.z = Math.min(cz.w, cz.z + dt * 38.0);
    }
  }

  // Animate Garuda Golden Wings & Sudarshana Chakra Halo
  chakraHalo.rotation.z = elapsed * 2.5;
  if (STATE.flyingActive) {
    const flap = Math.sin(elapsed * 9.0) * 0.38;
    leftWing.rotation.z = flap;
    rightWing.rotation.z = -flap;
  }

  // Sudarshana Chakra Artifact Passive Auto-Heal (from Karma Shop) + Tier VII Vishnu Avatar Aura
  chakraTimer += dt;
  if (chakraTimer >= 1.4) {
    chakraTimer = 0;
    const chakraRank = SHOP_TOOLS[5].rank;
    if (chakraRank > 0 || CONTINENTS[6].completed) {
      const near = findNearestSufferingEntity();
      if (near && near.mesh.position.distanceTo(playerGroup.position) <= 38) {
        const autoAmt = chakraRank * 45 + (CONTINENTS[6].completed ? 120 : 0);
        launchProjectile(playerGroup.position, near, autoAmt, 0xfde047);
      }
    }
  }

  for (let i = 0; i < mixers.length; i++) {
    mixers[i].update(dt);
  }

  // Player Movement (Speed-Running & Full 3D Sky-Flight!)
  let moveX = 0;
  let moveZ = 0;
  if (keys['w'] || keys['arrowup']) moveZ -= 1;
  if (keys['s'] || keys['arrowdown']) moveZ += 1;
  if (keys['a'] || keys['arrowleft']) moveX -= 1;
  if (keys['d'] || keys['arrowright']) moveX += 1;

  const isMoving = moveX !== 0 || moveZ !== 0;
  const mobMult = getMobilityMultiplier();

  if (isMoving) {
    const len = Math.hypot(moveX, moveZ);
    moveX /= len;
    moveZ /= len;

    const baseSpeed = STATE.flyingActive
      ? 48.0 * mobMult
      : STATE.speedRunActive
      ? 24.5 * mobMult
      : 10.5 * mobMult;

    const sinY = Math.sin(cameraYaw);
    const cosY = Math.cos(cameraYaw);
    const dx = moveX * cosY + moveZ * sinY;
    const dz = -moveX * sinY + moveZ * cosY;

    playerGroup.position.x += dx * baseSpeed * dt;
    playerGroup.position.z += dz * baseSpeed * dt;
    playerGroup.rotation.y = Math.atan2(dx, dz) + Math.PI;
    setPlayerAnim('Run');
  } else {
    setPlayerAnim('Idle');
  }

  const groundY = Math.max(-1.2, getTerrainHeight(playerGroup.position.x, playerGroup.position.z));
  if (STATE.flyingActive) {
    if (keys[' ']) playerGroup.position.y += 28.0 * dt;
    if (keys['c'] || keys['shift']) playerGroup.position.y -= 28.0 * dt;
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

  // Detect Continent Change as Player Flies Across the World
  const nearCont = getNearestContinent(playerGroup.position.x, playerGroup.position.z);
  if (nearCont !== STATE.currentContinent) {
    STATE.currentContinent = nearCont;
    updateAllHUD();
    addChatMessage('cyan', `🗺️ Entered <strong>${nearCont.name}</strong> (Difficulty Tier ${nearCont.roman}).`);
  }

  // Wander Wildlife
  interactables.forEach((ent) => {
    if (ent.kind === 'wildlife') {
      ent.wanderAngle += dt * 0.55;
      const tx = ent.homeX + Math.cos(ent.wanderAngle) * 4.0;
      const tz = ent.homeZ + Math.sin(ent.wanderAngle * 0.8) * 4.0;
      const dx = tx - ent.mesh.position.x;
      const dz = tz - ent.mesh.position.z;
      ent.mesh.position.x += dx * dt;
      ent.mesh.position.z += dz * dt;
      ent.mesh.position.y = getTerrainHeight(ent.mesh.position.x, ent.mesh.position.z);
      ent.mesh.rotation.y = Math.atan2(dx, dz);
    }
  });

  if (STATE.selectedTarget) {
    targetRing.position.copy(STATE.selectedTarget.mesh.position);
    targetRing.position.y = getTerrainHeight(targetRing.position.x, targetRing.position.z) + 0.2;
    targetRing.rotation.z = elapsed * 2.0;
  }

  // Update Castbar
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

  // Update Cooldowns
  for (let s = 1; s <= 8; s++) {
    if (STATE.cooldowns[s] > 0) {
      STATE.cooldowns[s] = Math.max(0, STATE.cooldowns[s] - dt);
      const cdEl = document.getElementById(`cd-${s}`);
      if (cdEl) cdEl.style.height = `${(STATE.cooldowns[s] / STATE.cdMax[s]) * 100}%`;
    }
  }

  // Update Projectiles
  for (let i = activeProjectiles.length - 1; i >= 0; i--) {
    const p = activeProjectiles[i];
    const tPos = p.target.mesh.position.clone();
    tPos.y += 1.3;
    const dir = tPos.sub(p.mesh.position);
    if (dir.length() < 1.0) {
      scene.remove(p.mesh);
      activeProjectiles.splice(i, 1);
      applyRejuvenation(p.target, p.healAmount, 'Sanjeevani');
    } else {
      dir.normalize();
      p.mesh.position.addScaledVector(dir, p.speed * dt);
    }
  }

  // Update Shockwaves
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
      sw.mesh.material.opacity = (1.0 - t) * 0.85;
    }
  }

  // Third-Person WoW Orbit Camera
  const camTarget = new THREE.Vector3(playerGroup.position.x, playerGroup.position.y + 2.2, playerGroup.position.z);
  const camX = camTarget.x + Math.sin(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camZ = camTarget.z + Math.cos(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camY = camTarget.y + Math.sin(cameraPitch) * cameraDist;
  const minCamY = getTerrainHeight(camX, camZ) + 1.4;

  camera.position.set(camX, Math.max(camY, minCamY), camZ);
  camera.lookAt(camTarget);

  updateWorldNameplates();
  drawMinimap();
  renderer.render(scene, camera);
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

animate();
