--// Froggy Hub - Auto Dodge (Jugadores y NPCs)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_DODGE_CLEANUP then pcall(env.__BF_DODGE_CLEANUP) end

local Config = {
    Enabled = false,
    DodgeDistance = 50,       
    Cooldown = 1.5,           
    DetectRange = 30,         
    DodgePlayers = true,
    DodgeNPCs = true,
    TriggerAnimations = {
        "Punch", "Slash", "Attack", "Combat", "Skill", 
        "Z", "X", "C", "V", "Gun", "Sword"
    }
}
env.BF_DODGE_CONFIG = Config

local connections = {}
local lastDodge = 0
local isDodging = false

local function getParts()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        return hum, root
    end
end

local function triggerDodge()
    local now = os.clock()
    if now - lastDodge < Config.Cooldown or isDodging then return end
    
    local hum, root = getParts()
    if not hum or not root then return end

    isDodging = true
    lastDodge = now
    
    local originalCF = root.CFrame
    root.CFrame = originalCF + Vector3.new(0, Config.DodgeDistance, 0)
    
    task.wait(0.1)
    
    if root and root.Parent then
        root.CFrame = originalCF
    end
    
    task.wait(0.1)
    isDodging = false
end

-- Función que revisa si un personaje (NPC o Jugador) está atacando
local function checkIfAttacking(char, myRoot)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if hum and root and hum.Health > 0 then
        local distance = (root.Position - myRoot.Position).Magnitude
        if distance <= Config.DetectRange then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local animName = track.Name
                    local assetName = track.Animation and track.Animation.Name or ""
                    
                    for _, trigger in ipairs(Config.TriggerAnimations) do
                        local lowerTrigger = string.lower(trigger)
                        if string.find(string.lower(animName), lowerTrigger) or string.find(string.lower(assetName), lowerTrigger) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local scanTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then return end
    
    scanTimer = scanTimer + dt
    if scanTimer < 0.05 then return end
    scanTimer = 0

    local hum, root = getParts()
    if not hum or not root then return end

    -- 1. Escanear Jugadores
    if Config.DodgePlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if checkIfAttacking(player.Character, root) then
                    triggerDodge()
                    return
                end
            end
        end
    end

    -- 2. Escanear NPCs (Carpeta Enemies de Blox Fruits)
    if Config.DodgeNPCs then
        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, npc in ipairs(enemiesFolder:GetChildren()) do
                if npc:IsA("Model") and not Players:GetPlayerFromCharacter(npc) then
                    if checkIfAttacking(npc, root) then
                        triggerDodge()
                        return
                    end
                end
            end
        end
    end
end))

env.__BF_DODGE_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_DODGE_CONFIG = nil
    env.__BF_DODGE_CLEANUP = nil
end
