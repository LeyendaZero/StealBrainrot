-- ⚙️ CONFIGURACIÓN GLOBAL
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_OBJECT = "Ballerina.Capuccina",
    
    -- URLs externas
    JOB_LIST_URL = "https://LeyendaZero.github.io/StealBrainrot/web/joblist.json",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    
    -- Parámetros de búsqueda
    SEARCH_RADIUS = 50,
    CHECK_INTERVAL = 30,
    UPDATE_INTERVAL = 300,  -- 5 minutos
    
    -- Modo de operación (auto-detección)
    AUTO_DETECT_MODE = true  -- true = auto, false = manual
}

-- 🔍 Detección automática de modo
local function detectMode()
    if not CONFIG.AUTO_DETECT_MODE then
        return CONFIG.MODE or "hunter"
    end
    
    -- Lógica de auto-detección (ejemplo: primera cuenta es monitor)
    local playerName = game:GetService("Players").LocalPlayer.Name
    return (playerName == "TuCuentaPrincipal") and "monitor" or "hunter"
end

-- 📦 MÓDULOS PRINCIPALES
local function setupHunter()
    -- Módulo de caza (para cuentas alternativas)
    local Hunter = {}
    
    function Hunter.updateJobList()
        -- Descargar lista actualizada desde GitHub
        local response = requestFunc({Url = CONFIG.JOB_LIST_URL, Method = "GET"})
        if response and response.Body then
            return game:GetService("HttpService"):JSONDecode(response.Body).jobs or {}
        end
        return {}
    end
    
    function Hunter.searchTarget()
        -- Lógica de búsqueda del objetivo
        return workspace:FindFirstChild(CONFIG.TARGET_OBJECT, true)
    end
    
    function Hunter.run()
        while true do
            local jobs = Hunter.updateJobList()
            for _, jobId in ipairs(jobs) do
                -- Lógica de salto entre servidores
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
                -- Esperar carga y buscar objetivo
                if Hunter.searchTarget() then
                    -- Reportar hallazgo
                    requestFunc({
                        Url = CONFIG.WEBHOOK_URL,
                        Method = "POST",
                        Body = -- ... (payload de Discord)
                    })
                    return
                end
                wait(CONFIG.CHECK_INTERVAL)
            end
            wait(CONFIG.UPDATE_INTERVAL)
        end
    end
    
    return Hunter
end

local function setupMonitor()
    -- Módulo de monitoreo (para cuenta principal)
    local Monitor = {}
    
    function Monitor.checkWebhook()
        -- Lógica para leer el webhook (requiere token de bot)
        -- Implementación conceptual:
        local response = requestFunc({
            Url = CONFIG.WEBHOOK_URL.."/messages?limit=1",
            Headers = {Authorization = "Bot TU_BOT_TOKEN"}
        })
        -- ... procesar respuesta
        return foundJobId
    end
    
    function Monitor.run()
        while true do
            local jobId = Monitor.checkWebhook()
            if jobId then
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
                return
            end
            wait(CONFIG.CHECK_INTERVAL)
        end
    end
    
    return Monitor
end

-- 🚀 INICIALIZACIÓN DEL SISTEMA
local function main()
    -- Configuración inicial
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local requestFunc = (syn and syn.request) or http.request or request
    
    -- Auto-detectar modo
    local mode = detectMode()
    
    -- Ejecutar módulo correspondiente
    if mode == "hunter" then
        setupHunter().run()
    elseif mode == "monitor" then
        setupMonitor().run()
    else
        warn("Modo no reconocido")
    end
end

-- Ejecutar sistema
main()
