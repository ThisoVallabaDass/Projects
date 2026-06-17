package com.tinytrail.service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Utils;
import com.tinytrail.entity.Payment;
import com.tinytrail.repository.PaymentRepository;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class PaymentService {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentService.class);
    
    @Autowired
    private PaymentRepository paymentRepository;
    
    @Autowired
    private OrderService orderService;
    
    @Value("${razorpay.key-id}")
    private String razorpayKeyId;
    
    @Value("${razorpay.key-secret}")
    private String razorpayKeySecret;
    
    private RazorpayClient razorpayClient;
    
    private RazorpayClient getRazorpayClient() throws RazorpayException {
        if (razorpayClient == null) {
            razorpayClient = new RazorpayClient(razorpayKeyId, razorpayKeySecret);
        }
        return razorpayClient;
    }
    
    public Payment createPayment(com.tinytrail.entity.Order order, Payment.PaymentMethod method) {
        Payment payment = new Payment(order, order.getTotalAmount(), method);
        return paymentRepository.save(payment);
    }
    
    public String createRazorpayOrder(com.tinytrail.entity.Order order) throws RazorpayException {
        try {
            RazorpayClient client = getRazorpayClient();
            
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", order.getTotalAmount().multiply(BigDecimal.valueOf(100)).intValue()); // Amount in paise
            orderRequest.put("currency", "INR");
            orderRequest.put("receipt", "order_" + order.getId());
            
            Order razorpayOrder = client.orders.create(orderRequest);
            String razorpayOrderId = razorpayOrder.get("id");
            
            // Create or update payment record
            Optional<Payment> existingPayment = paymentRepository.findByOrder(order);
            Payment payment;
            
            if (existingPayment.isPresent()) {
                payment = existingPayment.get();
                payment.setRazorpayOrderId(razorpayOrderId);
            } else {
                payment = createPayment(order, Payment.PaymentMethod.UPI);
                payment.setRazorpayOrderId(razorpayOrderId);
            }
            
            paymentRepository.save(payment);
            
            return razorpayOrderId;
            
        } catch (RazorpayException e) {
            logger.error("Error creating Razorpay order: {}", e.getMessage());
            throw e;
        }
    }
    
    public boolean verifyPayment(String razorpayOrderId, String razorpayPaymentId, String razorpaySignature) {
        try {
            JSONObject options = new JSONObject();
            options.put("razorpay_order_id", razorpayOrderId);
            options.put("razorpay_payment_id", razorpayPaymentId);
            options.put("razorpay_signature", razorpaySignature);
            
            boolean isValidSignature = Utils.verifyPaymentSignature(options, razorpayKeySecret);
            
            if (isValidSignature) {
                // Update payment record
                Optional<Payment> paymentOpt = paymentRepository.findByRazorpayOrderId(razorpayOrderId);
                if (paymentOpt.isPresent()) {
                    Payment payment = paymentOpt.get();
                    payment.setRazorpayPaymentId(razorpayPaymentId);
                    payment.setRazorpaySignature(razorpaySignature);
                    payment.setStatus(Payment.PaymentStatus.COMPLETED);
                    payment.setTransactionId(razorpayPaymentId);
                    
                    paymentRepository.save(payment);
                    
                    // Update order payment status
                    orderService.updatePaymentStatus(payment.getOrder().getId(), 
                                                   com.tinytrail.entity.Order.PaymentStatus.COMPLETED);
                    
                    return true;
                }
            }
            
            return false;
            
        } catch (RazorpayException e) {
            logger.error("Error verifying payment: {}", e.getMessage());
            return false;
        }
    }
    
    public Payment markPaymentFailed(String razorpayOrderId, String reason) {
        Optional<Payment> paymentOpt = paymentRepository.findByRazorpayOrderId(razorpayOrderId);
        if (paymentOpt.isPresent()) {
            Payment payment = paymentOpt.get();
            payment.setStatus(Payment.PaymentStatus.FAILED);
            payment.setFailureReason(reason);
            
            Payment savedPayment = paymentRepository.save(payment);
            
            // Update order payment status
            orderService.updatePaymentStatus(payment.getOrder().getId(), 
                                           com.tinytrail.entity.Order.PaymentStatus.FAILED);
            
            return savedPayment;
        }
        throw new RuntimeException("Payment not found for Razorpay order: " + razorpayOrderId);
    }
    
    public Optional<Payment> findById(Long id) {
        return paymentRepository.findById(id);
    }
    
    public Optional<Payment> findByOrder(com.tinytrail.entity.Order order) {
        return paymentRepository.findByOrder(order);
    }
    
    public Optional<Payment> findByTransactionId(String transactionId) {
        return paymentRepository.findByTransactionId(transactionId);
    }
    
    public List<Payment> findPaymentsByUserId(Long userId) {
        return paymentRepository.findPaymentsByUserId(userId);
    }
    
    public List<Payment> findPaymentsByEntrepreneurId(Long entrepreneurId) {
        return paymentRepository.findPaymentsByEntrepreneurId(entrepreneurId);
    }
    
    public List<Payment> findPaymentsByStatus(Payment.PaymentStatus status) {
        return paymentRepository.findByStatus(status);
    }
}
