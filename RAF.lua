local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Plost = workspace.Plots

local waveText = PlayerGui.MainUI.UITop.Top.Main.Wave.Frame.TextLabel
local startButtonText = PlayerGui.MainUI.UITop.Top.Main.Start.Frame.TextLabel
local RemoteEvent = game:GetService("ReplicatedStorage").Remotes.Fight.Start
local stopWave = 70
local selectedRarity = "All" -- เพิ่มตัวแปรที่ขาดตรงนี้เพื่อให้ Dropdown ทำงานได้สมบูรณ์

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
    Title = "Auto Roll",
    Desc = "Stays at the machine and rolls smoothly",
    Icon = "dice-5",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoRoll = state
    end,
})

local ToggleRoll = TabRoll:Toggle({
    Title = "Auto Roll",
    Desc = "Stays at the machine and rolls smoothly",
    Icon = "dice-5",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoRoll = state
    end,
})

local ToggleBuy = TabRoll:Toggle({
    Title = "Auto Buy Target",
    Desc = "Focuses on buying target rarity and pauses rolling",
    Icon = "shopping-cart",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoBuy = state
    end,
})

-- ลูป Auto Roll (ยืนกดสุ่มนิ่งๆ ที่ตู้ โดยจะทำงานก็ต่อเมื่อไม่ได้อยู่ในสถานะซื้อ)
task.spawn(function()
    while true do
        if _G.AutoRoll and not _G.IsBuying then
            local myPlot = nil
            for _, plot in ipairs(Plost:GetChildren()) do
                local plotOwner = plot:GetAttribute("Owner")
                if plotOwner and type(plotOwner) == "string" and plotOwner:gsub("%s+", "") == LocalPlayer.Name:gsub("%s+", "") then
                    myPlot = plot
                    break
                end
            end
            
            if myPlot then
                local rollModel = myPlot:FindFirstChild("Roll")
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if rollModel then
                    local prompt = rollModel:FindFirstChild("RollPrompt", true)
                    local targetPart = rollModel:FindFirstChild("RollButton") and rollModel.RollButton:FindFirstChild("Button") or rollModel.PrimaryPart or rollModel:FindFirstChildWhichIsA("BasePart")
                    
                    if targetPart and hrp then
                        local targetPos = targetPart.Position + Vector3.new(0, 3, 0)
                        
                        -- ล็อควาปมายืนที่ตู้แค่นิ่งๆ ถ้าไม่ออกนอกระยะจะไม่ดึงซ้ำซ้อนให้กระดุกกระดิ๊ก
                        if (hrp.Position - targetPos).Magnitude > 4 then
                            hrp.CFrame = CFrame.new(targetPos)
                            task.wait(0.2)
                        end
                        
                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                        end
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

-- ลูป Auto Buy (เจอตัวเป้าหมายแล้ว ล็อกนิ่ง โฟกัสซื้อตัวนั้นจนกว่าจะสำเร็จ)
task.spawn(function()
    while true do
        if _G.AutoBuy then
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
                    _G.IsBuying = true -- สั่งหยุด Auto Roll ทันทีแบบเด็ดขาด
                    local buyPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChildWhichIsA("BasePart")
                    
                    if buyPart then
                        -- วาปไปหาตัวละครเป้าหมาย
                        hrp.CFrame = buyPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5) -- รอให้นิ่ง
                        
                        local prompt = targetChar:FindFirstChild("ProximityPrompt", true) or targetChar:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            -- วนลูปกดซื้อซ้ำๆ จนกว่าหน้าต่างซื้อ (BuyUI) จะหายไปหรือตัวละครถูกซื้อสำเร็จ
                            repeat
                                pcall(function()
                                    fireproximityprompt(prompt)
                                end)
                                task.wait(0.4)
                            until not targetChar.Parent or not targetChar:FindFirstChild("Head") or not targetChar.Head:FindFirstChild("BuyUI") or not targetChar.Head.BuyUI.Enabled
                        end
                    end
                    
                    task.wait(0.3)
                    _G.IsBuying = false -- ซื้อเสร็จแล้วค่อยปลดล็อกให้ Auto Roll กลับไปสุ่มต่อ
                end
            end
        end
        task.wait(0.5)
    end
end)
