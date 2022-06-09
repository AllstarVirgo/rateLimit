local halfDayTimeSeconds = 12 * 60 * 60

local function getAddTokenCount(interval, maxRate)
    local tokenNumberPerMilliseconds = 1000 / maxRate;
    return interval / tokenNumberPerMilliseconds;
end

local function tryAcquire(key, currentTimeMillis, maxRate, requestTokenNumber)
    currentTimeMillis = tonumber(currentTimeMillis)
    maxRate = tonumber(maxRate)
    requestTokenNumber = tonumber(requestTokenNumber)
    local rateLimitMetaData = redis.pcall("hmget", key, "lastAccess", "currentTokenCount")
    local lastAccess = rateLimitMetaData[1]
    local currentTokenCount = rateLimitMetaData[2]
    if (type(lastAccess) == "boolean" or lastAccess == nil) then
        lastAccess = 0
        currentTokenCount = 0
        redis.pcall("hmset", key, "lastAccess", lastAccess, "currentTokenCount", currentTokenCount)
        redis.pcall("expire", key, halfDayTimeSeconds)
    end
    local interval = currentTimeMillis - lastAccess
    local addToken = getAddTokenCount(interval, maxRate)
    if addToken > 0 then
        currentTokenCount = currentTokenCount + addToken
    end

    if currentTokenCount >= maxRate then
        currentTokenCount = maxRate
    end

    if currentTokenCount > 0 and currentTokenCount >= requestTokenNumber then
        currentTokenCount = currentTokenCount - requestTokenNumber
        lastAccess = currentTimeMillis
        redis.pcall("hmset", key, "lastAccess", lastAccess, "currentTokenCount", currentTokenCount)
        return true
    end

    return false
end

local key = KEYS[1]
local currentTimeMillis = ARGV[1]
local maxRate = ARGV[2]
local requestTokenNumber = ARGV[3]

return tryAcquire(key, currentTimeMillis, maxRate, requestTokenNumber)