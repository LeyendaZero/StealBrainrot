-- bot_scanner.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_NAME = "BallerinaCappuccina",
    DISCORD_BOT_TOKEN = "MTI4OTAxNTQwMzYyNzk0MTkxOQ.GUDe_R.PYFHfDlZZZViaE7dND0GrHxVVTUJydneVIPIcM", -- Obtener del Developer Portal de Discord
    CONTROL_CHANNEL_ID = "1394088719421673675", -- Canal para enviar notificaciones
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 30,
    MAX_SERVERS = 50,
    DEBUG_MODE = true
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Escáner mejorado (sin cambios)
local function deepSearch()
    -- ... (el mismo código de búsqueda anterior)
    return targets
end

-- 📡 Comunicación con el bot
local function sendToBot(message, embedData)
    local payload = {
        content = message,
        embeds = embedData and {embedData} or nil
    }

    local success, err = pcall(function()
        if not syn then error("Se requiere Synapse X o equivalente") end
        
        syn.request({
            Url = "https://discord.com/api/v10/channels/"..CONFIG.CONTROL_CHANNEL_ID.."/messages",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bot "..CONFIG.DISCORD_BOT_TOKEN,
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not success and CONFIG.DEBUG_MODE then
        warn("Error al enviar al bot:", err)
    end
    return success
end

-- 🎯 Generador de embeds
local function createTargetEmbed(jobId, targets)
    local embed = {
        title = "🔍 DETECCIÓN CONFIRMADA",
        description = string.format("**%s** encontrado en el servidor", CONFIG.TARGET_NAME),
        color = 65280,
        fields = {
            {
                name = "📌 Ubicación",
                value = string.format("```%s```", tostring(targets[1].position)),
                inline = true
            },
            {
                name = "🆔 Server ID",
                value = string.format("```%s```", jobId),
                inline = true
            },
            {
                name = "🔗 Enlace Directo",
                value = string.format("[Unirse al servidor](roblox://placeId=%d&gameInstanceId=%s)", 
                    CONFIG.GAME_ID, jobId)
            }
        },
        footer = {
            text = string.format("Detectado por %s • %s", 
                LocalPlayer.Name, os.date("%X"))
        }
    }
    return embed
end

-- 🔄 Sistema principal modificado
local function botScan()
    if CONFIG.DEBUG_MODE then
        sendToBot("🟢 Sistema de escaneo iniciado")
    end

    while true do
        local servers = getPublicServers() -- Función del código anterior
        if #servers == 0 then
            sendToBot("⚠️ No se encontraron servidores públicos")
            task.wait(60)
            continue
        end

        for i, serverId in ipairs(servers) do
            if CONFIG.DEBUG_MODE then
                sendToBot(string.format("🔄 Escaneando servidor %d/%d", i, #servers))
            end

            local joinSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, serverId, LocalPlayer)
            end)

            if joinSuccess then
                repeat task.wait(1) until game:IsLoaded()
                task.wait(5)

                local targets = deepSearch()
                if #targets > 0 then
                    local embed = createTargetEmbed(serverId, targets)
                    sendToBot("@everyone 🎯 OBJETIVO DETECTADO", embed)
                    break
                end
            end

            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        task.wait(60)
    end
end

-- 🚀 Inicialización
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

-- Verificar credenciales primero
if CONFIG.DISCORD_BOT_TOKEN == "TU_BOT_TOKEN_AQUI" then
    warn("❌ Configura el token del bot primero")
else
    sendToBot("🔍 Iniciando escaneo pasivo...")
    botScan()
end
