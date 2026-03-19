--[[
    ShopManager.luau
    Handles Game Pass ownership checks and Developer Product purchases
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local DataManager   -- set via Init
local EconomyManager -- set via Init

local ShopManager = {}

-- Per-player lucky egg flag (consumed on next hatch)
ShopManager._luckyEggPlayers = {} -- [Player] = true

function ShopManager.Init(dataManager, economyManager)
    DataManager = dataManager
    EconomyManager = economyManager
end

-- Check if player owns a specific game pass
function ShopManager.OwnsGamePass(player: Player, passKey: string): boolean
    local passDef = GameConfig.GAME_PASSES[passKey]
    if not passDef then return false end

    local ok, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passDef.id)
    end)

    if ok then
        return result
    end
    return false
end

-- Prompt a game pass purchase
function ShopManager.PromptGamePass(player: Player, passKey: string)
    local passDef = GameConfig.GAME_PASSES[passKey]
    if not passDef then return end

    MarketplaceService:PromptGamePassPurchase(player, passDef.id)
end

-- Prompt a developer product purchase
function ShopManager.PromptDevProduct(player: Player, productKey: string)
    local productDef = GameConfig.DEV_PRODUCTS[productKey]
    if not productDef then return end

    MarketplaceService:PromptProductPurchase(player, productDef.id)
end

-- Check if a player has a lucky egg active
function ShopManager.HasLuckyEgg(player: Player): boolean
    return ShopManager._luckyEggPlayers[player] == true
end

-- Consume a player's lucky egg
function ShopManager.ConsumeLuckyEgg(player: Player)
    ShopManager._luckyEggPlayers[player] = nil
end

-- Build product ID -> key lookup for ProcessReceipt
local productIdToKey = {}
for key, def in GameConfig.DEV_PRODUCTS do
    productIdToKey[def.id] = key
end

-- Setup ProcessReceipt callback
function ShopManager.SetupProcessReceipt()
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            -- Player left, don't grant yet — return NotProcessedYet so Roblox retries
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local data = DataManager.GetData(player)
        if not data then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local productKey = productIdToKey[receiptInfo.ProductId]
        if not productKey then
            warn("[ShopManager] Unknown product ID: " .. receiptInfo.ProductId)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local granted = false

        if productKey == "Coins1000" then
            EconomyManager.AddCoins(player, GameConfig.DEV_PRODUCTS.Coins1000.coins)
            granted = true

        elseif productKey == "Coins10000" then
            EconomyManager.AddCoins(player, GameConfig.DEV_PRODUCTS.Coins10000.coins)
            granted = true

        elseif productKey == "InstantRebirth" then
            granted = EconomyManager.Rebirth(player, true) -- instant = true, skip cost check

        elseif productKey == "LuckyEgg" then
            ShopManager._luckyEggPlayers[player] = true
            granted = true
        end

        if granted then
            -- Save immediately after purchase
            DataManager.SaveData(player)

            -- Fire update to client
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if remotes then
                local updateEvent = remotes:FindFirstChild("DataUpdate")
                if updateEvent then
                    updateEvent:FireClient(player, data)
                end
            end

            return Enum.ProductPurchaseDecision.PurchaseGranted
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- Listen for game pass purchase completions
function ShopManager.SetupGamePassListener()
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        if not wasPurchased then return end

        -- Notify client to update UI
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local updateEvent = remotes:FindFirstChild("DataUpdate")
            if updateEvent then
                local data = DataManager.GetData(player)
                if data then
                    updateEvent:FireClient(player, data)
                end
            end
        end
    end)
end

-- Cleanup when player leaves
function ShopManager.OnPlayerLeaving(player: Player)
    ShopManager._luckyEggPlayers[player] = nil
end

return ShopManager
