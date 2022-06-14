# rateLimit

令牌桶限流算法java + redis的实现

限制速率的时间单位 支持 秒s(seconds) 分m(minute) 小时h(hour) 天(day)

核心的限流算法位于: src/main/resources/lua/rateLimiter.lua

客户端语言为Java
客户端框架为Spring-data-reids