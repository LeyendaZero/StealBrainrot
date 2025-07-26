local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    MAIN_ACCOUNT = "ZeroLeyends"
}

local function waitForNotification()
    -- Implementación real requeriría un bot de Discord
    -- Esta es una versión simplificada
    warn("Configura un bot de Discord para monitorización automática")
    warn("Revisa los mensajes manualmente mientras tanto")
    while true do task.wait(10) end
end

if game:GetService("Players").LocalPlayer.Name == CONFIG.MAIN_ACCOUNT then
    waitForNotification()
else
    warn("Este script es solo para la cuenta principal")
end
