--!strict
--[[
	Steal a Crystal — tunables.
]]

local Config = {}

Config.StartingCoins = 0
Config.StartingCarryCapacity = 1
Config.MaxCarryCapacity = 5

Config.Rarities = {
	Common = { displayName = "Common", color = Color3.fromRGB(120, 200, 255), value = 12, size = 1.2, spawnWeight = 48, glow = 0.35 },
	Rare = { displayName = "Rare", color = Color3.fromRGB(80, 255, 140), value = 40, size = 1.5, spawnWeight = 28, glow = 0.55 },
	Epic = { displayName = "Epic", color = Color3.fromRGB(190, 90, 255), value = 120, size = 1.85, spawnWeight = 16, glow = 0.8 },
	Legendary = { displayName = "Legendary", color = Color3.fromRGB(255, 185, 50), value = 340, size = 2.25, spawnWeight = 6, glow = 1.15 },
	Mythic = { displayName = "Mythic", color = Color3.fromRGB(255, 70, 110), value = 800, size = 2.6, spawnWeight = 2, glow = 1.4 },
}

Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

Config.WildZone = {
	center = Vector3.new(0, 2, 0),
	size = Vector3.new(160, 1, 160),
	spawnHeight = 3.2,
	maxCrystals = 48,
	respawnDelay = 3,
	spawnInterval = 1.6,
}

Config.Base = {
	plotSize = Vector3.new(36, 1, 36),
	plotSpacing = 48,
	pedestalSlots = 8,
	pedestalRadius = 10,
	sellPadSize = Vector3.new(7, 0.5, 7),
	wallHeight = 5,
	maxPlots = 12,
	ringRadius = 150,
	floorColor = Color3.fromRGB(38, 48, 68),
	accentColor = Color3.fromRGB(80, 130, 210),
	lockDuration = 10,
}

Config.Steal = {
	promptHoldDuration = 0.7,
	promptMaxDistance = 10,
	dropOnOwnerTouch = true,
	carryAttachOffset = Vector3.new(0, 2.6, 0),
	wantedDuration = 28,
}

Config.Cops = {
	enabled = true,
	count = 6,
	walkSpeed = 18,
	chaseSpeed = 23,
	catchDistance = 5.5,
	patrolRadius = 95,
	height = 3,
}

Config.Shop = {
	position = Vector3.new(0, 2, -95),
	items = {
		WalkSpeed1 = { id = "WalkSpeed1", name = "Swift Boots I", description = "Walk speed +4", cost = 50, category = "WalkSpeed", tier = 1, effect = { walkSpeed = 20 } },
		WalkSpeed2 = { id = "WalkSpeed2", name = "Swift Boots II", description = "Walk speed +8", cost = 160, category = "WalkSpeed", tier = 2, requires = "WalkSpeed1", effect = { walkSpeed = 24 } },
		WalkSpeed3 = { id = "WalkSpeed3", name = "Swift Boots III", description = "Walk speed +14", cost = 420, category = "WalkSpeed", tier = 3, requires = "WalkSpeed2", effect = { walkSpeed = 30 } },
		Carry2 = { id = "Carry2", name = "Crystal Pouch", description = "Carry up to 2 crystals", cost = 75, category = "Carry", tier = 1, effect = { carryCapacity = 2 } },
		Carry3 = { id = "Carry3", name = "Crystal Backpack", description = "Carry up to 3 crystals", cost = 200, category = "Carry", tier = 2, requires = "Carry2", effect = { carryCapacity = 3 } },
		Carry5 = { id = "Carry5", name = "Vault Sling", description = "Carry up to 5 crystals", cost = 550, category = "Carry", tier = 3, requires = "Carry3", effect = { carryCapacity = 5 } },
		Luck1 = { id = "Luck1", name = "Lucky Charm", description = "Better rare spawn luck", cost = 100, category = "Luck", tier = 1, effect = { luckBonus = 0.15 } },
		Luck2 = { id = "Luck2", name = "Fortune Amulet", description = "Better legendary luck", cost = 350, category = "Luck", tier = 2, requires = "Luck1", effect = { luckBonus = 0.35 } },
		Luck3 = { id = "Luck3", name = "Mythic Relic", description = "Mythic crystals can appear more often", cost = 900, category = "Luck", tier = 3, requires = "Luck2", effect = { luckBonus = 0.6 } },
		BaseLock = { id = "BaseLock", name = "Base Shield", description = "Brief lock after placing a crystal", cost = 120, category = "BaseLock", tier = 1, effect = { baseLock = true } },
	},
}

Config.NPC = { enabled = true, plotIndex = 12, name = "Crystal Keeper", crystalRarity = "Rare" }

Config.DataStore = { enabled = true, name = "StealACrystal_v2", autoSaveInterval = 45 }

Config.Tutorial = {
	steps = {
		"Welcome to Steal a Crystal. The wilds are huge — look for the glowing ring.",
		"Pick up crystals, carry them to YOUR base, and place them on pedestals.",
		"Sell on the gold pad for Coins. Spend Coins at the plaza Shop.",
		"Steal from other bases. Stealing makes you WANTED.",
		"Cops patrol the map. If they tag you while wanted, you drop everything.",
		"Sprint with Left Shift. G drops crystals. Get home to go clean.",
	},
}

Config.DefaultWalkSpeed = 16
Config.SprintBonus = 8

return Config
