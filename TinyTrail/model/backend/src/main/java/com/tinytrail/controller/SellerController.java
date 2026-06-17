package com.tinytrail.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.RequestPart;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/seller")
public class SellerController {

    @PostMapping(value = "/clean-menu", consumes = {"multipart/form-data"})
    public ResponseEntity<?> cleanMenu(@RequestPart("file") MultipartFile file) {
        // TODO: Integrate OCR (Tesseract) + LLM rewrite to extract structured menu
        if (file == null || file.isEmpty()) return ResponseEntity.badRequest().body("file required");
        Map<String,Object> resp = new HashMap<>();
        resp.put("text", "Mock OCR text extracted from handwritten menu. Replace with OCR+LLM pipeline.");
        resp.put("cleanedJson", Map.of("items", new String[]{"Item A - 50", "Item B - 30"}));
        return ResponseEntity.ok(resp);
    }

    @PostMapping(value = "/generate-photo")
    public ResponseEntity<?> generatePhoto(@RequestPart(name = "file", required = false) MultipartFile file, @RequestPart(name = "prompt", required = false) String prompt) {
        // TODO: Call external image generation API and return job id or URL
        Map<String,Object> resp = new HashMap<>();
        resp.put("status", "queued");
        resp.put("jobId", "mock-job-1234");
        resp.put("previewUrl", "https://placehold.co/600x400?text=mock");
        return ResponseEntity.ok(resp);
    }
}
package com.tinytrail.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/seller")
public class SellerController {

    @PostMapping("/clean-menu")
    public ResponseEntity<?> cleanMenu(@RequestPart MultipartFile file) {
        // TODO: Integrate OCR (Tesseract) and LLM rewriting
        // For now return a mock cleaned text and JSON
        return ResponseEntity.ok(Map.of("text", "Mock OCR text from handwritten menu", "cleanedJson", Map.of("items", new String[]{"Murukku", "Sundal"}))); 
    }

    @PostMapping("/generate-photo")
    public ResponseEntity<?> generatePhoto(@RequestParam(required = false) String prompt, @RequestPart(required = false) MultipartFile file) {
        // TODO: Integrate to external image generation service (example: DALL·E, Stable Diffusion)
        // Return mock job id and preview URL
        return ResponseEntity.ok(Map.of("jobId", "mock-job-123", "previewUrl", "https://via.placeholder.com/300"));
    }
}
package com.tinytrail.controller;

import com.tinytrail.entity.Seller;
import com.tinytrail.entity.User;
import com.tinytrail.repository.SellerRepository;
import com.tinytrail.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/seller")
@Tag(name = "Seller", description = "Seller management endpoints")
public class SellerController {

    @Autowired
    private SellerRepository sellerRepository;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/onboard")
    @Operation(summary = "Seller onboarding", description = "Register as a seller")
    public ResponseEntity<Seller> onboardSeller(Authentication authentication, @RequestBody Map<String, String> sellerData) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Check if user is already a seller
            if (sellerRepository.existsByUserId(user.getId())) {
                return ResponseEntity.badRequest().build();
            }

            Seller seller = new Seller();
            seller.setUser(user);
            seller.setShopName(sellerData.get("shopName"));
            seller.setPincode(sellerData.get("pincode"));
            seller.setAddress(sellerData.get("address"));
            seller.setDescription(sellerData.get("description"));

            seller = sellerRepository.save(seller);

            // Update user role to SELLER
            user.setRole(User.Role.SELLER);
            userRepository.save(user);

            return ResponseEntity.ok(seller);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/profile")
    @Operation(summary = "Get seller profile", description = "Get current seller profile")
    public ResponseEntity<Seller> getSellerProfile(Authentication authentication) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            Seller seller = sellerRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new RuntimeException("User is not a seller"));

            return ResponseEntity.ok(seller);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PutMapping("/profile")
    @Operation(summary = "Update seller profile", description = "Update seller profile")
    public ResponseEntity<Seller> updateSellerProfile(Authentication authentication, @RequestBody Map<String, String> sellerData) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            Seller seller = sellerRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new RuntimeException("User is not a seller"));

            if (sellerData.containsKey("shopName")) {
                seller.setShopName(sellerData.get("shopName"));
            }
            if (sellerData.containsKey("pincode")) {
                seller.setPincode(sellerData.get("pincode"));
            }
            if (sellerData.containsKey("address")) {
                seller.setAddress(sellerData.get("address"));
            }
            if (sellerData.containsKey("description")) {
                seller.setDescription(sellerData.get("description"));
            }

            seller = sellerRepository.save(seller);
            return ResponseEntity.ok(seller);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
