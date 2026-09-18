--!strict
--[[
	Personal crystal bases (plots): pedestals, sell pad, lock state, NPC demo base.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local BaseService = {}

export type StoredCrystal = {
	id: string,
	rarity: string,
	value: number,
	part: BasePart,
}

export type PlotState = {
	index: number,
	owner: Player?,
	isNPC: boolean,
	model: Model,
	center: Vector3,
	pedestals: { BasePart },
	slots: { StoredCrystal? },
	sellPad: BasePart,
	spawnPart: BasePart,
	lockedUntil: number,
	ownerName: string,
}

local plots: { PlotState } = {}
local playerToPlot: { [number]: number } = {}
local rng = Random.new()

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function plotCenter(index: number): Vector3
	local n = Config.Base.maxPlots
	local angle = ((index - 1) / n) * math.pi * 2 + math.pi / n
	local r = Config.Base.ringRadius
	return Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

local function buildPlotModel(index: number, ownerName: string): (Model, { BasePart }, BasePart, BasePart)
	local center = plotCenter(index)
	local model = Instance.new("Model")
	model.Name = "Plot_" .. index
	model.Parent = Workspace:WaitForChild("GameWorld"):WaitForChild("Bases")

	local cfg = Config.Base
	local floor = makePart(
		"Floor",
		cfg.plotSize,
		CFrame.new(center + Vector3.new(0, 0.5, 0)),
		cfg.floorColor,
		model,
		Enum.Material.Concrete
	)

	-- Low walls on three sides (open toward wild zone)
	local toWild = (Vector3.new(0, 0, 0) - center)
	local facing = CFrame.lookAt(center, Vector3.new(0, center.Y, 0))
	local half = cfg.plotSize.X / 2

	makePart("WallBack", Vector3.new(cfg.plotSize.X, cfg.wallHeight, 1), facing * CFrame.new(0, cfg.wallHeight / 2, half), cfg.accentColor, model)
	makePart("WallL", Vector3.new(1, cfg.wallHeight, cfg.plotSize.Z), facing * CFrame.new(-half, cfg.wallHeight / 2, 0), cfg.accentColor, model)
	makePart("WallR", Vector3.new(1, cfg.wallHeight, cfg.plotSize.Z), facing * CFrame.new(half, cfg.wallHeight / 2, 0), cfg.accentColor, model)

	-- Pedestals in a ring
	local pedestals: { BasePart } = {}
	local slots = cfg.pedestalSlots
	for i = 1, slots do
		local a = ((i - 1) / slots) * math.pi * 2
		local offset = Vector3.new(math.cos(a) * cfg.pedestalRadius, 1.25, math.sin(a) * cfg.pedestalRadius)
		local ped = makePart(
			"Pedestal_" .. i,
			Vector3.new(2.2, 1.5, 2.2),
			CFrame.new(center + offset),
			Color3.fromRGB(70, 80, 100),
			model,
			Enum.Material.Marble
		)
		ped:SetAttribute("SlotIndex", i)
		table.insert(pedestals, ped)
	end

	-- Sell pad toward wild zone
	local sellOffset = facing.LookVector * (-half + 4) -- toward center/wild
	-- Actually face inward: LookVector of facing points toward origin
	local sellPos = center + facing.LookVector * (half - 5) + Vector3.new(0, 0.75, 0)
	local sellPad = makePart(
		"SellPad",
		cfg.sellPadSize,
		CFrame.new(sellPos),
		Color3.fromRGB(255, 200, 50),
		model,
		Enum.Material.Neon
	)
	sellPad:SetAttribute("IsSellPad", true)

	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.Name = "SellPrompt"
	sellPrompt.ActionText = "Sell Crystals"
	sellPrompt.ObjectText = "Sell Pad"
	sellPrompt.HoldDuration = 0.4
	sellPrompt.MaxActivationDistance = 10
	sellPrompt.RequiresLineOfSight = false
	sellPrompt.Parent = sellPad

	local sellBill = Instance.new("BillboardGui")
	sellBill.Size = UDim2.fromOffset(140, 36)
	sellBill.StudsOffset = Vector3.new(0, 2.5, 0)
	sellBill.AlwaysOnTop = true
	sellBill.Parent = sellPad
	local st = Instance.new("TextLabel")
	st.Size = UDim2.fromScale(1, 1)
	st.BackgroundTransparency = 1
	st.Text = "💰 SELL"
	st.TextColor3 = Color3.fromRGB(255, 255, 180)
	st.TextScaled = true
	st.Font = Enum.Font.GothamBold
	st.Parent = sellBill

	-- Owner sign
	local sign = makePart("Sign", Vector3.new(8, 3, 0.4), facing * CFrame.new(0, 5, half + 0.5), Color3.fromRGB(40, 45, 60), model)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "OwnerLabel"
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ownerName .. "'s Base"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = signGui

	local spawnPart = makePart(
		"PlotSpawn",
		Vector3.new(4, 1, 4),
		CFrame.new(center + Vector3.new(0, 1, 0)),
		Color3.fromRGB(80, 120, 200),
		model
	)
	spawnPart.Transparency = 0.5
	spawnPart.CanCollide = false

	model.PrimaryPart = floor
	return model, pedestals, sellPad, spawnPart
end

function BaseService.createAllPlots()
	plots = {}
	playerToPlot = {}
	for i = 1, Config.Base.maxPlots do
		local model, pedestals, sellPad, spawnPart = buildPlotModel(i, "Empty")
		local state: PlotState = {
			index = i,
			owner = nil,
			isNPC = false,
			model = model,
			center = plotCenter(i),
			pedestals = pedestals,
			slots = table.create(Config.Base.pedestalSlots),
			sellPad = sellPad,
			spawnPart = spawnPart,
			lockedUntil = 0,
			ownerName = "Empty",
		}
		model:SetAttribute("PlotIndex", i)
		table.insert(plots, state)
	end
end

local function setOwnerLabel(plot: PlotState, name: string)
	plot.ownerName = name
	local sign = plot.model:FindFirstChild("Sign")
	if sign then
		local sg = sign:FindFirstChildOfClass("SurfaceGui")
		if sg then
			local label = sg:FindFirstChild("OwnerLabel") :: TextLabel?
			if label then
				label.Text = name .. "'s Base"
			end
		end
	end
end

function BaseService.assignPlot(player: Player): PlotState?
	-- Prefer free non-NPC plots
	for _, plot in ipairs(plots) do
		if plot.owner == nil and not plot.isNPC then
			plot.owner = player
			playerToPlot[player.UserId] = plot.index
			setOwnerLabel(plot, player.DisplayName)
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			return plot
		end
	end
	return nil
end

function BaseService.releasePlot(player: Player)
	local idx = playerToPlot[player.UserId]
	if not idx then
		return
	end
	local plot = plots[idx]
	if not plot then
		return
	end
	-- Clear stored crystals
	for i, stored in ipairs(plot.slots) do
		if stored and stored.part then
			stored.part:Destroy()
		end
		plot.slots[i] = nil
	end
	plot.owner = nil
	plot.lockedUntil = 0
	setOwnerLabel(plot, "Empty")
	plot.model:SetAttribute("OwnerUserId", 0)
	playerToPlot[player.UserId] = nil
end

function BaseService.getPlot(player: Player): PlotState?
	local idx = playerToPlot[player.UserId]
	if idx then
		return plots[idx]
	end
	return nil
end

function BaseService.getPlotByIndex(index: number): PlotState?
	return plots[index]
end

function BaseService.getAllPlots(): { PlotState }
	return plots
end

function BaseService.isLocked(plot: PlotState): boolean
	return os.clock() < plot.lockedUntil
end

function BaseService.lockPlot(plot: PlotState, duration: number)
	plot.lockedUntil = os.clock() + duration
	-- Visual flash
	local floor = plot.model:FindFirstChild("Floor") :: BasePart?
	if floor then
		local orig = floor.Color
		floor.Color = Color3.fromRGB(80, 200, 255)
		task.delay(duration, function()
			if floor.Parent then
				floor.Color = orig
			end
		end)
	end
end

function BaseService.findFreeSlot(plot: PlotState): number?
	for i = 1, #plot.pedestals do
		if plot.slots[i] == nil then
			return i
		end
	end
	return nil
end

function BaseService.createCrystalPart(rarity: string, parent: Instance, cframe: CFrame): Part
	local rcfg = Config.Rarities[rarity]
	assert(rcfg, "Unknown rarity " .. tostring(rarity))
	local size = rcfg.size
	local part = Instance.new("Part")
	part.Name = "Crystal_" .. rarity
	part.Size = Vector3.new(size, size * 1.4, size)
	part.CFrame = cframe
	part.Color = rcfg.color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball -- approximate gem; Mesh below
	part.Parent = parent

	-- Diamond-ish look via SpecialMesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(0.85, 1.25, 0.85)
	mesh.Parent = part

	local light = Instance.new("PointLight")
	light.Color = rcfg.color
	light.Brightness = 1 + rcfg.glow
	light.Range = 8 + rcfg.glow * 6
	light.Parent = part

	part:SetAttribute("Rarity", rarity)
	part:SetAttribute("Value", rcfg.value)

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(100, 28)
	bill.StudsOffset = Vector3.new(0, size * 0.9, 0)
	bill.AlwaysOnTop = true
	bill.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = rcfg.displayName
	t.TextColor3 = rcfg.color
	t.TextStrokeTransparency = 0.4
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.Parent = bill

	return part
end

local idCounter = 0
local function nextCrystalId(): string
	idCounter += 1
	return string.format("c_%d_%d", math.floor(os.clock() * 1000), idCounter)
end

function BaseService.placeCrystal(plot: PlotState, rarity: string, value: number): boolean
	local slot = BaseService.findFreeSlot(plot)
	if not slot then
		return false
	end
	local ped = plot.pedestals[slot]
	local id = nextCrystalId()
	local part = BaseService.createCrystalPart(rarity, plot.model, ped.CFrame * CFrame.new(0, 1.8, 0))
	part:SetAttribute("CrystalId", id)
	part:SetAttribute("Stored", true)

	-- Steal prompt for non-owners
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = rarity .. " Crystal"
	prompt.HoldDuration = Config.Steal.promptHoldDuration
	prompt.MaxActivationDistance = Config.Steal.promptMaxDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	plot.slots[slot] = {
		id = id,
		rarity = rarity,
		value = value,
		part = part,
	}
	return true
end

function BaseService.removeStoredCrystal(plot: PlotState, crystalId: string): StoredCrystal?
	for i, stored in ipairs(plot.slots) do
		if stored and stored.id == crystalId then
			plot.slots[i] = nil
			return stored
		end
	end
	return nil
end

function BaseService.getStoredByPart(part: BasePart): (PlotState?, StoredCrystal?, number?)
	for _, plot in ipairs(plots) do
		for i, stored in ipairs(plot.slots) do
			if stored and stored.part == part then
				return plot, stored, i
			end
		end
	end
	return nil, nil, nil
end

function BaseService.countStored(plot: PlotState): number
	local n = 0
	for _, s in ipairs(plot.slots) do
		if s then
			n += 1
		end
	end
	return n
end

function BaseService.sellAll(plot: PlotState): (number, number)
	local total = 0
	local count = 0
	for i, stored in ipairs(plot.slots) do
		if stored then
			total += stored.value
			count += 1
			if stored.part then
				stored.part:Destroy()
			end
			plot.slots[i] = nil
		end
	end
	return total, count
end

function BaseService.teleportToPlot(player: Player)
	local plot = BaseService.getPlot(player)
	if not plot then
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = plot.spawnPart.CFrame + Vector3.new(0, 3, 0)
	end
end

function BaseService.createNPCBase()
	if not Config.NPC.enabled then
		return
	end
	-- Use last plot for NPC so players get earlier ones
	local idx = Config.Base.maxPlots
	local plot = plots[idx]
	if not plot then
		return
	end
	plot.isNPC = true
	plot.owner = nil
	setOwnerLabel(plot, Config.NPC.name)
	plot.model:SetAttribute("IsNPC", true)

	-- Simple NPC figure
	local npcModel = Instance.new("Model")
	npcModel.Name = "NPC"
	npcModel.Parent = plot.model

	local torso = makePart("Torso", Vector3.new(2, 2, 1), CFrame.new(plot.center + Vector3.new(0, 3, 0)), Color3.fromRGB(200, 80, 80), npcModel)
	local head = makePart("Head", Vector3.new(1.2, 1.2, 1.2), torso.CFrame * CFrame.new(0, 1.6, 0), Color3.fromRGB(255, 210, 180), npcModel)
	head.Shape = Enum.PartType.Ball
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = npcModel
	npcModel.PrimaryPart = torso

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(160, 40)
	bill.StudsOffset = Vector3.new(0, 3, 0)
	bill.AlwaysOnTop = true
	bill.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = Config.NPC.name .. "\n(Demo — steal me!)"
	t.TextColor3 = Color3.fromRGB(255, 200, 200)
	t.TextScaled = true
	t.Font = Enum.Font.Gotham
	t.Parent = bill

	-- Place one stealable crystal
	BaseService.placeCrystal(plot, Config.NPC.crystalRarity, Config.Rarities[Config.NPC.crystalRarity].value)
end

return BaseService
