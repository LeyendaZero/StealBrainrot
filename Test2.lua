-- alt_hunter_ultimate.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "BombardiroCrocodilo",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 15,
    MAX_SERVERS = 50,
    DEBUG_MODE = true
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔄 Versiones alternativas de HTTP request
local function safeHttpPost(url, data)
    local jsonData = HttpService:JSONEncode(data)
    
    -- Intentar con syn.request primero
    if syn and syn.request then
        local response = syn.request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        return true
    end
    
    -- Intentar con http_post (alternativa común)
    if http_post then
        local success, response = pcall(http_post, url, jsonData)
        return success
    end
    
    -- Último intento con HttpService (puede fallar en algunos exploits)
    local success, err = pcall(function()
        HttpService:PostAsync(url, jsonData)
    end)
    
    if not success and CONFIG.DEBUG_MODE then
        warn("⚠️ Método alternativo también falló:", err)
    end
    return success
end

-- 📨 Sistema de reporte infalible
local function sendAllResultsToDiscord(results, jobId)
    -- Primero preparar los datos esenciales
    local baseInfo = {
        username = "Bandito Hunter",
        embeds = {}
    }
    
    -- Agregar resumen inicial
    table.insert(baseInfo.embeds, {
        title = "📊 RESUMEN DE ESCANEO",
        description = string.format("**Servidor:** %s\n**Objetivos encontrados:** %d", jobId, #results),
        color = #results > 0 and 65280 or 16711680,
        fields = {
            {name = "Patrón buscado", value = CONFIG.TARGET_PATTERN},
            {name = "Radio de búsqueda", value = string.format("%d studs", CONFIG.SCAN_RADIUS)}
        }
    })
    
    -- Agregar detalles de cada objetivo encontrado (máximo 10 para evitar sobrecarga)
    for i = 1, math.min(10, #results) do
        table.insert(baseInfo.embeds, {
            title = string.format("🎯 Objeto #%d", i),
            description = results[i].name,
            color = 10181046, -- Morado
            fields = {
                {name = "Distancia", value = string.format("%.1f studs", results[i].distance)},
                {name = "Posición", value = tostring(results[i].position)},
                {name = "Enlace", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId)}
            }
        })
    end
    
    -- Enviar usando el método más seguro disponible
    local success = safeHttpPost(CONFIG.WEBHOOK_URL, baseInfo)
    
    if CONFIG.DEBUG_MODE then
        if success then
            print("📤 Reporte enviado con éxito a Discord")
        else
            warn("❌ Todos los métodos de envío fallaron")
        end
    end
end

-- 🔍 Escáner optimizado (el que ya funcionó)
local function performDeepScan()
    local found = {}
    local rootPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()
    
    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if string.find(string.lower(child.Name), string.lower(CONFIG.TARGET_PATTERN)) then
                local pos = child:GetPivot().Position
                local dist = (pos - rootPos).Magnitude
                if dist <= CONFIG.SCAN_RADIUS then
                    table.insert(found, {
                        name = child:GetFullName(),
                        position = pos,
                        distance = dist
                    })
                end
            end
            if child:IsA("Folder") or child:IsA("Model") then
                scanRecursive(child)
            end
        end
    end

    scanRecursive(Workspace)
    table.sort(found, function(a, b) return a.distance < b.distance end)
    return found
end

-- 🚀 Núcleo del sistema de búsqueda
local function startHunting()
    print("\n=== SISTEMA DE BÚSQUEDA ACTIVADO ===")
    
    while true do
        -- Obtener servidores (versión simplificada)
        local servers = {}
        local success, response = pcall(function()
            return game:HttpGet(string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?limit=%d",
                CONFIG.GAME_ID, CONFIG.MAX_SERVERS
            ))
        end)
        
        if success then
            servers = HttpService:JSONDecode(response).data
        else
            warn("⚠️ Error al obtener servidores:", response)
            task.wait(60)
            continue
        end

        -- Procesar cada servidor
        for _, server in ipairs(servers) do
            if CONFIG.DEBUG_MODE then
                print("🔄 Intentando servidor:", server.id)
            end
            
            -- Teletransporte seguro
            local joinSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, server.id, LocalPlayer)
            end)
            
            if joinSuccess then
                repeat task.wait() until game:IsLoaded()
                task.wait(5) -- Espera de carga
                
                -- Escanear y reportar
                local scanResults = performDeepScan()
                sendAllResultsToDiscord(scanResults, server.id)
                
                if #scanResults > 0 and CONFIG.DEBUG_MODE then
                    print("🎯 Objetivos encontrados:", #scanResults)
                end
            end
            
            task.wait(CONFIG.SERVER_HOP_DELAY)
        end
        
        task.wait(30) -- Espera antes de refrescar
    end
end

-- Iniciar
if LocalPlayer.Character then
    startHunting()
else
    LocalPlayer.CharacterAdded:Wait()
    startHunting()
end
