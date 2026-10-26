--[[
    Froggy Hub - Modo Mantenimiento
    Script independiente (sin librerías externas).
    Uso: loadstring(game:HttpGet("URL_DE_ESTE_ARCHIVO"))()
]]

local ok, err = pcall(function()
    ----------------------------------------------------------------
    -- Servicios
    ----------------------------------------------------------------
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local StarterGui = game:GetService("StarterGui")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Configuración
    ----------------------------------------------------------------
    local GUI_NAME = "FroggyHubMaintenance"
    local LOGO_URL = "https://raw.githubusercontent.com/cristhiandalmauquintana-ctrl/Whitefantasy/main/logo.png"
    local LOGO_FILE = "FroggyHub_logo.png"
    local TIKTOK_LINK = "https://tiktok.com/@user879619640"
    local DISCORD_LINK = "https://discord.com/channels/1562554522134380544/1562554674123378769"

    local COLORS = {
        Background = Color3.fromRGB(16, 16, 22),
        Button = Color3.fromRGB(24, 24, 32),
        Green = Color3.fromRGB(110, 220, 90),
        Pink = Color3.fromRGB(255, 50, 100),
        White = Color3.fromRGB(255, 255, 255),
        Gray = Color3.fromRGB(190, 190, 200),
        DarkGray = Color3.fromRGB(130, 130, 145),
        RedDark = Color3.fromRGB(140, 30, 30),
        RedHover = Color3.fromRGB(190, 40, 40),
    }

    local FRAME_SIZE = UDim2.new(0, 450, 0, 320)

    ----------------------------------------------------------------
    -- Utilidades
    ----------------------------------------------------------------
    local function notify(title, text, duration)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration or 5,
            })
        end)
    end

    local function tween(obj, info, props)
        local t = TweenService:Create(obj, info, props)
        t:Play()
        return t
    end

    local function addCorner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = parent
        return c
    end

    local function addStroke(parent, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = thickness
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = parent
        return s
    end

    local function newLabel(props)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.BorderSizePixel = 0
        for k, v in pairs(props) do
            l[k] = v
        end
        return l
    end

    local function parentGui(gui)
        if typeof(gethui) == "function" then
            local good = pcall(function()
                gui.Parent = gethui()
            end)
            if good and gui.Parent then return end
        end
        local good = pcall(function()
            gui.Parent = CoreGui
        end)
        if good and gui.Parent then return end
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Elimina una instancia anterior si el script se ejecuta dos veces
    local function cleanOld()
        local containers = {}
        if typeof(gethui) == "function" then
            pcall(function() table.insert(containers, gethui()) end)
        end
        table.insert(containers, CoreGui)
        pcall(function() table.insert(containers, LocalPlayer:FindFirstChild("PlayerGui")) end)
        for _, c in ipairs(containers) do
            pcall(function()
                local old = c:FindFirstChild(GUI_NAME)
                if old then old:Destroy() end
            end)
        end
    end

    ----------------------------------------------------------------
    -- Notificación inicial
    ----------------------------------------------------------------
    notify("Froggy Hub", "Script en mantenimiento. / Script under maintenance.", 8)

    ----------------------------------------------------------------
    -- Interfaz
    ----------------------------------------------------------------
    cleanOld()

    local gui = Instance.new("ScreenGui")
    gui.Name = GUI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentGui(gui)

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundColor3 = COLORS.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    addCorner(main, 14)
    addStroke(main, COLORS.Green, 2)

    -- Degradado sutil de fondo
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 24, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20)),
    })
    bgGradient.Rotation = 90
    bgGradient.Parent = main

    -- Logo superior izquierdo
    local logoTop = Instance.new("ImageLabel")
    logoTop.Name = "LogoTopLeft"
    logoTop.BackgroundTransparency = 1
    logoTop.BorderSizePixel = 0
    logoTop.Position = UDim2.new(0, 10, 0, 10)
    logoTop.Size = UDim2.new(0, 60, 0, 60)
    logoTop.ScaleType = Enum.ScaleType.Fit
    logoTop.ImageTransparency = 1
    logoTop.Parent = main

    -- Logo inferior derecho (espejo, rotado 180°)
    local logoBottom = Instance.new("ImageLabel")
    logoBottom.Name = "LogoBottomRight"
    logoBottom.BackgroundTransparency = 1
    logoBottom.BorderSizePixel = 0
    logoBottom.AnchorPoint = Vector2.new(1, 1)
    logoBottom.Position = UDim2.new(1, -10, 1, -10)
    logoBottom.Size = UDim2.new(0, 60, 0, 60)
    logoBottom.Rotation = 180
    logoBottom.ScaleType = Enum.ScaleType.Fit
    logoBottom.ImageTransparency = 1
    logoBottom.Parent = main

    -- Título
    newLabel({
        Name = "Title",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 16),
        Size = UDim2.new(0, 300, 0, 28),
        Font = Enum.Font.GothamBlack,
        Text = "¡VOLVEMOS ENSEGUIDA!",
        TextSize = 22,
        TextColor3 = COLORS.White,
        Parent = main,
    })

    -- Subtítulo
    newLabel({
        Name = "Subtitle",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 46),
        Size = UDim2.new(0, 300, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "WE'LL BE RIGHT BACK!",
        TextSize = 12,
        TextColor3 = COLORS.Green,
        Parent = main,
    })

    -- Línea divisoria
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.AnchorPoint = Vector2.new(0.5, 0)
    divider.Position = UDim2.new(0.5, 0, 0, 78)
    divider.Size = UDim2.new(1, -60, 0, 1)
    divider.BackgroundColor3 = COLORS.Green
    divider.BackgroundTransparency = 0.7
    divider.BorderSizePixel = 0
    divider.Parent = main

    -- Descripción
    local green = "rgb(110,220,90)"
    newLabel({
        Name = "Description",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 84),
        Size = UDim2.new(1, -60, 0, 84),
        Font = Enum.Font.Gotham,
        RichText = true,
        Text = '<b><font color="' .. green .. '">ES:</font></b> Este script se encuentra inactivo temporalmente porque estamos aplicando mejoras. Estará disponible en breve. \n\n'
            .. '<b><font color="' .. green .. '">EN:</font></b> This script is temporarily offline while we perform an update. It will be back online shortly.',
        TextSize = 13,
        TextColor3 = COLORS.Gray,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = main,
    })

    -- Texto pequeño
    newLabel({
        Name = "SocialHint",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 172),
        Size = UDim2.new(1, -60, 0, 16),
        Font = Enum.Font.GothamMedium,
        Text = "Mantente pendiente a mis redes para saber cuándo vuelve:",
        TextSize = 11,
        TextColor3 = COLORS.DarkGray,
        TextWrapped = true,
        Parent = main,
    })

    -- Pie de página
    newLabel({
        Name = "Footer",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.new(0, 280, 0, 14),
        Font = Enum.Font.GothamBold,
        Text = "FROGGY HUB  •  MAINTENANCE",
        TextSize = 10,
        TextColor3 = COLORS.Green,
        TextTransparency = 0.4,
        Parent = main,
    })

    ----------------------------------------------------------------
    -- Botones de enlaces
    ----------------------------------------------------------------
    local buttonHolder = Instance.new("Frame")
    buttonHolder.Name = "Buttons"
    buttonHolder.AnchorPoint = Vector2.new(0.5, 0)
    buttonHolder.Position = UDim2.new(0.5, 0, 0, 196)
    buttonHolder.Size = UDim2.new(0, 380, 0, 45)
    buttonHolder.BackgroundTransparency = 1
    buttonHolder.BorderSizePixel = 0
    buttonHolder.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 20)
    layout.Parent = buttonHolder

    local function createLinkButton(order, text, accent, link, successMsg)
        local btn = Instance.new("TextButton")
        btn.Name = "LinkButton" .. order
        btn.LayoutOrder = order
        btn.Size = UDim2.new(0, 180, 0, 45)
        btn.BackgroundColor3 = COLORS.Button
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextSize = 12
        btn.TextColor3 = accent
        btn.Parent = buttonHolder
        addCorner(btn, 10)
        local stroke = addStroke(btn, accent, 1.5)

        local hoverColor = COLORS.Button:Lerp(accent, 0.16)
        local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        btn.MouseEnter:Connect(function()
            tween(btn, info, { BackgroundColor3 = hoverColor })
            tween(stroke, info, { Thickness = 2 })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, info, { BackgroundColor3 = COLORS.Button })
            tween(stroke, info, { Thickness = 1.5 })
        end)

        local busy = false
        btn.MouseButton1Click:Connect(function()
            local copied = pcall(function()
                setclipboard(link)
            end)
            if copied then
                notify("Froggy Hub", successMsg, 4)
            else
                notify("Froggy Hub", "Tu ejecutor no soporta copiar al portapapeles. / Your executor doesn't support clipboard.", 6)
            end
            if busy then return end
            busy = true
            local original = text
            btn.Text = copied and "¡Enlace copiado!" or "No se pudo copiar"
            task.delay(1.5, function()
                if btn and btn.Parent then
                    btn.Text = original
                end
                busy = false
            end)
        end)

        return btn
    end

    createLinkButton(1, "TikTok: @user879619640", COLORS.Pink, TIKTOK_LINK,
        "Enlace de TikTok copiado al portapapeles. / TikTok link copied.")
    createLinkButton(2, "Ir al Discord", COLORS.Green, DISCORD_LINK,
        "Enlace de Discord copiado al portapapeles. / Discord link copied.")

    ----------------------------------------------------------------
    -- Botón de cerrar
    ----------------------------------------------------------------
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -10, 0, 10)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.BackgroundColor3 = COLORS.RedDark
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "X"
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = COLORS.White
    closeBtn.ZIndex = 5
    closeBtn.Parent = main
    addCorner(closeBtn, 8)

    local closeInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, closeInfo, { BackgroundColor3 = COLORS.RedHover })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, closeInfo, { BackgroundColor3 = COLORS.RedDark })
    end)

    local closing = false
    closeBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        local t = tween(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
        })
        t.Completed:Connect(function()
            if gui then gui:Destroy() end
        end)
    end)

    ----------------------------------------------------------------
    -- Animación de entrada
    ----------------------------------------------------------------
    tween(main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = FRAME_SIZE,
    })

    ----------------------------------------------------------------
    -- Descarga del logo (en segundo plano para no retrasar la UI)
    ----------------------------------------------------------------
    task.spawn(function()
        local asset
        pcall(function()
            local data = game:HttpGet(LOGO_URL)
            writefile(LOGO_FILE, data)
            local getAsset = getcustomasset or getsynasset
            asset = getAsset(LOGO_FILE)
        end)

        if asset and asset ~= "" and gui and gui.Parent then
            logoTop.Image = asset
            logoBottom.Image = asset
            local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tween(logoTop, fade, { ImageTransparency = 0 })
            tween(logoBottom, fade, { ImageTransparency = 0 })
        end
    end)
end)

if not ok then
    warn("[Froggy Hub | Mantenimiento] Error: " .. tostring(err))
end
