--[[
    Froggy Hub - Modo Mantenimiento (Pond Edition)
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
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Configuración
    ----------------------------------------------------------------
    local GUI_NAME = "FroggyHubMaintenance"
    local LOGO_URL = "https://raw.githubusercontent.com/cristhiandalmauquintana-ctrl/Whitefantasy/main/logo.png"
    local LOGO_FILE = "FroggyHub_logo.png"
    local TIKTOK_LINK = "https://tiktok.com/@user879619640"
    local DISCORD_LINK = "https://discord.com/channels/1562554522134380544/1562554674123378769"

    -- Paleta idéntica a design.lua (Pond Theme)
    local C = {
        DeepGreen = Color3.fromRGB(12, 46, 34),
        Neon = Color3.fromRGB(105, 255, 90),
        WaterDark = Color3.fromRGB(8, 38, 52),
        WaterMid = Color3.fromRGB(16, 86, 104),
        WaterLight = Color3.fromRGB(110, 215, 230),
        Wood = Color3.fromRGB(118, 82, 50),
        WoodDark = Color3.fromRGB(66, 44, 28),
        WoodLight = Color3.fromRGB(160, 116, 70),
        PadGreen = Color3.fromRGB(46, 150, 70),
        PadDark = Color3.fromRGB(22, 96, 46),
        PadLight = Color3.fromRGB(90, 190, 100),
        FrogGreen = Color3.fromRGB(80, 210, 70),
        Text = Color3.fromRGB(228, 246, 228),
        TextDim = Color3.fromRGB(150, 188, 160),
        Pink = Color3.fromRGB(255, 120, 140),
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

    local function addStroke(parent, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = thickness
        s.Transparency = transparency or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = parent
        return s
    end

    local function addGradient(parent, c0, c1, rotation)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(c0, c1)
        g.Rotation = rotation or 90
        g.Parent = parent
        return g
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

    -- Marco exterior de madera
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundColor3 = C.Wood
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    addCorner(main, 16)
    addStroke(main, C.Neon, 2)
    addGradient(main, C.WoodLight, C.WoodDark, 90)

    -- Estanque (interior)
    local pond = Instance.new("Frame")
    pond.Name = "Pond"
    pond.Position = UDim2.new(0, 6, 0, 6)
    pond.Size = UDim2.new(1, -12, 1, -12)
    pond.BackgroundColor3 = C.WaterDark
    pond.BorderSizePixel = 0
    pond.ClipsDescendants = true
    pond.Parent = main
    addCorner(pond, 11)
    addStroke(pond, C.WoodDark, 2)
    addGradient(pond, C.WaterMid, C.WaterDark, 90)

    ----------------------------------------------------------------
    -- Decoración: nenúfares flotando y ondas en el agua
    ----------------------------------------------------------------
    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = pond

    local function makePad(size, xScale, yScale, bobTime, rot)
        local pad = Instance.new("Frame")
        pad.AnchorPoint = Vector2.new(0.5, 0.5)
        pad.Position = UDim2.new(xScale, 0, yScale, 0)
        pad.Size = UDim2.new(0, size, 0, size)
        pad.BackgroundColor3 = C.PadGreen
        pad.BackgroundTransparency = 0.45
        pad.BorderSizePixel = 0
        pad.Rotation = rot or 0
        pad.ZIndex = 1
        pad.Parent = decor
        addCorner(pad, size)
        addStroke(pad, C.PadDark, 2, 0.45)

        local shine = Instance.new("Frame")
        shine.AnchorPoint = Vector2.new(0.5, 0.5)
        shine.Position = UDim2.new(0.5, 0, 0.5, 0)
        shine.Size = UDim2.new(0.55, 0, 0.55, 0)
        shine.BackgroundColor3 = C.PadLight
        shine.BackgroundTransparency = 0.65
        shine.BorderSizePixel = 0
        shine.ZIndex = 1
        shine.Parent = pad
        addCorner(shine, size)

        -- corte típico del nenúfar
        local notch = Instance.new("Frame")
        notch.AnchorPoint = Vector2.new(0, 0.5)
        notch.Position = UDim2.new(0.5, 0, 0.5, 0)
        notch.Size = UDim2.new(0.5, 0, 0, 3)
        notch.BackgroundColor3 = C.WaterDark
        notch.BackgroundTransparency = 0.3
        notch.BorderSizePixel = 0
        notch.ZIndex = 1
        notch.Parent = pad

        -- vaivén suave
        tween(pad, TweenInfo.new(bobTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = UDim2.new(xScale, 6, yScale, -7),
            Rotation = (rot or 0) + 12,
        })
        return pad
    end

    makePad(70, 0.12, 0.88, 3.2, 20)
    makePad(46, 0.88, 0.22, 2.6, -15)
    makePad(34, 0.30, 0.18, 3.8, 40)
    makePad(54, 0.80, 0.82, 3.0, 0)

    local function makeRipple(xScale, yScale, delay)
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.new(xScale, 0, yScale, 0)
        r.Size = UDim2.new(0, 0, 0, 0)
        r.BackgroundTransparency = 1
        r.BorderSizePixel = 0
        r.ZIndex = 1
        r.Parent = decor
        addCorner(r, 100)
        local s = addStroke(r, C.WaterLight, 2, 1)

        task.spawn(function()
            task.wait(delay)
            while gui and gui.Parent do
                r.Size = UDim2.new(0, 0, 0, 0)
                s.Transparency = 0.35
                local info = TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                tween(r, info, { Size = UDim2.new(0, 110, 0, 110) })
                tween(s, info, { Transparency = 1 })
                task.wait(3.6)
            end
        end)
    end

    makeRipple(0.22, 0.45, 0)
    makeRipple(0.78, 0.55, 1.4)
    makeRipple(0.52, 0.92, 2.6)

    ----------------------------------------------------------------
    -- Logos (esquinas) con rana de respaldo si no carga la imagen
    ----------------------------------------------------------------
    local logoTop = Instance.new("ImageLabel")
    logoTop.Name = "LogoTopLeft"
    logoTop.BackgroundTransparency = 1
    logoTop.BorderSizePixel = 0
    logoTop.Position = UDim2.new(0, 10, 0, 8)
    logoTop.Size = UDim2.new(0, 58, 0, 58)
    logoTop.ScaleType = Enum.ScaleType.Fit
    logoTop.ImageTransparency = 1
    logoTop.ZIndex = 3
    logoTop.Parent = pond

    local logoBottom = Instance.new("ImageLabel")
    logoBottom.Name = "LogoBottomRight"
    logoBottom.BackgroundTransparency = 1
    logoBottom.BorderSizePixel = 0
    logoBottom.AnchorPoint = Vector2.new(1, 1)
    logoBottom.Position = UDim2.new(1, -10, 1, -8)
    logoBottom.Size = UDim2.new(0, 58, 0, 58)
    logoBottom.Rotation = 180
    logoBottom.ScaleType = Enum.ScaleType.Fit
    logoBottom.ImageTransparency = 1
    logoBottom.ZIndex = 3
    logoBottom.Parent = pond

    local frogFallback = newLabel({
        Name = "FrogFallback",
        Position = UDim2.new(0, 10, 0, 8),
        Size = UDim2.new(0, 58, 0, 58),
        Font = Enum.Font.GothamBold,
        Text = "🐸",
        TextSize = 40,
        TextColor3 = C.Text,
        ZIndex = 3,
        Parent = pond,
    })

    ----------------------------------------------------------------
    -- Textos
    ----------------------------------------------------------------
    local title = newLabel({
        Name = "Title",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 12),
        Size = UDim2.new(0, 290, 0, 28),
        Font = Enum.Font.GothamBlack,
        Text = "¡VOLVEMOS ENSEGUIDA!",
        TextSize = 22,
        TextColor3 = C.Neon,
        ZIndex = 3,
        Parent = pond,
    })
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = C.DeepGreen
    titleStroke.Thickness = 2
    titleStroke.Parent = title

    newLabel({
        Name = "Subtitle",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 42),
        Size = UDim2.new(0, 290, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "WE'LL BE RIGHT BACK!",
        TextSize = 12,
        TextColor3 = C.WaterLight,
        ZIndex = 3,
        Parent = pond,
    })

    -- Divisor tipo tronco
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.AnchorPoint = Vector2.new(0.5, 0)
    divider.Position = UDim2.new(0.5, 0, 0, 68)
    divider.Size = UDim2.new(1, -70, 0, 4)
    divider.BackgroundColor3 = C.Wood
    divider.BorderSizePixel = 0
    divider.ZIndex = 3
    divider.Parent = pond
    addCorner(divider, 2)
    addGradient(divider, C.WoodLight, C.WoodDark, 90)

    local neonHex = "rgb(105,255,90)"
    newLabel({
        Name = "Description",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 78),
        Size = UDim2.new(1, -60, 0, 84),
        Font = Enum.Font.Gotham,
        RichText = true,
        Text = '<b><font color="' .. neonHex .. '">ES:</font></b> Este script se encuentra inactivo temporalmente porque estamos aplicando mejoras. Estará disponible en breve.\n\n'
            .. '<b><font color="' .. neonHex .. '">EN:</font></b> This script is temporarily offline while we perform an update. It will be back online shortly.',
        TextSize = 13,
        TextColor3 = C.Text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 3,
        Parent = pond,
    })

    newLabel({
        Name = "SocialHint",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 164),
        Size = UDim2.new(1, -60, 0, 16),
        Font = Enum.Font.GothamMedium,
        Text = "Mantente pendiente a mis redes para saber cuándo vuelve:",
        TextSize = 11,
        TextColor3 = C.TextDim,
        TextWrapped = true,
        ZIndex = 3,
        Parent = pond,
    })

    ----------------------------------------------------------------
    -- Botones de enlaces (madera con borde de color)
    ----------------------------------------------------------------
    local buttonHolder = Instance.new("Frame")
    buttonHolder.Name = "Buttons"
    buttonHolder.AnchorPoint = Vector2.new(0.5, 0)
    buttonHolder.Position = UDim2.new(0.5, 0, 0, 186)
    buttonHolder.Size = UDim2.new(0, 380, 0, 44)
    buttonHolder.BackgroundTransparency = 1
    buttonHolder.BorderSizePixel = 0
    buttonHolder.ZIndex = 3
    buttonHolder.Parent = pond

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
        btn.Size = UDim2.new(0, 180, 0, 44)
        btn.BackgroundColor3 = C.Wood
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextSize = 12
        btn.TextColor3 = C.Text
        btn.ZIndex = 4
        btn.Parent = buttonHolder
        addCorner(btn, 10)
        local stroke = addStroke(btn, accent, 2)
        local grad = addGradient(btn, C.WoodLight, C.WoodDark, 90)

        local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        btn.MouseEnter:Connect(function()
            tween(stroke, info, { Thickness = 3 })
            tween(btn, info, { Size = UDim2.new(0, 186, 0, 46) })
            grad.Rotation = 270
        end)
        btn.MouseLeave:Connect(function()
            tween(stroke, info, { Thickness = 2 })
            tween(btn, info, { Size = UDim2.new(0, 180, 0, 44) })
            grad.Rotation = 90
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
            btn.Text = copied and "¡Enlace copiado! 🐸" or "No se pudo copiar"
            task.delay(1.5, function()
                if btn and btn.Parent then
                    btn.Text = original
                end
                busy = false
            end)
        end)

        return btn
    end

    createLinkButton(1, "TikTok: @user879619640", C.Pink, TIKTOK_LINK,
        "Enlace de TikTok copiado al portapapeles. / TikTok link copied.")
    createLinkButton(2, "Ir al Discord", C.Neon, DISCORD_LINK,
        "Enlace de Discord copiado al portapapeles. / Discord link copied.")

    ----------------------------------------------------------------
    -- Barra de progreso animada ("actualizando")
    ----------------------------------------------------------------
    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.AnchorPoint = Vector2.new(0.5, 0)
    track.Position = UDim2.new(0.5, 0, 0, 246)
    track.Size = UDim2.new(1, -150, 0, 12)
    track.BackgroundColor3 = C.WaterDark
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.ZIndex = 3
    track.Parent = pond
    addCorner(track, 6)
    addStroke(track, C.WoodDark, 2)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Position = UDim2.new(-0.4, 0, 0, 0)
    fill.Size = UDim2.new(0.4, 0, 1, 0)
    fill.BackgroundColor3 = C.Neon
    fill.BorderSizePixel = 0
    fill.ZIndex = 4
    fill.Parent = track
    addCorner(fill, 6)
    addGradient(fill, C.WaterLight, C.Neon, 0)

    tween(fill, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false), {
        Position = UDim2.new(1, 0, 0, 0),
    })

    local status = newLabel({
        Name = "Status",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 262),
        Size = UDim2.new(1, -60, 0, 14),
        Font = Enum.Font.GothamMedium,
        Text = "Croac... limpiando el estanque",
        TextSize = 11,
        TextColor3 = C.WaterLight,
        ZIndex = 3,
        Parent = pond,
    })

    local statusMessages = {
        "Croac... limpiando el estanque",
        "Croac... atrapando bugs (moscas)",
        "Croac... puliendo los nenúfares",
        "Croac... casi listo para saltar",
    }
    task.spawn(function()
        local i = 1
        while gui and gui.Parent do
            task.wait(2.6)
            if not (gui and gui.Parent) then break end
            i = i % #statusMessages + 1
            status.Text = statusMessages[i]
        end
    end)

    newLabel({
        Name = "Footer",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.new(0, 280, 0, 14),
        Font = Enum.Font.GothamBold,
        Text = "FROGGY HUB  •  MAINTENANCE",
        TextSize = 10,
        TextColor3 = C.Neon,
        TextTransparency = 0.4,
        ZIndex = 3,
        Parent = pond,
    })

    ----------------------------------------------------------------
    -- Botón de cerrar
    ----------------------------------------------------------------
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -10, 0, 10)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.BackgroundColor3 = C.RedDark
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "X"
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = C.Text
    closeBtn.ZIndex = 6
    closeBtn.Parent = pond
    addCorner(closeBtn, 8)
    addStroke(closeBtn, C.WoodDark, 2)

    local closeInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, closeInfo, { BackgroundColor3 = C.RedHover })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, closeInfo, { BackgroundColor3 = C.RedDark })
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
    -- Arrastrar la ventana (PC y móvil)
    ----------------------------------------------------------------
    do
        local dragging, dragStart, startPos
        main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

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
            frogFallback:Destroy()
            local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tween(logoTop, fade, { ImageTransparency = 0 })
            tween(logoBottom, fade, { ImageTransparency = 0 })
        end
    end)
end)

if not ok then
    warn("[Froggy Hub | Mantenimiento] Error: " .. tostring(err))
end
