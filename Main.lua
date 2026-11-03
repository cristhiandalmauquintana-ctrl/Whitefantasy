--// Main.lua - Froggy Hub | Elemental Magic Arena (Player Farm Update)
local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "Whitefantasy"
local BRANCH = "main"
local ROOT = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..BRANCH.."/"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- ==========================================
-- 1. SISTEMA INTELIGENTE DE IDIOMAS
-- ==========================================
local Translations = {
    ["es"] = {
        title = "FROGGY HUB", subtitle = "Elemental Arena | Player Farm Update",
        tab_main = "PRINCIPAL", tab_combat = "COMBATE", tab_visual = "VISUAL", tab_movement = "MOVIMIENTO", tab_farm = "AUTO FARM", tab_config = "CONFIG",
        rejoin = "RECONECTAR SERVIDOR", auto_combat = "AUTO COMBAT (M1)", m1_delay = "RETRASO M1",
        hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "TAMAÑO HITBOX (PELIGRO)",
        god_mode = "MODO DIOS", attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "¡IMPORTANTE! El Attack All equipará automáticamente este elemento al morir.", 
        attack_all_notify = "Recuerda usar la Guadaña para máximo daño.",
        select_element = "SELECCIONA TU ELEMENTO",
        esp = "ESP JUGADORES", boxes = "CAJAS 2D", tracers = "TRACERS", health = "BARRA DE VIDA",
        speed = "SPEED HACK", speed_val = "VELOCIDAD", jump = "SUPER JUMP", jump_val = "ALTURA DE SALTO",
        farm_players = "AUTO FARM PLAYERS", farm_desc = "Fija al jugador en el cielo y ataca automáticamente.",
        silent_collect = "AUTO-RECOLECCIÓN SILENCIOSA",
        dev_zone = "ZONA DE DESARROLLADOR", pass = "CONTRASEÑA DE PRUEBAS", unlock = "DESBLOQUEAR PRUEBA", destroy_ui = "DESTRUIR UI", lang_sel = "CAMBIAR IDIOMA", lang_desc = "Selecciona un idioma y vuelve a ejecutar."
    },
    ["en"] = {
        title = "FROGGY HUB", subtitle = "Elemental Arena | Player Farm Update",
        tab_main = "MAIN", tab_combat = "COMBAT", tab_visual = "VISUAL", tab_movement = "MOVEMENT", tab_farm = "AUTO FARM", tab_config = "CONFIG",
        rejoin = "REJOIN SERVER", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
        hitbox = "HITBOX EXPANDER (35 STUDS)", hitbox_size = "HITBOX SIZE (DANGER)",
        god_mode = "GOD MODE", attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "IMPORTANT! Attack All will auto-equip this element upon death.", 
        attack_all_notify = "Remember to use the Scythe for max damage.",
        select_element = "SELECT YOUR ELEMENT",
        esp = "PLAYER ESP", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "SPEED", jump = "SUPER JUMP", jump_val = "JUMP POWER",
        farm_players = "AUTO FARM PLAYERS", farm_desc = "Anchors player in the sky and attacks automatically.",
        silent_collect = "SILENT AUTO-COLLECT",
        dev_zone = "DEVELOPER ZONE", pass = "TEST PASSWORD", unlock = "UNLOCK TEST", destroy_ui = "DESTROY UI", lang_sel = "CHANGE LANGUAGE", lang_desc = "Select a language and re-execute."
    },
    ["fil"] = {
        title = "FROGGY HUB", subtitle = "Elemental Arena | Player Farm Update",
        tab_main = "PANGUNAHIN", tab_combat = "LABANAN", tab_visual = "BISWAL", tab_movement = "GALAW", tab_farm = "AUTO FARM", tab_config = "KONFIG",
        rejoin = "SUMALI ULIT", auto_combat = "AUTO COMBAT (M1)", m1_delay = "M1 DELAY",
        hitbox = "HITBOX EXPANDER", hitbox_size = "LAKI NG HITBOX",
        god_mode = "GOD MODE", attack_all = "ATTACK ALL (AUTO)", 
        attack_all_warn = "MAHALAGA! Awtomatikong i-e-equip ang elementong ito kapag namatay.", 
        attack_all_notify = "Tandaan na gumamit ng Scythe para sa max damage.",
        select_element = "PUMILI NG ELEMENTO",
        esp = "ESP NG PLAYERS", boxes = "2D BOXES", tracers = "TRACERS", health = "HEALTH BAR",
        speed = "SPEED HACK", speed_val = "BILIS", jump = "SUPER JUMP", jump_val = "TAAS NG TALON",
        farm_players = "AUTO FARM PLAYERS", farm_desc = "Inaayos ang player sa langit at awtomatikong umaatake.",
        silent_collect = "SILENT AUTO-COLLECT",
        dev_zone = "DEV ZONE", pass = "PASSWORD", unlock = "I-UNLOCK", destroy_ui = "IRISAN ANG UI", lang_sel = "PALITAN ANG WIKA", lang_desc = "Pumili ng wika at i-execute ulit."
    }
}

local function getSystemLanguage()
    local locale = "en"
    pcall(function()
        local id = LocalPlayer.LocaleId:lower()
        if id:find("es") then locale = "es"
        elseif id:find("fil") or id:find("tl") then locale = "fil"
        else locale = "en" end
    end)
    return locale
end

local currentLang = getSystemLanguage()
if isfile and readfile then
    local ok, savedLang = pcall(function() return readfile("FroggyLang.txt") end)
    if ok and Translations[savedLang] then currentLang = savedLang end
end

local function L(key) return Translations[currentLang][key] or Translations["en"][key] or key end

-- Elementos permitidos para el Farm (Melee)
local FarmElements = {
    "energy", "fuego", "agua", "hielo", "tierra", "aire", "oscuridad", 
    "lava", "veneno", "hierro", "espiritu", "destruccion", "cristal", "sonido", 
    "aurora", "fenix", "caos", "tecnología", "diamante", "demon", "ilusion", "relampago"
}

-- ==========================================
-- 2. CARGAMOS DISEÑO Y ASSETS
-- ==========================================
local UI_Library = loadstring(game:HttpGet(ROOT .. "design.lua"))()
local Assets = loadstring(game:HttpGet(ROOT .. "assets.lua"))()

local Window = UI_Library.CreateWindow({ Title = L("title"), Subtitle = L("subtitle") })
Assets.Extend(Window)

-- 3. CREAMOS LAS PESTAÑAS
local TabMain = Window:CreateTab(L("tab_main"))
local TabCombat = Window:CreateTab(L("tab_combat"))
local TabVisual = Window:CreateTab(L("tab_visual"))
local TabMovement = Window:CreateTab(L("tab_movement"))
local TabFarm = Window:CreateTab(L("tab_farm"))
local TabConfig = Window:CreateTab(L("tab_config"))

-- ==========================================
-- 4. DESCARGA DE MÓDULOS
-- ==========================================
local folder = "ElementalMagicArena/"

local function download(name, key)
    local url = ROOT .. folder .. name .. "?v=" .. os.time()
    local ok, res = pcall(game.HttpGet, game, url)
    if ok and type(res) == "string" and #res > 0 and res:sub(1,3) ~= "404" then
        local fnOk, fn = pcall(loadstring, res)
        if fnOk and type(fn) == "function" then pcall(fn) end
    else
        warn("❌ Could not download " .. name)
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

-- ==========================================
-- 5. CONECTAMOS LOS BOTONES A LA UI
-- ==========================================

-- === MAIN ===
TabMain:AddButton(L("rejoin"), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- === COMBAT ===
if CombC then
    TabCombat:AddToggle(L("auto_combat"), CombC.Enabled, function(state) CombC.Enabled = state end)
    TabCombat:AddSlider(L("m1_delay"), 0.1, 1.0, CombC.M1Delay or 0.3, function(val) CombC.M1Delay = val end)
end

local hitboxSlider = nil
if HitC then
    TabCombat:AddToggle(L("hitbox"), HitC.Enabled, function(state) HitC.Enabled = state end)
    hitboxSlider = TabCombat:AddSliderEx(L("hitbox_size"), 35, 500, 35, function(val) HitC.Size = val end, "lily")
    if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Visible = false end
end

if AttackAllC then
    TabCombat:AddSection(L("god_mode"))
    TabCombat:AddToggle(L("attack_all"), AttackAllC.Enabled, function(state)
        AttackAllC.Enabled = state
        if state then Assets.Notify({Title = L("god_mode"), Text = L("attack_all_notify"), Type = "warn"}) end
    end)
    
    TabCombat:AddDropdown(L("select_element"), FarmElements, AttackAllC.SelectedElement, function(val)
        AttackAllC.SelectedElement = val
        Assets.Notify({Title = "Element Selected", Text = val, Type = "success"})
    end)
    
    TabCombat:AddInfo(L("attack_all_warn"), "danger")
end

-- === VISUAL ===
if EspC then
    TabVisual:AddToggle(L("esp"), EspC.Enabled, function(state) EspC.Enabled = state end)
    TabVisual:AddToggle(L("boxes"), EspC.Boxes, function(state) EspC.Boxes = state end)
    TabVisual:AddToggle(L("tracers"), EspC.Tracers, function(state) EspC.Tracers = state end)
    TabVisual:AddToggle(L("health"), EspC.HealthBar, function(state) EspC.HealthBar = state end)
end

-- === MOVEMENT ===
if MoveC then
    TabMovement:AddToggle(L("speed"), MoveC.SpeedEnabled, function(state) MoveC.SpeedEnabled = state end)
    TabMovement:AddSlider(L("speed_val"), 16, 200, MoveC.Speed or 60, function(val) MoveC.Speed = val end)
    TabMovement:AddToggle(L("jump"), MoveC.JumpEnabled, function(state) MoveC.JumpEnabled = state end)
    TabMovement:AddSlider(L("jump_val"), 50, 300, MoveC.JumpPower or 100, function(val) MoveC.JumpPower = val end)
end

-- === AUTO FARM ===
if FarmC then
    TabFarm:AddSection(L("farm_players"))
    TabFarm:AddToggle(L("farm_players"), FarmC.Enabled, function(state)
        FarmC.Enabled = state
        if state then Assets.Notify({Title = "Farm", Text = "Farmeo Iniciado", Type = "success"})
        else Assets.Notify({Title = "Farm", Text = "Farmeo Detenido", Type = "warn"}) end
    end)
    
    TabFarm:AddDropdown(L("select_element"), FarmElements, FarmC.SelectedElement, function(val)
        FarmC.SelectedElement = val
        Assets.Notify({Title = "Farm Element", Text = "Usando: " .. val, Type = "info"})
    end)
    
    TabFarm:AddInfo(L("farm_desc"), "info")
end

-- === CONFIG ===
if SilentCollectC then
    TabConfig:AddSection(L("utilities"))
    TabConfig:AddToggle(L("silent_collect"), true, function(state)
        SilentCollectC.Enabled = state
        if state then Assets.Notify({Title = L("utilities"), Text = L("silent_collect") .. ": ON", Type = "success"})
        else Assets.Notify({Title = L("utilities"), Text = L("silent_collect") .. ": OFF", Type = "warn"}) end
    end)
    TabConfig:AddInfo("Collects Diamonds and Souls automatically in the background.", "info")
end

TabConfig:AddSection(L("lang_sel"))
TabConfig:AddDropdown(L("lang_sel"), {"es", "en", "fil"}, currentLang, function(val)
    if writefile then pcall(function() writefile("FroggyLang.txt", val) end) end
    Assets.Notify({Title = "Language", Text = L("lang_desc"), Type = "info", Duration = 5})
end)

TabConfig:AddSection(L("dev_zone"))
local passBox = TabConfig:AddTextBox(L("pass"), "...", function() end, { ClearButton = true })
local unlockBtn = TabConfig:AddButtonEx(L("unlock"), function()
    if passBox:Get() == "froggy_testing_2026" then
        Assets.Notify({Title = "OK", Text = L("dev_zone"), Type = "warn"})
        passBox.Instance.Visible = false
        if unlockBtn and unlockBtn.Instance then unlockBtn.Instance.Visible = false end
        if hitboxSlider and hitboxSlider.Instance then hitboxSlider.Instance.Visible = true end
    else
        Assets.Notify({Title = "Error", Text = "Wrong password", Type = "danger"})
        passBox:Set("")
    end
end, "wood", "md")

TabConfig:AddButton(L("destroy_ui"), function()
    Window:Destroy()
end)

print("[Main] Froggy Hub (Player Farm Update) cargado con éxito.")
