-- alt_hunter_stable.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "CocofantoElefanto",
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398573923280359425/SQDEI2MXkQUC6f4WGdexcHGdmYpUO_sARSkuBmF-Wa-fjQjsvpTiUjVcEjrvuVdSKGb1",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 15,  -- Aumentado para evitar flood
    MAX_RETRY_ATTEMPTS = 5,  -- Intentos por servidor
    STABILIZATION_WAIT = 10, -- Espera después de unirse
    DEBUG_MODE = true
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔄 Sistema de teletransporte estabilizado
local function stableTeleport(jobId)
    local originalJobId = game.JobId
    local attempts = 0
    
    while attempts < CONFIG.MAX_RETRY_ATTEMPTS do
        attempts += 1
        
        -- 1. Intentar teletransporte
        local teleportSuccess = pcall(function()
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)
        
        if not teleportSuccess then
            if CONFIG.DEBUG_MODE then
                print(string.format("⚠️ Intento %d/%d fallido para %s", attempts, CONFIG.MAX_RETRY_ATTEMPTS, jobId))
            end
            task.wait(5)
            continue
        end
        
        -- 2. Esperar carga estable
        local loaded = false
        local startTime = os.time()
        
        repeat
            task.wait(1)
            loaded = game:IsLoaded() and Players.LocalPlayer.Character ~= nil
            
            -- Verificar si nos redirigieron
            if loaded and game.JobId ~= jobId and os.time() - startTime > 10 then
                if CONFIG.DEBUG_MODE then
                    print(string.format("🔀 Redirigido de %s a %s", jobId, game.JobId))
                end
                break
            end
        until loaded or os.time() - startTime > 15
        
        -- 3. Verificación final
        if loaded and game.JobId == jobId then
            if CONFIG.DEBUG_MODE then
                print("✅ Teletransporte estable a", jobId)
            end
            task.wait(CONFIG.STABILIZATION_WAIT)
            return true
        end
        
        task.wait(3)
    end
    
    return false
end

-- 🔍 Escáner (el mismo que funcionó anteriormente)
local function deepScan()
    -- ... (mantén el mismo código de escaneo que ya funcionó)
end

-- 📨 Reportes (el mismo que antes)
local function sendHunterReport(targets, jobId)
    -- ... (mantén el mismo código de reportes)
end

-- 🚀 Obtener servidores con información de capacidad
local function getStableServers()
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=%d",
            CONFIG.GAME_ID, CONFIG.MAX_SERVERS
        ))
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            -- Preferir servidores con menos jugadores (más estables)
            if server.playing and server.playing < (server.maxPlayers * 0.7) then
                table.insert(servers, {
                    id = server.id,
                    players = server.playing,
                    ping = server.ping or 0
                })
            end
        end
        
        -- Ordenar por mejor ping y menor población
        table.sort(servers, function(a, b)
            if a.ping ~= b.ping then
                return a.ping < b.ping
            else
                return a.players < b.players
            end
        end)
    else
        warn("⚠️ Error al obtener servidores:", response)
    end

    return servers
end

-- 🔄 Ciclo de búsqueda mejorado
local function stableHuntingLoop()
    print("\n=== INICIANDO MODO HUNTER ESTABLE ===")

    while true do
        local servers = getStableServers()
        if #servers == 0 then
            warn("❌ No se obtuvieron servidores. Reintentando en 1 minuto...")
            task.wait(60)
            continue
        end

        if CONFIG.DEBUG_MODE then
            print(string.format("🔄 Obtenidos %d servidores estables", #servers))
        end

        for _, server in ipairs(servers) do
            if CONFIG.DEBUG_MODE then
                print(string.format("🛫 Intentando unirse a %s (%d/%d jugadores, %dms ping)", 
                    server.id, server.players, server.maxPlayers or 50, server.ping))
            end

            if stableTeleport(server.id) then
                local targets = deepScan()
                sendHunterReport(targets, server.id)

                if #targets > 0 then
                    print("🎯 Objetivo encontrado! Esperando antes de continuar...")
                    task.wait(300) -- Espera 5 minutos antes de reiniciar
                    break
                end
            end

            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        if CONFIG.DEBUG_MODE then
            print("🔁 Reiniciando ciclo de búsqueda...")
        end
        task.wait(30)
    end
end

-- 🎯 Inicialización
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
    task.wait(5)
end

stableHuntingLoop()
