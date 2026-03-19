--[[
    LeaderboardManager.luau
    In-game leaderboards using OrderedDataStore
    Shows: Top Coins, Top Rebirths, Top Pet Power
    Updates periodically, displays on physical leaderboard in spawn area
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataManager -- set via Init

local LeaderboardManager = {}

LeaderboardManager._boards = {
    {
        name = "💰 Top Coins",
        store = DataStoreService:GetOrderedDataStore("Leaderboard_Coins"),
        stat = "totalCoins",
    },
    {
        name = "🔄 Top Rebirths",
        store = DataStoreService:GetOrderedDataStore("Leaderboard_Rebirths"),
        stat = "rebirths",
    },
}

function LeaderboardManager.Init(dataManager)
    DataManager = dataManager
end

-- Update all leaderboard stores with current player stats
function LeaderboardManager._updateStores()
    for _, player in Players:GetPlayers() do
        local data = DataManager.GetData(player)
        if data then
            for _, board in LeaderboardManager._boards do
                local value = data[board.stat]
                if value and value > 0 then
                    local ok, err = pcall(function()
                        board.store:SetAsync(tostring(player.UserId), value)
                    end)
                    if not ok then
                        warn("[LeaderboardManager] Failed to update " .. board.name .. ": " .. tostring(err))
                    end
                end
            end
        end
    end
end

-- Create in-game leaderboard SurfaceGuis
function LeaderboardManager._createDisplays()
    local Workspace = game:GetService("Workspace")
    local mapFolder = Workspace:FindFirstChild("HatchLegendsMap")
    if not mapFolder then return end
    local spawnArea = mapFolder:FindFirstChild("SpawnArea")
    if not spawnArea then return end

    for i, board in LeaderboardManager._boards do
        -- Physical leaderboard part
        local part = Instance.new("Part")
        part.Name = "Leaderboard_" .. i
        part.Size = Vector3.new(10, 14, 1)
        part.Position = Vector3.new(-15 + (i - 1) * 15, 10, -105)
        part.Color = Color3.fromRGB(30, 30, 50)
        part.Material = Enum.Material.SmoothPlastic
        part.Anchored = true
        part.CanCollide = true
        part.Parent = spawnArea

        local corner = Instance.new("UICorner")

        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.Parent = part

        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0.12, 0)
        title.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        title.TextColor3 = Color3.fromRGB(0, 0, 0)
        title.Text = board.name
        title.Font = Enum.Font.FredokaOne
        title.TextScaled = true
        title.Parent = surfaceGui

        -- Entries container
        local entriesFrame = Instance.new("Frame")
        entriesFrame.Name = "Entries"
        entriesFrame.Size = UDim2.new(1, 0, 0.88, 0)
        entriesFrame.Position = UDim2.new(0, 0, 0.12, 0)
        entriesFrame.BackgroundTransparency = 1
        entriesFrame.Parent = surfaceGui

        local layout = Instance.new("UIListLayout")
        layout.Parent = entriesFrame

        -- 10 entry slots
        for rank = 1, 10 do
            local entry = Instance.new("TextLabel")
            entry.Name = "Entry_" .. rank
            entry.Size = UDim2.new(1, 0, 0.1, 0)
            entry.BackgroundTransparency = rank % 2 == 0 and 0.8 or 0.9
            entry.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
            entry.TextColor3 = rank <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
            entry.Text = "#" .. rank .. " ---"
            entry.Font = Enum.Font.GothamBold
            entry.TextScaled = true
            entry.Parent = entriesFrame
        end

        board._display = surfaceGui
    end
end

-- Refresh leaderboard displays with latest data
function LeaderboardManager._refreshDisplays()
    for _, board in LeaderboardManager._boards do
        if not board._display then continue end

        local ok, pages = pcall(function()
            return board.store:GetSortedAsync(false, 10)
        end)

        if ok and pages then
            local entries = pages:GetCurrentPage()
            local entriesFrame = board._display:FindFirstChild("Entries")
            if not entriesFrame then continue end

            for rank = 1, 10 do
                local label = entriesFrame:FindFirstChild("Entry_" .. rank)
                if not label then continue end

                if entries[rank] then
                    local userId = tonumber(entries[rank].key)
                    local value = entries[rank].value
                    local playerName = "[Unknown]"

                    if userId then
                        local nameOk, name = pcall(function()
                            return Players:GetNameFromUserIdAsync(userId)
                        end)
                        if nameOk then
                            playerName = name
                        end
                    end

                    local medals = { "🥇", "🥈", "🥉" }
                    local prefix = rank <= 3 and medals[rank] or ("#" .. rank)
                    label.Text = prefix .. " " .. playerName .. " - " .. tostring(value)
                else
                    label.Text = "#" .. rank .. " ---"
                end
            end
        end
    end
end

-- Start periodic updates
function LeaderboardManager.Start()
    -- Wait for map to generate
    task.wait(3)
    LeaderboardManager._createDisplays()

    task.spawn(function()
        while true do
            LeaderboardManager._updateStores()
            task.wait(5)
            LeaderboardManager._refreshDisplays()
            task.wait(55) -- Update every 60 seconds total
        end
    end)

    print("[LeaderboardManager] 📊 Leaderboards active!")
end

return LeaderboardManager
