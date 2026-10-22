--// Froggy Hub - Auto Combat V6 (Anti-Crash)
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_COMBAT_CLEANUP then pcall(env.__BF_COMBAT_CLEANUP) end

local Config = {
    Enabled = false,
    AutoM1 = true,
    M1Delay = 0.1,       -- Mínimo 0.1 para evitar crasheos en móvil
    AutoSkills = true,
    SkillDelay = 1.5,
    SkillKeys = {"Z", "X", "C", "V"}
}
env.BF_COMBAT_CONFIG = Config

local running = true

-- 🛠️ Hilo 1: Auto M1 (Clics)
task.spawn(function()
    while running do
        if Config.Enabled and Config.AutoM1 then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end)
            end
            -- Forzamos el delay mínimo a 0.1 para que no crashee
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
                        -- Usamos VirtualInputManager que es más estable que 'keypress'
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
