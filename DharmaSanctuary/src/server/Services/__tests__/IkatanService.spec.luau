--[[
    IkatanService.spec.luau
    ───────────────────────
    T-137: Unit tests for Ikatan bond system business rules.
    Tests offer TTL, acceptance guards, bidirectional bonding, and cap enforcement.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared    = ReplicatedStorage:WaitForChild("Shared")
	local Constants = require(Shared.Constants)

	-- ── Replicated helpers ──────────────────────────────────────────────────

	type OfferRecord = { fromUserId: number, expiresAt: number }

	local function makeOffer(fromUserId: number, createdAt: number): OfferRecord
		return { fromUserId = fromUserId, expiresAt = createdAt + Constants.IKATAN_OFFER_TTL }
	end

	local function isOfferExpired(offer: OfferRecord, now: number): boolean
		return now >= offer.expiresAt
	end

	local function listContains(list: { string }, target: number): boolean
		local s = tostring(target)
		for _, v in list do
			if v == s then return true end
		end
		return false
	end

	-- Simulate the accept handler guard checks.
	local function simulateAccept(
		offer:         OfferRecord?,
		fromUserId:    number,
		now:           number,
		acceptorData:  { [string]: any },
		initiatorData: { [string]: any },
		acceptorId:    number
	): (boolean, string?)
		if not offer or offer.fromUserId ~= fromUserId then return false, "noOffer" end
		if isOfferExpired(offer, now)                  then return false, "expired" end
		if listContains(acceptorData.ikatanList, fromUserId)  then return false, "duplicate" end
		if #acceptorData.ikatanList  >= Constants.MAX_IKATAN  then return false, "cap" end
		if #initiatorData.ikatanList >= Constants.MAX_IKATAN  then return false, "cap" end

		table.insert(acceptorData.ikatanList,  tostring(fromUserId))
		table.insert(initiatorData.ikatanList, tostring(acceptorId))
		acceptorData.cahayaHati  += 2
		initiatorData.cahayaHati += 2
		return true, nil
	end

	-- Simulate the offer sender guard checks.
	local function simulateOffer(
		senderData:    { [string]: any },
		targetData:    { [string]: any },
		targetUserId:  number
	): (boolean, string?)
		if listContains(senderData.ikatanList, targetUserId) then return false, "alreadyBonded" end
		if #senderData.ikatanList >= Constants.MAX_IKATAN    then return false, "cap" end
		if #targetData.ikatanList >= Constants.MAX_IKATAN    then return false, "cap" end
		return true, nil
	end

	local function makeData(overrides: { [string]: any }?): { [string]: any }
		local d: { [string]: any } = { ikatanList = {}, cahayaHati = 0 }
		if overrides then
			for k, v in overrides do d[k] = v end
		end
		return d
	end

	-- ── Offer TTL ────────────────────────────────────────────────────────

	describe("IkatanService – offer TTL", function()

		it("offer is valid before IKATAN_OFFER_TTL seconds elapse", function()
			local now    = 1000
			local offer  = makeOffer(42, now)
			expect(isOfferExpired(offer, now + Constants.IKATAN_OFFER_TTL - 1)).to.equal(false)
		end)

		it("offer expires exactly at IKATAN_OFFER_TTL seconds", function()
			local now   = 1000
			local offer = makeOffer(42, now)
			expect(isOfferExpired(offer, now + Constants.IKATAN_OFFER_TTL)).to.equal(true)
		end)

		it("expired offer is rejected by accept handler", function()
			local now   = 2000
			local offer = makeOffer(99, now - Constants.IKATAN_OFFER_TTL - 1)
			local acceptorData  = makeData()
			local initiatorData = makeData()
			local ok, reason = simulateAccept(offer, 99, now, acceptorData, initiatorData, 1)
			expect(ok).to.equal(false)
			expect(reason).to.equal("expired")
		end)

	end)

	-- ── Bidirectional bond ───────────────────────────────────────────────

	describe("IkatanService – bidirectional bonding", function()

		it("both players' ikatanLists updated after successful bond", function()
			local acceptorId    = 100
			local initiatorId   = 200
			local now           = 5000
			local offer         = makeOffer(initiatorId, now - 5)   -- fresh offer
			local acceptorData  = makeData()
			local initiatorData = makeData()

			local ok, _ = simulateAccept(offer, initiatorId, now, acceptorData, initiatorData, acceptorId)
			expect(ok).to.equal(true)
			expect(listContains(acceptorData.ikatanList,  initiatorId)).to.equal(true)
			expect(listContains(initiatorData.ikatanList, acceptorId)).to.equal(true)
		end)

		it("both players receive +2 cahayaHati on bond formation", function()
			local now           = 5000
			local offer         = makeOffer(200, now - 5)
			local acceptorData  = makeData({ cahayaHati = 3 })
			local initiatorData = makeData({ cahayaHati = 7 })

			simulateAccept(offer, 200, now, acceptorData, initiatorData, 100)
			expect(acceptorData.cahayaHati).to.equal(5)
			expect(initiatorData.cahayaHati).to.equal(9)
		end)

	end)

	-- ── Ikatan cap ────────────────────────────────────────────────────────

	describe("IkatanService – max Ikatan cap", function()

		it("offer blocked when sender already has MAX_IKATAN bonds", function()
			local senderList: { string } = {}
			for i = 1, Constants.MAX_IKATAN do
				table.insert(senderList, tostring(i))
			end
			local senderData = makeData({ ikatanList = senderList })
			local targetData = makeData()
			local ok, reason = simulateOffer(senderData, targetData, 99999)
			expect(ok).to.equal(false)
			expect(reason).to.equal("cap")
		end)

		it("offer allowed when sender has MAX_IKATAN - 1 bonds", function()
			local senderList: { string } = {}
			for i = 1, Constants.MAX_IKATAN - 1 do
				table.insert(senderList, tostring(i))
			end
			local senderData = makeData({ ikatanList = senderList })
			local targetData = makeData()
			local ok, _ = simulateOffer(senderData, targetData, 99999)
			expect(ok).to.equal(true)
		end)

	end)

	-- ── Duplicate bond ───────────────────────────────────────────────────

	describe("IkatanService – duplicate bond rejection", function()

		it("re-offering an already bonded partner is rejected", function()
			local targetId   = 999
			local senderData = makeData({ ikatanList = { tostring(targetId) } })
			local targetData = makeData()
			local ok, reason = simulateOffer(senderData, targetData, targetId)
			expect(ok).to.equal(false)
			expect(reason).to.equal("alreadyBonded")
		end)

	end)
end
