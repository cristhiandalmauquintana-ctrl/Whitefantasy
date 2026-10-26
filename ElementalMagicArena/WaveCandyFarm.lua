--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V1 - Halloween Event)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_WAVEFARM_CLEANUP then pcall(env.__BF_WAVEFARM_CLEANUP) end

local Config = {
    Enabled = false,
    CandyRadius = 500,      -- Radio para buscar caramelos
    NoEnemyTimeout = 3,     -- Segundos sin enemigos para pasar a recoger caramelos
}
env.BF_WAVEFARM_CONFIG = Config

local state = "WAITING" -- "WAITING", "KILLING", "COLLECTING"
local lastEnemyTime = 0
local connections = {}

-- Equipar espada automáticamente
local function equipWeapon()
    local char = LocalPlayer.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") or name:find("espada") then
                pcall(function() char.Humanoid:EquipTool(tool) end)
                break
            end
        end
    end
end

-- Buscar enemigo más cercano (Jugadores y NPCs)
local function getClosestEnemy()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300 -- Rango de búsqueda de enemigos
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = p end
            end
        end
    end
    
    -- Buscar NPCs de oleadas
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if hrp then
                    local d = (hrp.Position - myRoot.Position).Magnitude
                    if d < dist then dist = d; closest = obj end
                end
            end
        end
    end
    return closest
end

-- Buscar caramelos en el mapa
local function getCandies()
    local candies = {}
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return candies end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("candy") or name:find("caramel") or name:find("dulce") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - myRoot.Position).Magnitude <= Config.CandyRadius then
                    table.insert(candies, part)
                end
            end
        end
    end
    return candies
end

-- Bucle principal
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        -- Restaurar gravedad si se apaga
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
        return 
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    equipWeapon()
    local now = tick()
    local enemy = getClosestEnemy()

    if enemy then
        state = "KILLING"
        lastEnemyTime = now
        
        local targetHrp = enemy:IsA("Player") and enemy.Character:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
        if targetHrp then
            myHum.PlatformStand = true
            -- GLITCH: Pegarse al enemigo para que la Hitbox gigante lo toque
            myRoot.CFrame = CFrame.lookAt(targetHrp.Position - targetHrp.CFrame.LookVector * 2.5, targetHrp.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            
            -- Atacar (M1)
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end
    else
        if state == "KILLING" and (now - lastEnemyTime) < Config.NoEnemyTimeout then
            return -- Esperando a que termine la oleada
        end
        
        -- MODO RECOLECCIÓN
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
            
            myRoot.CFrame = CFrame.new(closestCandy.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            
            -- Intentar recoger con ProximityPrompt o por colisión (Touch)
            local prompt = closestCandy:FindFirstChildOfClass("ProximityPrompt") or (closestCandy.Parent and closestCandy.Parent:FindFirstChildOfClass("ProximityPrompt"))
            if prompt then
                pcall(function() fireproximityprompt(prompt) end)
            else
                pcall(function()
                    firetouchinterest(myRoot, closestCandy, 0)
                    task.wait(0.05)
                    firetouchinterest(myRoot, closestCandy, 1)
                end)
            end
        else
            state = "WAITING"
            myHum.PlatformStand = false
        end
    end
end))

env.__BF_WAVEFARM_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
    env.BF_WAVEFARM_CONFIG = nil
    env.__BF_WAVEFARM_CLEANUP = nil
end

print("[WaveCandyFarm] Módulo de Halloween cargado.")
