--// Froggy Hub - NearestKill.lua (V6 - Config y Stop Fix)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_KILL_CLEANUP then pcall(env.__BF_KILL_CLEANUP) end

-- 🔥 NUEVO: Configuración para que el panel pueda controlarlo
local Config = { Enabled = false }
env.BF_KILL_CONFIG = Config

local isRunning = false
local lockedTarget = nil
local startTime = 0
local heartbeatConn = nil

local function getClosestEnemy()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 2000 
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = p end
            end
        end
    end
    return closest
end

local function equipSword()
    local char = LP.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") then
                char.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end

local function stopKill()
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    isRunning = false
    lockedTarget = nil
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function executeKill()
    local targetPlayer = getClosestEnemy()
    if not targetPlayer then return end

    isRunning = true
    lockedTarget = targetPlayer
    startTime = tick()
    
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

    if not myRoot or not myHum then stopKill() return end

    equipSword()
    myHum.PlatformStand = true

    heartbeatConn = RunService.Heartbeat:Connect(function()
        -- 🛑 FIX: Si el toggle se apaga, detenemos todo inmediatamente
        if not Config.Enabled or not isRunning or not lockedTarget or not lockedTarget.Character then
            stopKill() return
        end

        local targetHum = lockedTarget.Character:FindFirstChild("Humanoid")
        local targetRoot = lockedTarget.Character:FindFirstChild("HumanoidRootPart")

        if not targetHum or targetHum.Health <= 0 or not targetRoot then
            stopKill() return
        end

        if tick() - startTime > 3 then
            stopKill() return
        end

        equipSword()
        
        -- Se pega al jugador
        local targetPos = targetRoot.Position
        local newCFrame = CFrame.lookAt(targetPos - targetRoot.CFrame.LookVector * 3, targetPos)
        myRoot.CFrame = newCFrame
        myRoot.AssemblyLinearVelocity = Vector3.zero
        
        local tool = myChar:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
    end)
end

-- UI del botón (Se mantiene igual)
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyNearestKill"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

local btnFrame = Instance.new("TextButton")
btnFrame.Size = UDim2.fromOffset(60, 60) 
btnFrame.Position = UDim2.new(1, -80, 1, -150) 
btnFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
btnFrame.Text = "KILL"
btnFrame.TextColor3 = Color3.fromRGB(255, 50, 50)
btnFrame.Visible = Config.Enabled -- Solo visible si está activo
btnFrame.Parent = gui

btnFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isRunning then return end 
        executeKill()
    end
end)

-- Ocultar/Mostrar botón según el toggle
RunService.Heartbeat:Connect(function()
    btnFrame.Visible = Config.Enabled
    if not Config.Enabled then stopKill() end
end)

LP.CharacterAdded:Connect(function() stopKill() end)

env.__BF_KILL_CLEANUP = function()
    stopKill()
    gui:Destroy()
    env.BF_KILL_CONFIG = nil
    env.__BF_KILL_CLEANUP = nil
end
