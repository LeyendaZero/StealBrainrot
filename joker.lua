
-- ConfiguraciÃ³n mejorada con sistema de persistencia
local ConfigManager = {
    Defaults = {
        GAME_ID = 109983668079237,
        TARGET_PATTERN = "Tralalero Tralala",
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
    },
    Current = {},
    SaveName = "HunterProConfig"
}

function ConfigManager:Load()
    if isfile and isfile(self.SaveName .. ".json") then
        local success, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(self.SaveName .. ".json"))
        end)
        if success then
            self.Current = data
            return
        end
    end
    
    self.Current = table.clone(self.Defaults)
end

function ConfigManager:Save()
    if writefile then
        writefile(self.SaveName .. ".json", game:GetService("HttpService"):JSONEncode(self.Current))
    end
end

function ConfigManager:Get(key)
    return self.Current[key] or self.Defaults[key]
end

function ConfigManager:Set(key, value)
    self.Current[key] = value
    self:Save()
end

-- Inicializar configuraciÃ³n
ConfigManager:Load()
local CONFIG = ConfigManager

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
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Logger mejorado
local Logger = {
    Logs = {},
    MaxLogs = 100
}

function Logger:Add(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] %s: %s", timestamp, level, message)
    
    table.insert(self.Logs, 1, logEntry)
    if #self.Logs > self.MaxLogs then
        table.remove(self.Logs)
    end
    
    if CONFIG:Get("DEBUG_MODE") or level == "ERROR" then
        print(logEntry)
    end
end

function Logger:GetRecent(count)
    count = math.min(count or 10, #self.Logs)
    local result = {}
    for i = 1, count do
        table.insert(result, self.Logs[i])
    end
    return result
end

-- Variables UI mejoradas
local UI = {
    Enabled = true,
    MainWindow = nil,
    Tabs = {},
    Status = {
        Scanning = false,
        TargetsFound = 0,
        ServersScanned = 0,
        CurrentAction = "Iniciando...",
        startTime = os.time()
    },
    Notifications = {}
}

-- Variables de estado mejoradas
local HunterState = {
    Active = false,
    Paused = false,
    LastScan = 0,
    LastServerHop = 0,
    Targets = {},
    CurrentServer = nil
}

-- Sistema de notificaciones
local NotificationManager = {
    ActiveNotifications = {},
    MaxNotifications = 3
}

function NotificationManager:Show(title, message, duration, color)
    duration = duration or 5
    color = color or Color3.fromRGB(70, 70, 200)
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0.9, 0, 0, 0)
    notification.Position = UDim2.new(0.05, 0, 0.05 + (#self.ActiveNotifications * 0.15), 0)
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notification.BorderSizePixel = 0
    notification.ClipsDescendants = true
    notification.ZIndex = 100
    
    local corner = Instance.new("UICorner", notification)
    corner.CornerRadius = UDim.new(0.05, 0)
    
    local titleLabel = Instance.new("TextLabel", notification)
    titleLabel.Size = UDim2.new(1, -10, 0.3, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 101
    
    local messageLabel = Instance.new("TextLabel", notification)
    messageLabel.Size = UDim2.new(1, -10, 0.7, 0)
    messageLabel.Position = UDim2.new(0, 5, 0.3, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.ZIndex = 101
    
    -- AnimaciÃ³n de entrada
    notification.Parent = CoreGui
    local tweenIn = TweenService:Create(
        notification,
        TweenInfo.new(0.3),
        {Size = UDim2.new(0.9, 0, 0.15, 0)}
    )
    tweenIn:Play()
    
    -- Mantener referencia
    table.insert(self.ActiveNotifications, notification)
    
    -- Eliminar despuÃ©s de la duraciÃ³n
    task.delay(duration, function()
        self:Remove(notification)
    end)
end

function NotificationManager:Remove(notification)
    -- AnimaciÃ³n de salida
    local tweenOut = TweenService:Create(
        notification,
        TweenInfo.new(0.3),
        {Size = UDim2.new(0.9, 0, 0, 0)}
    )
    tweenOut:Play()
    
    task.wait(0.3)
    if notification then
        notification:Destroy()
    end
    
    -- Reorganizar notificaciones restantes
    for i, notif in ipairs(self.ActiveNotifications) do
        if notif == notification then
            table.remove(self.ActiveNotifications, i)
            break
        end
    end
    
    for i, notif in ipairs(self.ActiveNotifications) do
        TweenService:Create(
            notif,
            TweenInfo.new(0.2),
            {Position = UDim2.new(0.05, 0, 0.05 + ((i-1) * 0.15), 0)}
        ):Play()
    end
end

-- Bola flotante mejorada
local floatingBall = Instance.new("TextButton")
floatingBall.Name = "HunterFloatingBall"
floatingBall.Size = UDim2.new(0, 60, 0, 60)
floatingBall.Position = UDim2.new(0.85, 0, 0.85, 0)
floatingBall.AnchorPoint = Vector2.new(0.5, 0.5)
floatingBall.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
floatingBall.Text = "â˜„ï¸"
floatingBall.TextSize = 28
floatingBall.ZIndex = 50
floatingBall.BorderSizePixel = 0
floatingBall.AutoButtonColor = false

local ballCorner = Instance.new("UICorner", floatingBall)
ballCorner.CornerRadius = UDim.new(1, 0)

local ballShadow = Instance.new("ImageLabel", floatingBall)
ballShadow.Name = "Shadow"
ballShadow.Size = UDim2.new(1, 12, 1, 12)
ballShadow.Position = UDim2.new(0, -6, 0, -6)
ballShadow.BackgroundTransparency = 1
ballShadow.Image = "rbxassetid://1316045217"
ballShadow.ImageColor3 = Color3.new(0, 0, 0)
ballShadow.ImageTransparency = 0.8
ballShadow.ScaleType = Enum.ScaleType.Slice
ballShadow.SliceCenter = Rect.new(10, 10, 118, 118)
ballShadow.ZIndex = 49

local ballHover = Instance.new("Frame", floatingBall)
ballHover.Size = UDim2.new(1, 0, 1, 0)
ballHover.BackgroundColor3 = Color3.new(1, 1, 1)
ballHover.BackgroundTransparency = 0.9
ballHover.Visible = false
ballHover.ZIndex = 51

floatingBall.MouseEnter:Connect(function()
    ballHover.Visible = true
    TweenService:Create(
        floatingBall, 
        TweenInfo.new(0.1), 
        {Size = UDim2.new(0, 65, 0, 65)}
    ):Play()
end)

floatingBall.MouseLeave:Connect(function()
    ballHover.Visible = false
    TweenService:Create(
        floatingBall, 
        TweenInfo.new(0.1), 
        {Size = UDim2.new(0, 60, 0, 60)}
    ):Play()
end)

-- FunciÃ³n para crear la interfaz mÃ³vil mejorada
local function createMobileUI()
    if not UI.Enabled then return end
    
    -- Limpiar UI existente
    if UI.MainWindow and UI.MainWindow.Parent then
        UI.MainWindow:Destroy()
    end

    -- Crear la ventana principal
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "AltHunterMobileUI"
    MainWindow.Size = UDim2.new(0.85, 0, 0.75, 0)
    MainWindow.Position = UDim2.new(0.075, 0, 0.125, 0)
    MainWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    MainWindow.BorderSizePixel = 0
    MainWindow.Visible = false
    MainWindow.ZIndex = 40

    local Corner = Instance.new("UICorner", MainWindow)
    Corner.CornerRadius = UDim.new(0.05, 0)

    local TitleBar = Instance.new("Frame", MainWindow)
    TitleBar.Size = UDim2.new(1, 0, 0.08, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.ZIndex = 41

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(0.8, 0, 1, 0)
    Title.Position = UDim2.new(0.1, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "HUNTER PRO"
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    Title.ZIndex = 42

    local CloseButton = Instance.new("TextButton", TitleBar)
    CloseButton.Size = UDim2.new(0.15, 0, 1, 0)
    CloseButton.Position = UDim2.new(0.85, 0, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "âœ•"
    CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    CloseButton.TextScaled = true
    CloseButton.ZIndex = 42
    CloseButton.AutoButtonColor = false

    -- Tabs Container
    local TabsContainer = Instance.new("Frame", MainWindow)
    TabsContainer.Size = UDim2.new(1, 0, 0.1, 0)
    TabsContainer.Position = UDim2.new(0, 0, 0.08, 0)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.ZIndex = 41

    -- Content Container
    local ContentContainer = Instance.new("Frame", MainWindow)
    ContentContainer.Size = UDim2.new(1, -10, 0.8, -10)
    ContentContainer.Position = UDim2.new(0, 5, 0.18, 5)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true
    ContentContainer.ZIndex = 41

    -- Status Bar
    local StatusBar = Instance.new("Frame", MainWindow)
    StatusBar.Size = UDim2.new(1, -10, 0.08, 0)
    StatusBar.Position = UDim2.new(0, 5, 0.9, 0)
    StatusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    StatusBar.ZIndex = 41
    
    local StatusLabel = Instance.new("TextLabel", StatusBar)
    StatusLabel.Size = UDim2.new(1, -10, 1, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Estado: Iniciando..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.TextScaled = true
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.ZIndex = 42
    UI.StatusLabel = StatusLabel

    -- FunciÃ³n para crear pestaÃ±as mÃ³viles mejoradas
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
        TabButton.ZIndex = 42
        TabButton.AutoButtonColor = false

        local TabContent = Instance.new("ScrollingFrame", ContentContainer)
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.Position = UDim2.new(#UI.Tabs, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = #UI.Tabs == 0
        TabContent.ScrollBarThickness = 4
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.ZIndex = 41
        TabContent.ScrollingDirection = Enum.ScrollingDirection.Y

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

    -- FunciÃ³n para crear botones mejorados
    local function createActionButton(parent, text, position, color, clickFunc)
        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(1, -10, 0.2, 0)
        button.Position = position
        button.BackgroundColor3 = color
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false
        button.ZIndex = 42
        
        local corner = Instance.new("UICorner", button)
        corner.CornerRadius = UDim.new(0.1, 0)
        
        local hover = Instance.new("Frame", button)
        hover.Size = UDim2.new(1, 0, 1, 0)
        hover.BackgroundColor3 = Color3.new(1, 1, 1)
        hover.BackgroundTransparency = 0.9
        hover.Visible = false
        hover.ZIndex = 43
        
        button.MouseEnter:Connect(function()
            hover.Visible = true
            TweenService:Create(
                button, 
                TweenInfo.new(0.1), 
                {BackgroundTransparency = 0.1}
            ):Play()
        end)
        
        button.MouseLeave:Connect(function()
            hover.Visible = false
            TweenService:Create(
                button, 
                TweenInfo.new(0.1), 
                {BackgroundTransparency = 0}
            ):Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            TweenService:Create(
                button, 
                TweenInfo.new(0.1), 
                {BackgroundTransparency = 0.3}
            ):Play()
            task.wait(0.1)
            TweenService:Create(
                button, 
                TweenInfo.new(0.1), 
                {BackgroundTransparency = 0}
            ):Play()
            clickFunc()
        end)
        
        return button
    end

    -- PestaÃ±a de Control mÃ³vil mejorada
    createMobileTab("Control", function(container)
        local StartButton = createActionButton(
            container,
            HunterState.Active and "DETENER" or "INICIAR",
            UDim2.new(0, 5, 0, 5),
            HunterState.Active and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(60, 120, 60),
            function()
                HunterState.Active = not HunterState.Active
                StartButton.Text = HunterState.Active and "DETENER" or "INICIAR"
                StartButton.BackgroundColor3 = HunterState.Active and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(60, 120, 60)
                if HunterState.Active then
                    NotificationManager:Show("Hunter Pro", "BÃºsqueda iniciada", 3, Color3.fromRGB(0, 200, 100))
                    coroutine.wrap(huntingLoop)()
                else
                    NotificationManager:Show("Hunter Pro", "BÃºsqueda detenida", 3, Color3.fromRGB(200, 60, 60))
                end
            end
        )

        local PauseButton = createActionButton(
            container,
            HunterState.Paused and "REANUDAR" or "PAUSAR",
            UDim2.new(0, 5, 0.25, 0),
            HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120),
            function()
                HunterState.Paused = not HunterState.Paused
                PauseButton.Text = HunterState.Paused and "REANUDAR" or "PAUSAR"
                PauseButton.BackgroundColor3 = HunterState.Paused and Color3.fromRGB(120, 120, 60) or Color3.fromRGB(60, 60, 120)
                NotificationManager:Show("Hunter Pro", HunterState.Paused and "BÃºsqueda pausada" or "BÃºsqueda reanudada", 2)
            end
        )

        -- ConfiguraciÃ³n mÃ³vil mejorada
        local configEntries = {
            {name = "PatrÃ³n:", key = "TARGET_PATTERN", type = "string", pos = 0.5},
            {name = "Ganancias:", key = "TARGET_EARNINGS", type = "number", pos = 0.6},
            {name = "Radio:", key = "SCAN_RADIUS", type = "number", pos = 0.7},
            {name = "Delay:", key = "SERVER_HOP_DELAY", type = "number", pos = 0.8},
            {name = "Max Servers:", key = "MAX_SERVERS", type = "number", pos = 0.9}
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
            label.ZIndex = 42

            if entry.type == "string" or entry.type == "number" then
                local textBox = Instance.new("TextBox", container)
                textBox.Size = UDim2.new(0.6, -5, 0.1, 0)
                textBox.Position = UDim2.new(0.4, 5, entry.pos, 0)
                textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                textBox.BorderSizePixel = 0
                textBox.Text = tostring(CONFIG:Get(entry.key))
                textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
                textBox.TextScaled = true
                textBox.Font = Enum.Font.Gotham
                textBox.ZIndex = 42
                textBox.ClearTextOnFocus = false

                textBox.FocusLost:Connect(function()
                    if entry.type == "number" then
                        local num = tonumber(textBox.Text)
                        if num then
                            CONFIG:Set(entry.key, num)
                            textBox.Text = tostring(num)
                        else
                            textBox.Text = tostring(CONFIG:Get(entry.key))
                        end
                    else
                        CONFIG:Set(entry.key, textBox.Text)
                    end
                    NotificationManager:Show("ConfiguraciÃ³n", entry.name .. " actualizado", 2)
                end)
            end
        end
    end)

    -- PestaÃ±a de Resultados mÃ³vil mejorada
    createMobileTab("Resultados", function(container)
        local TargetList = Instance.new("Frame", container)
        TargetList.Size = UDim2.new(1, 0, 1, 0)
        TargetList.BackgroundTransparency = 1
        TargetList.ZIndex = 41

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
                noTargets.ZIndex = 42
                return
            end

            for i, target in ipairs(HunterState.Targets) do
                if i > CONFIG:Get("MAX_TARGETS") then break end
                
                local targetFrame = Instance.new("Frame", TargetList)
                targetFrame.Size = UDim2.new(1, -10, 0.3, 0)
                targetFrame.Position = UDim2.new(0, 5, (i-1) * 0.32, 0)
                targetFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                targetFrame.ZIndex = 41
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
                nameLabel.ZIndex = 42

                local distanceLabel = Instance.new("TextLabel", targetFrame)
                distanceLabel.Size = UDim2.new(0.5, -5, 0.3, 0)
                distanceLabel.Position = UDim2.new(0, 5, 0.4, 0)
                distanceLabel.BackgroundTransparency = 1
                distanceLabel.Text = "Dist: " .. math.floor(target.distance) .. " studs"
                distanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
                distanceLabel.TextScaled = true
                distanceLabel.Font = Enum.Font.Gotham
                distanceLabel.ZIndex = 42

                local teleportButton = createActionButton(
                    targetFrame,
                    "TELEPORT",
                    UDim2.new(0.5, 5, 0.4, 0),
                    Color3.fromRGB(70, 70, 100),
                    function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(target.position)
                            NotificationManager:Show("Teleport", "Teletransportado a objetivo", 2)
                        else
                            NotificationManager:Show("Error", "No se puede teleportar", 2, Color3.fromRGB(200, 60, 60))
                        end
                    end
                )
                teleportButton.Size = UDim2.new(0.5, -5, 0.3, 0)
            end
        end

        updateTargetList()
        UI.UpdateTargetList = updateTargetList
    end)

    -- PestaÃ±a de EstadÃ­sticas mÃ³vil mejorada
    createMobileTab("EstadÃ­sticas", function(container)
        local StatsFrame = Instance.new("Frame", container)
        StatsFrame.Size = UDim2.new(1, 0, 1, 0)
        StatsFrame.BackgroundTransparency = 1
        StatsFrame.ZIndex = 41

        local function updateStats()
            StatsFrame:ClearAllChildren()
            
            local stats = {
                {"Servidores:", UI.Status.ServersScanned},
                {"Objetivos:", UI.Status.TargetsFound},
                {"Estado:", HunterState.Active and (HunterState.Paused and "PAUSADO" or "ACTIVO") or "INACTIVO"},
                {"Radio:", CONFIG:Get("SCAN_RADIUS") .. " studs"},
                {"Tiempo:", string.format("%.1f min", (os.time() - UI.Status.startTime) / 60)}
            }

            for i, stat in ipairs(stats) do
                local label = Instance.new("TextLabel", StatsFrame)
                label.Size = UDim2.new(0.5, -5, 0.15, 0)
                label.Position = UDim2.new(0, 5, (i-1) * 0.15, 0)
                label.BackgroundTransparency = 1
                label.Text = stat[1]
                label.TextColor3 = Color3.fromRGB(180, 180, 180)
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextScaled = true
                label.Font = Enum.Font.Gotham
                label.ZIndex = 42

                local value = Instance.new("TextLabel", StatsFrame)
                value.Size = UDim2.new(0.5, -5, 0.15, 0)
                value.Position = UDim2.new(0.5, 5, (i-1) * 0.15, 0)
                value.BackgroundTransparency = 1
                value.Text = tostring(stat[2])
                value.TextColor3 = Color3.fromRGB(220, 220, 220)
                value.TextXAlignment = Enum.TextXAlignment.Right
                value.TextScaled = true
                value.Font = Enum.Font.GothamMedium
                value.ZIndex = 42
            end
        end

        updateStats()
        UI.UpdateStats = updateStats
    end)

    -- PestaÃ±a de Registros mejorada
    createMobileTab("Registros", function(container)
        local LogsFrame = Instance.new("ScrollingFrame", container)
        LogsFrame.Size = UDim2.new(1, 0, 1, 0)
        LogsFrame.BackgroundTransparency = 1
        LogsFrame.ScrollBarThickness = 4
        LogsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LogsFrame.ZIndex = 41

        local function updateLogs()
            LogsFrame:ClearAllChildren()
            
            local logs = Logger:GetRecent(20)
            
            if #logs == 0 then
                local noLogs = Instance.new("TextLabel", LogsFrame)
                noLogs.Size = UDim2.new(1, -10, 0.2, 0)
                noLogs.Position = UDim2.new(0, 5, 0.4, 0)
                noLogs.BackgroundTransparency = 1
                noLogs.Text = "No hay registros disponibles"
                noLogs.TextColor3 = Color3.fromRGB(150, 150, 150)
                noLogs.TextScaled = true
                noLogs.Font = Enum.Font.Gotham
                noLogs.ZIndex = 42
                return
            end

            for i, log in ipairs(logs) do
                local logLabel = Instance.new("TextLabel", LogsFrame)
                logLabel.Size = UDim2.new(1, -10, 0, 30)
                logLabel.Position = UDim2.new(0, 5, 0, (i-1) * 35)
                logLabel.BackgroundTransparency = 1
                logLabel.Text = log
                logLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                logLabel.TextXAlignment = Enum.TextXAlignment.Left
                logLabel.TextScaled = false
                logLabel.TextWrapped = true
                logLabel.Font = Enum.Font.Gotham
                logLabel.ZIndex = 42
            end
        end

        local refreshButton = createActionButton(
            container,
            "ACTUALIZAR",
            UDim2.new(0.25, 5, 0.85, 0),
            Color3.fromRGB(70, 70, 100),
            updateLogs
        )
        refreshButton.Size = UDim2.new(0.5, -10, 0.1, 0)

        updateLogs()
        UI.UpdateLogs = updateLogs
    end)

    -- Configurar eventos de la bola flotante
    floatingBall.MouseButton1Click:Connect(function()
        MainWindow.Visible = not MainWindow.Visible
        floatingBall.Text = MainWindow.Visible and "âœ•" or "â˜„ï¸"
    end)

    CloseButton.MouseButton1Click:Connect(function()
        MainWindow.Visible = false
        floatingBall.Text = "â˜„ï¸"
    end)

    -- AÃ±adir al CoreGui
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "HunterMobileUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    floatingBall.Parent = ScreenGui
    MainWindow.Parent = ScreenGui
    UI.MainWindow = MainWindow
end

-- FunciÃ³n para actualizar la UI mejorada
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
    
    if UI.UpdateLogs then
        UI.UpdateLogs()
    end
end

-- Obtener universeId mejorado
local function getUniverseIdFromPlaceId(placeId)
    local url = string.format("https://games.roblox.com/v1/games/multiget-place-details?placeIds=[%d]", placeId)
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success then
        local success2, data = pcall(HttpService.JSONDecode, HttpService, response)
        if success2 and data and data[1] and data[1].universeId then
            return tostring(data[1].universeId)
        end
    end
    
    Logger:Add("No se pudo obtener universeId para el placeId "..tostring(placeId), "WARNING")
    return nil
end

local universeId = getUniverseIdFromPlaceId(CONFIG:Get("GAME_ID")) or tostring(CONFIG:Get("GAME_ID"))

-- Obtener servidores activos mejorado
local function getActiveServers()
    local servers = {}
    local cursor = ""
    local serversToGet = math.min(CONFIG:Get("MAX_SERVERS"), 100)
    
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=%d",
        universeId,
        serversToGet
    )
    
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if success then
        local success2, data = pcall(HttpService.JSONDecode, HttpService, response)
        if success2 and data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing and server.playing >= CONFIG:Get("MIN_PLAYERS") and server.playing <= CONFIG:Get("MAX_PLAYERS") then
                    table.insert(servers, server.id)
                    if #servers >= CONFIG:Get("MAX_SERVERS") then
                        break
                    end
                end
            end
        else
            Logger:Add("Error al decodificar respuesta de servidores: "..tostring(response), "ERROR")
        end
    else
        Logger:Add("Error al obtener servidores: "..tostring(response), "ERROR")
    end

    Logger:Add(string.format("Obtenidos %d servidores activos", #servers))
    return servers
end

-- Escaneo optimizado con chequeo por earnings
local function optimizedScan()
    local foundTargets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
      Logger:Add("No se encontrÃ³ HumanoidRootPart para escanear", "WARNING")
        return foundTargets
    end

    local scanRadius = CONFIG:Get("SCAN_RADIUS")
    local targetPattern = CONFIG:Get("TARGET_PATTERN"):lower()
    local targetEarnings = CONFIG:Get("TARGET_EARNINGS")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local distance = (rootPart.Position - humanoidRootPart.Position).Magnitude
                if distance <= scanRadius then
                    -- Verificar si el nombre coincide con el patrÃ³n
                    local playerName = player.Name:lower()
                    if playerName:find(targetPattern) then
                        -- Verificar earnings si es necesario
                        local isValidTarget = true
                        
                        if targetEarnings > 0 then
                            -- AquÃ­ irÃ­a la lÃ³gica para verificar las ganancias del jugador
                            -- Esto depende del juego especÃ­fico
                            isValidTarget = false -- Asumimos que no coincide por ahora
                        end
                        
                        if isValidTarget then
                            table.insert(foundTargets, {
                                name = player.Name,
                                position = humanoidRootPart.Position,
                                distance = distance,
                                player = player
                            })
                        end
                    end
                end
            end
        end
    end

    return foundTargets
end

-- FunciÃ³n para cambiar de servidor mejorada
local function serverHop()
    local servers = getActiveServers()
    if #servers == 0 then
        Logger:Add("No se encontraron servidores vÃ¡lidos", "WARNING")
        return false
    end

    -- Seleccionar un servidor aleatorio que no sea el actual
    local currentJobId = game.JobId
    local validServers = {}
    
    for _, serverId in ipairs(servers) do
        if serverId ~= currentJobId then
            table.insert(validServers, serverId)
        end
    end

    if #validServers == 0 then
        Logger:Add("No hay otros servidores disponibles", "WARNING")
        return false
    end

    local randomServer = validServers[math.random(1, #validServers)]
    Logger:Add("Cambiando a servidor: "..randomServer)
    
    TeleportService:TeleportToPlaceInstance(
        CONFIG:Get("GAME_ID"),
        randomServer,
        LocalPlayer
    )
    
    return true
end

-- Bucle principal de caza mejorado
huntingLoop = function()
    while HunterState.Active and task.wait(1) do
        if HunterState.Paused then
            UI.Status.CurrentAction = "PAUSADO"
            updateUI()
            task.wait(2)
            goto continue
        end

        UI.Status.CurrentAction = "Escaneando jugadores..."
        updateUI()

        -- Escanear objetivos
        local targets = optimizedScan()
        HunterState.Targets = targets
        
        if #targets > 0 then
            UI.Status.TargetsFound = UI.Status.TargetsFound + #targets
            UI.Status.CurrentAction = string.format("%d objetivo(s) encontrado(s)", #targets)
            updateUI()
            
            -- Notificar por webhook si estÃ¡ configurado
            local webhookUrl = CONFIG:Get("WEBHOOK_URL")
            if webhookUrl and webhookUrl ~= "tu_webhook_aqui" then
                local success, err = pcall(function()
                    local message = string.format(
                        "Objetivo encontrado: %s\nDistancia: %.1f studs\nServidor: %s",
                        targets[1].name,
                        targets[1].distance,
                        game.JobId
                    )
                    
                    HttpService:PostAsync(webhookUrl, HttpService:JSONEncode({
                        content = message,
                        embeds = nil
                    }))
                end)
                
                if not success then
                    Logger:Add("Error al enviar webhook: "..tostring(err), "ERROR")
                end
            end
            
            -- Mostrar notificaciÃ³n
            NotificationManager:Show(
                "Objetivo encontrado!",
                string.format("%s (%.1f studs)", targets[1].name, targets[1].distance),
                5,
                Color3.fromRGB(0, 200, 100)
            )
            
            -- Esperar antes de cambiar de servidor
            task.wait(CONFIG:Get("SERVER_HOP_DELAY"))
        else
            UI.Status.CurrentAction = "No se encontraron objetivos"
            updateUI()
        end

        -- Cambiar de servidor si no hay objetivos
        if #targets == 0 then
            UI.Status.CurrentAction = "Buscando nuevo servidor..."
            updateUI()
            
            local success = serverHop()
            if success then
                UI.Status.ServersScanned = UI.Status.ServersScanned + 1
                HunterState.LastServerHop = os.time()
                task.wait(5) -- Esperar a que complete el cambio de servidor
            else
                task.wait(5) -- Esperar antes de reintentar
            end
        end

        ::continue::
    end
end

-- InicializaciÃ³n mejorada
local function initialize()
    Logger:Add("Hunter Pro iniciado")
    Logger:Add(string.format("ConfiguraciÃ³n cargada - PatrÃ³n: '%s'", CONFIG:Get("TARGET_PATTERN")))
    
    -- Crear UI mÃ³vil
    createMobileUI()
    
    -- Configurar tecla de toggle (opcional)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            if UI.MainWindow then
                UI.MainWindow.Visible = not UI.MainWindow.Visible
                floatingBall.Text = UI.MainWindow.Visible and "âœ•" or "â˜„ï¸"
            end
        end
    end)
    
    -- Iniciar automÃ¡ticamente si estÃ¡ configurado
    if CONFIG:Get("AUTO_START") then
        HunterState.Active = true
        coroutine.wrap(huntingLoop)()
    end
end

-- Ejecutar inicializaciÃ³n
initialize()	
