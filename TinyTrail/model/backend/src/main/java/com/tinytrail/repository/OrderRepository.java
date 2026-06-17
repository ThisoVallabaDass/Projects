package com.tinytrail.repository;

import com.tinytrail.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    @Query("SELECT o FROM Order o WHERE o.buyer.id = :buyerId ORDER BY o.createdAt DESC")
    List<Order> findByBuyerId(@Param("buyerId") Long buyerId);
    
    @Query("SELECT o FROM Order o WHERE o.seller.id = :sellerId ORDER BY o.createdAt DESC")
    List<Order> findBySellerId(@Param("sellerId") Long sellerId);
    
    @Query("SELECT o FROM Order o WHERE o.status = :status ORDER BY o.createdAt DESC")
    List<Order> findByStatus(@Param("status") Order.OrderStatus status);
}
