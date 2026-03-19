--[[
    EggData.luau
    Egg definitions with loot tables
    Weights correspond to: Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 0.9%, Mythic 0.1%
]]

local EggData = {}

EggData.Eggs = {
    {
        name = "Grassland Egg",
        cost = 100,
        zone = "Grasslands",
        lootTable = {
            { petName = "Bunny",          weight = 30 },
            { petName = "Chick",          weight = 30 },
            { petName = "Frog",           weight = 25 },
            { petName = "Fox",            weight = 10 },
            { petName = "Unicorn",        weight = 4 },
            { petName = "Phoenix",        weight = 0.9 },
            { petName = "Rainbow Dragon", weight = 0.1 },
        },
    },
    {
        name = "Crystal Egg",
        cost = 5000,
        zone = "Crystal Caves",
        lootTable = {
            { petName = "Crystal Bat",   weight = 30 },
            { petName = "Gem Turtle",    weight = 30 },
            { petName = "Amethyst Cat",  weight = 25 },
            { petName = "Diamond Dog",   weight = 10 },
            { petName = "Sapphire Owl",  weight = 4 },
            { petName = "Emerald Hydra", weight = 0.9 },
            { petName = "Crystal Titan", weight = 0.1 },
        },
    },
    {
        name = "Volcano Egg",
        cost = 50000,
        zone = "Volcano",
        lootTable = {
            { petName = "Magma Slug",    weight = 30 },
            { petName = "Fire Lizard",   weight = 30 },
            { petName = "Lava Hound",    weight = 25 },
            { petName = "Inferno Tiger", weight = 10 },
            { petName = "Blaze Raptor",  weight = 4 },
            { petName = "Molten Serpent",weight = 0.9 },
            { petName = "Volcano Lord",  weight = 0.1 },
        },
    },
    {
        name = "Sky Egg",
        cost = 500000,
        zone = "Sky Islands",
        lootTable = {
            { petName = "Cloud Bunny",    weight = 30 },
            { petName = "Wind Sprite",    weight = 30 },
            { petName = "Storm Eagle",    weight = 25 },
            { petName = "Thunder Wolf",   weight = 10 },
            { petName = "Sky Leviathan",  weight = 4 },
            { petName = "Celestial Lion", weight = 0.9 },
            { petName = "Galaxy Pegasus", weight = 0.1 },
        },
    },
    {
        name = "Shadow Egg",
        cost = 5000000,
        zone = "Shadow Realm",
        lootTable = {
            { petName = "Shadow Rat",      weight = 30 },
            { petName = "Dark Wisp",       weight = 30 },
            { petName = "Void Walker",     weight = 25 },
            { petName = "Nightmare Steed", weight = 10 },
            { petName = "Abyssal Kraken",  weight = 4 },
            { petName = "Reaper Dragon",   weight = 0.9 },
            { petName = "Eternal Deity",   weight = 0.1 },
        },
    },
}

-- Build lookup by name
EggData.ByName = {}
for _, egg in EggData.Eggs do
    EggData.ByName[egg.name] = egg
end

-- Build lookup by zone
EggData.ByZone = {}
for _, egg in EggData.Eggs do
    EggData.ByZone[egg.zone] = egg
end

return EggData
