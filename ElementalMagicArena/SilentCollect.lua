--// Froggy Hub - Silent Collect (Diamonds & Souls Fix)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_SILENTCOLLECT_CLEANUP then pcall(env.__BF_SILENTCOLLECT_CLEANUP) end

local Config = {
    Enabled = true,
    MaxDistance = 500,    
    CollectRate = 0.2     
}
env.BF_SILENTCOLLECT_CONFIG = Config

local DiamondNames = {"diamond", "gem", "coin", "cash", "drop", "reward", "loot", "money"}
local SoulNames = {"soul", "alma"}

local function isDiamond(obj)
    if not obj or not obj.Parent then return false end
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart")) then return false end
    if obj.Parent:FindFirstChildOfClass("Humanoid") then return false end
    local name = string.lower(obj.Name)
    if name:find("anticheat") or name:find("honeypot") then return false end
    for _, dName in ipairs(DiamondNames) do
        if name:find(dName) then return true end
    end
    return false
end

local function isSoulPrompt(obj)
    if not obj or not obj:IsA("ProximityPrompt") then return false end
    if not obj.Enabled then return false end
    local name = string.lower(obj.Name .. obj.ObjectText .. obj.ActionText)
    local isSoul = false
    for _, sName in ipairs(SoulNames) do
        if name:find(sName) then isSoul = true break end
    end
    if name:find("shop") or name:find("buy") or name:find("robux") or name:find("gacha") then return false end
    return isSoul
end

local function collectDrops()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Diamantes
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isDiamond(obj) then
            if (obj.Position - myRoot.Position).Magnitude <= Config.MaxDistance then
                pcall(function()
                    firetouchinterest(myRoot, obj, 0)
                    task.wait(0.01)
                    firetouchinterest(myRoot, obj, 1)
                end)
            end
        end
    end

    -- Almas
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isSoulPrompt(obj) then
            local part = obj.Parent
            local pos = part:IsA("BasePart") and part.Position or (part:IsA("Model") and part.PrimaryPart and part.PrimaryPart.Position)
            if pos and (pos - myRoot.Position).Magnitude <= Config.MaxDistance then
                pcall(function() fireproximityprompt(obj) end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(Config.CollectRate) do
        if Config.Enabled and LocalPlayer.Character then
            collectDrops()
        end
    end
end)

env.__BF_SILENTCOLLECT_CLEANUP = function()
    Config.Enabled = false
    env.BF_SILENTCOLLECT_CONFIG = nil
    env.__BF_SILENTCOLLECT_CLEANUP = nil
end
