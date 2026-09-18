--!strict
--[[
	Optional DataStore with pcall + in-memory fallback for Studio Play Solo.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)

local DataService = {}

export type PlayerData = {
	coins: number,
	crystalsCollected: number,
	ownedUpgrades: { [string]: boolean },
	tutorialDone: boolean,
	version: number,
}

local DEFAULT: PlayerData = {
	coins = Config.StartingCoins,
	crystalsCollected = 0,
	ownedUpgrades = {},
	tutorialDone = false,
	version = 1,
}

local memory: { [number]: PlayerData } = {}
local store: DataStore? = nil
local storeAvailable = false

local function deepCopy(t: PlayerData): PlayerData
	local upgrades: { [string]: boolean } = {}
	for k, v in pairs(t.ownedUpgrades) do
		upgrades[k] = v
	end
	return {
		coins = t.coins,
		crystalsCollected = t.crystalsCollected,
		ownedUpgrades = upgrades,
		tutorialDone = t.tutorialDone,
		version = t.version,
	}
end

function DataService.init()
	if not Config.DataStore.enabled then
		storeAvailable = false
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStore.name)
	end)
	if ok and result then
		store = result
		storeAvailable = true
	else
		storeAvailable = false
		warn("[DataService] DataStore unavailable — using in-memory fallback. Reason:", result)
	end
end

function DataService.getDefault(): PlayerData
	return deepCopy(DEFAULT)
end

function DataService.load(player: Player): PlayerData
	local userId = player.UserId
	if memory[userId] then
		return memory[userId]
	end

	if storeAvailable and store then
		local ok, data = pcall(function()
			return store:GetAsync("p_" .. userId)
		end)
		if ok and typeof(data) == "table" then
			local merged = deepCopy(DEFAULT)
			if typeof(data.coins) == "number" then
				merged.coins = data.coins
			end
			if typeof(data.crystalsCollected) == "number" then
				merged.crystalsCollected = data.crystalsCollected
			end
			if typeof(data.ownedUpgrades) == "table" then
				for k, v in pairs(data.ownedUpgrades) do
					if v == true then
						merged.ownedUpgrades[k] = true
					end
				end
			end
			if typeof(data.tutorialDone) == "boolean" then
				merged.tutorialDone = data.tutorialDone
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
	local userId = player.UserId
	local data = memory[userId]
	if not data then
		return
	end
	if not storeAvailable or not store then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync("p_" .. userId, deepCopy(data))
	end)
	if not ok then
		warn("[DataService] Save failed for", player.Name, err)
	end
end

function DataService.get(player: Player): PlayerData
	local userId = player.UserId
	if not memory[userId] then
		return DataService.load(player)
	end
	return memory[userId]
end

function DataService.setCoins(player: Player, amount: number)
	local data = DataService.get(player)
	data.coins = math.max(0, math.floor(amount))
end

function DataService.addCoins(player: Player, delta: number)
	local data = DataService.get(player)
	data.coins = math.max(0, data.coins + math.floor(delta))
end

function DataService.addCrystalCount(player: Player, delta: number)
	local data = DataService.get(player)
	data.crystalsCollected = math.max(0, data.crystalsCollected + math.floor(delta))
end

function DataService.ownUpgrade(player: Player, id: string)
	local data = DataService.get(player)
	data.ownedUpgrades[id] = true
end

function DataService.hasUpgrade(player: Player, id: string): boolean
	local data = DataService.get(player)
	return data.ownedUpgrades[id] == true
end

function DataService.setTutorialDone(player: Player)
	local data = DataService.get(player)
	data.tutorialDone = true
end

function DataService.clear(player: Player)
	memory[player.UserId] = nil
end

function DataService.startAutoSave()
	task.spawn(function()
		while true do
			task.wait(Config.DataStore.autoSaveInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				DataService.save(player)
			end
		end
	end)
end

return DataService
