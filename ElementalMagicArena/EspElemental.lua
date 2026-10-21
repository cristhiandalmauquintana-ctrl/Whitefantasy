--// Froggy Hub - ESP para Elemental Magic Arena
--// Muestra Jugador, Vida, Elemento y Rareza. También resalta Diamantes y el Orbe del Vacío.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

--// Configuración (Se puede exponer al Main.lua si se desea)
local Config = {
    Enabled = true,
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowElement = true,
    ShowDiamonds = true,
    ShowVoidOrb = true,
    MaxDistance = 2000,
    ColorByRarity = true,
}

--// Lista de Elementos y su Rareza (Basado en la Wiki del juego)
local ElementRarity = {
    -- Comunes / Starters
    ["Fire"] = {Rarity = "Starter", Color = Color3.fromRGB(255, 100, 100)},
    ["Water"] = {Rarity = "Starter", Color = Color3.fromRGB(100, 150, 255)},
    ["Earth"] = {Rarity = "Starter", Color = Color3.fromRGB(150, 100, 50)},
    ["Air"] = {Rarity = "Starter", Color = Color3.fromRGB(200, 200, 200)},
    -- Comunes
    ["Lightning"] = {Rarity = "Common", Color = Color3.fromRGB(255, 255, 100)},
    ["Ice"] = {Rarity = "Common", Color = Color3.fromRGB(150, 255, 255)},
    ["Nature"] = {Rarity = "Common", Color = Color3.fromRGB(100, 255, 100)},
    -- Raros
    ["Shadow"] = {Rarity = "Rare", Color = Color3.fromRGB(100, 0, 150)},
    ["Light"] = {Rarity = "Rare", Color = Color3.fromRGB(255, 255, 200)},
    ["Plasma"] = {Rarity = "Rare", Color = Color3.fromRGB(255, 0, 255)}, -- 1 en 7,899
    -- Épicos
    ["Void"] = {Rarity = "Epic", Color = Color3.fromRGB(50, 0, 100)},
    ["Chaos"] = {Rarity = "Epic", Color = Color3.fromRGB(200, 0, 0)},
    ["Necromancy"] = {Rarity = "Epic", Color = Color3.fromRGB(80, 80, 80)},
    -- Legendarios
    ["Time"] = {Rarity = "Legendary", Color = Color3.fromRGB(255, 215, 0)},
    ["Astral"] = {Rarity = "Legendary", Color = Color3.fromRGB(200, 200, 255)},
    ["Dragon"] = {Rarity = "Legendary", Color = Color3.fromRGB(255, 50, 50)}, -- 1 en 10,800
    -- Otros
    ["Default"] = {Rarity = "Unknown", Color = Color3.fromRGB(255, 255, 255)},
}

--// Almacén de objetos visuales
local Objects = {} -- [Player] = {Billboard, Box, Stroke, BarBg, BarFill}
local DiamondObjects = {} -- [Instance] = {Billboard, Box}
local VoidOrbObject = nil

--// Función para obtener el elemento del jugador
local function getPlayerElement(player)
    -- 1. Intentar leer un atributo del jugador (común en juegos de Roblox)
    local ok, element = pcall(function() return player:GetAttribute("Element") end)
    if ok and element then return element end

    -- 2. Buscar un objeto llamado "Element" dentro del personaje
    local char = player.Character
    if char then
        local elemObj = char:FindFirstChild("Element")
        if elemObj then
            if elemObj:IsA("StringValue") then return elemObj.Value end
            if elemObj:IsA("ObjectValue") and elemObj.Value then return elemObj.Value.Name end
        end
    end
    return "Default"
end

--// Función para crear la interfaz de un jugador
local function createPlayerESP(player)
    if player == LocalPlayer or Objects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ElemESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(200, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Enabled = false
    billboard.Parent = game:GetService("CoreGui")

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Parent = billboard

    local infoLabel = Instance.new("TextLabel")
    infoLabel.BackgroundTransparency = 1
    infoLabel.Position = UDim2.new(0, 0, 0.4, 0)
    infoLabel.Size = UDim2.new(1, 0, 0.4, 0)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextStrokeTransparency = 0.3
    infoLabel.Parent = billboard

    -- Caja 2D
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = game:GetService("CoreGui")

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Parent = box

    -- Barra de Vida
    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.35
    barBg.BorderSizePixel = 0
    barBg.Visible = false
    barBg.Parent = game:GetService("CoreGui")

    local barFill = Instance.new("Frame")
    barFill.AnchorPoint = Vector2.new(0, 1)
    barFill.Position = UDim2.fromScale(0, 1)
    barFill.Size = UDim2.fromScale(1, 1)
    barFill.BorderSizePixel = 0
    barFill.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
    barFill.Parent = barBg

    Objects[player] = {
        Billboard = billboard,
        NameLabel = nameLabel,
        InfoLabel = infoLabel,
        Box = box,
        BoxStroke = boxStroke,
        BarBg = barBg,
        BarFill = barFill,
    }
end

--// Función para crear ESP de objetos (Diamantes / Orbe)
local function createItemESP(item, isOrb)
    if not item or not item:IsA("BasePart") then return end
    if DiamondObjects[item] or (isOrb and VoidOrbObject) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ItemESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(100, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Enabled = false
    billboard.Parent = game:GetService("CoreGui")

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = isOrb and Color3.fromRGB(200, 0, 255) or Color3.fromRGB(0, 255, 255)
    label.TextStrokeTransparency = 0.3
    label.Text = isOrb and "🔮 ORBE DEL VACÍO" or "💎 Diamante"
    label.Parent = billboard

    local data = {Billboard = billboard}
    if isOrb then
        VoidOrbObject = data
    else
        DiamondObjects[item] = data
    end
end

--// Loop de Actualización
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        for _, data in pairs(Objects) do
            data.Billboard.Enabled = false
            data.Box.Visible = false
            data.BarBg.Visible = false
        end
        for _, data in pairs(DiamondObjects) do data.Billboard.Enabled = false end
        if VoidOrbObject then VoidOrbObject.Billboard.Enabled = false end
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    -- 1. Actualizar Jugadores
    for player, data in pairs(Objects) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        local visible = root and hum and hum.Health > 0
        if visible and myRoot then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist > Config.MaxDistance then visible = false end
        end

        data.Billboard.Enabled = visible
        if visible then
            local elementName = getPlayerElement(player)
            local elemData = ElementRarity[elementName] or ElementRarity["Default"]

            -- Actualizar Texto
            data.NameLabel.Text = player.Name
            data.InfoLabel.Text = string.format("[%s] %s", elemData.Rarity, elementName)
            
            if Config.ColorByRarity then
                data.NameLabel.TextColor3 = elemData.Color
                data.BoxStroke.Color = elemData.Color
            end

            -- Posición en pantalla
            local top = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
            local bottom = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            
            if top.Z > 0 and bottom.Z > 0 then
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.55
                local cx = (top.X + bottom.X) / 2
                local cy = (top.Y + bottom.Y) / 2

                if Config.ShowBox then
                    data.Box.Size = UDim2.fromOffset(width, height)
                    data.Box.Position = UDim2.fromOffset(cx, cy)
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end

                if Config.ShowHealth then
                    local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    data.BarBg.Size = UDim2.fromOffset(4, height)
                    data.BarBg.Position = UDim2.fromOffset(cx - width / 2 - 6, cy)
                    data.BarFill.Size = UDim2.fromScale(1, ratio)
                    data.BarFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                    data.BarBg.Visible = true
                else
                    data.BarBg.Visible = false
                end
            else
                data.Box.Visible = false
                data.BarBg.Visible = false
            end
        end
    end

    -- 2. Actualizar Diamantes y Orbe
    if Config.ShowDiamonds then
        for _, item in ipairs(Workspace:GetChildren()) do
            if item:IsA("BasePart") and (string.find(item.Name, "Diamond") or string.find(item.Name, "Gem")) then
                if not DiamondObjects[item] then createItemESP(item, false) end
            end
        end
        for item, data in pairs(DiamondObjects) do
            if not item or not item.Parent then
                data.Billboard:Destroy()
                DiamondObjects[item] = nil
            else
                data.Billboard.Adornee = item
                data.Billboard.Enabled = true
            end
        end
    end

    if Config.ShowVoidOrb then
        local orb = Workspace:FindFirstChild("VoidOrb") or Workspace:FindFirstChild("Void Orb")
        if orb and orb:IsA("BasePart") then
            if not VoidOrbObject then createItemESP(orb, true) end
            if VoidOrbObject then
                VoidOrbObject.Billboard.Adornee = orb
                VoidOrbObject.Billboard.Enabled = true
            end
        else
            if VoidOrbObject then VoidOrbObject.Billboard.Enabled = false end
        end
    end
end)

--// Gestión de Jugadores
for _, player in ipairs(Players:GetPlayers()) do createPlayerESP(player) end
Players.PlayerAdded:Connect(createPlayerESP)

print("[Froggy Hub] ESP para Elemental Magic Arena cargado.")
