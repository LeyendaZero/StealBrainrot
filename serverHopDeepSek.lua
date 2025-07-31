local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "Chimpanzini Spiderini",
    TARGET_EARNINGS = 999999999,
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

-- Servicios
local huntingLoop
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Variables UI
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

-- Bola flotante
local floatingBall = Instance.new("TextButton")
floatingBall.Name = "HunterFloatingBall"
floatingBall.Size = UDim2.new(0, 50, 0, 50)
floatingBall.Position = UDim2.new(0.8, 0, 0.8, 0)
floatingBall.AnchorPoint = Vector2.new(0.5, 0.5)
floatingBall.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
floatingBall.Text = "🦊"
floatingBall.TextSize = 24
floatingBall.ZIndex = 10
floatingBall.BorderSizePixel = 0

local ballCorner = Instance.new("UICorner", floatingBall)
ballCorner.CornerRadius = UDim.new(1, 0)

local ballShadow = Instance.new("ImageLabel", floatingBall)
ballShadow.Name = "Shadow"
ballShadow.Size = UDim2.new(1, 10, 1, 10)
ballShadow.Position = UDim2.new(0, -5, 0, -5)
ballShadow.BackgroundTransparency = 1
ballShadow.Image = "rbxassetid://94048288092765"
ballShadow.ImageColor3 = Color3.new(0, 0, 0)
ballShadow.ImageTransparency = 0.8
ballShadow.ScaleType = Enum.ScaleType.Slice
ballShadow.SliceCenter = Rect.new(10, 10, 118, 118)
ballShadow.ZIndex = 9

-- Función para crear la interfaz móvil
local function createMobileUI()
    if not UI.Enabled then return end
    
    -- Limpiar UI existente
    if UI.MainWindow and UI.MainWindow.Parent then
        UI.MainWindow:Destroy()
    end

    -- Crear la ventana principal
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "AltHunterMobileUI"
    MainWindow.Size = UDim2.new(0.8, 0, 0.7, 0)
    MainWindow.Position = UDim2.new(0.1, 0, 0.15, 0)
    MainWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    MainWindow.BorderSizePixel = 0
    MainWindow.Visible = false

    local Corner = Instance.new("UICorner", MainWindow)
    Corner.CornerRadius = UDim.new(0.05, 0)

    local TitleBar = Instance.new("Frame", MainWindow)
    TitleBar.Size = UDim2.new(1, 0, 0.08, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    TitleBar.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(0.8, 0, 1, 0)
    Title.Position = UDim2.new(0.1, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "HUNTER PRO"
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold

    local CloseButton = Instance.new("TextButton", TitleBar)
    CloseButton.Size = UDim2.new(0.15, 0, 1, 0)
    CloseButton.Position = UDim2.new(0.85, 0, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    CloseButton.TextScaled = true

    -- Tabs Container
    local TabsContainer = Instance.new("Frame", MainWindow)
    TabsContainer.Size = UDim2.new(1, 0, 0.1, 0)
    TabsContainer.Position = UDim2.new(0, 0, 0.08, 0)
    TabsContainer.BackgroundTransparency = 1

    -- Content Container
    local ContentContainer = Instance.new("Frame", MainWindow)
    ContentContainer.Size = UDim2.new(1, -10, 0.8, -10)
    ContentContainer.Position = UDim2.new(0, 5, 0.18, 5)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true

    -- Status Bar
    local StatusBar = Instance.new("Frame", MainWindow)
    StatusBar.Size = UDim2.new(1, -10, 0.08, 0)
    StatusBar.Position = UDim2.new(0, 5, 0.9, 0)
    StatusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    
    local StatusLabel = Instance.new("TextLabel", StatusBar)
    StatusLabel.Size = UDim2.new(1, -10, 1, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Estado: Iniciando..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.TextScaled = true
    StatusLabel.Font = Enum.Font.Gotham
    UI.StatusLabel = StatusLabel

    -- Función para crear pestañas móviles
    local function createMobileTab(name, content)
        local TabButton = Instance.new("TextButton", TabsContainer)
        TabButton.Size = UDim2.new(0.33, -2, 1, 0)
        TabButton.Position = UDim2.new(#UI.Tabs * 0.33, 0, 0, 0)
        TabButton.BackgroundColor3 = #UI.Tabs == 0 and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 50)
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(220, 220, 220)
        TabButton.TextScaled = true
        TabButton.Font = Enum.Font.Gotham

        local TabContent = Instance.new("ScrollingFrame", ContentContainer)
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.Position = UDim2.new(#UI.Tabs, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = #UI.Tabs == 0
        TabContent.ScrollBarThickness = 4
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

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

    -- Pestaña de Control móvil
    createMobileTab("Control", function(container)
        local StartButton = Instance.new("TextButton", container)
        StartButton.Size = UDim2.new(1, -10, 0.2, 0)
        StartButton.Position = UDim2.new(0, 5, 0, 5)
        StartButton.BackgroundColor3 = HunterState.Active and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(60, 120, 60)
        StartButton.Text = HunterState.Active and "DETENER" or "INICIAR"
        StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartButton.TextScaled = true
        StartButton.Font = Enum.Font.GothamBold

        local PauseButton = Instance.new("TextButton", container)
        PauseButton.Size = UDim2.new(1, -10, 0.2, 0)
        PauseButton.Position = UDim2.new(0, 5, 0.25, 0)
        PauseButton.BackgroundColor3 = HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120)
        PauseButton.Text = HunterState.Paused and "REANUDAR" or "PAUSAR"
        PauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        PauseButton.TextScaled = true
        PauseButton.Font = Enum.Font.GothamBold

        StartButton.MouseButton1Click:Connect(function()
            HunterState.Active = not HunterState.Active
            StartButton.Text = HunterState.Active and "DETENER" or "INICIAR"
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

        -- Configuración móvil simplificada
        local configEntries = {
            {name = "Patrón:", key = "TARGET_PATTERN", type = "string", pos = 0.5},
            {name = "Radio:", key = "SCAN_RADIUS", type = "number", pos = 0.7},
            {name = "Delay:", key = "SERVER_HOP_DELAY", type = "number", pos = 0.9}
        }

        for _, entry in ipairs(configEntries) do
            local label = Instance.new("TextLabel", container)
            label.Size = UDim2.new(0.4, -5, 0.1, 0)
            label.Position = UDim2.new(0, 5, entry.pos, 0)
            label.BackgroundTransparency = 1
            label.Text = entry.name
            label.TextColor3 = Color3.fromRGB(220, 220, 220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextScaled = true
            label.Font = Enum.Font.Gotham

            if entry.type == "string" or entry.type == "number" then
                local textBox = Instance.new("TextBox", container)
                textBox.Size = UDim2.new(0.6, -5, 0.1, 0)
                textBox.Position = UDim2.new(0.4, 5, entry.pos, 0)
                textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                textBox.BorderSizePixel = 0
                textBox.Text = tostring(CONFIG[entry.key])
                textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
                textBox.TextScaled = true
                textBox.Font = Enum.Font.Gotham

                textBox.FocusLost:Connect(function()
                    if entry.type == "number" then
                        CONFIG[entry.key] = tonumber(textBox.Text) or CONFIG[entry.key]
                        textBox.Text = tostring(CONFIG[entry.key])
                    else
                        CONFIG[entry.key] = textBox.Text
                    end
                end)
            end
        end
    end)

    -- Pestaña de Resultados móvil
    createMobileTab("Resultados", function(container)
        local TargetList = Instance.new("Frame", container)
        TargetList.Size = UDim2.new(1, 0, 1, 0)
        TargetList.BackgroundTransparency = 1

        local function updateTargetList()
            TargetList:ClearAllChildren()
            
            if #HunterState.Targets == 0 then
                local noTargets = Instance.new("TextLabel", TargetList)
                noTargets.Size = UDim2.new(1, -10, 0.2, 0)
                noTargets.Position = UDim2.new(0, 5, 0.4, 0)
                noTargets.BackgroundTransparency = 1
                noTargets.Text = "No se encontraron objetivos"
                noTargets.TextColor3 = Color3.fromRGB(150, 150, 150)
                noTargets.TextScaled = true
                noTargets.Font = Enum.Font.Gotham
                return
            end

            for i, target in ipairs(HunterState.Targets) do
                if i > CONFIG.MAX_TARGETS then break end
                
                local targetFrame = Instance.new("Frame", TargetList)
                targetFrame.Size = UDim2.new(1, -10, 0.3, 0)
                targetFrame.Position = UDim2.new(0, 5, (i-1) * 0.32, 0)
                targetFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                Instance.new("UICorner", targetFrame)

                local nameLabel = Instance.new("TextLabel", targetFrame)
                nameLabel.Size = UDim2.new(1, -10, 0.4, 0)
                nameLabel.Position = UDim2.new(0, 5, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = target.name
                nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextScaled = true
                nameLabel.Font = Enum.Font.GothamBold

                local distanceLabel = Instance.new("TextLabel", targetFrame)
                distanceLabel.Size = UDim2.new(0.5, -5, 0.3, 0)
                distanceLabel.Position = UDim2.new(0, 5, 0.4, 0)
                distanceLabel.BackgroundTransparency = 1
                distanceLabel.Text = "Dist: " .. math.floor(target.distance) .. " studs"
                distanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
                distanceLabel.TextScaled = true
                distanceLabel.Font = Enum.Font.Gotham

                local teleportButton = Instance.new("TextButton", targetFrame)
                teleportButton.Size = UDim2.new(0.5, -5, 0.3, 0)
                teleportButton.Position = UDim2.new(0.5, 5, 0.4, 0)
                teleportButton.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
                teleportButton.Text = "TELEPORT"
                teleportButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                teleportButton.TextScaled = true
                teleportButton.Font = Enum.Font.Gotham

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

    -- Pestaña de Estadísticas móvil
    createMobileTab("Estadísticas", function(container)
        local StatsFrame = Instance.new("Frame", container)
        StatsFrame.Size = UDim2.new(1, 0, 1, 0)
        StatsFrame.BackgroundTransparency = 1

        local function updateStats()
            StatsFrame:ClearAllChildren()
            
            local stats = {
                {"Servidores:", UI.Status.ServersScanned},
                {"Objetivos:", UI.Status.TargetsFound},
                {"Estado:", HunterState.Active and (HunterState.Paused and "PAUSADO" or "ACTIVO") or "INACTIVO"},
                {"Radio:", CONFIG.SCAN_RADIUS .. " studs"}
            }

            for i, stat in ipairs(stats) do
                local label = Instance.new("TextLabel", StatsFrame)
                label.Size = UDim2.new(0.5, -5, 0.2, 0)
                label.Position = UDim2.new(0, 5, (i-1) * 0.2, 0)
                label.BackgroundTransparency = 1
                label.Text = stat[1]
                label.TextColor3 = Color3.fromRGB(180, 180, 180)
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextScaled = true
                label.Font = Enum.Font.Gotham

                local value = Instance.new("TextLabel", StatsFrame)
                value.Size = UDim2.new(0.5, -5, 0.2, 0)
                value.Position = UDim2.new(0.5, 5, (i-1) * 0.2, 0)
                value.BackgroundTransparency = 1
                value.Text = tostring(stat[2])
                value.TextColor3 = Color3.fromRGB(220, 220, 220)
                value.TextXAlignment = Enum.TextXAlignment.Right
                value.TextScaled = true
                value.Font = Enum.Font.GothamMedium
            end
        end

        updateStats()
        UI.UpdateStats = updateStats
    end)

    -- Configurar eventos de la bola flotante
    floatingBall.MouseButton1Click:Connect(function()
        MainWindow.Visible = not MainWindow.Visible
        floatingBall.Text = MainWindow.Visible and "✕" or "☄️"
    end)

    CloseButton.MouseButton1Click:Connect(function()
        MainWindow.Visible = false
        floatingBall.Text = "☄️"
    end)

    -- Añadir al CoreGui
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "HunterMobileUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    floatingBall.Parent = ScreenGui
    MainWindow.Parent = ScreenGui
    UI.MainWindow = MainWindow
end

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
huntingLoop = function()
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

-- Inicialización para móvil
local function initializeMobile()
    -- Esperar por el personaje del jugador
    if not LocalPlayer.Character then
        UI.Status.CurrentAction = "Esperando personaje..."
        updateUI()
        LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Crear la interfaz de usuario móvil
    createMobileUI()
    
    -- Iniciar estadísticas
    UI.Status.startTime = os.time()
    updateUI()
    
    -- Mensaje de inicio
    print("\n=== HUNTER PRO INICIALIZADO ===")
    print("Configuración actual:")
    for k, v in pairs(CONFIG) do
        print(string.format("%s: %s", k, tostring(v)))
    end
end

-- Ejecutar inicialización móvil
initializeMobile()
