--// ChatMessage.lua - Froggy Hub (Anti-Bloqueo de Chat)
local env = (getgenv and getgenv()) or _G
if env.__BF_CHAT_CLEANUP then pcall(env.__BF_CHAT_CLEANUP) end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local msg = "FroggyHub On Top! Hecho por Froggy / kinnnnj8"
local activeConnections = {}

-- Función para crear la burbuja de chat sobre la cabeza
local function showFloatingBubble()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return end
    
    -- Si ya existe, no crear otra
    if head:FindFirstChild("FroggyChatFallback") then return end
    
    local bg = Instance.new("BillboardGui")
    bg.Name = "FroggyChatFallback"
    bg.Adornee = head
    bg.Size = UDim2.fromOffset(240, 60)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    bg.Parent = head

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "🐸 FroggyHub On Top!\nHecho por Froggy / kinnnnj8"
    text.TextColor3 = Color3.fromRGB(110, 220, 90)
    text.TextStrokeTransparency = 0
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextScaled = true
    text.Parent = bg

    -- Se destruye automáticamente a los 10 segundos
    task.delay(10, function() 
        if bg and bg.Parent then bg:Destroy() end 
    end)
end

-- Función que intenta enviar el mensaje de todas las formas posibles
local function trySendChat()
    local success = false

    -- 1. Chat Nuevo (TextChatService)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            local general = channels and channels:FindFirstChild("RBXGeneral")
            if general then
                general:SendAsync(msg)
                success = true
            end
        end
    end)

    -- 2. Chat Viejo (SayMessageRequest)
    if not success then
        pcall(function()
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            local sayRequest = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
            if sayRequest then
                sayRequest:FireServer(msg, "All")
                success = true
            end
        end)
    end

    -- 3. Chat Viejo (SetCore)
    if not success then
        pcall(function()
            StarterGui:SetCore("ChatSendMessage", msg)
            success = true
        end)
    end

    -- 4. Método nuclear (VirtualUser - simula que tú escribes)
    if not success then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:TypeKey(Enum.KeyCode.Slash)
            task.wait(0.1)
            for i = 1, #msg do
                -- No se puede escribir letra por letra fácilmente sin executors avanzados, 
                -- pero esto es un intento desesperado.
            end
        end)
    end

    -- 5. Si todo falla, o si el chat es custom, mostramos la burbuja
    if not success then
        print("[Froggy] Chat bloqueado por el juego. Mostrando burbuja flotante.")
        showFloatingBubble()
    end
end

-- Escuchar cuando el personaje aparece (para sobrevivir a los resets y al duelo)
local function onCharacterAdded(char)
    task.wait(2) -- Esperar a que el personaje cargue bien
    trySendChat()
end

table.insert(activeConnections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded))

-- Ejecución inicial
task.spawn(function()
    task.wait(3)
    trySendChat()
    
    -- Reintentar un par de veces por si el chat tarda en cargar
    for i = 1, 5 do
        task.wait(2)
        trySendChat()
    end
end)

env.__BF_CHAT_CLEANUP = function()
    for _, c in ipairs(activeConnections) do pcall(function() c:Disconnect() end) end
    local char = LocalPlayer.Character
    local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
    local bg = head and head:FindFirstChild("FroggyChatFallback")
    if bg then bg:Destroy() end
    env.__BF_CHAT_CLEANUP = nil
end
