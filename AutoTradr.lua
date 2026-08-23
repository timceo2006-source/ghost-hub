local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
    -- ดึงค่า Config จาก getgenv แบบปลอดภัย (ถ้าไม่มีให้ใช้ค่าเริ่มต้น)
    local config = getgenv().AcceptTradeConfig or {}
    local targetSender = config.TargetSender or "pondpbpa"
    local allowedItems = config.AllowedItems or {
        ["Rainbow Comet Gnome"] = true,
    }

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
        local isValidSender = (targetSender == "" or string.find(targetText, targetSender))
        
        local isValidItem = true
        if allowedItems and next(allowedItems) ~= nil then
            isValidItem = false
            for itemName, _ in pairs(allowedItems) do
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
