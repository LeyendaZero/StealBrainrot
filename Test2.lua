-- alt_hunter_exact_population.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_PATTERN = "TralaleroTralala",
    WEBHOOK_URL = "https://discord.com/api/webhooks/tu_webhook_real",
    SCAN_RADIUS = 5000,
    SERVER_HOP_DELAY = 15,  -- Mayor tiempo entre saltos
    MAX_RETRY_ATTEMPTS = 3,  -- Menos intentos para evitar bans
    STABILIZATION_WAIT = 15, -- Espera después de unirse
    DEBUG_MODE = true,
    
    -- Nuevos parámetros de población
    TARGET_PLAYER_RANGE = {min = 0, max = 8}, -- Buscar servidores con 6-7 jugadores
    MAX_SERVER_PLAYERS = 8  -- Capacidad máxima del servidor
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🎯 Obtener servidores con población exacta
local function getOptimalServers()
    local optimalServers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
            CONFIG.GAME_ID
        ))
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            -- Filtrar por rango de jugadores deseado
            if server.playing and server.maxPlayers == CONFIG.MAX_SERVER_PLAYERS then
                if server.playing >= CONFIG.TARGET_PLAYER_RANGE.min and 
                   server.playing <= CONFIG.TARGET_PLAYER_RANGE.max then
                    
                    table.insert(optimalServers, {
                        id = server.id,
                        players = server.playing,
                        ping = server.ping or 0,
                        -- Calcular "vacantes"
                        vacancies = (CONFIG.MAX_SERVER_PLAYERS - server.playing)
                    })
                end
            end
        end
        
        -- Ordenar por: 1. Más vacantes, 2. Mejor ping
        table.sort(optimalServers, function(a, b)
            if a.vacancies ~= b.vacancies then
                return a.vacancies > b.vacancies
            else
                return a.ping < b.ping
            end
        end)
    else
        warn("⚠️ Error al obtener servidores:", response)
    end

    return optimalServers
end

-- 🔄 Teletransporte estabilizado (igual que antes)
local function stableTeleport(jobId)
    -- ... (mantener el mismo código anterior)
end

-- 🔍 Escáner y reportes (igual que antes)
local function deepScan()
    -- ... (mantener el mismo código que funcionó)
end

local function sendHunterReport(targets, jobId)
    -- ... (mantener el mismo código anterior)
end

-- 🚀 Ciclo de búsqueda optimizado
local function exactPopulationHunting()
    print("\n=== INICIANDO BÚSQUEDA EN SERVIDORES ", 
          CONFIG.TARGET_PLAYER_RANGE.min, "-", 
          CONFIG.TARGET_PLAYER_RANGE.max, "/", 
          CONFIG.MAX_SERVER_PLAYERS, " ===")

    while true do
        local servers = getOptimalServers()
        if #servers == 0 then
            warn("❌ No hay servidores óptimos. Reintentando en 2 minutos...")
            task.wait(120)
            continue
        end

        if CONFIG.DEBUG_MODE then
            print(string.format("\n🔄 Encontrados %d servidores ideales", #servers))
            for i, s in ipairs(servers) do
                if i <= 5 then  -- Mostrar solo los 5 primeros para no saturar
                    print(string.format("%d. %s (%d/%d jugadores, %dms ping)", 
                        i, s.id, s.players, CONFIG.MAX_SERVER_PLAYERS, s.ping))
                end
            end
        end

        for _, server in ipairs(servers) do
            if CONFIG.DEBUG_MODE then
                print(string.format("\n🛫 Intentando unirse a %s (%d/%d, %d vacantes)", 
                    server.id, server.players, CONFIG.MAX_SERVER_PLAYERS, server.vacancies))
            end

            if stableTeleport(server.id) then
                local targets = deepScan()
                sendHunterReport(targets, server.id)

                if #targets > 0 then
                    print("🎯 Objetivo encontrado! Esperando 5 minutos...")
                    task.wait(300)
                    break
                end
            end

            task.wait(CONFIG.SERVER_HOP_DELAY)
        end

        print("\n🔁 Reiniciando ciclo de búsqueda...")
        task.wait(30)
    end
end

-- 🏁 Iniciar sistema
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
    task.wait(5)  -- Espera adicional para personaje
end

exactPopulationHunting()
