# Dharma Sanctuary (धर्म क्षेत्र)
### Open-World Adventure & Virtue Progression Game for Roblox

Built on an open-source open-world architecture inspired by AAA open-world systems (GTA/Sky open realms), modified for **Indian Traditional Virtues**, **Surprise Celestial Gifts**, and **7 Tiers of Character Grades**.

---

## 🏛️ 7 Progressive Spiritual Grades

Players cultivate internal virtue (*Punya*) through their actions across the sanctuary. As virtue deepens, dynamic neon halos, celestial auras, and movement abilities unlock:

| Grade | Rank Name | Sanskrit Title | Required Virtue | Special Perk / Boon |
|---|---|---|---|---|
| **I** | **Seeker (Sadhak)** | जिज्ञासु (*Jijnyasu*) | 0 | Access to basic shrines & daily prayers |
| **II** | **Apprentice of Harmony (Sevak)** | सेवक (*Sevak*) | 100 | Temple Bell resonance, +10% walking grace speed |
| **III** | **Disciple of Righteousness (Dharmik)** | धार्मिक (*Dharmik*) | 300 | Chant of Protection aura, +25% gift discovery |
| **IV** | **Master of Contemplation (Yogi)** | योगी (*Yogi*) | 700 | Lotus levitation jump, double pilgrimage virtue |
| **V** | **Sage of Wisdom (Rishi)** | ऋषि (*Rishi*) | 1,500 | Golden Diya trail, surprise divine boons unlock |
| **VI** | **Legendary Great Soul (Mahatma)** | महात्मा (*Mahatma*) | 3,000 | Divine Solar radiance, global blessing broadcast |
| **VII** | **Supreme Enlightened (Paramahamsa)** | परमहंस (*Paramahamsa*) | 6,000 | Permanent Celestial Halo, Ascended Flight, Max Luck |

---

## 🪔 Traditional Indian Virtues (Pancha & Shada Dharma)

Actions replace standard combat with character refinement and community upliftment:

1. **Satya (सत्य - Truthfulness)**: Resolving disputes justly, adhering to promises.
2. **Ahimsa (अहिंसा - Non-violence & Compassion)**: Feeding street cows, caring for birds, helping injured pilgrims.
3. **Daan (दान - Selfless Charity)**: Offering food (*Annadana*), robes, and coins to monks and pilgrims.
4. **Seva (सेवा - Selfless Service)**: Cleaning sacred temple ghats, placing ghee lamps (*Diyas*).
5. **Dhyana (ध्यान - Meditation & Stillness)**: Prānāyāma breathwork under sacred Banyan trees.
6. **Shanti (शान्ति - Inner Equanimity)**: Pacifying chaotic conflicts and maintaining serenity.

---

## 🎁 Surprise Celestial Gifts & Relics

Every virtuous deed grants a chance to receive divine surprise blessings:
* **Amrita Kalash (Nectar of Immortality)** — *Divine Tier* (+500 Virtue, +1000 Gold, Golden Lotus Aura)
* **Maha Rudraksha Mala (108 Beads)** — *Legendary Tier* (+300 Virtue, +500 Gold, Blue Flame Trishul)
* **Kundalas of Surya Deva** — *Epic Tier* (+180 Virtue, +350 Gold, Sunburst Glow)
* **Mayur Pankh (Sacred Peacock Quill)** — *Rare Tier* (+120 Virtue, +200 Gold)
* **Holy Tulsi Garland of Vrindavan** — *Rare Tier* (+90 Virtue, +150 Gold)
* **Divine Mahaprasadam Thali** — *Common Tier* (+40 Virtue, +75 Gold)

---

## 🛠️ Project Structure

```
DharmaSanctuary/
├── default.project.json       # Rojo workspace configuration
├── src/
│   ├── shared/
│   │   ├── VirtueDefs.luau   # 7 Grades, Virtues, and Gift Defs
│   │   └── ...
│   ├── server/
│   │   ├── Services/
│   │   │   ├── VirtueService.luau  # Core Virtue, Halos, and Gift logic
│   │   │   └── ...
│   │   └── init.server.luau
│   └── client/
│       ├── Controllers/
│       │   ├── VirtueController.luau  # HUD, Action dock, and Gift modal UI
│       │   └── ...
│       └── init.client.luau
```

## 🚀 How to Run & Build
1. Open the directory in **Roblox Studio** or sync with **Rojo**:
   ```bash
   rojo serve
   ```
2. In Roblox Studio, connect via the Rojo plugin to sync all scripts into `ReplicatedStorage`, `ServerScriptService`, and `StarterPlayerScripts`.
