import * as THREE from 'three';
import { Sky } from 'three/addons/objects/Sky.js';

// ============================================================================
// AUDIO SYNTHESIZER (Spatial ambience, zone fanfares, spell audio)
// ============================================================================
class SoundEngine {
  constructor() {
    this.ctx = null;
    this.initOnFirstInteraction();
  }

  initOnFirstInteraction() {
    const unlock = () => {
      if (!this.ctx) {
        const AudioContext = window.AudioContext || window.webkitAudioContext;
        this.ctx = new AudioContext();
      }
      if (this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
      window.removeEventListener('keydown', unlock);
      window.removeEventListener('mousedown', unlock);
    };
    window.addEventListener('keydown', unlock);
    window.addEventListener('mousedown', unlock);
  }

  playChime(freq = 528, duration = 0.8) {
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(freq * 1.4, this.ctx.currentTime + duration);

    gain.gain.setValueAtTime(0.3, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + duration);
  }

  playZoneFanfare() {
    if (!this.ctx) return;
    const notes = [261.63, 329.63, 392.00, 523.25]; // C4, E4, G4, C5
    notes.forEach((freq, idx) => {
      setTimeout(() => this.playChime(freq, 1.2), idx * 160);
    });
  }

  playHeal() {
    if (!this.ctx) return;
    [432, 540, 648, 864].forEach((f, i) => setTimeout(() => this.playChime(f, 0.6), i * 80));
  }
}

const audio = new SoundEngine();

// ============================================================================
// 1. WOW-CLASSIC 4 LARGE PROGRESSION ZONES DEFINITION
// ============================================================================
const ZONES = [
  {
    id: 'ashram',
    name: 'Vrindavan Sacred Grove & Ashram (वृन्दावन आश्रम)',
    sub: 'Level 1-10 Starting Zone • The Meadow of Compassion',
    levelReq: 1,
    bounds: { minX: -100, maxX: 100, minZ: -100, maxZ: 100 },
    fogColor: 0x181326,
    sunIntensity: 2.8
  },
  {
    id: 'ghats',
    name: 'Varanasi Ancient Ghats & Sacred Ganga (महातीर्थ काशी)',
    sub: 'Level 10-25 Water & Spiritual Cleansing Zone',
    levelReq: 10,
    bounds: { minX: -450, maxX: -100, minZ: -300, maxZ: 300 },
    fogColor: 0x112233,
    sunIntensity: 2.2
  },
  {
    id: 'gurukul',
    name: 'Takshashila Ancient Academy & Fortress (तक्षशिला दुर्ग)',
    sub: 'Level 25-45 Fortified Knowledge & Martial Testing Grounds',
    levelReq: 25,
    bounds: { minX: 100, maxX: 450, minZ: -300, maxZ: 300 },
    fogColor: 0x241d1a,
    sunIntensity: 3.2
  },
  {
    id: 'himalaya',
    name: 'Himalayan Mount Kailash Peak (कैलाश शिखर)',
    sub: 'Level 45-60 Endgame Celestial Transcendence Realm',
    levelReq: 45,
    bounds: { minX: -300, maxX: 300, minZ: -650, maxZ: -200 },
    fogColor: 0x1a2d42,
    sunIntensity: 3.8
  }
];

const GRADES = [
  { level: 1, name: 'Sadhak (Seeker)', title: 'The Compassionate Seeker', req: 0, mult: 1.0 },
  { level: 5, name: 'Sevak (Guardian)', title: 'Protector of the Groves', req: 150, mult: 1.3 },
  { level: 10, name: 'Dharmik (Pilgrim of Kashi)', title: 'Purifier of the Ghats', req: 400, mult: 1.6 },
  { level: 25, name: 'Veer (Scholar-Warrior)', title: 'Master of Takshashila', req: 1200, mult: 2.2 },
  { level: 45, name: 'Rishi (Ascetic of Kailash)', title: 'Voice of Higher Truth', req: 3000, mult: 3.0 },
  { level: 60, name: 'Paramahamsa (Supreme Sovereign)', title: 'Guardian of Ancient & Future Bharat', req: 6000, mult: 4.5 }
];

const CELESTIAL_GIFTS = [
  { id: 'lotus_leap', name: 'Padma Siddhi (Lotus Leap)', tier: 'MYTHIC BOON', icon: '🪷', desc: 'Allows triple-jump soaring over cliffs and temple parapets.', unlockedKey: 'jump' },
  { id: 'surya_sprint', name: 'Surya Tejas (Solar Sprint)', tier: 'EPIC BOON', icon: '☀️', desc: 'Sprint at 3x speed across massive zones with radiant footsteps.', unlockedKey: 'sprint' },
  { id: 'garuda_wings', name: 'Garuda Paksha (Flight of Kailash)', tier: 'DIVINE ENDGAME MOUNT', icon: '🦅', desc: 'Full flight across the 1200-meter Himalayan skyway! Press [F].', unlockedKey: 'fly' },
  { id: 'akash_blink', name: 'Akash Gamana (Astral Teleport)', tier: 'TRANSCENDENT SIDDHI', icon: '✨', desc: 'Instantly warp 40 meters forward across chasm bridges. Press [T].', unlockedKey: 'teleport' }
];

// ============================================================================
// 2. STATE MANAGER
// ============================================================================
const state = {
  punya: 0,
  gold: 2400,
  fame: 150,
  annadanaCount: 0,
  prana: 100,
  level: 1,
  currentZone: ZONES[0],
  selectedTarget: null,
  isFlying: false,
  boons: {
    sprint: false,
    jump: false,
    fly: false,
    teleport: false
  },
  quests: {
    ashram: { till: 0, sow: 0, heal: 0, completed: false },
    ghats: { clean: 0, lamp: 0, feed: 0, completed: false },
    takshashila: { sparring: 0, scroll: 0, bell: 0, completed: false },
    kailash: { meditate: 0, flame: 0, completed: false }
  },
  discoveredZones: { ashram: true }
};

// ============================================================================
// 3. THREE.JS ENGINE SETUP (Massive Draw Distance for WoW-Scale Landscapes)
// ============================================================================
const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x181326, 0.0018);

const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.5, 2400);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.15;
container.appendChild(renderer.domElement);

// Atmospheric Preetham Sky Shader
const sky = new Sky();
sky.scale.setScalar(5000);
scene.add(sky);
const skyUniforms = sky.material.uniforms;
skyUniforms['turbidity'].value = 6;
skyUniforms['rayleigh'].value = 2.0;
skyUniforms['mieCoefficient'].value = 0.004;
skyUniforms['mieDirectionalG'].value = 0.8;

const sunVec = new THREE.Vector3();
const phi = THREE.MathUtils.degToRad(72);
const theta = THREE.MathUtils.degToRad(205);
sunVec.setFromSphericalCoords(1, phi, theta);
skyUniforms['sunPosition'].value.copy(sunVec);

const dirLight = new THREE.DirectionalLight(0xffdfa0, 2.8);
dirLight.position.copy(sunVec).multiplyScalar(400);
dirLight.castShadow = true;
dirLight.shadow.mapSize.set(2048, 2048);
dirLight.shadow.camera.near = 10;
dirLight.shadow.camera.far = 1200;
const d = 300;
dirLight.shadow.camera.left = -d; dirLight.shadow.camera.right = d;
dirLight.shadow.camera.top = d; dirLight.shadow.camera.bottom = -d;
scene.add(dirLight);

const hemiLight = new THREE.HemisphereLight(0xffecc7, 0x1b1928, 1.25);
scene.add(hemiLight);

// ============================================================================
// 4. SHARED PBR MATERIALS
// ============================================================================
const matSandstone = new THREE.MeshStandardMaterial({ color: 0xd9a464, roughness: 0.85 });
const matDarkStone = new THREE.MeshStandardMaterial({ color: 0x473c35, roughness: 0.9 });
const matMarble = new THREE.MeshStandardMaterial({ color: 0xfdfaf2, roughness: 0.35 });
const matGold = new THREE.MeshStandardMaterial({ color: 0xffd700, roughness: 0.25, metalness: 0.8 });
const matGrass = new THREE.MeshStandardMaterial({ color: 0x3d7038, roughness: 0.9 });
const matRiverWater = new THREE.MeshStandardMaterial({ color: 0x1b6ca8, roughness: 0.1, transparent: true, opacity: 0.85 });
const matSnow = new THREE.MeshStandardMaterial({ color: 0xf0f6ff, roughness: 0.6 });
const matIce = new THREE.MeshStandardMaterial({ color: 0x93c5fd, roughness: 0.2, transparent: true, opacity: 0.9 });

// Master World Terrain Plane (1400m x 1400m)
const worldGround = new THREE.Mesh(new THREE.PlaneGeometry(1600, 1600), matGrass);
worldGround.rotation.x = -Math.PI / 2;
worldGround.receiveShadow = true;
scene.add(worldGround);

const interactables = [];

// Selection Reticle on Active Target
const targetRing = new THREE.Mesh(
  new THREE.RingGeometry(2.0, 2.4, 32),
  new THREE.MeshBasicMaterial({ color: 0x38bdf8, side: THREE.DoubleSide })
);
targetRing.rotation.x = -Math.PI / 2;
targetRing.visible = false;
scene.add(targetRing);

// ============================================================================
// 5. ZONE BUILDER: 4 DISTINCT WOW-CLASSIC BIOMES
// ============================================================================

// ----------------------------------------------------------------------------
// ZONE 1: VRINDAVAN ASHRAM & SACRED GROVE (Center: 0, 0)
// ----------------------------------------------------------------------------
function buildVrindavanAshram() {
  // Sacred Banyan Centerpiece
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(2.5, 4.2, 14, 16), matDarkStone);
  trunk.position.set(0, 7, 0);
  trunk.castShadow = true;
  scene.add(trunk);

  const foliage = new THREE.Mesh(
    new THREE.DodecahedronGeometry(12, 1),
    new THREE.MeshStandardMaterial({ color: 0x2d8a38, roughness: 0.8 })
  );
  foliage.position.set(0, 18, 0);
  foliage.castShadow = true;
  scene.add(foliage);

  // Meditation Plinth & Chhatra around the tree
  const plinth = new THREE.Mesh(new THREE.CylinderGeometry(16, 17, 1.2, 24), matMarble);
  plinth.position.y = 0.6;
  plinth.receiveShadow = true;
  scene.add(plinth);

  // 6 Sacred Soil Beds for Healing Blooms
  for (let r = 0; r < 2; r++) {
    for (let c = 0; c < 3; c++) {
      const px = (c - 1) * 12;
      const pz = 28 + r * 12;

      const bed = new THREE.Mesh(new THREE.BoxGeometry(8, 0.6, 8), matSandstone);
      bed.position.set(px, 0.3, pz);
      scene.add(bed);

      const soilMat = new THREE.MeshStandardMaterial({ color: 0x4a3220, roughness: 0.95 });
      const soil = new THREE.Mesh(new THREE.BoxGeometry(7.2, 0.7, 7.2), soilMat);
      soil.position.set(px, 0.35, pz);
      scene.add(soil);

      const plantGroup = new THREE.Group();
      plantGroup.position.set(px, 0.7, pz);
      scene.add(plantGroup);

      const plot = {
        id: `plot_${r}_${c}`,
        type: 'garden_plot',
        name: `Ashram Tulsi Bed #${r * 3 + c + 1}`,
        subtitle: '[Needs Tilling & Ganga Water]',
        icon: '🌿',
        pos: new THREE.Vector3(px, 0.5, pz),
        stage: 'untilled',
        health: 20,
        soilMat,
        plantGroup
      };
      interactables.push(plot);
    }
  }

  // Wounded Ashram Fawns
  const fawnGroup = new THREE.Group();
  fawnGroup.position.set(22, 0, -18);
  const fawnBody = new THREE.Mesh(new THREE.BoxGeometry(2, 1.2, 2.6), new THREE.MeshStandardMaterial({ color: 0xba7638 }));
  fawnBody.position.y = 1.1;
  fawnGroup.add(fawnBody);
  const fawnHead = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1.3), new THREE.MeshStandardMaterial({ color: 0xba7638 }));
  fawnHead.position.set(0, 2.2, 1.3);
  fawnGroup.add(fawnHead);
  scene.add(fawnGroup);

  interactables.push({
    id: 'ashram_fawn',
    type: 'creature',
    name: 'Wounded Ashram Fawn',
    subtitle: '[Needs Sanjeevani Herbs (1)]',
    icon: '🦌',
    pos: new THREE.Vector3(22, 0, -18),
    health: 35,
    maxHealth: 100,
    healed: false
  });
}

// ----------------------------------------------------------------------------
// ZONE 2: VARANASI SACRED GHATS & RIVER GANGA (West: X: -280 to -120)
// ----------------------------------------------------------------------------
function buildVaranasiGhats() {
  const riverX = -260;

  // The Grand River Ganga Plane
  const ganga = new THREE.Mesh(new THREE.PlaneGeometry(160, 900), matRiverWater);
  ganga.rotation.x = -Math.PI / 2;
  ganga.position.set(riverX, 0.5, 0);
  scene.add(ganga);

  // Tiered Sandstone Ghats leading down to the water
  for (let s = 0; s < 12; s++) {
    const step = new THREE.Mesh(new THREE.BoxGeometry(6, 0.6, 500), matSandstone);
    step.position.set(-140 - s * 5.5, (11 - s) * 0.6, 0);
    step.receiveShadow = true;
    step.castShadow = true;
    scene.add(step);
  }

  // 4 Grand Riverside Temple Pavilions
  [-160, -60, 60, 160].forEach((pz, idx) => {
    const temple = new THREE.Group();
    temple.position.set(-145, 7.2, pz);

    const base = new THREE.Mesh(new THREE.BoxGeometry(16, 2, 16), matSandstone);
    temple.add(base);

    for (let c = 0; c < 4; c++) {
      const spire = new THREE.Mesh(new THREE.ConeGeometry(3.5, 14, 8), matSandstone);
      spire.position.set(c === 0 || c === 1 ? -5 : 5, 8, c === 0 || c === 2 ? -5 : 5);
      temple.add(spire);
    }

    const mainDome = new THREE.Mesh(new THREE.SphereGeometry(4.5, 16, 16), matGold);
    mainDome.position.y = 10;
    temple.add(mainDome);

    scene.add(temple);

    // Deepa / Ganga Aarti Fire Stand
    const deepa = new THREE.Mesh(new THREE.CylinderGeometry(1.2, 0.8, 2.2, 12), matGold);
    deepa.position.set(-170, 4.2, pz);
    scene.add(deepa);

    interactables.push({
      id: `ghat_deepa_${idx}`,
      type: 'deepa',
      name: `Ganga Aarti Sacred Flame #${idx + 1}`,
      subtitle: '[Offer Holy Flowers & Prayers]',
      icon: '🪔',
      pos: new THREE.Vector3(-170, 4.2, pz),
      health: 100
    });
  });

  // Pilgrim Annadana Chhatra at the Ghat Entrance
  const foodStall = new THREE.Mesh(new THREE.BoxGeometry(18, 5, 10), matSandstone);
  foodStall.position.set(-120, 8, 0);
  scene.add(foodStall);

  interactables.push({
    id: 'kashi_annadana',
    type: 'annadana',
    name: 'Kashi Vishwanath Annadana Hall',
    subtitle: '[Serve 100 Free Sacred Meals]',
    icon: '🍲',
    pos: new THREE.Vector3(-120, 8, 0),
    health: 100
  });
}

// ----------------------------------------------------------------------------
// ZONE 3: TAKSHASHILA ANCIENT ACADEMY & FORTRESS (East: X: 140 to 380)
// ----------------------------------------------------------------------------
function buildTakshashilaFortress() {
  const fortX = 260;

  // Massive Sandstone Perimeter Walls & Battlements
  const northWall = new THREE.Mesh(new THREE.BoxGeometry(220, 16, 8), matDarkStone);
  northWall.position.set(fortX, 8, -140);
  const southWall = new THREE.Mesh(new THREE.BoxGeometry(220, 16, 8), matDarkStone);
  southWall.position.set(fortX, 8, 140);
  const eastWall = new THREE.Mesh(new THREE.BoxGeometry(8, 16, 280), matDarkStone);
  eastWall.position.set(fortX + 110, 8, 0);

  scene.add(northWall, southWall, eastWall);

  // Grand Entrance Gate Towers
  const gateTower1 = new THREE.Mesh(new THREE.CylinderGeometry(7, 8, 24, 16), matDarkStone);
  gateTower1.position.set(fortX - 110, 12, -25);
  const gateTower2 = gateTower1.clone();
  gateTower2.position.set(fortX - 110, 12, 25);
  scene.add(gateTower1, gateTower2);

  // Central Great Library of Vedic Scrolls
  const library = new THREE.Mesh(new THREE.BoxGeometry(60, 20, 70), matSandstone);
  library.position.set(fortX, 10, 0);
  library.castShadow = true;
  scene.add(library);

  // Martial Sparring Terracotta Ring (Veer Bhumi)
  const ring = new THREE.Mesh(new THREE.CylinderGeometry(20, 21, 1, 32), new THREE.MeshStandardMaterial({ color: 0xa84a2a }));
  ring.position.set(fortX, 0.6, -70);
  scene.add(ring);

  interactables.push({
    id: 'takshashila_arena',
    type: 'arena_spar',
    name: 'Malla-Yuddha Martial Sparring Ring',
    subtitle: '[Discipline & Agility Training]',
    icon: '⚔️',
    pos: new THREE.Vector3(fortX, 1, -70),
    health: 100
  });

  interactables.push({
    id: 'takshashila_library',
    type: 'ancient_scroll',
    name: 'Ancient Palm-Leaf Archives',
    subtitle: '[Transcribe Sacred Texts of Bharat]',
    icon: '📜',
    pos: new THREE.Vector3(fortX, 2, 0),
    health: 100
  });
}

// ----------------------------------------------------------------------------
// ZONE 4: HIMALAYAN MOUNT KAILASH PEAK (North: Z: -600 to -240)
// ----------------------------------------------------------------------------
function buildHimalayanKailash() {
  const kailashZ = -440;

  // Towering Snow-Capped Mountain Range
  const peakGeo = new THREE.ConeGeometry(120, 260, 8);
  const peak = new THREE.Mesh(peakGeo, matSnow);
  peak.position.set(0, 130, kailashZ);
  peak.castShadow = true;
  scene.add(peak);

  // Flanking Mountain Ridges
  const leftRidge = new THREE.Mesh(new THREE.ConeGeometry(80, 180, 6), matDarkStone);
  leftRidge.position.set(-140, 90, kailashZ + 40);
  const rightRidge = new THREE.Mesh(new THREE.ConeGeometry(90, 200, 6), matDarkStone);
  rightRidge.position.set(150, 100, kailashZ + 30);
  scene.add(leftRidge, rightRidge);

  // Frozen Sacred Lake Manasarovar
  const lake = new THREE.Mesh(new THREE.CircleGeometry(65, 32), matIce);
  lake.rotation.x = -Math.PI / 2;
  lake.position.set(0, 1.2, kailashZ + 160);
  scene.add(lake);

  // Eternal Yogic Flame of Mahadeva Shiva
  const flamePedestal = new THREE.Mesh(new THREE.CylinderGeometry(4, 5, 3, 16), matMarble);
  flamePedestal.position.set(0, 2.5, kailashZ + 160);
  scene.add(flamePedestal);

  const flameAura = new THREE.Mesh(
    new THREE.OctahedronGeometry(2.4, 2),
    new THREE.MeshBasicMaterial({ color: 0x38bdf8, wireframe: true })
  );
  flameAura.position.set(0, 6.5, kailashZ + 160);
  scene.add(flameAura);

  interactables.push({
    id: 'kailash_flame',
    type: 'eternal_flame',
    name: 'Eternal Yogic Flame of Mount Kailash',
    subtitle: '[Highest Seat of Dhyana & Moksha]',
    icon: '❄️',
    pos: new THREE.Vector3(0, 3, kailashZ + 160),
    health: 100
  });
}

// Build all 4 zones
buildVrindavanAshram();
buildVaranasiGhats();
buildTakshashilaFortress();
buildHimalayanKailash();

// ============================================================================
// 6. PLAYER AVATAR & 3RD PERSON ENGINE
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, 0, 14);
scene.add(playerGroup);

const charMat = new THREE.MeshStandardMaterial({ color: 0xff7700, roughness: 0.4 });
const skinMat = new THREE.MeshStandardMaterial({ color: 0xf5c6a5, roughness: 0.5 });
const charBody = new THREE.Mesh(new THREE.CylinderGeometry(0.7, 0.9, 2.4, 16), charMat);
charBody.position.y = 1.6;
charBody.castShadow = true;
playerGroup.add(charBody);

const charHead = new THREE.Mesh(new THREE.SphereGeometry(0.58, 16, 16), skinMat);
charHead.position.y = 3.2;
charHead.castShadow = true;
playerGroup.add(charHead);

const charHalo = new THREE.Mesh(
  new THREE.RingGeometry(0.75, 1.0, 32),
  new THREE.MeshBasicMaterial({ color: 0xffe066, side: THREE.DoubleSide })
);
charHalo.position.set(0, 3.3, -0.4);
playerGroup.add(charHalo);

// Controls & Camera Orbit
const keys = {};
let camYaw = 0;
let camPitch = 0.32;
let camDist = 16;
let isDragging = false;
let velY = 0;

window.addEventListener('keydown', (e) => {
  keys[e.code] = true;
  if (e.code === 'Digit1') castSpell(1);
  if (e.code === 'Digit2') castSpell(2);
  if (e.code === 'Digit3') castSpell(3);
  if (e.code === 'Digit4') castSpell(4);
  if (e.code === 'Digit5') castSpell(5);
  if (e.code === 'KeyF') castSpell('F');
  if (e.code === 'KeyT') castSpell('T');
  if (e.code === 'KeyM') toggleDeitiesModal();
  if (e.code === 'KeyE') interactWithTargetOrNearest();
  if (e.code === 'Tab') {
    e.preventDefault();
    cycleNearestTarget();
  }
});

window.addEventListener('keyup', (e) => {
  keys[e.code] = false;
});

renderer.domElement.addEventListener('mousedown', (e) => {
  if (e.button === 0) {
    // Left click targeting
    const mouse = new THREE.Vector2(
      (e.clientX / window.innerWidth) * 2 - 1,
      -(e.clientY / window.innerHeight) * 2 + 1
    );
    let nearest = null;
    let nearestDist = Infinity;
    interactables.forEach((item) => {
      const screenPos = item.pos.clone().project(camera);
      const d = new THREE.Vector2(screenPos.x, screenPos.y).distanceTo(mouse);
      if (d < 0.15 && d < nearestDist) {
        nearestDist = d;
        nearest = item;
      }
    });
    if (nearest) selectTarget(nearest);
  }
  isDragging = true;
});

window.addEventListener('mouseup', () => { isDragging = false; });
window.addEventListener('mousemove', (e) => {
  if (!isDragging) return;
  camYaw -= e.movementX * 0.0055;
  camPitch = Math.max(0.04, Math.min(1.2, camPitch + e.movementY * 0.005));
});
window.addEventListener('wheel', (e) => {
  camDist = Math.max(6, Math.min(48, camDist + e.deltaY * 0.02));
});

// ============================================================================
// 7. TARGETING, ZONE DISCOVERY & SPELLCASTING
// ============================================================================
function selectTarget(item) {
  state.selectedTarget = item;
  targetRing.visible = true;
  targetRing.position.set(item.pos.x, 0.45, item.pos.z);

  const frame = document.getElementById('wow-target-frame');
  frame.classList.remove('target-hidden');
  document.getElementById('target-name').textContent = item.name;
  document.getElementById('target-subtitle').textContent = item.subtitle;
  document.getElementById('target-icon').textContent = item.icon;
  document.getElementById('target-health-val').textContent = Math.round(item.health);
  document.getElementById('target-health-fill').style.width = `${item.health}%`;

  audio.playChime(440, 0.3);
}

function cycleNearestTarget() {
  let nearest = null;
  let minDist = Infinity;
  interactables.forEach((item) => {
    const d = playerGroup.position.distanceTo(item.pos);
    if (d < minDist && item !== state.selectedTarget) {
      minDist = d;
      nearest = item;
    }
  });
  if (nearest) selectTarget(nearest);
}

function interactWithTargetOrNearest() {
  let tgt = state.selectedTarget;
  if (!tgt) {
    let minDist = Infinity;
    interactables.forEach((item) => {
      const d = playerGroup.position.distanceTo(item.pos);
      if (d < 16 && d < minDist) {
        minDist = d;
        tgt = item;
      }
    });
  }
  if (!tgt) {
    showFloatingText(playerGroup.position, 'No target selected! Approach an object and press [E]', 'float-healing');
    return;
  }

  selectTarget(tgt);

  if (tgt.type === 'garden_plot') handleGardenPlot(tgt);
  else if (tgt.type === 'creature') castSpell(1);
  else if (tgt.type === 'deepa') lightDeepa(tgt);
  else if (tgt.type === 'annadana') castSpell(3);
  else if (tgt.type === 'arena_spar') martialTraining(tgt);
  else if (tgt.type === 'ancient_scroll') studyScroll(tgt);
  else if (tgt.type === 'eternal_flame') meditateAtKailash(tgt);
}

function castSpell(key) {
  const tgt = state.selectedTarget;
  const dist = tgt ? playerGroup.position.distanceTo(tgt.pos) : 999;

  // Spell 1: Sanjeevani Herbs (Healing)
  if (key === 1 || key === '1') {
    triggerCooldown('1', 1.2);
    if (tgt && tgt.type === 'creature' && dist < 16) {
      tgt.health = Math.min(100, tgt.health + 35);
      document.getElementById('target-health-val').textContent = Math.round(tgt.health);
      document.getElementById('target-health-fill').style.width = `${tgt.health}%`;

      audio.playHeal();
      showFloatingText(tgt.pos, '+35 Vitality', 'float-healing');
      awardPunya(45, 'Healed Injured Creature');

      if (tgt.health >= 100 && !tgt.healed) {
        tgt.healed = true;
        tgt.subtitle = '[Fully Healed & Grateful]';
        document.getElementById('target-subtitle').textContent = tgt.subtitle;
        showSurpriseGift(CELESTIAL_GIFTS[1]); // Surya Sprint
      }
    } else {
      audio.playChime(380, 0.4);
      showFloatingText(playerGroup.position, '+15 Prana Balance', 'float-healing');
      state.prana = Math.min(100, state.prana + 15);
      updateHUD();
    }
  }

  // Spell 2: Ganga Jal (Watering & Sanctifying)
  if (key === 2 || key === '2') {
    triggerCooldown('2', 1.5);
    audio.playChime(640, 0.5);
    if (tgt && tgt.type === 'garden_plot' && dist < 16) {
      handleGardenPlot(tgt);
    } else {
      showFloatingText(playerGroup.position, 'Sanctified Ground with Ganga Jal', 'float-healing');
      awardPunya(15, 'Sanctification Deed');
    }
  }

  // Spell 3: Annadana (Feeding Pilgrims)
  if (key === 3 || key === '3') {
    triggerCooldown('3', 2.0);
    state.annadanaCount += 5;
    audio.playChime(720, 0.7);
    showFloatingText(playerGroup.position, 'Distributed 5 Annadana Meals (+65 Punya)', 'float-punya');
    awardPunya(65, 'Shared Food with Weary Travelers');
  }

  // Spell 4: Solar Sprint
  if (key === 4 || key === '4') {
    if (!state.boons.sprint) {
      showFloatingText(playerGroup.position, 'Locked! Heal creatures to unlock Surya Tejas.', 'float-punya');
      return;
    }
    triggerCooldown('4', 8.0);
    audio.playChime(880, 0.5);
    showFloatingText(playerGroup.position, '☀️ Surya Sprint Active!', 'float-punya');
  }

  // Spell 5: Lotus Leap
  if (key === 5 || key === '5') {
    if (!state.boons.jump) {
      showFloatingText(playerGroup.position, 'Locked! Nurture sacred blooms to unlock Lotus Leap.', 'float-punya');
      return;
    }
    velY = 28;
    audio.playChime(760, 0.6);
    showFloatingText(playerGroup.position, '🪷 Lotus Leap Soaring!', 'float-punya');
  }

  // Spell F: Garuda Flight
  if (key === 'F' || key === 'f') {
    if (!state.boons.fly) {
      showFloatingText(playerGroup.position, 'Locked! Reach Level 45 or Mount Kailash to unlock Garuda Flight.', 'float-punya');
      return;
    }
    state.isFlying = !state.isFlying;
    audio.playChime(950, 0.8);
    showFloatingText(playerGroup.position, state.isFlying ? '🦅 Ascended into Free Flight!' : 'Descended to Earth', 'float-punya');
  }

  // Spell T: Akash Blink (Teleport)
  if (key === 'T' || key === 't') {
    if (!state.boons.teleport) {
      showFloatingText(playerGroup.position, 'Locked! Attain Level 25 or Takshashila Mastery to unlock Blink.', 'float-punya');
      return;
    }
    const forward = new THREE.Vector3(0, 0, -1).applyAxisAngle(new THREE.Vector3(0, 1, 0), playerGroup.rotation.y);
    playerGroup.position.addScaledVector(forward, 40);
    audio.playChime(1100, 0.8);
    showFloatingText(playerGroup.position, '✨ Akash Blink (40m Forward)!', 'float-punya');
  }
}

function handleGardenPlot(plot) {
  if (plot.stage === 'untilled') {
    plot.stage = 'tilled';
    plot.soilMat.color.setHex(0x2d1a0d);
    plot.subtitle = '[Tilled • Sowing Sacred Tulsi Seeds]';
    audio.playChime(520, 0.5);
    showFloatingText(plot.pos, 'Tilled Sacred Soil Bed', 'float-punya');
    awardPunya(25, 'Soil Preparation');
  } else if (plot.stage === 'tilled') {
    plot.stage = 'mature';
    plot.subtitle = '[Mature Bloom • Press E to Harvest]';
    rebuildPlant(plot);
    audio.playChime(640, 0.5);
    showFloatingText(plot.pos, 'Sapling Bloomed with Radiance!', 'float-healing');
    awardPunya(45, 'Nurtured Sacred Life');
  } else if (plot.stage === 'mature') {
    plot.stage = 'untilled';
    plot.subtitle = '[Harvested • Needs Tilling]';
    while (plot.plantGroup.children.length) plot.plantGroup.remove(plot.plantGroup.children[0]);
    audio.playChime(880, 0.9);
    showFloatingText(plot.pos, '✨ Harvested Sacred Bloom! (+100 Punya, +150 Gold)', 'float-punya');
    awardPunya(100, 'Sacred Harvest');
    state.gold += 150;
    if (!state.boons.jump) showSurpriseGift(CELESTIAL_GIFTS[0]); // Lotus Leap
  }
  updateHUD();
}

function rebuildPlant(plot) {
  while (plot.plantGroup.children.length) plot.plantGroup.remove(plot.plantGroup.children[0]);
  const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.15, 0.2, 2.6, 8), new THREE.MeshStandardMaterial({ color: 0x22c55e }));
  stem.position.y = 1.3;
  plot.plantGroup.add(stem);
  const flower = new THREE.Mesh(new THREE.DodecahedronGeometry(1.2), new THREE.MeshStandardMaterial({ color: 0xff69b4, emissive: 0xaa2266, emissiveIntensity: 0.5 }));
  flower.position.y = 2.8;
  plot.plantGroup.add(flower);
}

function lightDeepa(deepa) {
  audio.playChime(780, 0.6);
  showFloatingText(deepa.pos, 'Lit Holy Deepa Lamp on the Ghats (+50 Punya)', 'float-punya');
  awardPunya(50, 'Ganga Aarti Light');
}

function martialTraining(arena) {
  audio.playChime(820, 0.5);
  showFloatingText(arena.pos, 'Practiced Malla Sparring Form (+60 Punya, +Agility)', 'float-punya');
  awardPunya(60, 'Martial Self-Discipline');
}

function studyScroll(scroll) {
  audio.playChime(920, 0.6);
  showFloatingText(scroll.pos, 'Deciphered Ancient Sanskrit Wisdom (+80 Punya)', 'float-punya');
  awardPunya(80, 'Takshashila Knowledge');
}

function meditateAtKailash(flame) {
  audio.playChime(1050, 0.9);
  showFloatingText(flame.pos, 'Attained Silent Dhyana at Mount Kailash (+200 Punya)', 'float-punya');
  awardPunya(200, 'Kailash Transcendence');
  if (!state.boons.fly) showSurpriseGift(CELESTIAL_GIFTS[2]); // Garuda Flight
}

// ============================================================================
// 8. PROGRESSION, LEVELING & ZONE DETECTION
// ============================================================================
function awardPunya(amount, reason) {
  const currentGrade = GRADES.slice().reverse().find(g => state.level >= g.level) || GRADES[0];
  const gained = Math.round(amount * currentGrade.mult);
  state.punya += gained;

  // Level Up Check
  const nextGrade = GRADES.find(g => g.level > state.level && state.punya >= g.req);
  if (nextGrade) {
    state.level = nextGrade.level;
    triggerLevelUp(nextGrade);
  }

  // Automatic Siddhi Unlocks
  if (state.level >= 25 && !state.boons.teleport) showSurpriseGift(CELESTIAL_GIFTS[3]); // Akash Blink
  if (state.level >= 45 && !state.boons.fly) showSurpriseGift(CELESTIAL_GIFTS[2]); // Garuda Flight

  updateHUD();
}

function triggerLevelUp(grade) {
  audio.playZoneFanfare();
  const banner = document.getElementById('levelup-banner');
  document.getElementById('levelup-title').textContent = `GRADE ${grade.level}: ${grade.name.toUpperCase()}`;
  banner.classList.remove('levelup-hidden');

  // Spawn golden ascension pillar
  const pillar = new THREE.Mesh(
    new THREE.CylinderGeometry(3.5, 3.5, 120, 24),
    new THREE.MeshBasicMaterial({ color: 0xffe066, transparent: true, opacity: 0.8 })
  );
  pillar.position.set(playerGroup.position.x, 60, playerGroup.position.z);
  scene.add(pillar);

  let op = 0.8;
  const fade = setInterval(() => {
    op -= 0.05;
    pillar.material.opacity = op;
    if (op <= 0) {
      clearInterval(fade);
      scene.remove(pillar);
    }
  }, 60);

  setTimeout(() => banner.classList.add('levelup-hidden'), 4500);
}

function checkZoneTriggers() {
  const px = playerGroup.position.x;
  const pz = playerGroup.position.z;

  const foundZone = ZONES.find((z) => {
    return px >= z.bounds.minX && px <= z.bounds.maxX && pz >= z.bounds.minZ && pz <= z.bounds.maxZ;
  }) || ZONES[0];

  if (foundZone !== state.currentZone) {
    state.currentZone = foundZone;
    audio.playZoneFanfare();

    // Trigger WoW Zone Banner
    const banner = document.getElementById('zone-banner');
    document.getElementById('zone-name').textContent = foundZone.name;
    document.getElementById('zone-sub').textContent = foundZone.sub;
    banner.classList.remove('zone-text-hidden');

    setTimeout(() => {
      banner.classList.add('zone-text-hidden');
    }, 4500);
  }
}

function showSurpriseGift(gift) {
  audio.playZoneFanfare();
  state.boons[gift.unlockedKey] = true;
  unlockActionSlot(gift.unlockedKey);

  document.getElementById('gift-rarity-text').textContent = `⭐ ${gift.tier} ⭐`;
  document.getElementById('gift-icon-big').textContent = gift.icon;
  document.getElementById('gift-name-text').textContent = gift.name;
  document.getElementById('gift-desc-text').textContent = gift.desc;
  document.getElementById('gift-modal').classList.remove('gift-modal-hidden');
}

document.getElementById('gift-claim-btn').addEventListener('click', () => {
  document.getElementById('gift-modal').classList.add('gift-modal-hidden');
});

function unlockActionSlot(key) {
  const map = { sprint: 'slot-4', jump: 'slot-5', fly: 'slot-6', teleport: 'slot-7' };
  const el = document.getElementById(map[key]);
  if (el) {
    el.classList.remove('locked');
    const lock = el.querySelector('.lock-indicator');
    if (lock) lock.remove();
  }
}

function triggerCooldown(slotNum, seconds) {
  const cd = document.getElementById(`cd-${slotNum}`);
  if (!cd) return;
  cd.style.height = '100%';
  let start = Date.now();
  const iv = setInterval(() => {
    let elapsed = (Date.now() - start) / 1000;
    let pct = Math.max(0, 1 - elapsed / seconds);
    cd.style.height = `${pct * 100}%`;
    if (pct <= 0) {
      clearInterval(iv);
      cd.style.height = '0%';
    }
  }, 50);
}

function showFloatingText(pos3D, text, cssClass = 'float-punya') {
  const container = document.getElementById('floating-text-container');
  const span = document.createElement('div');
  span.className = `floating-num ${cssClass}`;
  span.textContent = text;

  const screenPos = pos3D.clone().add(new THREE.Vector3(0, 2.5, 0)).project(camera);
  const x = ((screenPos.x + 1) / 2) * window.innerWidth;
  const y = ((-screenPos.y + 1) / 2) * window.innerHeight;

  span.style.left = `${x}px`;
  span.style.top = `${y}px`;
  container.appendChild(span);

  setTimeout(() => span.remove(), 1600);
}

function toggleDeitiesModal() {
  const modal = document.getElementById('deities-modal');
  modal.classList.toggle('modal-backdrop-hidden');
}
document.getElementById('close-modal-btn').addEventListener('click', toggleDeitiesModal);

// ============================================================================
// 9. UI SYNCHRONIZATION
// ============================================================================
function updateHUD() {
  const currentGrade = GRADES.slice().reverse().find(g => state.level >= g.level) || GRADES[0];
  const nextGrade = GRADES.find(g => g.level > state.level) || currentGrade;

  document.getElementById('player-level-badge').textContent = state.level;
  document.getElementById('player-char-name').textContent = `${currentGrade.name}`;
  document.getElementById('player-char-title').textContent = `[${currentGrade.title}]`;

  document.getElementById('prana-val').textContent = Math.round(state.prana);
  document.getElementById('prana-fill').style.width = `${state.prana}%`;

  document.getElementById('punya-val').textContent = state.punya.toLocaleString();
  document.getElementById('punya-max').textContent = nextGrade.req.toLocaleString();

  const pct = nextGrade === currentGrade
    ? 100
    : Math.min(100, Math.round(((state.punya - currentGrade.req) / (nextGrade.req - currentGrade.req)) * 100));
  document.getElementById('punya-fill').style.width = `${Math.max(4, pct)}%`;

  document.getElementById('cur-gold').textContent = state.gold.toLocaleString();
  document.getElementById('cur-annadana').textContent = state.annadanaCount;
  document.getElementById('cur-fame').textContent = state.fame;
}

// ============================================================================
// 10. 60-FPS ANIMATION & RENDER LOOP
// ============================================================================
const clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();

  charHalo.rotation.z = elapsed * 1.5;

  // WASD Locomotion
  let moveX = 0;
  let moveZ = 0;
  if (keys['KeyW'] || keys['ArrowUp']) moveZ -= 1;
  if (keys['KeyS'] || keys['ArrowDown']) moveZ += 1;
  if (keys['KeyA'] || keys['ArrowLeft']) moveX -= 1;
  if (keys['KeyD'] || keys['ArrowRight']) moveX += 1;

  const isMoving = moveX !== 0 || moveZ !== 0;
  let speed = 14;
  if (state.boons.sprint || keys['ShiftLeft']) speed = 28;
  if (state.isFlying) speed = 40;

  if (isMoving) {
    const moveAngle = Math.atan2(moveX, moveZ) + camYaw;
    playerGroup.rotation.y = moveAngle + Math.PI;
    playerGroup.position.x += Math.sin(moveAngle) * speed * dt;
    playerGroup.position.z += Math.cos(moveAngle) * speed * dt;
  }

  // Vertical Movement (Jump & Garuda Flight)
  if (state.isFlying) {
    if (keys['Space']) playerGroup.position.y += 24 * dt;
    if (keys['ControlLeft'] || keys['KeyC']) playerGroup.position.y = Math.max(0.2, playerGroup.position.y - 24 * dt);
  } else {
    if (keys['Space'] && playerGroup.position.y <= 0.05) {
      velY = state.boons.jump ? 26 : 14;
      audio.playChime(640, 0.3);
    }
    velY -= 36 * dt;
    playerGroup.position.y = Math.max(0, playerGroup.position.y + velY * dt);
    if (playerGroup.position.y <= 0) velY = 0;
  }

  // Camera Follow
  const targetPos = playerGroup.position.clone().add(new THREE.Vector3(0, 2.2, 0));
  camera.position.x = targetPos.x + Math.sin(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.z = targetPos.z + Math.cos(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.y = Math.max(1.5, targetPos.y + Math.sin(camPitch) * camDist);
  camera.lookAt(targetPos);

  // Check Zone boundaries
  checkZoneTriggers();

  // Compass Objective Guidance
  let nearest = interactables[0];
  let minDist = Infinity;
  interactables.forEach((item) => {
    const d = playerGroup.position.distanceTo(item.pos);
    if (d < minDist) {
      minDist = d;
      nearest = item;
    }
  });

  if (nearest) {
    const d = Math.round(minDist);
    document.getElementById('compass-zone-text').textContent =
      d < 6 ? `REACHED: ${nearest.name}` : `GUIDE: ${nearest.name} (${d}m)`;
  }

  renderer.render(scene, camera);
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

updateHUD();
animate();
