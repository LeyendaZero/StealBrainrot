-- alt_tester.lua
-- Versión de prueba para una sola cuenta ALT

-- ⚙️ CONFIGURACIÓN BÁSICA (Ajusta estos valores)
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_OBJECT = "Ballerina.Capuccina",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    TEST_SERVER = "ID_DE_UN_SERVIDOR_ESPECÍFICO" -- Opcional: para probar en un server concreto
}

-- 🛠️ INICIALIZACIÓN
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 🔍 FUNCIÓN DE BÚSQUEDA SIMPLIFICADA
local function quickSearch()
    print("🔍 Buscando objetivo rápido...")
    local target = workspace:FindFirstChild(CONFIG.TARGET_OBJECT, true)
    if target then
        local position = target:GetPivot().Position
        print("✅ ¡OBJETIVO ENCONTRADO! Posición:", position)
        return target, position
    end
    print("❌ Objetivo no encontrado en este servidor")
    return nil
end

-- 📨 REPORTE SIMPLIFICADO A DISCORD
local function sendTestReport(found, position, jobId)
    local status = found and "ENCONTRADO" or "NO ENCONTRADO"
    local color = found and 65280 or 16711680 -- Verde o Rojo
    
    local payload = {
        embeds = {{
            title = "PRUEBA ALT - RESULTADO",
            description = "Resultado de la prueba con una sola ALT",
            color = color,
            fields = {
                {name = "ESTADO", value = status},
                {name = "SERVER ID", value = jobId or "N/A"},
                {name = "POSICIÓN", value = position and tostring(position) or "N/A"},
                {name = "CUENTA ALT", value = LocalPlayer.Name}
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    
    local success, err = pcall(function()
        HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(payload))
    end)
    
    if success then
        print("📨 Reporte enviado a Discord")
    else
        warn("⚠️ Error al enviar reporte:", err)
    end
end

-- 🧪 MODO DE PRUEBA
local function testSingleServer(jobId)
    print("\n=== INICIANDO PRUEBA ===")
    print("🛫 Uniéndose al servidor:", jobId)
    
    local teleportSuccess = pcall(function()
        TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
    end)
    
    if not teleportSuccess then
        print("⚠️ Error al unirse al servidor")
        sendTestReport(false, nil, jobId)
        return false
    end
    
    repeat task.wait() until game:IsLoaded()
    print("✅ Servidor cargado. Iniciando escaneo...")
    task.wait(5) -- Espera para asegurar carga
    
    local target, position = quickSearch()
    sendTestReport(target ~= nil, position, jobId)
    
    return target ~= nil
end

-- 🚀 EJECUCIÓN (Elige un método)

-- Método 1: Probar un servidor específico (recomendado para pruebas)
if CONFIG.TEST_SERVER and #CONFIG.TEST_SERVER > 0 then
    print("🧪 MODO PRUEBA - SERVIDOR ESPECÍFICO")
    testSingleServer(CONFIG.TEST_SERVER)
    return
end

-- Método 2: Probar 3 servidores aleatorios (alternativa)
print("🧪 MODO PRUEBA - SERVIDORES ALEATORIOS")
local testServers = {
    "ID_SERVER_1",  -- Reemplaza con IDs reales
    "ID_SERVER_2",
    "ID_SERVER_3"
}

for i, serverId in ipairs(testServers) do
    if testSingleServer(serverId) then
        print("🎯 Prueba exitosa! Objetivo encontrado.")
        break
    end
    if i < #testServers then
        print("\n⏭️ Probando siguiente servidor...")
    end
end

print("\n=== PRUEBA FINALIZADA ===")
