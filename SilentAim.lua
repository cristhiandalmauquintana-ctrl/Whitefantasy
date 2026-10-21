--// Froggy Hub - Silent Aim v3 (FIX CRASH definitivo)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end

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

    MaxAimDistance = 200,    -- ⚠️ BAJADO de 500 a 200 (más seguro)
    UseCameraHook = false,   -- ⚠️ Cámara desactivada por defecto (era el crash)
    UseMouseHit = true,      -- Hook de Mouse.Hit (skills/espadas)
    UseMouseTarget = true,   -- Hook de Mouse.Target (Target de skills)

    TargetPart = nil,
    LastRejectReason = "",
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}

local mouseRef
pcall(function() mouseRef = LocalPlayer:GetMouse() end)
local cameraRef = workspace.CurrentCamera
pcall(function()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cameraRef = workspace.CurrentCamera
    end)
end)

local function isNum(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
local function isVec3(v) return v and isNum(v.X) and isNum(v.Y) and isNum(v.Z) end
local function isCFrame(cf) return cf and isVec3(cf.Position) and isVec3(cf.LookVector) end

local function isFriend(player)
    local c = friendCache[player.UserId]
    if c ~= nil then return c end
    local ok, r = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    friendCache[player.UserId] = ok and r or false
    return friendCache[player.UserId]
end

local function sameTeam(p) return LocalPlayer.Team ~= nil and p.Team == LocalPlayer.Team end
local function isAllowed(p)
    if p == LocalPlayer then return false end
    if Config.TeamCheck and sameTeam(p) then return false end
    if Config.IgnoreFriends and isFriend(p) then return false end
    return true
end

local function isVisible(part)
    if not cameraRef then return true end
    local ok, r = pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character, part.Parent }
        local hit = workspace:Raycast(cameraRef.CFrame.Position, part.Position - cameraRef.CFrame.Position, params)
        return hit == nil or hit.Instance:IsDescendantOf(part.Parent)
    end)
    return ok and r or true
end

-- ⚠️ FUNCIÓN CLAVE: devuelve nil si el objetivo está demasiado lejos (NO cappea)
local function computeAimPos(targetPart)
    if not targetPart or not targetPart.Parent then return nil, "no_part" end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, "no_player_root" end

    local okP, pos = pcall(function() return targetPart.Position end)
    if not okP or not isVec3(pos) then return nil, "bad_target_pos" end

    local vel = Vector3.zero
    pcall(function() vel = targetPart.AssemblyLinearVelocity end)
    if not isVec3(vel) then vel = Vector3.zero end

    local lead = vel * Config.Prediction
    if lead.Magnitude > 40 then lead = lead.Unit * 40 end
    local aimPos = pos + lead
    if not isVec3(aimPos) then return nil, "bad_aim_pos" end

    local okM, myPos = pcall(function() return myRoot.Position end)
    if not okM or not isVec3(myPos) then return nil, "bad_my_pos" end

    local dist = (aimPos - myPos).Magnitude
    if not isNum(dist) then return nil, "bad_dist" end
    if dist > Config.MaxAimDistance then
        return nil, "too_far_" .. math.floor(dist)
    end

    return aimPos
end

-- Loop de selección
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

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and (char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart"))
            try(part, hum)
        end
    end

    if Config.AttackNPCs then
        local folder = workspace:FindFirstChild("Enemies")
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

if type(hookmetamethod) ~= "function" then
    warn("[Froggy Hub] SilentAim: hookmetamethod no soportado.")
    return
end

local oldIndex
local hookOk, hookErr = pcall(function()
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not Config.Enabled then return oldIndex(self, key) end

        local targetPart = Config.TargetPart
        if not targetPart or not targetPart.Parent then return oldIndex(self, key) end

        -- Cámara (opcional, desactivada por defecto)
        if Config.UseCameraHook and self == cameraRef and key == "CFrame" then
            local originalCF = oldIndex(self, key)
            local aimPos = computeAimPos(targetPart)
            if not aimPos then return originalCF end
            if not isCFrame(originalCF) then return originalCF end
            local dir = aimPos - originalCF.Position
            if not isVec3(dir) or dir.Magnitude < 0.1 then return originalCF end
            local flat = Vector3.new(dir.X, 0, dir.Z)
            if flat.Magnitude < 0.01 then return originalCF end
            local ok, newCF = pcall(CFrame.lookAt, originalCF.Position, aimPos)
            if not ok or not isCFrame(newCF) then return originalCF end
            return newCF
        end

        -- Ratón
        if mouseRef and self == mouseRef then
            local aimPos = computeAimPos(targetPart)
            if not aimPos then return oldIndex(self, key) end

            if key == "Hit" and Config.UseMouseHit then
                -- ⚠️ CFrame en aimPos mirando hacia la cámara (rotación válida)
                local camPos = cameraRef and cameraRef.CFrame.Position or Vector3.zero
                if not isVec3(camPos) then camPos = aimPos + Vector3.new(0, 1, 0) end
                local ok, cf = pcall(CFrame.lookAt, aimPos, camPos)
                if ok and isCFrame(cf) then return cf end
                return oldIndex(self, key)
            elseif key == "Target" and Config.UseMouseTarget then
                return targetPart
            elseif key == "UnitRay" then
                local okO, originCF = pcall(function() return oldIndex(self, "Origin") end)
                if okO and isCFrame(originCF) then
                    local dir = aimPos - originCF.Position
                    if isVec3(dir) and dir.Magnitude > 0.1 then
                        return Ray.new(originCF.Position, dir.Unit * 1000)
                    end
                end
                return oldIndex(self, key)
            end
        end

        return oldIndex(self, key)
    end)
end)

if not hookOk then
    warn("[Froggy Hub] SilentAim: error instalando hook: " .. tostring(hookErr))
    return
end

print("[Froggy Hub] SilentAim v3 OK. MaxAimDistance=200, CameraHook=OFF")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    Config.TargetPart = nil
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
