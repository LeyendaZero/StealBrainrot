local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "Tralalero Tralala",
    TARGET_EARNINGS = 999999999, -- 💰 Lo que quieres ganar por segundo
    WEBHOOK_URL = "tu_webhook_aqui",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 2,
    MAX_SERVERS = 25,
    DEBUG_MODE = true
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Configuración inicial
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variables de control
local serversVisited = 0
_G.running = true

-- GUI principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FloatingHunterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Marco flotante
local DragFrame = Instance.new("Frame")
DragFrame.Size = UDim2.new(0, 200, 0, 60)
DragFrame.Position = UDim2.new(0.65, 0, 0.05, 0)
DragFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DragFrame.BackgroundTransparency = 0.2
DragFrame.BorderSizePixel = 0
DragFrame.Active = true
DragFrame.Draggable = true
DragFrame.Parent = ScreenGui

-- Esquinas redondeadas
local UICorner = Instance.new("UICorner", DragFrame)
UICorner.CornerRadius = UDim.new(0, 8)

-- Texto principal
local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 0.5, 0)
TextLabel.Position = UDim2.new(0, 0, 0, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.TextScaled = true
TextLabel.Text = "Servidores: 0"
TextLabel.Parent = DragFrame

-- Botón de detener
local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(1, 0, 0.5, 0)
StopButton.Position = UDim2.new(0, 0, 0.5, 0)
StopButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
StopButton.Text = "DETENER"
StopButton.TextScaled = true
StopButton.TextColor3 = Color3.new(1, 1, 1)
StopButton.Font = Enum.Font.SourceSansBold
StopButton.Parent = DragFrame

local ButtonCorner = Instance.new("UICorner", StopButton)
ButtonCorner.CornerRadius = UDim.new(0, 6)

-- Sonido de campanita
local BellSound = Instance.new("Sound")
BellSound.SoundId = "rbxassetid://911342077" -- ID de campanita
BellSound.Volume = 1
BellSound.Parent = DragFrame

-- Función para actualizar UI
local function updateUI(message, color)
	TextLabel.Text = message
	TextLabel.TextColor3 = color or Color3.fromRGB(0, 255, 0)
end

-- Parpadeo visual cuando encuentra entidad
local function flashMessage()
	task.spawn(function()
		for i = 1, 6 do
			TextLabel.Visible = not TextLabel.Visible
			task.wait(0.25)
		end
		TextLabel.Visible = true
	end)
end

-- Función pública que puedes llamar desde tu script cuando encuentra entidad
function onEntityFound()
	updateUI("¡Entidad en el servidor!", Color3.fromRGB(255, 0, 0))
	BellSound:Play()
	flashMessage()
end

-- Evento del botón para detener script
StopButton.MouseButton1Click:Connect(function()
	_G.running = false
	updateUI("🔴 Búsqueda detenida", Color3.fromRGB(255, 60, 60))
end)

-- Función para aumentar contador (llámala después de cada servidor visitado)
function incrementServerCount()
	serversVisited += 1
	updateUI("Servidores: " .. serversVisited)
end


local running = true

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

-- Función mejorada para unirse a servidor con estabilización
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
            
            -- Espera inicial para que el servidor se estabilice
            local waitTime = 0
            while waitTime < 5 do  -- Espera inicial de 5 segundos
                waitTime += 1
                task.wait(1)
            end

            -- Verificar que el personaje esté cargado
            if not LocalPlayer.Character then
                LocalPlayer.CharacterAdded:Wait()
                task.wait(2)  -- Espera adicional después de spawn
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

-- Función para monitorear estabilidad del servidor
local function checkServerStability()
    -- Obtener lista inicial de jugadores
    local initialPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        initialPlayers[player.Name] = true
    end
    
    -- Esperar periodo de observación
    task.wait(10)  -- 10 segundos de monitoreo
    
    -- Verificar si algún jugador se fue
    local playersLeft = 0
    for name, _ in pairs(initialPlayers) do
        if not Players:FindFirstChild(name) then
            playersLeft += 1
            if CONFIG.DEBUG_MODE then
                print("⚠️ Jugador se fue:", name)
            end
        end
    end
    
    return playersLeft == 0  -- True si ningún jugador se fue
end

-- Función para escanear buscando específicamente al jugador con Tralalero Tralala
local function scanForPlayerWithTarget()
    -- Primero buscar jugadores que puedan tener el objetivo
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character or player.CharacterAdded:Wait()
            
            -- Buscar en el inventario del jugador
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                for _, item in ipairs(backpack:GetChildren()) do
                    if string.find(string.lower(item.Name), string.lower(CONFIG.TARGET_PATTERN)) then
                        return true, player.Name
                    end
                end
            end
            
            -- Buscar en el modelo del personaje
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if string.find(string.lower(part.Name), string.lower(CONFIG.TARGET_PATTERN)) then
                        return true, player.Name
                    end
                end
            end
        end
    end
    
    return false, nil
end

-- Modificación del huntingLoop
local function huntingLoop()
    print("\n=== INICIANDO MODO HUNTER MEJORADO ===")
    print(string.format("🔍 Buscando '%s' o 💰 %d/s en radio de %d studs", CONFIG.TARGET_PATTERN, CONFIG.TARGET_EARNINGS, CONFIG.SCAN_RADIUS))

    while _G.running do
        local servers = getActiveServers()
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores. Reintentando en 1 minuto...")
            task.wait(60)
        else
            if CONFIG.DEBUG_MODE then
                print(string.format("🔄 Obtenidos %d servidores activos", #servers))
            end

            for _, serverId in ipairs(servers) do
                if not _G.running then break end
          
                if CONFIG.DEBUG_MODE then
                    print("🛫 Intentando unirse a:", serverId)
                end

                if joinServer(serverId) then
                    -- Verificar estabilidad del servidor
                    local isStable = checkServerStability()
                    
                    -- Verificar específicamente al jugador con el objetivo
                    local targetFound, playerName = scanForPlayerWithTarget()
                    
                    if not isStable then
                        print("⚠️ Servidor inestable - jugadores salieron. Saltando...")
                        incrementServerCount()
                        task.wait(CONFIG.SERVER_HOP_DELAY)
                        continue
                    end
                    
                    if targetFound then
                        print(string.format("🎯 Jugador con objetivo detectado: %s", playerName))
                        -- Hacer scan profundo solo si el jugador con el objetivo sigue presente
                        local targets = deepScan()
                        sendHunterReport(targets, serverId)
                        
                        if #targets > 0 then
                            print("🎯 Objetivo encontrado! Finalizando búsqueda.")
                            onEntityFound()
                            _G.running = false
                            break
                        end
                    else
                        -- Scan normal si no se detectó jugador con el objetivo
                        local targets = deepScan()
                        sendHunterReport(targets, serverId)
                        
                        if #targets > 0 then
                            print("🎯 Objetivo encontrado! Finalizando búsqueda.")
                            onEntityFound()
                            _G.running = false
                            break
                        end
                    end
                    
                    incrementServerCount()
                end

                task.wait(CONFIG.SERVER_HOP_DELAY)
            end

            if _G.running and CONFIG.DEBUG_MODE then
                print("🔁 Reiniciando ciclo de búsqueda...")
            end

            if running then
                task.wait(30)
            end
        end
    end
end
