--[[
    DataManager.luau
    Handles player data save/load with DataStoreService
    Includes retry logic and error handling
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local DataManager = {}
DataManager._playerData = {} -- [Player] = PlayerData table
DataManager._dataStore = DataStoreService:GetDataStore(GameConfig.DATA_STORE_NAME)

-- Default data for new players
function DataManager.GetDefaultData(): any
    return {
        coins = 0,
        totalCoins = 0,
        rebirths = 0,
        pets = {},
        petIndex = {},
        unlockedZones = { "Grasslands" },
        redeemedCodes = {},
        joinDate = os.time(),
        lastSave = os.time(),
    }
end

-- Deep copy a table
local function deepCopy(original)
    local copy = {}
    for key, value in original do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Load player data with retry
function DataManager.LoadData(player: Player): (boolean, any)
    local key = "Player_" .. player.UserId
    local data = nil
    local success = false

    for attempt = 1, GameConfig.DATA_STORE_RETRIES do
        local ok, result = pcall(function()
            return DataManager._dataStore:GetAsync(key)
        end)

        if ok then
            data = result
            success = true
            break
        else
            warn("[DataManager] Load attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(result))
            if attempt < GameConfig.DATA_STORE_RETRIES then
                task.wait(1)
            end
        end
    end

    if success then
        if data then
            -- Merge with defaults to handle schema migrations
            local defaults = DataManager.GetDefaultData()
            for key, value in defaults do
                if data[key] == nil then
                    data[key] = value
                end
            end
        else
            -- New player
            data = DataManager.GetDefaultData()
        end

        DataManager._playerData[player] = data
        return true, data
    else
        -- Failed to load after all retries — give them default data but mark it
        warn("[DataManager] CRITICAL: Failed to load data for " .. player.Name .. " after all retries")
        local defaults = DataManager.GetDefaultData()
        DataManager._playerData[player] = defaults
        return false, defaults
    end
end

-- Save player data with retry
function DataManager.SaveData(player: Player): boolean
    local data = DataManager._playerData[player]
    if not data then
        return false
    end

    data.lastSave = os.time()
    local key = "Player_" .. player.UserId

    for attempt = 1, GameConfig.DATA_STORE_RETRIES do
        local ok, err = pcall(function()
            DataManager._dataStore:SetAsync(key, data)
        end)

        if ok then
            return true
        else
            warn("[DataManager] Save attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(err))
            if attempt < GameConfig.DATA_STORE_RETRIES then
                task.wait(1)
            end
        end
    end

    warn("[DataManager] CRITICAL: Failed to save data for " .. player.Name)
    return false
end

-- Get player data (in memory)
function DataManager.GetData(player: Player): any?
    return DataManager._playerData[player]
end

-- Remove player data from memory (call after final save on leave)
function DataManager.RemoveData(player: Player)
    DataManager._playerData[player] = nil
end

-- Auto-save all players periodically
function DataManager.StartAutoSave()
    task.spawn(function()
        while true do
            task.wait(GameConfig.AUTO_SAVE_INTERVAL)
            for _, player in Players:GetPlayers() do
                if DataManager._playerData[player] then
                    DataManager.SaveData(player)
                end
            end
        end
    end)
end

return DataManager
