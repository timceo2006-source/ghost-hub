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
-- Auto Farm Bandit (Quest Fix & Mob Finder)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ดึง RemoteEvent
local sleitnickNet = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local ActionRemote = sleitnickNet:WaitForChild("RE/ActionRemote")
local QuestEvent = sleitnickNet:WaitForChild("RE/QuestEvent")

local autoFarmActive = false
local farmThread = nil
local noclipConnection = nil

-- 1. ระบบ Noclip
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

-- 2. อ่านค่า Level จาก HUD
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
    return 1
end

-- 3. ตรวจสอบเควสแบบครอบคลุม (เช็คจาก Quest.Container และ QuestTracker แถบข้างจอ)
local function HasActiveQuest()
    local playerGui = Player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local screenGui = playerGui:FindFirstChild("ScreenGui")
    if not screenGui then return false end

    -- เช็คจาก QuestTracker หรือแถบแสดงสถานะเควสด้านซ้าย
    local questTracker = screenGui:FindFirstChild("QuestTracker") or screenGui:FindFirstChild("Quest")
    if questTracker then
        local container = questTracker:FindFirstChild("Container") or questTracker
        if container and container.Visible then
            return true
        end
    end

    return false
end

-- 4. ค้นหา Bandit (ค้นหาทั้งใน Enemies และ Workspace)
local function GetTargetBandit()
    -- ค้นหาใน Workspace.Enemies ก่อน
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace
    
    for _, mob in pairs(enemiesFolder:GetChildren()) do
        -- เช็คชื่อมอนสเตอร์ที่มีคำว่า Bandit (ไม่สนอักษรเล็ก-ใหญ่)
        if string.find(string.lower(mob.Name), "bandit") 
           and mob:FindFirstChild("Humanoid") 
           and mob.Humanoid.Health > 0 
           and mob:FindFirstChild("HumanoidRootPart") then
            return mob
        end
    end
    return nil
end

-- 5. ลูปหลัก Auto Farm
local function runFarmLogic()
    EnableNoclip()
    print("[AutoFarm] เริ่มระบบ Auto Farm...")

    farmThread = task.spawn(function()
        local lastQuestAttempt = 0

        while autoFarmActive do
            task.wait(0.05)

            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local currentLevel = GetCurrentLevel()

                if currentLevel >= 1 and currentLevel <= 100 then
                    -- รับเควสเฉพาะเมื่อไม่มีเควสจริงๆ และเว้นระยะ 5 วินาที
                    local hasQuest = HasActiveQuest()
                    
                    if not hasQuest and (tick() - lastQuestAttempt > 5) then
                        lastQuestAttempt = tick()
                        print("[AutoFarm] ไม่พบเควส -> กำลังยิงรับเควส Bandit...")
                        pcall(function()
                            QuestEvent:FireServer("Request", { Id = 1 })
                        end)
                    end

                    -- ค้นหา Bandit
                    local target = GetTargetBandit()

                    if target and target:FindFirstChild("HumanoidRootPart") and target.Humanoid.Health > 0 then
                        local targetHRP = target.HumanoidRootPart
                        -- พุ่งไปลอยเหนือหัวมอนสเตอร์ 4.5 หน่วย
                        local targetCFrame = targetHRP.CFrame * CFrame.new(0, 4.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

                        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, 0.4)

                        -- ยิง Remote ตี
                        pcall(function()
                            ActionRemote:FireServer("M1", "Combat")
                        end)
                    else
                        -- พิมพ์แจ้งเตือนถ้าไม่เจอมอนสเตอร์ในระยะ (เว้นระยะพิมพ์ไม่ให้รก Console)
                        if math.random(1, 40) == 1 then
                            print("[AutoFarm] กำลังรอมอนสเตอร์ Bandit เกิด...")
                        end
                    end
                end
            end
        end
    end)
end

-- 6. Toggle
Tab:Toggle({
    Title = "Auto Farm Bandit (Quest Fix)",
    Desc = "แก้ไขการรับเควสซ้ำ และวาร์ปตีมอนสเตอร์",
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
