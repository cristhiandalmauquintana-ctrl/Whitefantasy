--// Froggy Hub - ElementalMagicArena/PlayerFarm.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__BF_PLAYERFARM_CLEANUP then pcall(env.__BF_PLAYERFARM_CLEANUP) end

local Config = {
    Enabled = false, -- 🔥 APAGADO POR DEFECTO
}
env.BF_PLAYERFARM_CONFIG = Config

-- Coordenadas
local FARM_X = 1451.5
local FARM_Y = -115.1
local FARM_Z = 85.7
local FARM_HEIGHT = 50

local gui = nil
local killTrackerCon = nil
local weaponLoop = nil
local soulLoop = nil
local kills = 0
local playerStates = {}
local currentFps = 60
local updateUIFunc = nil

-- ==========================================
-- UI PREMIUM (CON PANTALLA NEGRA)
-- ==========================================
local function createPremiumUI()
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    if parent:FindFirstChild("FarmUI_Premium") then parent:FindFirstChild("FarmUI_Premium"):Destroy() end

    local C = {
        bg = Color3.fromRGB(12, 12, 16), panel = Color3.fromRGB(22, 22, 28),
        card = Color3.fromRGB(30, 30, 38), neon = Color3.fromRGB(57, 255, 120),
        gold = Color3.fromRGB(255, 200, 40), red = Color3.fromRGB(255, 50, 60),
        redDark = Color3.fromRGB(150, 20, 30), text = Color3.fromRGB(235, 235, 240),
        dim = Color3.fromRGB(130, 130, 145), blue = Color3.fromRGB(80, 200, 255),
    }

    local function make(class, props, children)
        local inst = Instance.new(class)
        for k, v in pairs(props) do inst[k] = v end
        if children then for _, c in ipairs(children) do c.Parent = inst end end
        return inst
    end
    local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r)}) end
    local function stroke(c, t, tr) return make("UIStroke", {Color = c, Thickness = t or 1.5, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
    local function gradient(c1, c2, rot) return make("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 90}) end
    local function tween(obj, t, props, style, dir) local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); tw:Play(); return tw end

    gui = make("ScreenGui", { Name = "FarmUI_Premium", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })

    -- PANTALLA NEGRA
    make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 1, Parent = gui })

    -- FPS
    local fpsBox = make("Frame", { Size = UDim2.fromOffset(92, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2, Parent = gui }, {corner(8), stroke(C.neon, 1.2, 0.2)})
    local signal = make("Frame", { Size = UDim2.fromOffset(18, 14), Position = UDim2.new(0, 9, 0.5, -7), BackgroundTransparency = 1, ZIndex = 2, Parent = fpsBox })
    local sigBars = {}
    for i = 1, 4 do sigBars[i] = make("Frame", { Size = UDim2.fromOffset(3, 3 + (i * 2.75)), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, (i - 1) * 5, 1, 0), BackgroundColor3 = C.neon, BorderSizePixel = 0, ZIndex = 2, Parent = signal }, {corner(1)}) end
    local fpsLabel = make("TextLabel", { Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "60", TextSize = 15, TextColor3 = C.neon, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = fpsBox })
    make("TextLabel", { Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -28, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, Text = "FPS", TextSize = 9, TextColor3 = C.dim, ZIndex = 2, Parent = fpsBox })

    -- PANEL
    local panel = make("Frame", { Name = "Panel", Size = UDim2.fromOffset(250, 300), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.panel, BackgroundTransparency = 0.18, BorderSizePixel = 0, ZIndex = 3, Parent = gui }, {corner(14), gradient(Color3.fromRGB(34, 34, 44), Color3.fromRGB(10, 10, 14), 135)})
    local panelStroke = stroke(C.neon, 1.8, 0.1); panelStroke.Parent = panel
    make("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = panel })
    make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "PLAYER FARM", TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = panel }, {gradient(C.neon, C.gold, 0)})
    make("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromOffset(0, 24), BackgroundColor3 = C.gold, BorderSizePixel = 0, ZIndex = 3, Parent = panel }, {corner(1), make("UIGradient", { Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})})})

    -- ARMA
    local statusBox = make("Frame", { Name = "Status", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 34), BackgroundColor3 = C.card, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3, Parent = panel }, {corner(8)})
    local statusStroke = stroke(C.neon, 1.2, 0.3); statusStroke.Parent = statusBox
    local statusDot = make("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 10, 0.5, -4), BackgroundColor3 = C.neon, BorderSizePixel = 0, ZIndex = 3, Parent = statusBox }, {make("UICorner", {CornerRadius = UDim.new(1, 0)})})
    local statusLabel = make("TextLabel", { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(24, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "SISTEMA: LISTO", TextSize = 12, TextColor3 = C.neon, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = statusBox })

    -- VIDA
    local hpLabel = make("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 72), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "HP: 100/100", TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = panel })
    local hpTrack = make("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 92), BackgroundColor3 = Color3.fromRGB(8, 8, 10), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3, Parent = panel }, {corner(7), stroke(Color3.fromRGB(60, 60, 70), 1, 0.2)})
    local hpFill = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.neon, BorderSizePixel = 0, ZIndex = 3, Parent = hpTrack }, {corner(7)})
    local hpGradient = make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(30, 200, 90), C.neon), Rotation = 0, Parent = hpFill })

    -- STATS
    local grid = make("Frame", { Size = UDim2.new(1, 0, 0, 62), Position = UDim2.fromOffset(0, 118), BackgroundTransparency = 1, ZIndex = 3, Parent = panel }, {make("UIGridLayout", { CellSize = UDim2.new(0.333, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal })})
    local function makeCard(order, title, accent)
        local card = make("Frame", { LayoutOrder = order, BackgroundColor3 = C.card, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 3, Parent = grid }, {corner(10), stroke(accent, 1.3, 0.35), gradient(Color3.fromRGB(40, 40, 50), Color3.fromRGB(20, 20, 26), 90)})
        make("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 6), BackgroundTransparency = 1, Font = Enum.Font.Code, Text = title, TextSize = 10, TextColor3 = C.dim, ZIndex = 3, Parent = card })
        return make("TextLabel", { Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "0", TextSize = 20, TextColor3 = accent, ZIndex = 3, Parent = card })
    end
    local killsValue    = makeCard(1, "KILLS", C.red)
    local diamondsValue = makeCard(2, "DIAMANTES", C.blue)
    local soulsValue    = makeCard(3, "SOULS", C.gold)

    -- BOTÓN
    local actionBtn = make("TextButton", { Name = "StopButton", Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44), BackgroundColor3 = C.red, AutoButtonColor = false, Font = Enum.Font.GothamBlack, Text = "DETENER FARMEO", TextSize = 15, TextColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 3, Parent = panel }, {corner(10), gradient(Color3.fromRGB(255, 70, 80), C.redDark, 90)})
    local btnStroke = stroke(Color3.fromRGB(255, 120, 120), 1.8, 0.1); btnStroke.Parent = actionBtn

    actionBtn.MouseButton1Click:Connect(function()
        Config.Enabled = false -- 🔥 Al presionar el botón, apaga el módulo
    end)

    local frames, lastT = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - lastT >= 1 then currentFps = frames; frames, lastT = 0, now end
    end)

    gui.Parent = parent

    return function(hp, maxHp, k, d, s, fps)
        maxHp = math.max(maxHp or 100, 1); hp = math.clamp(hp or 0, 0, maxHp)
        local pct = hp / maxHp
        hpLabel.Text = string.format("HP: %d/%d", math.floor(hp), math.floor(maxHp))
        tween(hpFill, 0.3, {Size = UDim2.new(pct, 0, 1, 0)})
        killsValue.Text = tostring(k)
        diamondsValue.Text = tostring(d)
        soulsValue.Text = tostring(s)
        
        local systemReady = Config.Enabled
        statusLabel.Text = systemReady and "SISTEMA: LISTO" or "SISTEMA: FALLO"
        statusLabel.TextColor3 = systemReady and C.neon or C.red
        statusDot.BackgroundColor3 = systemReady and C.neon or C.red
        
        fpsLabel.Text = tostring(math.floor(fps))
        local col = fps >= 50 and C.neon or (fps >= 30 and C.gold or C.red)
        fpsLabel.TextColor3 = col
    end
end

-- ==========================================
-- LÓGICA DEL FARM
-- ==========================================
local function equipWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then pcall(function() hum:EquipTool(tool) end); break end
        end
    end
end

local function toggleModules(state)
    if env.BF_ATTACKALL_CONFIG then env.BF_ATTACKALL_CONFIG.Enabled = state end
    if env.BF_HITBOX_CONFIG then env.BF_HITBOX_CONFIG.Enabled = state end
    if env.BF_SILENTCOLLECT_CONFIG then env.BF_SILENTCOLLECT_CONFIG.Enabled = state end
end

local function getGameStats()
    local diamonds, souls = 0, 0
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local d = stats:FindFirstChild("Diamonds") or stats:FindFirstChild("Gems")
        if d then diamonds = d.Value end
        local s = stats:FindFirstChild("Souls") or stats:FindFirstChild("Soul")
        if s then souls = s.Value end
    end
    return diamonds, souls
end

local function startFarm()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    equipWeapon()
    task.wait(0.5)

    root.Anchored = false
    hum.PlatformStand = true

    -- BodyPosition suave
    local bp = root:FindFirstChild("FarmBP")
    if bp then bp:Destroy() end
    bp = Instance.new("BodyPosition")
    bp.Name = "FarmBP"
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.Position = Vector3.new(FARM_X, FARM_Y + FARM_HEIGHT, FARM_Z)
    bp.P = 10000
    bp.D = 1000
    bp.Parent = root

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
    end

    toggleModules(true)
    updateUIFunc = createPremiumUI() -- Inicia la UI

    if weaponLoop then task.cancel(weaponLoop) end
    weaponLoop = task.spawn(function()
        while Config.Enabled do
            local c = LocalPlayer.Character
            if c and not c:FindFirstChildOfClass("Tool") then equipWeapon() end
            task.wait(1)
        end
    end)

    if killTrackerCon then task.cancel(killTrackerCon) end
    killTrackerCon = task.spawn(function()
        while Config.Enabled do
            task.wait(0.1)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local c = p.Character
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        playerStates[p] = true
                    elseif playerStates[p] and (not h or h.Health <= 0) then
                        kills = kills + 1
                        playerStates[p] = false
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while Config.Enabled do
            task.wait(0.5)
            if updateUIFunc and hum then
                local d, s = getGameStats()
                updateUIFunc(hum.Health, hum.MaxHealth, kills, d, s, currentFps)
            end
        end
    end)
end

local function stopFarm()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root then
        local bp = root:FindFirstChild("FarmBP"); if bp then bp:Destroy() end
    end
    if hum then hum.PlatformStand = false end
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
        end
    end

    toggleModules(false)
    if gui then gui:Destroy(); gui = nil end
    updateUIFunc = nil
    if weaponLoop then task.cancel(weaponLoop); weaponLoop = nil end
    if killTrackerCon then task.cancel(killTrackerCon); killTrackerCon = nil end
    playerStates = {}
end

-- LOOP PRINCIPAL (Controlado por el Main.lua)
task.spawn(function()
    while task.wait(0.5) do
        if Config.Enabled then
            if not gui then startFarm() end
        else
            if gui then stopFarm() end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled then
        task.wait(2.5)
        if not gui then startFarm() end
    end
end)

env.__BF_PLAYERFARM_CLEANUP = function()
    Config.Enabled = false
    stopFarm()
    env.BF_PLAYERFARM_CONFIG = nil
    env.__BF_PLAYERFARM_CLEANUP = nil
end
