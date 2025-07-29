
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "TralaleroTralala",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398573923280359425/SQDEI2MXkQUC6f4WGdexcHGdmYpUO_sARSkuBmF-Wa-fjQjsvpTiUjVcEjrvuVdSKGb1", -- Cambia por el tuyo
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

-- 🔍 Escaneo profundo del workspace
local function deepScan()
    local foundTargets = {}
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local rootPosition = rootPart and rootPart.Position or Vector3.new(0, 0, 0)

    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if typeof(child.Name) == "string" and string.find(string.lower(child.Name), string.lower(CONFIG.TARGET_PATTERN)) then
                local position
                pcall(function()
                    position = child:GetPivot().Position
                end)
                position = position or (child.Position or Vector3.new(0, 0, 0))

                local distance = (position - rootPosition).Magnitude
                if distance <= CONFIG.SCAN_RADIUS then
                    table.insert(foundTargets, {
                        name = child:GetFullName(),
                        position = position,
                        distance = distance
                    })
                end
            end

            if child:IsA("Model") or child:IsA("Folder") then
                scanRecursive(child)
            end
        end
    end

    scanRecursive(Workspace)
    table.sort(foundTargets, function(a, b) return a.distance < b.distance end)

    return foundTargets
end

-- 📢 Enviar alerta por Webhook
local function sendHunterReport(targets, jobId)
    local embeds = {}
    local content = #targets > 0 and "@everyone 🎯 OBJETIVO DETECTADO" or "🔍 Escaneo sin coincidencias."

    for i, target in ipairs(targets) do
        if i <= 3 then
            table.insert(embeds, {
                ["title"] = "🎯 OBJETO DETECTADO",
                ["description"] = string.format("Nombre: `%s`\nDistancia: **%.1f studs**", target.name, target.distance),
                ["color"] = 65280,
                ["fields"] = {
                    {
                        ["name"] = "Posición",
                        ["value"] = tostring(target.position)
                    },
                    {
                        ["name"] = "Servidor",
                        ["value"] = jobId or game.JobId
                    },
                    {
                        ["name"] = "Enlace directo",
                        ["value"] = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId or game.JobId)
                    }
                }
            })
        end
    end

    if #embeds == 0 then
        table.insert(embeds, {
            ["title"] = "🔍 ESCANEO COMPLETADO",
            ["description"] = "No se encontró ningún objeto con coincidencia.",
            ["color"] = 16711680
        })
    end

    local payload = {
        ["content"] = content,
        ["embeds"] = embeds,
        ["username"] = "🛰️ TralaleroBot",
        ["avatar_url"] = "https://i.imgur.com/WScAnDg.png"
    }

    local success, err = pcall(function()
        HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(payload))
    end)

    if not success and CONFIG.DEBUG_MODE then
        warn("❌ Error al enviar Webhook:", err)
    end
end

-- 🔁 Obtener servidores públicos
local function getActiveServers()
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=%d",
            CONFIG.GAME_ID, CONFIG.MAX_SERVERS
        ))
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            table.insert(servers, server.id)
        end
    else
        warn("⚠️ Error al obtener servidores:", response)
    end

    return servers
end

-- 🛫 Entrar a servidor
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
            if not LocalPlayer.Character then
                LocalPlayer.CharacterAdded:Wait()
            end
            task.wait(3)
            return true
        else
            task.wait(5)
        end
    until attempts >= maxAttempts

    return false
end

-- 🔄 Bucle principal
local function huntingLoop()
    print("🛰️ Iniciando escaneo de objetos...")

    while true do
        local servers = getActiveServers()
        if #servers == 0 then
            warn("❌ No se encontraron servidores activos.")
            task.wait(60)
            continue
        end

        for _, serverId in ipairs(servers) do
            print("🔁 Cambiando a servidor:", serverId)
            if joinServer(serverId) then
                local targets = deepScan()
                sendHunterReport(targets, serverId)

                if #targets > 0 then
                    print("✅ OBJETO ENCONTRADO. Escaneo terminado.")
                    return
                end
            end
            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        print("🔃 Reiniciando ciclo de servidores...")
        task.wait(30)
    end
end

-- 🚀 Iniciar
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

huntingLoop()
