--// Main.lua - FROGGY HUB (PANTALLA DE ACTUALIZACIÓN / SEÑUELO)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 👇 CAMBIA ESTO POR TU LINK REAL DE DISCORD 👇
local DISCORD_LINK = "https://discord.gg/xXPfWMgTR" 

-- Crear UI
local gui = Instance.new("ScreenGui")
gui.Name = "FroggyUpdateNotice"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
bg.BackgroundTransparency = 0.3
bg.BorderSizePixel = 0
bg.Parent = gui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(320, 240)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 240, 250)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = bg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 128, 176)
stroke.Thickness = 3
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.fromOffset(10, 15)
title.BackgroundTransparency = 1
title.Text = "🐸 FROGGY HUB (ACTUALIZACIÓN)"
title.TextColor3 = Color3.fromRGB(214, 84, 138)
title.Font = Enum.Font.FredokaOne
title.TextSize = 20
title.Parent = mainFrame

local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1, -40, 0, 80)
desc.Position = UDim2.fromOffset(20, 60)
desc.BackgroundTransparency = 1
desc.Text = "El script ha sido movido a un nuevo repositorio por seguridad y por el ataque al servidor.\n\nPara obtener la nueva versión, ÚNETE OBLIGATORIAMENTE al Discord."
desc.TextColor3 = Color3.fromRGB(88, 56, 108)
desc.Font = Enum.Font.GothamMedium
desc.TextSize = 14
desc.TextWrapped = true
desc.Parent = mainFrame

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.fromOffset(260, 45)
copyBtn.Position = UDim2.fromOffset(30, 160)
copyBtn.BackgroundColor3 = Color3.fromRGB(255, 128, 176)
copyBtn.Text = "📋 COPIAR LINK DE DISCORD"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 15
copyBtn.Parent = mainFrame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DISCORD_LINK)
        copyBtn.Text = "¡COPIADO! VE A DISCORD AHORA"
        copyBtn.BackgroundColor3 = Color3.fromRGB(120, 226, 184)
    else
        copyBtn.Text = "No se pudo copiar. Link en el Discord."
    end
end)
