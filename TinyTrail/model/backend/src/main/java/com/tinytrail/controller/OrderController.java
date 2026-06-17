package com.tinytrail.controller;

import com.tinytrail.entity.Order;
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
@RequestMapping("/orders")
@Tag(name = "Orders", description = "Order management endpoints")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping
    @Operation(summary = "Create order", description = "Create a new order")
    public ResponseEntity<Order> createOrder(Authentication authentication, @RequestBody Map<String, Object> orderData) {
        try {
            Order order = orderService.createOrder(authentication.getName(), orderData);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/buyer")
    @Operation(summary = "Get buyer orders", description = "Get orders for current buyer")
    public ResponseEntity<List<Order>> getBuyerOrders(Authentication authentication) {
        try {
            List<Order> orders = orderService.getOrdersByBuyer(authentication.getName());
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/seller")
    @Operation(summary = "Get seller orders", description = "Get orders for current seller")
    public ResponseEntity<List<Order>> getSellerOrders(Authentication authentication) {
        try {
            List<Order> orders = orderService.getOrdersBySeller(authentication.getName());
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get order by ID", description = "Get order details by ID")
    public ResponseEntity<Order> getOrderById(@PathVariable Long id) {
        try {
            Order order = orderService.getOrderById(id);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}/status")
    @Operation(summary = "Update order status", description = "Update order status (seller/admin only)")
    public ResponseEntity<Order> updateOrderStatus(@PathVariable Long id, @RequestParam Order.OrderStatus status) {
        try {
            Order order = orderService.updateOrderStatus(id, status);
            return ResponseEntity.ok(order);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/admin/all")
    @Operation(summary = "Get all orders", description = "Get all orders (admin only)")
    public ResponseEntity<List<Order>> getAllOrders() {
        try {
            List<Order> orders = orderService.getAllOrders();
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
