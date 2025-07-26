-- passive_scanner.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_NAME = "BallerinaCappuccina", -- Nombre exacto del objeto
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398573923280359425/SQDEI2MXkQUC6f4WGdexcHGdmYpUO_sARSkuBmF-Wa-fjQjsvpTiUjVcEjrvuVdSKGb1",
    SCAN_RADIUS = 5000, -- Radio de búsqueda en studs
    SERVER_HOP_DELAY = 30, -- Espera entre servidores (segundos)
    MAX_SERVERS = 50, -- Límite de servidores a escanear
    DEBUG_MODE = true -- Muestra logs detallados
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Escáner mejorado
local function deepSearch()
    local targets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local referencePosition = rootPart and rootPart.Position or Vector3.new(0, 0, 0)

    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Coincidencia exacta del nombre
            if child.Name == CONFIG.TARGET_NAME then
                local position = child:GetPivot().Position
                local distance = (position - referencePosition).Magnitude
                
                if distance <= CONFIG.SCAN_RADIUS then
                    table.insert(targets, {
                        name = child:GetFullName(),
                        position = position,
                        distance = distance
                    })
                end
            end

            -- Búsqueda en subcarpetas
            if child:IsA("Folder") or child:IsA("Model") then
                scanRecursive(child)
            end
        end
    end

    -- Áreas prioritarias
    local priorityAreas = {
        Workspace,
        Workspace:FindFirstChild("Map") or Workspace,
        Workspace:FindFirstChild("GameObjects") or Workspace
    }

    for _, area in ipairs(priorityAreas) do
        scanRecursive(area)
    end

    -- Ordenar por proximidad
    table.sort(targets, function(a, b) return a.distance < b.distance end)
    return targets
end

-- 📨 Notificador a Discord
local function sendDetectionReport(jobId, targets)
    local embeds = {}
    local description = string.format("**Objetivo encontrado en el servidor**\n🔹 **Nombre:** %s\n🔹 **Total detectados:** %d", 
        CONFIG.TARGET_NAME, #targets)

    -- Información de los 3 más cercanos
    local closest = {}
    for i = 1, math.min(3, #targets) do
        table.insert(closest, string.format(
            "**#%d:** %s (%.1f studs)",
            i, targets[i].name, targets[i].distance
        ))
    end

    -- Construir embed
    local embed = {
        title = "🎯 DETECCIÓN EXITOSA",
        description = description,
        color = 65280, -- Verde
        fields = {
            {name = "Objetos cercanos", value = table.concat(closest, "\n")},
            {name = "ID del Servidor", value = jobId},
            {name = "Unirse al servidor", value = string.format(
                "[Haz clic aquí](roblox://placeId=%d&gameInstanceId=%s)",
                CONFIG.GAME_ID, jobId
            )}
        },
        footer = {text = "Scanner pasivo - " .. os.date("%X")}
    }

    -- Enviar reporte
    local success, err = pcall(function()
        local payload = {
            content = "@here Objetivo detectado!",
            embeds = {embed}
        }
        
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

-- 🔄 Obtención de servidores
local function getPublicServers()
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=%d",
            CONFIG.GAME_ID, CONFIG.MAX_SERVERS
        ))
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            if server.playing > 5 then -- Filtrar servidores con jugadores
                table.insert(servers, server.id)
            end
        end
    else
        if CONFIG.DEBUG_MODE then
            warn("Error al obtener servidores:", response)
        end
    end

    return servers
end

-- 🚀 Sistema principal
local function passiveScan()
    if CONFIG.DEBUG_MODE then
        print("\n=== INICIANDO ESCANEO PASIVO ===")
        print("🔍 Objetivo:", CONFIG.TARGET_NAME)
        print("📡 Radio de búsqueda:", CONFIG.SCAN_RADIUS, "studs")
    end

    while true do
        local servers = getPublicServers()
        if #servers == 0 then
            if CONFIG.DEBUG_MODE then
                print("⚠️ No se encontraron servidores. Reintentando...")
            end
            task.wait(60)
            continue
        end

        if CONFIG.DEBUG_MODE then
            print("\n🔄 Obtenidos", #servers, "servidores activos")
        end

        for i, serverId in ipairs(servers) do
            if CONFIG.DEBUG_MODE then
                print(string.format("\n(%d/%d) Escaneando servidor: %s", i, #servers, serverId))
            end

            -- Intento de unión al servidor
            local joinSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, serverId, LocalPlayer)
            end)

            if joinSuccess then
                -- Esperar carga completa
                repeat task.wait(1) until game:IsLoaded()
                task.wait(5) -- Espera adicional

                -- Buscar objetivo
                local targets = deepSearch()
                if #targets > 0 then
                    if CONFIG.DEBUG_MODE then
                        print("🎯 Objetivo encontrado! Enviando reporte...")
                    end
                    sendDetectionReport(serverId, targets)
                    break -- Terminar después de encontrar
                end
            elseif CONFIG.DEBUG_MODE then
                print("⚠️ Error al unirse al servidor:", serverId)
            end

            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        if CONFIG.DEBUG_MODE then
            print("\n🔁 Ciclo de escaneo completado. Reiniciando...")
        end
        task.wait(60) -- Espera antes de nuevo ciclo
    end
end

-- Iniciar sistema
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

passiveScan()
