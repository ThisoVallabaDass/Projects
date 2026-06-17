package com.tinytrail.service;

import com.tinytrail.entity.*;
import com.tinytrail.repository.OrderRepository;
import com.tinytrail.repository.ProductRepository;
import com.tinytrail.repository.SellerRepository;
import com.tinytrail.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SellerRepository sellerRepository;

    @Autowired
    private ProductRepository productRepository;

    public Order createOrder(String username, Map<String, Object> orderData) {
        User buyer = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Extract order data
        String deliveryAddress = (String) orderData.get("deliveryAddress");
        String paymentMethod = (String) orderData.get("paymentMethod");
        String upiId = (String) orderData.get("upiId");
        
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> items = (List<Map<String, Object>>) orderData.get("items");

        if (items == null || items.isEmpty()) {
            throw new RuntimeException("Order must contain at least one item");
        }

        // Get the first item to determine seller (assuming all items are from same seller for simplicity)
        Map<String, Object> firstItem = items.get(0);
        Long productId = Long.valueOf(firstItem.get("productId").toString());
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));

        Seller seller = product.getSeller();

        // Calculate total
        BigDecimal total = BigDecimal.ZERO;
        for (Map<String, Object> item : items) {
            Long itemProductId = Long.valueOf(item.get("productId").toString());
            Integer quantity = Integer.valueOf(item.get("quantity").toString());
            BigDecimal price = new BigDecimal(item.get("price").toString());
            
            total = total.add(price.multiply(new BigDecimal(quantity)));
        }

        // Create order
        Order order = new Order();
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setTotal(total);
        order.setDeliveryAddress(deliveryAddress);
        order.setPaymentMethod(paymentMethod);
        order.setUpiId(upiId);
        order.setStatus(Order.OrderStatus.PENDING);

        order = orderRepository.save(order);

        // Create order items
        for (Map<String, Object> item : items) {
            Long itemProductId = Long.valueOf(item.get("productId").toString());
            Integer quantity = Integer.valueOf(item.get("quantity").toString());
            BigDecimal price = new BigDecimal(item.get("price").toString());
            
            Product itemProduct = productRepository.findById(itemProductId)
                    .orElseThrow(() -> new RuntimeException("Product not found"));

            OrderItem orderItem = new OrderItem();
            orderItem.setOrder(order);
            orderItem.setProduct(itemProduct);
            orderItem.setQuantity(quantity);
            orderItem.setPrice(price);

            order.getOrderItems().add(orderItem);
        }

        return orderRepository.save(order);
    }

    public List<Order> getOrdersByBuyer(String username) {
        User buyer = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return orderRepository.findByBuyerId(buyer.getId());
    }

    public List<Order> getOrdersBySeller(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Seller seller = sellerRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("User is not a seller"));

        return orderRepository.findBySellerId(seller.getId());
    }

    public Order updateOrderStatus(Long orderId, Order.OrderStatus status) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        order.setStatus(status);
        
        if (status == Order.OrderStatus.DELIVERED) {
            order.setDeliveredAt(LocalDateTime.now());
        }

        return orderRepository.save(order);
    }

    public Order getOrderById(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }
}
