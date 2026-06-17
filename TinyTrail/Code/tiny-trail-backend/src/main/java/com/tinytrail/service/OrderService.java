package com.tinytrail.service;

import com.tinytrail.entity.Order;
import com.tinytrail.entity.Product;
import com.tinytrail.entity.User;
import com.tinytrail.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class OrderService {
    
    @Autowired
    private OrderRepository orderRepository;
    
    @Autowired
    private ProductService productService;
    
    public Order createOrder(User user, Product product, Integer quantity, String deliveryAddress, String deliveryPincode) {
        // Check product availability
        if (!productService.isProductAvailable(product.getId(), quantity)) {
            throw new RuntimeException("Product is not available in requested quantity");
        }
        
        // Calculate total amount
        BigDecimal totalAmount = product.getPrice().multiply(BigDecimal.valueOf(quantity));
        
        Order order = new Order(user, product, quantity, totalAmount);
        order.setDeliveryAddress(deliveryAddress);
        order.setDeliveryPincode(deliveryPincode);
        
        Order savedOrder = orderRepository.save(order);
        
        // Update product stock
        if (product.getStockQuantity() != null) {
            productService.updateStock(product.getId(), product.getStockQuantity() - quantity);
        }
        
        return savedOrder;
    }
    
    public Optional<Order> findById(Long id) {
        return orderRepository.findById(id);
    }
    
    public List<Order> findAllOrders() {
        return orderRepository.findAll();
    }
    
    public List<Order> findOrdersByUser(User user) {
        return orderRepository.findByUser(user);
    }
    
    public Page<Order> findOrdersByUser(User user, Pageable pageable) {
        return orderRepository.findByUser(user, pageable);
    }
    
    public List<Order> findOrdersByEntrepreneur(User entrepreneur) {
        return orderRepository.findOrdersByEntrepreneur(entrepreneur);
    }
    
    public Page<Order> findOrdersByEntrepreneur(User entrepreneur, Pageable pageable) {
        return orderRepository.findOrdersByEntrepreneur(entrepreneur, pageable);
    }
    
    public List<Order> findOrdersByStatus(Order.OrderStatus status) {
        return orderRepository.findByStatus(status);
    }
    
    public List<Order> findOrdersByUserAndStatus(User user, Order.OrderStatus status) {
        return orderRepository.findByUserAndStatus(user, status);
    }
    
    public List<Order> findOrdersByEntrepreneurAndStatus(User entrepreneur, Order.OrderStatus status) {
        return orderRepository.findByEntrepreneurAndStatus(entrepreneur, status);
    }
    
    public Order updateOrderStatus(Long orderId, Order.OrderStatus status) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setStatus(status);
            return orderRepository.save(order);
        }
        throw new RuntimeException("Order not found with id: " + orderId);
    }
    
    public Order updatePaymentStatus(Long orderId, Order.PaymentStatus paymentStatus) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setPaymentStatus(paymentStatus);
            
            // Auto-confirm order if payment is completed
            if (paymentStatus == Order.PaymentStatus.COMPLETED && order.getStatus() == Order.OrderStatus.PENDING) {
                order.setStatus(Order.OrderStatus.CONFIRMED);
            }
            
            return orderRepository.save(order);
        }
        throw new RuntimeException("Order not found with id: " + orderId);
    }
    
    public Order cancelOrder(Long orderId) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            
            // Only allow cancellation if order is not shipped or delivered
            if (order.getStatus() == Order.OrderStatus.SHIPPED || order.getStatus() == Order.OrderStatus.DELIVERED) {
                throw new RuntimeException("Cannot cancel order that has been shipped or delivered");
            }
            
            order.setStatus(Order.OrderStatus.CANCELLED);
            
            // Restore product stock
            Product product = order.getProduct();
            if (product.getStockQuantity() != null) {
                productService.updateStock(product.getId(), product.getStockQuantity() + order.getQuantity());
            }
            
            return orderRepository.save(order);
        }
        throw new RuntimeException("Order not found with id: " + orderId);
    }
    
    public List<Order> findOrdersByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return orderRepository.findOrdersByDateRange(startDate, endDate);
    }
    
    public List<Order> findEntrepreneurOrdersByDateRange(User entrepreneur, LocalDateTime startDate, LocalDateTime endDate) {
        return orderRepository.findEntrepreneurOrdersByDateRange(entrepreneur, startDate, endDate);
    }
    
    public Long countOrdersByEntrepreneur(User entrepreneur) {
        return orderRepository.countOrdersByEntrepreneur(entrepreneur);
    }
    
    public Long countOrdersByUser(User user) {
        return orderRepository.countOrdersByUser(user);
    }
}
