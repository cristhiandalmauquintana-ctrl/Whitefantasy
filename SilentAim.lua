--// Froggy Hub - Silent Aim v5 (Multi-hook + Debug)
--// Engancha Raycast, FindPartOnRay, GetPartBoundsInBox, GetPartsInPart, GetPartBoundsInRadius

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
    Debug = false,  -- Imprime en consola qué métodos se llaman al atacar
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}
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

-- Loop de selección (sin hooks)
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
        if myRoot and Config.MaxDistance > 0 then
            if (part.Position - myRoot.Position).Magnitude > Config.MaxDistance then return end
        end
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

-- ==========================================
-- HOOK MULTI-MÉTODO
-- ==========================================
if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] v5: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

-- Contador de métodos (para debug)
local methodCount = {}

local function debugLog(msg)
    if Config.Debug then
        print("[SA-Debug] " .. msg)
    end
end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- Debug: contar métodos usados
    if Config.Debug and (self == Workspace or tostring(self):find("Mouse")) then
        methodCount[method] = (methodCount[method] or 0) + 1
    end

    if Config.Enabled and Config.TargetPart and Config.TargetPart.Parent then
        local targetPart = Config.TargetPart
        local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
        if lead.Magnitude > 40 then lead = lead.Unit * 40 end
        local aimPos = targetPart.Position + lead

        -- 1. Raycast
        if method == "Raycast" and self == Workspace then
            local args = {...}
            local origin = args[1]
            if typeof(origin) == "Vector3" then
                local dir = aimPos - origin
                if dir.Magnitude > 0.1 then
                    args[2] = dir.Unit * math.max(dir.Magnitude, 500)
                    debugLog("Raycast redirigido (" .. math.floor(dir.Magnitude) .. " studs)")
                    return oldNamecall(self, unpack(args))
                end
            end
        end

        -- 2. FindPartOnRay (legacy)
        if (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and self == Workspace then
            local args = {...}
            local ray = args[1]
            if typeof(ray) == "Ray" then
                local dir = aimPos - ray.Origin
                if dir.Magnitude > 0.1 then
                    args[1] = Ray.new(ray.Origin, dir.Unit * 500)
                    debugLog(method .. " redirigido")
                    return oldNamecall(self, unpack(args))
                end
            end
        end

        -- 3. GetPartBoundsInBox / GetPartBoundsInRadius / GetPartsInPart (melee hitboxes)
        if (method == "GetPartBoundsInBox" or method == "GetPartBoundsInRadius" or method == "GetPartsInPart") and self == Workspace then
            local args = {...}
            local cframe = args[1]
            if typeof(cframe) == "CFrame" then
                local dir = aimPos - cframe.Position
                if dir.Magnitude > 0.1 then
                    args[1] = cframe + dir
                    debugLog(method .. " movido a " .. math.floor(dir.Magnitude) .. " studs")
                    return oldNamecall(self, unpack(args))
                end
            end
        end

        -- 4. ScreenPointToRay (algunos juegos lo usan para skills)
        if method == "ScreenPointToRay" and self == cameraRef then
            local args = {...}
            local ok, ray = pcall(oldNamecall, self, unpack(args))
            if ok and typeof(ray) == "Ray" then
                local dir = aimPos - ray.Origin
                if dir.Magnitude > 0.1 then
                    debugLog("ScreenPointToRay redirigido")
                    return Ray.new(ray.Origin, dir.Unit * 500)
                end
            end
        end

        -- 5. ViewportPointToRay (similar al anterior)
        if method == "ViewportPointToRay" and self == cameraRef then
            local args = {...}
            local ok, ray = pcall(oldNamecall, self, unpack(args))
            if ok and typeof(ray) == "Ray" then
                local dir = aimPos - ray.Origin
                if dir.Magnitude > 0.1 then
                    debugLog("ViewportPointToRay redirigido")
                    return Ray.new(ray.Origin, dir.Unit * 500)
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
print("[Froggy Hub] SilentAim v5 instalado (multi-método).")

-- Función para ver qué métodos se llamaron (útil para debug)
env.BF_SA_METHODS = function()
    if next(methodCount) == nil then
        return "Ningún método detectado. Activa Debug y ataca para ver."
    end
    local list = {}
    for k, v in pairs(methodCount) do
        table.insert(list, k .. ": " .. v)
    end
    return table.concat(list, "\n")
end

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    Config.TargetPart = nil
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end)
    env.BF_SA_CONFIG = nil
    env.BF_SA_METHODS = nil
    env.__BF_SA_CLEANUP = nil
end
