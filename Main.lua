--// Froggy Hub - Silent Aim v7 (Optimizado - Cero Lag)
--// Cachea el personaje y limita los cálculos para no afectar los FPS

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end

local Config = {
    Enabled = false,
    FOV = 200,
    MaxDistance = 35, -- Lo bajamos para evitar kicks por distancia
    Prediction = 0.12,
    AimPart = "HumanoidRootPart",
    TeamCheck = true,
    IgnoreFriends = false,
    AttackNPCs = false,
    TargetPart = nil,
    Debug = false, -- IMPORTANTE: Dejarlo en false para evitar lag
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

-- Cache del personaje local (evita FindFirstChild en el hook)
local myChar, myHead, myRoot
local function updateCache()
    myChar = LocalPlayer.Character
    if myChar then
        myHead = myChar:FindFirstChild("Head")
        myRoot = myChar:FindFirstChild("HumanoidRootPart")
    end
end
LocalPlayer.CharacterAdded:Connect(updateCache)
LocalPlayer.CharacterRemoving:Connect(function() myChar, myHead, myRoot = nil, nil, nil end)
updateCache()

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

-- Bucle de selección (Limitado a ~20 FPS para ahorrar rendimiento)
local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end -- 20 veces por segundo es más que suficiente
    updateTimer = 0
    if not Config.Enabled then Config.TargetPart = nil return end

    local cam = cameraRef
    if not cam or not myRoot then return end

    local center = cam.ViewportSize / 2
    local bestPart, bestDist = nil, Config.FOV

    local function try(part, hum)
        if not hum or not part or hum.Health <= 0 then return end
        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen or pos.Z <= 0 then return end
        
        -- Distancia desde el jugador
        local dist = (part.Position - myRoot.Position).Magnitude
        if dist > Config.MaxDistance then return end

        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if d < bestDist then
            bestPart, bestDist = part, d
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) and player.Character then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local part = char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart")
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

-- HOOK OPTIMIZADO
if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] v7: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- SALIDA RÁPIDA: Si no hay target o está apagado, ni siquiera procesa el resto
    if not Config.Enabled or not Config.TargetPart or not Config.TargetPart.Parent then
        return oldNamecall(self, ...)
    end

    if method == "FindPartOnRayWithIgnoreList" and self == Workspace then
        local args = {...}
        local ray = args[1]
        
        if typeof(ray) == "Ray" then
            local origin = ray.Origin
            
            -- Comprobar si el rayo sale de nuestro personaje (usando el cache)
            local isFromPlayer = false
            if myHead and (origin - myHead.Position).Magnitude < 15 then isFromPlayer = true end
            if not isFromPlayer and myRoot and (origin - myRoot.Position).Magnitude < 15 then isFromPlayer = true end
            
            -- Solo rayos cortos (golpes)
            if isFromPlayer and ray.Direction.Magnitude < 100 then
                local targetPart = Config.TargetPart
                local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
                if lead.Magnitude > 40 then lead = lead.Unit * 40 end
                local aimPos = targetPart.Position + lead

                local dir = aimPos - origin
                if dir.Magnitude > 0.1 then
                    args[1] = Ray.new(origin, dir.Unit * ray.Direction.Magnitude)
                    
                    if Config.Debug then
                        print("[SA-Debug] Golpe redirigido!")
                    end
                    
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
print("[Froggy Hub] SilentAim v7 instalado (Optimizado).")

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
    env.__BF_SA_CLEANUP = nil
end
