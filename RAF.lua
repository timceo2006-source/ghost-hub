local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Plost = workspace.Plots

local waveText = PlayerGui.MainUI.UITop.Top.Main.Wave.Frame.TextLabel
local startButtonText = PlayerGui.MainUI.UITop.Top.Main.Start.Frame.TextLabel
local RemoteEvent = game:GetService("ReplicatedStorage").Remotes.Fight.Start
local stopWave = 70
local selectedRarity = "All"

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

local Tab = Window:Tab({
    Title = "Main",
    Locked = false,
})

local Slider = Tab:Slider({
    Title = "Stop wave",
    Desc = "Slider Description",
    Step = 1,
    Value = {
        Min = 1,
        Max = 500,
        Default = 70,
    },
    Callback = function(value)
        stopWave = value
    end
})

local Toggle = Tab:Toggle({
    Title = "Auto Play",
    Desc = "Toggle Description",
    Icon = "bird",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoPlay = state
        if not state then
            RemoteEvent:FireServer("Stop")
        end
    end
})

task.spawn(function()
    while true do
        if _G.AutoPlay then
            local currentWaveNum = tonumber(waveText.Text:match("%d+")) or tonumber(waveText.Text) or 0
            
            if currentWaveNum >= stopWave then
                RemoteEvent:FireServer("Stop")
                task.wait(3)
                RemoteEvent:FireServer("Start")
                task.wait(2)
            else
                if startButtonText.Text == "START" then
                    RemoteEvent:FireServer("Start")
                    task.wait(2)
                elseif startButtonText.Text == "STOP" then
                end
            end
        end
        task.wait(1)
    end
end)

local TabRoll = Window:Tab({
    Title = "Roll & Buy",
    Locked = false,
})

local Dropdown = TabRoll:Dropdown({
    Title = "Select Target Rarity",
    Desc = "Buy and continue rolling when this rarity appears",
    Values = {"All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Value = "All",
    Callback = function(value)
        selectedRarity = value
    end,
})

local ToggleRoll = TabRoll:Toggle({
    Title = "Auto Roll & Buy",
    Desc = "Auto roll, buy target rarity, and loop",
    Icon = "dice-5",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoRoll = state
    end,
})

task.spawn(function()
    while true do
        if _G.AutoRoll then
            local myPlot = nil
            
            for _, plot in ipairs(Plost:GetChildren()) do
                local plotOwner = plot:GetAttribute("Owner")
                if plotOwner and type(plotOwner) == "string" and plotOwner:gsub("%s+", "") == LocalPlayer.Name:gsub("%s+", "") then
                    myPlot = plot
                    break
                end
            end
            
            if myPlot then
                local charactersFolder = myPlot:FindFirstChild("Characters")
                local targetChar = nil
                local targetRarityMatch = false
                
                if charactersFolder then
                    for _, char in ipairs(charactersFolder:GetChildren()) do
                        local success, rarityText = pcall(function()
                            return char.Head.BuyUI.Frame.Chance.TextLabel.Text
                        end)
                        
                        if success and rarityText then
                            if selectedRarity == "All" or rarityText:lower() == selectedRarity:lower() then
                                targetChar = char
                                targetRarityMatch = true
                                break
                            end
                        end
                    end
                end
                
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if targetRarityMatch and targetChar and hrp then
                    local buyPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChildWhichIsA("BasePart")
                    if buyPart then
                        hrp.CFrame = buyPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5)
                        
                        local prompt = targetChar:FindFirstChild("ProximityPrompt", true) or targetChar:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt)
                            task.wait(0.5)
                        end
                    end
                else
                    local rollModel = myPlot:FindFirstChild("Roll")
                    if rollModel then
                        local prompt = rollModel:FindFirstChild("RollPrompt", true)
                        local targetPart = rollModel:FindFirstChild("RollButton") and rollModel.RollButton:FindFirstChild("Button") or rollModel.PrimaryPart or rollModel:FindFirstChildWhichIsA("BasePart")
                        
                        if targetPart and hrp then
                            local targetPos = targetPart.Position + Vector3.new(0, 3, 0)
                            if (hrp.Position - targetPos).Magnitude > 8 then
                                hrp.CFrame = CFrame.new(targetPos)
                                task.wait(0.5)
                            end
                            
                            if prompt then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
    Title = "Roll & Buy",
    Locked = false,
})

local Dropdown = TabRoll:Dropdown({
    Title = "Select Target Rarity",
    Desc = "Buy and continue rolling when this rarity appears",
    Values = {"All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Value = "All",
    Callback = function(value)
        selectedRarity = value
    end,
})

local ToggleRoll = TabRoll:Toggle({
    Title = "Auto Roll & Buy",
    Desc = "Auto roll, buy target rarity, and loop",
    Icon = "dice-5",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoRoll = state
    end,
})

task.spawn(function()
    while true do
        if _G.AutoRoll then
            local myPlot = nil
            
            for _, plot in ipairs(Plost:GetChildren()) do
                local plotOwner = plot:GetAttribute("Owner")
                if plotOwner and type(plotOwner) == "string" and plotOwner:gsub("%s+", "") == LocalPlayer.Name:gsub("%s+", "") then
                    myPlot = plot
                    break
                end
            end
            
            if myPlot then
                local charactersFolder = myPlot:FindFirstChild("Characters")
                local targetChar = nil
                local targetRarityMatch = false
                
                -- 1. เช็คว่ามีตัวละครที่สุ่มออกมาตรงกับที่เลือกใน Dropdown หรือไม่
                if charactersFolder then
                    for _, char in ipairs(charactersFolder:GetChildren()) do
                        local success, rarityText = pcall(function()
                            return char.Head.BuyUI.Frame.Chance.TextLabel.Text
                        end)
                        
                        if success and rarityText then
                            if selectedRarity == "All" or rarityText:lower() == selectedRarity:lower() then
                                targetChar = char
                                targetRarityMatch = true
                                break
                            end
                        end
                    end
                end
                
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if targetRarityMatch and targetChar and hrp then
                    -- 2. ถ้าเจอตัวที่ตรงเงื่อนไข ให้วาปไปที่ตัวละครนั้นเพื่อกดซื้อ
                    local buyPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChildWhichIsA("BasePart")
                    if buyPart then
                        hrp.CFrame = buyPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5)
                        
                        local prompt = targetChar:FindFirstChild("ProximityPrompt", true) or targetChar:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt)
                            task.wait(0.5)
                        end
                    end
                else
                    -- 3. ถ้ายังไม่เจอ ให้วาปกลับมาที่ตู้สุ่ม (Roll) แล้วกดสุ่มต่อ
                    local rollModel = myPlot:FindFirstChild("Roll")
                    if rollModel then
                        local prompt = rollModel:FindFirstChild("RollPrompt", true)
                        local targetPart = rollModel:FindFirstChild("RollButton") and rollModel.RollButton:FindFirstChild("Button") or rollModel.PrimaryPart or rollModel:FindFirstChildWhichIsA("BasePart")
                        
                        if targetPart and hrp then
                            local targetPos = targetPart.Position + Vector3.new(0, 3, 0)
                            if (hrp.Position - targetPos).Magnitude > 8 then
                                hrp.CFrame = CFrame.new(targetPos)
                                task.wait(0.5)
                            end
                            
                            if prompt then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
