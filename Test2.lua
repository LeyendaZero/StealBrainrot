-- brainrot_final_fixed.lua
local CONFIG = {
    GAME_ID = 109983668079237,
    TARGET_NAME = "CocofantoElefanto", -- Nombre EXACTO
    WEBHOOK_URL = "https://discord.com/api/webhooks/1398405036253646849/eduChknG-GHdidQyljf3ONIvGebPSs7EqP_68sS_FV_nZc3bohUWlBv2BY3yy3iIMYmA",
    VERIFICATION_DELAY = 2, -- Segundos entre verificaciones
    MAX_TELEPORT_ATTEMPTS = 3,
    DEBUG_MODE = true
}

-- 🛠️ Servicios
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 🔍 Búsqueda precisa (versión optimizada)
local function findTargetExact()
    local function recursiveFind(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Coincidencia exacta de nombre (case sensitive)
            if child.Name == CONFIG.TARGET_NAME then
                -- Verificar que sea un objeto físico
                if child:IsA("Model") or child:IsA("BasePart") then
                    return child
                end
            end
            
            -- Búsqueda en subcarpetas
            if child:IsA("Folder") or child:IsA("Model") then
                local found = recursiveFind(child)
                if found then return found end
            end
        end
        return nil
    end
    
    return recursiveFind(Workspace)
end

-- 🚀 Teletransporte ultra-compatible
local function secureTeleport(jobId)
    local attempts = 0
    
    while attempts < CONFIG.MAX_TELEPORT_ATTEMPTS do
        attempts += 1
        
        -- Método 1: Standard
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId, LocalPlayer)
        end)
        
        if success then
            -- Esperar carga
            local loaded = false
            local startTime = os.clock()
            
            while os.clock() - startTime < 30 do -- Timeout de 30 segundos
                if game:IsLoaded() then
                    loaded = true
                    break
                end
                task.wait(1)
            end
            
            if loaded then
                -- Espera adicional para assets
                task.wait(5)
                return true
            end
        end
        
        -- Método 2: Alternativo para exploits modernos
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport("print('Teleport completado')")
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(CONFIG.GAME_ID, jobId)
            return true
        end
        
        task.wait(3) -- Espera entre intentos
    end
    
    return false
end

-- 📨 Sistema de reportes mejorado
local function sendFoundReport(target, jobId)
    local position = target:GetPivot().Position
    local payload = {
        content = "@here 🎯 OBJETIVO CONFIRMADO",
        embeds = {{
            title = "DETECCIÓN VERIFICADA",
            description = string.format("**%s** encontrado", target:GetFullName()),
            color = 65280,
            fields = {
                {name = "Posición", value = tostring(position)},
                {name = "Servidor", value = jobId or game.JobId},
                {name = "Enlace Directo", value = string.format("roblox://placeId=%d&gameInstanceId=%s", CONFIG.GAME_ID, jobId or game.JobId)}
            }
        }}
    }

    -- Envío compatible con todos los exploits
    local success, err = pcall(function()
        if request then
            request({
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
        warn("⚠️ Error en webhook:", err)
    end
end

-- 🔄 Bucle principal mejorado
local function main()
    -- Verificar servidor actual primero
    local target = findTargetExact()
    if target then
        sendFoundReport(target)
        print("✅ Objetivo encontrado en servidor actual")
        return
    end

    -- Obtener servidores
    local servers = {}
    local success, response = pcall(function()
        return game:HttpGet(string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=50",
            CONFIG.GAME_ID
        ))
    end)

    if not success then
        warn("❌ Error al obtener servidores:", response)
        return
    end

    servers = HttpService:JSONDecode(response).data

    -- Buscar en cada servidor
    for _, server in ipairs(servers) do
        if CONFIG.DEBUG_MODE then
            print("🔄 Intentando servidor:", server.id)
        end

        if secureTeleport(server.id) then
            -- Verificación triple
            local verified = false
            for i = 1, 3 do
                task.wait(CONFIG.VERIFICATION_DELAY)
                target = findTargetExact()
                if target then
                    verified = true
                    break
                end
            end

            if verified then
                sendFoundReport(target, server.id)
                print("🎯 Servidor confirmado - Manteniéndose en este servidor")
                
                -- Bucle de permanencia
                while true do
                    task.wait(10)
                    if not findTargetExact() then
                        print("⚠️ Objeto desaparecido - Reiniciando búsqueda")
                        break
                    end
                end
            else
                print("❌ Objeto no encontrado en este servidor")
            end
        end
    end
end

-- Inicialización segura
local function safeStart()
    pcall(function()
        if not LocalPlayer.Character then
            LocalPlayer.CharacterAdded:Wait()
        end
        main()
    end)
end

safeStart()
