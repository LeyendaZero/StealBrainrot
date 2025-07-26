local CONFIG = {
    GAME_ID = 109983668079237,
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    JOB_LIST_URL = "https://tugithub.github.io/StealBrainrot/web/joblist.json",
    TARGET_OBJECT = "Ballerina.Capuccina",
    CHECK_DELAY = 5
}

local function findTarget()
    local target = workspace:FindFirstChild(CONFIG.TARGET_OBJECT, true)
    if target then
        return target:GetPivot().Position
    end
end

local function reportFinding(jobId, position)
    local payload = {
        content = "@here 🎯 OBJETIVO ENCONTRADO",
        embeds = {{
            title = "Brainrot Localizado",
            description = "Objetivo encontrado en el servidor:",
            fields = {
                {name = "Job ID", value = jobId},
                {name = "Posición", value = tostring(position)},
                {name = "Enlace", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId)}
            },
            color = 65280
        }}
    }
    game:GetService("HttpService"):PostAsync(CONFIG.WEBHOOK_URL, game:GetService("HttpService"):JSONEncode(payload))
end

-- Código principal
while true do
    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet(CONFIG.JOB_LIST_URL)).jobs
    for _, jobId in ipairs(servers) do
        local success = pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(CONFIG.GAME_ID, jobId)
        end)
        
        if success then
            repeat task.wait() until game:IsLoaded()
            task.wait(3)
            
            local pos = findTarget()
            if pos then
                reportFinding(jobId, pos)
                return
            end
        end
        task.wait(CONFIG.CHECK_DELAY)
    end
    task.wait(60)
end
