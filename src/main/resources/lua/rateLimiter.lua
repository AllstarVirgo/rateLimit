local seconds = "s"
local minute = "m"
local hour = "h"
local day = "d"

local success = 200
local badRequest = 400
local notEnoughToken = 401

--interval 自用户上次取到令牌至现在，经历的毫秒数
--maxRate 最大速率
--timeUnit 最大速率对应的时间单位
--计算在特定时间间隔内需要添加多少个令牌
local function getAddTokenCount(interval, maxRate, timeUnit)
    local intervalUnit = 1
    if seconds == timeUnit then
        intervalUnit = 1000 * intervalUnit
    elseif minute == timeUnit then
        intervalUnit = 60 * 1000 * intervalUnit
    elseif hour == timeUnit then
        intervalUnit = 60 * 60 * 1000 * intervalUnit
    elseif day == timeUnit then
        intervalUnit = 24 * 60 * 60 * 1000 * intervalUnit
    end
    local intervalForAddToken = intervalUnit / maxRate;
    return math.floor(interval / intervalForAddToken);
end

local function invalidExpireTimeAndTimeUnit(timeUnit, expireTimeBySeconds)
    if seconds == timeUnit then
        if expireTimeBySeconds < 1 then
            return true
        end
    elseif minute == timeUnit then
        if expireTimeBySeconds < 60 then
            return true
        end
    elseif hour == timeUnit then
        if expireTimeBySeconds < (60 * 60) then
            return true
        end
    elseif day == timeUnit then
        if expireTimeBySeconds < (24 * 60 * 60) then
            return true
        end
    end
    return false
end

local function invalidRequestTokenNumber(requestTokenNumber)
    if requestTokenNumber == nil then
        return true
    end
    if type(requestTokenNumber) ~= "number" then
        return true
    end
    return requestTokenNumber <= 0
end

--key 唯一标识
--currentTimeMillis 当前时间戳
--maxRate 限制速率
--timeUnit 限制速率的时间单位 支持 s(seconds) m(minute) h(hour) d(day)
--requestTokenNumber  请求的令牌数
--expireTimeBySeconds 过期时间
--返回table, 第1个值是状态码，第2个值是桶内当前的令牌数
local function tryAcquire(key, currentTimeMillis, maxRate, requestTokenNumber, timeUnit, expireTimeBySeconds)
    currentTimeMillis = tonumber(currentTimeMillis)
    maxRate = tonumber(maxRate)
    requestTokenNumber = tonumber(requestTokenNumber)
    expireTimeBySeconds = tonumber(expireTimeBySeconds)
    local rateLimitMetaData = redis.pcall("hmget", key, "lastAccess", "currentTokenCount")
    local lastAccess = tonumber(rateLimitMetaData[1])
    local currentTokenCount = tonumber(rateLimitMetaData[2])
    if (type(lastAccess) == "boolean" or lastAccess == nil) then
        lastAccess = 0
        currentTokenCount = 0
        redis.pcall("hmset", key, "lastAccess", lastAccess, "currentTokenCount", currentTokenCount)
        redis.pcall("expire", key, expireTimeBySeconds)
    end
    --参数校验
    if currentTimeMillis < lastAccess or invalidExpireTimeAndTimeUnit(timeUnit, expireTimeBySeconds) or invalidRequestTokenNumber(requestTokenNumber) then
        redis.pcall("del", key)
        return { badRequest, currentTokenCount }
    end
    local interval = currentTimeMillis - lastAccess
    local addTokenNumberOfInterval = getAddTokenCount(interval, maxRate, timeUnit)
    if addTokenNumberOfInterval > 0 then
        currentTokenCount = currentTokenCount + addTokenNumberOfInterval
    end

    if currentTokenCount >= maxRate then
        currentTokenCount = maxRate
    end

    if currentTokenCount > 0 and currentTokenCount >= requestTokenNumber then
        currentTokenCount = currentTokenCount - requestTokenNumber
        lastAccess = currentTimeMillis
        redis.pcall("hmset", key, "lastAccess", lastAccess, "currentTokenCount", currentTokenCount)
        return { success, currentTokenCount }
    end

    return { notEnoughToken, currentTokenCount }
end

local key = KEYS[1]
local currentTimeMillis = ARGV[1]
local maxRate = ARGV[2]
local requestTokenNumber = ARGV[3]
local timeUnit = ARGV[4]
local expireTimeBySeconds = ARGV[5]

return tryAcquire(key, currentTimeMillis, maxRate, requestTokenNumber, timeUnit, expireTimeBySeconds)