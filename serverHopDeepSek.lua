local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "Tralalero Tralala",
    TARGET_EARNINGS = 999999999, -- 💰 Lo que quieres ganar por segundo
    WEBHOOK_URL = "tu_webhook_aqui",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 2,
    MAX_SERVERS = 25,
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

-- 🖥️ Función para crear la interfaz de usuario (versión más pequeña)
local function createUI()
    if not UI.Enabled then return end
    
    -- Limpiar UI existente
    if UI.MainWindow and UI.MainWindow.Parent then
        UI.MainWindow:Destroy()
    end

    -- Crear la ventana principal (más pequeña)
    local MainWindow = Instance.new("ScreenGui")
    MainWindow.Name = "AltHunterProUI"
    MainWindow.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if syn and syn.protect_gui then
        syn.protect_gui(MainWindow)
    end

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 350) -- Tamaño reducido
    Frame.Position = UDim2.new(0.5, -150, 0.5, -175)
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
    TitleBar.Size = UDim2.new(1, 0, 0, 25) -- Más delgado
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
    Title.TextSize = 12 -- Texto más pequeño
    Title.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 25, 0, 25) -- Más pequeño
    CloseButton.Position = UDim2.new(1, -25, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 12
    CloseButton.Parent = TitleBar

    CloseButton.MouseButton1Click:Connect(function()
        MainWindow.Enabled = false
    end)

    -- Tabs Container
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Size = UDim2.new(1, 0, 0, 25) -- Más delgado
    TabsContainer.Position = UDim2.new(0, 0, 0, 25)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = Frame

    -- Content Container (más pequeño)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -10, 1, -80) -- Ajustado
    ContentContainer.Position = UDim2.new(0, 5, 0, 55)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = Frame

    -- Status Bar (más pequeño)
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, -10, 0, 20) -- Más delgado
    StatusBar.Position = UDim2.new(0, 5, 1, -25)
    StatusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    StatusBar.Parent = Frame

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = StatusBar

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -5, 1, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Estado: Iniciando..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 10 -- Texto más pequeño
    StatusLabel.Parent = StatusBar
    UI.StatusLabel = StatusLabel

    -- Crear pestañas (versión simplificada)
    local function createTab(name, content)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0.5, 0, 1, 0)
        TabButton.Position = UDim2.new(#UI.Tabs * 0.5, 0, 0, 0)
        TabButton.BackgroundColor3 = #UI.Tabs == 0 and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 50)
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(220, 220, 220)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 10 -- Texto más pequeño
        TabButton.Parent = TabsContainer

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.Position = UDim2.new(#UI.Tabs, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = #UI.Tabs == 0
        TabContent.ScrollBarThickness = 3 -- Más delgado
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.Parent = ContentContainer

        if content then
            content(TabContent)
        end

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

    -- Pestaña de Control (simplificada)
    createTab("Control", function(container)
        local padding = 3 -- Menos espacio
        
        local StartButton = Instance.new("TextButton")
        StartButton.Size = UDim2.new(1, -5, 0, 30) -- Más pequeño
        StartButton.Position = UDim2.new(0, 5, 0, padding)
        StartButton.BackgroundColor3 = HunterState.Active and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(60, 120, 60)
        StartButton.Text = HunterState.Active and "DETENER" or "INICIAR"
        StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartButton.Font = Enum.Font.GothamBold
        StartButton.TextSize = 12 -- Texto más pequeño
        StartButton.Parent = container

        local PauseButton = Instance.new("TextButton")
        PauseButton.Size = UDim2.new(1, -5, 0, 30) -- Más pequeño
        PauseButton.Position = UDim2.new(0, 5, 0, padding + 35)
        PauseButton.BackgroundColor3 = HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120)
        PauseButton.Text = HunterState.Paused and "REANUDAR" or "PAUSAR"
        PauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        PauseButton.Font = Enum.Font.GothamBold
        StartButton.TextSize = 12 -- Texto más pequeño
        PauseButton.Parent = container

        StartButton.MouseButton1Click:Connect(function()
            HunterState.Active = not HunterState.Active
            StartButton.Text = HunterState.Active and "DETENER" or "INICIAR"
            StartButton.BackgroundColor3 = HunterState.Active and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(60, 120, 60)
        end)

        PauseButton.MouseButton1Click:Connect(function()
            HunterState.Paused = not HunterState.Paused
            PauseButton.Text = HunterState.Paused and "REANUDAR" or "PAUSAR"
            PauseButton.BackgroundColor3 = HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120)
        end)

        -- Configuración rápida (simplificada)
        local configEntries = {
            {name = "Patrón", key = "TARGET_PATTERN", type = "string"},
            {name = "Radio", key = "SCAN_RADIUS", type = "number"},
            {name = "Delay", key = "SERVER_HOP_DELAY", type = "number"},
            {name = "Debug", key = "DEBUG_MODE", type = "boolean"}
        }

        for i, entry in ipairs(configEntries) do
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, -10, 0, 18) -- Más pequeño
            label.Position = UDim2.new(0, 5, 0, padding + 70 + (i * 22))
            label.BackgroundTransparency = 1
            label.Text = entry.name .. ":"
            label.TextColor3 = Color3.fromRGB(220, 220, 220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 10 -- Texto más pequeño
            label.Parent = container

            if entry.type == "string" or entry.type == "number" then
                local textBox = Instance.new("TextBox")
                textBox.Size = UDim2.new(0.5, -10, 0, 18) -- Más pequeño
                textBox.Position = UDim2.new(0.5, 5, 0, padding + 70 + (i * 22))
                textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                textBox.BorderSizePixel = 0
                textBox.Text = tostring(CONFIG[entry.key])
                textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
                textBox.Font = Enum.Font.Gotham
                textBox.TextSize = 10 -- Texto más pequeño
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
                toggleButton.Size = UDim2.new(0.5, -10, 0, 18) -- Más pequeño
                toggleButton.Position = UDim2.new(0.5, 5, 0, padding + 70 + (i * 22))
                toggleButton.BackgroundColor3 = CONFIG[entry.key] and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(120, 60, 60)
                toggleButton.BorderSizePixel = 0
                toggleButton.Text = CONFIG[entry.key] and "ON" or "OFF"
                toggleButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                toggleButton.Font = Enum.Font.Gotham
                toggleButton.TextSize = 10 -- Texto más pequeño
                toggleButton.Parent = container

                toggleButton.MouseButton1Click:Connect(function()
                    CONFIG[entry.key] = not CONFIG[entry.key]
                    toggleButton.BackgroundColor3 = CONFIG[entry.key] and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(120, 60, 60)
                    toggleButton.Text = CONFIG[entry.key] and "ON" or "OFF"
                end)
            end
        end
    end)

    -- Pestaña de Resultados (simplificada)
    createTab("Resultados", function(container)
        local TargetList = Instance.new("Frame")
        TargetList.Size = UDim2.new(1, 0, 1, 0)
        TargetList.BackgroundTransparency = 1
        TargetList.Parent = container

        local function updateTargetList()
            TargetList:ClearAllChildren()
            
            if #HunterState.Targets == 0 then
                local noTargets = Instance.new("TextLabel")
                noTargets.Size = UDim2.new(1, -10, 0, 30) -- Más pequeño
                noTargets.Position = UDim2.new(0, 5, 0, 5)
                noTargets.BackgroundTransparency = 1
                noTargets.Text = "No se encontraron objetivos"
                noTargets.TextColor3 = Color3.fromRGB(150, 150, 150)
                noTargets.TextXAlignment = Enum.TextXAlignment.Center
                noTargets.Font = Enum.Font.Gotham
                noTargets.TextSize = 10 -- Texto más pequeño
                noTargets.Parent = TargetList
                return
            end

            for i, target in ipairs(HunterState.Targets) do
                if i > CONFIG.MAX_TARGETS then break end
                
                local targetFrame = Instance.new("Frame")
                targetFrame.Size = UDim2.new(1, -5, 0, 60) -- Más pequeño
                targetFrame.Position = UDim2.new(0, 5, 0, 5 + ((i-1) * 65))
                targetFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                targetFrame.Parent = TargetList

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = targetFrame

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -5, 0, 15) -- Más pequeño
                nameLabel.Position = UDim2.new(0, 5, 0, 5)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = target.name
                nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 10 -- Texto más pequeño
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Parent = targetFrame

                local distanceLabel = Instance.new("TextLabel")
                distanceLabel.Size = UDim2.new(0.5, -5, 0, 15) -- Más pequeño
                distanceLabel.Position = UDim2.new(0, 5, 0, 25)
                distanceLabel.BackgroundTransparency = 1
                distanceLabel.Text = "Dist: " .. math.floor(target.distance) .. " studs"
                distanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
                distanceLabel.Font = Enum.Font.Gotham
                distanceLabel.TextSize = 9 -- Texto más pequeño
                distanceLabel.Parent = targetFrame

                local teleportButton = Instance.new("TextButton")
                teleportButton.Size = UDim2.new(0.5, -5, 0, 15) -- Más pequeño
                teleportButton.Position = UDim2.new(0.5, 5, 0, 25)
                teleportButton.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
                teleportButton.Text = "TELEPORT"
                teleportButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                teleportButton.Font = Enum.Font.Gotham
                teleportButton.TextSize = 9 -- Texto más pequeño
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

    -- Pestaña de Estadísticas (simplificada)
    createTab("Estadísticas", function(container)
        local StatsFrame = Instance.new("Frame")
        StatsFrame.Size = UDim2.new(1, 0, 1, 0)
        StatsFrame.BackgroundTransparency = 1
        StatsFrame.Parent = container

        local function updateStats()
            StatsFrame:ClearAllChildren()
            
            local stats = {
                {"Servidores", UI.Status.ServersScanned},
                {"Objetivos", UI.Status.TargetsFound},
                {"Estado", HunterState.Active and (HunterState.Paused and "PAUSADO" or "ACTIVO") or "INACTIVO"},
                {"Radio", CONFIG.SCAN_RADIUS .. " studs"}
            }

            for i, stat in ipairs(stats) do
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.5, -5, 0, 15) -- Más pequeño
                label.Position = UDim2.new(0, 5, 0, 5 + ((i-1) * 20))
                label.BackgroundTransparency = 1
                label.Text = stat[1] .. ":"
                label.TextColor3 = Color3.fromRGB(180, 180, 180)
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Font = Enum.Font.Gotham
                label.TextSize = 10 -- Texto más pequeño
                label.Parent = StatsFrame

                local value = Instance.new("TextLabel")
                value.Size = UDim2.new(0.5, -5, 0, 15) -- Más pequeño
                value.Position = UDim2.new(0.5, 5, 0, 5 + ((i-1) * 20))
                value.BackgroundTransparency = 1
                value.Text = tostring(stat[2])
                value.TextColor3 = Color3.fromRGB(220, 220, 220)
                value.TextXAlignment = Enum.TextXAlignment.Right
                value.Font = Enum.Font.GothamMedium
                value.TextSize = 10 -- Texto más pequeño
                value.Parent = StatsFrame
            end
        end

        updateStats()
        UI.UpdateStats = updateStats
    end)

    MainWindow.Parent = CoreGui
    UI.MainWindow = MainWindow
    MainWindow.Enabled = false -- Inicialmente oculto
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

-- Obtener universeId
local function getUniverseIdFromPlaceId(placeId)
    local url = string.format("https://games.roblox.com/v1/games/multiget-place-details?placeIds=[%d]", placeId)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data[1] and data[1].universeId then
            return tostring(data[1].universeId)
        end
    end
    if CONFIG.DEBUG_MODE then
        warn("No se pudo obtener universeId para el placeId "..tostring(placeId))
    end
    return nil
end

local universeId = getUniverseIdFromPlaceId(CONFIG.GAME_ID) or tostring(CONFIG.GAME_ID)

-- Obtener servidores activos
local function getActiveServers()
    local servers = {}
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?limit=%d",
        universeId,
        CONFIG.MAX_SERVERS
    )
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data or {}) do
            table.insert(servers, server.id)
        end
    else
        warn("Error al obtener servidores: ", response)
    end

    return servers
end

-- Escaneo con chequeo por earnings
local function deepScan()
    local foundTargets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local rootPosition = rootPart and rootPart.Position or Vector3.new(0,0,0)

    UI.Status.CurrentAction = "Escaneando entorno..."
    updateUI()

    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if not HunterState.Active then break end
            while HunterState.Paused do task.wait(1) end
            
            local match = false
            local earningsDetected = nil

            -- Coincidencia por nombre
            if string.find(string.lower(child.Name), string.lower(CONFIG.TARGET_PATTERN)) then
                match = true
            end

            -- Coincidencia por NumberValue directo
            for _, v in ipairs(child:GetChildren()) do
                if v:IsA("NumberValue") and v.Name:lower():find("earnings") then
                    if v.Value == CONFIG.TARGET_EARNINGS then
                        match = true
                        earningsDetected = v.Value
                    end
                end
            end

            -- Coincidencia por TextLabel de BillboardGui
            for _, gui in ipairs(child:GetDescendants()) do
                if gui:IsA("TextLabel") then
                    local text = gui.Text:gsub("[^%d]", "")
                    local number = tonumber(text)
                    if number and number == CONFIG.TARGET_EARNINGS then
                        match = true
                        earningsDetected = number
                    end
                end
            end

            -- Si coincide
            if match then
                local success, pivot = pcall(function() return child:GetPivot() end)
                if success and pivot then
                    local objectPos = pivot.Position
                    local distance = (objectPos - rootPosition).Magnitude

                    if distance <= CONFIG.SCAN_RADIUS then
                        table.insert(foundTargets, {
                            name = child.Name,
                            fullName = child:GetFullName(),
                            position = objectPos,
                            distance = distance,
                            earnings = earningsDetected or "?",
                            timestamp = os.time(),
                            instance = child
                        })
                        
                        UI.Status.CurrentAction = string.format("Objetivo encontrado a %d studs", distance)
                        updateUI()
                    end
                end
            end

            if child:IsA("Model") or child:IsA("Folder") then
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

    for _, area in ipairs(priorityAreas) do
        if not HunterState.Active then break end
        scanRecursive(area)
    end

    table.sort(foundTargets, function(a, b) return a.distance < b.distance end)

    UI.Status.CurrentAction = string.format("Escaneo completado (%d obj)", #foundTargets)
    updateUI()

    return foundTargets
end

-- Reporte
local function sendHunterReport(targets, jobId)
    local embeds = {}
    local content = #targets > 0 and "@everyone 🎯 OBJETIVO ENCONTRADO" or nil

    if #targets > 0 then
        for i, target in ipairs(targets) do
            if i <= 3 then
                table.insert(embeds, {
                    title = string.format("OBJETO #%d - %.1f studs", i, target.distance),
                    description = target.fullName,
                    color = 65280,
                    fields = {
                        {name = "Posición", value = string.format("X:%.1f Y:%.1f Z:%.1f", target.position.X, target.position.Y, target.position.Z)},
                        {name = "Ganancia/s", value = tostring(target.earnings)},
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

-- Teleport
local function joinServer(jobId)
    local attempts = 0
    local maxAttempts = 3

    UI.Status.CurrentAction = "Uniendo a servidor..."
    updateUI()

    repeat
        attempts += 1
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)

        if success then
            repeat task.wait(1) until game:IsLoaded()
            local waitTime = 0
            while not Workspace:FindFirstChildWhichIsA("Model") and waitTime < 15 do
                waitTime += 1
                task.wait(1)
            end

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

-- Loop principal
local function huntingLoop()
    print("\n=== INICIANDO MODO HUNTER ===")
    print(string.format("🔍 Buscando '%s' o 💰 %d/s en radio de %d studs", CONFIG.TARGET_PATTERN, CONFIG.TARGET_EARNINGS, CONFIG.SCAN_RADIUS))
    
    -- Estadísticas de ejecución
    UI.Status.ServersScanned = 0
    UI.Status.TargetsFound = 0
    UI.Status.CurrentAction = "Iniciando búsqueda..."
    updateUI()

    while HunterState.Active do
        while HunterState.Paused do
            UI.Status.CurrentAction = "Búsqueda en pausa..."
            updateUI()
            task.wait(1)
        end
        
        local servers = getActiveServers()
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores. Reintentando en 1 minuto...")
            UI.Status.CurrentAction = "Esperando servidores..."
            updateUI()
            task.wait(60)
        else
            UI.Status.ServersScanned = UI.Status.ServersScanned + #servers
            updateUI()

            if CONFIG.DEBUG_MODE then
                print(string.format("🔄 Obtenidos %d servidores activos", #servers))
            end

            for _, serverId in ipairs(servers) do
                if not HunterState.Active then break end
                while HunterState.Paused do task.wait(1) end
          
                if CONFIG.DEBUG_MODE then
                    print("🛫 Intentando unirse a:", serverId)
                end

                if joinServer(serverId) then
                    local targets = deepScan()
                    HunterState.Targets = targets
                    UI.Status.TargetsFound = UI.Status.TargetsFound + #targets
                    updateUI()
                    
                    sendHunterReport(targets, serverId)

                    if #targets > 0 then
                        print("🎯 Objetivo encontrado! Finalizando búsqueda.")
                        UI.Status.CurrentAction = "Objetivo encontrado!"
                        updateUI()
                        HunterState.Active = false
                        break
                    end
                end

                task.wait(CONFIG.SERVER_HOP_DELAY)
            end

            if HunterState.Active and CONFIG.DEBUG_MODE then
                print("🔁 Reiniciando ciclo de búsqueda...")
            end

            if HunterState.Active then
                task.wait(30)
            end
        end
    end
    
    UI.Status.CurrentAction = "Búsqueda detenida"
    updateUI()
end

-- 🎯 Inicialización
local function initialize()
    -- Esperar por el personaje del jugador
    if not LocalPlayer.Character then
        UI.Status.CurrentAction = "Esperando personaje..."
        updateUI()
        LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Crear la interfaz de usuario
    createUI()
    
    -- Configurar tecla de acceso rápido (F5 para mostrar/ocultar)
    if syn and syn.is_beta then
        syn.toast_notification("Alt Hunter Pro", "Presiona F5 para mostrar/ocultar la interfaz", 5)
    end
    
    local UIVisible = false
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.F5 then
            UIVisible = not UIVisible
            if UI.MainWindow then
                UI.MainWindow.Enabled = UIVisible
            end
        end
    end)
    
    -- Iniciar estadísticas
    UI.Status.startTime = os.time()
    updateUI()
    
    -- Mensaje de inicio
    print("\n=== ALT HUNTER PRO INICIALIZADO ===")
    print("Configuración actual:")
    for k, v in pairs(CONFIG) do
        print(string.format("%s: %s", k, tostring(v)))
    end
    
    -- Iniciar automáticamente si se desea
    -- HunterState.Active = true
    -- coroutine.wrap(huntingLoop)()
end

-- Ejecutar inicialización
initialize()
