--// Froggy Hub - ElementalMagicArena/ServerHop.lua
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local env = (getgenv and getgenv()) or _G

local Config = {
    Enabled = false,
    HopTime = 600 -- Segundos (10 minutos por defecto)
}
env.BF_SERVERHOP_CONFIG = Config

-- 🔥 LÓGICA PARA GUARDAR EL ESTADO DE LOS TOGGLES
local function saveCurrentState()
    local state = {}
    
    if env.BF_PLAYERFARM_CONFIG then state.Farm = env.BF_PLAYERFARM_CONFIG.Enabled end
    if env.BF_HITBOX_CONFIG then state.Hitbox = env.BF_HITBOX_CONFIG.Enabled end
    if env.BF_ATTACKALL_CONFIG then state.AttackAll = env.BF_ATTACKALL_CONFIG.Enabled end
    if env.BF_ESP_CONFIG then state.ESP = env.BF_ESP_CONFIG.Enabled end
    if env.BF_MOVE_CONFIG then state.Speed = env.BF_MOVE_CONFIG.SpeedEnabled end
    if env.BF_COMBAT_CONFIG then state.AutoCombat = env.BF_COMBAT_CONFIG.Enabled end
    if env.BF_SILENTCOLLECT_CONFIG then state.SilentCollect = env.BF_SILENTCOLLECT_CONFIG.Enabled end

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(state)
    end)
    if success and writefile then
        pcall(function() writefile("FroggyConfig.json", encoded) end)
    end
end

-- 🔥 LÓGICA DE SERVER HOP
local function doHop()
    if not Config.Enabled then return end
    
    print("[Froggy] Server Hop: Guardando configuración y viajando...")
    saveCurrentState()

    -- Le decimos al ejecutor que re-ejecute el Main.lua al entrar al nuevo server
    local loadstringCmd = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/cristhiandalmauquintana-ctrl/Whitefantasy/main/Main.lua?v=" .. os.time()))()'
    
    local queued = false
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(loadstringCmd)
        queued = true
    elseif queue_on_teleport then
        queue_on_teleport(loadstringCmd)
        queued = true
    elseif fluxus and fluxus.queue_on_teleport then
        fluxus.queue_on_teleport(loadstringCmd)
        queued = true
    elseif is_sirhurt_closure and sirhurt then
        queue_on_teleport(loadstringCmd)
        queued = true
    end

    if not queued then
        warn("[Froggy] Tu ejecutor no soporta queue_on_teleport. El Hub NO se auto-ejecutará.")
    end

    task.wait(1) -- Dar tiempo a que se guarde el archivo
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Bucle del contador
task.spawn(function()
    local timer = Config.HopTime
    while task.wait(1) do
        if Config.Enabled then
            timer -= 1
            if timer <= 0 then
                timer = Config.HopTime
                doHop()
            end
        else
            timer = Config.HopTime -- Resetear si se apaga
        end
    end
end)

env.__BF_SERVERHOP_CLEANUP = function()
    Config.Enabled = false
    env.BF_SERVERHOP_CONFIG = nil
    env.__BF_SERVERHOP_CLEANUP = nil
end
