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
-- 1. ตั้งค่า Remote และตัวแปรระบบ
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ดึง RemoteEvent ผ่าน Net Framework ตามรูปของคุณ
local sleitnickNet = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local ActionRemote = sleitnickNet:WaitForChild("RE/ActionRemote")
local QuestEvent = sleitnickNet:WaitForChild("RE/QuestEvent")

-- ตัวแปรควบคุมการทำงาน
local autoFarmActive = false
local loopTask = nil
local heartbeatConnection = nil

-- ==========================================
-- 2. ฟังก์ชันช่วยเหลือ (อ่านค่า UI & ค้นหา มอนสเตอร์)
-- ==========================================

-- ดึง Level จาก UI ตามพาธ: ScreenGui.HUD.Level
local function GetCurrentLevel()
    local levelUI = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("ScreenGui")
        and Player.PlayerGui.ScreenGui:FindFirstChild("HUD")
        and Player.PlayerGui.ScreenGui.HUD:FindFirstChild("Level")
    
    if levelUI then
        local text = levelUI.Text ~= "" and levelUI.Text or levelUI.ContentText
        local levelNum = string.match(text, "%d+")
        return tonumber(levelNum) or 0
    end
    return 0
end

-- ค้นหา Bandit ใน Workspace.Enemies
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

-- ==========================================
-- 3. ฟังก์ชันหลัก Auto Farm
-- ==========================================
local function runFarmLogic()
    local lockedTarget = nil

    -- [ลูปสมอง] เลือกเป้าหมาย และ รับเควส
    loopTask = task.spawn(function()
        while autoFarmActive do
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local currentLevel = GetCurrentLevel()

                -- ทำงานเฉพาะช่วง Level 1 ถึง 100
                if currentLevel >= 1 and currentLevel <= 100 then
                    -- รับเควส Bandit (ID = 1)
                    pcall(function()
                        QuestEvent:FireServer("Request", { Id = 1 })
                    end)

                    -- ค้นหาตัวเป้าหมายใหม่หากตัวเดิมตายหรือไม่มี
                    if not (lockedTarget and lockedTarget:FindFirstChild("Humanoid") and lockedTarget.Humanoid.Health > 0) then
                        lockedTarget = GetTargetBandit()
                    end
                end
            end
            task.wait(0.3)
        end
    end)

    -- [ลูปเคลื่อนที่ & โจมตี] ทำงานทุกเฟรมเรต
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not autoFarmActive then return end
        local Character = Player.Character
        local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChild("Humanoid")

        if HRP and Humanoid and Humanoid.Health > 0 then
            if lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") and lockedTarget.Humanoid.Health > 0 then
                -- บังคับลอยตัวเพื่อไม่ให้ร่วง
                Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                
                -- วาปไปลอยอยู่เหนือหัว Bandit 4.5 หน่วย (ปรับหันหน้าลงมาตี)
                local targetHRP = lockedTarget.HumanoidRootPart
                HRP.CFrame = targetHRP.CFrame * CFrame.new(0, 4.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

                -- ยิง Remote โจมตี "M1", "Combat"
                pcall(function()
                    ActionRemote:FireServer("M1", "Combat")
                end)
            end
        end
    end)
end

-- ==========================================
-- 4. ปุ่ม Toggle สำหรับใส่ใน UI Library
-- ==========================================
Tab:Toggle({
    Title = "Auto Farm Bandit (Lv. 1 - 100)",
    Desc = "รับเควส วาปไปตี Bandit อัตโนมัติ",
    Value = false,
    Callback = function(state)
        autoFarmActive = state
        if state then
            runFarmLogic()
        else
            -- ยกเลิก Task ทั้งหมดเมื่อปิด Toggle
            if loopTask then task.cancel(loopTask) end
            if heartbeatConnection then heartbeatConnection:Disconnect() end
            
            -- คืนค่าการเคลื่อนที่ปกติให้ตัวละคร
            local char = Player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
})
