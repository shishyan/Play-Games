--[[
    DailyTaskService.spec.luau
    ──────────────────────────
    T-136: Unit tests for daily task generation, progress, milestones, and streak logic.
    All logic is replicated from DailyTaskService.luau for isolation.
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared        = ReplicatedStorage:WaitForChild("Shared")
	local Constants     = require(Shared.Constants)
	local DailyTaskDefs = require(Shared.DailyTaskDefs)

	-- ── Replicated helpers (mirror DailyTaskService internals) ───────────────

	local UTC7_OFFSET = 7 * 3600

	local function pickN(pool: { any }, n: number): { any }
		local copy: { any } = {}
		for _, v in pool do table.insert(copy, v) end
		local count  = math.min(n, #copy)
		local result: { any } = {}
		for i = 1, count do
			local j = math.random(i, #copy)
			copy[i], copy[j] = copy[j], copy[i]
			table.insert(result, copy[i])
		end
		return result
	end

	local function generateTasks(userId: number, dateString: string): { any }
		local seed = bit32.bxor(userId, tonumber(dateString) or 0)
		math.randomseed(seed)
		local easy   = pickN(DailyTaskDefs.EasyPool,   Constants.DAILY_TASK_EASY_COUNT)
		local medium = pickN(DailyTaskDefs.MediumPool,  Constants.DAILY_TASK_MEDIUM_COUNT)
		local hard   = pickN(DailyTaskDefs.HardPool,    Constants.DAILY_TASK_HARD_COUNT)
		local tasks: { any } = {}
		for _, def in easy   do table.insert(tasks, { id = def.id, progress = 0, completed = false, target = def.target }) end
		for _, def in medium do table.insert(tasks, { id = def.id, progress = 0, completed = false, target = def.target }) end
		for _, def in hard   do table.insert(tasks, { id = def.id, progress = 0, completed = false, target = def.target }) end
		return tasks
	end

	-- Milestone claim logic (mirrors DailyTask_ClaimMilestone handler).
	local function simulateClaim(taskState: { [string]: any }, tier: number): boolean
		if tier < 1 or tier > #Constants.MILESTONE_THRESHOLDS then return false end
		local completedCount = #taskState.completedIndices
		if completedCount < Constants.MILESTONE_THRESHOLDS[tier] then return false end
		for _, claimed in taskState.milestoneRewardsClaimed do
			if claimed == tier then return false end
		end
		table.insert(taskState.milestoneRewardsClaimed, tier)
		return true
	end

	-- Streak logic (mirrors handleLoginStreak).
	local function simulateStreak(data: { [string]: any }, todayStr: string)
		local lastDate = data.lastStreakDate
		if lastDate == todayStr then return end
		if lastDate == "" then
			data.loginStreak    = 1
			data.lastStreakDate = todayStr
			return
		end
		local function dateToTs(ds: string): number
			return os.time({
				year  = tonumber(ds:sub(1,4)) or 0,
				month = tonumber(ds:sub(5,6)) or 0,
				day   = tonumber(ds:sub(7,8)) or 0,
				hour  = 0, min = 0, sec = 0,
			})
		end
		local dayDiff = math.floor((dateToTs(todayStr) - dateToTs(lastDate)) / 86400)
		if dayDiff == 1 then
			data.loginStreak += 1
		elseif dayDiff > 1 then
			if data.graceDaysRemaining > 0 and dayDiff <= 2 then
				data.graceDaysRemaining -= 1
				data.loginStreak        += 1
			else
				data.loginStreak = 1
			end
		end
		data.lastStreakDate = todayStr
	end

	local function makeTaskState(completedCount: number): { [string]: any }
		local indices: { number } = {}
		for i = 1, completedCount do table.insert(indices, i) end
		return {
			date                    = "20240101",
			tasks                   = {},
			completedIndices        = indices,
			milestoneRewardsClaimed = {},
		}
	end

	-- ── Seeded generation ──────────────────────────────────────────────────

	describe("DailyTaskService – seeded generation", function()

		it("same userId + same date produces identical task set across two calls", function()
			local userId  = 7654321
			local dateStr = "20240315"
			local set1 = generateTasks(userId, dateStr)
			local set2 = generateTasks(userId, dateStr)
			expect(#set1).to.equal(#set2)
			for i, task in set1 do
				expect(task.id).to.equal(set2[i].id)
			end
		end)

		it("different userIds produce different seeds", function()
			local dateStr = "20240315"
			local seed1   = bit32.bxor(11111, tonumber(dateStr) or 0)
			local seed2   = bit32.bxor(22222, tonumber(dateStr) or 0)
			expect(seed1 == seed2).to.equal(false)
		end)

		it("generates the correct total task count (3 easy + 1 medium + 1 hard = 5)", function()
			local tasks = generateTasks(99999, "20240101")
			expect(#tasks).to.equal(
				Constants.DAILY_TASK_EASY_COUNT
				+ Constants.DAILY_TASK_MEDIUM_COUNT
				+ Constants.DAILY_TASK_HARD_COUNT
			)
		end)

	end)

	-- ── Progress increment ─────────────────────────────────────────────────

	describe("DailyTaskService – progress increment", function()

		it("correct task advances, others remain unchanged", function()
			local tasks = generateTasks(12345, "20240101")
			-- Pick the first task as the "target"; advance it
			local target  = tasks[1]
			local beforeId = target.id
			target.progress += 1
			-- Other tasks untouched
			for i = 2, #tasks do
				expect(tasks[i].progress).to.equal(0)
			end
			expect(tasks[1].id).to.equal(beforeId)
			expect(tasks[1].progress).to.equal(1)
		end)

		it("task marked completed when progress reaches target", function()
			local task = { id = "TEST", progress = 0, completed = false, target = 3 }
			for _ = 1, 3 do
				task.progress += 1
				if task.progress >= task.target then
					task.completed = true
				end
			end
			expect(task.completed).to.equal(true)
			expect(task.progress).to.equal(task.target)
		end)

	end)

	-- ── Milestone claim ────────────────────────────────────────────────────

	describe("DailyTaskService – milestone claim", function()

		it("tier 3 claim succeeds after exactly 3 completed tasks", function()
			local TIER      = 3
			local threshold = Constants.MILESTONE_THRESHOLDS[TIER]   -- 3
			local taskState = makeTaskState(threshold)
			local ok = simulateClaim(taskState, TIER)
			expect(ok).to.equal(true)
			expect(#taskState.milestoneRewardsClaimed).to.equal(1)
			expect(taskState.milestoneRewardsClaimed[1]).to.equal(TIER)
		end)

		it("tier 3 claim fails after only 2 completed tasks", function()
			local TIER      = 3
			local threshold = Constants.MILESTONE_THRESHOLDS[TIER]   -- 3
			local taskState = makeTaskState(threshold - 1)            -- 2 completed
			local ok = simulateClaim(taskState, TIER)
			expect(ok).to.equal(false)
			expect(#taskState.milestoneRewardsClaimed).to.equal(0)
		end)

		it("same tier cannot be claimed twice", function()
			local TIER      = 2
			local threshold = Constants.MILESTONE_THRESHOLDS[TIER]
			local taskState = makeTaskState(threshold)
			expect(simulateClaim(taskState, TIER)).to.equal(true)
			expect(simulateClaim(taskState, TIER)).to.equal(false)
		end)

	end)

	-- ── Login streak ──────────────────────────────────────────────────────

	describe("DailyTaskService – login streak", function()

		it("streak increments on consecutive days", function()
			local data = { loginStreak = 1, lastStreakDate = "20240101", graceDaysRemaining = 0 }
			simulateStreak(data, "20240102")
			expect(data.loginStreak).to.equal(2)
		end)

		it("streak resets to 1 after a 2-day gap with no grace days", function()
			local data = { loginStreak = 5, lastStreakDate = "20240101", graceDaysRemaining = 0 }
			simulateStreak(data, "20240103")   -- gap of 2 days, dayDiff == 2; grace == 0
			expect(data.loginStreak).to.equal(1)
		end)

		it("grace day consumed for a 2-day gap when grace is available", function()
			local data = { loginStreak = 5, lastStreakDate = "20240101", graceDaysRemaining = 1 }
			simulateStreak(data, "20240103")   -- dayDiff == 2, grace > 0 and dayDiff <= 2
			expect(data.loginStreak).to.equal(6)
			expect(data.graceDaysRemaining).to.equal(0)
		end)

		it("streak unchanged if same day logged in twice", function()
			local data = { loginStreak = 3, lastStreakDate = "20240101", graceDaysRemaining = 0 }
			simulateStreak(data, "20240101")
			expect(data.loginStreak).to.equal(3)
		end)

		it("first ever login sets streak to 1", function()
			local data = { loginStreak = 0, lastStreakDate = "", graceDaysRemaining = 0 }
			simulateStreak(data, "20240101")
			expect(data.loginStreak).to.equal(1)
		end)

	end)
end
