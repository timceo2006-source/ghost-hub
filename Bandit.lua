local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local vim = game:GetService("VirtualInputManager")

local currentTarget = nil
local lastSkillTime = 0

-- ฟังก์ชันกดปุ่มอัตโนมัติจากการอ่าน abilitySlot (แปลงค่า Q, E เป็น Enum.KeyCode ให้เอง)
local function pressKey(keyStr)
    local success, keyCode = pcall(function() return Enum.KeyCode[keyStr:upper()] end)
    if success and keyCode then
        task.spawn(function()
            vim:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            vim:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

-- หามอนสเตอร์และขยายฮิตบ็อกซ์
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

-- ลูป 1: ลอยตัวนิ่งๆ บนฟ้า
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

-- ลูป 2: ระบบ Auto Skill แบบเช็คโครงสร้างอัตโนมัติ
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
            
            local targetHrp = getTarget()
            if not targetHrp then return end
            
            -- [จุดสำคัญ] ค้นหาสกิลทั้งหมดและเช็คคูลดาวน์เองแบบไดนามิก
            if tick() - lastSkillTime > 0.15 then
                local items = {}
                -- รวมไอเทมจากทั้งในกระเป๋าและที่ถืออยู่
                if player:FindFirstChild("Backpack") then
                    for _, v in ipairs(player.Backpack:GetChildren()) do table.insert(items, v) end
                end
                for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end
                
                for _, item in ipairs(items) do
                    if item:IsA("Tool") then
                        local slot = item:FindFirstChild("abilitySlot")
                        local cd = item:FindFirstChild("cooldown")
                        
                        -- เช็คว่ามีโฟลเดอร์โครงสร้างสกิลครบไหม
                        if slot and cd and slot:IsA("ValueBase") and cd:IsA("ValueBase") then
                            -- ถ้าคูลดาวน์เหลือน้อยกว่า 0.1 (รวม 0 และค่าติดลบทั้งหมด)
                            if cd.Value <= 0.1 then
                                pressKey(tostring(slot.Value)) -- สั่งกดปุ่มตามตัวอักษรใน abilitySlot
                                lastSkillTime = tick()
                                return -- ออกจากลูปเพื่อรอสาดสกิลถัดไปในรอบหน้า
                            end
                        end
                    end
                end
            end
            
            -- โจมตีปกติ (M1) เฉพาะอาวุธที่คุณกดถืออยู่เท่านั้น จะได้ไม่รบกวนระบบเกม
            local equippedTool = char:FindFirstChildOfClass("Tool")
            if equippedTool then
                equippedTool:Activate()
            end
        end)
    end
end)
