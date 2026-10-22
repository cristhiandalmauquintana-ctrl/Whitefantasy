--// Froggy Hub - Auto Combat V5 (Súper Rápido y Estable)

local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game:GetService("Players").LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_COMBAT_CLEANUP then pcall(env.__BF_COMBAT_CLEANUP) end

local Config = {
    Enabled = false,
    AutoM1 = true,
    M1Delay = 0.05,       -- 0.05 = 20 clics por segundo (Rapidísimo, pero el juego lo aguanta)
    AutoSkills = true,
    SkillDelay = 1.5,
    SkillKeys = {"Z", "X", "C", "V"}
}
env.BF_COMBAT_CONFIG = Config

local lastClick = 0
local lastSkill = 0
local skillIndex = 1
local connection

local function pressKey(key)
    if type(keypress) == "function" then pcall(keypress, key) end
end

connection = RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then return end

    local now = os.clock()

    if Config.AutoM1 and (now - lastClick >= Config.M1Delay) then
        lastClick = now
        pcall(function()
            -- Clic izquierdo estándar (No usa tool:Activate, no rompe la física)
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
    end

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
