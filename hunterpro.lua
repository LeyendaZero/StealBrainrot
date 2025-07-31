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

local universeId = 7709344486

-- Obtener servidores activos
-- (El resto del código anterior permanece igual hasta getActiveServers)

-- Obtener servidores activos (versión corregida)
local function getActiveServers()
    local servers = {}
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?limit=%d",
        universeId,  -- Usar universeId en lugar de CONFIG.GAME_ID directamente
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

-- (El resto del código permanece igual hasta huntingLoop)

-- Versión mejorada de huntingLoop con lógica de continue corregida
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
                        goto continue  -- Usamos goto en lugar de continue
                    end
                    
                    if targetFound then
                        print(string.format("🎯 Jugador con objetivo detectado: %s", playerName))
                        -- Verificar nuevamente que el jugador sigue presente
                        local _, stillPresent = scanForPlayerWithTarget()
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
                            print("⚠️ El jugador con el objetivo ya no está presente")
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

                ::continue::  -- Etiqueta para el goto
                task.wait(CONFIG.SERVER_HOP_DELAY)
            end

            if _G.running and CONFIG.DEBUG_MODE then
                print("🔁 Reiniciando ciclo de búsqueda...")
            end

            task.wait(30)
        end
    end
end
