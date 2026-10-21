--// Froggy Hub - Silent Aim v2 (NPCs + anti-crash NaN)
--// Fix: NaN en CFrame.lookAt y Mouse.Hit cuando la distancia es grande

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
    MaxAimDistance = 500, -- Tope de seguridad (evita crashes y anti-cheat)
    TargetPart = nil,
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}

-- Cache para evitar recursión en el hook
local mouseRef
pcall(function() mouseRef = LocalPlayer:GetMouse() end)
local cameraRef = workspace.CurrentCamera
pcall(function()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cameraRef = workspace.CurrentCamera
    end)
end)

-- Helpers anti-NaN
local function isNum(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end
local function isVec3(v)
    return v and isNum(v.X) and isNum(v.Y) and isNum(v.Z)
end
local function isCFrame(cf)
    return cf and isVec3(cf.Position) and isVec3(cf.LookVector) and isVec3(cf.RightVector) and isVec3(cf.UpVector)
end

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
    local ok, result = pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character, part.Parent }
        local r = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
        return r == nil or r.Instance:IsDescendantOf(part.Parent)
    end)
    return ok and result or true
end

-- Calcula la posición de apuntado con TODAS las comprobaciones de seguridad
local function computeAimPos(targetPart)
    if not targetPart or not targetPart.Parent then return nil end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end -- jugador muerto/respawneando

    local okP, pos = pcall(function() return targetPart.Position end)
    if not okP or not isVec3(pos) then return nil end

    local vel = Vector3.zero
    pcall(function() vel = targetPart.AssemblyLinearVelocity end)
    if not isVec3(vel) then vel = Vector3.zero end

    local lead = vel * Config.Prediction
    if lead.Magnitude > 40 then lead = lead.Unit * 40 end
    local aimPos = pos + lead
    if not isVec3(aimPos) then return nil end

    local okM, myPos = pcall(function() return myRoot.Position end)
    if not okM or not isVec3(myPos) then return nil end

    -- Tope de seguridad para evitar NaN, crashes y anti-cheat
    local delta = aimPos - myPos
    local dist = delta.Magnitude
    if not isNum(dist) then return nil end
    local cap = Config.MaxAimDistance or 500
    if dist > cap then
        if dist < 0.001 then return nil end
        aimPos = myPos + delta.Unit * cap
    end

    return aimPos
end

-- CFrame.lookAt seguro (evita NaN cuando el objetivo está justo encima/debajo)
local function safeLookAt(originCF, aimPos)
    if not originCF or not aimPos then return originCF end
    if not isCFrame(originCF) or not isVec3(aimPos) then return originCF end
    local origin = originCF.Position
    local dir = aimPos - origin
    if not isVec3(dir) or dir.Magnitude < 0.1 then return originCF end
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude < 0.001 then return originCF end
    local ok, newCF = pcall(CFrame.lookAt, origin, aimPos)
    if not ok or not isCFrame(newCF) then return originCF end
    return newCF
end

-- Loop de búsqueda de objetivos
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
    local okSize, viewport = pcall(function() return cam.ViewportSize end)
    if not okSize or not viewport or not isNum(viewport.X) or not isNum(viewport.Y) then return end

    local center = viewport / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local bestPart, bestDist = nil, Config.FOV

    local function tryCandidate(part, hum)
        if not hum or not part or hum.Health <= 0 then return end
        local okW, pos, onScreen = pcall(function() return cam:WorldToViewportPoint(part.Position) end)
        if not okW or not pos or not onScreen then return end
        if pos.Z <= 0 or not isNum(pos.X) or not isNum(pos.Y) then return end
        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if not isNum(d) or d >= bestDist then return end
        local inRange = true
        if myRoot and Config.MaxDistance > 0 then
            local okR, dist = pcall(function() return (part.Position - myRoot.Position).Magnitude end)
            if not okR or not isNum(dist) then return end
            inRange = dist <= Config.MaxDistance
        end
        if not inRange then return end
        if Config.WallCheck and not isVisible(part) then return end
        bestPart, bestDist = part, d
    end

    -- 1. Jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and (char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart"))
            tryCandidate(part, hum)
        end
    end

    -- 2. NPCs
    if Config.AttackNPCs then
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, npc in ipairs(enemiesFolder:GetChildren()) do
                if not Players:GetPlayerFromCharacter(npc) then
                    local hum = npc:FindFirstChildOfClass("Humanoid")
                    local part = npc:FindFirstChild(Config.AimPart) or npc:FindFirstChild("HumanoidRootPart")
                    tryCandidate(part, hum)
                end
            end
        end
    end

    Config.TargetPart = bestPart
end))

-- Instalar hook
if type(hookmetamethod) ~= "function" then
    warn("[Froggy Hub] SilentAim: hookmetamethod no soportado por tu executor.")
    return
end

local oldIndex
local hookOk, hookErr = pcall(function()
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not Config.Enabled then
            return oldIndex(self, key)
        end
        local targetPart = Config.TargetPart
        if not targetPart or not targetPart.Parent then
            return oldIndex(self, key)
        end

        -- Cámara (con safeLookAt anti-NaN)
        if self == cameraRef and key == "CFrame" then
            local originalCF = oldIndex(self, key)
            local aimPos = computeAimPos(targetPart)
            if aimPos then
                return safeLookAt(originalCF, aimPos)
            end
            return originalCF
        end

        -- Ratón (con verificación de NaN)
        if mouseRef and self == mouseRef then
            local aimPos = computeAimPos(targetPart)
            if not aimPos then return oldIndex(self, key) end
            if key == "Hit" then
                return CFrame.new(aimPos)
            elseif key == "Target" then
                return targetPart
            elseif key == "UnitRay" then
                local okO, originCF = pcall(function() return oldIndex(self, "Origin") end)
                if okO and isCFrame(originCF) then
                    local origin = originCF.Position
                    local dir = aimPos - origin
                    if isVec3(dir) and dir.Magnitude > 0.1 then
                        return Ray.new(origin, dir.Unit * 1000)
                    end
                end
                return oldIndex(self, key)
            end
        end

        return oldIndex(self, key)
    end)
end)

if not hookOk then
    warn("[Froggy Hub] SilentAim: error al instalar el hook: " .. tostring(hookErr))
    return
end

print("[Froggy Hub] SilentAim v2 instalado (anti-crash activo).")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    Config.TargetPart = nil
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
