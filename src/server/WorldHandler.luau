--[[
    WorldHandler.luau
    Handles world interactions: bounce pads, teleport pads, kill plane,
    egg ProximityPrompt hatching, and egg bobbing animation
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EggData = require(Shared:WaitForChild("EggData"))

local DataManager    -- set via Init
local PetManager     -- set via Init
local EconomyManager -- set via Init
local ShopManager    -- set via Init

local WorldHandler = {}

function WorldHandler.Init(dataManager, petManager, economyManager, shopManager)
    DataManager = dataManager
    PetManager = petManager
    EconomyManager = economyManager
    ShopManager = shopManager
end

------------------------------------------------------------
-- BOUNCE PADS
------------------------------------------------------------

function WorldHandler.SetupBouncePads()
    -- Find all bounce pads and connect touch events
    local function setupPad(part)
        if not part:FindFirstChild("IsBouncePad") then return end

        part.Touched:Connect(function(hit)
            local character = hit.Parent
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if humanoid and rootPart then
                -- Launch the player upward! Kids love this.
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(0, 100000, 0)
                bodyVelocity.Velocity = Vector3.new(0, 80, 0)
                bodyVelocity.Parent = rootPart

                task.delay(0.3, function()
                    if bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                    end
                end)
            end
        end)
    end

    -- Setup existing pads and watch for new ones
    for _, desc in Workspace:GetDescendants() do
        setupPad(desc)
    end
    Workspace.DescendantAdded:Connect(setupPad)
end

------------------------------------------------------------
-- TELEPORT PADS
------------------------------------------------------------

function WorldHandler.SetupTeleportPads()
    local function setupTelepad(part)
        local dest = part:FindFirstChild("Destination")
        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
        if not dest or not prompt then return end

        prompt.Triggered:Connect(function(player)
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            -- Check if player has unlocked the required zone
            local reqZone = part:FindFirstChild("RequiredZone")
            if reqZone then
                local data = DataManager.GetData(player)
                if data and not table.find(data.unlockedZones, reqZone.Value) then
                    -- Notify player they need to unlock this zone
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then
                        local notif = remotes:FindFirstChild("Notification")
                        if notif then
                            notif:FireClient(player, "🔒 Unlock " .. reqZone.Value .. " first!")
                        end
                    end
                    return
                end
            end

            -- Teleport with a brief visual flash
            rootPart.CFrame = CFrame.new(dest.Value)
        end)
    end

    for _, desc in Workspace:GetDescendants() do
        if desc:IsA("Part") and desc:FindFirstChild("Destination") then
            setupTelepad(desc)
        end
    end
    Workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("Part") and desc:FindFirstChild("Destination") then
            task.wait() -- wait for children to load
            setupTelepad(desc)
        end
    end)
end

------------------------------------------------------------
-- EGG PROXIMITY PROMPT HATCHING
------------------------------------------------------------

function WorldHandler.SetupEggPrompts()
    local function setupEgg(part)
        local zoneTag = part:FindFirstChild("ZoneName")
        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
        if not zoneTag or not prompt then return end

        -- Map zone name to egg name
        local eggNameMap = {}
        for _, egg in EggData.Eggs do
            eggNameMap[egg.zone] = egg.name
        end

        prompt.Triggered:Connect(function(player)
            local eggName = eggNameMap[zoneTag.Value]
            if not eggName then return end

            -- Check for lucky egg
            local useLucky = ShopManager.HasLuckyEgg(player)

            local pets = PetManager.HatchEgg(player, eggName, useLucky)

            if useLucky and pets and #pets > 0 then
                ShopManager.ConsumeLuckyEgg(player)
            end

            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end

            if pets and #pets > 0 then
                -- Send data update
                local updateEvent = remotes:FindFirstChild("DataUpdate")
                local data = DataManager.GetData(player)
                if updateEvent and data then
                    updateEvent:FireClient(player, data)
                end

                -- Send hatch notification with fun messages
                local notif = remotes:FindFirstChild("Notification")
                if notif then
                    for _, pet in pets do
                        local rarityEmojis = {
                            Common = "⭐",
                            Uncommon = "⭐⭐",
                            Rare = "💎",
                            Epic = "💜",
                            Legendary = "🌟",
                            Mythic = "🔥🔥🔥",
                        }
                        local emoji = rarityEmojis[pet.rarity] or "⭐"
                        notif:FireClient(player, "🐣 " .. emoji .. " " .. pet.name .. " (" .. pet.rarity .. ") Power: " .. pet.power)
                    end
                end
            else
                -- Can't hatch - tell them why
                local notif = remotes:FindFirstChild("Notification")
                if notif then
                    local data = DataManager.GetData(player)
                    if data then
                        local egg = EggData.ByName[eggName]
                        if egg and not table.find(data.unlockedZones, egg.zone) then
                            notif:FireClient(player, "🔒 You need to unlock " .. egg.zone .. " first!")
                        elseif egg and data.coins < egg.cost then
                            notif:FireClient(player, "💰 Need " .. tostring(egg.cost) .. " coins! You have " .. tostring(data.coins))
                        else
                            notif:FireClient(player, "❌ Can't hatch right now!")
                        end
                    end
                end
            end
        end)
    end

    for _, desc in Workspace:GetDescendants() do
        if desc.Name == "Egg" and desc:FindFirstChild("ZoneName") then
            setupEgg(desc)
        end
    end
    Workspace.DescendantAdded:Connect(function(desc)
        if desc.Name == "Egg" and desc:FindFirstChild("ZoneName") then
            task.wait()
            setupEgg(desc)
        end
    end)
end

------------------------------------------------------------
-- EGG BOBBING ANIMATION (makes eggs float up and down)
------------------------------------------------------------

function WorldHandler.SetupEggAnimation()
    local eggs = {}

    local function registerEgg(part)
        if part.Name == "Egg" and part:FindFirstChild("ZoneName") then
            table.insert(eggs, {
                part = part,
                baseY = part.Position.Y,
                offset = math.random() * math.pi * 2, -- random phase offset
            })
        end
    end

    for _, desc in Workspace:GetDescendants() do
        registerEgg(desc)
    end
    Workspace.DescendantAdded:Connect(registerEgg)

    -- Animate eggs
    RunService.Heartbeat:Connect(function()
        local t = tick()
        for _, eggInfo in eggs do
            if eggInfo.part and eggInfo.part.Parent then
                local newY = eggInfo.baseY + math.sin(t * 2 + eggInfo.offset) * 1.5
                eggInfo.part.Position = Vector3.new(
                    eggInfo.part.Position.X,
                    newY,
                    eggInfo.part.Position.Z
                )
            end
        end
    end)
end

------------------------------------------------------------
-- KILL PLANE
------------------------------------------------------------

function WorldHandler.SetupKillPlane()
    RunService.Heartbeat:Connect(function()
        for _, player in Players:GetPlayers() do
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart and rootPart.Position.Y < -40 then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end
    end)
end

------------------------------------------------------------
-- SETUP ALL
------------------------------------------------------------

function WorldHandler.SetupAll()
    WorldHandler.SetupBouncePads()
    WorldHandler.SetupTeleportPads()
    WorldHandler.SetupEggPrompts()
    WorldHandler.SetupEggAnimation()
    WorldHandler.SetupKillPlane()
    print("[WorldHandler] 🎮 All world interactions ready!")
end

return WorldHandler
