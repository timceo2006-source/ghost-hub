if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FOV_RADIUS = 150
local AIM_SMOOTHNESS = 1
local MAX_AIM_DISTANCE = 600

local FriendList = {
	"AQWCCDE"
}

local origLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient
}

local function makeDraggable(gui)
	local dragging, dragInput, dragStart, startPos
	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function getCustomCharacter(player)
	if player.Character and player.Character:FindFirstChildWhichIsA("BasePart", true) then return player.Character end
	local char = workspace:FindFirstChild(player.Name)
	if char and char:IsA("Model") then return char end
	return nil
end

local function getTargetPart(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart", true)
end

local function isValidTarget(char)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return false end
	local head = char:FindFirstChild("Head") or char:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		if head.Transparency >= 0.9 then return false end
	else
		local isVisible = false
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.9 then
				isVisible = true; break
			end
		end
		if not isVisible then return false end
	end
	return true
end

local function isVisible(targetPart)
	local myChar = getCustomCharacter(LocalPlayer)
	if not myChar then return false end
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {myChar, targetPart.Parent, Camera}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, rayParams) == nil
end

local function isFriend(player)
	if not player then return false end
	for _, friendName in ipairs(FriendList) do
		if player.Name == friendName then return true end
	end
	local myChar = getCustomCharacter(LocalPlayer)
	local targetChar = getCustomCharacter(player)
	if myChar and targetChar then
		local function readTeamTag(char)
			local head = char:FindFirstChild("Head")
			if head then
				local tag = head:FindFirstChild("PlayerTeamTag")
				if tag and tag:FindFirstChild("Team") and tag.Team:IsA("TextLabel") and tag.Team.Text ~= "" then
					return tag.Team.Text
				end
			end
			return nil
		end
		local myTeam = readTeamTag(myChar)
		local targetTeam = readTeamTag(targetChar)
		if myTeam and targetTeam and myTeam == targetTeam then return true end
	end
	return false
end

local function getBestTargetInFOV(myPos)
	local closestTarget = nil
	local shortestDist = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = getCustomCharacter(player)
			local targetPart = getTargetPart(char)
			if char and targetPart and isValidTarget(char) and not isFriend(player) then
				local dist3D = (myPos - targetPart.Position).Magnitude
				if dist3D <= MAX_AIM_DISTANCE then
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if screenDist <= FOV_RADIUS then
							if isVisible(targetPart) and screenDist < shortestDist then
								shortestDist = screenDist
								closestTarget = targetPart
							end
						end
					end
				end
			end
		end
	end
	return closestTarget
end

local function createOrUpdateObjectESP(folder, object, displayName, color, myPart)
	if not object then return end
	local targetPart = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
	if not targetPart or not targetPart:IsA("BasePart") then return end
	local espName = tostring(object:GetDebugId(10))
	local gui = folder:FindFirstChild(espName)
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = espName
		gui.Size = UDim2.new(0, 150, 0, 40)
		gui.StudsOffset = Vector3.new(0, 1.5, 0)
		gui.AlwaysOnTop = true
		gui.Parent = folder
		local txt = Instance.new("TextLabel")
		txt.Name = "InfoText"
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = color
		txt.TextStrokeTransparency = 0.6
		txt.TextSize = 13
		txt.Font = Enum.Font.SourceSansBold
		txt.Parent = gui
	end
	gui.Adornee = targetPart
	local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
	local txt = gui:FindFirstChild("InfoText")
	if txt then txt.Text = string.format("%s\n[%dm]", displayName, dist) end
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub",
    Icon = "ghost",
    Author = "by .TiM",
    Folder = "MyGhostHub",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.RightControl,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = { Enabled = true, Anonymous = true, Callback = function() end }
})

local MainTab = Window:Tab({ Title = "Main", Locked = false })
local ESPTab = Window:Tab({ Title = "ESP", Locked = false })
local VisualsTab = Window:Tab({ Title = "Visuals", Locked = false })

local aimbotEnabled, aimbotLoop, screenGui = false, nil, nil

MainTab:Toggle({
	Title = "Aimbot (Safe Team)",
	Desc = "",
	Value = false,
	Callback = function(state)
		aimbotEnabled = state
		if state then
			if screenGui then screenGui:Destroy() end
			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "AimbotToggleGui"
			screenGui.ResetOnSpawn = false
			pcall(function() screenGui.Parent = CoreGui end)
			if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 100, 0, 30)
			btn.Position = UDim2.new(0.5, -50, 0, 10)
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			btn.BorderColor3 = Color3.fromRGB(0, 255, 255)
			btn.TextColor3 = Color3.fromRGB(50, 255, 50)
			btn.TextSize = 13
			btn.Font = Enum.Font.SourceSansBold
			btn.Text = "AIM: ON"
			btn.Parent = screenGui
			makeDraggable(btn)

			local aimActive = true
			btn.MouseButton1Click:Connect(function()
				aimActive = not aimActive
				btn.TextColor3 = aimActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
				btn.Text = aimActive and "AIM: ON" or "AIM: OFF"
			end)

			aimbotLoop = RunService.RenderStepped:Connect(function()
				if aimbotEnabled and aimActive then
					local myChar = getCustomCharacter(LocalPlayer)
					local myPart = getTargetPart(myChar)
					if myPart then
						local targetPart = getBestTargetInFOV(myPart.Position)
						if targetPart then
							local vel = targetPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
							local dist = (Camera.CFrame.Position - targetPart.Position).Magnitude
							local pred = targetPart.Position + (vel * ((dist / 2000) + 0.05))
							Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pred), AIM_SMOOTHNESS)
						end
					end
				end
			end)
		else
			if screenGui then screenGui:Destroy() screenGui = nil end
			if aimbotLoop then aimbotLoop:Disconnect() aimbotLoop = nil end
		end
	end
})

local espPlayerActive = false
local espFolder = nil

local function ensureFolder()
	if espFolder and espFolder.Parent then return end
	espFolder = Instance.new("Folder")
	espFolder.Name = "SecureESPFolder"
	local s, h = pcall(function() return gethui() end)
	if s and h then espFolder.Parent = h else pcall(function() espFolder.Parent = CoreGui end) if not espFolder.Parent then espFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end end
end

ESPTab:Toggle({
	Title = "ESP Players",
	Desc = "",
	Value = false,
	Callback = function(state)
		espPlayerActive = state
		if state then
			ensureFolder()
			task.spawn(function()
				while espPlayerActive do
					ensureFolder()
					local myChar = getCustomCharacter(LocalPlayer)
					local myPart = getTargetPart(myChar)
					if myPart then
						for _, player in ipairs(Players:GetPlayers()) do
							if player ~= LocalPlayer then
								local char = getCustomCharacter(player)
								local targetPart = getTargetPart(char)
								if char and targetPart and isValidTarget(char) then
									local gui = espFolder:FindFirstChild(player.Name .. "_ESP")
									if not gui then
										gui = Instance.new("BillboardGui")
										gui.Name = player.Name .. "_ESP"
										gui.Size = UDim2.new(0, 200, 0, 50)
										gui.StudsOffset = Vector3.new(0, 2, 0)
										gui.AlwaysOnTop = true
										local txt = Instance.new("TextLabel")
										txt.Name = "InfoText"
										txt.Size = UDim2.new(1, 0, 1, 0)
										txt.BackgroundTransparency = 1
										txt.TextStrokeTransparency = 0
										txt.Font = Enum.Font.SourceSansBold
										txt.Parent = gui
										gui.Parent = espFolder
									end
									local hl = espFolder:FindFirstChild(player.Name .. "_HL")
									if not hl then
										hl = Instance.new("Highlight")
										hl.Name = player.Name .. "_HL"
										hl.OutlineColor = Color3.fromRGB(255, 255, 255)
										hl.FillTransparency = 0.5
										hl.Parent = espFolder
									end
									gui.Adornee = targetPart
									hl.Adornee = char
									local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
									if dist <= 3000 then
										local txt = gui:FindFirstChild("InfoText")
										if txt then
											local hum = char:FindFirstChildOfClass("Humanoid")
											local hp = hum and math.floor(hum.Health) or 0
											if isFriend(player) then
												txt.TextColor3 = Color3.fromRGB(50, 255, 50)
												hl.FillColor = Color3.fromRGB(50, 255, 50)
											else
												txt.TextColor3 = Color3.fromRGB(0, 255, 255)
												hl.FillColor = Color3.fromRGB(0, 255, 255)
											end
											txt.Text = string.format("%s | [%dm] | %d HP", player.Name, dist, hp)
											txt.TextSize = dist > 1500 and 11 or (dist > 500 and 12 or 14)
										end
										gui.Enabled = true
										hl.Enabled = true
									else
										gui.Enabled = false; hl.Enabled = false
									end
								else
									local gui = espFolder:FindFirstChild(player.Name .. "_ESP")
									local hl = espFolder:FindFirstChild(player.Name .. "_HL")
									if gui then gui.Enabled = false end
									if hl then hl.Enabled = false end
								end
							end
						end
					end
					task.wait(0.1)
				end
			end)
		else
			if espFolder then espFolder:Destroy() espFolder = nil end
		end
	end
})

local espExitActive = false
local exitFolder = nil

ESPTab:Toggle({
	Title = "ESP Exit",
	Desc = "",
	Value = false,
	Callback = function(state)
		espExitActive = state
		if state then
			if not exitFolder then
				exitFolder = Instance.new("Folder")
				exitFolder.Name = "ExitESPFolder"
				pcall(function() exitFolder.Parent = CoreGui end)
				if not exitFolder.Parent then exitFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end
			task.spawn(function()
				while espExitActive do
					local myChar = getCustomCharacter(LocalPlayer)
					local myPart = getTargetPart(myChar)
					if myPart then
						local noCol = workspace:FindFirstChild("NoCollision")
						if noCol and noCol:FindFirstChild("ExitLocations") then
							for _, v in ipairs(noCol.ExitLocations:GetChildren()) do
								if v.Name == "Exit" then
									createOrUpdateObjectESP(exitFolder, v, "🚪 Exit", Color3.fromRGB(50, 255, 50), myPart)
								end
							end
						end
					end
					task.wait(1)
				end
			end)
		else
			if exitFolder then exitFolder:Destroy() exitFolder = nil end
		end
	end
})

local espCrateActive = false
local crateFolder = nil

ESPTab:Toggle({
	Title = "ESP Crates",
	Desc = "",
	Value = false,
	Callback = function(state)
		espCrateActive = state
		if state then
			if not crateFolder then
				crateFolder = Instance.new("Folder")
				crateFolder.Name = "CrateESPFolder"
				pcall(function() crateFolder.Parent = CoreGui end)
				if not crateFolder.Parent then crateFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end
			task.spawn(function()
				while espCrateActive do
					local myChar = getCustomCharacter(LocalPlayer)
					local myPart = getTargetPart(myChar)
					if myPart then
						local containers = workspace:FindFirstChild("Containers")
						if containers then
							for _, v in ipairs(containers:GetChildren()) do
								if v.Name == "MilitaryCrate" or v.Name == "Military Crate" then
									createOrUpdateObjectESP(crateFolder, v, "📦 Military", Color3.fromRGB(255, 165, 0), myPart)
								elseif v.Name == "Small Military Box" or v.Name == "SmallMilitaryBox" then
									createOrUpdateObjectESP(crateFolder, v, "📦 Small Box", Color3.fromRGB(50, 255, 50), myPart) 
								elseif v.Name == "Large Military Box" or v.Name == "LargeMilitaryBox" then
									createOrUpdateObjectESP(crateFolder, v, "📦 Large Box", Color3.fromRGB(255, 215, 0), myPart)
								elseif v.Name == "Large ABPOPA Box" or v.Name == "LargeABPOPABox" then
									createOrUpdateObjectESP(crateFolder, v, "📦 ABPOPA", Color3.fromRGB(180, 50, 255), myPart)
								end
							end
						end
					end
					task.wait(1)
				end
			end)
		else
			if crateFolder then crateFolder:Destroy() crateFolder = nil end
		end
	end
})

local nightVisionActive = false
local lightingConnection = nil

VisualsTab:Toggle({
	Title = "Night Vision",
	Desc = "",
	Value = false,
	Callback = function(state)
		nightVisionActive = state
		if state then
			local function applyNightVision()
				Lighting.Brightness = 2
				Lighting.ClockTime = 14
				Lighting.FogEnd = 100000
				Lighting.GlobalShadows = false
				Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			end
			applyNightVision()
			lightingConnection = Lighting.Changed:Connect(applyNightVision)
		else
			if lightingConnection then lightingConnection:Disconnect() lightingConnection = nil end
			Lighting.Brightness = origLighting.Brightness
			Lighting.ClockTime = origLighting.ClockTime
			Lighting.FogEnd = origLighting.FogEnd
			Lighting.GlobalShadows = origLighting.GlobalShadows
			Lighting.Ambient = origLighting.Ambient
		end
	end
})
