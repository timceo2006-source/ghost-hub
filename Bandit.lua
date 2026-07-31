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
-- 1. ตั้งค่า Remote และ Services
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

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
local farmThread = nil
local noclipConnection = nil
local currentTween = nil

-- ==========================================
-- 2. ระบบ Noclip (กันติดสิ่งกีดขวางขณะ Tween)
-- ==========================================
local function EnableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if autoFarmActive and Player.Character then
            for _, part in pairs(Player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
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

-- ==========================================
-- 3. ฟังก์ชันดึงค่า UI & มอนสเตอร์
-- ==========================================

-- ดึง Level จาก HUD
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

-- เช็คเควสจาก Quest.Container
local function HasActiveQuest()
    local container = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("ScreenGui")
        and Player.PlayerGui.ScreenGui:FindFirstChild("Quest")
        and Player.PlayerGui.ScreenGui.Quest:FindFirstChild("Container")

    if container then
        for _, child in pairs(container:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
                if child.Visible then return true end
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
-- 4. ฟังก์ชันเคลื่อนที่ด้วย Tween
-- ==========================================
local function TweenTo(targetCFrame, speed)
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    
    -- คำนวณเวลาจากระยะทางและความเร็ว
    local tweenSpeed = speed or 100 
    local tweenInfo = TweenInfo.new(distance / tweenSpeed, Enum.EasingStyle.Linear)
    
    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()
    return currentTween
end

-- ==========================================
-- 5. ลูปหลัก Auto Farm
-- ==========================================
local function runFarmLogic()
    EnableNoclip()

    farmThread = task.spawn(function()
        while autoFarmActive do
            task.wait(0.1)
            
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local currentLevel = GetCurrentLevel()

                -- ตรวจสอบเงื่อนไขเลเวล 1 - 100
                if currentLevel >= 1 and currentLevel <= 100 then
                    
                    -- รับเควสอัตโนมัติหากยังไม่มีเควส
                    if not HasActiveQuest() then
                        pcall(function()
                            QuestEvent:FireServer("Request", { Id = 1 })
                        end)
                    end

                    -- ค้นหาเป้าหมาย
                    local target = GetTargetBandit()

                    if target and target:FindFirstChild("HumanoidRootPart") and target.Humanoid.Health > 0 then
                        local targetHRP = target.HumanoidRootPart
                        -- ตำแหน่งเป้าหมาย: ลอยเหนือหัวมอนสเตอร์ 5 หน่วย (หันหน้าลง)
                        local targetCFrame = targetHRP.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

                        local dist = (hrp.Position - targetCFrame.Position).Magnitude
                        
                        -- ถ้าระยะห่างเกิน 5 หน่วย ให้ใช้ Tween บินไปหา
                        if dist > 5 then
                            TweenTo(targetCFrame, 90) -- ปรับความเร็วได้ตรงนี้ (แนะนำ 80 - 120)
                            task.wait(0.1)
                        else
                            -- ถ้าอยู่ใกล้แล้ว ล็อกตำแหน่งไว้เหนือหัว
                            hrp.CFrame = targetCFrame
                        end

                        -- ส่งสัญญาณโจมตี
                        pcall(function()
                            ActionRemote:FireServer("M1", "Combat")
                        end)
                    else
                        -- ถ้านอกเขตหรือไม่มีมอนสเตอร์ ให้ยกเลิก Tween
                        if currentTween then currentTween:Cancel() end
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- 6. Toggle สำหรับ UI Library
-- ==========================================
Tab:Toggle({
    Title = "Auto Farm Bandit (Tween)",
    Desc = "ใช้ระบบ Tween เคลื่อนที่ไปตี Bandit",
    Value = false,
    Callback = function(state)
        autoFarmActive = state
        if state then
            runFarmLogic()
        else
            -- ปิดการทำงาน และคืนค่าตัวละคร
            if farmThread then task.cancel(farmThread) end
            if currentTween then currentTween:Cancel() end
            DisableNoclip()
        end
    end
})
