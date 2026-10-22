--// ChatMessage.lua - Froggy Hub
local env = (getgenv and getgenv()) or _G
if env.__BF_CHAT_CLEANUP then pcall(env.__BF_CHAT_CLEANUP) end

local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local msg = "FroggyHub On Top! Hecho por Froggy / kinnnnj8"

-- Hilo independiente con sistema de reintentos
local thread = task.spawn(function()
    -- Intentamos 15 veces (30 segundos máximo) por si el chat tarda en cargar
    for i = 1, 15 do
        task.wait(2)
        local success = false

        -- 1. Chat Nuevo
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

        -- 2. Chat Viejo (Fallback)
        if not success then
            pcall(function()
                StarterGui:SetCore("ChatSendMessage", msg)
                success = true
            end)
        end

        -- Si se envió, cortamos el bucle
        if success then
            break
        end
    end
end)

env.__BF_CHAT_CLEANUP = function()
    if thread then task.cancel(thread) end
    env.__BF_CHAT_CLEANUP = nil
end
