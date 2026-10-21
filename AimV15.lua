--// Froggy Hub - Silent Aim v18 (Community-Proven Anti-Crash)
--// Basado en técnicas de filtrado con getcallingscript y hook de Mouse.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end

local Config = {
    Enabled = false,
    FOV = 400,
    ShowFOV = true,
    Aim360 = true,
    MaxDistance = 250,
    Prediction = 0.15,
    AimPart = "Head",
    TeamCheck = true,
    IgnoreFriends = false,
    AttackNPCs = false,
    TargetPart = nil,
    Debug = false,
}
env.BF_SA_CONFIG = Config

-- Nombres de los scripts internos de Blox Fruits que disparan los rayos de combate.
-- Añade más si encuentras que alguna habilidad no se redirige.
local CallingScripts = {
    "Combat", "Sword", "Gun", "Fruit", "Skill", "Weapon"
}

local connections = {}
local friendCache = {}

local function getParent()
    if gethui then local ok, ui = pcall(gethui); if ok and typeof(ui) == "Instance" then return ui end end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "FroggySA_FOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.DisplayOrder = 54
fovGui.Parent = getParent()

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = fovGui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.fromRGB(255, 50, 50)
fovStroke.Thickness = 2
fovStroke.Transparency = 0.3

local cameraRef = Workspace.CurrentCamera
local mouseRef = LocalPlayer:GetMouse()
pcall(function()
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() cameraRef = Workspace.CurrentCamera end)
end)

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
    if Config.TeamCheck then
        local ok, isSameTeam = pcall(function()
            if LocalPlayer.Team ~= nil and p.Team ~= nil then return LocalPlayer.Team == p.Team end
            return false
        end)
        if ok and isSameTeam then return false end
    end
    if Config.IgnoreFriends and isFriend(p) then return false end
    return true
end

local cachedAimPart = nil
local cachedAimVector = nil

local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    fovCircle.Visible = Config.Enabled and Config.ShowFOV
    if fovCircle.Visible then fovCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2) end

    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end
    updateTimer = 0

    if not Config.Enabled then Config.TargetPart = nil cachedAimPart = nil cachedAimVector = nil return end

    local cam = cameraRef
    if not cam or not myRoot then return end

    local center = cam.ViewportSize / 2
    local bestPart = nil
    local bestDist = Config.FOV
    local best3DDist = math.huge

    local function try(part, hum, isPlayer)
        if not hum or not part or hum.Health <= 0 then return end
        local dist3D = (part.Position - myRoot.Position).Magnitude
        if dist3D > Config.MaxDistance then return end
        local priorityBoost = (isPlayer and Config.PvPMode) and -1000 or 0

        if Config.Aim360 then
            if (dist3D + priorityBoost) < best3DDist then bestPart, best3DDist = part, (dist3D + priorityBoost) end
        else
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen and pos.Z > 0 then
                local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if (d + priorityBoost) < bestDist then bestPart, bestDist = part, (d + priorityBoost) end
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if isAllowed(player) and player.Character then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local aimPart = Config.PvPMode and char:FindFirstChild("Head") or char:FindFirstChild(Config.AimPart)
            local part = aimPart or char:FindFirstChild("HumanoidRootPart")
            try(part, hum, true)
        end
    end

    if Config.AttackNPCs and (not bestPart or not Config.PvPMode) then
        local folder = Workspace:FindFirstChild("Enemies")
        if folder then
            for _, npc in ipairs(folder:GetChildren()) do
                if npc:IsA("Model") and not Players:GetPlayerFromCharacter(npc) then
                    local hum = npc:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local part = npc:FindFirstChild(Config.AimPart) or npc:FindFirstChild("HumanoidRootPart")
                        try(part, hum, false)
                    end
                end
            end
        end
    end

    Config.TargetPart = bestPart

    if bestPart and bestPart.Parent then
        cachedAimPart = bestPart
        local ok, vel = pcall(function() return bestPart.AssemblyLinearVelocity end)
        if ok and vel then
            local pred = Config.Prediction
            if Config.PvPMode then pred = math.clamp(vel.Magnitude * 0.015, 0.1, 0.35) end
            local lead = vel * pred
            if lead.Magnitude > 80 then lead = lead.Unit * 80 end
            cachedAimVector = bestPart.Position + lead
        end
    else
        cachedAimPart = nil
        cachedAimVector = nil
    end
end))

if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] v18: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

-- HOOK DE NAMECALL FILTRADO (Rayos de armas/habilidades)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if Config.Enabled and cachedAimVector and cachedAimPart and cachedAimPart.Parent then
        if method == "FindPartOnRayWithIgnoreList" or method == "Raycast" then
            local args = {...}
            local ray = args[1]
            if typeof(ray) == "Ray" then
                local callingScript = getcallingscript()
                -- Solo modificamos si el script que llama está en nuestra lista blanca
                if callingScript and table.find(CallingScripts, callingScript.Name) then
                    local origin = ray.Origin
                    local direction = (cachedAimVector - origin).Unit * ray.Direction.Magnitude
                    args[1] = Ray.new(origin, direction)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- HOOK DE INDEX (Ratón y Cámara)
mt.__index = newcclosure(function(self, key)
    if Config.Enabled and cachedAimVector and cachedAimPart and cachedAimPart.Parent then
        if self == cameraRef and key == "CFrame" then
            local originalCF = oldIndex(self, key)
            local ok, newCF = pcall(CFrame.lookAt, originalCF.Position, cachedAimVector)
            if ok and newCF then return newCF end
        elseif mouseRef and self == mouseRef then
            if key == "Hit" then return CFrame.new(cachedAimVector) end
            if key == "Target" then return cachedAimPart end
            if key == "UnitRay" then
                local origin = oldIndex(self, "Origin")
                return Ray.new(origin, (cachedAimVector - origin).Unit * 1000)
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)
print("[Froggy Hub] SilentAim V18 (Community Filter) instalado. Anti-Crash activo.")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    fovGui:Destroy()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        mt.__index = oldIndex
        setreadonly(mt, true)
    end)
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
