local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Plost = workspace.Plots

local waveText = PlayerGui.MainUI.UITop.Top.Main.Wave.Frame.TextLabel
local startButtonText = PlayerGui.MainUI.UITop.Top.Main.Start.Frame.TextLabel
local RemoteEvent = game:GetService("ReplicatedStorage").Remotes.Fight.Start
local stopWave = 70

local Window = WindUI:CreateWindow({
    Title = "Ghost Hub",
    Icon = "ghost",
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
        end,
    },
})

local Tab = Window:Tab({
    Title = "Main",
    Locked = false,
})

local Slider = Tab:Slider({
    Title = "Stop wave",
    Desc = "Slider Description",
    Step = 1,
    Value = {
        Min = 1,
        Max = 500,
        Default = 70,
    },
    Callback = function(value)
        stopWave = value
    end
})

local Toggle = Tab:Toggle({
    Title = "Auto Play",
    Desc = "Toggle Description",
    Icon = "bird",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoPlay = state
        if not state then
            RemoteEvent:FireServer("Stop")
        end
    end
})

task.spawn(function()
    while true do
        if _G.AutoPlay then
            local currentWaveNum = tonumber(waveText.Text:match("%d+")) or tonumber(waveText.Text) or 0
            
            if currentWaveNum >= stopWave then
                RemoteEvent:FireServer("Stop")
                task.wait(3)
                RemoteEvent:FireServer("Start")
                task.wait(2)
            else
                if startButtonText.Text == "START" then
                    RemoteEvent:FireServer("Start")
                    task.wait(2)
                elseif startButtonText.Text == "STOP" then
                end
            end
        end
        task.wait(1)
    end
end)

local TabRoll = Window:Tab({
    Title = "Roll & Buy",
    Locked = false,
})

local ToggleRoll = TabRoll:Toggle({
    Title = "Auto Roll",
    Desc = "Toggle Description",
    Icon = "dice-5",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        _G.AutoRoll = state
    end,
})

task.spawn(function()
    while true do
        if _G.AutoRoll then
            local myPlot
            for _, plot in ipairs(Plost:GetChildren()) do
                local owner = plot:FindFirstChild("Owner")
                if owner and owner.Value == LocalPlayer then
                    myPlot = plot
                    break
                end
            end
            
            if myPlot and myPlot:FindFirstChild("Roll") then
                local rollModel = myPlot.Roll
                local rollButtonPart = rollModel:FindFirstChild("RollButton") and rollModel.RollButton:FindFirstChild("Button")
                local prompt = rollModel:FindFirstChild("RollPrompt", true)
                
                if rollButtonPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = rollButtonPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.5)
                    
                    if prompt then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
        task.wait(1)
    end
end)
