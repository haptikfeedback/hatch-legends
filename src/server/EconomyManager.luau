--[[
    EconomyManager.luau
    Handles coin earning (click + passive), spending, rebirth logic
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local DataManager -- set via Init
local PetManager  -- set via Init

local EconomyManager = {}

function EconomyManager.Init(dataManager, petManager)
    DataManager = dataManager
    PetManager = petManager
end

-- Calculate the total coin multiplier for a player
function EconomyManager.GetMultiplier(player: Player): number
    local data = DataManager.GetData(player)
    if not data then return 1 end

    local multiplier = 1.0

    -- Rebirth bonus
    multiplier += data.rebirths * GameConfig.REBIRTH_BONUS_PER

    -- VIP pass
    local ok, hasVIP = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GAME_PASSES.VIP.id)
    end)
    if ok and hasVIP then
        multiplier *= GameConfig.VIP_MULTIPLIER
    end

    return multiplier
end

-- Handle a tap/click to earn coins
function EconomyManager.OnTap(player: Player): number
    local data = DataManager.GetData(player)
    if not data then return 0 end

    local petPower = PetManager.GetEquippedPower(player)
    local baseEarn = GameConfig.BASE_COINS_PER_TAP + petPower
    local multiplier = EconomyManager.GetMultiplier(player)
    local earned = math.floor(baseEarn * multiplier)

    data.coins += earned
    data.totalCoins += earned

    return earned
end

-- Passive earning tick (called periodically for players with equipped pets)
function EconomyManager.PassiveTick(player: Player): number
    local data = DataManager.GetData(player)
    if not data then return 0 end

    local petPower = PetManager.GetEquippedPower(player)
    if petPower <= 0 then return 0 end

    local baseEarn = petPower * GameConfig.AFK_EARN_RATE
    local multiplier = EconomyManager.GetMultiplier(player)
    local earned = math.floor(baseEarn * multiplier)

    if earned > 0 then
        data.coins += earned
        data.totalCoins += earned
    end

    return earned
end

-- Check if player can afford something
function EconomyManager.CanAfford(player: Player, amount: number): boolean
    local data = DataManager.GetData(player)
    if not data then return false end
    return data.coins >= amount
end

-- Spend coins (returns true if successful)
function EconomyManager.Spend(player: Player, amount: number): boolean
    local data = DataManager.GetData(player)
    if not data then return false end

    if data.coins < amount then
        return false
    end

    data.coins -= amount
    return true
end

-- Add coins directly (for dev product purchases, codes, etc.)
function EconomyManager.AddCoins(player: Player, amount: number)
    local data = DataManager.GetData(player)
    if not data then return end

    data.coins += amount
    data.totalCoins += amount
end

-- Get rebirth cost for a player
function EconomyManager.GetRebirthCost(player: Player): number
    local data = DataManager.GetData(player)
    if not data then return math.huge end

    return math.floor(GameConfig.REBIRTH_BASE_COST * (GameConfig.REBIRTH_COST_MULTIPLIER ^ data.rebirths))
end

-- Perform rebirth (resets coins, keeps pets, increases rebirth count)
function EconomyManager.Rebirth(player: Player, instant: boolean?): boolean
    local data = DataManager.GetData(player)
    if not data then return false end

    if not instant then
        local cost = EconomyManager.GetRebirthCost(player)
        if data.coins < cost then
            return false
        end
    end

    -- Reset coins
    data.coins = 0

    -- Increment rebirth counter
    data.rebirths += 1

    -- Check if Shadow Realm should be unlocked
    if data.rebirths >= GameConfig.SHADOW_REALM_REBIRTH_REQ then
        if not table.find(data.unlockedZones, "Shadow Realm") then
            table.insert(data.unlockedZones, "Shadow Realm")
        end
    end

    return true
end

-- Unlock a zone by spending coins
function EconomyManager.UnlockZone(player: Player, zoneName: string): boolean
    local data = DataManager.GetData(player)
    if not data then return false end

    -- Already unlocked?
    if table.find(data.unlockedZones, zoneName) then
        return false
    end

    local cost = GameConfig.ZONE_UNLOCK_COSTS[zoneName]
    if not cost then return false end

    -- Shadow Realm requires rebirth, not coins
    if cost == -1 then
        if data.rebirths >= GameConfig.SHADOW_REALM_REBIRTH_REQ then
            table.insert(data.unlockedZones, zoneName)
            return true
        end
        return false
    end

    if data.coins < cost then
        return false
    end

    data.coins -= cost
    table.insert(data.unlockedZones, zoneName)
    return true
end

-- Start passive earning loop
function EconomyManager.StartPassiveEarning()
    task.spawn(function()
        while true do
            task.wait(GameConfig.AFK_TICK_INTERVAL)
            for _, player in Players:GetPlayers() do
                EconomyManager.PassiveTick(player)
            end
        end
    end)
end

return EconomyManager
