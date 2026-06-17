package com.tinytrail.repository;

import com.tinytrail.entity.Seller;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SellerRepository extends JpaRepository<Seller, Long> {
    Optional<Seller> findByUserId(Long userId);
    
    @Query("SELECT s FROM Seller s WHERE s.pincode = :pincode")
    List<Seller> findByPincode(@Param("pincode") String pincode);
    
    boolean existsByUserId(Long userId);
}
