package com.potato.ratelimiter.controller;

import com.potato.ratelimiter.client.RateLimiterClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MainController {

    @Autowired
    private RateLimiterClient rateLimiterClient;

    @GetMapping
    public String getStatus(){
        long code = (long)(rateLimiterClient.tryAcquire("ketty5", 5).get(0));
        if(code == 200){
            return "success\n";
        }
        return "false\n";
    }
}
