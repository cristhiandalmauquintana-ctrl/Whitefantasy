--// Froggy Hub - ElementalMagicArena/NoPopUps.lua (ALL-IN-ONE SHIELD)
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_NOPOPUPS_CLEANUP then pcall(env.__BF_NOPOPUPS_CLEANUP) end

local Config = { Enabled = false }
env.BF_NOPOPUPS_CONFIG = Config

local connections = {}
local GROUP_NAME = "FroggySword"

-- ==========================================
-- 1. ESPADA FANTASMA (COLLISION GROUPS)
-- ==========================================
pcall(function()
    PhysicsService:RegisterCollisionGroup(GROUP_NAME)
    PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, "Default", false)
end)

local function applyGhostGroup(tool)
    if not tool or not tool:IsA("Tool") then return end
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                PhysicsService:SetPartCollisionGroup(part, GROUP_NAME)
            end)
        end
    end
end

-- ==========================================
-- 2. SNIPER UI (HALLOWEEN, DUELOS Y ROBUX)
-- ==========================================
local function isBadText(text)
    local txt = string.lower(text)
    return txt:find("halloween") or txt:find("duel") or txt:find("1v1") or 
           txt:find("arena") or txt:find("robux") or txt:find("gem") or 
           txt:find("buy") or txt:find("comprar") or txt:find("shop")
end

local function snipeGUI(container)
    if not Config.Enabled or not container then return end
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if isBadText(obj.Text) then
                local parent = obj.Parent
                -- Buscamos el Frame principal (evitando borrar nuestra propia UI)
                while parent and not parent:IsA("ScreenGui") and parent ~= LocalPlayer:FindFirstChild("PlayerGui") do
                    if parent:IsA("Frame") and (parent.Size.X.Scale > 0.3 or parent.Size.X.Offset > 200) then
                        if not string.find(string.lower(parent.Name), "froggy") then
                            parent:Destroy()
                            break
                        end
                    end
                    parent = parent.Parent
                end
            end
        end
    end
end

-- ==========================================
-- 3. LÓGICA DE ACTIVACIÓN
-- ==========================================
local function startShield()
    -- Escuchar armas equipadas
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
        if Config.Enabled then
            char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") and Config.Enabled then
                    applyGhostGroup(child)
                end
            end)
        end
    end))

    -- Escuchar ventanas nuevas
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        table.insert(connections, pg.DescendantAdded:Connect(function()
            task.defer(function() snipeGUI(pg) end)
        end))
    end
    local cg = game:GetService("CoreGui")
    if cg then
        table.insert(connections, cg.DescendantAdded:Connect(function()
            task.defer(function() snipeGUI(cg) end)
        end))
    end

    print("[Froggy] All-in-One Shield Activado.")
end

local function stopShield()
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    connections = {}
    print("[Froggy] All-in-One Shield Desactivado.")
end

-- ==========================================
-- BUCLE PRINCIPAL (Aplica el grupo fantasma constantemente)
-- ==========================================
local oldEnabled = false
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not oldEnabled then
                oldEnabled = true
                startShield()
            end
            
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                applyGhostGroup(tool)
            end
            
            -- Escaneo pasivo por si el DescendantAdded falla en alguna UI
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then snipeGUI(pg) end
            
        elseif not Config.Enabled and oldEnabled then
            oldEnabled = false
            stopShield()
        end
    end
end)

env.__BF_NOPOPUPS_CLEANUP = function()
    Config.Enabled = false
    stopShield()
    env.BF_NOPOPUPS_CONFIG = nil
    env.__BF_NOPOPUPS_CLEANUP = nil
end
