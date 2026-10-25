import * as THREE from 'three';

// ============================================================================
// AUDIO SYNTHESIZER (Hordes.io Style Crisp Sound Cues)
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
  playChime(freq = 528, duration = 0.5) {
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
    [520, 650, 780].forEach((f, i) => setTimeout(() => this.playChime(f, 0.4), i * 70));
  }
  playLevelUp() {
    if (!this.ctx) return;
    [440, 554, 659, 880].forEach((f, i) => setTimeout(() => this.playChime(f, 0.8), i * 110));
  }
}
const audio = new SoundEngine();

// ============================================================================
// 1. HORDES.IO 4-CLASS SYSTEM (Adapted for Virtuous World)
// ============================================================================
const CLASSES = {
  vaidya: {
    name: 'Vaidya (Divine Healer)',
    role: 'Restorer of Wildlife & Healer of Beings',
    basePrana: 100,
    basePunya: 120,
    primarySpell: 'Sanjeevani Herbs',
    color: '#10b981'
  },
  palak: {
    name: 'Palak (Guardian Protector)',
    role: 'Sanctifier of Sacred Grounds & Shields',
    basePrana: 140,
    basePunya: 80,
    primarySpell: 'Vajra Shield',
    color: '#3b82f6'
  },
  sadhu: {
    name: 'Sadhu (Mystic Sage)',
    role: 'Channeler of Celestial Ganga Jal',
    basePrana: 90,
    basePunya: 150,
    primarySpell: 'Ganga Jal',
    color: '#a855f7'
  },
  dhanurdhar: {
    name: 'Dhanurdhar (Archer of Light)',
    role: 'Dispeller of Darkness from Afar',
    basePrana: 110,
    basePunya: 100,
    primarySpell: 'Solar Arrow',
    color: '#f59e0b'
  }
};

// ============================================================================
// 2. TEXTURING (Hordes.io Low-Poly Palette & Tiled Steppes)
// ============================================================================
function generateVoxelPaletteTexture() {
  const c = document.createElement('canvas');
  c.width = 256; c.height = 256;
  const ctx = c.getContext('2d');

  ctx.fillStyle = '#3f9642';
  ctx.fillRect(0, 0, 256, 256);

  ctx.strokeStyle = '#327c35';
  ctx.lineWidth = 2;
  for (let i = 0; i <= 256; i += 32) {
    ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 256); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(256, i); ctx.stroke();
  }

  for (let i = 0; i < 35; i++) {
    ctx.fillStyle = Math.random() > 0.5 ? '#fdd835' : '#f472b6';
    ctx.fillRect(Math.floor(Math.random() * 8) * 32 + 14, Math.floor(Math.random() * 8) * 32 + 14, 4, 4);
  }

  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(40, 40);
  return tex;
}

// ============================================================================
// 3. THREE.JS ENGINE SETUP
// ============================================================================
const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x87ceeb);
scene.fog = new THREE.FogExp2(0x87ceeb, 0.002);

const camera = new THREE.PerspectiveCamera(52, window.innerWidth / window.innerHeight, 0.5, 2000);
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.1;
container.appendChild(renderer.domElement);

const sunLight = new THREE.DirectionalLight(0xfffaed, 2.5);
sunLight.position.set(140, 240, 100);
sunLight.castShadow = true;
sunLight.shadow.mapSize.set(2048, 2048);
sunLight.shadow.camera.near = 10;
sunLight.shadow.camera.far = 600;
const d = 180;
sunLight.shadow.camera.left = -d; sunLight.shadow.camera.right = d;
sunLight.shadow.camera.top = d; sunLight.shadow.camera.bottom = -d;
scene.add(sunLight);

const ambientLight = new THREE.HemisphereLight(0xffffff, 0x334155, 1.25);
scene.add(ambientLight);

// ============================================================================
// 4. HORDES.IO MODULAR TERRAIN & ENVIRONMENT
// ============================================================================
const matGround = new THREE.MeshStandardMaterial({
  map: generateVoxelPaletteTexture(),
  roughness: 0.75,
  metalness: 0.05
});

const groundGeo = new THREE.PlaneGeometry(1200, 1200, 64, 64);
groundGeo.rotateX(-Math.PI / 2);

function getTerrainHeight(x, z) {
  let h = Math.sin(x * 0.015) * Math.cos(z * 0.015) * 6;
  return Math.round(h * 2) / 2; // Quantized step height
}

const gPos = groundGeo.attributes.position;
for (let i = 0; i < gPos.count; i++) {
  const vx = gPos.getX(i);
  const vz = gPos.getZ(i);
  gPos.setY(i, getTerrainHeight(vx, vz));
}
groundGeo.computeVertexNormals();

const terrainMesh = new THREE.Mesh(groundGeo, matGround);
terrainMesh.receiveShadow = true;
scene.add(terrainMesh);

// Flowing Sacred Ganga River
const river = new THREE.Mesh(
  new THREE.PlaneGeometry(120, 1000),
  new THREE.MeshStandardMaterial({ color: 0x0284c7, roughness: 0.1, transparent: true, opacity: 0.85 })
);
river.rotation.x = -Math.PI / 2;
river.position.set(-180, 0.35, 0);
scene.add(river);

// Hexagonal Stepped Trees (Hordes.io Signature Foliage)
const matWood = new THREE.MeshStandardMaterial({ color: 0x5d4037, roughness: 0.8 });
const matLeaf = new THREE.MeshStandardMaterial({ color: 0x2e7d32, roughness: 0.7 });
const matLeafLight = new THREE.MeshStandardMaterial({ color: 0x4caf50, roughness: 0.7 });
const matStone = new THREE.MeshStandardMaterial({ color: 0x78909c, roughness: 0.85 });

function createHordesTree(x, z, scale = 1) {
  const tree = new THREE.Group();
  const y = getTerrainHeight(x, z);
  tree.position.set(x, y, z);

  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.5 * scale, 0.7 * scale, 4 * scale, 6), matWood);
  trunk.position.y = 2 * scale;
  trunk.castShadow = true;
  tree.add(trunk);

  for (let i = 0; i < 3; i++) {
    const r1 = (3.2 - i * 0.7) * scale;
    const cone = new THREE.Mesh(new THREE.ConeGeometry(r1, 3.2 * scale, 6), i === 2 ? matLeafLight : matLeaf);
    cone.position.y = (3.6 + i * 2.2) * scale;
    cone.castShadow = true;
    tree.add(cone);
  }
  scene.add(tree);
}

for (let i = 0; i < 48; i++) {
  const ang = Math.random() * Math.PI * 2;
  const d = 30 + Math.random() * 120;
  const tx = Math.cos(ang) * d;
  const tz = Math.sin(ang) * d;
  if (tx > -240 && tx < -120) continue;
  createHordesTree(tx, tz, 0.85 + Math.random() * 0.4);
}

// ============================================================================
// 5. LIVING FOREST ENTITIES & NURTURING INTERACTABLES
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
  const y = getTerrainHeight(x, z);
  group.position.set(x, y, z);

  const body = new THREE.Mesh(new THREE.BoxGeometry(1.8, 1.2, 2.4), new THREE.MeshStandardMaterial({ color: 0xd97706, roughness: 0.6 }));
  body.position.y = 1.0;
  body.castShadow = true;
  group.add(body);

  const head = new THREE.Mesh(new THREE.BoxGeometry(1.0, 1.0, 1.2), new THREE.MeshStandardMaterial({ color: 0xd97706, roughness: 0.6 }));
  head.position.set(0, 1.8, 1.2);
  head.castShadow = true;
  group.add(head);

  const legMat = new THREE.MeshStandardMaterial({ color: 0x92400e });
  [[-0.6, -0.8], [0.6, -0.8], [-0.6, 0.8], [0.6, 0.8]].forEach(([lx, lz]) => {
    const leg = new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.9, 0.3), legMat);
    leg.position.set(lx, 0.45, lz);
    group.add(leg);
  });

  scene.add(group);

  const entity = {
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
  };
  interactables.push(entity);
}

spawnHordesAnimal(16, -12, 'Wounded Vrindavan Fawn', '🦌');
spawnHordesAnimal(-20, 16, 'Injured Golden Fox', '🦊');
spawnHordesAnimal(24, 24, 'Gentle Grove Gazelle', '🦌');

// 6 Sacred Soil Beds
for (let r = 0; r < 2; r++) {
  for (let c = 0; c < 3; c++) {
    const px = (c - 1) * 11;
    const pz = 22 + r * 11;

    const frame = new THREE.Mesh(new THREE.BoxGeometry(6.5, 0.4, 6.5), matStone);
    frame.position.set(px, 0.2, pz);
    scene.add(frame);

    const soilMat = new THREE.MeshStandardMaterial({ color: 0x3e2723, roughness: 0.9 });
    const soil = new THREE.Mesh(new THREE.BoxGeometry(5.8, 0.5, 5.8), soilMat);
    soil.position.set(px, 0.25, pz);
    scene.add(soil);

    const plantGroup = new THREE.Group();
    plantGroup.position.set(px, 0.5, pz);
    scene.add(plantGroup);

    interactables.push({
      id: `bed_${r}_${c}`,
      type: 'garden_plot',
      name: `Sacred Soil Bed #${r * 3 + c + 1}`,
      subtitle: 'Untilled • Press [E] or [2] to Nurture',
      icon: '🌿',
      pos: new THREE.Vector3(px, 0.5, pz),
      stage: 'untilled',
      health: 20,
      soilMat,
      plantGroup
    });
  }
}

// ============================================================================
// 6. PLAYER CONTROLLER & CLASS RIG
// ============================================================================
const playerGroup = new THREE.Group();
playerGroup.position.set(0, 0, 10);
scene.add(playerGroup);

const playerMesh = new THREE.Group();
const tunic = new THREE.Mesh(new THREE.BoxGeometry(1.2, 1.8, 0.8), new THREE.MeshStandardMaterial({ color: 0xe65100, roughness: 0.5 }));
tunic.position.y = 1.4;
tunic.castShadow = true;
playerMesh.add(tunic);

const pHead = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.8, 0.8), new THREE.MeshStandardMaterial({ color: 0xffcc80, roughness: 0.5 }));
pHead.position.y = 2.6;
pHead.castShadow = true;
playerMesh.add(pHead);

// Staff with Glowing Lotus Gem
const staff = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.08, 3.2, 8), matWood);
staff.position.set(0.9, 1.8, 0.2);
const staffGem = new THREE.Mesh(new THREE.SphereGeometry(0.3, 12, 12), new THREE.MeshStandardMaterial({ color: 0x10b981, emissive: 0x10b981, emissiveIntensity: 0.6 }));
staffGem.position.set(0.9, 3.4, 0.2);
playerMesh.add(staff, staffGem);

playerGroup.add(playerMesh);

// Player State
const state = {
  classKey: 'vaidya',
  punya: 480,
  gold: 3450,
  fame: 210,
  prana: 100,
  level: 1,
  selectedTarget: null,
  isFlying: false,
  isCasting: false,
  inventory: [
    { name: 'Sanjeevani Leaf', icon: '🌿', qty: 12 },
    { name: 'Ganga Jal Urn', icon: '💧', qty: 6 },
    { name: 'Prasad Ladoo', icon: '🍲', qty: 8 },
    { name: 'Rudraksha Mala', icon: '📿', qty: 1 }
  ],
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
  if (e.code === 'KeyB') toggleInventory();
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
  targetRing.position.set(item.pos.x, 0.35, item.pos.z);

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
    plot.soilMat.color.setHex(0x2d1a0d);
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
  const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.18, 2.6, 6), new THREE.MeshStandardMaterial({ color: 0x4caf50 }));
  stem.position.y = 1.3;
  plot.plantGroup.add(stem);
  const blossom = new THREE.Mesh(new THREE.DodecahedronGeometry(1.2), new THREE.MeshStandardMaterial({ color: 0xf472b6, emissive: 0xdb2777, emissiveIntensity: 0.5 }));
  blossom.position.y = 2.8;
  plot.plantGroup.add(blossom);
}

function awardPunya(amount) {
  state.punya += amount;
  const req = state.level * 140;
  if (state.punya >= req) {
    state.level++;
    audio.playLevelUp();
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
  audio.playLevelUp();
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

// Inventory Modal
function toggleInventory() {
  const modal = document.getElementById('inventory-modal');
  modal.classList.toggle('modal-backdrop-hidden');
  if (!modal.classList.contains('modal-backdrop-hidden')) {
    renderInventory();
  }
}
document.getElementById('btn-inventory').addEventListener('click', toggleInventory);
document.getElementById('btn-close-inv').addEventListener('click', toggleInventory);

function renderInventory() {
  const grid = document.getElementById('inv-grid');
  grid.innerHTML = '';
  for (let i = 0; i < 16; i++) {
    const item = state.inventory[i];
    const slot = document.createElement('div');
    slot.className = 'inv-slot';
    if (item) {
      slot.innerHTML = `<span class="inv-icon">${item.icon}</span><span class="inv-name">${item.name} (${item.qty})</span>`;
    }
    grid.appendChild(slot);
  }
}

// Minimap Update Loop
const minimapCanvas = document.getElementById('minimap-canvas');
const mmCtx = minimapCanvas.getContext('2d');

function updateMinimap() {
  mmCtx.fillStyle = '#0d1117';
  mmCtx.fillRect(0, 0, 160, 160);

  mmCtx.fillStyle = '#0284c7';
  mmCtx.fillRect(10, 0, 25, 160);

  mmCtx.fillStyle = '#10b981';
  mmCtx.beginPath();
  mmCtx.arc(80, 80, 18, 0, Math.PI * 2);
  mmCtx.fill();

  interactables.forEach((item) => {
    const mx = 80 + (item.pos.x / 1200) * 160;
    const my = 80 + (item.pos.z / 1200) * 160;
    mmCtx.fillStyle = item.type === 'creature' ? '#fbbf24' : '#34d399';
    mmCtx.fillRect(mx - 2, my - 2, 4, 4);
  });

  const px = 80 + (playerGroup.position.x / 1200) * 160;
  const py = 80 + (playerGroup.position.z / 1200) * 160;
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
