--// Froggy Hub - Auto Combat V8 (Anti-Crash + Joystick Safe + Filtro de Armas)
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_COMBAT_CLEANUP then pcall(env.__BF_COMBAT_CLEANUP) end

local Config = {
    Enabled = false,
    AutoM1 = true,
    M1Delay = 0.1,       -- Mínimo 0.1 para evitar crasheos
    AutoSkills = true,
    SkillDelay = 1.5,
    SkillKeys = {"Z", "X", "C", "V"}
}
env.BF_COMBAT_CONFIG = Config

local running = true

-- 🛠️ Función para verificar si el arma actual usa M1 (Espadas, Guadañas, Hachas, etc.)
local function isM1WeaponEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    local name = string.lower(tool.Name)
    
    -- Lista de palabras clave para armas que usan M1
    local weaponKeywords = {
        "sword", "katana", "blade", "dagger", "saber", "axe", "spear", "weapon", "fist",
        "scythe", "sickle", "reaper", "harvest", "crescent", "guadaña", "guadana"
    }
    
    for _, keyword in ipairs(weaponKeywords) do
        if name:find(keyword) then
            return true
        end
    end
    
    -- Si la herramienta tiene un click propio, permitir
    if tool:FindFirstChild("Click") or tool:FindFirstChild("Activated") then
        return true 
    end

    return false
end

-- 🛠️ Hilo 1: Auto M1 (Solo Armas de M1)
task.spawn(function()
    while running do
        if Config.Enabled and Config.AutoM1 and isM1WeaponEquipped() then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                pcall(function()
                    -- VirtualInputManager NO rompe el joystick
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end)
            end
            task.wait(math.clamp(Config.M1Delay, 0.1, 1))
        else
            task.wait(0.2)
        end
    end
end)

-- 🛠️ Hilo 2: Auto Skills (Z-X-C-V)
task.spawn(function()
    local skillIndex = 1
    while running do
        if Config.Enabled and Config.AutoSkills then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local keyName = Config.SkillKeys[skillIndex]
                local keyCode = Enum.KeyCode[keyName]
                
                if keyCode then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                    end)
                end
                
                skillIndex = skillIndex + 1
                if skillIndex > #Config.SkillKeys then skillIndex = 1 end
            end
            task.wait(math.clamp(Config.SkillDelay, 0.5, 5))
        else
            task.wait(0.5)
        end
    end
end)

env.__BF_COMBAT_CLEANUP = function()
    running = false
    env.BF_COMBAT_CONFIG = nil
    env.__BF_COMBAT_CLEANUP = nil
end
