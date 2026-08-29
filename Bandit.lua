local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local vim = game:GetService("VirtualInputManager")

local currentTarget = nil
local lastSkillTime = 0

-- ฟังก์ชันกดปุ่ม
local function pressKey(key)
    vim:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    vim:SendKeyEvent(false, key, false, game)
end

-- ฟังก์ชันเช็คคูลดาวน์
local function getCooldown(slotName)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local slot = item:FindFirstChild("abilitySlot")
                if slot and slot:IsA("ValueBase") and tostring(slot.Value):lower() == slotName:lower() then
                    local cd = item:FindFirstChild("cooldown")
                    if cd and cd:IsA("ValueBase") then return cd.Value end
                end
            end
        end
    end
    return 99
end

-- ฟังก์ชันหามอนสเตอร์และขยายฮิตบ็อกซ์
local function getTarget()
    -- ถ้ามีเป้าหมายเดิมอยู่แล้ว และยังมีชีวิต
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
                        
                        -- [จุดสำคัญ] ขยายฮิตบ็อกซ์มอนสเตอร์ให้ใหญ่โตมโหฬาร (กว้าง 25, สูง 25)
                        -- ทำให้เราตีโดนแน่นอนแม้จะลอยอยู่สูงมาก
                        hrp.Size = Vector3.new(25, 25, 25)
                        hrp.Transparency = 0.8 -- ทำให้โปร่งใสจะได้ไม่เกะกะจอ
                        hrp.CanCollide = false
                        
                        return hrp
                    end
                end
            end
        end
    end
    return nil
end

-- ลูปที่ 1: ล็อกตำแหน่งตัวละครให้อยู่บนฟ้า (อัปเดตทุกเฟรมเรท ป้องกันการร่วง 100%)
runService.Heartbeat:Connect(function()
    pcall(function()
        local char = player.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- ปิดการชนของตัวเรา
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) -- ลบแรงโน้มถ่วง
        
        local targetHrp = getTarget()
        if targetHrp then
            -- ลอยสูง 12 หน่วยตลอดเวลา และหันหน้าก้มมองมอนสเตอร์
            local safePos = targetHrp.Position + Vector3.new(0, 12, 0)
            hrp.CFrame = CFrame.lookAt(safePos, targetHrp.Position)
        end
    end)
end)

-- ลูปที่ 2: จัดการเรื่องการใช้สกิลและการตีปกติ (M1) แบบเร่งความเร็ว (Spam Mode)
task.spawn(function()
    -- ลดเวลาจาก 0.2 เหลือ 0.05 วินาที ทำให้เช็คคูลดาวน์และลั่นสกิลไวขึ้น 4 เท่า!
    while task.wait(0.05) do 
        pcall(function()
            local char = player.Character
            if not char then return end
            
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
            
            -- ลดเวลาหน่วงระหว่างสกิลจาก 0.5 เหลือ 0.15 วินาที
            if tick() - lastSkillTime > 0.15 then
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
            
            -- สั่งตีปกติรัวๆ ระหว่างรอสกิล
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end)
    end
end)
