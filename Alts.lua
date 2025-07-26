-- alt_system.lua
-- Sistema especializado para cuentas alternativas (Hunter)

-- ⚙️ CONFIGURACIÓN (Ajusta estos valores)
local CONFIG = {
    GAME_ID = 109983668079237, -- ID del juego Roblox
    TARGET_OBJECT = "Ballerina.Capuccina", -- Objeto a buscar
    WEBHOOK_URL = "https://discord.com/api/webhooks/tu_webhook_real", -- Webhook real de Discord
    JOB_LIST_URL = "https://raw.githubusercontent.com/tuusuario/StealBrainrot/main/web/joblist.json",
    SEARCH_DELAY = 5, -- Tiempo entre búsquedas (segundos)
    LOAD_WAIT_TIME = 10, -- Tiempo de espera después de unirte a un servidor
    MAX_SERVERS = 50 -- Máximo de servidores a analizar
}

-- 🛠️ INICIALIZACIÓN DE SERVICIOS
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 📡 FUNCIÓN PARA OBTENER SERVIDORES ACTIVOS
local function fetchActiveServers()
    local success, response = pcall(function()
        return game:HttpGet(CONFIG.JOB_LIST_URL)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        return data.jobs or {}
    else
        warn("⚠️ Error al obtener servidores:", response)
        return {}
    end
end

-- 🔍 BÚSQUEDA RECURSIVA DEL OBJETIVO
local function locateTarget()
    local function search(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == CONFIG.TARGET_OBJECT then
                return child
            end
            local found = search(child)
            if found then return found end
        end
        return nil
    end
    
    return search(workspace)
end

-- 📨 REPORTAR HALLAZGO A DISCORD
local function sendDiscoveryReport(jobId, position)
    local embed = {
        title = "🎯 OBJETIVO DETECTADO",
        description = "Una cuenta ALT ha encontrado el objetivo!",
        color = 65280, -- Verde
        fields = {
            {name = "SERVER ID", value = jobId, inline = true},
            {name = "POSICIÓN", value = tostring(position), inline = true},
            {name = "DETECTADO POR", value = LocalPlayer.Name},
            {name = "UNIRSE", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId)}
        },
        timestamp = DateTime.now():ToIsoDate()
    }

    local payload = {
        content = "@everyone Objetivo localizado!",
        embeds = {embed}
    }

    local success, err = pcall(function()
        HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(payload))
    end)
    
    if not success then
        warn("⚠️ Error al reportar hallazgo:", err)
    end
end

-- 🔄 CICLO PRINCIPAL DE BÚSQUEDA
local function startHunting()
    print("🛫 Iniciando modo Hunter en cuenta ALT...")
    
    while true do
        local servers = fetchActiveServers()
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores. Reintentando en 1 minuto...")
            task.wait(60)
            continue
        end

        print(string.format("📡 Obtenidos %d servidores activos", #servers))
        
        for _, jobId in ipairs(servers) do
            print("🔍 Analizando servidor:", jobId)
            
            -- Teletransporte seguro
            local teleportSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
            end)
            
            if not teleportSuccess then
                print("⚠️ Error al unirse al servidor. Continuando...")
                task.wait(CONFIG.SEARCH_DELAY)
                continue
            end
            
            -- Esperar carga completa
            repeat task.wait() until game:IsLoaded()
            print("✅ Servidor cargado. Buscando objetivo...")
            task.wait(CONFIG.LOAD_WAIT_TIME)
            
            -- Búsqueda del objetivo
            local target = locateTarget()
            if target then
                local targetPos = target:GetPivot().Position
                print(string.format("🎯 OBJETIVO ENCONTRADO en posición: %s", tostring(targetPos)))
                sendDiscoveryReport(jobId, targetPos)
                return -- Finalizar después de encontrar
            else
                print("❌ Objetivo no encontrado. Continuando...")
            end
            
            task.wait(CONFIG.SEARCH_DELAY)
        end
        
        print("🔁 Reiniciando ciclo de búsqueda...")
        task.wait(30) -- Espera antes de refrescar la lista
    end
end

-- 🚀 INICIAR SISTEMA
startHunting()
