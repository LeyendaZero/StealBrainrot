-- Configuración centralizada
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_OBJECT = "Ballerina.Capuccina",
    JOB_LIST_URL = "https://raw.githubusercontent.com/tuusuario/StealBrainrot/main/web/joblist.json",
    WEBHOOK_URL = "https://discord.com/api/webhooks/...",
    SEARCH_RADIUS = 50,
    CHECK_INTERVAL = 30
}

-- Código principal del hunter (similar al anterior pero mejorado)
local function main()
    while true do
        local jobs = getJobsFromGitHub(CONFIG.JOB_LIST_URL)
        for _, jobId in ipairs(jobs) do
            if not isJobChecked(jobId) then -- Evita revisar jobs ya chequeados
                attemptTeleportAndSearch(jobId)
            end
        end
        wait(CONFIG.CHECK_INTERVAL)
    end
end

main()
