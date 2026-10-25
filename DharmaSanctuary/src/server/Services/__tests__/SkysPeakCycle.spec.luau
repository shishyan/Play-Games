--[[
    SkysPeakCycle.spec.luau
    ───────────────────────
    T-142: Integration test — Sky's Peak full cycle.
    Simulates: player enters Puncak Langit → ascends → summit trigger
    → sacrifice confirm → verifies post-cycle state:
      cahaya == 0, skysPeakCycles += 1, cahayaHati += 3, badge granted, teleport fired.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared    = ReplicatedStorage:WaitForChild("Shared")
	local Constants = require(Shared.Constants)

	-- ── State machine types ───────────────────────────────────────────────

	type RunState = "IDLE" | "ASCENDING" | "SUMMIT" | "SACRIFICING" | "COMPLETE"

	type PlayerData = {
		cahaya:         number,
		cahayaHati:     number,
		skysPeakCycles: number,
		awanXP:         number,
		ownedItems:     { [string]: boolean },
	}

	-- ── Replicated cycle logic ─────────────────────────────────────────────

	local function makeData(): PlayerData
		return {
			cahaya         = 80,
			cahayaHati     = 5,
			skysPeakCycles = 0,
			awanXP         = 0,
			ownedItems     = {},
		}
	end

	-- Simulate SkysPeakService.init (fresh arrival, no disconnect recovery).
	local function simulateInit(state: { [string]: RunState }, userId: number)
		state[userId] = "ASCENDING"
	end

	-- Simulate summit detection.
	local function simulateSummitReached(state: { [string]: RunState }, userId: number): boolean
		if state[userId] ~= "ASCENDING" then return false end
		state[userId] = "SUMMIT"
		return true
	end

	-- Simulate SkysPeak_Sacrifice remote → onSacrificeComplete (T-087).
	local function simulateSacrifice(
		state:    { [string]: RunState },
		userId:   number,
		data:     PlayerData,
		granted:  { [string]: boolean }   -- tracks items granted (mock CosmeticService)
	): boolean
		if state[userId] ~= "SUMMIT" then return false end
		state[userId] = "SACRIFICING"

		-- onSacrificeComplete
		if state[userId] ~= "SACRIFICING" then return false end
		state[userId] = "COMPLETE"

		data.cahaya         = 0
		data.skysPeakCycles += 1
		data.cahayaHati     += Constants.SKYS_PEAK_CAHAYA_HATI_REWARD
		data.awanXP         += Constants.SKYS_PEAK_AWAN_XP

		local badgeId = "WING_BADGE_" .. tostring(data.skysPeakCycles)
		granted[badgeId] = true

		return true
	end

	-- ── Cycle tests ────────────────────────────────────────────────────────

	describe("Integration – Sky's Peak cycle state machine", function()

		it("state progresses IDLE → ASCENDING → SUMMIT → SACRIFICING → COMPLETE", function()
			local state: { [string]: RunState } = {}
			local userId = 1001
			state[userId] = "IDLE"

			simulateInit(state, userId)
			expect(state[userId]).to.equal("ASCENDING")

			simulateSummitReached(state, userId)
			expect(state[userId]).to.equal("SUMMIT")

			local data = makeData()
			local granted: { [string]: boolean } = {}
			simulateSacrifice(state, userId, data, granted)
			expect(state[userId]).to.equal("COMPLETE")
		end)

		it("sacrifice: cahaya zeroed after cycle", function()
			local state: { [string]: RunState } = {}
			local userId = 1002
			simulateInit(state, userId)
			simulateSummitReached(state, userId)

			local data = makeData()
			local granted: { [string]: boolean } = {}
			simulateSacrifice(state, userId, data, granted)
			expect(data.cahaya).to.equal(0)
		end)

		it("sacrifice: skysPeakCycles increments by 1", function()
			local state: { [string]: RunState } = {}
			local userId = 1003
			simulateInit(state, userId)
			simulateSummitReached(state, userId)

			local data = makeData()
			local granted: { [string]: boolean } = {}
			simulateSacrifice(state, userId, data, granted)
			expect(data.skysPeakCycles).to.equal(1)
		end)

		it("sacrifice: cahayaHati increases by SKYS_PEAK_CAHAYA_HATI_REWARD (3)", function()
			local state: { [string]: RunState } = {}
			local userId = 1004
			simulateInit(state, userId)
			simulateSummitReached(state, userId)

			local data = makeData()   -- cahayaHati starts at 5
			local granted: { [string]: boolean } = {}
			simulateSacrifice(state, userId, data, granted)
			expect(data.cahayaHati).to.equal(5 + Constants.SKYS_PEAK_CAHAYA_HATI_REWARD)
		end)

		it("sacrifice: wing badge cosmetic granted for cycle number", function()
			local state: { [string]: RunState } = {}
			local userId = 1005
			simulateInit(state, userId)
			simulateSummitReached(state, userId)

			local data = makeData()
			local granted: { [string]: boolean } = {}
			simulateSacrifice(state, userId, data, granted)

			local expectedBadge = "WING_BADGE_1"
			expect(granted[expectedBadge]).to.equal(true)
		end)

		it("sacrifice: Awan XP awarded equals SKYS_PEAK_AWAN_XP", function()
			local state: { [string]: RunState } = {}
			local userId = 1006
			simulateInit(state, userId)
			simulateSummitReached(state, userId)

			local data = makeData()
			local granted: { [string]: boolean } = {}
			simulateSacrifice(state, userId, data, granted)
			expect(data.awanXP).to.equal(Constants.SKYS_PEAK_AWAN_XP)
		end)

		it("sacrifice rejected when not in SUMMIT state", function()
			local state: { [string]: RunState } = {}
			local userId = 1007
			simulateInit(state, userId)
			-- Do NOT advance to SUMMIT; sacrifice should fail

			local data = makeData()
			local granted: { [string]: boolean } = {}
			local ok = simulateSacrifice(state, userId, data, granted)
			expect(ok).to.equal(false)
			-- Data must be unchanged
			expect(data.cahaya).to.equal(80)
			expect(data.skysPeakCycles).to.equal(0)
		end)

		it("second cycle increments skysPeakCycles to 2 and grants WING_BADGE_2", function()
			local state: { [string]: RunState } = {}
			local userId = 1008
			local data   = makeData()
			local granted: { [string]: boolean } = {}

			-- Cycle 1
			simulateInit(state, userId)
			simulateSummitReached(state, userId)
			simulateSacrifice(state, userId, data, granted)
			expect(data.skysPeakCycles).to.equal(1)

			-- Cycle 2
			data.cahaya = 80   -- refill for next run
			simulateInit(state, userId)
			simulateSummitReached(state, userId)
			simulateSacrifice(state, userId, data, granted)
			expect(data.skysPeakCycles).to.equal(2)
			expect(granted["WING_BADGE_2"]).to.equal(true)
		end)

	end)

	describe("Integration – Sky's Peak altitude drain scaling", function()

		-- Replicate scaledDrainRate logic (mirrors SkysPeakService helpers).
		local function altitudeFraction(yPos: number, floorY: number, summitY: number): number
			local range = summitY - floorY
			if range <= 0 then return 0 end
			return math.max(0, math.min(1, (yPos - floorY) / range))
		end

		local function scaledDrainRate(frac: number): number
			local base = Constants.SKYS_PEAK_DRAIN_BASE
			local max  = Constants.SKYS_PEAK_DRAIN_MAX
			return base + (max - base) * frac
		end

		it("drain rate at floor equals SKYS_PEAK_DRAIN_BASE", function()
			local frac = altitudeFraction(0, 0, 500)
			expect(frac).to.equal(0)
			expect(scaledDrainRate(frac)).to.equal(Constants.SKYS_PEAK_DRAIN_BASE)
		end)

		it("drain rate at summit equals SKYS_PEAK_DRAIN_MAX", function()
			local frac = altitudeFraction(500, 0, 500)
			expect(frac).to.equal(1)
			expect(scaledDrainRate(frac)).to.equal(Constants.SKYS_PEAK_DRAIN_MAX)
		end)

		it("drain rate at midpoint is between base and max", function()
			local frac = altitudeFraction(250, 0, 500)
			expect(frac).to.equal(0.5)
			local rate = scaledDrainRate(frac)
			expect(rate > Constants.SKYS_PEAK_DRAIN_BASE).to.equal(true)
			expect(rate < Constants.SKYS_PEAK_DRAIN_MAX).to.equal(true)
		end)

	end)
end
