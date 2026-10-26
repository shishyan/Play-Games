# How to publish "Samsara: Journey of Star Seeds" (no Roblox experience needed)

The file to use is **`Samsara-Journey-of-Star-Seeds.rbxl`** (in this folder). It is a Roblox "place file":
it contains all the game's scripts. The world itself (terrain, temple, villages, creatures) is **built by the
scripts when the game starts**, so the file looks almost empty when you open it in the editor. That is normal.

> Honest warning: this game has never been run in Roblox. Play it in Studio (step 3) before you publish,
> and keep it **Private** until you are happy. If something breaks, copy the red text from Studio's
> *Output* window and send it to me.

## 1. Install Roblox Studio (free)
1. Go to **create.roblox.com**, sign in with your Roblox account (create one if needed).
2. Click **Start Creating** to download and install **Roblox Studio**.

## 2. Open the file
Double-click `Samsara-Journey-of-Star-Seeds.rbxl`, or in Studio choose **File → Open from File…** and select it.

## 3. Play-test it
1. Click the green **Play** button (top toolbar, *Home* tab).
2. Wait about **10–20 seconds** — the world is being generated. A panel will appear: choose a fighting
   discipline, then walk to the temple and talk to **Acharya Satyadev**. Press **H** in game for the controls.
3. Press the red **Stop** button when done. Open **View → Output** to see any error messages.

## 4. Publish it
1. **File → Publish to Roblox As…** → **Create new game**.
2. Give it a name (for example *Samsara: Journey of Star Seeds*) and a description, then **Create**.
3. Open **Home → Game Settings** and set:
   - **Security → Enable Studio Access to API Services = ON** (this lets the game save players' progress).
   - **Avatar → Avatar Type = R15**.
   - **Permissions → Private** while testing. Switch to **Public** only when you want others to play.
4. **File → Publish to Roblox** again to save those settings to the cloud.

Your game now lives at **create.roblox.com → Creations**; click it to see its page and share the link.

## Tester shortcuts (in Studio, type these in chat while playing)
`/yuga 1` to `/yuga 4` jump to a Yuga · `/karma 40` · `/path dharma 50` · `/gold 500`.
Example: `/karma 40` then `/path dharma 40` lets you test the Svarga (celestial) gate.

## Updating later
Roblox games are updated by publishing a new version from Studio (File → Publish to Roblox). If I change the
code, I will give you a new `.rbxl` — open it and publish again over the same game.
