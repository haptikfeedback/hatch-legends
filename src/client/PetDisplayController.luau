--[[
    PetDisplayController.luau
    Makes equipped pets follow the player character as floating orbs/billboards
    Since we don't have 3D pet models (yet), we use BillboardGuis with pet info
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataUpdate = Remotes:WaitForChild("DataUpdate")

local player = Players.LocalPlayer

local PetDisplayController = {}
PetDisplayController._petParts = {} -- [petId] = Part
PetDisplayController._equippedPets = {} -- current list of equipped pet data

function PetDisplayController.Init()
    -- Listen for data updates to refresh displayed pets
    DataUpdate.OnClientEvent:Connect(function(data)
        if data and data.pets then
            PetDisplayController._updatePets(data.pets)
        end
    end)

    -- Orbit pets around player
    RunService.Heartbeat:Connect(function(dt)
        PetDisplayController._updatePositions(dt)
    end)

    -- Cleanup on character respawn
    player.CharacterAdded:Connect(function()
        PetDisplayController._clearAllPets()
    end)
end

function PetDisplayController._updatePets(allPets)
    local equipped = {}
    for _, pet in allPets do
        if pet.equipped then
            table.insert(equipped, pet)
        end
    end
    PetDisplayController._equippedPets = equipped

    -- Remove pets no longer equipped
    local equippedIds = {}
    for _, pet in equipped do
        equippedIds[pet.id] = true
    end

    for petId, part in PetDisplayController._petParts do
        if not equippedIds[petId] then
            part:Destroy()
            PetDisplayController._petParts[petId] = nil
        end
    end

    -- Add new equipped pets
    for _, pet in equipped do
        if not PetDisplayController._petParts[pet.id] then
            PetDisplayController._createPetVisual(pet)
        end
    end
end

function PetDisplayController._createPetVisual(pet)
    local part = Instance.new("Part")
    part.Name = "Pet_" .. pet.id
    part.Size = Vector3.new(1.5, 1.5, 1.5)
    part.Shape = Enum.PartType.Ball
    part.Material = Enum.Material.Neon
    part.Color = GameConfig.RARITY_COLORS[pet.rarity] or Color3.fromRGB(180, 180, 180)
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Transparency = 0.3
    part.Parent = workspace

    -- Billboard with pet info
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(4, 0, 2, 0)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = GameConfig.RARITY_COLORS[pet.rarity] or Color3.fromRGB(255, 255, 255)
    nameLabel.Text = pet.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard

    local powerLabel = Instance.new("TextLabel")
    powerLabel.Size = UDim2.new(1, 0, 0.4, 0)
    powerLabel.Position = UDim2.new(0, 0, 0.5, 0)
    powerLabel.BackgroundTransparency = 1
    powerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    powerLabel.Text = "⭐ " .. tostring(pet.power)
    powerLabel.Font = Enum.Font.Gotham
    powerLabel.TextScaled = true
    powerLabel.Parent = billboard

    PetDisplayController._petParts[pet.id] = part
end

function PetDisplayController._updatePositions(dt)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local center = rootPart.Position
    local time = tick()
    local count = 0
    local total = 0

    -- Count visible pets
    for _ in PetDisplayController._petParts do
        total += 1
    end
    if total == 0 then return end

    local radius = 4 + total * 0.5
    local heightOffset = 2

    for petId, part in PetDisplayController._petParts do
        local angle = (time * 1.5) + (count / total) * math.pi * 2
        local x = center.X + math.cos(angle) * radius
        local z = center.Z + math.sin(angle) * radius
        local y = center.Y + heightOffset + math.sin(time * 2 + count) * 0.5

        part.Position = Vector3.new(x, y, z)
        count += 1
    end
end

function PetDisplayController._clearAllPets()
    for petId, part in PetDisplayController._petParts do
        part:Destroy()
    end
    PetDisplayController._petParts = {}
end

return PetDisplayController
