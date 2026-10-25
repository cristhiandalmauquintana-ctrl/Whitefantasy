--// Froggy Hub - NearestKill.lua (V5 - Modo Vampiro + UI de Claude)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ==========================================
-- 1. CARGAR LA UI DE CLAUDE
-- ==========================================
-- Reemplaza esta URL con el enlace RAW de tu archivo NearestKillUI.lua en GitHub
local UI_URL = "https://raw.githubusercontent.com/cristhiandalmauquintana-ctrl/Whitefantasy/main/ElementalMagicArena/NearestKillUI.lua"
local NearestKillUI = loadstring(game:HttpGet(UI_URL))()

-- Crear el botón
local KillButton = NearestKillUI.new({
    Icon  = "⚔️",
    Label = "KILL",
    Size  = 76
})

-- ==========================================
-- 2. LÓGICA DEL MODO VAMPIRO
-- ==========================================
local isRunning = false

local function getClosestEnemy()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 2000 
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
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

local function equipSword()
    local char = LP.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") then
                char.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end

-- Conectar el clic del botón a la lógica
KillButton.OnClicked:Connect(function()
    if isRunning then return end

    local target = getClosestEnemy()
    if not target then
        return -- Si no hay enemigos, no hace nada
    end

    isRunning = true
    KillButton:SetCooldown(true) -- Bloqueamos el botón visualmente

    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")

    if myRoot and myHum then
        equipSword()
        
        -- 🔥 Activamos PlatformStand para flotar y quitarnos la gravedad
        myHum.PlatformStand = true
        
        local startTime = tick()
        
        -- Bucle de pegado (Máximo 3 segundos)
        while isRunning and target and target.Parent do
            local targetHum = target.Parent and target.Parent:FindFirstChild("Humanoid")
            
            -- Si el enemigo muere, salimos
            if not targetHum or targetHum.Health <= 0 then
                break
            end

            -- Seguro anti-bucle infinito
            if tick() - startTime > 3 then
                break
            end

            -- Teletransportar 3 studs arriba del enemigo
            local targetPos = target.Position + Vector3.new(0, 3, 0)
            myRoot.CFrame = CFrame.new(targetPos, target.Position)
            myRoot.AssemblyLinearVelocity = Vector3.zero

            -- Forzar ataque de la espada
            local tool = myChar:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
            end

            task.wait(0.05)
        end

        -- Restauramos la gravedad
        if myHum then
            myHum.PlatformStand = false
        end
    end

    isRunning = false
    KillButton:SetCooldown(false) -- Liberamos el botón
end)

print("[NearestKill] Cargado con éxito. UI Épica conectada al Modo Vampiro.")
