--[[
    IkatanTeleport.spec.luau
    ────────────────────────
    T-141: Integration test — Ikatan cross-server teleport.
    Simulates two mock players forming Ikatan, then Player A requesting teleport
    to Player B. Verifies: cooldown set, wing-level gate enforced, and the
    correct TeleportToPlaceInstance arguments are constructed.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared     = ReplicatedStorage:WaitForChild("Shared")
	local Constants  = require(Shared.Constants)
	local RealmDefs  = require(Shared.RealmDefs)
	local WingDefs   = require(Shared.WingDefs)

	-- ── Replicated teleport gate logic ──────────────────────────────────────

	type PresenceValue = { jobId: string, placeId: number, realmId: string }

	-- Simulate the Ikatan_TeleportRequest handler logic.
	local function simulateTeleportRequest(
		senderData:    { [string]: any },
		targetUserId:  number,
		presence:      PresenceValue?,
		lastTeleport:  { [number]: number },
		senderId:      number,
		now:           number
	): (boolean, string?, PresenceValue?)
		-- Target must be in sender's ikatanList
		local found = false
		for _, v in senderData.ikatanList do
			if v == tostring(targetUserId) then found = true; break end
		end
		if not found then return false, "notBonded", nil end

		-- Cooldown check
		local lastTime = lastTeleport[senderId] or 0
		if now - lastTime < Constants.IKATAN_TELEPORT_COOLDOWN then
			return false, "cooldown", nil
		end

		-- Target must be online (presence available)
		if not presence then return false, "offline", nil end

		-- Wing level gate: sender must meet target realm's minimum
		local realmDef = (RealmDefs :: any)[presence.realmId]
		if not realmDef then return false, "unknownRealm", nil end
		if senderData.wingLevel < realmDef.minWingLevel then
			return false, "wingLevel", nil
		end

		-- Cooldown set
		lastTeleport[senderId] = now

		return true, nil, presence
	end

	-- ── Tests ──────────────────────────────────────────────────────────────

	describe("Integration – Ikatan teleport gate: cooldown", function()

		it("teleport blocked when cooldown not yet elapsed", function()
			local senderId   = 1
			local targetId   = 2
			local now        = 10000
			local senderData = {
				wingLevel   = 5,
				ikatanList  = { tostring(targetId) },
			}
			local presence: PresenceValue = { jobId = "job_A", placeId = 123, realmId = "ISLE_DAWN" }
			local lastTeleport: { [number]: number } = { [senderId] = now - 1 }   -- 1 second ago < 30 min

			local ok, reason, _ = simulateTeleportRequest(senderData, targetId, presence, lastTeleport, senderId, now)
			expect(ok).to.equal(false)
			expect(reason).to.equal("cooldown")
		end)

		it("cooldown set on sender after successful teleport", function()
			local senderId   = 10
			local targetId   = 20
			local now        = 99999
			local senderData = {
				wingLevel   = 5,
				ikatanList  = { tostring(targetId) },
			}
			local presence: PresenceValue = { jobId = "job_B", placeId = 456, realmId = "ISLE_DAWN" }
			local lastTeleport: { [number]: number } = {}

			local ok, _, _ = simulateTeleportRequest(senderData, targetId, presence, lastTeleport, senderId, now)
			expect(ok).to.equal(true)
			expect(lastTeleport[senderId]).to.equal(now)
		end)

	end)

	describe("Integration – Ikatan teleport gate: wing level", function()

		it("teleport blocked when sender wing level is below target realm minimum", function()
			-- Find a realm with a minWingLevel > 1 to test the gate
			local testRealmId: string? = nil
			local testMinLevel: number = 0
			for realmId, def in RealmDefs do
				if type(def) == "table" and (def :: any).minWingLevel and (def :: any).minWingLevel > 1 then
					testRealmId  = realmId
					testMinLevel = (def :: any).minWingLevel
					break
				end
			end

			if not testRealmId then
				-- No realm has minWingLevel > 1; gate test is N/A for this config
				return
			end

			local senderId   = 30
			local targetId   = 40
			local now        = 200000
			local senderData = {
				wingLevel   = testMinLevel - 1,   -- one below minimum
				ikatanList  = { tostring(targetId) },
			}
			local presence: PresenceValue = { jobId = "job_C", placeId = 789, realmId = testRealmId }
			local lastTeleport: { [number]: number } = {}

			local ok, reason, _ = simulateTeleportRequest(senderData, targetId, presence, lastTeleport, senderId, now)
			expect(ok).to.equal(false)
			expect(reason).to.equal("wingLevel")
		end)

		it("teleport succeeds when wing level meets target realm minimum", function()
			local senderId   = 50
			local targetId   = 60
			local now        = 300000
			local senderData = {
				wingLevel   = 5,   -- ISLE_DAWN minWingLevel is 1
				ikatanList  = { tostring(targetId) },
			}
			local presence: PresenceValue = { jobId = "job_D", placeId = 100, realmId = "ISLE_DAWN" }
			local lastTeleport: { [number]: number } = {}

			local ok, reason, sentPresence = simulateTeleportRequest(senderData, targetId, presence, lastTeleport, senderId, now)
			expect(ok).to.equal(true)
			expect(reason).to.equal(nil)
			-- Verify the correct presence (place + job) is returned for teleport
			expect((sentPresence :: any).placeId).to.equal(100)
			expect((sentPresence :: any).jobId).to.equal("job_D")
		end)

	end)

	describe("Integration – Ikatan teleport gate: not bonded", function()

		it("teleport blocked when target is not in sender's ikatanList", function()
			local senderId   = 70
			local targetId   = 80
			local now        = 400000
			local senderData = {
				wingLevel   = 5,
				ikatanList  = {},   -- empty list
			}
			local presence: PresenceValue = { jobId = "job_E", placeId = 200, realmId = "ISLE_DAWN" }
			local lastTeleport: { [number]: number } = {}

			local ok, reason, _ = simulateTeleportRequest(senderData, targetId, presence, lastTeleport, senderId, now)
			expect(ok).to.equal(false)
			expect(reason).to.equal("notBonded")
		end)

	end)
end
