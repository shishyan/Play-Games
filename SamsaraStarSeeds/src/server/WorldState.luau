--!nonstrict
-- Server-wide state: the Rta meter, the Yuga lifecycle, community funds and the monuments of
-- transcended players. Persisted in a DataStore (with an in-memory fallback in Studio).
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Yuga = require(Shared.Yuga)
local LokaDefs = require(Shared.LokaDefs)

local WorldState = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("SamsaraWorldV1")
end)

local data = { rta = 0, epoch = 0, funds = { stepwell = 0, pathshala = 0, dharmashala = 0 }, monuments = {}, decree = "aranya_raksha" }
local bootTime = os.time()
local current = Yuga.at(0)
local dirty = false
local pendingFunds: { [string]: number } = {}
local pendingMonuments: { any } = {}

local function publish()
	workspace:SetAttribute("Rta", math.floor(data.rta * 10) / 10)
	workspace:SetAttribute("YugaIndex", current.index)
	workspace:SetAttribute("YugaName", current.name)
	workspace:SetAttribute("YugaRemaining", math.floor(current.remaining))
	workspace:SetAttribute("YugaCycle", current.cycle)
	workspace:SetAttribute("Decree", data.decree or "aranya_raksha")
	for id in pairs(LokaDefs.CommunityProjects) do
		workspace:SetAttribute("Fund_" .. id, data.funds[id] or 0)
	end
end

function WorldState.load()
	if store then
		local ok, res = pcall(function()
			return store:GetAsync("world")
		end)
		if ok and type(res) == "table" then
			data.rta = res.rta or 0
			data.epoch = res.epoch or 0
			for k, v in pairs(res.funds or {}) do
				data.funds[k] = v
			end
			data.monuments = res.monuments or {}
		elseif not ok then
			warn("[Samsara] World DataStore unavailable; using in-memory world state.")
		end
	end
	publish()
end

-- Merge-safe save: other servers may have written meanwhile, so add our deltas instead of overwriting.
function WorldState.save()
	if not store then
		return
	end
	local epochNow = WorldState.elapsed()
	local ok, result = pcall(function()
		return store:UpdateAsync("world", function(old)
			old = type(old) == "table" and old or { rta = 0, epoch = 0, funds = {}, monuments = {} }
			old.funds = old.funds or {}
			for id, d in pairs(pendingFunds) do
				old.funds[id] = (old.funds[id] or 0) + d
			end
			old.monuments = old.monuments or {}
			for _, m in ipairs(pendingMonuments) do
				table.insert(old.monuments, m)
			end
			while #old.monuments > 60 do
				table.remove(old.monuments, 1)
			end
			old.epoch = math.max(old.epoch or 0, epochNow)
			old.rta = data.rta
			return old
		end)
	end)
	if ok and type(result) == "table" then
		pendingFunds = {}
		pendingMonuments = {}
		data.funds = result.funds
		data.monuments = result.monuments
		data.epoch = epochNow -- keep the cosmic clock continuous across saves
		bootTime = os.time()
		dirty = false
	end
end

---------------------------------------------------------------- Yuga
-- The cosmic clock = persisted epoch offset + seconds since this server booted.
function WorldState.elapsed(): number
	return data.epoch + (os.time() - bootTime)
end

function WorldState.yuga()
	return current
end

function WorldState.rules()
	return current.rules
end

-- Testing/admin: jump to the start of a Yuga (1-4).
function WorldState.setYuga(index: number)
	data.epoch = Yuga.startOf(index) - (os.time() - bootTime)
	dirty = true
end

---------------------------------------------------------------- Rta (the web of cosmic order)
function WorldState.addRta(delta: number)
	data.rta = math.clamp(data.rta + delta, -100, 100)
	dirty = true
end

function WorldState.rta(): number
	return data.rta
end

-- 1.0 at neutral, up to 1.5 when the world is full of Anrita: more and tougher chaos.
function WorldState.chaosMult(): number
	return 1 + math.max(0, -data.rta) / 200
end

---------------------------------------------------------------- Community funds
function WorldState.fund(project: string, gold: number)
	local def = LokaDefs.CommunityProjects[project]
	if not def then
		return false
	end
	data.funds[project] = (data.funds[project] or 0) + gold
	pendingFunds[project] = (pendingFunds[project] or 0) + gold
	dirty = true
	return true
end

function WorldState.funded(project: string): boolean
	local def = LokaDefs.CommunityProjects[project]
	return def ~= nil and (data.funds[project] or 0) >= def.goal
end

function WorldState.fundAmount(project: string): number
	return data.funds[project] or 0
end

---------------------------------------------------------------- Regional Decrees (Sabha Parishad)
function WorldState.setDecree(id: string): boolean
	if not LokaDefs.Decrees[id] then
		return false
	end
	data.decree = id
	WorldState.addRta(4)
	publish()
	return true
end

function WorldState.decree()
	return LokaDefs.Decrees[data.decree] or LokaDefs.Decrees.aranya_raksha
end

function WorldState.decreeId(): string
	return data.decree or "aranya_raksha"
end

---------------------------------------------------------------- Monuments of the transcended
function WorldState.addMonument(name: string)
	local entry = { name = name, at = os.time(), cycle = current.cycle }
	table.insert(data.monuments, entry)
	table.insert(pendingMonuments, entry)
	dirty = true
end

function WorldState.monuments()
	return data.monuments
end

---------------------------------------------------------------- loop
function WorldState.start()
	task.spawn(function()
		local lastSave = os.clock()
		local lastIndex = -1
		while true do
			current = Yuga.at(WorldState.elapsed())
			if current.index ~= lastIndex then
				lastIndex = current.index
				workspace.Gravity = 196.2 * current.rules.gravity
			end
			-- Rta slowly heals toward neutral: the web re-knits.
			if data.rta ~= 0 then
				data.rta += (data.rta > 0 and -0.02 or 0.02)
				dirty = true
			end
			publish()
			if dirty and os.clock() - lastSave > 60 then
				lastSave = os.clock()
				WorldState.save()
			end
			task.wait(1)
		end
	end)
	game:BindToClose(function()
		WorldState.save()
	end)
end

return WorldState
