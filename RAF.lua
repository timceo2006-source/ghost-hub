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
    Icon = "door-open",
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
