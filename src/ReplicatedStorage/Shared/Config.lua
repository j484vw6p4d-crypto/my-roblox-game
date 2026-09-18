--!strict
--[[
	Steal a Crystal — central tunables.
	Adjust values here; services read Config at runtime.
]]

local Config = {}

--------------------------------------------------------------------------------
-- Economy
--------------------------------------------------------------------------------
Config.StartingCoins = 0
Config.StartingCarryCapacity = 1
Config.MaxCarryCapacity = 3

--------------------------------------------------------------------------------
-- Crystal rarities (spawnWeight is relative; higher = more common)
--------------------------------------------------------------------------------
Config.Rarities = {
	Common = {
		displayName = "Common",
		color = Color3.fromRGB(120, 200, 255),
		value = 10,
		size = 1.2,
		spawnWeight = 50,
		glow = 0.3,
	},
	Rare = {
		displayName = "Rare",
		color = Color3.fromRGB(80, 255, 120),
		value = 35,
		size = 1.5,
		spawnWeight = 30,
		glow = 0.5,
	},
	Epic = {
		displayName = "Epic",
		color = Color3.fromRGB(180, 80, 255),
		value = 100,
		size = 1.8,
		spawnWeight = 15,
		glow = 0.7,
	},
	Legendary = {
		displayName = "Legendary",
		color = Color3.fromRGB(255, 180, 40),
		value = 300,
		size = 2.2,
		spawnWeight = 5,
		glow = 1.0,
	},
}

Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary" }

--------------------------------------------------------------------------------
-- Wild zone crystal spawning
--------------------------------------------------------------------------------
Config.WildZone = {
	center = Vector3.new(0, 2, 0),
	size = Vector3.new(80, 1, 80), -- XZ footprint
	spawnHeight = 3,
	maxCrystals = 28,
	respawnDelay = 4, -- seconds after pickup before a new one can spawn
	spawnInterval = 2, -- check interval
}

--------------------------------------------------------------------------------
-- Player bases / plots
--------------------------------------------------------------------------------
Config.Base = {
	plotSize = Vector3.new(28, 1, 28),
	plotSpacing = 36, -- center-to-center
	pedestalSlots = 6,
	pedestalRadius = 8,
	sellPadSize = Vector3.new(6, 0.5, 6),
	wallHeight = 4,
	maxPlots = 8,
	-- Ring layout around wild zone
	ringRadius = 70,
	floorColor = Color3.fromRGB(45, 55, 75),
	accentColor = Color3.fromRGB(90, 140, 220),
	lockDuration = 8, -- seconds of base lock after placing (if upgraded)
}

--------------------------------------------------------------------------------
-- Stealing
--------------------------------------------------------------------------------
Config.Steal = {
	promptHoldDuration = 0.6,
	promptMaxDistance = 10,
	dropOnOwnerTouch = true,
	carryAttachOffset = Vector3.new(0, 2.5, 0),
}

--------------------------------------------------------------------------------
-- Shop upgrades (coin costs; effects applied server-side)
--------------------------------------------------------------------------------
Config.Shop = {
	position = Vector3.new(0, 2, -55),
	items = {
		WalkSpeed1 = {
			id = "WalkSpeed1",
			name = "Swift Boots I",
			description = "Walk speed +4",
			cost = 50,
			category = "WalkSpeed",
			tier = 1,
			effect = { walkSpeed = 20 }, -- default Roblox is 16
		},
		WalkSpeed2 = {
			id = "WalkSpeed2",
			name = "Swift Boots II",
			description = "Walk speed +8",
			cost = 150,
			category = "WalkSpeed",
			tier = 2,
			requires = "WalkSpeed1",
			effect = { walkSpeed = 24 },
		},
		Carry2 = {
			id = "Carry2",
			name = "Crystal Pouch",
			description = "Carry up to 2 crystals",
			cost = 75,
			category = "Carry",
			tier = 1,
			effect = { carryCapacity = 2 },
		},
		Carry3 = {
			id = "Carry3",
			name = "Crystal Backpack",
			description = "Carry up to 3 crystals",
			cost = 200,
			category = "Carry",
			tier = 2,
			requires = "Carry2",
			effect = { carryCapacity = 3 },
		},
		Luck1 = {
			id = "Luck1",
			name = "Lucky Charm",
			description = "Better rare spawn luck",
			cost = 100,
			category = "Luck",
			tier = 1,
			effect = { luckBonus = 0.15 },
		},
		Luck2 = {
			id = "Luck2",
			name = "Fortune Amulet",
			description = "Even better legendary luck",
			cost = 350,
			category = "Luck",
			tier = 2,
			requires = "Luck1",
			effect = { luckBonus = 0.35 },
		},
		BaseLock = {
			id = "BaseLock",
			name = "Base Shield",
			description = "Brief lock after placing a crystal",
			cost = 120,
			category = "BaseLock",
			tier = 1,
			effect = { baseLock = true },
		},
	},
}

--------------------------------------------------------------------------------
-- Demo NPC (Play Solo steal test)
--------------------------------------------------------------------------------
Config.NPC = {
	enabled = true,
	plotIndex = 1, -- uses first plot slot opposite players if needed
	name = "Crystal Keeper",
	crystalRarity = "Rare",
}

--------------------------------------------------------------------------------
-- DataStore
--------------------------------------------------------------------------------
Config.DataStore = {
	enabled = true,
	name = "StealACrystal_v1",
	autoSaveInterval = 60,
}

--------------------------------------------------------------------------------
-- Tutorial
--------------------------------------------------------------------------------
Config.Tutorial = {
	steps = {
		"Welcome to Steal a Crystal! Walk to the glowing wild zone.",
		"Pick up a crystal with the prompt, then carry it to YOUR base.",
		"Place it on a pedestal, then sell on the gold Sell Pad for Coins.",
		"Visit the Shop to upgrade speed, carry capacity, and luck.",
		"Steal from other bases (try the NPC base)! Owners can touch you to drop.",
	},
}

--------------------------------------------------------------------------------
-- Defaults for character
--------------------------------------------------------------------------------
Config.DefaultWalkSpeed = 16

return Config
