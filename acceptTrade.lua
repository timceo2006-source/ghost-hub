if _G.AutoGiftRunning then return end
_G.AutoGiftRunning = true

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.spawn(function()
    while true do
        pcall(function()
            local tabs = playerGui:FindFirstChild("Tabs")
            if tabs then
                local areYouSure = tabs:FindFirstChild("Are You Sure")
                if areYouSure and areYouSure.Enabled then
                    local yesButton = areYouSure.Menu.Frame.Buttons.Yes
                    if yesButton and yesButton:IsA("GuiButton") and yesButton.Visible then
                        GuiService.SelectedObject = yesButton
                        task.wait(0.05)
                        
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.02)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        
                        local absPos = yesButton.AbsolutePosition
                        local absSize = yesButton.AbsoluteSize
                        local clickX = absPos.X + (absSize.X / 2)
                        local clickY = absPos.Y + (absSize.Y / 2)
                        
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                        task.wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
                        
                        task.wait(1)
                    end
                end
            end
        end)
        task.wait(0.2)
    end
end)
