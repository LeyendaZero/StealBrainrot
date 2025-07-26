-- delta_scanner.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_NAME = "BallerinaCappuccina",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398573923280359425/SQDEI2MXkQUC6f4WGdexcHGdmYpUO_sARSkuBmF-Wa-fjQjsvpTiUjVcEjrvuVdSKGb1", -- Usar webhook normal
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 30,
    MAX_SERVERS = 50,
    DEBUG_MODE = true
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Función de búsqueda optimizada
local function findTarget()
    local startTime = os.clock()
    local target = Workspace:FindFirstChild(CONFIG.TARGET_NAME, true)
    
    if CONFIG.DEBUG_MODE then
        print(string.format("🔍 Búsqueda completada en %.2f segundos", os.clock() - startTime))
        print(target and "✅ Objetivo encontrado: "..target:GetFullName() or "❌ Objeto no encontrado")
    end
    
    return target
end

-- 📨 Envío seguro a Discord (compatible con Delta)
local function sendToDiscord(message, embed)
    local payload = {
        content = message,
        embeds = embed and {embed} or nil
    }

    local success, err = pcall(function()
        -- Método compatible con Delta
        local response = request({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
        
        if response.StatusCode ~= 200 and response.StatusCode ~= 204 then
            error("Código de estado: "..response.StatusCode)
        end
    end)

    if not success and CONFIG.DEBUG_MODE then
        print("⚠️ Error al enviar a Discord:", err)
    end
end

-- 🔄 Obtención de servidores públicos
local function getPublicServers()
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGetAsync(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=%d",
            CONFIG.GAME_ID, CONFIG.MAX_SERVERS
        ))
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            if server.playing > 3 then -- Filtrar servidores muertos
                table.insert(servers, server.id)
            end
        end
    elseif CONFIG.DEBUG_MODE then
        print("⚠️ Error al obtener servidores:", response)
    end

    return servers
end

-- 🚀 Sistema principal simplificado
local function startScanning()
    print("\n=== INICIANDO ESCANEO ===")
    print("Objetivo:", CONFIG.TARGET_NAME)
    print("Radio de búsqueda:", CONFIG.SCAN_RADIUS, "studs")

    while true do
        local servers = getPublicServers()
        if #servers == 0 then
            print("⚠️ No se encontraron servidores. Reintentando...")
            task.wait(60)
            continue
        end

        print("\n🔄 Obtenidos", #servers, "servidores activos")

        for i, serverId in ipairs(servers) do
            print(string.format("\n(%d/%d) Uniéndose a: %s", i, #servers, serverId))

            local joinSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, serverId)
            end)

            if joinSuccess then
                -- Esperar carga
                repeat task.wait(1) until game:IsLoaded()
                task.wait(3) -- Espera adicional

                local target = findTarget()
                if target then
                    local position = target:GetPivot().Position
                    print("🎯 Objetivo encontrado en:", position)

                    sendToDiscord("@here OBJETIVO ENCONTRADO", {
                        title = "DETECCIÓN EXITOSA",
                        description = string.format("**%s** encontrado", CONFIG.TARGET_NAME),
                        color = 65280,
                        fields = {
                            {name = "Posición", value = tostring(position)},
                            {name = "Servidor", value = serverId},
                            {name = "Enlace", value = string.format(
                                "roblox://placeId=%d&gameInstanceId=%s",
                                CONFIG.GAME_ID, serverId
                            )}
                        }
                    })
                    return -- Terminar después de encontrar
                end
            else
                print("⚠️ Error al unirse al servidor")
            end

            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        print("\n🔁 Ciclo completado. Reiniciando...")
        task.wait(30)
    end
end

-- ⚙️ Inicialización
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
    task.wait(2)
end

-- Verificar si request está disponible
if not request then
    print("❌ 'request' no está disponible. Usando método alternativo...")
    -- Método alternativo con HttpPostAsync
    CONFIG.USE_ALTERNATE_HTTP = true
end

startScanning()
