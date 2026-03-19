--[[
    Types.luau
    Type definitions for Hatch Legends
    Shared between server and client via ReplicatedStorage
]]

export type Pet = {
    id: string,
    name: string,
    rarity: string,
    power: number,
    zone: string,
    equipped: boolean,
}

export type PetDefinition = {
    name: string,
    rarity: string,
    power: number,
    zone: string,
}

export type EggLootEntry = {
    petName: string,
    weight: number,
}

export type EggDefinition = {
    name: string,
    cost: number,
    zone: string,
    lootTable: { EggLootEntry },
}

export type GamePassDef = {
    name: string,
    id: number,
    robuxPrice: number,
    description: string,
}

export type DevProductDef = {
    name: string,
    id: number,
    robuxPrice: number,
    description: string,
}

export type PlayerData = {
    coins: number,
    totalCoins: number,
    rebirths: number,
    pets: { Pet },
    petIndex: { string },
    unlockedZones: { string },
    redeemedCodes: { string },
    joinDate: number,
    lastSave: number,
}

return nil
