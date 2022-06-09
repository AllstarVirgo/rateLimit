package com.potato.ratelimiter.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;

import java.util.Collections;

public class RateLimiterClient {

    private final Logger logger = LoggerFactory.getLogger(RateLimiterClient.class);

    private final StringRedisTemplate stringRedisTemplate;

    private final RedisScript<Boolean> rateLimiterClientLua;

    public RateLimiterClient(StringRedisTemplate stringRedisTemplate, RedisScript<Boolean> rateLimiterClientLua) {
        this.stringRedisTemplate = stringRedisTemplate;
        this.rateLimiterClientLua = rateLimiterClientLua;
    }

    public boolean tryAcquire(String key, int maxRate) {
        try {
            return stringRedisTemplate.execute(rateLimiterClientLua, Collections.singletonList(key), String.valueOf(System.currentTimeMillis()), String.valueOf(maxRate), String.valueOf(1));
        } catch (Exception e) {
            logger.error("execute key failed", e);
        }
        return false;
    }

}
