

-- alt_detector.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_NAME = "BanditoBorbitto", -- Nombre exacto del modelo
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    SEARCH_DEPTH = 5, -- Profundidad de búsqueda recursiva
    DEBUG_MODE = true -- Muestra mensajes detallados
}

-- 🛠️ Servicios esenciales
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Búsqueda ultra-precisaa
local function deepFindTarget()
    local function scan(parent, depth)
        if depth > CONFIG.SEARCH_DEPTH then return nil end
        
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == CONFIG.TARGET_NAME then
                if CONFIG.DEBUG_MODE then
                    print("✅ OBJETIVO ENCONTRADO:", child:GetFullName())
                end
                return child
            end
            
            -- Búsqueda recursiva en subcarpetas
            if child:IsA("Folder") or child:IsA("Model") then
                local found = scan(child, depth + 1)
                if found then return found end
            end
        end
        return nil
    end
    
    return scan(workspace, 0)
end

-- 📨 Sistema de reportes mejorado
local function safeSendWebhook(data)
    local success, err = pcall(function()
        local payload = HttpService:JSONEncode(data)
        if syn and syn.request then
            syn.request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        else
            HttpService:PostAsync(CONFIG.WEBHOOK_URL, payload)
        end
    end)
    
    if not success and CONFIG.DEBUG_MODE then
        warn("⚠️ Error en webhook (seguro):", err)
    end
end

-- 🧪 Verificación completa
local function fullScan()
    print("\n=== ESCANEO INICIADO ===")
    
    -- 1. Verificar carga del juego
    if not workspace:IsDescendantOf(game) then
        print("❌ El workspace no está cargado correctamente")
        return false
    end

    -- 2. Búsqueda profunda
    local target = deepFindTarget()
    
    -- 3. Reporte de resultados
    if target then
        local position = target:GetPivot().Position
        print("🎯 OBJETIVO LOCALIZADO EN:", position)
        
        safeSendWebhook({
            embeds = {{
                title = "DETECCIÓN CONFIRMADA",
                description = "El objetivo fue encontrado con éxito",
                color = 65280,
                fields = {
                    {name = "Objeto", value = target:GetFullName()},
                    {name = "Posición", value = tostring(position)},
                    {name = "Servidor", value = game.JobId}
                }
            }}
        })
        return true
    else
        print("❌ Objeto no encontrado después de búsqueda exhaustiva")
        
        -- Reporte de servidor vacío
        safeSendWebhook({
            embeds = {{
                title = "OBJETIVO NO ENCONTRADO",
                description = "Búsqueda completada sin resultados",
                color = 16711680,
                fields = {
                    {name = "Servidor", value = game.JobId}
                }
            }}
        })
        return false
    end
end

-- 🚀 Sistema de conexión mejorado
local function joinServer(jobId)
    local attempts = 0
    local maxAttempts = 3
    
    repeat
        attempts += 1
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)
        
        if success then
            repeat task.wait(1) until game:IsLoaded()
            
            -- Espera adicional para assets críticos
            local waitTime = 0
            while not workspace:FindFirstChildWhichIsA("Model") and waitTime < 10 do
                waitTime += 1
                task.wait(1)
            end
            
            return fullScan()
        else
            print(string.format("⚠️ Intento %d/%d fallido", attempts, maxAttempts))
            task.wait(3)
        end
    until attempts >= maxAttempts
    
    return false
end

-- 📡 Obtener servidores activos (alternativa segura)
local function getPublicServers()
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=50", 
            CONFIG.GAME_ID)
        )
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            table.insert(servers, server.id)
        end
    else
        print("⚠️ Error al obtener servidores:", response)
    end
    
    return servers
end

-- 🎯 Ejecución principal
if CONFIG.DEBUG_MODE then
    print("=== MODO DEBUG ACTIVADO ===")
    print("Objetivo buscado:", CONFIG.TARGET_NAME)
    print("Webhook configurado:", CONFIG.WEBHOOK_URL)
end

-- Opción 1: Escanear servidor actual
fullScan()

-- Opción 2: Unirse a servidores aleatorios (descomentar para usar)
--[[
local servers = getPublicServers()
for _, jobId in ipairs(servers) do
    if joinServer(jobId) then break end
    task.wait(5)
end
]]
