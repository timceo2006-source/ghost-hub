local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FOV_RADIUS = 150
local PREDICTION_AMOUNT = 0.12 
local AIM_SMOOTHNESS = 0.5 

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

local espHubEnabled = false
local espLoop = nil

Tab:Button({
	Title = "ESP",
	Desc = "เปิด/ปิด ESP Players",
	Locked = false,
	Callback = function()
		espHubEnabled = not espHubEnabled
		
		if espHubEnabled then
			local function applyEsp(player, char)
				local targetPart = getTargetPart(char)
				if not targetPart then return end

				if not targetPart:FindFirstChild("PlayerInfoGui") then
					local gui = Instance.new("BillboardGui")
					gui.Name = "PlayerInfoGui"
					gui.Adornee = targetPart
					gui.Size = UDim2.new(0, 200, 0, 50)
					gui.StudsOffset = Vector3.new(0, 2, 0)
					gui.AlwaysOnTop = true
					gui.Parent = targetPart

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

				if not char:FindFirstChild("PlayerHighlight") then
					local hl = Instance.new("Highlight")
					hl.Name = "PlayerHighlight"
					hl.Adornee = char
					hl.Parent = char
					hl.FillColor = Color3.fromRGB(0, 255, 255)
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.5
					hl.OutlineTransparency = 0
				end
			end

			espLoop = RunService.RenderStepped:Connect(function()
				local myChar = getCustomCharacter(LocalPlayer)
				local myPart = getTargetPart(myChar)
				if not myPart then return end

				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer then
						local char = getCustomCharacter(player)
						local targetPart = getTargetPart(char)
						
						if char and targetPart then
							applyEsp(player, char)

							local gui = targetPart:FindFirstChild("PlayerInfoGui")
							local hl = char:FindFirstChild("PlayerHighlight")
							
							local dist = math.floor((myPart.Position - targetPart.Position).Magnitude)
							
							if gui then
								local txt = gui:FindFirstChild("InfoText")
								if txt then
									if dist <= 2500 then
										txt.Text = string.format("%s | [%dm]", player.Name, dist)
										gui.Enabled = true
										
										if dist > 1500 then
											txt.TextSize = 11
										elseif dist > 500 then
											txt.TextSize = 12
										else
											txt.TextSize = 14
										end
									else
										gui.Enabled = false
									end
								end
							end
							
							if hl then
								hl.Enabled = (dist <= 2500)
							end
						end
					end
				end
			end)
		else
			if espLoop then espLoop:Disconnect() espLoop = nil end
			for _, player in ipairs(Players:GetPlayers()) do
				local char = getCustomCharacter(player)
				if char then
					local targetPart = getTargetPart(char)
					if targetPart and targetPart:FindFirstChild("PlayerInfoGui") then
						targetPart.PlayerInfoGui:Destroy()
					end
					if char:FindFirstChild("PlayerHighlight") then
						char.PlayerHighlight:Destroy()
					end
				end
			end
		end
	end
})
