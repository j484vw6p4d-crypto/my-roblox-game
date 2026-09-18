--!strict
--[[
	Generates the playable world on a blank baseplate:
	wild zone, shop booth, lighting polish. Bases are created by BaseService.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Config = require(game.ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local function clearDefaultBaseplate()
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("BasePart") and (child.Name == "Baseplate" or child.Name == "SpawnLocation") then
			child:Destroy()
		end
	end
end

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	anchored: boolean?,
	canCollide: boolean?,
	parent: Instance,
	transparency: number?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Anchored = if props.anchored == nil then true else props.anchored
	p.CanCollide = if props.canCollide == nil then true else props.canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Transparency = props.transparency or 0
	p.Parent = props.parent
	return p
end

function WorldBuilder.build(): Folder
	clearDefaultBaseplate()

	local world = Instance.new("Folder")
	world.Name = "GameWorld"
	world.Parent = Workspace

	-- Ground plane under everything
	makePart({
		name = "Ground",
		size = Vector3.new(400, 2, 400),
		cframe = CFrame.new(0, -1, 0),
		color = Color3.fromRGB(34, 42, 55),
		material = Enum.Material.Slate,
		parent = world,
	})

	-- Wild zone platform
	local wz = Config.WildZone
	local wildFolder = Instance.new("Folder")
	wildFolder.Name = "WildZone"
	wildFolder.Parent = world

	local pad = makePart({
		name = "WildPad",
		size = Vector3.new(wz.size.X, 1, wz.size.Z),
		cframe = CFrame.new(wz.center.X, 0.5, wz.center.Z),
		color = Color3.fromRGB(55, 90, 110),
		material = Enum.Material.Grass,
		parent = wildFolder,
	})

	-- Soft border ring (visual only)
	local border = makePart({
		name = "WildBorder",
		size = Vector3.new(wz.size.X + 4, 0.4, wz.size.Z + 4),
		cframe = CFrame.new(wz.center.X, 0.85, wz.center.Z),
		color = Color3.fromRGB(100, 220, 255),
		material = Enum.Material.Neon,
		canCollide = false,
		transparency = 0.55,
		parent = wildFolder,
	})

	local label = Instance.new("BillboardGui")
	label.Name = "WildLabel"
	label.Size = UDim2.fromOffset(220, 40)
	label.StudsOffset = Vector3.new(0, 6, 0)
	label.AlwaysOnTop = true
	label.Parent = pad
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "✦ CRYSTAL WILDS ✦"
	text.TextColor3 = Color3.fromRGB(180, 240, 255)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = label

	-- Crystal spawn folder
	local crystalsFolder = Instance.new("Folder")
	crystalsFolder.Name = "Crystals"
	crystalsFolder.Parent = world

	-- Bases folder
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world

	-- Shop booth
	local shopFolder = Instance.new("Folder")
	shopFolder.Name = "Shop"
	shopFolder.Parent = world

	local shopPos = Config.Shop.position
	local booth = makePart({
		name = "ShopBooth",
		size = Vector3.new(14, 8, 10),
		cframe = CFrame.new(shopPos.X, 4, shopPos.Z),
		color = Color3.fromRGB(70, 50, 110),
		material = Enum.Material.SmoothPlastic,
		parent = shopFolder,
	})
	makePart({
		name = "ShopRoof",
		size = Vector3.new(16, 1, 12),
		cframe = CFrame.new(shopPos.X, 8.5, shopPos.Z),
		color = Color3.fromRGB(255, 200, 60),
		material = Enum.Material.Neon,
		parent = shopFolder,
	})
	local counter = makePart({
		name = "ShopCounter",
		size = Vector3.new(10, 2, 3),
		cframe = CFrame.new(shopPos.X, 1.5, shopPos.Z + 5),
		color = Color3.fromRGB(90, 70, 140),
		parent = shopFolder,
	})

	local shopPrompt = Instance.new("ProximityPrompt")
	shopPrompt.Name = "ShopPrompt"
	shopPrompt.ActionText = "Open Shop"
	shopPrompt.ObjectText = "Crystal Shop"
	shopPrompt.HoldDuration = 0.2
	shopPrompt.MaxActivationDistance = 12
	shopPrompt.RequiresLineOfSight = false
	shopPrompt.Parent = counter

	local shopBill = Instance.new("BillboardGui")
	shopBill.Size = UDim2.fromOffset(200, 50)
	shopBill.StudsOffset = Vector3.new(0, 6, 0)
	shopBill.AlwaysOnTop = true
	shopBill.Parent = booth
	local shopText = Instance.new("TextLabel")
	shopText.Size = UDim2.fromScale(1, 1)
	shopText.BackgroundTransparency = 1
	shopText.Text = "🛒 SHOP"
	shopText.TextColor3 = Color3.fromRGB(255, 230, 120)
	shopText.TextScaled = true
	shopText.Font = Enum.Font.GothamBold
	shopText.Parent = shopBill

	-- Central spawn for players who don't have a plot yet (brief)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 1, -40)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 0.3
	spawn.Color = Color3.fromRGB(100, 160, 255)
	spawn.Parent = world

	-- Lighting polish
	Lighting.Ambient = Color3.fromRGB(100, 100, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 130, 140)
	Lighting.Brightness = 2.2
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Parent = Lighting
	end
	atm.Density = 0.28
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(180, 200, 230)
	atm.Decay = Color3.fromRGB(100, 120, 160)
	atm.Glare = 0.15
	atm.Haze = 1.2

	return world
end

function WorldBuilder.getWildSpawnPoint(rng: Random?): Vector3
	local wz = Config.WildZone
	local r = rng or Random.new()
	local halfX = wz.size.X * 0.4
	local halfZ = wz.size.Z * 0.4
	local x = wz.center.X + r:NextNumber(-halfX, halfX)
	local z = wz.center.Z + r:NextNumber(-halfZ, halfZ)
	return Vector3.new(x, wz.spawnHeight, z)
end

return WorldBuilder
