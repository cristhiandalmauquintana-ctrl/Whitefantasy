--// Froggy Hub - ElementalMagicArena/AutoFarm.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local env = (getgenv and getgenv()) or _G

-- 1. CREAMOS LA CONFIGURACIÓN PARA EL MAIN
getgenv().BF_AUTOFARM_CONFIG = {
    Enabled = false,
    AutoEquip = true
}
local Config = getgenv().BF_AUTOFARM_CONFIG

-- 2. LÓGICA INTERNA
local function autoEquipWeapon()
    if not Config.AutoEquip then return end
    local char = LocalPlayer.Character
    if not char or char:FindFirstChildOfClass("Tool") then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") then
                char.Humanoid:EquipTool(item)
                break
            end
        end
    end
end

local function getClosestSoul()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 2000 
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("soul") then
            local isChar = false
            local parent = obj.Parent
            while parent and parent ~= Workspace do
                if parent:FindFirstChildOfClass("Humanoid") then isChar = true break end
                parent = parent.Parent
            end
            if not isChar then
                local d = (obj.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = obj end
            end
        end
    end
    return closest
end

local function getClosestEnemy()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, dist = nil, 300
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                local d = (head.Position - myRoot.Position).Magnitude
                if d < dist then dist = d; closest = head end
            end
        end
    end
    return closest
end

-- 3. LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then 
        -- Si se apaga, restauramos las colisiones
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        return 
    end
    
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    autoEquipWeapon()
    
    -- Modo Fantasma
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    
    -- Prioridad 1: Recoger Almas
    local soul = getClosestSoul()
    if soul then
        myRoot.CFrame = CFrame.new(soul.Position)
        myRoot.AssemblyLinearVelocity = Vector3.zero
        local prompt = soul:FindFirstChildOfClass("ProximityPrompt")
        if prompt then 
            fireproximityprompt(prompt) 
        else
            for _, child in ipairs(soul:GetChildren()) do
                if child:IsA("ProximityPrompt") then fireproximityprompt(child) end
            end
        end
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0,0))
        return 
    end
    
    -- Prioridad 2: Volar y matar
    local target = getClosestEnemy()
    if target then
        myRoot.CFrame = CFrame.new(target.Position + Vector3.new(0, 10, 0), target.Position)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end
end)

print("[AutoFarm] Módulo cargado y listo (Beta).")
