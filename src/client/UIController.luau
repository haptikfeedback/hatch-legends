--[[
    UIController.luau
    Creates and manages all game UI
    Mobile-friendly using UDim2 scale values
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EggData = require(Shared:WaitForChild("EggData"))
local PetData = require(Shared:WaitForChild("PetData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIController = {}
UIController._screenGui = nil
UIController._coinLabel = nil
UIController._rebirthLabel = nil
UIController._petInventoryFrame = nil
UIController._shopFrame = nil
UIController._codeFrame = nil
UIController._notificationLabel = nil
UIController._currentData = nil

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TapCoin = Remotes:WaitForChild("TapCoin")
local HatchEgg = Remotes:WaitForChild("HatchEgg")
local EquipPet = Remotes:WaitForChild("EquipPet")
local UnequipPet = Remotes:WaitForChild("UnequipPet")
local FusePets = Remotes:WaitForChild("FusePets")
local DeletePet = Remotes:WaitForChild("DeletePet")
local RedeemCode = Remotes:WaitForChild("RedeemCode")
local RequestRebirth = Remotes:WaitForChild("RequestRebirth")
local UnlockZone = Remotes:WaitForChild("UnlockZone")
local GetPlayerData = Remotes:WaitForChild("GetPlayerData")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local HatchResult = Remotes:WaitForChild("HatchResult")
local Notification = Remotes:WaitForChild("Notification")
local PromptPurchase = Remotes:WaitForChild("PromptPurchase")

------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------

local function formatNumber(n: number): string
    if n >= 1000000000 then
        return string.format("%.1fB", n / 1000000000)
    elseif n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(math.floor(n))
end

local function getRarityColor(rarity: string): Color3
    return GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(180, 180, 180)
end

local function createTextButton(parent, text, size, position, bgColor): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(60, 60, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextScaled = true
    btn.AutoButtonColor = true
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingTop = UDim.new(0, 2)
    padding.PaddingBottom = UDim.new(0, 2)
    padding.Parent = btn

    return btn
end

local function createFrame(parent, size, position, bgColor): Frame
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor or Color3.fromRGB(30, 30, 45)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    return frame
end

------------------------------------------------------------
-- BUILD UI
------------------------------------------------------------

function UIController.Init()
    -- Main ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "HatchLegendsUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    UIController._screenGui = gui

    UIController._buildHUD(gui)
    UIController._buildPetInventory(gui)
    UIController._buildShop(gui)
    UIController._buildCodeRedemption(gui)
    UIController._buildEggButtons(gui)
    UIController._buildNotification(gui)

    -- Listen for data updates
    DataUpdate.OnClientEvent:Connect(function(data)
        UIController._currentData = data
        UIController.RefreshAll()
    end)

    -- Listen for notifications
    Notification.OnClientEvent:Connect(function(msg)
        UIController.ShowNotification(msg)
    end)

    -- Listen for hatch results
    HatchResult.OnClientEvent:Connect(function(pets)
        if pets and #pets > 0 then
            for _, pet in pets do
                UIController.ShowNotification("Hatched: " .. pet.name .. " (" .. pet.rarity .. ") ⭐" .. pet.power)
            end
        end
    end)

    -- Request initial data
    task.spawn(function()
        local data = GetPlayerData:InvokeServer()
        if data then
            UIController._currentData = data
            UIController.RefreshAll()
        end
    end)
end

------------------------------------------------------------
-- HUD (top bar: coins, rebirths)
------------------------------------------------------------

function UIController._buildHUD(gui)
    -- Coins display (top left)
    local coinFrame = createFrame(gui, UDim2.new(0.25, 0, 0.05, 0), UDim2.new(0.02, 0, 0.02, 0), Color3.fromRGB(40, 40, 60))

    local coinIcon = Instance.new("TextLabel")
    coinIcon.Size = UDim2.new(0.15, 0, 1, 0)
    coinIcon.Position = UDim2.new(0, 0, 0, 0)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Text = "🪙"
    coinIcon.TextScaled = true
    coinIcon.Parent = coinFrame

    local coinLabel = Instance.new("TextLabel")
    coinLabel.Size = UDim2.new(0.8, 0, 1, 0)
    coinLabel.Position = UDim2.new(0.18, 0, 0, 0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    coinLabel.Text = "0"
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextSize = 18
    coinLabel.TextScaled = true
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinFrame
    UIController._coinLabel = coinLabel

    -- Rebirth display (top right)
    local rebirthFrame = createFrame(gui, UDim2.new(0.15, 0, 0.05, 0), UDim2.new(0.83, 0, 0.02, 0), Color3.fromRGB(60, 30, 60))

    local rebirthLabel = Instance.new("TextLabel")
    rebirthLabel.Size = UDim2.new(1, 0, 1, 0)
    rebirthLabel.BackgroundTransparency = 1
    rebirthLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
    rebirthLabel.Text = "🔄 Rebirth: 0"
    rebirthLabel.Font = Enum.Font.GothamBold
    rebirthLabel.TextSize = 14
    rebirthLabel.TextScaled = true
    rebirthLabel.Parent = rebirthFrame
    UIController._rebirthLabel = rebirthLabel

    -- Rebirth button (below rebirth counter)
    local rebirthBtn = createTextButton(
        gui, "🔄 REBIRTH",
        UDim2.new(0.15, 0, 0.04, 0),
        UDim2.new(0.83, 0, 0.08, 0),
        Color3.fromRGB(120, 40, 120)
    )
    rebirthBtn.MouseButton1Click:Connect(function()
        local success = RequestRebirth:InvokeServer()
        if not success then
            UIController.ShowNotification("Not enough coins to rebirth!")
        end
    end)
end

------------------------------------------------------------
-- EGG BUTTONS (bottom center)
------------------------------------------------------------

function UIController._buildEggButtons(gui)
    local eggContainer = createFrame(gui, UDim2.new(0.6, 0, 0.1, 0), UDim2.new(0.2, 0, 0.88, 0), Color3.fromRGB(30, 30, 50))
    eggContainer.BackgroundTransparency = 0.3

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0.02, 0)
    layout.Parent = eggContainer

    UIController._eggContainer = eggContainer
    UIController._eggButtons = {}

    for _, egg in EggData.Eggs do
        local btn = createTextButton(
            eggContainer,
            "🥚 " .. egg.name .. "\n" .. formatNumber(egg.cost),
            UDim2.new(0.18, 0, 0.85, 0),
            UDim2.new(0, 0, 0, 0),
            Color3.fromRGB(50, 70, 90)
        )
        btn.TextScaled = true
        btn.Name = egg.name

        btn.MouseButton1Click:Connect(function()
            local pets = HatchEgg:InvokeServer(egg.name)
            if pets and #pets > 0 then
                for _, pet in pets do
                    UIController.ShowNotification("🐣 " .. pet.name .. " (" .. pet.rarity .. ") ⭐" .. pet.power)
                end
            else
                UIController.ShowNotification("Can't hatch — check coins or zone unlock!")
            end
        end)

        UIController._eggButtons[egg.name] = btn
    end
end

------------------------------------------------------------
-- TAP BUTTON (center screen)
------------------------------------------------------------

-- Note: Tap input is handled by InputController, not UI. This is just the visual.

------------------------------------------------------------
-- PET INVENTORY (side panel, toggle)
------------------------------------------------------------

function UIController._buildPetInventory(gui)
    -- Toggle button
    local toggleBtn = createTextButton(
        gui, "🐾 Pets",
        UDim2.new(0.08, 0, 0.04, 0),
        UDim2.new(0.02, 0, 0.1, 0),
        Color3.fromRGB(70, 50, 90)
    )

    -- Inventory panel (hidden by default)
    local panel = createFrame(gui, UDim2.new(0.3, 0, 0.7, 0), UDim2.new(-0.31, 0, 0.15, 0), Color3.fromRGB(25, 25, 40))
    panel.ClipsDescendants = true
    UIController._petInventoryFrame = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.06, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "🐾 Pet Inventory"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = panel

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PetScroll"
    scrollFrame.Size = UDim2.new(0.95, 0, 0.9, 0)
    scrollFrame.Position = UDim2.new(0.025, 0, 0.08, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.3, 0, 0, 80)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 6)
    grid.Parent = scrollFrame

    UIController._petScrollFrame = scrollFrame

    -- Toggle animation
    local isOpen = false
    toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetPos = isOpen and UDim2.new(0.02, 0, 0.15, 0) or UDim2.new(-0.31, 0, 0.15, 0)
        TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
    end)
end

function UIController._refreshPetInventory()
    local scroll = UIController._petScrollFrame
    if not scroll then return end

    -- Clear existing
    for _, child in scroll:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local data = UIController._currentData
    if not data or not data.pets then return end

    for _, pet in data.pets do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = getRarityColor(pet.rarity)
        card.BackgroundTransparency = 0.7
        card.BorderSizePixel = 0
        card.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = card

        -- Pet name + rarity
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.95, 0, 0.4, 0)
        nameLabel.Position = UDim2.new(0.025, 0, 0.02, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = getRarityColor(pet.rarity)
        nameLabel.Text = pet.name .. " ⭐" .. pet.power
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card

        -- Rarity label
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(0.95, 0, 0.2, 0)
        rarityLabel.Position = UDim2.new(0.025, 0, 0.38, 0)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        rarityLabel.Text = pet.rarity
        rarityLabel.Font = Enum.Font.Gotham
        rarityLabel.TextSize = 10
        rarityLabel.TextScaled = true
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        rarityLabel.Parent = card

        -- Equip/Unequip button
        local equipBtn = createTextButton(
            card,
            pet.equipped and "Unequip" or "Equip",
            UDim2.new(0.45, 0, 0.3, 0),
            UDim2.new(0.025, 0, 0.64, 0),
            pet.equipped and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 120, 60)
        )

        equipBtn.MouseButton1Click:Connect(function()
            if pet.equipped then
                UnequipPet:InvokeServer(pet.id)
            else
                local success = EquipPet:InvokeServer(pet.id)
                if not success then
                    UIController.ShowNotification("No empty pet slots!")
                end
            end
        end)

        -- Delete button
        local delBtn = createTextButton(
            card,
            "Release",
            UDim2.new(0.45, 0, 0.3, 0),
            UDim2.new(0.5, 0, 0.64, 0),
            Color3.fromRGB(100, 40, 40)
        )

        delBtn.MouseButton1Click:Connect(function()
            DeletePet:InvokeServer(pet.id)
        end)
    end

    -- Update canvas size
    local grid = scroll:FindFirstChildOfClass("UIGridLayout")
    if grid then
        scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 10)
    end
end

------------------------------------------------------------
-- SHOP (toggle panel)
------------------------------------------------------------

function UIController._buildShop(gui)
    local shopBtn = createTextButton(
        gui, "🛒 Shop",
        UDim2.new(0.08, 0, 0.04, 0),
        UDim2.new(0.02, 0, 0.15, 0),
        Color3.fromRGB(70, 70, 40)
    )

    local panel = createFrame(gui, UDim2.new(0.35, 0, 0.6, 0), UDim2.new(0.325, 0, -0.65, 0), Color3.fromRGB(25, 30, 40))
    panel.ClipsDescendants = true
    UIController._shopFrame = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.07, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.Text = "🛒 Shop"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(0.95, 0, 0.88, 0)
    scroll.Position = UDim2.new(0.025, 0, 0.09, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 2, 0)
    scroll.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = scroll

    -- Section header: Game Passes
    local gpHeader = Instance.new("TextLabel")
    gpHeader.Size = UDim2.new(1, 0, 0, 30)
    gpHeader.BackgroundTransparency = 1
    gpHeader.TextColor3 = Color3.fromRGB(150, 200, 255)
    gpHeader.Text = "— Game Passes —"
    gpHeader.Font = Enum.Font.GothamBold
    gpHeader.TextSize = 14
    gpHeader.TextScaled = true
    gpHeader.Parent = scroll

    for key, pass in GameConfig.GAME_PASSES do
        local btn = createTextButton(
            scroll,
            key .. " — R$" .. pass.robuxPrice .. "\n" .. pass.description,
            UDim2.new(0.95, 0, 0, 50),
            UDim2.new(0, 0, 0, 0),
            Color3.fromRGB(50, 60, 80)
        )
        btn.TextScaled = true
        btn.MouseButton1Click:Connect(function()
            PromptPurchase:FireServer("GamePass", key)
        end)
    end

    -- Section header: Developer Products
    local dpHeader = Instance.new("TextLabel")
    dpHeader.Size = UDim2.new(1, 0, 0, 30)
    dpHeader.BackgroundTransparency = 1
    dpHeader.TextColor3 = Color3.fromRGB(150, 255, 150)
    dpHeader.Text = "— Products —"
    dpHeader.Font = Enum.Font.GothamBold
    dpHeader.TextSize = 14
    dpHeader.TextScaled = true
    dpHeader.Parent = scroll

    for key, product in GameConfig.DEV_PRODUCTS do
        local btn = createTextButton(
            scroll,
            product.description .. " — R$" .. product.robuxPrice,
            UDim2.new(0.95, 0, 0, 40),
            UDim2.new(0, 0, 0, 0),
            Color3.fromRGB(50, 80, 50)
        )
        btn.TextScaled = true
        btn.MouseButton1Click:Connect(function()
            PromptPurchase:FireServer("DevProduct", key)
        end)
    end

    -- Toggle
    local isOpen = false
    shopBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetPos = isOpen and UDim2.new(0.325, 0, 0.2, 0) or UDim2.new(0.325, 0, -0.65, 0)
        TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
    end)
end

------------------------------------------------------------
-- CODE REDEMPTION
------------------------------------------------------------

function UIController._buildCodeRedemption(gui)
    local codeBtn = createTextButton(
        gui, "🎁 Codes",
        UDim2.new(0.08, 0, 0.04, 0),
        UDim2.new(0.02, 0, 0.2, 0),
        Color3.fromRGB(40, 70, 70)
    )

    local panel = createFrame(gui, UDim2.new(0.25, 0, 0.1, 0), UDim2.new(0.375, 0, -0.15, 0), Color3.fromRGB(25, 35, 35))
    UIController._codeFrame = panel

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.6, 0, 0.6, 0)
    textBox.Position = UDim2.new(0.05, 0, 0.2, 0)
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "Enter code..."
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 14
    textBox.TextScaled = true
    textBox.ClearTextOnFocus = true
    textBox.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = textBox

    local redeemBtn = createTextButton(
        panel, "Redeem",
        UDim2.new(0.28, 0, 0.6, 0),
        UDim2.new(0.68, 0, 0.2, 0),
        Color3.fromRGB(60, 120, 60)
    )

    redeemBtn.MouseButton1Click:Connect(function()
        local code = textBox.Text
        if code and #code > 0 then
            local success, message = RedeemCode:InvokeServer(code)
            UIController.ShowNotification(message or (success and "Code redeemed!" or "Invalid code."))
            textBox.Text = ""
        end
    end)

    -- Toggle
    local isOpen = false
    codeBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetPos = isOpen and UDim2.new(0.375, 0, 0.45, 0) or UDim2.new(0.375, 0, -0.15, 0)
        TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
    end)
end

------------------------------------------------------------
-- NOTIFICATION SYSTEM
------------------------------------------------------------

function UIController._buildNotification(gui)
    local label = Instance.new("TextLabel")
    label.Name = "Notification"
    label.Size = UDim2.new(0.4, 0, 0.05, 0)
    label.Position = UDim2.new(0.3, 0, 0.3, 0)
    label.AnchorPoint = Vector2.new(0, 0)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    label.BackgroundTransparency = 0.3
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = ""
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextScaled = true
    label.Visible = false
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    UIController._notificationLabel = label
end

function UIController.ShowNotification(message: string)
    local label = UIController._notificationLabel
    if not label then return end

    label.Text = message
    label.Visible = true
    label.BackgroundTransparency = 0.3
    label.TextTransparency = 0

    -- Fade out after 3 seconds
    task.delay(3, function()
        if label.Text == message then
            local tween = TweenService:Create(label, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                TextTransparency = 1,
            })
            tween:Play()
            tween.Completed:Connect(function()
                if label.Text == message then
                    label.Visible = false
                end
            end)
        end
    end)
end

------------------------------------------------------------
-- REFRESH ALL UI
------------------------------------------------------------

function UIController.RefreshAll()
    local data = UIController._currentData
    if not data then return end

    -- Update HUD
    if UIController._coinLabel then
        UIController._coinLabel.Text = formatNumber(data.coins)
    end
    if UIController._rebirthLabel then
        UIController._rebirthLabel.Text = "🔄 Rebirth: " .. tostring(data.rebirths)
    end

    -- Update egg button availability
    if UIController._eggButtons then
        for eggName, btn in UIController._eggButtons do
            local egg = EggData.ByName[eggName]
            if egg then
                local unlocked = data.unlockedZones and table.find(data.unlockedZones, egg.zone)
                local canAfford = data.coins >= egg.cost
                if not unlocked then
                    btn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
                    btn.Text = "🔒 " .. eggName
                elseif not canAfford then
                    btn.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
                    btn.Text = "🥚 " .. eggName .. "\n" .. formatNumber(egg.cost)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(40, 80, 60)
                    btn.Text = "🥚 " .. eggName .. "\n" .. formatNumber(egg.cost)
                end
            end
        end
    end

    -- Refresh pet inventory
    UIController._refreshPetInventory()
end

return UIController
