-- main_control.lua
local CONFIG = game:GetService("HttpService"):JSONDecode(game:HttpGet("URL_RAW_alt_config.json"))

local function updateServerList()
    local servers = {}
    -- Lógica para obtener servidores activos
    -- ...
    game:GetService("HttpService"):PostAsync("URL_API_TU_SERVIDOR/servers", game:GetService("HttpService"):JSONEncode(servers))
end

local function listenForAlerts()
    while true do
        -- Verificar webhook o API para hallazgos
        -- ...
        task.wait(15)
    end
end

-- Ejecutar ambas funciones en paralelo
coroutine.wrap(updateServerList)()
coroutine.wrap(listenForAlerts)()
