--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Config = require(Shared:WaitForChild("Config"))
local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local WorldBuilder = require(Services:WaitForChild("WorldBuilder"))
local BaseService = require(Services:WaitForChild("BaseService"))
local EconomyService = require(Services:WaitForChild("EconomyService"))
local CrystalService = require(Services:WaitForChild("CrystalService"))
local ShopService = require(Services:WaitForChild("ShopService"))
local CopService = require(Services:WaitForChild("CopService"))
print("[Steal a Crystal] Booting…")
Remotes.init()
DataService.init()
DataService.startAutoSave()
local world = WorldBuilder.build()
BaseService.createAllPlots()
BaseService.createNPCBase()
local crystalsFolder = world:WaitForChild("Crystals") :: Folder
CrystalService.init(crystalsFolder)
ShopService.init()
CopService.init(CrystalService)
Remotes.get("PlaceCrystal").OnServerEvent:Connect(function(player) CrystalService.tryPlace(player) end)
Remotes.get("SellCrystals").OnServerEvent:Connect(function(player) CrystalService.trySell(player) end)
Remotes.get("BuyShopItem").OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" or #itemId > 64 then return end
	ShopService.tryBuy(player, itemId)
end)
Remotes.get("DropCarried").OnServerEvent:Connect(function(player)
	CrystalService.dropAll(player, "You dropped your crystals.")
end)
Remotes.get("TutorialDone").OnServerEvent:Connect(function(player) DataService.setTutorialDone(player) end)
Remotes.get("OpenShop").OnServerEvent:Connect(function(player) ShopService.sendCatalog(player) end)
local function restoreStored(player: Player)
	local plot = BaseService.getPlot(player)
	if not plot then return end
	local data = DataService.get(player)
	for _, rec in ipairs(data.storedCrystals) do
		if Config.Rarities[rec.rarity] then BaseService.placeCrystal(plot, rec.rarity, rec.value) end
	end
end
local function snapshotStored(player: Player)
	local plot = BaseService.getPlot(player)
	if not plot then return end
	local list = {}
	for i = 1, #plot.pedestals do
		local stored = plot.slots[i]
		if stored then table.insert(list, { rarity = stored.rarity, value = stored.value }) end
	end
	DataService.setStored(player, list)
end
local function onCharacter(player: Player, _char: Model)
	task.wait(0.3)
	EconomyService.applyCharacterStats(player)
	BaseService.teleportToPlot(player)
end
local function onPlayerAdded(player: Player)
	EconomyService.setupPlayer(player)
	local plot = BaseService.assignPlot(player)
	if not plot then warn("[Steal a Crystal] No free plots for", player.Name) else restoreStored(player) end
	CrystalService.bindOwnerTouchDrop(player)
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then onCharacter(player, player.Character) end
	task.defer(function()
		EconomyService.sync(player)
		local data = DataService.get(player)
		if not data.tutorialDone then
			Remotes.get("Notify"):FireClient(player, { text = "tutorial_start", kind = "tutorial" })
		end
	end)
end
local function onPlayerRemoving(player: Player)
	snapshotStored(player)
	DataService.save(player)
	CrystalService.onPlayerRemoving(player)
	CopService.onPlayerRemoving(player)
	BaseService.releasePlot(player)
	DataService.clear(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do snapshotStored(p) DataService.save(p) end
	task.wait(1)
end)
print("[Steal a Crystal] Ready. Plots:", Config.Base.maxPlots, "| Wild max:", Config.WildZone.maxCrystals)
