--// Froggy Hub - ElementalMagicArena/AutoFarm.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local env = (getgenv and getgenv()) or _G

-- 1. CONFIGURACIÓN
getgenv().BF_AUTOFARM_CONFIG = {
    Enabled = false,
    AutoEquip = true
}
local Config = getgenv().BF_AUTOFARM_CONFIG

-- 📍 COORDENADAS DE LA PLACA
local PlatePos = Vector3.new(817.7621459960938, -1.6697957515716553 + 3, 21.276567459106445)

-- Variables de control de estado
local needsElement = true 
local isWaitingOnPlate = false
local plateWaitTime = 0

-- 2. AUTO-EQUIPAR
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

task.spawn(function()
    while task.wait(1) do autoEquipWeapon() end
end)

-- 3. BÚSQUEDA
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
            if head and hum and hum.Health > 0 then
                local d = (head.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = head end
            end
        end
    end
    return closest
end

-- 4. LOOP PRINCIPAL (Suavizado con Heartbeat)
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then 
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        return 
    end
    
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum then return end
    
    -- 🔥 ANTI-TEMBLOR: PlataformStand desactiva la física mientras volamos
    hum.PlatformStand = true 
    
    -- SISTEMA DE ESTADO: Ir a la placa
    if needsElement then
        if not isWaitingOnPlate then
            -- Volamos a la placa y activamos colisiones
            myRoot.CFrame = CFrame.new(PlatePos)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
            isWaitingOnPlate = true
            plateWaitTime = os.clock() -- Guardamos el tiempo actual
        else
            -- Estamos esperando en la placa (1.5 segundos)
            if os.clock() - plateWaitTime > 1.5 then
                needsElement = false
                isWaitingOnPlate = false
            end
        end
        return -- No hacemos nada más mientras estamos en la placa
    end
    
    -- Modo fantasma
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    
    -- Recoger Almas
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
    
    -- Volar y matar (5 studs arriba para no marea la cámara)
    local target = getClosestEnemy()
    if target then
        myRoot.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0), target.Position)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end
end)

-- 5. DETECTOR DE MUERTE
local lastTargetHum = nil
task.spawn(function()
    while task.wait(0.2) do
        if not Config.Enabled then continue end
        local target = getClosestEnemy()
        if target then
            local hum = target.Parent:FindFirstChildOfClass("Humanoid")
            if hum then
                if lastTargetHum and lastTargetHum ~= hum and (lastTargetHum.Health <= 0 or not lastTargetHum.Parent) then
                    needsElement = true
                end
                lastTargetHum = hum
            end
        end
    end
end)

print("[AutoFarm] Módulo cargado. Anti-Temblor y Sistema de Placa activados.")
