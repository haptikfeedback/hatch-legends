--[[
    MapBuilder.luau
    Programmatically generates the entire Hatch Legends world
    Colorful, kid-friendly design for ages 4-12
    
    Creates:
    - Spawn area with welcome sign
    - 5 themed zones with platforms, egg pedestals, decorations
    - Zone gates with visual unlock indicators
    - Teleport pads between zones
    - Bounce pads (kids love bouncing!)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapBuilder = {}

------------------------------------------------------------
-- COLOR PALETTES (bright, kid-friendly)
------------------------------------------------------------

local ZONE_THEMES = {
    Grasslands = {
        primary = Color3.fromRGB(76, 175, 80),
        secondary = Color3.fromRGB(139, 195, 74),
        accent = Color3.fromRGB(255, 235, 59),
        ground = Color3.fromRGB(100, 181, 96),
        eggColor = Color3.fromRGB(255, 255, 200),
        particleColor = ColorSequence.new(Color3.fromRGB(255, 255, 100), Color3.fromRGB(100, 255, 100)),
        position = Vector3.new(0, 20, 0),
        groundMaterial = Enum.Material.Grass,
    },
    ["Crystal Caves"] = {
        primary = Color3.fromRGB(156, 39, 176),
        secondary = Color3.fromRGB(186, 104, 200),
        accent = Color3.fromRGB(0, 229, 255),
        ground = Color3.fromRGB(80, 40, 100),
        eggColor = Color3.fromRGB(200, 150, 255),
        particleColor = ColorSequence.new(Color3.fromRGB(200, 100, 255), Color3.fromRGB(100, 200, 255)),
        position = Vector3.new(1024, 20, 0),
        groundMaterial = Enum.Material.Ice,
    },
    Volcano = {
        primary = Color3.fromRGB(244, 67, 54),
        secondary = Color3.fromRGB(255, 152, 0),
        accent = Color3.fromRGB(255, 235, 59),
        ground = Color3.fromRGB(80, 30, 20),
        eggColor = Color3.fromRGB(255, 120, 50),
        particleColor = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 255, 0)),
        position = Vector3.new(0, 20, 1024),
        groundMaterial = Enum.Material.CrackedLava,
    },
    ["Sky Islands"] = {
        primary = Color3.fromRGB(33, 150, 243),
        secondary = Color3.fromRGB(255, 255, 255),
        accent = Color3.fromRGB(255, 193, 7),
        ground = Color3.fromRGB(200, 230, 255),
        eggColor = Color3.fromRGB(180, 220, 255),
        particleColor = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(100, 200, 255)),
        position = Vector3.new(512, 320, 512),
        groundMaterial = Enum.Material.Glacier,
    },
    ["Shadow Realm"] = {
        primary = Color3.fromRGB(50, 0, 70),
        secondary = Color3.fromRGB(0, 0, 0),
        accent = Color3.fromRGB(255, 0, 100),
        ground = Color3.fromRGB(20, 0, 30),
        eggColor = Color3.fromRGB(100, 0, 150),
        particleColor = ColorSequence.new(Color3.fromRGB(255, 0, 100), Color3.fromRGB(100, 0, 200)),
        position = Vector3.new(1024, 20, 1024),
        groundMaterial = Enum.Material.Slate,
    },
}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function createPart(parent, name, size, position, color, material, anchored)
    local part = Instance.new("Part")
    part.Name = name or "Part"
    part.Size = size or Vector3.new(4, 4, 4)
    part.Position = position or Vector3.new(0, 0, 0)
    part.Color = color or Color3.fromRGB(180, 180, 180)
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = anchored ~= false
    part.CanCollide = true
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function createBillboard(parent, text, color, size, offset)
    local bb = Instance.new("BillboardGui")
    bb.Size = size or UDim2.new(8, 0, 3, 0)
    bb.StudsOffset = offset or Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = false
    bb.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = bb
    return bb
end

local function addSparkles(parent, color)
    local s = Instance.new("Sparkles")
    s.SparkleColor = color or Color3.fromRGB(255, 255, 100)
    s.Parent = parent
    return s
end

local function addParticles(parent, colorSeq, rate, speed, lifetime, size)
    local e = Instance.new("ParticleEmitter")
    e.Color = colorSeq or ColorSequence.new(Color3.fromRGB(255, 255, 255))
    e.Rate = rate or 10
    e.Speed = NumberRange.new(speed or 2, (speed or 2) * 2)
    e.Lifetime = NumberRange.new(lifetime or 1, (lifetime or 1) * 2)
    e.Size = NumberSequence.new(size or 0.5)
    e.LightEmission = 0.5
    e.Parent = parent
    return e
end

local function addPointLight(parent, color, brightness, range)
    local l = Instance.new("PointLight")
    l.Color = color or Color3.fromRGB(255, 255, 200)
    l.Brightness = brightness or 1
    l.Range = range or 20
    l.Parent = parent
    return l
end

------------------------------------------------------------
-- SPAWN AREA
------------------------------------------------------------

function MapBuilder._buildSpawn(mapFolder)
    local folder = Instance.new("Folder")
    folder.Name = "SpawnArea"
    folder.Parent = mapFolder

    local spawnBase = Vector3.new(0, 20, -100) -- near Grasslands zone

    -- Main platform
    createPart(folder, "SpawnPlatform", Vector3.new(60, 3, 60), spawnBase + Vector3.new(0, -1.5, 0), Color3.fromRGB(100, 200, 255), Enum.Material.SmoothPlastic)

    -- Checkerboard tiles
    for x = -2, 2 do
        for z = -2, 2 do
            createPart(folder, "Tile", Vector3.new(11, 0.5, 11),
                spawnBase + Vector3.new(x * 12, 0.3, z * 12),
                (x + z) % 2 == 0 and Color3.fromRGB(150, 230, 255) or Color3.fromRGB(200, 255, 200),
                Enum.Material.SmoothPlastic
            )
        end
    end

    -- Welcome sign
    createPart(folder, "WelcomeSignPost", Vector3.new(3, 12, 3), spawnBase + Vector3.new(0, 6, -25), Color3.fromRGB(139, 90, 43), Enum.Material.Wood)
    local signBoard = createPart(folder, "WelcomeSignBoard", Vector3.new(20, 8, 1), spawnBase + Vector3.new(0, 14, -25), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
    createBillboard(signBoard, "🐣 HATCH LEGENDS 🐣", Color3.fromRGB(255, 255, 255), UDim2.new(10, 0, 4, 0), Vector3.new(0, 2, 0))
    addSparkles(signBoard, Color3.fromRGB(255, 215, 0))
    addPointLight(signBoard, Color3.fromRGB(255, 215, 0), 2, 30)

    local subSign = createPart(folder, "SubSign", Vector3.new(14, 3, 0.5), spawnBase + Vector3.new(0, 8, -25), Color3.fromRGB(255, 100, 100), Enum.Material.Neon)
    createBillboard(subSign, "Hatch Eggs • Collect Pets • Be a Legend!", Color3.fromRGB(255, 255, 200), UDim2.new(12, 0, 2, 0), Vector3.new(0, 1, 0))

    -- SpawnLocation
    local spawn = Instance.new("SpawnLocation")
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = spawnBase + Vector3.new(0, 1, 0)
    spawn.Color = Color3.fromRGB(100, 255, 100)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.5
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Duration = 0
    spawn.Parent = folder

    -- Rainbow arch
    local rainbowColors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 127, 0), Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(75, 0, 130), Color3.fromRGB(148, 0, 211),
    }
    for i = 0, 6 do
        local angle = math.rad(i * 30)
        local p = createPart(folder, "Rainbow_" .. i, Vector3.new(2, 2, 2),
            spawnBase + Vector3.new(math.cos(angle) * 25, math.sin(angle) * 25 + 5, 0),
            rainbowColors[i + 1], Enum.Material.Neon
        )
        p.Shape = Enum.PartType.Ball
        p.CanCollide = false
        p.Transparency = 0.2
    end

    -- Path to Grasslands
    for i = 0, 8 do
        createPart(folder, "Path_" .. i, Vector3.new(8, 1, 6),
            spawnBase + Vector3.new(0, -0.5, 30 + i * 7),
            i % 2 == 0 and Color3.fromRGB(200, 180, 140) or Color3.fromRGB(180, 160, 120),
            Enum.Material.Cobblestone
        )
    end
end

------------------------------------------------------------
-- EGG PEDESTAL (ProximityPrompt for kid-friendly interaction)
------------------------------------------------------------

function MapBuilder._buildEggPedestal(parent, zoneName, theme, position)
    local folder = Instance.new("Folder")
    folder.Name = zoneName .. "_EggPedestal"
    folder.Parent = parent

    -- Pedestal base
    local base = createPart(folder, "PedestalBase", Vector3.new(8, 4, 8), position + Vector3.new(0, 2, 0), theme.primary, Enum.Material.SmoothPlastic)
    base.Shape = Enum.PartType.Cylinder
    base.Orientation = Vector3.new(0, 0, 90)

    -- Pedestal top glow
    local top = createPart(folder, "PedestalTop", Vector3.new(1, 6, 6), position + Vector3.new(0, 4.5, 0), theme.accent, Enum.Material.Neon)
    top.Shape = Enum.PartType.Cylinder
    top.Orientation = Vector3.new(0, 0, 90)
    addPointLight(top, theme.accent, 1.5, 15)

    -- THE EGG (big, glowing, unmissable)
    local egg = createPart(folder, "Egg", Vector3.new(5, 7, 5), position + Vector3.new(0, 9, 0), theme.eggColor, Enum.Material.Neon)
    egg.Shape = Enum.PartType.Ball
    egg.CanCollide = false

    -- Egg spots
    for s = 1, 5 do
        local spot = createPart(folder, "EggSpot_" .. s, Vector3.new(1.2, 1.2, 1.2),
            position + Vector3.new(math.cos(s * 1.25) * 2, 8 + math.sin(s * 0.8) * 2, math.sin(s * 1.25) * 2),
            theme.accent, Enum.Material.Neon
        )
        spot.Shape = Enum.PartType.Ball
        spot.CanCollide = false
    end

    addParticles(egg, theme.particleColor, 15, 1, 2, 0.4)
    addSparkles(egg, theme.accent)

    -- ProximityPrompt (BIG, instant, easy for small kids)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = zoneName .. " Egg"
    prompt.ActionText = "🐣 HATCH!"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 15
    prompt.RequiresLineOfSight = false
    prompt.Parent = egg

    -- Zone tag (so server knows which egg this is)
    local tag = Instance.new("StringValue")
    tag.Name = "ZoneName"
    tag.Value = zoneName
    tag.Parent = egg

    createBillboard(egg, "🥚 " .. zoneName .. " Egg 🥚", theme.accent, UDim2.new(10, 0, 3, 0), Vector3.new(0, 6, 0))

    return folder, egg
end

------------------------------------------------------------
-- ZONE DECORATIONS
------------------------------------------------------------

function MapBuilder._addDecorations(folder, zoneName, theme, basePos)
    if zoneName == "Grasslands" then
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local dist = 35 + math.random(-5, 5)
            local pos = basePos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
            createPart(folder, "Trunk_" .. i, Vector3.new(2, 10 + math.random(0, 4), 2), pos + Vector3.new(0, 5, 0), Color3.fromRGB(139, 90, 43), Enum.Material.Wood)
            local c = createPart(folder, "Canopy_" .. i, Vector3.new(8 + math.random(0, 4), 8 + math.random(0, 4), 8 + math.random(0, 4)), pos + Vector3.new(0, 12, 0), Color3.fromRGB(50 + math.random(0, 50), 150 + math.random(0, 100), 50), Enum.Material.Grass)
            c.Shape = Enum.PartType.Ball
        end
        for i = 1, 15 do
            local f = createPart(folder, "Flower_" .. i, Vector3.new(1.5, 1.5, 1.5),
                basePos + Vector3.new(math.random(-45, 45), 0.5, math.random(-45, 45)),
                Color3.fromRGB(math.random(200, 255), math.random(50, 200), math.random(50, 200)), Enum.Material.Neon
            )
            f.Shape = Enum.PartType.Ball
            f.CanCollide = false
        end

    elseif zoneName == "Crystal Caves" then
        for i = 1, 12 do
            local angle = (i / 12) * math.pi * 2
            local dist = 25 + math.random(0, 20)
            local pos = basePos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
            local height = 8 + math.random(0, 12)
            local crystal = createPart(folder, "Crystal_" .. i, Vector3.new(2, height, 2), pos + Vector3.new(0, height / 2, 0),
                Color3.fromRGB(math.random(100, 200), math.random(50, 150), math.random(200, 255)), Enum.Material.Neon
            )
            crystal.Transparency = 0.3
            addPointLight(crystal, crystal.Color, 0.5, 12)
        end
        local ceil = createPart(folder, "Ceiling", Vector3.new(120, 3, 120), basePos + Vector3.new(0, 30, 0), Color3.fromRGB(30, 15, 40), Enum.Material.Slate)
        ceil.Transparency = 0.4

    elseif zoneName == "Volcano" then
        for i = 1, 6 do
            local lava = createPart(folder, "Lava_" .. i, Vector3.new(6 + math.random(0, 6), 0.5, 6 + math.random(0, 6)),
                basePos + Vector3.new(math.random(-40, 40), 0.2, math.random(-40, 40)), Color3.fromRGB(255, 80, 0), Enum.Material.Neon
            )
            lava.CanCollide = false
            addParticles(lava, ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)), 8, 3, 1.5, 0.6)
            addPointLight(lava, Color3.fromRGB(255, 100, 0), 1, 15)
        end
        createPart(folder, "VolcanoMountain", Vector3.new(30, 40, 30), basePos + Vector3.new(0, 20, 40), Color3.fromRGB(60, 30, 20), Enum.Material.Rock)
        for i = 1, 10 do
            createPart(folder, "Rock_" .. i, Vector3.new(3 + math.random(0, 4), 2 + math.random(0, 3), 3 + math.random(0, 4)),
                basePos + Vector3.new(math.random(-45, 45), 1, math.random(-45, 45)), Color3.fromRGB(60 + math.random(0, 30), 30 + math.random(0, 20), 20), Enum.Material.Rock
            )
        end

    elseif zoneName == "Sky Islands" then
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2
            local dist = 35 + math.random(-5, 10)
            local pos = basePos + Vector3.new(math.cos(angle) * dist, math.random(-5, 15), math.sin(angle) * dist)
            createPart(folder, "Island_" .. i, Vector3.new(12 + math.random(0, 8), 3, 12 + math.random(0, 8)), pos, Color3.fromRGB(180, 220, 255), Enum.Material.Glacier)
            local cloud = createPart(folder, "Cloud_" .. i, Vector3.new(15, 4, 15), pos + Vector3.new(0, -4, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
            cloud.Shape = Enum.PartType.Ball
            cloud.Transparency = 0.4
            cloud.CanCollide = false
        end
        for i = 1, 20 do
            local star = createPart(folder, "Star_" .. i, Vector3.new(0.5, 0.5, 0.5),
                basePos + Vector3.new(math.random(-50, 50), 20 + math.random(0, 30), math.random(-50, 50)), Color3.fromRGB(255, 255, 200), Enum.Material.Neon
            )
            star.Shape = Enum.PartType.Ball
            star.CanCollide = false
        end

    elseif zoneName == "Shadow Realm" then
        for i = 1, 10 do
            local angle = (i / 10) * math.pi * 2
            local dist = 30 + math.random(-5, 10)
            local pos = basePos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
            createPart(folder, "Pillar_" .. i, Vector3.new(3, 15 + math.random(0, 10), 3), pos + Vector3.new(0, 7, 0), Color3.fromRGB(20, 0, 30), Enum.Material.Slate)
            local rune = createPart(folder, "Rune_" .. i, Vector3.new(1.5, 1.5, 0.5), pos + Vector3.new(0, 5, 1.5), Color3.fromRGB(255, 0, 100), Enum.Material.Neon)
            rune.CanCollide = false
            addPointLight(rune, Color3.fromRGB(255, 0, 100), 0.8, 8)
        end
        for i = 1, 8 do
            local orb = createPart(folder, "DarkOrb_" .. i, Vector3.new(2, 2, 2),
                basePos + Vector3.new(math.random(-40, 40), 10 + math.random(0, 10), math.random(-40, 40)), Color3.fromRGB(100, 0, 150), Enum.Material.Neon
            )
            orb.Shape = Enum.PartType.Ball
            orb.CanCollide = false
            orb.Transparency = 0.3
            addParticles(orb, ColorSequence.new(Color3.fromRGB(150, 0, 200), Color3.fromRGB(255, 0, 100)), 5, 0.5, 2, 0.3)
        end
    end
end

------------------------------------------------------------
-- BOUNCE PADS
------------------------------------------------------------

function MapBuilder._addBouncePads(folder, theme, basePos)
    local offsets = {
        Vector3.new(20, 0, 20), Vector3.new(-20, 0, 20),
        Vector3.new(20, 0, -20), Vector3.new(-20, 0, -20),
    }
    for i, offset in offsets do
        local pad = createPart(folder, "BouncePad_" .. i, Vector3.new(6, 1, 6), basePos + offset + Vector3.new(0, 0.5, 0), theme.accent, Enum.Material.Neon)
        pad.Shape = Enum.PartType.Cylinder
        pad.Orientation = Vector3.new(0, 0, 90)
        createBillboard(pad, "⬆️", theme.accent, UDim2.new(3, 0, 3, 0), Vector3.new(0, 2, 0))
        local tag = Instance.new("BoolValue")
        tag.Name = "IsBouncePad"
        tag.Value = true
        tag.Parent = pad
    end
end

------------------------------------------------------------
-- BUILD ZONE
------------------------------------------------------------

function MapBuilder._buildZone(mapFolder, zoneName, theme)
    local folder = Instance.new("Folder")
    folder.Name = zoneName
    folder.Parent = mapFolder
    local basePos = theme.position

    -- Ground
    createPart(folder, "Ground", Vector3.new(120, 5, 120), basePos + Vector3.new(0, -2.5, 0), theme.ground, theme.groundMaterial)

    -- Border walls
    local walls = {
        { pos = Vector3.new(0, 3, 60), size = Vector3.new(120, 8, 2) },
        { pos = Vector3.new(0, 3, -60), size = Vector3.new(120, 8, 2) },
        { pos = Vector3.new(60, 3, 0), size = Vector3.new(2, 8, 120) },
        { pos = Vector3.new(-60, 3, 0), size = Vector3.new(2, 8, 120) },
    }
    for i, w in walls do
        local wall = createPart(folder, "Wall_" .. i, w.size, basePos + w.pos, theme.secondary, Enum.Material.SmoothPlastic)
        wall.Transparency = 0.5
    end

    -- Zone sign
    local sign = createPart(folder, "ZoneSign", Vector3.new(16, 6, 1), basePos + Vector3.new(0, 10, -55), theme.accent, Enum.Material.Neon)
    sign.CanCollide = false
    createBillboard(sign, "✨ " .. zoneName .. " ✨", theme.accent, UDim2.new(12, 0, 4, 0), Vector3.new(0, 2, 0))
    addPointLight(sign, theme.accent, 2, 25)

    -- Egg pedestal
    MapBuilder._buildEggPedestal(folder, zoneName, theme, basePos)

    -- Decorations
    MapBuilder._addDecorations(folder, zoneName, theme, basePos)

    -- Bounce pads
    MapBuilder._addBouncePads(folder, theme, basePos)

    -- Tap zone indicator
    local tapZone = createPart(folder, "TapZone", Vector3.new(30, 0.5, 30), basePos + Vector3.new(0, 0.3, 0), theme.accent, Enum.Material.Neon)
    tapZone.Transparency = 0.7
    tapZone.CanCollide = false
    tapZone.Shape = Enum.PartType.Cylinder
    tapZone.Orientation = Vector3.new(0, 0, 90)
end

------------------------------------------------------------
-- TELEPORT PADS
------------------------------------------------------------

function MapBuilder._buildTeleportPads(mapFolder)
    local folder = Instance.new("Folder")
    folder.Name = "TeleportPads"
    folder.Parent = mapFolder

    -- Teleport connections: each zone connects to its neighbors in the 2x2 grid
    -- Layout:  Grasslands(0,0)  -- Crystal Caves(1024,0)
    --          Volcano(0,1024)  -- Shadow Realm(1024,1024)
    --          Sky Islands(512,320,512) -- center, above
    local connections = {
        { from = "Grasslands",    to = "Crystal Caves",  fromOffset = Vector3.new(55, 0.5, 0),   toOffset = Vector3.new(-55, 5, 0) },
        { from = "Grasslands",    to = "Volcano",        fromOffset = Vector3.new(0, 0.5, 55),   toOffset = Vector3.new(0, 5, -55) },
        { from = "Crystal Caves", to = "Grasslands",     fromOffset = Vector3.new(-55, 0.5, 0),  toOffset = Vector3.new(55, 5, 0) },
        { from = "Crystal Caves", to = "Shadow Realm",   fromOffset = Vector3.new(0, 0.5, 55),   toOffset = Vector3.new(0, 5, -55) },
        { from = "Volcano",       to = "Grasslands",     fromOffset = Vector3.new(0, 0.5, -55),  toOffset = Vector3.new(0, 5, 55) },
        { from = "Volcano",       to = "Shadow Realm",   fromOffset = Vector3.new(55, 0.5, 0),   toOffset = Vector3.new(-55, 5, 0) },
        { from = "Shadow Realm",  to = "Crystal Caves",  fromOffset = Vector3.new(0, 0.5, -55),  toOffset = Vector3.new(0, 5, 55) },
        { from = "Shadow Realm",  to = "Volcano",        fromOffset = Vector3.new(-55, 0.5, 0),  toOffset = Vector3.new(55, 5, 0) },
        -- Sky Islands connects to all 4 ground zones
        { from = "Grasslands",    to = "Sky Islands",    fromOffset = Vector3.new(0, 0.5, -40),   toOffset = Vector3.new(0, 5, 0) },
        { from = "Sky Islands",   to = "Grasslands",     fromOffset = Vector3.new(-40, 0.5, 0),  toOffset = Vector3.new(0, 5, 0) },
    }

    for _, conn in connections do
        local fromTheme = ZONE_THEMES[conn.from]
        local toTheme = ZONE_THEMES[conn.to]

        local pad = createPart(folder, "TP_" .. conn.from .. "_to_" .. conn.to, Vector3.new(8, 1, 8), fromTheme.position + conn.fromOffset, toTheme.accent, Enum.Material.Neon)
        pad.Shape = Enum.PartType.Cylinder
        pad.Orientation = Vector3.new(0, 0, 90)
        addParticles(pad, toTheme.particleColor, 20, 3, 1, 0.3)
        addPointLight(pad, toTheme.accent, 2, 15)
        createBillboard(pad, "🌀 " .. conn.to, toTheme.accent, UDim2.new(8, 0, 3, 0), Vector3.new(0, 4, 0))

        local dest = Instance.new("Vector3Value")
        dest.Name = "Destination"
        dest.Value = toTheme.position + conn.toOffset
        dest.Parent = pad

        local req = Instance.new("StringValue")
        req.Name = "RequiredZone"
        req.Value = conn.to
        req.Parent = pad

        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = "Go to " .. conn.to
        prompt.ActionText = "🌀 Teleport!"
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 12
        prompt.Parent = pad
    end
end

------------------------------------------------------------
-- LIGHTING (bright, colorful, kid-friendly)
------------------------------------------------------------

function MapBuilder._setupLighting()
    Lighting.Ambient = Color3.fromRGB(50, 50, 60)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
    -- Note: Lighting.Technology must be set manually in Studio (Properties panel)
    -- Set it to "Voxel" for best kid-friendly look
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 100)
    Lighting.ClockTime = 14

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.3
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Saturation = 0.3
    cc.Brightness = 0.05
    cc.Parent = Lighting

    local rays = Instance.new("SunRaysEffect")
    rays.Intensity = 0.1
    rays.Spread = 0.5
    rays.Parent = Lighting
end

------------------------------------------------------------
-- MAIN BUILD
------------------------------------------------------------

function MapBuilder.BuildAll()
    local existing = Workspace:FindFirstChild("HatchLegendsMap")
    if existing then existing:Destroy() end

    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "HatchLegendsMap"
    mapFolder.Parent = Workspace

    MapBuilder._setupLighting()
    MapBuilder._buildSpawn(mapFolder)

    for zoneName, theme in ZONE_THEMES do
        MapBuilder._buildZone(mapFolder, zoneName, theme)
    end

    MapBuilder._buildTeleportPads(mapFolder)

    -- Kill plane
    local kp = createPart(mapFolder, "KillPlane", Vector3.new(2000, 1, 2000), Vector3.new(0, -50, 0), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic)
    kp.Transparency = 1
    kp.CanCollide = false

    print("[MapBuilder] 🌍 World generated successfully!")
    return mapFolder
end

return MapBuilder
