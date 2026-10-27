--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V16 - Noclip Local + Offset)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_WAVEFARM_CLEANUP then pcall(env.__BF_WAVEFARM_CLEANUP) end

local Config = {
    Enabled = false,
    CandyRadius = 2000,
    MaxAttackDistance = 2000, 
    FlySpeed = 200,           
    AttackDistance = 4,       -- Distancia para atacar (una vez llegamos al offset)
}
env.BF_WAVEFARM_CONFIG = Config

local state = "WAITING" 
local lastEnemyTime = 0
local connections = {}

local function equipWeapon()
    local char = LocalPlayer.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") then
                pcall(function() char.Humanoid:EquipTool(tool) end)
                break
            end
        end
    end
end

local function getClosestNPC()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, Config.MaxAttackDistance
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if hrp then
                    local d = (hrp.Position - myRoot.Position).Magnitude
                    if d < dist then dist = d; closest = hrp end
                end
            end
        end
    end
    return closest
end

local function getCandies()
    local candies = {}
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return candies end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("MeshPart") and obj.Name == "Candy" then
            local d = (obj.Position - myRoot.Position).Magnitude
            if d <= Config.CandyRadius then
                table.insert(candies, obj)
            end
        end
    end
    return candies
end

-- 🔥 NOCLIP LOCAL: Desactiva la colisión solo para tu personaje
local function setNoclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then 
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        setNoclip(false) -- Al apagar, restauramos la colisión
        return 
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    equipWeapon()
    local now = tick()
    local targetHrp = getClosestNPC()

    if targetHrp then
        state = "KILLING"
        lastEnemyTime = now
        
        myHum.PlatformStand = true
        setNoclip(true) -- 🔥 Activamos el noclip mientras vuela y ataca
        
        -- 🎯 CALCULAMOS EL OFFSET: 3 studs derecha, 1 arriba
        local offsetCFrame = targetHrp.CFrame * CFrame.new(3, 1, 0)
        local targetPos = offsetCFrame.Position
        
        local distance = (targetPos - myRoot.Position).Magnitude
        
        if distance > Config.AttackDistance then
            -- VOLAR HACIA EL OFFSET
            local direction = (targetPos - myRoot.Position).Unit
            myRoot.CFrame = CFrame.lookAt(myRoot.Position + (direction * Config.FlySpeed * dt), targetHrp.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
        else
            -- ATACAR EN EL OFFSET
            myRoot.CFrame = offsetCFrame
            myRoot.AssemblyLinearVelocity = Vector3.zero
            
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end
        
    else
        state = "COLLECTING"
        local candies = getCandies()
        if #candies > 0 then
            myHum.PlatformStand = true
            setNoclip(true) -- Noclip también para recoger caramelos
            
            local closestCandy = candies[1]
            for _, c in ipairs(candies) do
                if (c.Position - myRoot.Position).Magnitude < (closestCandy.Position - myRoot.Position).Magnitude then
                    closestCandy = c
                end
            end
            
            local candyPos = closestCandy.Position
            local distToCandy = (candyPos - myRoot.Position).Magnitude
            
            if distToCandy > 3 then
                local direction = (candyPos - myRoot.Position).Unit
                myRoot.CFrame = CFrame.lookAt(myRoot.Position + (direction * (Config.FlySpeed * 1.5) * dt), candyPos)
                myRoot.AssemblyLinearVelocity = Vector3.zero
            else
                myRoot.CFrame = CFrame.new(candyPos)
                myRoot.AssemblyLinearVelocity = Vector3.zero
                
                local prompt = closestCandy:FindFirstChildWhichIsA("ProximityPrompt", true) 
                if prompt then
                    pcall(function() fireproximityprompt(prompt) end)
                else
                    pcall(function()
                        firetouchinterest(myRoot, closestCandy, 0)
                        task.wait(0.1)
                        firetouchinterest(myRoot, closestCandy, 1)
                    end)
                end
                task.wait(0.1)
            end
        else
            state = "WAITING"
            myHum.PlatformStand = false
            setNoclip(false) -- Restauramos colisión si no hay nada
            myRoot.Anchored = false
        end
    end
end))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Config.Enabled then
        equipWeapon()
        state = "WAITING"
        lastEnemyTime = 0
    end
end))

env.__BF_WAVEFARM_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    setNoclip(false)
    env.BF_WAVEFARM_CONFIG = nil
    env.__BF_WAVEFARM_CLEANUP = nil
end
