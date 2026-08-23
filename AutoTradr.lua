local Config = getgenv().AcceptTradeConfig or {
    TargetSender = "BrookSP001", -- ค่าเริ่มต้นถ้าไม่ได้ตั้งค่า
    AllowedItems = {
        ["Rainbow Comet Gnome"] = true,
    }
}

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
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
    local areYouSureGui = nil
    local confirmButton = nil
    local targetText = nil

    pcall(function()
        areYouSureGui = playerGui:FindFirstChild("Tabs") and playerGui.Tabs:FindFirstChild("Are You Sure")
        if areYouSureGui and areYouSureGui.Enabled then
            confirmButton = areYouSureGui.Menu.Frame.Buttons.Yes
            targetText = areYouSureGui.Menu.Frame.TextLabel.Text
        end
    end)

    if areYouSureGui and areYouSureGui.Enabled and confirmButton and confirmButton.Parent then
        local isValidSender = (Config.TargetSender == "" or string.find(targetText, Config.TargetSender))
        
        local isValidItem = true
        if Config.AllowedItems and next(Config.AllowedItems) ~= nil then
            isValidItem = false
            for itemName, _ in pairs(Config.AllowedItems) do
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
                        for _, conn in ipairs(getconnections(confirmButton.Activated)) do
                            conn:Fire()
                        end
                        for _, conn in ipairs(getconnections(confirmButton.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end
                end)
                task.wait(0.05)
            end

            task.wait(0.1)
            resetTradeUI()
        else
            pcall(function()
                local denyButton = areYouSureGui.Menu.Frame.Buttons.No
                if denyButton then
                    GuiService.SelectedObject = denyButton
                    for _, conn in ipairs(getconnections(denyButton.Activated)) do
                        conn:Fire()
                    end
                end
            end)
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
