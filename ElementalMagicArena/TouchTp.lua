--// Froggy Hub - ElementalMagicArena/TouchTP.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.__BF_TOUCHTP_CLEANUP then pcall(env.__BF_TOUCHTP_CLEANUP) end

local Config = {
    Enabled = false,
    TP_Mode_Active = false,
    FloatingGui = nil,
    Connections = {}
}

env.BF_TOUCHTP_CONFIG = Config

-- ==========================================
-- EFECTO DE SOMBRA (AFTERIMAGE)
-- ==========================================
local function createAfterimage(character, oldPosition)
    if not character then return end
    task.spawn(function()
        pcall(function()
            local clone = character:Clone()
            clone.Name = "FroggyShadow"
            
            local hum = clone:FindFirstChildOfClass("Humanoid")
            if hum then hum:Destroy() end
            
            for _, child in ipairs(clone:GetDescendants()) do
                if child:IsA("Script") or child:IsA("LocalScript") then child:Destroy() end
            end

            local root = clone:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = oldPosition end
            
            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                    part.CanCollide = false
                    part.CanQuery = false
                    part.CanTouch = false
                    part.Material = Enum.Material.Neon
                    part.Color = Color3.fromRGB(120, 226, 184) -- Verde Menta
                    part.Transparency = 0.5
                elseif part:IsA("Decal") or part:IsA("Texture") or part:IsA("BillboardGui") then
                    part:Destroy()
                end
            end
            
            clone.Parent = workspace
            
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart") then
                    TweenService:Create(part, tweenInfo, {Transparency = 1}):Play()
                end
            end
            
            task.delay(0.5, function() if clone then clone:Destroy() end end)
        end)
    end)
end

-- ==========================================
-- LÓGICA DEL TELETRANSPORTE
-- ==========================================
local function performTeleport(position)
    if not Config.TP_Mode_Active then return end 

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    local ray = Camera:ViewportPointToRay(position.X, position.Y)
    local rayParams = RaycastParams.new()
    
    local filterList = {char}
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "FroggyShadow" then table.insert(filterList, obj) end
    end
    
    rayParams.FilterDescendantsInstances = filterList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, rayParams)

    if result and result.Instance then
        local oldPos = root.CFrame
        root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
        createAfterimage(char, oldPos)
    end
end

table.insert(Config.Connections, UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
    if processedByUI then return end
    performTeleport(position)
end))

-- ==========================================
-- BOTÓN FLOTANTE
-- ==========================================
local function createFloatingButton()
    if Config.FloatingGui then Config.FloatingGui:Destroy() end
    
    local FloatingGui = Instance.new("ScreenGui")
    FloatingGui.Name = "FroggyTPButton"
    FloatingGui.ResetOnSpawn = false
    FloatingGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    Config.FloatingGui = FloatingGui

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.fromOffset(70, 70)
    ToggleBtn.Position = UDim2.new(0.8, 0, 0.4, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 96, 110)
    ToggleBtn.Text = "TP: OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.FredokaOne
    ToggleBtn.TextSize = 16
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Parent = FloatingGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ToggleBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 3
    stroke.Parent = ToggleBtn

    local dragging, dragInput, dragStart, startPos
    table.insert(Config.Connections, ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ToggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    
    table.insert(Config.Connections, ToggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end))
    
    table.insert(Config.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    table.insert(Config.Connections, ToggleBtn.MouseButton1Click:Connect(function()
        Config.TP_Mode_Active = not Config.TP_Mode_Active
        if Config.TP_Mode_Active then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 226, 184)
            ToggleBtn.Text = "TP: ON"
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 96, 110)
            ToggleBtn.Text = "TP: OFF"
        end
    end))
end

-- ==========================================
-- CONTROL DE ENCENDIDO / APAGADO
-- ==========================================
local function setEnabled(state)
    Config.Enabled = state
    if state then
        createFloatingButton()
    else
        if Config.FloatingGui then Config.FloatingGui:Destroy() Config.FloatingGui = nil end
        Config.TP_Mode_Active = false
    end
end

-- Exponer la función para el Main.lua
Config.SetEnabled = setEnabled

-- ==========================================
-- LIMPIEZA
-- ==========================================
env.__BF_TOUCHTP_CLEANUP = function()
    Config.Enabled = false
    if Config.FloatingGui then Config.FloatingGui:Destroy() Config.FloatingGui = nil end
    for _, conn in ipairs(Config.Connections) do pcall(function() conn:Disconnect() end) end
    Config.Connections = {}
    env.BF_TOUCHTP_CONFIG = nil
    env.__BF_TOUCHTP_CLEANUP = nil
end
