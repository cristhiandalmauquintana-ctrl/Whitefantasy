--// Froggy Hub - Silent Aim v17 (Modo Fantasma - Anti-Crash)
--// Sin Hook de Remotes. Solo Cámara y Ratón para evadir el Anti-Cheat.

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
    PvPMode = true,          
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

-- Variables cacheadas para el Hook
local cachedAimCFrame = nil
local cachedAimPart = nil
local cachedAimVector = nil

local updateTimer = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    fovCircle.Visible = Config.Enabled and Config.ShowFOV
    if fovCircle.Visible then fovCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2) end

    updateTimer = updateTimer + dt
    if updateTimer < 0.05 then return end
    updateTimer = 0
    
    if not Config.Enabled then 
        Config.TargetPart = nil 
        cachedAimCFrame = nil
        cachedAimPart = nil
        cachedAimVector = nil
        return 
    end

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

    -- CALCULAMOS EL AIM AQUÍ (Fuera del hook)
    if bestPart and bestPart.Parent then
        cachedAimPart = bestPart
        local ok, vel = pcall(function() return bestPart.AssemblyLinearVelocity end)
        if ok and vel then
            local dynamicPrediction = Config.Prediction
            if Config.PvPMode then
                dynamicPrediction = math.clamp(vel.Magnitude * 0.015, 0.1, 0.35)
            end
            local lead = vel * dynamicPrediction
            if lead.Magnitude > 80 then lead = lead.Unit * 80 end
            local pos = bestPart.Position + lead
            
            if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then pos = bestPart.Position end
            
            cachedAimVector = pos
            local origin = cameraRef.CFrame.Position
            cachedAimCFrame = CFrame.lookAt(origin, pos) 
        end
    else
        cachedAimPart = nil
        cachedAimVector = nil
        cachedAimCFrame = nil
    end
end))

if not getrawmetatable or not newcclosure then
    warn("[Froggy Hub] v17: Tu executor no soporta getrawmetatable/newcclosure.")
    return
end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

-- ÚNICO HOOK: Cámara y Ratón
mt.__index = newcclosure(function(self, key)
    if Config.Enabled and cachedAimCFrame and cachedAimPart and cachedAimPart.Parent then
        -- Hook de Cámara
        if self == cameraRef and key == "CFrame" then
            local originalCF = oldIndex(self, key)
            -- Mantenemos la posición original de la cámara, solo cambiamos hacia donde mira
            return CFrame.lookAt(originalCF.Position, cachedAimVector)
        -- Hook del Ratón
        elseif mouseRef and self == mouseRef then
            if key == "Hit" then 
                -- Retornamos un CFrame válido mirando desde la cámara al objetivo
                return CFrame.lookAt(cameraRef.CFrame.Position, cachedAimVector) 
            end
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
print("[Froggy Hub] SilentAim V17 (Modo Fantasma) instalado. Cero detección de Anti-Cheat.")

env.__BF_SA_CLEANUP = function()
    Config.Enabled = false
    fovGui:Destroy()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function()
        setreadonly(mt, false)
        mt.__index = oldIndex
        setreadonly(mt, true)
    end)
    env.BF_SA_CONFIG = nil
    env.__BF_SA_CLEANUP = nil
end
