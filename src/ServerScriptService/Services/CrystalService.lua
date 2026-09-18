--!strict
--[[
	Wild crystal spawning, pickup, carry state, place, steal, owner-touch drop.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local BaseService = require(script.Parent.BaseService)
local EconomyService = require(script.Parent.EconomyService)
local DataService = require(script.Parent.DataService)

local CrystalService = {}

export type CarriedItem = {
	rarity: string,
	value: number,
	visual: BasePart?,
}

type CarryState = {
	items: { CarriedItem },
}

local carry: { [number]: CarryState } = {}
local wildCrystals: { [BasePart]: boolean } = {}
local crystalsFolder: Folder
local rng = Random.new()
local connections: { RBXScriptConnection } = {}

local function getCarry(player: Player): CarryState
	local s = carry[player.UserId]
	if not s then
		s = { items = {} }
		carry[player.UserId] = s
	end
	return s
end

local function notify(player: Player, text: string, kind: string?)
	Remotes.get("Notify"):FireClient(player, { text = text, kind = kind or "info" })
end

local function rollRarity(luckBonus: number): string
	local weights: { { string | number } } = {}
	local total = 0
	for _, name in ipairs(Config.RarityOrder) do
		local w = Config.Rarities[name].spawnWeight
		-- Luck shifts weight toward rarer tiers
		if name == "Rare" then
			w = w * (1 + luckBonus * 0.5)
		elseif name == "Epic" then
			w = w * (1 + luckBonus)
		elseif name == "Legendary" then
			w = w * (1 + luckBonus * 1.5)
		elseif name == "Common" then
			w = w * math.max(0.2, 1 - luckBonus * 0.4)
		end
		total += w
		table.insert(weights, { name, w })
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, entry in ipairs(weights) do
		acc += entry[2] :: number
		if roll <= acc then
			return entry[1] :: string
		end
	end
	return "Common"
end

local function attachCarryVisual(player: Player, rarity: string, index: number): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	local offset = Config.Steal.carryAttachOffset + Vector3.new((index - 1) * 1.2 - 0.6, 0, 0)
	local part = BaseService.createCrystalPart(rarity, char, hrp.CFrame * CFrame.new(offset))
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.Name = "CarriedCrystal_" .. index

	-- Remove prompts from carried copy
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = part
	weld.Parent = part

	part:SetAttribute("Carried", true)
	return part
end

local function clearCarryVisuals(state: CarryState)
	for _, item in ipairs(state.items) do
		if item.visual then
			item.visual:Destroy()
			item.visual = nil
		end
	end
end

function CrystalService.getCarriedCount(player: Player): number
	return #getCarry(player).items
end

function CrystalService.clearPlayer(player: Player)
	local state = carry[player.UserId]
	if state then
		clearCarryVisuals(state)
	end
	carry[player.UserId] = nil
end

function CrystalService.dropAll(player: Player, reason: string?)
	local state = getCarry(player)
	if #state.items == 0 then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local dropPos = if hrp then hrp.Position else Vector3.new(0, 5, 0)

	for _, item in ipairs(state.items) do
		if item.visual then
			item.visual:Destroy()
		end
		-- Respawn as wild crystal near drop
		CrystalService.spawnWildAt(dropPos + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), item.rarity)
	end
	table.clear(state.items)
	notify(player, reason or "You dropped your crystals!", "warn")
end

function CrystalService.spawnWildAt(position: Vector3, rarity: string?): BasePart
	local luck = 0
	local r = rarity or rollRarity(luck)
	local part = BaseService.createCrystalPart(r, crystalsFolder, CFrame.new(position))
	part:SetAttribute("Wild", true)
	CollectionService:AddTag(part, "WildCrystal")
	wildCrystals[part] = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = Config.Rarities[r].displayName .. " Crystal"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function(player: Player)
		CrystalService.tryPickupWild(player, part)
	end)

	part.AncestryChanged:Connect(function(_, parent)
		if not parent then
			wildCrystals[part] = nil
		end
	end)

	-- Gentle bob
	task.spawn(function()
		local baseY = position.Y
		local t0 = os.clock()
		while part.Parent do
			local t = os.clock() - t0
			part.CFrame = CFrame.new(position.X, baseY + math.sin(t * 2) * 0.35, position.Z)
				* CFrame.Angles(0, t * 0.8, 0)
			task.wait(0.05)
		end
	end)

	return part
end

function CrystalService.tryPickupWild(player: Player, part: BasePart): boolean
	if not part.Parent or not wildCrystals[part] then
		return false
	end
	if not part:GetAttribute("Wild") then
		return false
	end
	local capacity = EconomyService.getCarryCapacity(player)
	local state = getCarry(player)
	if #state.items >= capacity then
		notify(player, "Carry full! Upgrade at the Shop or place crystals first.", "warn")
		return false
	end

	local rarity = part:GetAttribute("Rarity") :: string
	local value = part:GetAttribute("Value") :: number
	if typeof(rarity) ~= "string" then
		return false
	end

	wildCrystals[part] = nil
	part:Destroy()

	local visual = attachCarryVisual(player, rarity, #state.items + 1)
	table.insert(state.items, {
		rarity = rarity,
		value = value or Config.Rarities[rarity].value,
		visual = visual,
	})
	notify(player, "Picked up " .. rarity .. " crystal!", "success")
	return true
end

function CrystalService.tryPlace(player: Player): boolean
	local plot = BaseService.getPlot(player)
	if not plot then
		notify(player, "You have no base!", "warn")
		return false
	end
	local state = getCarry(player)
	if #state.items == 0 then
		notify(player, "You aren't carrying any crystals.", "warn")
		return false
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	if (hrp.Position - plot.center).Magnitude > Config.Base.plotSize.X then
		notify(player, "Stand in your base to place crystals.", "warn")
		return false
	end

	local placed = 0
	while #state.items > 0 do
		if not BaseService.findFreeSlot(plot) then
			notify(player, "Pedestals full! Sell some crystals.", "warn")
			break
		end
		local item = table.remove(state.items, 1) :: CarriedItem
		if item.visual then
			item.visual:Destroy()
		end
		if BaseService.placeCrystal(plot, item.rarity, item.value) then
			placed += 1
			EconomyService.recordCrystalCollected(player)
		end
	end

	-- Refresh remaining carry visuals indices
	clearCarryVisuals(state)
	for i, item in ipairs(state.items) do
		item.visual = attachCarryVisual(player, item.rarity, i)
	end

	if placed > 0 then
		notify(player, string.format("Placed %d crystal(s) on pedestals!", placed), "success")
		if DataService.hasUpgrade(player, "BaseLock") then
			BaseService.lockPlot(plot, Config.Base.lockDuration)
			notify(player, "Base shield active briefly!", "info")
		end
		return true
	end
	return false
end

function CrystalService.trySell(player: Player): boolean
	local plot = BaseService.getPlot(player)
	if not plot then
		return false
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	if (hrp.Position - plot.sellPad.Position).Magnitude > 14 then
		notify(player, "Get closer to your Sell Pad.", "warn")
		return false
	end

	local total, count = BaseService.sellAll(plot)
	if count == 0 then
		notify(player, "No crystals on pedestals to sell.", "warn")
		return false
	end
	EconomyService.addCoins(player, total, "sold " .. count .. " crystals")
	return true
end

function CrystalService.trySteal(player: Player, crystalPart: BasePart): boolean
	local plot, stored = BaseService.getStoredByPart(crystalPart)
	if not plot or not stored then
		return false
	end
	if plot.owner == player then
		notify(player, "That's already yours!", "info")
		return false
	end
	if BaseService.isLocked(plot) then
		notify(player, "This base is shielded!", "warn")
		return false
	end

	local capacity = EconomyService.getCarryCapacity(player)
	local state = getCarry(player)
	if #state.items >= capacity then
		notify(player, "Carry full — can't steal right now.", "warn")
		return false
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	if (hrp.Position - crystalPart.Position).Magnitude > Config.Steal.promptMaxDistance + 4 then
		return false
	end

	local removed = BaseService.removeStoredCrystal(plot, stored.id)
	if not removed then
		return false
	end
	removed.part:Destroy()

	local visual = attachCarryVisual(player, removed.rarity, #state.items + 1)
	table.insert(state.items, {
		rarity = removed.rarity,
		value = removed.value,
		visual = visual,
	})

	notify(player, "Stolen a " .. removed.rarity .. " crystal!", "success")
	if plot.owner then
		notify(plot.owner, player.DisplayName .. " stole a crystal from your base!", "warn")
	end
	return true
end

function CrystalService.maintainWildPopulation()
	task.spawn(function()
		while true do
			task.wait(Config.WildZone.spawnInterval)
			local count = 0
			for part in pairs(wildCrystals) do
				if part.Parent then
					count += 1
				else
					wildCrystals[part] = nil
				end
			end
			while count < Config.WildZone.maxCrystals do
				-- Average luck of online players lightly influences spawn (use max luck)
				local luck = 0
				for _, plr in ipairs(Players:GetPlayers()) do
					luck = math.max(luck, EconomyService.getLuckBonus(plr))
				end
				local rarity = rollRarity(luck * 0.5)
				local pos = require(script.Parent.WorldBuilder).getWildSpawnPoint(rng)
				CrystalService.spawnWildAt(pos, rarity)
				count += 1
				task.wait(0.05)
			end
		end
	end)
end

function CrystalService.bindOwnerTouchDrop(player: Player)
	local function onCharacter(char: Model)
		local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if not hrp then
			return
		end
		local conn = hrp.Touched:Connect(function(hit)
			if not Config.Steal.dropOnOwnerTouch then
				return
			end
			local otherChar = hit:FindFirstAncestorOfClass("Model")
			if not otherChar then
				return
			end
			local thief = Players:GetPlayerFromCharacter(otherChar)
			if not thief or thief == player then
				return
			end
			-- Only force drop if thief is carrying AND standing near owner's plot with stolen goods
			if CrystalService.getCarriedCount(thief) <= 0 then
				return
			end
			local ownerPlot = BaseService.getPlot(player)
			if not ownerPlot then
				return
			end
			local thiefHrp = otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not thiefHrp then
				return
			end
			-- Kid-friendly: owner touching thief near owner's base OR anywhere if thief recently stole
			-- Simple rule: if thief is within owner's plot radius, owner touch drops
			if (thiefHrp.Position - ownerPlot.center).Magnitude <= Config.Base.plotSize.X * 0.75 then
				CrystalService.dropAll(thief, player.DisplayName .. " caught you — crystals dropped!")
			end
		end)
		table.insert(connections, conn)
		char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				conn:Disconnect()
			end
		end)
	end

	if player.Character then
		onCharacter(player.Character)
	end
	table.insert(connections, player.CharacterAdded:Connect(onCharacter))
end

function CrystalService.wirePrompts()
	-- Sell pads & steal prompts are created dynamically; use Ancestry + Descendant
	local world = Workspace:WaitForChild("GameWorld")

	local function hookPrompt(prompt: ProximityPrompt)
		if prompt.Name == "SellPrompt" then
			prompt.Triggered:Connect(function(player)
				CrystalService.trySell(player)
			end)
		elseif prompt.Name == "StealPrompt" then
			prompt.Triggered:Connect(function(player)
				local part = prompt.Parent
				if part and part:IsA("BasePart") then
					CrystalService.trySteal(player, part)
				end
			end)
		elseif prompt.Name == "PlacePrompt" then
			prompt.Triggered:Connect(function(player)
				CrystalService.tryPlace(player)
			end)
		end
	end

	for _, d in ipairs(world:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			hookPrompt(d)
		end
	end
	table.insert(connections, world.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			hookPrompt(d)
		end
	end))
end

function CrystalService.addPlacePrompts()
	for _, plot in ipairs(BaseService.getAllPlots()) do
		local floor = plot.model:FindFirstChild("Floor") :: BasePart?
		if floor and not floor:FindFirstChild("PlacePrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "PlacePrompt"
			prompt.ActionText = "Place Crystals"
			prompt.ObjectText = "Your Base"
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 16
			prompt.RequiresLineOfSight = false
			prompt.Parent = floor
		end
	end
end

function CrystalService.init(folder: Folder)
	crystalsFolder = folder
	CrystalService.wirePrompts()
	CrystalService.addPlacePrompts()
	CrystalService.maintainWildPopulation()

	-- Initial burst
	for _ = 1, math.min(12, Config.WildZone.maxCrystals) do
		local pos = require(script.Parent.WorldBuilder).getWildSpawnPoint(rng)
		CrystalService.spawnWildAt(pos, rollRarity(0))
	end
end

function CrystalService.onPlayerRemoving(player: Player)
	CrystalService.clearPlayer(player)
end

return CrystalService
