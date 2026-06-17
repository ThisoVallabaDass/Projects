package com.tinytrail.controller;

import com.tinytrail.entity.Order;
import com.tinytrail.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/webhooks")
@Tag(name = "Webhooks", description = "Webhook endpoints for external services")
public class WebhookController {

    @Autowired
    private OrderService orderService;

    @PostMapping("/payment")
    @Operation(summary = "Payment webhook", description = "Simulate payment webhook for testing")
    public ResponseEntity<String> paymentWebhook(@RequestBody Map<String, Object> webhookData) {
        try {
            Long orderId = Long.valueOf(webhookData.get("orderId").toString());
            String status = webhookData.get("status").toString();
            String transactionId = webhookData.get("txnId") != null ? 
                webhookData.get("txnId").toString() : null;

            Order order = orderService.getOrderById(orderId);
            
            if ("SUCCESS".equals(status)) {
                order.setStatus(Order.OrderStatus.CONFIRMED);
                order.setTransactionId(transactionId);
            } else if ("FAILED".equals(status)) {
                order.setStatus(Order.OrderStatus.CANCELLED);
            }

            orderService.updateOrderStatus(orderId, order.getStatus());

            return ResponseEntity.ok("Webhook processed successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Webhook processing failed: " + e.getMessage());
        }
    }

    @PostMapping("/delivery")
    @Operation(summary = "Delivery webhook", description = "Simulate delivery webhook for testing")
    public ResponseEntity<String> deliveryWebhook(@RequestBody Map<String, Object> webhookData) {
        try {
            Long orderId = Long.valueOf(webhookData.get("orderId").toString());
            String status = webhookData.get("status").toString();

            Order.OrderStatus orderStatus;
            switch (status) {
                case "SHIPPED":
                    orderStatus = Order.OrderStatus.SHIPPED;
                    break;
                case "DELIVERED":
                    orderStatus = Order.OrderStatus.DELIVERED;
                    break;
                default:
                    orderStatus = Order.OrderStatus.PENDING;
            }

            orderService.updateOrderStatus(orderId, orderStatus);

            return ResponseEntity.ok("Delivery webhook processed successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Delivery webhook processing failed: " + e.getMessage());
        }
    }
}
