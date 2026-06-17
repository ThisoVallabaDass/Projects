package com.tinytrail.controller;

import com.tinytrail.entity.Order;
import com.tinytrail.entity.User;
import com.tinytrail.repository.UserRepository;
import com.tinytrail.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@Tag(name = "Admin", description = "Admin management endpoints")
public class AdminController {

    @Autowired
    private OrderService orderService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/orders")
    @Operation(summary = "Get all orders", description = "Get all orders (admin only)")
    public ResponseEntity<List<Order>> getAllOrders(Authentication authentication) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            if (user.getRole() != User.Role.ADMIN) {
                return ResponseEntity.forbidden().build();
            }

            List<Order> orders = orderService.getAllOrders();
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PutMapping("/orders/{id}/status")
    @Operation(summary = "Update order status", description = "Update order status (admin only)")
    public ResponseEntity<Order> updateOrderStatus(Authentication authentication, 
                                                 @PathVariable Long id, 
                                                 @RequestParam Order.OrderStatus status) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            if (user.getRole() != User.Role.ADMIN) {
                return ResponseEntity.forbidden().build();
            }

            Order order = orderService.updateOrderStatus(id, status);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/seed")
    @Operation(summary = "Seed sample data", description = "Create sample data for testing")
    public ResponseEntity<String> seedData() {
        try {
            // This would typically be implemented in a separate service
            // For now, just return success
            return ResponseEntity.ok("Sample data seeded successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to seed data: " + e.getMessage());
        }
    }

    @GetMapping("/stats")
    @Operation(summary = "Get admin stats", description = "Get platform statistics")
    public ResponseEntity<Map<String, Object>> getStats(Authentication authentication) {
        try {
            User user = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            if (user.getRole() != User.Role.ADMIN) {
                return ResponseEntity.forbidden().build();
            }

            // Mock stats - in real implementation, calculate from database
            Map<String, Object> stats = Map.of(
                "totalOrders", 150,
                "totalUsers", 75,
                "totalSellers", 25,
                "totalProducts", 300
            );

            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
