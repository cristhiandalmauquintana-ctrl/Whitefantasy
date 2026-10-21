--// Froggy Hub - Silent Aim (Aim Assist silencioso)
--// Intercepta la cámara y el ratón para redirigir golpes sin mover la pantalla.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then
    pcall(env.__BF_SA_CLEANUP)
end

local Config = {
    Enabled = false,
    FOV = 200,                    -- Radio en píxeles para elegir objetivo
    MaxDistance = 400,            -- Studs máximos
    Prediction = 0.12,            -- Anticipación de movimiento
    AimPart = "HumanoidRootPart", -- "HumanoidRootPart" o "Head"
    TeamCheck = true,
    IgnoreFriends = false,
    WallCheck = false,
    Target = nil,                 -- Jugador actual (interno)
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}

local function isFriend(player)
    local cached = friendCache[player.UserId]
    if cached ~= nil then return cached end
    local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    friendCache[player.UserId] = ok and result or false
    return friendCache[player.UserId]
end

local function sameTeam(player)
    if LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then return true end
    return false
end

local function isAllowed(player)
    if player == LocalPlayer then return false end
    if Config.TeamCheck and sameTeam(player) then return false end
    if Config.IgnoreFriends and isFriend(player) then return false end
    return true
end

local function getPart(player)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    return char:FindFirstChild(Config.AimPart) or char:FindFirstChild("HumanoidRootPart")
end

local function isVisible(part)
    local camera = workspace.CurrentCamera
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

-- Actualiza el objetivo constantemente
local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end -- 20 veces por segundo
    updateTimer = 0

    if not Config.Enabled then
        Config.Target = nil
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    local best, bestDist = nil, Config.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) then
            local part = getPart(player)
            if part then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    local inRange = true
                    if myRoot and Config.MaxDistance > 0 then
                        inRange = (part.Position - myRoot.Position).Magnitude <= Config.MaxDistance
                    end
                    if d < bestDist and inRange and (not Config.WallCheck or isVisible(part)) then
                        best, bestDist = player, d
                    end
                end
            end
        end
    end
    Config.Target = best
end))

--// El Hook (La magia del Silent Aim)
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not Config.Enabled or not Config.Target then
        return oldIndex(self, key)
    end

    local targetPart = getPart(Config.Target)
    if not targetPart then
        return oldIndex(self, key)
    end

    -- Calcular la posición con predicción
    local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
    if lead.Magnitude > 40 then lead = lead.Unit * 40 end
    local aimPos = targetPart.Position + lead

    -- 1. Hookear la Cámara (para habilidades que usan Camera.CFrame)
    local camera = workspace.CurrentCamera
    if self == camera and key == "CFrame" then
        local originalCFrame = oldIndex(self, key)
        return CFrame.lookAt(originalCFrame.Position, aimPos)
    end

    -- 2. Hookear el Ratón (para espadas, armas y skills que usan Mouse.Hit)
    local mouse = LocalPlayer:GetMouse()
    if self == mouse then
        if key == "Hit" then
            return aimPos
        elseif key == "Target" then
            return targetPart
        elseif key == "UnitRay" then
            local origin = oldIndex(self, "Origin")
            return Ray.new(origin, (aimPos - origin).Unit * 1000)
        end
    end

    return oldIndex(self, key)
end)

env.__BF_SA_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    if oldIndex then
        pcall(function() hookmetamethod = oldIndex end) -- Restaurar el hook original si es posible
    end
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
