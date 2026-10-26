--// Froggy Hub - ElementalMagicArena/AutoFarm.lua (V11 - Kamikaze Full Fixes)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local env = (getgenv and getgenv()) or _G

getgenv().BF_AUTOFARM_CONFIG = { Enabled = false, AutoEquip = true }
local Config = getgenv().BF_AUTOFARM_CONFIG

-- Coordenadas de la placa (Ajusta la Y o X si es necesario)
local PlatePos = Vector3.new(817.7621459960938, 1.33, 21.276567459106445)

local state = "FARMING" 
local waitTimer = 0
local currentTarget = nil

-- Limpieza de física para no quedarse flotando al apagar el script
local function resetPhysics()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum then hum.PlatformStand = false end
    if root then root.Anchored = false end
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- Equipar arma automáticamente (Solo si no tiene nada)
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

-- Al morir/respawnear, volvemos a equipar y reiniciar estado
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    autoEquipWeapon()
    state = "GOING_TO_PLATE"
end)

-- Buscar almas (objetos)
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

-- Buscar jugadores (CON FILTRO ANTI-LOBBY POR SUELO)
local function getClosestPlayer()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300 
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and hrp then
                local isInLobby = false
                
                -- 🔍 Raycast hacia abajo para ver qué piso está pisando el enemigo
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {p.Character}
                local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -15, 0), rayParams)
                
                if ray and ray.Instance then
                    local floorName = ray.Instance.Name:lower()
                    
                    -- 🛑 Ignorar si está en SpawnLocation, Part o Baseplate
                    if floorName:find("spawnlocation") or floorName == "part" or floorName:find("baseplate") then
                        isInLobby = true
                    end
                end
                
                -- Si no está en el lobby, es un objetivo válido
                if not isInLobby then
                    local d = (hrp.Position - myRoot.Position).Magnitude
                    if d < dist then dist = d; closest = hrp end
                end
            end
        end
    end
    return closest
end

-- Bucle Principal
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        resetPhysics()
        currentTarget = nil
        return 
    end
    
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not myRoot or not hum then return end
    
    -- Si caes al vacío, volvemos a la placa
    if myRoot.Position.Y < -50 then
        resetPhysics()
        myRoot.CFrame = CFrame.new(PlatePos)
        state = "WAITING_PLATE"
        waitTimer = os.clock()
        return
    end
    
    if state == "GOING_TO_PLATE" then
        resetPhysics() 
        myRoot.CFrame = CFrame.new(PlatePos)
        state = "WAITING_PLATE"
        waitTimer = os.clock()
        
    elseif state == "WAITING_PLATE" then
        resetPhysics()
        -- Esperamos 1.5 segundos en la placa
        if os.clock() - waitTimer > 1.5 then 
            autoEquipWeapon() -- 🔥 Volvemos a equipar el elemento después de tocar la placa
            state = "FARMING" 
        end
        
    elseif state == "FARMING" then
        hum.PlatformStand = true 
        
        -- Auto-equipar por si el juego nos lo quitó en el aire
        autoEquipWeapon()

        -- 1. Prioridad: Almas
        local soul = getClosestSoul()
        if soul then
            myRoot.CFrame = CFrame.new(soul.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            local prompt = soul:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            return 
        end
        
        -- 2. Prioridad: Enemigos reales (Fuera del lobby)
        local target = getClosestPlayer()
        if target then
            currentTarget = target
            
            -- 🔥 Seguimiento fluido (Stick) sin anclarse
            myRoot.CFrame = CFrame.new(target.Position + Vector3.new(2, 2, 0), target.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero 
            
            local humTarget = target.Parent and target.Parent:FindFirstChild("Humanoid")
            if humTarget and humTarget.Health <= 0 then 
                state = "GOING_TO_PLATE" 
            end
        else
            -- Si no hay nadie, volvemos a la placa
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
