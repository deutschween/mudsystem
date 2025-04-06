local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Visual Debug Configuration
local DEBUG_VISUAL = true
local DEBUG_COLOR = Color3.new(1, 0, 0)
local DEBUG_SPHERE_SIZE = Vector3.new(1, 1, 1)

-- Event
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mudModifierEvent = Instance.new("RemoteEvent")
mudModifierEvent.Name = "MudModifierEvent"
mudModifierEvent.Parent = ReplicatedStorage

-- Enhanced Settings
local SETTINGS = {
	MudMaterial = Enum.Material.Mud,
	CheckHeight = {
		Offset = Vector3.new(0, -2.5, 0),
		RaycastDistance = 3
	},
	Accumulation = {
		EnterTime = 30,
		ExitTime = 30,
		Rate = 1
	},
	SpeedReduction = {
		PerLevel = 5,
		MaxLevel = 3,
		MinSpeed = 1
	}
}

-- System State
local playerStates = {}
local debugParts = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {Workspace.Camera}

-- Debug Visualization
local function createDebugPart(player)
	if not DEBUG_VISUAL then return end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Transparency = 0.7
	part.Color = DEBUG_COLOR
	part.Size = DEBUG_SPHERE_SIZE
	part.Shape = Enum.PartType.Ball
	part.Parent = Workspace
	debugParts[player] = part
end

local function updateDebugVisual(player, position, inMud)
	if not DEBUG_VISUAL then return end
	local debugPart = debugParts[player]
	if debugPart then
		debugPart.Position = position + SETTINGS.CheckHeight.Offset
		debugPart.Color = inMud and Color3.new(0, 1, 0) or DEBUG_COLOR
	end
end

-- Ground Detection
local function getGroundMaterial(position)
	local ray = Ray.new(position + Vector3.new(0, 0.5, 0), 
		Vector3.new(0, -SETTINGS.CheckHeight.RaycastDistance, 0))
	local result = Workspace:Raycast(ray.Origin, ray.Direction, raycastParams)
	if not result then return false end

	return result.Material == SETTINGS.MudMaterial or
		(result.Instance and result.Instance:IsA("BasePart") and 
			result.Instance.Material == SETTINGS.MudMaterial)
end

-- State Management
local function managePlayerState(playerState)
	local enterDebounce = false
	local exitDebounce = false

	while true do
		local rootPart = playerState.Character:FindFirstChild("HumanoidRootPart")
		if not rootPart or not playerState.Humanoid or not playerState.Humanoid.Parent then
			task.wait(1)
			continue
		end

		local checkPosition = rootPart.Position + SETTINGS.CheckHeight.Offset
		local inMud = getGroundMaterial(checkPosition)
		updateDebugVisual(playerState.Player, rootPart.Position, inMud)

		if inMud and not enterDebounce then
			enterDebounce = true
			exitDebounce = false
			task.delay(SETTINGS.Accumulation.EnterTime, function()
				enterDebounce = false
			end)

			playerState.MudLevel = math.min(playerState.MudLevel + SETTINGS.Accumulation.Rate, SETTINGS.SpeedReduction.MaxLevel)
			local modifier = -playerState.MudLevel * SETTINGS.SpeedReduction.PerLevel
			mudModifierEvent:FireClient(playerState.Player, modifier)
			--print(`[Mud] {playerState.Player.Name} entered mud (Level {playerState.MudLevel})`)

		elseif not inMud and not exitDebounce then
			exitDebounce = true
			enterDebounce = false
			task.delay(SETTINGS.Accumulation.ExitTime, function()
				exitDebounce = false
			end)

			playerState.MudLevel = math.max(playerState.MudLevel - SETTINGS.Accumulation.Rate, 0)
			local modifier = -playerState.MudLevel * SETTINGS.SpeedReduction.PerLevel
			mudModifierEvent:FireClient(playerState.Player, modifier)
			--print(`[Mud] {playerState.Player.Name} exited mud (Level {playerState.MudLevel})`)
		end

		task.wait(0.1)
	end
end

-- Player Setup
local function setupPlayer(player)
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")
		createDebugPart(player)

		playerStates[player] = {
			Player = player,
			Character = character,
			Humanoid = humanoid,
			BaseSpeed = humanoid.WalkSpeed,
			MudLevel = 0
		}

		mudModifierEvent:FireClient(player, 0)
		task.spawn(managePlayerState, playerStates[player])
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end

	player.PlayerRemoving:Connect(function()
		if debugParts[player] then
			debugParts[player]:Destroy()
			debugParts[player] = nil
		end
		playerStates[player] = nil
	end)
end

-- Initialize System
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

warn("Mud System 1.0 Stable")
