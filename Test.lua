-- alt_hunter_pro.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "CocofantoElefanto", -- Patrón que funcionó
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    SCAN_RADIUS = 5000, -- Distancia aumentada como solicitaste
    SERVER_HOP_DELAY = 10, -- Espera entre servidores
    MAX_SERVERS = 100, -- Límite de servidores a analizar
    DEBUG_MODE = true -- Muestra información detallada
}

-- 🛠️ Servicios esenciales
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Escáner ultra-confiable (el que funcionó)
local function deepScan()
    local foundTargets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local rootPosition = rootPart and rootPart.Position or Vector3.new(0, 0, 0)
    
    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Coincidencia parcial del nombre (case insensitive)
            if string.find(string.lower(child.Name), string.lower(CONFIG.TARGET_PATTERN)) then
                local objectPos = child:GetPivot().Position
                local distance = (objectPos - rootPosition).Magnitude
                
                if distance <= CONFIG.SCAN_RADIUS then
                    table.insert(foundTargets, {
                        name = child:GetFullName(),
                        position = objectPos,
                        distance = distance
                    })
                end
            end
            
            -- Escanear recursivamente modelos y carpetas
            if child:IsA("Model") or child:IsA("Folder") then
                scanRecursive(child)
            end
        end
    end

    -- Áreas prioritarias para escanear primero
    local priorityAreas = {
        Workspace,
        Workspace:FindFirstChild("Map") or Workspace,
        Workspace:FindFirstChild("GameObjects") or Workspace,
        Workspace:FindFirstChild("Workspace") or Workspace
    }

    for _, area in ipairs(priorityAreas) do
        scanRecursive(area)
    end

    -- Ordenar por distancia
    table.sort(foundTargets, function(a, b) return a.distance < b.distance end)
    
    return foundTargets
end

-- 📨 Sistema de reportes mejorado
local function sendHunterReport(targets, jobId)
    local embeds = {}
    local content = #targets > 0 and "@everyone 🎯 OBJETIVO ENCONTRADO" or nil
    
    if #targets > 0 then
        for i, target in ipairs(targets) do
            if i <= 3 then -- Limitar a los 3 más cercanos
                table.insert(embeds, {
                    title = string.format("OBJETO #%d - %.1f studs", i, target.distance),
                    description = target.name,
                    color = 65280,
                    fields = {
                        {name = "Posición", value = tostring(target.position)},
                        {name = "Servidor", value = jobId or game.JobId},
                        {name = "Enlace", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId or game.JobId)}
                    }
                })
            end
        end
    else
        table.insert(embeds, {
            title = "ESCANEO COMPLETADO",
            description = "No se encontraron objetivos",
            color = 16711680,
            fields = {
                {name = "Servidor", value = jobId or game.JobId},
                {name = "Patrón buscado", value = CONFIG.TARGET_PATTERN}
            }
        })
    end

    local payload = {
        content = content,
        embeds = embeds
    }

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
        warn("⚠️ Error al enviar reporte:", err)
    end
end

-- 🚀 Sistema de cambio de servidores
local function getActiveServers()
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
            table.insert(servers, server.id)
        end
    else
        warn("⚠️ Error al obtener servidores:", response)
    end

    return servers
end

local function joinServer(jobId)
    local attempts = 0
    local maxAttempts = 3

    repeat
        attempts += 1
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)

        if success then
            -- Esperar carga completa
            repeat task.wait(1) until game:IsLoaded()
            
            -- Espera adicional para assets
            local waitTime = 0
            while not Workspace:FindFirstChildWhichIsA("Model") and waitTime < 15 do
                waitTime += 1
                task.wait(1)
            end

            -- Verificar personaje
            if not LocalPlayer.Character then
                LocalPlayer.CharacterAdded:Wait()
            end
            
            return true
        else
            if CONFIG.DEBUG_MODE then
                print(string.format("⚠️ Intento %d/%d fallido para servidor %s", attempts, maxAttempts, jobId))
            end
            task.wait(5)
        end
    until attempts >= maxAttempts

    return false
end

-- 🔄 Ciclo principal de búsqueda
local function huntingLoop()
    print("\n=== INICIANDO MODO HUNTER ===")
    print(string.format("🔍 Buscando '%s' en radio de %d studs", CONFIG.TARGET_PATTERN, CONFIG.SCAN_RADIUS))

    while true do
        local servers = getActiveServers()
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores. Reintentando en 1 minuto...")
            task.wait(60)
            continue
        end

        if CONFIG.DEBUG_MODE then
            print(string.format("🔄 Obtenidos %d servidores activos", #servers))
        end

        for _, serverId in ipairs(servers) do
            if CONFIG.DEBUG_MODE then
                print("🛫 Intentando unirse a:", serverId)
            end

            if joinServer(serverId) then
                local targets = deepScan()
                sendHunterReport(targets, serverId)

                if #targets > 0 then
                    print("🎯 Objetivo encontrado! Finalizando búsqueda.")
                    return -- Terminar después de éxito
                end
            end

            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        if CONFIG.DEBUG_MODE then
            print("🔁 Reiniciando ciclo de búsqueda...")
        end
        task.wait(30) -- Espera antes de refrescar lista
    end
end

-- 🎯 Inicialización
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

huntingLoop()
