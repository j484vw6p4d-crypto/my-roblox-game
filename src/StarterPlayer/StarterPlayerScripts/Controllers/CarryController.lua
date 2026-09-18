--!strict
--[[
	Tracks local carry count from character children for HUD.
]]

local Players = game:GetService("Players")

local UIController = require(script.Parent.UIController)

local CarryController = {}

local player = Players.LocalPlayer

local function countCarried(char: Model): number
	local n = 0
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("Carried") == true then
			n += 1
		end
	end
	return n
end

local function watch(char: Model)
	local function refresh()
		UIController.setCarried(countCarried(char))
	end
	refresh()
	char.ChildAdded:Connect(refresh)
	char.ChildRemoved:Connect(refresh)
end

function CarryController.init()
	if player.Character then
		watch(player.Character)
	end
	player.CharacterAdded:Connect(watch)
end

return CarryController
