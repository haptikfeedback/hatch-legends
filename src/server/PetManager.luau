--[[
    PetManager.luau
    Handles pet hatching (weighted random), fusion, equip/unequip
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PetData = require(Shared:WaitForChild("PetData"))
local EggData = require(Shared:WaitForChild("EggData"))

local DataManager -- set via Init to avoid circular require

local PetManager = {}

function PetManager.Init(dataManager)
    DataManager = dataManager
end

-- Weighted random selection from a loot table
-- Returns the petName selected
function PetManager.RollPet(lootTable: { any }, player: Player?): string
    -- Check if player has Lucky game pass (boosts rare+ weights)
    local hasLucky = false
    if player then
        local ok, result = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GAME_PASSES.Lucky.id)
        end)
        if ok and result then
            hasLucky = true
        end
    end

    -- Build adjusted weights
    local adjustedTable = {}
    local totalWeight = 0

    for _, entry in lootTable do
        local pet = PetData.ByName[entry.petName]
        local weight = entry.weight

        -- If player has Lucky pass, boost Rare+ weights
        if hasLucky and pet then
            local rarityIndex = table.find(GameConfig.RARITY_ORDER, pet.rarity)
            if rarityIndex and rarityIndex >= 3 then -- Rare is index 3
                weight = weight * GameConfig.LUCKY_RARITY_BOOST
            end
        end

        totalWeight += weight
        table.insert(adjustedTable, { petName = entry.petName, weight = weight })
    end

    -- Roll
    local roll = math.random() * totalWeight
    local cumulative = 0

    for _, entry in adjustedTable do
        cumulative += entry.weight
        if roll <= cumulative then
            return entry.petName
        end
    end

    -- Fallback (should never happen)
    return adjustedTable[1].petName
end

-- Create a pet instance from a definition
function PetManager.CreatePetInstance(petName: string): any
    local def = PetData.ByName[petName]
    if not def then
        warn("[PetManager] Unknown pet: " .. petName)
        return nil
    end

    return {
        id = HttpService:GenerateGUID(false),
        name = def.name,
        rarity = def.rarity,
        power = def.power,
        zone = def.zone,
        equipped = false,
    }
end

-- Hatch an egg for a player. Returns list of hatched pets (1 or 3 for triple hatch)
function PetManager.HatchEgg(player: Player, eggName: string, useLuckyEgg: boolean?): { any }?
    local data = DataManager.GetData(player)
    if not data then return nil end

    local eggDef = EggData.ByName[eggName]
    if not eggDef then
        warn("[PetManager] Unknown egg: " .. eggName)
        return nil
    end

    -- Check zone unlock
    if not table.find(data.unlockedZones, eggDef.zone) then
        return nil
    end

    -- Check cost
    if data.coins < eggDef.cost then
        return nil
    end

    -- Determine hatch count (triple hatch pass)
    local hatchCount = 1
    local hasTriple = false
    do
        local ok, result = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GAME_PASSES.TripleHatch.id)
        end)
        if ok and result then
            hasTriple = true
            hatchCount = 3
        end
    end

    -- Deduct cost (only once even for triple hatch — that's the value of the pass)
    data.coins -= eggDef.cost

    -- Roll pets
    local hatchedPets = {}
    for i = 1, hatchCount do
        local petName

        -- Lucky Egg dev product: guaranteed Rare+
        if useLuckyEgg and i == 1 then
            -- Filter loot table to Rare+ only
            local rareTable = {}
            for _, entry in eggDef.lootTable do
                local pet = PetData.ByName[entry.petName]
                if pet then
                    local rarityIndex = table.find(GameConfig.RARITY_ORDER, pet.rarity)
                    if rarityIndex and rarityIndex >= 3 then
                        table.insert(rareTable, entry)
                    end
                end
            end
            if #rareTable > 0 then
                petName = PetManager.RollPet(rareTable, player)
            else
                petName = PetManager.RollPet(eggDef.lootTable, player)
            end
        else
            petName = PetManager.RollPet(eggDef.lootTable, player)
        end

        local petInstance = PetManager.CreatePetInstance(petName)
        if petInstance then
            table.insert(data.pets, petInstance)
            table.insert(hatchedPets, petInstance)

            -- Update pet index (collection)
            if not table.find(data.petIndex, petName) then
                table.insert(data.petIndex, petName)
            end
        end
    end

    return hatchedPets
end

-- Equip a pet by ID
function PetManager.EquipPet(player: Player, petId: string): boolean
    local data = DataManager.GetData(player)
    if not data then return false end

    -- Count currently equipped
    local equippedCount = 0
    local targetPet = nil
    for _, pet in data.pets do
        if pet.equipped then
            equippedCount += 1
        end
        if pet.id == petId then
            targetPet = pet
        end
    end

    if not targetPet then return false end
    if targetPet.equipped then return false end -- already equipped

    -- Check slot limit
    local maxSlots = GameConfig.BASE_PET_SLOTS
    local ok, hasExtraSlot = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GAME_PASSES.ExtraPetSlot.id)
    end)
    if ok and hasExtraSlot then
        maxSlots = GameConfig.MAX_PET_SLOTS
    end

    if equippedCount >= maxSlots then
        return false
    end

    targetPet.equipped = true
    return true
end

-- Unequip a pet by ID
function PetManager.UnequipPet(player: Player, petId: string): boolean
    local data = DataManager.GetData(player)
    if not data then return false end

    for _, pet in data.pets do
        if pet.id == petId then
            pet.equipped = false
            return true
        end
    end
    return false
end

-- Fuse 3 pets of same name+rarity into next rarity tier
-- Returns the new pet if successful, nil otherwise
function PetManager.FusePets(player: Player, petIds: { string }): any?
    local data = DataManager.GetData(player)
    if not data then return nil end

    if #petIds ~= GameConfig.FUSION_COUNT then
        return nil
    end

    -- Find the pets and validate they're the same name and rarity
    local fusionPets = {}
    for _, id in petIds do
        for _, pet in data.pets do
            if pet.id == id then
                table.insert(fusionPets, pet)
                break
            end
        end
    end

    if #fusionPets ~= GameConfig.FUSION_COUNT then
        return nil
    end

    local baseName = fusionPets[1].name
    local baseRarity = fusionPets[1].rarity
    for _, pet in fusionPets do
        if pet.name ~= baseName or pet.rarity ~= baseRarity then
            return nil -- not all same
        end
    end

    -- Find next rarity tier
    local currentIndex = table.find(GameConfig.RARITY_ORDER, baseRarity)
    if not currentIndex or currentIndex >= #GameConfig.RARITY_ORDER then
        return nil -- already max rarity
    end
    local nextRarity = GameConfig.RARITY_ORDER[currentIndex + 1]

    -- Check if a pet of this name exists at next rarity (it might not for all combos)
    -- We'll create a upgraded version with boosted power
    local baseDef = PetData.ByName[baseName]
    if not baseDef then return nil end

    -- Remove the 3 sacrificed pets
    for _, fusePet in fusionPets do
        fusePet.equipped = false
        for i, pet in data.pets do
            if pet.id == fusePet.id then
                table.remove(data.pets, i)
                break
            end
        end
    end

    -- Create upgraded pet
    local newPet = {
        id = HttpService:GenerateGUID(false),
        name = baseName,
        rarity = nextRarity,
        power = baseDef.power * 3, -- 3x power for fused pet
        zone = baseDef.zone,
        equipped = false,
    }

    table.insert(data.pets, newPet)

    -- Update collection
    local fusedKey = baseName -- same name, just different rarity
    if not table.find(data.petIndex, fusedKey) then
        table.insert(data.petIndex, fusedKey)
    end

    return newPet
end

-- Delete/release a pet
function PetManager.DeletePet(player: Player, petId: string): boolean
    local data = DataManager.GetData(player)
    if not data then return false end

    for i, pet in data.pets do
        if pet.id == petId then
            table.remove(data.pets, i)
            return true
        end
    end
    return false
end

-- Get total power of equipped pets
function PetManager.GetEquippedPower(player: Player): number
    local data = DataManager.GetData(player)
    if not data then return 0 end

    local totalPower = 0
    for _, pet in data.pets do
        if pet.equipped then
            totalPower += pet.power
        end
    end
    return totalPower
end

return PetManager
