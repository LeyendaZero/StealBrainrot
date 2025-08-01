-- ✅ SCRIPT COMPLETO CON LISTA DE SERVIDORES Y BOTONES JOIN

local CONFIG = { GAME_ID = 109983668079237, TARGET_PATTERN = "Tralalero Tralala", TARGET_EARNINGS = 999999999, WEBHOOK_URL = "tu_webhook_aqui", SCAN_RADIUS = 5000, SERVER_HOP_DELAY = 2, MAX_SERVERS = 25, DEBUG_MODE = true }

local Players = game:GetService("Players") local HttpService = game:GetService("HttpService") local TeleportService = game:GetService("TeleportService") local Workspace = game:GetService("Workspace") local LocalPlayer = Players.LocalPlayer local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local serversVisited = 0 local foundServers = {} _G.running = true

-- GUI flotante estilo Lyez Hub local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "FloatingHunterUI" ScreenGui.ResetOnSpawn = false ScreenGui.IgnoreGuiInset = true ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling ScreenGui.Parent = PlayerGui

local DragFrame = Instance.new("Frame") DragFrame.Size = UDim2.new(0, 220, 0, 280) DragFrame.Position = UDim2.new(0.7, 0, 0.1, 0) DragFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) DragFrame.BackgroundTransparency = 0.2 DragFrame.BorderSizePixel = 0 DragFrame.Active = true DragFrame.Draggable = true DragFrame.Parent = ScreenGui

Instance.new("UICorner", DragFrame).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel") TitleLabel.Size = UDim2.new(1, 0, 0, 30) TitleLabel.Position = UDim2.new(0, 0, 0, 0) TitleLabel.BackgroundTransparency = 1 TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) TitleLabel.Font = Enum.Font.SourceSansBold TitleLabel.TextScaled = true TitleLabel.Text = "Servidores con Objetivo" TitleLabel.Parent = DragFrame

local StopButton = Instance.new("TextButton") StopButton.Size = UDim2.new(1, 0, 0, 30) StopButton.Position = UDim2.new(0, 0, 1, -30) StopButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60) StopButton.Text = "DETENER" StopButton.TextScaled = true StopButton.TextColor3 = Color3.new(1, 1, 1) StopButton.Font = Enum.Font.SourceSansBold StopButton.Parent = DragFrame Instance.new("UICorner", StopButton).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame") ScrollFrame.Size = UDim2.new(1, 0, 1, -60) ScrollFrame.Position = UDim2.new(0, 0, 0, 30) ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) ScrollFrame.ScrollBarThickness = 6 ScrollFrame.BackgroundTransparency = 1 ScrollFrame.Parent = DragFrame

local UIListLayout = Instance.new("UIListLayout") UIListLayout.Parent = ScrollFrame UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder UIListLayout.Padding = UDim.new(0, 4)

StopButton.MouseButton1Click:Connect(function() _G.running = false StopButton.Text = "BUSQUEDA DETENIDA" StopButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150) end)

local function addServerToList(target, jobId) for _, entry in ipairs(foundServers) do if entry.jobId == jobId then return end end

table.insert(foundServers, {target = target, jobId = jobId})

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, -8, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Frame.BorderSizePixel = 0
Frame.Parent = ScrollFrame
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

local Text = Instance.new("TextLabel")
Text.Size = UDim2.new(0.7, 0, 1, 0)
Text.Position = UDim2.new(0, 6, 0, 0)
Text.BackgroundTransparency = 1
Text.Text = string.format("%s | 💰 %s", target.name, target.earnings or "?")
Text.TextColor3 = Color3.fromRGB(255, 255, 255)
Text.TextScaled = true
Text.Font = Enum.Font.SourceSans
Text.Parent = Frame

local JoinBtn = Instance.new("TextButton")
JoinBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
JoinBtn.Position = UDim2.new(0.72, 0, 0.1, 0)
JoinBtn.Text = "JOIN"
JoinBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
JoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinBtn.TextScaled = true
JoinBtn.Font = Enum.Font.SourceSansBold
JoinBtn.Parent = Frame
Instance.new("UICorner", JoinBtn).CornerRadius = UDim.new(0, 5)

JoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
end)

ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)

end

-- Función simulada de huntingLoop local function huntingLoop() while _G.running do local servers = {"1", "2", "3"} -- ejemplo, reemplaza con getActiveServers() for _, serverId in ipairs(servers) do if not _G.running then break end local targets = { {name = "Tralalero Tralala", earnings = 999999999, distance = 20, position = Vector3.new()} } for _, target in ipairs(targets) do addServerToList(target, serverId) end task.wait(CONFIG.SERVER_HOP_DELAY) end end end

huntingLoop()

