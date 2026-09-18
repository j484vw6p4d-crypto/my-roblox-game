--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local CopService = {}
local wantedUntil: { [number]: number } = {}
local cops: { Model } = {}
local rng = Random.new()
local CrystalService

function CopService.isWanted(player: Player): boolean
	local t = wantedUntil[player.UserId]
	return t ~= nil and os.clock() < t
end

function CopService.getWantedRemaining(player: Player): number
	local t = wantedUntil[player.UserId]
	if not t then
		return 0
	end
	return math.max(0, t - os.clock())
end

function CopService.setWanted(player: Player, duration: number?)
	local d = duration or Config.Steal.wantedDuration
	wantedUntil[player.UserId] = os.clock() + d
	Remotes.get("Notify"):FireClient(player, { text = "WANTED — cops will chase you!", kind = "warn" })
	Remotes.get("UpdateStats"):FireClient(player, { wanted = true, wantedLeft = d })
end

function CopService.clearWanted(player: Player)
	wantedUntil[player.UserId] = nil
	Remotes.get("UpdateStats"):FireClient(player, { wanted = false, wantedLeft = 0 })
end

local function makePart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function spawnCop(index: number, folder: Folder): Model
	local model = Instance.new("Model")
	model.Name = "Cop_" .. index
	model.Parent = folder
	local pos = Vector3.new(rng:NextNumber(-60, 60), Config.Cops.height, rng:NextNumber(-60, 60))
	local torso = makePart("Torso", Vector3.new(2, 2.2, 1.1), CFrame.new(pos), Color3.fromRGB(30, 50, 110), model)
	local head = makePart("Head", Vector3.new(1.2, 1.2, 1.2), torso.CFrame * CFrame.new(0, 1.7, 0), Color3.fromRGB(240, 210, 175), model)
	head.Shape = Enum.PartType.Ball
	makePart("Hat", Vector3.new(1.5, 0.35, 1.5), head.CFrame * CFrame.new(0, 0.7, 0), Color3.fromRGB(20, 25, 40), model)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(80, 140, 255)
	light.Brightness = 1.4
	light.Range = 14
	light.Parent = torso
	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(90, 28)
	bill.StudsOffset = Vector3.new(0, 2.8, 0)
	bill.AlwaysOnTop = true
	bill.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "COP"
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(120, 180, 255)
	label.Parent = bill
	model.PrimaryPart = torso
	model:SetAttribute("PatrolAngle", rng:NextNumber(0, math.pi * 2))
	model:SetAttribute("Index", index)
	return model
end

function CopService.init(crystalService: any)
	if not Config.Cops.enabled then
		return
	end
	CrystalService = crystalService
	local world = Workspace:WaitForChild("GameWorld")
	local folder = Instance.new("Folder")
	folder.Name = "Cops"
	folder.Parent = world
	for i = 1, Config.Cops.count do
		table.insert(cops, spawnCop(i, folder))
	end
	task.spawn(function()
		while true do
			task.wait(0.12)
			for _, cop in ipairs(cops) do
				local torso = cop.PrimaryPart
				if torso then
					local targetPlayer: Player? = nil
					local targetPos: Vector3? = nil
					local closest = 1e9
					for _, player in ipairs(Players:GetPlayers()) do
						if CopService.isWanted(player) and player.Character then
							local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
							if hrp then
								local d = (hrp.Position - torso.Position).Magnitude
								if d < closest then
									closest = d
									targetPlayer = player
									targetPos = hrp.Position
								end
							end
						end
					end
					local speed = Config.Cops.walkSpeed
					local dest: Vector3
					if targetPos and targetPlayer then
						speed = Config.Cops.chaseSpeed
						dest = Vector3.new(targetPos.X, Config.Cops.height, targetPos.Z)
						if closest <= Config.Cops.catchDistance then
							if CrystalService then
								CrystalService.dropAll(targetPlayer, "A cop caught you — crystals dropped!")
							end
							CopService.clearWanted(targetPlayer)
						end
					else
						local ang = cop:GetAttribute("PatrolAngle") :: number
						ang += 0.015 + (cop:GetAttribute("Index") :: number) * 0.001
						cop:SetAttribute("PatrolAngle", ang)
						local r = Config.Cops.patrolRadius * (0.55 + 0.2 * ((cop:GetAttribute("Index") :: number) % 3))
						dest = Vector3.new(math.cos(ang) * r, Config.Cops.height, math.sin(ang) * r)
					end
					local pos = torso.Position
					local delta = dest - pos
					local dist = delta.Magnitude
					if dist > 0.2 then
						local step = math.min(dist, speed * 0.12)
						local nextPos = pos + delta.Unit * step
						cop:PivotTo(CFrame.lookAt(nextPos, Vector3.new(dest.X, nextPos.Y, dest.Z)))
					end
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				if CopService.isWanted(player) then
					Remotes.get("UpdateStats"):FireClient(player, { wanted = true, wantedLeft = CopService.getWantedRemaining(player) })
				end
			end
		end
	end)
end

function CopService.onPlayerRemoving(player: Player)
	wantedUntil[player.UserId] = nil
end

return CopService
