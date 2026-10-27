--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V15 - Colisión Sólida)
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
    FlySpeed = 200,           -- Velocidad de vuelo
    AttackDistance = 20,      -- 🔥 Distancia a la que choca con la hitbox (17.5 es el radio de la caja)
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

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then 
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
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
        
        local targetPos = targetHrp.Position
        local distance = (targetPos - myRoot.Position).Magnitude
        
        if distance > Config.AttackDistance then
            -- 🔥 VOLAR HACIA EL ENEMIGO (Hasta chocar con la caja)
            local direction = (targetPos - myRoot.Position).Unit
            myRoot.CFrame = CFrame.lookAt(myRoot.Position + (direction * Config.FlySpeed * dt), targetPos)
            myRoot.AssemblyLinearVelocity = Vector3.zero
        else
            -- 🔥 CHOCANDO CON LA HITBOX: Mantenemos la posición y atacamos
            -- Empujamos un poquito hacia adentro para mantener la presión sobre la caja roja
            local direction = (targetPos - myRoot.Position).Unit
            myRoot.AssemblyLinearVelocity = direction * 10 
            
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
    env.BF_WAVEFARM_CONFIG = nil
    env.__BF_WAVEFARM_CLEANUP = nil
end
