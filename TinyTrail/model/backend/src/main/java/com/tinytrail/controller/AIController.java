package com.tinytrail.controller;

import com.tinytrail.ai.AiService;
import com.tinytrail.ai.dto.AiRequest;
import com.tinytrail.ai.dto.AiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
public class AIController {

    @Autowired
    private AiService aiService;

    // TODO: Add rate limiting and authentication
    @PostMapping("/query")
    public ResponseEntity<AiResponse> query(@RequestBody AiRequest req) {
        AiResponse resp = aiService.query(req);
        return ResponseEntity.ok(resp);
    }
}
package com.tinytrail.controller;

import com.tinytrail.service.ai.AiService;
import com.tinytrail.service.ai.dto.AiRequest;
import com.tinytrail.service.ai.dto.AiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/ai")
public class AIController {

    private final AiService aiService;

    // Simple in-memory rate limiter per IP
    private final Map<String, RequestWindow> rateLimitMap = new ConcurrentHashMap<>();
    private final int MAX_REQUESTS = 10; // per window
    private final long WINDOW_MS = 60_000; // 1 minute

    public AIController(AiService aiService) {
        this.aiService = aiService;
    }

    @PostMapping("/query")
    public ResponseEntity<AiResponse> query(@RequestBody AiRequest request, @RequestHeader(value = "X-Forwarded-For", required = false) String xff, @RequestHeader(value = "X-Real-IP", required = false) String realIp) {
        String ip = realIp != null ? realIp : (xff != null ? xff.split(",")[0] : "local");

        RequestWindow window = rateLimitMap.computeIfAbsent(ip, k -> new RequestWindow(Instant.now().toEpochMilli(), 0));
        long now = Instant.now().toEpochMilli();
        if (now - window.startAt > WINDOW_MS) {
            window.startAt = now;
            window.count = 0;
        }
        if (window.count >= MAX_REQUESTS) {
            return ResponseEntity.status(429).build();
        }
        window.count++;

        AiResponse response = aiService.query(request);
        return ResponseEntity.ok(response);
    }

    private static class RequestWindow {
        long startAt;
        int count;

        public RequestWindow(long startAt, int count) {
            this.startAt = startAt;
            this.count = count;
        }
    }
}
