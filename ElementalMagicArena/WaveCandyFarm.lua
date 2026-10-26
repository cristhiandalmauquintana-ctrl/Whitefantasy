--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V2 - Táctico y Anti-Muerte)
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
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") or name:find("espada") then
                pcall(function() char.Humanoid:EquipTool(tool) end)
                break
            end
        end
    end
end

-- 🔍 BUSCAR SOLO NPCs (Ignorar Jugadores)
local function getClosestNPC()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300 
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            -- Si tiene humanidad, está vivo y NO es un jugador
            if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
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
    
    -- Buscamos solo NPCs (enemigos de las oleadas)
    local targetHrp = getClosestNPC()

    if targetHrp then
        state = "KILLING"
        lastEnemyTime = now
        
        myHum.PlatformStand = true
        
        -- 🔥 SOLUCIÓN AL DAÑO Y POSICIÓN:
        -- En lugar de ir al centro, usamos el CFrame del enemigo para posicionarnos
        -- 3 studs a la derecha y 1 stud arriba.
        local offsetCFrame = targetHrp.CFrame * CFrame.new(3, 1, 0)
        myRoot.CFrame = offsetCFrame
        myRoot.AssemblyLinearVelocity = Vector3.zero
        
        -- Atacar (M1)
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        
    else
        if state == "KILLING" and (now - lastEnemyTime) < Config.NoEnemyTimeout then
            return -- Esperando a que termine la oleada o spawneen más
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

-- 🔄 AUTO-RESPAWN: Si mueres, el script se reinicia automáticamente
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1) -- Esperar a que cargue el personaje
    if Config.Enabled then
        state = "WAITING"
        lastEnemyTime = 0
        -- El Heartbeat lo detectará automáticamente y empezará a atacar/recoger
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

print("[WaveCandyFarm] V2 Táctica cargada. Solo ataca NPCs y usa offset seguro.")
