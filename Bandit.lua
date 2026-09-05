local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FOV_RADIUS = 150
local PREDICTION_AMOUNT = 0.12 
local AIM_SMOOTHNESS = 1.0 -- ปรับเป็น 1.0 เพื่อให้เป้าล็อกติดแน่น สู้แรงดีดปืน

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
			
			if char and targetPart and isVisible(targetPart) then
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

-- ================= AIMBOT SYSTEM =================
local aimbotHubEnabled = false
local aimbotEnabled = false
local aimbotLoop = nil
local aimbotHotkey = nil
local screenGui = nil

Tab:Button({
	Title = "Aimbot",
	Desc = "เปิด/ปิด Aimbot และ ปุ่มกลางจอ (กด X เพื่อเปิด/ปิด)",
	Locked = false,
	Callback = function()
		aimbotHubEnabled = not aimbotHubEnabled
		
		if aimbotHubEnabled then
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
								if not targetVelocity then
									targetVelocity = Vector3.new(0, 0, 0)
								end
								
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

-- ================= ESP 2D SYSTEM (SECURE) =================
local espHubEnabled = false
local espLoop = nil
local espScreen = nil

Tab:Button({
	Title = "ESP",
	Desc = "เปิด/ปิด ESP Players (ระบบ 2D ป้องกันเกมลบ)",
	Locked = false,
	Callback = function()
		espHubEnabled = not espHubEnabled
		
		if espHubEnabled then
			if not espScreen then
				espScreen = Instance.new("ScreenGui")
				espScreen.Name = "Secure2DESP"
				espScreen.IgnoreGuiInset = true 
				espScreen.ResetOnSpawn = false
				pcall(function() espScreen.Parent = CoreGui end)
				if not espScreen.Parent then espScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			end

			espLoop = RunService.RenderStepped:Connect(function()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer then
						local char = getCustomCharacter(player)
						local targetPart = getTargetPart(char)
						
						local labelName = player.Name .. "_TextESP"
						local label = espScreen:FindFirstChild(labelName)
						
						if char and targetPart and myPart then
							local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
							
							if dist <= 2500 then
								local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
								
								if onScreen then
									if not label then
										label = Instance.new("TextLabel")
										label.Name = labelName
										label.Parent = espScreen
										label.BackgroundTransparency = 1
										label.TextColor3 = Color3.fromRGB(0, 255, 255)
										label.TextStrokeTransparency = 0
										label.Font = Enum.Font.SourceSansBold
										label.Size = UDim2.new(0, 200, 0, 20)
										label.AnchorPoint = Vector2.new(0.5, 0.5) 
									end
									
									label.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
									label.Text = string.format("%s | [%dm]", player.Name, dist)
									label.Visible = true
									
									if dist > 1500 then
										label.TextSize = 11
									elseif dist > 500 then
										label.TextSize = 12
									else
										label.TextSize = 14
									end
								else
									if label then label.Visible = false end
								end
							else
								if label then label.Visible = false end
							end
						else
							if label then label.Visible = false end
						end
					end
				end
			end)
		else
			if espLoop then espLoop:Disconnect() espLoop = nil end
			if espScreen then 
				espScreen:Destroy() 
				espScreen = nil 
			end
		end
	end
})

-- ================= NIGHT VISION SYSTEM =================
local nightVisionEnabled = false
local lightingConnection = nil

Tab:Button({
	Title = "Night Vision",
	Desc = "เปิด/ปิด มองกลางคืน (สว่างทั้งแมพ)",
	Locked = false,
	Callback = function()
		nightVisionEnabled = not nightVisionEnabled
		
		if nightVisionEnabled then
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
