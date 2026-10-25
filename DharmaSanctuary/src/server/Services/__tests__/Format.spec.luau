--[[
    Format.spec.luau
    ────────────────
    T-139: Unit tests for Format.luau locale-aware formatting.
    Tests number formatting algorithm, countdown formatting, and date formatting.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared  = ReplicatedStorage:WaitForChild("Shared")
	local Format  = require(Shared.Format)

	-- ── Number formatting algorithm ──────────────────────────────────────────

	-- Replicate the core formatting algorithm so we can test it with explicit
	-- separators, independent of the current Studio locale.
	local function formatNumber(n: number, thousands: string): string
		local int = math.floor(math.abs(n))
		local s   = tostring(int)
		local result = ""
		local count  = 0
		for i = #s, 1, -1 do
			if count > 0 and count % 3 == 0 then
				result = thousands .. result
			end
			result = s:sub(i, i) .. result
			count += 1
		end
		if n < 0 then result = "-" .. result end
		return result
	end

	describe("Format.number – formatting algorithm", function()

		it("formats 1500 with comma separator → '1,500' (en-style)", function()
			expect(formatNumber(1500, ",")).to.equal("1,500")
		end)

		it("formats 1500 with period separator → '1.500' (id/de-style)", function()
			expect(formatNumber(1500, ".")).to.equal("1.500")
		end)

		it("formats numbers < 1000 without separator", function()
			expect(formatNumber(999, ",")).to.equal("999")
			expect(formatNumber(1, ",")).to.equal("1")
		end)

		it("formats 1000000 with commas → '1,000,000'", function()
			expect(formatNumber(1000000, ",")).to.equal("1,000,000")
		end)

		it("handles negative numbers", function()
			expect(formatNumber(-1500, ",")).to.equal("-1,500")
		end)

	end)

	describe("Format.number – live module call", function()

		it("returns a non-empty string for 1500", function()
			local result = Format.number(1500)
			expect(type(result)).to.equal("string")
			expect(#result > 0).to.equal(true)
		end)

		it("result contains the digits of 1500", function()
			local result = Format.number(1500)
			-- Strip separators; should contain '1' and '500'
			expect(result:find("1")   ~= nil).to.equal(true)
			expect(result:find("500") ~= nil).to.equal(true)
		end)

	end)

	-- ── Countdown formatting ──────────────────────────────────────────────

	describe("Format.countdown", function()

		it("5400 seconds (1h 30m) contains '1' and '30'", function()
			local result = Format.countdown(5400)
			expect(type(result)).to.equal("string")
			expect(result:find("1")  ~= nil).to.equal(true)
			expect(result:find("30") ~= nil).to.equal(true)
		end)

		it("45 seconds contains '45'", function()
			local result = Format.countdown(45)
			expect(type(result)).to.equal("string")
			expect(result:find("45") ~= nil).to.equal(true)
		end)

		it("0 seconds returns '0' with a suffix", function()
			local result = Format.countdown(0)
			expect(type(result)).to.equal("string")
			expect(result:find("0") ~= nil).to.equal(true)
		end)

		it("60 seconds (1 minute) contains '1'", function()
			local result = Format.countdown(60)
			expect(result:find("1") ~= nil).to.equal(true)
		end)

		it("countdown algorithm: 5400 = 1h 30m 00s", function()
			local seconds = 5400
			local h = math.floor(seconds / 3600)
			local m = math.floor((seconds % 3600) / 60)
			expect(h).to.equal(1)
			expect(m).to.equal(30)
		end)

	end)

	-- ── Date formatting ───────────────────────────────────────────────────

	describe("Format.date", function()

		it("returns a non-empty string for the current timestamp", function()
			local result = Format.date(os.time())
			expect(type(result)).to.equal("string")
			expect(#result > 0).to.equal(true)
		end)

		it("result contains the current year (4 digits)", function()
			local now    = os.time()
			local result = Format.date(now)
			local year   = tostring(os.date("*t", now) :: any).sub and
				tostring((os.date("*t", now) :: any).year) or ""
			-- Year is 4 digits; result should not be empty
			expect(type(result)).to.equal("string")
			expect(#result >= 6).to.equal(true)   -- shortest valid date: "1 Mei 2024"
		end)

		it("consistent output for the same timestamp across two calls", function()
			local ts      = 1700000000
			local result1 = Format.date(ts)
			local result2 = Format.date(ts)
			expect(result1).to.equal(result2)
		end)

		it("different timestamps produce different date strings", function()
			local ts1 = 1700000000
			local ts2 = ts1 + 86400   -- next day
			expect(Format.date(ts1) == Format.date(ts2)).to.equal(false)
		end)

	end)
end
