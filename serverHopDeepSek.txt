local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuración inicial
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

-- Variables de control
local serversVisited = 0
local specialsFound = 0
local isOpen = true
local espGodEnabled = false
local espSecretEnabled = false
_G.running = true

-- Crear la GUI principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HunterPremiumUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Marco principal (se puede mover)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Esquinas redondeadas
local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

-- Barra de título (también sirve para mover el panel)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BackgroundTransparency = 0.1
TitleBar.BorderSizePixel = 0
TitleBar.Active = true
TitleBar.Draggable = true
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 12)

-- Título "HUNTER PREMIUM"
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 100) -- Verde neón
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.Text = "HUNTER PREMIUM"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Botón para minimizar/maximizar
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 30, 0, 30)
ToggleButton.Position = UDim2.new(1, -35, 0.5, -15)
ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ToggleButton.Text = "-"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 18
ToggleButton.Parent = TitleBar

local ToggleCorner = Instance.new("UICorner", ToggleButton)
ToggleCorner.CornerRadius = UDim.new(0, 6)

-- Contenedor del contenido (se oculta al minimizar)
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0.5, 0, 0, 50)
ContentFrame.AnchorPoint = Vector2.new(0.5, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Información del servidor
local ServerInfo = Instance.new("TextLabel")
ServerInfo.Size = UDim2.new(1, 0, 0, 40)
ServerInfo.Position = UDim2.new(0, 0, 0, 0)
ServerInfo.BackgroundTransparency = 1
ServerInfo.TextColor3 = Color3.fromRGB(200, 200, 255)
ServerInfo.Font = Enum.Font.Gotham
ServerInfo.TextSize = 16
ServerInfo.Text = "Estado: Conectando..."
ServerInfo.TextXAlignment = Enum.TextXAlignment.Left
ServerInfo.Parent = ContentFrame

-- Contador de jugadores
local PlayersInfo = Instance.new("TextLabel")
PlayersInfo.Size = UDim2.new(1, 0, 0, 40)
PlayersInfo.Position = UDim2.new(0, 0, 0, 40)
PlayersInfo.BackgroundTransparency = 1
PlayersInfo.TextColor3 = Color3.fromRGB(200, 200, 255)
PlayersInfo.Font = Enum.Font.Gotham
PlayersInfo.TextSize = 16
PlayersInfo.Text = "Jugadores: 0/0 (Score: 0)"
PlayersInfo.TextXAlignment = Enum.TextXAlignment.Left
PlayersInfo.Parent = ContentFrame

-- Contenedor para los contadores
local CountersFrame = Instance.new("Frame")
CountersFrame.Size = UDim2.new(1, 0, 0, 80)
CountersFrame.Position = UDim2.new(0, 0, 0, 80)
CountersFrame.BackgroundTransparency = 1
CountersFrame.Parent = ContentFrame

-- Contador de servidores verificados
local ServersCounter = Instance.new("Frame")
ServersCounter.Size = UDim2.new(0.48, 0, 1, 0)
ServersCounter.Position = UDim2.new(0, 0, 0, 0)
ServersCounter.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ServersCounter.BackgroundTransparency = 0.2
ServersCounter.Parent = CountersFrame

local ServersCorner = Instance.new("UICorner", ServersCounter)
ServersCorner.CornerRadius = UDim.new(0, 8)

local ServersLabel = Instance.new("TextLabel")
ServersLabel.Size = UDim2.new(1, 0, 0.4, 0)
ServersLabel.Position = UDim2.new(0, 0, 0, 0)
ServersLabel.BackgroundTransparency = 1
ServersLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
ServersLabel.Font = Enum.Font.Gotham
ServersLabel.TextSize = 14
ServersLabel.Text = "Servidores Verificados"
ServersLabel.Parent = ServersCounter

local ServersValue = Instance.new("TextLabel")
ServersValue.Size = UDim2.new(1, 0, 0.6, 0)
ServersValue.Position = UDim2.new(0, 0, 0.4, 0)
ServersValue.BackgroundTransparency = 1
ServersValue.TextColor3 = Color3.fromRGB(0, 200, 255)
ServersValue.Font = Enum.Font.GothamBold
ServersValue.TextSize = 24
ServersValue.Text = "0"
ServersValue.Parent = ServersCounter

-- Contador de especiales encontrados
local SpecialsCounter = Instance.new("Frame")
SpecialsCounter.Size = UDim2.new(0.48, 0, 1, 0)
SpecialsCounter.Position = UDim2.new(0.52, 0, 0, 0)
SpecialsCounter.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
SpecialsCounter.BackgroundTransparency = 0.2
SpecialsCounter.Parent = CountersFrame

local SpecialsCorner = Instance.new("UICorner", SpecialsCounter)
SpecialsCorner.CornerRadius = UDim.new(0, 8)

local SpecialsLabel = Instance.new("TextLabel")
SpecialsLabel.Size = UDim2.new(1, 0, 0.4, 0)
SpecialsLabel.Position = UDim2.new(0, 0, 0, 0)
SpecialsLabel.BackgroundTransparency = 1
SpecialsLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
SpecialsLabel.Font = Enum.Font.Gotham
SpecialsLabel.TextSize = 14
SpecialsLabel.Text = "Especiales Encontrados"
SpecialsLabel.Parent = SpecialsCounter

local SpecialsValue = Instance.new("TextLabel")
SpecialsValue.Size = UDim2.new(1, 0, 0.6, 0)
SpecialsValue.Position = UDim2.new(0, 0, 0.4, 0)
SpecialsValue.BackgroundTransparency = 1
SpecialsValue.TextColor3 = Color3.fromRGB(255, 100, 100)
SpecialsValue.Font = Enum.Font.GothamBold
SpecialsValue.TextSize = 24
SpecialsValue.Text = "0"
SpecialsValue.Parent = SpecialsCounter

-- Barra de progreso
local ProgressBarFrame = Instance.new("Frame")
ProgressBarFrame.Size = UDim2.new(1, 0, 0, 20)
ProgressBarFrame.Position = UDim2.new(0, 0, 0, 170)
ProgressBarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ProgressBarFrame.BackgroundTransparency = 0.3
ProgressBarFrame.Parent = ContentFrame

local ProgressBarCorner = Instance.new("UICorner", ProgressBarFrame)
ProgressBarCorner.CornerRadius = UDim.new(0, 8)

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.Position = UDim2.new(0, 0, 0, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBarFrame

local ProgressBarInnerCorner = Instance.new("UICorner", ProgressBar)
ProgressBarInnerCorner.CornerRadius = UDim.new(0, 8)

local ProgressText = Instance.new("TextLabel")
ProgressText.Size = UDim2.new(1, 0, 1, 0)
ProgressText.Position = UDim2.new(0, 0, 0, 0)
ProgressText.BackgroundTransparency = 1
ProgressText.TextColor3 = Color3.new(1, 1, 1)
ProgressText.Font = Enum.Font.GothamBold
ProgressText.TextSize = 12
ProgressText.Text = "0%"
ProgressText.Parent = ProgressBarFrame

-- Botón de parada
local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(1, 0, 0, 50)
StopButton.Position = UDim2.new(0, 0, 0, 200)
StopButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
StopButton.TextColor3 = Color3.new(1, 1, 1)
StopButton.Font = Enum.Font.GothamBold
StopButton.TextSize = 18
StopButton.Text = "PARAR"
StopButton.Parent = ContentFrame

local StopButtonCorner = Instance.new("UICorner", StopButton)
StopButtonCorner.CornerRadius = UDim.new(0, 8)

-- Controles de búsqueda
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, 0, 0, 80)
SearchFrame.Position = UDim2.new(0, 0, 0, 260)
SearchFrame.BackgroundTransparency = 1
SearchFrame.Parent = ContentFrame

local SearchLabel = Instance.new("TextLabel")
SearchLabel.Size = UDim2.new(1, 0, 0, 20)
SearchLabel.Position = UDim2.new(0, 0, 0, 0)
SearchLabel.BackgroundTransparency = 1
SearchLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
SearchLabel.Font = Enum.Font.Gotham
SearchLabel.TextSize = 14
SearchLabel.Text = "Patrón de búsqueda:"
SearchLabel.TextXAlignment = Enum.TextXAlignment.Left
SearchLabel.Parent = SearchFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, 0, 0, 30)
SearchBox.Position = UDim2.new(0, 0, 0, 20)
SearchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
SearchBox.BackgroundTransparency = 0.3
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 14
SearchBox.Text = CONFIG.TARGET_PATTERN
SearchBox.PlaceholderText = "Ingrese patrón de búsqueda..."
SearchBox.Parent = SearchFrame

local SearchBoxCorner = Instance.new("UICorner", SearchBox)
SearchBoxCorner.CornerRadius = UDim.new(0, 6)

-- Botones de ESP
local ESPButtonsFrame = Instance.new("Frame")
ESPButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
ESPButtonsFrame.Position = UDim2.new(0, 0, 0, 350)
ESPButtonsFrame.BackgroundTransparency = 1
ESPButtonsFrame.Parent = ContentFrame

-- Botón ESP God
local ESPGodButton = Instance.new("TextButton")
ESPGodButton.Size = UDim2.new(0.48, 0, 1, 0)
ESPGodButton.Position = UDim2.new(0, 0, 0, 0)
ESPGodButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ESPGodButton.TextColor3 = Color3.new(1, 1, 1)
ESPGodButton.Font = Enum.Font.GothamBold
ESPGodButton.TextSize = 14
ESPGodButton.Text = "ESP God [DESACTIVADO]"
ESPGodButton.Parent = ESPButtonsFrame

local ESPGodCorner = Instance.new("UICorner", ESPGodButton)
ESPGodCorner.CornerRadius = UDim.new(0, 6)

-- Botón ESP Secret
local ESPSecretButton = Instance.new("TextButton")
ESPSecretButton.Size = UDim2.new(0.48, 0, 1, 0)
ESPSecretButton.Position = UDim2.new(0.52, 0, 0, 0)
ESPSecretButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ESPSecretButton.TextColor3 = Color3.new(1, 1, 1)
ESPSecretButton.Font = Enum.Font.GothamBold
ESPSecretButton.TextSize = 14
ESPSecretButton.Text = "ESP Secret [DESACTIVADO]"
ESPSecretButton.Parent = ESPButtonsFrame

local ESPSecretCorner = Instance.new("UICorner", ESPSecretButton)
ESPSecretCorner.CornerRadius = UDim.new(0, 6)

-- Función para actualizar la UI
local function updateUI()
    ServersValue.Text = tostring(serversVisited)
    SpecialsValue.Text = tostring(specialsFound)
    
    -- Actualizar estado de los botones ESP
    ESPGodButton.Text = "ESP God ["..(espGodEnabled and "ACTIVADO" or "DESACTIVADO").."]"
    ESPGodButton.BackgroundColor3 = espGodEnabled and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 80)
    
    ESPSecretButton.Text = "ESP Secret ["..(espSecretEnabled and "ACTIVADO" or "DESACTIVADO").."]"
    ESPSecretButton.BackgroundColor3 = espSecretEnabled and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 80)
end

-- Función para actualizar la barra de progreso
local function updateProgress(percent)
    ProgressBar:TweenSize(
        UDim2.new(percent / 100, 0, 1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
    ProgressText.Text = math.floor(percent).."%"
end

-- Función para minimizar/maximizar
local function toggleUI()
    isOpen = not isOpen
    if isOpen then
        MainFrame.Size = UDim2.new(0, 350, 0, 400)
        ToggleButton.Text = "-"
        ContentFrame.Visible = true
    else
        MainFrame.Size = UDim2.new(0, 350, 0, 40)
        ToggleButton.Text = "+"
        ContentFrame.Visible = false
    end
end

-- Eventos de los botones
ToggleButton.MouseButton1Click:Connect(toggleUI)
StopButton.MouseButton1Click:Connect(function()
    _G.running = false
    ServerInfo.Text = "Estado: Detenido"
    ServerInfo.TextColor3 = Color3.fromRGB(255, 60, 60)
end)

ESPGodButton.MouseButton1Click:Connect(function()
    espGodEnabled = not espGodEnabled
    updateUI()
    -- Aquí iría la lógica para activar/desactivar el ESP God
end)

ESPSecretButton.MouseButton1Click:Connect(function()
    espSecretEnabled = not espSecretEnabled
    updateUI()
    -- Aquí iría la lógica para activar/desactivar el ESP Secret
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        CONFIG.TARGET_PATTERN = SearchBox.Text
    end
end)

-- Función para actualizar la información del servidor
local function updateServerInfo(serverNum, totalServers, playerCount, maxPlayers, score)
    ServerInfo.Text = string.format("Estado: Servidor %d/%d", serverNum, totalServers)
    PlayersInfo.Text = string.format("Jugadores: %d/%d (Score: %d)", playerCount, maxPlayers, score)
end

-- Función para cuando se encuentra un objetivo especial
local function onSpecialFound()
    specialsFound += 1
    updateUI()
    -- Aquí podrías añadir efectos visuales/sonoros
end

-- Inicializar la UI
updateUI()
updateProgress(0)

