-- alt_hunter.lua
local CONFIG = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://raw.githubusercontent.com/LeyendaZero/StealBrainrot/main/Alt__configt.json"))

local function isAltAccount()
    return string.find(game:GetService("Players").LocalPlayer.Name, CONFIG.alt_prefix) ~= nil
end

local function safeTeleport(jobId)
    local attempts = 0
    repeat
        attempts += 1
        local success = pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(CONFIG.game_id, jobId)
        end)
        if success then return true end
        task.wait(math.random(10, 30)) -- Espera aleatoria
    until attempts >= 3
    return false
end

local function scanForTarget()
    -- Usa el método de escaneo que ya funcionó
    local target = workspace:FindFirstChild(CONFIG.target_object, true)
    if target then
        return target:GetPivot().Position
    end
    return nil
end

local function reportToDiscord(jobId, position)
    local payload = {
        content = "@here 🎯 OBJETIVO ENCONTRADO",
        embeds = {{
            title = "DETECCIÓN EXITOSA",
            description = "Cuenta ALT encontró el objetivo",
            fields = {
                {name = "Servidor", value = jobId},
                {name = "Posición", value = tostring(position)},
                {name = "ALT", value = game:GetService("Players").LocalPlayer.Name}
            }
        }}
    }
    game:GetService("HttpService"):PostAsync(CONFIG.webhook_url, game:GetService("HttpService"):JSONEncode(payload))
end

-- Ejecución principal
if isAltAccount() then
    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("URL_LISTA_SERVIDORES")).servers
    
    for i = 1, math.min(CONFIG.max_servers_per_alt, #servers) do
        local jobId = servers[i]
        if safeTeleport(jobId) then
            repeat task.wait() until game:IsLoaded()
            task.wait(10) -- Espera para asegurar carga
            
            local targetPos = scanForTarget()
            if targetPos then
                reportToDiscord(jobId, targetPos)
                break
            end
        end
        task.wait(CONFIG.delay_between_hops + math.random(-10, 10)) -- Variabilidad
    end
end
