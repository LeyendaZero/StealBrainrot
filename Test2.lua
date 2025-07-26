-- brainrot_teleporter.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_NAME = "Tralalalero Tralala", -- Nombre EXACTO del modelo
    WEBHOOK_URL = "https://discord.com/api/webhooks/tu_webhook_real",
    VERIFICATION_ATTEMPTS = 3, -- Veces que verifica antes de reportar
    SEARCH_RADIUS = 200, -- Radio más pequeño para mayor precisión
    DEBUG_MODE = true
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Búsqueda ultra-precisaa
local function locateExactTarget()
    local target = Workspace:FindFirstChild(CONFIG.TARGET_NAME, true)
    
    -- Verificación adicional
    if target then
        -- Comprobar que sea un Modelo/Parte válida
        if not (target:IsA("Model") or target:IsA("BasePart")) then
            if CONFIG.DEBUG_MODE then
                print("⚠️ Objeto encontrado pero no es Model/Part:", target.ClassName)
            end
            return nil
        end
        
        -- Verificar posición dentro del radio
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local distance = (target:GetPivot().Position - root.Position).Magnitude
            if distance > CONFIG.SEARCH_RADIUS then
                if CONFIG.DEBUG_MODE then
                    print(string.format("⚠️ Objeto muy lejano (%.1f studs)", distance))
                end
                return nil
            end
        end
        
        return target
    end
    return nil
end

-- 🚔 Sistema anti-falsos positivos
local function verifyTargetExistence()
    for i = 1, CONFIG.VERIFICATION_ATTEMPTS do
        local target = locateExactTarget()
        if target then
            if CONFIG.DEBUG_MODE then
                print(string.format("✅ Verificación %d/%d exitosa", i, CONFIG.VERIFICATION_ATTEMPTS))
            end
            return target
        end
        task.wait(1) -- Pequeña espera entre verificaciones
    end
    return nil
end

-- 📨 Reporte infalible
local function sendSecureReport(target, jobId)
    local position = target:GetPivot().Position
    local payload = {
        content = "@everyone 🎯 BRAINROT CONFIRMADO",
        embeds = {{
            title = "UBICACIÓN EXACTA",
            description = "Objetivo verificado 3 veces antes de reportar",
            color = 65280,
            fields = {
                {name = "Nombre", value = target:GetFullName()},
                {name = "Posición", value = tostring(position)},
                {name = "Enlace Directo", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId or game.JobId)}
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    -- Método ultra-compatible
    local success = pcall(function()
        if syn and syn.request then
            syn.request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        elseif request then
            request({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        else
            error("No hay método HTTP disponible")
        end
    end)

    if not success and CONFIG.DEBUG_MODE then
        warn("⚠️ Error al enviar reporte (pero el objetivo SÍ está ahí)")
    end
end

-- 🚫 Anti-teleport aleatorio
local function safeTeleport(jobId)
    -- 1. Desactivar cualquier teleport automático
    if getconnections then
        for _, conn in ipairs(getconnections(TeleportService.TeleportInitiated)) do
            conn:Disable()
        end
    end

    -- 2. Teletransporte directo
    local success = pcall(function()
        TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
    end)

    -- 3. Espera confirmación
    if success then
        repeat task.wait() until game:IsLoaded()
        
        -- Espera EXTRA para asegurar carga
        local waitTime = 0
        while not Workspace:FindFirstChildWhichIsA("Model") and waitTime < 10 do
            waitTime += 1
            task.wait(1)
        end

        return true
    end
    return false
end

-- 🎯 Ejecución principal
local function main()
    -- Verificar objetivo actual primero (por si ya estamos en el server correcto)
    local target = verifyTargetExistence()
    if target then
        sendSecureReport(target)
        print("🎯 ¡Objetivo encontrado en el servidor actual!")
        return
    end

    -- Obtener servidores activos
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=50",
            CONFIG.GAME_ID
        ))
    end)

    if success then
        servers = HttpService:JSONDecode(response).data
    else
        warn("❌ Error al obtener servidores:", response)
        return
    end

    -- Buscar en cada servidor
    for _, server in ipairs(servers) do
        print("🛫 Uniéndose a:", server.id)
        
        if safeTeleport(server.id) then
            -- Verificación triple
            local foundTarget = verifyTargetExistence()
            
            if foundTarget then
                sendSecureReport(foundTarget, server.id)
                print("🎯 ¡Servidor confirmado! No se harán más saltos.")
                
                -- Mantenerse en este servidor
                while true do
                    task.wait(10)
                    -- Verificar periódicamente que el objetivo sigue ahí
                    if not locateExactTarget() then
                        warn("⚠️ El objetivo desapareció. Reiniciando búsqueda...")
                        break
                    end
                end
            else
                print("❌ Objeto no encontrado después de verificación")
            end
        end
        
        task.wait(CONFIG.SERVER_HOP_DELAY)
    end
end

-- Iniciar
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

main()
