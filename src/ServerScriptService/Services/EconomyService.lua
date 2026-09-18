--!strict
--[[
	Leaderstats + coin / crystal count helpers. Server-authoritative.
]]

local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local EconomyService = {}

local function ensureLeaderstats(player: Player): Folder
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:IsA("Folder") then
		return ls
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = folder

	local crystals = Instance.new("IntValue")
	crystals.Name = "Crystals"
	crystals.Value = 0
	crystals.Parent = folder

	return folder
end

function EconomyService.sync(player: Player)
	local data = DataService.get(player)
	local ls = ensureLeaderstats(player)
	local coins = ls:FindFirstChild("Coins") :: IntValue
	local crystals = ls:FindFirstChild("Crystals") :: IntValue
	coins.Value = data.coins
	crystals.Value = data.crystalsCollected

	Remotes.get("UpdateStats"):FireClient(player, {
		coins = data.coins,
		crystals = data.crystalsCollected,
		carryCapacity = EconomyService.getCarryCapacity(player),
		walkSpeed = EconomyService.getWalkSpeed(player),
		luckBonus = EconomyService.getLuckBonus(player),
		hasBaseLock = DataService.hasUpgrade(player, "BaseLock"),
		ownedUpgrades = data.ownedUpgrades,
	})
end

function EconomyService.setupPlayer(player: Player)
	DataService.load(player)
	ensureLeaderstats(player)
	EconomyService.sync(player)
end

function EconomyService.addCoins(player: Player, amount: number, reason: string?)
	if amount == 0 then
		return
	end
	DataService.addCoins(player, amount)
	EconomyService.sync(player)
	if reason then
		Remotes.get("Notify"):FireClient(player, {
			text = string.format("%s%d Coins (%s)", amount >= 0 and "+" or "", amount, reason),
			kind = if amount >= 0 then "success" else "warn",
		})
	end
end

function EconomyService.trySpend(player: Player, cost: number): boolean
	local data = DataService.get(player)
	if data.coins < cost then
		return false
	end
	DataService.addCoins(player, -cost)
	EconomyService.sync(player)
	return true
end

function EconomyService.recordCrystalCollected(player: Player)
	DataService.addCrystalCount(player, 1)
	EconomyService.sync(player)
end

function EconomyService.getCarryCapacity(player: Player): number
	if DataService.hasUpgrade(player, "Carry3") then
		return 3
	end
	if DataService.hasUpgrade(player, "Carry2") then
		return 2
	end
	return Config.StartingCarryCapacity
end

function EconomyService.getWalkSpeed(player: Player): number
	if DataService.hasUpgrade(player, "WalkSpeed2") then
		return Config.Shop.items.WalkSpeed2.effect.walkSpeed :: number
	end
	if DataService.hasUpgrade(player, "WalkSpeed1") then
		return Config.Shop.items.WalkSpeed1.effect.walkSpeed :: number
	end
	return Config.DefaultWalkSpeed
end

function EconomyService.getLuckBonus(player: Player): number
	if DataService.hasUpgrade(player, "Luck2") then
		return Config.Shop.items.Luck2.effect.luckBonus :: number
	end
	if DataService.hasUpgrade(player, "Luck1") then
		return Config.Shop.items.Luck1.effect.luckBonus :: number
	end
	return 0
end

function EconomyService.applyCharacterStats(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = EconomyService.getWalkSpeed(player)
	end
end

return EconomyService
