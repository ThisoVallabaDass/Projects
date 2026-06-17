package com.tinytrail.repository;

import com.tinytrail.entity.Product;
import com.tinytrail.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    
    List<Product> findByEntrepreneur(User entrepreneur);
    
    List<Product> findByPincode(String pincode);
    
    List<Product> findByCategory(String category);
    
    List<Product> findByLanguage(Product.Language language);
    
    Page<Product> findByPincodeAndIsAvailable(String pincode, Boolean isAvailable, Pageable pageable);
    
    Page<Product> findByCategoryAndPincodeAndIsAvailable(String category, String pincode, Boolean isAvailable, Pageable pageable);
    
    @Query("SELECT p FROM Product p WHERE p.pincode = :pincode AND p.isAvailable = true AND " +
           "(LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.category) LIKE LOWER(CONCAT('%', :searchTerm, '%')))")
    Page<Product> searchProductsByPincode(@Param("pincode") String pincode, 
                                         @Param("searchTerm") String searchTerm, 
                                         Pageable pageable);
    
    @Query("SELECT p FROM Product p WHERE p.isAvailable = true AND " +
           "(LOWER(p.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.description) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(p.category) LIKE LOWER(CONCAT('%', :searchTerm, '%')))")
    Page<Product> searchProducts(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    @Query("SELECT DISTINCT p.category FROM Product p WHERE p.isAvailable = true")
    List<String> findAllCategories();
    
    @Query("SELECT DISTINCT p.category FROM Product p WHERE p.pincode = :pincode AND p.isAvailable = true")
    List<String> findCategoriesByPincode(@Param("pincode") String pincode);
    
    List<Product> findByEntrepreneurAndIsAvailable(User entrepreneur, Boolean isAvailable);
    
    @Query("SELECT p FROM Product p WHERE p.entrepreneur.id = :entrepreneurId AND p.isAvailable = true")
    List<Product> findActiveProductsByEntrepreneur(@Param("entrepreneurId") Long entrepreneurId);
}
