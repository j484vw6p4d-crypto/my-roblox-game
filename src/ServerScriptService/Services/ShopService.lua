--!strict
--[[
	Shop purchases — server validates cost, prerequisites, applies upgrades.
]]

local Workspace = game:GetService("Workspace")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local ShopService = {}

local function notify(player: Player, text: string, kind: string?)
	Remotes.get("Notify"):FireClient(player, { text = text, kind = kind or "info" })
end

local function catalogFor(player: Player): { any }
	local list = {}
	for id, item in pairs(Config.Shop.items) do
		table.insert(list, {
			id = item.id,
			name = item.name,
			description = item.description,
			cost = item.cost,
			category = item.category,
			tier = item.tier,
			requires = item.requires,
			owned = DataService.hasUpgrade(player, item.id),
		})
	end
	table.sort(list, function(a, b)
		if a.category == b.category then
			return a.tier < b.tier
		end
		return a.category < b.category
	end)
	return list
end

function ShopService.sendCatalog(player: Player)
	Remotes.get("ShopData"):FireClient(player, catalogFor(player))
end

function ShopService.tryBuy(player: Player, itemId: string): boolean
	if typeof(itemId) ~= "string" then
		return false
	end
	local item = Config.Shop.items[itemId]
	if not item then
		notify(player, "Unknown shop item.", "warn")
		return false
	end
	if DataService.hasUpgrade(player, itemId) then
		notify(player, "You already own that!", "info")
		return false
	end
	if item.requires and not DataService.hasUpgrade(player, item.requires) then
		notify(player, "You need the previous upgrade first.", "warn")
		return false
	end

	-- Distance check to shop
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	local shopPos = Config.Shop.position
	if (hrp.Position - shopPos).Magnitude > 28 then
		notify(player, "Move closer to the Shop.", "warn")
		return false
	end

	if not EconomyService.trySpend(player, item.cost) then
		notify(player, "Not enough Coins!", "warn")
		return false
	end

	DataService.ownUpgrade(player, itemId)
	EconomyService.applyCharacterStats(player)
	EconomyService.sync(player)
	ShopService.sendCatalog(player)
	notify(player, "Purchased: " .. item.name, "success")
	return true
end

function ShopService.wireShopPrompt()
	local world = Workspace:WaitForChild("GameWorld")
	local shop = world:WaitForChild("Shop")
	local counter = shop:WaitForChild("ShopCounter")
	local prompt = counter:WaitForChild("ShopPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player)
		ShopService.sendCatalog(player)
		Remotes.get("OpenShop"):FireClient(player)
	end)
end

function ShopService.init()
	ShopService.wireShopPrompt()
end

return ShopService
