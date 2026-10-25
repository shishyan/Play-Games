import * as THREE from 'three';
import { Sky } from 'three/addons/objects/Sky.js';
import { Water } from 'three/addons/objects/Water.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// ============================================================================
// 1. GAME DEFINITIONS: 7 GRADES, VIRTUES, SACRED GARDEN, ARENA, 7 GODS & EMPIRE
// ============================================================================
const GRADES = [
  { level: 1, roman: 'I', name: 'Seeker (Sadhak) • जिज्ञासु', title: 'The Novice of Truth', req: 0, mult: 1.0, haloColor: 0xdddddd },
  { level: 2, roman: 'II', name: 'Apprentice (Sevak) • सेवक', title: 'The Compassionate Helper', req: 100, mult: 1.2, haloColor: 0x38d996 },
  { level: 3, roman: 'III', name: 'Disciple (Dharmik) • धार्मिक', title: 'The Righteous Protector', req: 300, mult: 1.4, haloColor: 0x3bc9db },
  { level: 4, roman: 'IV', name: 'Contemplative (Yogi) • योगी', title: 'The Centered Soul', req: 700, mult: 1.7, haloColor: 0xa855f7 },
  { level: 5, roman: 'V', name: 'Sage of Light (Rishi) • ऋषि', title: 'Counselor of Wisdom', req: 1500, mult: 2.1, haloColor: 0xf59e0b },
  { level: 6, roman: 'VI', name: 'Great Soul (Mahatma) • महात्मा', title: 'The Legendary Paragon', req: 3000, mult: 2.6, haloColor: 0xef4444 },
  { level: 7, roman: 'VII', name: 'Enlightened (Paramahamsa) • परमहंस', title: 'The Supreme Transcendent Saint', req: 6000, mult: 3.5, haloColor: 0xffe066 },
];

const SEEDS = [
  { id: 'tulsi', name: 'Holy Tulsi (तुलसी)', color: 0x9b59b6, stem: 0x2ecc71, virtue: 35, gold: 45, boonId: 'walk', boonName: 'Charan Sparsh (Graceful Walk +Speed)', boonDesc: 'Walking Speed +35% & Herbal Footsteps' },
  { id: 'marigold', name: 'Golden Marigold (झेंडू)', color: 0xffa500, stem: 0x27ae60, virtue: 40, gold: 60, boonId: 'sprint', boonName: 'Surya Ashva (Solar Sprint)', boonDesc: 'Blazing Running Speed (2.0x)' },
  { id: 'lotus', name: 'Sacred Padma Lotus (पद्म)', color: 0xff69b4, stem: 0x16a085, virtue: 65, gold: 100, boonId: 'jump', boonName: 'Padma Plavana (Lotus Sky Leap)', boonDesc: 'High Levitation Jump (2.4x)' },
  { id: 'parijata', name: 'Celestial Parijata (पारिजात)', color: 0xfff5e6, stem: 0xff7f50, virtue: 110, gold: 180, boonId: 'fly', boonName: 'Garuda Gamana (Ascended Flight [F])', boonDesc: 'Press [F] to Fly freely across the skies!' },
  { id: 'sanjeevani', name: 'Maha Sanjeevani (संजीवनी)', color: 0x00ffcc, stem: 0x00b894, virtue: 180, gold: 320, boonId: 'teleport', boonName: 'Akash Gamana (Astral Blink [T])', boonDesc: 'Press [T] to Teleport forward instantly!' },
  { id: 'kalpavriksha', name: 'Kalpavriksha Sapling (कल्पवृक्ष)', color: 0xffd700, stem: 0xd4af37, virtue: 350, gold: 600, boonId: 'cosmic', boonName: 'Maha Siddhi (All-Cosmic Mastery)', boonDesc: 'Unlocks Flight, Teleport, Sprint & Golden Halo!' },
];

const SURPRISE_GIFTS = [
  { name: 'Amrita Kalash (Nectar of Immortality)', tier: 'DIVINE RELIC', virtue: 500, gold: 1000, quote: 'The Heavens shower golden lotus petals! You have received the immortal Amrita Kalash!' },
  { name: 'Maha Rudraksha Mala of 108 Beads', tier: 'LEGENDARY RELIC', virtue: 300, gold: 500, quote: 'A wandering Himalayan Rishi smiles with grace and bestows his sanctified Rudraksha!' },
  { name: 'Kundalas of Surya Deva', tier: 'EPIC RELIC', virtue: 180, gold: 350, quote: 'Morning sunbeams condense into radiant golden ornaments in your palms!' },
  { name: 'Mayur Pankh (Sacred Peacock Quill)', tier: 'RARE BLESSING', virtue: 120, gold: 220, quote: 'A dancing peacock in the temple grove gifts you a shimmering iridescent feather!' },
  { name: 'Holy Tulsi Garland of Vrindavan', tier: 'BLESSED PRASADAM', virtue: 80, gold: 150, quote: 'Fragrant basil blossoms fill your spirit with tranquil devotion.' },
];

const DEITIES = [
  { id: 'surya', name: 'Surya Deva (सूर्य देव)', domain: 'Solar Radiance & Valor', color: 0xffa500, boon: '+75% Martial Power & Solar Aura', virtueBonus: 200, fameBonus: 200, incomeMult: 1.2, pos: new THREE.Vector3(-42, 0, -68) },
  { id: 'lakshmi', name: 'Mata Lakshmi (माता लक्ष्मी)', domain: 'Abundance & Prosperity', color: 0xffd700, boon: '+100% Gold & 2x Empire Income', virtueBonus: 200, fameBonus: 250, incomeMult: 2.0, pos: new THREE.Vector3(-28, 0, -78) },
  { id: 'saraswati', name: 'Mata Saraswati (माता सरस्वती)', domain: 'Supreme Wisdom & Arts', color: 0xffffff, boon: '+50% Virtue Gain on All Deeds', virtueBonus: 300, fameBonus: 300, incomeMult: 1.25, pos: new THREE.Vector3(-14, 0, -84) },
  { id: 'hanuman', name: 'Sri Hanuman (श्री हनुमान)', domain: 'Strength, Speed & Devotion', color: 0xff5722, boon: 'Unlocks Super-Sprint & High Leap', virtueBonus: 250, fameBonus: 300, incomeMult: 1.15, pos: new THREE.Vector3(0, 0, -86) },
  { id: 'ganesha', name: 'Sri Ganesha (श्री गणेश)', domain: 'Remover of Obstacles', color: 0xf43f5e, boon: '+150% Enterprise Revenue', virtueBonus: 250, fameBonus: 350, incomeMult: 1.8, pos: new THREE.Vector3(14, 0, -84) },
  { id: 'shiva', name: 'Mahadeva Shiva (महादेव शिव)', domain: 'Transcendence & Stillness', color: 0x38bdf8, boon: 'Unlocks Garuda Flight & Cosmic Shield', virtueBonus: 400, fameBonus: 500, incomeMult: 1.4, pos: new THREE.Vector3(28, 0, -78) },
  { id: 'vishnu', name: 'Bhagavan Vishnu (भगवान विष्णु)', domain: 'Cosmic Preservation & Dharma', color: 0x2dd4bf, boon: 'Chakravarti Grace (+1000 Fame & 2.5x Income)', virtueBonus: 600, fameBonus: 1000, incomeMult: 2.5, pos: new THREE.Vector3(42, 0, -68) },
];

const PROPERTIES = [
  { id: 'ghat_land', name: 'Varanasi Sacred Riverfront Land', cat: 'Sacred Land', price: 500, reqFame: 50, goldPerMin: 120, virtuePerMin: 30, pos: new THREE.Vector3(-58, 0, 10) },
  { id: 'ayurveda_farm', name: 'Patanjali Herbal & Saffron Plantation', cat: 'Mega-Farm', price: 1200, reqFame: 100, goldPerMin: 280, virtuePerMin: 60, pos: new THREE.Vector3(-58, 0, 32) },
  { id: 'goshala', name: 'Surabhi Gir Cow Sanctuary (Goshala)', cat: 'Mega-Farm', price: 2500, reqFame: 200, goldPerMin: 550, virtuePerMin: 140, pos: new THREE.Vector3(-58, 0, -14) },
  { id: 'silk_guild', name: 'Banarasi Royal Silk & Brocade Guild', cat: 'Enterprise', price: 4500, reqFame: 350, goldPerMin: 980, virtuePerMin: 110, pos: new THREE.Vector3(-58, 0, -36) },
  { id: 'bronze_foundry', name: 'Chola Temple Bronze & Kalash Foundry', cat: 'Enterprise', price: 9000, reqFame: 600, goldPerMin: 2100, virtuePerMin: 220, pos: new THREE.Vector3(58, 0, 25) },
  { id: 'spice_fleet', name: 'Sagar Ratna Maritime Spice Fleet', cat: 'Enterprise', price: 18000, reqFame: 1000, goldPerMin: 4800, virtuePerMin: 450, pos: new THREE.Vector3(58, 0, -25) },
];

const LANDMARK_COORDS = {
  garden: { name: '🌿 Sacred Garden of Dharma (Quest 1)', pos: new THREE.Vector3(0, 0, 32) },
  mandir: { name: '🛕 Grand Golden Mandir (Central Temple)', pos: new THREE.Vector3(0, 0, -35) },
  arena: { name: '⚔️ Legends Testing Ground (Akhada)', pos: new THREE.Vector3(48, 0, -8) },
  ghats: { name: '🌊 Sacred River Ganga & Stone Ghats', pos: new THREE.Vector3(-75, 0, 0) },
  shrines: { name: '🔥 Circle of the 7 Deities', pos: new THREE.Vector3(0, 0, -75) },
  empire: { name: '🏛️ Royal Bazaar & Guild Estates', pos: new THREE.Vector3(-52, 0, -10) },
};

// ============================================================================
// 2. PLAYER STATE
// ============================================================================
const state = {
  virtue: 0,
  gold: 1500,
  fame: 100,
  gradeLevel: 1,
  seedIndex: 0,
  awakeningMeter: 20,
  isAwakened: false,
  isFlying: false,
  boons: {
    walk: false,
    sprint: false,
    jump: false,
    fly: false,
    teleport: false,
    cosmic: false,
  },
  blessedGods: {},
  ownedProps: {},
  questGarden: { till: 0, plant: 0, water: 0, harvest: 0, completed: false },
  questArena: { gada: 0, archery: 0, malla: 0, awaken: 0, completed: false },
  waypoint: LANDMARK_COORDS.garden,
};

// ============================================================================
// 3. THREE.JS AAA SCENE, SKY, WATER & BLOOM POST-PROCESSING
// ============================================================================
const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x1a1528, 0.0028);

const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.5, 1200);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.1;
container.appendChild(renderer.domElement);

// Unreal Bloom Post-Processing for Authentic Next-Gen Glow
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloomPass = new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  0.55, // strength
  0.45, // radius
  0.82  // threshold
);
composer.addPass(bloomPass);

// Atmospheric Golden-Hour Preetham Sky Shader
const sky = new Sky();
sky.scale.setScalar(4000);
scene.add(sky);
const skyUniforms = sky.material.uniforms;
skyUniforms['turbidity'].value = 8;
skyUniforms['rayleigh'].value = 2.5;
skyUniforms['mieCoefficient'].value = 0.005;
skyUniforms['mieDirectionalG'].value = 0.82;

const sunVec = new THREE.Vector3();
const phi = THREE.MathUtils.degToRad(88 - 14); // Golden sunset elevation
const theta = THREE.MathUtils.degToRad(195);
sunVec.setFromSphericalCoords(1, phi, theta);
skyUniforms['sunPosition'].value.copy(sunVec);

// Warm Directional Sunlight + Soft Hemisphere Ambient
const dirLight = new THREE.DirectionalLight(0xffdfa0, 3.2);
dirLight.position.copy(sunVec).multiplyScalar(180);
dirLight.castShadow = true;
dirLight.shadow.mapSize.set(2048, 2048);
dirLight.shadow.camera.near = 10;
dirLight.shadow.camera.far = 400;
const d = 110;
dirLight.shadow.camera.left = -d;
dirLight.shadow.camera.right = d;
dirLight.shadow.camera.top = d;
dirLight.shadow.camera.bottom = -d;
scene.add(dirLight);

const hemiLight = new THREE.HemisphereLight(0xffd6a5, 0x1e293b, 1.15);
scene.add(hemiLight);

// ============================================================================
// 4. PROCEDURAL PBR MATERIALS & SACRED ARCHITECTURE BUILDER
// ============================================================================
function makeGridTexture(bgHex, lineHex, repeat = 20) {
  const c = document.createElement('canvas');
  c.width = 256; c.height = 256;
  const ctx = c.getContext('2d');
  ctx.fillStyle = bgHex;
  ctx.fillRect(0, 0, 256, 256);
  ctx.strokeStyle = lineHex;
  ctx.lineWidth = 4;
  ctx.strokeRect(0, 0, 256, 256);
  ctx.beginPath();
  ctx.moveTo(128, 0); ctx.lineTo(128, 256);
  ctx.moveTo(0, 128); ctx.lineTo(256, 128);
  ctx.stroke();
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(repeat, repeat);
  return tex;
}

const marbleTex = makeGridTexture('#f3efe6', '#d8cebe', 28);
const sandstoneTex = makeGridTexture('#d9a773', '#b8834f', 16);
const grassTex = makeGridTexture('#2d5a36', '#244a2c', 60);

const matMarble = new THREE.MeshStandardMaterial({ map: marbleTex, roughness: 0.25, metalness: 0.08 });
const matSandstone = new THREE.MeshStandardMaterial({ map: sandstoneTex, roughness: 0.55, metalness: 0.05 });
const matGold = new THREE.MeshStandardMaterial({ color: 0xffcf40, roughness: 0.18, metalness: 0.88, emissive: 0x442800, emissiveIntensity: 0.35 });
const matGrass = new THREE.MeshStandardMaterial({ map: grassTex, roughness: 0.85 });
const matTerracotta = new THREE.MeshStandardMaterial({ color: 0xb85332, roughness: 0.75 });
const matDarkWood = new THREE.MeshStandardMaterial({ color: 0x5c3a21, roughness: 0.7 });

// Create Floating 3D Canvas Label Sprite for Buildings & Stations
function create3DBanner(text, subtext, hexColor = '#ffe066', scaleWidth = 10) {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 128;
  const ctx = canvas.getContext('2d');

  ctx.fillStyle = 'rgba(10, 14, 24, 0.86)';
  ctx.beginPath();
  ctx.roundRect(8, 8, 496, 112, 22);
  ctx.fill();
  ctx.lineWidth = 5;
  ctx.strokeStyle = hexColor;
  ctx.stroke();

  ctx.fillStyle = hexColor;
  ctx.font = 'bold 28px Cinzel, serif';
  ctx.textAlign = 'center';
  ctx.fillText(text, 256, 54);

  ctx.fillStyle = '#e2e8f0';
  ctx.font = '600 20px Plus Jakarta Sans, sans-serif';
  ctx.fillText(subtext, 256, 92);

  const tex = new THREE.CanvasTexture(canvas);
  const mat = new THREE.SpriteMaterial({ map: tex, transparent: true, depthTest: false });
  const sprite = new THREE.Sprite(mat);
  sprite.scale.set(scaleWidth, scaleWidth * 0.25, 1);
  sprite.renderOrder = 999;
  return sprite;
}

// Interactive Registry for [E] Proximity Checks
const interactiveObjects = [];

function buildSacredOpenWorld() {
  // 1. Continental Emerald Ground & Central Marble Mandala Plaza
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(900, 900), matGrass);
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  const centralPlaza = new THREE.Mesh(new THREE.CylinderGeometry(58, 60, 0.5, 64), matMarble);
  centralPlaza.position.set(0, 0.25, 0);
  centralPlaza.receiveShadow = true;
  scene.add(centralPlaza);

  // Golden Mandala Rings on Central Plaza
  const ringGeo = new THREE.RingGeometry(14, 15.2, 64);
  const ringMat = new THREE.MeshBasicMaterial({ color: 0xf5b942, side: THREE.DoubleSide });
  const ringMesh = new THREE.Mesh(ringGeo, ringMat);
  ringMesh.rotation.x = -Math.PI / 2;
  ringMesh.position.set(0, 0.52, 0);
  scene.add(ringMesh);

  // 2. Sacred River Ganga with Realistic Animated Shader Water & Ghats (West at X = -95)
  const waterGeo = new THREE.PlaneGeometry(55, 900);
  const waterNormal = makeGridTexture('#8080ff', '#7070ee', 40);
  const river = new Water(waterGeo, {
    textureWidth: 512,
    textureHeight: 512,
    waterNormals: waterNormal,
    sunDirection: sunVec.clone().normalize(),
    sunColor: 0xffe082,
    waterColor: 0x0284c7,
    distortionScale: 2.8,
    fog: true,
  });
  river.rotation.x = -Math.PI / 2;
  river.position.set(-102, 0.15, 0);
  scene.add(river);
  window.__riverWater = river;

  // Stone Stepped Varanasi Ghats along the River
  for (let step = 0; step < 5; step++) {
    const ghatStep = new THREE.Mesh(new THREE.BoxGeometry(3.2, (5 - step) * 0.45, 180), matSandstone);
    ghatStep.position.set(-66 - step * 2.8, ((5 - step) * 0.45) / 2, 0);
    ghatStep.receiveShadow = true;
    ghatStep.castShadow = true;
    scene.add(ghatStep);
  }
  const ghatBanner = create3DBanner('🌊 SACRED RIVER GANGA GHATS', 'Press [E] to Perform Seva & Offer Deepdan Lamps', '#3bc9db', 13);
  ghatBanner.position.set(-72, 7.5, 0);
  scene.add(ghatBanner);

  interactiveObjects.push({
    type: 'seva_ghat',
    pos: new THREE.Vector3(-70, 0, 0),
    radius: 9,
    getPrompt: () => ({ action: '🪔 Offer Sacred Ghee Lamp & Perform River Seva (+50 Virtue)', object: 'Varanasi Ganga Ghat' }),
    onInteract: () => {
      awardVirtue(50, 'Seva (River Purification)');
      spawnFloatingEffect(new THREE.Vector3(-70, 2, 0), 0x3bc9db);
    }
  });

  // 3. THE GRAND GOLDEN MANDIR (Central Nagara Shikhara Temple at Z = -35)
  const templeGroup = new THREE.Group();
  templeGroup.position.set(0, 0, -35);

  // Raised Plinth (Jagati)
  const plinth = new THREE.Mesh(new THREE.BoxGeometry(36, 3, 38), matSandstone);
  plinth.position.y = 1.5;
  plinth.castShadow = true;
  plinth.receiveShadow = true;
  templeGroup.add(plinth);

  // Carved Stone Steps up to Mandir
  for (let s = 0; s < 6; s++) {
    const stepMesh = new THREE.Mesh(new THREE.BoxGeometry(12, 0.5, 1.2), matMarble);
    stepMesh.position.set(0, 0.25 + s * 0.5, 19 + (5 - s) * 0.9);
    templeGroup.add(stepMesh);
  }

  // 16 Ornate Mandapa Pillars
  for (let x = -13; x <= 13; x += 8.6) {
    for (let z = -13; z <= 13; z += 8.6) {
      if (Math.abs(x) < 5 && Math.abs(z) < 5) continue;
      const col = new THREE.Mesh(new THREE.CylinderGeometry(0.85, 1.1, 11, 16), matSandstone);
      col.position.set(x, 8.5, z);
      col.castShadow = true;
      templeGroup.add(col);
    }
  }

  // Towering 9-Tier Nagara Shikhara Spire
  for (let t = 0; t < 9; t++) {
    const w = 24 - t * 2.2;
    const tier = new THREE.Mesh(
      new THREE.BoxGeometry(w, 3.2, w),
      t >= 7 ? matGold : matSandstone
    );
    tier.position.set(0, 15.5 + t * 2.9, -2);
    tier.castShadow = true;
    templeGroup.add(tier);
  }

  // Glowing Golden Kalash Pinnacle & Sudarshana Chakra
  const kalash = new THREE.Mesh(new THREE.SphereGeometry(2.6, 32, 32), matGold);
  kalash.position.set(0, 43, -2);
  templeGroup.add(kalash);

  const spireCone = new THREE.Mesh(new THREE.ConeGeometry(1.4, 6, 24), matGold);
  spireCone.position.set(0, 47, -2);
  templeGroup.add(spireCone);

  // Inner Sanctum Glowing Lingam / Lotus Altar
  const altar = new THREE.Mesh(new THREE.CylinderGeometry(2.2, 2.8, 2.2, 32), matGold);
  altar.position.set(0, 4.1, -2);
  templeGroup.add(altar);

  const templeLight = new THREE.PointLight(0xffcf40, 5, 35);
  templeLight.position.set(0, 8, -2);
  templeGroup.add(templeLight);

  const mandirBanner = create3DBanner('🛕 GRAND DHARMA MANDIR', 'Press [E] Inside Sanctum for Deep Dhyana Meditation', '#ffe066', 14);
  mandirBanner.position.set(0, 19, 18);
  templeGroup.add(mandirBanner);

  scene.add(templeGroup);

  interactiveObjects.push({
    type: 'mandir_sanctum',
    pos: new THREE.Vector3(0, 3, -35),
    radius: 9,
    getPrompt: () => ({ action: '🧘 Meditate in Sanctum Sanctorum (+60 Virtue)', object: 'Grand Dharma Mandir' }),
    onInteract: () => {
      awardVirtue(60, 'Dhyana (Sanctum Meditation)');
      spawnFloatingEffect(new THREE.Vector3(0, 5, -35), 0xffd700);
    }
  });

  // 4. QUEST 1: SACRED BOTANICAL GARDEN OF DHARMA (Z = +32)
  buildSacredGardenDistrict();

  // 5. QUEST 2: VEER BHUMI LEGENDS TESTING GROUND ARENA (X = +48, Z = -8)
  buildLegendsArenaDistrict();

  // 6. THE 7 GODS CELESTIAL SHRINES ARC (North Semi-Circle behind Mandir)
  buildSevenGodsShrines();

  // 7. ROYAL BAZAAR & TYCOON REAL ESTATE BUILDINGS
  buildEmpireProperties();

  // 8. HIMALAYAN SNOW PEAKS HORIZON RING
  buildHimalayanPeaks();
}

// ============================================================================
// 4A. SACRED GARDEN OF DHARMA BUILDER (6 INTERACTIVE PLOTS)
// ============================================================================
const gardenPlots = [];

function buildSacredGardenDistrict() {
  const center = new THREE.Vector3(0, 0, 32);
  const terrace = new THREE.Mesh(new THREE.BoxGeometry(34, 0.7, 26), matMarble);
  terrace.position.copy(center).setY(0.35);
  terrace.receiveShadow = true;
  scene.add(terrace);

  const banner = create3DBanner('🌿 QUEST 1: SACRED GARDEN OF DHARMA', 'Walk to any Soil Bed & Press [E] to Till ➔ Sow ➔ Water ➔ Harvest!', '#38d996', 14);
  banner.position.set(0, 9.5, 32);
  scene.add(banner);

  // 4 Sacred Flowering Banyan Trees at Corners
  const treeOffsets = [[-15, -11], [15, -11], [-15, 11], [15, 11]];
  treeOffsets.forEach(([ox, oz]) => {
    const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 1.3, 7, 12), matDarkWood);
    trunk.position.set(center.x + ox, 3.5, center.z + oz);
    trunk.castShadow = true;
    scene.add(trunk);

    const canopy = new THREE.Mesh(
      new THREE.DodecahedronGeometry(4.8, 1),
      new THREE.MeshStandardMaterial({ color: 0x228b22, roughness: 0.65 })
    );
    canopy.position.set(center.x + ox, 8.2, center.z + oz);
    canopy.castShadow = true;
    scene.add(canopy);
  });

  // 6 Interactive Mandala Soil Plots (3x2 grid)
  let idx = 0;
  for (let row = 0; row < 2; row++) {
    for (let col = 0; col < 3; col++) {
      idx++;
      const px = center.x + (col - 1) * 9;
      const pz = center.z + (row - 0.5) * 9;

      const frame = new THREE.Mesh(new THREE.BoxGeometry(6.2, 0.9, 6.2), matGold);
      frame.position.set(px, 0.75, pz);
      scene.add(frame);

      const soilMat = new THREE.MeshStandardMaterial({ color: 0x3b6e38, roughness: 0.9 });
      const soil = new THREE.Mesh(new THREE.BoxGeometry(5.6, 0.95, 5.6), soilMat);
      soil.position.set(px, 0.8, pz);
      soil.receiveShadow = true;
      scene.add(soil);

      const plantGroup = new THREE.Group();
      plantGroup.position.set(px, 1.3, pz);
      scene.add(plantGroup);

      const plotSign = create3DBanner(`Plot #${idx}: Untilled`, 'Press [E] to Till Soil', '#38d996', 5.5);
      plotSign.position.set(px, 4.2, pz);
      scene.add(plotSign);

      const plotObj = {
        id: idx,
        pos: new THREE.Vector3(px, 1, pz),
        soilMesh: soil,
        soilMat,
        plantGroup,
        signSprite: plotSign,
        stage: 'untilled', // untilled -> tilled -> planted -> watered -> mature
        seed: null,
        growth: 0,
      };
      gardenPlots.push(plotObj);

      interactiveObjects.push({
        type: 'garden_plot',
        pos: plotObj.pos,
        radius: 5.2,
        getPrompt: () => getPlotPrompt(plotObj),
        onInteract: () => interactWithPlot(plotObj),
      });
    }
  }
}

function updatePlotSign(plot, title, sub, color) {
  scene.remove(plot.signSprite);
  plot.signSprite = create3DBanner(title, sub, color, 5.5);
  plot.signSprite.position.set(plot.pos.x, 4.2, plot.pos.z);
  scene.add(plot.signSprite);
}

function getPlotPrompt(plot) {
  const curSeed = SEEDS[state.seedIndex];
  if (plot.stage === 'untilled') return { action: '🌱 Step 1: Till Sacred Soil Bed', object: `Mandala Plot #${plot.id}` };
  if (plot.stage === 'tilled') return { action: `🌿 Step 2: Sow ${curSeed.name}`, object: `Mandala Plot #${plot.id}` };
  if (plot.stage === 'planted') return { action: '💧 Step 3: Water with Holy Ganga Jal', object: `${plot.seed.name}` };
  if (plot.stage === 'watered') return { action: `⏳ Growing (${Math.round(plot.growth * 100)}%)... Click to Boost!`, object: `${plot.seed.name}` };
  return { action: `✨ Step 4: Harvest ${plot.seed.name} & Unlock Boon!`, object: `Mature Sacred Blossom` };
}

function rebuildPlantMesh(plot) {
  while (plot.plantGroup.children.length) {
    plot.plantGroup.remove(plot.plantGroup.children[0]);
  }
  if (!plot.seed) return;

  const h = Math.max(0.4, plot.growth * 2.6);
  const stem = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.18, h, 10),
    new THREE.MeshStandardMaterial({ color: plot.seed.stem, roughness: 0.5 })
  );
  stem.position.y = h / 2;
  plot.plantGroup.add(stem);

  // Leaves
  if (plot.growth > 0.3) {
    for (let i = 0; i < 4; i++) {
      const leaf = new THREE.Mesh(
        new THREE.SphereGeometry(0.35, 10, 10),
        new THREE.MeshStandardMaterial({ color: plot.seed.stem })
      );
      leaf.scale.set(1.6, 0.3, 0.8);
      const ang = (i * Math.PI) / 2;
      leaf.position.set(Math.cos(ang) * 0.35, h * 0.55, Math.sin(ang) * 0.35);
      plot.plantGroup.add(leaf);
    }
  }

  // Radiant Neon Blossom when mature
  if (plot.stage === 'mature') {
    const flowerMat = new THREE.MeshStandardMaterial({
      color: plot.seed.color,
      emissive: plot.seed.color,
      emissiveIntensity: 1.2,
      roughness: 0.2,
    });
    const centerOrb = new THREE.Mesh(new THREE.SphereGeometry(0.55, 20, 20), flowerMat);
    centerOrb.position.y = h + 0.3;
    plot.plantGroup.add(centerOrb);

    for (let p = 0; p < 8; p++) {
      const ang = (p * Math.PI) / 4;
      const petal = new THREE.Mesh(new THREE.SphereGeometry(0.38, 12, 12), flowerMat);
      petal.scale.set(1.4, 0.4, 0.8);
      petal.position.set(Math.cos(ang) * 0.65, h + 0.25, Math.sin(ang) * 0.65);
      petal.rotation.y = -ang;
      plot.plantGroup.add(petal);
    }
  }
}

function interactWithPlot(plot) {
  if (plot.stage === 'untilled') {
    plot.stage = 'tilled';
    plot.soilMat.color.setHex(0x6e472b);
    state.questGarden.till = Math.min(3, state.questGarden.till + 1);
    awardVirtue(15, 'Seva (Tilling Sacred Earth)');
    updatePlotSign(plot, `Plot #${plot.id}: Tilled`, 'Press [E] to Sow Seed', '#ffe066');
  } else if (plot.stage === 'tilled') {
    const chosen = SEEDS[state.seedIndex];
    plot.seed = chosen;
    plot.stage = 'planted';
    plot.growth = 0.25;
    state.questGarden.plant = Math.min(3, state.questGarden.plant + 1);
    rebuildPlantMesh(plot);
    awardVirtue(20, `Sowed ${chosen.name}`);
    updatePlotSign(plot, chosen.name, 'Press [E] to Water with Ganga Jal', '#3bc9db');
  } else if (plot.stage === 'planted') {
    plot.stage = 'watered';
    plot.soilMat.color.setHex(0x3a2312);
    state.questGarden.water = Math.min(3, state.questGarden.water + 1);
    awardVirtue(20, 'Ahimsa (Nurturing Sapling)');
    spawnFloatingEffect(plot.pos, 0x3bc9db);
    updatePlotSign(plot, `${plot.seed.name}`, 'Growing Fast...', '#38d996');
  } else if (plot.stage === 'watered') {
    plot.growth = Math.min(1, plot.growth + 0.45);
    rebuildPlantMesh(plot);
    if (plot.growth >= 1) {
      plot.stage = 'mature';
      rebuildPlantMesh(plot);
      updatePlotSign(plot, `✨ ${plot.seed.name} BLOOMED!`, 'Press [E] to Harvest & Unlock Siddhi!', '#ffe066');
    }
  } else if (plot.stage === 'mature') {
    const harvestedSeed = plot.seed;
    state.gold += harvestedSeed.gold;
    state.questGarden.harvest = Math.min(3, state.questGarden.harvest + 1);
    unlockMovementBoon(harvestedSeed);
    awardVirtue(harvestedSeed.virtue, `Harvested ${harvestedSeed.name}`);
    spawnFloatingEffect(plot.pos, harvestedSeed.color);

    // Cycle seed automatically so player experiences new flowers effortlessly
    state.seedIndex = (state.seedIndex + 1) % SEEDS.length;
    document.getElementById('current-seed-label').textContent = SEEDS[state.seedIndex].name;

    // Reset plot to tilled for easy re-planting
    plot.stage = 'tilled';
    plot.seed = null;
    plot.growth = 0;
    plot.soilMat.color.setHex(0x6e472b);
    rebuildPlantMesh(plot);
    updatePlotSign(plot, `Plot #${plot.id}: Ready`, 'Press [E] to Sow Next Seed', '#ffe066');
    checkQuestCompletions();
  }
  updateHUD();
}

// ============================================================================
// 4B. QUEST 2: VEER BHUMI LEGENDS TESTING GROUND ARENA (X = +48, Z = -8)
// ============================================================================
function buildLegendsArenaDistrict() {
  const center = new THREE.Vector3(48, 0, -8);

  // Circular Terracotta Akhada Wrestling & Martial Ring
  const arenaRing = new THREE.Mesh(new THREE.CylinderGeometry(22, 24, 0.8, 48), matTerracotta);
  arenaRing.position.copy(center).setY(0.4);
  arenaRing.receiveShadow = true;
  scene.add(arenaRing);

  const borderTorus = new THREE.Mesh(new THREE.TorusGeometry(22.5, 0.6, 16, 64), matGold);
  borderTorus.rotation.x = Math.PI / 2;
  borderTorus.position.copy(center).setY(0.85);
  scene.add(borderTorus);

  const arenaBanner = create3DBanner('⚔️ QUEST 2: VEER BHUMI (TESTING GROUNDS)', 'Press [E] at 4 Martial Stations & Press [1, 2, Q, G] for Combos!', '#ff7847', 15);
  arenaBanner.position.set(center.x, 11, center.z);
  scene.add(arenaBanner);

  // 8 Flaming Perimeter Pillars
  for (let i = 0; i < 8; i++) {
    const ang = (i * Math.PI) / 4;
    const px = center.x + Math.cos(ang) * 21;
    const pz = center.z + Math.sin(ang) * 21;
    const pillar = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 1.1, 8, 12), matSandstone);
    pillar.position.set(px, 4, pz);
    pillar.castShadow = true;
    scene.add(pillar);

    const flame = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.9, 1),
      new THREE.MeshStandardMaterial({ color: 0xff5500, emissive: 0xff4400, emissiveIntensity: 2.0 })
    );
    flame.position.set(px, 8.8, pz);
    scene.add(flame);
  }

  // 4 Martial Training Stations inside the Arena
  const stations = [
    { id: 'gada', name: 'Hanuman Gada Mace', sub: 'Strength Training [E]', offset: [-9, -9], color: 0xf59e0b },
    { id: 'archery', name: 'Dhanurveda Archery Target', sub: 'Pinpoint Focus [E]', offset: [9, -9], color: 0x3bc9db },
    { id: 'malla', name: 'Malla-Yuddha Clay Golem', sub: 'Ahimsa Sparring [E]', offset: [-9, 9], color: 0xef4444 },
    { id: 'kalari', name: 'Kalaripayattu Agility Pillar', sub: 'Meippayattu Reflex [E]', offset: [9, 9], color: 0x38d996 },
  ];

  stations.forEach((st) => {
    const spos = new THREE.Vector3(center.x + st.offset[0], 0.8, center.z + st.offset[1]);
    const ped = new THREE.Mesh(new THREE.CylinderGeometry(2.4, 2.8, 0.6, 24), matMarble);
    ped.position.copy(spos);
    scene.add(ped);

    // Distinct 3D Martial Prop
    const dummy = new THREE.Mesh(
      st.id === 'gada' ? new THREE.SphereGeometry(1.4, 16, 16) : new THREE.CylinderGeometry(0.8, 0.9, 3.6, 16),
      new THREE.MeshStandardMaterial({ color: st.color, emissive: st.color, emissiveIntensity: 0.35, metalness: 0.5, roughness: 0.3 })
    );
    dummy.position.copy(spos).add(new THREE.Vector3(0, 2.2, 0));
    dummy.castShadow = true;
    scene.add(dummy);

    const sign = create3DBanner(st.name, st.sub, '#ff7847', 6.5);
    sign.position.copy(spos).add(new THREE.Vector3(0, 5.2, 0));
    scene.add(sign);

    interactiveObjects.push({
      type: 'arena_station',
      pos: spos,
      radius: 5.0,
      getPrompt: () => ({ action: `⚔️ Train ${st.name} (+25% Awakening & +35 Virtue)`, object: 'Veer Bhumi Martial Station' }),
      onInteract: () => {
        if (st.id === 'gada') state.questArena.gada = Math.min(5, state.questArena.gada + 1);
        else if (st.id === 'archery') state.questArena.archery = Math.min(5, state.questArena.archery + 1);
        else state.questArena.malla = Math.min(5, state.questArena.malla + 1);

        state.awakeningMeter = Math.min(100, state.awakeningMeter + 25);
        awardVirtue(35, `Trained ${st.name}`);
        spawnCombatShockwave(spos, st.color);
        checkQuestCompletions();
        updateHUD();
      }
    });
  });
}

// ============================================================================
// 4C. THE 7 DEITIES SHRINES & EMPIRE ESTATES
// ============================================================================
function buildSevenGodsShrines() {
  DEITIES.forEach((deity) => {
    const g = new THREE.Group();
    g.position.copy(deity.pos);

    const base = new THREE.Mesh(new THREE.CylinderGeometry(3.8, 4.4, 1.2, 24), matMarble);
    base.position.y = 0.6;
    g.add(base);

    const idol = new THREE.Mesh(
      new THREE.OctahedronGeometry(2.0, 2),
      new THREE.MeshStandardMaterial({ color: deity.color, emissive: deity.color, emissiveIntensity: 1.1, roughness: 0.15, metalness: 0.8 })
    );
    idol.position.y = 3.8;
    g.add(idol);

    const ring = new THREE.Mesh(new THREE.TorusGeometry(2.8, 0.14, 16, 48), matGold);
    ring.position.y = 3.8;
    g.add(ring);

    const sign = create3DBanner(`🔥 ${deity.name}`, `Press [E] to Receive Boon: ${deity.boon}`, '#ffe066', 7.5);
    sign.position.y = 7.8;
    g.add(sign);

    scene.add(g);

    interactiveObjects.push({
      type: 'deity_shrine',
      pos: deity.pos,
      radius: 6.0,
      getPrompt: () => ({
        action: state.blessedGods[deity.id] ? `🙏 Commune with ${deity.name}` : `✨ Claim Divine Boon of ${deity.name}`,
        object: deity.domain
      }),
      onInteract: () => claimDeityBoon(deity),
    });
  });
}

function buildEmpireProperties() {
  PROPERTIES.forEach((prop) => {
    const g = new THREE.Group();
    g.position.copy(prop.pos);

    const bldg = new THREE.Mesh(new THREE.BoxGeometry(10, 7, 10), matSandstone);
    bldg.position.y = 3.5;
    bldg.castShadow = true;
    bldg.receiveShadow = true;
    g.add(bldg);

    const roof = new THREE.Mesh(new THREE.ConeGeometry(8.5, 4, 4), matGold);
    roof.position.y = 9;
    roof.rotation.y = Math.PI / 4;
    g.add(roof);

    const sign = create3DBanner(`🏛️ ${prop.name}`, `${prop.price} Gold • +${prop.goldPerMin} Gold/min [Press E]`, '#a855f7', 8.0);
    sign.position.y = 12.5;
    g.add(sign);

    scene.add(g);

    interactiveObjects.push({
      type: 'property',
      pos: prop.pos,
      radius: 8.0,
      getPrompt: () => ({
        action: state.ownedProps[prop.id] ? `✓ Owned Estate (+${prop.goldPerMin} Gold/m)` : `🏰 Acquire ${prop.name} (${prop.price} Gold)`,
        object: prop.cat
      }),
      onInteract: () => buyProperty(prop),
    });
  });
}

function buildHimalayanPeaks() {
  const mountainMat = new THREE.MeshStandardMaterial({ color: 0x334155, roughness: 0.85 });
  const snowMat = new THREE.MeshStandardMaterial({ color: 0xf8fafc, roughness: 0.35, emissive: 0x1e293b, emissiveIntensity: 0.2 });

  for (let i = 0; i < 18; i++) {
    const ang = (i / 18) * Math.PI * 2;
    const dist = 210 + (i % 3) * 35;
    const h = 75 + (i % 4) * 28;
    const r = 45 + (i % 3) * 12;

    const peak = new THREE.Mesh(new THREE.ConeGeometry(r, h, 7), mountainMat);
    peak.position.set(Math.cos(ang) * dist, h / 2 - 2, Math.sin(ang) * dist);
    scene.add(peak);

    const cap = new THREE.Mesh(new THREE.ConeGeometry(r * 0.46, h * 0.45, 7), snowMat);
    cap.position.set(Math.cos(ang) * dist, h * 0.78 - 2, Math.sin(ang) * dist);
    scene.add(cap);
  }
}

buildSacredOpenWorld();

// ============================================================================
// 5. ANIMATED 3D CHARACTER + SPIRITUAL HALO + GOLDEN PATH GUIDANCE BEAM
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, 0, 44);
scene.add(playerGroup);

// Spiritual Floating Neon Halo Ring above Player
const haloGeo = new THREE.TorusGeometry(0.85, 0.08, 16, 48);
const haloMat = new THREE.MeshStandardMaterial({ color: 0xdddddd, emissive: 0xdddddd, emissiveIntensity: 1.8 });
const playerHalo = new THREE.Mesh(haloGeo, haloMat);
playerHalo.rotation.x = Math.PI / 2;
playerHalo.position.y = 3.1;
playerGroup.add(playerHalo);

// Load Animated 3D Human Character (Three.js Soldier GLB with Idle/Walk/Run skeletal animations)
let mixer = null;
const animActions = {};
let activeAction = null;

const fallbackAvatar = new THREE.Group();
const robeMesh = new THREE.Mesh(
  new THREE.CapsuleGeometry(0.45, 1.1, 16, 16),
  new THREE.MeshStandardMaterial({ color: 0xff8c00, roughness: 0.35 })
);
robeMesh.position.y = 1.05;
robeMesh.castShadow = true;
fallbackAvatar.add(robeMesh);
const headMesh = new THREE.Mesh(
  new THREE.SphereGeometry(0.38, 24, 24),
  new THREE.MeshStandardMaterial({ color: 0xf1c27d, roughness: 0.4 })
);
headMesh.position.y = 2.05;
fallbackAvatar.add(headMesh);
playerGroup.add(fallbackAvatar);

const loader = new GLTFLoader();
loader.load(
  'https://threejs.org/examples/models/gltf/Soldier.glb',
  (gltf) => {
    playerGroup.remove(fallbackAvatar);
    const model = gltf.scene;
    model.scale.set(1.35, 1.35, 1.35);
    model.traverse((obj) => {
      if (obj.isMesh) {
        obj.castShadow = true;
        obj.receiveShadow = true;
      }
    });
    playerGroup.add(model);

    mixer = new THREE.AnimationMixer(model);
    gltf.animations.forEach((clip) => {
      animActions[clip.name] = mixer.clipAction(clip);
    });
    if (animActions['Idle']) {
      activeAction = animActions['Idle'];
      activeAction.play();
    }
  },
  undefined,
  () => {
    // Keeps sleek saffron-robed 3D avatar if offline
  }
);

function fadeToAction(name) {
  if (!mixer || !animActions[name] || activeAction === animActions[name]) return;
  const prev = activeAction;
  activeAction = animActions[name];
  if (prev) prev.fadeOut(0.2);
  activeAction.reset().fadeIn(0.2).play();
}

// Golden Path 3D Ribbon & Sky Beacon connecting Player to Active Waypoint
const waypointBeacon = new THREE.Mesh(
  new THREE.CylinderGeometry(0.6, 0.6, 65, 16),
  new THREE.MeshBasicMaterial({ color: 0xffe066, transparent: true, opacity: 0.35 })
);
scene.add(waypointBeacon);

const pathPoints = [new THREE.Vector3(), new THREE.Vector3()];
const pathGeo = new THREE.BufferGeometry().setFromPoints(pathPoints);
const pathLine = new THREE.Line(
  pathGeo,
  new THREE.LineBasicMaterial({ color: 0xffe066, linewidth: 3 })
);
scene.add(pathLine);

// ============================================================================
// 6. PLAYER MOVEMENT, CAMERA ORBIT, FLIGHT & TELEPORTATION ENGINE
// ============================================================================
const keys = {};
let camYaw = 0;
let camPitch = 0.38;
let camDist = 14;
let isDragging = false;
let velY = 0;

window.addEventListener('keydown', (e) => {
  keys[e.code] = true;
  if (e.code === 'KeyE') triggerNearestInteraction();
  if (e.code === 'KeyF') toggleFlightMode();
  if (e.code === 'KeyT') triggerAstralTeleport();
  if (e.code === 'KeyM') toggleEmpireModal();
  if (e.code === 'Digit1') performMartialMove('Vajra Ground Pound', 0x3bc9db, 25);
  if (e.code === 'Digit2') performMartialMove('Silambam Staff Whirlwind', 0xffe066, 25);
  if (e.code === 'KeyQ') performMartialDash();
  if (e.code === 'KeyG') triggerRudraAwakening();
});

window.addEventListener('keyup', (e) => {
  keys[e.code] = false;
});

renderer.domElement.addEventListener('mousedown', () => { isDragging = true; });
window.addEventListener('mouseup', () => { isDragging = false; });
window.addEventListener('mousemove', (e) => {
  if (!isDragging) return;
  camYaw -= e.movementX * 0.006;
  camPitch = Math.max(0.08, Math.min(1.25, camPitch + e.movementY * 0.005));
});
window.addEventListener('wheel', (e) => {
  camDist = Math.max(6, Math.min(35, camDist + e.deltaY * 0.01));
});

// ============================================================================
// 7. CORE GAMEPLAY FUNCTIONS (VIRTUE, GRADES, BOONS, COMBAT, EMPIRE)
// ============================================================================
function awardVirtue(baseAmount, reasonText) {
  const curGrade = GRADES[state.gradeLevel - 1];
  const saraswatiMult = state.blessedGods['saraswati'] ? 1.5 : 1.0;
  const gained = Math.round(baseAmount * curGrade.mult * saraswatiMult);
  state.virtue += gained;

  // Check Grade Promotion (7 Levels)
  for (let i = GRADES.length - 1; i >= 0; i--) {
    if (state.virtue >= GRADES[i].req && GRADES[i].level > state.gradeLevel) {
      state.gradeLevel = GRADES[i].level;
      haloMat.color.setHex(GRADES[i].haloColor);
      haloMat.emissive.setHex(GRADES[i].haloColor);
      showSurpriseGift({
        name: `Promoted to Grade ${GRADES[i].roman}: ${GRADES[i].name}`,
        tier: 'SPIRITUAL ASCENSION',
        virtue: 100,
        gold: 300,
        quote: `Your inner aura shines brighter! Multiplier increased to ${GRADES[i].mult}x!`,
      });
      break;
    }
  }

  // 22% chance for a Surprise Celestial Gift on any virtuous deed
  if (Math.random() < 0.22) {
    const gift = SURPRISE_GIFTS[Math.floor(Math.random() * SURPRISE_GIFTS.length)];
    state.virtue += gift.virtue;
    state.gold += gift.gold;
    showSurpriseGift(gift);
  }

  document.getElementById('interaction-hint').textContent = `✨ +${gained} Virtue (${reasonText})`;
  updateHUD();
}

function unlockMovementBoon(seed) {
  state.boons[seed.boonId] = true;
  if (seed.boonId === 'cosmic') {
    state.boons.walk = state.boons.sprint = state.boons.jump = state.boons.fly = state.boons.teleport = true;
  }
  renderBoonsList();
}

function renderBoonsList() {
  const containerEl = document.getElementById('active-boons-list');
  const activeItems = SEEDS.filter((s) => state.boons[s.boonId]);
  if (activeItems.length === 0 && Object.keys(state.blessedGods).length === 0) return;

  containerEl.innerHTML = '';
  activeItems.forEach((s) => {
    const div = document.createElement('div');
    div.className = 'boon-pill';
    div.innerHTML = `<strong>🌸 ${s.boonName}</strong><span>${s.boonDesc}</span>`;
    containerEl.appendChild(div);
  });

  DEITIES.forEach((d) => {
    if (state.blessedGods[d.id]) {
      const div = document.createElement('div');
      div.className = 'boon-pill';
      div.innerHTML = `<strong>🔥 Boon of ${d.name}</strong><span>${d.boon}</span>`;
      containerEl.appendChild(div);
    }
  });
}

function toggleFlightMode() {
  if (!state.boons.fly && !state.blessedGods['shiva']) {
    // Allow instant trial of Garuda Flight so players never feel locked out!
    state.boons.fly = true;
    renderBoonsList();
  }
  state.isFlying = !state.isFlying;
  velY = 0;
  if (state.isFlying) {
    playerGroup.position.y = Math.max(playerGroup.position.y + 4, 8);
    spawnFloatingEffect(playerGroup.position, 0x3bc9db);
  }
}

function triggerAstralTeleport() {
  state.boons.teleport = true;
  renderBoonsList();
  const forward = new THREE.Vector3(-Math.sin(camYaw), 0, -Math.cos(camYaw)).normalize();
  playerGroup.position.addScaledVector(forward, 22);
  spawnCombatShockwave(playerGroup.position, 0x00ffcc);
  awardVirtue(15, 'Akash Gamana (Astral Blink)');
}

function performMartialMove(moveName, hexColor, virtueGain) {
  state.awakeningMeter = Math.min(100, state.awakeningMeter + 15);
  spawnCombatShockwave(playerGroup.position, hexColor);
  awardVirtue(virtueGain, moveName);
}

function performMartialDash() {
  const forward = new THREE.Vector3(-Math.sin(camYaw), 0, -Math.cos(camYaw)).normalize();
  playerGroup.position.addScaledVector(forward, 12);
  spawnCombatShockwave(playerGroup.position, 0xff7847);
  awardVirtue(15, 'Agni Dash');
}

function triggerRudraAwakening() {
  state.awakeningMeter = 0;
  state.isAwakened = true;
  state.questArena.awaken = 1;
  state.boons.sprint = true;
  state.boons.jump = true;
  renderBoonsList();
  spawnCombatShockwave(playerGroup.position, 0xff2200);
  awardVirtue(120, 'RUDRA TEJAS AWAKENING!');
  checkQuestCompletions();
  updateHUD();
}

function claimDeityBoon(deity) {
  if (!state.blessedGods[deity.id]) {
    state.blessedGods[deity.id] = true;
    state.fame += deity.fameBonus;
    if (deity.id === 'hanuman') { state.boons.sprint = true; state.boons.jump = true; }
    if (deity.id === 'shiva') { state.boons.fly = true; }
    renderBoonsList();
    showSurpriseGift({
      name: `Divine Boon of ${deity.name}`,
      tier: 'DEITY BLESSING (वरदान)',
      virtue: deity.virtueBonus,
      gold: 400,
      quote: deity.boon,
    });
    awardVirtue(deity.virtueBonus, `Blessed by ${deity.name}`);
  } else {
    awardVirtue(40, `Prayer to ${deity.name}`);
  }
  renderEmpireModalLists();
}

function buyProperty(prop) {
  if (state.ownedProps[prop.id]) return;
  if (state.fame < prop.reqFame) {
    alert(`Requires ${prop.reqFame} Fame! Commune with the 7 Gods or complete Quests to raise Fame.`);
    return;
  }
  if (state.gold < prop.price) {
    alert(`Requires ${prop.price} Gold! Harvest sacred flowers or claim gifts to earn Gold.`);
    return;
  }
  state.gold -= prop.price;
  state.ownedProps[prop.id] = true;
  state.fame += Math.round(prop.price / 8);
  awardVirtue(100, `Established ${prop.name}`);
  spawnFloatingEffect(prop.pos, 0xffd700);
  renderEmpireModalLists();
  updateHUD();
}

function checkQuestCompletions() {
  const qg = state.questGarden;
  if (!qg.completed && qg.till >= 3 && qg.plant >= 3 && qg.water >= 3 && qg.harvest >= 3) {
    qg.completed = true;
    claimDeityBoon(DEITIES[1]); // Mata Lakshmi auto-blesses upon completing Garden Quest!
  }
  const qa = state.questArena;
  if (!qa.completed && qa.gada >= 5 && qa.archery >= 5 && qa.malla >= 5 && qa.awaken >= 1) {
    qa.completed = true;
    claimDeityBoon(DEITIES[3]); // Sri Hanuman auto-blesses upon completing Arena Quest!
  }
}

// ============================================================================
// 8. VISUAL EFFECTS (SHOCKWAVES & FLOATING PARTICLES)
// ============================================================================
const activeEffects = [];

function spawnCombatShockwave(pos, colorHex) {
  const mesh = new THREE.Mesh(
    new THREE.RingGeometry(0.5, 1.4, 32),
    new THREE.MeshBasicMaterial({ color: colorHex, side: THREE.DoubleSide, transparent: true, opacity: 0.9 })
  );
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.copy(pos).setY(0.6);
  scene.add(mesh);
  activeEffects.push({ mesh, scaleSpeed: 18, fadeSpeed: 1.6 });
}

function spawnFloatingEffect(pos, colorHex) {
  const mesh = new THREE.Mesh(
    new THREE.TorusGeometry(1.2, 0.15, 12, 32),
    new THREE.MeshBasicMaterial({ color: colorHex, transparent: true, opacity: 0.9 })
  );
  mesh.rotation.x = Math.PI / 2;
  mesh.position.copy(pos).setY(1.0);
  scene.add(mesh);
  activeEffects.push({ mesh, scaleSpeed: 5, riseSpeed: 3.5, fadeSpeed: 1.2 });
}

// ============================================================================
// 9. UI BINDINGS & HUD UPDATES
// ============================================================================
function showSurpriseGift(gift) {
  document.getElementById('gift-tier').textContent = `[${gift.tier}]`;
  document.getElementById('gift-name').textContent = gift.name;
  document.getElementById('gift-quote').textContent = `"${gift.quote}"`;
  document.getElementById('gift-reward').textContent = `+${gift.virtue} Virtue (पुण्य) • +${gift.gold} Gold`;
  document.getElementById('gift-popup').classList.remove('hidden');
}

document.getElementById('gift-claim-btn').addEventListener('click', () => {
  document.getElementById('gift-popup').classList.add('hidden');
});

function updateHUD() {
  const curGrade = GRADES[state.gradeLevel - 1];
  const nextGrade = GRADES[state.gradeLevel] || curGrade;

  document.getElementById('grade-badge').textContent = `GRADE ${curGrade.roman}`;
  document.getElementById('grade-title').textContent = curGrade.name;
  document.getElementById('grade-subtitle').textContent = `${curGrade.title} (${curGrade.mult}x Virtue Mult)`;
  document.getElementById('virtue-val').textContent = state.virtue.toLocaleString();
  document.getElementById('virtue-next').textContent = nextGrade.req.toLocaleString();
  document.getElementById('gold-val').textContent = state.gold.toLocaleString();
  document.getElementById('fame-val').textContent = state.fame.toLocaleString();
  document.getElementById('awaken-pct').textContent = `${state.awakeningMeter}%`;

  const pct = nextGrade === curGrade
    ? 100
    : Math.min(100, Math.round(((state.virtue - curGrade.req) / (nextGrade.req - curGrade.req)) * 100));
  document.getElementById('virtue-bar-fill').style.width = `${Math.max(4, pct)}%`;

  // Update Quest 1 & 2 checklists
  const setStep = (id, cur, max) => {
    const li = document.getElementById(id);
    if (!li) return;
    li.querySelector('.cnt').textContent = `${cur}/${max}`;
    if (cur >= max) li.classList.add('done');
  };
  setStep('q-till', state.questGarden.till, 3);
  setStep('q-plant', state.questGarden.plant, 3);
  setStep('q-water', state.questGarden.water, 3);
  setStep('q-harvest', state.questGarden.harvest, 3);

  setStep('q-gada', state.questArena.gada, 5);
  setStep('q-archery', state.questArena.archery, 5);
  setStep('q-malla', state.questArena.malla, 5);
  setStep('q-awaken', state.questArena.awaken, 1);
}

// Onboarding Welcome Buttons
document.getElementById('start-garden-btn').addEventListener('click', () => {
  document.getElementById('welcome-modal').classList.add('hidden');
  teleportToLandmark('garden');
});

document.getElementById('start-arena-btn').addEventListener('click', () => {
  document.getElementById('welcome-modal').classList.add('hidden');
  teleportToLandmark('arena');
  document.querySelector('[data-q="arena"]').click();
});

// Quest Tabs
document.querySelectorAll('.q-tab').forEach((btn) => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.q-tab').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
    const q = btn.getAttribute('data-q');
    document.getElementById('quest-content-garden').classList.toggle('hidden', q !== 'garden');
    document.getElementById('quest-content-arena').classList.toggle('hidden', q !== 'arena');
  });
});

// GPS Instant Travel Buttons
function teleportToLandmark(key) {
  const lm = LANDMARK_COORDS[key];
  if (!lm) return;
  state.waypoint = lm;
  playerGroup.position.set(lm.pos.x, 0, lm.pos.z + 10);
  camYaw = 0;
  spawnFloatingEffect(playerGroup.position, 0xffe066);
}

document.querySelectorAll('.gps-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    teleportToLandmark(btn.getAttribute('data-target'));
  });
});

// Bottom Action Dock Buttons
let currentNearestInteractable = null;

function triggerNearestInteraction() {
  if (currentNearestInteractable) {
    currentNearestInteractable.onInteract();
  } else {
    // If not near a specific object, perform a quick garden or meditation action
    awardVirtue(20, 'Spontaneous Prayer & Seva');
    spawnFloatingEffect(playerGroup.position, 0x38d996);
  }
}

document.getElementById('context-prompt').addEventListener('click', triggerNearestInteraction);
document.getElementById('btn-interact-nearest').addEventListener('click', triggerNearestInteraction);

document.getElementById('btn-seed-select').addEventListener('click', () => {
  state.seedIndex = (state.seedIndex + 1) % SEEDS.length;
  document.getElementById('current-seed-label').textContent = SEEDS[state.seedIndex].name;
});

document.getElementById('btn-meditate').addEventListener('click', () => {
  awardVirtue(35, 'Dhyana (Mindful Breathwork)');
  spawnFloatingEffect(playerGroup.position, 0xa855f7);
});

document.getElementById('btn-annadana').addEventListener('click', () => {
  awardVirtue(45, 'Daan (Annadana Sacred Feast Offering)');
  spawnFloatingEffect(playerGroup.position, 0xffd700);
});

document.getElementById('btn-strike').addEventListener('click', () => performMartialMove('Vajra Strike', 0x3bc9db, 25));
document.getElementById('btn-whirlwind').addEventListener('click', () => performMartialMove('Silambam Staff Spin', 0xffe066, 25));
document.getElementById('btn-dash').addEventListener('click', performMartialDash);
document.getElementById('btn-awaken').addEventListener('click', triggerRudraAwakening);
document.getElementById('btn-fly').addEventListener('click', toggleFlightMode);
document.getElementById('btn-teleport').addEventListener('click', triggerAstralTeleport);

// Empire & 7 Gods Modal
function toggleEmpireModal() {
  const modal = document.getElementById('empire-modal');
  modal.classList.toggle('hidden');
  if (!modal.classList.contains('hidden')) renderEmpireModalLists();
}

document.getElementById('btn-open-empire').addEventListener('click', toggleEmpireModal);
document.getElementById('close-empire-btn').addEventListener('click', toggleEmpireModal);

function renderEmpireModalLists() {
  const godsList = document.getElementById('gods-list');
  godsList.innerHTML = '';
  DEITIES.forEach((d) => {
    const blessed = !!state.blessedGods[d.id];
    const row = document.createElement('div');
    row.className = `item-row ${blessed ? 'owned' : ''}`;
    row.innerHTML = `
      <div class="item-info">
        <h4>🔥 ${d.name}</h4>
        <p>${d.domain} • <strong>${d.boon}</strong></p>
      </div>
      <button class="cta-pill ${blessed ? 'green-pill' : 'gold-pill'}">${blessed ? '✓ Blessed' : 'Claim Boon'}</button>
    `;
    row.querySelector('button').addEventListener('click', () => claimDeityBoon(d));
    godsList.appendChild(row);
  });

  const propsList = document.getElementById('properties-list');
  propsList.innerHTML = '';
  let totalGoldRate = 0;
  let totalVirtueRate = 0;
  let ownedCount = 0;

  PROPERTIES.forEach((p) => {
    const owned = !!state.ownedProps[p.id];
    if (owned) {
      totalGoldRate += p.goldPerMin;
      totalVirtueRate += p.virtuePerMin;
      ownedCount++;
    }
    const row = document.createElement('div');
    row.className = `item-row ${owned ? 'owned' : ''}`;
    row.innerHTML = `
      <div class="item-info">
        <h4>🏰 ${p.name} <small>[${p.cat}]</small></h4>
        <p>+${p.goldPerMin} Gold/min • +${p.virtuePerMin} Virtue/min (Req: ${p.reqFame} Fame)</p>
      </div>
      <button class="cta-pill ${owned ? 'green-pill' : 'gold-pill'}">${owned ? '✓ Owned' : `${p.price} Gold`}</button>
    `;
    if (!owned) {
      row.querySelector('button').addEventListener('click', () => buyProperty(p));
    }
    propsList.appendChild(row);
  });

  const boonsCount = Object.keys(state.blessedGods).length;
  document.getElementById('empire-summary-line').textContent =
    `Passive Income: +${totalGoldRate} Gold/min • +${totalVirtueRate} Virtue/min • Owned Estates: ${ownedCount} / ${PROPERTIES.length} • Divine Boons: ${boonsCount} / 7`;
}

// Passive Tycoon & Garden Growth Loop (Every 1 second)
setInterval(() => {
  // Grow watered garden plants automatically
  gardenPlots.forEach((plot) => {
    if (plot.stage === 'watered' || plot.stage === 'planted') {
      const rate = plot.stage === 'watered' ? 0.25 : 0.08;
      plot.growth = Math.min(1, plot.growth + rate);
      rebuildPlantMesh(plot);
      if (plot.growth >= 1) {
        plot.stage = 'mature';
        rebuildPlantMesh(plot);
        updatePlotSign(plot, `✨ ${plot.seed.name} BLOOMED!`, 'Press [E] to Harvest & Unlock Siddhi!', '#ffe066');
      }
    }
  });

  // Empire passive payouts
  let goldGain = 0;
  let virtueGain = 0;
  PROPERTIES.forEach((p) => {
    if (state.ownedProps[p.id]) {
      goldGain += Math.round(p.goldPerMin / 20);
      virtueGain += Math.round(p.virtuePerMin / 20);
    }
  });
  if (state.blessedGods['lakshmi']) goldGain *= 2;
  if (goldGain > 0 || virtueGain > 0) {
    state.gold += goldGain;
    state.virtue += virtueGain;
    updateHUD();
  }
}, 1000);

// ============================================================================
// 10. MAIN 60-FPS RENDER & PHYSICS LOOP
// ============================================================================
const clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();

  if (mixer) mixer.update(dt);
  if (window.__riverWater) {
    window.__riverWater.material.uniforms['time'].value += dt * 0.8;
  }

  // Rotate player halo & shrine idols
  playerHalo.rotation.z = elapsed * 1.5;

  // Player Movement Vector
  let moveX = 0;
  let moveZ = 0;
  if (keys['KeyW'] || keys['ArrowUp']) moveZ -= 1;
  if (keys['KeyS'] || keys['ArrowDown']) moveZ += 1;
  if (keys['KeyA'] || keys['ArrowLeft']) moveX -= 1;
  if (keys['KeyD'] || keys['ArrowRight']) moveX += 1;

  const isMoving = moveX !== 0 || moveZ !== 0;
  let baseSpeed = 12;
  if (state.boons.walk) baseSpeed = 16;
  if (state.boons.sprint || keys['ShiftLeft']) baseSpeed = 24;
  if (state.isFlying) baseSpeed = 30;

  if (isMoving) {
    const moveAngle = Math.atan2(moveX, moveZ) + camYaw;
    playerGroup.rotation.y = moveAngle + Math.PI;
    playerGroup.position.x += Math.sin(moveAngle) * baseSpeed * dt;
    playerGroup.position.z += Math.cos(moveAngle) * baseSpeed * dt;
    fadeToAction(baseSpeed > 18 ? 'Run' : 'Walk');
  } else {
    fadeToAction('Idle');
  }

  // Vertical Physics (Jump & Garuda Flight)
  if (state.isFlying) {
    if (keys['Space']) playerGroup.position.y += 18 * dt;
    if (keys['ControlLeft'] || keys['KeyC']) playerGroup.position.y = Math.max(1, playerGroup.position.y - 18 * dt);
  } else {
    if (keys['Space'] && playerGroup.position.y <= 0.05) {
      velY = state.boons.jump ? 19 : 11;
    }
    velY -= 28 * dt;
    playerGroup.position.y = Math.max(0, playerGroup.position.y + velY * dt);
    if (playerGroup.position.y <= 0) velY = 0;
  }

  // Update Third-Person Orbit Camera
  const targetPos = playerGroup.position.clone().add(new THREE.Vector3(0, 2.2, 0));
  camera.position.x = targetPos.x + Math.sin(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.z = targetPos.z + Math.cos(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.y = Math.max(1.5, targetPos.y + Math.sin(camPitch) * camDist);
  camera.lookAt(targetPos);

  // Update Golden Path Guidance Beam & Compass Distance
  if (state.waypoint) {
    waypointBeacon.position.set(state.waypoint.pos.x, 32, state.waypoint.pos.z);
    const posAttr = pathLine.geometry.attributes.position;
    posAttr.setXYZ(0, playerGroup.position.x, playerGroup.position.y + 0.6, playerGroup.position.z);
    posAttr.setXYZ(1, state.waypoint.pos.x, 0.8, state.waypoint.pos.z);
    posAttr.needsUpdate = true;

    const dist = Math.round(playerGroup.position.distanceTo(state.waypoint.pos));
    document.getElementById('compass-direction').textContent =
      dist < 8
        ? `📍 ARRIVED: ${state.waypoint.name}`
        : `🧭 GOLDEN PATH ➔ ${state.waypoint.name} (${dist}m)`;
  }

  // Check Nearest Interactive Object for Floating [E] Context Prompt
  let bestObj = null;
  let bestDist = Infinity;
  interactiveObjects.forEach((obj) => {
    const d = playerGroup.position.distanceTo(obj.pos);
    if (d <= obj.radius && d < bestDist) {
      bestDist = d;
      bestObj = obj;
    }
  });

  currentNearestInteractable = bestObj;
  const promptEl = document.getElementById('context-prompt');
  if (bestObj) {
    const info = bestObj.getPrompt();
    document.getElementById('prompt-action').textContent = info.action;
    document.getElementById('prompt-object').textContent = info.object;
    promptEl.classList.remove('hidden');
  } else {
    promptEl.classList.add('hidden');
  }

  // Animate visual shockwaves & particles
  for (let i = activeEffects.length - 1; i >= 0; i--) {
    const fx = activeEffects[i];
    fx.mesh.scale.addScalar(fx.scaleSpeed * dt);
    if (fx.riseSpeed) fx.mesh.position.y += fx.riseSpeed * dt;
    fx.mesh.material.opacity -= fx.fadeSpeed * dt;
    if (fx.mesh.material.opacity <= 0) {
      scene.remove(fx.mesh);
      activeEffects.splice(i, 1);
    }
  }

  composer.render();
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  composer.setSize(window.innerWidth, window.innerHeight);
});

updateHUD();
animate();
