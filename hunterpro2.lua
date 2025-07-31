local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "Tralalero Tralala",
    TARGET_EARNINGS = 999999999,
    WEBHOOK_URL = "",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 5,
    MAX_SERVERS = 25,
    DEBUG_MODE = true
}

-- Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variables de control
local serversVisited = 0
_G.running = true

-- GUI (opcional, puedes comentarla si no la necesitas)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FloatingHunterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local DragFrame = Instance.new("Frame")
DragFrame.Size = UDim2.new(0, 200, 0, 60)
DragFrame.Position = UDim2.new(0.65, 0, 0.05, 0)
DragFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DragFrame.BackgroundTransparency = 0.2
DragFrame.BorderSizePixel = 0
DragFrame.Active = true
DragFrame.Draggable = true
DragFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", DragFrame)
UICorner.CornerRadius = UDim.new(0, 8)

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 0.5, 0)
TextLabel.Position = UDim2.new(0, 0, 0, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.TextScaled = true
TextLabel.Text = "Servidores: 0"
TextLabel.Parent = DragFrame

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

local BellSound = Instance.new("Sound")
BellSound.SoundId = "rbxassetid://911342077"
BellSound.Volume = 1
BellSound.Parent = DragFrame

-- Función para actualizar UI
local function updateUI(message, color)
    if TextLabel then
        TextLabel.Text = message
        TextLabel.TextColor3 = color or Color3.fromRGB(0, 255, 0)
    end
end

-- Parpadeo visual cuando encuentra entidad
local function flashMessage()
    task.spawn(function()
        for i = 1, 6 do
            if TextLabel then
                TextLabel.Visible = not TextLabel.Visible
            end
            task.wait(0.25)
        end
        if TextLabel then
            TextLabel.Visible = true
        end
    end)
end

-- Función cuando encuentra entidad
function onEntityFound()
    updateUI("¡Entidad en el servidor!", Color3.fromRGB(255, 0, 0))
    if BellSound then
        BellSound:Play()
    end
    flashMessage()
end

-- Evento del botón para detener script
if StopButton then
    StopButton.MouseButton1Click:Connect(function()
        _G.running = false
        updateUI("🔴 Búsqueda detenida", Color3.fromRGB(255, 60, 60))
    end)
end

-- Función para aumentar contador
function incrementServerCount()
    serversVisited += 1
    updateUI("Servidores: " .. serversVisited)
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
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.id then
                    table.insert(servers, server.id)
                end
            end
        end
    else
        warn("Error al obtener servidores: ", response)
    end

    return servers
end

-- Función para escanear la base del jugador
local function scanPlayerBase(player)
    if not player or not player.Name then return false end
    
    -- Posibles ubicaciones de bases
    local searchLocations = {
        Workspace,
        Workspace:FindFirstChild("PlayerBases") or Workspace,
        Workspace:FindFirstChild("Bases") or Workspace,
        Workspace:FindFirstChild("Structures") or Workspace
    }
    
    for _, location in ipairs(searchLocations) do
        if location then
            for _, obj in ipairs(location:GetChildren()) do
                if obj and obj:IsA("Model") and obj.Name then
                    -- Verificar si pertenece al jugador
                    if string.find(obj.Name:lower(), player.Name:lower()) or 
                       (obj:GetAttribute("Owner") and tostring(obj:GetAttribute("Owner")) == player.Name) then
                        -- Buscar el objetivo en esta base
                        for _, descendant in ipairs(obj:GetDescendants()) do
                            if descendant and descendant.Name then
                                -- Por nombre
                                if string.find(descendant.Name:lower(), CONFIG.TARGET_PATTERN:lower()) then
                                    return true, player.Name, descendant:GetFullName()
                                end
                                
                                -- Por texto en carteles
                                if (descendant:IsA("TextLabel") or descendant:IsA("TextButton")) and descendant.Text then
                                    if string.find(descendant.Text:lower(), CONFIG.TARGET_PATTERN:lower()) then
                                        return true, player.Name, descendant:GetFullName()
                                    end
                                end
                                
                                -- Por valor de earnings
                                if descendant:IsA("NumberValue") and descendant.Name and string.find(descendant.Name:lower(), "earnings") then
                                    if descendant.Value == CONFIG.TARGET_EARNINGS then
                                        return true, player.Name, descendant:GetFullName()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- Función para buscar jugadores con el objetivo en su base
local function scanForPlayerWithTarget()
    local players = Players:GetPlayers()
    for _, player in ipairs(players) do
        if player and player ~= LocalPlayer then
            local found, playerName, objectPath = scanPlayerBase(player)
            if found then
                return true, playerName, objectPath
            end
        end
    end
    return false, nil, nil
end

-- Escaneo profundo del área
local function deepScan()
    local foundTargets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local rootPosition = rootPart and rootPart.Position or Vector3.new(0,0,0)

    local function scanRecursive(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child and child.Name then
                local match = false
                local earningsDetected = nil

                -- Coincidencia por nombre
                if string.find(child.Name:lower(), CONFIG.TARGET_PATTERN:lower()) then
                    match = true
                end

                -- Coincidencia por NumberValue
                for _, v in ipairs(child:GetChildren()) do
                    if v and v:IsA("NumberValue") and v.Name and string.find(v.Name:lower(), "earnings") then
                        if v.Value == CONFIG.TARGET_EARNINGS then
                            match = true
                            earningsDetected = v.Value
                        end
                    end
                end

                -- Coincidencia por TextLabel
                for _, gui in ipairs(child:GetDescendants()) do
                    if gui and gui:IsA("TextLabel") and gui.Text then
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
                    local success, pivot = pcall(function() 
                        return child:GetPivot() 
                    end)
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
    end

    -- Áreas prioritarias para escanear
    local priorityAreas = {
        Workspace,
        Workspace:FindFirstChild("Map") or Workspace,
        Workspace:FindFirstChild("GameObjects") or Workspace,
        Workspace:FindFirstChild("Workspace") or Workspace
    }

    for _, area in ipairs(priorityAreas) do
        if area then
            scanRecursive(area)
        end
    end

    table.sort(foundTargets, function(a, b) 
        return a.distance < b.distance 
    end)

    return foundTargets
end

-- Enviar reporte
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

-- Unirse a servidor con estabilización
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
            
            -- Espera inicial para estabilización
            local waitTime = 0
            while waitTime < 5 do
                waitTime += 1
                task.wait(1)
            end

            -- Verificar personaje
            if not LocalPlayer.Character then
                LocalPlayer.CharacterAdded:Wait()
                task.wait(2)
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

-- Verificar estabilidad del servidor
local function checkServerStability()
    -- Obtener lista inicial de jugadores
    local initialPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player and player.Name then
            initialPlayers[player.Name] = true
        end
    end
    
    -- Esperar periodo de observación
    task.wait(10)
    
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
    
    return playersLeft == 0
end

-- Loop principal de búsqueda
local function huntingLoop()
    print("\n=== INICIANDO MODO HUNTER MEJORADO ===")
    print(string.format("🔍 Buscando '%s' o 💰 %d/s en radio de %d studs", CONFIG.TARGET_PATTERN, CONFIG.TARGET_EARNINGS, CONFIG.SCAN_RADIUS))

    while _G.running do
        local servers = getActiveServers()
        if not servers or #servers == 0 then
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
                    -- Verificar estabilidad
                    local isStable = checkServerStability()
                    
                    -- Verificar jugador con objetivo en su base
                    local targetFound, playerName, objectPath = scanForPlayerWithTarget()
                    
                    if not isStable then
                        print("⚠️ Servidor inestable - jugadores salieron. Saltando...")
                        incrementServerCount()
                        task.wait(CONFIG.SERVER_HOP_DELAY)
                        goto continue
                    end
                    
                    if targetFound then
                        print(string.format("🎯 Jugador con objetivo detectado: %s (Objeto: %s)", playerName, objectPath))
                        -- Verificar nuevamente
                        local _, stillPresent, stillPresentPath = scanForPlayerWithTarget()
                        if stillPresent == playerName then
                            local targets = deepScan()
                            sendHunterReport(targets, serverId)
                            
                            if #targets > 0 then
                                print("🎯 Objetivo encontrado! Finalizando búsqueda.")
                                onEntityFound()
                                _G.running = false
                                break
                            end
                        else
                            print("⚠️ El objetivo ya no está presente")
                        end
                    else
                        -- Escaneo normal si no se detectó jugador con el objetivo
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

                ::continue::
                task.wait(CONFIG.SERVER_HOP_DELAY)
            end

            if _G.running and CONFIG.DEBUG_MODE then
                print("🔁 Reiniciando ciclo de búsqueda...")
            end

            task.wait(30)
        end
    end
end

-- Iniciar script
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

huntingLoop()
