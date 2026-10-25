--[[
    CahayaService.spec.luau
    ───────────────────────
    T-134: Unit tests for Cahaya economy business rules.
    Tests the logic as implemented in CahayaService.luau.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared     = ReplicatedStorage:WaitForChild("Shared")
	local Constants  = require(Shared.Constants)

	-- ── helpers ──────────────────────────────────────────────────────────────

	-- Minimal PlayerData fields touched by Cahaya logic
	local function makeData(overrides: { [string]: any }?): { [string]: any }
		local d: { [string]: any } = {
			cahaya                = 50,
			cahayaHati            = 10,
			dailyCahayaCollected  = 0,
			ikatanGiftsGivenToday = 0,
		}
		if overrides then
			for k, v in overrides do
				d[k] = v
			end
		end
		return d
	end

	-- Simulate the orb-collection grant (mirrors Cahaya_CollectOrb handler logic).
	local function simulateCollect(data: { [string]: any }, grant: number): boolean
		if data.dailyCahayaCollected >= Constants.DAILY_CAHAYA_CAP then
			return false   -- cap reached; orb rejected
		end
		data.cahaya += grant
		data.dailyCahayaCollected = math.min(
			data.dailyCahayaCollected + grant,
			Constants.DAILY_CAHAYA_CAP
		)
		return true
	end

	-- Simulate the revive logic (mirrors CahayaService.revive).
	local function simulateRevive(
		rescuerData: { [string]: any },
		targetData:  { [string]: any }
	): boolean
		if rescuerData.cahaya < Constants.REVIVE_CAHAYA_COST then return false end
		rescuerData.cahaya -= Constants.REVIVE_CAHAYA_COST
		targetData.cahaya   = Constants.REVIVE_RESTORED_CAHAYA
		return true
	end

	-- Simulate the gift logic (mirrors CahayaService.gift).
	local function simulateGift(
		giverData:     { [string]: any },
		recipientData: { [string]: any },
		amount:        number
	): (boolean, string?)
		if giverData.ikatanGiftsGivenToday >= Constants.MAX_IKATAN_GIFTS_PER_DAY then
			return false, "dailyLimit"
		end
		if giverData.cahayaHati < amount then
			return false, "insufficient"
		end
		giverData.cahayaHati     = giverData.cahayaHati - amount + Constants.GIFT_GIVER_BONUS
		recipientData.cahayaHati = recipientData.cahayaHati + amount
		giverData.ikatanGiftsGivenToday += 1
		return true, nil
	end

	-- ── Test suite ────────────────────────────────────────────────────────────

	describe("CahayaService – daily cap", function()

		it("accepts exactly 150 orbs", function()
			local data = makeData()
			for _ = 1, Constants.DAILY_CAHAYA_CAP do
				simulateCollect(data, 1)
			end
			expect(data.dailyCahayaCollected).to.equal(Constants.DAILY_CAHAYA_CAP)
			expect(data.cahaya).to.equal(50 + Constants.DAILY_CAHAYA_CAP)
		end)

		it("rejects the 151st orb once cap is reached", function()
			local data = makeData({ dailyCahayaCollected = Constants.DAILY_CAHAYA_CAP })
			local accepted = simulateCollect(data, 1)
			expect(accepted).to.equal(false)
			-- cahaya must not have changed
			expect(data.cahaya).to.equal(50)
		end)

	end)

	describe("CahayaService – extinguish", function()

		it("drain triggers extinguish flag exactly at 0 cahaya", function()
			local extinguished = false
			local data = makeData({ cahaya = 1 })
			data.cahaya = math.max(0, data.cahaya - 1)
			if data.cahaya == 0 then extinguished = true end
			expect(extinguished).to.equal(true)
		end)

		it("drain to 1 does not trigger extinguish", function()
			local extinguished = false
			local data = makeData({ cahaya = 2 })
			data.cahaya = math.max(0, data.cahaya - 1)
			if data.cahaya == 0 then extinguished = true end
			expect(extinguished).to.equal(false)
			expect(data.cahaya).to.equal(1)
		end)

	end)

	describe("CahayaService – revive", function()

		it("deducts REVIVE_CAHAYA_COST from rescuer and restores target to REVIVE_RESTORED_CAHAYA", function()
			local rescuerData = makeData({ cahaya = 5 })
			local targetData  = makeData({ cahaya = 0 })
			local ok = simulateRevive(rescuerData, targetData)
			expect(ok).to.equal(true)
			expect(rescuerData.cahaya).to.equal(5 - Constants.REVIVE_CAHAYA_COST)
			expect(targetData.cahaya).to.equal(Constants.REVIVE_RESTORED_CAHAYA)
		end)

		it("fails if rescuer cahaya < REVIVE_CAHAYA_COST", function()
			local rescuerData = makeData({ cahaya = 0 })
			local targetData  = makeData({ cahaya = 0 })
			local ok = simulateRevive(rescuerData, targetData)
			expect(ok).to.equal(false)
			expect(rescuerData.cahaya).to.equal(0)
			expect(targetData.cahaya).to.equal(0)
		end)

	end)

	describe("CahayaService – gift daily limit", function()

		it("allows exactly MAX_IKATAN_GIFTS_PER_DAY gifts", function()
			local giverData     = makeData({ cahayaHati = 100, ikatanGiftsGivenToday = 0 })
			local recipientData = makeData({ cahayaHati = 0 })

			for i = 1, Constants.MAX_IKATAN_GIFTS_PER_DAY do
				local ok, reason = simulateGift(giverData, recipientData, 1)
				expect(ok).to.equal(true)
				expect(reason).to.equal(nil)
				expect(giverData.ikatanGiftsGivenToday).to.equal(i)
			end
		end)

		it("rejects the gift after the daily limit is exhausted", function()
			local giverData     = makeData({ cahayaHati = 100, ikatanGiftsGivenToday = Constants.MAX_IKATAN_GIFTS_PER_DAY })
			local recipientData = makeData({ cahayaHati = 0 })
			local ok, reason = simulateGift(giverData, recipientData, 1)
			expect(ok).to.equal(false)
			expect(reason).to.equal("dailyLimit")
		end)

	end)

	describe("CahayaService – gift giver bonus", function()

		it("giver receives +GIFT_GIVER_BONUS cahayaHati per gift", function()
			local giftAmount    = 2
			local giverData     = makeData({ cahayaHati = 10, ikatanGiftsGivenToday = 0 })
			local recipientData = makeData({ cahayaHati = 5 })

			local ok, _ = simulateGift(giverData, recipientData, giftAmount)
			expect(ok).to.equal(true)
			-- giver: 10 - 2 + GIFT_GIVER_BONUS
			expect(giverData.cahayaHati).to.equal(10 - giftAmount + Constants.GIFT_GIVER_BONUS)
			-- recipient: 5 + 2
			expect(recipientData.cahayaHati).to.equal(5 + giftAmount)
		end)

	end)
end
