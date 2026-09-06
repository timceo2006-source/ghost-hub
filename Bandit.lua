local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FOV_RADIUS = 150
local PREDICTION_AMOUNT = 0.12 
local AIM_SMOOTHNESS = 1

local origLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient
}

local function getCustomCharacter(player)
	if player.Character and player.Character:FindFirstChildWhichIsA("BasePart", true) then
		return player.Character
	end
	local char = workspace:FindFirstChild(player.Name)
	if char and char:IsA("Model") then
		return char
	end
	return nil
end

local function getTargetPart(char)
	if not char then return nil end
	return char:FindFirstChild("Head", true) or 
		   char:FindFirstChild("HumanoidRootPart", true) or 
		   char:FindFirstChildWhichIsA("BasePart", true)
end

-- ฟังก์ชันสำหรับกรอง แอนตี้ชีท (ผีล่องหน)
local function isValidTarget(char)
	if not char then return false end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then 
		return false 
	end
	
	local head = char:FindFirstChild("Head") or char:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		if head.Transparency >= 0.9 then
			return false
		end
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
	
	local myPart = getTargetPart(myChar)
	if not myPart then return false end

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
			
			if char and targetPart and isValidTarget(char) and isVisible(targetPart) then
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if screenDist <= FOV_RADIUS then
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
	return closestTarget
end

-- ฟังก์ชันสร้างป้ายบอกระยะทางสำหรับสิ่งของ
local function createOrUpdateObjectESP(folder, object, displayName, color, myPart)
	if not object then return end
	
	local targetPart = object
	if object:IsA("Model") then
		targetPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
	end
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
	if txt then
		txt.Text = string.format("%s\n[%dm]", displayName, dist)
	end
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
})

local Tab = Window:Tab({
	Title = "Main",
	Locked = false,
})

local aimbotEnabled = false
local aimbotLoop = nil
local aimbotHotkey = nil
local screenGui = nil

Tab:Toggle({
	Title = "Aimbot",
	Desc = "เปิด/ปิด Aimbot และ ปุ่มกลางจอ (กด X เพื่อเปิด/ปิด)",
	Value = false,
	Callback = function(state)
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
			toggleButton.TextColor3 = Color3.fromRGB(255, 50, 50)
			toggleButton.TextSize = 13
			toggleButton.Font = Enum.Font.SourceSansBold
			toggleButton.Text = "AIM: OFF"
			toggleButton.Parent = screenGui
			
			aimbotEnabled = false

			local function toggleAimbotState()
				aimbotEnabled = not aimbotEnabled
				toggleButton.TextColor3 = aimbotEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
				toggleButton.Text = aimbotEnabled and "AIM: ON" or "AIM: OFF"
			end

			toggleButton.MouseButton1Click:Connect(toggleAimbotState)
			aimbotHotkey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.KeyCode == Enum.KeyCode.X then
					toggleAimbotState()
				end
			end)

			if not aimbotLoop then
				aimbotLoop = RunService.RenderStepped:Connect(function()
					if aimbotEnabled then
						local myChar = getCustomCharacter(LocalPlayer)
						local myPart = getTargetPart(myChar)
						if myPart then
							local targetPart = getBestTargetInFOV(myPart.Position)
							if targetPart then
								local targetVelocity = targetPart.AssemblyLinearVelocity
								if not targetVelocity then targetVelocity = Vector3.new(0, 0, 0) end
								
								local predictedPos = targetPart.Position + (targetVelocity * PREDICTION_AMOUNT)
								local currentCamCF = Camera.CFrame
								local targetCF = CFrame.new(currentCamCF.Position, predictedPos)
								Camera.CFrame = currentCamCF:Lerp(targetCF, AIM_SMOOTHNESS)
							end
						end
					end
				end)
			end
		else
			aimbotEnabled = false
			if screenGui then screenGui:Destroy() screenGui = nil end
			if aimbotLoop then aimbotLoop:Disconnect() aimbotLoop = nil end
			if aimbotHotkey then aimbotHotkey:Disconnect() aimbotHotkey = nil end
		end
	end
})

local espLoop = nil
local espFolder = nil

Tab:Toggle({
	Title = "ESP Players",
	Desc = "เปิด/ปิด ESP ผู้เล่น",
	Value = false,
	Callback = function(state)
		if state then
			if not espFolder then
				espFolder = Instance.new("Folder")
				espFolder.Name = "SecureESPFolder"
				pcall(function() espFolder.Parent = CoreGui end)
				if not espFolder.Parent then espFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end

			espLoop = RunService.RenderStepped:Connect(function()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				if not myPart then return end

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
								gui.Parent = espFolder

								local textLabel = Instance.new("TextLabel")
								textLabel.Name = "InfoText"
								textLabel.Size = UDim2.new(1, 0, 1, 0)
								textLabel.BackgroundTransparency = 1
								textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
								textLabel.TextStrokeTransparency = 0
								textLabel.TextSize = 14
								textLabel.Font = Enum.Font.SourceSansBold
								textLabel.Parent = gui
							end
							
							local hl = espFolder:FindFirstChild(player.Name .. "_HL")
							if not hl then
								hl = Instance.new("Highlight")
								hl.Name = player.Name .. "_HL"
								hl.FillColor = Color3.fromRGB(0, 255, 255)
								hl.OutlineColor = Color3.fromRGB(255, 255, 255)
								hl.FillTransparency = 0.5
								hl.OutlineTransparency = 0
								hl.Parent = espFolder
							end
							
							if gui.Adornee ~= targetPart then gui.Adornee = targetPart end
							if hl.Adornee ~= char then hl.Adornee = char end
							
							local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
							
							if dist <= 2500 then
								local txt = gui:FindFirstChild("InfoText")
								if txt then
									txt.Text = string.format("%s | [%dm]", player.Name, dist)
									if dist > 1500 then txt.TextSize = 11
									elseif dist > 500 then txt.TextSize = 12
									else txt.TextSize = 14 end
								end
								
								if not gui.Enabled then gui.Enabled = true end
								if not hl.Enabled then hl.Enabled = true end
							else
								if gui.Enabled then gui.Enabled = false end
								if hl.Enabled then hl.Enabled = false end
							end
						else
							local gui = espFolder:FindFirstChild(player.Name .. "_ESP")
							local hl = espFolder:FindFirstChild(player.Name .. "_HL")
							if gui and gui.Enabled then gui.Enabled = false end
							if hl and hl.Enabled then hl.Enabled = false end
						end
					end
				end
			end)
		else
			if espLoop then espLoop:Disconnect() espLoop = nil end
			if espFolder then espFolder:Destroy() espFolder = nil end
		end
	end
})

local exitLoop = nil
local exitFolder = nil

Tab:Toggle({
	Title = "ESP ทางออก",
	Desc = "แสดงจุดหลบหนี (Exit Locations)",
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
				if noCol then
					local exitLocs = noCol:FindFirstChild("ExitLocations")
					if exitLocs then
						for _, v in ipairs(exitLocs:GetChildren()) do
							if v.Name == "Exit" then
								createOrUpdateObjectESP(exitFolder, v, "🚪 ทางออก", Color3.fromRGB(50, 255, 50), myPart)
							end
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

local crateLoop = nil
local crateFolder = nil

Tab:Toggle({
	Title = "ESP กล่องทหาร",
	Desc = "แสดงกล่อง Military Crate",
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
						end
					end
				end
				
				-- เคลียร์ป้ายเก่าๆ กรณีของถูกเก็บหรือหายไป
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

local lightingConnection = nil

Tab:Toggle({
	Title = "Night Vision",
	Desc = "เปิด/ปิด มองกลางคืน (สว่างทั้งแมพ)",
	Value = false,
	Callback = function(state)
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
			if lightingConnection then
				lightingConnection:Disconnect()
				lightingConnection = nil
			end
			Lighting.Brightness = origLighting.Brightness
			Lighting.ClockTime = origLighting.ClockTime
			Lighting.FogEnd = origLighting.FogEnd
			Lighting.GlobalShadows = origLighting.GlobalShadows
			Lighting.Ambient = origLighting.Ambient
		end
	end
})
