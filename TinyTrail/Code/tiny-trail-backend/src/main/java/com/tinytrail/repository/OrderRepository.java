package com.tinytrail.repository;

import com.tinytrail.entity.Order;
import com.tinytrail.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    
    List<Order> findByUser(User user);
    
    Page<Order> findByUser(User user, Pageable pageable);
    
    List<Order> findByStatus(Order.OrderStatus status);
    
    List<Order> findByPaymentStatus(Order.PaymentStatus paymentStatus);
    
    @Query("SELECT o FROM Order o WHERE o.product.entrepreneur = :entrepreneur")
    List<Order> findOrdersByEntrepreneur(@Param("entrepreneur") User entrepreneur);
    
    @Query("SELECT o FROM Order o WHERE o.product.entrepreneur = :entrepreneur")
    Page<Order> findOrdersByEntrepreneur(@Param("entrepreneur") User entrepreneur, Pageable pageable);
    
    @Query("SELECT o FROM Order o WHERE o.user = :user AND o.status = :status")
    List<Order> findByUserAndStatus(@Param("user") User user, @Param("status") Order.OrderStatus status);
    
    @Query("SELECT o FROM Order o WHERE o.product.entrepreneur = :entrepreneur AND o.status = :status")
    List<Order> findByEntrepreneurAndStatus(@Param("entrepreneur") User entrepreneur, 
                                           @Param("status") Order.OrderStatus status);
    
    @Query("SELECT o FROM Order o WHERE o.createdAt BETWEEN :startDate AND :endDate")
    List<Order> findOrdersByDateRange(@Param("startDate") LocalDateTime startDate, 
                                     @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT o FROM Order o WHERE o.product.entrepreneur = :entrepreneur AND " +
           "o.createdAt BETWEEN :startDate AND :endDate")
    List<Order> findEntrepreneurOrdersByDateRange(@Param("entrepreneur") User entrepreneur,
                                                 @Param("startDate") LocalDateTime startDate,
                                                 @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT COUNT(o) FROM Order o WHERE o.product.entrepreneur = :entrepreneur")
    Long countOrdersByEntrepreneur(@Param("entrepreneur") User entrepreneur);
    
    @Query("SELECT COUNT(o) FROM Order o WHERE o.user = :user")
    Long countOrdersByUser(@Param("user") User user);
}
