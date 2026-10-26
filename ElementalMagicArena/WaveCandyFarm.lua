--// Froggy Hub - ElementalMagicArena/WaveCandyFarm.lua (V7 - Atacar NPCs, Ignorar Players)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_WAVEFARM_CLEANUP then pcall(env.__BF_WAVEFARM_CLEANUP) end

local Config = {
    Enabled = false,
    CandyRadius = 2000,     -- Rango largo para el mapa de Halloween
    NoEnemyTimeout = 3,
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

-- 🔥 FIX: Ataca a todo lo que tenga Humanoid, excepto a los jugadores reales
local function getClosestNPC()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 2000 
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            -- Si tiene Humanidad, está vivo, y NO es un jugador
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
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("candy") or name:find("caramel") or name:find("dulce") or name:find("treat") or name:find("sweet") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - myRoot.Position).Magnitude <= Config.CandyRadius then
                    table.insert(candies, part)
                end
            end
        end
    end
    return candies
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if root then root.Anchored = false end
        return 
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    local now = tick()
    local targetHrp = getClosestNPC()

    if targetHrp then
        state = "KILLING"
        lastEnemyTime = now
        
        myHum.PlatformStand = true
        
        -- Instakill: Nos lanzamos al centro del enemigo
        local offsetCFrame = targetHrp.CFrame * CFrame.new(0, 1, 0)
        myRoot.CFrame = offsetCFrame
        myRoot.AssemblyLinearVelocity = Vector3.zero
        
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        
    else
        if state == "KILLING" and (now - lastEnemyTime) < Config.NoEnemyTimeout then
            return 
        end
        
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
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum then hum.PlatformStand = false end
    if root then root.Anchored = false end
    env.BF_WAVEFARM_CONFIG = nil
    env.__BF_WAVEFARM_CLEANUP = nil
end
