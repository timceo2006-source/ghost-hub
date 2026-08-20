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

-- เปลี่ยนค่าเริ่มต้นเป็น Table เปล่าเพื่อรองรับการเลือกหลายอัน
local selectedRarities = {}

local Dropdown = TabRoll:Dropdown({
    Title = "Select Target Rarities",
    Desc = "Select multiple rarities to buy/stop",
    Values = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Value = {},
    MultiSelect = true,
    Callback = function(values)
        selectedRarities = values
    end,
})

local function isRaritySelected(rarityText)
    if not rarityText then return false end
    for _, selected in pairs(selectedRarities) do
        -- รองรับทั้งกรณีที่ WindUI ส่งค่ามาเป็นตารางคีย์แบบ [1] = "Epic" หรือคีย์ชื่อเรตติ้ง
        local val = type(selected) == "table" and (selected.Name or selected[1]) or selected
        if type(val) == "string" and val:lower() == rarityText:lower() then
            return true
        end
    end
    return false
end


local ToggleRoll = TabRoll:Toggle({
    Title = "Auto Roll",
    Desc = "Rolls at machine",
    Icon = "dice-5",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoRoll = state
    end,
})

local ToggleBuy = TabRoll:Toggle({
    Title = "Auto Buy Target",
    Desc = "On = Stops rolling and buys target. Off = Stops rolling if target appears, but does not buy.",
    Icon = "shopping-cart",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoBuy = state
    end,
})

-- ฟังก์ชันเสริมสำหรับเช็คว่าเรตติ้งนี้ถูกเลือกไว้ใน Dropdown หรือยัง
local function isRaritySelected(rarityText)
    if not rarityText then return false end
    for _, selected in pairs(selectedRarities) do
        if type(selected) == "string" and selected:lower() == rarityText:lower() then
            return true
        end
    end
    return false
end

-- ลูปเช็คตัวละครเป้าหมาย (รองรับ Multi-select)
task.spawn(function()
    while true do
        local myPlot = nil
        for _, plot in ipairs(Plost:GetChildren()) do
            local plotOwner = plot:GetAttribute("Owner")
            if plotOwner and type(plotOwner) == "string" and plotOwner:gsub("%s+", "") == LocalPlayer.Name:gsub("%s+", "") then
                myPlot = plot
                break
            end
        end
        
        local targetChar = nil
        local targetExists = false
        
        if myPlot then
            local charactersFolder = myPlot:FindFirstChild("Characters")
            if charactersFolder then
                for _, char in ipairs(charactersFolder:GetChildren()) do
                    local success, rarityText = pcall(function()
                        return char.Head.BuyUI.Frame.Chance.TextLabel.Text
                    end)
                    if success and rarityText then
                        -- เช็คเทียบกับรายการที่เลือกไว้หลายอัน
                        if isRaritySelected(rarityText) then
                            targetChar = char
                            targetExists = true
                            break
                        end
                    end
                end
            end
        end
        
        -- ถ้าเปิด Auto Buy และเจอเป้าหมายที่เลือกไว้: สั่งหยุดสุ่ม และพุ่งไปซื้อให้เสร็จ
        if _G.AutoBuy and targetExists and targetChar then
            _G.IsBuying = true 
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local buyPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChildWhichIsA("BasePart")
            
            if buyPart and hrp then
                hrp.CFrame = buyPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.4)
                
                local prompt = targetChar:FindFirstChild("ProximityPrompt", true) or targetChar:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    repeat
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                        task.wait(0.4)
                    until not targetChar.Parent or not targetChar:FindFirstChild("Head") or not targetChar.Head:FindFirstChild("BuyUI") or not targetChar.Head.BuyUI.Enabled
                end
            end
            task.wait(0.4)
            _G.IsBuying = false
            
        -- ถ้าปิด Auto Buy แต่เจอเป้าหมายที่เลือกไว้: แค่ล็อกสถานะไม่ให้ Auto Roll สุ่มต่อ
        elseif not _G.AutoBuy and targetExists then
            _G.IsBuying = true
        else
            _G.IsBuying = false
        end
        
        task.wait(0.3)
    end
end)

-- ลูป Auto Roll (ทำหน้าที่กดสุ่มที่ตู้สุ่มอย่างเดียว)
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
