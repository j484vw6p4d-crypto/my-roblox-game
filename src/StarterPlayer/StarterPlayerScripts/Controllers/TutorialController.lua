--!strict
--[[
	Soft first-join tutorial overlay.
]]

local Players = game:GetService("Players")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Config = require(game.ReplicatedStorage.Shared.Config)

local TutorialController = {}

local player = Players.LocalPlayer
local gui: ScreenGui?
local stepIndex = 1
local active = false

function TutorialController.start()
	if active then
		return
	end
	active = true
	stepIndex = 1

	local pg = player:WaitForChild("PlayerGui") :: PlayerGui
	gui = Instance.new("ScreenGui")
	gui.Name = "TutorialGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = pg

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 480, 0, 160)
	panel.Position = UDim2.new(0.5, -240, 1, -200)
	panel.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
	panel.BackgroundTransparency = 0.1
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 200, 255)
	stroke.Thickness = 2
	stroke.Parent = panel

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -24, 0, 28)
	header.Position = UDim2.fromOffset(12, 10)
	header.BackgroundTransparency = 1
	header.Text = "How to play"
	header.Font = Enum.Font.GothamBold
	header.TextSize = 20
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Color3.fromRGB(160, 220, 255)
	header.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -24, 0, 60)
	body.Position = UDim2.fromOffset(12, 44)
	body.BackgroundTransparency = 1
	body.TextWrapped = true
	body.Font = Enum.Font.Gotham
	body.TextSize = 16
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(230, 235, 245)
	body.Parent = panel

	local nextBtn = Instance.new("TextButton")
	nextBtn.Size = UDim2.fromOffset(120, 36)
	nextBtn.Position = UDim2.new(1, -140, 1, -48)
	nextBtn.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
	nextBtn.Text = "Next"
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.TextSize = 16
	nextBtn.TextColor3 = Color3.new(1, 1, 1)
	nextBtn.Parent = panel
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = nextBtn

	local skipBtn = Instance.new("TextButton")
	skipBtn.Size = UDim2.fromOffset(80, 36)
	skipBtn.Position = UDim2.new(1, -230, 1, -48)
	skipBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 75)
	skipBtn.Text = "Skip"
	skipBtn.Font = Enum.Font.Gotham
	skipBtn.TextSize = 14
	skipBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
	skipBtn.Parent = panel
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = skipBtn

	local function render()
		local steps = Config.Tutorial.steps
		body.Text = string.format("(%d/%d)  %s", stepIndex, #steps, steps[stepIndex])
		if stepIndex >= #steps then
			nextBtn.Text = "Let's go!"
		else
			nextBtn.Text = "Next"
		end
	end

	local function finish()
		active = false
		Remotes.get("TutorialDone"):FireServer()
		if gui then
			gui:Destroy()
			gui = nil
		end
	end

	nextBtn.MouseButton1Click:Connect(function()
		if stepIndex >= #Config.Tutorial.steps then
			finish()
		else
			stepIndex += 1
			render()
		end
	end)
	skipBtn.MouseButton1Click:Connect(finish)

	render()
end

function TutorialController.init()
	Remotes.get("Notify").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and payload.kind == "tutorial" then
			TutorialController.start()
		end
	end)
end

return TutorialController
