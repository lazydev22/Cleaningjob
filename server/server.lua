local Core = exports.vorp_core:GetCore()

local activeJobs = {}
local cooldowns = {}
local jobActionInFlight = {}

local function getCharacter(source)
    local user = Core.getUser(source)
    if not user then return nil end
    return user.getUsedCharacter
end

local function getTown(townId)
    for _, town in ipairs(Config.Towns) do
        if town.id == townId then
            return town
        end
    end
    return nil
end

local function isWithinCleanSpotDistance(source, coords)
    return exports.dsml_security:ValidateDistance(source, coords, Config.Distances.spot + Config.Security.SpotDistanceTolerance)
end

local function secondsLeft(charIdentifier)
    local availableAt = cooldowns[charIdentifier]
    if not availableAt then return 0 end
    local left = availableAt - os.time()
    return left > 0 and left or 0
end

-- Uses weathersync's synced clock so every player agrees on night; pcall-wrapped since a
-- missing/stopped weathersync should just mean "never night", not an error.
local function isNightTime()
    local cfg = Config.NightRestriction
    if not cfg or not cfg.enable then return false end

    local ok, time = pcall(function() return exports.weathersync:getTime() end)
    if not ok or not time or not time.hour then return false end

    local hour, startHour, endHour = time.hour, cfg.startHour, cfg.endHour
    if startHour <= endHour then
        return hour >= startHour and hour < endHour
    end
    return hour >= startHour or hour < endHour
end

local function allSpotIndexes(spots)
    local indexes = {}
    for i = 1, #spots do
        indexes[i] = i
    end
    return indexes
end

-- Random subset of a flat spot list per Config.SpotDrop; grouped towns use allSpotIndexes
-- instead since picking one place already narrows things down.
local function pickJobSpots(spots)
    local indexes = allSpotIndexes(spots)

    local drop = Config.SpotDrop
    local maxDrop = math.min((drop and drop.max or 0), #indexes - 1)
    local minDrop = math.min((drop and drop.min or 0), maxDrop)
    local dropCount = maxDrop > minDrop and math.random(minDrop, maxDrop) or maxDrop

    for i = #indexes, 2, -1 do
        local j = math.random(i)
        indexes[i], indexes[j] = indexes[j], indexes[i]
    end

    local chosen = {}
    for i = 1, #indexes - dropCount do
        chosen[#chosen + 1] = indexes[i]
    end
    table.sort(chosen)

    return chosen
end

Core.Callback.Register('dsml_cleaningjob:GetStatus', function(source, cb)
    local Character = getCharacter(source)
    if not Character then return cb({ active = false, cooldown = 0, isNight = isNightTime() }) end

    local job = activeJobs[source]
    if job then
        return cb({
            active = true,
            townId = job.townId,
            townName = job.townName,
            areaName = job.areaName,
            cleaned = job.count,
            total = job.total,
            cleanedIndexes = job.cleaned,
            spotIndexes = job.spotIndexes,
        })
    end

    cb({ active = false, cooldown = secondsLeft(Character.charIdentifier), isNight = isNightTime() })
end)

Core.Callback.Register('dsml_cleaningjob:GetJob', function(source, cb, townId)
    if not exports.dsml_security:RateLimit(source, 'GetJob', Config.Security.RateLimitMs.GetJob) then
        return cb({ success = false, message = 'Slow down.' })
    end

    if type(townId) ~= 'string' then
        exports.dsml_security:LogSuspicious(source, 'GetJob', 'badarg', ('townId=%s'):format(tostring(townId)))
        return cb({ success = false, message = 'That job is not available.' })
    end

    local Character = getCharacter(source)
    if not Character then return cb({ success = false, message = 'Character not found.' }) end

    local town = getTown(townId)
    if not town then return cb({ success = false, message = 'That job is not available.' }) end

    if activeJobs[source] then
        return cb({ success = false, message = 'You already have an active job.' })
    end

    local left = secondsLeft(Character.charIdentifier)
    if left > 0 then
        return cb({
            success = false,
            message = ('You can pick up another job in %d minute(s).'):format(math.ceil(left / 60))
        })
    end

    if isNightTime() then
        return cb({ success = false, message = 'Cleaning jobs are not available at night — come back after dawn.' })
    end

    local areaName = Config.PickTownArea(town)
    local spots = Config.ResolveTownSpots(town, areaName)
    local spotIndexes = areaName and allSpotIndexes(spots) or pickJobSpots(spots)

    activeJobs[source] = {
        townId = town.id,
        townName = town.name,
        areaName = areaName,
        spotIndexes = spotIndexes,
        cleaned = {},
        count = 0,
        total = #spotIndexes,
        phaseStartedAt = GetGameTimer(),
    }

    cb({
        success = true,
        townName = town.name,
        areaName = areaName,
        cleaned = 0,
        total = #spotIndexes,
        spotIndexes = spotIndexes,
    })
end)

local function denyClean(source, spotIndex, reason)
    TriggerClientEvent('dsml_cleaningjob:client:cleanResult', source, false, spotIndex, reason)
end

RegisterNetEvent('dsml_cleaningjob:CleanSpot', function(spotIndex)
    local _source = source

    if not exports.dsml_security:ValidateNumber(spotIndex, { integer = true, min = 1 }) then
        exports.dsml_security:LogSuspicious(_source, 'CleanSpot', 'badarg', ('spotIndex=%s'):format(tostring(spotIndex)))
        return denyClean(_source, spotIndex, 'badarg')
    end

    if not exports.dsml_security:RateLimit(_source, 'CleanSpot', Config.Security.RateLimitMs.CleanSpot) then
        return denyClean(_source, spotIndex, 'ratelimit')
    end

    local job = activeJobs[_source]
    if not job then return denyClean(_source, spotIndex, 'nojob') end

    local town = getTown(job.townId)
    if not town then return denyClean(_source, spotIndex, 'nojob') end

    local spots = Config.ResolveTownSpots(town, job.areaName)
    if spotIndex > #spots then return denyClean(_source, spotIndex, 'badarg') end

    local isJobSpot = false
    for _, idx in ipairs(job.spotIndexes) do
        if idx == spotIndex then
            isJobSpot = true
            break
        end
    end
    if not isJobSpot then return denyClean(_source, spotIndex, 'notjobspot') end

    if job.cleaned[spotIndex] then return end

    if jobActionInFlight[_source] then return denyClean(_source, spotIndex, 'busy') end
    jobActionInFlight[_source] = true

    local spot = spots[spotIndex]

    if not isWithinCleanSpotDistance(_source, spot.coords) then
        jobActionInFlight[_source] = nil
        exports.dsml_security:LogSuspicious(_source, 'CleanSpot', 'distance',
            ('spotIndex=%d townId=%s'):format(spotIndex, job.townId))
        return denyClean(_source, spotIndex, 'moved')
    end

    -- dsml_progressbar's own timing is never trusted; re-derived here off phaseStartedAt.
    local requiredMs = Config.CleanTime * (Config.Security.TimingTolerancePct or 1)
    local elapsedMs = GetGameTimer() - (job.phaseStartedAt or 0)
    if elapsedMs < requiredMs then
        jobActionInFlight[_source] = nil
        exports.dsml_security:LogSuspicious(_source, 'CleanSpot', 'impossible',
            ('spotIndex=%d elapsed=%dms required=%dms'):format(spotIndex, elapsedMs, requiredMs))
        return denyClean(_source, spotIndex, 'toosoon')
    end

    job.cleaned[spotIndex] = true
    job.count = job.count + 1
    job.phaseStartedAt = GetGameTimer()

    jobActionInFlight[_source] = nil

    TriggerClientEvent('dsml_cleaningjob:client:cleanResult', _source, true, spotIndex)
    TriggerClientEvent('dsml_cleaningjob:progress', _source, job.townName, job.count, job.total)

    if job.count >= job.total then
        TriggerClientEvent('bln_notify:send', _source, {
            title = 'All spots cleaned — head back to report in and get paid.',
            duration = 5000,
            placement = 'middle-right',
            useBackground = false,
            customSound = { sound = 'INFO_SHOW', soundSet = 'Ledger_Sounds' },
        })
    end
end)

Core.Callback.Register('dsml_cleaningjob:FinishJob', function(source, cb)
    if not exports.dsml_security:RateLimit(source, 'FinishJob', Config.Security.RateLimitMs.FinishJob) then
        return cb({ success = false, message = 'Slow down.' })
    end

    local Character = getCharacter(source)
    if not Character then return cb({ success = false, message = 'Character not found.' }) end

    local job = activeJobs[source]
    if not job then
        return cb({ success = false, message = "You don't have an active job." })
    end

    if job.count < job.total then
        return cb({
            success = false,
            message = ('You still have %d spot(s) left to clean.'):format(job.total - job.count)
        })
    end

    -- Job is cleared before anything below can yield, closing a double-payout race; the lock is
    -- defense in depth on top.
    if not exports.dsml_security:AcquireAction(source, 'dsml_cleaningjob:finishing') then
        return cb({ success = false, message = 'Still processing your last request.' })
    end
    activeJobs[source] = nil

    Character.addCurrency(Config.Reward.CurrencyType, Config.Reward.Amount)

    TriggerEvent('dsml_quests:activityCompleted', source, {
        resource = 'dsml_cleaningjob',
        action = 'cleaning',
        location = job.townId,
        amount = 1,
    })

    local cooldownMs = math.random(Config.JobCooldown.min, Config.JobCooldown.max)
    cooldowns[Character.charIdentifier] = os.time() + math.floor(cooldownMs / 1000)

    exports.dsml_security:ReleaseAction(source, 'dsml_cleaningjob:finishing')
    cb({ success = true, message = 'Job complete — payment received.' })
end)

AddEventHandler('playerDropped', function()
    activeJobs[source] = nil
    jobActionInFlight[source] = nil
end)
