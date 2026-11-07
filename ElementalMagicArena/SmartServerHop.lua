--// Froggy Hub - ElementalMagicArena/SmartServerHop.lua (INDEPENDIENTE)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local env = (getgenv and getgenv()) or _G
local Config = {
    Enabled = true,
    HopTime = 1200, -- 20 minutos por defecto
    IsAsking = false
}
env.BF_SERVERHOP_CONFIG = Config

-- 1. Cargar Assets para la UI (Solo si no está en memoria)
local Assets = env.BF_ASSETS_LIBRARY
if not Assets then
    local ok, res = pcall(game.HttpGet, game, ROOT .. "assets.lua?v=" .. os.time())
    if ok and type(res) == "string" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then
            Assets = fn()
            env.BF_ASSETS_LIBRARY = Assets
        end
    end
end

-- 2. Guardar estado para el Queue on Teleport
local function saveCurrentState()
    local state = {}
    if env.BF_PLAYERFARM_CONFIG then state.Farm = env.BF_PLAYERFARM_CONFIG.Enabled end
    if env.BF_HITBOX_CONFIG then state.Hitbox = env.BF_HITBOX_CONFIG.Enabled end
    if env.BF_ATTACKALL_CONFIG then state.AttackAll = env.BF_ATTACKALL_CONFIG.Enabled end
    if env.BF_ESP_CONFIG then state.ESP = env.BF_ESP_CONFIG.Enabled end
    if env.BF_MOVE_CONFIG then state.Speed = env.BF_MOVE_CONFIG.SpeedEnabled end
    if env.BF_COMBAT_CONFIG then state.AutoCombat = env.BF_COMBAT_CONFIG.Enabled end
    if env.BF_SILENTCOLLECT_CONFIG then state.SilentCollect = env.BF_SILENTCOLLECT_CONFIG.Enabled end

    local success, encoded = pcall(function() return HttpService:JSONEncode(state) end)
    if success and writefile then
        pcall(function() writefile("FroggyConfig.json", encoded) end)
    end
end

-- 3. Función de Hop
local function doHop()
    Config.IsAsking = false
    print("[Froggy] Server Hop: Guardando configuración y viajando...")
    saveCurrentState()

    local loadstringCmd = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/cristhiandalmauquintana-ctrl/Whitefantasy/main/Main.lua?v=" .. os.time()))()'
    
    if syn and syn.queue_on_teleport then syn.queue_on_teleport(loadstringCmd)
    elseif queue_on_teleport then queue_on_teleport(loadstringCmd)
    elseif fluxus and fluxus.queue_on_teleport then fluxus.queue_on_teleport(loadstringCmd) end

    task.wait(1)
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

-- 4. Panel de Advertencia usando Assets.lua
local function showWarningPanel()
    Config.IsAsking = true
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FroggyHopWarning"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 99999
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

    -- Fondo oscuro
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    bg.Parent = gui

    -- Panel principal
    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(300, 180)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Assets.Colors.WaterDark
    panel.BorderSizePixel = 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Assets.Colors.Amber
    stroke.Thickness = 2.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "⚠️ TIEMPO DE SERVIDOR ⚠️"
    title.Font = Assets.Fonts.Title
    title.TextSize = 18
    title.TextColor3 = Assets.Colors.Amber
    title.Parent = panel

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 60)
    desc.Position = UDim2.fromOffset(20, 45)
    desc.BackgroundTransparency = 1
    desc.Text = "Llevas mucho tiempo aquí. Los moderadores podrían estar buscándote. ¿Quieres cambiar de servidor para estar a salvo?"
    desc.Font = Assets.Fonts.Body
    desc.TextSize = 13
    desc.TextColor3 = Assets.Colors.Text
    desc.TextWrapped = true
    desc.Parent = panel

    -- Botones usando Assets
    local btnYes = Assets.CreateButton(panel, {
        Text = "SÍ, CAMBIAR",
        Style = "outline",
        Size = UDim2.fromOffset(120, 36),
        Position = UDim2.new(0, 20, 1, -50),
        Callback = function()
            gui:Destroy()
            doHop()
        end
    })

    local btnNo = Assets.CreateButton(panel, {
        Text = "NO, QUEDARME",
        Style = "berry",
        Size = UDim2.fromOffset(120, 36),
        Position = UDim2.new(1, -140, 1, -50),
        Callback = function()
            gui:Destroy()
            Config.IsAsking = false
            Config.HopTime = 300 -- Dar 5 minutos extra si dice que no
        end
    })

    -- Aviso sonoro
    if Assets.Notify then
        Assets.Notify({Title = "Aviso", Text = "Considera cambiar de servidor.", Type = "warn"})
    end
end

-- 5. Bucle del Temporizador
task.spawn(function()
    while task.wait(1) do
        if Config.Enabled and not Config.IsAsking then
            Config.HopTime -= 1
            if Config.HopTime <= 0 then
                -- Verificar si el Farm está activo
                local isFarming = env.BF_PLAYERFARM_CONFIG and env.BF_PLAYERFARM_CONFIG.Enabled
                
                if isFarming then
                    -- Modo Farm: Hop Automático
                    doHop()
                else
                    -- Modo Normal: Preguntar
                    showWarningPanel()
                end
            end
        end
    end
end)

env.__BF_SERVERHOP_CLEANUP = function()
    Config.Enabled = false
    env.BF_SERVERHOP_CONFIG = nil
    env.__BF_SERVERHOP_CLEANUP = nil
end
