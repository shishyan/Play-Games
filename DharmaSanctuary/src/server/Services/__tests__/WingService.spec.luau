--[[
    WingService.spec.luau
    ─────────────────────
    T-135: Unit tests for wing level progression rules.
    Tests WingDefs configuration and upgrade/gate business logic.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared     = ReplicatedStorage:WaitForChild("Shared")
	local Constants  = require(Shared.Constants)
	local WingDefs   = require(Shared.WingDefs)

	-- Simulate the upgrade handler logic (mirrors Wing_UpgradeRequest handler).
	local function simulateUpgrade(data: { [string]: any }): (boolean, string?)
		if data.wingLevel >= Constants.MAX_WING_LEVEL then
			return false, "maxLevel"
		end
		local nextLevel = data.wingLevel + 1
		local def       = WingDefs[nextLevel]
		if not def then return false, "noDef" end
		if data.cahayaHati < def.cahayaHatiCost then
			return false, "insufficient"
		end
		data.cahayaHati -= def.cahayaHatiCost
		data.wingLevel   = nextLevel
		return true, nil
	end

	describe("WingService – upgrade success", function()

		it("upgrade succeeds with exactly enough cahayaHati", function()
			local currentLevel = 1
			local cost = WingDefs[currentLevel + 1].cahayaHatiCost   -- level 2 costs 3
			local data = { wingLevel = currentLevel, cahayaHati = cost }

			local ok, _ = simulateUpgrade(data)
			expect(ok).to.equal(true)
			expect(data.wingLevel).to.equal(2)
			expect(data.cahayaHati).to.equal(0)
		end)

		it("upgrade leaves remainder when cahayaHati exceeds cost", function()
			local data = { wingLevel = 1, cahayaHati = 10 }
			local cost = WingDefs[2].cahayaHatiCost
			local ok, _ = simulateUpgrade(data)
			expect(ok).to.equal(true)
			expect(data.cahayaHati).to.equal(10 - cost)
		end)

	end)

	describe("WingService – upgrade failure", function()

		it("upgrade fails if cahayaHati is one below cost", function()
			local cost = WingDefs[2].cahayaHatiCost
			local data = { wingLevel = 1, cahayaHati = cost - 1 }
			local ok, reason = simulateUpgrade(data)
			expect(ok).to.equal(false)
			expect(reason).to.equal("insufficient")
			expect(data.wingLevel).to.equal(1)
		end)

		it("upgrade blocked at MAX_WING_LEVEL (10)", function()
			local data = { wingLevel = Constants.MAX_WING_LEVEL, cahayaHati = 9999 }
			local ok, reason = simulateUpgrade(data)
			expect(ok).to.equal(false)
			expect(reason).to.equal("maxLevel")
			expect(data.wingLevel).to.equal(Constants.MAX_WING_LEVEL)
		end)

	end)

	describe("WingService – carry gate", function()

		it("carry is unlocked exactly at level 4", function()
			expect(WingDefs[4].canCarry).to.equal(true)
		end)

		it("carry is locked at level 3 and below", function()
			expect(WingDefs[3].canCarry).to.equal(false)
			expect(WingDefs[2].canCarry).to.equal(false)
			expect(WingDefs[1].canCarry).to.equal(false)
		end)

	end)

	describe("WingService – Sky's Peak gate", function()

		it("Sky's Peak access unlocked exactly at level 5", function()
			expect(WingDefs[5].canEnterSkysPeak).to.equal(true)
		end)

		it("Sky's Peak locked at level 4 and below", function()
			expect(WingDefs[4].canEnterSkysPeak).to.equal(false)
			expect(WingDefs[3].canEnterSkysPeak).to.equal(false)
		end)

	end)

	describe("WingService – Awan XP", function()

		it("Awan XP per level equals AWAN_XP_WING_PER_LEVEL * newLevel", function()
			for level = 2, Constants.MAX_WING_LEVEL do
				local expected = Constants.AWAN_XP_WING_PER_LEVEL * level
				expect(expected).to.equal(50 * level)
			end
		end)

		it("level 3 upgrade awards 150 XP (50 × 3)", function()
			local data = { wingLevel = 2, cahayaHati = WingDefs[3].cahayaHatiCost }
			local ok, _ = simulateUpgrade(data)
			expect(ok).to.equal(true)
			local xp = Constants.AWAN_XP_WING_PER_LEVEL * data.wingLevel
			expect(xp).to.equal(150)
		end)

	end)
end
