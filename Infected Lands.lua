local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub - Pro Edition",
    Icon = "ghost",
    Author = "by You & AI",
    Folder = "ProGhostHub",
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

local minaTab = Window:Tab({ Title = "mina", Locked = false })
local vTab = Window:Tab({ Title = "V", Locked = false })

local AimbotSettings = {
    Enabled = false,
    FOV = 150,
    Smoothness = 0.5,
    MaxDistance = 600,
    Prediction = true
}
local aimbotLoop = nil

local function IsVisible(targetPart)
    if not targetPart then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, rayParams) == nil
end

local function GetClosestTarget()
    local closestTarget = nil
    local shortestDist = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart = player.Character:FindFirstChild("Head") or player.Character.PrimaryPart
            if targetPart then
                local dist3D = (Camera.CFrame.Position - targetPart.Position).Magnitude
                if dist3D <= AimbotSettings.MaxDistance and IsVisible(targetPart) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if screenDist <= AimbotSettings.FOV and screenDist < shortestDist then
                            shortestDist = screenDist
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

minaTab:Toggle({
    Title = "Aimbot",
    Desc = "Aimbot with Prediction",
    Value = false,
    Callback = function(state)
        AimbotSettings.Enabled = state
        if state then
            if not aimbotLoop then
                aimbotLoop = RunService.RenderStepped:Connect(function()
                    if AimbotSettings.Enabled then
                        local target = GetClosestTarget()
                        if target then
                            local aimPosition = target.Position
                            if AimbotSettings.Prediction then
                                local velocity = target.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                                local dist = (Camera.CFrame.Position - target.Position).Magnitude
                                local timeToTarget = dist / 2000 
                                aimPosition = aimPosition + (velocity * timeToTarget)
                            end
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPosition), AimbotSettings.Smoothness)
                        end
                    end
                end)
            end
        else
            if aimbotLoop then
                aimbotLoop:Disconnect()
                aimbotLoop = nil
            end
        end
    end
})

local ESP_Enabled = false
local espFolder = nil

local function ensureESPFolder()
    if not espFolder then
        espFolder = Instance.new("Folder")
        espFolder.Name = "UniversalESPFolder"
        local success, hiddenGui = pcall(function() return gethui() end)
        if success and hiddenGui then
            espFolder.Parent = hiddenGui
        else
            espFolder.Parent = CoreGui
        end
    end
end

vTab:Toggle({
    Title = "ESP Players",
    Desc = "Player ESP [Distance & HP]",
    Value = false,
    Callback = function(state)
        ESP_Enabled = state
        if state then
            ensureESPFolder()
            task.spawn(function()
                while ESP_Enabled do
                    if LocalPlayer.Character then
                        local myPos = LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position
                        if myPos then
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer then
                                    local char = player.Character
                                    local hum = char and char:FindFirstChild("Humanoid")
                                    local targetPart = char and (char:FindFirstChild("Head") or char.PrimaryPart)
                                    
                                    if char and hum and hum.Health > 0 and targetPart then
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
                                            txt.TextStrokeTransparency = 0.5
                                            txt.Font = Enum.Font.SourceSansBold
                                            txt.Parent = gui
                                            gui.Parent = espFolder
                                        end
                                        
                                        if gui.Adornee ~= targetPart then gui.Adornee = targetPart end
                                        
                                        local dist = math.floor((myPos - targetPart.Position).Magnitude)
                                        local txt = gui:FindFirstChild("InfoText")
                                        if txt then
                                            txt.Text = string.format("%s | [%dm] | %d HP", player.Name, dist, math.floor(hum.Health))
                                        end
                                        gui.Enabled = true
                                    else
                                        local gui = espFolder:FindFirstChild(player.Name .. "_ESP")
                                        if gui then gui.Enabled = false end
                                    end
                                end
                            end
                        end
                    else
                        if espFolder then espFolder:ClearAllChildren() end
                    end
                    task.wait(0.1)
                end
                if espFolder then espFolder:ClearAllChildren() end
            end)
        else
            if espFolder then espFolder:ClearAllChildren() end
        end
    end
})
