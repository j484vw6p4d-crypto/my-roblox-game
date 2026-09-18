--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local DataService = {}
export type StoredRecord = { rarity: string, value: number }
export type PlayerData = { coins: number, crystalsCollected: number, ownedUpgrades: { [string]: boolean }, tutorialDone: boolean, storedCrystals: { StoredRecord }, version: number }
local DEFAULT: PlayerData = { coins = Config.StartingCoins, crystalsCollected = 0, ownedUpgrades = {}, tutorialDone = false, storedCrystals = {}, version = 2 }
local memory: { [number]: PlayerData } = {}
local store: DataStore? = nil
local storeAvailable = false
local function copyStored(list: { StoredRecord }): { StoredRecord }
	local out = {}
	for i = 1, #list do
		local item = list[i]
		if item then table.insert(out, { rarity = item.rarity, value = item.value }) end
	end
	return out
end
local function deepCopy(t: PlayerData): PlayerData
	local upgrades: { [string]: boolean } = {}
	for k, v in pairs(t.ownedUpgrades) do upgrades[k] = v end
	return { coins = t.coins, crystalsCollected = t.crystalsCollected, ownedUpgrades = upgrades, tutorialDone = t.tutorialDone, storedCrystals = copyStored(t.storedCrystals), version = t.version }
end
function DataService.init()
	if not Config.DataStore.enabled then storeAvailable = false return end
	local ok, result = pcall(function() return DataStoreService:GetDataStore(Config.DataStore.name) end)
	if ok and result then store = result storeAvailable = true else storeAvailable = false warn("[DataService] fallback", result) end
end
function DataService.load(player: Player): PlayerData
	local userId = player.UserId
	if memory[userId] then return memory[userId] end
	if storeAvailable and store then
		local ok, data = pcall(function() return store:GetAsync("p_" .. userId) end)
		if ok and typeof(data) == "table" then
			local merged = deepCopy(DEFAULT)
			if typeof(data.coins) == "number" then merged.coins = data.coins end
			if typeof(data.crystalsCollected) == "number" then merged.crystalsCollected = data.crystalsCollected end
			if typeof(data.ownedUpgrades) == "table" then for k, v in pairs(data.ownedUpgrades) do if v == true then merged.ownedUpgrades[k] = true end end end
			if typeof(data.tutorialDone) == "boolean" then merged.tutorialDone = data.tutorialDone end
			if typeof(data.storedCrystals) == "table" then
				merged.storedCrystals = {}
				for _, item in ipairs(data.storedCrystals) do
					if typeof(item) == "table" and typeof(item.rarity) == "string" then
						table.insert(merged.storedCrystals, { rarity = item.rarity, value = typeof(item.value) == "number" and item.value or 0 })
					end
				end
			end
			memory[userId] = merged
			return merged
		end
	end
	local fresh = deepCopy(DEFAULT)
	memory[userId] = fresh
	return fresh
end
function DataService.save(player: Player)
	local data = memory[player.UserId]
	if not data or not storeAvailable or not store then return end
	local ok, err = pcall(function() store:SetAsync("p_" .. player.UserId, deepCopy(data)) end)
	if not ok then warn("[DataService] Save failed", player.Name, err) end
end
function DataService.get(player: Player): PlayerData
	if not memory[player.UserId] then return DataService.load(player) end
	return memory[player.UserId]
end
function DataService.addCoins(player: Player, delta: number)
	local data = DataService.get(player)
	data.coins = math.max(0, data.coins + math.floor(delta))
end
function DataService.addCrystalCount(player: Player, delta: number)
	local data = DataService.get(player)
	data.crystalsCollected = math.max(0, data.crystalsCollected + math.floor(delta))
end
function DataService.ownUpgrade(player: Player, id: string) DataService.get(player).ownedUpgrades[id] = true end
function DataService.hasUpgrade(player: Player, id: string): boolean return DataService.get(player).ownedUpgrades[id] == true end
function DataService.setTutorialDone(player: Player) DataService.get(player).tutorialDone = true end
function DataService.setStored(player: Player, list: { StoredRecord }) DataService.get(player).storedCrystals = copyStored(list) end
function DataService.clear(player: Player) memory[player.UserId] = nil end
function DataService.startAutoSave()
	task.spawn(function()
		while true do
			task.wait(Config.DataStore.autoSaveInterval)
			for _, player in ipairs(Players:GetPlayers()) do DataService.save(player) end
		end
	end)
end
return DataService
