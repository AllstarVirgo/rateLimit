package com.potato.ratelimiter.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;

import java.util.ArrayList;
import java.util.Collections;

public class RateLimiterClient {

    private final Logger logger = LoggerFactory.getLogger(RateLimiterClient.class);

    private final StringRedisTemplate stringRedisTemplate;

    private final RedisScript<ArrayList> rateLimiterClientLua;

    public RateLimiterClient(StringRedisTemplate stringRedisTemplate, RedisScript<ArrayList> rateLimiterClientLua) {
        this.stringRedisTemplate = stringRedisTemplate;
        this.rateLimiterClientLua = rateLimiterClientLua;
    }

    public ArrayList tryAcquire(String key, int maxRate) {
        try {
            return stringRedisTemplate.execute(rateLimiterClientLua, Collections.singletonList(key), String.valueOf(System.currentTimeMillis()), String.valueOf(maxRate), String.valueOf(1), "s",String.valueOf(10));
        } catch (Exception e) {
            logger.error("execute key failed", e);
        }
        return new ArrayList();
    }

}
