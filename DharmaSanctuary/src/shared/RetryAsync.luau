--[[
    RetryAsync.luau
    ───────────────
    Retries an async function up to maxAttempts times with a fixed delay between attempts.
    Used by DataService and IkatanService for all DataStore calls.
]]

local RetryAsync = {}

-- run(fn, maxAttempts, delaySeconds) -> (success, result)
-- Returns true + result on first success, or false + nil after all attempts fail.
function RetryAsync.run(fn: () -> any, maxAttempts: number, delaySeconds: number): (boolean, any)
	local lastErr: any
	for attempt = 1, maxAttempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		warn(string.format("[RetryAsync] Attempt %d/%d failed: %s", attempt, maxAttempts, tostring(result)))
		if attempt < maxAttempts then
			task.wait(delaySeconds)
		end
	end
	warn(string.format("[RetryAsync] All %d attempts exhausted. Last error: %s", maxAttempts, tostring(lastErr)))
	return false, nil
end

return RetryAsync
