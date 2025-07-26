-- bandito_scanner.lua
local CONFIG = {
    SCAN_RADIUS = 5000, -- Studs alrededor del jugador a escanear
    TARGET_PATTERN = "Bandito", -- Palabra clave para buscar (puede ser parte del nombre)
    WEBHOOK_URL = "https://discord.com/api/webhooks/tu_webhook_real",
    DEBUG_MODE = true -- Muestra información detallada
}

-- 🛠️ Servicios esenciales
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Escáner ultra-exhaustivo
local function fullWorkspaceScan()
    if not LocalPlayer.Character then
        warn("❌ No hay personaje del jugador")
        return nil
    end

    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        warn("❌ No se encontró HumanoidRootPart")
        return nil
    end

    local foundObjects = {}
    local startTime = os.clock()
    
    -- Función recursiva de escaneo
    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Verificar por nombre
            if string.find(child.Name:lower(), CONFIG.TARGET_PATTERN:lower()) then
                table.insert(foundObjects, {
                    name = child:GetFullName(),
                    position = child:GetPivot().Position,
                    distance = (child:GetPivot().Position - rootPart.Position).Magnitude
                })
            end
            
            -- Escanear recursivamente
            if child:IsA("Folder") or child:IsA("Model") then
                scanRecursive(child)
            end
        end
    end

    -- Escanear áreas críticas primero
    local priorityAreas = {
        Workspace,
        Workspace:FindFirstChild("Map") or Workspace,
        Workspace:FindFirstChild("GameObjects") or Workspace
    }

    for _, area in ipairs(priorityAreas) do
        scanRecursive(area)
    end

    -- Ordenar por distancia
    table.sort(foundObjects, function(a, b) return a.distance < b.distance end)

    if CONFIG.DEBUG_MODE then
        print(string.format("\n🔍 Escaneo completado en %.2f segundos", os.clock() - startTime))
        print("📊 Objetos encontrados:", #foundObjects)
        for i, obj in ipairs(foundObjects) do
            print(string.format("%d. %s (Distancia: %.1f studs)", i, obj.name, obj.distance))
        end
    end

    return foundObjects
end

-- 📨 Reporte inteligente
local function sendScanReport(foundObjects)
    local embeds = {}
    local content = #foundObjects > 0 and "@here Objetivos encontrados!" or nil

    if #foundObjects > 0 then
        for i, obj in ipairs(foundObjects) do
            if i <= 5 then -- Limitar a 5 resultados principales
                table.insert(embeds, {
                    title = "OBJETO #"..i,
                    description = obj.name,
                    color = 65280,
                    fields = {
                        {name = "Distancia", value = string.format("%.1f studs", obj.distance), inline = true},
                        {name = "Posición", value = tostring(obj.position), inline = true},
                        {name = "Servidor", value = game.JobId}
                    }
                })
            end
        end
    else
        table.insert(embeds, {
            title = "ESCANEO COMPLETADO",
            description = "No se encontraron objetos coincidentes",
            color = 16711680,
            fields = {
                {name = "Patrón buscado", value = CONFIG.TARGET_PATTERN},
                {name = "Servidor", value = game.JobId}
            }
        })
    end

    local success, err = pcall(function()
        local payload = {
            content = content,
            embeds = embeds
        }
        
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

-- 🎯 Ejecución principal
local function main()
    print("\n=== INICIANDO ESCANEO COMPLETO ===")
    print("🔍 Buscando patrones que contengan:", CONFIG.TARGET_PATTERN)
    
    local foundObjects = fullWorkspaceScan()
    sendScanReport(foundObjects)
    
    print("\n=== ESCANEO FINALIZADO ===")
    if CONFIG.DEBUG_MODE then
        print("Presiona F9 para ver detalles completos")
    end
end

-- Esperar a que el personaje cargue
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

main()
