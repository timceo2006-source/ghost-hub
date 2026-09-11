-- ป้องกันการรันสคริปต์ก่อนเกมโหลดเสร็จ
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FOV_RADIUS = 150
local AIM_SMOOTHNESS = 1
local MAX_AIM_DISTANCE = 750

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
	return char:FindFirstChild("Head", true) or char:FindFirstChild("HumanoidRootPart", true) or char:FindFirstChildWhichIsA("BasePart", true)
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
				isVisible = true
				break
			end
		end
		if not isVisible then return false end
	end
	return true
end

local function isVisible(targetPart)
	local myChar = getCustomCharacter(LocalPlayer)
	if not myChar then return false end
	local origin = Camera.CFrame.Position
	local destination = targetPart.Position
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {myChar, targetPart.Parent, Camera}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	local result = workspace:Raycast(origin, destination - origin, rayParams)
	return result == nil
end

local function getBestTargetInFOV(myPos)
	local closestTarget = nil
	local shortestDist = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = getCustomCharacter(player)
			local targetPart = getTargetPart(char)
			
			if char and targetPart and isValidTarget(char) then
				local dist3D = (myPos - targetPart.Position).Magnitude
				
				if dist3D <= MAX_AIM_DISTANCE then
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if screenDist <= FOV_RADIUS then
							if isVisible(targetPart) then 
								if screenDist < shortestDist then
									shortestDist = screenDist
									closestTarget = targetPart
								end
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
	local targetPart = object
	if object:IsA("Model") then targetPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart") end
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
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "InfoText"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = color
		textLabel.TextStrokeTransparency = 0.6
		textLabel.TextSize = 13
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.Parent = gui
	end
	if gui.Adornee ~= targetPart then gui.Adornee = targetPart end
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
})

-- สร้างแท็บจัดหมวดหมู่ใหม่
local MainTab = Window:Tab({ Title = "Main", Locked = false })
local ESPTab = Window:Tab({ Title = "ESP", Locked = false })
local VisualsTab = Window:Tab({ Title = "Visuals", Locked = false })

-- ================= 1. แท็บ MAIN (ระบบต่อสู้) =================
local aimbotEnabled, aimbotLoop, screenGui = false, nil, nil

MainTab:Toggle({
	Title = "Aimbot (Limit 600m)",
	Desc = "ON/OFF Aimbot (ล็อกเป้าเฉพาะระยะ 600 เมตร)",
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
			
			local toggleButton = Instance.new("TextButton")
			toggleButton.Size = UDim2.new(0, 100, 0, 30)
			toggleButton.Position = UDim2.new(0.5, -50, 0, 10)
			toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			toggleButton.BorderColor3 = Color3.fromRGB(0, 255, 255)
			toggleButton.TextColor3 = Color3.fromRGB(50, 255, 50)
			toggleButton.TextSize = 13
			toggleButton.Font = Enum.Font.SourceSansBold
			toggleButton.Text = "AIM: ON"
			toggleButton.Parent = screenGui
			makeDraggable(toggleButton)

			local aimActive = true
			toggleButton.MouseButton1Click:Connect(function()
				aimActive = not aimActive
				toggleButton.TextColor3 = aimActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
				toggleButton.Text = aimActive and "AIM: ON" or "AIM: OFF"
			end)

			if not aimbotLoop then
				aimbotLoop = RunService.RenderStepped:Connect(function()
					if aimbotEnabled and aimActive then
						local myChar = getCustomCharacter(LocalPlayer)
						local myPart = getTargetPart(myChar)
						if myPart then
							local targetPart = getBestTargetInFOV(myPart.Position)
							if targetPart then
								local targetVelocity = targetPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
								local dist = (Camera.CFrame.Position - targetPart.Position).Magnitude
								local dynPred = (dist / 2000) + 0.05
								local predictedPos = targetPart.Position + (targetVelocity * dynPred)
								Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPos), AIM_SMOOTHNESS)
							end
						end
					end
				end)
			end
		else
			if screenGui then screenGui:Destroy() screenGui = nil end
			if aimbotLoop then aimbotLoop:Disconnect() aimbotLoop = nil end
		end
	end
})


-- ================= 2. แท็บ ESP (ระบบเรดาร์/มองทะลุ) =================

-- ESP Players
local espPlayerActive = false
local espFolder = nil

local function ensureFolder()
	if espFolder and espFolder.Parent then return end
	espFolder = Instance.new("Folder")
	espFolder.Name = "SecureESPFolder"
	local success, hiddenGui = pcall(function() return gethui() end)
	if success and hiddenGui then
		espFolder.Parent = hiddenGui
	else
		pcall(function() espFolder.Parent = CoreGui end)
		if not espFolder.Parent then espFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	end
end

ESPTab:Toggle({
	Title = "ESP Players",
	Desc = "เปิด/ปิด ESP ผู้เล่น",
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
										txt.TextColor3 = Color3.fromRGB(0, 255, 255)
										txt.TextStrokeTransparency = 0
										txt.Font = Enum.Font.SourceSansBold
										txt.Parent = gui
										gui.Parent = espFolder
									end
									
									local hl = espFolder:FindFirstChild(player.Name .. "_HL")
									if not hl then
										hl = Instance.new("Highlight")
										hl.Name = player.Name .. "_HL"
										hl.FillColor = Color3.fromRGB(0, 255, 255)
										hl.OutlineColor = Color3.fromRGB(255, 255, 255)
										hl.FillTransparency = 0.5
										hl.Parent = espFolder
									end
									
									if gui.Adornee ~= targetPart then gui.Adornee = targetPart end
									if hl.Adornee ~= char then hl.Adornee = char end
									
									local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
									if dist <= 3000 then
										local txt = gui:FindFirstChild("InfoText")
										if txt then
											local hum = char:FindFirstChildOfClass("Humanoid")
											local hp = hum and math.floor(hum.Health) or 0
											txt.Text = string.format("%s | [%dm] | %d HP", player.Name, dist, hp)
											txt.TextSize = dist > 1500 and 11 or (dist > 500 and 12 or 14)
										end
										gui.Enabled = true
										hl.Enabled = true
									else
										gui.Enabled = false
										hl.Enabled = false
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

-- ESP Bot
local espBotActive = false
local botEspFolder = nil

ESPTab:Toggle({
	Title = "ESP บอท (Bot)",
	Desc = "เปิด/ปิด ESP บอท",
	Value = false,
	Callback = function(state)
		espBotActive = state
		if state then
			if not botEspFolder then
				botEspFolder = Instance.new("Folder")
				botEspFolder.Name = "BotESPFolder"
				pcall(function() botEspFolder.Parent = CoreGui end)
				if not botEspFolder.Parent then botEspFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end
			
			task.spawn(function()
				while espBotActive do
					local myChar = getCustomCharacter(LocalPlayer)
					local myPart = getTargetPart(myChar)
					
					if myPart then
						for _, model in ipairs(workspace:GetChildren()) do
							if model:IsA("Model") and model ~= myChar then
								local hum = model:FindFirstChildOfClass("Humanoid")
								local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
								
								if hum and root and hum.Health > 0 then
									if not Players:GetPlayerFromCharacter(model) then
										local espName = "Bot_" .. tostring(model:GetDebugId(10))
										local gui = botEspFolder:FindFirstChild(espName .. "_ESP")
										
										if not gui then
											gui = Instance.new("BillboardGui")
											gui.Name = espName .. "_ESP"
											gui.Size = UDim2.new(0, 200, 0, 50)
											gui.StudsOffset = Vector3.new(0, 2, 0)
											gui.AlwaysOnTop = true
											
											local txt = Instance.new("TextLabel")
											txt.Name = "InfoText"
											txt.Size = UDim2.new(1, 0, 1, 0)
											txt.BackgroundTransparency = 1
											txt.TextColor3 = Color3.fromRGB(255, 50, 50)
											txt.Font = Enum.Font.SourceSansBold
											txt.Parent = gui
											gui.Parent = botEspFolder
										end
										
										if gui.Adornee ~= root then gui.Adornee = root end
										local dist = math.floor((myPart.Position - root.Position).Magnitude)
										
										if dist <= 2500 then
											local txt = gui:FindFirstChild("InfoText")
											if txt then
												txt.Text = string.format("[BOT] | [%dm] | %d HP", dist, math.floor(hum.Health))
												txt.TextSize = dist > 1500 and 11 or (dist > 500 and 12 or 14)
											end
											gui.Enabled = true
										else
											gui.Enabled = false
										end
									end
								end
							end
						end
						
						for _, obj in ipairs(botEspFolder:GetChildren()) do
							if obj:IsA("BillboardGui") then
								local adornee = obj.Adornee
								if not adornee or not adornee.Parent or not adornee.Parent:FindFirstChildOfClass("Humanoid") or adornee.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
									obj:Destroy()
								end
							end
						end
					end
					task.wait(0.5) 
				end
			end)
		else
			if botEspFolder then botEspFolder:Destroy() botEspFolder = nil end
		end
	end
})

-- ESP Exit
local espExitActive = false
local exitFolder = nil

ESPTab:Toggle({
	Title = "ESP ทางออก",
	Desc = "เปิด/ปิด ทางออก",
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
									createOrUpdateObjectESP(exitFolder, v, "🚪 ทางออก", Color3.fromRGB(50, 255, 50), myPart)
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

-- ESP Crates
local espCrateActive = false
local crateFolder = nil

ESPTab:Toggle({
	Title = "ESP กล่องทหาร",
	Desc = "เปิด/ปิด กล่อง",
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
									createOrUpdateObjectESP(crateFolder, v, "📦 กล่องทหาร", Color3.fromRGB(255, 165, 0), myPart)
								elseif v.Name == "Small Military Box" or v.Name == "SmallMilitaryBox" then
									createOrUpdateObjectESP(crateFolder, v, "📦 กล่องอาวุธเล็ก", Color3.fromRGB(50, 255, 50), myPart) 
								elseif v.Name == "Large Military Box" or v.Name == "LargeMilitaryBox" then
									createOrUpdateObjectESP(crateFolder, v, "📦 กล่องอาวุธใหญ่", Color3.fromRGB(255, 215, 0), myPart)
								elseif v.Name == "Large ABPOPA Box" or v.Name == "LargeABPOPABox" then
									createOrUpdateObjectESP(crateFolder, v, "📦 กล่อง ABPOPA ใหญ่", Color3.fromRGB(180, 50, 255), myPart)
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


-- ================= 3. แท็บ VISUALS (ปรับแต่งสภาพแวดล้อม) =================

-- Night Vision
local nightVisionActive = false
local lightingConnection = nil

VisualsTab:Toggle({
	Title = "Night Vision",
	Desc = "เปิด/ปิด การมองเห็นตอนกลางคืน",
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

-- Remove Grass
local origDecoration = false
pcall(function()
	origDecoration = workspace.Terrain.Decoration
end)

VisualsTab:Toggle({
	Title = "Remove Grass (ลบหญ้า)",
	Desc = "ลบหญ้าบนพื้น โล่งตา หาคนง่าย",
	Value = false,
	Callback = function(state)
		pcall(function()
			if state then
				workspace.Terrain.Decoration = false
			else
				workspace.Terrain.Decoration = origDecoration
			end
		end)
	end
})
