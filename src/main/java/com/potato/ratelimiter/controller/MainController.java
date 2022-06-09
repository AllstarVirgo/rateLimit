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
        if(rateLimiterClient.tryAcquire("ketty", 5)){
            return "success\n";
        }
        return "false\n";
    }
}
