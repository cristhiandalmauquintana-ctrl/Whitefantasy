--// Froggy Hub - ElementalMagicArena/AttackAll.lua (V17 - STABLE)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_ATTACKALL_CLEANUP then pcall(env.__BF_ATTACKALL_CLEANUP) end

local Config = { Enabled = false, Size = 1000 }
env.BF_ATTACKALL_CONFIG = Config

local TargetPos = Vector3.new(816.06640625, -14.519143104553223, 37.429420471191409)

local originalData = {}
local shieldedPlayersParts = {}
local purgedParts = {}
local honeypotParts = {}

if hookfunction then
    hookfunction(MarketplaceService.PromptProductPurchase, function() return end)
    hookfunction(MarketplaceService.PromptGamePassPurchase, function() return end)
end

local function killTouch(obj)
    if obj:IsA("BasePart") then
        obj.CanTouch = false
        obj.CanQuery = false
    elseif obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
        if not purgedParts[obj] then
            purgedParts[obj] = { Enabled = obj.Enabled, MaxDist = obj.MaxActivationDistance }
        end
        obj.Enabled = false
        obj.MaxActivationDistance = 0
    end
end

local function globalPurge()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isChar = obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")
            local isTPS = obj:IsDescendantOf(Workspace:FindFirstChild("TPS"))
            if obj.Anchored and not isChar and not isTPS then
                if not purgedParts[obj] then purgedParts[obj] = { CanTouch = obj.CanTouch, CanQuery = obj.CanQuery } end
                killTouch(obj)
            end
        elseif (obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector")) then
            local isTPS = obj:IsDescendantOf(Workspace:FindFirstChild("TPS"))
            if not isTPS then
                local pName = string.lower(obj.Name .. (obj.Parent and obj.Parent.Name or ""))
                if not pName:find("soul") and not pName:find("alma") then
                    killTouch(obj)
                end
            end
        end
    end
end

local function getHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

local function expandSword(tool)
    local handle = getHandle(tool)
    if not handle then return end
    if not originalData[handle] then
        originalData[handle] = { Size = handle.Size, Transparency = handle.Transparency, CanCollide = handle.CanCollide, Massless = handle.Massless, CanTouch = handle.CanTouch }
    end
    handle.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    handle.Transparency = 1 
    handle.CanCollide = false 
    handle.Massless = true
    handle.CanTouch = true
end

local function restoreSword(tool)
    local handle = getHandle(tool)
    if not handle or not originalData[handle] then return end
    local data = originalData[handle]
    handle.Size = data.Size
    handle.Transparency = data.Transparency
    handle.CanCollide = data.CanCollide
    handle.Massless = data.Massless
    handle.CanTouch = data.CanTouch
    originalData[handle] = nil
end

LocalPlayer.CharacterAdded:Connect(function()
    originalData = {}
    if Config.Enabled then
        task.wait(1.5) 
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if myRoot then
            myRoot.CFrame = CFrame.new(TargetPos + Vector3.new(0, 3, 0))
            task.wait(0.5)
            local tpsFolder = Workspace:FindFirstChild("TPS")
            if tpsFolder then
                local closestTele = nil
                for _, obj in ipairs(tpsFolder:GetDescendants()) do
                    if obj:IsA("BasePart") and string.lower(obj.Name) == "teleporter" then
                        closestTele = obj; break
                    end
                end
                if closestTele and getconnections then
                    for _, conn in pairs(getconnections(closestTele.Touched)) do
                        if conn.Enabled then pcall(function() conn:Fire(myRoot) end) end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if Config.Enabled then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                expandSword(tool)
                task.wait(0.25)
                restoreSword(tool)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.Enabled then
            globalPurge() 
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hasShield = p.Character:FindFirstChildOfClass("ForceField") or (p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid:FindFirstChildOfClass("ForceField"))
                    if hasShield then
                        if not shieldedPlayersParts[p] then shieldedPlayersParts[p] = {} end
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") and not shieldedPlayersParts[p][part] then
                                shieldedPlayersParts[p][part] = { CanTouch = part.CanTouch, CanQuery = part.CanQuery }
                                part.CanTouch = false; part.CanQuery = false
                            end
                        end
                    elseif shieldedPlayersParts[p] then
                        for part, data in pairs(shieldedPlayersParts[p]) do
                            if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end
                        end
                        shieldedPlayersParts[p] = nil
                    end
                end
            end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local name = string.lower(obj.Name)
                    if name:find("anticheat") or name:find("anti-cheat") or name:find("ac_npc") or name:find("honeypot") or name:find("trap") then
                        if obj:IsA("BasePart") then
                            if not honeypotParts[obj] then honeypotParts[obj] = { CanTouch = obj.CanTouch, CanQuery = obj.CanQuery }; obj.CanTouch = false; obj.CanQuery = false end
                        else
                            for _, part in ipairs(obj:GetDescendants()) do
                                if part:IsA("BasePart") and not honeypotParts[part] then honeypotParts[part] = { CanTouch = part.CanTouch, CanQuery = part.CanQuery }; part.CanTouch = false; part.CanQuery = false end
                            end
                        end
                    end
                end
            end
        end
    end
end)

env.__BF_ATTACKALL_CLEANUP = function()
    Config.Enabled = false
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then restoreSword(tool) end
    
    for p, parts in pairs(shieldedPlayersParts) do
        for part, data in pairs(parts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    end
    for part, data in pairs(honeypotParts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    for obj, data in pairs(purgedParts) do
        if obj and obj.Parent then
            if obj:IsA("BasePart") then
                obj.CanTouch = data.CanTouch; obj.CanQuery = data.CanQuery
            elseif obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                obj.Enabled = data.Enabled
                obj.MaxActivationDistance = data.MaxDist
            end
        end
    end
    
    env.BF_ATTACKALL_CONFIG = nil
    env.__BF_ATTACKALL_CLEANUP = nil
end
