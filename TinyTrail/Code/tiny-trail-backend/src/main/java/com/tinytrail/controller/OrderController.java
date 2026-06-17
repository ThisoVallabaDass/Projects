package com.tinytrail.controller;

import com.tinytrail.dto.ApiResponse;
import com.tinytrail.entity.Order;
import com.tinytrail.entity.Product;
import com.tinytrail.entity.User;
import com.tinytrail.service.OrderService;
import com.tinytrail.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/orders")
public class OrderController {
    
    @Autowired
    private OrderService orderService;
    
    @Autowired
    private ProductService productService;
    
    @PostMapping
    public ResponseEntity<?> createOrder(@Valid @RequestBody OrderRequest orderRequest, 
                                       Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            
            Optional<Product> productOpt = productService.findById(orderRequest.getProductId());
            if (!productOpt.isPresent()) {
                return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Product not found"));
            }
            
            Product product = productOpt.get();
            
            Order order = orderService.createOrder(user, product, orderRequest.getQuantity(),
                                                 orderRequest.getDeliveryAddress(), 
                                                 orderRequest.getDeliveryPincode());
            
            return ResponseEntity.ok(new ApiResponse(true, "Order created successfully", order));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error creating order: " + e.getMessage()));
        }
    }
    
    @GetMapping("/my-orders")
    public ResponseEntity<?> getMyOrders(Authentication authentication,
                                       @RequestParam(defaultValue = "0") int page,
                                       @RequestParam(defaultValue = "10") int size) {
        try {
            User user = (User) authentication.getPrincipal();
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            
            Page<Order> orders = orderService.findOrdersByUser(user, pageable);
            
            return ResponseEntity.ok(new ApiResponse(true, "Orders retrieved successfully", orders));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving orders: " + e.getMessage()));
        }
    }
    
    @GetMapping("/entrepreneur-orders")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> getEntrepreneurOrders(Authentication authentication,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "10") int size) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            
            Page<Order> orders = orderService.findOrdersByEntrepreneur(entrepreneur, pageable);
            
            return ResponseEntity.ok(new ApiResponse(true, "Orders retrieved successfully", orders));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving orders: " + e.getMessage()));
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<?> getOrderById(@PathVariable Long id, Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            Optional<Order> orderOpt = orderService.findById(id);
            
            if (!orderOpt.isPresent()) {
                return ResponseEntity.notFound().build();
            }
            
            Order order = orderOpt.get();
            
            // Check if user has access to this order
            boolean hasAccess = order.getUser().getId().equals(user.getId()) ||
                              (user.getRole() == User.Role.ENTREPRENEUR && 
                               order.getProduct().getEntrepreneur().getId().equals(user.getId()));
            
            if (!hasAccess) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "Access denied"));
            }
            
            return ResponseEntity.ok(new ApiResponse(true, "Order retrieved successfully", order));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving order: " + e.getMessage()));
        }
    }
    
    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> updateOrderStatus(@PathVariable Long id, 
                                             @RequestBody OrderStatusRequest statusRequest,
                                             Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            Optional<Order> orderOpt = orderService.findById(id);
            
            if (!orderOpt.isPresent()) {
                return ResponseEntity.notFound().build();
            }
            
            Order order = orderOpt.get();
            
            // Check if the order belongs to the authenticated entrepreneur's products
            if (!order.getProduct().getEntrepreneur().getId().equals(entrepreneur.getId())) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "You can only update orders for your products"));
            }
            
            Order updatedOrder = orderService.updateOrderStatus(id, statusRequest.getStatus());
            
            return ResponseEntity.ok(new ApiResponse(true, "Order status updated successfully", updatedOrder));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error updating order status: " + e.getMessage()));
        }
    }
    
    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancelOrder(@PathVariable Long id, Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            Optional<Order> orderOpt = orderService.findById(id);
            
            if (!orderOpt.isPresent()) {
                return ResponseEntity.notFound().build();
            }
            
            Order order = orderOpt.get();
            
            // Only the customer who placed the order can cancel it
            if (!order.getUser().getId().equals(user.getId())) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "You can only cancel your own orders"));
            }
            
            Order cancelledOrder = orderService.cancelOrder(id);
            
            return ResponseEntity.ok(new ApiResponse(true, "Order cancelled successfully", cancelledOrder));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error cancelling order: " + e.getMessage()));
        }
    }
    
    @GetMapping("/stats")
    @PreAuthorize("hasRole('ENTREPRENEUR')")
    public ResponseEntity<?> getOrderStats(Authentication authentication) {
        try {
            User entrepreneur = (User) authentication.getPrincipal();
            
            Long totalOrders = orderService.countOrdersByEntrepreneur(entrepreneur);
            List<Order> pendingOrders = orderService.findOrdersByEntrepreneurAndStatus(entrepreneur, Order.OrderStatus.PENDING);
            List<Order> confirmedOrders = orderService.findOrdersByEntrepreneurAndStatus(entrepreneur, Order.OrderStatus.CONFIRMED);
            List<Order> shippedOrders = orderService.findOrdersByEntrepreneurAndStatus(entrepreneur, Order.OrderStatus.SHIPPED);
            List<Order> deliveredOrders = orderService.findOrdersByEntrepreneurAndStatus(entrepreneur, Order.OrderStatus.DELIVERED);
            
            OrderStats stats = new OrderStats();
            stats.setTotalOrders(totalOrders);
            stats.setPendingOrders((long) pendingOrders.size());
            stats.setConfirmedOrders((long) confirmedOrders.size());
            stats.setShippedOrders((long) shippedOrders.size());
            stats.setDeliveredOrders((long) deliveredOrders.size());
            
            return ResponseEntity.ok(new ApiResponse(true, "Order statistics retrieved successfully", stats));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving order statistics: " + e.getMessage()));
        }
    }
    
    // Inner classes for request/response
    public static class OrderRequest {
        private Long productId;
        private Integer quantity;
        private String deliveryAddress;
        private String deliveryPincode;
        private String orderNotes;
        
        // Getters and setters
        public Long getProductId() { return productId; }
        public void setProductId(Long productId) { this.productId = productId; }
        
        public Integer getQuantity() { return quantity; }
        public void setQuantity(Integer quantity) { this.quantity = quantity; }
        
        public String getDeliveryAddress() { return deliveryAddress; }
        public void setDeliveryAddress(String deliveryAddress) { this.deliveryAddress = deliveryAddress; }
        
        public String getDeliveryPincode() { return deliveryPincode; }
        public void setDeliveryPincode(String deliveryPincode) { this.deliveryPincode = deliveryPincode; }
        
        public String getOrderNotes() { return orderNotes; }
        public void setOrderNotes(String orderNotes) { this.orderNotes = orderNotes; }
    }
    
    public static class OrderStatusRequest {
        private Order.OrderStatus status;
        
        public Order.OrderStatus getStatus() { return status; }
        public void setStatus(Order.OrderStatus status) { this.status = status; }
    }
    
    public static class OrderStats {
        private Long totalOrders;
        private Long pendingOrders;
        private Long confirmedOrders;
        private Long shippedOrders;
        private Long deliveredOrders;
        
        // Getters and setters
        public Long getTotalOrders() { return totalOrders; }
        public void setTotalOrders(Long totalOrders) { this.totalOrders = totalOrders; }
        
        public Long getPendingOrders() { return pendingOrders; }
        public void setPendingOrders(Long pendingOrders) { this.pendingOrders = pendingOrders; }
        
        public Long getConfirmedOrders() { return confirmedOrders; }
        public void setConfirmedOrders(Long confirmedOrders) { this.confirmedOrders = confirmedOrders; }
        
        public Long getShippedOrders() { return shippedOrders; }
        public void setShippedOrders(Long shippedOrders) { this.shippedOrders = shippedOrders; }
        
        public Long getDeliveredOrders() { return deliveredOrders; }
        public void setDeliveredOrders(Long deliveredOrders) { this.deliveredOrders = deliveredOrders; }
    }
}
