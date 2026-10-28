--!nonstrict
-- Menu panels: class selection, character, bags & remedies, quest log, alchemy table, help, ending.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Dhanurveda = require(Shared.Dhanurveda)
local Purusharthas = require(Shared.Purusharthas)
local Karma = require(Shared.Karma)
local Ayurveda = require(Shared.Ayurveda)
local ItemDefs = require(Shared.ItemDefs)
local QuestDefs = require(Shared.QuestDefs)
local Quests = require(Shared.Quests)
local Yuga = require(Shared.Yuga)
local LokaDefs = require(Shared.LokaDefs)
local GurukulaDefs = require(Shared.GurukulaDefs)
local Remotes = require(Shared.Remotes)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Input = require(script.Parent.Input)
local Effects = require(script.Parent.Effects)

local Panels = {}
local C = UI.colors

local window: Frame
local body: ScrollingFrame
local titleLabel: TextLabel
local current: string? = nil
local alchemySel: { string } = {}

local PATHS = { "dharma", "artha", "kama", "moksha" }
local PATH_LABEL = { dharma = "Dharma — duty & harmony", artha = "Artha — prosperity", kama = "Kama — vitality & art", moksha = "Moksha — liberation" }

local function line(text: string, color: Color3?, size: number?, font: Enum.Font?): TextLabel
	local l = UI.label(body, text, UDim2.new(1, -12, 0, 0), UDim2.new(), {
		color = color or C.text, textSize = size or 16, font = font or UI.fonts.body, wrap = true, stroke = 1, rich = true,
	})
	l.AutomaticSize = Enum.AutomaticSize.Y
	return l
end

local function gap(px: number)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, px)
	f.BackgroundTransparency = 1
	f.Parent = body
end

local function openWindow(title: string)
	titleLabel.Text = title
	if not window.Visible then
		Effects.sound("panel_open")
	end
	window.Visible = true
	Input.setBlocked(true)
	UI.clear(body)
end

function Panels.close()
	if window.Visible then
		Effects.sound("panel_close")
	end
	window.Visible = false
	current = nil
	Input.setBlocked(false)
end

---------------------------------------------------------------- individual panels
local function classSelect()
	openWindow("Choose Your Dhanurveda Discipline")
	current = "classSelect"
	line("You are a Star Seed — a soul seeded into the world to keep Rta (cosmic order) in balance. There are no levels here: you grow along four Purusharthas by what you do. First, choose how you fight. You can retrain later with Guru Kripa.", C.text, 17)
	gap(8)
	for _, name in ipairs(Dhanurveda.ClassOrder) do
		local c = Dhanurveda.Classes[name]
		line(("<b>%s %s</b>"):format(c.icon, c.title), C.goldBright, 20, UI.fonts.title)
		line(c.blurb, C.dim, 15)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -12, 0, 34)
		row.Parent = body
		UI.list(row, 8, true)
		for _, wid in ipairs(c.weapons) do
			local w = Dhanurveda.Weapons[wid]
			UI.button(row, w.icon .. " Take up the " .. w.name, UDim2.fromOffset(260, 32), UDim2.new(), function()
				Remotes.get("ChooseClass"):FireServer(name, wid)
				Panels.close()
			end, { textSize = 14 })
		end
		gap(8)
	end
end

local function character()
	local s = State.get()
	if not s then
		return
	end
	local curStage, nextStage, effLevel = GurukulaDefs.gradeFor(s.paths, s.legacy)
	openWindow(("Gurukula & Character — %s (%s)"):format(curStage.code, curStage.title))
	current = "character"
	line(("<b>🎓 Current Enrollment: %s — %s</b>  ·  <i>%s</i>"):format(curStage.code, curStage.title, curStage.paruvam), C.goldBright, 19, UI.fonts.title)
	line(("<b>Zone on Earth (Bhumi):</b> %s  ·  <b>Gurukula Level:</b> %d%s"):format(
		curStage.zoneName,
		effLevel,
		nextStage and ("  (Next: %s at Level %d)"):format(nextStage.code, nextStage.minTotalLevels) or "  (Supreme Sovereign Stage)"
	), C.good, 15)
	line(curStage.summary, C.text, 15)
	gap(6)
	line("<b>📚 The 7 Sacred Ashram Books (GuruKulaDesam.com)</b>", C.goldBright, 18, UI.fonts.title)
	for _, book in ipairs(GurukulaDefs.AshramBooks) do
		local unlocked = table.find(curStage.booksUnlocked, book.id) ~= nil
		line(("%s <b>Book %d: %s (%s)</b> — %s · <i>%s</i>"):format(
			unlocked and "📖" or "🔒",
			book.number,
			book.translit,
			book.tamilName,
			book.englishName,
			book.virtueFocus
		), unlocked and book.color or C.dim, 14)
	end
	gap(6)
	line("<b>The Four Purusharthas</b>", C.goldBright, 18, UI.fonts.title)
	for _, path in ipairs(PATHS) do
		local v = s.paths[path]
		line(("<b>%s</b>   %d / 100   ·   <i>%s</i>"):format(PATH_LABEL[path], math.floor(v), Purusharthas.TIER_NAMES[Purusharthas.tier(v)]), C[path], 18, UI.fonts.hudBold)
	end
	local stats = Purusharthas.stats(s.paths)
	gap(6)
	line("<b>What your practice gives you</b>", C.goldBright, 18, UI.fonts.title)
	line(("Kavacha (spiritual armour): %d%% damage reduction  ·  Corruption resistance: %d%%"):format(math.floor(stats.kavacha * 100 + 0.5), math.floor(stats.corruptionResist * 100 + 0.5)), C.dharma)
	line(("Craft tier %d (Artha)  ·  Gold bonus +%d%%"):format(math.min(4, 1 + Purusharthas.tier(s.paths.artha)), math.floor((stats.goldMult - 1) * 100 + 0.5)), C.artha)
	line(("Stamina %d  ·  Move speed +%d%%  ·  Lotus footprints at Kama 40%s"):format(math.floor(stats.maxStamina), math.floor((stats.speedMult - 1) * 100 + 0.5), s.paths.kama >= 40 and " ✔" or ""), C.kama)
	line(("Moksha: %s"):format(s.paths.moksha > 0 and "growing" or (Purusharthas.mokshaUnlocked(s.paths) and "unlocked — seek the Yogi" or "locked until Dharma, Artha and Kama each reach 20")), C.moksha)
	gap(6)
	line("<b>Astras</b>", C.goldBright, 18, UI.fonts.title)
	for _, id in ipairs(Dhanurveda.AstraOrder) do
		local a = Dhanurveda.Astras[id]
		local ok, why = Purusharthas.canAstra(s.paths, id)
		line(("%s %s — %s"):format(a.icon, a.name, ok and "ready" or (why or "locked")), ok and C.good or C.dim)
	end
	gap(6)
	line("<b>Karma &amp; the wheel</b>", C.goldBright, 18, UI.fonts.title)
	line(("Karma %d (%s path)  ·  Anrita acts: %d  ·  Samsara cycles: %d  ·  Legacy: %d"):format(math.floor(s.karma + 0.5), Karma.path(s.karma), s.anrita, s.cycles, s.legacy), C.text)
	line(("Lifetime gold earned %d  ·  given as Dana %d  (%d%%)"):format(s.goldEarned, s.danaGiven, s.goldEarned > 0 and math.floor(s.danaGiven / s.goldEarned * 100) or 0), s.tamas and C.danger or C.text)
	if s.tamas then
		line(("TAMAS: you hoard wealth. Your weapon decays and hits weaker. Give %d more gold as Dana to the community fund (Sadhvi Maitreyi)."):format(s.danaOwed), C.danger)
	end
	local y = Yuga.EPOCHS[workspace:GetAttribute("YugaIndex") or 1]
	gap(6)
	line(("<b>%s</b> — %s"):format(y.name, y.blurb), C.goldBright, 16)
	local decId = workspace:GetAttribute("Decree") or "aranya_raksha"
	local dec = LokaDefs.Decrees[decId]
	if dec then
		line(("<b>Regional Decree:</b> %s — %s"):format(dec.name, dec.desc), C.artha, 15)
	end
	local mountList = {}
	for mid in pairs(s.mounts or {}) do
		if LokaDefs.Mounts[mid] then
			table.insert(mountList, LokaDefs.Mounts[mid].name)
		end
	end
	line(("<b>Attuned Mounts (press M):</b> %s"):format(#mountList > 0 and table.concat(mountList, ", ") or "None yet — approach a wild Ashva or Marut Stag on Bhumi"), C.kama, 15)
end

local function bags()
	local s = State.get()
	if not s then
		return
	end
	openWindow("Bags & Remedies")
	current = "bags"
	line(("Gold: %d"):format(s.gold), C.goldBright, 18, UI.fonts.hudBold)
	gap(4)
	local ids = {}
	for id in pairs(s.inv) do
		table.insert(ids, id)
	end
	table.sort(ids)
	if #ids == 0 then
		line("Your bag is empty.", C.dim)
	end
	for _, id in ipairs(ids) do
		local def = ItemDefs[id]
		line(("%s <b>%s</b> × %d — %s"):format(def.icon, def.name, s.inv[id], def.desc), C.text, 15)
	end
	gap(8)
	line("<b>Remedies (crafted at the Vaidya's table)</b>", C.goldBright, 18, UI.fonts.title)
	if #s.remedies == 0 then
		line("None yet. Gather herbs and combine two at the alchemy table.", C.dim)
	end
	for _, r in ipairs(s.remedies) do
		line(("🧪 %s — treats %s  (V %+.1f · P %+.1f · K %+.1f)"):format(r.name, r.targets, r.cure.vata, r.cure.pitta, r.cure.kapha), C.text, 15)
	end
	gap(6)
	UI.button(body, "Use the best remedy now (key 7)", UDim2.fromOffset(300, 32), UDim2.new(), function()
		Remotes.get("UseRemedy"):FireServer()
	end, { textSize = 14 })
end

local function questLog()
	local s = State.get()
	if not s then
		return
	end
	openWindow("Quest Log")
	current = "quests"
	local ids = {}
	for qid in pairs(s.quests) do
		table.insert(ids, qid)
	end
	table.sort(ids)
	if #ids == 0 then
		line("No quests yet. Speak with Acharya Satyadev near the temple.", C.dim)
	end
	for _, qid in ipairs(ids) do
		local q = s.quests[qid]
		local def = QuestDefs[qid]
		local mark = q.state == "done" and "✔" or (q.state == "ready" and "❗" or "•")
		line(("%s <b>%s</b>"):format(mark, def.name), q.state == "done" and C.dim or C.goldBright, 18, UI.fonts.hudBold)
		if q.state ~= "done" then
			line(def.text, C.text, 15)
			line(q.state == "ready" and ("Ready — return to " .. def.turnIn) or Quests.progressText(qid, q), q.state == "ready" and C.good or C.dim, 14)
		end
		gap(4)
	end
end

local function alchemy()
	local s = State.get()
	if not s then
		return
	end
	openWindow("Alchemy Table — Pancha Mahabhuta")
	current = "alchemy"
	line("Pick TWO herbs. Elements decide the remedy: <b>Kapha</b> = Earth+Water, <b>Pitta</b> = Fire+Water, <b>Vata</b> = Air+Space. Warm, pungent herbs clear Kapha; cooling, bitter herbs calm Pitta; grounding herbs settle Vata. Choose wrongly and you worsen another humor.", C.text, 15)
	gap(6)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -12, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Parent = body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(190, 56)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.Parent = row
	for id, herb in pairs(Ayurveda.Herbs) do
		local have = s.inv[id] or 0
		local els = {}
		for e, n in pairs(herb.elements) do
			table.insert(els, e:sub(1, 1):upper() .. e:sub(2) .. n)
		end
		table.sort(els)
		local selected = table.find(alchemySel, id) ~= nil
		local b = UI.button(row, ("%s %s ×%d\n%s"):format(herb.icon, herb.name, have, table.concat(els, " ")), UDim2.new(), UDim2.new(), function()
			local i = table.find(alchemySel, id)
			if i then
				table.remove(alchemySel, i)
			elseif #alchemySel < 2 then
				table.insert(alchemySel, id)
			end
			alchemy()
		end, { textSize = 13, color = have > 0 and C.text or C.dim, bg = selected and Color3.fromRGB(70, 56, 20) or C.slate2 })
		b.Active = have > 0
	end
	gap(8)
	if #alchemySel == 2 then
		local remedy = Ayurveda.craft(alchemySel[1], alchemySel[2])
		line(("<b>%s</b>"):format(remedy.name), C.goldBright, 18, UI.fonts.hudBold)
		line(("Treats <b>%s</b>   (Vata %+.1f · Pitta %+.1f · Kapha %+.1f)"):format(remedy.targets, remedy.cure.vata, remedy.cure.pitta, remedy.cure.kapha), C.text, 15)
		local enough = (s.inv[alchemySel[1]] or 0) >= (alchemySel[1] == alchemySel[2] and 2 or 1) and (s.inv[alchemySel[2]] or 0) >= 1
		UI.button(body, enough and "Craft remedy" or "Not enough herbs", UDim2.fromOffset(220, 34), UDim2.new(), function()
			if enough then
				Remotes.get("CraftRemedy"):FireServer(alchemySel[1], alchemySel[2])
				alchemySel = {}
				task.delay(0.5, alchemy)
			end
		end, { textSize = 15 })
	else
		line("Select two herbs (you can pick the same herb twice).", C.dim, 15)
	end
end

local function help()
	openWindow("GuruKulaDesam — Virtual School of Dharmic Life")
	current = "help"
	local text = {
		"<b>Motto: \"Living Dharma is Nirvana\" (இல்லற தர்மமே நிர்வாணம்).</b> Welcome to GuruKulaDesam on Earth (Bhumi) — a realistic Virtual School of Dharmic Life where you progress one grade at a time through Dharmic Virtues and strict Ahimsa (Non-Killing).",
		"<b>Academic &amp; Spiritual Ladder on Earth.</b> Every soul starts at <b>Pre-School (Mazhalai Balavihar)</b> &amp; <b>Grade 1 (Prathama Kaksha)</b>, then advances through <b>Grades 2–12</b>, <b>B.A. (Snataka)</b>, <b>M.A. (Acharya)</b>, <b>Ph.D. (Vidyavaridhi)</b>, the <b>Antar-Yuddha Inner Dungeon</b>, and the <b>Dharma Rajya Kingdom</b>. Visit the Pre-School Sand Slate, the Grade 1 Olai Chuvadi Desk, and the Campus Avenue of Grade Gates!",
		"<b>The 14 Non-Human Realms + Earth.</b> Earth (Bhumi) is the human Gurukula. Above Earth rise the <b>7 Upper Lokas</b> (Bhur, Bhuvar, Svar, Mahar, Janar, Tapar, Satya) and below lie the <b>7 Lower Talas</b> (Atala, Vitala, Sutala, Talatala, Mahatala, Rasatala, Patala). Inspect the <b>Brahmanda Stambha Observatory</b> east of the temple to study all 14 realms.",
		"<b>100% Ahimsa (Kollaamai — Non-Killing).</b> As Thirukkural Chapter 33 teaches, no creature is ever killed here. Sacred creatures (cows, deer, Ashva steeds, Marut stags) cannot be harmed. Agitated spirits have their agitation calmed with Dhanurveda Prana implements (LMB / keys 1–3) or the <b>[V] Shanti Mantra</b> until they awaken in golden peace (Prabodha).",
		"<b>Divine Gurukula Music &amp; Sound.</b> Authentic hymns from <b>@guru-kula-desam</b> (Gayathri Manthiram, Thirukkural Kadavul Vazhthu, Vaan Sirappu, Kollaamai, Thiruppugazh, Devaram, Thiruvasagam) play continuously. Use the bottom-right Jukebox (⏭ / 🔊) to switch tracks anytime.",
		"<b>Astras (4-6) &amp; Yajnas.</b> Select an Astra or interact with a blighted site/stage: strike Z/X/C on each beat as it crosses the golden line.",
		"<b>Doshas &amp; Ayurveda.</b> Gather herbs, combine two at Vaidya Kamala's alchemy table, and press 7 to restore Vata, Pitta, and Kapha balance.",
		"<b>Keys.</b> C Gurukula &amp; Character · B Bags · L Quests · H Guide · Tab Target · V Shanti Mantra · M Mount · 7 Remedy · 8 Amrita · Esc Close.",
	}
	for _, t in ipairs(text) do
		line(t, C.text, 16)
		gap(4)
	end
end

local function transcended(payload)
	openWindow("Transcendence")
	current = "transcended"
	line(("<b>%s</b>, you have let go."):format(payload.monument), C.goldBright, 24, UI.fonts.title)
	line("Moksha is complete. Your path leaves this world, and a pillar bearing your name now stands in Maha-Loka, blessing every soul who arrives after you.", C.text, 18)
	line(("You return as a new Star Seed carrying your ancestors' blessing (legacy %d): a head start on every worldly path."):format(payload.legacy), C.moksha, 17)
end

---------------------------------------------------------------- public
function Panels.open(name: string, payload: any?)
	if name == "close" then
		Panels.close()
		return
	end
	if current == name then
		Panels.close()
		return
	end
	if name == "classSelect" then
		classSelect()
	elseif name == "character" then
		character()
	elseif name == "bags" then
		bags()
	elseif name == "quests" then
		questLog()
	elseif name == "alchemy" then
		alchemy()
	elseif name == "help" then
		help()
	elseif name == "transcended" then
		transcended(payload)
	end
end

function Panels.start()
	window = UI.frame(UI.root, UDim2.fromOffset(700, 520), UDim2.fromScale(0.5, 0.5), { anchor = Vector2.new(0.5, 0.5), name = "Panel", color = Color3.fromRGB(24, 20, 30), transparency = 0.04 })
	window.Visible = false
	window.ZIndex = 35
	titleLabel = UI.label(window, "", UDim2.new(1, -60, 0, 32), UDim2.fromOffset(16, 8), { font = UI.fonts.title, textSize = 26, color = C.goldBright })
	titleLabel.ZIndex = 36
	local x = UI.button(window, "✕", UDim2.fromOffset(30, 28), UDim2.new(1, -42, 0, 10), function()
		if current == "classSelect" then
			return -- must choose a class
		end
		Panels.close()
	end, { textSize = 14 })
	x.ZIndex = 37
	body = UI.scroller(window, UDim2.new(1, -28, 1, -56), UDim2.fromOffset(14, 48))
	body.ZIndex = 36
	UI.list(body, 3)

	-- Live-refresh read-only panels, keeping the scroll position (at most every 1.5s).
	local lastRefresh = 0
	State.changed:Connect(function()
		if (current ~= "character" and current ~= "bags" and current ~= "quests") or os.clock() - lastRefresh < 1.5 then
			return
		end
		lastRefresh = os.clock()
		local pos = body.CanvasPosition
		local keep = current
		current = nil
		Panels.open(keep :: string)
		body.CanvasPosition = pos
	end)
	Remotes.get("Panel").OnClientEvent:Connect(function(payload)
		Panels.open(payload.name, payload)
	end)
end

return Panels
