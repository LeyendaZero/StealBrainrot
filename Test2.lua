-- ⚙️ CONFIGURACIÓN
local CONFIG = {
    GAME_ID = 109983668079237, -- ID del juego
    TARGET_NAMES = {"BombardiloCrocodilo", "BallerinaCappuccina", "BanditoBorbitto", "CocofantoElefanto", "TralaleroTralala"}, -- Nombres posibles
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398573923280359425/SQDEI2MXkQUC6f4WGdexcHGdmYpUO_sARSkuBmF-Wa-fjQjsvpTiUjVcEjrvuVdSKGb1", -- Webhook de Discord
    SCAN_RADIUS = 5000, -- Radio de búsqueda (studs)
    MAX_TELEPORT_ATTEMPTS = 3, -- Intentos por servidor
    SERVER_HOP_DELAY = 10, -- Espera entre servidores (segundos)
    DEBUG_MODE = true -- Muestra logs detallados
}

-- 🛠️ SERVICIOS
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔄 FUNCIÓN PARA EVITAR REDIRECCIONES
local function forceJoinServer(jobId)
    local attempts = 0
    local lastJobId = game.JobId
    
    while attempts < CONFIG.MAX_TELEPORT_ATTEMPTS do
        attempts += 1
        
        -- 1. Intentar teletransporte normal
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)
        
        if not success then
            task.wait(5)
            continue
        end

        -- 2. Esperar carga (hasta 30 segundos)
        local startTime = os.clock()
        repeat
            task.wait(1)
        until game:IsLoaded() or (os.clock() - startTime) > 30

        -- 3. Verificar JobID actual
        if game.JobId == jobId then
            return true -- ✅ Éxito
        else
            warn("⚠️ Redireccionado a:", game.JobId, "| Reintentando...")
            task.wait(5)
        end
    end
    
    return false -- ❌ Falló después de varios intentos
end

-- 🔍 DETECCIÓN DEL BRAINROT (BUSQUEDA PROFUNDA)
local function findBrainrot()
    local function scan(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Busca coincidencias en los nombres configurados
            for _, targetName in ipairs(CONFIG.TARGET_NAMES) do
                if string.find(child.Name:lower(), targetName:lower()) then
                    return child
                end
            end

            -- Búsqueda recursiva en modelos/carpetas
            if child:IsA("Model") or child:IsA("Folder") then
                local found = scan(child)
                if found then return found end
            end
        end
        return nil
    end

    return scan(workspace) -- Escanea desde el Workspace
end

-- 📨 REPORTE A DISCORD
local function sendReport(jobId, target)
    local embed = {
        title = "🎯 BRAINROT DETECTADO",
        color = 65280, -- Verde
        fields = {
            {name = "Objeto", value = target:GetFullName()},
            {name = "Posición", value = tostring(target:GetPivot().Position)},
            {name = "Servidor", value = jobId},
            {name = "Unirse", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId)}
        }
    }

    local payload = {
        content = "@everyone ¡Objetivo encontrado!",
        embeds = {embed}
    }

    -- Envía el reporte (con soporte para múltiples exploits)
    local success, err = pcall(function()
        if syn and syn.request then
            syn.request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        else
            HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(payload))
        end
    end)

    if not success and CONFIG.DEBUG_MODE then
        warn("Error al enviar reporte:", err)
    end
end

-- 🚀 CICLO PRINCIPAL
local function main()
    -- Obtener lista de servidores activos
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=100",
            CONFIG.GAME_ID
        ))
    end)

    if success then
        servers = HttpService:JSONDecode(response).data
    else
        warn("Error al obtener servidores:", response)
        return
    end

    -- Buscar en cada servidor
    for _, server in ipairs(servers) do
        local jobId = server.id

        if CONFIG.DEBUG_MODE then
            print("🔍 Intentando unirse a:", jobId)
        end

        -- 1. Forzar unión al servidor correcto
        if forceJoinServer(jobId) then
            -- 2. Esperar a que el personaje cargue
            if not LocalPlayer.Character then
                LocalPlayer.CharacterAdded:Wait()
                task.wait(3)
            end

            -- 3. Buscar el Brainrot
            local target = findBrainrot()
            if target then
                sendReport(jobId, target)
                print("✅ Objetivo encontrado. Finalizando búsqueda.")
                return -- Terminar el script
            end
        end

        task.wait(CONFIG.SERVER_HOP_DELAY)
    end

    print("🔁 Búsqueda completada. No se encontró el objetivo.")
end

-- Iniciar
main()
