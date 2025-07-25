-- ⚙️ CONFIGURACIÓN
local GAME_ID = 109983668079237
local TARGET_OBJECT = "Ballerina.Capuccina" -- Objeto específico a buscar
local JOB_LIST_URL = "https://leyendazero.github.io/StealBrainrot/joblist.json"
local MAIN_DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA"
local ALERT_DISCORD_WEBHOOK = "WEBHOOK_PARA_ALERTAS_PRINCIPALES"

-- 📡 FUNCIONES
local requestFunc = (syn and syn.request) or (http and http.request) or (http_request) or (fluxus and fluxus.request)
if not requestFunc then
    warn("❌ Tu ejecutor no soporta funciones HTTP.")
    return
end

function getJobsFromGitHub()
    local response = requestFunc({
        Url = JOB_LIST_URL,
        Method = "GET"
    })
    return game:GetService("HttpService"):JSONDecode(response.Body).jobs
end

function findTargetObject()
    -- Busca el objeto específico en el workspace
    local target = workspace:FindFirstChild(TARGET_OBJECT, true)
    if target then
        return target, target:GetPivot().Position
    end
    return nil
end

function reportFoundTarget(jobId, position)
    local payload = {
        content = "@everyone", -- Notifica a todos
        embeds = {{
            title = "🎯 Objetivo Encontrado",
            description = "¡Se encontró el objeto buscado!",
            color = 65280,
            fields = {
                { name = "Job ID", value = jobId },
                { name = "Cuenta", value = LocalPlayer.Name },
                { name = "Posición", value = tostring(position) },
                { name = "Enlace Directo", value = "roblox://placeId="..GAME_ID.."&gameInstanceId="..jobId }
            }
        }}
    }
    
    -- Envía a ambos webhooks
    for _, webhook in pairs({MAIN_DISCORD_WEBHOOK, ALERT_DISCORD_WEBHOOK}) do
        requestFunc({  
            Url = webhook,  
            Method = "POST",  
            Headers = {["Content-Type"] = "application/json"},  
            Body = game:GetService("HttpService"):JSONEncode(payload)  
        })
    end
end

-- 🔁 LOOP PRINCIPAL
while true do
    local jobs = getJobsFromGitHub()
    for _, jobId in ipairs(jobs) do
        print("🔁 Saltando a JobID:", jobId)
        TeleportService:TeleportToPlaceInstance(GAME_ID, jobId, LocalPlayer)
        
        repeat wait(2) until game:IsLoaded()
        wait(5) -- Espera adicional para que todo cargue
        
        local target, pos = findTargetObject()
        if target then
            print("✅ Objetivo encontrado:", target:GetFullName())
            reportFoundTarget(jobId, pos)
            return -- Termina este script, el objetivo fue encontrado
        else
            print("❌ Objetivo no encontrado. Continuando...")
            wait(2)
        end
    end
    wait(10) -- Espera antes de revisar la lista de jobs nuevamente
end
