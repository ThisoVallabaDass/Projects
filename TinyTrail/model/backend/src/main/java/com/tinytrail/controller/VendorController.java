package com.tinytrail.controller;

import com.tinytrail.model.Vendor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/vendors")
public class VendorController {

    // TODO: Inject VendorService / repository

    @GetMapping("/{id}")
    public ResponseEntity<Vendor> getVendor(@PathVariable Long id) {
        // TODO: fetch vendor from DB
        Vendor v = new Vendor();
        v.setId(id);
        v.setName("Mock Vendor");
        v.setTagline("Homemade treats");
        return ResponseEntity.ok(v);
    }

    @PostMapping("/{id}/subscribe")
    public ResponseEntity<?> subscribe(@PathVariable Long id) {
        // TODO: implement subscription creation + mock payment
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/verify")
    public ResponseEntity<?> verify(@PathVariable Long id) {
        // admin endpoint
        // TODO: set isVerifiedHomeKitchen=true
        return ResponseEntity.ok().build();
    }
}
package com.tinytrail.controller;

import com.tinytrail.entity.Subscription;
import com.tinytrail.entity.SubscriptionPlan;
import com.tinytrail.entity.Vendor;
import com.tinytrail.repository.SubscriptionPlanRepository;
import com.tinytrail.repository.SubscriptionRepository;
import com.tinytrail.repository.VendorRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.Optional;

@RestController
@RequestMapping("/api/vendors")
public class VendorController {

    private final VendorRepository vendorRepository;
    private final SubscriptionPlanRepository planRepository;
    private final SubscriptionRepository subscriptionRepository;

    public VendorController(VendorRepository vendorRepository, SubscriptionPlanRepository planRepository, SubscriptionRepository subscriptionRepository) {
        this.vendorRepository = vendorRepository;
        this.planRepository = planRepository;
        this.subscriptionRepository = subscriptionRepository;
    }

    @GetMapping("/{id}")
    public ResponseEntity<Vendor> getVendor(@PathVariable Long id) {
        Optional<Vendor> v = vendorRepository.findById(id);
        return v.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/{id}/subscribe")
    public ResponseEntity<?> subscribe(@PathVariable Long id, @RequestParam Long userId, @RequestParam Long planId) {
        // mock payment flow: create subscription with status CREATED
        Optional<Vendor> vendor = vendorRepository.findById(id);
        if (vendor.isEmpty()) return ResponseEntity.notFound().build();

        Optional<SubscriptionPlan> plan = planRepository.findById(planId);
        if (plan.isEmpty()) return ResponseEntity.badRequest().body("Invalid plan");

        Subscription s = new Subscription();
        s.setPlan(plan.get());
        s.setStatus("CREATED");
        // TODO: associate real user by userId after auth integration
        subscriptionRepository.save(s);

        return ResponseEntity.created(URI.create("/api/subscriptions/" + s.getId())).body(Map.of("paymentToken", "MOCK_TOKEN", "subscriptionId", s.getId()));
    }

    @PostMapping("/{id}/verify")
    public ResponseEntity<?> verifyVendor(@PathVariable Long id) {
        Optional<Vendor> vendorOpt = vendorRepository.findById(id);
        if (vendorOpt.isEmpty()) return ResponseEntity.notFound().build();
        Vendor v = vendorOpt.get();
        v.setIsVerifiedHomeKitchen(true);
        vendorRepository.save(v);
        return ResponseEntity.ok(Map.of("verified", true));
    }
}
