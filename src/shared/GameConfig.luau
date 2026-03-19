--[[
    GameConfig.luau
    All tuning constants for Hatch Legends
]]

local GameConfig = {}

-- Coin earning
GameConfig.BASE_COINS_PER_TAP = 1
GameConfig.AFK_EARN_RATE = 0.25         -- multiplier vs active earning
GameConfig.AFK_TICK_INTERVAL = 1        -- seconds between passive ticks

-- Rebirth
GameConfig.REBIRTH_BASE_COST = 10000    -- coins needed for first rebirth
GameConfig.REBIRTH_COST_MULTIPLIER = 2.5 -- each rebirth costs this much more
GameConfig.REBIRTH_BONUS_PER = 0.25     -- +25% multiplier per rebirth

-- Pet equip slots
GameConfig.BASE_PET_SLOTS = 3
GameConfig.EXTRA_SLOT_PER_PASS = 1      -- Extra Pet Slot pass adds this many (stackable up to 3 purchases conceptually, but game pass = 1 purchase)
GameConfig.MAX_PET_SLOTS = 6

-- Pet fusion: combine 3 of same name+rarity -> next rarity
GameConfig.FUSION_COUNT = 3

-- Zone unlock costs (coins required)
GameConfig.ZONE_UNLOCK_COSTS = {
    Grasslands = 0,
    ["Crystal Caves"] = 10000,
    Volcano = 100000,
    ["Sky Islands"] = 1000000,
    ["Shadow Realm"] = -1, -- special: requires rebirth 5
}
GameConfig.SHADOW_REALM_REBIRTH_REQ = 5

-- VIP multiplier
GameConfig.VIP_MULTIPLIER = 2.0
-- Lucky pass rarity boost
GameConfig.LUCKY_RARITY_BOOST = 1.5     -- 50% more chance for rare+

-- Rarity order (ascending)
GameConfig.RARITY_ORDER = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"
}

-- Rarity colors for UI
GameConfig.RARITY_COLORS = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(76, 175, 80),
    Rare = Color3.fromRGB(33, 150, 243),
    Epic = Color3.fromRGB(156, 39, 176),
    Legendary = Color3.fromRGB(255, 193, 7),
    Mythic = Color3.fromRGB(244, 67, 54),
}

-- Game Pass IDs (replace with real IDs after creating in Studio)
GameConfig.GAME_PASSES = {
    VIP         = { id = 100001, robuxPrice = 399, description = "2x coins, VIP badge, gold name" },
    AutoHatch   = { id = 100002, robuxPrice = 149, description = "Automatically hatch eggs" },
    TripleHatch = { id = 100003, robuxPrice = 249, description = "Hatch 3 eggs at once" },
    ExtraPetSlot= { id = 100004, robuxPrice = 99,  description = "Equip up to 6 pets" },
    Lucky       = { id = 100005, robuxPrice = 199, description = "+50% rare pet chance" },
}

-- Developer Product IDs (replace with real IDs after creating in Studio)
GameConfig.DEV_PRODUCTS = {
    Coins1000      = { id = 200001, robuxPrice = 49,  coins = 1000,  description = "1,000 Coins" },
    Coins10000     = { id = 200002, robuxPrice = 399, coins = 10000, description = "10,000 Coins" },
    InstantRebirth = { id = 200003, robuxPrice = 99,  description = "Skip rebirth threshold" },
    LuckyEgg       = { id = 200004, robuxPrice = 149, description = "Next egg guaranteed Rare+" },
}

-- Auto-save interval
GameConfig.AUTO_SAVE_INTERVAL = 60 -- seconds

-- Data store
GameConfig.DATA_STORE_NAME = "HatchLegendsPlayerData_v1"
GameConfig.DATA_STORE_RETRIES = 3

return GameConfig
