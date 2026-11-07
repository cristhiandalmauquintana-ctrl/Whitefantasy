--// Froggy Hub - ElementalMagicArena/AutoTournament.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_TOURNAMENT_CLEANUP then pcall(env.__BF_TOURNAMENT_CLEANUP) end

local Config = {
    Enabled = false
}
env.BF_TOURNAMENT_CONFIG = Config

local bodyPos = nil
local bodyGyro = nil
local stalkerCon = nil
local equipCon = nil

local function getEnemy()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                return p, root
            end
        end
    end
    return nil, nil
end

local function equipWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then 
                pcall(function() hum:EquipTool(tool) end)
                break 
            end
        end
    end
end

local function startTournament()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local oldBP = root:FindFirstChild("TourneyBP"); if oldBP then oldBP:Destroy() end
    local oldBG = root:FindFirstChild("TourneyBG"); if oldBG then oldBG:Destroy() end

    hum.PlatformStand = true
    root.Anchored = false

    bodyPos = Instance.new("BodyPosition")
    bodyPos.Name = "TourneyBP"
    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyPos.P = 50000
    bodyPos.D = 2000
    bodyPos.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "TourneyBG"
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 50000
    bodyGyro.D = 2000
    bodyGyro.Parent = root

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
    end

    if equipCon then task.cancel(equipCon) end
    equipCon = task.spawn(function()
        while Config.Enabled do
            if not LocalPlayer.Character:FindFirstChildOfClass("Tool") then equipWeapon() end
            if env.BF_ATTACKALL_CONFIG then env.BF_ATTACKALL_CONFIG.Enabled = true end
            task.wait(0.5)
        end
    end)

    if stalkerCon then task.cancel(stalkerCon) end
    stalkerCon = RunService.RenderStepped:Connect(function()
        if not Config.Enabled or not bodyPos or not bodyGyro then return end
        
        local c = LocalPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end

        local _, enemyRoot = getEnemy()
        if enemyRoot then
            local targetCFrame = enemyRoot.CFrame * CFrame.new(0, 10, 10)
            bodyPos.Position = targetCFrame.Position
            bodyGyro.CFrame = targetCFrame
        end
    end)
end

local function stopTournament()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root then
        local bp = root:FindFirstChild("TourneyBP"); if bp then bp:Destroy() end
        local bg = root:FindFirstChild("TourneyBG"); if bg then bg:Destroy() end
    end
    if hum then hum.PlatformStand = false end
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
        end
    end
    if stalkerCon then stalkerCon:Disconnect(); stalkerCon = nil end
    if equipCon then task.cancel(equipCon); equipCon = nil end
end

-- Bucle de control para el Hub
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled and not bodyPos then
            startTournament()
        elseif not Config.Enabled and bodyPos then
            stopTournament()
        end
    end
end)

env.__BF_TOURNAMENT_CLEANUP = function()
    Config.Enabled = false
    stopTournament()
    env.BF_TOURNAMENT_CONFIG = nil
    env.__BF_TOURNAMENT_CLEANUP = nil
end
