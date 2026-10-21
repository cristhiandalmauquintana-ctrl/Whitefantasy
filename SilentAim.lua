--// Froggy Hub - Silent Aim v12 (Universal: Remotes + Raycast + Hitbox)
--// Ataque para Frutas, Armas, Pistolas y Estilos de Pelea.

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
    MaxDistance = 350,       -- Distancia general
    M1Distance = 35,         -- Distancia para Espadas/Puños (Evita Kicks)
    Prediction = 0.15,
    HitboxExpand = true,
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
fovStroke.Color = Color3.fromRGB(110, 220, 90)
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
    if Config.TeamCheck and LocalPlayer.Team ~= nil and p.Team == LocalPlayer.Team then return false end
    if Config.IgnoreFriends and isFriend(p) then return false end
    return true
end

-- HITBOX EXPANDER (Para que los M1 conecten)
local expandedHitboxes = {}
local function expandHitbox(part)
    if not Config.HitboxExpand or expandedHitboxes[part] then return end
    expandedHitboxes[part] = part.Size
    part.Size = Vector3.new(15, 15, 15) -- Hitbox gigante invisible
end
local function resetHitboxes()
    for part, originalSize in pairs(expandedHitboxes) do
        if part and part.Parent then pcall(function() part.Size = originalSize end) end
    end
    expandedHitboxes = {}
end

local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    fovCircle.Visible = Config.Enabled and Config.ShowFOV
    if fovCircle.Visible then fovCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2) end

    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end
    updateTimer = 0
    if not Config.Enabled then Config.TargetPart = nil resetHitboxes() return end

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
    if bestPart then expandHitbox(bestPart) end
end))

if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] v12: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

local function getAimPos(targetPart)
    local lead = targetPart.AssemblyLinearVelocity * Config.Prediction
    if lead.Magnitude > 60 then lead = lead.Unit * 60 end
    return targetPart.Position + lead
end

-- HOOK 1: RemoteEvents (Frutas y Habilidades)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if Config.Enabled and Config.TargetPart and Config.TargetPart.Parent and method == "FireServer" then
        local args = {...}
        local aimPos = getAimPos(Config.TargetPart)
        
        for i, arg in ipairs(args) do
            if typeof(arg) == "CFrame" then
                args[i] = CFrame.lookAt(arg.Position, aimPos)
                if Config.Debug then print("[SA] Remote CFrame -> Target") end
            elseif typeof(arg) == "Vector3" then
                local origin = myHead and myHead.Position or myRoot.Position
                args[i] = (aimPos - origin).Unit
                if Config.Debug then print("[SA] Remote Vector -> Target") end
            elseif typeof(arg) == "Instance" and arg:FindFirstChild("Humanoid") and arg ~= myChar then
                -- Si el juego manda al Humanoid del enemigo, lo forzamos
                if Config.TargetPart.Parent == arg then
                    args[i] = arg
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end)

-- HOOK 2: Cámara, Ratón y Raycast (Pistolas, Espadas y M1)
mt.__index = newcclosure(function(self, key)
    if Config.Enabled and Config.TargetPart and Config.TargetPart.Parent then
        if self == cameraRef and key == "CFrame" then
            local originalCF = oldIndex(self, key)
            local aimPos = getAimPos(Config.TargetPart)
            local ok, newCF = pcall(CFrame.lookAt, originalCF.Position, aimPos)
            if ok and newCF then return newCF end
        elseif mouseRef and self == mouseRef then
            local aimPos = getAimPos(Config.TargetPart)
            if key == "Hit" then return CFrame.new(aimPos) end
            if key == "Target" then return Config.TargetPart end
            if key == "UnitRay" then
                local origin = oldIndex(self, "Origin")
                return Ray.new(origin, (aimPos - origin).Unit * 1000)
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)
print("[Froggy Hub] SilentAim v12 (Universal) instalado.")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    resetHitboxes()
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
