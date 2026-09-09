-- ป้องกันการรันสคริปต์ก่อนเกมโหลดเสร็จ (กัน Error)
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
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if screenDist <= FOV_RADIUS then
						if isVisible(targetPart) then 
							local dist = (myPos - targetPart.Position).Magnitude
							if dist < shortestDist then
								shortestDist = dist
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
    ToggleKey = Enum.KeyCode.LeftShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
        end,
    },
})

local Tab = Window:Tab({ Title = "Main", Locked = false })
local VisualsTab = Window:Tab({ Title = "Visuals", Locked = false })

-- ================= AIMBOT =================
local aimbotEnabled, aimbotLoop, screenGui = false, nil, nil

Tab:Toggle({
	Title = "Aimbot",
	Desc = "ON/OFF Aimbot",
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

-- ================= ESP PLAYERS (Last Known Position) =================
local espLoop = nil
local espFolder = nil
local anchorFolder = nil
local espAnchors = {}

Tab:Toggle({
	Title = "ESP Players",
	Desc = "เปิด/ปิด ESP (ระบบจำตำแหน่งล่าสุดเมื่อศัตรูหายไป)",
	Value = false,
	Callback = function(state)
		if state then
			local function ensureFolder()
				if not (espFolder and espFolder.Parent) then
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
				
				if not (anchorFolder and anchorFolder.Parent) then
					anchorFolder = Instance.new("Folder")
					anchorFolder.Name = "ESP_Anchors"
					anchorFolder.Parent = workspace
				end
			end
			
			ensureFolder()
			
			espLoop = RunService.RenderStepped:Connect(function()
				ensureFolder()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				if not myPart then return end
				
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer then
						
						-- สร้างสมอ (Anchor) ล่องหนให้ผู้เล่น
						local anchor = espAnchors[player]
						if not anchor or not anchor.Parent then
							anchor = Instance.new("Part")
							anchor.Name = "Anchor_" .. player.Name
							anchor.Transparency = 1
							anchor.Anchored = true
							anchor.CanCollide = false
							anchor.Size = Vector3.new(1, 1, 1)
							anchor.Position = Vector3.new(0, -9999, 0)
							anchor.Parent = anchorFolder
							espAnchors[player] = anchor
						end

						-- สร้างป้ายชื่อ (เกาะกับสมอ)
						local gui = espFolder:FindFirstChild(player.Name .. "_ESP")
						if not gui then
							gui = Instance.new("BillboardGui")
							gui.Name = player.Name .. "_ESP"
							gui.Size = UDim2.new(0, 200, 0, 50)
							gui.StudsOffset = Vector3.new(0, 2.5, 0)
							gui.AlwaysOnTop = true
							
							local txt = Instance.new("TextLabel")
							txt.Name = "InfoText"
							txt.Size = UDim2.new(1, 0, 1, 0)
							txt.BackgroundTransparency = 1
							txt.TextStrokeTransparency = 0.5
							txt.Font = Enum.Font.SourceSansBold
							txt.Parent = gui
							gui.Parent = espFolder
						end
						
						if gui.Adornee ~= anchor then gui.Adornee = anchor end

						local hl = espFolder:FindFirstChild(player.Name .. "_HL")
						if not hl then
							hl = Instance.new("Highlight")
							hl.Name = player.Name .. "_HL"
							hl.FillColor = Color3.fromRGB(0, 255, 255)
							hl.OutlineColor = Color3.fromRGB(255, 255, 255)
							hl.FillTransparency = 0.5
							hl.Parent = espFolder
						end
						
						local char = getCustomCharacter(player)
						local targetPart = getTargetPart(char)
						local txt = gui:FindFirstChild("InfoText")
						
						-- ถ้าศัตรูอยู่ในระยะและมองเห็น (Active)
						if char and targetPart and isValidTarget(char) then
							-- ย้ายสมอมาที่ตัวศัตรู
							anchor.Position = targetPart.Position
							
							local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
							if dist <= 3000 then
								if txt then
									local hum = char:FindFirstChildOfClass("Humanoid")
									local hp = hum and math.floor(hum.Health) or 0
									txt.TextColor3 = Color3.fromRGB(0, 255, 255)
									txt.Text = string.format("%s | [%dm] | %d HP", player.Name, dist, hp)
									txt.TextSize = dist > 1500 and 11 or (dist > 500 and 12 or 14)
								end
								
								if hl.Adornee ~= char then hl.Adornee = char end
								hl.Enabled = true
								gui.Enabled = true
							else
								hl.Enabled = false
								gui.Enabled = false
							end
							
						-- ถ้าศัตรูหายไป โดนเกมสตรีมทิ้ง หรือตาย (Ghost Mode)
						else
							hl.Enabled = false -- ปิดไฮไลต์เพราะไม่มีตัวคน
							
							-- เช็คว่าสมอเคยบันทึกตำแหน่งไว้ไหม (ตำแหน่งต้องไม่ใช่อยู่ใต้ดินลึกๆ)
							if anchor.Position.Y > -9000 then
								local dist = math.floor((myPart.Position - anchor.Position).Magnitude)
								if dist <= 3000 then
									if txt then
										txt.TextColor3 = Color3.fromRGB(170, 170, 170) -- เปลี่ยนป้ายเป็นสีเทา
										txt.Text = string.format("%s [LAST SEEN %dm]", player.Name, dist)
										txt.TextSize = 12
									end
									gui.Enabled = true
								else
									gui.Enabled = false
								end
							else
								gui.Enabled = false
							end
						end
					end
				end
			end)
		else
			if espLoop then espLoop:Disconnect() espLoop = nil end
			if espFolder then espFolder:Destroy() espFolder = nil end
			if anchorFolder then anchorFolder:Destroy() anchorFolder = nil end
			espAnchors = {} -- เคลียร์สมอทั้งหมดเวลาปิด ESP
		end
	end
})

-- ================= ESP BOT =================
local botEspLoop = nil
local botEspFolder = nil

Tab:Toggle({
	Title = "ESP บอท (Bot)",
	Desc = "เปิด/ปิด ESP บอท",
	Value = false,
	Callback = function(state)
		if state then
			if not botEspFolder then
				botEspFolder = Instance.new("Folder")
				botEspFolder.Name = "BotESPFolder"
				pcall(function() botEspFolder.Parent = CoreGui end)
				if not botEspFolder.Parent then botEspFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end
			
			botEspLoop = RunService.RenderStepped:Connect(function()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				if not myPart then return end
				
				for _, model in ipairs(workspace:GetChildren()) do
					if model:IsA("Model") and model ~= myChar then
						local hum = model:FindFirstChildOfClass("Humanoid")
						local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
						
						if hum and root and hum.Health > 0 then
							if not Players:GetPlayerFromCharacter(model) then
								local espName = "Bot_" .. tostring(model:GetDebugId(10))
								local gui = botEspFolder:FindFirstChild(espName .. "_ESP")
								
								if not gui then
									gui = Instance.new("BillboardGui", botEspFolder)
									gui.Name = espName .. "_ESP"
									gui.Size = UDim2.new(0, 200, 0, 50)
									gui.StudsOffset = Vector3.new(0, 2, 0)
									gui.AlwaysOnTop = true
									local txt = Instance.new("TextLabel", gui)
									txt.Name = "InfoText"
									txt.Size = UDim2.new(1, 0, 1, 0)
									txt.BackgroundTransparency = 1
									txt.TextColor3 = Color3.fromRGB(255, 50, 50)
									txt.Font = Enum.Font.SourceSansBold
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
			end)
		else
			if botEspLoop then botEspLoop:Disconnect() botEspLoop = nil end
			if botEspFolder then botEspFolder:Destroy() botEspFolder = nil end
		end
	end
})

-- ================= ESP EXIT =================
local exitLoop = nil
local exitFolder = nil

Tab:Toggle({
	Title = "ESP ทางออก",
	Desc = "เปิด/ปิด ทางออก",
	Value = false,
	Callback = function(state)
		if state then
			if not exitFolder then
				exitFolder = Instance.new("Folder")
				exitFolder.Name = "ExitESPFolder"
				pcall(function() exitFolder.Parent = CoreGui end)
				if not exitFolder.Parent then exitFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end
			
			exitLoop = RunService.RenderStepped:Connect(function()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				if not myPart then return end
				
				local noCol = workspace:FindFirstChild("NoCollision")
				if noCol and noCol:FindFirstChild("ExitLocations") then
					for _, v in ipairs(noCol.ExitLocations:GetChildren()) do
						if v.Name == "Exit" then
							createOrUpdateObjectESP(exitFolder, v, "🚪 ทางออก", Color3.fromRGB(50, 255, 50), myPart)
						end
					end
				end
			end)
		else
			if exitLoop then exitLoop:Disconnect() exitLoop = nil end
			if exitFolder then exitFolder:Destroy() exitFolder = nil end
		end
	end
})

-- ================= ESP CRATES =================
local crateLoop = nil
local crateFolder = nil

Tab:Toggle({
	Title = "ESP กล่องทหาร",
	Desc = "เปิด/ปิด กล่อง",
	Value = false,
	Callback = function(state)
		if state then
			if not crateFolder then
				crateFolder = Instance.new("Folder")
				crateFolder.Name = "CrateESPFolder"
				pcall(function() crateFolder.Parent = CoreGui end)
				if not crateFolder.Parent then crateFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end
			
			crateLoop = RunService.RenderStepped:Connect(function()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				if not myPart then return end
				
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
				
				for _, gui in ipairs(crateFolder:GetChildren()) do
					if not gui.Adornee or not gui.Adornee.Parent then
						gui:Destroy()
					end
				end
			end)
		else
			if crateLoop then crateLoop:Disconnect() crateLoop = nil end
			if crateFolder then crateFolder:Destroy() crateFolder = nil end
		end
	end
})

-- ================= VISUALS =================
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
			Lighting.GlobalShadows = or
