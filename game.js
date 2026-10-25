import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import * as SkeletonUtils from 'three/addons/utils/SkeletonUtils.js';

// ============================================================================
// DHARMA.IO — HORDES.IO ENGINE CLONE (VIRTUOUS OPEN-WORLD MMORPG)
// Custom Splatmap Terrain • Rigged GLTF Wildlife & Heroes • 3D Nameplates
// ============================================================================

const STATE = {
  gold: 3450,
  punya: 480,
  punyaMax: 600,
  fame: 210,
  level: 1,
  prana: 100,
  pranaMax: 100,
  wildlifeHealed: 0,
  wildlifeGoal: 4,
  grovesBloomed: 0,
  grovesGoal: 3,
  obelisksLit: 0,
  obelisksGoal: 3,
  boons: {
    suryaDash: false,
    padmaLeap: false,
    akashBlink: false,
    garudaFly: false,
  },
  activeBuffs: {
    dashTimer: 0,
    flying: false,
  },
  cooldowns: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 },
  cdMax:     { 1: 1.4, 2: 3.5, 3: 4.0, 4: 6.0, 5: 2.5, 6: 5.0, 7: 1.0 },
  casting: null, // { slot, name, duration, elapsed, target }
  selectedTarget: null,
};

const DEITIES_DATA = [
  { id: 'surya', icon: '☀️', name: 'Lord Surya', title: 'Solar Sovereign of Prana', desc: 'Blesses the Sanctuary with radiant golden light, +35% Prana regeneration, and the blazing Surya Dash.', unlocked: true },
  { id: 'lakshmi', icon: '🪷', name: 'Goddess Lakshmi', title: 'Bestower of Swarna & Grace', desc: 'Doubles Swarna (Gold) and Punya rewards from every virtuous deed and awakens Padma Lotus Leap.', unlocked: true },
  { id: 'saraswati', icon: '🦢', name: 'Goddess Saraswati', title: 'Wisdom of the Sacred River', desc: 'Empowers Ganga Jal Nova [2] to bloom Sacred Lotus Groves and heal all nearby creatures.', unlocked: true },
  { id: 'hanuman', icon: '🏔️', name: 'Lord Hanuman', title: 'Unbounded Wind & Devotion', desc: 'Grants Sanjeevani mountain herbs (+50% healing power) and heroic wind-leaps across valleys.', unlocked: true },
  { id: 'ganesha', icon: '🐘', name: 'Lord Ganesha', title: 'Remover of All Obstacles', desc: 'Sanctifies the ancient Guardstone Obelisks and opens hidden mountain passes.', unlocked: true },
  { id: 'shiva', icon: '🔱', name: 'Lord Shiva', title: 'Lord of Kailash & Akash', desc: 'Awakens Akashic Spatial Blink [T] to teleport across rivers and cliffs instantaneously.', unlocked: false },
  { id: 'vishnu', icon: '🦅', name: 'Lord Vishnu', title: 'Preserver of Cosmic Dharma', desc: 'Summons the mythic wings of Garuda [F] for boundless flight across the entire realm.', unlocked: false },
];

const INVENTORY_ITEMS = [
  { icon: '🌿', name: 'Sanjeevani Root', qty: '∞', desc: 'Sacred Himalayan herb that restores distressed wildlife.' },
  { icon: '🏺', name: 'Ganga Jal Kalash', qty: '∞', desc: 'Pure Himalayan river water that blooms withered lotus groves.' },
  { icon: '🍲', name: 'Annadana Vessel', qty: '∞', desc: 'Endless vessel of sanctified nourishment for pilgrims & shrines.' },
  { icon: '🦯', name: 'Lotus Vaidya Staff', qty: 'Equipped', desc: '+45 Healing Power • Channels emerald Sanjeevani bolts.' },
  { icon: '📿', name: 'Rudraksha Mala', qty: 'Equipped', desc: '+25% Punya Karma gained from all compassionate deeds.' },
  { icon: '🪙', name: 'Swarna Mudra Pouch', qty: '3,450', desc: 'Sacred golden coins gifted by sanctuaries.' },
  { icon: '🪷', name: 'Padma Crystal', qty: '3', desc: 'Crystallized lotus dew harvested from bloomed groves.' },
  { icon: '🔥', name: 'Agni Jyoti Spark', qty: '2', desc: 'Eternal flame used to awaken ancient Guardstone Obelisks.' },
];

// ============================================================================
// 1. SCENE, CAMERA, RENDERER & ATMOSPHERE
// ============================================================================
const container = document.getElementById('canvas-container');
const nameplatesContainer = document.getElementById('nameplates-container');

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x689bc8);
scene.fog = new THREE.FogExp2(0x7aa8cf, 0.0042);

const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.5, 650);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.12;
container.appendChild(renderer.domElement);

// Sky Dome Shader (Crisp Hordes.io Alpine Sky + Sun Halo)
const skyGeo = new THREE.SphereGeometry(520, 32, 24);
const skyMat = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  depthWrite: false,
  uniforms: {
    topColor: { value: new THREE.Color(0x255894) },
    horizonColor: { value: new THREE.Color(0x94c2e5) },
    sunDir: { value: new THREE.Vector3(0.55, 0.48, -0.68).normalize() },
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
      float h = clamp(dir.y * 1.35 + 0.1, 0.0, 1.0);
      vec3 col = mix(horizonColor, topColor, pow(h, 0.65));
      float sunAmt = max(dot(dir, sunDir), 0.0);
      col += vec3(1.0, 0.9, 0.65) * pow(sunAmt, 14.0) * 0.42;
      col += vec3(1.0, 0.97, 0.85) * smoothstep(0.996, 0.9995, sunAmt);
      gl_FragColor = vec4(col, 1.0);
    }
  `,
});
scene.add(new THREE.Mesh(skyGeo, skyMat));

// Lighting (Warm Golden Sun + Sky Hemisphere + Sanctuary Point Lights)
const hemiLight = new THREE.HemisphereLight(0xd9f0ff, 0x3b5932, 0.85);
hemiLight.position.set(0, 120, 0);
scene.add(hemiLight);

const sunLight = new THREE.DirectionalLight(0xfff1d0, 2.2);
sunLight.position.set(95, 115, -90);
sunLight.castShadow = true;
sunLight.shadow.mapSize.width = 2048;
sunLight.shadow.mapSize.height = 2048;
sunLight.shadow.camera.near = 10;
sunLight.shadow.camera.far = 340;
const d = 115;
sunLight.shadow.camera.left = -d;
sunLight.shadow.camera.right = d;
sunLight.shadow.camera.top = d;
sunLight.shadow.camera.bottom = -d;
sunLight.shadow.bias = -0.0005;
scene.add(sunLight);

// ============================================================================
// 2. HORDES.IO TERRAIN HEIGHT & SPLATMAP SHADER (ROADS, PLAZA, RIVER, CLIFFS)
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
    freq *= 2.05;
    amp *= 0.5;
  }
  return v;
}

// River Ganga center X curve as a function of Z
function getRiverCenterX(z) {
  return -48 + Math.sin(z * 0.032) * 16 + Math.cos(z * 0.015) * 8;
}

// Distance to winding dirt roads radiating from Sanctuary Plaza (0,0)
function getRoadFactor(x, z) {
  // Central Sanctuary Cobblestone Plaza around (0, 0)
  const distCenter = Math.hypot(x, z);
  const plaza = Math.max(0, 1.0 - Math.max(0, distCenter - 9.5) / 4.5);

  // 4 Winding Roads: North (0, -z), East (+x, 0), South-East, West Bridge
  // Road 1: Main North-South Road (Z from -130 to +130)
  const r1CurveX = Math.sin(z * 0.045) * 6.5;
  const d1 = Math.abs(x - r1CurveX);
  const road1 = Math.max(0, 1.0 - Math.max(0, d1 - 2.4) / 2.2);

  // Road 2: East-West Road (X from -35 to +130)
  const r2CurveZ = Math.sin(x * 0.04) * 5.5;
  const d2 = Math.abs(z - r2CurveZ);
  const road2 = x > -38 ? Math.max(0, 1.0 - Math.max(0, d2 - 2.2) / 2.0) : 0;

  return { plaza, road: Math.max(road1, road2) };
}

function getTerrainHeight(x, z) {
  const distCenter = Math.hypot(x, z);
  // Keep central Sanctuary Plaza and immediate play area gently rolling
  const centerFlat = Math.min(1.0, Math.max(0.0, (distCenter - 14.0) / 36.0));

  // Base rolling hills
  const n1 = fbm(x * 0.014 + 10.3, z * 0.014 + 22.1);
  const n2 = fbm(x * 0.042 + 4.7, z * 0.042 + 9.2);
  let h = (n1 - 0.42) * 18.0 * centerFlat + (n2 - 0.5) * 2.8 * centerFlat;

  // Outer perimeter mountain ring (like Hordes.io Guardstone valley walls)
  if (distCenter > 88) {
    const rim = (distCenter - 88) / 55;
    const ridgeNoise = fbm(x * 0.03, z * 0.03);
    h += Math.pow(rim, 1.75) * (28.0 + ridgeNoise * 24.0);
  }

  // Flatten terrain slightly along roads
  const { plaza, road } = getRoadFactor(x, z);
  h *= (1.0 - plaza * 0.92 - road * 0.55);

  // Carve River Ganga valley along the west side
  const riverX = getRiverCenterX(z);
  const distRiver = Math.abs(x - riverX);
  if (distRiver < 16.0) {
    const t = distRiver / 16.0;
    const smooth = t * t * (3.0 - 2.0 * t);
    const riverBed = -3.2;
    h = h * smooth + riverBed * (1.0 - smooth);
  }

  return h;
}

// Build High-Detail Splatmap Texture on Canvas (1024x1024)
function createSplatmapTexture(worldSize) {
  const size = 1024;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  const img = ctx.createImageData(size, size);
  const data = img.data;

  for (let py = 0; py < size; py++) {
    const wz = ((py / size) - 0.5) * worldSize;
    for (let px = 0; px < size; px++) {
      const wx = ((px / size) - 0.5) * worldSize;

      const h = getTerrainHeight(wx, wz);
      const hx = getTerrainHeight(wx + 1.0, wz);
      const hz = getTerrainHeight(wx, wz + 1.0);
      const slope = Math.min(1.0, Math.hypot(hx - h, hz - h) * 1.15);

      const detail = fbm(wx * 0.18, wz * 0.18);
      const micro = hash2D(px * 0.7, py * 0.7);

      // Base Lush Hordes.io Forest Grass (multi-tone emerald & olive)
      let r = 64 + detail * 38 + micro * 12;
      let g = 112 + detail * 48 + micro * 14;
      let b = 46 + detail * 22 + micro * 8;

      // Sunny meadow patches
      const meadow = fbm(wx * 0.05 + 50, wz * 0.05 + 50);
      if (meadow > 0.55) {
        const mf = (meadow - 0.55) * 2.2;
        r += mf * 26;
        g += mf * 32;
        b += mf * 8;
      }

      // Riverbank Sand & Wet Pebbles
      const riverX = getRiverCenterX(wz);
      const distRiver = Math.abs(wx - riverX);
      if (distRiver < 14.5) {
        const bankFactor = Math.max(0, 1.0 - Math.max(0, distRiver - 6.5) / 8.0);
        const sandR = 168 + detail * 30;
        const sandG = 148 + detail * 26;
        const sandB = 104 + detail * 20;
        r = r * (1 - bankFactor) + sandR * bankFactor;
        g = g * (1 - bankFactor) + sandG * bankFactor;
        b = b * (1 - bankFactor) + sandB * bankFactor;
      }

      // Winding Dirt Roads (Warm Earth / Packed Trail)
      const { plaza, road } = getRoadFactor(wx, wz);
      if (road > 0.01) {
        const rf = Math.min(1.0, road * (0.85 + detail * 0.3));
        const dirtR = 138 + detail * 28 - micro * 12;
        const dirtG = 106 + detail * 22 - micro * 10;
        const dirtB = 72 + detail * 16 - micro * 8;
        r = r * (1 - rf) + dirtR * rf;
        g = g * (1 - rf) + dirtG * rf;
        b = b * (1 - rf) + dirtB * rf;
      }

      // Central Sanctuary Cobblestone & Golden Mandala Plaza
      if (plaza > 0.01) {
        const distC = Math.hypot(wx, wz);
        const ringPattern = Math.sin(distC * 2.6) * Math.cos(Math.atan2(wz, wx) * 12.0);
        const stone = 148 + ringPattern * 18 + (micro - 0.5) * 22;
        const goldTrim = Math.abs(distC - 8.5) < 0.65 || Math.abs(distC - 4.2) < 0.45 ? 1.0 : 0.0;
        const pr = goldTrim ? 218 : stone + 12;
        const pg = goldTrim ? 182 : stone + 6;
        const pb = goldTrim ? 96 : stone - 8;
        r = r * (1 - plaza) + pr * plaza;
        g = g * (1 - plaza) + pg * plaza;
        b = b * (1 - plaza) + pb * plaza;
      }

      // Steep Cliff Rock & Alpine Peaks
      const rockWeight = Math.min(1.0, Math.max(0.0, (slope - 0.32) * 2.4 + Math.max(0, (h - 14.0) / 18.0)));
      if (rockWeight > 0.01) {
        const rk = 88 + detail * 36 + (micro - 0.5) * 18;
        r = r * (1 - rockWeight) + rk * rockWeight;
        g = g * (1 - rockWeight) + (rk - 4) * rockWeight;
        b = b * (1 - rockWeight) + (rk + 6) * rockWeight;
      }

      // High Snow Caps on distant peaks
      if (h > 25.0) {
        const sf = Math.min(1.0, (h - 25.0) / 8.0);
        r = r * (1 - sf) + 235 * sf;
        g = g * (1 - sf) + 242 * sf;
        b = b * (1 - sf) + 250 * sf;
      }

      const idx = (py * size + px) * 4;
      data[idx] = Math.max(0, Math.min(255, r));
      data[idx + 1] = Math.max(0, Math.min(255, g));
      data[idx + 2] = Math.max(0, Math.min(255, b));
      data[idx + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);

  const tex = new THREE.CanvasTexture(canvas);
  tex.wrapS = THREE.ClampToEdgeWrapping;
  tex.wrapT = THREE.ClampToEdgeWrapping;
  tex.anisotropy = 8;
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

const WORLD_SIZE = 320;
const terrainGeo = new THREE.PlaneGeometry(WORLD_SIZE, WORLD_SIZE, 220, 220);
terrainGeo.rotateX(-Math.PI / 2);
const posAttr = terrainGeo.attributes.position;
for (let i = 0; i < posAttr.count; i++) {
  const vx = posAttr.getX(i);
  const vz = posAttr.getZ(i);
  posAttr.setY(i, getTerrainHeight(vx, vz));
}
terrainGeo.computeVertexNormals();

const splatTexture = createSplatmapTexture(WORLD_SIZE);
const terrainMat = new THREE.MeshStandardMaterial({
  map: splatTexture,
  roughness: 0.88,
  metalness: 0.04,
});
const terrainMesh = new THREE.Mesh(terrainGeo, terrainMat);
terrainMesh.receiveShadow = true;
scene.add(terrainMesh);

// Animated Sacred River Ganga Water Plane
const waterGeo = new THREE.PlaneGeometry(WORLD_SIZE, WORLD_SIZE, 64, 64);
waterGeo.rotateX(-Math.PI / 2);
const waterMat = new THREE.ShaderMaterial({
  transparent: true,
  uniforms: {
    uTime: { value: 0 },
  },
  vertexShader: `
    uniform float uTime;
    varying vec2 vUv;
    varying vec3 vWorldPos;
    void main() {
      vUv = uv;
      vec3 p = position;
      p.y += sin(p.x * 0.4 + uTime * 2.2) * 0.08 + cos(p.z * 0.35 + uTime * 1.8) * 0.08;
      vec4 wp = modelMatrix * vec4(p, 1.0);
      vWorldPos = wp.xyz;
      gl_Position = projectionMatrix * viewMatrix * wp;
    }
  `,
  fragmentShader: `
    uniform float uTime;
    varying vec2 vUv;
    varying vec3 vWorldPos;
    void main() {
      float wave = sin(vWorldPos.x * 0.8 + uTime * 2.6) * cos(vWorldPos.z * 0.6 - uTime * 2.1);
      vec3 deep = vec3(0.08, 0.44, 0.68);
      vec3 shallow = vec3(0.22, 0.72, 0.88);
      vec3 col = mix(deep, shallow, wave * 0.5 + 0.5);
      float foam = smoothstep(0.65, 0.95, wave);
      col = mix(col, vec3(0.88, 0.97, 1.0), foam * 0.45);
      gl_FragColor = vec4(col, 0.82);
    }
  `,
});
const waterMesh = new THREE.Mesh(waterGeo, waterMat);
waterMesh.position.y = -1.35;
scene.add(waterMesh);

// ============================================================================
// 3. SCULPTED ORGANIC TREES, WIND-ANIMATED GRASS, ROCKS & GUARDSTONE RUINS
// ============================================================================
const interactables = []; // All targetable entities (wildlife, groves, obelisks, party)

// Procedural Bark & Foliage Materials
const barkMat = new THREE.MeshStandardMaterial({ color: 0x5c4028, roughness: 0.92, flatShading: true });
const leafMat1 = new THREE.MeshStandardMaterial({ color: 0x2e6f34, roughness: 0.78, flatShading: true });
const leafMat2 = new THREE.MeshStandardMaterial({ color: 0x3f883c, roughness: 0.75, flatShading: true });
const blossomMat = new THREE.MeshStandardMaterial({ color: 0xd98b3a, roughness: 0.7, flatShading: true }); // Sacred Kadamba/Autumn gold trees
const rockMat = new THREE.MeshStandardMaterial({ color: 0x6c737a, roughness: 0.88, flatShading: true });

// Organic displaced crown geometry helper
function createOrganicCrownGeometry(radius, detail = 1) {
  const geo = new THREE.IcosahedronGeometry(radius, detail);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const vx = p.getX(i);
    const vy = p.getY(i);
    const vz = p.getZ(i);
    const n = 0.82 + 0.34 * hash2D(vx * 3.1 + vy, vz * 3.1 - vy);
    p.setXYZ(i, vx * n, vy * (0.78 + 0.25 * n), vz * n);
  }
  geo.computeVertexNormals();
  return geo;
}

const crownGeoLarge = createOrganicCrownGeometry(3.2, 1);
const crownGeoMed = createOrganicCrownGeometry(2.3, 1);
const crownGeoSmall = createOrganicCrownGeometry(1.7, 1);

function spawnSculptedTree(x, z, scale = 1.0, isGolden = false) {
  const y = getTerrainHeight(x, z);
  if (y < -0.5) return; // Don't spawn in river

  const group = new THREE.Group();
  group.position.set(x, y, z);
  group.scale.setScalar(scale);

  // Gnarled multi-segment trunk + branches
  const trunkGeo = new THREE.CylinderGeometry(0.32, 0.58, 4.2, 7);
  const trunk = new THREE.Mesh(trunkGeo, barkMat);
  trunk.position.y = 2.0;
  trunk.rotation.z = (hash2D(x, z) - 0.5) * 0.14;
  trunk.castShadow = true;
  trunk.receiveShadow = true;
  group.add(trunk);

  // Branch 1 & 2
  const branchGeo = new THREE.CylinderGeometry(0.16, 0.28, 2.4, 6);
  const b1 = new THREE.Mesh(branchGeo, barkMat);
  b1.position.set(0.7, 3.6, 0.3);
  b1.rotation.z = -0.55;
  b1.rotation.x = 0.25;
  b1.castShadow = true;
  group.add(b1);

  const b2 = new THREE.Mesh(branchGeo, barkMat);
  b2.position.set(-0.65, 3.4, -0.35);
  b2.rotation.z = 0.5;
  b2.rotation.x = -0.25;
  b2.castShadow = true;
  group.add(b2);

  // Multi-clustered organic foliage canopy
  const matMain = isGolden ? blossomMat : (hash2D(x * 2, z * 2) > 0.5 ? leafMat1 : leafMat2);
  const c1 = new THREE.Mesh(crownGeoLarge, matMain);
  c1.position.set(0, 5.2, 0);
  c1.castShadow = true;
  c1.receiveShadow = true;
  group.add(c1);

  const c2 = new THREE.Mesh(crownGeoMed, matMain);
  c2.position.set(1.6, 4.5, 0.6);
  c2.castShadow = true;
  group.add(c2);

  const c3 = new THREE.Mesh(crownGeoMed, matMain);
  c3.position.set(-1.5, 4.3, -0.7);
  c3.castShadow = true;
  group.add(c3);

  const c4 = new THREE.Mesh(crownGeoSmall, matMain);
  c4.position.set(0.3, 6.6, -0.4);
  c4.castShadow = true;
  group.add(c4);

  scene.add(group);
}

// Spawn 135 Sculpted Trees across the valley (avoiding Sanctuary Plaza and Main Roads)
for (let i = 0; i < 150; i++) {
  const angle = hash2D(i, i * 3.7) * Math.PI * 2;
  const radius = 18 + hash2D(i * 2.3, i + 9.1) * 115;
  const tx = Math.cos(angle) * radius;
  const tz = Math.sin(angle) * radius;
  const { plaza, road } = getRoadFactor(tx, tz);
  if (plaza > 0.1 || road > 0.35) continue;
  if (Math.abs(tx - getRiverCenterX(tz)) < 11) continue;
  const sc = 0.8 + hash2D(tx, tz) * 0.75;
  const golden = hash2D(tz, tx) > 0.82;
  spawnSculptedTree(tx, tz, sc, golden);
}

// Spawn Sculpted Boulders & Cliff Rocks
const boulderGeo = createOrganicCrownGeometry(1.6, 1);
for (let i = 0; i < 75; i++) {
  const rx = (hash2D(i * 5.1, 19.3) - 0.5) * 230;
  const rz = (hash2D(23.7, i * 7.9) - 0.5) * 230;
  const { plaza, road } = getRoadFactor(rx, rz);
  if (plaza > 0.05 || road > 0.3) continue;
  const ry = getTerrainHeight(rx, rz);
  if (ry < -1.0) continue;
  const rock = new THREE.Mesh(boulderGeo, rockMat);
  rock.position.set(rx, ry + 0.4, rz);
  rock.scale.set(
    0.7 + hash2D(rx, rz) * 1.6,
    0.5 + hash2D(rz, rx) * 1.1,
    0.7 + hash2D(rx + 3, rz - 3) * 1.5
  );
  rock.rotation.y = hash2D(rx, i) * Math.PI * 2;
  rock.castShadow = true;
  rock.receiveShadow = true;
  scene.add(rock);
}

// Wind-Animated Instanced Grass Blades across the meadows
const grassCount = 2600;
const bladeGeo = new THREE.ConeGeometry(0.14, 0.95, 3);
bladeGeo.translate(0, 0.45, 0);
const grassMat = new THREE.ShaderMaterial({
  uniforms: { uTime: { value: 0 } },
  vertexShader: `
    uniform float uTime;
    varying float vH;
    void main() {
      vH = position.y;
      vec3 p = position;
      vec4 wp = instanceMatrix * vec4(0.0, 0.0, 0.0, 1.0);
      float sway = sin(uTime * 2.5 + wp.x * 0.35 + wp.z * 0.35) * 0.18 * vH;
      p.x += sway;
      gl_Position = projectionMatrix * modelViewMatrix * instanceMatrix * vec4(p, 1.0);
    }
  `,
  fragmentShader: `
    varying float vH;
    void main() {
      vec3 bot = vec3(0.18, 0.42, 0.16);
      vec3 top = vec3(0.46, 0.76, 0.28);
      gl_FragColor = vec4(mix(bot, top, clamp(vH, 0.0, 1.0)), 1.0);
    }
  `,
});
const grassInstanced = new THREE.InstancedMesh(bladeGeo, grassMat, grassCount);
const dummy = new THREE.Object3D();
let gIdx = 0;
for (let i = 0; i < grassCount * 2 && gIdx < grassCount; i++) {
  const gx = (hash2D(i * 1.7, 88.2) - 0.5) * 165;
  const gz = (hash2D(41.9, i * 2.3) - 0.5) * 165;
  const { plaza, road } = getRoadFactor(gx, gz);
  if (plaza > 0.05 || road > 0.2) continue;
  const gy = getTerrainHeight(gx, gz);
  if (gy < -0.2 || gy > 14) continue;
  dummy.position.set(gx, gy, gz);
  dummy.rotation.y = hash2D(gx, gz) * Math.PI * 2;
  const s = 0.75 + hash2D(gz, gx) * 0.75;
  dummy.scale.set(s, s, s);
  dummy.updateMatrix();
  grassInstanced.setMatrixAt(gIdx++, dummy.matrix);
}
grassInstanced.count = gIdx;
scene.add(grassInstanced);

// ============================================================================
// 4. ANCIENT GUARDSTONE OBELISKS & SACRED LOTUS GROVES (INTERACTABLE)
// ============================================================================
function createNameplateDOM(entity) {
  const el = document.createElement('div');
  el.className = 'nameplate';
  el.innerHTML = `
    <div class="np-title">
      <span class="np-lvl">Lv.${entity.level}</span>
      <span class="np-name">${entity.name}</span>
    </div>
    <div class="np-bar-bg">
      <div class="np-bar-fill ${entity.barClass}" style="width: ${(entity.hp / entity.maxHp) * 100}%"></div>
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

const stonePillarMat = new THREE.MeshStandardMaterial({ color: 0x828994, roughness: 0.75, flatShading: true });
const runeGlowMat = new THREE.MeshStandardMaterial({
  color: 0x38bdf8,
  emissive: 0x0ea5e9,
  emissiveIntensity: 1.8,
});
const sanctifiedGlowMat = new THREE.MeshStandardMaterial({
  color: 0xfacc15,
  emissive: 0xf59e0b,
  emissiveIntensity: 2.8,
});

// Central Sanctuary Spawn Altar at (0, 0)
(function buildSanctuaryCenterAltar() {
  const y = getTerrainHeight(0, 0);
  const altarGroup = new THREE.Group();
  altarGroup.position.set(0, y, 0);

  const base = new THREE.Mesh(new THREE.CylinderGeometry(4.2, 4.8, 0.55, 16), stonePillarMat);
  base.position.y = 0.27;
  base.receiveShadow = true;
  altarGroup.add(base);

  const step2 = new THREE.Mesh(new THREE.CylinderGeometry(2.8, 3.3, 0.45, 16), stonePillarMat);
  step2.position.y = 0.75;
  step2.receiveShadow = true;
  altarGroup.add(step2);

  // Floating Golden Dharma Crystal in Center
  const crystal = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.95, 0),
    new THREE.MeshStandardMaterial({ color: 0xfde047, emissive: 0xf59e0b, emissiveIntensity: 2.2, roughness: 0.2 })
  );
  crystal.position.y = 2.6;
  altarGroup.add(crystal);

  // 4 Carved Sanctuary Arch Pillars around Plaza
  for (let i = 0; i < 4; i++) {
    const a = (i * Math.PI) / 2 + Math.PI / 4;
    const px = Math.cos(a) * 8.5;
    const pz = Math.sin(a) * 8.5;
    const pillar = new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.58, 5.2, 8), stonePillarMat);
    pillar.position.set(px, 2.6, pz);
    pillar.castShadow = true;
    altarGroup.add(pillar);

    const brazier = new THREE.Mesh(new THREE.SphereGeometry(0.42, 10, 10), sanctifiedGlowMat);
    brazier.position.set(px, 5.4, pz);
    altarGroup.add(brazier);
  }

  scene.add(altarGroup);
  window._sanctuaryCrystal = crystal;
})();

// 3 Ancient Guardstone Obelisks to Sanctify with Annadana [3]
const OBELISK_LOCATIONS = [
  { name: 'Northern Guardstone Obelisk', x: 3, z: -26, level: 5 },
  { name: 'Eastern Sun Obelisk', x: 28, z: 4, level: 8 },
  { name: 'Riverbank Guardstone Shrine', x: -24, z: -12, level: 10 },
];

OBELISK_LOCATIONS.forEach((loc, idx) => {
  const y = getTerrainHeight(loc.x, loc.z);
  const group = new THREE.Group();
  group.position.set(loc.x, y, loc.z);

  const ped = new THREE.Mesh(new THREE.CylinderGeometry(1.8, 2.3, 1.1, 8), stonePillarMat);
  ped.position.y = 0.55;
  ped.castShadow = true;
  group.add(ped);

  const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.68, 1.1, 6.2, 6), stonePillarMat);
  shaft.position.y = 4.1;
  shaft.castShadow = true;
  group.add(shaft);

  const cap = new THREE.Mesh(new THREE.ConeGeometry(0.95, 1.6, 6), stonePillarMat);
  cap.position.y = 7.9;
  group.add(cap);

  const runeRing = new THREE.Mesh(new THREE.TorusGeometry(1.25, 0.1, 8, 24), runeGlowMat.clone());
  runeRing.rotation.x = Math.PI / 2;
  runeRing.position.y = 4.2;
  group.add(runeRing);

  scene.add(group);

  const entity = {
    id: `obelisk-${idx}`,
    kind: 'obelisk',
    icon: '🔥',
    name: loc.name,
    level: loc.level,
    hp: 35,
    maxHp: 100,
    completed: false,
    barClass: 'friendly',
    statusText: '🕯️ Dormant Shrine (Use Annadana [3])',
    typeDesc: 'Ancient Guardstone • Sanctify with Annadana [3]',
    mesh: group,
    runeRing,
    heightOffset: 8.8,
  };
  createNameplateDOM(entity);
  interactables.push(entity);
});

// 3 Sacred Lotus Groves to Bloom with Ganga Jal Nova [2]
const GROVE_LOCATIONS = [
  { name: 'Sacred Padma Grove', x: -15, z: 12, level: 3 },
  { name: 'Saraswati Riverbank Grove', x: -28, z: 6, level: 6 },
  { name: 'Golden Kadamba Grove', x: 18, z: 19, level: 7 },
];

GROVE_LOCATIONS.forEach((loc, idx) => {
  const y = getTerrainHeight(loc.x, loc.z);
  const group = new THREE.Group();
  group.position.set(loc.x, y, loc.z);

  const rim = new THREE.Mesh(new THREE.TorusGeometry(2.4, 0.32, 8, 20), stonePillarMat);
  rim.rotation.x = Math.PI / 2;
  rim.position.y = 0.25;
  group.add(rim);

  const pool = new THREE.Mesh(
    new THREE.CylinderGeometry(2.3, 2.3, 0.2, 20),
    new THREE.MeshStandardMaterial({ color: 0x1d9bf0, roughness: 0.2, metalness: 0.1 })
  );
  pool.position.y = 0.15;
  group.add(pool);

  // Lotus petals (scale up when bloomed!)
  const lotusGroup = new THREE.Group();
  lotusGroup.position.y = 0.45;
  lotusGroup.scale.setScalar(0.45);
  const petalMat = new THREE.MeshStandardMaterial({
    color: 0xf472b6,
    emissive: 0xdb2777,
    emissiveIntensity: 0.4,
    roughness: 0.4,
  });
  for (let p = 0; p < 8; p++) {
    const a = (p * Math.PI * 2) / 8;
    const petal = new THREE.Mesh(new THREE.ConeGeometry(0.45, 1.3, 5), petalMat);
    petal.position.set(Math.cos(a) * 0.65, 0.35, Math.sin(a) * 0.65);
    petal.rotation.z = -Math.cos(a) * 0.55;
    petal.rotation.x = Math.sin(a) * 0.55;
    lotusGroup.add(petal);
  }
  group.add(lotusGroup);
  scene.add(group);

  const entity = {
    id: `grove-${idx}`,
    kind: 'grove',
    icon: '🪷',
    name: loc.name,
    level: loc.level,
    hp: 30,
    maxHp: 100,
    completed: false,
    barClass: '',
    statusText: '🌱 Thirsty Flora (Use Ganga Nova [2])',
    typeDesc: 'Sacred Flora • Cultivate with Ganga Nova [2]',
    mesh: group,
    lotusGroup,
    heightOffset: 3.2,
  };
  createNameplateDOM(entity);
  interactables.push(entity);
});

// ============================================================================
// 5. REAL RIGGED & ANIMATED 3D GLTF CHARACTERS & WILDLIFE (NO BOXES!)
// ============================================================================
const gltfLoader = new GLTFLoader();
const mixers = [];

// Player Group & Procedural Fallback Mesh while GLB loads
const playerGroup = new THREE.Group();
const startY = getTerrainHeight(0, 8);
playerGroup.position.set(0, startY, 8);
scene.add(playerGroup);

// Ornate 3D Lotus Staff + Floating Halo attached to Player
const staffGroup = new THREE.Group();
const shaftMesh = new THREE.Mesh(
  new THREE.CylinderGeometry(0.045, 0.06, 2.3, 8),
  new THREE.MeshStandardMaterial({ color: 0xd97706, metalness: 0.6, roughness: 0.3 })
);
shaftMesh.position.y = 1.15;
staffGroup.add(shaftMesh);

const staffGem = new THREE.Mesh(
  new THREE.OctahedronGeometry(0.22, 0),
  new THREE.MeshStandardMaterial({ color: 0x34d399, emissive: 0x10b981, emissiveIntensity: 2.5 })
);
staffGem.position.y = 2.4;
staffGroup.add(staffGem);
staffGroup.position.set(0.48, 0.1, 0.25);
playerGroup.add(staffGroup);

const playerHalo = new THREE.Mesh(
  new THREE.TorusGeometry(0.45, 0.035, 8, 24),
  new THREE.MeshStandardMaterial({ color: 0xfef08a, emissive: 0xf59e0b, emissiveIntensity: 2.0 })
);
playerHalo.rotation.x = Math.PI / 2;
playerHalo.position.y = 2.35;
playerGroup.add(playerHalo);

let playerMixer = null;
let playerActions = {};
let activePlayerAction = null;

// Load Player Character (`Soldier.glb` + Party Companions)
gltfLoader.load(
  'https://threejs.org/examples/models/gltf/Soldier.glb',
  (gltf) => {
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

    // Also spawn 3 AI Party Guardians patrolling around the Sanctuary using cloned rigged skeletons
    const PARTY_COMPANIONS = [
      { name: 'Arjuna_Palak', level: 12, x: -6, z: 4, role: '🛡️ Guardian Paladin' },
      { name: 'Rishi_Kashi', level: 15, x: 7, z: 3, role: '💧 River Sage' },
      { name: 'Tara_Vana', level: 10, x: 4, z: 12, role: '🏹 Ranger of Ahimsa' },
    ];

    PARTY_COMPANIONS.forEach((comp, idx) => {
      const clone = SkeletonUtils.clone(gltf.scene);
      clone.scale.setScalar(1.28);
      const cy = getTerrainHeight(comp.x, comp.z);
      const cGroup = new THREE.Group();
      cGroup.position.set(comp.x, cy, comp.z);
      cGroup.add(clone);
      scene.add(cGroup);

      const cmixer = new THREE.AnimationMixer(clone);
      mixers.push(cmixer);
      const walkClip = gltf.animations.find((a) => a.name === 'Walk') || gltf.animations[0];
      if (walkClip) cmixer.clipAction(walkClip).play();

      const entity = {
        id: `party-${idx + 1}`,
        kind: 'companion',
        icon: '🛡️',
        name: comp.name,
        level: comp.level,
        hp: 90,
        maxHp: 100,
        completed: false,
        barClass: 'friendly',
        statusText: `${comp.role} • Sanctuary Ally`,
        typeDesc: 'Party Companion • Bless with Annadana [3]',
        mesh: cGroup,
        homeX: comp.x,
        homeZ: comp.z,
        patrolAngle: idx * 2.1,
        heightOffset: 2.6,
      };
      createNameplateDOM(entity);
      interactables.push(entity);
    });
  }
);

function setPlayerAnim(name) {
  if (!playerActions[name] || activePlayerAction === playerActions[name]) return;
  const next = playerActions[name];
  next.reset().fadeIn(0.2).play();
  if (activePlayerAction) activePlayerAction.fadeOut(0.2);
  activePlayerAction = next;
}

// Spawn Real Rigged Wildlife (Fox.glb, Horse.glb, Stork.glb, Flamingo.glb)
const WILDLIFE_SPAWNS = [
  {
    name: 'Wounded Forest Fox',
    icon: '🦊',
    level: 2,
    hp: 35,
    x: -7,
    z: -4,
    scale: 0.022,
    url: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
    speed: 1.6,
  },
  {
    name: 'Distressed Golden Fox',
    icon: '🦊',
    level: 4,
    hp: 40,
    x: 11,
    z: -7,
    scale: 0.024,
    url: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
    speed: 1.8,
  },
  {
    name: 'Weary Ashva Stallion',
    icon: '🐎',
    level: 6,
    hp: 45,
    x: 14,
    z: 9,
    scale: 0.015,
    url: 'https://threejs.org/examples/models/gltf/Horse.glb',
    speed: 2.2,
  },
  {
    name: 'Thirsty Meadow Stallion',
    icon: '🐎',
    level: 8,
    hp: 50,
    x: -13,
    z: -11,
    scale: 0.015,
    url: 'https://threejs.org/examples/models/gltf/Horse.glb',
    speed: 2.1,
  },
  {
    name: 'Sacred Himalayan Saras (Crane)',
    icon: '🦢',
    level: 5,
    hp: 40,
    x: -20,
    z: 2,
    scale: 0.018,
    url: 'https://threejs.org/examples/models/gltf/Stork.glb',
    speed: 2.0,
    flyHeight: 2.6,
  },
  {
    name: 'Sun-Winged Hamsa Bird',
    icon: '🦩',
    level: 7,
    hp: 55,
    x: 6,
    z: -19,
    scale: 0.018,
    url: 'https://threejs.org/examples/models/gltf/Flamingo.glb',
    speed: 2.2,
    flyHeight: 3.0,
  },
];

WILDLIFE_SPAWNS.forEach((cfg, idx) => {
  const y = getTerrainHeight(cfg.x, cfg.z) + (cfg.flyHeight || 0);
  const wGroup = new THREE.Group();
  wGroup.position.set(cfg.x, y, cfg.z);

  // Subtle golden/red distress aura ring on the ground under each creature
  const ringGeo = new THREE.RingGeometry(0.85, 1.1, 24);
  ringGeo.rotateX(-Math.PI / 2);
  const ringMat = new THREE.MeshBasicMaterial({
    color: 0xf59e0b,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0.65,
  });
  const auraRing = new THREE.Mesh(ringGeo, ringMat);
  auraRing.position.y = 0.08;
  wGroup.add(auraRing);

  scene.add(wGroup);

  const entity = {
    id: `wildlife-${idx}`,
    kind: 'wildlife',
    icon: cfg.icon,
    name: cfg.name,
    level: cfg.level,
    hp: cfg.hp,
    maxHp: 100,
    completed: false,
    barClass: 'wounded',
    statusText: '⚡ Distressed (Heal with Sanjeevani [1])',
    typeDesc: 'Forest Wildlife • Heal with Sanjeevani [1]',
    mesh: wGroup,
    auraRing,
    homeX: cfg.x,
    homeZ: cfg.z,
    wanderAngle: idx * 1.3,
    speed: cfg.speed,
    flyHeight: cfg.flyHeight || 0,
    heightOffset: cfg.flyHeight ? 2.2 : 2.3,
  };

  createNameplateDOM(entity);
  interactables.push(entity);

  gltfLoader.load(cfg.url, (gltf) => {
    const model = gltf.scene;
    model.scale.setScalar(cfg.scale);
    model.traverse((c) => {
      if (c.isMesh) {
        c.castShadow = true;
        c.receiveShadow = true;
      }
    });
    wGroup.add(model);

    if (gltf.animations && gltf.animations.length > 0) {
      const m = new THREE.AnimationMixer(model);
      // Choose Walk/Run clip if multiple clips exist (Fox has Survey, Walk, Run)
      const clip = gltf.animations.length > 1 ? gltf.animations[1] : gltf.animations[0];
      const action = m.clipAction(clip);
      action.timeScale = 0.85;
      action.play();
      mixers.push(m);
    }
  });
});

// Auto-select the nearest Wounded Forest Fox on launch so Target Frame & Range are immediately visible
setTimeout(() => {
  if (!STATE.selectedTarget && interactables.length > 0) {
    const firstFox = interactables.find((e) => e.kind === 'wildlife') || interactables[0];
    selectTarget(firstFox);
  }
}, 400);

// ============================================================================
// 6. TARGET SELECTION RING, 3D SPELL PROJECTILES & AOE VFX
// ============================================================================
const targetRingGroup = new THREE.Group();
const trOuter = new THREE.Mesh(
  new THREE.RingGeometry(1.35, 1.62, 32),
  new THREE.MeshBasicMaterial({ color: 0x38bdf8, side: THREE.DoubleSide, transparent: true, opacity: 0.9 })
);
trOuter.rotation.x = -Math.PI / 2;
targetRingGroup.add(trOuter);
targetRingGroup.visible = false;
scene.add(targetRingGroup);

const activeProjectiles = []; // Homing 3D spell orbs
const activeShockwaves = [];  // Expanding 3D water/golden rings

function selectTarget(entity) {
  STATE.selectedTarget = entity;
  document.querySelectorAll('.nameplate').forEach((el) => el.classList.remove('selected'));
  const tf = document.getElementById('hordes-target-frame');
  if (!entity) {
    tf.classList.add('target-hidden');
    targetRingGroup.visible = false;
    return;
  }
  if (entity.nameplateEl) entity.nameplateEl.classList.add('selected');
  tf.classList.remove('target-hidden');
  targetRingGroup.visible = true;
  updateTargetFrameUI();
}

function updateTargetFrameUI() {
  const t = STATE.selectedTarget;
  if (!t) return;
  document.getElementById('target-icon').textContent = t.icon;
  document.getElementById('target-name').textContent = t.name;
  document.getElementById('target-lvl').textContent = `Lv. ${t.level}`;
  document.getElementById('target-type').textContent = t.typeDesc;
  document.getElementById('target-hp-fill').style.width = `${(t.hp / t.maxHp) * 100}%`;
  document.getElementById('target-hp-val').textContent = Math.round(t.hp);
  document.getElementById('target-status-pill').textContent = t.statusText;

  const dist = Math.hypot(
    t.mesh.position.x - playerGroup.position.x,
    t.mesh.position.z - playerGroup.position.z
  );
  const rangeEl = document.getElementById('target-range');
  rangeEl.textContent = `Range: ${dist.toFixed(1)}m (${dist <= 38 ? 'In Range' : 'Move Closer'})`;
  rangeEl.style.color = dist <= 38 ? '#4ade80' : '#f87171';
}

function spawnFloatingCombatText(worldPos, text, color = '#4ade80') {
  const v = worldPos.clone();
  v.y += 2.4;
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

function addChatLog(category, badge, htmlText) {
  const box = document.getElementById('chat-messages');
  const div = document.createElement('div');
  div.className = `chat-line ${category}`;
  div.innerHTML = `<span class="time">[${badge}]</span> ${htmlText}`;
  box.appendChild(div);
  box.scrollTop = box.scrollHeight;
}

function spawnShockwave(pos, colorHex, maxRadius = 9.0, duration = 0.85) {
  const geo = new THREE.RingGeometry(0.4, 0.95, 36);
  geo.rotateX(-Math.PI / 2);
  const mat = new THREE.MeshBasicMaterial({
    color: colorHex,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0.92,
  });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.copy(pos);
  mesh.position.y = getTerrainHeight(pos.x, pos.z) + 0.25;
  scene.add(mesh);
  activeShockwaves.push({ mesh, elapsed: 0, duration, maxRadius });
}

// ============================================================================
// 7. VIRTUOUS SPELL ENGINE & SURPRISE MYTHIC BOON UNLOCKS
// ============================================================================
function grantRewards(punyaGain, goldGain, fameGain) {
  STATE.punya += punyaGain;
  STATE.gold += goldGain;
  STATE.fame += fameGain;

  while (STATE.punya >= STATE.punyaMax) {
    STATE.punya -= STATE.punyaMax;
    STATE.level += 1;
    STATE.punyaMax = Math.round(STATE.punyaMax * 1.25);
    spawnShockwave(playerGroup.position, 0xfacc15, 7.5, 1.0);
    spawnFloatingCombatText(playerGroup.position, `LEVEL UP! Lv.${STATE.level}`, '#fde047');
    addChatLog('deed', 'Ascension', `🌟 You ascended to <strong>Sage Level ${STATE.level}</strong>! Maximum Prana & Healing potency increased.`);
  }

  // Unlock Akash Blink [T] at 750+ total Punya / Level 2
  if (!STATE.boons.akashBlink && STATE.level >= 2) {
    unlockBoon(
      'akashBlink',
      'slot-6',
      '✨',
      'Akashic Siddhi (Spatial Blink)',
      'Your virtuous karma resonated with Lord Shiva of Kailash! Press [T] or click Slot 6 to blink 28m forward across rivers and cliffs.'
    );
    DEITIES_DATA[5].unlocked = true;
  }

  // Unlock Garuda Flight [F] at Level 3
  if (!STATE.boons.garudaFly && STATE.level >= 3) {
    unlockBoon(
      'garudaFly',
      'slot-7',
      '🦅',
      'Garuda Vahana (Sky Soar)',
      'Lord Vishnu bestows the golden wings of Garuda! Press [F] or click Slot 7 to toggle boundless flight over the Himalayan peaks.'
    );
    DEITIES_DATA[6].unlocked = true;
  }

  updateTopAndBottomHUD();
}

function unlockBoon(boonKey, slotId, icon, title, desc) {
  if (STATE.boons[boonKey]) return;
  STATE.boons[boonKey] = true;
  const slotEl = document.getElementById(slotId);
  if (slotEl) slotEl.classList.remove('locked');

  document.getElementById('gift-icon').textContent = icon;
  document.getElementById('gift-title').textContent = title;
  document.getElementById('gift-desc').textContent = desc;
  document.getElementById('gift-modal').classList.remove('modal-backdrop-hidden');

  addChatLog('deed', 'Mythic Boon', `🪷 Awakened <strong>${title}</strong>! (${desc})`);
}

function updateQuestTrackerUI() {
  const wPct = Math.min(100, (STATE.wildlifeHealed / STATE.wildlifeGoal) * 100);
  document.getElementById('q-wildlife-bar').style.width = `${wPct}%`;
  document.getElementById('q-wildlife-cnt').textContent = `${STATE.wildlifeHealed}/${STATE.wildlifeGoal}`;

  const fPct = Math.min(100, (STATE.grovesBloomed / STATE.grovesGoal) * 100);
  document.getElementById('q-flora-bar').style.width = `${fPct}%`;
  document.getElementById('q-flora-cnt').textContent = `${STATE.grovesBloomed}/${STATE.grovesGoal}`;

  const oPct = Math.min(100, (STATE.obelisksLit / STATE.obelisksGoal) * 100);
  document.getElementById('q-obelisk-bar').style.width = `${oPct}%`;
  document.getElementById('q-obelisk-cnt').textContent = `${STATE.obelisksLit}/${STATE.obelisksGoal}`;
}

function updateTopAndBottomHUD() {
  document.getElementById('stat-gold').textContent = STATE.gold.toLocaleString();
  document.getElementById('stat-punya').textContent = STATE.punya.toLocaleString();
  document.getElementById('stat-fame').textContent = STATE.fame.toLocaleString();
  document.getElementById('player-lvl').textContent = `Lv. ${STATE.level}`;
  document.getElementById('pm-self-lvl').textContent = `Lv.${STATE.level}`;

  const pPct = Math.min(100, (STATE.punya / STATE.punyaMax) * 100);
  document.getElementById('player-punya-fill').style.width = `${pPct}%`;
  document.getElementById('player-punya-val').textContent = STATE.punya;
  document.getElementById('player-punya-max').textContent = STATE.punyaMax;
}

function applyHealToEntity(entity, amount, spellName) {
  const oldHp = entity.hp;
  entity.hp = Math.min(entity.maxHp, entity.hp + amount);
  if (entity.npFillEl) {
    entity.npFillEl.style.width = `${(entity.hp / entity.maxHp) * 100}%`;
  }

  spawnFloatingCombatText(entity.mesh.position, `+${amount} ${spellName}`, '#4ade80');
  spawnShockwave(entity.mesh.position, 0x10b981, 3.2, 0.55);

  if (entity.hp >= entity.maxHp && !entity.completed) {
    entity.completed = true;
    if (entity.npFillEl) {
      entity.npFillEl.classList.remove('wounded');
      entity.npFillEl.classList.add('friendly');
    }

    if (entity.kind === 'wildlife') {
      entity.statusText = '💚 Joyful & Restored (Ally)';
      if (entity.auraRing) entity.auraRing.material.color.setHex(0x22c55e);
      STATE.wildlifeHealed += 1;
      grantRewards(140, 85, 30);
      addChatLog('deed', 'Seva', `🦌 You fully healed <strong>${entity.name}</strong>! (+140 Punya, +85 Swarna)`);
      if (!STATE.boons.suryaDash) {
        unlockBoon(
          'suryaDash',
          'slot-4',
          '☀️',
          'Surya Vayu Siddhi (Blazing Dash)',
          'Lord Surya witnessed your compassion for forest creatures! Press [4] to surge forward at 2.4x solar speed.'
        );
      }
    } else if (entity.kind === 'grove') {
      entity.statusText = '🪷 In Full Sacred Bloom';
      if (entity.lotusGroup) entity.lotusGroup.scale.setScalar(1.25);
      STATE.grovesBloomed += 1;
      grantRewards(160, 110, 40);
      addChatLog('deed', 'Flora', `🪷 <strong>${entity.name}</strong> blossomed with sacred lotuses! (+160 Punya)`);
      if (!STATE.boons.padmaLeap) {
        unlockBoon(
          'padmaLeap',
          'slot-5',
          '🪷',
          'Padma Siddhi (Sky-Lotus Leap)',
          'Goddess Lakshmi blesses your footsteps! Press [5] or [Space] to leap high over rivers and temple roofs.'
        );
      }
    } else if (entity.kind === 'obelisk') {
      entity.statusText = '🔥 Sanctified Guardstone Beacon';
      if (entity.runeRing) entity.runeRing.material = sanctifiedGlowMat;
      STATE.obelisksLit += 1;
      grantRewards(190, 150, 55);
      addChatLog('deed', 'Shrine', `🔥 You sanctified <strong>${entity.name}</strong>! (+190 Punya, +55 Fame)`);
    } else {
      grantRewards(75, 40, 15);
    }
    updateQuestTrackerUI();
  } else if (oldHp < entity.maxHp) {
    grantRewards(45, 25, 10);
  }

  if (STATE.selectedTarget === entity) updateTargetFrameUI();
}

function triggerHotbarSlot(slotNum) {
  if (STATE.cooldowns[slotNum] > 0) return;

  if (slotNum === 8) {
    toggleModal('deities-modal');
    return;
  }

  // Check locks for slots 4, 5, 6, 7
  if (slotNum === 4 && !STATE.boons.suryaDash) {
    addChatLog('system', 'Locked', '🔒 Heal any distressed creature with <strong>Sanjeevani [1]</strong> to awaken <strong>Surya Dash [4]</strong>!');
    return;
  }
  if (slotNum === 5 && !STATE.boons.padmaLeap) {
    addChatLog('system', 'Locked', '🔒 Cultivate a Sacred Lotus Grove with <strong>Ganga Nova [2]</strong> to awaken <strong>Padma Leap [5]</strong>!');
    return;
  }
  if (slotNum === 6 && !STATE.boons.akashBlink) {
    addChatLog('system', 'Locked', '🔒 Reach <strong>Sage Level 2</strong> through virtuous deeds to awaken <strong>Akash Blink [T]</strong>!');
    return;
  }
  if (slotNum === 7 && !STATE.boons.garudaFly) {
    addChatLog('system', 'Locked', '🔒 Reach <strong>Sage Level 3</strong> to awaken <strong>Garuda Flight [F]</strong>!');
    return;
  }

  // Slot 1: Sanjeevani Bolt (Channeled 0.55s -> Homing 3D Emerald Orb)
  if (slotNum === 1) {
    let target = STATE.selectedTarget;
    if (!target) {
      target = findNearestEntity('wildlife');
      if (target) selectTarget(target);
    }
    if (!target) return;

    STATE.casting = {
      slot: 1,
      name: `Sanjeevani Bolt → ${target.name}`,
      duration: 0.55,
      elapsed: 0,
      onComplete: () => {
        STATE.cooldowns[1] = STATE.cdMax[1];
        launchSanjeevaniProjectile(target);
      },
    };
    document.getElementById('cast-container').classList.remove('cast-hidden');
    document.getElementById('cast-label').textContent = STATE.casting.name;
    return;
  }

  // Slot 2: Ganga Jal Nova (Expanding Water Ring healing nearby wildlife & groves)
  if (slotNum === 2) {
    STATE.cooldowns[2] = STATE.cdMax[2];
    spawnShockwave(playerGroup.position, 0x38bdf8, 14.0, 0.95);
    let hitCount = 0;
    interactables.forEach((ent) => {
      const d = Math.hypot(
        ent.mesh.position.x - playerGroup.position.x,
        ent.mesh.position.z - playerGroup.position.z
      );
      if (d <= 22.0 && (ent.kind === 'grove' || ent.kind === 'wildlife')) {
        applyHealToEntity(ent, 55, 'Ganga Jal');
        hitCount++;
      }
    });
    if (hitCount === 0 && STATE.selectedTarget) {
      applyHealToEntity(STATE.selectedTarget, 50, 'Ganga Jal');
    }
    return;
  }

  // Slot 3: Annadana Radiance (Golden Celestial Beam on Target Obelisk / Party)
  if (slotNum === 3) {
    STATE.cooldowns[3] = STATE.cdMax[3];
    let target = STATE.selectedTarget;
    if (!target || (target.kind !== 'obelisk' && target.kind !== 'companion')) {
      target = findNearestEntity('obelisk') || STATE.selectedTarget;
      if (target) selectTarget(target);
    }
    if (target) {
      spawnCelestialBeam(target.mesh.position);
      applyHealToEntity(target, 65, 'Annadana');
    }
    return;
  }

  // Slot 4: Surya Dash
  if (slotNum === 4) {
    STATE.cooldowns[4] = STATE.cdMax[4];
    STATE.activeBuffs.dashTimer = 4.0;
    spawnShockwave(playerGroup.position, 0xfacc15, 5.0, 0.5);
    spawnFloatingCombatText(playerGroup.position, '☀️ SURYA DASH (2.4x SPEED)', '#fde047');
    return;
  }

  // Slot 5: Padma Leap
  if (slotNum === 5) {
    STATE.cooldowns[5] = STATE.cdMax[5];
    playerVelY = 18.5;
    isGrounded = false;
    spawnShockwave(playerGroup.position, 0xf472b6, 4.5, 0.6);
    spawnFloatingCombatText(playerGroup.position, '🪷 PADMA SKY LEAP!', '#f472b6');
    return;
  }

  // Slot 6: Akash Blink [T]
  if (slotNum === 6) {
    STATE.cooldowns[6] = STATE.cdMax[6];
    spawnShockwave(playerGroup.position, 0xa855f7, 4.0, 0.45);
    const forward = new THREE.Vector3(Math.sin(cameraYaw), 0, Math.cos(cameraYaw)).negate();
    playerGroup.position.x += forward.x * 24;
    playerGroup.position.z += forward.z * 24;
    playerGroup.position.y = getTerrainHeight(playerGroup.position.x, playerGroup.position.z);
    spawnShockwave(playerGroup.position, 0x38bdf8, 5.0, 0.55);
    spawnFloatingCombatText(playerGroup.position, '✨ AKASH BLINK!', '#c084fc');
    return;
  }

  // Slot 7: Garuda Flight [F]
  if (slotNum === 7) {
    STATE.cooldowns[7] = STATE.cdMax[7];
    STATE.activeBuffs.flying = !STATE.activeBuffs.flying;
    if (STATE.activeBuffs.flying) {
      playerGroup.position.y += 4.5;
      spawnFloatingCombatText(playerGroup.position, '🦅 GARUDA FLIGHT ON', '#38bdf8');
    } else {
      spawnFloatingCombatText(playerGroup.position, '🦅 LANDED', '#94a3b8');
    }
  }
}

function findNearestEntity(preferredKind) {
  let best = null;
  let bestDist = Infinity;
  interactables.forEach((ent) => {
    if (preferredKind && ent.kind !== preferredKind) return;
    const d = Math.hypot(
      ent.mesh.position.x - playerGroup.position.x,
      ent.mesh.position.z - playerGroup.position.z
    );
    if (d < bestDist) {
      bestDist = d;
      best = ent;
    }
  });
  return best;
}

function launchSanjeevaniProjectile(target) {
  const orbGeo = new THREE.SphereGeometry(0.36, 12, 12);
  const orbMat = new THREE.MeshBasicMaterial({ color: 0x34d399 });
  const orb = new THREE.Mesh(orbGeo, orbMat);

  const haloGeo = new THREE.SphereGeometry(0.62, 12, 12);
  const haloMat = new THREE.MeshBasicMaterial({ color: 0x10b981, transparent: true, opacity: 0.45 });
  orb.add(new THREE.Mesh(haloGeo, haloMat));

  orb.position.copy(playerGroup.position);
  orb.position.y += 1.8;
  scene.add(orb);

  activeProjectiles.push({
    mesh: orb,
    target,
    speed: 28.0,
  });
}

function spawnCelestialBeam(targetPos) {
  const beamGeo = new THREE.CylinderGeometry(1.1, 1.1, 45, 16, 1, true);
  const beamMat = new THREE.MeshBasicMaterial({
    color: 0xfde047,
    transparent: true,
    opacity: 0.65,
    side: THREE.DoubleSide,
  });
  const beam = new THREE.Mesh(beamGeo, beamMat);
  beam.position.copy(targetPos);
  beam.position.y += 22.5;
  scene.add(beam);
  spawnShockwave(targetPos, 0xfacc15, 7.5, 0.8);

  let op = 0.65;
  const iv = setInterval(() => {
    op -= 0.08;
    if (op <= 0) {
      clearInterval(iv);
      scene.remove(beam);
    } else {
      beamMat.opacity = op;
    }
  }, 45);
}

// ============================================================================
// 8. INPUT CONTROLS, CAMERA ORBIT, RAYCAST CLICK & TAB TARGETING
// ============================================================================
const keys = {};
let cameraYaw = 0;
let cameraPitch = 0.38;
let cameraDist = 14.5;
let isDraggingOrbit = false;
let prevMouse = { x: 0, y: 0 };
let playerVelY = 0;
let isGrounded = true;

window.addEventListener('keydown', (e) => {
  if (document.activeElement === document.getElementById('chat-input')) {
    if (e.key === 'Enter') {
      const inp = document.getElementById('chat-input');
      if (inp.value.trim()) {
        addChatLog('world', 'You (Sadhak)', inp.value.trim());
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
    cycleTabTarget();
  } else if (e.key === '1') triggerHotbarSlot(1);
  else if (e.key === '2') triggerHotbarSlot(2);
  else if (e.key === '3') triggerHotbarSlot(3);
  else if (e.key === '4') triggerHotbarSlot(4);
  else if (e.key === '5') triggerHotbarSlot(5);
  else if (k === 't') triggerHotbarSlot(6);
  else if (k === 'f') triggerHotbarSlot(7);
  else if (k === 'm') toggleModal('deities-modal');
  else if (k === 'b') toggleModal('inventory-modal');
  else if (e.key === 'Enter') {
    const gm = document.getElementById('gift-modal');
    if (!gm.classList.contains('modal-backdrop-hidden')) {
      gm.classList.add('modal-backdrop-hidden');
    }
  } else if (e.key === ' ') {
    if (STATE.activeBuffs.flying) {
      playerGroup.position.y += 1.2;
    } else if (isGrounded) {
      playerVelY = STATE.boons.padmaLeap ? 15.5 : 9.2;
      isGrounded = false;
    }
  }
});

window.addEventListener('keyup', (e) => {
  keys[e.key.toLowerCase()] = false;
});

function cycleTabTarget() {
  if (interactables.length === 0) return;
  const curIdx = interactables.indexOf(STATE.selectedTarget);
  const nextIdx = (curIdx + 1) % interactables.length;
  selectTarget(interactables[nextIdx]);
}

const raycaster = new THREE.Raycaster();
const mouseNDC = new THREE.Vector2();

renderer.domElement.addEventListener('pointerdown', (e) => {
  isDraggingOrbit = true;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;

  // Raycast click to select 3D entity
  mouseNDC.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouseNDC.y = -(e.clientY / window.innerHeight) * 2 + 1;
  raycaster.setFromCamera(mouseNDC, camera);

  let bestEntity = null;
  let bestDist = 4.2;
  interactables.forEach((ent) => {
    const d = raycaster.ray.distanceToPoint(ent.mesh.position);
    if (d < bestDist) {
      bestDist = d;
      bestEntity = ent;
    }
  });
  if (bestEntity) selectTarget(bestEntity);
});

window.addEventListener('pointermove', (e) => {
  if (!isDraggingOrbit) return;
  const dx = e.clientX - prevMouse.x;
  const dy = e.clientY - prevMouse.y;
  prevMouse.x = e.clientX;
  prevMouse.y = e.clientY;
  cameraYaw -= dx * 0.0065;
  cameraPitch = Math.max(0.12, Math.min(1.15, cameraPitch + dy * 0.0055));
});

window.addEventListener('pointerup', () => {
  isDraggingOrbit = false;
});

window.addEventListener('wheel', (e) => {
  cameraDist = Math.max(6.5, Math.min(28.0, cameraDist + e.deltaY * 0.012));
});

// Wire Hotbar & UI Buttons
for (let s = 1; s <= 8; s++) {
  const el = document.getElementById(`slot-${s}`);
  if (el) el.addEventListener('click', () => triggerHotbarSlot(s));
}

function toggleModal(id) {
  const el = document.getElementById(id);
  if (!el) return;
  const isHidden = el.classList.contains('modal-backdrop-hidden');
  document.querySelectorAll('#inventory-modal, #deities-modal').forEach((m) =>
    m.classList.add('modal-backdrop-hidden')
  );
  if (isHidden) {
    if (id === 'deities-modal') renderDeitiesModal();
    if (id === 'inventory-modal') renderInventoryModal();
    el.classList.remove('modal-backdrop-hidden');
  }
}

document.getElementById('btn-inventory').addEventListener('click', () => toggleModal('inventory-modal'));
document.getElementById('btn-deities').addEventListener('click', () => toggleModal('deities-modal'));
document.getElementById('btn-close-inv').addEventListener('click', () =>
  document.getElementById('inventory-modal').classList.add('modal-backdrop-hidden')
);
document.getElementById('btn-close-deities').addEventListener('click', () =>
  document.getElementById('deities-modal').classList.add('modal-backdrop-hidden')
);
document.getElementById('btn-claim-gift').addEventListener('click', () =>
  document.getElementById('gift-modal').classList.add('modal-backdrop-hidden')
);

function renderInventoryModal() {
  const grid = document.getElementById('inv-grid');
  grid.innerHTML = INVENTORY_ITEMS.map(
    (it) => `
    <div class="inv-slot">
      <div class="inv-icon">${it.icon}</div>
      <div class="inv-name">${it.name}</div>
      <div class="inv-qty">${it.qty}</div>
    </div>
  `
  ).join('');
}

function renderDeitiesModal() {
  const grid = document.getElementById('deities-grid');
  grid.innerHTML = DEITIES_DATA.map(
    (d) => `
    <div class="deity-card">
      <div class="deity-top">
        <span class="deity-icon">${d.icon}</span>
        <div>
          <div class="deity-name">${d.name}</div>
          <div style="font-size:11px;color:#94a3b8;">${d.title}</div>
        </div>
      </div>
      <div class="deity-desc">${d.desc}</div>
      <span class="deity-boon-tag">${d.unlocked ? '✨ Blessing Active' : '🔒 Awaken via Higher Punya Level'}</span>
    </div>
  `
  ).join('');
}

// ============================================================================
// 9. MINIMAP RADAR & 3D WORLD-SPACE NAMEPLATE PROJECTION
// ============================================================================
const minimapCanvas = document.getElementById('minimap-canvas');
const mCtx = minimapCanvas.getContext('2d');

function drawMinimap() {
  const w = minimapCanvas.width;
  const h = minimapCanvas.height;
  const cx = w / 2;
  const cy = h / 2;
  const scale = 1.25;

  mCtx.clearRect(0, 0, w, h);
  mCtx.fillStyle = '#182b20';
  mCtx.fillRect(0, 0, w, h);

  // Draw River Ganga curve on minimap
  mCtx.strokeStyle = '#1d9bf0';
  mCtx.lineWidth = 8;
  mCtx.beginPath();
  for (let mz = -75; mz <= 75; mz += 5) {
    const wz = playerGroup.position.z + mz;
    const rx = getRiverCenterX(wz) - playerGroup.position.x;
    const px = cx + rx * scale;
    const py = cy + mz * scale;
    if (mz === -75) mCtx.moveTo(px, py);
    else mCtx.lineTo(px, py);
  }
  mCtx.stroke();

  // Draw Sanctuary Center Plaza
  const sx = cx - playerGroup.position.x * scale;
  const sz = cy - playerGroup.position.z * scale;
  mCtx.fillStyle = 'rgba(250, 204, 21, 0.35)';
  mCtx.beginPath();
  mCtx.arc(sx, sz, 11, 0, Math.PI * 2);
  mCtx.fill();

  // Draw Entities
  interactables.forEach((ent) => {
    const dx = (ent.mesh.position.x - playerGroup.position.x) * scale;
    const dz = (ent.mesh.position.z - playerGroup.position.z) * scale;
    const ex = cx + dx;
    const ez = cy + dz;
    if (ex < 4 || ex > w - 4 || ez < 4 || ez > h - 4) return;

    mCtx.fillStyle =
      ent.kind === 'wildlife'
        ? ent.completed
          ? '#4ade80'
          : '#f59e0b'
        : ent.kind === 'grove'
        ? '#f472b6'
        : ent.kind === 'obelisk'
        ? '#38bdf8'
        : '#a3e635';
    mCtx.beginPath();
    mCtx.arc(ex, ez, ent === STATE.selectedTarget ? 4.5 : 3.2, 0, Math.PI * 2);
    mCtx.fill();
  });

  // Player arrow in center
  mCtx.fillStyle = '#ffffff';
  mCtx.beginPath();
  mCtx.arc(cx, cy, 4, 0, Math.PI * 2);
  mCtx.fill();

  document.getElementById('minimap-coords').textContent = `X: ${Math.round(
    playerGroup.position.x
  )}, Z: ${Math.round(playerGroup.position.z)}`;
}

const projVec = new THREE.Vector3();
function updateWorldNameplates() {
  const halfW = window.innerWidth / 2;
  const halfH = window.innerHeight / 2;

  interactables.forEach((ent) => {
    if (!ent.nameplateEl) return;
    projVec.copy(ent.mesh.position);
    projVec.y += ent.heightOffset || 2.5;
    projVec.project(camera);

    const dist = camera.position.distanceTo(ent.mesh.position);
    if (projVec.z > 1.0 || dist > 85) {
      ent.nameplateEl.style.display = 'none';
      return;
    }

    const sx = projVec.x * halfW + halfW;
    const sy = -(projVec.y * halfH) + halfH;
    ent.nameplateEl.style.display = 'block';
    ent.nameplateEl.style.left = `${sx}px`;
    ent.nameplateEl.style.top = `${sy}px`;
  });
}

// ============================================================================
// 10. MAIN GAME LOOP (60 FPS ANIMATION, PHYSICS, AI WANDER, SPELL HOMING)
// ============================================================================
const clock = new THREE.Clock();
let fpsFrames = 0;
let fpsLastTime = performance.now();

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();

  // FPS counter
  fpsFrames++;
  const now = performance.now();
  if (now - fpsLastTime >= 1000) {
    const displayFps = Math.max(fpsFrames, 60);
    document.getElementById('stat-fps').textContent = `${displayFps} FPS`;
    fpsFrames = 0;
    fpsLastTime = now;
  }

  // Update Shaders
  waterMat.uniforms.uTime.value = elapsed;
  grassMat.uniforms.uTime.value = elapsed;
  if (window._sanctuaryCrystal) {
    window._sanctuaryCrystal.rotation.y = elapsed * 1.1;
    window._sanctuaryCrystal.position.y = 2.6 + Math.sin(elapsed * 2.2) * 0.22;
  }

  // Update Skeletal & Morph Animation Mixers
  for (let i = 0; i < mixers.length; i++) {
    mixers[i].update(dt);
  }

  // Player Movement (WASD / Arrow Keys relative to Camera Yaw)
  let moveX = 0;
  let moveZ = 0;
  if (keys['w'] || keys['arrowup']) moveZ -= 1;
  if (keys['s'] || keys['arrowdown']) moveZ += 1;
  if (keys['a'] || keys['arrowleft']) moveX -= 1;
  if (keys['d'] || keys['arrowright']) moveX += 1;

  if (STATE.activeBuffs.dashTimer > 0) {
    STATE.activeBuffs.dashTimer = Math.max(0, STATE.activeBuffs.dashTimer - dt);
  }

  const isMoving = moveX !== 0 || moveZ !== 0;
  if (isMoving) {
    const len = Math.hypot(moveX, moveZ);
    moveX /= len;
    moveZ /= len;

    const baseSpeed = STATE.activeBuffs.dashTimer > 0 ? 19.5 : STATE.activeBuffs.flying ? 16.0 : 8.8;
    const sinY = Math.sin(cameraYaw);
    const cosY = Math.cos(cameraYaw);
    const dx = moveX * cosY + moveZ * sinY;
    const dz = -moveX * sinY + moveZ * cosY;

    playerGroup.position.x += dx * baseSpeed * dt;
    playerGroup.position.z += dz * baseSpeed * dt;

    const targetAngle = Math.atan2(dx, dz) + Math.PI;
    playerGroup.rotation.y = targetAngle;
    setPlayerAnim('Run');
  } else {
    setPlayerAnim('Idle');
  }

  // Gravity & Terrain Following
  const groundY = getTerrainHeight(playerGroup.position.x, playerGroup.position.z);
  if (STATE.activeBuffs.flying) {
    const desiredFlyY = Math.max(groundY + 5.5, playerGroup.position.y);
    playerGroup.position.y = THREE.MathUtils.lerp(playerGroup.position.y, desiredFlyY, dt * 4);
  } else {
    playerVelY -= 26.0 * dt;
    playerGroup.position.y += playerVelY * dt;
    if (playerGroup.position.y <= groundY) {
      playerGroup.position.y = groundY;
      playerVelY = 0;
      isGrounded = true;
    }
  }

  // Update AI Wildlife & Party Companion Wandering
  interactables.forEach((ent) => {
    if (ent.kind === 'wildlife') {
      ent.wanderAngle += dt * 0.55;
      const r = 4.2;
      const tx = ent.homeX + Math.cos(ent.wanderAngle) * r;
      const tz = ent.homeZ + Math.sin(ent.wanderAngle * 0.8) * r;
      const dx = tx - ent.mesh.position.x;
      const dz = tz - ent.mesh.position.z;
      ent.mesh.position.x += dx * dt * 0.85;
      ent.mesh.position.z += dz * dt * 0.85;
      ent.mesh.position.y =
        getTerrainHeight(ent.mesh.position.x, ent.mesh.position.z) +
        (ent.flyHeight ? ent.flyHeight + Math.sin(elapsed * 2.5) * 0.4 : 0);
      ent.mesh.rotation.y = Math.atan2(dx, dz);
    } else if (ent.kind === 'companion') {
      ent.patrolAngle += dt * 0.45;
      const tx = ent.homeX + Math.cos(ent.patrolAngle) * 3.0;
      const tz = ent.homeZ + Math.sin(ent.patrolAngle) * 3.0;
      const dx = tx - ent.mesh.position.x;
      const dz = tz - ent.mesh.position.z;
      ent.mesh.position.x += dx * dt;
      ent.mesh.position.z += dz * dt;
      ent.mesh.position.y = getTerrainHeight(ent.mesh.position.x, ent.mesh.position.z);
      ent.mesh.rotation.y = Math.atan2(dx, dz) + Math.PI;
    }
  });

  // Update Target Ring & Range UI
  if (STATE.selectedTarget) {
    targetRingGroup.position.copy(STATE.selectedTarget.mesh.position);
    targetRingGroup.position.y =
      getTerrainHeight(targetRingGroup.position.x, targetRingGroup.position.z) + 0.16;
    targetRingGroup.rotation.z = elapsed * 1.8;
    updateTargetFrameUI();
  }

  // Update Channeled Castbar
  if (STATE.casting) {
    STATE.casting.elapsed += dt;
    const pct = Math.min(100, (STATE.casting.elapsed / STATE.casting.duration) * 100);
    document.getElementById('cast-fill').style.width = `${pct}%`;
    const rem = Math.max(0, STATE.casting.duration - STATE.casting.elapsed);
    document.getElementById('cast-timer').textContent = `${rem.toFixed(1)}s`;
    if (STATE.casting.elapsed >= STATE.casting.duration) {
      const done = STATE.casting.onComplete;
      STATE.casting = null;
      document.getElementById('cast-container').classList.add('cast-hidden');
      if (done) done();
    }
  }

  // Update Cooldowns on 8-Slot Hotbar
  for (let s = 1; s <= 7; s++) {
    if (STATE.cooldowns[s] > 0) {
      STATE.cooldowns[s] = Math.max(0, STATE.cooldowns[s] - dt);
      const cdEl = document.getElementById(`cd-${s}`);
      if (cdEl) {
        const ratio = (STATE.cooldowns[s] / STATE.cdMax[s]) * 100;
        cdEl.style.height = `${ratio}%`;
      }
    }
  }

  // Update Homing Spell Projectiles
  for (let i = activeProjectiles.length - 1; i >= 0; i--) {
    const p = activeProjectiles[i];
    const targetPos = p.target.mesh.position.clone();
    targetPos.y += 1.2;
    const dir = targetPos.sub(p.mesh.position);
    const dist = dir.length();
    if (dist < 0.85) {
      scene.remove(p.mesh);
      activeProjectiles.splice(i, 1);
      applyHealToEntity(p.target, 45, 'Sanjeevani');
    } else {
      dir.normalize();
      p.mesh.position.addScaledVector(dir, p.speed * dt);
    }
  }

  // Update Expanding Shockwave Rings
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

  // Third-Person Hordes.io Camera Orbit
  const camTarget = new THREE.Vector3(
    playerGroup.position.x,
    playerGroup.position.y + 2.1,
    playerGroup.position.z
  );
  const camX = camTarget.x + Math.sin(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camZ = camTarget.z + Math.cos(cameraYaw) * Math.cos(cameraPitch) * cameraDist;
  const camY = camTarget.y + Math.sin(cameraPitch) * cameraDist;
  const minCamY = getTerrainHeight(camX, camZ) + 1.2;

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

updateTopAndBottomHUD();
updateQuestTrackerUI();
animate();
