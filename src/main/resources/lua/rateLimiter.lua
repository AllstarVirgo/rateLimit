local function tryAcquire(key, currentTimeMillis, maxRate)
    currentTimeMillis = tonumber(currentTimeMillis)
    maxRate = tonumber(maxRate)
    local rateLimitMetaData = redis.pcall("hmget", key, "lastAccess", "currentTokenCount")
    local lastAccess = rateLimitMetaData[1]
    local currentTokenCount = rateLimitMetaData[2]
    if (lastAccess == nil or currentTokenCount == nil) then
        lastAccess = 0
        currentTokenCount = 0
        redis.pcall("hmset", key, "lastAccess", lastAccess, "currentTokenCount", currentTokenCount)
    end
    local interval = currentTimeMillis - lastAccess
    local addToken = getAddTokenCount(interval, maxRate)
    if addToken > 0 then
        currentTokenCount = currentTokenCount + addToken
    end

    if currentTokenCount >= maxRate then
        currentTokenCount = maxRate
    end

    lastAccess = currentTimeMillis
    redis.pcall("hmset", key, "lastAccess", lastAccess, "currentTokenCount", currentTokenCount)

    if currentTokenCount > 0 then
        currentTokenCount = currentTokenCount - 1
        return true
    end

    return false
end

local function getAddTokenCount(interval, maxRate)
    local tokenNumberPerMilliseconds = 1000 / maxRate;
    return interval / tokenNumberPerMilliseconds;
end

local key = KEYS[1]
local currentTimeMillis = ARGV[1]
local maxRate = ARGV[2]
return tryAcquire(key, currentTimeMillis, maxRate)