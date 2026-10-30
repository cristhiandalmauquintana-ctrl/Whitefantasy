--// Froggy Hub - ElementalMagicArena/AttackAll.lua (Módulo Independiente)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local env = (getgenv and getgenv()) or _G
if env.__BF_ATTACKALL_CLEANUP then pcall(env.__BF_ATTACKALL_CLEANUP) end

local Config = {
    Enabled = false,
    Size = 1000
}
env.BF_ATTACKALL_CONFIG = Config

local originalData = {}
local shieldedPlayersParts = {}
local honeypotParts = {}
local connections = {}

-- 🔥 BYPASSES
if getrawmetatable and newcclosure then
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.Enabled and (method == "PromptProductPurchase" or method == "PromptGamePassPurchase" or method == "PromptPurchase") then
            return nil 
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

local function hideUIFriendly(guiObj)
    if not Config.Enabled then return end
    if guiObj:IsA("ScreenGui") then
        local allowedGuis = { "Chat", "PlayerList", "Backpack", "Health", "Froggy", "TouchGui", "CoreGui" }
        local isAllowed = false
        for _, allowed in ipairs(allowedGuis) do
            if guiObj.Name:find(allowed) then isAllowed = true break end
        end
        if not isAllowed then
            for _, obj in ipairs(guiObj:GetDescendants()) do
                if obj:IsA("GuiObject") then
                    obj.BackgroundTransparency = 1
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextTransparency = 1
                    elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then obj.ImageTransparency = 1 end
                end
            end
        end
    end
end
table.insert(connections, PlayerGui.ChildAdded:Connect(hideUIFriendly))

-- Lógica del Handle
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

-- Bypasses optimizados (cada 0.5s)
task.spawn(function()
    while task.wait(0.5) do
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

-- Auto-Flicker (El truco del daño)
task.spawn(function()
    while task.wait() do
        if Config.Enabled then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                expandSword(tool)
                task.wait(0.25)
                restoreSword(tool)
                task.wait(0.25)
            else
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

env.__BF_ATTACKALL_CLEANUP = function()
    Config.Enabled = false
    for _, c in ipairs(connections) do c:Disconnect() end
    for p, parts in pairs(shieldedPlayersParts) do
        for part, data in pairs(parts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    end
    for part, data in pairs(honeypotParts) do if part and part.Parent then part.CanTouch = data.CanTouch; part.CanQuery = data.CanQuery end end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then restoreSword(tool) end
    env.BF_ATTACKALL_CONFIG = nil
    env.__BF_ATTACKALL_CLEANUP = nil
end
