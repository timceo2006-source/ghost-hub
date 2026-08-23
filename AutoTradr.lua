local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ดึงค่าจาก getgenv() ที่ผู้ใช้ตั้งค่าไว้ก่อนรัน ถ้าไม่ได้ตั้งให้ใช้ค่าเริ่มต้นแทน
local Config = getgenv().AcceptTradeConfig or {}
local TARGET_SENDER = Config.TargetSender or "BrookSP001"
local ALLOWED_ITEMS = Config.AllowedItems or {
    ["Rainbow Comet Gnome"] = true,
}

local function resetTradeUI()
    pcall(function()
        local tabs = playerGui:FindFirstChild("Tabs")
        if tabs then
            local areYouSure = tabs:FindFirstChild("Are You Sure")
            if areYouSure then
                areYouSure.Enabled = false
            end
        end
        GuiService.SelectedObject = nil
    end)
end

local function autoAcceptTradeLoop()
    local areYouSureGui = nil
    local confirmButton = nil
    local targetText = ""

    pcall(function()
        areYouSureGui = playerGui:FindFirstChild("Tabs") and playerGui.Tabs:FindFirstChild("Are You Sure")
        if areYouSureGui and areYouSureGui.Enabled then
            confirmButton = areYouSureGui.Menu.Frame.Buttons.Yes
            targetText = areYouSureGui.Menu.Frame.TextLabel.Text
        end
    end)

    if areYouSureGui and areYouSureGui.Enabled and confirmButton and confirmButton.Parent then
        -- เช็คชื่อผู้ส่ง
        local isValidSender = (TARGET_SENDER == "" or string.find(targetText, TARGET_SENDER))
        
        -- เช็คชื่อไอเทม
        local isValidItem = true
        if ALLOWED_ITEMS and next(ALLOWED_ITEMS) ~= nil then
            isValidItem = false
            for itemName, _ in pairs(ALLOWED_ITEMS) do
                if string.find(targetText, itemName) then
                    isValidItem = true
                    break
                end
            end
        end

        if isValidSender and isValidItem then
            while areYouSureGui.Parent and areYouSureGui.Enabled do
                pcall(function()
                    if confirmButton and confirmButton.Parent then
                        GuiService.SelectedObject = confirmButton
                        
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.02)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        
                        if getconnections then
                            for _, conn in ipairs(getconnections(confirmButton.Activated)) do
                                conn:Fire()
                            end
                        end
                    end
                end)
                task.wait(0.08)
            end

            task.wait(0.1)
            resetTradeUI()
            task.wait(0.2)
        else
            -- ถ้าไม่ใช่คนส่งหรือไอเทมที่กำหนด ให้กดปฏิเสธ (ปุ่ม No)
            pcall(function()
                local denyButton = areYouSureGui.Menu.Frame.Buttons.No
                if denyButton then
                    GuiService.SelectedObject = denyButton
                    if getconnections then
                        for _, conn in ipairs(getconnections(denyButton.Activated)) do
                            conn:Fire()
                        end
                    end
                end
            end)
            task.wait(0.5)
            resetTradeUI()
        end
    end
end

while true do
    autoAcceptTradeLoop()
    task.wait(0.05)
end
    end
end

while true do
    autoAcceptTradeLoop()
    task.wait(0.05)
end
while true do
    autoAcceptTradeLoop()
    task.wait(0.05)
end
            task.wait(0.5)
            resetTradeUI()
        end
        
        task.wait(0.2)
    end
end

while true do
    autoAcceptTradeLoop()
    task.wait(0.1)
end
            task.wait(0.5)
            resetTradeUI()
        end
        
        task.wait(0.2)
    end
end

while true do
    autoAcceptTradeLoop()
    task.wait(0.05)
end
end
