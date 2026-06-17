package com.tinytrail.controller;

import com.tinytrail.dto.ApiResponse;
import com.tinytrail.entity.Order;
import com.tinytrail.entity.Payment;
import com.tinytrail.entity.User;
import com.tinytrail.service.OrderService;
import com.tinytrail.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/payments")
public class PaymentController {
    
    @Autowired
    private PaymentService paymentService;
    
    @Autowired
    private OrderService orderService;
    
    @PostMapping("/create-order")
    public ResponseEntity<?> createPaymentOrder(@RequestBody PaymentOrderRequest request, 
                                              Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            Optional<Order> orderOpt = orderService.findById(request.getOrderId());
            
            if (!orderOpt.isPresent()) {
                return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Order not found"));
            }
            
            Order order = orderOpt.get();
            
            // Check if the order belongs to the authenticated user
            if (!order.getUser().getId().equals(user.getId())) {
                return ResponseEntity.status(403)
                    .body(new ApiResponse(false, "Access denied"));
            }
            
            String razorpayOrderId = paymentService.createRazorpayOrder(order);
            
            PaymentOrderResponse response = new PaymentOrderResponse();
            response.setRazorpayOrderId(razorpayOrderId);
            response.setAmount(order.getTotalAmount());
            response.setOrderId(order.getId());
            
            return ResponseEntity.ok(new ApiResponse(true, "Payment order created successfully", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error creating payment order: " + e.getMessage()));
        }
    }
    
    @PostMapping("/verify")
    public ResponseEntity<?> verifyPayment(@RequestBody PaymentVerificationRequest request,
                                         Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            
            boolean isValid = paymentService.verifyPayment(
                request.getRazorpayOrderId(),
                request.getRazorpayPaymentId(),
                request.getRazorpaySignature()
            );
            
            if (isValid) {
                return ResponseEntity.ok(new ApiResponse(true, "Payment verified successfully"));
            } else {
                // Mark payment as failed
                paymentService.markPaymentFailed(request.getRazorpayOrderId(), "Payment verification failed");
                return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Payment verification failed"));
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error verifying payment: " + e.getMessage()));
        }
    }
    
    @PostMapping("/failure")
    public ResponseEntity<?> handlePaymentFailure(@RequestBody PaymentFailureRequest request,
                                                 Authentication authentication) {
        try {
            paymentService.markPaymentFailed(request.getRazorpayOrderId(), request.getErrorDescription());
            
            return ResponseEntity.ok(new ApiResponse(true, "Payment failure recorded"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error recording payment failure: " + e.getMessage()));
        }
    }
    
    @GetMapping("/order/{orderId}")
    public ResponseEntity<?> getPaymentByOrderId(@PathVariable Long orderId, Authentication authentication) {
        try {
            User user = (User) authentication.getPrincipal();
            Optional<Order> orderOpt = orderService.findById(orderId);
            
            if (!orderOpt.isPresent()) {
                return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Order not found"));
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
            
            Optional<Payment> payment = paymentService.findByOrder(order);
            
            if (payment.isPresent()) {
                return ResponseEntity.ok(new ApiResponse(true, "Payment retrieved successfully", payment.get()));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ApiResponse(false, "Error retrieving payment: " + e.getMessage()));
        }
    }
    
    // Inner classes for request/response
    public static class PaymentOrderRequest {
        private Long orderId;
        
        public Long getOrderId() { return orderId; }
        public void setOrderId(Long orderId) { this.orderId = orderId; }
    }
    
    public static class PaymentOrderResponse {
        private String razorpayOrderId;
        private java.math.BigDecimal amount;
        private Long orderId;
        
        public String getRazorpayOrderId() { return razorpayOrderId; }
        public void setRazorpayOrderId(String razorpayOrderId) { this.razorpayOrderId = razorpayOrderId; }
        
        public java.math.BigDecimal getAmount() { return amount; }
        public void setAmount(java.math.BigDecimal amount) { this.amount = amount; }
        
        public Long getOrderId() { return orderId; }
        public void setOrderId(Long orderId) { this.orderId = orderId; }
    }
    
    public static class PaymentVerificationRequest {
        private String razorpayOrderId;
        private String razorpayPaymentId;
        private String razorpaySignature;
        
        public String getRazorpayOrderId() { return razorpayOrderId; }
        public void setRazorpayOrderId(String razorpayOrderId) { this.razorpayOrderId = razorpayOrderId; }
        
        public String getRazorpayPaymentId() { return razorpayPaymentId; }
        public void setRazorpayPaymentId(String razorpayPaymentId) { this.razorpayPaymentId = razorpayPaymentId; }
        
        public String getRazorpaySignature() { return razorpaySignature; }
        public void setRazorpaySignature(String razorpaySignature) { this.razorpaySignature = razorpaySignature; }
    }
    
    public static class PaymentFailureRequest {
        private String razorpayOrderId;
        private String errorDescription;
        
        public String getRazorpayOrderId() { return razorpayOrderId; }
        public void setRazorpayOrderId(String razorpayOrderId) { this.razorpayOrderId = razorpayOrderId; }
        
        public String getErrorDescription() { return errorDescription; }
        public void setErrorDescription(String errorDescription) { this.errorDescription = errorDescription; }
    }
}
