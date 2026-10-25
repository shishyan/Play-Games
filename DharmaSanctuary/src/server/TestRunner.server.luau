--[[
    TestRunner.server.luau
    ──────────────────────
    T-133: Studio-only TestEZ bootstrap. Scans Server for *.spec ModuleScripts
    and runs them with TestEZ. Prints pass/fail count to output.
]]

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local TestEZ   = require(Packages.TestEZ)

-- Collect all *.spec ModuleScripts under ServerScriptService.Server
local roots: { ModuleScript } = {}
local server = ServerScriptService:WaitForChild("Server")

for _, desc in server:GetDescendants() do
	if desc:IsA("ModuleScript") and desc.Name:match("%.spec$") then
		table.insert(roots, desc :: ModuleScript)
	end
end

if #roots == 0 then
	warn("[TestRunner] No *.spec files found under Server.")
	return
end

print(string.format("[TestRunner] Discovered %d spec file(s). Running tests...", #roots))

local results = TestEZ.TestBootstrap:run(roots)

local passed  = (results :: any).successCount  or 0
local failed  = (results :: any).failureCount  or 0
local skipped = (results :: any).skippedCount  or 0

print(string.format("[TestRunner] %d passed  |  %d failed  |  %d skipped", passed, failed, skipped))

if failed > 0 then
	warn("[TestRunner] SOME TESTS FAILED — scroll up for details.")
end
