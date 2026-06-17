package com.tinytrail.repository;

import com.tinytrail.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByPincode(String pincode);
    
    @Query("SELECT p FROM Product p WHERE p.pincode = :pincode AND p.category = :category")
    List<Product> findByPincodeAndCategory(@Param("pincode") String pincode, @Param("category") String category);
    
    @Query("SELECT p FROM Product p WHERE p.seller.id = :sellerId")
    List<Product> findBySellerId(@Param("sellerId") Long sellerId);
    
    @Query("SELECT DISTINCT p.category FROM Product p WHERE p.category IS NOT NULL")
    List<String> findDistinctCategories();
    
    @Query("SELECT p FROM Product p WHERE LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR LOWER(p.description) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    List<Product> searchByNameOrDescription(@Param("searchTerm") String searchTerm);
}
