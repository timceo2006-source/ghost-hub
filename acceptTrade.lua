local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function autoAcceptTradeLoop()
    pcall(function()
        local tabs = playerGui:FindFirstChild("Tabs")
        if tabs then
            local areYouSure = tabs:FindFirstChild("Are You Sure")
            if areYouSure and areYouSure.Enabled then
                local confirmButton = areYouSure.Menu.Frame.Buttons.Yes
                if confirmButton and confirmButton.Visible then
                    -- จำลองการคลิกตำแหน่งปุ่มผ่านเมธอดภายในของเกมโดยตรง
                    if firesignal then
                        firesignal(confirmButton.MouseButton1Click)
                        firesignal(confirmButton.Activated)
                    elseif fireclickdetector then
                        -- กรณีสำรอง
                    end
                    
                    -- อีกวิธี: ใช้การจำลองกดเมาส์ลงบนปุ่มโดยตรงแบบแม่นยำ
                    local vim = game:GetService("VirtualInputManager")
                    local absPos = confirmButton.AbsolutePosition
                    local absSize = confirmButton.AbsoluteSize
                    local clickX = absPos.X + (absSize.X / 2)
                    local clickY = absPos.Y + (absSize.Y / 2)
                    
                    vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                    task.wait(0.05)
                    vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
                    
                    task.wait(0.5)
                end
            end
        end
    end)
end

while true do
    autoAcceptTradeLoop()
    task.wait(0.1)
end
