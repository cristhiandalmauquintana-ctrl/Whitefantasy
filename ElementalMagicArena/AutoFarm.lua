--// Froggy Hub - ElementalMagicArena/AutoFarm.lua (V6 - Kamikaze Players + Fix Placa)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local env = (getgenv and getgenv()) or _G

getgenv().BF_AUTOFARM_CONFIG = { Enabled = false, AutoEquip = true }
local Config = getgenv().BF_AUTOFARM_CONFIG

local PlatePos = Vector3.new(817.7621459960938, 1.33, 21.276567459106445)
local state = "FARMING" 
local waitTimer = 0
local currentTarget = nil

-- Limpieza de física (Para que no te quedes flotando)
local function resetPhysics()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

local function autoEquipWeapon()
    if not Config.AutoEquip then return end
    local char = LocalPlayer.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") then
                pcall(function() char.Humanoid:EquipTool(item) end)
                break
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    autoEquipWeapon()
    state = "GOING_TO_PLATE"
end)

-- Buscar almas (solo NPCs/Objetos)
local function getClosestSoul()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 2000 
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("soul") then
            local d = (obj.Position - myRoot.Position).Magnitude
            if d < dist then dist = d; closest = obj end
        end
    end
    return closest
end

-- 🔥 VOLVEMOS A BUSCAR JUGADORES
local function getClosestPlayer()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300 
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = hrp end
            end
        end
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        -- 🛑 FIX: Si lo apagas, te devuelve la gravedad al instante
        resetPhysics()
        currentTarget = nil
        return 
    end
    
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not myRoot or not hum then return end
    
    if myRoot.Position.Y < -50 then
        resetPhysics()
        myRoot.CFrame = CFrame.new(PlatePos)
        state = "WAITING_PLATE"
        waitTimer = os.clock()
        return
    end
    
    if tick() % 2 < 0.1 then autoEquipWeapon() end
    
    if state == "GOING_TO_PLATE" then
        -- 🛑 FIX PLACA: Nos aseguramos de tener gravedad para poder pisar la placa
        resetPhysics() 
        myRoot.CFrame = CFrame.new(PlatePos)
        state = "WAITING_PLATE"
        waitTimer = os.clock()
        
    elseif state == "WAITING_PLATE" then
        resetPhysics()
        if os.clock() - waitTimer > 1.5 then state = "FARMING" end
        
    elseif state == "FARMING" then
        -- Aquí sí flotamos para el Kamikaze
        hum.PlatformStand = true 
        for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        
        local soul = getClosestSoul()
        if soul then
            myRoot.CFrame = CFrame.new(soul.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            local prompt = soul:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            return 
        end
        
        local target = getClosestPlayer()
        if target then
            currentTarget = target
            -- Se pega al jugador (3 studs arriba)
            myRoot.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0), target.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            
            local humTarget = target.Parent and target.Parent:FindFirstChild("Humanoid")
            if humTarget and humTarget.Health <= 0 then 
                state = "GOING_TO_PLATE" 
            end
        else
            -- Si no hay jugadores cerca, esperamos un momento antes de ir a la placa
            if currentTarget then
                local humTarget = currentTarget.Parent and currentTarget.Parent:FindFirstChild("Humanoid")
                if not humTarget or humTarget.Health <= 0 then
                    state = "GOING_TO_PLATE"
                    currentTarget = nil
                end
            else
                state = "GOING_TO_PLATE"
            end
        end
    end
end)
