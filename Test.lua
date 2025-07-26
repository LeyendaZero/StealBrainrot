
-- alt_tester.lua (Versión corregida)
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PARENT = "BallerinaCappuccina", -- Nombre exacto del contenedor
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    TEST_SERVER = "ID_DE_SERVIDOR_PRUEBA" -- Opcional
}

-- 🛠️ SERVICIOS
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 🔍 BÚSQUEDA PRECISA DEL CONTENEDOR
local function findTargetContainer()
    -- Busca primero en el workspace principal
    local container = workspace:FindFirstChild(CONFIG.TARGET_PARENT)
    
    -- Si no está, busca recursivamente (por si está dentro de otra carpeta)
    if not container then
        local function recursiveSearch(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == CONFIG.TARGET_PARENT then
                    return child
                end
                local found = recursiveSearch(child)
                if found then return found end
            end
            return nil
        end
        container = recursiveSearch(workspace)
    end
    
    return container
end

-- 📊 VERIFICACIÓN COMPLETA
local function verifyTarget()
    local container = findTargetContainer()
    if not container then
        print("❌ No se encontró el contenedor", CONFIG.TARGET_PARENT)
        return false, nil
    end
    
    print("✅ Contenedor encontrado. Verificando contenido...")
    
    -- Contar cubos hijos
    local cubeCount = 0
    for _, child in ipairs(container:GetDescendants()) do
        if child.Name:match("^Cube") then -- Busca cubos (Cube1, Cube2, etc.)
            cubeCount = cubeCount + 1
        end
    end
    
    local position = container:GetPivot().Position
    print(string.format("📦 %s contiene %d cubos en posición: %s", 
        CONFIG.TARGET_PARENT, cubeCount, tostring(position)))
    
    return true, position
end

-- 📨 REPORTE MEJORADO
local function sendEnhancedReport(found, position, details)
    local embed = {
        title = found and "🎯 OBJETIVO LOCALIZADO" or "❌ OBJETIVO NO ENCONTRADO",
        color = found and 65280 or 16711680,
        fields = {
            {name = "CONTENEDOR", value = CONFIG.TARGET_PARENT},
            {name = "ESTADO", value = found and "PRESENTE" or "AUSENTE"},
            {name = "POSICIÓN", value = position and tostring(position) or "N/A"},
            {name = "DETALLES", value = details or "N/A"},
            {name = "SERVER ID", value = game.JobId or "N/A"}
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    local payload = {
        embeds = {embed},
        content = found and "@here Objetivo encontrado!" or nil
    }
    
    local success, err = pcall(function()
        HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(payload))
    end)
    
    if not success then
        warn("⚠️ Error al enviar reporte:", err)
    end
end

-- 🧪 EJECUCIÓN DE PRUEBA
local function runTest()
    print("\n=== INICIANDO PRUEBA MEJORADA ===")
    print("🔍 Buscando:", CONFIG.TARGET_PARENT)
    
    local found, position = verifyTarget()
    local details = found and string.format("Contenedor válido encontrado con cubos en %s", tostring(position)) or "Estructura no encontrada"
    
    sendEnhancedReport(found, position, details)
    print("=== PRUEBA FINALIZADA ===")
end

-- 🚀 INICIAR (Elige un método)
if CONFIG.TEST_SERVER and #CONFIG.TEST_SERVER > 0 then
    -- Método 1: Servidor específico
    local teleportSuccess = pcall(function()
        TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, CONFIG.TEST_SERVER, LocalPlayer)
    end)
    
    if teleportSuccess then
        repeat task.wait() until game:IsLoaded()
        task.wait(5) -- Espera de carga
        runTest()
    else
        warn("⚠️ Error al unirse al servidor de prueba")
    end
else
    -- Método 2: Servidor actual
    runTest()
end
