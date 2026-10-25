--// Froggy Hub - NearestKill.lua (Botón Flotante de Asesinato)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- Esperar a que el personaje esté cargado
local function getMyRoot()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

-- Función para buscar al enemigo más cercano
local function getClosestEnemy()
    local myRoot = getMyRoot()
    if not myRoot then return nil end

    local closest, dist = nil, 2000 -- Rango máximo de búsqueda (2000 studs)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = hrp
                end
            end
        end
    end
    return closest
end

-- Función para equipar la espada automáticamente
local function equipSword()
    local char = LP.Character
    if not char then return end
    
    -- Si ya tiene algo equipado, no hacemos nada
    if char:FindFirstChildOfClass("Tool") then return end
    
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            -- Busca espadas o armas elementales
            if name:find("sword") or name:find("light") or name:find("energy") or name:find("knife") then
                char.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end

-- ==========================================
-- INTERFAZ GRÁFICA (Botón Flotante)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyNearestKill"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = LP:WaitForChild("PlayerGui")

-- Marco principal del botón
local btnFrame = Instance.new("Frame")
btnFrame.Name = "KillButton"
btnFrame.Size = UDim2.fromOffset(70, 70)
btnFrame.Position = UDim2.new(1, -100, 0.5, -35) -- Aparece a la derecha
btnFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
btnFrame.BackgroundTransparency = 0.2
btnFrame.BorderSizePixel = 0
btnFrame.Active = true
btnFrame.Parent = gui

local corner = Instance.new("UICorner", btnFrame)
corner.CornerRadius = UDim.new(1, 0) -- Forma circular

-- Borde Neón
local stroke = Instance.new("UIStroke", btnFrame)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 50, 50) -- Rojo peligro
local gradient = Instance.new("UIGradient", stroke)
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 77, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
})

-- Icono central (Una espada dibujada con texto)
local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.fromScale(1, 1)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚔️"
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextSize = 30
iconLabel.Parent = btnFrame

-- Texto inferior
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0, 15)
textLabel.Position = UDim2.new(0, 0, 1, -15)
textLabel.BackgroundTransparency = 1
textLabel.Text = "KILL"
textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
textLabel.Font = Enum.Font.GothamBold
textLabel.TextSize = 10
textLabel.Parent = btnFrame

-- Efecto de pulso (Animación)
local tweenService = game:GetService("TweenService")
local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulseTween = tweenService:Create(stroke, pulseInfo, { Color = Color3.fromRGB(180, 77, 255) })
pulseTween:Play()

-- Hacer el botón arrastrable
local dragging = false
local dragInput, mousePos, framePos

btnFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = btnFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - mousePos
        btnFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- LÓGICA DE EJECUCIÓN
-- ==========================================
local isCooldown = false

btnFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isCooldown then return end -- Si está en cooldown, no hace nada

        local target = getClosestEnemy()
        if target then
            isCooldown = true
            
            -- 1. Equipar espada
            equipSword()
            
            -- 2. Teletransportarse al enemigo
            local myRoot = getMyRoot()
            if myRoot then
                -- Teletransporte un poco arriba para que el cuerpo choque con la hitbox
                myRoot.CFrame = target.CFrame * CFrame.new(0, 2, 0)
                myRoot.AssemblyLinearVelocity = Vector3.zero
            end
            
            -- 3. Feedback visual (Se pone verde y dice "KILLED")
            iconLabel.Text = "✅"
            textLabel.Text = "DONE"
            stroke.Color = Color3.fromRGB(50, 255, 50)
            
            -- 4. Cooldown de 1.5 segundos (tiempo para que la hitbox mate)
            task.wait(1.5)
            
            -- 5. Desactivar (Volver al estado original)
            iconLabel.Text = "⚔️"
            textLabel.Text = "KILL"
            stroke.Color = Color3.fromRGB(255, 50, 50)
            isCooldown = false
        else
            -- No hay enemigos
            textLabel.Text = "NONE"
            task.wait(1)
            textLabel.Text = "KILL"
        end
    end
end)

print("[NearestKill] Módulo cargado. Botón flotante listo.")
