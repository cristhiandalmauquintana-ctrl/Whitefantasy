--// Main.lua - FROGGY HUB (PANTALLA DE ACTUALIZACIÓN MULTI-IDIOMA / SEÑUELO)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 👇 CAMBIA ESTO POR TU LINK REAL DE DISCORD 👇
local DISCORD_LINK = "https://discord.gg/TU_LINK_AQUI" 

-- ==========================================
-- SISTEMA DE IDIOMAS AUTOMÁTICO
-- ==========================================
local Translations = {
    ["es"] = {
        title = "🐸 FROGGY HUB (ACTUALIZACIÓN)",
        desc = "El script ha sido movido a un nuevo repositorio por seguridad y por el ataque al servidor.\n\nPara obtener la nueva versión, ÚNETE OBLIGATORIAMENTE al Discord.",
        btn_copy = "📋 COPIAR LINK DE DISCORD",
        btn_copied = "¡COPIADO! VE A DISCORD AHORA",
        btn_fail = "No se pudo copiar."
    },
    ["en"] = {
        title = "🐸 FROGGY HUB (UPDATE)",
        desc = "The script has been moved to a new repository for security reasons and due to the server attack.\n\nTo get the new version, you MUST JOIN the Discord.",
        btn_copy = "📋 COPY DISCORD LINK",
        btn_copied = "COPIED! GO TO DISCORD NOW",
        btn_fail = "Could not copy."
    },
    ["fil"] = {
        title = "🐸 FROGGY HUB (UPDATE)",
        desc = "Ang script ay inilipat sa isang bagong repository para sa seguridad at dahil sa pag-atake sa server.\n\nUpang makuha ang bagong bersyon, KAILANGAN mong SUMALI sa Discord.",
        btn_copy = "📋 KOPYAHIN ANG DISCORD LINK",
        btn_copied = "NAKOPYA! PUMUNTA SA DISCORD NGAYON",
        btn_fail = "Hindi makopya."
    }
}

local currentLang = "en"
pcall(function()
    local id = LocalPlayer.LocaleId:lower()
    if id:find("es") then 
        currentLang = "es"
    elseif id:find("fil") or id:find("tl") then 
        currentLang = "fil"
    end
end)

local function L(key) 
    return Translations[currentLang][key] or Translations["en"][key] 
end

-- ==========================================
-- CREACIÓN DE LA UI KAWAII
-- ==========================================
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
mainFrame.Size = UDim2.fromOffset(320, 250)
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
title.Text = L("title")
title.TextColor3 = Color3.fromRGB(214, 84, 138)
title.Font = Enum.Font.FredokaOne
title.TextSize = 20
title.Parent = mainFrame

local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1, -40, 0, 100)
desc.Position = UDim2.fromOffset(20, 60)
desc.BackgroundTransparency = 1
desc.Text = L("desc")
desc.TextColor3 = Color3.fromRGB(88, 56, 108)
desc.Font = Enum.Font.GothamMedium
desc.TextSize = 14
desc.TextWrapped = true
desc.Parent = mainFrame

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.fromOffset(260, 45)
copyBtn.Position = UDim2.fromOffset(30, 170)
copyBtn.BackgroundColor3 = Color3.fromRGB(255, 128, 176)
copyBtn.Text = L("btn_copy")
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 15
copyBtn.Parent = mainFrame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DISCORD_LINK)
        copyBtn.Text = L("btn_copied")
        copyBtn.BackgroundColor3 = Color3.fromRGB(120, 226, 184)
    else
        copyBtn.Text = L("btn_fail")
    end
end)
