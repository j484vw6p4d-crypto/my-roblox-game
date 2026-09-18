--!strict
--[[
	Steal a Crystal — client entry point.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
-- Ensure remotes folder exists (server creates; wait)
ReplicatedStorage:WaitForChild("Remotes")

local Controllers = script.Parent:WaitForChild("Controllers")
local UIController = require(Controllers:WaitForChild("UIController"))
local TutorialController = require(Controllers:WaitForChild("TutorialController"))
local CarryController = require(Controllers:WaitForChild("CarryController"))

UIController.init()
TutorialController.init()
CarryController.init()

print("[Steal a Crystal] Client ready")
