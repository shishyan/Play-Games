--!nonstrict
-- The Samsara engine: death -> the Bardo -> karmic evaluation -> blessing, plain rebirth, or Spiritual Debt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Samsara = require(Shared.Samsara)
local Purusharthas = require(Shared.Purusharthas)
local Remotes = require(Shared.Remotes)
local PlayerState = require(script.Parent.PlayerState)
local WorldState = require(script.Parent.WorldState)
local Guard = require(script.Parent.Guard)
local Services = require(script.Parent.Services)

local SamsaraService = {}

local rng = Random.new()
local ShowRemote = Remotes.get("SamsaraShow")
local pending: { [Player]: any } = {}

local function evalCtx(player: Player, greedy: boolean, riddleCorrect: boolean)
	local profile = PlayerState.get(player)
	return {
		karma = profile.karma,
		anrita = profile.anrita,
		tamas = PlayerState.stats(player).tamas,
		greedy = greedy,
		danaRatio = Purusharthas.danaRatio(profile),
		riddleCorrect = riddleCorrect,
	}
end

---------------------------------------------------------------- Spiritual Debt
local function mergeInto(dst, src)
	for id, n in pairs(src) do
		dst[id] = (dst[id] or 0) + n
	end
end

function SamsaraService.beginDebt(player: Player)
	local profile = PlayerState.get(player)
	profile.vault = profile.vault or { inv = {}, remedies = {} }
	mergeInto(profile.vault.inv, profile.inv)
	for _, r in ipairs(profile.remedies) do
		table.insert(profile.vault.remedies, r)
	end
	profile.inv = {}
	profile.remedies = {}
	profile.debt = Samsara.newDebt()
	PlayerState.toast(player, "Your belongings are withheld. Draw water at the step-well and carry it gently to the hermitage.", "warn")
end

function SamsaraService.clearDebt(player: Player)
	local profile = PlayerState.get(player)
	if profile.vault then
		mergeInto(profile.inv, profile.vault.inv)
		for _, r in ipairs(profile.vault.remedies) do
			table.insert(profile.remedies, r)
		end
		profile.vault = nil
	end
	profile.debt = nil
	PlayerState.addPath(player, "dharma", 4)
	PlayerState.addKarma(player, 3, "Spiritual Debt repaid")
	PlayerState.applyToCharacter(player, true)
	PlayerState.toast(player, "The hermit pours the water over the altar. Your debt is repaid and your belongings return.", "karma_good")
	PlayerState.markDirty(player)
end

---------------------------------------------------------------- death and rebirth
local function finalize(player: Player, answer: number?)
	local pend = pending[player]
	if not pend then
		return
	end
	pending[player] = nil
	local profile = PlayerState.get(player)
	if not profile then
		return
	end
	local correct = Samsara.riddleCorrect(pend.riddle, answer)
	local ev = Samsara.evaluate(evalCtx(player, pend.greedy, correct))
	local outcome = Samsara.outcome(ev.kind)
	profile.cycles += 1
	profile.anrita = math.max(0, profile.anrita - 2) -- the wheel forgives a little
	if correct then
		PlayerState.addKarma(player, 2, "wisdom in the Bardo")
	end
	if outcome.debt then
		SamsaraService.beginDebt(player)
	end
	Services.Loka.spawnAt(player, outcome.spawn)
	if outcome.buff then
		PlayerState.addBuff(player, outcome.buff)
	end
	if WorldState.funded("dharmashala") then
		PlayerState.addBuff(player, { id = "dharmashala", name = "Dharmashala Rest", icon = "🏠", dur = 120, regen = 5 })
	end
	PlayerState.toast(player, outcome.title, ev.kind == "debt" and "warn" or "karma_good")
	PlayerState.toast(player, outcome.text, "info")
end

function SamsaraService.onDeath(player: Player)
	local profile = PlayerState.get(player)
	if not profile or pending[player] then
		return
	end
	local stats = PlayerState.stats(player)
	local recentAnrita = profile.flags.lastAnritaAt ~= nil and os.time() - profile.flags.lastAnritaAt < 120
	local riddle = Samsara.pickRiddle(rng)
	local token = {}
	pending[player] = { riddle = riddle, greedy = stats.tamas or recentAnrita, token = token }
	PlayerState.toast(player, "Your body falls... the wheel of Samsara turns.", "warn")
	task.delay(2, function()
		local pend = pending[player]
		if not pend or pend.token ~= token or not player.Parent then
			return
		end
		Services.Loka.spawnAt(player, "bardo_arrival", true)
		local ev = Samsara.evaluate(evalCtx(player, pend.greedy, false))
		local r = Samsara.RIDDLES[riddle]
		ShowRemote:FireClient(player, {
			score = math.floor(ev.score), kind = ev.kind, reasons = ev.reasons,
			riddle = { q = r.q, options = r.options }, cycles = profile.cycles + 1, seconds = 30,
		})
		task.delay(32, function()
			if pending[player] and pending[player].token == token then
				finalize(player, nil)
			end
		end)
	end)
end

function SamsaraService.onCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	hum.Died:Connect(function()
		SamsaraService.onDeath(player)
	end)
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			local profile = PlayerState.get(player)
			if profile and profile.debt and profile.debt.stage == "carry" then
				Samsara.spill(profile.debt, "jump")
				PlayerState.toast(player, ("The vessel sloshes! Water left: %d%%"):format(profile.debt.water), "warn")
				PlayerState.markDirty(player)
			end
		end
	end)
end

function SamsaraService.start()
	Remotes.get("SamsaraAnswer").OnServerEvent:Connect(function(player, answer)
		if pending[player] and Guard.ok(player, "samsara", 1) then
			finalize(player, typeof(answer) == "number" and answer or nil)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
	end)
end

return SamsaraService
