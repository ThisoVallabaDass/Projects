package com.tinytrail.controller;

import com.tinytrail.entity.Subscription;
import com.tinytrail.repository.SubscriptionRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.Map;

@RestController
@RequestMapping("/api/subscriptions")
public class SubscriptionController {

    private final SubscriptionRepository subscriptionRepository;

    public SubscriptionController(SubscriptionRepository subscriptionRepository) {
        this.subscriptionRepository = subscriptionRepository;
    }

    @PostMapping
    public ResponseEntity<?> createSubscription(@RequestBody Map<String, Object> body) {
        // body should include planId and userId (or use authenticated user)
        // Validate and create subscription record with status CREATED
        Subscription s = new Subscription();
        s.setStatus("CREATED");
        subscriptionRepository.save(s);
        // Return a mock payment token and subscription id
        return ResponseEntity.created(URI.create("/api/subscriptions/" + s.getId())).body(Map.of("subscriptionId", s.getId(), "paymentToken", "MOCK_PAY_TOKEN"));
    }
}
