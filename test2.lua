-- stationary_scanner.lua
local CONFIG = {
    TARGET_NAME = "BallerinaCappuccina", -- Nombre exacto del objeto
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398573923280359425/SQDEI2MXkQUC6f4WGdexcHGdmYpUO_sARSkuBmF-Wa-fjQjsvpTiUjVcEjrvuVdSKGb1",
    SCAN_RADIUS = 5000, -- Radio de búsqueda en studs
    SCAN_INTERVAL = 60, -- Tiempo entre escaneos (segundos)
    DEBUG_MODE = true   -- Muestra información detallada
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Escáner local optimizado
local function scanAroundPlayer()
    local startTime = os.clock()
    local foundObjects = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then
        if CONFIG.DEBUG_MODE then
            print("❌ No se encontró HumanoidRootPart")
        end
        return {}
    end

    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Coincidencia exacta del nombre
            if child.Name == CONFIG.TARGET_NAME then
                local position = child:GetPivot().Position
                local distance = (position - rootPart.Position).Magnitude
                
                if distance <= CONFIG.SCAN_RADIUS then
                    table.insert(foundObjects, {
                        name = child:GetFullName(),
                        position = position,
                        distance = distance
                    })
                end
            end
            
            -- Escanear subcarpetas y modelos
            if child:IsA("Folder") or child:IsA("Model") then
                scanRecursive(child)
            end
        end
    end

    -- Áreas prioritarias
    local areasToScan = {
        Workspace,
        Workspace:FindFirstChild("Map") or Workspace,
        Workspace:FindFirstChild("GameObjects") or Workspace
    }

    for _, area in ipairs(areasToScan) do
        scanRecursive(area)
    end

    -- Ordenar por distancia
    table.sort(foundObjects, function(a, b) return a.distance < b.distance end)
    
    if CONFIG.DEBUG_MODE then
        print(string.format("🔍 Escaneo completado en %.2f segundos", os.clock() - startTime))
        print("📌 Objetos encontrados:", #foundObjects)
    end
    
    return foundObjects
end

-- 📨 Notificador a Discord (compatible con Delta)
local function sendDetectionReport(targets)
    if #targets == 0 then return false end

    local embed = {
        title = "🎯 OBJETIVO DETECTADO",
        description = string.format("**%s** encontrado en el servidor", CONFIG.TARGET_NAME),
        color = 65280, -- Verde
        fields = {
            {
                name = "🗺️ Posición",
                value = tostring(targets[1].position),
                inline = true
            },
            {
                name = "📏 Distancia",
                value = string.format("%.1f studs", targets[1].distance),
                inline = true
            },
            {
                name = "🆔 Server ID",
                value = game.JobId
            },
            {
                name = "🔗 Enlace Directo",
                value = string.format("[Unirse a este servidor](roblox://placeId=%d&gameInstanceId=%s)", 
                    game.PlaceId, game.JobId)
            }
        },
        footer = {
            text = string.format("Detectado por %s • %s", 
                LocalPlayer.Name, os.date("%X"))
        }
    }

    local success, err = pcall(function()
        -- Método compatible con Delta
        local response = request({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                content = "@here Objetivo localizado!",
                embeds = {embed}
            })
        })
        
        return response.StatusCode == 200 or response.StatusCode == 204
    end)

    if not success and CONFIG.DEBUG_MODE then
        print("⚠️ Error al enviar reporte:", err)
    end
    
    return success
end

-- 🔄 Sistema de escaneo periódico
local function startStationaryScan()
    print("\n=== INICIANDO ESCANEO ESTACIONARIO ===")
    print("🔍 Objetivo:", CONFIG.TARGET_NAME)
    print("📡 Radio de escaneo:", CONFIG.SCAN_RADIUS, "studs")
    print("⏱️ Intervalo:", CONFIG.SCAN_INTERVAL, "segundos")

    local alreadyReported = {} -- Evitar reportes duplicados

    while true do
        local targets = scanAroundPlayer()
        
        if #targets > 0 then
            local targetKey = targets[1].position.X..targets[1].position.Y..targets[1].position.Z
            
            if not alreadyReported[targetKey] then
                if sendDetectionReport(targets) then
                    print("📨 Reporte enviado correctamente")
                    alreadyReported[targetKey] = true
                end
            elseif CONFIG.DEBUG_MODE then
                print("ℹ️ Objetivo ya reportado anteriormente")
            end
        elseif CONFIG.DEBUG_MODE then
            print("🔄 No se encontraron objetivos. Volviendo a escanear...")
        end

        task.wait(CONFIG.SCAN_INTERVAL)
    end
end

-- 🚀 Inicialización segura
local function initialize()
    -- Esperar a que el personaje cargue
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
        task.wait(2) -- Espera adicional
    end
    
    -- Verificar si request está disponible
    if not request then
        print("❌ 'request' no disponible. Usando HttpPost...")
        function sendDetectionReport(targets)
            HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode({
                content = "@here Objetivo localizado!",
                embeds = {...} -- Mismo embed de antes
            }))
            return true
        end
    end
    
    startStationaryScan()
end

-- Iniciar sistema
initialize()
