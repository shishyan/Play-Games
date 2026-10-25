--!strict
--[[
    RemoteUtils.luau
    ─────────────────
    T-131: Safe wrappers for RemoteEvent:FireClient and :FireAllClients.
    A disconnected or throttled player must not crash server-side logic.
]]

local RemoteUtils = {}

function RemoteUtils.fireClient(remote: RemoteEvent, player: Player, payload: any)
	local ok, err = pcall(remote.FireClient, remote, player, payload)
	if not ok then
		warn("[" .. remote.Name .. "] FireClient error:", err)
	end
end

function RemoteUtils.fireAllClients(remote: RemoteEvent, payload: any)
	local ok, err = pcall(remote.FireAllClients, remote, payload)
	if not ok then
		warn("[" .. remote.Name .. "] FireAllClients error:", err)
	end
end

return RemoteUtils
