-- Script para la cuenta principal (monitor de Discord)

local DISCORD_WEBHOOK = "TU_WEBHOOK_PERSONAL"
local GAME_ID = 109983668079237

-- Función para verificar mensajes en el webhook
function checkWebhookForAlerts()
    local response = requestFunc({
        Url = DISCORD_WEBHOOK.."/messages?limit=1",
        Method = "GET",
        Headers = {["Authorization"] = "Bot TOKEN_AQUI"} -- Necesitarás un bot token
    })
    
    local messages = game:GetService("HttpService"):JSONDecode(response.Body)
    for _, msg in ipairs(messages) do
        if msg.embeds and msg.embeds[1].title == "🎯 Objetivo Encontrado" then
            local jobId = msg.embeds[1].fields[1].value
            return jobId
        end
    end
    return nil
end

-- Loop principal para monitorear
while true do
    local foundJobId = checkWebhookForAlerts()
    if foundJobId then
        print("⚠️ Objetivo encontrado en JobID:", foundJobId)
        TeleportService:TeleportToPlaceInstance(GAME_ID, foundJobId, LocalPlayer)
        break
    end
    wait(30) -- Revisa cada 30 segundos
end
