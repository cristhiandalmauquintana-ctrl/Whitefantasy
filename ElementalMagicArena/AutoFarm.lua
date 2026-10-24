--// Froggy Hub - ElementalMagicArena/AutoFarm.lua (V3 - Anti-Caídas)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local env = (getgenv and getgenv()) or _G

getgenv().BF_AUTOFARM_CONFIG = { Enabled = false, AutoEquip = true }
local Config = getgenv().BF_AUTOFARM_CONFIG

local PlatePos = Vector3.new(817.7621459960938, -1.6697957515716553 + 3, 21.276567459106445)

-- Variables de Estado
local state = "FARMING" -- "FARMING", "GOING_TO_PLATE", "WAITING_PLATE"
local waitTimer = 0
local currentTarget = nil

-- 1. AUTO-EQUIP A PRUEBA DE MUERTE
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

-- Se ejecuta CADA VEZ que respawneas
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1) -- Esperar a que el personaje cargue
    autoEquipWeapon()
    state = "GOING_TO_PLATE" -- Al nacer, vamos a la placa
end)

-- 2. BÚSQUEDA SEGURA
local function getClosestSoul()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 2000 
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("soul") then
            local isChar = false
            local parent = obj.Parent
            while parent and parent ~= Workspace do
                if parent:FindFirstChildOfClass("Humanoid") then isChar = true break end
                parent = parent.Parent
            end
            if not isChar then
                local d = (obj.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = obj end
            end
        end
    end
    return closest
end

local function getClosestEnemy()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChild("Humanoid")
            -- 🔥 VERIFICACIÓN ESTRICTA: El enemigo debe estar vivo y existir
            if head and head.Parent and hum and hum.Health > 0 then
                local d = (head.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = head end
            end
        end
    end
    return closest
end

-- 3. LOOP PRINCIPAL BLINDADO
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    -- 🛑 ANTI-CAÍDAS: Si por alguna razón cae al vacío, lo devolvemos
    if myRoot and myRoot.Position.Y < -50 then
        myRoot.CFrame = CFrame.new(PlatePos)
        state = "WAITING_PLATE"
        waitTimer = os.clock()
        return
    end
    
    if not myRoot or not hum then return end
    
    -- Equipar arma constantemente por si acaso
    if tick() % 2 < 0.1 then autoEquipWeapon() end
    
    -- ==========================================
    -- LÓGICA DE ESTADOS
    -- ==========================================
    
    if state == "GOING_TO_PLATE" then
        hum.PlatformStand = false -- Dejar que la gravedad actúe para pisar la placa
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
        myRoot.CFrame = CFrame.new(PlatePos)
        state = "WAITING_PLATE"
        waitTimer = os.clock()
        
    elseif state == "WAITING_PLATE" then
        hum.PlatformStand = false
        -- Esperar 1.5 segundos en la placa
        if os.clock() - waitTimer > 1.5 then
            state = "FARMING"
        end
        
    elseif state == "FARMING" then
        -- Activar vuelo fantasma
        hum.PlatformStand = true 
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        
        -- 1. Recoger Almas
        local soul = getClosestSoul()
        if soul then
            myRoot.CFrame = CFrame.new(soul.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            local prompt = soul:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) else
                for _, child in ipairs(soul:GetChildren()) do
                    if child:IsA("ProximityPrompt") then fireproximityprompt(child) end
                end
            end
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0,0))
            return 
        end
        
        -- 2. Volar y matar
        local target = getClosestEnemy()
        if target then
            currentTarget = target
            -- Volar 3 studs arriba del enemigo
            myRoot.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0), target.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            
            -- Verificar si el enemigo murió mientras estábamos cerca
            local humTarget = target.Parent and target.Parent:FindFirstChild("Humanoid")
            if humTarget and humTarget.Health <= 0 then
                state = "GOING_TO_PLATE" -- Enemigo muerto, a recargar elemento
            end
        else
            -- Si no hay enemigos, buscar si el último enemigo murió
            if currentTarget then
                local humTarget = currentTarget.Parent and currentTarget.Parent:FindFirstChild("Humanoid")
                if not humTarget or humTarget.Health <= 0 then
                    state = "GOING_TO_PLATE"
                    currentTarget = nil
                end
            end
        end
    end
end)

print("[AutoFarm] Sistema V3 blindado cargado.")
