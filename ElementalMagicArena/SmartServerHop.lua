--// Froggy Hub - ElementalMagicArena/SmartServerHop.lua (módulo real, SIN UI)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.__BF_SERVERHOP_CLEANUP then pcall(env.__BF_SERVERHOP_CLEANUP) end

local Config = {
    Enabled = false,   -- apagado por defecto
    HopTime = 1200,    -- segundos (20 min)
}
env.BF_SERVERHOP_CONFIG = Config

local running = true
local elapsed = 0

local function hop()
    local ok, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    end)
    if ok then
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok2 and data and data.data then
            local list = {}
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 then
                    table.insert(list, s.id)
                end
            end
            if #list > 0 then
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(#list)], LocalPlayer)
                end)
                return
            end
        end
    end
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

task.spawn(function()
    while running do
        task.wait(1)
        if Config.Enabled then
            elapsed = elapsed + 1
            if elapsed >= (tonumber(Config.HopTime) or 1200) then
                elapsed = 0
                hop()
                task.wait(15) -- evita spam si el teleport tarda
            end
        else
            elapsed = 0
        end
    end
end)

env.__BF_SERVERHOP_CLEANUP = function()
    running = false
    Config.Enabled = false
    env.BF_SERVERHOP_CONFIG = nil
    env.__BF_SERVERHOP_CLEANUP = nil
end
