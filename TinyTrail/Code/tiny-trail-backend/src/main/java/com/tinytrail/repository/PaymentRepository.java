package com.tinytrail.repository;

import com.tinytrail.entity.Order;
import com.tinytrail.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    
    Optional<Payment> findByOrder(Order order);
    
    Optional<Payment> findByTransactionId(String transactionId);
    
    Optional<Payment> findByRazorpayPaymentId(String razorpayPaymentId);
    
    Optional<Payment> findByRazorpayOrderId(String razorpayOrderId);
    
    List<Payment> findByStatus(Payment.PaymentStatus status);
    
    List<Payment> findByMethod(Payment.PaymentMethod method);
    
    @Query("SELECT p FROM Payment p WHERE p.order.user.id = :userId")
    List<Payment> findPaymentsByUserId(@Param("userId") Long userId);
    
    @Query("SELECT p FROM Payment p WHERE p.order.product.entrepreneur.id = :entrepreneurId")
    List<Payment> findPaymentsByEntrepreneurId(@Param("entrepreneurId") Long entrepreneurId);
    
    @Query("SELECT p FROM Payment p WHERE p.status = :status AND p.order.user.id = :userId")
    List<Payment> findByStatusAndUserId(@Param("status") Payment.PaymentStatus status, 
                                       @Param("userId") Long userId);
}
