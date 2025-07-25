local CONFIG = {
    GAME_ID = 109983668079237,
    WEBHOOK_URL = "https://discord.com/api/webhooks/...",
    CHECK_INTERVAL = 15
}

-- Monitorea el webhook y teletransporta cuando encuentra algo
local function monitorWebhook()
    while true do
        local foundJob = checkForNewFinds()
        if foundJob then
            teleportToJob(foundJob)
            break
        end
        wait(CONFIG.CHECK_INTERVAL)
    end
end

monitorWebhook()
