--// Froggy Hub - Silent Aim v9 (Ignora M1 + Límite Seguro para Frutas)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SA_CLEANUP then pcall(env.__BF_SA_CLEANUP) end

local Config = {
    Enabled = false,
    FOV = 300,
    ShowFOV = true,
    Aim360 = true,           -- Por defecto en 360 para frutas
    MaxDistance = 350,       -- Límite seguro (ni muy corto, ni muy lejos)
    Prediction = 0.12,
    AimPart = "HumanoidRootPart",
    TeamCheck = true,
    IgnoreFriends = false,
    AttackNPCs = false,
    TargetPart = nil,
    Debug = false,
}
env.BF_SA_CONFIG = Config

local connections = {}
local friendCache = {}

local function getParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and typeof(ui) == "Instance" then return ui end
    end
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
fovStroke.Color = Color3.fromRGB(110, 220, 90)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.4

local cameraRef = Workspace.CurrentCamera
pcall(function()
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cameraRef = Workspace.CurrentCamera
    end)
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
    if Config.TeamCheck and LocalPlayer.Team ~= nil and p.Team == LocalPlayer.Team then return false end
    if Config.IgnoreFriends and isFriend(p) then return false end
    return true
end

local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    fovCircle.Visible = Config.Enabled and Config.ShowFOV
    if fovCircle.Visible then fovCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2) end

    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end
    updateTimer = 0
    if not Config.Enabled then Config.TargetPart = nil return end

    local cam = cameraRef
    if not cam or not myRoot then return end

    local center = cam.ViewportSize / 2
    local bestPart = nil
    local bestDist = Config.FOV
    local best3DDist = math.huge

    local function try(part, hum)
        if not hum or not part or hum.Health <= 0 then return end
        local dist3D = (part.Position - myRoot.Position).Magnitude
        if dist3D > Config.MaxDistance then return end

        if Config.Aim360 then
            if dist3D < best3DDist then bestPart, best3DDist = part, dist3D end
        else
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen and pos.Z > 0 then
                local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if d < bestDist then bestPart, bestDist = part, d end
            end
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

if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] v9: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if not Config.Enabled or not Config.TargetPart or not Config.TargetPart.Parent then
        return oldNamecall(self, ...)
    end

    if method == "FindPartOnRayWithIgnoreList" and self == Workspace then
        local args = {...}
        local ray = args[1]
        
        if typeof(ray) == "Ray" then
            local origin = ray.Origin
            
            -- 1. EL FILTRO M1: Si el rayo es menor a 50 studs, IGNORAR (Es un golpe de espada)
            if ray.Direction.Magnitude < 50 then
                return oldNamecall(self, ...)
            end

            -- 2. EL FILTRO DE ORIGEN: Asegurarse de que viene del jugador
            local isFromPlayer = false
            if myHead and (origin - myHead.Position).Magnitude < 15 then isFromPlayer = true end
            if not isFromPlayer and myRoot and (origin - myRoot.Position).Magnitude < 15 then isFromPlayer = true end
            
            -- Si es una habilidad y viene del jugador, REDIRIGIR
            if isFromPlayer then
                local targetPart = Config.TargetPart
                local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
                if lead.Magnitude > 40 then lead = lead.Unit * 40 end
                local aimPos = targetPart.Position + lead

                local dir = aimPos - origin
                if dir.Magnitude > 0.1 then
                    args[1] = Ray.new(origin, dir.Unit * ray.Direction.Magnitude)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
print("[Froggy Hub] SilentAim v9 instalado (Ignora M1 + Solo Habilidades).")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    Config.TargetPart = nil
    fovGui:Destroy()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end)
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
