--[[
    init.client.luau
    Main client bootstrap for Hatch Legends
    Initializes all client controllers
]]

local UIController = require(script:WaitForChild("UIController"))
local InputController = require(script:WaitForChild("InputController"))
local PetDisplayController = require(script:WaitForChild("PetDisplayController"))

-- Initialize UI first
UIController.Init()

-- Initialize input with callback to update coin display
InputController.Init(function(earned, totalCoins)
    if UIController._currentData then
        UIController._currentData.coins = totalCoins
        UIController.RefreshAll()
    end
    -- Show floating text for earned coins
    if earned and earned > 0 then
        UIController.ShowNotification("+" .. tostring(earned) .. " 🪙")
    end
end)

-- Initialize pet display
PetDisplayController.Init()

print("[Hatch Legends] Client initialized!")
