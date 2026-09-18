--!strict
--[[
	Creates / waits for RemoteEvents used by client ↔ server.
	Server calls Remotes.init() once at boot; clients use Remotes.get().
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local REMOTE_NAMES = {
	"PickupCrystal",
	"PlaceCrystal",
	"SellCrystals",
	"StealCrystal",
	"BuyShopItem",
	"DropCarried",
	"UpdateStats", -- server → client leaderstat / carry sync
	"Notify", -- server → client toast messages
	"TutorialDone",
	"OpenShop", -- client request for shop catalog snapshot
	"ShopData", -- server → client shop state
}

local folder: Folder? = nil
local cache: { [string]: RemoteEvent } = {}

local function ensureFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = "Remotes"
	f.Parent = ReplicatedStorage
	return f
end

function Remotes.init()
	folder = ensureFolder()
	for _, name in ipairs(REMOTE_NAMES) do
		local ev = folder:FindFirstChild(name)
		if not ev then
			ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
		cache[name] = ev :: RemoteEvent
	end
end

function Remotes.get(name: string): RemoteEvent
	if cache[name] then
		return cache[name]
	end
	local f = ReplicatedStorage:WaitForChild("Remotes", 30) :: Folder
	local ev = f:WaitForChild(name, 30) :: RemoteEvent
	cache[name] = ev
	return ev
end

function Remotes.getAll(): { [string]: RemoteEvent }
	if not next(cache) then
		Remotes.init()
	end
	return cache
end

return Remotes
