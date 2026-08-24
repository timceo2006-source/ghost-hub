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
            tabs.Enabled = false
        end
        GuiService.SelectedObject = nil
    end)
end

local function autoAcceptTradeLoop()
    pcall(function()
        local tabs = playerGui:FindFirstChild("Tabs")
        if tabs then
            local areYouSure = tabs:FindFirstChild("Are You Sure")
            if areYouSure and areYouSure.Enabled then
                local confirmButton = areYouSure.Menu.Frame.Buttons.Yes
                if confirmButton and confirmButton.Parent then
                    while areYouSure.Parent and areYouSure.Enabled do
                        pcall(function()
                            if confirmButton and confirmButton.Parent then
                                GuiService.SelectedObject = confirmButton
                                
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                task.wait(0.02)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                
                                for _, conn in ipairs(getconnections(confirmButton.Activated)) do
                                    conn:Fire()
                                end
                                for _, conn in ipairs(getconnections(confirmButton.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end
                        end)
                        task.wait(0.08)
                    end

                    task.wait(0.1)
                    resetTradeUI()
                    task.wait(0.2)
                end
            end
        end
    end)
end

while true do
    autoAcceptTradeLoop()
    task.wait(0.05)
end
