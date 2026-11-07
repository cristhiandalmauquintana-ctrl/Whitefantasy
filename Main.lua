--// Main.lua - Froggy Hub | Elemental Magic Arena (Clean Release)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local env = (getgenv and getgenv()) or _G

-- 🛑 CANDADO ANTI-DOBLE EJECUCIÓN
if env.BF_CURRENT_UI then
    pcall(function() env.BF_CURRENT_UI:Destroy() end)
    env.BF_CURRENT_UI = nil
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- SISTEMA DE IDIOMAS
local Translations = {
    ["es"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | CHIBI EDITION",
        tab_main = "PRINCIPAL", tab_combat = "COMBATE", tab_visual = "VISUAL", tab_movement = "MOVIMIENTO", tab_farm = "AUTO FARM", tab_tourney = "TORNEO", tab_config = "CONFIG",
        rejoin = "RECONECTAR SERVIDOR", auto_combat = "AUTO COMBAT (M1)", m1_delay = "RETRASO M1",
        hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "TAMAÑO HITBOX (BETA)",
        attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "¡IMPORTANTE! El Attack All equipará automáticamente Energy al morir.", 
        select_element = "SELECCIONA TU ELEMENTO",
        esp = "ESP JUGADORES", boxes = "CAJAS 2D", tracers = "TRACERS", health = "BARRA DE VIDA",
        speed = "SPEED HACK", speed_val = "VELOCIDAD", jump = "SUPER JUMP", jump_val = "ALTURA DE SALTO",
        farm_players = "AUTO FARM PLAYERS", farm_desc = "Usa el Dropdown para elegir el elemento. (Solo funciona con elementos que tengan espada).",
        tourney_desc = "Persigue al enemigo 10 studs atrás y arriba. Ideal para 1v1.",
        silent_collect = "AUTO-RECOLECCIÓN SILENCIOSA",
        no_robux = "BLOQUEAR COMPRAS DE ROBUX", no_robux_desc = "Evita que la espada abra tiendas de gemas.",
        dev_zone = "ZONA DE DESARROLLADOR", pass = "CONTRASEÑA DE PRUEBAS", unlock = "DESBLOQUEAR PRUEBA", destroy_ui = "DESTRUIR UI", lang_sel = "CAMBIAR IDIOMA", lang_desc = "Selecciona un idioma y vuelve a ejecutar."
    },
    ["en"] = {
        title = "FROGGY HUB", subtitle = "200 MEMBERS | CHIBI EDITION",
        tab_main = "MAIN", tab_combat = "COMBAT", tab_visual = "VISUAL", tab_movement = "MOVEMENT", tab_farm = "AUTO FARM", tab_tourney = "TOURNAMENT", tab_config = "CONFIG",
        rejoin = "REJOIN SERVER", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
        hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "HITBOX SIZE (BETA)",
        attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "IMPORTANT! Attack All will auto-equip Energy upon death.", 
        select_element = "SELECT YOUR ELEMENT",
        esp = "PLAYER ESP", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "SPEED", jump = "SUPER JUMP", jump_val = "JUMP POWER",
        farm_players = "AUTO FARM PLAYERS", farm_desc = "Use the Dropdown to select the element. (Only works with sword-based elements).",
        tourney_desc = "Stalks the enemy 10 studs behind and above. Ideal for 1v1s.",
        silent_collect = "SILENT AUTO-COLLECT",
        no_robux = "BLOCK ROBUX PURCHASES", no_robux_desc = "Prevents the sword from opening gem shops.",
        dev_zone = "DEVELOPER ZONE", pass = "TEST PASSWORD", unlock = "UNLOCK TEST", destroy_ui = "DESTROY UI", lang_sel = "CHANGE LANGUAGE", lang_desc = "Select a language and re-execute."
    }
}

local currentLang = "en"
pcall(function()
    local id = LocalPlayer.LocaleId:lower()
    if id:find("es") then currentLang = "es" end
end)
local function L(key) return Translations[currentLang][key] or Translations["en"][key] or key end

-- CARGAMOS DISEÑO
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua?v=" .. os.time()))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua?v=" .. os.time()))()
env.BF_UI_LIBRARY = UI_Library 
env.BF_ASSETS_LIBRARY = Assets

local Window = UI_Library.CreateWindow({ Title = L("title"), Subtitle = L("subtitle") })
env.BF_CURRENT_UI = Window

local TabMain = Window:CreateTab(L("tab_main"))
local TabCombat = Window:CreateTab(L("tab_combat"))
local TabVisual = Window:CreateTab(L("tab_visual"))
local TabMovement = Window:CreateTab(L("tab_movement"))
local TabFarm = Window:CreateTab(L("tab_farm"))
local TabTourney = Window:CreateTab(L("tab_tourney"))
local TabConfig = Window:CreateTab(L("tab_config"))

-- DESCARGA DE MÓDULOS
local folder = "ElementalMagicArena/"
local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    local ok, res = pcall(game.HttpGet, game, url)
    if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then pcall(fn) end
    else
        warn("[Froggy] ❌ No se pudo descargar: " .. name)
    end
    task.wait(0.1)
    return env[key] or _G[key]
end

local CombC = download("AutoCombat.lua", "BF_COMBAT_CONFIG")
local EspC = download("EspElemental.lua", "BF_ESP_CONFIG")
local HitC = download("HitboxExpander.lua", "BF_HITBOX_CONFIG")
local MoveC = download("Movement.lua", "BF_MOVE_CONFIG")
local AttackAllC = download("AttackAll.lua", "BF_ATTACKALL_CONFIG")
local SilentCollectC = download("SilentCollect.lua", "BF_SILENTCOLLECT_CONFIG")
local FarmC = download("PlayerFarm.lua", "BF_PLAYERFARM_CONFIG")
local TourneyC = download("AutoTournament.lua", "BF_TOURNAMENT_CONFIG")
local NoRobuxC = download("NoRobux.lua", "BF_NOROBUX_CONFIG")

if NoRobuxC then NoRobuxC.Enabled = true end -- Forzar encendido

-- CONEXIÓN UI
TabMain:AddButton(L("rejoin"), function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)

if CombC then
    TabCombat:AddToggle(L("auto_combat"), false, function(state) CombC.Enabled = state end)
    TabCombat:AddSlider(L("m1_delay"), 0.1, 1.0, CombC.M1Delay or 0.3, function(val) CombC.M1Delay = val end)
end

local hitboxSlider = nil
if HitC then
    TabCombat:AddToggle(L("hitbox"), false, function(state) HitC.Enabled = state end)
    hitboxSlider = TabCombat:AddSlider(L("hitbox_size"), 35, 500, 35, function(val) HitC.Size = val end)
    if hitboxSlider and hitboxSlider.Instance then 
        hitboxSlider.Instance.Visible = false 
        if hitboxSlider.Instance.Parent then hitboxSlider.Instance.Parent.Visible = false end
    end
end

-- 🔥 ATTACK ALL LIMPIO (Sin Godmode vacío ni Dropdown inútil)
if AttackAllC then
    TabCombat:AddSection(L("attack_all"))
    TabCombat:AddToggle(L("attack_all"), false, function(state) AttackAllC.Enabled = state end)
    TabCombat:AddInfo(L("attack_all_warn"))
end

if EspC then
    TabVisual:AddToggle(L("esp"), false, function(state) EspC.Enabled = state end)
    TabVisual:AddToggle(L("boxes"), false, function(state) EspC.Boxes = state end)
    TabVisual:AddToggle(L("tracers"), false, function(state) EspC.Tracers = state end)
    TabVisual:AddToggle(L("health"), false, function(state) EspC.HealthBar = state end)
end

if MoveC then
    TabMovement:AddToggle(L("speed"), false, function(state) MoveC.SpeedEnabled = state end)
    TabMovement:AddSlider(L("speed_val"), 16, 200, MoveC.Speed or 60, function(val) MoveC.Speed = val end)
    TabMovement:AddToggle(L("jump"), false, function(state) MoveC.JumpEnabled = state end)
    TabMovement:AddSlider(L("jump_val"), 50, 300, MoveC.JumpPower or 100, function(val) MoveC.JumpPower = val end)
end

-- === AUTO FARM (CON DROPDOWN DE ELEMENTOS) ===
if FarmC then
    TabFarm:AddSection("AUTO FARM")
    
    local ElementList = {
        "energy", "luz", "fuego", "agua", "hielo", "tierra", "aire", "oscuridad", 
        "lava", "veneno", "hierro", "espiritu", "destruccion", "cristal", "sonido", 
        "aurora", "fenix", "caos", "tecnología", "diamante", "amor", "demon", 
        "ilusion", "campos de fuerza", "relampago", "telequinesis", "life", "mirror", 
        "time", "sueño", "creacion", "espacio", "realidad", "dios de elementos",
        "witchcraft", "luck", "nature", "void", "infection", "necromancy", 
        "celestial", "gold", "snow", "dimension", "nova", "sand", "killstreak"
    }

    TabFarm:AddDropdown(L("select_element"), ElementList, FarmC.SelectedElement or "energy", function(val)
        FarmC.SelectedElement = val
        Window:Notify({Title = "Farm Element", Content = "Seleccionado: " .. val, Type = "info"})
        if FarmC.Enabled then
            Window:Notify({Title = "Aviso", Content = "Apaga y enciende el Farm para aplicar el nuevo elemento.", Type = "warning"})
        end
    end)

    TabFarm:AddToggle(L("farm_players"), false, function(state)
        FarmC.Enabled = state
        if state then 
            Window:Notify({Title = "Farm", Content = "Iniciando Farm usando " .. (FarmC.SelectedElement or "energy"), Type = "success"})
        else 
            Window:Notify({Title = "Farm", Content = "Farmeo Detenido.", Type = "warning"})
        end
    end)
    TabFarm:AddInfo(L("farm_desc"))
end

if TourneyC then
    TabTourney:AddSection("AUTO TOURNAMENT (1v1)")
    TabTourney:AddToggle("AUTO TOURNAMENT", false, function(state) TourneyC.Enabled = state end)
    TabTourney:AddInfo(L("tourney_desc"))
end

if SilentCollectC then
    TabConfig:AddSection(L("utilities"))
    TabConfig:AddToggle(L("silent_collect"), true, function(state) SilentCollectC.Enabled = state end)
end

if NoRobuxC then
    TabConfig:AddSection("SEGURIDAD EXTRA")
    TabConfig:AddToggle(L("no_robux"), true, function(state) NoRobuxC.Enabled = state end)
    TabConfig:AddInfo(L("no_robux_desc"))
end

TabConfig:AddSection(L("lang_sel"))
TabConfig:AddDropdown(L("lang_sel"), {"es", "en"}, currentLang, function(val)
    if writefile then pcall(function() writefile("FroggyLang.txt", val) end) end
end)

TabConfig:AddSection(L("dev_zone"))
local passBox = TabConfig:AddTextbox(L("pass"), "", "...", function() end)
local unlockBtn = TabConfig:AddButton(L("unlock"), function()
    if passBox:Get() == "froggy_testing_2026" then
        passBox.Instance.Visible = false
        if unlockBtn and unlockBtn.Instance then unlockBtn.Instance.Visible = false end
        if hitboxSlider and hitboxSlider.Instance then 
            hitboxSlider.Instance.Visible = true 
            if hitboxSlider.Instance.Parent then hitboxSlider.Instance.Parent.Visible = true end
        end
    else
        passBox:Set("")
    end
end)

TabConfig:AddButton(L("destroy_ui"), function()
    Window:Destroy()
    if env.BF_CURRENT_UI == Window then env.BF_CURRENT_UI = nil end
end)
