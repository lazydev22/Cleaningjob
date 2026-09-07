local Core = exports.vorp_core:GetCore()
local progressbar = exports.dsml_progressbar:initiate()
local Animations = exports.vorp_animations:initiate()

local activeTownId = nil
local activeTown = nil
local activeAreaName = nil
local activeSpotIndexes = {}
local cleanedSpots = {}
local menuOpen = false
local cleaning = false

local function toIndexSet(list)
    local set = {}
    for _, index in ipairs(list or {}) do
        set[index] = true
    end
    return set
end

local function GetCoordDistance(v1, v2)
    return #(v1 - v2)
end

local function getTown(townId)
    for _, town in ipairs(Config.Towns) do
        if town.id == townId then
            return town
        end
    end
    return nil
end

local function setActiveTown(townId)
    activeTownId = townId
    activeTown = townId and getTown(townId) or nil
end

local function displayTownName(town, townName, areaName)
    if not areaName then return townName end
    return ('%s — %s'):format(townName, Config.AreaLabel(areaName, town.spots[areaName]))
end

local function townGarbageProps(town)
    return (town and town.garbageProps) or Config.GarbageProps
end

local function townCleaningAnimation(town)
    return (town and town.cleaningAnimation) or Config.CleaningAnimation
end

local spotBlips = {}
local spotBlipCoords = {}
local routedSpotIndex = nil

-- SetBlipRoute natives aren't exposed as Lua globals on this build, so they're invoked by hash
-- and pcall-wrapped so a missing native just disables the route line instead of breaking cleaning.
local routeNativeWarned = false
local function warnRouteNativeFailed()
    if routeNativeWarned then return end
    routeNativeWarned = true
    print('^1dsml_cleaningjob: blip route natives failed on this game build — spot route lines disabled for this session. Set Config.SpotBlip.route = false to silence this.^7')
end

local function SetBlipRouteNative(blip, enabled)
    local ok = pcall(Citizen.InvokeNative, 0x4F7D8A9BFB0B43E9, blip, enabled)
    if not ok then warnRouteNativeFailed() end
end

local function SetBlipRouteColourNative(blip, colour)
    local ok = pcall(Citizen.InvokeNative, 0x837155CD2F63DA09, blip, colour)
    if not ok then warnRouteNativeFailed() end
end

local function clearSpotBlips()
    for _, blip in pairs(spotBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    spotBlips = {}
    spotBlipCoords = {}
    routedSpotIndex = nil
end

local function updateSpotRoute()
    local cfg = Config.SpotBlip
    if not cfg or not cfg.enable or not cfg.route or routeNativeWarned then return end

    local coords = GetEntityCoords(PlayerPedId())
    local nearestIndex, nearestDist = nil, nil
    for index, spotCoords in pairs(spotBlipCoords) do
        local dist = GetCoordDistance(spotCoords, coords)
        if not nearestDist or dist < nearestDist then
            nearestDist = dist
            nearestIndex = index
        end
    end

    if nearestIndex == routedSpotIndex then return end

    if routedSpotIndex and spotBlips[routedSpotIndex] and DoesBlipExist(spotBlips[routedSpotIndex]) then
        SetBlipRouteNative(spotBlips[routedSpotIndex], false)
    end

    routedSpotIndex = nearestIndex
    if nearestIndex and spotBlips[nearestIndex] then
        SetBlipRouteNative(spotBlips[nearestIndex], true)
        SetBlipRouteColourNative(spotBlips[nearestIndex], cfg.routeColor or 5)
    end
end

local function refreshSpotBlips()
    clearSpotBlips()

    local cfg = Config.SpotBlip
    if not cfg or not cfg.enable or not activeTown then return end

    for index, spot in ipairs(Config.ResolveTownSpots(activeTown, activeAreaName)) do
        if activeSpotIndexes[index] and not cleanedSpots[index] then
            local blip = BlipAddForCoords(1664425300, spot.coords.x, spot.coords.y, spot.coords.z)
            if cfg.sprite then
                SetBlipSprite(blip, cfg.sprite, false)
            end
            SetBlipScale(blip, cfg.scale or 0.15)
            SetBlipName(blip, spot.label or 'Cleaning Spot')
            if cfg.colorModifier then
                BlipAddModifier(blip, joaat(cfg.colorModifier))
            end
            spotBlips[index] = blip
            spotBlipCoords[index] = spot.coords
        end
    end

    updateSpotRoute()
end

local spotGarbageProps = {}

local function despawnSpotGarbage(index)
    local obj = spotGarbageProps[index]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    spotGarbageProps[index] = nil
end

local function clearAllSpotGarbage()
    for index in pairs(spotGarbageProps) do
        despawnSpotGarbage(index)
    end
end

local function spawnSpotGarbage(index, coords, models)
    if spotGarbageProps[index] then return end
    if not models or #models == 0 then return end

    local modelName = models[math.random(#models)]
    local hashModel = joaat(modelName)
    if not IsModelValid(hashModel) then
        print(("^1dsml_cleaningjob: \"%s\" is not a valid prop model^7"):format(modelName))
        return
    end

    RequestModel(hashModel, false)
    local attempts = 0
    while not HasModelLoaded(hashModel) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(hashModel) then return end

    local obj = CreateObject(hashModel, coords.x, coords.y, coords.z, false, false, false)
    repeat Wait(0) until DoesEntityExist(obj)

    PlaceEntityOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, false)
    SetModelAsNoLongerNeeded(hashModel)

    spotGarbageProps[index] = obj
end

local function refreshSpotGarbage()
    for index in pairs(spotGarbageProps) do
        if not activeSpotIndexes[index] or cleanedSpots[index] then
            despawnSpotGarbage(index)
        end
    end

    if not activeTown then return end

    local models = townGarbageProps(activeTown)
    for index, spot in ipairs(Config.ResolveTownSpots(activeTown, activeAreaName)) do
        if activeSpotIndexes[index] and not cleanedSpots[index] then
            spawnSpotGarbage(index, spot.coords, models)
        end
    end
end

local townNpcPeds = {}
local townGrounded = {}
local townNpcBlips = {}

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    clearSpotBlips()
    clearAllSpotGarbage()

    for _, ped in pairs(townNpcPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in ipairs(townNpcBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)

local function spawnTownNpc(town)
    local npc = town.npc
    local hashModel = joaat(npc.model)
    if not IsModelValid(hashModel) then
        print(("^1dsml_cleaningjob: \"%s\" is not a valid ped model (town: %s)^7"):format(npc.model, town.id))
        return
    end

    RequestModel(hashModel, false)
    local attempts = 0
    while not HasModelLoaded(hashModel) and attempts < 200 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(hashModel) then
        print(("^1dsml_cleaningjob: ped model \"%s\" failed to load (town: %s)^7"):format(npc.model, town.id))
        return
    end

    local ped = CreatePed(hashModel, npc.coords.x, npc.coords.y, npc.coords.z, npc.heading or 0.0, false, false, false, false)
    repeat Wait(0) until DoesEntityExist(ped)

    -- Required or this ped model renders as a bare invisible skeleton.
    SetRandomOutfitVariation(ped, true)

    -- Collision only reliably streams in near the player, so this fast path only ever grounds
    -- whichever town the player already happens to be near at startup; every other town stays
    -- ungrounded until groundTownNpc() catches it later from the interaction loop below.
    RequestCollisionAtCoord(npc.coords.x, npc.coords.y, npc.coords.z)
    local colAttempts = 0
    while not HasCollisionLoadedAroundEntity(ped) and colAttempts < 20 do
        Wait(50)
        colAttempts = colAttempts + 1
    end
    if HasCollisionLoadedAroundEntity(ped) then
        townGrounded[town.id] = true
    end

    PlaceEntityOnGroundProperly(ped, true)
    SetEntityNoCollisionEntity(PlayerPedId(), ped, false)
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hashModel)

    -- Scenario must start before FreezeEntityPosition below or it never takes hold.
    if npc.scenario and npc.scenario ~= '' then
        TaskStartScenarioInPlace(ped, joaat(npc.scenario), -1, true)
    end

    Wait(1000)
    FreezeEntityPosition(ped, true)

    townNpcPeds[town.id] = ped
end

-- Re-snaps + re-freezes a town's NPC the first time the player is close enough that collision
-- there is guaranteed to have actually streamed in.
local function groundTownNpc(town, ped)
    if townGrounded[town.id] or not ped or not DoesEntityExist(ped) then return end

    FreezeEntityPosition(ped, false)
    PlaceEntityOnGroundProperly(ped, true)
    FreezeEntityPosition(ped, true)
    townGrounded[town.id] = true
end

local function registerNpcBlip(town)
    local npc = town.npc
    if npc.blip and npc.blip.enable then
        local blip = BlipAddForCoords(1664425300, npc.coords.x, npc.coords.y, npc.coords.z)
        SetBlipSprite(blip, npc.blip.sprite, true)
        SetBlipScale(blip, 0.2)
        SetBlipName(blip, ('%s Cleaning Job'):format(town.name))
        townNpcBlips[#townNpcBlips + 1] = blip
    end
end

CreateThread(function()
    repeat Wait(4000) until LocalPlayer.state.IsInSession
    UIPrompt.initialize()

    for _, town in ipairs(Config.Towns) do
        spawnTownNpc(town)
        registerNpcBlip(town)
    end

    -- Resync in case this script (re)started while the server already had an active job for
    -- this player.
    local status = Core.Callback.TriggerAwait('dsml_cleaningjob:GetStatus')
    if status and status.active then
        setActiveTown(status.townId)
        activeAreaName = status.areaName
        activeSpotIndexes = toIndexSet(status.spotIndexes)
        cleanedSpots = status.cleanedIndexes or {}
        refreshSpotBlips()
        refreshSpotGarbage()
        SendNUIMessage({
            type = 'dsml-clean-hud',
            active = true,
            townName = displayTownName(activeTown, status.townName, status.areaName),
            cleaned = status.cleaned,
            total = status.total
        })
    end
end)

CreateThread(function()
    while true do
        Wait(3000)
        if activeTownId then
            updateSpotRoute()
        end
    end
end)

--- NUI -----------------------------------------------------------------

local function openMenu(townId)
    local status = Core.Callback.TriggerAwait('dsml_cleaningjob:GetStatus')
    if not status then return end

    menuOpen = true
    setActiveTown(status.active and status.townId or nil)
    activeAreaName = status.active and status.areaName or nil

    if status.active then
        activeSpotIndexes = toIndexSet(status.spotIndexes)
        cleanedSpots = status.cleanedIndexes or {}
        refreshSpotBlips()
        refreshSpotGarbage()
        status.townName = displayTownName(activeTown, status.townName, status.areaName)
        SendNUIMessage({
            type = 'dsml-clean-hud',
            active = true,
            townName = status.townName,
            cleaned = status.cleaned,
            total = status.total
        })
    end

    SendNUIMessage({ type = 'dsml-clean-open', status = status, townId = townId })
    SetNuiFocus(true, true)
end

RegisterNUICallback('dsml-clean-close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('dsml-clean-getjob', function(data, cb)
    local result = Core.Callback.TriggerAwait('dsml_cleaningjob:GetJob', data.townId)
    if result and result.success then
        setActiveTown(data.townId)
        activeAreaName = result.areaName
        activeSpotIndexes = toIndexSet(result.spotIndexes)
        cleanedSpots = {}
        refreshSpotBlips()
        refreshSpotGarbage()
        SendNUIMessage({
            type = 'dsml-clean-hud',
            active = true,
            townName = displayTownName(activeTown, result.townName, result.areaName),
            cleaned = 0,
            total = result.total
        })
    end
    cb(result)
end)

RegisterNUICallback('dsml-clean-finish', function(_, cb)
    local result = Core.Callback.TriggerAwait('dsml_cleaningjob:FinishJob')
    if result and result.success then
        setActiveTown(nil)
        activeAreaName = nil
        activeSpotIndexes = {}
        cleanedSpots = {}
        clearSpotBlips()
        clearAllSpotGarbage()
        SendNUIMessage({ type = 'dsml-clean-hud', active = false })
    end
    cb(result)
end)

-- The server can reject a spot (moved out of range, rate-limited, timing too short), so local
-- state is only ever committed here, never optimistically beforehand.
RegisterNetEvent('dsml_cleaningjob:client:cleanResult', function(success, spotIndex, reason)
    cleaning = false

    if success then
        cleanedSpots[spotIndex] = true
        despawnSpotGarbage(spotIndex)
        refreshSpotBlips()
        return
    end

    if reason ~= 'nojob' and reason ~= 'notjobspot' then
        exports.bln_notify:tip("That didn't work — try again.", 3000, 'middle-right')
    end
    refreshSpotBlips()
    refreshSpotGarbage()
end)

RegisterNetEvent('dsml_cleaningjob:progress', function(townName, cleaned, total)
    local displayName = activeTown and displayTownName(activeTown, townName, activeAreaName) or townName
    SendNUIMessage({ type = 'dsml-clean-hud', active = true, townName = displayName, cleaned = cleaned, total = total })
end)

--- Interaction loop ------------------------------------------------------

local townPromptCache = {}
local function npcPromptFor(town)
    local label = townPromptCache[town.id]
    if not label then
        label = ('Talk to %s Cleaning Contractor'):format(town.name)
        townPromptCache[town.id] = label
    end
    return label
end

local spotLabelCache = setmetatable({}, { __mode = 'k' })
local function cleanLabelFor(spot)
    local label = spotLabelCache[spot]
    if not label then
        label = ('Clean: %s'):format(spot.label or 'Spot')
        spotLabelCache[spot] = label
    end
    return label
end

CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())

        for _, town in ipairs(Config.Towns) do
            local npcDist = GetCoordDistance(town.npc.coords, coords)

            if not townGrounded[town.id] and npcDist < 40.0 then
                groundTownNpc(town, townNpcPeds[town.id])
            end

            if not menuOpen and not cleaning and npcDist < Config.Distances.npc then
                sleep = 0
                UIPrompt.activate(npcPromptFor(town))
                if UIPrompt.completedThisFrame() then
                    openMenu(town.id)
                end
            end
        end

        if not menuOpen and not cleaning and activeTown then
            for index, spot in ipairs(Config.ResolveTownSpots(activeTown, activeAreaName)) do
                if activeSpotIndexes[index] and not cleanedSpots[index] then
                    local dist = GetCoordDistance(spot.coords, coords)

                    if Config.SpotMarker and dist < Config.SpotMarker.distance then
                        sleep = 0
                        local m = Config.SpotMarker
                        DrawMarker(m.type, spot.coords.x, spot.coords.y, spot.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.0, m.scale.x, m.scale.y, m.scale.z, m.color.r, m.color.g, m.color.b, m.color.a,
                            m.bob, false, 2, false, nil, nil, false)
                    end

                    if dist < Config.Distances.spot then
                        sleep = 0
                        UIPrompt.activate(cleanLabelFor(spot))
                        if UIPrompt.completedThisFrame() then
                            cleaning = true
                            local animation = townCleaningAnimation(activeTown)
                            Animations.startAnimation(animation)

                            progressbar.start(('Cleaning %s...'):format(spot.label or ''), Config.CleanTime,
                                function()
                                    Animations.endAnimation(animation)
                                    -- cleaning stays true until the server replies, so this spot
                                    -- can't be double-fired while a reply is pending.
                                    TriggerServerEvent('dsml_cleaningjob:CleanSpot', index)
                                end)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
