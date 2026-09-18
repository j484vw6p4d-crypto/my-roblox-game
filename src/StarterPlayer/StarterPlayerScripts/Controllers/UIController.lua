--!strict
--[[
	HUD: coins/crystals toast, carry hint, shop panel.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Config = require(game.ReplicatedStorage.Shared.Config)

local UIController = {}

local player = Players.LocalPlayer
local playerGui: PlayerGui
local hud: ScreenGui
local toastFrame: Frame
local shopFrame: Frame
local shopList: ScrollingFrame
local carryLabel: TextLabel
local hintLabel: TextLabel

local shopOpen = false
local stats = {
	coins = 0,
	crystals = 0,
	carryCapacity = 1,
	carried = 0,
}

local function makeCorner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
end

local function makeStroke(parent: Instance, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = 1.5
	s.Transparency = 0.4
	s.Parent = parent
end

function UIController.showToast(text: string, kind: string?)
	local color = Color3.fromRGB(230, 240, 255)
	if kind == "success" then
		color = Color3.fromRGB(120, 255, 160)
	elseif kind == "warn" then
		color = Color3.fromRGB(255, 180, 100)
	elseif kind == "tutorial" then
		return -- handled by TutorialController
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 0, 32)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
	label.BackgroundTransparency = 0.15
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextWrapped = true
	label.Parent = toastFrame
	makeCorner(label, 6)

	local layout = toastFrame:FindFirstChildOfClass("UIListLayout")
	task.delay(3.2, function()
		if label.Parent then
			local tw = TweenService:Create(label, TweenInfo.new(0.35), { BackgroundTransparency = 1, TextTransparency = 1 })
			tw:Play()
			tw.Completed:Wait()
			label:Destroy()
		end
	end)
end

local function rebuildShop(catalog: { any })
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, item in ipairs(catalog) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 72)
		row.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
		row.Parent = shopList
		makeCorner(row, 8)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -120, 0, 28)
		title.Position = UDim2.fromOffset(12, 8)
		title.BackgroundTransparency = 1
		title.Text = item.name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 18
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -120, 0, 28)
		desc.Position = UDim2.fromOffset(12, 36)
		desc.BackgroundTransparency = 1
		desc.Text = item.description
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextColor3 = Color3.fromRGB(180, 190, 210)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 14
		desc.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(100, 40)
		btn.Position = UDim2.new(1, -112, 0.5, -20)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.AutoButtonColor = true
		makeCorner(btn, 6)
		btn.Parent = row

		if item.owned then
			btn.Text = "Owned"
			btn.BackgroundColor3 = Color3.fromRGB(60, 70, 90)
			btn.TextColor3 = Color3.fromRGB(160, 160, 160)
			btn.Active = false
		else
			btn.Text = item.cost .. " 🪙"
			btn.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.MouseButton1Click:Connect(function()
				Remotes.get("BuyShopItem"):FireServer(item.id)
			end)
		end
	end
end

function UIController.setShopOpen(open: boolean)
	shopOpen = open
	shopFrame.Visible = open
end

function UIController.toggleShop()
	UIController.setShopOpen(not shopOpen)
end

function UIController.updateStats(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	if typeof(payload.coins) == "number" then
		stats.coins = payload.coins
	end
	if typeof(payload.crystals) == "number" then
		stats.crystals = payload.crystals
	end
	if typeof(payload.carryCapacity) == "number" then
		stats.carryCapacity = payload.carryCapacity
	end
	carryLabel.Text = string.format("Carry  %d / %d", stats.carried, stats.carryCapacity)
end

function UIController.setCarried(n: number)
	stats.carried = n
	carryLabel.Text = string.format("Carry  %d / %d", stats.carried, stats.carryCapacity)
end

function UIController.init()
	playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	hud = Instance.new("ScreenGui")
	hud.Name = "StealACrystalHUD"
	hud.ResetOnSpawn = false
	hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hud.Parent = playerGui

	-- Top bar
	local top = Instance.new("Frame")
	top.Name = "TopBar"
	top.Size = UDim2.new(0, 320, 0, 48)
	top.Position = UDim2.new(0.5, -160, 0, 12)
	top.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
	top.BackgroundTransparency = 0.2
	top.Parent = hud
	makeCorner(top, 10)
	makeStroke(top, Color3.fromRGB(120, 160, 255))

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = "💎 Steal a Crystal"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextColor3 = Color3.fromRGB(200, 230, 255)
	title.Parent = top

	carryLabel = Instance.new("TextLabel")
	carryLabel.Size = UDim2.new(0, 160, 0, 36)
	carryLabel.Position = UDim2.new(0, 16, 1, -52)
	carryLabel.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
	carryLabel.BackgroundTransparency = 0.2
	carryLabel.Text = "Carry  0 / 1"
	carryLabel.Font = Enum.Font.GothamMedium
	carryLabel.TextSize = 16
	carryLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
	carryLabel.Parent = hud
	makeCorner(carryLabel, 8)

	hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(0, 280, 0, 36)
	hintLabel.Position = UDim2.new(1, -296, 1, -52)
	hintLabel.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
	hintLabel.BackgroundTransparency = 0.25
	hintLabel.Text = "[E] Place  ·  [G] Drop  ·  [B] Shop"
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextSize = 14
	hintLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
	hintLabel.Parent = hud
	makeCorner(hintLabel, 8)

	toastFrame = Instance.new("Frame")
	toastFrame.Name = "Toasts"
	toastFrame.Size = UDim2.new(0, 360, 0, 200)
	toastFrame.Position = UDim2.new(0.5, -180, 0, 70)
	toastFrame.BackgroundTransparency = 1
	toastFrame.Parent = hud
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = toastFrame

	-- Shop panel
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "Shop"
	shopFrame.Size = UDim2.new(0, 420, 0, 460)
	shopFrame.Position = UDim2.new(0.5, -210, 0.5, -230)
	shopFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 48)
	shopFrame.Visible = false
	shopFrame.Parent = hud
	makeCorner(shopFrame, 12)
	makeStroke(shopFrame, Color3.fromRGB(255, 200, 80))

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, -50, 0, 48)
	shopTitle.Position = UDim2.fromOffset(16, 8)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Text = "🛒 Crystal Shop"
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextSize = 24
	shopTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
	shopTitle.Parent = shopFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.Position = UDim2.new(1, -48, 0, 12)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Parent = shopFrame
	makeCorner(closeBtn, 8)
	closeBtn.MouseButton1Click:Connect(function()
		UIController.setShopOpen(false)
	end)

	shopList = Instance.new("ScrollingFrame")
	shopList.Size = UDim2.new(1, -24, 1, -72)
	shopList.Position = UDim2.fromOffset(12, 60)
	shopList.BackgroundTransparency = 1
	shopList.ScrollBarThickness = 6
	shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopList.Parent = shopFrame
	local shopLayout = Instance.new("UIListLayout")
	shopLayout.Padding = UDim.new(0, 8)
	shopLayout.Parent = shopList

	Remotes.get("Notify").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and typeof(payload.text) == "string" then
			if payload.kind == "tutorial" then
				return
			end
			UIController.showToast(payload.text, payload.kind)
		end
	end)

	Remotes.get("UpdateStats").OnClientEvent:Connect(function(payload)
		UIController.updateStats(payload)
	end)

	Remotes.get("ShopData").OnClientEvent:Connect(function(catalog)
		if typeof(catalog) == "table" then
			rebuildShop(catalog)
		end
	end)

	Remotes.get("OpenShop").OnClientEvent:Connect(function()
		UIController.setShopOpen(true)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.G then
			Remotes.get("DropCarried"):FireServer()
		elseif input.KeyCode == Enum.KeyCode.E then
			Remotes.get("PlaceCrystal"):FireServer()
		elseif input.KeyCode == Enum.KeyCode.B then
			-- Request shop if near; server still validates buy distance
			Remotes.get("OpenShop"):FireServer()
			UIController.toggleShop()
		end
	end)
end

return UIController
