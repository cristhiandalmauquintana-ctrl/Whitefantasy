--// Froggy Hub - ElementalMagicArena/AutoFarm.lua (V9 - Filtro Anti-Lobby y Re-Equip)
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

local function autoEquipWeapon()
    if not Config.AutoEquip then return end
    local char = LocalPlayer.Character
    -- Si ya tiene un arma equipada, no hacemos nada
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            -- Buscamos espadas, elementos de luz, energía, etc.
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

local function getClosestPlayer()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300 
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                -- 🔥 FIX ANTI-LOBBY: Si el jugador está a menos de 100 studs de la placa, lo ignoramos (está en el lobby)
                local distanceToLobby = (hrp.Position - PlatePos).Magnitude
                if distanceToLobby > 100 then
                    local d = (hrp.Position - myRoot.Position).Magnitude
                    if d < dist then dist = d; closest = hrp end
                end
            end
        end
    end
    return closest
end

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
        -- Esperamos 1.5 segundos para que la placa haga su efecto (y nos quite el arma)
        if os.clock() - waitTimer > 1.5 then 
            -- 🔥 FIX RE-EQUIP: Justo después de la placa, nos volvemos a equipar el arma
            autoEquipWeapon() 
            state = "FARMING" 
        end
        
    elseif state == "FARMING" then
        hum.PlatformStand = true 
        
        -- Por si acaso perdemos el arma en el aire, intentamos equipar
        autoEquipWeapon()

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
            
            -- Seguimiento constante (Stick) al enemigo
            myRoot.CFrame = CFrame.new(target.Position + Vector3.new(2, 2, 0), target.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero 
            
            local humTarget = target.Parent and target.Parent:FindFirstChild("Humanoid")
            if humTarget and humTarget.Health <= 0 then 
                state = "GOING_TO_PLATE" 
            end
        else
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
