--// Froggy Hub - Auto Combat V2 (Bypass de Animación y Tool Activate)

local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game:GetService("Players").LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_COMBAT_CLEANUP then pcall(env.__BF_COMBAT_CLEANUP) end

local Config = {
    Enabled = false,
    AutoM1 = true,
    M1Delay = 0.03,       -- 0.03 es muchísimo más rápido que antes
    BypassAnim = true,    -- Destruye la animación para atacar de nuevo
    AutoSkills = true,
    SkillDelay = 1.0,
    SkillKeys = {"Z", "X", "C", "V"}
}
env.BF_COMBAT_CONFIG = Config

local lastClick = 0
local lastSkill = 0
local skillIndex = 1
local connection

local function pressKey(key)
    if type(keypress) == "function" then
        pcall(keypress, key)
    end
end

-- Función para cancelar animaciones y liberar el cooldown del arma
local function bypassWeaponCooldown(char)
    if not Config.BypassAnim then return end
    local animator = char:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local name = string.lower(track.Name)
        -- Detenemos cualquier animación que parezca un ataque
        if string.find(name, "attack") or string.find(name, "slash") or string.find(name, "punch") or string.find(name, "swing") or string.find(name, "m1") then
            track:Stop(0) -- El 0 significa "detener instantáneamente"
        end
    end
end

connection = RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then return end

    local now = os.clock()

    -- 1. Hacer M1 (Bypass total)
    if Config.AutoM1 and (now - lastClick >= Config.M1Delay) then
        lastClick = now
        
        -- Cancelamos la animación para liberar el arma
        bypassWeaponCooldown(char)

        -- Buscamos el arma equipada
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            -- 🔥 EL SECRETO: Activar el tool directamente salta la cola del ratón
            pcall(function() tool:Activate() end)
        else
            -- Si no hay arma (estilo de pelea), usamos el clic normal
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end)
        end
    end

    -- 2. Lanzar Habilidades automáticamente
    if Config.AutoSkills and (now - lastSkill >= Config.SkillDelay) then
        lastSkill = now
        local keyName = Config.SkillKeys[skillIndex]
        local keyCode = Enum.KeyCode[keyName]
        if keyCode then pressKey(keyCode) end
        skillIndex = skillIndex + 1
        if skillIndex > #Config.SkillKeys then skillIndex = 1 end
    end
end)

env.__BF_COMBAT_CLEANUP = function()
    if connection then connection:Disconnect() end
    env.BF_COMBAT_CONFIG = nil
    env.__BF_COMBAT_CLEANUP = nil
end
