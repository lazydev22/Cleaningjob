Config = {}

Config.InteractKey = 0x760A9C6F

Config.Distances = {
    npc = 2.0,
    spot = 1.5,
}

Config.CleanTime = 10000

Config.CleaningAnimation = 'sweeping'

Config.GarbageProps = { 'p_debrispile01x', 'p_debrispile02x', 'p_debrispile03x', 'p_litternbx01x', 'p_litternbx02x' }

Config.SpotMarker = {
    type = 1,
    distance = 20.0,
    scale = vector3(0.9, 0.9, 0.5),
    color = { r = 201, g = 162, b = 75, a = 160 },
    bob = true,
}

Config.SpotBlip = {
    enable = true,
    sprite = -1580514024,
    colorModifier = 'BLIP_MODIFIER_MP_COLOR_32',
    scale = 0.15,
    route = true,
    routeColor = 5,
}

-- Never drops more than max-1 spots, so at least 1 always remains.
Config.SpotDrop = {
    min = 1,
    max = 2,
}

Config.JobCooldown = {
    min = 5 * 60 * 1000,
    max = 10 * 60 * 1000,
}

Config.NightRestriction = {
    enable = true,
    startHour = 20,
    endHour = 6,
}

Config.Reward = {
    CurrencyType = 0,
    Amount = 1.25,
}

Config.Security = {
    RateLimitMs = {
        GetJob = 1000,
        CleanSpot = 500,
        FinishJob = 1000,
    },
    SpotDistanceTolerance = 1.5,
    TimingTolerancePct = 0.85,
}

-- spots is either a flat {label, coords} array, or a table of named places each holding one -
-- see Config.PickTownArea/ResolveTownSpots below for how the two shapes are told apart.
Config.Towns = {
    {
        id = 'blackwater',
        name = 'Blackwater',
        npc = {
            model = 'a_m_m_middlesdtownfolk_01',
            coords = vector3(-770.78, -1325.72, 43.62),
            heading = 182.9,
            scenario = 'WORLD_HUMAN_LEAN_BACK_RAILING_DRINKING',
            blip = { enable = true, sprite = -1656531561 },
        },
        spots = {
            backstreets = {
                { label = 'Muddy Boardwalk',     coords = vector3(-756.2, -1328.18, 43.73) },
                { label = 'Overturned Crate',    coords = vector3(-780.65, -1330.49, 43.64) },
                { label = 'Spilled Feed Trough', coords = vector3(-806.38, -1330.16, 43.68) },
            },
            outskirts = {
                { label = 'Dusty Porch',    coords = vector3(-804.58, -1292.68, 43.46) },
                { label = 'Broken Barrels', coords = vector3(-793.35, -1269.97, 43.63) },
            },
        },
    },
    {
        id = 'saintdenis',
        name = 'Saint Denis',
        npc = {
            model = 'a_m_m_middlesdtownfolk_02',
            coords = vector3(2683.01, -1267.7, 51.78),
            heading = 295.82,
            scenario = 'WORLD_HUMAN_LEAN_BACK_WALL_SMOKING_BAR_CA',
            blip = { enable = true, sprite = -1656531561 },
        },
        spots = {
            station = {
                { label = 'Filthy Alley',       coords = vector3(2672.07, -1469.92, 46.3) },
                { label = 'Overflowing Trash',   coords = vector3(2690.01, -1461.8, 46.28) },
                { label = 'Muddy Street Corner', coords = vector3(2698.02, -1449.85, 46.26) },
                { label = 'Muddy Street Corner', coords = vector3(2704.88, -1431.79, 46.17) },
                { label = 'Muddy Street Corner', coords = vector3(2725.23, -1427.24, 45.97) },
                { label = 'Muddy Street Corner', coords = vector3(2742.33, -1424.42, 46.17) },
            },
            supremecourt = {
                { label = 'Spilled Crates', coords = vector3(2602.16, -1295.22, 52.27) },
                { label = 'Broken Fence',   coords = vector3(2591.05, -1283.57, 52.27) },
                { label = 'Broken Fence',   coords = vector3(2577.96, -1287.3, 52.27) },
                { label = 'Broken Fence',   coords = vector3(2573.52, -1300.47, 52.27) },
            },
        },
    },
    {
        id = 'valentine',
        name = 'Valentine',
        npc = {
            model = 'U_M_M_BWMStableHand_01',
            coords = vector3(-343.95, 797.96, 116.29),
            heading = 98.05,
            scenario = 'WORLD_HUMAN_LEAN_BACK_WALL_SMOKING',
            blip = { enable = true, sprite = 990667866 },
        },
        garbageProps = { 'p_horsepoop02x', 'p_horsepoop03x' },
        cleaningAnimation = 'gravedigging',
        spots = {
            { label = 'Horse Stall',     coords = vector3(-343.1, 790.27, 116.09) },
            { label = 'Stable Aisle',    coords = vector3(-316.96, 783.12, 117.23) },
            { label = 'Hitching Post',   coords = vector3(-299.25, 795.6, 118.52) },
            { label = 'Stable Entrance', coords = vector3(-287.11, 790.3, 118.71) },
            { label = 'Feed Corner',     coords = vector3(-266.27, 797.55, 118.57) },
            { label = 'Feed Corner',     coords = vector3(-279.06, 763.83, 117.94) },
            { label = 'Feed Corner',     coords = vector3(-303.73, 749.28, 118.02) },
            { label = 'Feed Corner',     coords = vector3(-351.86, 759.36, 116.34) },
            { label = 'Feed Corner',     coords = vector3(-361.9, 770.49, 116.43) },
            { label = 'Feed Corner',     coords = vector3(-357.74, 771.31, 116.46) },
            { label = 'Feed Corner',     coords = vector3(-387.07, 778.36, 115.77) },
        },
    },
    {
        id = 'rhodes',
        name = 'Rhodes',
        npc = {
            model = 'U_M_M_BWMStableHand_01',
            coords = vector3(1418.48, -1320.53, 77.86),
            heading = 27.77,
            scenario = 'WORLD_HUMAN_LEAN_BACK_WHITTLE',
            blip = { enable = true, sprite = 990667866 },
        },
        garbageProps = { 'p_horsepoop02x', 'p_horsepoop03x' },
        cleaningAnimation = 'gravedigging',
        spots = {
            { label = 'Horse Stall',     coords = vector3(1431.56, -1288.21, 76.82) },
            { label = 'Stable Aisle',    coords = vector3(1428.0, -1291.0, 76.9) },
            { label = 'Hitching Post',   coords = vector3(1435.5, -1289.5, 76.8) },
            { label = 'Stable Entrance', coords = vector3(1432.97, -1295.39, 76.82) },
            { label = 'Feed Corner',     coords = vector3(1418.0, -1293.0, 77.5) },
        },
    },
}

function Config.PickTownArea(town)
    if town.spots[1] then return nil end

    local names = {}
    for name in pairs(town.spots) do names[#names + 1] = name end
    if #names == 0 then return nil end

    return names[math.random(#names)]
end

function Config.ResolveTownSpots(town, placeName)
    if town.spots[1] then return town.spots end
    return (placeName and town.spots[placeName]) or {}
end

function Config.AreaLabel(placeName, placeSpots)
    if placeSpots and placeSpots.label then return placeSpots.label end
    return placeName:sub(1, 1):upper() .. placeName:sub(2)
end
