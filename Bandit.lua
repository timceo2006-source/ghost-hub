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

-- ดึง RemoteEvent ผ่าน Net Framework
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
-- 2. ฟังก์ชันตรวจสอบเควสและเลเวล
-- ==========================================

-- ดึง Level จาก UI
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

-- เช็คว่ามีเควสทำงานอยู่หรือไม่จาก Quest.Container ตามรูป
local function HasActiveQuest()
    local container = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("ScreenGui")
        and Player.PlayerGui.ScreenGui:FindFirstChild("Quest")
        and Player.PlayerGui.ScreenGui.Quest:FindFirstChild("Container")

    if container then
        -- หาก Container เปิดแสดงผลอยู่ หรือมีกี่องค์ประกอบด้านใน ถือว่ามีเควสอยู่แล้ว
        if container.Visible then
            for _, child in pairs(container:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and child.Visible then
                    return true
                end
            end
        end
    end
    return false
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

    -- [ลูปสมอง] รับเควสเมื่อไม่มีเควส + ล็อกเป้าหมาย
    loopTask = task.spawn(function()
        while autoFarmActive do
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local currentLevel = GetCurrentLevel()

                if currentLevel >= 1 and currentLevel <= 100 then
                    -- ถ้าระบบตรวจพบว่ายังไม่มีเควสใน Container ถึงจะส่งสัญญาณรับเควส
                    if not HasActiveQuest() then
                        pcall(function()
                            QuestEvent:FireServer("Request", { Id = 1 })
                        end)
                    end

                    -- ค้นหา Bandit
                    if not (lockedTarget and lockedTarget:FindFirstChild("Humanoid") and lockedTarget.Humanoid.Health > 0) then
                        lockedTarget = GetTargetBandit()
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    -- [ลูปเคลื่อนที่ & โจมตี]
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not autoFarmActive then return end
        local Character = Player.Character
        local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChild("Humanoid")

        if HRP and Humanoid and Humanoid.Health > 0 then
            if lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") and lockedTarget.Humanoid.Health > 0 then
                Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                
                -- วาปไปลอยอยู่เหนือหัว Bandit 4.5 หน่วย
                local targetHRP = lockedTarget.HumanoidRootPart
                HRP.CFrame = targetHRP.CFrame * CFrame.new(0, 4.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

                -- ตีมอนสเตอร์
                pcall(function()
                    ActionRemote:FireServer("M1", "Combat")
                end)
            end
        end
    end)
end

-- ==========================================
-- 4. Toggle
-- ==========================================
Tab:Toggle({
    Title = "Auto Farm Bandit (Lv. 1 - 100)",
    Desc = "ตรวจเควสอัตโนมัติ + วาปตี Bandit",
    Value = false,
    Callback = function(state)
        autoFarmActive = state
        if state then
            runFarmLogic()
        else
            if loopTask then task.cancel(loopTask) end
            if heartbeatConnection then heartbeatConnection:Disconnect() end
            
            local char = Player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
})
