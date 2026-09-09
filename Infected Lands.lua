-- ป้องกันการรันสคริปต์ก่อนเกมโหลดเสร็จ
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FOV_RADIUS = 150
local AIM_SMOOTHNESS = 1
local MAX_AIM_DISTANCE = 600 -- ระยะล็อกเป้าสูงสุด 600 เมตร

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
	local shortestDist = MAX_AIM_DISTANCE
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
						local dist = (myPos - targetPart.Position).Magnitude
						if dist <= shortestDist then
							if isVisible(targetPart) then 
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

local Tab = Window:Tab({ Title = "Main", Locked = false })

-- ================= AIMBOT =================
local aimbotEnabled, aimbotLoop, screenGui = false, nil, nil

Tab:Toggle({
	Title = "Aimbot (Limit 600m)",
	Desc = "ON/OFF Aimbot (ล็อกเป้าเฉพาะคนที่อยู่ในระยะไม่เกิน 600m)",
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

-- ================= ESP PLAYERS =================
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

Tab:Toggle({
	Title = "ESP Players",
	Desc = "เปิด/ปิด ESP ผู้เล่น (เช็คไว ไม่แลค ไม่กินสเปค)",
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
