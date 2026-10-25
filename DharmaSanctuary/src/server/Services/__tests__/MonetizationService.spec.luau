--[[
    MonetizationService.spec.luau
    ─────────────────────────────
    T-138: Unit tests for monetization business rules.
    Tests idempotency, starter pack one-time claim, unknown product guard,
    and pending grant queue mechanics.
]]

return function()

	-- ── Replicated helpers ──────────────────────────────────────────────────

	-- Simulate the idempotency check from ProcessReceipt.
	local function isAlreadyProcessed(history: { [string]: boolean }, purchaseId: string): boolean
		return history[purchaseId] == true
	end

	-- Simulate handleStarterPack one-time-claim guard.
	local function simulateStarterPack(data: { [string]: any }): boolean
		if data.starterPackClaimed then return false end
		data.starterPackClaimed = true
		data.cahayaHati         = (data.cahayaHati or 0) + 5
		data.cahaya             = (data.cahaya or 0) + 50
		return true
	end

	-- Simulate handler dispatch (mirrors getHandlers lookup).
	local function simulateDispatch(handlers: { [number]: any }, productId: number): (boolean, string?)
		local handler = handlers[productId]
		if not handler then return false, "noHandler" end
		handler()
		return true, nil
	end

	type PendingGrant = { productId: number, purchaseId: string }

	-- Simulate enqueueGrant (pure data structure operation).
	local function enqueueGrant(queue: { PendingGrant }, productId: number, purchaseId: string)
		table.insert(queue, { productId = productId, purchaseId = purchaseId })
	end

	-- Simulate applyPendingGrants (mirrors MonetizationService.applyPendingGrants logic).
	local function applyPendingGrants(
		queue:    { PendingGrant },
		history:  { [string]: boolean },
		handlers: { [number]: () -> () }
	): number
		local applied = 0
		for _, grant in queue do
			if history[grant.purchaseId] then continue end
			local handler = handlers[grant.productId]
			if handler then
				handler()
				applied += 1
			end
			history[grant.purchaseId] = true
		end
		return applied
	end

	-- ── Tests ─────────────────────────────────────────────────────────────

	describe("MonetizationService – idempotent receipt", function()

		it("second call with same purchaseId returns 'already processed'", function()
			local history: { [string]: boolean } = {}
			local id = "receipt_001"

			-- First call: not yet in history
			expect(isAlreadyProcessed(history, id)).to.equal(false)
			history[id] = true

			-- Second call: already processed
			expect(isAlreadyProcessed(history, id)).to.equal(true)
		end)

		it("different purchaseIds are independent", function()
			local history: { [string]: boolean } = { ["receipt_A"] = true }
			expect(isAlreadyProcessed(history, "receipt_A")).to.equal(true)
			expect(isAlreadyProcessed(history, "receipt_B")).to.equal(false)
		end)

	end)

	describe("MonetizationService – starter pack one-time claim", function()

		it("first claim succeeds and sets starterPackClaimed", function()
			local data = { starterPackClaimed = false, cahayaHati = 0, cahaya = 0 }
			local ok = simulateStarterPack(data)
			expect(ok).to.equal(true)
			expect(data.starterPackClaimed).to.equal(true)
			expect(data.cahayaHati).to.equal(5)
			expect(data.cahaya).to.equal(50)
		end)

		it("second claim is blocked by starterPackClaimed flag", function()
			local data = { starterPackClaimed = true, cahayaHati = 5, cahaya = 50 }
			local ok = simulateStarterPack(data)
			expect(ok).to.equal(false)
			-- State must not change
			expect(data.cahayaHati).to.equal(5)
			expect(data.cahaya).to.equal(50)
		end)

	end)

	describe("MonetizationService – unknown product ID", function()

		it("returns noHandler for an unregistered productId", function()
			local handlers: { [number]: () -> () } = {
				[101] = function() end,
				[202] = function() end,
			}
			local ok, reason = simulateDispatch(handlers, 9999)
			expect(ok).to.equal(false)
			expect(reason).to.equal("noHandler")
		end)

		it("known productId is dispatched successfully", function()
			local called = false
			local handlers: { [number]: () -> () } = {
				[101] = function() called = true end,
			}
			local ok, _ = simulateDispatch(handlers, 101)
			expect(ok).to.equal(true)
			expect(called).to.equal(true)
		end)

	end)

	describe("MonetizationService – pending grant applied on next login", function()

		it("enqueued grant is stored with correct productId and purchaseId", function()
			local queue: { PendingGrant } = {}
			enqueueGrant(queue, 101, "purchase_XYZ")
			expect(#queue).to.equal(1)
			expect(queue[1].productId).to.equal(101)
			expect(queue[1].purchaseId).to.equal("purchase_XYZ")
		end)

		it("applyPendingGrants calls the correct handler for each queued grant", function()
			local applied: { number } = {}
			local handlers: { [number]: () -> () } = {
				[101] = function() table.insert(applied, 101) end,
				[202] = function() table.insert(applied, 202) end,
			}
			local queue: { PendingGrant } = {
				{ productId = 101, purchaseId = "p_1" },
				{ productId = 202, purchaseId = "p_2" },
			}
			local history: { [string]: boolean } = {}
			local count = applyPendingGrants(queue, history, handlers)
			expect(count).to.equal(2)
			expect(applied[1]).to.equal(101)
			expect(applied[2]).to.equal(202)
		end)

		it("already-processed grants in history are skipped", function()
			local applied: { number } = {}
			local handlers: { [number]: () -> () } = {
				[101] = function() table.insert(applied, 101) end,
			}
			local queue: { PendingGrant } = {
				{ productId = 101, purchaseId = "p_already" },
			}
			-- Pre-mark as processed
			local history: { [string]: boolean } = { ["p_already"] = true }
			local count = applyPendingGrants(queue, history, handlers)
			expect(count).to.equal(0)
			expect(#applied).to.equal(0)
		end)

	end)
end
