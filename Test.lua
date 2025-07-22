local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Variables
local targetHeight = humanoidRootPart.Position.Y + 50  -- 50 studs hacia arriba
local speed = 1  -- Velocidad de movimiento por paso
local delayTime = 0.1  -- Retardo entre cada paso

-- Función para realizar el teletransporte suave
local function smoothTeleportUp()
    local currentPosition = humanoidRootPart.Position
    local targetPosition = Vector3.new(currentPosition.X, targetHeight, currentPosition.Z)
    local distance = (targetPosition - currentPosition).Magnitude
    local steps = math.floor(distance / speed)
    
    -- Mover gradualmente hacia la posición objetivo
    for i = 1, steps do
        humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(CFrame.new(targetPosition), i / steps)
        wait(delayTime)
    end
end

-- Ejecutar el teletransporte
smoothTeleportUp()
