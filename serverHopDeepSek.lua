
-- Configuración principal
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "Tralalero Tralala",
    TARGET_EARNINGS = 999999999,
    WEBHOOK_URL = "tu_webhook_aqui",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 2,
    MAX_SERVERS = 25,
    DEBUG_MODE = true
}

-- Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variable de control
local running = false -- Cambiado a false inicialmente

-- Crear la GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10

-- Marco principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.5, 0, 0.2, 0) -- Aumentado para botón extra
MainFrame.Position = UDim2.new(0.25, 0, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Selectable = true

-- Esquinas redondeadas
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.1, 0)
UICorner.Parent = MainFrame

-- Título
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0.25, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Server Hopper"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextStrokeTransparency = 0.8
TitleLabel.Parent = MainFrame

-- Contador de servidores
local CounterLabel = Instance.new("TextLabel")
CounterLabel.Name = "CounterLabel"
CounterLabel.Size = UDim2.new(1, 0, 0.25, 0)
CounterLabel.Position = UDim2.new(0, 0, 0.25, 0)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "Presiona INICIAR"
CounterLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
CounterLabel.TextScaled = true
CounterLabel.Font = Enum.Font.Gotham
CounterLabel.Parent = MainFrame

-- Botón de inicio
local StartButton = Instance.new("TextButton")
StartButton.Name = "StartButton"
StartButton.Size = UDim2.new(0.8, 0, 0.2, 0)
StartButton.Position = UDim2.new(0.1, 0, 0.5, 0)
StartButton.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
StartButton.BackgroundTransparency = 0.3
StartButton.Text = "INICIAR"
StartButton.TextColor3 = Color3.fromRGB(200, 255, 200)
StartButton.TextScaled = true
StartButton.Font = Enum.Font.GothamBold
StartButton.Parent = MainFrame

-- Botón de detener
local StopButton = Instance.new("TextButton")
StopButton.Name = "StopButton"
StopButton.Size = UDim2.new(0.8, 0, 0.2, 0)
StopButton.Position = UDim2.new(0.1, 0, 0.75, 0)
StopButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
StartButton.BackgroundTransparency = 0.3
StopButton.Text = "DETENER"
StopButton.TextColor3 = Color3.fromRGB(255, 200, 200)
StopButton.TextScaled = true
StopButton.Font = Enum.Font.GothamBold
StopButton.Parent = MainFrame

-- Esquinas redondeadas para los botones
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0.2, 0)
ButtonCorner.Parent = StartButton
ButtonCorner:Clone().Parent = StopButton

-- Efecto hover para los botones
local function setupButtonHover(button, normalColor, hoverColor)
    button.MouseButton1Down:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)

    button.MouseButton1Up:Connect(function()
        button.BackgroundColor3 = normalColor
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normalColor
    end)
end

setupButtonHover(StartButton, Color3.fromRGB(30, 80, 30), Color3.fromRGB(40, 100, 40))
setupButtonHover(StopButton, Color3.fromRGB(80, 30, 30), Color3.fromRGB(100, 40, 40))

-- Sonido de notificación
local notificationSound = Instance.new("Sound")
notificationSound.SoundId = "rbxassetid://4590662760"
notificationSound.Volume = 0.5
notificationSound.Parent = SoundService

-- Función para hacer la GUI arrastrable
local function makeDraggable(gui, handle)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Hacer el marco principal arrastrable
makeDraggable(MainFrame, MainFrame)

-- Función para mostrar que se encontró una entidad
local function showEntityFound()
    CounterLabel.Text = "¡Entidad en el servidor!"
    CounterLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    
    -- Efecto de parpadeo
    local flashTween = TweenService:Create(
        CounterLabel,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true),
        {TextTransparency = 0.5}
    )
    flashTween:Play()
    
    -- Reproducir sonido de notificación
    notificationSound:Play()
end

-- Función para actualizar el contador
local function updateCounter(count)
    CounterLabel.Text = "Servers: " .. tostring(count)
    CounterLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    CounterLabel.TextTransparency = 0
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

    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
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
                            name = child:GetFullName(),
                            position = objectPos,
                            distance = distance,
                            earnings = earningsDetected or "?"
                        })
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
        scanRecursive(area)
    end

    table.sort(foundTargets, function(a, b) return a.distance < b.distance end)

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
                    description = target.name,
                    color = 65280,
                    fields = {
                        {name = "Posición", value = tostring(target.position)},
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

    local serversVisited = 0
    
    while running do
        local servers = getActiveServers()
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores. Reintentando en 1 minuto...")
            task.wait(60)
        else
            if CONFIG.DEBUG_MODE then
                print(string.format("🔄 Obtenidos %d servidores activos", #servers))
            end

            for _, serverId in ipairs(servers) do
                if not running then break end
                
                serversVisited += 1
                updateCounter(serversVisited)

                if CONFIG.DEBUG_MODE then
                    print("🛫 Intentando unirse a:", serverId)
                end

                if joinServer(serverId) then
                    local targets = deepScan()
                    sendHunterReport(targets, serverId)

                    if #targets > 0 then
                        print("🎯 Objetivo encontrado! Finalizando búsqueda.")
                        showEntityFound()
                        running = false
                        break
                    end
                end

                task.wait(CONFIG.SERVER_HOP_DELAY)
            end

            if running and CONFIG.DEBUG_MODE then
                print("🔁 Reiniciando ciclo de búsqueda...")
            end

            if running then
                task.wait(30)
            end
        end
    end
end

-- Conectar botón de inicio
StartButton.MouseButton1Click:Connect(function()
    if not running then
        running = true
        StartButton.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
        StopButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
        TitleLabel.Text = "BUSCANDO..."
        CounterLabel.Text = "Servers: 0"
        
        -- Iniciar el proceso de búsqueda en un nuevo hilo
        coroutine.wrap(function()
            huntingLoop()
        end)()
    end
end)

-- Conectar el botón de detener
StopButton.MouseButton1Click:Connect(function()
    running = false
    StartButton.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
    TitleLabel.Text = "DETENIDO"
    CounterLabel.Text = "Búsqueda finalizada"
end)

