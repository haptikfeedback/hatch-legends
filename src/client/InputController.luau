--[[
    InputController.luau
    Handles tap/click input for earning coins
    Works on both desktop (mouse click) and mobile (touch)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TapCoin = Remotes:WaitForChild("TapCoin")

local player = Players.LocalPlayer

local InputController = {}
InputController._cooldown = false
InputController._cooldownTime = 0.1 -- 100ms between taps (anti-spam)
InputController._onCoinEarned = nil -- callback for UI updates

function InputController.Init(onCoinEarned: ((earned: number, total: number) -> ())?)
    InputController._onCoinEarned = onCoinEarned

    -- Desktop: mouse click
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end -- ignore clicks on UI elements

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            InputController._handleTap()
        end
    end)

    -- Mobile: touch tap
    UserInputService.TouchTap:Connect(function(touchPositions, gameProcessed)
        if gameProcessed then return end
        InputController._handleTap()
    end)
end

function InputController._handleTap()
    if InputController._cooldown then return end
    InputController._cooldown = true

    task.spawn(function()
        local earned, totalCoins = TapCoin:InvokeServer()
        if earned and InputController._onCoinEarned then
            InputController._onCoinEarned(earned, totalCoins)
        end
    end)

    task.delay(InputController._cooldownTime, function()
        InputController._cooldown = false
    end)
end

return InputController
