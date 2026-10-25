--// Froggy Hub - NearestKill.lua (V4 - Modo Vampiro / Flotar hasta matar)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- Función para buscar al enemigo más cercano
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
                if d < dist then dist = d; closest = hrp end
            end
        end
    end
    return closest
end

-- Función para equipar la espada
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

-- ==========================================
-- INTERFAZ GRÁFICA (Botón Flotante)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyNearestKill"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = LP:WaitForChild("PlayerGui")

local btnFrame = Instance.new("Frame")
btnFrame.Name = "KillButton"
btnFrame.Size = UDim2.fromOffset(60, 60) 
btnFrame.Position = UDim2.new(1, -80, 1, -150) 
btnFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
btnFrame.BackgroundTransparency = 0.2
btnFrame.BorderSizePixel = 0
btnFrame.Active = true
btnFrame.Parent = gui

Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(1, 0)

local stroke = Instance.new("UIStroke", btnFrame)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 50, 50)

local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.fromScale(1, 1)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚔️"
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextSize = 28
iconLabel.Parent = btnFrame

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0, 12)
textLabel.Position = UDim2.new(0, 0, 1, -14)
textLabel.BackgroundTransparency = 1
textLabel.Text = "KILL"
textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
textLabel.Font = Enum.Font.GothamBold
textLabel.TextSize = 9
textLabel.Parent = btnFrame

-- Arrastrar el botón
local dragging = false
local dragInput, mousePos, framePos

btnFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = btnFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
-- LÓGICA DE EJECUCIÓN (MODO VAMPIRO)
-- ==========================================
local isRunning = false

btnFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isRunning then return end 
        
        local target = getClosestEnemy()
        if not target then
            textLabel.Text = "NONE"
            task.wait(1)
            textLabel.Text = "KILL"
            return
        end

        isRunning = true
        iconLabel.Text = "🩸"
        textLabel.Text = "LOCKED"
        stroke.Color = Color3.fromRGB(255, 100, 100)

        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChild("Humanoid")

        if myRoot and myHum then
            -- Equipar espada
            equipSword()

            -- 🔥 EL TRUCO: Desactivamos la gravedad (PlatformStand)
            myHum.PlatformStand = true

            local startTime = tick()
            -- Bucle infinito de pegamiento hasta que muera o pasen 3 segundos
            while isRunning and target and target.Parent do
                local targetHum = target.Parent and target.Parent:FindFirstChild("Humanoid")
                
                -- Si el enemigo murió, rompemos el bucle
                if not targetHum or targetHum.Health <= 0 then
                    break
                end

                -- Si pasa mucho tiempo (3 segundos), rompemos por seguridad
                if tick() - startTime > 3 then
                    break
                end

                -- Teletransportamos al jugador 3 studs arriba del enemigo (para que el cuerpo no se caiga)
                -- y forzamos el ataque con la espada
                local targetPos = target.Position + Vector3.new(0, 3, 0)
                myRoot.CFrame = CFrame.new(targetPos, target.Position)
                myRoot.AssemblyLinearVelocity = Vector3.zero

                -- Disparamos la espada (por si el roce no es suficiente)
                local tool = myChar:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end

                task.wait(0.05) -- Muy rápido para que el hitbox haga el combo
            end

            -- 🛑 FIN DEL BUCLE: Restauramos la gravedad
            if myHum then
                myHum.PlatformStand = false
            end
        end

        -- Resetear UI
        isRunning = false
        iconLabel.Text = "⚔️"
        textLabel.Text = "KILL"
        stroke.Color = Color3.fromRGB(255, 50, 50)
    end
end)

print("[NearestKill] Módulo cargado. Modo Vampiro listo.")
