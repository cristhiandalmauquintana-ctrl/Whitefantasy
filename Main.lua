--// Main.lua - FROGGY HUB | MODO SUPERVIVENCIA (Sin diseño de Claude)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Limpieza
for _, obj in ipairs(CoreGui:GetChildren()) do
    if obj.Name == "FroggyBasic" then obj:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "FroggyBasic"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

-- ==========================================
-- 1. SELECTOR DE JUEGO
-- ==========================================
local prompt = Instance.new("Frame")
prompt.Size = UDim2.fromOffset(300, 200)
prompt.Position = UDim2.fromScale(0.5, 0.5)
prompt.AnchorPoint = Vector2.new(0.5, 0.5)
prompt.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
prompt.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "SELECCIONA EL JUEGO"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = prompt

local btnElem = Instance.new("TextButton")
btnElem.Size = UDim2.fromOffset(200, 40)
btnElem.Position = UDim2.new(0.5, 0, 0, 60)
btnElem.AnchorPoint = Vector2.new(0.5, 0)
btnElem.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
btnElem.Text = "Elemental Magic Arena"
btnElem.TextColor3 = Color3.new(1, 1, 1)
btnElem.Font = Enum.Font.SourceSansBold
btnElem.TextSize = 16
btnElem.Parent = prompt

local btnBlox = Instance.new("TextButton")
btnBlox.Size = UDim2.fromOffset(200, 40)
btnBlox.Position = UDim2.new(0.5, 0, 0, 120)
btnBlox.AnchorPoint = Vector2.new(0.5, 0)
btnBlox.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
btnBlox.Text = "Blox Fruits"
btnBlox.TextColor3 = Color3.new(1, 1, 1)
btnBlox.Font = Enum.Font.SourceSansBold
btnBlox.TextSize = 16
btnBlox.Parent = prompt

local selectedGame = nil

-- ==========================================
-- 2. CARGA DE MÓDULOS
-- ==========================================
local function loadScript(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and #res > 0 and res:sub(1, 3) ~= "404" then
        local fn = loadstring(res)
        if fn then pcall(fn) end
    end
end

local function startHub(gameFolder, gameName)
    prompt:Destroy()
    
    local loading = Instance.new("TextLabel")
    loading.Size = UDim2.fromScale(1, 1)
    loading.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    loading.Text = "CARGANDO " .. string.upper(gameName) .. "...\nPor favor espera."
    loading.TextColor3 = Color3.fromRGB(110, 220, 90)
    loading.Font = Enum.Font.SourceSansBold
    loading.TextSize = 30
    loading.Parent = gui
    
    local baseUrl = "https://raw.githubusercontent.com/cristhiandalmauquintana-ctrl/Whitefantasy/main/"
    if gameFolder == "ElementalMagicArena" then
        baseUrl = baseUrl .. "ElementalMagicArena/"
    end

    task.spawn(function()
        -- Cargar God Mode
        loadScript(baseUrl .. "GodMode.lua")
        task.wait(0.5)
        -- Cargar Hitbox
        loadScript(baseUrl .. "HitboxExpander.lua")
        task.wait(0.5)
        -- Cargar AutoCombat (Solo si es Elemental)
        if gameFolder == "ElementalMagicArena" then
            loadScript(baseUrl .. "AutoCombat.lua")
            task.wait(0.5)
            loadScript(baseUrl .. "EspElemental.lua")
        else
            loadScript(baseUrl .. "Esp.lua")
        end
        task.wait(0.5)
        
        loading:Destroy()
        createPanel()
    end)
end

-- ==========================================
-- 3. PANEL FEO Y FUNCIONAL
-- ==========================================
local function createPanel()
    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(300, 350)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    panel.Parent = gui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(110, 220, 90)
    stroke.Thickness = 2
    stroke.Parent = panel
    
    local topText = Instance.new("TextLabel")
    topText.Size = UDim2.new(1, 0, 0, 40)
    topText.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    topText.Text = "FROGGY HUB v12.0 (TEST)"
    topText.TextColor3 = Color3.fromRGB(110, 220, 90)
    topText.Font = Enum.Font.SourceSansBold
    topText.TextSize = 18
    topText.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 500)
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    -- Función para crear botones (Toggles)
    local function createToggle(text, config, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.Text = text .. ": OFF"
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 16
        btn.Parent = scroll

        btn.MouseButton1Click:Connect(function()
            if config and config[key] ~= nil then
                config[key] = not config[key]
                if config[key] then
                    btn.Text = text .. ": ON"
                    btn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
                else
                    btn.Text = text .. ": OFF"
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                end
            else
                warn("Configuración no cargada para: " .. text)
            end
        end)
    end

    -- Obtener configuraciones globales
    local espConfig = _G.BF_ESP_CONFIG or (getgenv() and getgenv().BF_ESP_CONFIG)
    local hitboxConfig = _G.BF_HITBOX_CONFIG or (getgenv() and getgenv().BF_HITBOX_CONFIG)
    local combatConfig = _G.BF_COMBAT_CONFIG or (getgenv() and getgenv().BF_COMBAT_CONFIG)
    local godConfig = _G.BF_GODMODE_CONFIG or (getgenv() and getgenv().BF_GODMODE_CONFIG)

    -- Crear los botones
    createToggle("ESP (Cajas)", espConfig, "Enabled")
    createToggle("Hitbox Expander", hitboxConfig, "Enabled")
    createToggle("Auto Combat", combatConfig, "Enabled")
    createToggle("God Mode", godConfig, "Enabled")

    -- Botón para Cerrar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(100, 30)
    closeBtn.Position = UDim2.new(1, -110, 1, -40)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "CERRAR"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.Parent = panel

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

-- Conexiones de los botones del selector
btnElem.MouseButton1Click:Connect(function()
    selectedGame = "ElementalMagicArena"
    startHub(selectedGame, "Elemental Magic Arena")
end)

btnBlox.MouseButton1Click:Connect(function()
    selectedGame = "BloxFruits"
    startHub(selectedGame, "Blox Fruits")
end)

print("✅ Selector cargado. Elige un juego.")
