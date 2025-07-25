-- Configuración centralizada
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_OBJECT = "Ballerina.Capuccina",
    JOB_LIST_URL = "https://raw.githubusercontent.com/LeyendaZero/StealBrainrot/main/web/joblist.json",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
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
