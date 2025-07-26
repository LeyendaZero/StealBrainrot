-- ⚙️ CONFIGURACIÓN
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_OBJECT = "Ballerina.Capuccina",
    JOB_LIST_URL = "https://raw.githubusercontent.com/LeyendaZero/StealBrainrot/main/web/joblist.json",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    SEARCH_RADIUS = 50,
    CHECK_INTERVAL = 30
}

-- 📡 FUNCIONES ESENCIALES
local requestFunc = (syn and syn.request) or (http and http.request) or (http_request) or (fluxus and fluxus.request) or request
if not requestFunc then
    warn("❌ Tu ejecutor no soporta funciones HTTP.")
    return
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Función para obtener jobs desde GitHub
local function getJobsFromGitHub(url)
    local success, response = pcall(function()
        return requestFunc({
            Url = url,
            Method = "GET"
        })
    end)
    
    if success and response.Body then
        return HttpService:JSONDecode(response.Body).jobs or {}
    else
        warn("❌ Error al obtener jobs:", response)
        return {}
    end
end

-- Función para verificar si un job ya fue chequeado
local checkedJobs = {}
local function isJobChecked(jobId)
    return checkedJobs[jobId] ~= nil
end

-- Función para buscar el objeto objetivo
local function findTargetObject()
    local target = workspace:FindFirstChild(CONFIG.TARGET_OBJECT, true)
    if target then
        return target, target:GetPivot().Position
    end
    return nil
end

-- Función para reportar hallazgos
local function reportFoundTarget(jobId, position)
    local payload = {
        content = "@everyone",
        embeds = {{
            title = "🎯 Objetivo Encontrado",
            description = "¡Se encontró el objeto buscado!",
            color = 65280,
            fields = {
                { name = "Job ID", value = jobId },
                { name = "Cuenta", value = LocalPlayer.Name },
                { name = "Posición", value = tostring(position) },
                { name = "Enlace Directo", value = "roblox://placeId="..CONFIG.GAME_ID.."&gameInstanceId="..jobId }
            }
        }}
    }
    
    requestFunc({  
        Url = CONFIG.WEBHOOK_URL,  
        Method = "POST",  
        Headers = {["Content-Type"] = "application/json"},  
        Body = HttpService:JSONEncode(payload)  
    })
end

-- Función para teletransportarse y buscar
local function attemptTeleportAndSearch(jobId)
    local success = pcall(function()
        TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
    end)
    
    if not success then
        warn("❌ Error al teletransportarse a JobID:", jobId)
        return
    end
    
    repeat wait(2) until game:IsLoaded()
    wait(5) -- Espera adicional para que todo cargue
    
    local target, pos = findTargetObject()
    if target then
        print("✅ Objetivo encontrado:", target:GetFullName())
        reportFoundTarget(jobId, pos)
        return true
    else
        print("❌ Objetivo no encontrado en JobID:", jobId)
        checkedJobs[jobId] = true
        return false
    end
end

-- Función principal
local function main()
    while true do
        local jobs = getJobsFromGitHub(CONFIG.JOB_LIST_URL)
        for _, jobId in ipairs(jobs) do
            if not isJobChecked(jobId) then
                if attemptTeleportAndSearch(jobId) then
                    return -- Termina si encuentra el objetivo
                end
            end
        end
        wait(CONFIG.CHECK_INTERVAL)
    end
end

-- Iniciar el script
main()
