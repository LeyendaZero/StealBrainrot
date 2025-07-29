# Alt Hunter Pro (Versión Mejorada con UI)

Aquí tienes el código completo con todas las mejoras implementadas, incluyendo una interfaz de usuario funcional:

```lua
-- alt_hunter_pro_advanced.lua
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

-- 🛠️ Servicios esenciales
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 🎨 Variables para la UI
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

-- 🔄 Variables de estado
local HunterState = {
    Active = false,
    Paused = false,
    LastScan = 0,
    LastServerHop = 0,
    Targets = {}
}

-- 🖥️ Función para crear la interfaz de usuario
local function createUI()
    if not UI.Enabled then return end
    
    -- Limpiar UI existente
    if UI.MainWindow and UI.MainWindow.Parent then
        UI.MainWindow:Destroy()
    end

    -- Crear la ventana principal
    local MainWindow = Instance.new("ScreenGui")
    MainWindow.Name = "AltHunterProUI"
    MainWindow.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if syn and syn.protect_gui then
        syn.protect_gui(MainWindow)
    end

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 350, 0, 450)
    Frame.Position = UDim2.new(0.5, -175, 0.5, -225)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = MainWindow

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "ALT HUNTER PRO"
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 14
    CloseButton.Parent = TitleBar

    CloseButton.MouseButton1Click:Connect(function()
        MainWindow:Destroy()
        UI.MainWindow = nil
    end)

    -- Tabs Container
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Size = UDim2.new(1, 0, 0, 30)
    TabsContainer.Position = UDim2.new(0, 0, 0, 30)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = Frame

    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -20, 1, -110)
    ContentContainer.Position = UDim2.new(0, 10, 0, 70)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = Frame

    -- Status Bar
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, -20, 0, 30)
    StatusBar.Position = UDim2.new(0, 10, 1, -40)
    StatusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    StatusBar.Parent = Frame

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = StatusBar

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 1, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Estado: Iniciando..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 12
    StatusLabel.Parent = StatusBar
    UI.StatusLabel = StatusLabel

    -- Crear pestañas
    local function createTab(name, content)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0.5, 0, 1, 0)
        TabButton.Position = UDim2.new(#UI.Tabs * 0.5, 0, 0, 0)
        TabButton.BackgroundColor3 = #UI.Tabs == 0 and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 50)
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(220, 220, 220)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 12
        TabButton.Parent = TabsContainer

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.Position = UDim2.new(#UI.Tabs, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = #UI.Tabs == 0
        TabContent.ScrollBarThickness = 4
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.Parent = ContentContainer

        if content then
            content(TabContent)
        end

    
    
    
-- 🔄 Ciclo principal de búsqueda mejorado
local function huntingLoop()
    print("\n=== INICIANDO ALT HUNTER PRO ===")
    print(string.format("🔍 Buscando '%s' en radio de %d studs", CONFIG.TARGET_PATTERN, CONFIG.SCAN_RADIUS))
    
    -- Estadísticas de ejecución
    UI.Status.ServersScanned = 0
    UI.Status.TargetsFound = 0
    UI.Status.CurrentAction = "Iniciando búsqueda..."
    updateUI()
    
    -- Sistema de parada emergente
    local stopFile = "alt_hunter_stop.txt"
    if isfile and isfile(stopFile) then
        delfile(stopFile)
    end
    

    -- Pestaña de Control
    createTab("Control", function(container)
        local padding = 5
        
        local StartButton = Instance.new("TextButton")
        StartButton.Size = UDim2.new(1, -10, 0, 40)
        StartButton.Position = UDim2.new(0, 5, 0, padding)
        StartButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        StartButton.Text = HunterState.Active and "DETENER BÚSQUEDA" or "INICIAR BÚSQUEDA"
        StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartButton.Font = Enum.Font.GothamBold
        StartButton.TextSize = 14
        StartButton.Parent = container

        local PauseButton = Instance.new("TextButton")
        PauseButton.Size = UDim2.new(1, -10, 0, 40)
        PauseButton.Position = UDim2.new(0, 5, 0, padding + 45)
        PauseButton.BackgroundColor3 = HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120)
        PauseButton.Text = HunterState.Paused and "REANUDAR" or "PAUSAR"
        PauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        PauseButton.Font = Enum.Font.GothamBold
        PauseButton.TextSize = 14
        PauseButton.Parent = container

        StartButton.MouseButton1Click:Connect(function()
            HunterState.Active = not HunterState.Active
            StartButton.Text = HunterState.Active and "DETENER BÚSQUEDA" or "INICIAR BÚSQUEDA"
            StartButton.BackgroundColor3 = HunterState.Active and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(60, 120, 60)
            
            if HunterState.Active then
                coroutine.wrap(huntingLoop)()
            end
        end)

        PauseButton.MouseButton1Click:Connect(function()
            HunterState.Paused = not HunterState.Paused
            PauseButton.Text = HunterState.Paused and "REANUDAR" or "PAUSAR"
            PauseButton.BackgroundColor3 = HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120)
        end)

        -- Configuración rápida
        local configEntries = {
            {name = "Patrón de Búsqueda", key = "TARGET_PATTERN", type = "string"},
            {name = "Radio de Escaneo", key = "SCAN_RADIUS", type = "number"},
            {name = "Delay entre Servers", key = "SERVER_HOP_DELAY", type = "number"},
            {name = "Máx. Servidores", key = "MAX_SERVERS", type = "number"},
            {name = "Modo Debug", key = "DEBUG_MODE", type = "boolean"},
            {name = "Anti-Detección", key = "ANTI_DETECTION", type = "boolean"}
        }

        for i, entry in ipairs(configEntries) do
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, -10, 0, 20)
            label.Position = UDim2.new(0, 5, 0, padding + 100 + (i * 25))
            label.BackgroundTransparency = 1
            label.Text = entry.name .. ":"
            label.TextColor3 = Color3.fromRGB(220, 220, 220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.Parent = container

            if entry.type == "string" or entry.type == "number" then
                local textBox = Instance.new("TextBox")
                textBox.Size = UDim2.new(0.5, -10, 0, 20)
                textBox.Position = UDim2.new(0.5, 5, 0, padding + 100 + (i * 25))
                textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                textBox.BorderSizePixel = 0
                textBox.Text = tostring(CONFIG[entry.key])
                textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
                textBox.Font = Enum.Font.Gotham
                textBox.TextSize = 12
                textBox.Parent = container

                textBox.FocusLost:Connect(function()
                    if entry.type == "number" then
                        CONFIG[entry.key] = tonumber(textBox.Text) or CONFIG[entry.key]
                        textBox.Text = tostring(CONFIG[entry.key])
                    else
                        CONFIG[entry.key] = textBox.Text
                    end
                end)
            elseif entry.type == "boolean" then
                local toggleButton = Instance.new("TextButton")
                toggleButton.Size = UDim2.new(0.5, -10, 0, 20)
                toggleButton.Position = UDim2.new(0.5, 5, 0, padding + 100 + (i * 25))
                toggleButton.BackgroundColor3 = CONFIG[entry.key] and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(120, 60, 60)
                toggleButton.BorderSizePixel = 0
                toggleButton.Text = CONFIG[entry.key] and "ON" or "OFF"
                toggleButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                toggleButton.Font = Enum.Font.Gotham
                toggleButton.TextSize = 12
                toggleButton.Parent = container

                toggleButton.MouseButton1Click:Connect(function()
                    CONFIG[entry.key] = not CONFIG[entry.key]
                    toggleButton.BackgroundColor3 = CONFIG[entry.key] and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(120, 60, 60)
                    toggleButton.Text = CONFIG[entry.key] and "ON" or "OFF"
                end)
            end
        end
    end)

    -- Pestaña de Resultados
    createTab("Resultados", function(container)
        local TargetList = Instance.new("Frame")
        TargetList.Size = UDim2.new(1, 0, 1, 0)
        TargetList.BackgroundTransparency = 1
        TargetList.Parent = container

        local function updateTargetList()
            TargetList:ClearAllChildren()
            
            if #HunterState.Targets == 0 then
                local noTargets = Instance.new("TextLabel")
                noTargets.Size = UDim2.new(1, -10, 0, 40)
                noTargets.Position = UDim2.new(0, 5, 0, 5)
                noTargets.BackgroundTransparency = 1
                noTargets.Text = "No se encontraron objetivos aún"
                noTargets.TextColor3 = Color3.fromRGB(150, 150, 150)
                noTargets.TextXAlignment = Enum.TextXAlignment.Center
                noTargets.Font = Enum.Font.Gotham
                noTargets.TextSize = 14
                noTargets.Parent = TargetList
                return
            end

            for i, target in ipairs(HunterState.Targets) do
                if i > CONFIG.MAX_TARGETS then break end
                
                local targetFrame = Instance.new("Frame")
                targetFrame.Size = UDim2.new(1, -10, 0, 80)
                targetFrame.Position = UDim2.new(0, 5, 0, 5 + ((i-1) * 85))
                targetFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                targetFrame.Parent = TargetList

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = targetFrame

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -10, 0, 20)
                nameLabel.Position = UDim2.new(0, 5, 0, 5)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = target.name
                nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 12
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Parent = targetFrame

                local distanceLabel = Instance.new("TextLabel")
                distanceLabel.Size = UDim2.new(0.5, -10, 0, 20)
                distanceLabel.Position = UDim2.new(0, 5, 0, 30)
                distanceLabel.BackgroundTransparency = 1
                distanceLabel.Text = "Distancia: " .. math.floor(target.distance) .. " studs"
                distanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
                distanceLabel.Font = Enum.Font.Gotham
                distanceLabel.TextSize = 12
                distanceLabel.Parent = targetFrame

                local positionLabel = Instance.new("TextLabel")
                positionLabel.Size = UDim2.new(1, -10, 0, 20)
                positionLabel.Position = UDim2.new(0, 5, 0, 50)
                positionLabel.BackgroundTransparency = 1
                positionLabel.Text = string.format("Pos: X:%.1f, Y:%.1f, Z:%.1f", 
                    target.position.X, target.position.Y, target.position.Z)
                positionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                positionLabel.TextXAlignment = Enum.TextXAlignment.Left
                positionLabel.Font = Enum.Font.Gotham
                positionLabel.TextSize = 12
                positionLabel.Parent = targetFrame

                local teleportButton = Instance.new("TextButton")
                teleportButton.Size = UDim2.new(0.5, -10, 0, 20)
                teleportButton.Position = UDim2.new(0.5, 5, 0, 30)
                teleportButton.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
                teleportButton.Text = "TELEPORT"
                teleportButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                teleportButton.Font = Enum.Font.Gotham
                teleportButton.TextSize = 12
                teleportButton.Parent = targetFrame

                teleportButton.MouseButton1Click:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(target.position)
                    end
                end)
            end
        end

        updateTargetList()
        UI.UpdateTargetList = updateTargetList
    end)

    -- Pestaña de Estadísticas
    createTab("Estadísticas", function(container)
        local StatsFrame = Instance.new("Frame")
        StatsFrame.Size = UDim2.new(1, 0, 1, 0)
        StatsFrame.BackgroundTransparency = 1
        StatsFrame.Parent = container

        local function updateStats()
            StatsFrame:ClearAllChildren()
            
            local stats = {
                {"Servidores Escaneados", UI.Status.ServersScanned},
                {"Objetivos Encontrados", UI.Status.TargetsFound},
                {"Última Acción", UI.Status.CurrentAction},
                {"Estado", HunterState.Active and (HunterState.Paused and "PAUSADO" or "ACTIVO") or "INACTIVO"},
                {"Radio de Búsqueda", CONFIG.SCAN_RADIUS .. " studs"},
                {"Patrón Buscado", CONFIG.TARGET_PATTERN}
            }

            for i, stat in ipairs(stats) do
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.5, -10, 0, 20)
                label.Position = UDim2.new(0, 5, 0, 10 + ((i-1) * 25))
                label.BackgroundTransparency = 1
                label.Text = stat[1] .. ":"
                label.TextColor3 = Color3.fromRGB(180, 180, 180)
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Font = Enum.Font.Gotham
                label.TextSize = 12
                label.Parent = StatsFrame

                local value = Instance.new("TextLabel")
                value.Size = UDim2.new(0.5, -10, 0, 20)
                value.Position = UDim2.new(0.5, 5, 0, 10 + ((i-1) * 25))
                value.BackgroundTransparency = 1
                value.Text = tostring(stat[2])
                value.TextColor3 = Color3.fromRGB(220, 220, 220)
                value.TextXAlignment = Enum.TextXAlignment.Right
                value.Font = Enum.Font.GothamMedium
                value.TextSize = 12
                value.Parent = StatsFrame
            end
        end

        updateStats()
        UI.UpdateStats = updateStats
    end)

    MainWindow.Parent = CoreGui
    UI.MainWindow = MainWindow
end

-- 🔄 Función para actualizar la UI
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

-- 🔍 Escáner ultra-optimizado
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
    
    -- Cache de tipos para optimización
    local isModel = Instance.new("Model").ClassName
    local isFolder = Instance.new("Folder").ClassName
    
    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if not HunterState.Active then break end
            while HunterState.Paused do task.wait(1) end
            
            scannedInstances = scannedInstances + 1
            
            -- Coincidencia optimizada
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
            
            -- Escaneo recursivo optimizado
            local childClass = child.ClassName
            if childClass == isModel or childClass == isFolder then
                scanRecursive(child)
            end
        end
    end

    -- Áreas prioritarias con manejo de errores
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

    -- Ordenar y limitar resultados
    table.sort(foundTargets, function(a, b) return a.distance < b.distance end)
    
    if CONFIG.DEBUG_MODE then
        print(string.format("🔍 Escaneo completado en %.2fs | %d instancias | %d objetivos", 
              os.clock() - startTime, scannedInstances, #foundTargets))
    end
    
    UI.Status.CurrentAction = string.format("Escaneo completado (%d obj)", #foundTargets)
    updateUI()
    
    return foundTargets
end

-- 📨 Sistema de reportes mejorado
local function sendHunterReport(targets, jobId)
    local embeds = {}
    local content = nil
    
    -- Configuración de prioridad de notificación
    if #targets > 0 then
        content = "@everyone 🎯 OBJETIVO ENCONTRADO"
        local playerCount = #Players:GetPlayers()
        
        for i, target in ipairs(targets) do
            if i <= 3 then -- Limitar a 3 resultados
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

    -- Configuración del payload mejorado
    local payload = {
        username = "AltHunter Pro",
        avatar_url = "https://i.imgur.com/J7l1tO7.png",
        content = content,
        embeds = embeds
    }

    -- Sistema de reintentos mejorado
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
            task.wait(2 ^ attempts) -- Backoff exponencial
        end
    until success or attempts >= maxAttempts

    if not success and CONFIG.DEBUG_MODE then
        warn("⚠️ Error al enviar reporte después de", attempts, "intentos")
    end
    
    return success
end

-- 🌐 Sistema de obtención de servidores mejorado
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
            -- Filtrar servidores por población
            if server.playing and server.playing >= CONFIG.MIN_PLAYERS and server.playing <= CONFIG.MAX_PLAYERS then
                table.insert(servers, {
                    id = server.id,
                    players = server.playing,
                    ping = math.random(50, 150) -- Simular ping para priorización
                })
            end
        end
        
        -- Ordenar servidores por mejor ping y población
        table.sort(servers, function(a, b)
            return a.ping < b.ping or (a.ping == b.ping and a.players > b.players)
        end)
    else
        if CONFIG.DEBUG_MODE then
            warn("⚠️ Error al obtener servidores:", response)
            -- Usar servidores de respaldo si la API falla
            if game.JobId ~= "" then
                table.insert(servers, {id = game.JobId, players = #Players:GetPlayers(), ping = 100})
            end
        end
    end

    return servers
end

-- 🚀 Sistema de unión a servidores mejorado
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
            -- Usar teleportación suave si está disponible
            if TeleportService.TeleportInitiated then
                TeleportService:AbortTeleport()
                task.wait(0.5)
            end
            
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)

        if success then
            -- Esperar carga con timeout
            local loadStart = os.clock()
            local loaded = false
            
            while os.clock() - loadStart < 30 do -- Timeout de 30 segundos
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
                -- Esperar personaje válido
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
            local delay = math.min(5 * attempts, 15) -- Backoff progresivo
            task.wait(delay)
        end
    until success or attempts >= maxAttempts

    return success
end

 --///////////////////////////CLICLO HUNTING LOOP//////

       TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(UI.Tabs) do
                tab.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                tab.Content.Visible = false
            end
            TabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            TabContent.Visible = true
        end)

        table.insert(UI.Tabs, {
            Name = name,
            Button = TabButton,
            Content = TabContent
        })
    end
    


 --/////////////////////////HUNTINGLOOP////////////
    while HunterState.Active do
        -- Verificar parada emergente
        if isfile and isfile(stopFile) then
            print("🛑 Detención emergente activada. Finalizando ejecución.")
            UI.Status.CurrentAction = "Detenido por archivo de parada"
            updateUI()
            sendHunterReport({}, game.JobId) -- Reporte final
            return
        end
        
        while HunterState.Paused do
            UI.Status.CurrentAction = "Búsqueda en pausa..."
            updateUI()
            task.wait(1)
        end
        
        -- Obtener servidores con filtros mejorados
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
                -- Aplicar técnicas anti-detección
                if CONFIG.ANTI_DETECTION then
                    CONFIG.SERVER_HOP_DELAY = math.random(CONFIG.SERVER_HOP_DELAY-2, CONFIG.SERVER_HOP_DELAY+5)
                    task.wait(math.random(1, 3))
                end
                
                -- Escaneo profundo con medición de tiempo
                local scanStart = os.clock()
                HunterState.Targets = deepScan()
                local scanTime = os.clock() - scanStart
                
                if #HunterState.Targets > 0 then
                    UI.Status.TargetsFound = UI.Status.TargetsFound + #HunterState.Targets
                    updateUI()
                    sendHunterReport(HunterState.Targets, server.id)
                    
                    -- Decidir si continuar basado en la calidad del hallazgo
                    if HunterState.Targets[1].distance < 100 then -- Objetivo muy cercano
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
                
                -- Reporte periódico cada 10 servidores
                if UI.Status.ServersScanned % 10 == 0 then
                    sendHunterReport({}, server.id)
                end
            end

            -- Espera adaptativa basada en resultados anteriores
            local delay = CONFIG.SERVER_HOP_DELAY
            if #HunterState.Targets > 0 then
                delay = delay * 2 -- Esperar más si encontramos algo
            end
            task.wait(delay)
        end

        -- Reporte de estado cada ciclo completo
        if CONFIG.DEBUG_MODE then
            local elapsed = os.time() - UI.Status.startTime
            print(string.format("🔁 Ciclo completado | %d servidores | %d objetivos | %02d:%02d ejecutándose", 
                  UI.Status.ServersScanned, UI.Status.TargetsFound, elapsed/60, elapsed%60))
        end
        
        UI.Status.CurrentAction = "Refrescando lista de servidores..."
        updateUI()
        task.wait(30) -- Espera antes de refrescar lista
    end
    
    UI.Status.CurrentAction = "Búsqueda detenida"
    updateUI()
end

--////////////////////////////

-- 🎯 Inicialización corregida
local function initialize()
    -- Esperar por el personaje del jugador
    if not LocalPlayer.Character then
        if UI.StatusLabel then
            UI.StatusLabel.Text = "Estado: Esperando personaje..."
        end
        LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Crear la interfaz de usuario
    createUI()
    
    -- Configurar tecla de acceso rápido (Opcional)
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
    
    -- Iniciar estadísticas
    UI.Status.startTime = os.time()
    updateUI()
    
    -- Mensaje de inicio
    print("\n=== ALT HUNTER PRO INICIALIZADO ===")
    print("Configuración actual:")
    for k, v in pairs(CONFIG) do
        print(string.format("%s: %s", k, tostring(v)))
    end
    
    if UI.MainWindow then
        print("\nInterfaz de usuario disponible. Usa los controles para iniciar la búsqueda.")
    end
end

-- Ejecutar inicialización de manera segura
local function safeInitialize()
    local success, err = pcall(initialize)
    if not success then
        warn("Error durante la inicialización:", err)
        if UI.StatusLabel then
            UI.StatusLabel.Text = "Error: " .. tostring(err)
        end
    end
end

-- Ejecutar inicialización corregida
if coroutine and coroutine.wrap then
    coroutine.wrap(safeInitialize)()
else
    spawn(safeInitialize)
end