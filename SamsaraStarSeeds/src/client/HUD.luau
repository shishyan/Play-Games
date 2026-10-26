--!nonstrict
-- The heads-up display: vitals, the four Purusharthas, Karma meter, Yuga/Rta, hotbar, target, quests, toasts.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Dhanurveda = require(Shared.Dhanurveda)
local Purusharthas = require(Shared.Purusharthas)
local Karma = require(Shared.Karma)
local Quests = require(Shared.Quests)
local QuestDefs = require(Shared.QuestDefs)
local Ayurveda = require(Shared.Ayurveda)
local Yuga = require(Shared.Yuga)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Target = require(script.Parent.Target)

local HUD = {}
local C = UI.colors

local player = Players.LocalPlayer
local els: any = {}
local slots: any = {}
local cooldowns: { [number]: { untilT: number, dur: number } } = {}

local PATH_ORDER = { "dharma", "artha", "kama", "moksha" }
local PATH_NAMES = { dharma = "Dharma", artha = "Artha", kama = "Kama", moksha = "Moksha" }

---------------------------------------------------------------- toasts
local toastColors = {
	info = C.text, xp = C.moksha, gold = C.goldBright, level = C.goldBright, karma_good = C.good, karma_bad = C.danger,
	warn = C.danger, quest = Color3.fromRGB(120, 200, 255), loot = Color3.fromRGB(150, 230, 170), path = C.goldBright,
	path_dharma = C.dharma, path_artha = C.artha, path_kama = C.kama, path_moksha = C.moksha,
}

function HUD.toast(text: string, kind: string?)
	if not els.toasts then
		return
	end
	local l = UI.label(els.toasts, text, UDim2.new(1, 0, 0, 22), UDim2.new(), {
		color = toastColors[kind or "info"] or C.text, font = UI.fonts.hudBold, textSize = 17, xAlign = Enum.TextXAlignment.Center, stroke = 0.25, wrap = true,
	})
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Size = UDim2.new(1, 0, 0, 0)
	l.LayoutOrder = -math.floor(os.clock() * 100)
	task.delay(5.5, function()
		for i = 1, 10 do
			if not l.Parent then
				return
			end
			l.TextTransparency = i / 10
			l.TextStrokeTransparency = 0.25 + i * 0.07
			task.wait(0.05)
		end
		l:Destroy()
	end)
	local kids = els.toasts:GetChildren()
	if #kids > 9 then
		kids[1]:Destroy()
	end
end

---------------------------------------------------------------- hotbar
local function slotAbility(snap, index: number): any
	if index <= 3 then
		local id = Dhanurveda.loadout(snap.class, snap.stance)[index]
		local ab = Dhanurveda.Abilities[id]
		return { id = id, name = ab.name, icon = ab.icon, kind = "ability", desc = ab.desc, cd = ab.cd }
	elseif index <= 6 then
		local id = Dhanurveda.AstraOrder[index - 3]
		local a = Dhanurveda.Astras[id]
		return { id = id, name = a.name, icon = a.icon, kind = "astra", desc = a.desc, cd = a.cd }
	elseif index == 7 then
		return { id = "remedy", name = "Remedy", icon = "🌿", kind = "remedy", desc = "Use the best crafted remedy for your worst imbalance.", cd = 1 }
	end
	return { id = "amrita", name = "Amrita", icon = "🧪", kind = "amrita", desc = "Restore 70 health. Breaks a Vrata.", cd = 1 }
end

function HUD.slotInfo(snap, index: number)
	return slotAbility(snap, index)
end

function HUD.startCooldown(index: number, seconds: number)
	cooldowns[index] = { untilT = os.clock() + seconds, dur = seconds }
end

local function buildHotbar()
	if els.hotbar then
		els.hotbar:Destroy()
	end
	local bar = UI.frame(UI.root, UDim2.fromOffset(8 * 62 + 12, 76), UDim2.new(0.5, 0, 1, -8), {
		anchor = Vector2.new(0.5, 1), name = "Hotbar", transparency = 0.3,
	})
	els.hotbar = bar
	slots = {}
	for i = 1, 8 do
		local s = Instance.new("TextButton")
		s.Name = "Slot" .. i
		s.Size = UDim2.fromOffset(58, 64)
		s.Position = UDim2.fromOffset(6 + (i - 1) * 62, 6)
		s.BackgroundColor3 = C.slate2
		s.BorderSizePixel = 0
		s.Text = ""
		s.AutoButtonColor = true
		s.Parent = bar
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = s
		local stroke = Instance.new("UIStroke")
		stroke.Color = i >= 4 and i <= 6 and C.moksha or C.gold
		stroke.Thickness = 1.5
		stroke.Parent = s
		local icon = UI.label(s, "", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 6), { xAlign = Enum.TextXAlignment.Center, textSize = 26, stroke = 1 })
		local key = UI.label(s, tostring(i), UDim2.fromOffset(16, 14), UDim2.fromOffset(3, 1), { textSize = 12, color = C.goldBright, font = UI.fonts.hudBold })
		local name = UI.label(s, "", UDim2.new(1, -2, 0, 14), UDim2.new(0, 1, 1, -16), { xAlign = Enum.TextXAlignment.Center, textSize = 10, color = C.dim })
		local cd = Instance.new("Frame")
		cd.Name = "CD"
		cd.Size = UDim2.fromScale(1, 0)
		cd.AnchorPoint = Vector2.new(0, 1)
		cd.Position = UDim2.fromScale(0, 1)
		cd.BackgroundColor3 = Color3.new(0, 0, 0)
		cd.BackgroundTransparency = 0.45
		cd.BorderSizePixel = 0
		cd.ZIndex = 5
		cd.Parent = s
		local count = UI.label(s, "", UDim2.fromOffset(30, 14), UDim2.new(1, -31, 0, 2), { xAlign = Enum.TextXAlignment.Right, textSize = 12, color = C.text, font = UI.fonts.hudBold })
		slots[i] = { button = s, icon = icon, name = name, cd = cd, count = count, key = key }
	end
end

function HUD.onSlot(callback: (number) -> ())
	for i, s in pairs(slots) do
		s.button.Activated:Connect(function()
			callback(i)
		end)
	end
end

---------------------------------------------------------------- build
function HUD.build()
	els.vitals = UI.frame(UI.root, UDim2.fromOffset(280, 104), UDim2.fromOffset(12, 12), { name = "Vitals" })
	els.classIcon = UI.label(els.vitals, "", UDim2.fromOffset(42, 42), UDim2.fromOffset(8, 6), { textSize = 32, xAlign = Enum.TextXAlignment.Center })
	els.classText = UI.label(els.vitals, "", UDim2.fromOffset(220, 20), UDim2.fromOffset(54, 5), { font = UI.fonts.title, textSize = 17, color = C.goldBright })
	els.weaponText = UI.label(els.vitals, "", UDim2.fromOffset(220, 16), UDim2.fromOffset(54, 24), { textSize = 12, color = C.dim })
	els.hp = UI.bar(els.vitals, UDim2.fromOffset(264, 20), UDim2.fromOffset(8, 46), C.hp)
	els.stamina = UI.bar(els.vitals, UDim2.fromOffset(264, 14), UDim2.fromOffset(8, 70), C.stamina, { textSize = 11 })
	els.status = UI.label(els.vitals, "", UDim2.fromOffset(264, 14), UDim2.fromOffset(8, 87), { textSize = 11, color = C.danger })

	els.target = UI.frame(UI.root, UDim2.fromOffset(280, 62), UDim2.fromOffset(12, 122), { name = "Target" })
	els.target.Visible = false
	els.targetName = UI.label(els.target, "", UDim2.fromOffset(264, 18), UDim2.fromOffset(8, 4), { font = UI.fonts.title, textSize = 16 })
	els.targetHp = UI.bar(els.target, UDim2.fromOffset(264, 16), UDim2.fromOffset(8, 24), C.hpLow)
	els.targetPower = UI.bar(els.target, UDim2.fromOffset(264, 5), UDim2.fromOffset(8, 42), Color3.fromRGB(80, 140, 255))
	els.targetTag = UI.label(els.target, "", UDim2.fromOffset(264, 12), UDim2.fromOffset(8, 48), { textSize = 11, color = C.goldBright })

	els.buffs = Instance.new("Frame")
	els.buffs.BackgroundTransparency = 1
	els.buffs.Size = UDim2.fromOffset(280, 26)
	els.buffs.Position = UDim2.fromOffset(12, 190)
	els.buffs.Parent = UI.root
	UI.list(els.buffs, 4, true)

	-- top centre: karma + yuga
	els.top = UI.frame(UI.root, UDim2.fromOffset(440, 84), UDim2.new(0.5, 0, 0, 8), { anchor = Vector2.new(0.5, 0), name = "TopCenter" })
	UI.label(els.top, "ASURA", UDim2.fromOffset(50, 14), UDim2.fromOffset(8, 4), { textSize = 11, color = C.danger, font = UI.fonts.hudBold })
	UI.label(els.top, "DEVA", UDim2.fromOffset(50, 14), UDim2.new(1, -58, 0, 4), { textSize = 11, color = C.goldBright, font = UI.fonts.hudBold, xAlign = Enum.TextXAlignment.Right })
	els.karmaText = UI.label(els.top, "", UDim2.fromOffset(300, 14), UDim2.new(0.5, 0, 0, 4), { anchor = Vector2.new(0.5, 0), xAlign = Enum.TextXAlignment.Center, textSize = 12, color = C.text })
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -16, 0, 10)
	track.Position = UDim2.fromOffset(8, 20)
	track.BorderSizePixel = 0
	track.BackgroundColor3 = Color3.new(1, 1, 1)
	track.Parent = els.top
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 40, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 130)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 210, 70)),
	})
	grad.Parent = track
	els.karmaPointer = Instance.new("Frame")
	els.karmaPointer.Size = UDim2.fromOffset(4, 18)
	els.karmaPointer.AnchorPoint = Vector2.new(0.5, 0.5)
	els.karmaPointer.Position = UDim2.fromScale(0.5, 0.5)
	els.karmaPointer.BackgroundColor3 = Color3.new(1, 1, 1)
	els.karmaPointer.BorderSizePixel = 0
	els.karmaPointer.Parent = track
	els.yugaText = UI.label(els.top, "", UDim2.new(1, -16, 0, 16), UDim2.fromOffset(8, 34), { font = UI.fonts.title, textSize = 16, color = C.goldBright, xAlign = Enum.TextXAlignment.Center })
	els.rta = UI.bar(els.top, UDim2.new(1, -16, 0, 11), UDim2.fromOffset(8, 54), C.good, { textSize = 10 })
	els.wind = UI.label(els.top, "", UDim2.new(1, -16, 0, 12), UDim2.fromOffset(8, 68), { textSize = 10, color = C.dim, xAlign = Enum.TextXAlignment.Center })

	-- top right: paths + quest tracker
	els.paths = UI.frame(UI.root, UDim2.fromOffset(250, 118), UDim2.new(1, -12, 0, 12), { anchor = Vector2.new(1, 0), name = "Paths" })
	els.pathBars = {}
	for i, path in ipairs(PATH_ORDER) do
		local y = 6 + (i - 1) * 27
		UI.label(els.paths, PATH_NAMES[path], UDim2.fromOffset(56, 14), UDim2.fromOffset(8, y), { textSize = 12, color = C[path], font = UI.fonts.hudBold })
		els.pathBars[path] = UI.bar(els.paths, UDim2.fromOffset(176, 12), UDim2.fromOffset(66, y + 1), C[path], { textSize = 10 })
		els.pathBars[path].tier = UI.label(els.paths, "", UDim2.fromOffset(176, 11), UDim2.fromOffset(66, y + 14), { textSize = 9, color = C.dim })
	end
	els.tracker = UI.frame(UI.root, UDim2.fromOffset(250, 20), UDim2.new(1, -12, 0, 138), { anchor = Vector2.new(1, 0), name = "Tracker", transparency = 0.4 })
	els.tracker.AutomaticSize = Enum.AutomaticSize.Y
	UI.pad(els.tracker, 6)
	UI.list(els.tracker, 3)

	els.toasts = Instance.new("Frame")
	els.toasts.BackgroundTransparency = 1
	els.toasts.Size = UDim2.fromOffset(520, 220)
	els.toasts.AnchorPoint = Vector2.new(0.5, 0)
	els.toasts.Position = UDim2.new(0.5, 0, 0, 100)
	els.toasts.Parent = UI.root
	UI.list(els.toasts, 2)

	buildHotbar()

	els.hint = UI.label(UI.root, "WASD move · Space jump · LMB attack (hold to draw a bow) · 1-3 skills · 4-6 Astras · 7 remedy · 8 Amrita · V pacify · Tab target · C B L panels · H help", UDim2.new(1, -20, 0, 14), UDim2.new(0, 10, 1, -92), { textSize = 11, color = C.dim, stroke = 0.4 })
end

---------------------------------------------------------------- refresh
local function refreshTracker(snap)
	UI.clear(els.tracker)
	UI.label(els.tracker, "QUESTS", UDim2.new(1, 0, 0, 14), UDim2.new(), { font = UI.fonts.title, textSize = 14, color = C.goldBright })
	local any = false
	local ids = {}
	for qid, q in pairs(snap.quests) do
		if q.state ~= "done" then
			table.insert(ids, qid)
		end
	end
	table.sort(ids)
	for _, qid in ipairs(ids) do
		local q = snap.quests[qid]
		local def = QuestDefs[qid]
		any = true
		local ready = q.state == "ready"
		local l = UI.label(els.tracker, (ready and "✔ " or "• ") .. def.name .. "\n" .. (ready and ("Return to " .. def.turnIn) or Quests.progressText(qid, q)), UDim2.new(1, 0, 0, 0), UDim2.new(), {
			textSize = 12, color = ready and C.good or C.text, wrap = true,
		})
		l.AutomaticSize = Enum.AutomaticSize.Y
	end
	if not any then
		UI.label(els.tracker, "Speak with Acharya Satyadev\nnear the temple.", UDim2.new(1, 0, 0, 30), UDim2.new(), { textSize = 12, color = C.dim, wrap = true })
	end
end

local function refreshBuffs(snap)
	UI.clear(els.buffs)
	local now = workspace:GetServerTimeNow()
	for _, b in ipairs(snap.buffs) do
		local remaining = b.untilT - now
		if remaining > 0 then
			local f = UI.frame(els.buffs, UDim2.fromOffset(60, 24), UDim2.new(), { transparency = 0.3, strokeColor = C.good })
			UI.label(f, b.icon .. " " .. math.ceil(remaining) .. "s", UDim2.fromScale(1, 1), UDim2.new(), { textSize = 12, xAlign = Enum.TextXAlignment.Center })
			f.Name = b.name
		end
	end
end

local function refreshSlots(snap)
	for i = 1, 8 do
		local s = slots[i]
		local info = slotAbility(snap, i)
		s.icon.Text = info.icon
		s.name.Text = info.name
		local locked = false
		if info.kind == "astra" then
			local ok = Purusharthas.canAstra(snap.paths, info.id)
			locked = not ok
			if locked then
				local gate = Purusharthas.ASTRA_GATES[info.id]
				s.name.Text = ("%s %d"):format(PATH_NAMES[gate.path], gate.need)
			end
		end
		s.button.BackgroundColor3 = locked and Color3.fromRGB(20, 20, 26) or C.slate2
		s.icon.TextTransparency = locked and 0.6 or 0
		s.count.Text = info.kind == "amrita" and tostring(snap.inv.amrita or 0) or (info.kind == "remedy" and tostring(#snap.remedies) or "")
	end
end

function HUD.refresh(snap)
	if not snap or not els.vitals then
		return
	end
	local class = Dhanurveda.Classes[snap.class]
	local weapon = Dhanurveda.Weapons[snap.weapon]
	els.classIcon.Text = class.icon
	els.classText.Text = class.name .. (snap.debt and snap.debt.stage ~= "done" and "  (Spiritual Debt)" or "")
	local dur = math.floor(snap.durability)
	els.weaponText.Text = ("%s  T%d  ·  durability %d%%%s"):format(weapon.name, snap.weaponTier, dur, snap.tamas and "  ·  Tamas!" or "")
	UI.setBar(els.stamina, snap.stamina / snap.maxStamina, ("Stamina %d / %d"):format(snap.stamina, snap.maxStamina))
	for _, path in ipairs(PATH_ORDER) do
		local v = snap.paths[path]
		UI.setBar(els.pathBars[path], v / 100, ("%d"):format(math.floor(v)))
		els.pathBars[path].tier.Text = Purusharthas.TIER_NAMES[Purusharthas.tier(v)]
	end
	els.karmaPointer.Position = UDim2.fromScale((snap.karma + 100) / 200, 0.5)
	els.karmaText.Text = ("Karma %d  ·  %s path  ·  Samsara cycle %d"):format(math.floor(snap.karma + 0.5), Karma.path(snap.karma), snap.cycles)
	refreshTracker(snap)
	refreshBuffs(snap)
	refreshSlots(snap)
end

local function refreshTarget()
	local model = Target.get()
	if not model or not model.Parent then
		els.target.Visible = false
		return
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		els.target.Visible = false
		return
	end
	els.target.Visible = true
	els.targetName.Text = model:GetAttribute("Display") or model.Name
	local frac = hum.Health / hum.MaxHealth
	UI.setBar(els.targetHp, frac, ("%d / %d"):format(math.ceil(hum.Health), math.ceil(hum.MaxHealth)))
	els.targetHp.fill.BackgroundColor3 = model:GetAttribute("Peaceful") and C.good or C.hpLow
	UI.setBar(els.targetPower, model:GetAttribute("Power") or 0)
	if model:GetAttribute("Corrupt") and frac <= 0.4 then
		els.targetTag.Text = "Weakened — press V to pacify with a mantra (mercy earns Dharma)"
	elseif model:GetAttribute("Shielded") then
		els.targetTag.Text = "Energy-shielded — Khanda cuts shields; Astras pierce them"
	elseif model:GetAttribute("Peaceful") then
		els.targetTag.Text = "Sacred creature — harming it breaks ahimsa"
	else
		els.targetTag.Text = ""
	end
end

---------------------------------------------------------------- per-frame
function HUD.start()
	State.changed:Connect(HUD.refresh)
	Target.changed:Connect(refreshTarget)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		-- vitals follow the humanoid every frame; heavier text at 10 Hz
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and els.hp then
			UI.setBar(els.hp, hum.Health / math.max(1, hum.MaxHealth), ("%d / %d"):format(math.ceil(hum.Health), math.ceil(hum.MaxHealth)))
			els.hp.fill.BackgroundColor3 = (hum.Health / hum.MaxHealth) < 0.3 and C.hpLow or C.hp
		end
		local now = os.clock()
		for i, s in pairs(slots) do
			local cd = cooldowns[i]
			if cd and cd.untilT > now then
				s.cd.Size = UDim2.fromScale(1, (cd.untilT - now) / cd.dur)
			else
				s.cd.Size = UDim2.fromScale(1, 0)
			end
		end
		if acc < 0.1 then
			return
		end
		acc = 0
		local snap = State.get()
		refreshTarget()
		if snap then
			local idx = workspace:GetAttribute("YugaIndex") or 1
			local remaining = workspace:GetAttribute("YugaRemaining") or 0
			els.yugaText.Text = ("%s  ·  %d:%02d remaining"):format(workspace:GetAttribute("YugaName") or "Satya Yuga", math.floor(remaining / 60), remaining % 60)
			local epoch = Yuga.EPOCHS[idx]
			if epoch then
				els.yugaText.TextColor3 = ({ Color3.fromRGB(255, 225, 120), Color3.fromRGB(255, 190, 110), Color3.fromRGB(230, 150, 190), Color3.fromRGB(190, 140, 255) })[idx]
			end
			local rta = workspace:GetAttribute("Rta") or 0
			UI.setBar(els.rta, (rta + 100) / 200, ("Rta of the world: %+d"):format(math.floor(rta)))
			els.rta.fill.BackgroundColor3 = rta >= 0 and C.good or C.danger
			local wx, wz = workspace:GetAttribute("WindX") or 0, workspace:GetAttribute("WindZ") or 0
			els.wind.Text = ("Wind %.1f  %s"):format(math.sqrt(wx * wx + wz * wz), math.abs(wx) + math.abs(wz) < 0.2 and "calm" or (wx > 0 and "→ east" or "← west"))
			local dominant, level = Ayurveda.dominant(snap.doshas)
			if dominant then
				els.status.Text = ("Dosha imbalance: %s %d%%  (craft a remedy at the Vaidya's table)"):format(dominant:sub(1, 1):upper() .. dominant:sub(2), math.floor(level))
				els.status.TextColor3 = C[dominant]
			else
				els.status.Text = snap.debt and snap.debt.stage ~= "done" and (snap.debt.stage == "carry" and ("Carrying water: %d%% — walk gently"):format(snap.debt.water) or "Debt: draw water at the step-well") or ""
				els.status.TextColor3 = C.goldBright
			end
			refreshBuffs(snap)
		end
	end)
end

return HUD
