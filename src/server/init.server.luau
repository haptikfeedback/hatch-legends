--[[
    init.server.luau
    Main server bootstrap for Hatch Legends
    Creates RemoteEvents/RemoteFunctions and initializes all managers
    Generates the world and sets up all interactions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EggData = require(Shared:WaitForChild("EggData"))

-- Require server managers
local DataManager = require(script:WaitForChild("DataManager"))
local PetManager = require(script:WaitForChild("PetManager"))
local EconomyManager = require(script:WaitForChild("EconomyManager"))
local ShopManager = require(script:WaitForChild("ShopManager"))
local CodeManager = require(script:WaitForChild("CodeManager"))
local MapBuilder = require(script:WaitForChild("MapBuilder"))
local WorldHandler = require(script:WaitForChild("WorldHandler"))
local LeaderboardManager = require(script:WaitForChild("LeaderboardManager"))

-- Initialize managers with dependencies
PetManager.Init(DataManager)
EconomyManager.Init(DataManager, PetManager)
ShopManager.Init(DataManager, EconomyManager)
CodeManager.Init(DataManager, EconomyManager, ShopManager)
WorldHandler.Init(DataManager, PetManager, EconomyManager, ShopManager)
LeaderboardManager.Init(DataManager)

------------------------------------------------------------
-- GENERATE THE WORLD
------------------------------------------------------------
MapBuilder.BuildAll()

------------------------------------------------------------
-- CREATE REMOTE EVENTS / FUNCTIONS
------------------------------------------------------------
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

-- Remote Events (server -> client or fire-and-forget)
local function createRemoteEvent(name: string): RemoteEvent
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = Remotes
    return remote
end

-- Remote Functions (client -> server with return value)
local function createRemoteFunction(name: string): RemoteFunction
    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = Remotes
    return remote
end

-- Events
local DataUpdate = createRemoteEvent("DataUpdate")          -- server pushes data to client
local HatchResult = createRemoteEvent("HatchResult")        -- server sends hatched pets to client
local Notification = createRemoteEvent("Notification")      -- server sends notification messages

-- Functions (client invokes, server returns)
local TapCoin = createRemoteFunction("TapCoin")             -- client taps to earn coins
local HatchEgg = createRemoteFunction("HatchEgg")           -- client requests egg hatch
local EquipPet = createRemoteFunction("EquipPet")           -- equip pet by ID
local UnequipPet = createRemoteFunction("UnequipPet")       -- unequip pet by ID
local FusePets = createRemoteFunction("FusePets")           -- fuse 3 pets
local DeletePet = createRemoteFunction("DeletePet")         -- delete/release a pet
local RedeemCode = createRemoteFunction("RedeemCode")       -- redeem promo code
local RequestRebirth = createRemoteFunction("RequestRebirth") -- request rebirth
local UnlockZone = createRemoteFunction("UnlockZone")       -- unlock a zone
local GetPlayerData = createRemoteFunction("GetPlayerData")  -- client requests full data
local PromptPurchase = createRemoteEvent("PromptPurchase")  -- client requests shop purchase

------------------------------------------------------------
-- REMOTE FUNCTION HANDLERS
------------------------------------------------------------

-- Tap to earn coins
TapCoin.OnServerInvoke = function(player: Player)
    local earned = EconomyManager.OnTap(player)
    local data = DataManager.GetData(player)
    return earned, data and data.coins or 0
end

-- Hatch an egg (via UI button — ProximityPrompt hatching is in WorldHandler)
HatchEgg.OnServerInvoke = function(player: Player, eggName: string)
    if type(eggName) ~= "string" then return nil end

    local useLucky = ShopManager.HasLuckyEgg(player)
    local pets = PetManager.HatchEgg(player, eggName, useLucky)

    if useLucky and pets and #pets > 0 then
        ShopManager.ConsumeLuckyEgg(player)
    end

    if pets then
        local data = DataManager.GetData(player)
        if data then
            DataUpdate:FireClient(player, data)
        end
    end

    return pets
end

-- Equip pet
EquipPet.OnServerInvoke = function(player: Player, petId: string)
    if type(petId) ~= "string" then return false end
    local success = PetManager.EquipPet(player, petId)
    if success then
        local data = DataManager.GetData(player)
        if data then DataUpdate:FireClient(player, data) end
    end
    return success
end

-- Unequip pet
UnequipPet.OnServerInvoke = function(player: Player, petId: string)
    if type(petId) ~= "string" then return false end
    local success = PetManager.UnequipPet(player, petId)
    if success then
        local data = DataManager.GetData(player)
        if data then DataUpdate:FireClient(player, data) end
    end
    return success
end

-- Fuse pets
FusePets.OnServerInvoke = function(player: Player, petIds: any)
    if type(petIds) ~= "table" then return nil end
    local newPet = PetManager.FusePets(player, petIds)
    if newPet then
        local data = DataManager.GetData(player)
        if data then DataUpdate:FireClient(player, data) end
    end
    return newPet
end

-- Delete pet
DeletePet.OnServerInvoke = function(player: Player, petId: string)
    if type(petId) ~= "string" then return false end
    local success = PetManager.DeletePet(player, petId)
    if success then
        local data = DataManager.GetData(player)
        if data then DataUpdate:FireClient(player, data) end
    end
    return success
end

-- Redeem code
RedeemCode.OnServerInvoke = function(player: Player, code: string)
    if type(code) ~= "string" then return false, "Invalid code." end
    local success, message = CodeManager.RedeemCode(player, code)
    if success then
        local data = DataManager.GetData(player)
        if data then DataUpdate:FireClient(player, data) end
    end
    return success, message
end

-- Rebirth
RequestRebirth.OnServerInvoke = function(player: Player)
    local success = EconomyManager.Rebirth(player, false)
    if success then
        local data = DataManager.GetData(player)
        if data then
            DataUpdate:FireClient(player, data)
        end
        Notification:FireClient(player, "🔄 REBIRTH " .. tostring(data.rebirths) .. "! You're getting stronger! 💪")
    end
    return success
end

-- Unlock zone
UnlockZone.OnServerInvoke = function(player: Player, zoneName: string)
    if type(zoneName) ~= "string" then return false end
    local success = EconomyManager.UnlockZone(player, zoneName)
    if success then
        local data = DataManager.GetData(player)
        if data then DataUpdate:FireClient(player, data) end
        Notification:FireClient(player, "🌟 NEW ZONE UNLOCKED: " .. zoneName .. "! 🎉")
    end
    return success
end

-- Get player data on demand
GetPlayerData.OnServerInvoke = function(player: Player)
    return DataManager.GetData(player)
end

------------------------------------------------------------
-- SHOP PURCHASE HANDLER
------------------------------------------------------------
PromptPurchase.OnServerEvent:Connect(function(player: Player, purchaseType: string, purchaseKey: string)
    if type(purchaseType) ~= "string" or type(purchaseKey) ~= "string" then return end
    if purchaseType == "GamePass" then
        ShopManager.PromptGamePass(player, purchaseKey)
    elseif purchaseType == "DevProduct" then
        ShopManager.PromptDevProduct(player, purchaseKey)
    end
end)

------------------------------------------------------------
-- PLAYER LIFECYCLE
------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
    local success, data = DataManager.LoadData(player)
    if not success then
        Notification:FireClient(player, "⚠️ Could not load your save. Progress may not save!")
    end
    DataUpdate:FireClient(player, data)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    DataManager.SaveData(player)
    ShopManager.OnPlayerLeaving(player)
    DataManager.RemoveData(player)
end)

game:BindToClose(function()
    for _, player in Players:GetPlayers() do
        DataManager.SaveData(player)
    end
end)

------------------------------------------------------------
-- START ALL SYSTEMS
------------------------------------------------------------
DataManager.StartAutoSave()
EconomyManager.StartPassiveEarning()
ShopManager.SetupProcessReceipt()
ShopManager.SetupGamePassListener()
WorldHandler.SetupAll()
LeaderboardManager.Start()

print("[Hatch Legends] 🐣 Server initialized! World built! Let's hatch! 🎮")
