--// Froggy Hub - Silent Aim (con soporte para NPCs) - FIXED
--// Bugs corregidos: recursión infinita en __index, Mouse.Hit tipo CFrame, hook seguro.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then
    pcall(env.__BF_SA_CLEANUP)
end

local Config = {
    Enabled = false,
    FOV = 200,
    MaxDistance = 400,
    Prediction = 0.12,
    AimPart = "HumanoidRootPart",
    TeamCheck = true,
    IgnoreFriends = false,
    WallCheck = false,
    AttackNPCs = false,
    TargetPart = nil,
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}

-- ⚠️ CACHE CRÍTICO (evita la recursión infinita dentro del hook)
local mouseRef
pcall(function() mouseRef = LocalPlayer:GetMouse() end)
local cameraRef = workspace.CurrentCamera
pcall(function()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cameraRef = workspace.CurrentCamera
    end)
end)

local function isFriend(player)
    local cached = friendCache[player.UserId]
    if cached ~= nil then return cached end
    local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    friendCache[player.UserId] = ok and result or false
    return friendCache[player.UserId]
end

local function sameTeam(player)
    return LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end

local function isAllowed(player)
    if player == LocalPlayer then return false end
    if Config.TeamCheck and sameTeam(player) then return false end
    if Config.IgnoreFriends and isFriend(player) then return false end
    return true
end

local function isVisible(part)
    local cam = cameraRef
    if not cam then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, part.Parent }
    local result = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

-- Loop de búsqueda (FUERA del hook, sin riesgo de recursión)
local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end
    updateTimer = 0

    if not Config.Enabled then
        Config.TargetPart = nil
        return
    end

    local cam = cameraRef
    if not cam then return end
    local center = cam.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local bestPart, bestDist = nil, Config.FOV

    -- 1. Jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and (char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart"))
            if hum and part and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    local inRange = true
                    if myRoot and Config.MaxDistance > 0 then
                        inRange = (part.Position - myRoot.Position).Magnitude <= Config.MaxDistance
                    end
                    if d < bestDist and inRange and (not Config.WallCheck or isVisible(part)) then
                        bestPart, bestDist = part, d
                    end
                end
            end
        end
    end

    -- 2. NPCs
    if Config.AttackNPCs then
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        local scanTargets = enemiesFolder and enemiesFolder:GetChildren() or {}
        for _, npc in ipairs(scanTargets) do
            if not Players:GetPlayerFromCharacter(npc) then
                local hum = npc:FindFirstChildOfClass("Humanoid")
                local part = npc:FindFirstChild(Config.AimPart) or npc:FindFirstChild("HumanoidRootPart")
                if hum and part and hum.Health > 0 then
                    local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        local inRange = true
                        if myRoot and Config.MaxDistance > 0 then
                            inRange = (part.Position - myRoot.Position).Magnitude <= Config.MaxDistance
                        end
                        if d < bestDist and inRange and (not Config.WallCheck or isVisible(part)) then
                            bestPart, bestDist = part, d
                        end
                    end
                end
            end
        end
    end

    Config.TargetPart = bestPart
end))

--// Hook seguro
if type(hookmetamethod) ~= "function" then
    warn("[Froggy Hub] SilentAim: tu executor NO soporta hookmetamethod.")
    return
end

local oldIndex
local hookOk, hookErr = pcall(function()
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        -- Salida rápida (no interfiere si está apagado)
        if not Config.Enabled then
            return oldIndex(self, key)
        end
        local targetPart = Config.TargetPart
        if not targetPart or not targetPart.Parent then
            return oldIndex(self, key)
        end

        -- Cámara (para skills que usan Camera.CFrame)
        if self == cameraRef and key == "CFrame" then
            local originalCFrame = oldIndex(self, key)
            local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
            if lead.Magnitude > 40 then lead = lead.Unit * 40 end
            local aimPos = targetPart.Position + lead
            return CFrame.lookAt(originalCFrame.Position, aimPos)
        end

        -- Ratón (para espadas, armas y skills)
        if mouseRef and self == mouseRef then
            local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
            if lead.Magnitude > 40 then lead = lead.Unit * 40 end
            local aimPos = targetPart.Position + lead

            if key == "Hit" then
                -- ⚠️ Mouse.Hit devuelve CFrame, NO Vector3
                return CFrame.new(aimPos)
            elseif key == "Target" then
                return targetPart
            elseif key == "UnitRay" then
                local origin = oldIndex(self, "Origin").Position
                return Ray.new(origin, (aimPos - origin).Unit * 1000)
            end
        end

        return oldIndex(self, key)
    end)
end)

if not hookOk then
    warn("[Froggy Hub] SilentAim: error al instalar el hook: " .. tostring(hookErr))
    return
end

print("[Froggy Hub] SilentAim instalado correctamente.")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
