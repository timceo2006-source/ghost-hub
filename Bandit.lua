local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local vim = game:GetService("VirtualInputManager")

local currentTarget = nil
local lastSkillTime = 0

-- สั่งกดปุ่มแบบไม่ให้ลูปหยุดชะงัก (เพิ่มความไวขั้นสุด)
local function pressKey(key)
    task.spawn(function()
        vim:SendKeyEvent(true, key, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, key, false, game)
    end)
end

-- เช็คคูลดาวน์จากทั้งในกระเป๋า (Backpack) และที่กำลังถืออยู่ (Character)
local function getCooldown(slotName)
    local items = {}
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do table.insert(items, item) end
    end
    
    local char = player.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do table.insert(items, item) end
    end
    
    for _, item in ipairs(items) do
        if item:IsA("Tool") then
            local slot = item:FindFirstChild("abilitySlot")
            if slot and slot:IsA("ValueBase") and tostring(slot.Value):lower() == slotName:lower() then
                local cd = item:FindFirstChild("cooldown")
                if cd and cd:IsA("ValueBase") then 
                    return cd.Value 
                end
            end
        end
    end
    return 99 -- ป้องกัน Error ถ้าหาไม่เจอ
end

-- ฟังก์ชันหามอนสเตอร์และขยายฮิตบ็อกซ์
local function getTarget()
    if currentTarget and currentTarget.Parent and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
        local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
    end
    
    currentTarget = nil
    local dungeon = workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, room in ipairs(dungeon:GetChildren()) do
            local enemyFolder = room:FindFirstChild("enemyFolder")
            if enemyFolder then
                for _, monster in ipairs(enemyFolder:GetChildren()) do
                    local hum = monster:FindFirstChild("Humanoid")
                    local hrp = monster:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        currentTarget = monster
                        
                        -- ขยายฮิตบ็อกซ์มอนสเตอร์ให้ตีโดนจากบนฟ้า
                        hrp.Size = Vector3.new(25, 25, 25)
                        hrp.Transparency = 0.8 
                        hrp.CanCollide = false
                        
                        return hrp
                    end
                end
            end
        end
    end
    return nil
end

-- ลูปที่ 1: ล็อกตำแหน่งตัวละครให้อยู่บนฟ้า
runService.Heartbeat:Connect(function()
    pcall(function()
        local char = player.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
        
        local targetHrp = getTarget()
        if targetHrp then
            local safePos = targetHrp.Position + Vector3.new(0, 12, 0)
            hrp.CFrame = CFrame.lookAt(safePos, targetHrp.Position)
        end
    end)
end)

-- ลูปที่ 2: จัดการเรื่องการใช้สกิลและการตีปกติ (สแปมสกิลรัวๆ)
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            local char = player.Character
            -- เช็คว่าตัวละครมีชีวิตอยู่ไหม ป้องกันการรวนตอนตายเกิดใหม่
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
            
            local targetHrp = getTarget()
            if not targetHrp then return end
            
            -- บังคับถืออาวุธ
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                local tool = backpack:FindFirstChildOfClass("Tool")
                if tool then tool.Parent = char end
            end
            
            local qCd = getCooldown("q")
            local eCd = getCooldown("e")
            
            -- เช็คคูลดาวน์และสาดสกิลทันทีที่หลอดคูลดาวน์หมด
            if tick() - lastSkillTime > 0.1 then
                if qCd <= 0.1 then
                    pressKey(Enum.KeyCode.Q)
                    lastSkillTime = tick()
                    return
                elseif eCd <= 0.1 then
                    pressKey(Enum.KeyCode.E)
                    lastSkillTime = tick()
                    return
                end
            end
            
            -- สั่งตีปกติ
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end)
    end
end)
