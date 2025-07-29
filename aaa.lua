-- alt_hunter_pro_fixed.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "TralaleroTralala",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 10,
    MAX_SERVERS = 100,
    DEBUG_MODE = true,
    ANTI_DETECTION = true,
    MAX_TARGETS = 3,
    MIN_PLAYERS = 5,
    MAX_PLAYERS = 30
}

-- Servicios esenciales
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Variables para la UI
local UI = {
    Enabled = true,
    MainWindow = nil,
    Tabs = {},
    Status = {
        Scanning = false,
        TargetsFound = 0,
        ServersScanned = 0,
        CurrentAction = "Iniciando..."
    }
}

-- Variables de estado
local HunterState = {
    Active = false,
    Paused = false,
    LastScan = 0,
    LastServerHop = 0,
    Targets = {}
}

-- Función para actualizar la UI
local function updateUI()
    if not UI.MainWindow then return end
    
    if UI.StatusLabel then
        UI.StatusLabel.Text = "Estado: " .. UI.Status.CurrentAction
    end
    
    if UI.UpdateStats then
        UI.UpdateStats()
    end
    
    if UI.UpdateTargetList then
        UI.UpdateTargetList()
    end
end

-- Escáner optimizado
local function deepScan()
    local foundTargets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        UI.Status.CurrentAction = "Esperando personaje..."
        updateUI()
        return foundTargets 
    end
    
    local rootPosition = rootPart.Position
    local startTime = os.clock()
    local scannedInstances = 0
    local targetLower = string.lower(CONFIG.TARGET_PATTERN)
    
    local isModel = Instance.new("Model").ClassName
    local isFolder = Instance.new("Folder").ClassName
    
    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if not HunterState.Active then break end
            while HunterState.Paused do task.wait(1) end
            
            scannedInstances = scannedInstances + 1
            
            local childLower = string.lower(child.Name)
            if string.find(childLower, targetLower, 1, true) then
                local success, objectPos = pcall(function()
                    return child:GetPivot().Position
                end)
                
                if success then
                    local distance = (objectPos - rootPosition).Magnitude
                    
                    if distance <= CONFIG.SCAN_RADIUS then
                        table.insert(foundTargets, {
                            name = child.Name,
                            fullName = child:GetFullName(),
                            position = objectPos,
                            distance = math.floor(distance),
                            timestamp = os.time(),
                            instance = child
                        })
                        
                        UI.Status.CurrentAction = string.format("Objetivo encontrado a %d studs", distance)
                        updateUI()
                    end
                end
            end
            
            local childClass = child.ClassName
            if childClass == isModel or childClass == isFolder then
                scanRecursive(child)
            end
        end
    end

    local priorityAreas = {
        Workspace,
        Workspace:FindFirstChild("Map") or Workspace,
        Workspace:FindFirstChild("GameObjects") or Workspace,
        Workspace:FindFirstChild("Workspace") or Workspace
    }

    UI.Status.CurrentAction = "Escaneando entorno..."
    updateUI()

    for _, area in ipairs(priorityAreas) do
        if not HunterState.Active then break end
        local success, err = pcall(scanRecursive, area)
        if not success and CONFIG.DEBUG_MODE then
            warn("Error escaneando área:", area:GetFullName(), "| Error:", err)
        end
    end

    table.sort(foundTargets, function(a, b) return a.distance < b.distance end)
    
    if CONFIG.DEBUG_MODE then
        print(string.format("🔍 Escaneo completado en %.2fs | %d instancias | %d objetivos", 
              os.clock() - startTime, scannedInstances, #foundTargets))
    end
    
    UI.Status.CurrentAction = string.format("Escaneo completado (%d obj)", #foundTargets)
    updateUI()
    
    return foundTargets
end

-- Sistema de reportes mejorado
local function sendHunterReport(targets, jobId)
    local embeds = {}
    local content = nil
    
    if #targets > 0 then
        content = "@everyone 🎯 OBJETIVO ENCONTRADO"
        local playerCount = #Players:GetPlayers()
        
        for i, target in ipairs(targets) do
            if i <= 3 then
                local embedColor = i == 1 and 65280 or (i == 2 and 16753920 or 16711680)
                
                table.insert(embeds, {
                    title = string.format("🎯 OBJETO #%d - %d studs", i, target.distance),
                    description = string.format("```%s```", target.fullName),
                    color = embedColor,
                    fields = {
                        {name = "📍 Posición", value = string.format("X: %.1f | Y: %.1f | Z: %.1f", 
                            target.position.X, target.position.Y, target.position.Z)},
                        {name = "🕒 Hora", value = os.date("%H:%M:%S", target.timestamp)},
                        {name = "👥 Jugadores", value = playerCount},
                        {name = "🔗 Enlace directo", value = string.format("[Unirse al servidor](roblox://placeId=%d&gameInstanceId=%s)", 
                            CONFIG.GAME_ID, jobId)}
                    },
                    footer = {text = string.format("Servidor: %s", jobId)}
                })
            end
        end
    else
        table.insert(embeds, {
            title = "🔍 ESCANEO COMPLETADO",
            description = "No se encontraron objetivos coincidentes",
            color = 8421504,
            fields = {
                {name = "🔎 Patrón buscado", value = string.format("```%s```", CONFIG.TARGET_PATTERN)},
                {name = "📏 Radio de búsqueda", value = string.format("%d studs", CONFIG.SCAN_RADIUS)},
                {name = "🆔 ID Servidor", value = jobId or game.JobId}
            },
            footer = {text = os.date("%H:%M:%S")}
        })
    end

    local payload = {
        username = "AltHunter Pro",
        avatar_url = "https://i.imgur.com/J7l1tO7.png",
        content = content,
        embeds = embeds
    }

    local maxAttempts = 3
    local attempts = 0
    local success = false
    
    repeat
        attempts += 1
        success = pcall(function()
            local response
            if syn and syn.request then
                response = syn.request({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload),
                    Timeout = 10
                })
                
                if response.StatusCode ~= 204 then
                    error("Código de estado: "..response.StatusCode)
                end
            else
                HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(payload))
            end
        end)
        
        if not success and attempts < maxAttempts then
            task.wait(2 ^ attempts)
        end
    until success or attempts >= maxAttempts

    if not success and CONFIG.DEBUG_MODE then
        warn("⚠️ Error al enviar reporte después de", attempts, "intentos")
    end
    
    return success
end

-- Obtención de servidores mejorada
local function getActiveServers()
    local servers = {}
    
    UI.Status.CurrentAction = "Buscando servidores..."
    updateUI()

    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=%d",
            CONFIG.GAME_ID, CONFIG.MAX_SERVERS
        ), true, {["Cache-Control"] = "no-cache"})
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            if server.playing and server.playing >= CONFIG.MIN_PLAYERS and server.playing <= CONFIG.MAX_PLAYERS then
                table.insert(servers, {
                    id = server.id,
                    players = server.playing,
                    ping = math.random(50, 150)
                })
            end
        end
        
        table.sort(servers, function(a, b)
            return a.ping < b.ping or (a.ping == b.ping and a.players > b.players)
        end)
    else
        if CONFIG.DEBUG_MODE then
            warn("⚠️ Error al obtener servidores:", response)
            if game.JobId ~= "" then
                table.insert(servers, {id = game.JobId, players = #Players:GetPlayers(), ping = 100})
            end
        end
    end

    return servers
end

-- Unión a servidores mejorada
local function joinServer(serverInfo)
    local jobId = serverInfo.id
    local attempts = 0
    local maxAttempts = 3
    local success = false

    UI.Status.CurrentAction = string.format("Uniendo a servidor (%d/%d jug)", serverInfo.players, CONFIG.MAX_PLAYERS)
    updateUI()

    if CONFIG.DEBUG_MODE then
        print(string.format("🛫 Intentando unirse a %s (%d jugadores, ping: %dms)", 
              jobId, serverInfo.players, serverInfo.ping))
    end

    repeat
        attempts += 1
        success = pcall(function()
            if TeleportService.TeleportInitiated then
                TeleportService:AbortTeleport()
                task.wait(0.5)
            end
            
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)

        if success then
            local loadStart = os.clock()
            local loaded = false
            
            while os.clock() - loadStart < 30 do
                if game:IsLoaded() and Workspace:FindFirstChildWhichIsA("BasePart") then
                    loaded = true
                    break
                end
                task.wait(1)
            end
            
            if not loaded then
                if CONFIG.DEBUG_MODE then
                    warn("⚠️ Timeout de carga para servidor:", jobId)
                end
                success = false
            else
                local charStart = os.clock()
                while os.clock() - charStart < 15 do
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        break
                    end
                    task.wait(1)
                end
                
                if not LocalPlayer.Character then
                    if CONFIG.DEBUG_MODE then
                        warn("⚠️ No se pudo cargar el personaje en servidor:", jobId)
                    end
                    success = false
                end
            end
        end

        if not success and attempts < maxAttempts then
            local delay = math.min(5 * attempts, 15)
            task.wait(delay)
        end
    until success or attempts >= maxAttempts

    return success
end

-- Ciclo principal de búsqueda (definido después de todas las funciones que usa)
local function huntingLoop()
    print("\n=== INICIANDO ALT HUNTER PRO ===")
    print(string.format("🔍 Buscando '%s' en radio de %d studs", CONFIG.TARGET_PATTERN, CONFIG.SCAN_RADIUS))
    
    UI.Status.ServersScanned = 0
    UI.Status.TargetsFound = 0
    UI.Status.CurrentAction = "Iniciando búsqueda..."
    updateUI()
    
    local stopFile = "alt_hunter_stop.txt"
    if isfile and isfile(stopFile) then
        delfile(stopFile)
    end

    while HunterState.Active do
        if isfile and isfile(stopFile) then
            print("🛑 Detención emergente activada. Finalizando ejecución.")
            UI.Status.CurrentAction = "Detenido por archivo de parada"
            updateUI()
            sendHunterReport({}, game.JobId)
            return
        end
        
        while HunterState.Paused do
            UI.Status.CurrentAction = "Búsqueda en pausa..."
            updateUI()
            task.wait(1)
        end
        
        local servers = getActiveServers()
        UI.Status.ServersScanned = UI.Status.ServersScanned + #servers
        updateUI()
        
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores válidos. Reintentando en 2 minutos...")
            UI.Status.CurrentAction = "Esperando servidores..."
            updateUI()
            task.wait(120)
            continue
        end

        if CONFIG.DEBUG_MODE then
            print(string.format("🌐 %d servidores disponibles | %d analizados hasta ahora", 
                  #servers, UI.Status.ServersScanned))
        end

        for _, server in ipairs(servers) do
            if not HunterState.Active then break end
            while HunterState.Paused do task.wait(1) end
            
            if joinServer(server) then
                if CONFIG.ANTI_DETECTION then
                    CONFIG.SERVER_HOP_DELAY = math.random(CONFIG.SERVER_HOP_DELAY-2, CONFIG.SERVER_HOP_DELAY+5)
                    task.wait(math.random(1, 3))
                end
                
                local scanStart = os.clock()
                HunterState.Targets = deepScan()
                local scanTime = os.clock() - scanStart
                
                if #HunterState.Targets > 0 then
                    UI.Status.TargetsFound = UI.Status.TargetsFound + #HunterState.Targets
                    updateUI()
                    sendHunterReport(HunterState.Targets, server.id)
                    
                    if HunterState.Targets[1].distance < 100 then
                        print("🎯 Objetivo principal encontrado! Finalizando búsqueda.")
                        UI.Status.CurrentAction = "Objetivo principal encontrado!"
                        updateUI()
                        return
                    else
                        print("🎯 Objetivo encontrado pero continuando búsqueda...")
                    end
                elseif CONFIG.DEBUG_MODE then
                    print(string.format("🔍 Escaneo completado en %.1fs - Sin objetivos", scanTime))
                end
                
                if UI.Status.ServersScanned % 10 == 0 then
                    sendHunterReport({}, server.id)
                end
            end

            local delay = CONFIG.SERVER_HOP_DELAY
            if #HunterState.Targets > 0 then
                delay = delay * 2
            end
            task.wait(delay)
        end

        if CONFIG.DEBUG_MODE then
            local elapsed = os.time() - UI.Status.startTime
            print(string.format("🔁 Ciclo completado | %d servidores | %d objetivos | %02d:%02d ejecutándose", 
                  UI.Status.ServersScanned, UI.Status.TargetsFound, elapsed/60, elapsed%60))
        end
        
        UI.Status.CurrentAction = "Refrescando lista de servidores..."
        updateUI()
        task.wait(30)
    end
    
    UI.Status.CurrentAction = "Búsqueda detenida"
    updateUI()
end

-- Función para iniciar la caza de manera segura
local function startHunting()
    if huntingLoop then
        coroutine.wrap(huntingLoop)()
    else
        warn("Error: huntingLoop no está definida")
    end
end

-- [Resto del código de la UI (createUI, etc.) permanece igual]

-- Inicialización corregida
local function initialize()
    if not LocalPlayer.Character then
        if UI.StatusLabel then
            UI.StatusLabel.Text = "Estado: Esperando personaje..."
        end
        LocalPlayer.CharacterAdded:Wait()
    end
    
    createUI()
    
    if syn and syn.is_beta then
        syn.toast_notification("Alt Hunter Pro", "Presiona F5 para mostrar/ocultar la interfaz", 5)
        
        local UIVisible = true
        game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == Enum.KeyCode.F5 then
                UIVisible = not UIVisible
                if UI.MainWindow then
                    UI.MainWindow.Enabled = UIVisible
                end
            end
        end)
    end
    
    UI.Status.startTime = os.time()
    updateUI()
    
    print("\n=== ALT HUNTER PRO INICIALIZADO ===")
    print("Configuración actual:")
    for k, v in pairs(CONFIG) do
        print(string.format("%s: %s", k, tostring(v)))
    end
    
    if UI.MainWindow then
        print("\nInterfaz de usuario disponible. Usa los controles para iniciar la búsqueda.")
    end
end

-- Iniciar el script de manera segura
local success, err = pcall(initialize)
if not success then
    warn("Error durante la inicialización:", err)
end
