--// Froggy Hub - Silent Aim v4 (Método Raycast - Anti-Crash)
--// Engancha Workspace:Raycast usando getrawmetatable + newcclosure.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end

local Config = {
    Enabled = false,
    FOV = 200,
    MaxDistance = 500,
    Prediction = 0.12,
    AimPart = "HumanoidRootPart",
    TeamCheck = true,
    IgnoreFriends = false,
    AttackNPCs = false,
    TargetPart = nil,
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}

-- Caches para evitar recursión
local cameraRef = Workspace.CurrentCamera
pcall(function()
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cameraRef = Workspace.CurrentCamera
    end)
end)

local function isFriend(player)
    local c = friendCache[player.UserId]
    if c ~= nil then return c end
    local ok, r = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    friendCache[player.UserId] = ok and r or false
    return friendCache[player.UserId]
end

local function isAllowed(p)
    if p == LocalPlayer then return false end
    if Config.TeamCheck and LocalPlayer.Team ~= nil and p.Team == LocalPlayer.Team then return false end
    if Config.IgnoreFriends and isFriend(p) then return false end
    return true
end

-- Loop de selección de objetivo (sin hooks, seguro)
local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end
    updateTimer = 0
    if not Config.Enabled then Config.TargetPart = nil return end

    local cam = cameraRef
    if not cam then return end
    local center = cam.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local bestPart, bestDist = nil, Config.FOV

    local function try(part, hum)
        if not hum or not part or hum.Health <= 0 then return end
        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen or pos.Z <= 0 then return end
        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if d >= bestDist then return end
        local inRange = true
        if myRoot and Config.MaxDistance > 0 then
            inRange = (part.Position - myRoot.Position).Magnitude <= Config.MaxDistance
        end
        if inRange then bestPart, bestDist = part, d end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and (char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart"))
            try(part, hum)
        end
    end

    if Config.AttackNPCs then
        local folder = Workspace:FindFirstChild("Enemies")
        if folder then
            for _, npc in ipairs(folder:GetChildren()) do
                if not Players:GetPlayerFromCharacter(npc) then
                    local hum = npc:FindFirstChildOfClass("Humanoid")
                    local part = npc:FindFirstChild(Config.AimPart) or npc:FindFirstChild("HumanoidRootPart")
                    try(part, hum)
                end
            end
        end
    end

    Config.TargetPart = bestPart
end))

-- ==========================================================
-- HOOK SEGURO: Raycast usando getrawmetatable + newcclosure
-- ==========================================================
if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] SilentAim v4: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Interceptar Raycast cuando está activo y hay un objetivo
    if Config.Enabled and method == "Raycast" and self == Workspace and Config.TargetPart then
        local targetPart = Config.TargetPart
        if targetPart and targetPart.Parent then
            -- Cálculo de predicción
            local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
            if lead.Magnitude > 40 then lead = lead.Unit * 40 end
            local aimPos = targetPart.Position + lead

            -- El Raycast original usa (origin, direction, params)
            -- Solo modificamos la dirección si apunta cerca del objetivo
            local origin = args[1]
            local originalDir = args[2]
            if typeof(origin) == "Vector3" and typeof(originalDir) == "Vector3" then
                -- Redirigir el rayo hacia el objetivo
                args[2] = (aimPos - origin).Unit * originalDir.Magnitude
            end
        end
    end

    return oldNamecall(self, unpack(args))
end)

setreadonly(mt, true)
print("[Froggy Hub] SilentAim v4 instalado (Método Raycast).")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    Config.TargetPart = nil
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    -- Restaurar el namecall original
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end)
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
