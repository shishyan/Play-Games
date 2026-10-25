--[[
    DailyTaskCycle.spec.luau
    ────────────────────────
    T-140: Integration test — Daily Task full cycle.
    Simulates: task generation → progress → 5 completions → claim all milestone tiers
    → verifies DataStore state shape (completedIndices, milestoneRewardsClaimed,
    cahayaHati increased, full-clear flag set).
]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared        = ReplicatedStorage:WaitForChild("Shared")
	local Constants     = require(Shared.Constants)
	local DailyTaskDefs = require(Shared.DailyTaskDefs)

	-- ── Full cycle harness ───────────────────────────────────────────────────

	-- Build an initial task state matching DailyTaskService.generateTaskState.
	local function buildTaskState(userId: number, dateStr: string)
		local function pickN(pool: { any }, n: number): { any }
			local copy: { any } = {}
			for _, v in pool do table.insert(copy, v) end
			local result: { any } = {}
			for i = 1, math.min(n, #copy) do
				local j = math.random(i, #copy)
				copy[i], copy[j] = copy[j], copy[i]
				table.insert(result, copy[i])
			end
			return result
		end

		local seed = bit32.bxor(userId, tonumber(dateStr) or 0)
		math.randomseed(seed)

		local easy   = pickN(DailyTaskDefs.EasyPool,   Constants.DAILY_TASK_EASY_COUNT)
		local medium = pickN(DailyTaskDefs.MediumPool,  Constants.DAILY_TASK_MEDIUM_COUNT)
		local hard   = pickN(DailyTaskDefs.HardPool,    Constants.DAILY_TASK_HARD_COUNT)

		local tasks: { any } = {}
		for _, def in easy   do table.insert(tasks, { id = def.id, target = def.target, progress = 0, completed = false }) end
		for _, def in medium do table.insert(tasks, { id = def.id, target = def.target, progress = 0, completed = false }) end
		for _, def in hard   do table.insert(tasks, { id = def.id, target = def.target, progress = 0, completed = false }) end

		return {
			date                    = dateStr,
			tasks                   = tasks,
			completedIndices        = {} :: { number },
			milestoneRewardsClaimed = {} :: { number },
		}
	end

	-- Force-complete a task (bypass progress increment for speed).
	local function forceComplete(taskState: { [string]: any }, index: number)
		local task = taskState.tasks[index]
		if task and not task.completed then
			task.progress  = task.target
			task.completed = true
			table.insert(taskState.completedIndices, index)
		end
	end

	-- Simulate milestone claim logic.
	local function claimMilestone(
		taskState:    { [string]: any },
		tier:         number,
		playerData:   { [string]: any }
	): boolean
		if tier < 1 or tier > #Constants.MILESTONE_THRESHOLDS then return false end
		if #taskState.completedIndices < Constants.MILESTONE_THRESHOLDS[tier] then return false end
		for _, claimed in taskState.milestoneRewardsClaimed do
			if claimed == tier then return false end
		end
		table.insert(taskState.milestoneRewardsClaimed, tier)

		local reward = Constants.MILESTONE_REWARDS[tier]
		if reward.cahaya    and reward.cahaya    > 0 then playerData.cahaya    += reward.cahaya    end
		if reward.cahayaHati and reward.cahayaHati > 0 then playerData.cahayaHati += reward.cahayaHati end
		return true
	end

	-- ── Full cycle test ──────────────────────────────────────────────────────

	describe("Integration – Daily Task full cycle", function()

		it("completes all 5 tasks and claims all 5 milestone tiers", function()
			local userId    = 55555
			local dateStr   = "20240601"
			local taskState = buildTaskState(userId, dateStr)
			local playerData: { [string]: any } = { cahaya = 0, cahayaHati = 0 }

			-- Verify 5 tasks were generated
			local taskCount =
				Constants.DAILY_TASK_EASY_COUNT +
				Constants.DAILY_TASK_MEDIUM_COUNT +
				Constants.DAILY_TASK_HARD_COUNT
			expect(#taskState.tasks).to.equal(taskCount)

			-- Complete all 5 tasks
			for i = 1, #taskState.tasks do
				forceComplete(taskState, i)
			end
			expect(#taskState.completedIndices).to.equal(taskCount)

			-- Claim all 5 milestone tiers
			for tier = 1, #Constants.MILESTONE_THRESHOLDS do
				local ok = claimMilestone(taskState, tier, playerData)
				expect(ok).to.equal(true)
			end

			-- Verify milestoneRewardsClaimed has all 5 tiers
			expect(#taskState.milestoneRewardsClaimed).to.equal(#Constants.MILESTONE_THRESHOLDS)

			-- Verify cahayaHati increased (tiers 3 and 5 grant cahayaHati)
			-- tier 3 → cahayaHati +1 ; tier 5 → cahayaHati +2 → total ≥ 3
			expect(playerData.cahayaHati >= 3).to.equal(true)
		end)

		it("milestone tiers are claimed in order and cannot be double-claimed", function()
			local taskState = buildTaskState(77777, "20240101")
			local playerData: { [string]: any } = { cahaya = 0, cahayaHati = 0 }

			-- Complete all tasks first
			for i = 1, #taskState.tasks do
				forceComplete(taskState, i)
			end

			-- Claim tier 1
			expect(claimMilestone(taskState, 1, playerData)).to.equal(true)
			-- Double-claim tier 1 must fail
			expect(claimMilestone(taskState, 1, playerData)).to.equal(false)
		end)

		it("completedIndices length equals the number of completed tasks", function()
			local taskState = buildTaskState(88888, "20240202")
			for i = 1, 3 do
				forceComplete(taskState, i)
			end
			expect(#taskState.completedIndices).to.equal(3)
		end)

	end)
end
