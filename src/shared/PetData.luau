--[[
    PetData.luau
    All pet definitions for Hatch Legends
    Each pet has: name, rarity, power, zone
]]

local PetData = {}

PetData.Pets = {
    -- ============ GRASSLANDS ============
    { name = "Bunny",       rarity = "Common",    power = 1,    zone = "Grasslands" },
    { name = "Chick",       rarity = "Common",    power = 1,    zone = "Grasslands" },
    { name = "Frog",        rarity = "Uncommon",  power = 3,    zone = "Grasslands" },
    { name = "Fox",         rarity = "Rare",      power = 8,    zone = "Grasslands" },
    { name = "Unicorn",     rarity = "Epic",      power = 25,   zone = "Grasslands" },
    { name = "Phoenix",     rarity = "Legendary", power = 100,  zone = "Grasslands" },
    { name = "Rainbow Dragon", rarity = "Mythic", power = 500,  zone = "Grasslands" },

    -- ============ CRYSTAL CAVES ============
    { name = "Crystal Bat",   rarity = "Common",    power = 5,    zone = "Crystal Caves" },
    { name = "Gem Turtle",    rarity = "Common",    power = 5,    zone = "Crystal Caves" },
    { name = "Amethyst Cat",  rarity = "Uncommon",  power = 15,   zone = "Crystal Caves" },
    { name = "Diamond Dog",   rarity = "Rare",      power = 40,   zone = "Crystal Caves" },
    { name = "Sapphire Owl",  rarity = "Epic",      power = 120,  zone = "Crystal Caves" },
    { name = "Emerald Hydra", rarity = "Legendary", power = 500,  zone = "Crystal Caves" },
    { name = "Crystal Titan", rarity = "Mythic",    power = 2500, zone = "Crystal Caves" },

    -- ============ VOLCANO ============
    { name = "Magma Slug",    rarity = "Common",    power = 25,    zone = "Volcano" },
    { name = "Fire Lizard",   rarity = "Common",    power = 25,    zone = "Volcano" },
    { name = "Lava Hound",    rarity = "Uncommon",  power = 75,    zone = "Volcano" },
    { name = "Inferno Tiger", rarity = "Rare",      power = 200,   zone = "Volcano" },
    { name = "Blaze Raptor",  rarity = "Epic",      power = 600,   zone = "Volcano" },
    { name = "Molten Serpent", rarity = "Legendary", power = 2500,  zone = "Volcano" },
    { name = "Volcano Lord",  rarity = "Mythic",    power = 12500, zone = "Volcano" },

    -- ============ SKY ISLANDS ============
    { name = "Cloud Bunny",    rarity = "Common",    power = 125,    zone = "Sky Islands" },
    { name = "Wind Sprite",    rarity = "Common",    power = 125,    zone = "Sky Islands" },
    { name = "Storm Eagle",    rarity = "Uncommon",  power = 375,    zone = "Sky Islands" },
    { name = "Thunder Wolf",   rarity = "Rare",      power = 1000,   zone = "Sky Islands" },
    { name = "Sky Leviathan",  rarity = "Epic",      power = 3000,   zone = "Sky Islands" },
    { name = "Celestial Lion", rarity = "Legendary", power = 12500,  zone = "Sky Islands" },
    { name = "Galaxy Pegasus", rarity = "Mythic",    power = 62500,  zone = "Sky Islands" },

    -- ============ SHADOW REALM ============
    { name = "Shadow Rat",      rarity = "Common",    power = 625,    zone = "Shadow Realm" },
    { name = "Dark Wisp",       rarity = "Common",    power = 625,    zone = "Shadow Realm" },
    { name = "Void Walker",     rarity = "Uncommon",  power = 1875,   zone = "Shadow Realm" },
    { name = "Nightmare Steed", rarity = "Rare",      power = 5000,   zone = "Shadow Realm" },
    { name = "Abyssal Kraken",  rarity = "Epic",      power = 15000,  zone = "Shadow Realm" },
    { name = "Reaper Dragon",   rarity = "Legendary", power = 62500,  zone = "Shadow Realm" },
    { name = "Eternal Deity",   rarity = "Mythic",    power = 312500, zone = "Shadow Realm" },
}

-- Build a lookup by name for quick access
PetData.ByName = {}
for _, pet in PetData.Pets do
    PetData.ByName[pet.name] = pet
end

-- Build a lookup by zone
PetData.ByZone = {}
for _, pet in PetData.Pets do
    if not PetData.ByZone[pet.zone] then
        PetData.ByZone[pet.zone] = {}
    end
    table.insert(PetData.ByZone[pet.zone], pet)
end

return PetData
