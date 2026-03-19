--[[
    CodeManager.luau
    Promo code system for social media growth
    Codes defined in this module, tracks per-player redemption
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local DataManager    -- set via Init
local EconomyManager -- set via Init

local CodeManager = {}

-- Define all active promo codes
-- reward types: "coins", "luckyEgg" (grants lucky egg flag for next hatch)
CodeManager.CODES = {
    ["LAUNCH"] = {
        reward = "coins",
        amount = 500,
        description = "Launch day reward!",
    },
    ["HATCHLEGENDS"] = {
        reward = "coins",
        amount = 1000,
        description = "Thanks for playing Hatch Legends!",
    },
    ["FOLLOWUS"] = {
        reward = "coins",
        amount = 2500,
        description = "Follow us on social media!",
    },
    ["LUCKY2024"] = {
        reward = "luckyEgg",
        amount = 1,
        description = "Free lucky egg!",
    },
    ["REBIRTH"] = {
        reward = "coins",
        amount = 5000,
        description = "Rebirth bonus code!",
    },
}

function CodeManager.Init(dataManager, economyManager, shopManager)
    DataManager = dataManager
    EconomyManager = economyManager
    CodeManager._shopManager = shopManager
end

-- Attempt to redeem a code. Returns success, message
function CodeManager.RedeemCode(player: Player, code: string): (boolean, string)
    local data = DataManager.GetData(player)
    if not data then
        return false, "Data not loaded yet."
    end

    -- Normalize code to uppercase
    code = string.upper(code)

    -- Check if code exists
    local codeDef = CodeManager.CODES[code]
    if not codeDef then
        return false, "Invalid code."
    end

    -- Check if already redeemed
    if table.find(data.redeemedCodes, code) then
        return false, "Already redeemed!"
    end

    -- Grant reward
    if codeDef.reward == "coins" then
        EconomyManager.AddCoins(player, codeDef.amount)
    elseif codeDef.reward == "luckyEgg" then
        if CodeManager._shopManager then
            CodeManager._shopManager._luckyEggPlayers[player] = true
        end
    end

    -- Mark as redeemed
    table.insert(data.redeemedCodes, code)

    return true, codeDef.description .. " +" .. (codeDef.reward == "coins" and tostring(codeDef.amount) .. " coins" or "Lucky Egg")
end

return CodeManager
