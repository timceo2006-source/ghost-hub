local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub",
    Icon = "door-open", -- lucide icon
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
            print("clicked")
        end,
    },
})

local Tab = Window:Tab({
    Title = "Farm",
    Icon = "", -- optional
    Locked = false,
})

-- ==========================================
-- Auto Farm Bandit (Fixed & Debugged)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ดึง RemoteEvent ผ่าน Net Framework
local sleitnickNet = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local ActionRemote = sleitnickNet:WaitForChild("RE/ActionRemote")
local QuestEvent = sleitnickNet:WaitForChild("RE/QuestEvent")

local autoFarmActive = false
local farmThread = nil
local noclipConnection = nil

-- 1. ระบบ Noclip และลบแรงโน้มถ่วงไม่ให้ร่วงพื้น
local function EnableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if autoFarmActive and Player.Character then
            for _, part in pairs(Player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end)
end

local function DisableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- 2. อ่านค่า Level
local function GetCurrentLevel()
    local levelUI = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("ScreenGui")
        and Player.PlayerGui.ScreenGui:FindFirstChild("HUD")
        and Player.PlayerGui.ScreenGui.HUD:FindFirstChild("Level")
    
    if levelUI then
        local text = levelUI.Text ~= "" and levelUI.Text or levelUI.ContentText
        local levelNum = string.match(text, "%d+")
        if levelNum then return tonumber(levelNum) end
    end
    
    if Player:FindFirstChild("PlayerData") and Player.PlayerData:FindFirstChild("Experience") then
        return Player.PlayerData.Experience.Level.Value
    end
    return 1
end

-- 3. เช็คสถานะเควส
local function HasActiveQuest()
    local container = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("ScreenGui")
        and Player.PlayerGui.ScreenGui:FindFirstChild("Quest")
        and Player.PlayerGui.ScreenGui.Quest:FindFirstChild("Container")

    if container and container.Visible then
        for _, child in pairs(container:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and child.Visible then
                return true
            end
        end
    end
    return false
end

-- 4. ค้นหา Bandit ใน Workspace.Enemies
local function GetTargetBandit()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    for _, mob in pairs(enemiesFolder:GetChildren()) do
        if string.find(mob.Name, "Bandit") 
           and mob:FindFirstChild("Humanoid") 
           and mob.Humanoid.Health > 0 
           and mob:FindFirstChild("HumanoidRootPart") then
            return mob
        end
    end
    return nil
end

-- 5. ลูปทำงานหลัก
local function runFarmLogic()
    EnableNoclip()
    print("[AutoFarm] เริ่มทำงาน...")

    farmThread = task.spawn(function()
        local lastQuestTime = 0

        while autoFarmActive do
            task.wait(0.05)

            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local currentLevel = GetCurrentLevel()

                if currentLevel >= 1 and currentLevel <= 100 then
                    -- รับเควสอัตโนมัติเมื่อไม่มีเควส (หน่วงเวลา 3 วินาที)
                    if not HasActiveQuest() and (tick() - lastQuestTime > 3) then
                        lastQuestTime = tick()
                        print("[AutoFarm] กำลังรับเควส Bandit (ID: 1)...")
                        pcall(function()
                            QuestEvent:FireServer("Request", { Id = 1 })
                        end)
                    end

                    -- ค้นหามอนสเตอร์
                    local target = GetTargetBandit()

                    if target and target:FindFirstChild("HumanoidRootPart") and target.Humanoid.Health > 0 then
                        local targetHRP = target.HumanoidRootPart
                        -- ตำแหน่งลอยเหนือหัว 4.5 หน่วย
                        local targetCFrame = targetHRP.CFrame * CFrame.new(0, 4.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

                        -- เคลื่อนที่เข้าหาแบบ Lerp สด (ไม่ติดค้าง Tween)
                        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, 0.3)

                        -- ส่งสัญญาณตี
                        pcall(function()
                            ActionRemote:FireServer("M1", "Combat")
                        end)
                    end
                else
                    print("[AutoFarm] เลเวลไม่อยู่ในช่วง 1 - 100 (ปัจจุบัน: " .. tostring(currentLevel) .. ")")
                end
            end
        end
    end)
end

-- 6. Toggle สำหรับใส่ใน UI
Tab:Toggle({
    Title = "Auto Farm Bandit (Fixed)",
    Desc = "แก้ไขการเคลื่อนที่ + พิมพ์ Debug ลง Delta Console",
    Value = false,
    Callback = function(state)
        autoFarmActive = state
        if state then
            runFarmLogic()
        else
            print("[AutoFarm] ปิดการทำงาน")
            if farmThread then task.cancel(farmThread) end
            DisableNoclip()
        end
    end
})
