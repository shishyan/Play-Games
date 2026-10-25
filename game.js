import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

// ============================================================================
// AUDIO SYNTHESIZER (Web Audio API)
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
      if (this.ctx.state === 'suspended') this.ctx.resume();
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
    [261.63, 329.63, 392.0, 523.25].forEach((f, i) => setTimeout(() => this.playChime(f, 1.2), i * 160));
  }
  playHeal() {
    if (!this.ctx) return;
    [432, 540, 648, 864].forEach((f, i) => setTimeout(() => this.playChime(f, 0.6), i * 80));
  }
}
const audio = new SoundEngine();

// ============================================================================
// 1. TEXTURE GENERATORS (Authentic Hand-Painted Stylized MMO Textures)
// ============================================================================
function generateGrassTexture() {
  const c = document.createElement('canvas');
  c.width = 512; c.height = 512;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#2f5726';
  ctx.fillRect(0, 0, 512, 512);

  // Layered soft painted patches
  for (let i = 0; i < 3000; i++) {
    const x = Math.random() * 512;
    const y = Math.random() * 512;
    const r = Math.random() * 6 + 2;
    ctx.fillStyle = Math.random() > 0.5 ? '#3b6e30' : (Math.random() > 0.5 ? '#24451d' : '#4b853d');
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
  }

  // Soft clover / wildflower specks
  for (let i = 0; i < 200; i++) {
    const x = Math.random() * 512;
    const y = Math.random() * 512;
    ctx.fillStyle = Math.random() > 0.6 ? '#fcd34d' : '#f472b6';
    ctx.beginPath();
    ctx.arc(x, y, 2, 0, Math.PI * 2);
    ctx.fill();
  }

  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(60, 60);
  return tex;
}

function generateBarkTexture() {
  const c = document.createElement('canvas');
  c.width = 256; c.height = 256;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#3a271d';
  ctx.fillRect(0, 0, 256, 256);
  ctx.strokeStyle = '#221610';
  ctx.lineWidth = 3;
  for (let x = 0; x < 256; x += 12) {
    ctx.beginPath();
    ctx.moveTo(x + Math.sin(x) * 4, 0);
    ctx.bezierCurveTo(x + 10, 80, x - 10, 160, x, 256);
    ctx.stroke();
  }
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(2, 6);
  return tex;
}

function generateStoneTexture() {
  const c = document.createElement('canvas');
  c.width = 256; c.height = 256;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#78716c';
  ctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 1500; i++) {
    ctx.fillStyle = Math.random() > 0.5 ? '#57534e' : '#a8a29e';
    ctx.fillRect(Math.random() * 256, Math.random() * 256, 4, 4);
  }
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(8, 8);
  return tex;
}

// ============================================================================
// 2. SCENE, ATMOSPHERIC LIGHTING, SKYBOX & FOG
// ============================================================================
const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();
scene.background = new THREE.Color(0xb6d5ec); // WoW Elwynn / Nagrand sky blue
scene.fog = new THREE.FogExp2(0xb6d5ec, 0.0018);

const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.5, 3000);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;
container.appendChild(renderer.domElement);

// Warm Sunlight & Atmospheric Ambient
const sunLight = new THREE.DirectionalLight(0xfff3d6, 2.4);
sunLight.position.set(180, 260, 140);
sunLight.castShadow = true;
sunLight.shadow.mapSize.set(2048, 2048);
sunLight.shadow.camera.near = 10;
sunLight.shadow.camera.far = 800;
const d = 220;
sunLight.shadow.camera.left = -d; sunLight.shadow.camera.right = d;
sunLight.shadow.camera.top = d; sunLight.shadow.camera.bottom = -d;
sunLight.shadow.bias = -0.0003;
scene.add(sunLight);

const ambientLight = new THREE.HemisphereLight(0xdbeafe, 0x4d7c0f, 1.1);
scene.add(ambientLight);

// ============================================================================
// 3. CONTINUOUS TERRAIN & ROLLING HILLS (No Flat Green Sheet)
// ============================================================================
const terrainGeo = new THREE.PlaneGeometry(1600, 1600, 128, 128);
terrainGeo.rotateX(-Math.PI / 2);

const posAttr = terrainGeo.attributes.position;
function getTerrainHeight(x, z) {
  // Flat sanctuary area in center (0, 0)
  const distFromCenter = Math.sqrt(x * x + z * z);
  if (distFromCenter < 50) return 0;

  // Gentle rolling hills
  let h = Math.sin(x * 0.012) * Math.cos(z * 0.012) * 8;
  h += Math.sin(x * 0.025 + 1.2) * Math.sin(z * 0.025) * 4;

  // Mountain ridges on north (Mount Kailash foothills)
  if (z < -160) {
    const northFactor = Math.min(1, (-z - 160) / 250);
    h += (Math.sin(x * 0.02) * 20 + Math.cos(z * 0.02) * 25 + 40) * northFactor;
  }
  return h;
}

for (let i = 0; i < posAttr.count; i++) {
  const vx = posAttr.getX(i);
  const vz = posAttr.getZ(i);
  posAttr.setY(i, getTerrainHeight(vx, vz));
}
terrainGeo.computeVertexNormals();

const grassTex = generateGrassTexture();
const barkTex = generateBarkTexture();
const stoneTex = generateStoneTexture();

const matTerrain = new THREE.MeshStandardMaterial({
  map: grassTex,
  roughness: 0.85,
  metalness: 0.05
});
const terrainMesh = new THREE.Mesh(terrainGeo, matTerrain);
terrainMesh.receiveShadow = true;
scene.add(terrainMesh);

// Sacred River Ganga on the West (Cuts naturally through terrain)
const riverMesh = new THREE.Mesh(
  new THREE.PlaneGeometry(140, 1200),
  new THREE.MeshStandardMaterial({ color: 0x2563eb, roughness: 0.1, transparent: true, opacity: 0.85 })
);
riverMesh.rotation.x = -Math.PI / 2;
riverMesh.position.set(-240, 0.4, 0);
scene.add(riverMesh);

// ============================================================================
// 4. STYLIZED HAND-CRAFTED FLORA (Complex Tree Foliage & Shrubbery)
// ============================================================================
const matFoliageDark = new THREE.MeshStandardMaterial({ color: 0x1e5a22, roughness: 0.8 });
const matFoliageMid = new THREE.MeshStandardMaterial({ color: 0x2f7d34, roughness: 0.8 });
const matFoliageLight = new THREE.MeshStandardMaterial({ color: 0x4ade80, roughness: 0.75 });
const matBark = new THREE.MeshStandardMaterial({ map: barkTex, roughness: 0.9 });
const matStone = new THREE.MeshStandardMaterial({ map: stoneTex, roughness: 0.85 });

function createOrganicTree(x, z, scale = 1) {
  const treeGroup = new THREE.Group();
  const y = getTerrainHeight(x, z);
  treeGroup.position.set(x, y, z);

  // Twisted Trunk (Compound cylinders for natural taper)
  const trunk1 = new THREE.Mesh(new THREE.CylinderGeometry(0.8 * scale, 1.4 * scale, 6 * scale, 10), matBark);
  trunk1.position.y = 3 * scale;
  trunk1.castShadow = true;
  treeGroup.add(trunk1);

  const trunk2 = new THREE.Mesh(new THREE.CylinderGeometry(0.5 * scale, 0.8 * scale, 5 * scale, 8), matBark);
  trunk2.position.set(0.2 * scale, 7 * scale, 0.1 * scale);
  trunk2.rotation.z = 0.08;
  trunk2.castShadow = true;
  treeGroup.add(trunk2);

  // Multi-cluster WoW-style foliage puffs (Layered spheres)
  const puffGeo = new THREE.DodecahedronGeometry(2.8 * scale, 1);
  const puffOffsets = [
    { x: 0, y: 9.5 * scale, z: 0, s: 1.3, mat: matFoliageDark },
    { x: -1.6 * scale, y: 8.5 * scale, z: 0.8 * scale, s: 1.0, mat: matFoliageMid },
    { x: 1.6 * scale, y: 8.8 * scale, z: -0.6 * scale, s: 1.1, mat: matFoliageMid },
    { x: 0.8 * scale, y: 11.2 * scale, z: 0.8 * scale, s: 0.9, mat: matFoliageLight },
    { x: -0.8 * scale, y: 11.5 * scale, z: -0.8 * scale, s: 0.85, mat: matFoliageLight }
  ];

  puffOffsets.forEach((p) => {
    const puff = new THREE.Mesh(puffGeo, p.mat);
    puff.position.set(p.x, p.y, p.z);
    puff.scale.setScalar(p.s);
    puff.castShadow = true;
    treeGroup.add(puff);
  });

  scene.add(treeGroup);
}

// Populate Grove with 45 Organic Trees
for (let i = 0; i < 45; i++) {
  const angle = Math.random() * Math.PI * 2;
  const dist = 35 + Math.random() * 120;
  const tx = Math.cos(angle) * dist;
  const tz = Math.sin(angle) * dist;
  if (tx > -220 && tx < -260) continue; // Keep river clear
  createOrganicTree(tx, tz, 0.85 + Math.random() * 0.5);
}

// Giant Ancient Banyan Tree at Sanctuary Center (0, 0)
const grandBanyan = new THREE.Group();
grandBanyan.position.set(0, 0, 0);

const banyanTrunk = new THREE.Mesh(new THREE.CylinderGeometry(2.4, 4.2, 14, 16), matBark);
banyanTrunk.position.y = 7;
banyanTrunk.castShadow = true;
grandBanyan.add(banyanTrunk);

// Giant foliage canopy (4 massive intersecting volumes)
const banyanCanopyGeo = new THREE.DodecahedronGeometry(8.5, 2);
[
  { x: 0, y: 16, z: 0, s: 1.3, m: matFoliageDark },
  { x: -4, y: 14.5, z: 3, s: 1.1, m: matFoliageMid },
  { x: 4, y: 15, z: -2.5, s: 1.15, m: matFoliageMid },
  { x: 0, y: 19.5, z: 0, s: 0.95, m: matFoliageLight }
].forEach(c => {
  const canopy = new THREE.Mesh(banyanCanopyGeo, c.m);
  canopy.position.set(c.x, c.y, c.z);
  canopy.scale.setScalar(c.s);
  canopy.castShadow = true;
  grandBanyan.add(canopy);
});

// Stone circular meditation plinth under the Banyan
const stonePlinth = new THREE.Mesh(new THREE.CylinderGeometry(14, 15, 0.8, 32), matStone);
stonePlinth.position.y = 0.4;
stonePlinth.receiveShadow = true;
grandBanyan.add(stonePlinth);

scene.add(grandBanyan);

// ============================================================================
// 5. INTERACTIVE SACRED FLORA & LIVING FOREST CREATURES
// ============================================================================
const interactables = [];

// Selection Reticle on Active Target
const targetRing = new THREE.Mesh(
  new THREE.RingGeometry(2.2, 2.7, 32),
  new THREE.MeshBasicMaterial({ color: 0x38bdf8, side: THREE.DoubleSide })
);
targetRing.rotation.x = -Math.PI / 2;
targetRing.visible = false;
scene.add(targetRing);

// 6 Sacred Soil Beds (Tilled mandala plots around central grove)
for (let r = 0; r < 2; r++) {
  for (let c = 0; c < 3; c++) {
    const px = (c - 1) * 11;
    const pz = 24 + r * 11;

    const stoneFrame = new THREE.Mesh(new THREE.BoxGeometry(7.5, 0.5, 7.5), matStone);
    stoneFrame.position.set(px, 0.25, pz);
    stoneFrame.castShadow = true;
    scene.add(stoneFrame);

    const soilMat = new THREE.MeshStandardMaterial({ color: 0x3d2516, roughness: 0.95 });
    const soil = new THREE.Mesh(new THREE.BoxGeometry(6.6, 0.6, 6.6), soilMat);
    soil.position.set(px, 0.32, pz);
    soil.receiveShadow = true;
    scene.add(soil);

    const plantGroup = new THREE.Group();
    plantGroup.position.set(px, 0.6, pz);
    scene.add(plantGroup);

    const plot = {
      id: `tulsi_bed_${r}_${c}`,
      type: 'garden_plot',
      name: `Sacred Tulsi Soil Bed #${r * 3 + c + 1}`,
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

// Animated 3D Living Forest Creatures (Fox/Fawn Model via GLTF)
const gltfLoader = new GLTFLoader();
const livingCreatures = [];

function spawnAnimatedCreature(x, z, name) {
  const y = getTerrainHeight(x, z);
  const creatureObj = {
    id: `creature_${x}_${z}`,
    type: 'creature',
    name,
    subtitle: '[Wounded • Needs Sanjeevani Herbs (1)]',
    icon: '🦊',
    pos: new THREE.Vector3(x, y, z),
    health: 35,
    maxHealth: 100,
    healed: false,
    group: new THREE.Group(),
    mixer: null
  };
  creatureObj.group.position.set(x, y, z);
  scene.add(creatureObj.group);
  interactables.push(creatureObj);

  gltfLoader.load(
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
    (gltf) => {
      const model = gltf.scene;
      model.scale.set(0.024, 0.024, 0.024);
      model.traverse(node => {
        if (node.isMesh) {
          node.castShadow = true;
          node.receiveShadow = true;
        }
      });
      creatureObj.group.add(model);

      if (gltf.animations && gltf.animations.length > 0) {
        creatureObj.mixer = new THREE.AnimationMixer(model);
        const action = creatureObj.mixer.clipAction(gltf.animations[0]); // Idle / Survey
        action.play();
      }
      livingCreatures.push(creatureObj);
    },
    undefined,
    () => {
      // Fallback stylized procedural mesh if offline
      const body = new THREE.Mesh(new THREE.BoxGeometry(1.6, 1.2, 2.4), new THREE.MeshStandardMaterial({ color: 0xc27136 }));
      body.position.y = 1.0;
      creatureObj.group.add(body);
    }
  );
}

spawnAnimatedCreature(18, -14, 'Injured Vrindavan Fox');
spawnAnimatedCreature(-22, 18, 'Wounded Forest Fawn');
spawnAnimatedCreature(26, 26, 'Gentle Grove Deer');

// ============================================================================
// 6. WOW PLAYER AVATAR & 3D ANIMATION RIG (Soldier / Seeker Rig)
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, 0, 14);
scene.add(playerGroup);

let playerMixer = null;
const playerActions = {};
let currentAction = null;

// Saffron Halo behind avatar
const charHalo = new THREE.Mesh(
  new THREE.RingGeometry(0.7, 0.95, 32),
  new THREE.MeshBasicMaterial({ color: 0xffe066, side: THREE.DoubleSide })
);
charHalo.position.set(0, 3.2, -0.4);
playerGroup.add(charHalo);

gltfLoader.load(
  'https://threejs.org/examples/models/gltf/Soldier.glb',
  (gltf) => {
    const model = gltf.scene;
    model.scale.set(1.3, 1.3, 1.3);
    model.traverse(node => {
      if (node.isMesh) {
        node.castShadow = true;
        node.receiveShadow = true;
      }
    });
    playerGroup.add(model);

    playerMixer = new THREE.AnimationMixer(model);
    gltf.animations.forEach(clip => {
      playerActions[clip.name] = playerMixer.clipAction(clip);
    });
    if (playerActions['Idle']) {
      currentAction = playerActions['Idle'];
      currentAction.play();
    }
  },
  undefined,
  () => {
    // Fallback mesh
    const body = new THREE.Mesh(new THREE.CylinderGeometry(0.65, 0.85, 2.2, 16), new THREE.MeshStandardMaterial({ color: 0xff7700 }));
    body.position.y = 1.6;
    playerGroup.add(body);
  }
);

function fadePlayerAction(name) {
  if (!playerMixer || !playerActions[name] || currentAction === playerActions[name]) return;
  const prev = currentAction;
  currentAction = playerActions[name];
  if (prev) prev.fadeOut(0.2);
  currentAction.reset().fadeIn(0.2).play();
}

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
    const mouse = new THREE.Vector2(
      (e.clientX / window.innerWidth) * 2 - 1,
      -(e.clientY / window.innerHeight) * 2 + 1
    );
    let nearest = null;
    let nearestDist = Infinity;
    interactables.forEach((item) => {
      const screenPos = item.pos.clone().project(camera);
      const d = new THREE.Vector2(screenPos.x, screenPos.y).distanceTo(mouse);
      if (d < 0.16 && d < nearestDist) {
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
// 7. TARGETING, ZONE DETECTION & VIRTUOUS PROGRESSION
// ============================================================================
const state = {
  punya: 0,
  gold: 2400,
  fame: 150,
  annadanaCount: 0,
  prana: 100,
  level: 1,
  selectedTarget: null,
  isFlying: false,
  boons: { sprint: false, jump: false, fly: false, teleport: false }
};

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
    showFloatingText(playerGroup.position, 'No target nearby! Left-click or press [Tab] to select', 'float-healing');
    return;
  }

  selectTarget(tgt);

  if (tgt.type === 'garden_plot') handleGardenPlot(tgt);
  else if (tgt.type === 'creature') castSpell(1);
}

function castSpell(key) {
  const tgt = state.selectedTarget;
  const dist = tgt ? playerGroup.position.distanceTo(tgt.pos) : 999;

  // Spell 1: Sanjeevani Herbs (Heal Creature)
  if (key === 1 || key === '1') {
    triggerCooldown('1', 1.2);
    if (tgt && tgt.type === 'creature' && dist < 18) {
      tgt.health = Math.min(100, tgt.health + 35);
      document.getElementById('target-health-val').textContent = Math.round(tgt.health);
      document.getElementById('target-health-fill').style.width = `${tgt.health}%`;

      audio.playHeal();
      showFloatingText(tgt.pos, '+35 Vitality', 'float-healing');
      awardPunya(45, 'Healed Wounded Wildlife');

      if (tgt.health >= 100 && !tgt.healed) {
        tgt.healed = true;
        tgt.subtitle = '[Fully Healed & Joyful]';
        document.getElementById('target-subtitle').textContent = tgt.subtitle;
        showSurpriseGift({
          name: 'Surya Tejas (Solar Sprint)',
          tier: 'EPIC BOON',
          icon: '☀️',
          desc: 'Blessed by the grateful forest spirits! Hold [Shift] or press [4] to sprint at 3x speed.',
          unlockedKey: 'sprint'
        });
      }
    } else {
      audio.playChime(380, 0.4);
      showFloatingText(playerGroup.position, '+15 Prana Balance', 'float-healing');
      state.prana = Math.min(100, state.prana + 15);
      updateHUD();
    }
  }

  // Spell 2: Ganga Jal (Purify / Water)
  if (key === 2 || key === '2') {
    triggerCooldown('2', 1.5);
    audio.playChime(640, 0.5);
    if (tgt && tgt.type === 'garden_plot' && dist < 18) {
      handleGardenPlot(tgt);
    } else {
      showFloatingText(playerGroup.position, 'Sanctified Sacred Ground', 'float-healing');
      awardPunya(15, 'Purification');
    }
  }

  // Spell 3: Annadana (Feed Pilgrims)
  if (key === 3 || key === '3') {
    triggerCooldown('3', 2.0);
    state.annadanaCount += 5;
    audio.playChime(720, 0.7);
    showFloatingText(playerGroup.position, 'Served 5 Annadana Meals (+65 Punya)', 'float-punya');
    awardPunya(65, 'Annadana Distribution');
  }

  // Spell 4: Solar Sprint
  if (key === 4 || key === '4') {
    if (!state.boons.sprint) {
      showFloatingText(playerGroup.position, 'Locked! Heal forest creatures to awaken Surya Tejas.', 'float-punya');
      return;
    }
    triggerCooldown('4', 8.0);
    audio.playChime(880, 0.5);
    showFloatingText(playerGroup.position, '☀️ Surya Tejas Sprint Active!', 'float-punya');
  }

  // Spell 5: Lotus Leap
  if (key === 5 || key === '5') {
    if (!state.boons.jump) {
      showFloatingText(playerGroup.position, 'Locked! Harvest sacred blooms to unlock Lotus Leap.', 'float-punya');
      return;
    }
    velY = 28;
    audio.playChime(760, 0.6);
    showFloatingText(playerGroup.position, '🪷 Lotus Sky Leap!', 'float-punya');
  }

  // Spell F: Garuda Flight
  if (key === 'F' || key === 'f') {
    if (!state.boons.fly) {
      showFloatingText(playerGroup.position, 'Locked! Reach Level 10 or Shiva shrine to unlock flight.', 'float-punya');
      return;
    }
    state.isFlying = !state.isFlying;
    audio.playChime(950, 0.8);
    showFloatingText(playerGroup.position, state.isFlying ? '🦅 Garuda Flight Ascended!' : 'Landed Safely', 'float-punya');
  }

  // Spell T: Akash Blink
  if (key === 'T' || key === 't') {
    if (!state.boons.teleport) {
      showFloatingText(playerGroup.position, 'Locked! Attain Level 5 to blink across space.', 'float-punya');
      return;
    }
    const forward = new THREE.Vector3(0, 0, -1).applyAxisAngle(new THREE.Vector3(0, 1, 0), playerGroup.rotation.y);
    playerGroup.position.addScaledVector(forward, 36);
    audio.playChime(1100, 0.8);
    showFloatingText(playerGroup.position, '✨ Akash Blink Teleport (36m)!', 'float-punya');
  }
}

function handleGardenPlot(plot) {
  if (plot.stage === 'untilled') {
    plot.stage = 'tilled';
    plot.soilMat.color.setHex(0x24150c);
    plot.subtitle = '[Tilled • Sowing Celestial Seeds]';
    audio.playChime(520, 0.5);
    showFloatingText(plot.pos, 'Tilled Sacred Soil Bed', 'float-punya');
    awardPunya(25, 'Soil Preparation');
  } else if (plot.stage === 'tilled') {
    plot.stage = 'mature';
    plot.subtitle = '[Mature Bloom • Press E to Harvest]';
    rebuildPlant(plot);
    audio.playChime(640, 0.5);
    showFloatingText(plot.pos, 'Sacred Sapling Bloomed Radiantly!', 'float-healing');
    awardPunya(50, 'Nurtured Sacred Life');
  } else if (plot.stage === 'mature') {
    plot.stage = 'untilled';
    plot.subtitle = '[Harvested • Needs Tilling]';
    while (plot.plantGroup.children.length) plot.plantGroup.remove(plot.plantGroup.children[0]);
    audio.playChime(880, 0.9);
    showFloatingText(plot.pos, '✨ Harvested Sacred Bloom! (+100 Punya, +150 Gold)', 'float-punya');
    awardPunya(100, 'Sacred Blossom Harvest');
    state.gold += 150;

    if (!state.boons.jump) {
      showSurpriseGift({
        name: 'Padma Siddhi (Lotus Leap)',
        tier: 'MYTHIC BOON',
        icon: '🪷',
        desc: 'Unlocked from nurturing sacred blooms! Press [Space] to leap sky-high over cliffs and trees.',
        unlockedKey: 'jump'
      });
    }
  }
  updateHUD();
}

function rebuildPlant(plot) {
  while (plot.plantGroup.children.length) plot.plantGroup.remove(plot.plantGroup.children[0]);
  const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.22, 2.8, 8), new THREE.MeshStandardMaterial({ color: 0x22c55e }));
  stem.position.y = 1.4;
  plot.plantGroup.add(stem);
  const flower = new THREE.Mesh(new THREE.DodecahedronGeometry(1.3), new THREE.MeshStandardMaterial({ color: 0xff69b4, emissive: 0xaa2266, emissiveIntensity: 0.5 }));
  flower.position.y = 3.0;
  plot.plantGroup.add(flower);
}

function awardPunya(amount, reason) {
  state.punya += amount;
  if (state.punya >= state.level * 120) {
    state.level++;
    triggerLevelUp();
  }
  if (state.level >= 5 && !state.boons.teleport) {
    showSurpriseGift({
      name: 'Akash Gamana (Astral Teleport)',
      tier: 'TRANSCENDENT SIDDHI',
      icon: '✨',
      desc: 'Mastery of Karma folds space! Press [T] to instantly blink 36m forward.',
      unlockedKey: 'teleport'
    });
  }
  if (state.level >= 10 && !state.boons.fly) {
    showSurpriseGift({
      name: 'Garuda Paksha (Divine Flight)',
      tier: 'DIVINE LEGENDARY BOON',
      icon: '🦅',
      desc: 'Ascended to the heavens! Toggle free flight anytime with [F].',
      unlockedKey: 'fly'
    });
  }
  updateHUD();
}

function triggerLevelUp() {
  audio.playZoneFanfare();
  const banner = document.getElementById('levelup-banner');
  document.getElementById('levelup-title').textContent = `LEVEL ${state.level}: GUARDIAN OF BHARAT`;
  banner.classList.remove('levelup-hidden');

  const pillar = new THREE.Mesh(
    new THREE.CylinderGeometry(3.5, 3.5, 120, 24),
    new THREE.MeshBasicMaterial({ color: 0xffe066, transparent: true, opacity: 0.85 })
  );
  pillar.position.set(playerGroup.position.x, 60, playerGroup.position.z);
  scene.add(pillar);

  let op = 0.85;
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

function updateHUD() {
  document.getElementById('player-level-badge').textContent = state.level;
  document.getElementById('prana-val').textContent = Math.round(state.prana);
  document.getElementById('prana-fill').style.width = `${state.prana}%`;

  document.getElementById('punya-val').textContent = state.punya.toLocaleString();
  const maxPunya = state.level * 120;
  document.getElementById('punya-max').textContent = maxPunya.toLocaleString();
  const pct = Math.min(100, Math.round((state.punya / maxPunya) * 100));
  document.getElementById('punya-fill').style.width = `${Math.max(4, pct)}%`;

  document.getElementById('cur-gold').textContent = state.gold.toLocaleString();
  document.getElementById('cur-annadana').textContent = state.annadanaCount;
  document.getElementById('cur-fame').textContent = state.fame;
}

// ============================================================================
// 8. 60-FPS ANIMATION & RENDER LOOP
// ============================================================================
const clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();

  charHalo.rotation.z = elapsed * 1.5;

  if (playerMixer) playerMixer.update(dt);
  livingCreatures.forEach(c => {
    if (c.mixer) c.mixer.update(dt);
  });

  // Movement
  let moveX = 0;
  let moveZ = 0;
  if (keys['KeyW'] || keys['ArrowUp']) moveZ -= 1;
  if (keys['KeyS'] || keys['ArrowDown']) moveZ += 1;
  if (keys['KeyA'] || keys['ArrowLeft']) moveX -= 1;
  if (keys['KeyD'] || keys['ArrowRight']) moveX += 1;

  const isMoving = moveX !== 0 || moveZ !== 0;
  let speed = 14;
  if (state.boons.sprint || keys['ShiftLeft']) speed = 28;
  if (state.isFlying) speed = 38;

  if (isMoving) {
    const moveAngle = Math.atan2(moveX, moveZ) + camYaw;
    playerGroup.rotation.y = moveAngle + Math.PI;
    playerGroup.position.x += Math.sin(moveAngle) * speed * dt;
    playerGroup.position.z += Math.cos(moveAngle) * speed * dt;
    fadePlayerAction(speed > 20 ? 'Run' : 'Walk');
  } else {
    fadePlayerAction('Idle');
  }

  // Terrain clamping & Jump
  const groundY = getTerrainHeight(playerGroup.position.x, playerGroup.position.z);
  if (state.isFlying) {
    if (keys['Space']) playerGroup.position.y += 24 * dt;
    if (keys['ControlLeft'] || keys['KeyC']) playerGroup.position.y = Math.max(groundY + 1, playerGroup.position.y - 24 * dt);
  } else {
    if (keys['Space'] && playerGroup.position.y <= groundY + 0.1) {
      velY = state.boons.jump ? 26 : 14;
      audio.playChime(640, 0.3);
    }
    velY -= 36 * dt;
    playerGroup.position.y = Math.max(groundY, playerGroup.position.y + velY * dt);
    if (playerGroup.position.y <= groundY) velY = 0;
  }

  // Camera Orbit
  const targetPos = playerGroup.position.clone().add(new THREE.Vector3(0, 2.4, 0));
  camera.position.x = targetPos.x + Math.sin(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.z = targetPos.z + Math.cos(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.y = Math.max(groundY + 1.8, targetPos.y + Math.sin(camPitch) * camDist);
  camera.lookAt(targetPos);

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
