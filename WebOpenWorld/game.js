import * as THREE from 'three';

// ============================================================================
// AUDIO SYNTHESIZER (Crisp Hordes.io cues)
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
  playChime(freq = 528, duration = 0.4) {
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(freq * 1.3, this.ctx.currentTime + duration);
    gain.gain.setValueAtTime(0.25, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + duration);
  }
  playHeal() {
    if (!this.ctx) return;
    [520, 650, 780].forEach((f, i) => setTimeout(() => this.playChime(f, 0.35), i * 70));
  }
}
const audio = new SoundEngine();

// ============================================================================
// 1. ENGINE & ATMOSPHERE (HORDES.IO COHESIVE SKY & SUNLIGHT)
// ============================================================================
const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();

// Authentic Hordes.io Atmosphere: Deep rich sky with subtle atmospheric fog
scene.background = new THREE.Color(0x7bb6e8);
scene.fog = new THREE.FogExp2(0x7bb6e8, 0.0035);

const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.5, 1800);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;
container.appendChild(renderer.domElement);

// Warm directional sunlight & ambient occlusion fill
const dirLight = new THREE.DirectionalLight(0xfff5e6, 2.2);
dirLight.position.set(120, 200, 100);
dirLight.castShadow = true;
dirLight.shadow.mapSize.set(2048, 2048);
dirLight.shadow.camera.near = 10;
dirLight.shadow.camera.far = 500;
const d = 140;
dirLight.shadow.camera.left = -d; dirLight.shadow.camera.right = d;
dirLight.shadow.camera.top = d; dirLight.shadow.camera.bottom = -d;
dirLight.shadow.bias = -0.0004;
scene.add(dirLight);

const hemiLight = new THREE.HemisphereLight(0xdff0ff, 0x224422, 1.15);
scene.add(hemiLight);

// ============================================================================
// 2. TRUE HORDES.IO PROCEDURAL CHUNK TERRAIN (Contoured Rolling Elevation)
// ============================================================================
// Noise function for natural organic hills
function getElevation(x, z) {
  // Center sanctuary clearing
  const dist = Math.sqrt(x * x + z * z);
  if (dist < 40) return 0;

  let h = Math.sin(x * 0.015) * Math.cos(z * 0.015) * 7.0;
  h += Math.sin(x * 0.035 + 1.2) * Math.sin(z * 0.035) * 3.5;
  return h;
}

const terrainGeo = new THREE.PlaneGeometry(900, 900, 120, 120);
terrainGeo.rotateX(-Math.PI / 2);

const tPos = terrainGeo.attributes.position;
const colors = [];
const colorTop = new THREE.Color(0x438938);   // Vibrant forest grass
const colorLow = new THREE.Color(0x356f2c);   // Shaded valley green
const colorRock = new THREE.Color(0x756858);  // Cliff rock

for (let i = 0; i < tPos.count; i++) {
  const vx = tPos.getX(i);
  const vz = tPos.getZ(i);
  const vy = getElevation(vx, vz);
  tPos.setY(i, vy);

  // Natural slope vertex coloring (eliminates flat grid look)
  if (vy > 6) {
    colors.push(colorTop.r, colorTop.g, colorTop.b);
  } else if (vy < -2) {
    colors.push(colorRock.r, colorRock.g, colorRock.b);
  } else {
    colors.push(colorLow.r, colorLow.g, colorLow.b);
  }
}
terrainGeo.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
terrainGeo.computeVertexNormals();

const terrainMat = new THREE.MeshStandardMaterial({
  vertexColors: true,
  roughness: 0.85,
  metalness: 0.05,
  flatShading: true // Crisp low-poly faceted shading (Hordes signature)
});
const terrainMesh = new THREE.Mesh(terrainGeo, terrainMat);
terrainMesh.receiveShadow = true;
scene.add(terrainMesh);

// Authentic River Ganga flowing through a carved valley
const riverGeo = new THREE.PlaneGeometry(80, 800, 16, 64);
riverGeo.rotateX(-Math.PI / 2);
const rPos = riverGeo.attributes.position;
for (let i = 0; i < rPos.count; i++) {
  rPos.setY(i, 0.4);
}
const riverMat = new THREE.MeshStandardMaterial({
  color: 0x1d70b8,
  roughness: 0.15,
  transparent: true,
  opacity: 0.88
});
const riverMesh = new THREE.Mesh(riverGeo, riverMat);
riverMesh.position.set(-160, 0, 0);
scene.add(riverMesh);

// ============================================================================
// 3. INSTANCED 3D DENSE GRASS FIELD (HORDES.IO BLADE DENSITY)
// ============================================================================
// A single optimized grass blade geometry
const bladeGeo = new THREE.ConeGeometry(0.18, 0.85, 3);
bladeGeo.translate(0, 0.42, 0);
const bladeMat = new THREE.MeshStandardMaterial({
  color: 0x55a630,
  roughness: 0.8,
  flatShading: true
});

const GRASS_COUNT = 3500;
const instancedGrass = new THREE.InstancedMesh(bladeGeo, bladeMat, GRASS_COUNT);
const dummy = new THREE.Object3D();

let gIdx = 0;
for (let i = 0; i < GRASS_COUNT; i++) {
  const gx = (Math.random() - 0.5) * 360;
  const gz = (Math.random() - 0.5) * 360;
  if (gx > -200 && gx < -120) continue; // Keep river clear

  const gy = getElevation(gx, gz);
  dummy.position.set(gx, gy, gz);
  dummy.rotation.y = Math.random() * Math.PI * 2;
  dummy.rotation.z = (Math.random() - 0.5) * 0.2;
  const s = 0.75 + Math.random() * 0.5;
  dummy.scale.set(s, s * (0.8 + Math.random() * 0.6), s);
  dummy.updateMatrix();
  instancedGrass.setMatrixAt(gIdx++, dummy.matrix);
}
instancedGrass.count = gIdx;
instancedGrass.receiveShadow = true;
scene.add(instancedGrass);

// ============================================================================
// 4. HORDES.IO STYLIZED LOW-POLY TREES (WARPED MULTI-TIERED CONES)
// ============================================================================
const matWood = new THREE.MeshStandardMaterial({ color: 0x4a3324, roughness: 0.9, flatShading: true });
const matPine1 = new THREE.MeshStandardMaterial({ color: 0x245a27, roughness: 0.8, flatShading: true });
const matPine2 = new THREE.MeshStandardMaterial({ color: 0x2e6f32, roughness: 0.8, flatShading: true });
const matPine3 = new THREE.MeshStandardMaterial({ color: 0x3d8c42, roughness: 0.75, flatShading: true });

function createHordesTree(x, z, scale = 1) {
  const tree = new THREE.Group();
  const y = getElevation(x, z);
  tree.position.set(x, y, z);

  // Tapered low-poly trunk
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.4 * scale, 0.7 * scale, 3.6 * scale, 6), matWood);
  trunk.position.y = 1.8 * scale;
  trunk.castShadow = true;
  tree.add(trunk);

  // 4 tiered staggered hexagonal cones
  const tiers = [
    { r: 2.8 * scale, h: 2.6 * scale, y: 3.2 * scale, m: matPine1 },
    { r: 2.2 * scale, h: 2.4 * scale, y: 4.8 * scale, m: matPine2 },
    { r: 1.6 * scale, h: 2.2 * scale, y: 6.2 * scale, m: matPine2 },
    { r: 1.0 * scale, h: 1.8 * scale, y: 7.4 * scale, m: matPine3 }
  ];

  tiers.forEach(t => {
    const cone = new THREE.Mesh(new THREE.ConeGeometry(t.r, t.h, 6), t.m);
    cone.position.y = t.y;
    cone.rotation.y = Math.random() * 0.5;
    cone.castShadow = true;
    tree.add(cone);
  });

  scene.add(tree);
}

// Populate Forest with 65 trees
for (let i = 0; i < 65; i++) {
  const ang = Math.random() * Math.PI * 2;
  const d = 32 + Math.random() * 140;
  const tx = Math.cos(ang) * d;
  const tz = Math.sin(ang) * d;
  if (tx > -205 && tx < -115) continue;
  createHordesTree(tx, tz, 0.85 + Math.random() * 0.45);
}

// ============================================================================
// 5. LIVING FAUNA & SANCTUARY OBJECTIVES
// ============================================================================
const interactables = [];

// Selection Ring under Active Target
const targetRing = new THREE.Mesh(
  new THREE.RingGeometry(1.8, 2.2, 24),
  new THREE.MeshBasicMaterial({ color: 0x38bdf8, side: THREE.DoubleSide })
);
targetRing.rotation.x = -Math.PI / 2;
targetRing.visible = false;
scene.add(targetRing);

function spawnHordesAnimal(x, z, name, icon) {
  const group = new THREE.Group();
  const y = getElevation(x, z);
  group.position.set(x, y, z);

  const matFur = new THREE.MeshStandardMaterial({ color: 0xc8712e, roughness: 0.7, flatShading: true });
  const body = new THREE.Mesh(new THREE.BoxGeometry(1.8, 1.2, 2.4), matFur);
  body.position.y = 1.0;
  body.castShadow = true;
  group.add(body);

  const head = new THREE.Mesh(new THREE.BoxGeometry(1.0, 1.0, 1.2), matFur);
  head.position.set(0, 1.8, 1.2);
  head.castShadow = true;
  group.add(head);

  const legMat = new THREE.MeshStandardMaterial({ color: 0x8a4417, flatShading: true });
  [[-0.6, -0.8], [0.6, -0.8], [-0.6, 0.8], [0.6, 0.8]].forEach(([lx, lz]) => {
    const leg = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.9, 0.32), legMat);
    leg.position.set(lx, 0.45, lz);
    group.add(leg);
  });

  scene.add(group);

  interactables.push({
    id: `animal_${x}_${z}`,
    type: 'creature',
    name,
    subtitle: 'Wounded Wildlife • Needs Sanjeevani [1]',
    icon,
    pos: new THREE.Vector3(x, y, z),
    group,
    health: 35,
    maxHealth: 100,
    healed: false
  });
}

spawnHordesAnimal(16, -14, 'Injured Vrindavan Fawn', '🦌');
spawnHordesAnimal(-22, 18, 'Wounded Golden Fox', '🦊');
spawnHordesAnimal(25, 26, 'Gentle Grove Gazelle', '🦌');

// Natural Stone-Bordered Soil Beds
const matStone = new THREE.MeshStandardMaterial({ color: 0x5a636e, roughness: 0.85, flatShading: true });
for (let r = 0; r < 2; r++) {
  for (let c = 0; c < 3; c++) {
    const px = (c - 1) * 11;
    const pz = 22 + r * 11;
    const py = getElevation(px, pz);

    const frame = new THREE.Mesh(new THREE.BoxGeometry(6.5, 0.4, 6.5), matStone);
    frame.position.set(px, py + 0.2, pz);
    frame.castShadow = true;
    scene.add(frame);

    const soilMat = new THREE.MeshStandardMaterial({ color: 0x2e1d13, roughness: 0.95, flatShading: true });
    const soil = new THREE.Mesh(new THREE.BoxGeometry(5.8, 0.5, 5.8), soilMat);
    soil.position.set(px, py + 0.25, pz);
    soil.receiveShadow = true;
    scene.add(soil);

    const plantGroup = new THREE.Group();
    plantGroup.position.set(px, py + 0.5, pz);
    scene.add(plantGroup);

    interactables.push({
      id: `bed_${r}_${c}`,
      type: 'garden_plot',
      name: `Sacred Soil Bed #${r * 3 + c + 1}`,
      subtitle: 'Untilled • Press [E] or [2] to Nurture',
      icon: '🌿',
      pos: new THREE.Vector3(px, py + 0.5, pz),
      stage: 'untilled',
      health: 20,
      soilMat,
      plantGroup
    });
  }
}

// ============================================================================
// 6. HORDES.IO PLAYER AVATAR & CONTROLLER
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, 0, 10);
scene.add(playerGroup);

const playerMesh = new THREE.Group();
// Tunic with low-poly armor trim
const tunic = new THREE.Mesh(new THREE.BoxGeometry(1.2, 1.8, 0.8), new THREE.MeshStandardMaterial({ color: 0xe65100, roughness: 0.5, flatShading: true }));
tunic.position.y = 1.4;
tunic.castShadow = true;
playerMesh.add(tunic);

const pHead = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.8, 0.8), new THREE.MeshStandardMaterial({ color: 0xffcc80, roughness: 0.5, flatShading: true }));
pHead.position.y = 2.6;
pHead.castShadow = true;
playerMesh.add(pHead);

// Staff with Glowing Lotus Gem
const staff = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.08, 3.2, 6), matWood);
staff.position.set(0.9, 1.8, 0.2);
const staffGem = new THREE.Mesh(new THREE.DodecahedronGeometry(0.35), new THREE.MeshStandardMaterial({ color: 0x10b981, emissive: 0x10b981, emissiveIntensity: 0.8, flatShading: true }));
staffGem.position.set(0.9, 3.4, 0.2);
playerMesh.add(staff, staffGem);

playerGroup.add(playerMesh);

// Player State
const state = {
  punya: 480,
  gold: 3450,
  fame: 210,
  prana: 100,
  level: 1,
  selectedTarget: null,
  isFlying: false,
  isCasting: false,
  boons: { sprint: false, jump: false, fly: false, teleport: false }
};

// Controls & Camera Orbit
const keys = {};
let camYaw = 0;
let camPitch = 0.42;
let camDist = 18;
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
  camPitch = Math.max(0.06, Math.min(1.2, camPitch + e.movementY * 0.005));
});
window.addEventListener('wheel', (e) => {
  camDist = Math.max(8, Math.min(42, camDist + e.deltaY * 0.02));
});

// ============================================================================
// 7. TARGETING, CASTING & VIRTUOUS PROGRESSION
// ============================================================================
function selectTarget(item) {
  state.selectedTarget = item;
  targetRing.visible = true;
  targetRing.position.set(item.pos.x, item.pos.y - 0.1, item.pos.z);

  const frame = document.getElementById('hordes-target-frame');
  frame.classList.remove('target-hidden');
  document.getElementById('target-name').textContent = item.name;
  document.getElementById('target-type').textContent = item.subtitle;
  document.getElementById('target-icon').textContent = item.icon;
  document.getElementById('target-hp-val').textContent = Math.round(item.health);
  document.getElementById('target-hp-fill').style.width = `${item.health}%`;

  audio.playChime(440, 0.25);
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
  if (!tgt) return;
  selectTarget(tgt);

  if (tgt.type === 'garden_plot') handleGardenPlot(tgt);
  else if (tgt.type === 'creature') castSpell(1);
}

function startCast(castTimeSec, spellName, onComplete) {
  if (state.isCasting) return;
  state.isCasting = true;
  const castContainer = document.getElementById('cast-container');
  const castFill = document.getElementById('cast-fill');
  document.getElementById('cast-label').textContent = `Channelling ${spellName}...`;
  castContainer.classList.remove('cast-hidden');

  let start = Date.now();
  const iv = setInterval(() => {
    let elapsed = (Date.now() - start) / 1000;
    let pct = Math.min(1, elapsed / castTimeSec);
    castFill.style.width = `${pct * 100}%`;
    if (pct >= 1) {
      clearInterval(iv);
      castContainer.classList.add('cast-hidden');
      state.isCasting = false;
      onComplete();
    }
  }, 40);
}

function castSpell(key) {
  const tgt = state.selectedTarget;
  const dist = tgt ? playerGroup.position.distanceTo(tgt.pos) : 999;

  // Spell 1: Sanjeevani Herbs (0.8s Cast)
  if (key === 1 || key === '1') {
    triggerCooldown('1', 1.2);
    startCast(0.8, 'Sanjeevani Herbs', () => {
      if (tgt && tgt.type === 'creature' && dist < 20) {
        tgt.health = Math.min(100, tgt.health + 40);
        document.getElementById('target-hp-val').textContent = Math.round(tgt.health);
        document.getElementById('target-hp-fill').style.width = `${tgt.health}%`;

        audio.playHeal();
        showFloatingText(tgt.pos, '+40 Vitality', 'float-healing');
        awardPunya(50);
        addChatMessage('deed', `[Heal] Channeled Sanjeevani on ${tgt.name}! (+50 Punya)`);

        if (tgt.health >= 100 && !tgt.healed) {
          tgt.healed = true;
          tgt.subtitle = 'Fully Restored & Grateful';
          document.getElementById('target-type').textContent = tgt.subtitle;
          showSurpriseGift('Surya Tejas (Solar Sprint)', '☀️', 'sprint', 'Awakened from wildlife rescue! Press [4] to sprint at 3x speed.');
        }
      } else {
        audio.playChime(380, 0.4);
        showFloatingText(playerGroup.position, '+20 Prana', 'float-healing');
        state.prana = Math.min(100, state.prana + 20);
        updateHUD();
      }
    });
  }

  // Spell 2: Ganga Jal (AoE Sanctify / Water)
  if (key === 2 || key === '2') {
    triggerCooldown('2', 1.5);
    audio.playChime(640, 0.5);
    if (tgt && tgt.type === 'garden_plot' && dist < 18) {
      handleGardenPlot(tgt);
    } else {
      showFloatingText(playerGroup.position, 'Sanctified Sacred Ground', 'float-healing');
      awardPunya(20);
    }
  }

  // Spell 3: Annadana (Shared Pilgrim Meals)
  if (key === 3 || key === '3') {
    triggerCooldown('3', 2.0);
    audio.playChime(720, 0.6);
    showFloatingText(playerGroup.position, 'Distributed 5 Annadana Meals (+65 Punya)', 'float-punya');
    awardPunya(65);
    addChatMessage('world', '[Annadana] Shared sacred meals with visiting seekers! (+65 Punya)');
  }

  // Spell 4: Surya Tejas Sprint
  if (key === 4 || key === '4') {
    if (!state.boons.sprint) {
      showFloatingText(playerGroup.position, 'Locked! Heal wildlife to unlock.', 'float-punya');
      return;
    }
    triggerCooldown('4', 8.0);
    audio.playChime(880, 0.5);
    showFloatingText(playerGroup.position, '☀️ Surya Tejas Active (3x Speed)!', 'float-punya');
  }

  // Spell 5: Lotus Leap
  if (key === 5 || key === '5') {
    if (!state.boons.jump) {
      showFloatingText(playerGroup.position, 'Locked! Harvest mature blooms to unlock.', 'float-punya');
      return;
    }
    velY = 28;
    audio.playChime(760, 0.6);
    showFloatingText(playerGroup.position, '🪷 Lotus Sky Leap!', 'float-punya');
  }

  // Spell F: Garuda Flight
  if (key === 'F' || key === 'f') {
    if (!state.boons.fly) {
      showFloatingText(playerGroup.position, 'Locked! Attain Level 5 to take flight.', 'float-punya');
      return;
    }
    state.isFlying = !state.isFlying;
    audio.playChime(950, 0.8);
    showFloatingText(playerGroup.position, state.isFlying ? '🦅 Garuda Flight Ascended!' : 'Landed', 'float-punya');
  }

  // Spell T: Akash Blink
  if (key === 'T' || key === 't') {
    if (!state.boons.teleport) {
      showFloatingText(playerGroup.position, 'Locked! Attain Level 3 to blink.', 'float-punya');
      return;
    }
    const forward = new THREE.Vector3(0, 0, -1).applyAxisAngle(new THREE.Vector3(0, 1, 0), playerGroup.rotation.y);
    playerGroup.position.addScaledVector(forward, 36);
    audio.playChime(1100, 0.8);
    showFloatingText(playerGroup.position, '✨ Akash Blink (36m Forward)!', 'float-punya');
  }
}

function handleGardenPlot(plot) {
  if (plot.stage === 'untilled') {
    plot.stage = 'tilled';
    plot.soilMat.color.setHex(0x1a110a);
    plot.subtitle = 'Tilled • Sowing Tulsi Seeds';
    audio.playChime(520, 0.5);
    showFloatingText(plot.pos, 'Tilled Soil Bed', 'float-punya');
    awardPunya(30);
  } else if (plot.stage === 'tilled') {
    plot.stage = 'mature';
    plot.subtitle = 'Mature Bloom • Press [E] to Harvest';
    rebuildPlant(plot);
    audio.playChime(640, 0.5);
    showFloatingText(plot.pos, 'Sapling Bloomed Radiantly!', 'float-healing');
    awardPunya(50);
  } else if (plot.stage === 'mature') {
    plot.stage = 'untilled';
    plot.subtitle = 'Harvested • Needs Tilling';
    while (plot.plantGroup.children.length) plot.plantGroup.remove(plot.plantGroup.children[0]);
    audio.playChime(880, 0.8);
    showFloatingText(plot.pos, '✨ Harvested Sacred Bloom! (+100 Punya)', 'float-punya');
    awardPunya(100);
    state.gold += 150;

    if (!state.boons.jump) {
      showSurpriseGift('Padma Siddhi (Lotus Leap)', '🪷', 'jump', 'Unlocked from nurturing sacred blooms! Press [Space] to soar over terrain.');
    }
  }
  updateHUD();
}

function rebuildPlant(plot) {
  while (plot.plantGroup.children.length) plot.plantGroup.remove(plot.plantGroup.children[0]);
  const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.18, 2.6, 6), new THREE.MeshStandardMaterial({ color: 0x4caf50, flatShading: true }));
  stem.position.y = 1.3;
  plot.plantGroup.add(stem);
  const blossom = new THREE.Mesh(new THREE.DodecahedronGeometry(1.2), new THREE.MeshStandardMaterial({ color: 0xf472b6, emissive: 0xdb2777, emissiveIntensity: 0.5, flatShading: true }));
  blossom.position.y = 2.8;
  plot.plantGroup.add(blossom);
}

function awardPunya(amount) {
  state.punya += amount;
  const req = state.level * 140;
  if (state.punya >= req) {
    state.level++;
    showFloatingText(playerGroup.position, `✨ LEVEL UP! [Level ${state.level}] ✨`, 'float-punya');
    addChatMessage('world', `🌟 Congratulations! You ascended to Level ${state.level}!`);
    if (state.level >= 3 && !state.boons.teleport) {
      showSurpriseGift('Akash Gamana (Astral Teleport)', '✨', 'teleport', 'Mastery of Karma folds space! Press [T] to blink 36m forward.');
    }
    if (state.level >= 5 && !state.boons.fly) {
      showSurpriseGift('Garuda Paksha (Divine Flight)', '🦅', 'fly', 'Ascended to the skies! Toggle free flight anytime with [F].');
    }
  }
  updateHUD();
}

function showSurpriseGift(name, icon, unlockedKey, desc) {
  state.boons[unlockedKey] = true;
  unlockActionSlot(unlockedKey);

  document.getElementById('gift-title').textContent = name;
  document.getElementById('gift-icon').textContent = icon;
  document.getElementById('gift-desc').textContent = desc;
  document.getElementById('gift-modal').classList.remove('modal-backdrop-hidden');
}

document.getElementById('btn-claim-gift').addEventListener('click', () => {
  document.getElementById('gift-modal').classList.add('modal-backdrop-hidden');
});

function unlockActionSlot(key) {
  const map = { sprint: 'slot-4', jump: 'slot-5', teleport: 'slot-6', fly: 'slot-7' };
  const el = document.getElementById(map[key]);
  if (el) {
    el.classList.remove('locked');
    const lock = el.querySelector('.lock-glyph');
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
  }, 40);
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

  setTimeout(() => span.remove(), 1400);
}

function addChatMessage(type, text) {
  const msgBox = document.getElementById('chat-messages');
  const div = document.createElement('div');
  div.className = `chat-line ${type}`;
  div.innerHTML = text;
  msgBox.appendChild(div);
  msgBox.scrollTop = msgBox.scrollHeight;
}

// Minimap Loop
const minimapCanvas = document.getElementById('minimap-canvas');
const mmCtx = minimapCanvas.getContext('2d');

function updateMinimap() {
  mmCtx.fillStyle = '#0d1117';
  mmCtx.fillRect(0, 0, 160, 160);

  mmCtx.fillStyle = '#1d70b8';
  mmCtx.fillRect(10, 0, 22, 160);

  mmCtx.fillStyle = '#438938';
  mmCtx.beginPath();
  mmCtx.arc(80, 80, 20, 0, Math.PI * 2);
  mmCtx.fill();

  interactables.forEach((item) => {
    const mx = 80 + (item.pos.x / 900) * 160;
    const my = 80 + (item.pos.z / 900) * 160;
    mmCtx.fillStyle = item.type === 'creature' ? '#fbbf24' : '#34d399';
    mmCtx.fillRect(mx - 2, my - 2, 4, 4);
  });

  const px = 80 + (playerGroup.position.x / 900) * 160;
  const py = 80 + (playerGroup.position.z / 900) * 160;
  mmCtx.fillStyle = '#38bdf8';
  mmCtx.beginPath();
  mmCtx.arc(px, py, 3.5, 0, Math.PI * 2);
  mmCtx.fill();

  document.getElementById('minimap-coords').textContent = `X: ${Math.round(playerGroup.position.x)}, Z: ${Math.round(playerGroup.position.z)}`;
}

function updateHUD() {
  document.getElementById('player-lvl').textContent = `Lv. ${state.level}`;
  document.getElementById('player-prana-val').textContent = Math.round(state.prana);
  document.getElementById('player-prana-fill').style.width = `${state.prana}%`;

  document.getElementById('player-punya-val').textContent = state.punya;
  const maxPunya = state.level * 140;
  document.getElementById('player-punya-max').textContent = maxPunya;
  const pct = Math.min(100, Math.round((state.punya / maxPunya) * 100));
  document.getElementById('player-punya-fill').style.width = `${Math.max(4, pct)}%`;

  document.getElementById('stat-gold').textContent = state.gold.toLocaleString();
  document.getElementById('stat-punya').textContent = state.punya;
  document.getElementById('stat-fame').textContent = state.fame;
}

// ============================================================================
// 8. 60-FPS ANIMATION & RENDER LOOP
// ============================================================================
const clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);

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

    playerMesh.position.y = Math.sin(clock.getElapsedTime() * 14) * 0.15;
  } else {
    playerMesh.position.y = 0;
  }

  // Terrain Clamping & Jump
  const groundY = getElevation(playerGroup.position.x, playerGroup.position.z);
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
  const targetPos = playerGroup.position.clone().add(new THREE.Vector3(0, 2.2, 0));
  camera.position.x = targetPos.x + Math.sin(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.z = targetPos.z + Math.cos(camYaw) * Math.cos(camPitch) * camDist;
  camera.position.y = Math.max(groundY + 1.8, targetPos.y + Math.sin(camPitch) * camDist);
  camera.lookAt(targetPos);

  if (state.selectedTarget) {
    const d = Math.round(playerGroup.position.distanceTo(state.selectedTarget.pos));
    const distEl = document.getElementById('target-range');
    if (distEl) distEl.textContent = `Range: ${d}m (${d <= 20 ? 'In Spell Range' : 'Too Far'})`;
  }

  updateMinimap();
  renderer.render(scene, camera);
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

updateHUD();
animate();
